import SwiftUI

// Rectangle Factory — ages 7–9
// Child drags a corner handle to resize a frame over a dot grid.
// When frameWidth × frameHeight == targetN the rectangle is valid (a factor pair).
// Collecting all factor pairs for a given N advances to the next N in the sequence.
// Shake resets the current frame.
//
// UX improvements over v1:
//  • Smart start: frame opens near √N so child makes small adjustments, not big drags.
//  • Dot-grid thumbnails: found-factors gallery shows mini dot grids, not plain text chips.
//  • Star progress row in header: one ★ per factor pair, filled in as discovered.
//  • Wider grid (8 cols for N > 12) so larger factor pairs like 3×8 are reachable.

struct RectangleFactoryView: View {
    enum CompletionStyle: Equatable {
        case standard
        case prime
    }

    @Bindable var appModel: AppModel

    private static let nSequence: [Int] = [4, 6, 9, 12, 7, 11, 16, 18, 13, 24]

    @State private var sequenceIndex: Int = 0
    @State private var sessionStart: Date = .now
    @State private var targetN: Int = 4
    @State private var foundFactors: Set<String> = []
    @State private var frameWidth: Int = 2
    @State private var frameHeight: Int = 1
    @State private var showEquation: Bool = false
    @State private var lastEquation: String = ""
    @State private var allFoundForN: Bool = false
    @State private var celebratingFactorKey: String?

    // MARK: - Grid constants

