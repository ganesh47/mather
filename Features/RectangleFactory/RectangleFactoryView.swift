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
    @State private var targetN: Int = 4
    @State private var foundFactors: Set<String> = []
    @State private var frameWidth: Int = 1
    @State private var frameHeight: Int = 1
    @State private var showEquation: Bool = false
    @State private var lastEquation: String = ""
    @State private var allFoundForN: Bool = false
    @State private var celebratingFactorKey: String?

    // MARK: - Grid constants

    private let dotSize: CGFloat = 22
    private let dotSpacing: CGFloat = 10

    /// Wider grid for large N so more factor pairs fit on screen.
    private var gridColumns: Int { targetN > 12 ? 8 : 6 }
    /// Maximum frame dimension the drag handle can reach.
    private var maxFrameDim: Int  { targetN > 12 ? 8 : 6 }

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
            loadN(RectangleFactoryView.nSequence[0])
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rectangle Factory")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
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
        let cellSize = dotSize + dotSpacing
        let rows = Int(ceil(Double(targetN) / Double(gridColumns)))
        let gridW = CGFloat(gridColumns) * cellSize - dotSpacing
        let gridH = CGFloat(rows) * cellSize - dotSpacing
        let frameW = CGFloat(frameWidth) * cellSize - dotSpacing
        let frameH = CGFloat(frameHeight) * cellSize - dotSpacing

        let valid = frameWidth * frameHeight == targetN

        return ZStack(alignment: .topLeading) {
            // Dot grid
            dotGrid(rows: rows, cellSize: cellSize, valid: valid)
                .frame(width: gridW, height: gridH)

            // Selection frame overlay
            selectionFrame(w: frameW, h: frameH, valid: valid, cellSize: cellSize)

            // Equation label (floats above top-right of frame on valid snap)
            if showEquation {
                discoveryCallout
                    .offset(x: frameW + 6, y: 0)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: frameWidth)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: frameHeight)
        .animation(.easeInOut(duration: 0.2), value: showEquation)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func dotGrid(rows: Int, cellSize: CGFloat, valid: Bool) -> some View {
        let activeColor: Color = valid ? MatherTheme.accent : MatherTheme.warm
        return VStack(alignment: .leading, spacing: dotSpacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: dotSpacing) {
                    ForEach(0..<gridColumns, id: \.self) { col in
                        let idx = row * gridColumns + col
                        let inFrame = col < frameWidth && row < frameHeight
                        Circle()
                            .fill(idx < targetN
                                  ? (inFrame ? activeColor : MatherTheme.ink.opacity(0.25))
                                  : Color.clear)
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
    }

    private func selectionFrame(w: CGFloat, h: CGFloat, valid: Bool, cellSize: CGFloat) -> some View {
        let borderColor: Color = valid ? MatherTheme.accent : MatherTheme.softBlue
        let borderWidth: CGFloat = valid ? 3 : 2

        return ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderWidth)
                .frame(width: w, height: h)

            // Corner drag handle
            Circle()
                .fill(borderColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                )
                .offset(x: 14, y: 14)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDrag(translation: value.translation, cellSize: cellSize)
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
    @State private var dragStartW: Int = 1
    @State private var dragStartH: Int = 1

    private func handleDrag(translation: CGSize, cellSize: CGFloat) {
        if !isDragging {
            isDragging = true
            dragStartW = frameWidth
            dragStartH = frameHeight
        }
        let newW = max(1, min(dragStartW + Int((translation.width  / cellSize).rounded()), maxFrameDim))
        let newH = max(1, min(dragStartH + Int((translation.height / cellSize).rounded()), maxFrameDim))
        if newW != frameWidth || newH != frameHeight {
            frameWidth  = newW
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

    nonisolated static func advanceButtonTitle(hasNext: Bool) -> String {
        hasNext ? "Next Number →" : "All done! 🎉"
    }

    /// Starting frame dimensions: one cell wider than the square-root floor,
    /// one cell shorter — visually near the centre of the dot grid but not
    /// on a valid factor pair.  Edge-case checked so it never accidentally
    /// land on the answer.
    nonisolated static func smartStartDimensions(for n: Int) -> (width: Int, height: Int) {
        let s = max(1, Int(sqrt(Double(n)).rounded(.down)))
        var w = s + 1
        var h = max(1, s - 1)
        // Clamp to on-screen grid (8 max)
        w = min(w, 8)
        h = min(h, 8)
        // If this accidentally lands on a valid answer, shift width by 1
        if w * h == n {
            w = min(w + 1, 8)
        }
        return (width: w, height: h)
    }
}
