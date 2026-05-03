import SwiftUI

@MainActor
struct GameplayThreadView: View {
    let thread: GameplayThreadDefinition
    let appModel: AppModel?
    let seed: UInt64

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var navigation = GameplayStageNavigationState()

    init(thread: GameplayThreadDefinition, appModel: AppModel? = nil, seed: UInt64 = 912) {
        self.thread = thread
        self.appModel = appModel
        self.seed = seed
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = GameplayStageRenderSupport.usesCompactStageLayout(width: proxy.size.width, height: proxy.size.height)
            ScrollView {
                VStack(spacing: compact ? 14 : 20) {
                    header(compact: compact)

                    if let stage = navigation.activeStage(in: thread) {
                        stageView(stage, compact: compact)
                    } else {
                        GameplayThreadSummaryView(summary: navigation.summary())
                    }
                }
                .padding(ResponsiveLayout.contentPadding(for: horizontalSizeClass))
                .frame(maxWidth: GameplayStageRenderSupport.maximumContentWidth(compact: compact))
                .frame(maxWidth: .infinity)
            }
            .background(MatherTheme.background.ignoresSafeArea())
        }
    }

    private func header(compact: Bool) -> some View {
        CardSurface {
            VStack(alignment: .leading, spacing: compact ? 10 : 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(thread.title)
                            .font(compact ? .title2.weight(.bold) : .largeTitle.weight(.bold))
                            .foregroundStyle(MatherTheme.ink)
                        Text(thread.category.subtitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                    Spacer()
                    Text("\(min(navigation.activeStageIndex + 1, thread.stages.count))/\(thread.stages.count)")
                        .font(.headline.monospacedDigit().weight(.bold))
                        .foregroundStyle(MatherTheme.accent)
                }

                ProgressView(value: navigation.progressFraction(for: thread))
                    .tint(MatherTheme.accent)

                let summary = navigation.summary()
                HStack(spacing: 12) {
                    GameplayStatPill(title: "Score", value: "\(summary.correctCount)✓")
                    GameplayStatPill(title: "Misses", value: "\(summary.mistakeCount)")
                    GameplayStatPill(title: "Time", value: GameplayTimeFormatter.short(summary.durationSeconds))
                }
            }
        }
    }

    @ViewBuilder
    private func stageView(_ stage: GameplayStageDefinition, compact: Bool) -> some View {
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: seed + UInt64(navigation.activeStageIndex))
        switch stage.kind {
        case .flashcards:
            FlashcardStageView(thread: thread, stage: stage, appModel: appModel, compact: compact) { correct, mistakes, hints in
                complete(correct: correct, mistakes: mistakes, hints: hints)
            }
        case .easyMemory:
            MemoryStageView(thread: thread, stage: stage, round: round, appModel: appModel, compact: compact) { correct, mistakes, hints in
                complete(correct: correct, mistakes: mistakes, hints: hints)
            }
        case .flipMemory:
            FlipMemoryStageView(thread: thread, stage: stage, round: round, appModel: appModel, compact: compact) { correct, mistakes, hints in
                complete(correct: correct, mistakes: mistakes, hints: hints)
            }
        case .bondBlast:
            BondBlastStageView(thread: thread, stage: stage, round: round, appModel: appModel, compact: compact) { correct, mistakes, hints in
                complete(correct: correct, mistakes: mistakes, hints: hints)
            }
        case .multipleChoice:
            MultipleChoiceStageView(thread: thread, stage: stage, round: round, appModel: appModel, compact: compact) { correct, mistakes, hints in
                complete(correct: correct, mistakes: mistakes, hints: hints)
            }
        }
    }

    private func complete(correct: Int, mistakes: Int, hints: Int) {
        navigation.completeCurrentStage(thread: thread, correctCount: correct, mistakeCount: mistakes, hintsUsed: hints)
        appModel?.hapticsService.stageSuccess(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
    }
}

@MainActor
struct FlashcardStageView: View {
    let thread: GameplayThreadDefinition
    let stage: GameplayStageDefinition
    let appModel: AppModel?
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void

    @State private var index = 0
    @State private var listenCount = 0

