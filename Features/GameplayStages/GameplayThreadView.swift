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
    @State private var navigation: GameplayStageNavigationState

    init(
        thread: GameplayThreadDefinition = GameplaySampleThreads.countries,
        actions: GameplayStageFeedbackActions = GameplayStageFeedbackActions(),
        now: Date = Date()
    ) {
        self.thread = thread
        self.actions = actions
        _navigation = State(initialValue: GameplayStageNavigationState(startedAt: now, currentStageStartedAt: now))
    }

    @MainActor
    init(thread: GameplayThreadDefinition = GameplaySampleThreads.countries, appModel: AppModel, now: Date = Date()) {
        self.init(thread: thread, actions: .appModel(appModel), now: now)
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = GameplayStageRenderSupport.usesCompactStageLayout(width: proxy.size.width, height: proxy.size.height)
            ScrollView {
                VStack(spacing: compact ? 12 : 20) {
                    header(compact: compact)
                    activeStage(compact: compact)
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
            let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: UInt64(navigation.activeStageIndex + 17))
            switch stage.kind {
            case .flashcards:
                FlashcardStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(correct: correct, mistakes: mistakes, hints: hints)
                }
            case .easyMemory:
                MemoryStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(correct: correct, mistakes: mistakes, hints: hints)
                }
            case .flipMemory:
                FlipMemoryStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(correct: correct, mistakes: mistakes, hints: hints)
                }
            case .bondBlast:
                BondBlastStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(correct: correct, mistakes: mistakes, hints: hints)
                }
            case .multipleChoice:
                MultipleChoiceStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact) { correct, mistakes, hints in
                    complete(correct: correct, mistakes: mistakes, hints: hints)
                }
            }
        } else {
            Text("No stage is available yet.")
                .font(.headline)
                .foregroundStyle(MatherTheme.ink)
        }
    }

    private func complete(correct: Int, mistakes: Int, hints: Int) {
        navigation.completeCurrentStage(thread: thread, correctCount: correct, mistakeCount: mistakes, hintsUsed: hints)
        actions.success()
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
            ProgressView(value: navigation.progressFraction(for: thread))
                .tint(MatherTheme.accent)
                .accessibilityLabel("Gameplay thread progress")
        }
    }

    private func controls(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Button("Back") { navigation.goBack() }
                .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                .disabled(!navigation.canGoBack)
            Button("Retry") { navigation.retryCurrentStage() }
                .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
            Spacer(minLength: 0)
            Text("Score \(navigation.summary().correctCount)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink.opacity(0.8))
                .accessibilityLabel("Current score \(navigation.summary().correctCount)")
        }
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
            Text("\(summary.correctCount) correct • \(summary.mistakeCount) review items • \(stageCount) stages")
                .font(.headline)
                .foregroundStyle(MatherTheme.ink.opacity(0.78))
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
