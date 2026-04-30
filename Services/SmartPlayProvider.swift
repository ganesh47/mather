import Foundation

enum SmartPlayResponseSource: String, Equatable, Sendable {
    case curatedFallback
}

struct SmartPlayRequestContext: Equatable, Sendable {
    var laneID: String
    var stageID: String?
    var activityID: String?
    var learningGoal: String?
    var localeIdentifier: String
    var knownFacts: [String]

    init(
        laneID: String,
        stageID: String? = nil,
        activityID: String? = nil,
        learningGoal: String? = nil,
        localeIdentifier: String = Locale.current.identifier,
        knownFacts: [String] = []
    ) {
        self.laneID = laneID
        self.stageID = stageID
        self.activityID = activityID
        self.learningGoal = learningGoal
        self.localeIdentifier = localeIdentifier
        self.knownFacts = knownFacts
    }
}

struct SmartPlayHintRequest: Equatable, Sendable {
    var context: SmartPlayRequestContext
    var currentProblem: String?
    var attemptCount: Int
    var availableTools: [String]

    init(
        context: SmartPlayRequestContext,
        currentProblem: String? = nil,
        attemptCount: Int = 0,
        availableTools: [String] = []
    ) {
        self.context = context
        self.currentProblem = currentProblem
        self.attemptCount = attemptCount
        self.availableTools = availableTools
    }
}

struct SmartPlayHintResponse: Equatable, Sendable {
    var spokenText: String
    var source: SmartPlayResponseSource
}

struct SmartPlayStoryRequest: Equatable, Sendable {
    var context: SmartPlayRequestContext
    var theme: String?
    var targetNumber: Int?

    init(
        context: SmartPlayRequestContext,
        theme: String? = nil,
        targetNumber: Int? = nil
    ) {
        self.context = context
        self.theme = theme
        self.targetNumber = targetNumber
    }
}

struct SmartPlayStoryResponse: Equatable, Sendable {
    var spokenText: String
    var source: SmartPlayResponseSource
}

struct SmartPlayReviewPromptRequest: Equatable, Sendable {
    var context: SmartPlayRequestContext
    var completedActivities: [String]
    var successCount: Int
    var retryCount: Int

    init(
        context: SmartPlayRequestContext,
        completedActivities: [String] = [],
        successCount: Int = 0,
        retryCount: Int = 0
    ) {
        self.context = context
        self.completedActivities = completedActivities
        self.successCount = successCount
        self.retryCount = retryCount
    }
}

struct SmartPlayReviewPromptResponse: Equatable, Sendable {
    var spokenText: String
    var source: SmartPlayResponseSource
}

@MainActor
protocol SmartPlayProvider {
    func hint(for request: SmartPlayHintRequest) async -> SmartPlayHintResponse
    func story(for request: SmartPlayStoryRequest) async -> SmartPlayStoryResponse
    func reviewPrompt(for request: SmartPlayReviewPromptRequest) async -> SmartPlayReviewPromptResponse
}
