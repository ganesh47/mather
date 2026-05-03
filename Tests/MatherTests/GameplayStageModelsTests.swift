import Foundation
import Testing
@testable import Mather

struct GameplayStageModelsTests {
    @Test
    func threadDefinitionSupportsEntitiesPropertiesVisualsAudioAndStages() {
        let capital = GameplayPropertyType(id: "capital", title: "Capital", icon: "building.columns", learningPriority: 2)
        let flag = GameplayPropertyType(id: "flag", title: "Flag", icon: "flag", learningPriority: 1)
        let india = GameplayEntity(
            id: "india",
            name: "India",
            visual: .emoji("🇮🇳"),
            audioCue: GameplayAudioCue(text: "India"),
            explanation: "India is a country in Asia.",
            properties: [
                GameplayProperty(id: "india-flag", typeID: "flag", value: "Indian flag", visual: .emoji("🇮🇳")),
                GameplayProperty(id: "india-capital", typeID: "capital", value: "New Delhi", explanation: "New Delhi is India's capital.")
            ]
        )

        let thread = GameplayThreadDefinition(
            id: "countries",
            title: "Countries",
            category: .countries,
            entities: [india],
            propertyTypes: [capital, flag]
        )

        #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
        #expect(thread.propertyTypes.map(\.id) == ["flag", "capital"])
        #expect(thread.entity(for: "india")?.properties(ofType: "capital").first?.value == "New Delhi")
        #expect(thread.entities.first?.audioCue?.text == "India")
    }

    @Test
    func progressionPolicyDefaultsToFullGameplayThreadOrder() {
        let policy = GameplayProgressionPolicy.standard
        #expect(policy.requiredStageOrder == GameplayStageKind.allCases)
        #expect(policy.minimumAccuracyToAdvance == 0.7)
        #expect(policy.reviewWeakItemsBetweenStages)
    }
}
