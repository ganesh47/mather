import Foundation
import Testing
@testable import Mather

struct GameplayThreadContentTests {
    @Test
    func fruitsThreadHasCuratedEntityAndPropertyCoverage() {
        let thread = GameplayThreadCatalog.fruits

        #expect(thread.id == "fruits")
        #expect(thread.category.id == "chemistry")
        #expect(thread.entities.count == 8)
        #expect(Set(thread.propertyTypes.map(\.id)) == Set(["name", "color", "taste", "seed-skin", "grows-on", "category"]))
        #expect(thread.entities.allSatisfy { $0.id.hasPrefix("fruit-") })
        #expect(thread.entities.allSatisfy { $0.visualKey?.isEmpty == false })
        #expect(thread.entities.allSatisfy { $0.visualAssetName == nil })

        for fruit in thread.entities {
            let propertyTypes = Set(fruit.properties.map(\.typeID))
            #expect(propertyTypes == Set(["name", "color", "taste", "seed-skin", "grows-on", "category"]), "\(fruit.id) should expose every fruit property type")
            #expect(fruit.properties.allSatisfy { !$0.value.isEmpty && !$0.explanation.isEmpty }, "\(fruit.id) properties should be kid-readable")
        }
    }

    @Test
    func fruitStagesUseReusableIssue912StageKindsAndFilters() {
        let thread = GameplayThreadCatalog.fruits

        #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
        #expect(thread.stages.allSatisfy { $0.maximumItemCount >= 6 })
        #expect(thread.stages[0].propertyTypeIDs.isEmpty)
        #expect(thread.stages[1].propertyTypeIDs == ["name", "color"])
        #expect(thread.stages[2].propertyTypeIDs == ["color", "taste"])
        #expect(thread.stages[3].propertyTypeIDs.contains("seed-skin"))
        #expect(thread.stages[4].propertyTypeIDs.contains("grows-on"))
    }

    @Test
    func fruitsThreadGeneratesRoundsForEachStage() {
        let thread = GameplayThreadCatalog.fruits

        for stage in thread.stages {
            let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 912)
            #expect(round.stageID == stage.id)
            #expect(round.kind == stage.kind)
            #expect(!round.items.isEmpty, "\(stage.id) should generate playable items")
            #expect(round.items.count <= stage.maximumItemCount)

            if !stage.propertyTypeIDs.isEmpty {
                let allowed = Set(stage.propertyTypeIDs)
                #expect(round.items.allSatisfy { item in
                    guard let propertyTypeID = item.propertyTypeID else { return false }
                    return allowed.contains(propertyTypeID)
                }, "\(stage.id) should only select allowed fruit properties")
            }
        }
    }

    @Test
    func fruitMultipleChoiceQuestionsHaveSamePropertyDistractors() throws {
        let thread = GameplayThreadCatalog.fruits
        let stage = try #require(thread.stages.first { $0.kind == .multipleChoice })
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 45)
        let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round)

        #expect(questions.count == round.items.count)
        for question in questions {
            #expect(question.choices.count >= 2)
            #expect(question.choices.contains(question.answer))
            #expect(question.choices.allSatisfy { !$0.title.isEmpty })
        }
    }

    @Test
    func shapeThreadAddsRicherCardsAndNameCardsUseNeutralVisuals() throws {
        let thread = GameplayThreadCatalog.shapes

        #expect(thread.entities.count >= 12)
        #expect(Set(thread.entities.map(\.name)).isSuperset(of: ["Pentagon", "Hexagon", "Crescent", "Trapezoid"]))

        let nameStage = try #require(thread.stages.first { $0.id == "shapes-easy-memory" })
        let nameItems = thread.entities.prefix(4).compactMap { entity -> GameplayRoundItem? in
            guard let property = entity.properties.first(where: { $0.typeID == "name" }) else { return nil }
            return GameplayRoundItem(id: "\(entity.id)::\(property.id)", entityID: entity.id, propertyID: property.id, propertyTypeID: property.typeID)
        }
        let round = GameplayRoundDefinition(id: "shape-names-test", stageID: nameStage.id, kind: nameStage.kind, items: nameItems, seed: 1006)
        let namePairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)

        #expect(namePairs.count == 4)
        #expect(namePairs.allSatisfy { $0.right.subtitle == "Name" })
        #expect(namePairs.allSatisfy { $0.right.visualKey != $0.left.visualKey })
        #expect(nameStage.maximumItemCount >= 8)
    }

}
