import Foundation

/// A vehicle-themed session — replaces abstract circles with car SF symbols
/// and uses parking-lot vocabulary throughout the CPA loop.
///
/// Pedagogical rationale: vehicles are a peak intrinsic interest domain for
/// ages 5-6 (Alexander et al., 2008). Spatial grounding in a familiar scenario
/// ("park 7 cars") activates the same embodied simulation circuits as hands-on
/// manipulation (Glenberg et al., 2004), accelerating concrete number sense.
/// The 2×5 ten-frame structure is preserved — subitising depends on spatial
/// arrangement, not object shape (Clements, 2002).
struct VehicleTheme: SliceTheme {
    var counterKind: CounterKind { .vehicle(symbolName: "car.fill") }
    var celebrationEmoji: String { "🚗" }
    var counterNoun: String { "cars" }

    func concretePrompt(target: Int) -> String {
        "Park \(target) cars in the garage."
    }

    func pictorialPrompt(target: Int) -> String {
        "Split the cars into two parking zones."
    }

    func abstractPrompt() -> String {
        "Write the split as an equation."
    }

    func transferPrompt(decompositionA: Int, decompositionB: Int) -> String {
        "Park the cars again — \(decompositionA) on the left and \(decompositionB) on the right."
    }

    func stageSuccessPhrase(for stage: SliceStage, target: Int) -> String {
        switch stage {
        case .concrete:  return "You filled the garage!"
        case .pictorial: return "Both zones together make the same number."
        case .abstract:  return "Your equation matches the split."
        case .transfer:  return "You parked them perfectly."
        case .done:      return "Problem complete."
        }
    }

    func sessionIntroPhrase() -> String {
        "Let's park and split cars to ten."
    }

    func sessionEndPhrase() -> String {
        "Session complete. Great parking!"
    }

    func sessionStartFeedback() -> String {
        "Park the cars in the garage."
    }
}
