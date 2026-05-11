import SwiftUI

struct GameplayStageTitle: View {
    let title: String
    let prompt: String
    let detail: String
    let showsPrompt: Bool

    init(stage: GameplayStageDefinition, detail: String, showsPrompt: Bool = true) {
        self.title = stage.title
        self.prompt = stage.prompt
        self.detail = detail
        self.showsPrompt = showsPrompt
    }

    init(title: String, prompt: String, detail: String = "", showsPrompt: Bool = true) {
        self.title = title
        self.prompt = prompt
        self.detail = detail
        self.showsPrompt = showsPrompt
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(MatherTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                if showsPrompt {
                    Text(prompt)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.ink.opacity(0.72))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([title, prompt].filter { !$0.isEmpty }.joined(separator: ". "))
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let item: GameplayDisplayItem
    let compact: Bool
    var showsSubtitle = true
    var selected = false
    var inspected = false
    var matched = false
    var correct = false
    var concealed = false
    var prominence: GameplayDisplayCardProminence = .normal

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            if showsVisual {
                ZStack(alignment: .topTrailing) {
                    GameplayDisplayVisual(
                        item: item,
                        concealed: concealed,
                        visualSize: visualSize,
                        visualFrameWidth: visualFrameWidth,
                        visualFrameHeight: visualFrameHeight,
                        cornerRadius: isFeatured || item.presentation == .visualOnly ? 28 : 22,
                        tint: stateTint
                    )
                    if showsStateBadge {
                        Image(systemName: stateBadgeSystemName)
                            .font(.system(size: compact ? 16 : 21, weight: .black, design: .rounded))
                            .foregroundStyle(stateBadgeColor)
                            .padding(6)
                            .background(Circle().fill(MatherTheme.card.opacity(0.92)))
                            .offset(x: compact ? 4 : 8, y: compact ? -4 : -8)
                            .accessibilityHidden(true)
                    }
                }
            }
            if showsTitle {
                Text(concealed ? "Hidden match" : item.title)
                    .font(titleFont)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(item.presentation == .titleOnly ? 3 : 2)
                    .minimumScaleFactor(0.76)
            }
            let subtitle = concealed ? "Tap to check" : item.subtitle
            if showsSubtitle && item.presentation == .visualWithTitle && !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MatherTheme.ink.opacity(0.68))
                    .lineLimit(3)
                    .minimumScaleFactor(0.76)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minimumHeight)
        .padding(compact ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(cardBorder, lineWidth: borderWidth)
        )
        .shadow(color: cardShadow, radius: correct ? 12 : 6, x: 0, y: correct ? 6 : 3)
        .scaleEffect(correct && !reduceMotion ? 1.03 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.76), value: correct)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: selected)
    }

    private var cardFill: Color {
        if correct { return MatherTheme.warm.opacity(0.34) }
        if matched { return MatherTheme.accent.opacity(0.20) }
        if selected { return MatherTheme.softBlue.opacity(0.58) }
        if inspected { return MatherTheme.softBlue.opacity(0.50) }
        return MatherTheme.card
    }

    private var cardBorder: Color {
        if correct { return MatherTheme.coral }
        if matched { return MatherTheme.accent }
        if selected { return MatherTheme.accent }
        if inspected { return MatherTheme.softBlue }
        return MatherTheme.panelDeep.opacity(0.12)
    }

    private var borderWidth: CGFloat {
        if correct { return 4 }
        if selected || inspected || matched { return 3 }
        return 1
    }

    private var cardShadow: Color {
        if correct { return MatherTheme.coral.opacity(0.18) }
        if matched { return MatherTheme.accent.opacity(0.14) }
        if selected { return MatherTheme.accent.opacity(0.12) }
        return MatherTheme.panelDeep.opacity(0.08)
    }

    private var stateTint: Color {
        if correct { return MatherTheme.warm }
        if matched { return MatherTheme.accent }
        if selected { return MatherTheme.accent }
        if inspected { return MatherTheme.softBlue }
        return MatherTheme.softBlue
    }

    private var showsStateBadge: Bool {
        selected || matched || correct
    }

    private var stateBadgeSystemName: String {
        if correct { return "sparkles" }
        if matched { return "checkmark.circle.fill" }
        return "hand.tap.fill"
    }

    private var stateBadgeColor: Color {
        if correct { return MatherTheme.coral }
        if matched { return MatherTheme.accent }
        return MatherTheme.accent
    }

    private var isFeatured: Bool { prominence == .featured }
    private var showsVisual: Bool { concealed || item.presentation != .titleOnly }
    private var showsTitle: Bool { concealed || item.presentation != .visualOnly }
    private var titleFont: Font {
        if item.presentation == .titleOnly {
            return compact ? .title3.bold() : .title.bold()
        }
        return prominence == .featured ? (compact ? .title3.bold() : .title.bold()) : (compact ? .headline.bold() : .title3.bold())
    }
    private var visualSize: CGFloat {
        if item.presentation == .visualOnly { return compact ? 86 : 124 }
        if isFeatured { return item.isFruitCard ? (compact ? 126 : 168) : (compact ? 104 : 140) }
        if item.isFruitCard { return compact ? 64 : 88 }
        return compact ? 40 : 58
    }
    private var visualFrameWidth: CGFloat {
        if item.presentation == .visualOnly { return compact ? 132 : 180 }
        if isFeatured { return item.isFruitCard ? (compact ? 250 : 360) : (compact ? 220 : 320) }
        if item.isFruitCard { return compact ? 104 : 132 }
        return compact ? 64 : 86
    }
    private var visualFrameHeight: CGFloat {
        if item.presentation == .visualOnly { return compact ? 112 : 156 }
        if isFeatured { return item.isFruitCard ? (compact ? 190 : 260) : (compact ? 170 : 240) }
        if item.isFruitCard { return compact ? 94 : 118 }
        return compact ? 58 : 78
    }
    private var minimumHeight: CGFloat {
        if item.presentation == .titleOnly { return compact ? 104 : 132 }
        if item.presentation == .visualOnly { return compact ? 138 : 184 }
        if isFeatured { return item.isFruitCard ? (compact ? 330 : 430) : (compact ? 310 : 400) }
        if item.isFruitCard { return compact ? 160 : 202 }
        return compact ? 118 : 164
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
    let tint: Color

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
                ZStack {
                    if item.isFruitCard && !concealed {
                        Text("✨")
                            .font(.system(size: max(18, visualSize * 0.26), weight: .bold, design: .rounded))
                            .offset(x: -visualFrameWidth * 0.28, y: -visualFrameHeight * 0.28)
                            .accessibilityHidden(true)
                        Text("🌱")
                            .font(.system(size: max(16, visualSize * 0.22), weight: .bold, design: .rounded))
                            .offset(x: visualFrameWidth * 0.30, y: visualFrameHeight * 0.26)
                            .accessibilityHidden(true)
                    }
                    Text(item.visualKey ?? "✦")
                        .font(.system(size: visualSize, weight: .regular, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                }
            }
        }
        .frame(width: visualFrameWidth, height: visualFrameHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.42), MatherTheme.card.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
        case "country-united-states":
            return [CGPoint(x: 0.08, y: 0.40), CGPoint(x: 0.24, y: 0.24), CGPoint(x: 0.48, y: 0.30), CGPoint(x: 0.74, y: 0.20), CGPoint(x: 0.92, y: 0.42), CGPoint(x: 0.80, y: 0.66), CGPoint(x: 0.50, y: 0.70), CGPoint(x: 0.22, y: 0.62)]
        case "country-united-kingdom":
            return [CGPoint(x: 0.48, y: 0.08), CGPoint(x: 0.66, y: 0.22), CGPoint(x: 0.58, y: 0.40), CGPoint(x: 0.72, y: 0.62), CGPoint(x: 0.56, y: 0.88), CGPoint(x: 0.40, y: 0.68), CGPoint(x: 0.48, y: 0.48), CGPoint(x: 0.30, y: 0.28)]
        case "country-china":
            return [CGPoint(x: 0.16, y: 0.30), CGPoint(x: 0.38, y: 0.12), CGPoint(x: 0.68, y: 0.16), CGPoint(x: 0.88, y: 0.38), CGPoint(x: 0.78, y: 0.68), CGPoint(x: 0.54, y: 0.86), CGPoint(x: 0.28, y: 0.70), CGPoint(x: 0.10, y: 0.52)]
        case "country-germany":
            return [CGPoint(x: 0.42, y: 0.08), CGPoint(x: 0.64, y: 0.20), CGPoint(x: 0.58, y: 0.40), CGPoint(x: 0.72, y: 0.62), CGPoint(x: 0.52, y: 0.90), CGPoint(x: 0.34, y: 0.72), CGPoint(x: 0.24, y: 0.42)]
        case "country-mexico":
            return [CGPoint(x: 0.12, y: 0.24), CGPoint(x: 0.42, y: 0.30), CGPoint(x: 0.66, y: 0.44), CGPoint(x: 0.86, y: 0.70), CGPoint(x: 0.68, y: 0.84), CGPoint(x: 0.44, y: 0.62), CGPoint(x: 0.22, y: 0.56)]
        case "country-south-africa":
            return [CGPoint(x: 0.22, y: 0.30), CGPoint(x: 0.58, y: 0.18), CGPoint(x: 0.86, y: 0.42), CGPoint(x: 0.72, y: 0.76), CGPoint(x: 0.46, y: 0.90), CGPoint(x: 0.18, y: 0.70), CGPoint(x: 0.10, y: 0.48)]
        case "country-italy":
            return [CGPoint(x: 0.42, y: 0.08), CGPoint(x: 0.60, y: 0.22), CGPoint(x: 0.54, y: 0.48), CGPoint(x: 0.72, y: 0.72), CGPoint(x: 0.58, y: 0.88), CGPoint(x: 0.40, y: 0.62), CGPoint(x: 0.32, y: 0.34)]
        case "country-saudi-arabia":
            return [CGPoint(x: 0.18, y: 0.26), CGPoint(x: 0.56, y: 0.18), CGPoint(x: 0.86, y: 0.44), CGPoint(x: 0.76, y: 0.74), CGPoint(x: 0.46, y: 0.86), CGPoint(x: 0.20, y: 0.62)]
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

struct GameplayMatchStatusStrip: View {
    let matchedText: String
    let roundText: String
    let compact: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                statusPill(text: matchedText, systemImage: "checkmark.circle.fill", tint: MatherTheme.accent)
                statusPill(text: roundText, systemImage: "target", tint: MatherTheme.coral)
            }

            VStack(alignment: .leading, spacing: 8) {
                statusPill(text: matchedText, systemImage: "checkmark.circle.fill", tint: MatherTheme.accent)
                statusPill(text: roundText, systemImage: "target", tint: MatherTheme.coral)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func statusPill(text: String, systemImage: String, tint: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font((compact ? Font.caption : Font.subheadline).weight(.black))
            .foregroundStyle(MatherTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, compact ? 9 : 12)
            .padding(.vertical, compact ? 6 : 8)
            .background(tint.opacity(0.16), in: Capsule())
    }
}

struct GameplayPairingStageShell: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let prompt: String
    let compact: Bool
    var showsStagePrompt = true
    @Binding var viewModel: GameplayMatchStageViewModel
    let actions: GameplayStageFeedbackActions
    let onComplete: (Int, Int, Int) -> Void

    @State private var autoProgressTask: Task<Void, Never>?
    @State private var autoProgressSignature: String?

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
            GameplayStageTitle(title: title, prompt: prompt, detail: viewModel.turnProgressText, showsPrompt: showsStagePrompt)
            GameplayTurnGuidance(text: viewModel.turnGuidanceText, compact: compact)
            GameplayMatchStatusStrip(
                matchedText: viewModel.matchedProgressText,
                roundText: viewModel.currentRoundRequirementText,
                compact: compact
            )
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.activePairs) { pair in
                    let state = viewModel.cardState(forLeft: pair)
                    Button {
                        viewModel.selectLeft(pairID: pair.id)
                    } label: {
                        GameplayDisplayCard(
                            item: pair.left,
                            compact: compact,
                            showsSubtitle: false,
                            selected: state == .selected,
                            inspected: state == .inspected,
                            matched: state == .matched,
                            correct: state == .justMatched,
                            prominence: viewModel.activePairs.count == 1 ? .featured : .normal
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.accessibilityLabel(for: pair.left, side: .left))
                }
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.shuffledRights) { item in
                    let state = viewModel.cardState(forRight: item)
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
                            showsSubtitle: false,
                            selected: state == .selected,
                            inspected: state == .inspected,
                            matched: state == .matched,
                            correct: state == .justMatched,
                            concealed: viewModel.shouldConcealRight(item),
                            prominence: viewModel.activePairs.count == 1 ? .featured : .normal
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.accessibilityLabel(for: item, side: .right))
                }
            }
            if autoProgressSignature != nil {
                GameplayMatchRewardBanner(text: "Turn complete! Tap Next turn now, or it will open automatically.")
            } else if viewModel.isComplete {
                GameplayMatchRewardBanner(text: "Stage complete — finish when you’re ready!")
            }
            if let item = viewModel.inspectedItem, !viewModel.shouldConcealRight(item) {
                GameplayCardDetailCallout(item: item, compact: compact)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 10) {
                    hintControl
                    Spacer(minLength: 8)
                    footerProgressOrAction
                }
                VStack(alignment: .leading, spacing: 10) {
                    hintControl
                    footerProgressOrAction
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(compact ? 14 : 20)
        .padding(.bottom, compact ? 12 : 8)
        .background(GameplayStagePanel())
        .onDisappear { cancelAutoProgress() }
    }

    private func scheduleAutoProgressIfReady() {
        let signature: String?
        if viewModel.canAdvanceTurn {
            signature = "turn-\(viewModel.activeTurnIndex)-\(viewModel.correctCount)"
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
                if reduceMotion {
                    viewModel.advanceTurn()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        viewModel.advanceTurn()
                    }
                }
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

    private var hintControl: some View {
        Button("Hint") { viewModel.hintCount += 1 }
            .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
    }

    @ViewBuilder
    private var footerProgressOrAction: some View {
        if viewModel.canAdvanceTurn {
            Button(autoProgressSignature == nil ? "Next turn" : "Next turn now") {
                cancelAutoProgress()
                viewModel.advanceTurn()
            }
            .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
        } else if viewModel.isComplete {
            Button("Finish stage") {
                cancelAutoProgress()
                onComplete(viewModel.correctCount, viewModel.mismatchCount, viewModel.hintCount)
            }
            .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
        } else {
            Text(viewModel.finishRequirementText)
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.ink.opacity(0.68))
                .multilineTextAlignment(compact ? .leading : .trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: compact ? 132 : 176), spacing: 12)]
    }

    private func pairID(for item: GameplayDisplayItem) -> String {
        viewModel.pairID(forRight: item)
    }
}

private struct GameplayTurnGuidance: View {
    let text: String
    let compact: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text("👀")
                .font(.system(size: compact ? 15 : 18))
                .accessibilityHidden(true)
            Text(text)
                .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink.opacity(0.74))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, compact ? 8 : 10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(MatherTheme.softBlue.opacity(0.32)))
        .accessibilityElement(children: .combine)
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
                    .fixedSize(horizontal: false, vertical: true)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
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
