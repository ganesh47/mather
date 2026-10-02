import Foundation
import Testing
@testable import Mather

@MainActor
struct ShapeDetectiveTVSessionTests {
    private func isolatedStore(_ profile: String = "child") -> (ShapeDetectiveTVSessionStore, UserDefaults) {
        let suite = "ShapeDetectiveTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (.init(defaults: defaults, profileID: profile), defaults)
    }

    private func finish(_ session: ShapeDetectiveTVSession) {
        while let item = session.current {
            #expect(session.choose(item.answerID))
            session.advance()
        }
    }

    @Test func sevenItemsHaveFiniteEndingAndRepeatedSelectCannotDuplicateEvidence() {
        let (store, _) = isolatedStore()
        var results: [ActivityResult] = []
        let session = ShapeDetectiveTVSession(profileID: "child", store: store, onResult: { results.append($0) })
        session.advance()
        #expect(session.checkpoint.index == 0)
        let first = session.current!
        #expect(session.choose(first.answerID))
        #expect(!session.choose(first.answerID))
        #expect(session.checkpoint.attempts.filter { $0.outcome == .independentCorrect }.count == 1)
        session.advance()
        finish(session)
        #expect(session.isComplete)
        #expect(session.unaidedCount == 7)
        #expect(results.count == 1)
        #expect(results[0].completedStageIDs.count == 7)
        session.advance()
        session.requestHint()
        #expect(results.count == 1)
        #expect(session.current == nil)
    }

    @Test func wrongAnswerKeepsChoicesOpenAndHintsDoNotRevealAnswer() {
        let (store, _) = isolatedStore()
        let session = ShapeDetectiveTVSession(profileID: "child", store: store)
        let item = session.current!
        let wrong = item.choices.first { $0.id != item.answerID }!
        #expect(!session.choose(wrong.id))
        #expect(!session.checkpoint.solved)
        #expect(session.checkpoint.misses == 1)
        #expect(session.checkpoint.hintLevel == 1)
        #expect(!session.feedback.contains("answer is"))
        #expect(session.choose(item.answerID))
        #expect(session.supportedCount == 1)
        #expect(session.unaidedCount == 0)
        #expect(session.checkpoint.attempts.map(\.outcome) == [.exposure, .incorrect, .help, .supportedCorrect])
    }

    @Test func retryAfterRelaunchPreservesSupportAndFrozenEventIdentity() {
        let (store, _) = isolatedStore()
        let session = ShapeDetectiveTVSession(profileID: "child", store: store)
        let item = session.current!
        _ = session.choose(item.choices.first { $0.id != item.answerID }!.id)
        let before = session.checkpoint
        var replayed: [ItemAttempt] = []
        let resumed = ShapeDetectiveTVSession(profileID: "child", store: store, onAttempt: { replayed.append($0) })
        #expect(resumed.checkpoint == before)
        #expect(replayed == before.attempts)
        #expect(resumed.choose(item.answerID))
        #expect(resumed.checkpoint.attempts.last?.outcome == .supportedCorrect)
        #expect(resumed.checkpoint.sessionID == before.sessionID)
        #expect(resumed.checkpoint.attempts.last?.adultHelp == .unknown)
        #expect(resumed.checkpoint.attempts.last?.appHintUsed == true)
    }

    @Test func explicitHintIsSupportedWhileRepeatingPromptIsNotHelp() {
        let (store, _) = isolatedStore()
        let session = ShapeDetectiveTVSession(profileID: "child", store: store)
        let events = session.checkpoint.attempts
        _ = session.prompt
        _ = session.prompt
        #expect(session.checkpoint.attempts == events)
        session.requestHint()
        session.requestHint()
        session.requestHint()
        #expect(session.checkpoint.hintLevel == 2)
        #expect(session.checkpoint.attempts.filter { $0.outcome == .help }.count == 2)
        #expect(session.choose(session.current!.answerID))
        #expect(session.checkpoint.attempts.last?.outcome == .supportedCorrect)
    }

    @Test func probeChangesGeometryStartsUnhintedAndIsNotReusedOnReplay() {
        let (store, _) = isolatedStore()
        let session = ShapeDetectiveTVSession(profileID: "child", store: store)
        for _ in 0..<6 { _ = session.choose(session.current!.answerID); session.advance() }
        let probe = session.current!
        #expect(probe.isProbe)
        #expect(session.checkpoint.hintLevel == 0)
        let exposure = session.checkpoint.attempts.last!
        #expect(exposure.outcome == .exposure && exposure.isFreshProbe == true && exposure.appHintUsed == false)
        let figure = probe.choices.first { $0.id == probe.answerID }!.figure
        #expect(!ShapeDetectiveCatalog.practice.flatMap(\.choices).map(\.figure).contains(figure))
        _ = session.choose(probe.answerID)
        #expect(session.checkpoint.attempts.last?.outcome == .independentCorrect)
        session.advance()
        session.replay()
        #expect(session.checkpoint.probeID != probe.id)
        #expect(store.usedProbeIDs.contains(probe.id))
        #expect(session.checkpoint.sessionID != exposure.sessionID)
    }

