import Testing
@testable import Mather

struct NumberStoryStageVocabularyTests {
    @Test
    func gravitySplitVocabularyUsesExactStoryTargetAndParts() {
        let problem = SliceProblem(target: 14, decompositionA: 8, decompositionB: 6)
        let prompt = NumberStoryGenerator.prompt(for: problem, themeId: "space")

        let vocabulary = NumberStoryStageVocabulary.vocabulary(for: prompt, stage: .gravitySplit)
        let searchableText = vocabulary.searchableText

        #expect(searchableText.contains("14"))
        #expect(searchableText.contains("8"))
        #expect(searchableText.contains("6"))
        #expect(searchableText.contains(prompt.objectNoun))
        #expect(searchableText.contains(prompt.leftContainer))
        #expect(searchableText.contains(prompt.rightContainer))
        #expect(prompt.target == problem.target)
        #expect(prompt.leftPart == problem.decompositionA)
        #expect(prompt.rightPart == problem.decompositionB)
    }

    @Test
    func recallVocabularyUsesStoryTargetWithoutChangingMathTruth() {
        let problem = SliceProblem(target: 20, decompositionA: 12, decompositionB: 8)
        let prompt = NumberStoryGenerator.prompt(for: problem, themeId: "vehicle")

        let sumVocabulary = NumberStoryStageVocabulary.vocabulary(for: prompt, stage: .sumSprint)
        let bondVocabulary = NumberStoryStageVocabulary.vocabulary(for: prompt, stage: .bondBlast)
        let burst = SumSprintBurstState.make(for: problem)
        let bondPairs = BondMatchState.makePairs(for: problem.target)

        #expect(sumVocabulary.searchableText.contains("20"))
        #expect(sumVocabulary.searchableText.contains(prompt.objectNoun))
        #expect(bondVocabulary.searchableText.contains("20"))
        #expect(bondVocabulary.searchableText.contains(prompt.objectNoun))
        #expect(burst.target == problem.target)
        #expect(burst.cards.allSatisfy { card in
            switch card.content {
            case .prompt:
                return true
            case .sum(let value):
                return value == problem.target
            }
        })
        #expect(bondPairs.allSatisfy { $0.left + $0.right == problem.target })
    }

    @Test
    func storyStageVocabularyAvoidsPressureAndDangerLanguage() {
        let bannedTerms = [
            "timer",
            "hurry",
            "fast",
            "race",
            "sprint",
            "lose",
            "lost",
            "wrong",
            "shame",
            "scary",
            "danger",
            "rescue",
            "punish",
            "punishment",
            "emergency",
            "before it is too late",
        ]
        let problems = [
            SliceProblem(target: 6, decompositionA: 2, decompositionB: 4),
            SliceProblem(target: 10, decompositionA: 7, decompositionB: 3),
            SliceProblem(target: 37, decompositionA: 20, decompositionB: 17),
            SliceProblem(target: 100, decompositionA: 60, decompositionB: 40),
            SliceProblem(target: 1_000, decompositionA: 400, decompositionB: 600),
        ]
        let themeIds = ["classic", "space", "vehicle", "garden", "festival"]
        let stages: [NumberStoryStage] = [.gravitySplit, .sumSprint, .bondBlast]

        for problem in problems {
            for themeId in themeIds {
                let prompt = NumberStoryGenerator.prompt(for: problem, themeId: themeId)
                for stage in stages {
                    let text = NumberStoryStageVocabulary
                        .vocabulary(for: prompt, stage: stage)
                        .searchableText
                        .lowercased()

                    for term in bannedTerms {
                        #expect(!text.contains(term))
                    }
                }
            }
        }
    }
}

private extension NumberStoryStageVocabulary {
    var searchableText: String {
        [
            title,
            targetReminder,
            instruction,
            leftLabel,
            rightLabel,
            accessibilityLabel,
        ].joined(separator: " ")
    }
}
