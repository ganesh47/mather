import Foundation

enum NumberStoryGenerator {
    static func prompt(for problem: SliceProblem, themeId: String) -> NumberStoryPrompt {
        let pack = pack(for: problem.target, themeId: themeId)
        return pack.prompt(for: problem)
    }

    private static func pack(for target: Int, themeId: String) -> NumberStoryPack {
        let normalizedTheme = themeId.lowercased()

        let preferred: NumberStoryTemplateID
        switch normalizedTheme {
        case "vehicle", "vehicles", "vehicle_garage":
            preferred = .vehicleGarage
        case "garden", "garden_seed_shop":
            preferred = .gardenSeedShop
        case "festival", "festival_prep":
            preferred = .festivalPrep
        case "space", "planets", "space_cargo":
            preferred = .spaceCargo
        default:
            preferred = classicTemplate(for: target)
        }

        if let pack = packs[preferred], pack.supports(target) {
            return pack
        }

        return packs[.spaceCargo] ?? NumberStoryPack.spaceCargo
    }

    private static func classicTemplate(for target: Int) -> NumberStoryTemplateID {
        switch target {
        case 1...10:
            return .gardenSeedShop
        case 11...20:
            return .spaceCargo
        case 21...100:
            return .festivalPrep
        default:
            return .spaceCargo
        }
    }

    private static let packs: [NumberStoryTemplateID: NumberStoryPack] = [
        .spaceCargo: .spaceCargo,
        .vehicleGarage: .vehicleGarage,
        .gardenSeedShop: .gardenSeedShop,
        .festivalPrep: .festivalPrep,
    ]
}

private struct NumberStoryPack {
    let id: NumberStoryTemplateID
    let title: String
    let supportedRange: ClosedRange<Int>
    let setting: String
    let action: String
    let objectNoun: String
    let leftContainer: String
    let rightContainer: String
    let successVerb: String

    func supports(_ target: Int) -> Bool {
        supportedRange.contains(target)
    }

    func prompt(for problem: SliceProblem) -> NumberStoryPrompt {
        let target = problem.target
        let leftPart = problem.decompositionA
        let rightPart = problem.decompositionB
        let noun = objectNoun
        let hint = NumberStoryRepresentationHint.forTarget(target)

        return NumberStoryPrompt(
            id: "\(id.rawValue)-\(target)-\(leftPart)-\(rightPart)",
            templateID: id,
            title: title,
            spokenIntro: "\(setting) needs \(target) \(noun). \(action) \(leftPart) in \(leftContainer) and \(rightPart) in \(rightContainer).",
            reminder: "Remember: \(target) \(noun).",
            successLine: "Yes: \(leftPart) and \(rightPart) \(successVerb) \(target) \(noun).",
            target: target,
            leftPart: leftPart,
            rightPart: rightPart,
            objectNoun: noun,
            leftContainer: leftContainer,
            rightContainer: rightContainer,
            representationHint: hint
        )
    }

    static let spaceCargo = NumberStoryPack(
        id: .spaceCargo,
        title: "Space Cargo",
        supportedRange: 1...1_000,
        setting: "The rocket",
        action: "Load",
        objectNoun: "star bolts",
        leftContainer: "the silver bay",
        rightContainer: "the blue bay",
        successVerb: "make"
    )

    static let vehicleGarage = NumberStoryPack(
        id: .vehicleGarage,
        title: "Vehicle Garage",
        supportedRange: 1...1_000,
        setting: "The garage",
        action: "Park",
        objectNoun: "wheels",
        leftContainer: "the red lift",
        rightContainer: "the blue lift",
        successVerb: "make"
    )

    static let gardenSeedShop = NumberStoryPack(
        id: .gardenSeedShop,
        title: "Seed Shop",
        supportedRange: 1...100,
        setting: "The garden",
        action: "Plant",
        objectNoun: "seeds",
        leftContainer: "the sunny bed",
        rightContainer: "the shady bed",
        successVerb: "grow into"
    )

    static let festivalPrep = NumberStoryPack(
        id: .festivalPrep,
        title: "Festival Prep",
        supportedRange: 1...1_000,
        setting: "The festival",
        action: "Place",
        objectNoun: "lanterns",
        leftContainer: "the stage tray",
        rightContainer: "the gate tray",
        successVerb: "make"
    )
}

private extension NumberStoryRepresentationHint {
    static func forTarget(_ target: Int) -> NumberStoryRepresentationHint {
        switch target {
        case 1...10:
            return .singles
        case 11...20:
            return .tenFrames
        case 21...100:
            return .tensAndOnes
        case 1_000:
            return .thousandBlock
        default:
            return .hundredsTensOnes
        }
    }
}
