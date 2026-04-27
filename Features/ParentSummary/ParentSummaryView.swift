import Observation
import SwiftUI

struct ParentSummaryView: View {
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]
    let gameSessions: [StoredGameSession]
    let profiles: [StoredKidProfile]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let digest = appModel.telemetryWriter.digest(from: summaries)
        let recentRows = ParentSummaryHistoryRow.recentRows(summaries: summaries, gameSessions: gameSessions, limit: 5)

        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    CardSurface {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Parent Summary")
                                .font(.largeTitle.weight(.black))
                            Text(digest.objectiveTitle)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }
                    }

                    if summaries.isEmpty && gameSessions.isEmpty {
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
                            columns: ResponsiveLayout.statColumns(for: horizontalSizeClass),
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

                        if ResponsiveLayout.isWide(horizontalSizeClass) {
                            LazyVGrid(
                                columns: ResponsiveLayout.parentSummarySupportingColumns(for: horizontalSizeClass),
                                alignment: .leading,
                                spacing: 16
                            ) {
                                profileOverviewCard(summaries: summaries, gameSessions: gameSessions)
                                nextTargetCard(digest: digest)
                            }
                            recentSessionsCard(rows: recentRows, totalCount: summaries.count + gameSessions.count)
                        } else {
                            profileOverviewCard(summaries: summaries, gameSessions: gameSessions)
                            recentSessionsCard(rows: recentRows, totalCount: summaries.count + gameSessions.count)
                            nextTargetCard(digest: digest)
                        }
                    }

                    LazyVGrid(
                        columns: ResponsiveLayout.parentActionColumns(for: horizontalSizeClass),
                        spacing: 16
                    ) {
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
                .padding(ResponsiveLayout.contentPadding(for: horizontalSizeClass))
                .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
                .frame(maxWidth: .infinity)
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
            return "\(totalCount) saved locally across all games"
        }
        return "Showing latest \(visibleCount) of \(totalCount) saved locally across all games"
    }

    private func profileOverviewCard(summaries: [StoredSessionSummary], gameSessions: [StoredGameSession]) -> some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("Profile overview")
                    .font(.title3.weight(.bold))
                ForEach(profiles, id: \.id) { profile in
                    let count = summaries.filter { $0.profileId == profile.id }.count + gameSessions.filter { $0.profileId == profile.id }.count
                    HStack {
                        Text("\(profile.emoji) \(profile.name)")
                        Spacer()
                        Text("\(count) sessions")
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }
            }
        }
    }

    private func nextTargetCard(digest: ParentDigest) -> some View {
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

    private func recentSessionsCard(rows: [ParentSummaryHistoryRow], totalCount: Int) -> some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent sessions")
                    .font(.title3.weight(.bold))
                Text(historyCaption(totalCount: totalCount, visibleCount: rows.count))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Session \(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MatherTheme.accent)
                            Text(row.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                            if let profile = profiles.first(where: { $0.id == row.profileId }) {
                                Text("\(profile.emoji) \(profile.name)")
                                    .font(.caption)
                                    .foregroundStyle(MatherTheme.cardSubtitle)
                            }
                            Text(row.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.weight(.semibold))
                            Text(row.detail)
                                .font(.caption)
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }
                        Spacer()
                        if index == 0 {
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
                    .background(index == 0 ? MatherTheme.warm.opacity(0.2) : Color.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("parent-summary-session-\(index)")
                }
            }
        }
    }

}


struct ParentSummaryHistoryRow: Identifiable, Equatable {
    enum Source: Equatable {
        case makeAndBreak
        case game
    }

    var id: String
    var source: Source
    var profileId: String
    var title: String
    var startedAt: Date
    var detail: String

    static func recentRows(
        summaries: [StoredSessionSummary],
        gameSessions: [StoredGameSession],
        limit: Int
    ) -> [ParentSummaryHistoryRow] {
        let makeAndBreakRows = summaries.map { summary in
            ParentSummaryHistoryRow(
                id: "make-break-\(summary.sessionId)",
                source: .makeAndBreak,
                profileId: summary.profileId,
                title: summary.objectiveTitle,
                startedAt: summary.startedAt,
                detail: "\(summary.problemsCompleted) problems · \(Int(summary.firstAttemptAccuracy * 100))% first try"
            )
        }

        let gameRows = gameSessions.map { session in
            ParentSummaryHistoryRow(
                id: "game-\(session.id)",
                source: .game,
                profileId: session.profileId,
                title: session.gameName,
                startedAt: session.startedAt,
                detail: "\(session.scoreValue) \(session.scoreLabel)"
            )
        }

        return (makeAndBreakRows + gameRows)
            .sorted { $0.startedAt > $1.startedAt }
            .prefix(limit)
            .map { $0 }
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
