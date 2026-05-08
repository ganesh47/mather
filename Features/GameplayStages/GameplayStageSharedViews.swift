import SwiftUI

struct GameplayStageTitle: View {
    let title: String
    let prompt: String
    let detail: String

    init(stage: GameplayStageDefinition, detail: String) {
        self.title = stage.title
        self.prompt = stage.prompt
        self.detail = detail
    }

    init(title: String, prompt: String, detail: String = "") {
        self.title = title
        self.prompt = prompt
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(MatherTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(prompt)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink.opacity(0.72))
            }
            Spacer()
            if !detail.isEmpty {
                Text(detail)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(MatherTheme.softBlue.opacity(0.5)))
            }
        }
    }
}

struct GameplayStagePanel: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(MatherTheme.panel.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(MatherTheme.panelDeep.opacity(0.18), lineWidth: 1)
            )
    }
}

struct GameplayDisplayCard: View {
    let item: GameplayDisplayItem
    let compact: Bool
    var showsSubtitle = true
    var selected = false
    var matched = false
    var concealed = false
    var prominence: GameplayDisplayCardProminence = .normal

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            GameplayDisplayVisual(
                item: item,
                concealed: concealed,
                visualSize: visualSize,
                visualFrameWidth: visualFrameWidth,
                visualFrameHeight: visualFrameHeight,
                cornerRadius: isFeatured ? 28 : 22
            )
            Text(concealed ? "Hidden match" : item.title)
                .font(prominence == .featured ? (compact ? .title3.bold() : .title.bold()) : (compact ? .headline.bold() : .title3.bold()))
                .multilineTextAlignment(.center)
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
            let subtitle = concealed ? "Tap to check" : item.subtitle
            if showsSubtitle && !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MatherTheme.ink.opacity(0.68))
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minimumHeight)
        .padding(compact ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(matched ? MatherTheme.accent.opacity(0.22) : selected ? MatherTheme.softBlue : MatherTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(selected ? MatherTheme.accent : .clear, lineWidth: 3)
        )
    }

    private var isFeatured: Bool { prominence == .featured }
    private var visualSize: CGFloat {
        if isFeatured { return compact ? 104 : 140 }
        return compact ? 40 : 58
    }
    private var visualFrameWidth: CGFloat {
        if isFeatured { return compact ? 220 : 320 }
        return compact ? 64 : 86
    }
    private var visualFrameHeight: CGFloat {
        if isFeatured { return compact ? 170 : 240 }
        return compact ? 58 : 78
    }
    private var minimumHeight: CGFloat {
        if isFeatured { return compact ? 310 : 400 }
        return compact ? 132 : 164
    }
}

enum GameplayDisplayCardProminence {
    case normal
    case featured
}

private struct GameplayDisplayVisual: View {
    let item: GameplayDisplayItem
    let concealed: Bool
    let visualSize: CGFloat
    let visualFrameWidth: CGFloat
    let visualFrameHeight: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if concealed {
                Text("?")
                    .font(.system(size: visualSize, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.accent)
            } else if let assetName = item.visualAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
                    .padding(visualAssetPadding)
            } else if let shapeKey = item.visualShapeKey {
                CountryMapShapeArtwork(shapeKey: shapeKey)
                    .accessibilityHidden(true)
                    .padding(visualAssetPadding)
            } else {
                Text(item.visualKey ?? "✦")
                    .font(.system(size: visualSize, weight: .regular, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
            }
        }
        .frame(width: visualFrameWidth, height: visualFrameHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(MatherTheme.softBlue.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(MatherTheme.panelDeep.opacity(concealed ? 0 : 0.12), lineWidth: 1)
        )
    }

    private var visualAssetPadding: CGFloat {
        max(4, min(14, visualFrameHeight * 0.08))
    }
}

private struct CountryMapShapeArtwork: View {
    let shapeKey: String

