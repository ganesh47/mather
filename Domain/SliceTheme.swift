import Foundation

/// Describes how a counter cell is rendered — shape, SF Symbol, or local image asset.
enum CounterKind: Equatable {
    case circle
    case themedSymbol(symbolName: String, assetName: String?)
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

/// A space-themed VS1 session for the parent-facing Planets setup card.
///
/// Uses a simple SF Symbol counter so the first slice stays asset-light while
/// still giving the child space vocabulary in the CPA loop.
struct SpaceTheme: SliceTheme {
    var counterKind: CounterKind { .themedSymbol(symbolName: "sparkles", assetName: nil) }
    var celebrationEmoji: String { "🚀" }
    var counterNoun: String { "star bolts" }

    func concretePrompt(target: Int) -> String {
        "Load \(target) star bolts for the rocket."
    }

    func pictorialPrompt(target: Int) -> String {
        "Split \(target) star bolts between two space bays."
    }

    func abstractPrompt() -> String {
        "Type the same space split as an equation."
    }

    func transferPrompt(decompositionA: Int, decompositionB: Int) -> String {
        "Load the same star bolt total from memory."
    }

    func stageSuccessPhrase(for stage: SliceStage, target: Int) -> String {
        switch stage {
        case .storyAnchor:
            return "Mission ready."
        case .concrete:
            return "Yes. You loaded \(target) star bolts."
        case .pictorial:
            return "Those bays still make \(target)."
        case .abstract:
            return "Your equation matches the space split."
        case .transfer:
            return "You loaded the same total from memory."
        case .bondMatch:
            return "Those bonds are ready."
        case .gravitySplit:
            return "Space balance made."
        case .sumSprint:
            return "Space burst complete."
        case .done:
            return "Problem complete."
        }
    }

    func sessionIntroPhrase() -> String {
        "Let's make and break numbers with space cargo."
    }

    func sessionEndPhrase() -> String {
        "Mission complete. You made and broke numbers with space cargo."
    }

    func sessionStartFeedback() -> String {
        "Load the star bolts on the rocket pad."
    }
}
