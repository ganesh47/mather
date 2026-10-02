import SwiftUI

struct MatherTVRootView: View {
    @State private var narration = TVNarrationController()
    @State private var learningStore = Self.makeLearningStore()
    @State private var showsFamilyGuide = ProcessInfo.processInfo.arguments.contains("-tv-family-ui-test")
    @FocusState private var focusedAction: MatherTVAction.ID?
    @State private var activeGame: MatherTVAction? = ProcessInfo.processInfo.arguments.contains("-angle-arcade-ui-test") ? .angle : nil
    @State private var lastFocusedAction = MatherTVAction.memory

    private let actions = MatherTVAction.allCases
    private let columns = Array(repeating: GridItem(.fixed(520), spacing: 28), count: 3)

    var body: some View {
        Group {
            if showsFamilyGuide {
                TVFamilyLearningView(store: learningStore) {
                    showsFamilyGuide = false
                    focusLauncher()
                }
            } else if let activeGame {
                gameView(for: activeGame)
                    .id(activeGame.id + "-" + learningStore.context.profileID)
                    .overlay(alignment: .top) {
                        if activeGame != .angle {
                        Label("Menu  ·  All games", systemImage: "chevron.backward")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(.black.opacity(0.30), in: Capsule())
                            .padding(.top, 28)
                            .accessibilityHidden(true)
                        }
                    }
                    .onExitCommand {
                        if activeGame != .angle { exitGame(activeGame) }
                    }
            } else {
                launcher
            }
        }
        .onAppear {
            focusLauncher()
        }
    }

    private var launcher: some View {
        ZStack {
            MatherTVBackdrop()

            VStack(alignment: .leading, spacing: 26) {
                header

                LazyVGrid(columns: columns, alignment: .leading, spacing: 26) {
                    ForEach(actions) { action in
                        Button {
                            openGame(action)
                        } label: {
                            MatherTVGameCard(
                                action: action,
                                isFocused: focusedAction == action.id
                            )
                        }
                        .buttonStyle(.plain)
                        .focused($focusedAction, equals: action.id)
                        .accessibilityLabel(action.title)
                        .accessibilityHint(action.accessibilityHint)
                        .accessibilityIdentifier("tv-mode-\(action.id)")
                    }
                }

                HStack(spacing: 14) {
                    Image(systemName: "hand.tap.fill")
                    Text("Swipe to explore")
                    Text("·")
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Press select to play")
                }
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))

                HStack(spacing: 24) {
                    Button("Learners & family guide") {
                        focusedAction = nil
                        showsFamilyGuide = true
                    }.buttonStyle(TVFamilyButtonStyle())
                        .accessibilityIdentifier("tv-family-panel")
                    Text("Playing: \(learningStore.context.name)")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .accessibilityIdentifier("tv-launcher-learner")
                }
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.vertical, 54)
        }
        .onAppear {
            narration.presentPrompt("Welcome to Mather Game Night. Swipe to choose a game, then press select to play. Press Play Pause to hear these instructions again.")
        }
        .onChange(of: focusedAction) { _, actionID in
            let action = actions.first { $0.id == actionID }
            narration.focus(action.map { "\($0.title). \($0.subtitle). Press select to play." })
        }
        .onPlayPauseCommand { narration.repeatPrompt() }
        .onDisappear { narration.stop() }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Mather Game Night")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Five calm, big-screen games for curious minds.")
                    .font(.system(size: 27, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()

            Label("5 games", systemImage: "sparkles")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.78, green: 0.94, blue: 0.66))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white.opacity(0.08), in: Capsule())
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func gameView(for action: MatherTVAction) -> some View {
        switch action {
        case .memory:
            MemoryGalleryTVView()
        case .angle:
            AngleArcadeTVView(onExit: { exitGame(.angle) })
        case .sprint:
            SumSprintPartyTVView(profileID: learningStore.context.profileID, familyMode: learningStore.context.familyMode,
                onAttempt: { _ = learningStore.record($0) }, onResult: { _ = learningStore.save($0) })
        case .compare:
            CompareCampTVView()
        case .shapes:
            ShapeDetectiveTVView()
        }
    }

    private func openGame(_ action: MatherTVAction) {
        narration.stop()
        lastFocusedAction = action
        focusedAction = nil
        activeGame = action
    }

    private func exitGame(_ action: MatherTVAction) {
        lastFocusedAction = action
        activeGame = nil
        focusLauncher()
    }

    private func focusLauncher() {
        guard activeGame == nil, !showsFamilyGuide else { return }
        Task { @MainActor in
            focusedAction = lastFocusedAction.id
        }
    }

    private static func makeLearningStore() -> TVLearningStore {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-tv-family-ui-test") else { return TVLearningStore() }
        let suite = "mather.tvFamily.uiTests"
        let defaults = UserDefaults(suiteName: suite)!
        if arguments.contains("-tv-family-reset") { defaults.removePersistentDomain(forName: suite) }
        let store = TVLearningStore(defaults: defaults)
        if store.learners.isEmpty {
            _ = store.addLearner(name: "Alex")
            let profileID = store.context.profileID
            let attempt = ItemAttempt(activityID: "tv-sum-sprint", conceptID: "number-parts", entityID: "2+3", stageID: "practice",
                outcome: .supportedCorrect, profileID: profileID, sessionID: "fixture", contentVersion: 1,
                itemVariantID: "trays-2-3", appHintUsed: true, isFreshProbe: false, adultHelp: .unknown)
            _ = store.save(ActivityResult(id: "fixture", activityID: attempt.activityID, title: "Sum Sprint", startedAt: Date(), attempts: [attempt], completedStageIDs: ["practice"], profileID: profileID, contentVersion: 1))
            _ = store.addLearner(name: "Jamie")
            store.selectLearner(nil)
        }
        return store
    }
}