    var body: some View {
        CountryMapSilhouette(shapeKey: shapeKey)
            .fill(
                LinearGradient(
                    colors: [MatherTheme.accent.opacity(0.95), MatherTheme.panelDeep.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                CountryMapSilhouette(shapeKey: shapeKey)
                    .stroke(MatherTheme.ink.opacity(0.18), lineWidth: 2)
            )
            .shadow(color: MatherTheme.panelDeep.opacity(0.18), radius: 4, x: 0, y: 3)
    }
}

private struct CountryMapSilhouette: Shape {
    let shapeKey: String

    func path(in rect: CGRect) -> Path {
        let points = normalizedPoints(for: shapeKey)
        guard let first = points.first else { return Path() }
        var path = Path()
        path.move(to: point(first, in: rect))
        for coordinate in points.dropFirst() {
            path.addLine(to: point(coordinate, in: rect))
        }
        path.closeSubpath()
        return path
    }

    private func point(_ coordinate: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + coordinate.x * rect.width, y: rect.minY + coordinate.y * rect.height)
    }

    private func normalizedPoints(for key: String) -> [CGPoint] {
        switch key {
        case "country-india":
            return [CGPoint(x: 0.40, y: 0.08), CGPoint(x: 0.70, y: 0.22), CGPoint(x: 0.62, y: 0.52), CGPoint(x: 0.52, y: 0.92), CGPoint(x: 0.34, y: 0.58), CGPoint(x: 0.24, y: 0.24)]
        case "country-japan":
            return [CGPoint(x: 0.58, y: 0.06), CGPoint(x: 0.72, y: 0.18), CGPoint(x: 0.65, y: 0.36), CGPoint(x: 0.76, y: 0.56), CGPoint(x: 0.58, y: 0.92), CGPoint(x: 0.42, y: 0.76), CGPoint(x: 0.50, y: 0.52), CGPoint(x: 0.34, y: 0.30)]
        case "country-france":
            return [CGPoint(x: 0.34, y: 0.12), CGPoint(x: 0.66, y: 0.12), CGPoint(x: 0.82, y: 0.42), CGPoint(x: 0.66, y: 0.78), CGPoint(x: 0.36, y: 0.86), CGPoint(x: 0.16, y: 0.48)]
        case "country-egypt":
            return [CGPoint(x: 0.18, y: 0.18), CGPoint(x: 0.72, y: 0.18), CGPoint(x: 0.72, y: 0.56), CGPoint(x: 0.86, y: 0.72), CGPoint(x: 0.58, y: 0.74), CGPoint(x: 0.18, y: 0.72)]
        case "country-brazil":
            return [CGPoint(x: 0.34, y: 0.08), CGPoint(x: 0.70, y: 0.18), CGPoint(x: 0.88, y: 0.46), CGPoint(x: 0.70, y: 0.74), CGPoint(x: 0.54, y: 0.92), CGPoint(x: 0.24, y: 0.76), CGPoint(x: 0.12, y: 0.44)]
        case "country-australia":
            return [CGPoint(x: 0.20, y: 0.42), CGPoint(x: 0.40, y: 0.24), CGPoint(x: 0.76, y: 0.32), CGPoint(x: 0.88, y: 0.56), CGPoint(x: 0.66, y: 0.78), CGPoint(x: 0.32, y: 0.72), CGPoint(x: 0.12, y: 0.58)]
        case "country-canada":
            return [CGPoint(x: 0.06, y: 0.34), CGPoint(x: 0.22, y: 0.16), CGPoint(x: 0.42, y: 0.28), CGPoint(x: 0.58, y: 0.14), CGPoint(x: 0.86, y: 0.30), CGPoint(x: 0.94, y: 0.54), CGPoint(x: 0.72, y: 0.68), CGPoint(x: 0.42, y: 0.58), CGPoint(x: 0.20, y: 0.72)]
        case "country-kenya":
            return [CGPoint(x: 0.42, y: 0.10), CGPoint(x: 0.64, y: 0.18), CGPoint(x: 0.72, y: 0.46), CGPoint(x: 0.54, y: 0.90), CGPoint(x: 0.30, y: 0.70), CGPoint(x: 0.34, y: 0.34)]
        default:
            return [CGPoint(x: 0.30, y: 0.12), CGPoint(x: 0.74, y: 0.28), CGPoint(x: 0.66, y: 0.76), CGPoint(x: 0.24, y: 0.86), CGPoint(x: 0.16, y: 0.42)]
        }
    }
}

struct GameplayMatchRewardBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text("★")
                .font(.title3.bold())
                .foregroundStyle(MatherTheme.warm)
            Text(text)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(MatherTheme.warm.opacity(0.24)))
        .accessibilityElement(children: .combine)
    }
}

