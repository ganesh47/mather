import Foundation

/// A concrete vehicle persona that drives all CPA vocabulary for one problem.
///
/// Each spec bundles the SF Symbol, noun, emoji, and all stage prompts so that
/// `VehicleTheme` can delegate everything to the active spec. The engine cycles
/// through `VehicleSpec.pool` — one spec per problem — giving children a fresh
/// vehicle on every question without breaking CPA coherence within a problem.
struct VehicleSpec: Sendable {
    let symbolName: String
    let assetName: String?
    let counterNoun: String
    let celebrationEmoji: String
    let concretePromptFn: @Sendable (Int) -> String
    let pictorialPromptFn: @Sendable (Int) -> String
    let abstractPromptFn: @Sendable () -> String
    let transferPromptFn: @Sendable (Int, Int) -> String
    let stageSuccessFn: @Sendable (SliceStage, Int) -> String
    let sessionIntroFn: @Sendable () -> String
    let sessionEndFn: @Sendable () -> String
    let sessionStartFeedbackFn: @Sendable () -> String
}

extension VehicleSpec {
    /// Ordered pool — engine iterates through this list, one per problem, wrapping around.
    static let pool: [VehicleSpec] = [
        .car, .pickupTruck, .boxTruck, .bus, .bulldozer, .dumpTruck, .cementMixer, .miningTruck, .helicopter, .airplane,
    ]

