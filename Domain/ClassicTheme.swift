import Foundation

/// The default theme — reproduces every hardcoded string and circle counter
/// from the original engine. Behaviour is unchanged when ClassicTheme is active.
struct ClassicTheme: SliceTheme {
    var counterKind: CounterKind { .circle }
    var celebrationEmoji: String { "⭐️" }
    var counterNoun: String { "counters" }

    func concretePrompt(target: Int) -> String {
        "Make \(target) with the counters."
    }

    func pictorialPrompt(target: Int) -> String {
        "Break \(target) into two groups."
    }

    func abstractPrompt() -> String {
        "Type the same split as an equation."
    }

    func transferPrompt(decompositionA: Int, decompositionB: Int) -> String {
        "Show the same equation with counters again. Build the two parts from memory."
    }

    func stageSuccessPhrase(for stage: SliceStage, target: Int) -> String {
        switch stage {
        case .storyAnchor: return "Story ready."
        case .concrete:   return "Yes. You made \(target)."
        case .pictorial:  return "That break still makes \(target)."
        case .abstract:   return "Your equation matches the split."
        case .transfer:   return "You matched the same equation with counters."
        case .gravitySplit: return "Perfect balance!"
        case .sumSprint:  return "Nice sprint!"
        case .bondMatch:  return "Bond Blast complete!"
        case .done:       return "Problem complete."
        }
    }

    func sessionIntroPhrase() -> String {
        "Let's make and break numbers in different ways."
    }

    func sessionEndPhrase() -> String {
        "Session complete. Great job showing the same number in different ways."
    }

    func sessionStartFeedback() -> String {
        "Make the target number with the big counters."
    }
}
