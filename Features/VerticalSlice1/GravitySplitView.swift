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
    let onReset: () -> Void
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

    private var splitEquation: String {
        "Split \(state.target) into two parts"
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
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                headerText
                Spacer(minLength: 8)
                compactActionRail
            }

            VStack(alignment: .leading, spacing: 10) {
                headerText
                compactActionRail
            }
        }
    }

    private var headerText: some View {
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
    }

    private var compactActionRail: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if state.isLocked {
                Text("⭐️")
                    .font(.system(size: 34))
                    .scaleEffect(lockScale)
                    .transition(.scale.combined(with: .opacity))

                Button("Next") {
                    onSubmit()
                }
                .font(.caption.weight(.black))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier("gravity-split-next-button")
            } else {
                Button {
                    onReset()
                } label: {
                    Label("Clear", systemImage: "arrow.counterclockwise")
                        .labelStyle(.titleAndIcon)
                }
                .font(.caption.weight(.black))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(state.leftCount == 0 && state.rightCount == 0)
                .accessibilityIdentifier("gravity-split-clear-button")
            }
        }
    }

    private var liveCountRow: some View {
        HStack(spacing: 7) {
            counterPill(value: state.leftCount, fill: MatherTheme.warm)
            Text("+").font(.headline.weight(.black)).foregroundStyle(.secondary)
            counterPill(value: state.rightCount, fill: MatherTheme.accent)
            Text("=").font(.headline.weight(.black)).foregroundStyle(.secondary)
            Text("\(state.target)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
        }
    }

    private func counterPill(value: Int, fill: Color) -> some View {
        Text("\(value)")
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
            seesawBalancePreview

            ViewThatFits(in: .horizontal) {
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

                VStack(spacing: 10) {
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
        }
        .accessibilityIdentifier("gravity-direct-token-board")
    }


    private var seesawBalancePreview: some View {
        let totalPlaced = max(1, state.leftCount + state.rightCount)
        let tilt = CGFloat(state.rightCount - state.leftCount) / CGFloat(totalPlaced)
        let rotation = Double(max(-0.16, min(0.16, tilt)) * 18)

        return VStack(spacing: 4) {
            ZStack(alignment: .center) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [MatherTheme.warm.opacity(0.86), MatherTheme.accent.opacity(0.86)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 12)
                    .overlay(
                        Capsule()
                            .strokeBorder(MatherTheme.ink.opacity(0.10), lineWidth: 1)
                    )
                    .rotationEffect(.degrees(rotation))
                    .animation(.spring(response: 0.32, dampingFraction: 0.72), value: state.leftCount)
                    .animation(.spring(response: 0.32, dampingFraction: 0.72), value: state.rightCount)

                GravitySplitTrianglePivot()
                    .fill(MatherTheme.ink.opacity(0.18))
                    .frame(width: 34, height: 24)
                    .offset(y: 17)

                HStack {
                    balancePan(label: vocabulary.leftLabel, count: state.leftCount, fill: MatherTheme.warm)
                    Spacer(minLength: 34)
                    balancePan(label: vocabulary.rightLabel, count: state.rightCount, fill: MatherTheme.accent)
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 58)

            Text(state.isLocked ? "See-saw balanced" : "Balance the see-saw")
                .font(.caption2.weight(.black))
                .foregroundStyle(state.isLocked ? MatherTheme.accent : MatherTheme.cardSubtitle)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(MatherTheme.panel.opacity(0.56), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lever see-saw balance. Left side has \(state.leftCount), right side has \(state.rightCount).")
        .accessibilityIdentifier("gravity-seesaw-balance-preview")
    }

    private func balancePan(label: String, count: Int, fill: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.caption.weight(.black))
                .foregroundStyle(fill)
                .frame(width: 34, height: 26)
                .background(fill.opacity(0.13), in: Circle())
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
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

            quantityDisplay(
                count: sourceCount,
                fill: MatherTheme.softBlue,
                prefix: "source",
                isInteractive: false
            ) { _ in }
            .frame(minHeight: state.usesGroupedRepresentation ? 50 : 36)
            .accessibilityLabel("Unused tokens: \(sourceCount)")
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
                Text("\(count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(fill)
            }

            quantityDisplay(count: count, fill: fill, prefix: side == .left ? "left" : "right", isInteractive: true) { _ in
                guard !state.isLocked else { return }
                onTap(-1, side)
            }
            .frame(minHeight: state.usesGroupedRepresentation ? 54 : 68, alignment: .topLeading)

            addTokenControl(label: label, count: count, target: target, fill: fill, side: side)
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

    private func addTokenControl(
        label: String,
        count: Int,
        target: Int,
        fill: Color,
        side: TransferSide
    ) -> some View {
        let sideName = side == .left ? "left" : "right"

        return Group {
            if state.usesGroupedRepresentation {
                groupedStepControls(label: label, fill: fill, side: side)
            } else {
                let canAdd = !state.isLocked && sourceCount > 0 && count < target

                Button {
                    onTap(1, side)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.medium)
                        Text("Add \(label)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .contentShape(Rectangle())
                }
                .font(.caption.weight(.black))
                .foregroundStyle(canAdd ? fill : MatherTheme.cardSubtitle.opacity(0.55))
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(canAdd ? fill.opacity(0.10) : Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(canAdd ? fill.opacity(0.34) : Color.secondary.opacity(0.16), lineWidth: 1)
                )
                .buttonStyle(.plain)
                .disabled(!canAdd)
                .opacity(canAdd ? 1 : 0.72)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Add \(label)")
                .accessibilityHint(canAdd ? "Adds one token to the \(label) side." : "This side cannot accept more tokens right now.")
                .accessibilityIdentifier("gravity-\(sideName)-add-button")
            }
        }
    }

    private func groupedStepControls(label: String, fill: Color, side: TransferSide) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ForEach(state.groupedStepValues, id: \.self) { step in
                    stepButton(
                        label: "+\(step)",
                        accessibilityLabel: "Add \(step) to \(label)",
                        enabled: groupedStepDelta(step, side: side) == step,
                        fill: fill
                    ) {
                        onTap(step, side)
                    }
                }
            }

            HStack(spacing: 6) {
                ForEach(state.groupedStepValues, id: \.self) { step in
                    stepButton(
                        label: "-\(step)",
                        accessibilityLabel: "Remove \(step) from \(label)",
                        enabled: state.currentCount(for: side) >= step && !state.isLocked,
                        fill: fill
                    ) {
                        onTap(-step, side)
                    }
                }
            }
        }
        .accessibilityIdentifier("gravity-\(side == .left ? "left" : "right")-grouped-controls")
    }

    private func groupedStepDelta(_ step: Int, side: TransferSide) -> Int {
        guard !state.isLocked else { return 0 }
        return min(step, sourceCount, state.remainingCapacity(for: side))
    }

    private func stepButton(
        label: String,
        accessibilityLabel: String,
        enabled: Bool,
        fill: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.black))
                .frame(maxWidth: .infinity, minHeight: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? fill : MatherTheme.cardSubtitle.opacity(0.55))
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(enabled ? fill.opacity(0.10) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(enabled ? fill.opacity(0.34) : Color.secondary.opacity(0.16), lineWidth: 1)
        )
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.72)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func tokenGrid(
        count: Int,
        fill: Color,
        prefix: String,
        isInteractive: Bool,
        action: @escaping (Int) -> Void
    ) -> some View {
        let columns = Array(repeating: GridItem(.fixed(34), spacing: 2), count: compactColumnCount(for: max(count, 1)))

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 2) {
            ForEach(0..<count, id: \.self) { idx in
                if isInteractive {
                    Button {
                        action(idx)
                    } label: {
                        tokenCircle(fill: fill)
                    }
                    .buttonStyle(.plain)
                    .disabled(state.isLocked)
                    .accessibilityLabel("Remove token")
                    .accessibilityIdentifier("gravity-\(prefix)-token-\(idx)")
                } else {
                    tokenCircle(fill: fill)
                        .accessibilityLabel("Unused token")
                        .accessibilityIdentifier("gravity-\(prefix)-token-\(idx)")
                }
            }
        }
    }

    @ViewBuilder
    private func quantityDisplay(
        count: Int,
        fill: Color,
        prefix: String,
        isInteractive: Bool,
        action: @escaping (Int) -> Void
    ) -> some View {
        if state.usesGroupedRepresentation {
            GroupedNumberView(value: count, fill: fill)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("gravity-\(prefix)-grouped-number")
        } else {
            tokenGrid(count: count, fill: fill, prefix: prefix, isInteractive: isInteractive, action: action)
        }
    }


    private func tokenCircle(fill: Color) -> some View {
        Circle()
            .fill(fill)
            .overlay(Circle().strokeBorder(.white.opacity(0.75), lineWidth: 1.25))
            .shadow(color: fill.opacity(0.18), radius: 1.5, y: 1)
            .frame(width: 24, height: 24)
            .frame(width: 34, height: 34)
            .contentShape(Circle())
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
            Text("Tap Add on each side until the equation is complete: \(state.leftCount) + \(state.rightCount) = \(state.target). Use Clear to try again.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}


private struct GravitySplitTrianglePivot: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