struct GameplayPairingStageShell: View {
    let title: String
    let prompt: String
    let compact: Bool
    @Binding var viewModel: GameplayMatchStageViewModel
    let actions: GameplayStageFeedbackActions
    let onComplete: (Int, Int, Int) -> Void

    @State private var autoProgressTask: Task<Void, Never>?
    @State private var autoProgressSignature: String?

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
            GameplayStageTitle(title: title, prompt: prompt, detail: "\(viewModel.turnProgressText) • \(viewModel.correctCount)/\(viewModel.pairs.count)")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.activePairs) { pair in
                    Button {
                        viewModel.selectLeft(pairID: pair.id)
                    } label: {
                        GameplayDisplayCard(
                            item: pair.left,
                            compact: compact,
                            selected: viewModel.selectedLeftID == pair.id,
                            matched: viewModel.matchedPairIDs.contains(pair.id),
                            prominence: viewModel.activePairs.count == 1 ? .featured : .normal
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.accessibilityLabel(for: pair.left, side: .left))
                }
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.shuffledRights) { item in
                    Button {
                        let wasMatching = viewModel.selectedLeftID != nil
                        let correct = viewModel.chooseRight(item)
                        if correct { actions.success() }
                        else if wasMatching { actions.failure() }
                        scheduleAutoProgressIfReady()
                    } label: {
                        GameplayDisplayCard(
                            item: item,
                            compact: compact,
                            showsSubtitle: true,
                            selected: viewModel.inspectedItemID == item.id,
                            matched: viewModel.matchedPairIDs.contains(pairID(for: item)),
                            concealed: viewModel.shouldConcealRight(item),
                            prominence: viewModel.activePairs.count == 1 ? .featured : .normal
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.accessibilityLabel(for: item, side: .right))
                }
            }
            if autoProgressSignature != nil {
                GameplayMatchRewardBanner(text: viewModel.canAdvanceTurn ? "Great matches! Next turn is coming…" : "Great matches! Your reward is coming…")
            }
            if let item = viewModel.inspectedItem, !viewModel.shouldConcealRight(item) {
                GameplayCardDetailCallout(item: item, compact: compact)
            }
            HStack {
                Button("Hint") { viewModel.hintCount += 1 }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                Spacer()
                if viewModel.canAdvanceTurn {
                    Button("Next turn") {
                        cancelAutoProgress()
                        viewModel.advanceTurn()
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                } else {
                    Button("Finish stage") {
                        cancelAutoProgress()
                        onComplete(viewModel.correctCount, viewModel.mismatchCount, viewModel.hintCount)
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                    .disabled(!viewModel.isComplete)
                }
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
        .onDisappear { cancelAutoProgress() }
    }

    private func scheduleAutoProgressIfReady() {
        let signature: String?
        if viewModel.canAdvanceTurn {
            signature = "turn-\(viewModel.activeTurnIndex)-\(viewModel.correctCount)"
        } else if viewModel.isComplete {
            signature = "complete-\(viewModel.correctCount)"
        } else {
            signature = nil
        }
        guard let signature else { return }
        guard autoProgressSignature != signature else { return }
        cancelAutoProgress()
        autoProgressSignature = signature
        autoProgressTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_200))
            guard autoProgressSignature == signature else { return }
            if viewModel.canAdvanceTurn {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    viewModel.advanceTurn()
                }
            } else if viewModel.isComplete {
                onComplete(viewModel.correctCount, viewModel.mismatchCount, viewModel.hintCount)
            }
            autoProgressSignature = nil
            autoProgressTask = nil
        }
    }

    private func cancelAutoProgress() {
        autoProgressTask?.cancel()
        autoProgressTask = nil
        autoProgressSignature = nil
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: compact ? 132 : 176), spacing: 12)]
    }

    private func pairID(for item: GameplayDisplayItem) -> String {
        viewModel.pairID(forRight: item)
    }
}

private struct GameplayCardDetailCallout: View {
    let item: GameplayDisplayItem
    let compact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(item.visualKey ?? "✦")
                .font(.system(size: compact ? 24 : 30, weight: .semibold, design: .rounded))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.headline.bold())
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.ink.opacity(0.72))
                }
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(MatherTheme.softBlue.opacity(0.5)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Card details: \(item.title), \(item.subtitle)")
    }
}