    static let car = VehicleSpec(
        symbolName: "car.fill",
        assetName: "VS1VehicleCar",
        counterNoun: "cars",
        celebrationEmoji: "🚗",
        concretePromptFn: { "Park \($0) cars in the garage." },
        pictorialPromptFn: { _ in "Split the cars into two parking zones." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Park the cars to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "You filled the garage!"
            case .pictorial:  return "Both zones together make the same number."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "You parked them perfectly."
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's park and split cars in different ways." },
        sessionEndFn: { "Session complete. Great parking!" },
        sessionStartFeedbackFn: { "Park the cars in the garage." }
    )

    static let pickupTruck = VehicleSpec(
        symbolName: "truck.pickup.side.fill",
        assetName: "VS1VehiclePickupTruck",
        counterNoun: "trucks",
        celebrationEmoji: "🛻",
        concretePromptFn: { "Load \($0) trucks at the depot." },
        pictorialPromptFn: { _ in "Split the trucks into two groups." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Park the trucks to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "All trucks loaded!"
            case .pictorial:  return "Both groups add up to the same number."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Trucks delivered perfectly."
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's load and split trucks in different ways." },
        sessionEndFn: { "Session complete. Great hauling!" },
        sessionStartFeedbackFn: { "Load the trucks at the depot." }
    )

    static let boxTruck = VehicleSpec(
        symbolName: "truck.box.fill",
        assetName: nil,
        counterNoun: "vans",
        celebrationEmoji: "🚚",
        concretePromptFn: { "Send \($0) vans to the warehouse." },
        pictorialPromptFn: { _ in "Split the vans into two routes." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Park the vans to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "Warehouse full!"
            case .pictorial:  return "Both routes carry the same total."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Vans delivered!"
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's deliver vans in different ways." },
        sessionEndFn: { "Session complete. All delivered!" },
        sessionStartFeedbackFn: { "Send the vans to the warehouse." }
    )

    static let bus = VehicleSpec(
        symbolName: "bus.fill",
        assetName: nil,
        counterNoun: "buses",
        celebrationEmoji: "🚌",
        concretePromptFn: { "Fill \($0) buses with passengers." },
        pictorialPromptFn: { _ in "Split the buses into two stops." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Park the buses to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "All aboard!"
            case .pictorial:  return "Both stops total the same."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Buses on route!"
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's fill buses in different ways." },
        sessionEndFn: { "Session complete. Everyone on board!" },
        sessionStartFeedbackFn: { "Fill the buses with passengers." }
    )

    static let bulldozer = VehicleSpec(
        symbolName: "bulldozer.fill",
        assetName: "VS1VehicleBulldozer",
        counterNoun: "bulldozers",
        celebrationEmoji: "🚧",
        concretePromptFn: { "Line up \($0) bulldozers on the site." },
        pictorialPromptFn: { _ in "Split the bulldozers into two zones." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Place the bulldozers to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "Site ready!"
            case .pictorial:  return "Both zones cover the same total."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Bulldozers in position!"
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's line up bulldozers in different ways." },
        sessionEndFn: { "Session complete. Great work on the site!" },
        sessionStartFeedbackFn: { "Line up the bulldozers on the site." }
    )

    static let dumpTruck = VehicleSpec(
        symbolName: "truck.box.fill",
        assetName: "VS1VehicleDumpTruck",
        counterNoun: "dump trucks",
        celebrationEmoji: "🚚",
        concretePromptFn: { "Load \($0) dump trucks at the quarry." },
        pictorialPromptFn: { _ in "Split the dump trucks into two work zones." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Place the dump trucks to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "Quarry crew ready!"
            case .pictorial:  return "Both work zones add up to the same total."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Dump trucks in position!"
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's load dump trucks in different ways." },
        sessionEndFn: { "Session complete. Great hauling!" },
        sessionStartFeedbackFn: { "Load the dump trucks at the quarry." }
    )

    static let cementMixer = VehicleSpec(
        symbolName: "cement.truck.fill",
        assetName: "VS1VehicleCementMixer",
        counterNoun: "cement mixers",
        celebrationEmoji: "🚛",
        concretePromptFn: { "Roll out \($0) cement mixers for the pour." },
        pictorialPromptFn: { _ in "Split the cement mixers into two crews." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Place the cement mixers to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "Mixer crew ready!"
            case .pictorial:  return "Both crews add up to the same total."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Cement mixers lined up!"
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's roll cement mixers in different ways." },
        sessionEndFn: { "Session complete. Smooth work!" },
        sessionStartFeedbackFn: { "Roll out the cement mixers for the pour." }
    )

    static let miningTruck = VehicleSpec(
        symbolName: "truck.box.fill",
        assetName: "VS1VehicleMiningTruck",
        counterNoun: "mining trucks",
        celebrationEmoji: "⛏️",
        concretePromptFn: { "Send \($0) mining trucks to the pit." },
        pictorialPromptFn: { _ in "Split the mining trucks into two roads." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Place the mining trucks to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "Heavy trucks ready!"
            case .pictorial:  return "Both roads carry the same total."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Mining trucks lined up!"
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's send mining trucks in different ways." },
        sessionEndFn: { "Session complete. Mighty hauling!" },
        sessionStartFeedbackFn: { "Send the mining trucks to the pit." }
    )


    static let helicopter = VehicleSpec(
        symbolName: "helicopter",
        assetName: nil,
        counterNoun: "helicopters",
        celebrationEmoji: "🚁",
        concretePromptFn: { "Land \($0) helicopters on the pad." },
        pictorialPromptFn: { _ in "Split the helicopters into two pads." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Land the helicopters to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "All landed!"
            case .pictorial:  return "Both pads together hold the same total."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Helicopters landed perfectly."
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's land helicopters in different ways." },
        sessionEndFn: { "Session complete. Great landing!" },
        sessionStartFeedbackFn: { "Land the helicopters on the pad." }
    )

    static let airplane = VehicleSpec(
        symbolName: "airplane",
        assetName: nil,
        counterNoun: "planes",
        celebrationEmoji: "✈️",
        concretePromptFn: { "Park \($0) planes at the gate." },
        pictorialPromptFn: { _ in "Split the planes into two terminals." },
        abstractPromptFn: { "Write the split as an equation." },
        transferPromptFn: { _, _ in "Park the planes to show the same total from memory." },
        stageSuccessFn: { stage, _ in
            switch stage {
            case .storyAnchor: return "Story ready."
            case .concrete:   return "All planes at the gate!"
            case .pictorial:  return "Both terminals hold the same total."
            case .abstract:   return "Your equation matches the split."
            case .transfer:   return "Planes ready for take-off!"
            case .gravitySplit: return "Perfect balance!"
            case .sumSprint:  return "Nice sprint!"
            case .bondMatch:  return "Bond Blast complete!"
            case .done:       return "Problem complete."
            }
        },
        sessionIntroFn: { "Let's park planes in different ways." },
        sessionEndFn: { "Session complete. Safe travels!" },
        sessionStartFeedbackFn: { "Park the planes at the gate." }
    )
}
