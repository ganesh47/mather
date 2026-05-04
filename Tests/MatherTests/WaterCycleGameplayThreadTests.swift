import Foundation
import Testing
@testable import Mather

struct WaterCycleGameplayThreadTests {
    @Test
    func waterCycleThreadModelsCoreProcessStepsWithRequiredProperties() {
        let thread = GameplayThreadCatalog.waterCycle

        #expect(thread.id == "water-cycle")
        #expect(thread.entities.map(\.id) == [
            "water-cycle-evaporation",
            "water-cycle-condensation",
            "water-cycle-precipitation",
            "water-cycle-collection"
        ])
        #expect(Set(thread.propertyTypes.map(\.id)) == ["order", "simpleExplanation", "cause", "whatHappens", "visualClue"])

        for entity in thread.entities {
            let propertyTypeIDs = Set(entity.properties.map(\.typeID))
            #expect(propertyTypeIDs == ["order", "simpleExplanation", "cause", "whatHappens", "visualClue"])
            #expect(entity.visualAssetName?.hasPrefix("MemoryWaterCycle") == true)
            #expect(entity.properties.allSatisfy { !$0.value.isEmpty })
        }
    }

    @Test
    func waterCycleOrderCluesFollowEvaporationToCollectionSequence() {
        let thread = GameplayThreadCatalog.waterCycle
        let orderValues = thread.entities.compactMap { entity in
            entity.properties.first { $0.typeID == "order" }?.value
        }

        #expect(orderValues == ["1 of 4", "2 of 4", "3 of 4", "4 of 4"])
        #expect(thread.entities[0].properties.first { $0.typeID == "cause" }?.value.localizedCaseInsensitiveContains("sun") == true)
        #expect(thread.entities[1].properties.first { $0.typeID == "whatHappens" }?.value.localizedCaseInsensitiveContains("droplets") == true)
        #expect(thread.entities[2].properties.first { $0.typeID == "visualClue" }?.value.localizedCaseInsensitiveContains("rain") == true)
        #expect(thread.entities[3].properties.first { $0.typeID == "whatHappens" }?.value.localizedCaseInsensitiveContains("ponds") == true)
    }


    @Test
    func waterCycleFlashcardsExposeLargeRenderableAssetMetadata() {
        let thread = GameplayThreadCatalog.waterCycle
        let stage = thread.stages[0]
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 5)
        let cards = GameplayStageContentBuilder.flashcards(thread: thread, round: round)

        #expect(cards.count == 4)
        #expect(cards.allSatisfy { $0.visualAssetName?.hasPrefix("MemoryWaterCycle") == true })
        #expect(cards.allSatisfy { $0.visualShapeKey == nil })
    }

    @Test
    func waterCycleStagesGenerateFocusedRounds() {
        let thread = GameplayThreadCatalog.waterCycle

        #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])

        let flashcardStage = thread.stages[0]
        let flashcardRound = SpacedRepetitionScheduler.makeRound(thread: thread, stage: flashcardStage, seed: 912)
        #expect(flashcardRound.items.count == 4)
        #expect(flashcardRound.items.allSatisfy { $0.propertyID == nil && $0.propertyTypeID == nil })

        let orderStage = thread.stages[1]
        let orderRound = SpacedRepetitionScheduler.makeRound(thread: thread, stage: orderStage, seed: 912)
        #expect(orderRound.items.count == 4)
        #expect(orderRound.items.allSatisfy { $0.propertyTypeID == "order" })

        let bondStage = thread.stages[3]
        let bondRound = SpacedRepetitionScheduler.makeRound(thread: thread, stage: bondStage, seed: 912)
        #expect(bondRound.items.count == 8)
        #expect(Set(bondRound.items.compactMap(\.propertyTypeID)) == ["cause", "visualClue"])

        let quizStage = thread.stages[4]
        let quizRound = SpacedRepetitionScheduler.makeRound(thread: thread, stage: quizStage, seed: 912)
        let quizViewModel = GameplayMultipleChoiceStageViewModel(thread: thread, round: quizRound)
        #expect(quizViewModel.questions.count == 4)
        #expect(quizViewModel.questions.allSatisfy { $0.choices.contains($0.answer) })
    }
}
