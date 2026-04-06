import Foundation

/// A concrete vehicle persona that drives all CPA vocabulary for one problem.
///
/// Each spec bundles the SF Symbol, noun, emoji, and all stage prompts so that
/// `VehicleTheme` can delegate everything to the active spec. The engine cycles
/// through `VehicleSpec.pool` — one spec per problem — giving children a fresh
/// vehicle on every question without breaking CPA coherence within a problem.
struct VehicleSpec {
    let symbolName: String
    let counterNoun: String
    let celebrationEmoji: String
    let concretePromptFn: (Int) -> String
    let pictorialPromptFn: (Int) -> String
    let abstractPromptFn: () -> String
    let transferPromptFn: (Int, Int) -> String
    let stageSuccessFn: (SliceStage, Int) -> String
    let sessionIntroFn: () -> String
    let sessionEndFn: () -> String
    let sessionStartFeedbackFn: () -> String
}

extension VehicleSpec {
    /// Ordered pool — engine iterates through this list, one per problem, wrapping around.
    static let pool: [VehicleSpec] = [
        .car, .pickupTruck, .boxTruck, .bus, .bulldozer, .helicopter, .airplane,
    ]

    static let car = VehicleSpec(
        symbolName: "car.fill",
        counterNoun: "cars",
        celebrationEmoji: "🚗",
        concretePromptFn: { "Park \($0) cars in the garage." },
        pictorialPromptFn: { _ in "Split the cars into two parking zones." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { "\($0) cars on the left and \($1) on the right." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .concrete:  return "You filled the garage!"
            case .pictorial: return "Both zones together make the same number."
            case .abstract:  return "Your equation matches the split."
            case .transfer:  return "You parked them perfectly."
            case .done:      return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's park and split cars to ten." },
        sessionEndFn: { "Session complete. Great parking!" },
        sessionStartFeedbackFn: { "Park the cars in the garage." }
    )

    static let pickupTruck = VehicleSpec(
        symbolName: "truck.pickup.side.fill",
        counterNoun: "trucks",
        celebrationEmoji: "🛻",
        concretePromptFn: { "Load \($0) trucks at the depot." },
        pictorialPromptFn: { _ in "Split the trucks into two groups." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { "\($0) trucks on the left and \($1) on the right." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .concrete:  return "All trucks loaded!"
            case .pictorial: return "Both groups add up to the same number."
            case .abstract:  return "Your equation matches the split."
            case .transfer:  return "Trucks delivered perfectly."
            case .done:      return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's load and split trucks to ten." },
        sessionEndFn: { "Session complete. Great hauling!" },
        sessionStartFeedbackFn: { "Load the trucks at the depot." }
    )

    static let boxTruck = VehicleSpec(
        symbolName: "truck.box.fill",
        counterNoun: "vans",
        celebrationEmoji: "🚚",
        concretePromptFn: { "Send \($0) vans to the warehouse." },
        pictorialPromptFn: { _ in "Split the vans into two routes." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { "\($0) vans on the left and \($1) on the right." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .concrete:  return "Warehouse full!"
            case .pictorial: return "Both routes carry the same total."
            case .abstract:  return "Your equation matches the split."
            case .transfer:  return "Vans delivered!"
            case .done:      return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's deliver vans to ten." },
        sessionEndFn: { "Session complete. All delivered!" },
        sessionStartFeedbackFn: { "Send the vans to the warehouse." }
    )

    static let bus = VehicleSpec(
        symbolName: "bus.fill",
        counterNoun: "buses",
        celebrationEmoji: "🚌",
        concretePromptFn: { "Fill \($0) buses with passengers." },
        pictorialPromptFn: { _ in "Split the buses into two stops." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { "\($0) buses at the left stop and \($1) at the right." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .concrete:  return "All aboard!"
            case .pictorial: return "Both stops total the same."
            case .abstract:  return "Your equation matches the split."
            case .transfer:  return "Buses on route!"
            case .done:      return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's fill buses to ten." },
        sessionEndFn: { "Session complete. Everyone on board!" },
        sessionStartFeedbackFn: { "Fill the buses with passengers." }
    )

    static let bulldozer = VehicleSpec(
        symbolName: "bulldozer.fill",
        counterNoun: "bulldozers",
        celebrationEmoji: "🚧",
        concretePromptFn: { "Line up \($0) bulldozers on the site." },
        pictorialPromptFn: { _ in "Split the bulldozers into two zones." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { "\($0) bulldozers on the left and \($1) on the right." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .concrete:  return "Site ready!"
            case .pictorial: return "Both zones cover the same total."
            case .abstract:  return "Your equation matches the split."
            case .transfer:  return "Bulldozers in position!"
            case .done:      return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's line up bulldozers to ten." },
        sessionEndFn: { "Session complete. Great work on the site!" },
        sessionStartFeedbackFn: { "Line up the bulldozers on the site." }
    )

    static let helicopter = VehicleSpec(
        symbolName: "helicopter",
        counterNoun: "helicopters",
        celebrationEmoji: "🚁",
        concretePromptFn: { "Land \($0) helicopters on the pad." },
        pictorialPromptFn: { _ in "Split the helicopters into two pads." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { "\($0) helicopters on the left pad and \($1) on the right." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .concrete:  return "All landed!"
            case .pictorial: return "Both pads together hold the same total."
            case .abstract:  return "Your equation matches the split."
            case .transfer:  return "Helicopters landed perfectly."
            case .done:      return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's land helicopters to ten." },
        sessionEndFn: { "Session complete. Great landing!" },
        sessionStartFeedbackFn: { "Land the helicopters on the pad." }
    )

    static let airplane = VehicleSpec(
        symbolName: "airplane",
        counterNoun: "planes",
        celebrationEmoji: "✈️",
        concretePromptFn: { "Park \($0) planes at the gate." },
        pictorialPromptFn: { _ in "Split the planes into two terminals." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { "\($0) planes at the left terminal and \($1) at the right." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .concrete:  return "All planes at the gate!"
            case .pictorial: return "Both terminals hold the same total."
            case .abstract:  return "Your equation matches the split."
            case .transfer:  return "Planes ready for take-off!"
            case .done:      return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's park planes to ten." },
        sessionEndFn: { "Session complete. Safe travels!" },
        sessionStartFeedbackFn: { "Park the planes at the gate." }
    )
}
