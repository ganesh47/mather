import Foundation

struct ExportArtifact: Equatable {
    let url: URL
    let fileName: String
}

@MainActor
final class TelemetryWriter {
    static let schemaVersion = 1

    private let encoder: JSONEncoder
    private let fileManager: FileManager
    private let documentsDirectory: URL
    private(set) var currentExport: ExportArtifact?

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func beginSession(sessionId: UUID, featureFlags: FeatureFlagService) throws {
        let fileName = "session-\(sessionId.uuidString).jsonl"
        let exportDirectory = exportsDirectory()
        if !fileManager.fileExists(atPath: exportDirectory.path) {
            try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        }

        let fileURL = exportDirectory.appendingPathComponent(fileName)
        fileManager.createFile(atPath: fileURL.path, contents: nil)
        currentExport = ExportArtifact(url: fileURL, fileName: fileName)

        try append(
            SliceEvent(
                type: .sessionStart,
                payload: [
                    "schema_version": String(Self.schemaVersion),
                    "feature_verticalSlice1Enabled": String(featureFlags.verticalSlice1Enabled),
                    "feature_testModeEnabled": String(featureFlags.testModeEnabled),
                    "feature_audioEnabled": String(featureFlags.audioEnabled),
                    "theme_id": featureFlags.selectedThemeId
                ]
            )
        )
    }

    func append(_ event: SliceEvent) throws {
        guard let currentExport else { return }
        let data = try encoder.encode(event)
        guard let line = String(data: data, encoding: .utf8)?.appending("\n").data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }

        if let handle = try? FileHandle(forWritingTo: currentExport.url) {
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
            try handle.close()
        }
    }

    @discardableResult
    func finishSession(session: SliceSession, digest: ParentDigest, themeId: String = "classic") throws -> ExportArtifact? {
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
        try verifyReadableJSONL()
        return currentExport
    }

    func verifyReadableJSONL() throws {
        guard let currentExport else { return }
        let content = try String(contentsOf: currentExport.url, encoding: .utf8)
        for line in content.split(separator: "\n") {
            _ = try JSONDecoder().decode(SliceEvent.self, from: Data(line.utf8))
        }
    }

    func exportsDirectory() -> URL {
        documentsDirectory.appendingPathComponent("SessionExports", isDirectory: true)
    }

    func exportURL(fileName: String) -> URL {
        exportsDirectory().appendingPathComponent(fileName)
    }

    func clearExports() {
        let directory = exportsDirectory()
        guard let urls = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for url in urls {
            try? fileManager.removeItem(at: url)
        }
        currentExport = nil
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
