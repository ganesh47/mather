import Foundation

/// Adult assistance is reported context, never inferred from a correct tap.
enum AdultHelpStatus: String, Codable, Equatable, Hashable {
    case unknown, reportedNoHelp, reportedHelp
}

/// Viewing, support and eventual success are deliberately different evidence.
enum ItemAttemptOutcome: String, Codable, Equatable, Hashable {
    case exposure, help, independentCorrect, supportedCorrect, incorrect

    #if !os(tvOS)
    var recallOutcome: GameplayExposureOutcome? {
        switch self {
        case .exposure, .help: nil
        case .independentCorrect: .correct
        case .supportedCorrect: .supportedCorrect
        case .incorrect: .incorrect
        }
    }
    #endif
}

struct ItemAttempt: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let activityID: String
    let conceptID: String
    let entityID: String
    let propertyID: String?
    let stageID: String
    let outcome: ItemAttemptOutcome
    let response: String?
    let occurredAt: Date
    let profileID: String?
    let sessionID: String?
    let contentVersion: Int?
    let itemVariantID: String?
    let appHintUsed: Bool?
    let isFreshProbe: Bool?
    let adultHelp: AdultHelpStatus?

    init(id: UUID = UUID(), activityID: String, conceptID: String, entityID: String, propertyID: String? = nil, stageID: String, outcome: ItemAttemptOutcome, response: String? = nil, occurredAt: Date = Date(), profileID: String? = nil, sessionID: String? = nil, contentVersion: Int? = nil, itemVariantID: String? = nil, appHintUsed: Bool? = nil, isFreshProbe: Bool? = nil, adultHelp: AdultHelpStatus? = nil) {
        self.id = id
        self.activityID = activityID
        self.conceptID = conceptID
        self.entityID = entityID
        self.propertyID = propertyID
        self.stageID = stageID
        self.outcome = outcome
        self.response = response
        self.occurredAt = occurredAt
        self.profileID = profileID
        self.sessionID = sessionID
        self.contentVersion = contentVersion
        self.itemVariantID = itemVariantID
        self.appHintUsed = appHintUsed
        self.isFreshProbe = isFreshProbe
        self.adultHelp = adultHelp
    }

    func withContext(profileID: String? = nil, sessionID: String? = nil, contentVersion: Int? = nil) -> ItemAttempt {
        ItemAttempt(id: id, activityID: activityID, conceptID: conceptID, entityID: entityID, propertyID: propertyID,
            stageID: stageID, outcome: outcome, response: response, occurredAt: occurredAt,
            profileID: profileID ?? self.profileID, sessionID: sessionID ?? self.sessionID, contentVersion: contentVersion ?? self.contentVersion,
            itemVariantID: itemVariantID, appHintUsed: appHintUsed, isFreshProbe: isFreshProbe, adultHelp: adultHelp)
    }

    func withOutcome(_ outcome: ItemAttemptOutcome) -> ItemAttempt {
        ItemAttempt(id: id, activityID: activityID, conceptID: conceptID, entityID: entityID, propertyID: propertyID,
            stageID: stageID, outcome: outcome, response: response, occurredAt: occurredAt,
            profileID: profileID, sessionID: sessionID, contentVersion: contentVersion,
            itemVariantID: itemVariantID, appHintUsed: appHintUsed, isFreshProbe: isFreshProbe, adultHelp: adultHelp)
    }

    #if !os(tvOS)
    var exposureKey: GameplayExposureKey { GameplayExposureKey(entityID: entityID, propertyID: propertyID, stageID: stageID) }
    #endif
}

/// Restarting a screen does not erase support already used for that item in this session.
enum ActivityEvidenceNormalizer {
    private struct Target: Hashable {
        let activityID: String
        let entityID: String
        let propertyID: String?
        let stageID: String
        let profileID: String?
        let sessionID: String?
        let contentVersion: Int?

        init(_ attempt: ItemAttempt) {
            activityID = attempt.activityID
            entityID = attempt.entityID
            propertyID = attempt.propertyID
            stageID = attempt.stageID
            profileID = attempt.profileID
            sessionID = attempt.sessionID
            contentVersion = attempt.contentVersion
        }
    }

    static func normalized(_ events: [ItemAttempt], after previous: [ItemAttempt] = []) -> [ItemAttempt] {
        var supported = Set(previous.filter { $0.outcome == .help || $0.outcome == .incorrect || $0.outcome == .supportedCorrect }.map(Target.init))
        return events.map { event in
            let target = Target(event)
            if event.outcome == .help || event.outcome == .incorrect || event.outcome == .supportedCorrect {
                supported.insert(target)
            }
            return event.outcome == .independentCorrect && (supported.contains(target) || event.appHintUsed == true || event.adultHelp == .reportedHelp) ? event.withOutcome(.supportedCorrect) : event
        }
    }
}

struct ActivityResult: Identifiable, Codable, Equatable {
    let id: String
    let activityID: String
    let title: String
    let startedAt: Date
    let endedAt: Date
    let attempts: [ItemAttempt]
    let completedStageIDs: [String]
    let profileID: String?
    let contentVersion: Int?

    init(id: String = UUID().uuidString, activityID: String, title: String, startedAt: Date, endedAt: Date = Date(), attempts: [ItemAttempt], completedStageIDs: [String], profileID: String? = nil, contentVersion: Int? = nil) {
        self.id = id
        self.activityID = activityID
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.attempts = attempts
        self.completedStageIDs = completedStageIDs
        self.profileID = profileID
        self.contentVersion = contentVersion
    }
}

#if !os(tvOS)
struct ActivityLaunchContext: Codable, Equatable {
    let activityID: String
    let conceptID: String?
    let returnLaneID: CapabilityLaneID?

    init(activityID: String, conceptID: String? = nil, returnLaneID: CapabilityLaneID? = nil) {
        self.activityID = activityID
        self.conceptID = conceptID
        self.returnLaneID = returnLaneID
    }
}
#endif

/// Small generic envelope; each activity owns and validates its payload.
struct QuestCheckpoint: Codable, Equatable {
    let activityID: String
    let sessionID: String
    let startedAt: Date
    let payload: Data
    var profileID: String? = nil
    var updatedAt: Date? = nil
}
