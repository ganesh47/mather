import SwiftUI

struct MatherTVRootView: View {
    @FocusState private var focusedAction: MatherTVAction.ID?
    @State private var activeGame: MatherTVAction?
    @State private var lastFocusedAction = MatherTVAction.memory

    private let actions = MatherTVAction.allCases
    private let columns = Array(repeating: GridItem(.fixed(520), spacing: 28), count: 3)

    var body: some View {
        Group {
            if let activeGame {
                gameView(for: activeGame)
                    .id(activeGame.id)
                    .overlay(alignment: .top) {
                        Label("Menu  ·  All games", systemImage: "chevron.backward")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(.black.opacity(0.30), in: Capsule())
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
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.vertical, 54)
        }
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
            AngleArcadeTVView()
        case .sprint:
            SumSprintPartyTVView()
        case .compare:
            CompareCampTVView()
        case .shapes:
            ShapeDetectiveTVView()
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
        case .sprint: "Build addition streaks"
        case .compare: "Spot the bigger group"
        case .shapes: "Solve shape clues"
        }
    }

    var skill: String {
        switch self {
        case .memory: "Recall"
        case .angle: "Angles"
        case .sprint: "Addition"
        case .compare: "Number sense"
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
        case .compare: "Opens the Compare Camp number sense game."
        case .shapes: "Opens the Shape Detective geometry game."
        }
    }
}

#Preview {
    MatherTVRootView()
}
