import SwiftUI

struct SessionConfigView: View {
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
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

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
                    }
                }

                Button("Back to Home") {
                    appModel.engine.showHome()
                }
                .font(.headline.weight(.semibold))

                Spacer()
            }
            .padding(24)
        }
    }
}
