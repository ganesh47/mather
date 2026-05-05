import SwiftUI

struct GameplayStageFeedbackActions {
    var speak: @MainActor (String) -> Void = { _ in }
    var success: @MainActor () -> Void = {}
    var failure: @MainActor () -> Void = {}

    @MainActor
    static func services(speechService: SpeechService, hapticsService: HapticsService, featureFlags: FeatureFlagService) -> GameplayStageFeedbackActions {
        GameplayStageFeedbackActions(
            speak: { text in speechService.speakLearningDetails(text, enabled: featureFlags.audioEnabled) },
            success: { hapticsService.cardSnapCorrect(enabled: featureFlags.hapticsEnabled) },
            failure: { hapticsService.cardSnapMismatch(enabled: featureFlags.hapticsEnabled) }
        )
    }

    @MainActor
    static func appModel(_ appModel: AppModel) -> GameplayStageFeedbackActions {
        services(speechService: appModel.speechService, hapticsService: appModel.hapticsService, featureFlags: appModel.featureFlags)
    }
}

struct GameplayThreadView: View {
    let thread: GameplayThreadDefinition
    var actions: GameplayStageFeedbackActions
    var progressStore: GameplayProgressStore?
    var onHome: @MainActor () -> Void
    var onBackToStageSurface: @MainActor () -> Void
    @State private var navigation: GameplayStageNavigationState

    init(
        thread: GameplayThreadDefinition = GameplaySampleThreads.countries,
        actions: GameplayStageFeedbackActions = GameplayStageFeedbackActions(),
        progressStore: GameplayProgressStore? = nil,
        now: Date = Date(),
        onHome: @escaping @MainActor () -> Void = {},
        onBackToStageSurface: @escaping @MainActor () -> Void = {}
    ) {
        self.thread = thread
        self.actions = actions
        self.progressStore = progressStore
        self.onHome = onHome
        self.onBackToStageSurface = onBackToStageSurface
        _navigation = State(initialValue: GameplayStageNavigationState(startedAt: now, currentStageStartedAt: now))
    }

