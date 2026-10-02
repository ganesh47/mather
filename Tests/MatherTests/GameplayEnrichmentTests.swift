import Foundation
import Testing
@testable import Mather

@Suite("Gameplay enrichment")
struct GameplayEnrichmentTests {
    @MainActor @Test func identicalVisibleMemoryAnswersRemainInterchangeable() {
        let first = MemoryAnimal(id: "a", name: "10", canonicalName: "2 + 8", picture: .text("2 + 8"), metadata: MemoryDeck.numberBondsTo10[0].metadata)
        let second = MemoryAnimal(id: "b", name: "10", canonicalName: "3 + 7", picture: .text("3 + 7"), metadata: MemoryDeck.numberBondsTo10[1].metadata)
        let prompt = MemoryCard(pairId: first.id, content: .picture(first))
        let equivalent = MemoryCard(pairId: second.id, content: .label(second))
        #expect(MemoryView.cardsFormValidMatch(prompt, equivalent))
        #expect(MemoryView.cardsFormValidMatch(equivalent, prompt))
        #expect(!MemoryView.cardsFormValidMatch(prompt, MemoryCard(pairId: second.id, content: .picture(second))))
    }

    @MainActor @Test func numberBondPromptsAskForUniqueMissingPartsWithoutSpeakingTheAnswer() {
        #expect(Set(MemoryDeck.numberBondsTo10.map(\.name)).count == 10)
        for (index, animal) in MemoryDeck.numberBondsTo10.enumerated() {
            let part = index + 1
            #expect(animal.picture == .text("\(part) + ? = 10"))
            #expect(Int(animal.name) == 10 - part)
            #expect(MemoryView.spokenTapPrompt(for: MemoryCard(pairId: animal.id, content: .picture(animal))) == "\(part) + ? = 10")
        }
    }

    @Test func protractorRequiresFiveDifferentLevels() {
        var progress = ProtractorCompletionProgress()
        let first = progress.complete(levelIndex: 2, levelCount: 5)
        #expect(first)
        for _ in 0..<10 { let repeated = progress.complete(levelIndex: 2, levelCount: 5); #expect(!repeated) }
        let wrappedRepeat = progress.complete(levelIndex: 7, levelCount: 5)
        #expect(!wrappedRepeat)
        #expect(progress.count == 1)
        for level in [0, 1, 3, 4] { let unique = progress.complete(levelIndex: level, levelCount: 5); #expect(unique) }
        #expect(progress.count == 5)
    }

    @Test func cannonCollisionFollowsTheVisibleArc() throws {
        let launches = AngleArcadeCampaign.levels.filter { $0.kind == .launch }
        #expect(launches.count == 6)
        for level in launches {
            let target = try #require(level.target)
            let shot = try #require(level.shot(angle: level.authoredSolution.angle, power: level.authoredSolution.power))
            let endpoint = try #require(shot.path.last)
            let contactRadius = target.radius + level.projectileRadius
            // The rendered projectile ends at physical contact with the target circle.
            let distance = hypot(Double(endpoint.x) - target.distance, Double(endpoint.y) - target.height)
            #expect(shot.hit, "\(level.id) authored hit")
            #expect(abs(distance - contactRadius) < 0.00001, "\(level.id) visible contact")

            if !level.guided {
                let miss = try #require(level.shot(angle: level.startingAngle, power: level.startingPower))
                #expect(!miss.hit, "\(level.id) starting miss")
                #expect(miss.path.allSatisfy {
                    hypot(Double($0.x) - target.distance, Double($0.y) - target.height) > contactRadius
                }, "\(level.id) missed path stays outside the target")
            }
        }
    }

    @Test func pitchComparisonsChangeFrequencyAtTheSameAmplitude() {
        let bands = SoundPitchBand.allCases
        let profiles = bands.map { $0.soundExample.profile }
        #expect(Set(profiles.map(\.peakAmplitude)).count == 1)
        #expect(Set(profiles.map(\.durationSeconds)).count == 1)
        #expect(profiles[0].primaryFrequency < profiles[1].primaryFrequency)
        #expect(profiles[1].primaryFrequency < profiles[2].primaryFrequency)
        #expect(profiles.allSatisfy { $0.secondaryFrequency == nil })
    }
    @Test func editorialCluesAvoidKnownMisconceptionsAndUnverifiedBirdMetrics() throws {
        let birds = GameplayThreadCatalog.worldBirds
        let blast = try #require(birds.stages.first { $0.kind == .bondBlast })
        #expect(Set(blast.propertyTypeIDs) == ["name", "home", "colors"])
        let shapes = GameplayThreadCatalog.shapes
        let circle = try #require(shapes.entities.first { $0.id == "shape-circle" })
        #expect(circle.summary.contains("straight sides"))
        let rhombus = try #require(shapes.entities.first { $0.id == "shape-diamond" })
        #expect(rhombus.name == "Rhombus")
        #expect(rhombus.properties.contains { $0.explanation.contains("Turning a square keeps it a square") })
        let trapezoid = try #require(shapes.entities.first { $0.id == "shape-trapezoid" })
        #expect(trapezoid.visualKey != "▰")
        let evaporation = try #require(GameplayThreadCatalog.waterCycle.entities.first { $0.id == "water-cycle-evaporation" })
        #expect(evaporation.summary.contains("invisible"))
        #expect(evaporation.properties.contains { $0.value.contains("arrows represent invisible water vapor") })
    }

}
