import Foundation

struct CompareCampSessionResult: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let categoryID: String
    let activity: CompareCampActivity
    let difficulty: CompareCampDifficulty
    let seed: UInt64
    let roundsCompleted: Int
    let firstTryCount: Int
    let helpedRoundCount: Int
    let completedAt: Date

    init(
        id: UUID = UUID(), categoryID: String, activity: CompareCampActivity,
        difficulty: CompareCampDifficulty, seed: UInt64, roundsCompleted: Int,
        firstTryCount: Int, helpedRoundCount: Int, completedAt: Date = Date()
    ) {
        self.id = id
        self.categoryID = categoryID
        self.activity = activity
        self.difficulty = difficulty
        self.seed = seed
        self.roundsCompleted = roundsCompleted
        self.firstTryCount = firstTryCount
        self.helpedRoundCount = helpedRoundCount
        self.completedAt = completedAt
    }
}

/// A local passport records exploration, not a claim of conceptual mastery.
struct CompareCampProgress: Equatable, Codable, Sendable {
    let schemaVersion: Int
    private(set) var sessions: [CompareCampSessionResult]

    init(sessions: [CompareCampSessionResult] = []) {
        schemaVersion = 1
        self.sessions = sessions
    }

    var completedCampIDs: Set<String> { Set(sessions.map(\.categoryID)) }
    var totalSessionCount: Int { sessions.count }
    var totalRounds: Int { sessions.reduce(0) { $0 + $1.roundsCompleted } }
    var adventuresCompleted: Int { sessions.filter { $0.activity == .adventure }.count }

    func resultCount(for categoryID: String) -> Int { sessions.filter { $0.categoryID == categoryID }.count }

    mutating func record(_ result: CompareCampSessionResult) {
        guard Self.isValid(result), !sessions.contains(where: { $0.id == result.id }) else { return }
        sessions.append(result)
    }

    private enum CodingKeys: String, CodingKey { case schemaVersion, sessions }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decode(Int.self, forKey: .schemaVersion)
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .schemaVersion, in: values, debugDescription: "Unsupported Compare Camp passport version")
        }
        let decoded = try values.decode([CompareCampSessionResult].self, forKey: .sessions)
        guard decoded.allSatisfy(Self.isValid), Set(decoded.map(\.id)).count == decoded.count else {
            throw DecodingError.dataCorruptedError(forKey: .sessions, in: values, debugDescription: "Invalid Compare Camp session results")
        }
        schemaVersion = version
        sessions = decoded
    }

    private static func isValid(_ result: CompareCampSessionResult) -> Bool {
        CompareCampCategory.all.contains { $0.id == result.categoryID }
            && result.roundsCompleted == 8
            && (0...result.roundsCompleted).contains(result.firstTryCount)
            && (0...result.roundsCompleted).contains(result.helpedRoundCount)
    }
}