    private let dotSize: CGFloat = 22
    private let dotSpacing: CGFloat = 10


    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                Spacer(minLength: 12)
                GeometryReader { geo in
                    factoryBody(in: geo)
                }
                .padding(.horizontal, 20)
                bottomBar
            }
        }
        .onChange(of: appModel.motionService.shakeDetected) { _, shook in
            if shook { resetFrame() }
        }
        .onAppear {
            sessionStart = .now
            loadN(RectangleFactoryView.nSequence[0])
        }
        .onDisappear {
            guard sequenceIndex > 0 else { return }
            appModel.gameSessionStore.save(
                gameName: "Rectangle Factory",
                startedAt: sessionStart,
                scoreValue: sequenceIndex,
                scoreLabel: "numbers factored"
            )
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rectangle Factory")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Make \(targetN) dots fit perfectly")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        // Star progress: one star per factor pair
                        let total = Self.factorsOf(targetN).count
                        HStack(spacing: 3) {
                            ForEach(0..<total, id: \.self) { i in
                                Image(systemName: i < foundFactors.count ? "star.fill" : "star")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(
                                        i < foundFactors.count ? MatherTheme.warm : MatherTheme.warm.opacity(0.3)
                                    )
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: foundFactors.count)
                            }
                        }
                    }

                    Text(Self.instructionText(for: targetN))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            Button {
                appModel.engine.showHome()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Done")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Factory body

    private func factoryBody(in geo: GeometryProxy) -> some View {
        let gridSize = Self.playableGrid(for: targetN)
        let horizontalPadding: CGFloat = 12
        let verticalPadding: CGFloat = 28
        let availableWidth = max(geo.size.width - horizontalPadding * 2, 180)
        let availableHeight = max(geo.size.height - verticalPadding * 2, 180)
        let cellPitch = max(10, floor(min(availableWidth / CGFloat(gridSize.columns), availableHeight / CGFloat(gridSize.rows))))
        let dotDiameter = max(5, min(22, cellPitch * 0.45))
        let frameW = CGFloat(frameWidth) * cellPitch
        let frameH = CGFloat(frameHeight) * cellPitch
        let valid = frameWidth * frameHeight == targetN

        return VStack(spacing: 14) {
            if showEquation {
                Text(lastEquation)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(MatherTheme.card.opacity(0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(MatherTheme.accent.opacity(0.18), lineWidth: 1)
                    )
                    .transition(.scale.combined(with: .opacity))
            }

            VStack(spacing: 10) {
                Text("\(frameWidth) × \(frameHeight) = \(frameWidth * frameHeight)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(valid ? MatherTheme.accent : MatherTheme.ink)
                    .accessibilityLabel("Current rectangle \(frameWidth) by \(frameHeight) equals \(frameWidth * frameHeight)")

                ZStack(alignment: .topLeading) {
                    dotGrid(columns: gridSize.columns, rows: gridSize.rows, dotDiameter: dotDiameter, cellPitch: cellPitch, valid: valid)
                        .frame(width: CGFloat(gridSize.columns) * cellPitch, height: CGFloat(gridSize.rows) * cellPitch)

                    selectionFrame(w: frameW, h: frameH, valid: valid, cellPitch: cellPitch)
                }
                .padding(16)
                .background(MatherTheme.card.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: frameWidth)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: frameHeight)
        .animation(.easeInOut(duration: 0.2), value: showEquation)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func dotGrid(columns: Int, rows: Int, dotDiameter: CGFloat, cellPitch: CGFloat, valid: Bool) -> some View {
        let activeColor: Color = valid ? MatherTheme.accent : MatherTheme.warm

        return VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { col in
                        Circle()
                            .fill(col < frameWidth && row < frameHeight ? activeColor : MatherTheme.ink.opacity(0.18))
                            .frame(width: dotDiameter, height: dotDiameter)
                            .frame(width: cellPitch, height: cellPitch)
                    }
                }
            }
        }
    }

    private func selectionFrame(w: CGFloat, h: CGFloat, valid: Bool, cellPitch: CGFloat) -> some View {
        let borderColor: Color = valid ? MatherTheme.accent : MatherTheme.softBlue
        let borderWidth: CGFloat = valid ? 3 : 2
        let handleSize = max(24, min(40, cellPitch * 1.35))

        return ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderWidth)
                .frame(width: w, height: h)

            Circle()
                .fill(borderColor)
                .frame(width: handleSize, height: handleSize)
                .contentShape(Rectangle())
                .overlay(
                    Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                        .font(.system(size: min(14, handleSize * 0.38), weight: .bold))
                        .foregroundStyle(.white)
                )
                .offset(x: handleSize * 0.35, y: handleSize * 0.35)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDrag(translation: value.translation, cellPitch: cellPitch)
                        }
                        .onEnded { _ in
                            isDragging = false
                            checkValidity()
                        }
                )
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            // Found-factors gallery: mini dot-grid thumbnails
            if !foundFactors.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(foundFactors.sorted(), id: \.self) { key in
                            thumbnailChip(key)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 56)
            }

            if allFoundForN {
                completionPanel
                    .padding(.horizontal, 24)
            }

            Text("Shake to reset frame")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
    }

    private func liveCountBadge(valid: Bool) -> some View {
        Text("\(frameWidth) × \(frameHeight) = \(frameWidth * frameHeight)")
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(valid ? .white : MatherTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(valid ? MatherTheme.accent : MatherTheme.card.opacity(0.96))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(valid ? MatherTheme.accent : MatherTheme.softBlue.opacity(0.35), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
    }

    private var discoveryCallout: some View {
        VStack(alignment: .leading, spacing: 6) {
            if celebratingFactorKey != nil {
                Label("New rectangle!", systemImage: "sparkles")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.coral)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(MatherTheme.coral.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(lastEquation)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(MatherTheme.card.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var completionPanel: some View {
        let style = Self.completionStyle(for: targetN)

        return Group {
            if style == .prime {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(MatherTheme.warm)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(Self.completionTitle(for: targetN))
                                .font(.headline.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                            Text("Only 1×\(targetN) works, so \(targetN) is special.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }

                        Spacer(minLength: 0)
                    }

                    Button(action: advanceToNextN) {
                        Text(Self.advanceButtonTitle(hasNext: sequenceIndex + 1 < RectangleFactoryView.nSequence.count))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(MatherTheme.coral)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    MatherTheme.warm.opacity(0.22),
                                    MatherTheme.coral.opacity(0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(MatherTheme.warm.opacity(0.35), lineWidth: 1.5)
                )
            } else {
                Button(action: advanceToNextN) {
                    Text(Self.advanceButtonTitle(hasNext: sequenceIndex + 1 < RectangleFactoryView.nSequence.count))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MatherTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    /// Mini dot-grid thumbnail chip with dimensions label.
    /// Shows up to 4 rows × 6 cols of dots to stay compact.
    private func thumbnailChip(_ key: String) -> some View {
        let parts = key.split(separator: "x").compactMap { Int($0) }
        guard parts.count == 2 else { return AnyView(EmptyView()) }
        let rows = parts[0]    // smaller dimension → rows
        let cols = parts[1]    // larger dimension → cols
        let displayRows = min(rows, 4)
        let displayCols = min(cols, 6)

        return AnyView(
            HStack(spacing: 7) {
                // Mini dot grid
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(0..<displayRows, id: \.self) { _ in
                        HStack(spacing: 2) {
                            ForEach(0..<displayCols, id: \.self) { _ in
                                Circle()
                                    .fill(MatherTheme.accent)
                                    .frame(width: 5, height: 5)
                            }
                            if cols > 6 {
                                Text("⋯")
                                    .font(.system(size: 5))
                                    .foregroundStyle(MatherTheme.accent.opacity(0.6))
                            }
                        }
                    }
                    if rows > 4 {
                        Text("⋮")
                            .font(.system(size: 5))
                            .foregroundStyle(MatherTheme.accent.opacity(0.6))
                    }
                }
                // Dimension label
                Text("\(rows)×\(cols)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                key == celebratingFactorKey
                    ? LinearGradient(
                        colors: [MatherTheme.warm.opacity(0.34), MatherTheme.coral.opacity(0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [MatherTheme.accent.opacity(0.15), MatherTheme.accent.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .overlay(alignment: .topTrailing) {
                if key == celebratingFactorKey {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(MatherTheme.coral)
                        .offset(x: 4, y: -4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(key == celebratingFactorKey ? 1.08 : 1)
            .shadow(
                color: key == celebratingFactorKey ? MatherTheme.coral.opacity(0.22) : .clear,
                radius: 10,
                y: 4
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.58), value: celebratingFactorKey)
        )
    }

    // MARK: - Drag handling

    @State private var isDragging = false
    @State private var dragStartW: Int = 2
    @State private var dragStartH: Int = 1

    private func handleDrag(translation: CGSize, cellPitch: CGFloat) {
        if !isDragging {
            isDragging = true
            dragStartW = frameWidth
            dragStartH = frameHeight
        }

        let gridSize = Self.playableGrid(for: targetN)
        let newW = max(1, min(dragStartW + Int((translation.width / cellPitch).rounded()), gridSize.columns))
        let newH = max(1, min(dragStartH + Int((translation.height / cellPitch).rounded()), gridSize.rows))
        if newW != frameWidth || newH != frameHeight {
            frameWidth = newW
            frameHeight = newH
            showEquation = false
        }
    }

    // MARK: - Game logic

    private func checkValidity() {
        guard frameWidth * frameHeight == targetN else { return }
        let key = Self.factorKey(frameWidth, frameHeight)
        guard !foundFactors.contains(key) else { return }
        foundFactors.insert(key)
        celebratingFactorKey = key
        lastEquation = "\(min(frameWidth, frameHeight)) × \(max(frameWidth, frameHeight)) = \(targetN)"
        showEquation = true
        appModel.hapticsService.cardSnapCorrect(enabled: appModel.featureFlags.hapticsEnabled)
        appModel.speechService.speak(
            "\(min(frameWidth, frameHeight)) times \(max(frameWidth, frameHeight)) equals \(targetN)!",
            enabled: appModel.featureFlags.audioEnabled
        )
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            showEquation = false
            celebratingFactorKey = nil
            checkAllFound()
        }
    }

    private func checkAllFound() {
        let allFactors = Self.factorsOf(targetN)
        guard foundFactors.count >= allFactors.count else { return }
        allFoundForN = true
        appModel.hapticsService.bondMatchComplete(enabled: appModel.featureFlags.hapticsEnabled)
        appModel.speechService.speak(
            Self.completionSpeech(for: targetN),
            enabled: appModel.featureFlags.audioEnabled
        )
    }

    private func advanceToNextN() {
        let next = sequenceIndex + 1
        guard next < RectangleFactoryView.nSequence.count else {
            appModel.engine.showHome()
            return
        }
        sequenceIndex = next
        loadN(RectangleFactoryView.nSequence[next])
    }

    /// Load a new target N, starting the frame near √N so the child
    /// makes small adjustments rather than dragging from 1×1.
    private func loadN(_ n: Int) {
        targetN = n
        foundFactors = []
        allFoundForN = false
        showEquation = false
        celebratingFactorKey = nil
        let start = Self.smartStartDimensions(for: n)
        frameWidth  = start.width
        frameHeight = start.height
    }

    private func resetFrame() {
        let start = Self.smartStartDimensions(for: targetN)
        frameWidth  = start.width
        frameHeight = start.height
        showEquation = false
        celebratingFactorKey = nil
    }

    // MARK: - Static helpers

    /// Canonical factor key: smaller dimension first so 3×4 and 4×3 hash identically.
    nonisolated static func factorKey(_ a: Int, _ b: Int) -> String {
        "\(min(a, b))x\(max(a, b))"
    }

    /// All distinct canonical factor pairs for n.
    nonisolated static func factorsOf(_ n: Int) -> Set<String> {
        var result = Set<String>()
        for i in 1...n where n % i == 0 {
            result.insert(factorKey(i, n / i))
        }
        return result
    }

    nonisolated static func completionStyle(for n: Int) -> CompletionStyle {
        factorsOf(n).count == 1 ? .prime : .standard
    }

    nonisolated static func completionTitle(for n: Int) -> String {
        completionStyle(for: n) == .prime ? "Prime discovery!" : "All rectangles found!"
    }

    nonisolated static func completionSpeech(for n: Int) -> String {
        let count = factorsOf(n).count
        let noun = count == 1 ? "rectangle" : "rectangles"
        return completionStyle(for: n) == .prime
            ? "\(n) is prime. Only one rectangle works!"
            : "You found all \(count) \(noun) for \(n)!"
    }

    nonisolated static func instructionText(for n: Int) -> String {
        "Drag the blue corner to resize the box. Cover exactly \(n) dots."
    }

    nonisolated static func advanceButtonTitle(hasNext: Bool) -> String {
        hasNext ? "Next Number →" : "All done! 🎉"
    }

    /// Starting frame dimensions: one cell wider than the square-root floor,
    /// one cell shorter — visually near the centre of the dot grid but not
    /// on a valid factor pair.  Edge-case checked so it never accidentally
    /// land on the answer.
    nonisolated static func playableGrid(for n: Int) -> (columns: Int, rows: Int) {
        var maxColumns = 1
        var maxRows = 1

        for key in factorsOf(n) {
            let parts = key.split(separator: "x").compactMap { Int($0) }
            guard parts.count == 2 else { continue }
            maxRows = max(maxRows, parts[0])
            maxColumns = max(maxColumns, parts[1])
        }

        return (columns: maxColumns, rows: maxRows)
    }

    nonisolated static func smartStartDimensions(for n: Int) -> (width: Int, height: Int) {
        let grid = playableGrid(for: n)
        let side = max(1, Int(Double(n).squareRoot().rounded(.down)))
        var width = min(max(2, side + 1), grid.columns)
        var height = min(max(1, side), grid.rows)

        if width * height == n {
            if width < grid.columns {
                width += 1
            } else if height > 1 {
                height -= 1
            }
        }

        return (width: width, height: height)
    }
}
