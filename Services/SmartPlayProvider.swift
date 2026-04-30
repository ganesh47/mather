import Foundation

enum SmartPlayPromptKind: String, Equatable, Sendable {
    case hint
    case story
    case review
}

enum SmartPlayPromptSource: Equatable, Sendable {
    case curatedFallback
}

struct SmartPlayPrompt: Equatable, Sendable {
    let kind: SmartPlayPromptKind
    let spokenText: String
    let source: SmartPlayPromptSource
}

struct SmartPlayActivityContext: Equatable, Sendable {
    let laneID: String
    let activityID: String
    let stageID: String?
    let goal: String
    let problemText: String?
    let themeID: String?

    init(
        laneID: String,
        activityID: String,
        stageID: String? = nil,
        goal: String,
        problemText: String? = nil,
        themeID: String? = nil
    ) {
        self.laneID = laneID
        self.activityID = activityID
        self.stageID = stageID
        self.goal = goal
        self.problemText = problemText
        self.themeID = themeID
    }
}

struct SmartPlayHintRequest: Equatable, Sendable {
    let context: SmartPlayActivityContext
    let attemptSummary: String?

    init(context: SmartPlayActivityContext, attemptSummary: String? = nil) {
        self.context = context
        self.attemptSummary = attemptSummary
    }
}

struct SmartPlayStoryRequest: Equatable, Sendable {
    let context: SmartPlayActivityContext
    let storySeed: String?

    init(context: SmartPlayActivityContext, storySeed: String? = nil) {
        self.context = context
        self.storySeed = storySeed
    }
}

struct SmartPlayReviewPromptRequest: Equatable, Sendable {
    let context: SmartPlayActivityContext
    let completedSkillSummary: String?

    init(context: SmartPlayActivityContext, completedSkillSummary: String? = nil) {
        self.context = context
        self.completedSkillSummary = completedSkillSummary
    }
}

enum SmartPlayRequest: Equatable, Sendable {
    case hint(SmartPlayHintRequest)
    case story(SmartPlayStoryRequest)
    case reviewPrompt(SmartPlayReviewPromptRequest)
}

protocol SmartPlayProvider: Sendable {
    func prompt(for request: SmartPlayRequest) async -> SmartPlayPrompt
}

struct CuratedSmartPlayProvider: SmartPlayProvider {
    func prompt(for request: SmartPlayRequest) async -> SmartPlayPrompt {
        switch request {
        case let .hint(request):
            SmartPlayPrompt(
                kind: .hint,
                spokenText: hintText(for: request),
                source: .curatedFallback
            )
        case let .story(request):
            SmartPlayPrompt(
                kind: .story,
                spokenText: storyText(for: request),
                source: .curatedFallback
            )
        case let .reviewPrompt(request):
            SmartPlayPrompt(
                kind: .review,
                spokenText: reviewText(for: request),
                source: .curatedFallback
            )
        }
    }

    private func hintText(for request: SmartPlayHintRequest) -> String {
        let goal = clean(request.context.goal)
        if let problemText = cleanOptional(request.context.problemText) {
            return "Try one careful move for \(problemText). Then check how it helps with \(goal)."
        }
        return "Try one careful move. Then check how it helps with \(goal)."
    }

    private func storyText(for request: SmartPlayStoryRequest) -> String {
        let goal = clean(request.context.goal)
        if let theme = cleanOptional(request.context.themeID) {
            return "Here is a \(theme) story. We are exploring \(goal) with calm, careful choices."
        }
        return "Here is a learning story. We are exploring \(goal) with calm, careful choices."
    }

    private func reviewText(for request: SmartPlayReviewPromptRequest) -> String {
        if let summary = cleanOptional(request.completedSkillSummary) {
            return "Show that idea one more way: \(summary). Say what stayed the same."
        }
        let goal = clean(request.context.goal)
        return "Show \(goal) one more way. Say what stayed the same."
    }

    private func cleanOptional(_ text: String?) -> String? {
        guard let cleaned = text.map(clean), !cleaned.isEmpty else { return nil }
        return cleaned
    }

    private func clean(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
