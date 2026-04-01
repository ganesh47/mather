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
                        Text("Make & Break to 10")
                            .font(.title2.weight(.bold))
                        Text(appModel.featureFlags.verticalSlice1Enabled ? "Practice making and breaking numbers to 10 using touch, pictures, and equations." : "Enable the activity in Settings before handing the iPad to your child.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(appModel.featureFlags.verticalSlice1Enabled ? "Play" : "Open Settings") {
                            appModel.featureFlags.verticalSlice1Enabled ? appModel.engine.showSessionConfig() : appModel.engine.showSettings()
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .accessibilityHint("Starts the make and break to ten experience in one tap.")
                    }
                }

                ViewThatFits {
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
                    VStack(spacing: 12) {
                        Button("Parent Summary") {
                            appModel.engine.showParentSummary()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.7)))

                        Button("Settings") {
                            appModel.engine.showSettings()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue))
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }
}
