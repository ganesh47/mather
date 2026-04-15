import SwiftUI

/// Bond Blast — the sensor-powered complement-match finale stage for VS1.
///
/// Displays all complement pairs for the session target (e.g. for 7:
/// 1+6, 2+5, 3+4). The child can drag or tap a left card, then drop or tap on
/// the matching right card to lock the pair. All pairs locked = stage done.
///
/// **Sensor integration** (both ambient — tap-only path always works):
/// - Tilt drift: unselected left cards float ±6 pt with device attitude.
/// - Shake: shuffles the right column order for unmatched pairs.
/// - Clap (optional, default off): triggers a celebration response after
///   all pairs are matched.
///
/// Lifecycle: `MotionService` and `SoundDetectionService` are started/stopped
/// by `SliceSessionView` via `.onAppear` / `.onDisappear` modifiers applied at
/// the call site, not inside this view.
struct BondMatchView: View {

    // MARK: - Inputs

    let state: BondMatchState
    let tiltPitch: Double
    let tiltRoll: Double
    let shakeDetected: Bool
    let clapDetected: Bool
    /// Called when the child correctly matches a pair (passes the pair's id).
    let onMatch: (UUID) -> Void
    /// Called when the child taps a wrong right-column target.
    let onMismatch: () -> Void
    /// Called when the child taps or drags a left card (pickup haptic).
    let onDragStarted: (UUID) -> Void
    /// Called when a card is near a snap zone (near-snap haptic).
    let onNearTarget: () -> Void
    /// Call after consuming a shake event so MotionService can reset.
    let onShakeHandled: () -> Void
    /// Call after consuming a clap event so SoundDetectionService can reset.
    let onClapHandled: () -> Void

    // MARK: - Local state

    /// The left-card pair currently selected (highlighted), waiting for a right-tap or drop.
    @State private var selectedPairId: UUID? = nil
    @GestureState private var dragOffset: CGSize = .zero
    /// Right column display order — shuffled at appear, reshuffled on shake.
    @State private var shuffledRightValues: [Int] = []
    /// Right-value that is currently wobbling after a mismatch.
    @State private var mismatchedRightValue: Int? = nil

    // MARK: - Constants

    private let cardSize: CGFloat = 88
    private let cardSpacing: CGFloat = 12

    // MARK: - Tilt drift

    /// Subtle positional drift applied to unselected, unmatched left cards.
    /// Max ±6 pt — perceptible but does not displace cards out of their tap zone.
    private var tiltDrift: CGSize {
        CGSize(
            width:  CGFloat(tiltRoll)  * 6,
            height: CGFloat(tiltPitch) * 6
        )
    }

    // MARK: - Body