    var body: some View {
        let entity = thread.entities[min(index, max(thread.entities.count - 1, 0))]
        StageCard(title: stage.title, prompt: stage.prompt) {
            VStack(spacing: compact ? 14 : 18) {
                GameplayVisual(item: GameplayDisplayItem(id: entity.id, entityID: entity.id, title: entity.name, subtitle: entity.summary, visualKey: entity.visualKey, visualAssetName: entity.visualAssetName), size: compact ? 96 : 132)
                Text(entity.name)
                    .font(compact ? .largeTitle.weight(.heavy) : .system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text(entity.summary.isEmpty ? "Look closely, then listen and say it back." : entity.summary)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MatherTheme.cardSubtitle)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? 126 : 160), spacing: 10)], spacing: 10) {
                    ForEach(entity.properties.prefix(compact ? 4 : 6)) { property in
                        GameplayFactChip(title: thread.propertyTypesByID[property.typeID]?.displayName ?? property.typeID, value: property.value)
                    }
                }

                HStack(spacing: 12) {
                    Button("Listen again") { speak(entity) }
                        .buttonStyle(SecondaryTileButtonStyle(minHeight: compact ? 54 : 64, font: .headline.weight(.bold)))
                    Button(index == thread.entities.count - 1 ? "Finish" : "Next") {
                        if index == thread.entities.count - 1 {
                            onComplete(thread.entities.count, 0, listenCount)
                        } else {
                            index += 1
                            appModel?.hapticsService.cardPickup(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle(verticalPadding: compact ? 14 : 18, font: .headline.weight(.bold)))
                }
            }
        }
    }

    private func speak(_ entity: GameplayEntity) {
        listenCount += 1
        let facts = entity.properties.prefix(3).map(\.value).joined(separator: ", ")
        appModel?.speechService.speakLearningDetails("\(entity.name). \(entity.summary) \(facts)", enabled: appModel?.featureFlags.audioEnabled ?? false)
    }
}

@MainActor
struct MemoryStageView: View {
    let thread: GameplayThreadDefinition
    let stage: GameplayStageDefinition
    let round: GameplayRoundDefinition
    let appModel: AppModel?
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void

    @State private var selectedLeftID: String?
    @State private var matchedIDs = Set<String>()
    @State private var mistakes = 0
    @State private var hints = 0

    var body: some View {
        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)
        PairingStageBody(stage: stage, pairs: pairs, rightItems: pairs.map(\.right), selectedLeftID: selectedLeftID, matchedIDs: matchedIDs, compact: compact, revealsLeftCards: true, revealsRightCards: true) { pairID in
            selectedLeftID = pairID
            appModel?.hapticsService.cardPickup(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        } onRightTap: { item in
            handleRightTap(item, pairs: pairs)
        } footer: {
            StageFooter(canComplete: matchedIDs.count == pairs.count, compact: compact, retryTitle: "Hint") {
                hints += 1
            } complete: {
                onComplete(matchedIDs.count, mistakes, hints)
            }
        }
    }

