import Foundation

/// Describes how a counter cell is rendered — shape or SF Symbol.
enum CounterKind: Equatable {
    case circle
    case vehicle(symbolName: String)
}

/// A theme controls the vocabulary and counter appearance for a VS1 session.
/// It is a pure value type: no state, no observation, no actor isolation.
/// The engine freezes the active theme at `startSession()` and holds it for the
/// duration of the session — themes never change mid-session.
protocol SliceTheme {
    /// How counter cells are rendered in the concrete, split, and transfer views.
    var counterKind: CounterKind { get }

    /// Emoji shown in the fullscreen celebration overlay on a correct stage answer.
    var celebrationEmoji: String { get }

    /// Noun for a single counter — used in failure hint copy so the hint matches
    /// the active theme's vocabulary (e.g. "counters" vs "cars").
    var counterNoun: String { get }

    // MARK: - Stage prompts (spoken by SpeechService)

    func concretePrompt(target: Int) -> String
    func pictorialPrompt(target: Int) -> String
    func abstractPrompt() -> String
    func transferPrompt(decompositionA: Int, decompositionB: Int) -> String

    // MARK: - Success messages

    /// Spoken when the child completes a stage correctly.
    func stageSuccessPhrase(for stage: SliceStage, target: Int) -> String

    // MARK: - Session lifecycle phrases

    func sessionIntroPhrase() -> String
    func sessionEndPhrase() -> String
    /// Shown as `feedbackMessage` at the start of a session (before first prompt).
    func sessionStartFeedback() -> String
}