    @MainActor
    init(thread: GameplayThreadDefinition = GameplaySampleThreads.countries, appModel: AppModel, now: Date = Date()) {
        self.init(
            thread: thread,
            actions: .appModel(appModel),
            progressStore: appModel.gameplayProgressStore,
            now: now,
            onHome: { appModel.engine.showHome() },
            onBackToStageSurface: { appModel.engine.returnFromGameplay(defaultRoute: .lab) }
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = GameplayStageRenderSupport.usesCompactStageLayout(width: proxy.size.width, height: proxy.size.height)
            ScrollView {
                VStack(spacing: compact ? 12 : 20) {
                    topChrome(compact: compact)
                    header(compact: compact)
                    activeStage(compact: compact)
                        .id(navigation.stageAttemptID)
                        .frame(maxWidth: GameplayStageRenderSupport.maximumContentWidth(compact: compact))
                    controls(compact: compact)
                }
                .padding(compact ? 14 : 24)
                .frame(maxWidth: .infinity)
            }
            .background(MatherTheme.background.ignoresSafeArea())
        }
        .navigationTitle(thread.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func activeStage(compact: Bool) -> some View {
        if navigation.isComplete(for: thread) {
            GameplayThreadSummaryView(summary: navigation.summary(), stageCount: thread.stages.count)
        } else if let stage = navigation.activeStage(in: thread) {
            let round = progressStore?.makeRound(thread: thread, stage: stage, seed: UInt64(navigation.activeStageIndex + 17))
                ?? SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: UInt64(navigation.activeStageIndex + 17))
            switch stage.kind {
            case .flashcards:
                FlashcardStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(stage: stage, round: round, correct: correct, mistakes: mistakes, hints: hints)
                }
            case .easyMemory:
                MemoryStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(stage: stage, round: round, correct: correct, mistakes: mistakes, hints: hints)
                }
            case .flipMemory:
                FlipMemoryStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(stage: stage, round: round, correct: correct, mistakes: mistakes, hints: hints)
                }
            case .bondBlast:
                BondBlastStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(stage: stage, round: round, correct: correct, mistakes: mistakes, hints: hints)
                }
            case .multipleChoice:
                MultipleChoiceStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(stage: stage, round: round, correct: correct, mistakes: mistakes, hints: hints)
                }
            }
        } else {
            Text("No stage is available yet.")
                .font(.headline)
                .foregroundStyle(MatherTheme.ink)
        }
    }

    private func complete(stage: GameplayStageDefinition, round: GameplayRoundDefinition, correct: Int, mistakes: Int, hints: Int) {
        let occurredAt = Date()
        navigation.completeCurrentStage(thread: thread, correctCount: correct, mistakeCount: mistakes, hintsUsed: hints, now: occurredAt)
        persistProgress(stage: stage, round: round, correct: correct, mistakes: mistakes, hints: hints, at: occurredAt)
        if navigation.isComplete(for: thread) {
            let endedAt = navigation.stageResults.last?.completedAt ?? occurredAt
            progressStore?.saveThreadSession(thread: thread, startedAt: navigation.startedAt, endedAt: endedAt, results: navigation.stageResults)
        }
        actions.success()
    }

    private func persistProgress(stage: GameplayStageDefinition, round: GameplayRoundDefinition, correct: Int, mistakes: Int, hints: Int, at date: Date) {
        guard let progressStore else { return }
        progressStore.markExposed(thread: thread, stage: stage, items: round.items, at: date)
        progressStore.apply(
            updates: repetitionUpdates(for: round, stage: stage, correct: correct, mistakes: mistakes, at: date),
            thread: thread,
            hintsByKey: hintsByKey(for: round, stage: stage, totalHints: hints),
            metadataByKey: Dictionary(uniqueKeysWithValues: round.items.map { item in
                let key = SpacedRepetitionScheduler.recordKey(for: item, stageID: stage.id)
                return (key, "stage=\(stage.kind.rawValue);score=\(correct);mistakes=\(mistakes)")
            })
        )
    }

    private func repetitionUpdates(for round: GameplayRoundDefinition, stage: GameplayStageDefinition, correct: Int, mistakes: Int, at date: Date) -> [SpacedRepetitionUpdate] {
        let correctLimit = max(0, correct)
        let mistakeLimit = max(0, mistakes)
        return round.items.enumerated().map { index, item in
            let outcome: GameplayExposureOutcome
            if index < correctLimit {
                outcome = mistakeLimit == 0 ? .correct : .supportedCorrect
            } else if index < correctLimit + mistakeLimit {
                outcome = .incorrect
            } else {
                outcome = .supportedCorrect
            }
            return SpacedRepetitionUpdate(key: SpacedRepetitionScheduler.recordKey(for: item, stageID: stage.id), outcome: outcome, occurredAt: date)
        }
    }

    private func hintsByKey(for round: GameplayRoundDefinition, stage: GameplayStageDefinition, totalHints: Int) -> [GameplayExposureKey: Int] {
        guard totalHints > 0, !round.items.isEmpty else { return [:] }
        let key = SpacedRepetitionScheduler.recordKey(for: round.items[0], stageID: stage.id)
        return [key: totalHints]
    }

    private func topChrome(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Button {
                backAction()
            } label: {
                Label(navigation.canGoBack ? "Back" : "Stages", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
            .accessibilityLabel(navigation.canGoBack ? "Back to previous stage" : "Back to stage details")
            .accessibilityIdentifier("GameplayStageTopBackButton")

            Spacer(minLength: 0)

            Button {
                onHome()
            } label: {
                Label("Home", systemImage: "house.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
            .accessibilityLabel("Home")
            .accessibilityIdentifier("GameplayStageHomeButton")
        }
        .frame(maxWidth: GameplayStageRenderSupport.maximumContentWidth(compact: compact))
    }

    private func backAction() {
        if navigation.canGoBack {
            navigation.goBack()
        } else {
            onBackToStageSurface()
        }
    }

    private func header(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.category.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.accent)
                    Text(thread.title)
                        .font(compact ? .title2.bold() : .largeTitle.bold())
                        .foregroundStyle(MatherTheme.ink)
                }
                Spacer()
                Text("Stage \(min(navigation.activeStageIndex + 1, max(thread.stages.count, 1)))/\(thread.stages.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(MatherTheme.card))
            }
            HStack(spacing: 10) {
                ProgressView(value: navigation.progressFraction(for: thread))
                    .tint(MatherTheme.accent)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Gameplay thread progress")
                    .accessibilityValue("Stage \(min(navigation.activeStageIndex + 1, max(thread.stages.count, 1))) of \(thread.stages.count)")
                Text("\(Int((navigation.progressFraction(for: thread) * 100).rounded()))%")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .monospacedDigit()
                    .accessibilityHidden(true)
            }
        }
    }

    private func controls(compact: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            controlRow(compact: compact)
            VStack(alignment: .leading, spacing: 8) {
                controlButtons(compact: compact)
                scoreText
            }
        }
    }

    private func controlRow(compact: Bool) -> some View {
        HStack(spacing: 10) {
            controlButtons(compact: compact)
            Spacer(minLength: 0)
            scoreText
        }
    }

    private func controlButtons(compact: Bool) -> some View {
        HStack(spacing: 8) {
            Button(navigation.canGoBack ? "Back" : "Stages") { backAction() }
                .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                .accessibilityLabel(navigation.canGoBack ? "Back to previous stage" : "Back to stage details")
                .accessibilityIdentifier("GameplayStageBackButton")
            Button("Retry") { navigation.retryCurrentStage(in: thread) }
                .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                .accessibilityLabel("Retry current stage")
                .accessibilityIdentifier("GameplayStageRetryButton")
        }
    }

    private var scoreText: some View {
        Text("Score \(navigation.summary().scorePoints)")
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .foregroundStyle(MatherTheme.ink.opacity(0.8))
            .accessibilityLabel("Current score \(navigation.summary().scorePoints)")
    }
}