    private func handleRightTap(_ item: GameplayDisplayItem, pairs: [GameplayMatchPair]) {
        guard let selectedLeftID, let pair = pairs.first(where: { $0.id == selectedLeftID }) else { return }
        if pair.right.id == item.id {
            matchedIDs.insert(pair.id)
            self.selectedLeftID = nil
            appModel?.hapticsService.cardSnapCorrect(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        } else {
            mistakes += 1
            appModel?.hapticsService.cardSnapMismatch(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        }
    }
}

@MainActor
struct FlipMemoryStageView: View {
    let thread: GameplayThreadDefinition
    let stage: GameplayStageDefinition
    let round: GameplayRoundDefinition
    let appModel: AppModel?
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void

    @State private var revealedRightIDs = Set<String>()
    @State private var selectedLeftID: String?
    @State private var matchedIDs = Set<String>()
    @State private var mistakes = 0

    var body: some View {
        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)
        let rightItems = GameplayStageContentBuilder.sortedRights(pairs, seed: round.seed)
        PairingStageBody(stage: stage, pairs: pairs, rightItems: rightItems, selectedLeftID: selectedLeftID, matchedIDs: matchedIDs, compact: compact, revealsLeftCards: true, revealsRightCards: false, revealedRightIDs: revealedRightIDs) { pairID in
            selectedLeftID = pairID
        } onRightTap: { item in
            revealedRightIDs.insert(item.id)
            handleRightTap(item, pairs: pairs)
        } footer: {
            StageFooter(canComplete: matchedIDs.count == pairs.count, compact: compact, retryTitle: "Peek") {
                revealedRightIDs = Set(rightItems.map(\.id))
            } complete: {
                onComplete(matchedIDs.count, mistakes, revealedRightIDs.count)
            }
        }
    }

    private func handleRightTap(_ item: GameplayDisplayItem, pairs: [GameplayMatchPair]) {
        guard let selectedLeftID, let pair = pairs.first(where: { $0.id == selectedLeftID }) else { return }
        if pair.right.id == item.id {
            matchedIDs.insert(pair.id)
            self.selectedLeftID = nil
            appModel?.hapticsService.cardSnapCorrect(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        } else {
            mistakes += 1
            appModel?.hapticsService.cardSnapMismatch(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        }
    }
}

@MainActor
struct BondBlastStageView: View {
    let thread: GameplayThreadDefinition
    let stage: GameplayStageDefinition
    let round: GameplayRoundDefinition
    let appModel: AppModel?
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void

    @State private var selectedLeftID: String?
    @State private var matchedIDs = Set<String>()
    @State private var mistakes = 0

    var body: some View {
        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)
        PairingStageBody(stage: stage, pairs: pairs, rightItems: GameplayStageContentBuilder.sortedRights(pairs, seed: round.seed), selectedLeftID: selectedLeftID, matchedIDs: matchedIDs, compact: compact, revealsLeftCards: true, revealsRightCards: true) { pairID in
            selectedLeftID = pairID
            appModel?.hapticsService.cardPickup(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        } onRightTap: { item in
            handleRightTap(item, pairs: pairs)
        } footer: {
            StageFooter(canComplete: matchedIDs.count == pairs.count, compact: compact, retryTitle: "Retry") {
                selectedLeftID = nil
                matchedIDs.removeAll()
                mistakes = 0
            } complete: {
                onComplete(matchedIDs.count, mistakes, 0)
                appModel?.hapticsService.bondMatchComplete(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
            }
        }
    }

    private func handleRightTap(_ item: GameplayDisplayItem, pairs: [GameplayMatchPair]) {
        guard let selectedLeftID, let pair = pairs.first(where: { $0.id == selectedLeftID }) else { return }
        if pair.right.id == item.id {
            matchedIDs.insert(pair.id)
            self.selectedLeftID = nil
            appModel?.hapticsService.cardSnapCorrect(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        } else {
            mistakes += 1
            appModel?.hapticsService.cardSnapMismatch(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        }
    }
}

@MainActor
struct MultipleChoiceStageView: View {
    let thread: GameplayThreadDefinition
    let stage: GameplayStageDefinition
    let round: GameplayRoundDefinition
    let appModel: AppModel?
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void

    @State private var index = 0
    @State private var correct = 0
    @State private var mistakes = 0
    @State private var answeredQuestionIDs = Set<String>()

    var body: some View {
        let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round)
        let question = questions[min(index, max(questions.count - 1, 0))]
        StageCard(title: stage.title, prompt: stage.prompt) {
            VStack(alignment: .leading, spacing: compact ? 14 : 18) {
                Text("Question \(min(index + 1, questions.count)) of \(questions.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
                Text(question.prompt)
                    .font(compact ? .title2.weight(.bold) : .title.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                ForEach(question.choices) { choice in
                    Button {
                        answer(choice, question: question, questionCount: questions.count)
                    } label: {
                        HStack {
                            GameplayVisual(item: choice, size: compact ? 40 : 50)
                            VStack(alignment: .leading) {
                                Text(choice.title)
                                Text(choice.subtitle).font(.caption.weight(.bold)).opacity(0.7)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: answeredQuestionIDs.contains(question.id) && choice.id == question.answer.id ? MatherTheme.accent.opacity(0.35) : MatherTheme.softBlue, minHeight: compact ? 62 : 76, font: .headline.weight(.bold)))
                }
            }
        }
    }

    private func answer(_ choice: GameplayDisplayItem, question: GameplayMultipleChoiceQuestion, questionCount: Int) {
        guard !answeredQuestionIDs.contains(question.id) else { return }
        answeredQuestionIDs.insert(question.id)
        if choice.id == question.answer.id {
            correct += 1
            appModel?.hapticsService.cardSnapCorrect(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        } else {
            mistakes += 1
            appModel?.hapticsService.cardSnapMismatch(enabled: appModel?.featureFlags.hapticsEnabled ?? false)
        }
        if index == questionCount - 1 {
            onComplete(correct, mistakes, 0)
        } else {
            index += 1
        }
    }
}

private struct PairingStageBody<Footer: View>: View {
    let stage: GameplayStageDefinition
    let pairs: [GameplayMatchPair]
    let rightItems: [GameplayDisplayItem]
    let selectedLeftID: String?
    let matchedIDs: Set<String>
    let compact: Bool
    let revealsLeftCards: Bool
    let revealsRightCards: Bool
    var revealedRightIDs: Set<String> = []
    let onLeftTap: (String) -> Void
    let onRightTap: (GameplayDisplayItem) -> Void
    @ViewBuilder let footer: Footer

    var body: some View {
        StageCard(title: stage.title, prompt: stage.prompt) {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: compact ? 10 : 16) {
                    VStack(spacing: 10) {
                        ForEach(pairs) { pair in
                            GameplayChoiceCard(item: pair.left, revealed: revealsLeftCards, selected: selectedLeftID == pair.id, matched: matchedIDs.contains(pair.id), compact: compact) {
                                guard !matchedIDs.contains(pair.id) else { return }
                                onLeftTap(pair.id)
                            }
                        }
                    }
                    VStack(spacing: 10) {
                        ForEach(rightItems) { item in
                            let pairID = pairs.first(where: { $0.right.id == item.id })?.id
                            GameplayChoiceCard(item: item, revealed: revealsRightCards || revealedRightIDs.contains(item.id), selected: false, matched: pairID.map { matchedIDs.contains($0) } ?? false, compact: compact) {
                                guard pairID.map({ !matchedIDs.contains($0) }) ?? true else { return }
                                onRightTap(item)
                            }
                        }
                    }
                }
                footer
            }
        }
    }
}

private struct GameplayChoiceCard: View {
    let item: GameplayDisplayItem
    let revealed: Bool
    let selected: Bool
    let matched: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if revealed {
                    GameplayVisual(item: item, size: compact ? 44 : 58)
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(item.subtitle)
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .opacity(0.75)
                } else {
                    Text("?")
                        .font(.largeTitle.weight(.heavy))
                    Text("Flip")
                        .font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(MatherTheme.ink)
            .frame(maxWidth: .infinity, minHeight: compact ? 104 : 130)
            .padding(8)
            .background(matched ? MatherTheme.accent.opacity(0.28) : selected ? MatherTheme.warm.opacity(0.38) : MatherTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(selected ? MatherTheme.warm : .clear, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(revealed ? "\(item.title), \(item.subtitle)" : "Face down card")
    }
}

private struct StageCard<Content: View>: View {
    let title: String
    let prompt: String
    @ViewBuilder let content: Content

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title.weight(.heavy))
                        .foregroundStyle(MatherTheme.ink)
                    Text(prompt)
                        .font(.headline)
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
                content
            }
        }
    }
}

private struct StageFooter: View {
    let canComplete: Bool
    let compact: Bool
    let retryTitle: String
    let retry: () -> Void
    let complete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(retryTitle, action: retry)
                .buttonStyle(SecondaryTileButtonStyle(minHeight: compact ? 52 : 62, font: .headline.weight(.bold)))
            Button("Next", action: complete)
                .buttonStyle(PrimaryActionButtonStyle(verticalPadding: compact ? 13 : 16, font: .headline.weight(.bold)))
                .disabled(!canComplete)
                .opacity(canComplete ? 1 : 0.45)
        }
    }
}

private struct GameplayVisual: View {
    let item: GameplayDisplayItem
    let size: CGFloat

    var body: some View {
        Group {
            if let asset = item.visualAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
            } else if let key = item.visualKey, key.count <= 4 {
                Text(key)
                    .font(.system(size: size * 0.62))
            } else if let key = item.visualKey {
                Image(systemName: key)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.22)
            } else {
                Text(String(item.title.prefix(1)))
                    .font(.system(size: size * 0.45, weight: .heavy, design: .rounded))
            }
        }
        .frame(width: size, height: size)
        .background(MatherTheme.softBlue.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
    }
}

private struct GameplayFactChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(MatherTheme.accent)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MatherTheme.ink)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatherTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct GameplayStatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2.weight(.heavy)).foregroundStyle(MatherTheme.cardSubtitle)
            Text(value).font(.headline.monospacedDigit().weight(.bold)).foregroundStyle(MatherTheme.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MatherTheme.panel)
        .clipShape(Capsule())
    }
}

private struct GameplayThreadSummaryView: View {
    let summary: GameplayScoreSummary

    var body: some View {
        StageCard(title: "Thread complete", prompt: "Great recall work.") {
            HStack(spacing: 12) {
                GameplayStatPill(title: "Correct", value: "\(summary.correctCount)")
                GameplayStatPill(title: "Mistakes", value: "\(summary.mistakeCount)")
                GameplayStatPill(title: "Stars", value: String(repeating: "★", count: summary.stars))
            }
        }
    }
}

private enum GameplayTimeFormatter {
    static func short(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }
}

#Preview("Gameplay thread") {
    GameplayThreadView(thread: GameplaySampleThreads.countries)
}
