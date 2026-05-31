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
    func electronicsThreadCoversElementaryCircuitAndSafetyBasics() {
        let thread = GameplayThreadCatalog.electronics

        #expect(thread.id == "electronics")
        #expect(thread.category.id == "electronics")
        #expect(thread.title == "Circuit Spark")
        #expect(thread.entities.count == 8)
        #expect(Set(thread.propertyTypes.map(\.id)) == Set(["part", "job", "rule"]))
        #expect(Set(thread.entities.map(\.name)).isSuperset(of: [
            "Battery",
            "Bulb",
            "Wire",
            "Switch",
            "Closed Circuit",
            "Open Circuit",
            "Safe Game Circuit",
            "Outlet Safety",
        ]))

        let expectedAssetNames: Set<String> = [
            "ElectronicsBattery",
            "ElectronicsBulb",
            "ElectronicsWire",
            "ElectronicsSwitch",
            "ElectronicsClosedCircuit",
            "ElectronicsOpenCircuit",
            "ElectronicsSafeCircuit",
            "ElectronicsOutletSafety",
        ]
        #expect(Set(thread.entities.compactMap(\.visualAssetName)) == expectedAssetNames)
        #expect(thread.entities.allSatisfy { $0.visualKey == nil })
        #expect(thread.entities.allSatisfy { entity in
            entity.properties.allSatisfy { property in
                property.visualAssetName.map(expectedAssetNames.contains) == true && property.visualKey == nil
            }
        })

        let propertyValues = thread.entities.flatMap { $0.properties.map(\.value) }
        for requiredValue in [
            "Game batteries are pretend",
            "Bulb or light",
            "Wire",
            "Closed switch can turn on",
            "Light on in closed circuit",
            "Bulb on",
            "Bulb off",
            "Screen play is safe",
            "Do not touch outlets",
        ] {
            #expect(propertyValues.contains(requiredValue), "Circuit Spark should teach \(requiredValue)")
        }

        let propertyCopy = thread.entities.flatMap { entity in
            entity.properties.flatMap { [$0.value, $0.explanation] }
        }
        let contentParts = [thread.category.subtitle]
            + thread.stages.map(\.prompt)
            + thread.entities.map(\.summary)
            + propertyCopy
        let allCopy = contentParts.joined(separator: " ")
        #expect(allCopy.contains("Ask a grown-up"))
        #expect(allCopy.contains("plug point") && allCopy.contains("outlet"))
        #expect(allCopy.contains("pretend") && allCopy.contains("safe"))
        #expect(!allCopy.localizedCaseInsensitiveContains("magnet"))
        #expect(!allCopy.localizedCaseInsensitiveContains("sensor"))
        #expect(!allCopy.localizedCaseInsensitiveContains("logic"))
        #expect(!allCopy.localizedCaseInsensitiveContains("conductor"))
        #expect(!allCopy.localizedCaseInsensitiveContains("insulator"))
        #expect(!allCopy.localizedCaseInsensitiveContains("shock"))
        #expect(!allCopy.localizedCaseInsensitiveContains("danger"))

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
        #expect(thread.stages[1].propertyTypeIDs == ["part"])
        #expect(thread.stages[1].prompt.localizedCaseInsensitiveContains("symbol"))
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
    func electronicsEasyMemoryPairsSymbolOnlyCardsWithPartNames() throws {
        let thread = GameplayThreadCatalog.electronics
        let stage = try #require(thread.stages.first { $0.kind == .easyMemory })
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 1062)
        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)

        #expect(round.items.allSatisfy { $0.propertyTypeID == "part" })
        #expect(pairs.allSatisfy { $0.left.title == "Name this symbol" })
        #expect(pairs.allSatisfy { $0.left.presentation == .visualOnly })
        #expect(pairs.allSatisfy { $0.left.visualKey != nil || $0.left.visualAssetName != nil })
        #expect(pairs.allSatisfy { $0.right.subtitle == "Part name" })
        #expect(pairs.allSatisfy { $0.right.presentation == .titleOnly })
        #expect(pairs.allSatisfy { $0.right.visualKey == nil && $0.right.visualAssetName == nil })
        #expect(Set(pairs.map { $0.right.title.lowercased() }).count == pairs.count)
    }

    @Test
    func electronicsCardsResolveToDeterministicVectorArtworkKeys() {
        let thread = GameplayThreadCatalog.electronics
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: thread.stages[0], seed: 1071)
        let cards = GameplayStageContentBuilder.flashcards(thread: thread, round: round)
        let mappedKeys = Set(cards.compactMap(\.electronicsArtworkKey))

        #expect(mappedKeys == Set(ElectronicsArtworkKey.allCases))
        #expect(GameplayThreadCatalog.fruits.entities.allSatisfy { ElectronicsArtworkKey(entityID: $0.id) == nil })
        #expect(LabActivityID.circuitSpark.electronicsArtworkKey == .closedCircuit)
        #expect(LabActivityID.fruitCards.electronicsArtworkKey == nil)
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
        #expect(namePairs.allSatisfy { $0.left.presentation == .visualOnly })
        #expect(namePairs.allSatisfy { $0.right.subtitle == "Shape name" })
        #expect(namePairs.allSatisfy { $0.right.presentation == .titleOnly })
        #expect(namePairs.allSatisfy { $0.right.visualKey == nil && $0.right.visualAssetName == nil })
        #expect(nameStage.maximumItemCount >= 8)

        let bondStage = try #require(thread.stages.first { $0.id == "shapes-bond-blast" })
        let bondRound = GameplayRoundDefinition(id: "shape-bond-names-test", stageID: bondStage.id, kind: bondStage.kind, items: nameItems, seed: 1069)
        let bondPairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: bondRound)

        #expect(bondPairs.allSatisfy { $0.left.title == "Name this shape" })
        #expect(bondPairs.allSatisfy { $0.left.presentation == .visualOnly })
        #expect(bondPairs.allSatisfy { $0.right.presentation == .titleOnly })
    }

}