private struct GameplayThreadSummaryView: View {
    let summary: GameplayScoreSummary
    let stageCount: Int

    var body: some View {
        VStack(spacing: 14) {
            Text(String(repeating: "★", count: summary.stars) + String(repeating: "☆", count: max(0, 3 - summary.stars)))
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(MatherTheme.warm)
                .accessibilityLabel("\(summary.stars) stars")
            Text("Thread complete")
                .font(.title.bold())
                .foregroundStyle(MatherTheme.ink)
            Text("Score \(summary.scorePoints) • \(summary.correctCount)/\(summary.attemptedCount) correct • \(summary.formattedDuration)")
                .font(.headline)
                .foregroundStyle(MatherTheme.ink.opacity(0.78))
            Text("Accuracy \(summary.formattedAccuracy) • \(summary.mistakeCount) review items • \(stageCount) stages")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink.opacity(0.68))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(MatherTheme.card))
    }
}

enum GameplayStageControlKind {
    case primary
    case secondary
}

struct GameplayStageControlButtonStyle: ButtonStyle {
    let kind: GameplayStageControlKind
    let compact: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(minHeight: GameplayStageRenderSupport.touchTargetSize(compact: compact))
            .padding(.horizontal, compact ? 14 : 18)
            .foregroundStyle(kind == .primary ? .white : MatherTheme.ink)
            .background(
                Capsule().fill(kind == .primary ? MatherTheme.accent.opacity(configuration.isPressed ? 0.78 : 1) : MatherTheme.card)
            )
            .opacity(configuration.isPressed ? 0.86 : 1)
    }
}

#Preview("Gameplay stages") {
    NavigationStack {
        GameplayThreadView()
    }
}
