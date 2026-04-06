import Foundation

/// A vehicle-themed session — replaces abstract circles with a vehicle SF Symbol
/// and uses scenario-specific vocabulary throughout the CPA loop.
///
/// The active `VehicleSpec` determines which vehicle appears and what language is
/// used. The engine cycles through `VehicleSpec.pool` one per problem so each
/// question brings a fresh vehicle without breaking CPA coherence within a problem.
///
/// Pedagogical rationale: vehicles are a peak intrinsic interest domain for
/// ages 5-6 (Alexander et al., 2008). Spatial grounding in a familiar scenario
/// activates the same embodied simulation circuits as hands-on manipulation
/// (Glenberg et al., 2004). The 2×5 ten-frame structure is preserved —
/// subitising depends on spatial arrangement, not object shape (Clements, 2002).
struct VehicleTheme: SliceTheme {
    private let spec: VehicleSpec

    init(spec: VehicleSpec = .car) { self.spec = spec }

    var counterKind: CounterKind { .vehicle(symbolName: spec.symbolName) }
    var celebrationEmoji: String { spec.celebrationEmoji }
    var counterNoun: String { spec.counterNoun }

    func concretePrompt(target: Int) -> String { spec.concretePromptFn(target) }
    func pictorialPrompt(target: Int) -> String { spec.pictorialPromptFn(target) }
    func abstractPrompt() -> String { spec.abstractPromptFn() }
    func transferPrompt(decompositionA: Int, decompositionB: Int) -> String {
        spec.transferPromptFn(decompositionA, decompositionB)
    }
    func stageSuccessPhrase(for stage: SliceStage, target: Int) -> String {
        spec.stageSuccessFn(stage, target)
    }
    func sessionIntroPhrase() -> String { spec.sessionIntroFn() }
    func sessionEndPhrase() -> String { spec.sessionEndFn() }
    func sessionStartFeedback() -> String { spec.sessionStartFeedbackFn() }
}
