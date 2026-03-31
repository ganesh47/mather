import SwiftUI

struct HomeView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mather")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                    Text("Make and break numbers with touch-first play.")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                CardSurface {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Vertical Slice 1")
                            .font(.title2.weight(.bold))
                        Text(appModel.featureFlags.verticalSlice1Enabled ? "Play the full CPA loop from counters to equation and transfer." : "Turn on the VS1 feature flag in Settings before handing this to a child.")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Button(appModel.featureFlags.verticalSlice1Enabled ? "Play" : "Open Settings") {
                            appModel.featureFlags.verticalSlice1Enabled ? appModel.engine.showSessionConfig() : appModel.engine.showSettings()
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .accessibilityHint("Starts the make and break to ten experience in one tap.")
                    }
                }

                HStack(spacing: 16) {
                    Button("Parent Summary") {
                        appModel.engine.showParentSummary()
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.7)))

                    Button("Settings") {
                        appModel.engine.showSettings()
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue))
                }
                .frame(maxHeight: 120)

                Spacer()
            }
            .padding(24)
        }
    }
}
