import CoreGraphics
import Foundation
import Testing
@testable import Mather

struct GameplayStageViewModelsTests {
    @Test
    func navigationCompletesOneActiveStageAtATime() {
        let thread = GameplaySampleThreads.countries
        let start = Date(timeIntervalSince1970: 100)
        let finish = Date(timeIntervalSince1970: 125)
        var state = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)

        #expect(state.activeStage(in: thread)?.kind == .flashcards)
        #expect(state.progressFraction(for: thread) == 0.2)

        state.completeCurrentStage(thread: thread, correctCount: 4, mistakeCount: 1, hintsUsed: 0, now: finish)

        #expect(state.activeStage(in: thread)?.kind == .easyMemory)
        #expect(state.stageResults.count == 1)
        #expect(state.stageResults.first?.durationSeconds == 25)
        #expect(state.canGoBack)
    }

    @Test
    func retryCurrentStageRebuildsAttemptAndClearsCompletedResult() {
        let thread = GameplaySampleThreads.countries
        let start = Date(timeIntervalSince1970: 200)
        var state = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)

        state.completeCurrentStage(thread: thread, correctCount: 3, mistakeCount: 0, now: start.addingTimeInterval(10))
        #expect(state.activeStageIndex == 1)
        let attemptBeforeRetry = state.stageAttemptID

        state.retryCurrentStage(in: thread, now: start.addingTimeInterval(12))

        #expect(state.activeStageIndex == 1)
        #expect(state.stageResults.map(\.stageID) == [thread.stages[0].id])
        #expect(state.currentStageStartedAt == start.addingTimeInterval(12))
        #expect(state.stageAttemptID != attemptBeforeRetry)
    }

    @Test
    func retryAfterThreadCompleteReturnsToLastStage() {
        let thread = GameplayThreadDefinition(
            id: "short-thread",
            title: "Short Thread",
            category: GameplayCategory(id: "test", title: "Test", subtitle: ""),
            propertyTypes: [],
            entities: [],
            stages: [
                GameplayStageDefinition(id: "look", kind: .flashcards, title: "Look", prompt: "Look"),
                GameplayStageDefinition(id: "quiz", kind: .multipleChoice, title: "Quiz", prompt: "Quiz")
            ]
        )
        let start = Date(timeIntervalSince1970: 300)
        var state = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)
        state.completeCurrentStage(thread: thread, correctCount: 1, mistakeCount: 0, now: start.addingTimeInterval(5))
        state.completeCurrentStage(thread: thread, correctCount: 1, mistakeCount: 0, now: start.addingTimeInterval(10))
        #expect(state.isComplete(for: thread))

        state.retryCurrentStage(in: thread, now: start.addingTimeInterval(11))

        #expect(!state.isComplete(for: thread))
        #expect(state.activeStage(in: thread)?.id == "quiz")
        #expect(state.stageResults.map(\.stageID) == ["look"])
    }

    @Test
    func contentBuilderCreatesPropertyPairsForRoundItems() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .easyMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 912)

        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)

        #expect(!pairs.isEmpty)
        let allPairsMatchEntities = pairs.allSatisfy { pair in
            pair.left.entityID == pair.right.entityID
        }
        let allPairsUseCapitalSubtitle = pairs.allSatisfy { pair in
            pair.right.subtitle == "Capital"
        }
        #expect(allPairsMatchEntities)
        #expect(allPairsUseCapitalSubtitle)
    }


    @Test
    func flipMemoryHiddenRightCardRevealsWhenTappedFirst() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .flipMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 77)
        var viewModel = GameplayMatchStageViewModel(thread: thread, round: round, mode: .flipMemory, turnItemCount: 2)
        let firstRight = viewModel.shuffledRights[0]

        #expect(viewModel.shouldConcealRight(firstRight))
        let correct = viewModel.chooseRight(firstRight)

        #expect(!correct)
        #expect(!viewModel.shouldConcealRight(firstRight))
        #expect(viewModel.inspectedItemID == firstRight.id)
        #expect(viewModel.mismatchCount == 0)
    }

    @Test
    func matchTurnsAvoidDuplicateEntitiesWherePossible() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .bondBlast }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 18)
        let viewModel = GameplayMatchStageViewModel(thread: thread, round: round, mode: .bondBlast, turnItemCount: 3)

        #expect(viewModel.activePairs.count <= 3)
        #expect(Set(viewModel.activePairs.map { $0.left.entityID }).count == viewModel.activePairs.count)
    }

    @Test
    func multipleChoiceQuestionsIncludeAnswerAndDistractors() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .multipleChoice }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 5)

        let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round, choicesPerQuestion: 4)

        #expect(questions.count == min(stage.maximumItemCount, thread.entities.count))
        let allQuestionsContainAnswer = questions.allSatisfy { question in
            question.choices.contains(question.answer)
        }
        let allQuestionsHaveDistractors = questions.allSatisfy { question in
            question.choices.count >= 2
        }
        #expect(allQuestionsContainAnswer)
        #expect(allQuestionsHaveDistractors)
    }

    @Test
    func renderSupportKeepsCompactPhoneCardsLargeEnough() {
        #expect(GameplayStageRenderSupport.usesCompactStageLayout(width: 390, height: 720))
        #expect(GameplayStageRenderSupport.cardMinimumWidth(availableWidth: 390, compact: true) >= 132)
        #expect(GameplayStageRenderSupport.cardMinimumWidth(availableWidth: 820, compact: false) == 180)
    }

    @Test
    func matchErrorAndHelpSupportOnlyTheActualPromptItem() throws {
        let thread = GameplaySampleThreads.countries
        let stage = try #require(thread.stages.first { $0.kind == .easyMemory })
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 88)
        var model = GameplayMatchStageViewModel(thread: thread, round: round, mode: .easyMemory, turnItemCount: 2)
        let first = try #require(model.activePairs.first)
        let second = try #require(model.activePairs.last)
        #expect(first.id != second.id)
        model.selectLeft(pairID: first.id)
        let actualMutation1 = model.chooseRight(second.right)
        #expect(!actualMutation1)
        let actualMutation2 = model.chooseRight(first.right)
        #expect(actualMutation2)
        model.selectLeft(pairID: second.id)
        let actualMutation3 = model.chooseRight(second.right)
        #expect(actualMutation3)
        #expect(model.evidence.attempts.map(\.outcome) == [.incorrect, .supportedCorrect, .independentCorrect])
        #expect(model.evidence.attempts[0].entityID == first.left.entityID)
        #expect(model.evidence.attempts[2].entityID == second.left.entityID)

        var helped = GameplayMatchStageViewModel(thread: thread, round: round, mode: .easyMemory, turnItemCount: 2)
        helped.selectLeft(pairID: first.id)
        let helpText = helped.showHelp()
        #expect(helpText.contains(first.right.title))
        #expect(helped.helpedRightID == first.right.id)
        let actualMutation4 = helped.chooseRight(first.right)
        #expect(actualMutation4)
        helped.selectLeft(pairID: second.id)
        let actualMutation5 = helped.chooseRight(second.right)
        #expect(actualMutation5)
        #expect(helped.evidence.attempts.map(\.outcome) == [.help, .supportedCorrect, .independentCorrect])
    }

    @Test
    func flashcardsOnlyEmitExposureAndKeepNarrationConcise() throws {
        let thread = GameplayThreadCatalog.fruits
        let stage = try #require(thread.stages.first { $0.kind == .flashcards })
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 90)
        var model = GameplayFlashcardStageViewModel(thread: thread, round: round)
        model.markExposure()
        model.markActiveCardSpotted()
        #expect(model.evidence.attempts.allSatisfy { $0.outcome == .exposure })
        let card = try #require(model.activeCard)
        let entity = try #require(thread.entities.first { $0.id == card.entityID })
        #expect(card.subtitle.contains(entity.summary))
        #expect(card.subtitle.count < 400)
    }

    @Test
    func quizHelpAndErrorsAreSupportedAndRequireExplicitAdvance() throws {
        let thread = GameplaySampleThreads.countries
        let stage = try #require(thread.stages.first { $0.kind == .multipleChoice })
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 91)
        var model = GameplayMultipleChoiceStageViewModel(thread: thread, round: round)
        let question = try #require(model.activeQuestion)
        let wrong = try #require(question.choices.first { !question.isCorrect($0) })
        let actualMutation6 = model.choose(wrong)
        #expect(!actualMutation6)
        let helpText = model.showHelp()
        #expect(helpText.contains(question.answer.title))
        #expect(model.helpedChoiceID == question.answer.id)
        let actualMutation7 = model.choose(question.answer)
        #expect(actualMutation7)
        #expect(model.activeIndex == 0)
        #expect(model.evidence.attempts.map(\.outcome) == [.incorrect, .help, .supportedCorrect])
        #expect(model.evidence.attempts.allSatisfy { $0.entityID == question.answer.entityID && $0.propertyID != nil })
        let attemptsBeforeRepeatedTap = model.evidence.attempts.count
        let actualMutation8 = model.choose(question.answer)
        #expect(actualMutation8)
        #expect(model.evidence.attempts.count == attemptsBeforeRepeatedTap)
        let actualMutation9 = model.advanceAfterCorrectChoice()
        #expect(!actualMutation9)
        #expect(model.activeIndex == 1)
    }

    @Test
    func everyCatalogQuizUsesDistinctChoicesOfTheAssessedPropertyType() throws {
        for id in GameplayThreadID.allCases {
            let thread = GameplayThreadCatalog.thread(for: id)
            // Validate every property's quiz semantics, including topics whose current
            // child mission does not expose a quiz stage.
            for type in thread.propertyTypes {
                let stage = GameplayStageDefinition(id: "test-quiz-" + type.id, kind: .multipleChoice,
                    title: "Quiz", prompt: type.prompt, propertyTypeIDs: [type.id], maximumItemCount: 4)
                let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 93)
                let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round)
                let values = Set(thread.entities.flatMap { $0.properties.filter { $0.typeID == type.id }.map(\.value) })
                let semanticValues = Set(values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                if semanticValues.count < 2 {
                    #expect(questions.isEmpty)
                    continue
                }
                #expect(!questions.isEmpty)
                #expect(questions.count == round.items.count)
                for question in questions {
                    let item = try #require(round.items.first { question.id == "quiz-" + $0.id })
                    #expect(item.propertyTypeID == type.id)
                    #expect(question.choices.count >= 2)
                    #expect(Set(question.choices.map { $0.title.lowercased() }).count == question.choices.count)
                    #expect(question.choices.allSatisfy { values.contains($0.title) })
                    #expect(question.prompt.contains(type.prompt))
                }
            }
        }
    }

    @Test
    func matchCheckpointRestoresTheSameRoundSelectionHelpAndAttempts() throws {
        let thread = GameplaySampleThreads.countries
        let stage = try #require(thread.stages.first { $0.kind == .flipMemory })
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 94)
        var model = GameplayMatchStageViewModel(thread: thread, round: round, mode: .flipMemory, turnItemCount: 2)
        let pair = try #require(model.activePairs.first)
        model.selectLeft(pairID: pair.id)
        model.showHelp()
        let stateData = try JSONEncoder().encode(model)
        let checkpoint = GameplayThreadCheckpoint(navigation: GameplayStageNavigationState(activeStageIndex: 2), round: round,
            stageState: stateData, attempts: model.evidence.attempts, introductionIndex: 1, introductionFinished: true, sessionID: "resume-session", threadSnapshot: thread,
            contentVersion: 1, assetURLs: ["flag": URL(fileURLWithPath: "/verified-cache/v1/flag.png")])
        let reloaded = try JSONDecoder().decode(GameplayThreadCheckpoint.self, from: JSONEncoder().encode(checkpoint))
        #expect(reloaded.matches(thread: thread))
        #expect(reloaded == checkpoint)
        let changedEntities = thread.entities.map { entity in
            GameplayEntity(id: entity.id, name: entity.name, properties: entity.properties.map {
                GameplayProperty(id: $0.id, typeID: $0.typeID, value: "Updated answer")
            })
        }
        let changedThread = GameplayThreadDefinition(id: thread.id, title: thread.title, category: thread.category,
            propertyTypes: thread.propertyTypes, entities: changedEntities, stages: thread.stages)
        #expect(reloaded.matches(thread: changedThread))
        #expect(reloaded.threadSnapshot == thread)
        #expect(reloaded.threadSnapshot.entities[0].properties[0].value != changedThread.entities[0].properties[0].value)
        #expect(reloaded.assetURLs["flag"]?.path == "/verified-cache/v1/flag.png")
        var restored = try JSONDecoder().decode(GameplayMatchStageViewModel.self, from: try #require(reloaded.stageState))
        #expect(restored == model)
        let actualMutation10 = restored.chooseRight(pair.right)
        #expect(actualMutation10)
        #expect(restored.evidence.attempts.last?.outcome == .supportedCorrect)
    }

    @Test
    func compactEasyMemoryCollapsesExplanatoryStagePrompt() {
        #expect(!GameplayStageRenderSupport.showsStagePrompt(kind: .easyMemory, compact: true))
        #expect(GameplayStageRenderSupport.showsStagePrompt(kind: .easyMemory, compact: false))
        #expect(GameplayStageRenderSupport.showsStagePrompt(kind: .flipMemory, compact: true))
        #expect(GameplayStageRenderSupport.showsStagePrompt(kind: .multipleChoice, compact: true))
    }
}

struct GameplayThreadCatalogRegressionTests {
    @Test
    func allDirectGameplayEntriesUseFiveStageReusableThread() {
        let directEntries: [GameplayThreadID] = [.countries, .fruits, .waterCycle]

        for id in directEntries {
            let thread = GameplayThreadCatalog.thread(for: id)
            #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
            #expect(!thread.entities.isEmpty)
        }
    }
}
