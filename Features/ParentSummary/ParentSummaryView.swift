import Observation
import SwiftUI

struct ParentSummaryView: View {
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]

    var body: some View {
        let digest = appModel.telemetryWriter.digest(from: summaries)

        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Parent Summary")
                                .font(.largeTitle.weight(.black))
                            Text(digest.objectiveTitle)
                                .font(.title2.weight(.bold))
                            Text("Problems completed: \(digest.problemsCompleted)")
                            Text("First try accuracy: \(Int(digest.firstAttemptAccuracy * 100))%")
                            Text("Transfer correct: \(digest.transferCorrectCount)")
                            Text("Median pace: \(digest.medianLatencyMs) ms")
                            Text("Next step: \(digest.nextTargetHint)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent sessions")
                                .font(.title2.weight(.bold))
                            if summaries.isEmpty {
                                Text("No sessions yet. Run one child session to populate history.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(Array(summaries.prefix(5))) { summary in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(summary.startedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.headline.weight(.semibold))
                                        Text("Completed \(summary.problemsCompleted) problems, accuracy \(Int(summary.firstAttemptAccuracy * 100))%")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(summary.sessionId == summaries.first?.sessionId ? MatherTheme.warm.opacity(0.45) : Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                        }
                    }

                    HStack(spacing: 16) {
                        Button("Settings") {
                            appModel.engine.showSettings()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.7)))

                        Button("Home") {
                            appModel.engine.showHome()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.7)))
                    }
                }
                .padding(24)
            }
        }
    }
}