struct WorldCreatureGameplayThreadTests {
    @Test
    func worldCreatureThreadsResolveFromCatalogAndUseMemoryDeckSource() {
        let animalThread = GameplayThreadCatalog.thread(for: .worldAnimals)
        let birdThread = GameplayThreadCatalog.thread(for: .worldBirds)

        #expect(animalThread.id == "world-animals")
        #expect(birdThread.id == "world-birds")
        #expect(animalThread.category.id == "geography-world")
        #expect(birdThread.category.id == "geography-world")
        #expect(animalThread.entities.map(\.name) == MemoryDeck.domesticAnimals.prefix(12).map(\.name))
        #expect(birdThread.entities.map(\.name) == MemoryDeck.birds.prefix(12).map(\.name))
        #expect(birdThread.entities.allSatisfy { $0.visualAssetName?.isEmpty == false })
        #expect(animalThread.entities.allSatisfy { $0.visualKey?.isEmpty == false })
    }

    @Test
    func worldCreatureThreadsHaveNonEmptyEntitiesAndResolvableStageProperties() {
        for threadID in [GameplayThreadID.worldAnimals, .worldBirds] {
            let thread = GameplayThreadCatalog.thread(for: threadID)
            let propertyTypeIDs = Set(thread.propertyTypes.map(\.id))

            #expect(!thread.entities.isEmpty)
            if threadID == .worldAnimals {
                #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .multipleChoice, .bondBlast])
            } else {
                #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .bondBlast])
            }
            #expect(thread.entities.allSatisfy { !$0.properties.isEmpty })
            #expect(thread.entities.allSatisfy { entity in
                Set(entity.properties.map(\.typeID)).isSubset(of: propertyTypeIDs)
            })
            #expect(thread.stages.allSatisfy { stage in
                Set(stage.propertyTypeIDs).isSubset(of: propertyTypeIDs)
            })

            for stage in thread.stages {
                let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 1044)
                #expect(!round.items.isEmpty, "\(stage.id) should generate playable items")
                #expect(round.items.count <= stage.maximumItemCount)
            }
        }
    }

    @Test
    func worldCreatureEasyMemoryAvoidsIdenticalNamePromptAndAnswerDuplicates() throws {
        for threadID in [GameplayThreadID.worldAnimals, .worldBirds] {
            let thread = GameplayThreadCatalog.thread(for: threadID)
            let stage = try #require(thread.stages.first { $0.kind == .easyMemory })
            let nameItems = thread.entities.prefix(4).compactMap { entity -> GameplayRoundItem? in
                guard let property = entity.properties.first(where: { $0.typeID == "name" }) else { return nil }
                return GameplayRoundItem(id: "\(entity.id)::\(property.id)", entityID: entity.id, propertyID: property.id, propertyTypeID: property.typeID)
            }
            let round = GameplayRoundDefinition(id: "\(thread.id)-names-test", stageID: stage.id, kind: stage.kind, items: nameItems, seed: 1044)
            let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)

            #expect(pairs.count == nameItems.count)
            #expect(pairs.allSatisfy { $0.left.title != $0.right.title })
            #expect(pairs.allSatisfy { $0.right.subtitle == (threadID == .worldAnimals ? "Animal name" : "Bird name") })
            #expect(pairs.allSatisfy { $0.left.presentation == .visualOnly })
            #expect(pairs.allSatisfy { $0.right.presentation == .titleOnly })
            #expect(pairs.allSatisfy { $0.right.visualKey == nil && $0.right.visualAssetName == nil })
        }
    }
    @Test
    func worldAnimalsEasyMemoryStartsWithPictureNameRound() throws {
        let thread = GameplayThreadCatalog.worldAnimals
        let stage = try #require(thread.stages.first { $0.id == "world-animals-name-match" })
        #expect(stage.title == "Name Match")
        #expect(stage.propertyTypeIDs == ["name"])
        #expect(stage.prompt.localizedCaseInsensitiveContains("picture"))
        #expect(stage.prompt.localizedCaseInsensitiveContains("name"))

        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 1053)
        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)

        #expect(round.items.allSatisfy { $0.propertyTypeID == "name" })
        #expect(pairs.allSatisfy { $0.left.title == "Name this animal" })
        #expect(pairs.allSatisfy { $0.left.presentation == .visualOnly })
        #expect(pairs.allSatisfy { $0.right.presentation == .titleOnly })
        #expect(Set(pairs.map { $0.right.title.lowercased() }).count == pairs.count)
    }

    @Test
    func worldAnimalsProgressesThroughNameHabitatDietAndMixedStages() throws {
        let thread = GameplayThreadCatalog.worldAnimals
        let propertyTypeIDs = Set(thread.propertyTypes.map(\.id))

        #expect(propertyTypeIDs.isSuperset(of: ["name", "habitat", "diet"]))
        #expect(thread.stages.map(\.id) == [
            "world-animals-flashcards",
            "world-animals-name-match",
            "world-animals-habitat-match",
            "world-animals-diet-quiz",
            "world-animals-bond-blast"
        ])
        #expect(thread.stages.map(\.title) == [
            "Animal Cards",
            "Name Match",
            "Habitat Match",
            "Food Quiz",
            "Animal Blast"
        ])

        let habitatStage = try #require(thread.stages.first { $0.id == "world-animals-habitat-match" })
        let dietStage = try #require(thread.stages.first { $0.id == "world-animals-diet-quiz" })
        let mixedStage = try #require(thread.stages.first { $0.id == "world-animals-bond-blast" })

        #expect(habitatStage.kind == .flipMemory)
        #expect(habitatStage.propertyTypeIDs == ["habitat"])
        #expect(dietStage.kind == .multipleChoice)
        #expect(dietStage.propertyTypeIDs == ["diet"])
        #expect(mixedStage.propertyTypeIDs == ["name", "habitat", "diet", "movement", "sound", "colors", "kind"])

        let dietValues = Set(thread.entities.compactMap { entity in
            entity.properties.first { $0.typeID == "diet" }?.value
        })

        #expect(dietValues == Set([
            "Herbivore: mostly eats plants",
            "Carnivore: mostly eats meat",
            "Omnivore: eats plants and animals"
        ]))
        #expect(thread.entities.allSatisfy { entity in
            Set(["name", "habitat", "diet"]).isSubset(of: Set(entity.properties.map(\.typeID)))
        })
    }

    @Test
    func worldBirdsEasyMemoryStartsWithDeterministicPictureNameRoundWithoutDuplicateVisibleAnswers() throws {
        let thread = GameplayThreadCatalog.worldBirds
        let stage = try #require(thread.stages.first { $0.kind == .easyMemory })
        #expect(stage.propertyTypeIDs == ["name"])
        #expect(stage.prompt.localizedCaseInsensitiveContains("picture"))
        #expect(stage.prompt.localizedCaseInsensitiveContains("name"))

        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 1049)
        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)

        #expect(round.items.count == min(stage.maximumItemCount, thread.entities.count))
        #expect(round.items.allSatisfy { $0.propertyTypeID == "name" })
        #expect(pairs.allSatisfy { $0.left.title == "Name this bird" })
        #expect(pairs.allSatisfy { $0.left.visualAssetName?.isEmpty == false })
        #expect(pairs.allSatisfy { $0.right.subtitle == "Bird name" })
        #expect(pairs.allSatisfy { $0.left.presentation == .visualOnly })
        #expect(pairs.allSatisfy { $0.right.presentation == .titleOnly })
        #expect(pairs.allSatisfy { $0.right.visualKey == nil && $0.right.visualAssetName == nil })
        #expect(Set(pairs.map { $0.right.title.lowercased() }).count == pairs.count)
    }


    @Test
    func worldCreatureBondBlastHasEnoughFactProperties() throws {
        let animalThread = GameplayThreadCatalog.worldAnimals
        let birdThread = GameplayThreadCatalog.worldBirds

        let animalStage = try #require(animalThread.stages.first { $0.kind == .bondBlast })
        let birdStage = try #require(birdThread.stages.first { $0.kind == .bondBlast })

        #expect(animalStage.propertyTypeIDs.count >= 5)
        #expect(birdStage.propertyTypeIDs.count >= 5)
        #expect(animalThread.entities.allSatisfy { entity in
            Set(animalStage.propertyTypeIDs).isSubset(of: Set(entity.properties.map(\.typeID)))
        })
        #expect(birdThread.entities.allSatisfy { entity in
            Set(birdStage.propertyTypeIDs).isSubset(of: Set(entity.properties.map(\.typeID)))
        })
    }
}