    var body: some View {
        CardSurface {
            VStack(spacing: 20) {
                headerView
                pairsGrid
                progressDots
            }
        }
        .onAppear {
            setupShuffledOrder()
        }
        .onChange(of: shakeDetected) { _, shook in
            guard shook else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                shuffleUnmatchedRight()
            }
            onShakeHandled()
        }
        .onChange(of: clapDetected) { _, clapped in
            guard clapped, state.isComplete else { return }
            onClapHandled()
        }
        .sensoryFeedback(.success, trigger: state.matchCount)
        .accessibilityLabel("Bond Blast matching board. Make \(state.target). \(state.matchCount) of \(state.pairs.count) matched.")
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("Bond Blast!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.accent)
                .accessibilityAddTraits(.isHeader)
            Text("Make \(state.target)")
                .font(.title2.weight(.bold))
                .foregroundStyle(MatherTheme.warm)
        }
        .frame(maxWidth: .infinity)
    }

    private var pairsGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: selectable source cards
            VStack(spacing: cardSpacing) {
                columnLabel("Pick")
                ForEach(state.pairs) { pair in
                    leftCard(pair: pair)
                }
            }

            // Centre: large "+" separator
            VStack {
                columnLabel(" ")  // height spacer to align with labels
                Text("+")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .frame(height: cardSize)
            }

            // Right column: shuffle targets (complement values)
            VStack(spacing: cardSpacing) {
                columnLabel("Match")
                ForEach(shuffledRightValues, id: \.self) { rightVal in
                    rightCard(value: rightVal)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var progressDots: some View {
        HStack(spacing: 10) {
            ForEach(0..<state.pairs.count, id: \.self) { i in
                Circle()
                    .fill(i < state.matchCount ? MatherTheme.accent : Color.secondary.opacity(0.25))
                    .frame(width: 14, height: 14)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state.matchCount)
    }

    // MARK: - Card builders

    @ViewBuilder
    private func leftCard(pair: ComplementPair) -> some View {
        let isSelected = selectedPairId == pair.id
        let isMatched  = pair.isMatched

        Button {
            guard !isMatched else { return }
            if !isSelected { onDragStarted(pair.id) }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) {
                selectedPairId = isSelected ? nil : pair.id
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                numberCardFill(
                    value: pair.left,
                    textColor: isMatched ? MatherTheme.accent : .white,
                    background: isMatched
                        ? MatherTheme.accent.opacity(0.15)
                        : (isSelected ? MatherTheme.warm : MatherTheme.warm.opacity(0.85)),
                    strokeColor: isSelected ? .white : (isMatched ? MatherTheme.accent : .clear),
                    strokeWidth: isSelected ? 4 : (isMatched ? 2 : 0),
                    dashed: false
                )
                // Drag hint: small right-arrow shown before any match is made.
                // Disappears once the child discovers the mechanic (first match).
                .overlay(alignment: .bottomTrailing) {
                    if !isMatched && state.matchCount == 0 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(6)
                            .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: state.matchCount)
                .shadow(
                    color: isSelected ? MatherTheme.warm.opacity(0.55) : .clear,
                    radius: 12
                )
                // Tilt drift — only on unselected, unmatched cards
                .offset((!isSelected && !isMatched) ? tiltDrift : .zero)
                .offset(isSelected && !isMatched ? dragOffset : .zero)
                .animation(.linear(duration: 0.1), value: tiltDrift)

                if isMatched {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MatherTheme.accent)
                        .font(.title3.weight(.bold))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.07 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.6), value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .updating($dragOffset) { value, state, _ in
                    guard selectedPairId == pair.id || !isMatched else { return }
                    state = value.translation
                }
                .onChanged { _ in
                    guard !isMatched else { return }
                    if selectedPairId != pair.id {
                        selectedPairId = pair.id
                        onDragStarted(pair.id)
                    }
                }
                .onEnded { value in
                    guard !isMatched else { return }
                    let horizontalTravel = value.translation.width
                    if horizontalTravel > 90 {
                        onNearTarget()
                        onMatch(pair.id)
                        withAnimation(.spring(response: 0.2)) { selectedPairId = nil }
                    } else if abs(horizontalTravel) > 40 {
                        onMismatch()
                    }
                }
        )
        .frame(width: cardSize, height: cardSize)
        .accessibilityLabel("\(pair.left)\(isMatched ? ", matched" : isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("bond-left-\(pair.left)")
    }

    @ViewBuilder
    private func rightCard(value: Int) -> some View {
        let isMatched   = state.pairs.first(where: { $0.right == value })?.isMatched == true
        let isWobbling  = mismatchedRightValue == value
        let isActivated = selectedPairId != nil && !isMatched

        Button {
            guard let selId = selectedPairId,
                  let pair = state.pairs.first(where: { $0.id == selId }),
                  !pair.isMatched else { return }

            if value == pair.right {
                onMatch(selId)
                withAnimation(.spring(response: 0.2)) { selectedPairId = nil }
            } else {
                onMismatch()
                triggerMismatch(for: value)
            }
        } label: {
            numberCardFill(
                value: value,
                textColor: isMatched ? MatherTheme.softBlue : MatherTheme.ink,
                background: isMatched
                    ? MatherTheme.softBlue.opacity(0.15)
                    : (isActivated ? MatherTheme.softBlue.opacity(0.18) : Color.secondary.opacity(0.08)),
                strokeColor: isMatched
                    ? MatherTheme.softBlue
                    : (isActivated ? MatherTheme.softBlue.opacity(0.6) : Color.secondary.opacity(0.3)),
                strokeWidth: 3,
                dashed: !isMatched && !isActivated
            )
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .frame(width: cardSize, height: cardSize)
        .offset(x: isWobbling ? 8 : 0)
        .animation(
            isWobbling
                ? .easeInOut(duration: 0.08).repeatCount(5, autoreverses: true)
                : .default,
            value: isWobbling
        )
        .accessibilityLabel("\(value)\(isMatched ? ", matched" : "")")
        .accessibilityIdentifier("bond-right-\(value)")
    }

    // MARK: - Shared card fill

    @ViewBuilder
    private func numberCardFill(
        value: Int,
        textColor: Color,
        background: Color,
        strokeColor: Color,
        strokeWidth: CGFloat,
        dashed: Bool
    ) -> some View {
        Text("\(value)")
            .font(.system(size: 38, weight: .black, design: .rounded))
            .foregroundStyle(textColor)
            .frame(width: cardSize, height: cardSize)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            dash: dashed ? [7, 4] : []
                        )
                    )
            )
    }

    private func columnLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(height: 20)
    }

    // MARK: - Private helpers

    private func setupShuffledOrder() {
        shuffledRightValues = state.pairs.map(\.right).shuffled()
    }

    /// Re-shuffle only the unmatched right values in place.
    private func shuffleUnmatchedRight() {
        let matched   = Set(state.pairs.filter(\.isMatched).map(\.right))
        var unmatched = shuffledRightValues.filter { !matched.contains($0) }.shuffled()
        shuffledRightValues = shuffledRightValues.map { val in
            matched.contains(val) ? val : unmatched.removeFirst()
        }
    }

    private func triggerMismatch(for value: Int) {
        mismatchedRightValue = value
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            mismatchedRightValue = nil
        }
    }
}