private struct MatherTVGameCard: View {
    let action: MatherTVAction
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: action.symbolName)
                .font(.system(size: 44, weight: .bold))
                .frame(width: 82, height: 82)
                .foregroundStyle(isFocused ? Color(red: 0.08, green: 0.13, blue: 0.19) : action.accent)
                .background(isFocused ? action.accent : .white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 9) {
                Text(action.title)
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(isFocused ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(action.subtitle)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(isFocused ? Color(red: 0.17, green: 0.22, blue: 0.30) : .white.opacity(0.72))
                    .lineLimit(1)

                Label(action.skill, systemImage: "star.fill")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isFocused ? Color(red: 0.08, green: 0.34, blue: 0.42) : action.accent.opacity(0.88))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .frame(width: 520, height: 230, alignment: .leading)
        .background(isFocused ? .white : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(isFocused ? action.accent : .white.opacity(0.16), lineWidth: isFocused ? 4 : 2)
        )
        .scaleEffect(isFocused ? 1.045 : 1.0)
        .shadow(color: .black.opacity(isFocused ? 0.36 : 0.14), radius: isFocused ? 26 : 8, x: 0, y: isFocused ? 16 : 6)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isFocused)
    }
}

struct MatherTVBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.13),
                Color(red: 0.08, green: 0.20, blue: 0.24),
                Color(red: 0.13, green: 0.10, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            VStack(spacing: 0) {
                Color.white.opacity(0.08)
                    .frame(height: 1)
                Spacer()
                Color.white.opacity(0.10)
                    .frame(height: 1)
            }
            .padding(.vertical, 116)
        }
    }
}

private enum MatherTVAction: String, CaseIterable, Identifiable {
    case memory
    case angle
    case sprint
    case compare
    case shapes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memory: "Memory Gallery"
        case .angle: "Angle Arcade"
        case .sprint: "Sum Sprint Party"
        case .compare: "Compare Camp"
        case .shapes: "Shape Detective"
        }
    }

    var subtitle: String {
        switch self {
        case .memory: "Match pictures and names"
        case .angle: "Predict, aim, launch"
        case .sprint: "Build parts, try a new puzzle"
        case .compare: "Explore 24 learning camps"
        case .shapes: "Trace properties, explore shapes"
        }
    }

    var skill: String {
        switch self {
        case .memory: "Recall"
        case .angle: "Angles"
        case .sprint: "Addition"
        case .compare: "Build, compare & discover"
        case .shapes: "Geometry"
        }
    }

    var symbolName: String {
        switch self {
        case .memory: "rectangle.stack.fill"
        case .angle: "scope"
        case .sprint: "plus.forwardslash.minus"
        case .compare: "scale.3d"
        case .shapes: "square.on.circle.fill"
        }
    }

    var accent: Color {
        switch self {
        case .memory: Color(red: 0.55, green: 0.88, blue: 1.0)
        case .angle: Color(red: 1.0, green: 0.66, blue: 0.40)
        case .sprint: Color(red: 0.78, green: 0.94, blue: 0.66)
        case .compare: Color(red: 0.98, green: 0.78, blue: 0.36)
        case .shapes: Color(red: 0.86, green: 0.67, blue: 1.0)
        }
    }

    var accessibilityHint: String {
        switch self {
        case .memory: "Opens the Memory Gallery picture matching game."
        case .angle: "Opens the Angle Arcade aiming game."
        case .sprint: "Opens the Sum Sprint Party addition game."
        case .compare: "Opens 24 Compare Camp adventures with counting, matching, and number signs."
        case .shapes: "Opens the Shape Detective geometry game."
        }
    }
}

#Preview {
    MatherTVRootView()
}
