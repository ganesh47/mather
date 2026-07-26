import SwiftUI

struct MatherTVRootView: View {
    @FocusState private var focusedAction: MatherTVAction.ID?
    @State private var activeGame: MatherTVAction?
    @State private var lastFocusedAction = MatherTVAction.memory

    private let actions = MatherTVAction.allCases

    var body: some View {
        Group {
            if let activeGame {
                gameView(for: activeGame)
                    .id(activeGame.id)
                    .overlay(alignment: .top) {
                        Label("Menu  ·  All games", systemImage: "chevron.backward")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(.black.opacity(0.26), in: Capsule())
                            .padding(.top, 28)
                            .accessibilityHidden(true)
                    }
                    .onExitCommand {
                        exitGame(activeGame)
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

            VStack(alignment: .leading, spacing: 46) {
                header

                HStack(spacing: 30) {
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

                Label("Swipe to choose, then press select to play.", systemImage: "hand.tap.fill")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.66))
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.vertical, 76)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose a game")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("One game at a time. Press Menu anytime to come back here.")
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func gameView(for action: MatherTVAction) -> some View {
        switch action {
        case .memory:
            MemoryGalleryTVView()
        case .angle:
            AngleArcadeTVView()
        case .sprint:
            SumSprintPartyTVView()
        }
    }

    private func openGame(_ action: MatherTVAction) {
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
        guard activeGame == nil else { return }
        Task { @MainActor in
            focusedAction = lastFocusedAction.id
        }
    }
}

private struct MatherTVGameCard: View {
    let action: MatherTVAction
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: action.symbolName)
                .font(.system(size: 58, weight: .bold))
                .frame(width: 96, height: 96)
                .foregroundStyle(isFocused ? Color(red: 0.09, green: 0.13, blue: 0.19) : .white)
                .background(isFocused ? .white : .white.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(action.title)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(isFocused ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                .lineLimit(2)

            Text(action.subtitle)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(isFocused ? Color(red: 0.15, green: 0.20, blue: 0.29) : .white.opacity(0.68))

            Spacer(minLength: 0)

            Label("Play", systemImage: "play.fill")
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(isFocused ? Color(red: 0.08, green: 0.28, blue: 0.39) : .white.opacity(0.72))
        }
        .padding(32)
        .frame(width: 500, height: 390, alignment: .topLeading)
        .background(isFocused ? .white : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(isFocused ? Color(red: 0.55, green: 0.88, blue: 1.0) : .white.opacity(0.14), lineWidth: isFocused ? 4 : 2)
        )
        .scaleEffect(isFocused ? 1.045 : 1.0)
        .shadow(color: .black.opacity(isFocused ? 0.36 : 0.16), radius: isFocused ? 28 : 10, x: 0, y: isFocused ? 18 : 8)
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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memory: "Memory Gallery"
        case .angle: "Angle Arcade"
        case .sprint: "Sum Sprint Party"
        }
    }

    var subtitle: String {
        switch self {
        case .memory: "Picture-name matching"
        case .angle: "Predict, aim, launch"
        case .sprint: "Big answer tiles"
        }
    }

    var symbolName: String {
        switch self {
        case .memory: "rectangle.stack.fill"
        case .angle: "scope"
        case .sprint: "square.grid.2x2.fill"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .memory: "Opens the Memory Gallery picture matching game."
        case .angle: "Opens the Angle Arcade aiming game."
        case .sprint: "Opens the Sum Sprint Party answer game."
        }
    }
}

#Preview {
    MatherTVRootView()
}
