import Testing
@testable import Mather

struct NumberStoryGeneratorTests {
    @Test
    func generatedPromptsCarryExactProblemNumbers() {
        let cases = [
            SliceProblem(target: 6, decompositionA: 2, decompositionB: 4),
            SliceProblem(target: 10, decompositionA: 7, decompositionB: 3),
            SliceProblem(target: 14, decompositionA: 8, decompositionB: 6),
            SliceProblem(target: 20, decompositionA: 12, decompositionB: 8),
            SliceProblem(target: 37, decompositionA: 20, decompositionB: 17),
            SliceProblem(target: 100, decompositionA: 60, decompositionB: 40),
            SliceProblem(target: 250, decompositionA: 100, decompositionB: 150),
            SliceProblem(target: 1_000, decompositionA: 400, decompositionB: 600),
        ]

        for problem in cases {
            let prompt = NumberStoryGenerator.prompt(for: problem, themeId: "space")

            #expect(prompt.target == problem.target)
            #expect(prompt.leftPart == problem.decompositionA)
            #expect(prompt.rightPart == problem.decompositionB)
            #expect(prompt.spokenIntro.contains("\(problem.target)"))
            #expect(prompt.spokenIntro.contains("\(problem.decompositionA)"))
            #expect(prompt.spokenIntro.contains("\(problem.decompositionB)"))
            #expect(prompt.reminder.contains("\(problem.target)"))
            #expect(prompt.successLine.contains("\(problem.target)"))
            #expect(prompt.successLine.contains("\(problem.decompositionA)"))
            #expect(prompt.successLine.contains("\(problem.decompositionB)"))
        }
    }

    @Test
    func promptGenerationIsDeterministicForSameProblemAndTheme() {
        let problem = SliceProblem(target: 37, decompositionA: 20, decompositionB: 17)

        let first = NumberStoryGenerator.prompt(for: problem, themeId: "classic")
        let second = NumberStoryGenerator.prompt(for: problem, themeId: "classic")

        #expect(first == second)
    }

    @Test
    func classicAndVehicleThemesUseDifferentCuratedPacks() {
        let problem = SliceProblem(target: 20, decompositionA: 12, decompositionB: 8)

        let classic = NumberStoryGenerator.prompt(for: problem, themeId: "classic")
        let vehicle = NumberStoryGenerator.prompt(for: problem, themeId: "vehicle")

        #expect(classic.templateID != vehicle.templateID)
        #expect(vehicle.templateID == .vehicleGarage)
        #expect(vehicle.title == "Vehicle Garage")
        #expect(vehicle.objectNoun == "wheels")
        #expect(classic.target == vehicle.target)
        #expect(classic.leftPart == vehicle.leftPart)
        #expect(classic.rightPart == vehicle.rightPart)
    }

    @Test
    func curatedPacksCoverRequiredFamiliesAndBands() {
        let small = SliceProblem(target: 6, decompositionA: 2, decompositionB: 4)
        let hundred = SliceProblem(target: 100, decompositionA: 60, decompositionB: 40)
        let large = SliceProblem(target: 250, decompositionA: 100, decompositionB: 150)

        #expect(NumberStoryGenerator.prompt(for: small, themeId: "space").templateID == .spaceCargo)
        #expect(NumberStoryGenerator.prompt(for: small, themeId: "planets").templateID == .spaceCargo)
        #expect(NumberStoryGenerator.prompt(for: small, themeId: "vehicle").templateID == .vehicleGarage)
        #expect(NumberStoryGenerator.prompt(for: small, themeId: "garden").templateID == .gardenSeedShop)
        #expect(NumberStoryGenerator.prompt(for: hundred, themeId: "festival").templateID == .festivalPrep)
        #expect(NumberStoryGenerator.prompt(for: large, themeId: "garden").templateID == .spaceCargo)
    }

    @Test
    func promptTextAvoidsBannedPressureAndDangerLanguage() {
        let bannedTerms = [
            "timer",
            "hurry",
            "fast",
            "race",
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
            SliceProblem(target: 14, decompositionA: 8, decompositionB: 6),
            SliceProblem(target: 20, decompositionA: 12, decompositionB: 8),
            SliceProblem(target: 37, decompositionA: 20, decompositionB: 17),
            SliceProblem(target: 100, decompositionA: 60, decompositionB: 40),
            SliceProblem(target: 250, decompositionA: 100, decompositionB: 150),
            SliceProblem(target: 1_000, decompositionA: 400, decompositionB: 600),
        ]
        let themeIds = ["classic", "space", "planets", "vehicle", "garden", "festival"]

        for problem in problems {
            for themeId in themeIds {
                let prompt = NumberStoryGenerator.prompt(for: problem, themeId: themeId)
                let text = prompt.searchableText.lowercased()

                for term in bannedTerms {
                    #expect(!text.contains(term))
                }
            }
        }
    }

    @Test
    func representationHintsFollowNumberBands() {
        #expect(NumberStoryGenerator.prompt(for: SliceProblem(target: 6, decompositionA: 2, decompositionB: 4), themeId: "space").representationHint == .singles)
        #expect(NumberStoryGenerator.prompt(for: SliceProblem(target: 14, decompositionA: 8, decompositionB: 6), themeId: "space").representationHint == .tenFrames)
        #expect(NumberStoryGenerator.prompt(for: SliceProblem(target: 37, decompositionA: 20, decompositionB: 17), themeId: "space").representationHint == .tensAndOnes)
        #expect(NumberStoryGenerator.prompt(for: SliceProblem(target: 250, decompositionA: 100, decompositionB: 150), themeId: "space").representationHint == .hundredsTensOnes)
        #expect(NumberStoryGenerator.prompt(for: SliceProblem(target: 1_000, decompositionA: 400, decompositionB: 600), themeId: "space").representationHint == .thousandBlock)
    }
}

private extension NumberStoryPrompt {
    var searchableText: String {
        [
            title,
            spokenIntro,
            reminder,
            successLine,
            objectNoun,
            leftContainer,
            rightContainer,
        ].joined(separator: " ")
    }
}
