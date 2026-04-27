import Foundation

enum NumberStoryTemplateID: String, Codable, CaseIterable, Identifiable {
    case spaceCargo = "space_cargo"
    case vehicleGarage = "vehicle_garage"
    case gardenSeedShop = "garden_seed_shop"
    case festivalPrep = "festival_prep"

    var id: String { rawValue }
}

enum NumberStoryRepresentationHint: String, Codable {
    case singles
    case tenFrames
    case tensAndOnes
    case hundredsTensOnes
    case thousandBlock
}

struct NumberStoryPrompt: Identifiable, Codable, Equatable {
    let id: String
    let templateID: NumberStoryTemplateID
    let title: String
    let spokenIntro: String
    let reminder: String
    let successLine: String
    let target: Int
    let leftPart: Int
    let rightPart: Int
    let objectNoun: String
    let leftContainer: String
    let rightContainer: String
    let representationHint: NumberStoryRepresentationHint
}
