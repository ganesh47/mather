import SwiftUI

private struct ThemeOption: Identifiable {
    let id: String
    let name: String
    let iconSystemName: String
    let color: Color
}

private let themeOptions: [ThemeOption] = [
    ThemeOption(id: "classic", name: "Classic", iconSystemName: "circle.fill", color: MatherTheme.warm),
    ThemeOption(id: "vehicle", name: "Vehicles", iconSystemName: "car.fill", color: MatherTheme.softBlue),
]

struct SessionConfigView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                CardSurface {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Session setup")
                            .font(.title.weight(.black))
                        Text("Keep sessions short and consistent.")
                            .font(.headline)
                            .foregroundStyle(MatherTheme.ink.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()

                        Text("Theme")
                            .font(.title3.weight(.semibold))

                        // Theme picker — two cards, selected card gets accent border.
                        // Tapping sets selectedThemeId; engine reads it at startSession().
                        HStack(spacing: 12) {
                            ForEach(themeOptions) { option in
                                themeCard(option)
                            }
                        }

                        Divider()

                        Stepper(value: Binding(
                            get: { appModel.engine.config.maxProblems },
                            set: { appModel.engine.updateConfig(problemCount: $0) }
                        ), in: 4...8) {
                            Text("Problems: \(appModel.engine.config.maxProblems)")
                                .font(.title3.weight(.semibold))
                        }

                        Toggle("Speak prompts", isOn: Binding(
                            get: { appModel.featureFlags.audioEnabled },
                            set: {
                                appModel.featureFlags.audioEnabled = $0
                                appModel.engine.updateConfig(audioEnabled: $0)
                            }
                        ))
                        .font(.title3.weight(.semibold))

                        Button("Start Session") {
                            appModel.engine.startSession()
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .accessibilityIdentifier("start-session-button")
                    }
                }

                Button("Back to Home") {
                    appModel.engine.showHome()
                }
                .font(.headline.weight(.semibold))
            }
            .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(24)
        }
    }

    private func themeCard(_ option: ThemeOption) -> some View {
        let isSelected = appModel.featureFlags.selectedThemeId == option.id
        return Button {
            appModel.featureFlags.selectedThemeId = option.id
        } label: {
            VStack(spacing: 10) {
                Image(systemName: option.iconSystemName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(option.color)
                    .frame(width: 56, height: 56)
                    .background(option.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(option.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? option.color : MatherTheme.ink.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? option.color.opacity(0.10) : Color.secondary.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(isSelected ? option.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("theme-card-\(option.id)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
