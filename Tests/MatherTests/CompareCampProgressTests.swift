import Foundation
import Testing
@testable import Mather

@Suite("Compare Camp local passport")
struct CompareCampProgressTests {
    @Test func recordingIsIdempotentAndPassportSurvivesCodableRoundTrip() throws {
        var progress = CompareCampProgress()
        let result = session()
        progress.record(result)
        progress.record(result)
        #expect(progress.totalSessionCount == 1)
        #expect(progress.totalRounds == 8)
        #expect(progress.adventuresCompleted == 1)
        #expect(progress.completedCampIDs == [CompareCampCategory.first.id])
        #expect(progress.resultCount(for: CompareCampCategory.first.id) == 1)
        #expect(try JSONDecoder().decode(CompareCampProgress.self, from: JSONEncoder().encode(progress)) == progress)
    }

    @Test func incompleteOrImpossibleResultsAreNotPassportDiscoveries() {
        var progress = CompareCampProgress()
        progress.record(session(roundsCompleted: 7))
        progress.record(session(firstTryCount: 9))
        progress.record(session(helpedRoundCount: -1))
        progress.record(session(categoryID: "unknown"))
        #expect(progress.sessions.isEmpty)
    }

    @Test func unknownSchemaAndCorruptedSessionCountsFailDecoding() throws {
        var progress = CompareCampProgress()
        progress.record(session())
        let data = try JSONEncoder().encode(progress)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["schemaVersion"] = 999
        let futureVersion = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(CompareCampProgress.self, from: futureVersion) }
        object["schemaVersion"] = 1
        var sessions = try #require(object["sessions"] as? [[String: Any]])
        sessions[0]["firstTryCount"] = Int.max
        object["sessions"] = sessions
        let corrupt = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(CompareCampProgress.self, from: corrupt) }
    }

    private func session(
        categoryID: String = CompareCampCategory.first.id, roundsCompleted: Int = 8,
        firstTryCount: Int = 6, helpedRoundCount: Int = 2
    ) -> CompareCampSessionResult {
        .init(categoryID: categoryID, activity: .adventure, difficulty: .small,
              seed: 0, roundsCompleted: roundsCompleted, firstTryCount: firstTryCount,
              helpedRoundCount: helpedRoundCount)
    }
}
