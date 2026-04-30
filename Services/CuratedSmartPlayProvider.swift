import Foundation

@MainActor
struct CuratedSmartPlayProvider: SmartPlayProvider {
    func hint(for request: SmartPlayHintRequest) async -> SmartPlayHintResponse {
        SmartPlayHintResponse(
            spokenText: hintText(for: request),
            source: .curatedFallback
        )
    }

    func story(for request: SmartPlayStoryRequest) async -> SmartPlayStoryResponse {
        SmartPlayStoryResponse(
            spokenText: storyText(for: request),
            source: .curatedFallback
        )
    }

    func reviewPrompt(for request: SmartPlayReviewPromptRequest) async -> SmartPlayReviewPromptResponse {
        SmartPlayReviewPromptResponse(
            spokenText: reviewText(for: request),
            source: .curatedFallback
        )
    }

    private func hintText(for request: SmartPlayHintRequest) -> String {
        let context = request.context.normalizedTokens
        if context.contains("make-break-10") || context.contains("vs1") {
            if request.attemptCount >= 2 {
                return "Try making one group smaller and the other group bigger. Count both groups together."
            }
            return "Try moving one counter, then count each group."
        }

        if context.contains("sum-sprint") {
            return "Look for the number that joins with this one. Then say the whole amount."
        }

        if context.contains("room-quest") {
            return "Look carefully at the place, then try the closest matching spot."
        }

        return "Try one small move, then check what changed."
    }

    private func storyText(for request: SmartPlayStoryRequest) -> String {
        let context = request.context.normalizedTokens
        if context.contains("make-break-10") || context.contains("vs1") {
            let target = request.targetNumber ?? 10
            return "The builders are sharing \(target) blocks between two trucks. Move the blocks until both trucks match your plan."
        }

        if context.contains("sum-sprint") {
            return "The cards are racing to find their partner. Match the numbers and keep the race moving."
        }

        if context.contains("room-quest") {
            return "The room has a secret math spot. Find the matching place and check it like a detective."
        }

        let theme = request.theme.flatMap { $0.trimmedNonEmpty } ?? "math"
        return "This \(theme) challenge needs careful looking. Try a move, then check your answer."
    }

    private func reviewText(for request: SmartPlayReviewPromptRequest) -> String {
        let context = request.context.normalizedTokens
        if context.contains("make-break-10") || context.contains("vs1") {
            return "Show how you made the number two ways. Tell which parts stayed the same."
        }

        if request.retryCount > request.successCount {
            return "Show one tricky part again. Tell what you will try first next time."
        }

        if request.successCount > 0 {
            return "Show your favorite answer from today. Tell how you knew it worked."
        }

        return "Show one thing you tried. Tell what changed when you tried it."
    }
}

private extension SmartPlayRequestContext {
    var normalizedTokens: Set<String> {
        Set(
            [laneID, stageID, activityID, learningGoal]
                .compactMap { $0.flatMap { value in value.trimmedNonEmpty }?.lowercased() }
        )
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
