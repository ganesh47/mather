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
    ThemeOption(id: "space", name: "Planets", iconSystemName: "sparkles", color: MatherTheme.accent),
]

struct SessionConfigView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topExitBar

                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: horizontalSizeClass == .regular ? 24 : 18) {
                            setupCard

                            if horizontalSizeClass == .regular {
                                whatHappensNextPanel
                            }
                        }
                        .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(minHeight: horizontalSizeClass == .regular ? max(proxy.size.height - 24, 0) : nil, alignment: .center)
                        .padding(.horizontal, 24)
                        .padding(.top, horizontalSizeClass == .regular ? 20 : 14)
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.visible)
                }
            }
        }
    }

    private var topExitBar: some View {
        HStack {
            Button {
                appModel.engine.showHome()
            } label: {
                Label("Back to Home", systemImage: "chevron.left")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.softBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(MatherTheme.softBlue.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("back-to-home-button")

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(MatherTheme.background.opacity(0.94))
    }

    private var setupCard: some View {
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
                    .accessibilityIdentifier("session-setup-theme-section")

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
                .accessibilityIdentifier("problems-stepper")

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Target numbers")
                        .font(.title3.weight(.semibold))
                    Text("Choose the largest number this session can ask for.")
                        .font(.subheadline)
                        .foregroundStyle(MatherTheme.ink.opacity(0.6))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                        ForEach(ParentTargetCap.quickPicks, id: \.self) { maxTarget in
                            targetCapButton(maxTarget: maxTarget)
                        }
                    }
                }
                .accessibilityIdentifier("target-cap-section")

                Toggle("Speak prompts", isOn: Binding(
                    get: { appModel.featureFlags.audioEnabled },
                    set: {
                        appModel.featureFlags.audioEnabled = $0
                        appModel.engine.updateConfig(audioEnabled: $0)
                    }
                ))
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("speak-prompts-toggle")

                Button("Start Session") {
                    appModel.engine.startSession()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("start-session-button")
            }
        }
    }

    private var whatHappensNextPanel: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("What happens next")
                    .font(.title3.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                setupStep(icon: "hand.tap.fill", title: "Make it", detail: "Build the number with counters.")
                setupStep(icon: "scalemass.fill", title: "Gravity Split", detail: "Split it into two balanced parts.")
                setupStep(icon: "square.grid.2x2.fill", title: "Sum Sprint", detail: "Match sums to totals.")
                setupStep(icon: "bolt.fill", title: "Bond Blast", detail: "Finish by finding all number bonds.")
            }
        }
        .accessibilityIdentifier("session-setup-next-steps-panel")
    }

    private func setupStep(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.accent)
                .frame(width: 30, height: 30)
                .background(MatherTheme.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
        }
    }

    private func targetCapButton(maxTarget: Int) -> some View {
        let normalizedTarget = ParentTargetCap.normalize(maxTarget)
        let isSelected = appModel.engine.config.parentTargetCap == normalizedTarget
        return Button {
            appModel.engine.updateConfig(minTarget: 1, maxTarget: normalizedTarget)
        } label: {
            VStack(spacing: 6) {
                Text("Up to")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink.opacity(0.55))
                Text("\(normalizedTarget)")
                    .font(.title2.weight(.black))
                    .foregroundStyle(isSelected ? MatherTheme.warm : MatherTheme.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? MatherTheme.warm.opacity(0.12) : Color.secondary.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(isSelected ? MatherTheme.warm : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("target-cap-up-to-\(normalizedTarget)")
        .accessibilityLabel("Target numbers up to \(normalizedTarget)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
        .accessibilityLabel("\(option.name) theme")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
