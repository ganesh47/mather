import SwiftUI

// Rectangle Factory — ages 7–9
// Child drags a corner handle to resize a frame over a dot grid.
// When frameWidth × frameHeight == targetN the rectangle is valid (a factor pair).
// Collecting all factor pairs for a given N advances to the next N in the sequence.
// Shake resets the current frame.

struct RectangleFactoryView: View {
    @Bindable var appModel: AppModel

    // N progression: mix of composites and primes so child encounters "only one rectangle" moments
    private static let nSequence: [Int] = [4, 6, 9, 12, 7, 11, 16, 18, 13, 24]

    @State private var sequenceIndex: Int = 0
    @State private var targetN: Int = 4
    @State private var foundFactors: Set<String> = []
    @State private var frameWidth: Int = 1
    @State private var frameHeight: Int = 1
    @State private var showEquation: Bool = false
    @State private var lastEquation: String = ""
    @State private var allFoundForN: Bool = false

    // Grid layout constants
    private let dotSize: CGFloat = 22
    private let dotSpacing: CGFloat = 10
    private let gridColumns: Int = 6   // dots per row

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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rectangle Factory")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("Make \(targetN) dots fit perfectly")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
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

            // Equation label (floats above top-right of frame)
            if showEquation {
                Text(lastEquation)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(MatherTheme.card.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            // Frame border
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
            // Found factor chips
            if !foundFactors.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(foundFactors.sorted(), id: \.self) { key in
                            factorChip(key)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 40)
            }

            if allFoundForN {
                Button(action: advanceToNextN) {
                    Text(sequenceIndex + 1 < RectangleFactoryView.nSequence.count ? "Next Number →" : "All done! 🎉")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MatherTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
            }

            Text("Shake to reset frame")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
    }

    private func factorChip(_ key: String) -> some View {
        let parts = key.split(separator: "x").compactMap { Int($0) }
        let label = parts.count == 2 ? "\(parts[0]) × \(parts[1]) = \(targetN)" : key
        return Text(label)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(MatherTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(MatherTheme.accent.opacity(0.15))
            .clipShape(Capsule())
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
        let newW = max(1, min(dragStartW + Int((translation.width / cellSize).rounded()), gridColumns))
        let newH = max(1, min(dragStartH + Int((translation.height / cellSize).rounded()), gridColumns))
        if newW != frameWidth || newH != frameHeight {
            frameWidth = newW
            frameHeight = newH
            showEquation = false
        }
    }

    // MARK: - Game logic

    private func checkValidity() {
        guard frameWidth * frameHeight == targetN else { return }
        let key = factorKey(frameWidth, frameHeight)
        guard !foundFactors.contains(key) else { return }
        foundFactors.insert(key)
        lastEquation = "\(min(frameWidth, frameHeight)) × \(max(frameWidth, frameHeight)) = \(targetN)"
        showEquation = true
        appModel.hapticsService.cardSnapCorrect(enabled: appModel.featureFlags.hapticsEnabled)
        appModel.speechService.speak("\(min(frameWidth, frameHeight)) times \(max(frameWidth, frameHeight)) equals \(targetN)!", enabled: appModel.featureFlags.audioEnabled)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            showEquation = false
            checkAllFound()
        }
    }

    private func checkAllFound() {
        let allFactors = Self.factorsOf(targetN)
        if foundFactors.count >= allFactors.count {
            allFoundForN = true
            appModel.hapticsService.bondMatchComplete(enabled: appModel.featureFlags.hapticsEnabled)
            let count = allFactors.count
            let noun = count == 1 ? "rectangle" : "rectangles"
            appModel.speechService.speak(
                count == 1
                    ? "\(targetN) is prime — only one \(noun)!"
                    : "You found all \(count) \(noun) for \(targetN)!",
                enabled: appModel.featureFlags.audioEnabled
            )
        }
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

    private func loadN(_ n: Int) {
        targetN = n
        foundFactors = []
        allFoundForN = false
        showEquation = false
        frameWidth = 1
        frameHeight = 1
    }

    private func resetFrame() {
        frameWidth = 1
        frameHeight = 1
        showEquation = false
    }

    // MARK: - Helpers

    /// Canonical factor key: smaller dimension first so 3×4 and 4×3 hash identically.
    static func factorKey(_ a: Int, _ b: Int) -> String {
        "\(min(a, b))x\(max(a, b))"
    }

    /// All distinct canonical factor pairs for n (excluding 1×n when n is prime — included).
    static func factorsOf(_ n: Int) -> Set<String> {
        var result = Set<String>()
        for i in 1...n {
            if n % i == 0 {
                result.insert(factorKey(i, n / i))
            }
        }
        return result
    }
}

