import SwiftUI

/// Balance-scale stage where the child uses plus and minus controls to build
/// the requested split from zero.
///
/// Tilt is ignored in V1 loop mode and kept only for future polish hooks.
/// When `state.isLocked` becomes true the view auto-advances after 0.6 s.
struct GravitySplitView: View {

    // MARK: - Inputs

    let state: GravitySplitState
    let tiltRoll: Double
    let shakeDetected: Bool
    let onAdjustTilt: (Double) -> Void
    let onTap: (Int, TransferSide) -> Void
    let onShakeHandled: () -> Void
    let onSubmit: () -> Void

    // MARK: - Local animation state

    @State private var lockScale: CGFloat = 1.0
    /// True until the child taps GO, keeping tilt locked while they get steady.
    @State private var showGoScrim = true

    // MARK: - Constants

    private let maxBeamAngle: Double = 0.22   // radians ≈ 12.6°

    // MARK: - Derived

    /// Beam rotation in radians. Left-heavy → clockwise (left pan descends).
    private var beamAngle: Double {
        guard state.target > 0 else { return 0 }
        if state.isLocked { return 0 }
        let solvedBias = Double(state.decompositionA - state.decompositionB) / Double(max(state.target, 1))
        let builtBias = Double(state.leftCount - state.rightCount) / Double(max(state.target, 1))
        return (solvedBias - builtBias) * maxBeamAngle
    }

    // MARK: - Body

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 16) {
                headerRow
                balanceSceneView
                tapControlRow
                if !state.isLocked {
                    instructionText
                }
            }
        }
        .onChange(of: tiltRoll) { _, roll in
            guard !showGoScrim else { return }
            onAdjustTilt(roll)
        }
        .onChange(of: shakeDetected) { _, shook in
            guard shook else { return }
            onShakeHandled()
        }
        .onChange(of: state.decompositionA) { _, _ in
            // New problem arrived — show GO scrim again for the fresh stage.
            showGoScrim = true
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
            "Balance scale. Make \(state.target). Left: \(state.leftCount). Right: \(state.rightCount)."
        )
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gravity Split")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.coral)

                HStack(spacing: 8) {
                    counterPill(value: state.leftCount, fill: MatherTheme.warm)
                    Text("+").font(.title3.weight(.black)).foregroundStyle(.secondary)
                    counterPill(value: state.rightCount, fill: MatherTheme.accent)
                    Text("/").font(.title3.weight(.black)).foregroundStyle(.secondary)
                    Text("\(state.decompositionA) + \(state.decompositionB)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                }
            }

            Spacer()

            if state.isLocked {
                Text("⭐️")
                    .font(.system(size: 44))
                    .scaleEffect(lockScale)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func counterPill(value: Int, fill: Color) -> some View {
        Text("\(value)")
            .font(.system(size: 26, weight: .black, design: .rounded))
            .foregroundStyle(fill)
            .frame(minWidth: 52, minHeight: 52)
            .background(fill.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(fill.opacity(0.28), lineWidth: 1.5)
            )
    }

    // MARK: - Balance scene

    private var balanceSceneView: some View {
        ZStack(alignment: .bottom) {
            // Pivot triangle
            pivotTriangle
                .frame(width: 32, height: 22)
                .offset(y: 0)

            // Beam + pans, rotated as a unit
            HStack(spacing: 0) {
                panView(count: state.leftCount, fill: MatherTheme.warm, side: "left")
                    .frame(maxWidth: .infinity)

                // Beam bar
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(MatherTheme.ink.opacity(0.72))
                    .frame(width: 44, height: 10)

                panView(count: state.rightCount, fill: MatherTheme.accent, side: "right")
                    .frame(maxWidth: .infinity)
            }
            .rotationEffect(.radians(beamAngle), anchor: .bottom)
            .animation(.interpolatingSpring(stiffness: 100, damping: 16), value: beamAngle)
            .offset(y: -22)

            // "Hold steady — GO!" overlay. Blocks tilt until the child is ready,
            // preventing accidental solves before they understand the mechanic.
            if showGoScrim {
                goScrimOverlay
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding(.vertical, 4)
    }

    private var goScrimOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
            VStack(spacing: 10) {
                Text("Hold steady…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showGoScrim = false
                    }
                } label: {
                    Label("GO!", systemImage: "gyroscope")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(minWidth: 120, minHeight: 52)
                        .background(MatherTheme.coral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("gravity-go-button")
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var pivotTriangle: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            context.fill(path, with: .color(MatherTheme.ink.opacity(0.55)))
        }
    }

    private func panView(count: Int, fill: Color, side: String) -> some View {
        VStack(spacing: 6) {
            // Counter dots in the pan (up to target, max display 10)
            let display = min(state.target, 10)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5),
                spacing: 4
            ) {
                ForEach(0..<display, id: \.self) { idx in
                    Circle()
                        .fill(idx < count ? fill : fill.opacity(0.15))
                        .overlay(
                            Circle()
                                .strokeBorder(fill.opacity(idx < count ? 0.3 : 0.4), lineWidth: 1.5)
                        )
                        .shadow(color: idx < count ? fill.opacity(0.3) : .clear, radius: 3, y: 1)
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityIdentifier("gravity-\(side)-dot-\(idx)")
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fill.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(fill.opacity(0.22), lineWidth: 1.5)
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tap fallback

    private var tapControlRow: some View {
        HStack(spacing: 12) {
            panControlButtons(
                label: "Left",
                fill: MatherTheme.warm,
                side: "left",
                canDecrement: state.leftCount > 0 && !state.isLocked,
                canIncrement: state.leftCount < state.decompositionA && !state.isLocked
            ) { delta in
                onTap(delta, .left)
            }

            panControlButtons(
                label: "Right",
                fill: MatherTheme.accent,
                side: "right",
                canDecrement: state.rightCount > 0 && !state.isLocked,
                canIncrement: state.rightCount < state.decompositionB && !state.isLocked
            ) { delta in
                onTap(delta, .right)
            }
        }
    }

    private func panControlButtons(
        label: String,
        fill: Color,
        side: String,
        canDecrement: Bool,
        canIncrement: Bool,
        action: @escaping (Int) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Button {
                action(-1)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title.weight(.bold))
                    .frame(minWidth: 48, minHeight: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(canDecrement ? fill : fill.opacity(0.3))
            .disabled(!canDecrement)
            .accessibilityLabel("Remove from \(label.lowercased()) pan")
            .accessibilityIdentifier("gravity-\(side)-minus")

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(fill)
                .frame(minWidth: 38)

            Button {
                action(1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title.weight(.bold))
                    .frame(minWidth: 48, minHeight: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(canIncrement ? fill : fill.opacity(0.3))
            .disabled(!canIncrement)
            .accessibilityLabel("Add to \(label.lowercased()) pan")
            .accessibilityIdentifier("gravity-\(side)-plus")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(fill.opacity(0.08))
        )
    }

    // MARK: - Instruction

    private var instructionText: some View {
        HStack(spacing: 8) {
            Image(systemName: "gyroscope")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.coral.opacity(0.8))
            Text("Use plus and minus to build the split from zero")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
