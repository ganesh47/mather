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
    let contentVersion: Int
    let assetURLs: [String: URL]
    let profileID: String?
    var actions: GameplayStageFeedbackActions
    var progressStore: GameplayProgressStore?
    var onHome: @MainActor () -> Void
    var onBackToStageSurface: @MainActor () -> Void
    @State private var navigation: GameplayStageNavigationState
    @State private var round: GameplayRoundDefinition?
    @State private var stageState: Data?
    @State private var attempts: [ItemAttempt] = []
    @State private var sessionID: String = UUID().uuidString
    @State private var introductionIndex = 0
    @State private var introductionFinished = false

    init(
        thread: GameplayThreadDefinition = GameplaySampleThreads.countries,
        contentVersion: Int = 1,
        assetURLs: [String: URL] = [:],
        actions: GameplayStageFeedbackActions = GameplayStageFeedbackActions(),
        progressStore: GameplayProgressStore? = nil,
        now: Date = Date(),
        onHome: @escaping @MainActor () -> Void = {},
        onBackToStageSurface: @escaping @MainActor () -> Void = {}
    ) {
        self.actions = actions
        self.progressStore = progressStore
        self.onHome = onHome
        self.onBackToStageSurface = onBackToStageSurface
        if let checkpoint = progressStore?.checkpoint(for: thread.id),
           let saved = try? JSONDecoder().decode(GameplayThreadCheckpoint.self, from: checkpoint.payload), saved.matches(thread: thread), saved.profileID == progressStore?.activeProfileID {
            self.profileID = saved.profileID
            self.thread = saved.threadSnapshot
            self.contentVersion = saved.contentVersion
            self.assetURLs = saved.assetURLs
            _navigation = State(initialValue: saved.navigation)
            _round = State(initialValue: saved.round)
            _stageState = State(initialValue: saved.stageState)
            _attempts = State(initialValue: saved.attempts)
            _sessionID = State(initialValue: saved.sessionID)
            _introductionIndex = State(initialValue: saved.introductionIndex)
            _introductionFinished = State(initialValue: saved.introductionFinished)
        } else {
            self.profileID = progressStore?.activeProfileID
            self.thread = thread
            self.contentVersion = contentVersion
            self.assetURLs = assetURLs
            _navigation = State(initialValue: GameplayStageNavigationState(startedAt: now, currentStageStartedAt: now))
        }
    }

    @MainActor
    init(thread: GameplayThreadDefinition = GameplaySampleThreads.countries, contentVersion: Int = 1, assetURLs: [String: URL] = [:], appModel: AppModel, now: Date = Date()) {
        self.init(
            thread: thread,
            contentVersion: contentVersion,
            assetURLs: assetURLs,
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
                }
                .padding(compact ? 14 : 24)
                .padding(.bottom, compact ? 86 : 78)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                controls(compact: compact)
                    .padding(.horizontal, compact ? 14 : 24)
                    .padding(.top, compact ? 8 : 10)
                    .padding(.bottom, compact ? 10 : 12)
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(MatherTheme.panelDeep.opacity(0.12))
                            .frame(height: 1)
                    }
            }
            .background(MatherTheme.background.ignoresSafeArea())
        }
        .environment(\.learningContentAssetURLs, assetURLs)
        .navigationTitle(thread.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { prepareRoundIfNeeded() }
    }

    @ViewBuilder
    private func activeStage(compact: Bool) -> some View {
        if navigation.isComplete(for: thread) {
            GameplayThreadSummaryView(summary: navigation.summary(), stageCount: thread.stages.count)
        } else if let stage = navigation.activeStage(in: thread), let round, round.stageID == stage.id {
            if round.items.isEmpty {
                VStack(spacing: 16) {
                    Text("You explored all these clues!").font(.title2.bold())
                    Button("Next activity") { complete(attempts: []) }
                        .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                }.onAppear { actions.speak("You explored all these clues. Tap Next activity when ready.") }
            } else if stage.kind != .flashcards && !introductionFinished {
                introduction(stage: stage, round: round, compact: compact)
            } else {
                let attemptID = navigation.stageAttemptID
                let progress: ([ItemAttempt], Data) -> Void = { events, state in
                    guard navigation.stageAttemptID == attemptID else { return }
                    capture(events)
                    stageState = state
                    saveCheckpoint()
                }
                switch stage.kind {
                case .flashcards:
                    FlashcardStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact, stateData: stageState, onProgress: progress) { complete(attempts: $0) }
                case .easyMemory:
                    MemoryStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact, stateData: stageState, onProgress: progress) { complete(attempts: $0) }
                case .flipMemory:
                    FlipMemoryStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact, stateData: stageState, onProgress: progress) { complete(attempts: $0) }
                case .bondBlast:
                    BondBlastStageView(thread: thread, stage: stage, round: round, actions: actions, compact: compact, stateData: stageState, onProgress: progress) { complete(attempts: $0) }
                case .multipleChoice:
                    MultipleChoiceStageView(thread: thread, stage: stage, round: round, attemptID: attemptID, actions: actions, compact: compact, stateData: stageState, onProgress: progress) { complete(attempts: $0) }
                }
            }
        } else {
            ProgressView().onAppear { prepareRoundIfNeeded() }
        }
    }

    /// Teach exactly the selected entity/property set before assessing it.
    private func introduction(stage: GameplayStageDefinition, round: GameplayRoundDefinition, compact: Bool) -> some View {
        let index = min(introductionIndex, max(round.items.count - 1, 0))
        let item = round.items.indices.contains(index) ? round.items[index] : nil
        let entity = thread.entities.first { $0.id == item?.entityID }
        let property = entity?.properties.first { $0.id == item?.propertyID }
        let detail = [entity?.summary, property?.value, property?.explanation].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ". ")
        let spoken = (entity?.name ?? "Explore") + ". " + detail
        return VStack(spacing: compact ? 12 : 18) {
            GameplayStageTitle(title: "Look and listen", prompt: "Explore these clues. Then try a playful challenge.", detail: "\(index + 1) of \(round.items.count)")
            if let entity {
                GameplayDisplayCard(item: GameplayDisplayItem(id: "introduce-\(item?.id ?? entity.id)", entityID: entity.id,
                    title: entity.name, subtitle: detail, visualKey: entity.visualKey, visualAssetName: entity.visualAssetName,
                    visualShapeKey: entity.visualShapeKey), compact: compact, showsSubtitle: true, prominence: .featured)
            }
            HStack(spacing: 12) {
                Button("Listen again") { actions.speak(spoken) }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                Button(index >= round.items.count - 1 ? "Let’s play" : "Next clue") {
                    if index >= round.items.count - 1 { introductionFinished = true }
                    else { introductionIndex += 1 }
                    saveCheckpoint()
                }
                .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                .accessibilityIdentifier("GameplayIntroductionNextButton")
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
        .id("introduction-\(index)")
        .onAppear {
            actions.speak(spoken)
            if let item, !attempts.contains(where: { $0.stageID == stage.id && $0.entityID == item.entityID && $0.propertyID == item.propertyID && $0.outcome == .exposure }) {
                capture([ItemAttempt(activityID: thread.id, conceptID: item.propertyTypeID ?? thread.id,
                    entityID: item.entityID, propertyID: item.propertyID, stageID: stage.id, outcome: .exposure)])
            }
            saveCheckpoint()
        }
    }

    private func prepareRoundIfNeeded() {
        guard !navigation.isComplete(for: thread), let stage = navigation.activeStage(in: thread) else { return }
        if round?.stageID == stage.id { return }
        let seed = UInt64(navigation.activeStageIndex + navigation.stageAttemptNonce * 97 + 17)
        round = progressStore?.makeRound(thread: thread, stage: stage, seed: seed, contentVersion: contentVersion)
            ?? SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: seed)
        stageState = nil
        introductionIndex = 0
        introductionFinished = stage.kind == .flashcards
        saveCheckpoint()
    }

    private func capture(_ events: [ItemAttempt]) {
        guard profileID == progressStore?.activeProfileID else { return }
        let existingIDs = Set(attempts.map(\.id))
        let contextualized = events.filter { !existingIDs.contains($0.id) }
            .map { $0.withContext(profileID: profileID, sessionID: sessionID, contentVersion: contentVersion) }
        let normalized = ActivityEvidenceNormalizer.normalized(contextualized, after: attempts)
        attempts.append(contentsOf: normalized)
        progressStore?.recordAttempts(normalized, sessionID: sessionID)
    }

    private func saveCheckpoint() {
        guard profileID == progressStore?.activeProfileID else { return }
        guard !navigation.isComplete(for: thread) else { return }
        let state = GameplayThreadCheckpoint(navigation: navigation, round: round, stageState: stageState, attempts: attempts,
            introductionIndex: introductionIndex, introductionFinished: introductionFinished, sessionID: sessionID,
            threadSnapshot: thread, contentVersion: contentVersion, assetURLs: assetURLs, profileID: profileID)
        guard let data = try? JSONEncoder().encode(state) else { return }
        progressStore?.saveCheckpoint(QuestCheckpoint(activityID: thread.id, sessionID: sessionID, startedAt: navigation.startedAt, payload: data, profileID: profileID))
    }

    private func complete(attempts events: [ItemAttempt]) {
        guard profileID == progressStore?.activeProfileID else { return }
        capture(events)
        let correct = events.filter { $0.outcome == .independentCorrect || $0.outcome == .supportedCorrect }.count
        let mistakes = events.filter { $0.outcome == .incorrect }.count
        let hints = events.filter { $0.outcome == .help }.count
        navigation.completeCurrentStage(thread: thread, correctCount: correct, mistakeCount: mistakes, hintsUsed: hints)
        progressStore?.saveActivityResult(ActivityResult(id: sessionID, activityID: thread.id, title: thread.title,
            startedAt: navigation.startedAt, attempts: attempts, completedStageIDs: navigation.stageResults.map(\.stageID), profileID: profileID, contentVersion: contentVersion))
        round = nil
        stageState = nil
        if navigation.isComplete(for: thread) {
            progressStore?.clearCheckpoint(for: thread.id)
            actions.speak("You explored every activity! Well done. You can play again or choose another adventure.")
        } else {
            prepareRoundIfNeeded()
        }
        actions.success()
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
        if navigation.isComplete(for: thread) {
            onBackToStageSurface()
        } else if navigation.canGoBack {
            navigation.goBack()
            round = nil
            prepareRoundIfNeeded()
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
        HStack(spacing: 10) {
            Button(navigation.isComplete(for: thread) ? "Play again" : "Retry") {
                if navigation.isComplete(for: thread) {
                    sessionID = UUID().uuidString
                    attempts = []
                    navigation = GameplayStageNavigationState()
                } else {
                    navigation.retryCurrentStage(in: thread)
                }
                round = nil
                prepareRoundIfNeeded()
            }
                .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                .accessibilityLabel("Retry current stage")
                .accessibilityIdentifier("GameplayStageRetryButton")
            Spacer(minLength: 0)
            scoreText
        }
    }

    private var scoreText: some View {
        let text = navigation.stageResults.isEmpty ? "Exploring" : "\(navigation.stageResults.count) activities explored"
        return Text(text)
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .foregroundStyle(MatherTheme.ink.opacity(0.8))
            .accessibilityLabel(navigation.stageResults.isEmpty ? "Learning stage in progress" : "\(navigation.stageResults.count) activities explored")
            .accessibilityIdentifier("GameplayStageScoreLabel")
    }
}

private struct GameplayThreadSummaryView: View {
    let summary: GameplayScoreSummary
    let stageCount: Int

    var body: some View {
        VStack(spacing: 14) {
            Text("★ ★ ★")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(MatherTheme.warm)
                .accessibilityLabel("Three celebration stars")
            Text("Adventure complete!")
                .font(.title.bold())
                .foregroundStyle(MatherTheme.ink)
            Text("You explored \(stageCount) activities.")
                .font(.headline)
                .foregroundStyle(MatherTheme.ink.opacity(0.78))
            Text("Learning grows each time you play.")
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
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(minWidth: 80, minHeight: GameplayStageRenderSupport.touchTargetSize(compact: compact))
            .padding(.horizontal, compact ? 14 : 18)
            .foregroundStyle(kind == .primary ? .white : MatherTheme.ink)
            .background(
                Capsule().fill(kind == .primary ? MatherTheme.accent.opacity(configuration.isPressed ? 0.78 : 1) : MatherTheme.card)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.86 : 1) : 0.45)
    }
}

#Preview("Gameplay stages") {
    NavigationStack {
        GameplayThreadView()
    }
}
