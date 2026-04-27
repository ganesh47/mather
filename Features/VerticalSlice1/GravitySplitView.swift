import SwiftUI

/// Break It proof stage where the child partitions the already-made target by
/// directly moving compact tokens between a source tray and two independent zones.
///
/// Tilt callbacks are retained for the route contract, but the main child path is
/// touch-first: tap a source token to place it, tap a zone token to send it back.
/// When `state.isLocked` becomes true the view auto-advances after 0.6 s.
struct GravitySplitView: View {

    // MARK: - Inputs

    let state: GravitySplitState
    let storyPrompt: NumberStoryPrompt?
    let tiltRoll: Double
    let shakeDetected: Bool
    let onAdjustTilt: (Double) -> Void
    let onTap: (Int, TransferSide) -> Void
    let onShakeHandled: () -> Void
    let onSubmit: () -> Void

    // MARK: - Local animation state

    @State private var lockScale: CGFloat = 1.0

    // MARK: - Derived

    private var vocabulary: NumberStoryStageVocabulary {
        if let storyPrompt {
            return NumberStoryStageVocabulary.vocabulary(for: storyPrompt, stage: .gravitySplit)
        }
        return NumberStoryStageVocabulary.fallback(stage: .gravitySplit, target: state.target)
    }

    private var sourceCount: Int {
        max(0, state.target - state.leftCount - state.rightCount)
    }

    private var nextOpenSide: TransferSide? {
        if state.leftCount < state.decompositionA { return .left }
        if state.rightCount < state.decompositionB { return .right }
        return nil
    }

    private var splitEquation: String {
        "Split \(state.target) into \(state.decompositionA) and \(state.decompositionB)"
    }

    // MARK: - Body

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                headerRow
                tokenBoard
                if !state.isLocked {
                    instructionText
                }
            }
        }
        .onChange(of: tiltRoll) { _, roll in
            onAdjustTilt(roll)
        }
        .onChange(of: shakeDetected) { _, shook in
            guard shook else { return }
            onShakeHandled()
        }
        .onChange(of: state.isLocked) { _, locked in
            guard locked else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.48)) {
                lockScale = 1.12
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                onSubmit()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Break It. \(splitEquation). \(vocabulary.leftLabel): \(state.leftCount). \(vocabulary.rightLabel): \(state.rightCount). \(sourceCount) left to place."
        )
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(vocabulary.title)
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.coral)

                Text(splitEquation)
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                    .accessibilityIdentifier("gravity-split-equation")

                Text(vocabulary.targetReminder)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.warm)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                liveCountRow
            }

            Spacer()

            if state.isLocked {
                Text("⭐️")
                    .font(.system(size: 40))
                    .scaleEffect(lockScale)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var liveCountRow: some View {
        HStack(spacing: 7) {
            counterPill(value: state.leftCount, target: state.decompositionA, fill: MatherTheme.warm)
            Text("+").font(.headline.weight(.black)).foregroundStyle(.secondary)
            counterPill(value: state.rightCount, target: state.decompositionB, fill: MatherTheme.accent)
            Text("=").font(.headline.weight(.black)).foregroundStyle(.secondary)
            Text("\(state.target)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
        }
    }

    private func counterPill(value: Int, target: Int, fill: Color) -> some View {
        Text("\(value)/\(target)")
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(fill)
            .frame(minWidth: 58, minHeight: 36)
            .background(fill.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(fill.opacity(0.28), lineWidth: 1.5)
            )
    }

    // MARK: - Direct manipulation board

    private var tokenBoard: some View {
        VStack(spacing: 10) {
            sourceTray

            HStack(alignment: .top, spacing: 10) {
                destinationZone(
                    label: vocabulary.leftLabel,
                    count: state.leftCount,
                    target: state.decompositionA,
                    fill: MatherTheme.warm,
                    side: .left
                )
                destinationZone(
                    label: vocabulary.rightLabel,
                    count: state.rightCount,
                    target: state.decompositionB,
                    fill: MatherTheme.accent,
                    side: .right
                )
            }
        }
        .accessibilityIdentifier("gravity-direct-token-board")
    }

    private var sourceTray: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Made set")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Spacer()
                Text("\(sourceCount) left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }

            tokenGrid(count: sourceCount, fill: MatherTheme.softBlue, prefix: "source") { _ in
                guard !state.isLocked, let side = nextOpenSide else { return }
                onTap(1, side)
            }
            .frame(minHeight: 44)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MatherTheme.softBlue.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MatherTheme.softBlue.opacity(0.22), lineWidth: 1.5)
                )
        )
        .accessibilityIdentifier("gravity-source-tray")
    }

    private func destinationZone(
        label: String,
        count: Int,
        target: Int,
        fill: Color,
        side: TransferSide
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(fill)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Text("\(count)/\(target)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(fill)
            }

            tokenGrid(count: count, fill: fill, prefix: side == .left ? "left" : "right") { _ in
                guard !state.isLocked else { return }
                onTap(-1, side)
            }
            .frame(minHeight: 86, alignment: .topLeading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(fill.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(fill.opacity(count == target ? 0.45 : 0.20), lineWidth: 1.5)
                )
        )
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("gravity-\(side == .left ? "left" : "right")-zone")
    }

    private func tokenGrid(
        count: Int,
        fill: Color,
        prefix: String,
        action: @escaping (Int) -> Void
    ) -> some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: 22, maximum: 30), spacing: 5), count: compactColumnCount(for: max(count, 1)))

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
            ForEach(0..<count, id: \.self) { idx in
                Button {
                    action(idx)
                } label: {
                    Circle()
                        .fill(fill)
                        .overlay(Circle().strokeBorder(.white.opacity(0.75), lineWidth: 1.5))
                        .shadow(color: fill.opacity(0.24), radius: 2, y: 1)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .disabled(state.isLocked)
                .accessibilityLabel(prefix == "source" ? "Move token" : "Remove token")
                .accessibilityIdentifier("gravity-\(prefix)-token-\(idx)")
            }
        }
    }

    private func compactColumnCount(for count: Int) -> Int {
        switch state.target {
        case 0...6: return min(max(count, 1), 6)
        case 7...12: return 6
        default: return 8
        }
    }

    // MARK: - Instruction

    private var instructionText: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.coral.opacity(0.8))
            Text(vocabulary.instruction)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
