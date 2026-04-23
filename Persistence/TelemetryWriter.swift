import Foundation
import SwiftData

@MainActor
final class TelemetryWriter {
    static let schemaVersion = 1

    private let encoder: JSONEncoder
    private let modelContext: ModelContext
    private let activeProfileIdProvider: () -> String

    private(set) var currentSessionId: String?

    convenience init() {
        let schema = Schema([StoredTelemetryEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        self.init(modelContext: ModelContext(container), activeProfileIdProvider: { KidProfileStore.defaultProfileId })
    }

    init(modelContext: ModelContext, activeProfileIdProvider: @escaping () -> String) {
        self.modelContext = modelContext
        self.activeProfileIdProvider = activeProfileIdProvider
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func beginSession(sessionId: UUID, featureFlags: FeatureFlagService) throws {
        currentSessionId = sessionId.uuidString

        try append(
            SliceEvent(
                type: .sessionStart,
                payload: [
                    "schema_version": String(Self.schemaVersion),
                    "feature_testModeEnabled": String(featureFlags.testModeEnabled),
                    "feature_audioEnabled": String(featureFlags.audioEnabled),
                    "theme_id": featureFlags.selectedThemeId
                ]
            )
        )
    }

    func append(_ event: SliceEvent) throws {
        guard let currentSessionId else { return }
        let data = try encoder.encode(event)
        guard let encodedEvent = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let row = StoredTelemetryEvent(
            sessionId: currentSessionId,
            profileId: activeProfileIdProvider(),
            event: event,
            encodedEvent: encodedEvent
        )
        modelContext.insert(row)
        try modelContext.save()
    }

    func finishSession(session: SliceSession, digest: ParentDigest, themeId: String = "classic") throws {
        try append(
            SliceEvent(
                type: .sessionEnd,
                payload: [
                    "schema_version": String(Self.schemaVersion),
                    "problems_completed": String(digest.problemsCompleted),
                    "first_attempt_accuracy": String(format: "%.2f", digest.firstAttemptAccuracy),
                    "median_latency_ms": String(digest.medianLatencyMs),
                    "transfer_correct": String(digest.transferCorrectCount),
                    "theme_id": themeId
                ]
            )
        )
    }

    func clearEventsForActiveProfile() {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredTelemetryEvent>(
            predicate: #Predicate { $0.profileId == profileId }
        )
        guard let events = try? modelContext.fetch(descriptor) else { return }
        for event in events {
            modelContext.delete(event)
        }
        try? modelContext.save()
        currentSessionId = nil
    }

    func digest(from summaries: [StoredSessionSummary]) -> ParentDigest {
        guard !summaries.isEmpty else {
            return ParentDigest(
                objectiveTitle: "Make & Break Numbers",
                firstAttemptAccuracy: 0,
                medianLatencyMs: 0,
                problemsCompleted: 0,
                transferCorrectCount: 0,
                nextTargetHint: "Start with targets 6 to 8 and watch for relaxed repetition."
            )
        }

        let sorted = summaries.sorted { $0.startedAt > $1.startedAt }
        let totalProblems = sorted.map(\.problemsCompleted).reduce(0, +)
        let accuracy: Double
        if totalProblems == 0 {
            accuracy = 0
        } else {
            let weightedSum = sorted.reduce(0.0) { acc, s in
                acc + s.firstAttemptAccuracy * Double(s.problemsCompleted)
            }
            accuracy = weightedSum / Double(totalProblems)
        }
        let latencies = sorted.map(\.medianLatencyMs).sorted()
        let median = latencies[latencies.count / 2]
        let completed = sorted.map(\.problemsCompleted).reduce(0, +)
        let transferCorrect = sorted.map(\.transferCorrectCount).reduce(0, +)

        return ParentDigest(
            objectiveTitle: sorted.first?.objectiveTitle ?? "Make & Break Numbers",
            firstAttemptAccuracy: accuracy,
            medianLatencyMs: median,
            problemsCompleted: completed,
            transferCorrectCount: transferCorrect,
            nextTargetHint: digestHint(accuracy: accuracy, transferCorrect: transferCorrect, completed: completed)
        )
    }

    private func digestHint(accuracy: Double, transferCorrect: Int, completed: Int) -> String {
        guard completed > 0 else {
            return "Start with targets 6 to 8 and watch for relaxed repetition."
        }
        let transferRate = Double(transferCorrect) / Double(completed)
        if transferRate < accuracy - 0.3 {
            return "The reverse direction (equation → counters) is the gap. Practise writing '3 + 4 =' and asking your child to show it with physical objects."
        }
        if accuracy < 0.5 {
            return "Repeat the current range — keep sessions short and use real objects at home (pebbles, pasta) alongside the app."
        }
        if accuracy < 0.7 {
            return "Repeat targets 6 to 8 with audio prompts enabled. Physical practice at home helps consolidate the concept."
        }
        if accuracy < 0.9 {
            return "Good progress. Try one more session and watch for faster, confident transfer responses."
        }
        return "Strong mastery. Consider expanding the range or introducing numeral writing on paper."
    }
}
