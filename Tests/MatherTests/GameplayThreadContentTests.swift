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
        #expect(Set(thread.propertyTypes.map(\.id)) == Set(["name", "color", "taste", "seed-skin", "grows-on", "grow-climate", "origin", "flavor", "category"]))
        #expect(thread.entities.allSatisfy { $0.id.hasPrefix("fruit-") })
        #expect(thread.entities.allSatisfy { $0.visualKey?.isEmpty == false })
        #expect(thread.entities.allSatisfy { $0.visualAssetName == nil })

        for fruit in thread.entities {
            let propertyTypes = Set(fruit.properties.map(\.typeID))
            #expect(propertyTypes == Set(["name", "color", "taste", "seed-skin", "grows-on", "grow-climate", "origin", "flavor", "category"]), "\(fruit.id) should expose every fruit property type")
            #expect(fruit.properties.allSatisfy { !$0.value.isEmpty && !$0.explanation.isEmpty }, "\(fruit.id) properties should be kid-readable")
        }
    }

    @Test
    func fruitStagesUseReusableIssue912StageKindsAndFilters() {
        let thread = GameplayThreadCatalog.fruits

        #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
        #expect(thread.stages.allSatisfy { $0.maximumItemCount >= 6 })
        #expect(thread.stages[0].propertyTypeIDs.isEmpty)
        #expect(thread.stages[1].propertyTypeIDs == ["name", "taste", "grows-on", "grow-climate"])
        #expect(thread.stages[2].propertyTypeIDs == ["color", "taste", "flavor", "origin"])
        #expect(thread.stages[3].propertyTypeIDs.contains("grow-climate"))
        #expect(thread.stages[3].propertyTypeIDs.contains("origin"))
        #expect(thread.stages[4].propertyTypeIDs.contains("grows-on"))
        #expect(thread.stages[4].propertyTypeIDs.contains("flavor"))
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
    func electronicsThreadCoversCircuitAndMagnetBasicsWithoutColorOnlyAnswers() {
        let thread = GameplayThreadCatalog.electronics

        #expect(thread.id == "electronics")
        #expect(thread.category.id == "electronics")
        #expect(thread.title == "Circuit Spark")
        #expect(thread.entities.count == 8)
        #expect(Set(thread.propertyTypes.map(\.id)) == Set(["part", "job", "rule"]))
        #expect(Set(thread.entities.map(\.name)).isSuperset(of: [
            "Battery",
            "Bulb",
            "Closed Circuit",
            "Open Circuit",
            "Switch",
            "Conductor",
            "Insulator",
            "Magnet Poles",
        ]))

        let propertyValues = thread.entities.flatMap { $0.properties.map(\.value) }
        for requiredValue in [
            "Needs a loop",
            "Lights in a closed circuit",
            "Bulb on",
            "Bulb off",
            "Closed switch means on path",
            "Copper helps the bulb",
            "Not for the light path",
            "Opposites attract",
        ] {
            #expect(propertyValues.contains(requiredValue), "Circuit Spark should teach \(requiredValue)")
        }

        #expect(thread.entities.allSatisfy { entity in
            entity.properties.allSatisfy { property in
                !property.value.isEmpty && !property.explanation.isEmpty
            }
        })
    }

    @Test
    func electronicsStagesGeneratePlayableReusableRounds() {
        let thread = GameplayThreadCatalog.electronics

        #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
        #expect(thread.stages[1].propertyTypeIDs == ["part", "job"])
        #expect(thread.stages[2].propertyTypeIDs == ["job", "rule"])
        #expect(thread.stages[3].propertyTypeIDs == ["part", "job", "rule"])
        #expect(thread.stages[4].propertyTypeIDs == ["job", "rule"])

        for stage in thread.stages {
            let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 1024)
            #expect(round.stageID == stage.id)
            #expect(round.kind == stage.kind)
            #expect(!round.items.isEmpty, "\(stage.id) should generate playable items")
            #expect(round.items.count <= stage.maximumItemCount)
        }
    }

    @Test
    func fruitEasyMemoryIncludesGrowTasteAndClimateFacts() throws {
        let thread = GameplayThreadCatalog.fruits
        let stage = try #require(thread.stages.first { $0.id == "fruit-easy-memory" })
        let candidatePropertyTypeIDs = Set(SpacedRepetitionScheduler.candidateItems(thread: thread, stage: stage).compactMap(\.propertyTypeID))

        #expect(candidatePropertyTypeIDs == Set(["name", "taste", "grows-on", "grow-climate"]))
        #expect(candidatePropertyTypeIDs.isSuperset(of: Set(["taste", "grows-on", "grow-climate"])))
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
    func shapeThreadAddsRicherCardsAndNameMatchUsesRecallPrompts() throws {
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
        #expect(namePairs.allSatisfy { $0.left.title == "Name this shape" })
        #expect(namePairs.allSatisfy { $0.left.title != $0.right.title })
        #expect(namePairs.allSatisfy { $0.right.subtitle == "Shape name" })
        #expect(namePairs.allSatisfy { $0.right.visualKey != nil && $0.right.visualKey != "Aa" })
        #expect(nameStage.maximumItemCount >= 8)
    }

}
