import SwiftUI

struct SessionSummaryView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                CardSurface {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Session complete")
                            .font(.largeTitle.weight(.black))
                        Text(appModel.engine.feedbackMessage)
                            .font(.title3)
                        if let summary = appModel.engine.completedSummary {
                            Text("Problems completed: \(summary.problemsCompleted)")
                            Text("First try accuracy: \(Int(summary.firstAttemptAccuracy * 100))%")
                            Text("Export file: \(summary.exportFileName)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button("Play again") {
                    appModel.engine.showSessionConfig()
                }
                .buttonStyle(PrimaryActionButtonStyle())

                HStack(spacing: 16) {
                    Button("Parent summary") {
                        appModel.engine.showParentSummary()
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.75)))

                    Button("Done") {
                        appModel.engine.showHome()
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.75)))
                }

                Spacer()
            }
            .padding(24)
        }
    }
}