    @Test func exhaustedProbePoolIsHonestlyReportedAsRevisit() {
        let (store, _) = isolatedStore()
        ShapeDetectiveCatalog.probes.forEach { store.reserveProbe($0.id) }
        let session = ShapeDetectiveTVSession(profileID: "child", store: store)
        for _ in 0..<6 { _ = session.choose(session.current!.answerID); session.advance() }
        #expect(session.current!.isProbe)
        #expect(!session.checkpoint.probeIsFresh)
        #expect(session.prompt.hasPrefix("A shape check again."))
        #expect(session.checkpoint.attempts.last?.isFreshProbe == false)
    }

    @Test func finishedResultAndOptionalRoomPromptNeverCreateVerifiedTransfer() {
        let (store, _) = isolatedStore()
        let session = ShapeDetectiveTVSession(profileID: "child", store: store)
        finish(session)
        let result = session.result!
        session.showRoomPrompt()
        #expect(session.checkpoint.roomPromptShown)
        #expect(session.result == result)
        var replayedResults: [ActivityResult] = []
        let resumed = ShapeDetectiveTVSession(profileID: "child", store: store, onResult: { replayedResults.append($0) })
        #expect(resumed.isComplete)
        #expect(replayedResults == [result])
    }

    @Test func storesAreIsolatedByProfileAndRejectCorruptOrFuturePayloads() {
        let (store, defaults) = isolatedStore("child-A")
        let session = ShapeDetectiveTVSession(profileID: "child-A", store: store)
        session.requestHint()
        let other = ShapeDetectiveTVSessionStore(defaults: defaults, profileID: "child-B")
        #expect(other.load() == nil)
        var invalid = session.checkpoint
        invalid.version = 999
        defaults.set(try! JSONEncoder().encode(invalid), forKey: "mather.shape-detective.v1.child-A")
        #expect(store.load() == nil)
        defaults.set(Data("bad json".utf8), forKey: "mather.shape-detective.v1.child-A")
        #expect(store.load() == nil)
        invalid = session.checkpoint
        invalid.index = 7
        #expect(!invalid.isValid(for: "child-A"))
        invalid = session.checkpoint
        invalid.attempts.append(invalid.attempts[0])
        #expect(!invalid.isValid(for: "child-A"))
    }

    @Test func parentResetClearsOnlyThisProfilesCheckpointAndProbeHistory() {
        let (store, defaults) = isolatedStore("child-A")
        let first = ShapeDetectiveTVSession(profileID: "child-A", store: store)
        first.requestHint()
        store.reserveProbe(ShapeDetectiveCatalog.probes[0].id)
        let other = ShapeDetectiveTVSessionStore(defaults: defaults, profileID: "child-B")
        let second = ShapeDetectiveTVSession(profileID: "child-B", store: other)
        second.requestHint()
        other.reserveProbe(ShapeDetectiveCatalog.probes[1].id)
        let preserved = other.load()
        store.clear()
        #expect(store.load() == nil)
        #expect(store.usedProbeIDs.isEmpty)
        #expect(other.load() == preserved)
        #expect(other.usedProbeIDs == [ShapeDetectiveCatalog.probes[1].id])
    }

    @Test func everyClueHasOnePropertyAnswerAndAccurateDrawnGeometry() {
        for item in ShapeDetectiveCatalog.practice + ShapeDetectiveCatalog.probes {
            #expect(item.choices.count == 4)
            #expect(Set(item.choices.map(\.id)).count == 4)
            #expect(item.choices.filter { $0.figure.kind == item.answer }.count == 1)
            for choice in item.choices {
                let figure = choice.figure
                let vertices = figure.vertices
                if figure.kind == .circle { #expect(vertices.isEmpty); continue }
                #expect(vertices.count == (figure.kind == .triangle ? 3 : 4))
                let sides = vertices.indices.map { i in
                    hypot(vertices[(i + 1) % vertices.count].x - vertices[i].x, vertices[(i + 1) % vertices.count].y - vertices[i].y)
                }
                let rightCorners = vertices.indices.filter { i in
                    let previous = vertices[(i + vertices.count - 1) % vertices.count]
                    let next = vertices[(i + 1) % vertices.count]
                    let point = vertices[i]
                    return abs((previous.x - point.x) * (next.x - point.x) + (previous.y - point.y) * (next.y - point.y)) < 0.000001
                }.count
                if figure.kind == .square || figure.kind == .nonSquareRhombus {
                    #expect(sides.allSatisfy { abs($0 - sides[0]) < 0.000001 })
                }
                if figure.kind == .square || figure.kind == .rectangle { #expect(rightCorners == 4) }
                if figure.kind == .nonSquareRhombus { #expect(rightCorners == 0) }
                if figure.kind == .rectangle { #expect(abs(sides[0] - sides[1]) > 0.1) }
            }
        }
        let square = ShapeDetectiveCatalog.practice.first { $0.answer == .square }!
        #expect(square.fact.contains("square is also a rectangle"))
        #expect(square.choices.contains { $0.figure.kind == .nonSquareRhombus })
    }
}
