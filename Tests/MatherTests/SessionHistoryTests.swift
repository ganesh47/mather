import Foundation
import SwiftData
import Testing
@testable import Mather

// MARK: - Helpers

@MainActor
private func makeInMemoryStore() throws -> (SessionHistoryStore, ModelContext) {
    let schema = Schema([StoredSessionSummary.self, StoredTelemetryEvent.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)
    return (SessionHistoryStore(modelContext: context, activeProfileIdProvider: { "test-profile" }), context)
}

private func makeDraft(
    sessionId: String = UUID().uuidString,
    problemsCompleted: Int = 5,
    accuracy: Double = 0.8,
    transferCorrect: Int = 3,
    medianLatencyMs: Int = 1200,
    startedAt: Date = .now
) -> SessionSummaryDraft {
    SessionSummaryDraft(
        sessionId: sessionId,
        startedAt: startedAt,
        endedAt: startedAt.addingTimeInterval(300),
        objectiveTitle: "Make & Break",
        problemsCompleted: problemsCompleted,
        firstAttemptAccuracy: accuracy,
        transferCorrectCount: transferCorrect,
        medianLatencyMs: medianLatencyMs,
        nextTargetHint: "Keep going.",
        exportFileName: "swiftdata://session/\(sessionId)"
    )
}

private func makeGameSession(
    id: String = UUID().uuidString,
    profileId: String = "test-profile",
    gameName: String = "Sum Sprint",
    startedAt: Date = .now,
    scoreValue: Int = 8,
    scoreLabel: String = "correct",
    detail: String? = nil
) -> StoredGameSession {
    StoredGameSession(
        id: id,
        profileId: profileId,
        gameName: gameName,
        startedAt: startedAt,
        durationSeconds: 45,
        scoreValue: scoreValue,
        scoreLabel: scoreLabel,
        detail: detail
    )
}

// MARK: - SessionHistoryStore tests

@MainActor
struct SessionHistoryStoreTests {
    @Test
    func savePersistsSummary() throws {
        let (store, context) = try makeInMemoryStore()
        let draft = makeDraft(problemsCompleted: 6, accuracy: 0.75)

        store.save(draft)

        let fetched = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        #expect(fetched.count == 1)
        #expect(fetched[0].problemsCompleted == 6)
        #expect(fetched[0].firstAttemptAccuracy == 0.75)
    }

    @Test
    func clearAllRemovesAllSummaries() throws {
        let (store, context) = try makeInMemoryStore()
        store.save(makeDraft())
        store.save(makeDraft())

        store.clearAll()

        let fetched = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        #expect(fetched.isEmpty)
    }

    @Test
    func saveMultipleSessionsAreAllPersisted() throws {
        let (store, context) = try makeInMemoryStore()
        store.save(makeDraft(sessionId: "aaa", problemsCompleted: 3))
        store.save(makeDraft(sessionId: "bbb", problemsCompleted: 6))

        let fetched = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        #expect(fetched.count == 2)
    }
}

// MARK: - TelemetryWriter.digest tests

@MainActor
struct TelemetryWriterDigestTests {
    @Test
    func digestReturnsDefaultsForEmptyHistory() {
        let schema = Schema([StoredTelemetryEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let writer = TelemetryWriter(modelContext: ModelContext(container), activeProfileIdProvider: { "test-profile" })
        let digest = writer.digest(from: [])

        #expect(digest.problemsCompleted == 0)
        #expect(digest.firstAttemptAccuracy == 0)
        #expect(digest.transferCorrectCount == 0)
        #expect(digest.medianLatencyMs == 0)
    }

    @Test
    func digestAggregatesTotalsAcrossSessions() throws {
        let (store, context) = try makeInMemoryStore()
        store.save(makeDraft(problemsCompleted: 4, accuracy: 1.0, transferCorrect: 4, medianLatencyMs: 1000))
        store.save(makeDraft(problemsCompleted: 6, accuracy: 0.5, transferCorrect: 2, medianLatencyMs: 2000))

        let summaries = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        let schema = Schema([StoredTelemetryEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let digest = TelemetryWriter(modelContext: ModelContext(container), activeProfileIdProvider: { "test-profile" }).digest(from: summaries)

        #expect(digest.problemsCompleted == 10)
        #expect(digest.transferCorrectCount == 6)
        // Problem-weighted mean: (4 × 1.0 + 6 × 0.5) / 10 = 0.70
        #expect(abs(digest.firstAttemptAccuracy - 0.70) < 0.001)
    }

    @Test
    func digestMedianLatencyPicksMiddleValue() throws {
        let (store, context) = try makeInMemoryStore()
        store.save(makeDraft(medianLatencyMs: 1000))
        store.save(makeDraft(medianLatencyMs: 2000))
        store.save(makeDraft(medianLatencyMs: 3000))

        let summaries = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        let schema = Schema([StoredTelemetryEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let digest = TelemetryWriter(modelContext: ModelContext(container), activeProfileIdProvider: { "test-profile" }).digest(from: summaries)

        #expect(digest.medianLatencyMs == 2000)
    }

    @Test
    func digestNextHintEncouragesProgressWhenAccuracyHigh() throws {
        let (store, context) = try makeInMemoryStore()
        store.save(makeDraft(accuracy: 0.9))

        let summaries = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        let schema = Schema([StoredTelemetryEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let digest = TelemetryWriter(modelContext: ModelContext(container), activeProfileIdProvider: { "test-profile" }).digest(from: summaries)

        // High accuracy (>= 0.7) should give a "keep going" hint, not a "repeat" hint
        #expect(!digest.nextTargetHint.contains("Repeat"))
    }

    @Test
    func digestNextHintSuggestsRepeatWhenAccuracyLow() throws {
        let (store, context) = try makeInMemoryStore()
        store.save(makeDraft(accuracy: 0.4))

        let summaries = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        let schema = Schema([StoredTelemetryEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let digest = TelemetryWriter(modelContext: ModelContext(container), activeProfileIdProvider: { "test-profile" }).digest(from: summaries)

        #expect(digest.nextTargetHint.contains("Repeat"))
    }

    @Test
    func digestFirstAttemptAccuracyIsWeightedByProblemCount() throws {
        let (store, context) = try makeInMemoryStore()
        // 1 problem at 100% first-try — contributes weight 1
        store.save(makeDraft(problemsCompleted: 1, accuracy: 1.0))
        // 9 problems at 0% first-try — contributes weight 9
        store.save(makeDraft(problemsCompleted: 9, accuracy: 0.0))

        let summaries = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        let schema = Schema([StoredTelemetryEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let digest = TelemetryWriter(modelContext: ModelContext(container), activeProfileIdProvider: { "test-profile" }).digest(from: summaries)

        // Session-average would give (1.0 + 0.0) / 2 = 0.50 — wrong.
        // Problem-weighted: (1 × 1.0 + 9 × 0.0) / 10 = 0.10 — correct.
        #expect(abs(digest.firstAttemptAccuracy - 0.10) < 0.001)
    }

    @Test
    func digestFirstAttemptAccuracyIsZeroWhenNoProblemsCompleted() throws {
        let (store, context) = try makeInMemoryStore()
        // Legacy-style records with no problems completed (crash or early exit)
        store.save(makeDraft(problemsCompleted: 0, accuracy: 0.0))
        store.save(makeDraft(problemsCompleted: 0, accuracy: 0.0))

        let summaries = try context.fetch(FetchDescriptor<StoredSessionSummary>())
        let schema = Schema([StoredTelemetryEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let digest = TelemetryWriter(modelContext: ModelContext(container), activeProfileIdProvider: { "test-profile" }).digest(from: summaries)

        #expect(digest.firstAttemptAccuracy == 0)  // divide-by-zero guard
        #expect(digest.problemsCompleted == 0)
    }
}

// MARK: - Parent summary history row tests

@MainActor
struct ParentSummaryOverviewTests {
    @Test
    func overviewTreatsGameOnlyHistoryAsScoresWithoutMakeBreakProgress() {
        let game = makeGameSession(scoreValue: 7, scoreLabel: "correct", detail: "Level 2")

        let overview = ParentSummaryOverview.make(summaries: [], gameSessions: [game])

        #expect(overview.hasAnyHistory)
        #expect(!overview.hasValidMakeBreakProgress)
        #expect(overview.hasGameScores)
        #expect(overview.headerSubtitle == "Game scores")
        #expect(overview.gameScores.map(\.scoreText) == ["7 correct"])
        #expect(overview.gameScores.first?.detail == "Level 2")
    }

    @Test
    func overviewIgnoresZeroProblemMakeBreakForMasteryScores() {
        let zeroProblem = StoredSessionSummary(
            from: makeDraft(sessionId: "zero", problemsCompleted: 0, accuracy: 0, medianLatencyMs: 0),
            profileId: "test-profile"
        )

        let overview = ParentSummaryOverview.make(summaries: [zeroProblem], gameSessions: [])

        #expect(overview.hasAnyHistory)
        #expect(!overview.hasValidMakeBreakProgress)
        #expect(!overview.hasGameScores)
        #expect(overview.validMakeBreakSummaries.isEmpty)
    }

    @Test
    func overviewKeepsValidMakeBreakProgressSeparateFromGameScores() {
        let base = Date(timeIntervalSinceReferenceDate: 50_000)
        let makeAndBreak = StoredSessionSummary(
            from: makeDraft(sessionId: "valid", problemsCompleted: 4, startedAt: base.addingTimeInterval(-120)),
            profileId: "test-profile"
        )
        let latestGame = makeGameSession(id: "latest-game", gameName: "Angle Cannon", startedAt: base, scoreValue: 5, scoreLabel: "targets hit")
        let olderGame = makeGameSession(id: "older-game", gameName: "Memory", startedAt: base.addingTimeInterval(-60), scoreValue: 3, scoreLabel: "rounds")

        let overview = ParentSummaryOverview.make(
            summaries: [makeAndBreak],
            gameSessions: [olderGame, latestGame],
            gameScoreLimit: 1
        )

        #expect(overview.hasValidMakeBreakProgress)
        #expect(overview.validMakeBreakSummaries.map(\.sessionId) == ["valid"])
        #expect(overview.gameScores.map(\.gameName) == ["Angle Cannon"])
        #expect(overview.gameScores.map(\.scoreText) == ["5 targets hit"])
    }
}

// MARK: - Parent summary history row tests

@MainActor
struct ParentSummaryHistoryRowTests {
    @Test
    func recentRowsMergeMakeAndBreakAndExplorerGameSessions() throws {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let makeAndBreak = StoredSessionSummary(
            from: makeDraft(sessionId: "make-break-old", problemsCompleted: 2, startedAt: now.addingTimeInterval(-120)),
            profileId: "test-profile"
        )
        let sumSprint = makeGameSession(id: "sum-sprint-new", startedAt: now)

        let rows = ParentSummaryHistoryRow.recentRows(
            summaries: [makeAndBreak],
            gameSessions: [sumSprint],
            limit: 5
        )

        #expect(rows.map(\.title) == ["Sum Sprint", "Make & Break"])
        #expect(rows.map(\.source) == [.game, .makeAndBreak])
        #expect(rows[0].detail == "8 correct")
        #expect(rows[1].detail == "2 problems · 80% first try")
    }

    @Test
    func recentRowsRespectsLimitAfterSortingAllSessionTypes() throws {
        let now = Date(timeIntervalSinceReferenceDate: 20_000)
        let oldest = StoredSessionSummary(
            from: makeDraft(sessionId: "oldest", startedAt: now.addingTimeInterval(-300)),
            profileId: "test-profile"
        )
        let newest = makeGameSession(id: "newest", gameName: "Angle Cannon", startedAt: now, scoreValue: 3, scoreLabel: "hits")
        let middle = makeGameSession(id: "middle", gameName: "Memory", startedAt: now.addingTimeInterval(-60), scoreValue: 6, scoreLabel: "matches")

        let rows = ParentSummaryHistoryRow.recentRows(
            summaries: [oldest],
            gameSessions: [middle, newest],
            limit: 2
        )

        #expect(rows.map(\.title) == ["Angle Cannon", "Memory"])
    }
}

// MARK: - Parent summary trend tests

@MainActor
struct ParentSummaryTrendPointTests {
    @Test
    func recentPointsReturnsEmptyForEmptyHistory() {
        let points = ParentSummaryTrendPoint.recentPoints(from: [])

        #expect(points.isEmpty)
    }

    @Test
    func recentPointsOrdersOldestToLatestAfterTakingRecentLimit() {
        let base = Date(timeIntervalSinceReferenceDate: 30_000)
        let old = StoredSessionSummary(
            from: makeDraft(sessionId: "old", problemsCompleted: 2, accuracy: 0.5, startedAt: base.addingTimeInterval(-300)),
            profileId: "test-profile"
        )
        let middle = StoredSessionSummary(
            from: makeDraft(sessionId: "middle", problemsCompleted: 4, accuracy: 0.75, startedAt: base.addingTimeInterval(-120)),
            profileId: "test-profile"
        )
        let latest = StoredSessionSummary(
            from: makeDraft(sessionId: "latest", problemsCompleted: 6, accuracy: 1.0, startedAt: base),
            profileId: "test-profile"
        )

        let points = ParentSummaryTrendPoint.recentPoints(from: [latest, old, middle], limit: 2)

        #expect(points.map(\.id) == ["middle", "latest"])
        #expect(points.map(\.accuracyLabel) == ["75%", "100%"])
        #expect(points.last?.problemsCompleted == 6)
    }

    @Test
    func recentPointsFiltersByProfileAndClampsLegacyValues() {
        let base = Date(timeIntervalSinceReferenceDate: 40_000)
        let selected = StoredSessionSummary(
            from: makeDraft(sessionId: "selected", problemsCompleted: -2, accuracy: 1.4, medianLatencyMs: -100, startedAt: base),
            profileId: "profile-a"
        )
        let otherProfile = StoredSessionSummary(
            from: makeDraft(sessionId: "other", problemsCompleted: 5, accuracy: 0.8, startedAt: base.addingTimeInterval(60)),
            profileId: "profile-b"
        )

        let points = ParentSummaryTrendPoint.recentPoints(from: [otherProfile, selected], profileId: "profile-a")

        #expect(points.map(\.id) == ["selected"])
        #expect(points[0].accuracy == 1)
        #expect(points[0].problemsCompleted == 0)
        #expect(points[0].paceLabel == "—")
    }
}

// MARK: - Parent summary Explorer Lab tests

struct ParentSummaryExplorerLabSummaryTests {
    @Test
    func summaryShowsGracefulEmptyStateForSeededProfile() {
        let summary = ParentSummaryExplorerLabSummary.make(profile: .emptyExplorerProfile())

        #expect(summary.rows.isEmpty)
        #expect(summary.activeLaneCount == 0)
        #expect(summary.completedModeCount == 0)
        #expect(summary.subtitle == "Lane, mode, concept, and mastery signals from Explorer Lab.")
    }

    @Test
    func summaryMapsLaneModeConceptAndMasteryCopy() {
        var profile = ExplorerLabMasteryProfile.emptyExplorerProfile()
        profile.updateLane(.numbers) { lane in
            lane.markCompleted(.learn)
            lane.markCompleted(.challenge)
            lane.setConfidence(.steady, for: "number-bond")
            lane.setConfidence(.mastered, for: "array")
        }

        let summary = ParentSummaryExplorerLabSummary.make(profile: profile)

        #expect(summary.activeLaneCount == 1)
        #expect(summary.completedModeCount == 2)
        #expect(summary.subtitle == "1 active lane · 2 modes completed")
        #expect(summary.rows.map(\.laneTitle) == ["Numbers Lab"])
        #expect(summary.rows.first?.masteryLabel == "50% ready")
        #expect(summary.rows.first?.detailLabel == "2 / 4 modes · Try Timed next · 2 steady concepts")
    }

    @Test
    func summaryOrdersByMasteryAndLimitsRows() {
        var profile = ExplorerLabMasteryProfile.emptyExplorerProfile()
        profile.updateLane(.numbers) { lane in
            lane.markCompleted(.learn)
        }
        profile.updateLane(.geometry) { lane in
            lane.markCompleted(.learn)
            lane.markCompleted(.explore)
        }
        profile.updateLane(.physics) { lane in
            lane.markCompleted(.explore)
            lane.setConfidence(.steady, for: "motion")
        }

        let summary = ParentSummaryExplorerLabSummary.make(profile: profile, limit: 2)

        #expect(summary.activeLaneCount == 3)
        #expect(summary.completedModeCount == 4)
        #expect(summary.rows.map(\.laneTitle) == ["Geometry Lab", "Physics Lab"])
    }
}
