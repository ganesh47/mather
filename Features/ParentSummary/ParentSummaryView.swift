import Observation
import SwiftUI

struct ParentSummaryView: View {
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]
    let gameSessions: [StoredGameSession]
    let profiles: [StoredKidProfile]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let overview = ParentSummaryOverview.make(summaries: summaries, gameSessions: gameSessions)
        let digest = appModel.telemetryWriter.digest(from: overview.validMakeBreakSummaries)
        let recentRows = ParentSummaryHistoryRow.recentRows(summaries: summaries, gameSessions: gameSessions, limit: 5)
        let trendPoints = ParentSummaryTrendPoint.recentPoints(from: overview.validMakeBreakSummaries, limit: 6)
        let explorerLabSummary = ParentSummaryExplorerLabSummary.make(profile: appModel.explorerLabMasteryProfile)

        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Parent Summary")
                                .font(.largeTitle.weight(.black))
                            Text(overview.hasValidMakeBreakProgress ? digest.objectiveTitle : overview.headerSubtitle)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)

                            parentActionButtons
                        }
                    }

                    if !overview.hasAnyHistory {
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
                        explorerLabProgressCard(summary: explorerLabSummary)
                    } else {
                        if overview.hasValidMakeBreakProgress {
                            makeBreakScorecard(digest: digest)
                        } else {
                            makeBreakInsufficientProgressCard(hasGameScores: overview.hasGameScores)
                        }

                        if overview.hasGameScores {
                            recentGameScoresCard(scores: overview.gameScores)
                        }

                        if overview.hasValidMakeBreakProgress {
                            recentProgressCard(points: trendPoints)
                        }

                        if ResponsiveLayout.isWide(horizontalSizeClass) {
                            LazyVGrid(
                                columns: ResponsiveLayout.parentSummarySupportingColumns(for: horizontalSizeClass),
                                alignment: .leading,
                                spacing: 16
                            ) {
                                profileOverviewCard(summaries: summaries, gameSessions: gameSessions)
                                explorerLabProgressCard(summary: explorerLabSummary)
                                if overview.hasValidMakeBreakProgress {
                                    nextTargetCard(digest: digest)
                                }
                            }
                            recentSessionsCard(rows: recentRows, totalCount: summaries.count + gameSessions.count)
                        } else {
                            profileOverviewCard(summaries: summaries, gameSessions: gameSessions)
                            explorerLabProgressCard(summary: explorerLabSummary)
                            recentSessionsCard(rows: recentRows, totalCount: summaries.count + gameSessions.count)
                            if overview.hasValidMakeBreakProgress {
                                nextTargetCard(digest: digest)
                            }
                        }
                    }
                }
                .padding(ResponsiveLayout.contentPadding(for: horizontalSizeClass))
                .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func explorerLabProgressCard(summary: ParentSummaryExplorerLabSummary) -> some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Explorer Lab")
                            .font(.title3.weight(.bold))
                        Text(summary.subtitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(MatherTheme.accent)
                        .accessibilityHidden(true)
                }

                if summary.rows.isEmpty {
                    Text("No Explorer Lab practice yet. Lane progress appears after a mode, card, or concept is practiced.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MatherTheme.panel.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    ForEach(summary.rows) { row in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(row.laneTitle)
                                    .font(.headline.weight(.bold))
                                Spacer(minLength: 8)
                                Text(row.masteryLabel)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(MatherTheme.accent)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }
                            Text(row.detailLabel)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(MatherTheme.panel.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("parent-summary-explorer-lab")
        }
    }


    private var parentActionButtons: some View {
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

    private func paceLabel(_ ms: Int) -> String {
        guard ms > 0 else { return "—" }
        let seconds = ms / 1000
        return seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m \(seconds % 60)s"
    }

    private func makeBreakScorecard(digest: ParentDigest) -> some View {
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
        .accessibilityIdentifier("parent-summary-scorecard")
    }

    private func makeBreakInsufficientProgressCard(hasGameScores: Bool) -> some View {
        CardSurface {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(MatherTheme.accent)
                    .font(.title3.weight(.bold))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("No completed Make & Break practice yet")
                        .font(.title3.weight(.bold))
                    Text(hasGameScores ? "Make & Break mastery scores appear after a completed Make & Break session. Recent game scores are shown below." : "Complete Make & Break to see mastery scores here.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("parent-summary-make-break-insufficient-progress")
        }
    }

    private func historyCaption(totalCount: Int, visibleCount: Int) -> String {
        guard totalCount > 0 else { return "No saved sessions yet." }
        if totalCount == visibleCount {
            return "\(totalCount) saved locally across all games"
        }
        return "Showing latest \(visibleCount) of \(totalCount) saved locally across all games"
    }

    private func recentGameScoresCard(scores: [ParentSummaryGameScore]) -> some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("Game scores")
                    .font(.title3.weight(.bold))
                Text("Recent scores saved locally across non-Make & Break games.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(scores) { score in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(MatherTheme.warm)
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(score.gameName)
                                .font(.headline.weight(.bold))
                            Text(score.scoreText)
                                .font(.title3.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if let detail = score.detail {
                                Text(detail)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(MatherTheme.cardSubtitle)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text(score.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(MatherTheme.panel.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityIdentifier("parent-summary-game-scores")
        }
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

    private func recentProgressCard(points: [ParentSummaryTrendPoint]) -> some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent progress")
                            .font(.title3.weight(.bold))
                        Text("Local, on-device history from recent Make & Break sessions.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chart.xyaxis.line")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(MatherTheme.accent)
                        .accessibilityHidden(true)
                }

                if points.count < 2 {
                    Text("Complete more sessions to see a trend.")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MatherTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 96, alignment: .center)
                        .background(MatherTheme.panel.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    TrendSparkline(points: points)
                        .frame(height: 132)
                        .accessibilityIdentifier("parent-summary-recent-progress-chart")
                    HStack(alignment: .top, spacing: 12) {
                        trendSummary(label: "First try", value: points.last?.accuracyLabel ?? "—")
                        trendSummary(label: "Latest pace", value: points.last?.paceLabel ?? "—")
                        trendSummary(label: "Problems", value: points.last.map { "\($0.problemsCompleted)" } ?? "—")
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("parent-summary-recent-progress")
        }
    }

    private func trendSummary(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .tracking(1.1)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(MatherTheme.panel.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

}


struct ParentSummaryOverview {
    var hasAnyHistory: Bool
    var validMakeBreakSummaries: [StoredSessionSummary]
    var gameScores: [ParentSummaryGameScore]

    var hasValidMakeBreakProgress: Bool {
        !validMakeBreakSummaries.isEmpty
    }

    var hasGameScores: Bool {
        !gameScores.isEmpty
    }

    var headerSubtitle: String {
        hasGameScores ? "Game scores" : "Make & Break"
    }

    static func make(
        summaries: [StoredSessionSummary],
        gameSessions: [StoredGameSession],
        gameScoreLimit: Int = 3
    ) -> ParentSummaryOverview {
        ParentSummaryOverview(
            hasAnyHistory: !summaries.isEmpty || !gameSessions.isEmpty,
            validMakeBreakSummaries: summaries.filter { $0.problemsCompleted > 0 },
            gameScores: ParentSummaryGameScore.recentScores(from: gameSessions, limit: gameScoreLimit)
        )
    }
}

struct ParentSummaryGameScore: Identifiable, Equatable {
    var id: String
    var profileId: String
    var gameName: String
    var startedAt: Date
    var scoreText: String
    var detail: String?

    static func recentScores(
        from gameSessions: [StoredGameSession],
        limit: Int
    ) -> [ParentSummaryGameScore] {
        gameSessions
            .sorted { $0.startedAt > $1.startedAt }
            .prefix(limit)
            .map {
                ParentSummaryGameScore(
                    id: $0.id,
                    profileId: $0.profileId,
                    gameName: $0.gameName,
                    startedAt: $0.startedAt,
                    scoreText: "\($0.scoreValue) \($0.scoreLabel)",
                    detail: $0.detail
                )
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

struct ParentSummaryTrendPoint: Identifiable, Equatable {
    var id: String
    var startedAt: Date
    var accuracy: Double
    var problemsCompleted: Int
    var medianLatencyMs: Int
    var profileId: String

    var accuracyLabel: String {
        "\(Int((accuracy * 100).rounded()))%"
    }

    var paceLabel: String {
        guard medianLatencyMs > 0 else { return "—" }
        let seconds = medianLatencyMs / 1000
        return seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m \(seconds % 60)s"
    }

    static func recentPoints(
        from summaries: [StoredSessionSummary],
        limit: Int = 6,
        profileId: String? = nil
    ) -> [ParentSummaryTrendPoint] {
        summaries
            .filter { profileId == nil || $0.profileId == profileId }
            .sorted { $0.startedAt < $1.startedAt }
            .suffix(limit)
            .map {
                ParentSummaryTrendPoint(
                    id: $0.sessionId,
                    startedAt: $0.startedAt,
                    accuracy: min(max($0.firstAttemptAccuracy, 0), 1),
                    problemsCompleted: max($0.problemsCompleted, 0),
                    medianLatencyMs: max($0.medianLatencyMs, 0),
                    profileId: $0.profileId
                )
            }
    }
}

struct ParentSummaryExplorerLabSummary: Equatable {
    var rows: [ParentSummaryExplorerLabLaneRow]
    var activeLaneCount: Int
    var completedModeCount: Int

    var subtitle: String {
        guard activeLaneCount > 0 else {
            return "Lane, mode, concept, and mastery signals from Explorer Lab."
        }
        let laneNoun = activeLaneCount == 1 ? "lane" : "lanes"
        return "\(activeLaneCount) active \(laneNoun) · \(completedModeCount) modes completed"
    }

    static func make(
        profile: ExplorerLabMasteryProfile,
        limit: Int = 3
    ) -> ParentSummaryExplorerLabSummary {
        let orderedRows = CapabilityLaneRegistry.all.compactMap { descriptor -> ParentSummaryExplorerLabLaneRow? in
            guard let state = profile[descriptor.id],
                  ParentSummaryExplorerLabLaneRow.hasParentVisibleProgress(state)
            else {
                return nil
            }
            return ParentSummaryExplorerLabLaneRow(descriptor: descriptor, state: state)
        }
        .sorted { lhs, rhs in
            if lhs.masteryFraction == rhs.masteryFraction {
                return lhs.registryOrder < rhs.registryOrder
            }
            return lhs.masteryFraction > rhs.masteryFraction
        }

        return ParentSummaryExplorerLabSummary(
            rows: Array(orderedRows.prefix(limit)),
            activeLaneCount: orderedRows.count,
            completedModeCount: orderedRows.reduce(0) { $0 + $1.completedModeCount }
        )
    }
}

struct ParentSummaryExplorerLabLaneRow: Identifiable, Equatable {
    var id: CapabilityLaneID
    var registryOrder: Int
    var laneTitle: String
    var completedModeCount: Int
    var availableModeCount: Int
    var masteryFraction: Double
    var masteryLabel: String
    var nextModeLabel: String
    var conceptLabel: String

    var detailLabel: String {
        "\(completedModeCount) / \(availableModeCount) modes · \(nextModeLabel) · \(conceptLabel)"
    }

    init(descriptor: CapabilityLaneDescriptor, state: LaneMasteryState) {
        let registryOrder = CapabilityLaneRegistry.all.firstIndex { $0.id == descriptor.id } ?? 0
        let completedModeCount = state.completedModeCount
        self.id = descriptor.id
        self.registryOrder = registryOrder
        self.laneTitle = descriptor.title
        self.completedModeCount = completedModeCount
        self.availableModeCount = state.availableModes.count
        self.masteryFraction = state.masteryFraction
        self.masteryLabel = "\(Int((state.masteryFraction * 100).rounded()))% ready"
        self.nextModeLabel = state.nextRecommendedMode.map { "Try \($0.rawValue) next" } ?? "Choose any mode"
        self.conceptLabel = Self.conceptLabel(for: state)
    }

    static func hasParentVisibleProgress(_ state: LaneMasteryState) -> Bool {
        state.completedModeCount > 0
            || !state.reviewedCardIDs.isEmpty
            || state.conceptConfidence.values.contains { $0 > .introduced }
    }

    private static func conceptLabel(for state: LaneMasteryState) -> String {
        let steadyOrMastered = state.conceptConfidence.values.filter { $0 >= .steady }.count
        if steadyOrMastered > 0 {
            return "\(steadyOrMastered) steady concepts"
        }
        if state.conceptConfidence.values.contains(where: { $0 == .practicing }) {
            return "Concepts practicing"
        }
        if !state.reviewedCardIDs.isEmpty {
            return "\(state.reviewedCardIDs.count) cards reviewed"
        }
        return "Concepts introduced"
    }
}

private struct TrendSparkline: View {
    let points: [ParentSummaryTrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                let size = proxy.size
                let coordinates = chartCoordinates(in: size)

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(MatherTheme.panel.opacity(0.55))

                    Path { path in
                        guard let first = coordinates.first else { return }
                        path.move(to: first)
                        coordinates.dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(MatherTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                    ForEach(Array(coordinates.enumerated()), id: \.offset) { index, coordinate in
                        Circle()
                            .fill(index == coordinates.count - 1 ? MatherTheme.warm : MatherTheme.accent)
                            .overlay(Circle().stroke(MatherTheme.card, lineWidth: 3))
                            .frame(width: 15, height: 15)
                            .position(coordinate)
                    }
                }
            }
            .frame(minHeight: 84)

            HStack {
                Text("Oldest")
                Spacer()
                Text("Latest")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(MatherTheme.cardSubtitle)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let labels = points.map { "\($0.startedAt.formatted(date: .abbreviated, time: .omitted)): \($0.accuracyLabel) first try, \($0.problemsCompleted) problems, \($0.paceLabel) pace" }
        return "Recent progress trend. " + labels.joined(separator: "; ")
    }

    private func chartCoordinates(in size: CGSize) -> [CGPoint] {
        let inset: CGFloat = 16
        let width = max(size.width - inset * 2, 1)
        let height = max(size.height - inset * 2, 1)
        let maxProblems = max(points.map(\.problemsCompleted).max() ?? 1, 1)

        return points.enumerated().map { index, point in
            let xProgress = points.count <= 1 ? 0.5 : CGFloat(index) / CGFloat(points.count - 1)
            let accuracyWeight = CGFloat(point.accuracy) * 0.72
            let progressWeight = (CGFloat(point.problemsCompleted) / CGFloat(maxProblems)) * 0.28
            let yProgress = min(max(accuracyWeight + progressWeight, 0), 1)
            return CGPoint(x: inset + width * xProgress, y: inset + height * (1 - yProgress))
        }
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
            }
            Text(value)
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 118, alignment: .topLeading)
        .padding(16)
        .background(MatherTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(color.opacity(0.36), lineWidth: 1.5)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(color.opacity(0.9))
                .frame(width: 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("parent-summary-stat-\(label.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }
}
