import SwiftUI

/// Bond Blast — the sensor-powered complement-match finale stage for VS1.
///
/// Displays all complement pairs for the session target (e.g. for 7:
/// 1+6, 2+5, 3+4). The child can tap a left card, then tap the matching
/// right card to lock the pair. Dragging a left card previews the target lane,
/// but correctness is only confirmed against the actual right-slot landing row.
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
    let storyPrompt: NumberStoryPrompt?
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
    /// Cancels stale mismatch animation resets when Bond Blast exits or restarts.
    @State private var mismatchResetTask: Task<Void, Never>? = nil
    @State private var mismatchResetRevision = 0
    @State private var consumedCurrentClap = false

    enum DragReleaseResolution: Equatable {
        case cancel
        case match(UUID)
        case mismatch(Int)
    }

    // MARK: - Constants

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var cardSize: CGFloat { ResponsiveLayout.isWide(horizontalSizeClass) ? 110 : 88 }
    private let cardSpacing: CGFloat = 12
    private var compactPairsMaxHeight: CGFloat? {
        ResponsiveLayout.isWide(horizontalSizeClass) ? nil : 408
    }

    private var vocabulary: NumberStoryStageVocabulary {
        if let storyPrompt {
            return NumberStoryStageVocabulary.vocabulary(for: storyPrompt, stage: .bondBlast)
        }
        return NumberStoryStageVocabulary.fallback(stage: .bondBlast, target: state.target)
    }

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
                reachablePairsGrid
                progressDots
            }
            .frame(maxWidth: 660, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, alignment: .center)
        .onAppear {
            reconcileShuffledOrder()
        }
        .onChange(of: state.pairs.map(\.right)) { _, _ in
            reconcileShuffledOrder()
        }
        .onChange(of: shakeDetected) { _, shook in
            guard shook else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                shuffleUnmatchedRight()
            }
            onShakeHandled()
        }
        .onChange(of: clapDetected) { _, clapped in
            handleClapChange(clapped)
        }
        .onChange(of: state.isComplete) { _, isComplete in
            guard isComplete else { return }
            handleCompletionChange()
        }
        .sensoryFeedback(.success, trigger: state.matchCount)
        .accessibilityLabel("\(vocabulary.accessibilityLabel) \(state.matchCount) of \(state.pairs.count) matched.")
        .onDisappear {
            cancelMismatchReset()
            consumedCurrentClap = false
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 6) {
            Text(vocabulary.title)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.accent)
                .accessibilityAddTraits(.isHeader)
            Text(vocabulary.targetReminder)
                .font(.title2.weight(.bold))
                .foregroundStyle(MatherTheme.warm)
            Text(selectedPairId == nil ? vocabulary.instruction : "Now find its match")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var reachablePairsGrid: some View {
        ScrollView(.vertical) {
            pairsGrid
                .padding(.vertical, 2)
        }
        .scrollIndicators(.visible)
        .frame(maxHeight: compactPairsMaxHeight)
        .frame(maxWidth: .infinity)
    }

    private var pairsGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: selectable source cards
            VStack(spacing: cardSpacing) {
                columnLabel(vocabulary.leftLabel)
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
                columnLabel(vocabulary.rightLabel)
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
                    value: String(pair.left),
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
                    let resolution = Self.dragReleaseResolution(
                        pair: pair,
                        translation: value.translation,
                        state: state,
                        shuffledRightValues: shuffledRightValues,
                        cardSize: cardSize,
                        cardSpacing: cardSpacing
                    )
                    switch resolution {
                    case .cancel:
                        break
                    case .match(let id):
                        onNearTarget()
                        onMatch(id)
                        withAnimation(.spring(response: 0.2)) { selectedPairId = nil }
                    case .mismatch(let rightValue):
                        onMismatch()
                        triggerMismatch(for: rightValue)
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
        let shownValue = Self.visibleRightValue(
            selectedPairId: selectedPairId,
            rightValue: value,
            state: state
        )

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
                value: shownValue.map(String.init) ?? "?",
                textColor: isMatched
                    ? MatherTheme.softBlue
                    : (shownValue == nil ? .secondary : MatherTheme.ink),
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
        .accessibilityLabel(shownValue.map { "\($0)\(isMatched ? ", matched" : "")" } ?? "Hidden match")
        .accessibilityIdentifier("bond-right-\(value)")
    }

    // MARK: - Shared card fill

    nonisolated static func visibleRightValue(
        selectedPairId: UUID?,
        rightValue: Int,
        state: BondMatchState
    ) -> Int? {
        let isMatched = state.pairs.first(where: { $0.right == rightValue })?.isMatched == true
        return (selectedPairId != nil || isMatched) ? rightValue : nil
    }

    nonisolated static func dragReleaseResolution(
        pair: ComplementPair,
        translation: CGSize,
        state: BondMatchState,
        shuffledRightValues: [Int],
        cardSize: CGFloat,
        cardSpacing: CGFloat
    ) -> DragReleaseResolution {
        let horizontalTravel = translation.width
        guard horizontalTravel > 90 else {
            return .cancel
        }

        guard let sourceRow = state.pairs.firstIndex(where: { $0.id == pair.id }), !shuffledRightValues.isEmpty else {
            return .cancel
        }

        let rowStride = cardSize + cardSpacing
        let rowOffset = Int((translation.height / rowStride).rounded())
        let targetRow = min(max(sourceRow + rowOffset, 0), shuffledRightValues.count - 1)
        let droppedValue = shuffledRightValues[targetRow]

        return droppedValue == pair.right ? .match(pair.id) : .mismatch(droppedValue)
    }

    @ViewBuilder
    private func numberCardFill(
        value: String,
        textColor: Color,
        background: Color,
        strokeColor: Color,
        strokeWidth: CGFloat,
        dashed: Bool
    ) -> some View {
        Text(value)
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

    private func reconcileShuffledOrder() {
        let rightValues = state.pairs.map(\.right)
        guard Self.rightOrderNeedsReset(existingRightValues: shuffledRightValues, pairRightValues: rightValues) else { return }
        shuffledRightValues = rightValues.shuffled()
    }

    nonisolated static func rightOrderNeedsReset(existingRightValues: [Int], pairRightValues: [Int]) -> Bool {
        existingRightValues.count != pairRightValues.count || Set(existingRightValues) != Set(pairRightValues)
    }

    nonisolated static func shuffledUnmatchedRightValues(
        existingRightValues: [Int],
        matchedRightValues: Set<Int>,
        shuffle: ([Int]) -> [Int] = { $0.shuffled() }
    ) -> [Int] {
        var unmatched = shuffle(existingRightValues.filter { !matchedRightValues.contains($0) })
        return existingRightValues.map { value in
            guard !matchedRightValues.contains(value) else { return value }
            return unmatched.isEmpty ? value : unmatched.removeFirst()
        }
    }

    /// Re-shuffle only the unmatched right values in place.
    private func shuffleUnmatchedRight() {
        let matched = Set(state.pairs.filter(\.isMatched).map(\.right))
        shuffledRightValues = Self.shuffledUnmatchedRightValues(
            existingRightValues: shuffledRightValues,
            matchedRightValues: matched
        )
    }

    private func triggerMismatch(for value: Int) {
        mismatchResetTask?.cancel()
        mismatchResetRevision &+= 1
        let revision = mismatchResetRevision
        mismatchedRightValue = value
        mismatchResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled,
                  Self.shouldAcceptDelayedMismatchReset(scheduledRevision: revision, currentRevision: mismatchResetRevision) else { return }
            mismatchedRightValue = nil
            mismatchResetTask = nil
        }
    }

    private func cancelMismatchReset() {
        mismatchResetRevision &+= 1
        mismatchResetTask?.cancel()
        mismatchResetTask = nil
        mismatchedRightValue = nil
    }

    nonisolated static func shouldAcceptDelayedMismatchReset(scheduledRevision: Int, currentRevision: Int) -> Bool {
        scheduledRevision == currentRevision
    }

    private func handleClapChange(_ clapped: Bool) {
        guard clapped else {
            consumedCurrentClap = false
            return
        }
        consumeClapIfNeeded()
    }

    private func handleCompletionChange() {
        guard clapDetected else { return }
        consumeClapIfNeeded()
    }

    private func consumeClapIfNeeded() {
        guard Self.shouldConsumeClap(clapDetected: clapDetected, alreadyConsumed: consumedCurrentClap) else { return }
        consumedCurrentClap = true
        onClapHandled()
    }

    nonisolated static func shouldConsumeClap(clapDetected: Bool, alreadyConsumed: Bool) -> Bool {
        clapDetected && !alreadyConsumed
    }
}
