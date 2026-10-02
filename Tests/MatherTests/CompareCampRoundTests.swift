import Foundation
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import Mather

@Suite("Compare Camp content and generated challenges")
struct CompareCampRoundTests {
    @Test func twentyFourCampsHaveDistinctIDsAndSixCompleteRegions() {
        #expect(CompareCampCategory.all.count == 24)
        #expect(Set(CompareCampCategory.all.map(\.id)).count == 24)
        #expect(CompareCampRegion.allCases.count == 6)
        for region in CompareCampRegion.allCases {
            #expect(region.categories.count == 4)
            #expect(region.categories.allSatisfy { $0.region == region })
        }
        for camp in CompareCampCategory.all {
            #expect(camp.tokenAssetName != nil)
            #expect(camp.tokenEmoji == nil)
            #expect(!camp.tokenName.isEmpty && !camp.tokenPlural.isEmpty)
            #expect(!camp.artAssetName.isEmpty)
            #expect(camp.accentHex.count == 6)
        }
    }

    #if canImport(UIKit)
    @MainActor
    @Test func everyCampArtworkReferenceLoadsFromTheAppAssetCatalog() {
        for category in CompareCampCategory.all {
            #expect(UIImage(named: category.artAssetName) != nil)
            if let asset = category.tokenAssetName { #expect(UIImage(named: asset) != nil) }
        }
    }
    #endif

    @Test func everyGeneratedTaskHasBoundedCountsAndDerivedTruth() {
        for category in CompareCampCategory.all {
            for activity in CompareCampActivity.allCases {
                for difficulty in CompareCampDifficulty.allCases {
                    for seed: UInt64 in [0, 17, .max] {
                        var previous: CompareCampRound?
                        for index in 0..<8 {
                            let round = CompareCampRound.make(category: category, activity: activity,
                                                              difficulty: difficulty, index: index,
                                                              seed: seed, previous: previous)
                            #expect((0...difficulty.maxCount).contains(round.leftCount))
                            #expect((0...difficulty.maxCount).contains(round.rightCount))
                            #expect(round.maxCount == difficulty.maxCount)
                            #expect(round.relation == .comparing(round.leftCount, round.rightCount))
                            #expect(round.difference == abs(round.leftCount - round.rightCount))
                            #expect(!round.usesTimer)
                            #expect(Set(round.choices.map(\.id)).count == round.choices.count)
                            if round.activity == .makeEqual {
                                #expect(round.leftCount != round.rightCount)
                                #expect(round.choices.isEmpty)
                            } else {
                                #expect(round.choices.count == 3)
                                #expect(round.choices.filter { $0.id == round.correctAnswerID }.count == 1)
                            }
                            if let previous {
                                #expect(previous.leftCount != round.leftCount || previous.rightCount != round.rightCount)
                            }
                            if round.stage == .transfer { #expect(round.category.region != category.region) }
                            previous = round
                        }
                    }
                }
            }
        }
    }

    @Test func adventuresFollowTwoStopsPerCPAStageAndUseNewSubjectsForTransfer() {
        let rounds = (0..<8).map {
            CompareCampRound.make(category: .first, activity: .adventure, difficulty: .small, index: $0)
        }
        #expect(rounds.map(\.stage) == [.concrete, .concrete, .pictorial, .pictorial, .abstract, .abstract, .transfer, .transfer])
        #expect(rounds.map(\.activity) == [.makeEqual, .makeEqual, .more, .fewer, .symbols, .symbols, .more, .difference])
        #expect(rounds.prefix(6).allSatisfy { $0.category == .first })
        #expect(rounds.suffix(2).allSatisfy { $0.category.region != CompareCampCategory.first.region })
    }

    @Test func focusedNumberSignPracticeBeginsWithConcreteQuantities() {
        let rounds = (0..<8).map {
            CompareCampRound.make(category: .first, activity: .symbols, difficulty: .growing, index: $0)
        }
        #expect(rounds.prefix(2).allSatisfy { $0.activity == .makeEqual })
        #expect(rounds[2].activity == .more)
        #expect(rounds[3].activity == .fewer)
        #expect(rounds.suffix(4).allSatisfy { $0.activity == .symbols })
    }

    @Test func comparisonSessionsBalanceAllRelationsAndIncludeZero() {
        var allCounts: Set<Int> = []
        for seed: UInt64 in 0..<64 {
            let rounds = (0..<8).map {
                CompareCampRound.make(category: .first, activity: .more, difficulty: .small, index: $0, seed: seed)
            }
            for relation in CompareCampRelation.allCases {
                #expect((2...3).contains(rounds.filter { $0.relation == relation }.count))
            }
            allCounts.formUnion(rounds.flatMap { [$0.leftCount, $0.rightCount] })
        }
        #expect(allCounts == Set(0...5))
    }

    @Test func moreFewerSignsAndExtrasGiveMathematicallyCorrectAnswers() {
        for seed: UInt64 in 0..<8 {
            for activity in [CompareCampActivity.more, .fewer, .symbols, .difference] {
                for index in 0..<8 {
                    let round = CompareCampRound.make(category: .first, activity: activity,
                                                      difficulty: .big, index: index, seed: seed)
                    switch round.activity {
                    case .more:
                        #expect(round.correctAnswerID == (round.leftCount == round.rightCount ? "same" : round.leftCount > round.rightCount ? "left" : "right"))
                    case .fewer:
                        #expect(round.correctAnswerID == (round.leftCount == round.rightCount ? "same" : round.leftCount < round.rightCount ? "left" : "right"))
                    case .symbols:
                        #expect(round.correctAnswerID == round.relation.rawValue)
                    case .difference:
                        #expect(round.correctAnswerID == "number-\(round.difference)")
                        #expect(round.choices.allSatisfy { (0...20).contains($0.value ?? -1) })
                    default: break
                    }
                }
            }
        }
    }

    @Test func seededGenerationIsRepeatableAndExtremeInputsDoNotOverflow() {
        let first = CompareCampRound.make(category: .first, activity: .adventure, difficulty: .big, index: 7, seed: .max)
        #expect(first == CompareCampRound.make(category: .first, activity: .adventure, difficulty: .big, index: 7, seed: .max))
        for index in [Int.min, -9, -1, 0, 8, Int.max] {
            let round = CompareCampRound.make(category: .first, activity: .more, difficulty: .small, index: index, seed: .max)
            #expect((0..<8).contains(round.index))
            #expect((0...5).contains(round.leftCount))
        }
        let sequenceA = (0..<8).map { CompareCampRound.make(category: .first, activity: .more, difficulty: .growing, index: $0, seed: 0) }
        let sequenceB = (0..<8).map { CompareCampRound.make(category: .first, activity: .more, difficulty: .growing, index: $0, seed: 1) }
        #expect(sequenceA != sequenceB)
    }

    @Test func differentCampsOfferDifferentQuantityJourneysAtTheSameSeed() {
        let signatures = CompareCampCategory.all.map { category in
            (0..<8).map {
                let round = CompareCampRound.make(category: category, activity: .adventure,
                                                  difficulty: .small, index: $0)
                return "\(round.leftCount):\(round.rightCount)"
            }.joined(separator: ",")
        }
        #expect(Set(signatures).count == CompareCampCategory.all.count)
    }
}
