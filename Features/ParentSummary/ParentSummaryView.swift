import Observation
import SwiftUI

struct ParentSummaryView: View {
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]

    var body: some View {
        let filtered = summaries.filter { $0.profileId == appModel.activeProfile?.id }
        let digest = appModel.telemetryWriter.digest(from: filtered)
        let recentSummaries = Array(filtered.prefix(5))

        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    CardSurface {
                        VStack(alignment: .leading, spacing: 8) {
                            if let profile = appModel.activeProfile {
                                HStack(spacing: 8) {
                                    Text(profile.emoji)
                                        .font(.title2)
                                    Text(profile.name)
                                        .font(.title2.weight(.black))
                                        .foregroundStyle(MatherTheme.ink)
                                }
                            }
                            Text("Parent Summary")
                                .font(.largeTitle.weight(.black))
                            Text(digest.objectiveTitle)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }
                    }

                    if filtered.isEmpty {
                        CardSurface {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 44))
                                    .foregroundStyle(MatherTheme.accent)
                                Text("No sessions yet")
                                    .font(.title3.weight(.bold))
                                Text("Complete a session with your child and the summary will appear here.")
                                    .font(.subheadline)
                                    .foregroundStyle(MatherTheme.cardSubtitle)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            StatTile(
                                value: "\(digest.problemsCompleted)",
                                label: "Problems done",
                                icon: "checkmark.circle.fill",
                                color: MatherTheme.accent
                            )
                            StatTile(
                                value: "\(Int(digest.firstAttemptAccuracy * 100))%",
                                label: "First try",
                                icon: "star.fill",
                                color: MatherTheme.warm
                            )
                            StatTile(
                                value: "\(digest.transferCorrectCount)",
                                label: "Transfers",
                                icon: "arrow.triangle.2.circlepath",
                                color: MatherTheme.softBlue
                            )
                            StatTile(
                                value: paceLabel(digest.medianLatencyMs),
                                label: "Avg pace",
                                icon: "clock.fill",
                                color: Color.purple.opacity(0.7)
                            )
                        }

                        CardSurface {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recent sessions")
                                    .font(.title3.weight(.bold))
                                Text(historyCaption(totalCount: filtered.count, visibleCount: recentSummaries.count))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(MatherTheme.cardSubtitle)
                                ForEach(Array(recentSummaries.enumerated()), id: \.element.sessionId) { index, summary in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Session \(index + 1)")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(MatherTheme.accent)
                                            Text(summary.startedAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(.subheadline.weight(.semibold))
                                            Text("\(summary.problemsCompleted) problems · \(Int(summary.firstAttemptAccuracy * 100))% first try")
                                                .font(.caption)
                                                .foregroundStyle(MatherTheme.cardSubtitle)
                                        }
                                        Spacer()
                                        if summary.sessionId == filtered.first?.sessionId {
                                            Text("Latest")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(MatherTheme.accent)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(MatherTheme.accent.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(10)
                                    .background(summary.sessionId == filtered.first?.sessionId ? MatherTheme.warm.opacity(0.2) : Color.secondary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .accessibilityElement(children: .combine)
                                    .accessibilityIdentifier("parent-summary-session-\(index)")
                                }
                            }
                        }

                        CardSurface {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(MatherTheme.warm)
                                    .font(.title3)
                                Text(digest.nextTargetHint)
                                    .font(.subheadline.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    HStack(spacing: 16) {
                        Button("Switch Profile") {
                            appModel.activeProfile = nil
                            appModel.engine.showHome()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.accent.opacity(0.18)))

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

    private func paceLabel(_ ms: Int) -> String {
        guard ms > 0 else { return "—" }
        let seconds = ms / 1000
        return seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m \(seconds % 60)s"
    }

    private func historyCaption(totalCount: Int, visibleCount: Int) -> String {
        guard totalCount > 0 else { return "No saved sessions yet." }
        if totalCount == visibleCount {
            return "\(totalCount) saved locally"
        }
        return "Showing latest \(visibleCount) of \(totalCount) saved locally"
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 34, weight: .black, design: .rounded))
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
