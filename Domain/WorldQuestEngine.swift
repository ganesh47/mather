import Foundation
import Observation

@MainActor
@Observable
final class WorldQuestEngine {
    enum Phase: Equatable { case setup, exploring, answering, feedback, completed }
    enum Suspension: Hashable { case narration, interruption }

    let catalog: CountryCatalog
    private(set) var phase: Phase = .setup
    private(set) var pack: WorldQuestPack = .starter
    private(set) var mode: WorldQuestMode = .practice
    private(set) var questions: [String] = []
    private(set) var questionIndex = 0
    private(set) var answers: [WorldQuestAnswer] = []
    private(set) var attempts = 0
    private(set) var usedHint = false
    private(set) var lastWrongID: String?
    private(set) var remainingSeconds = 20.0
    private(set) var suspensions: Set<Suspension> = []
    private(set) var completion: WorldQuestSession?
    @ObservationIgnored private let now: () -> Double
    @ObservationIgnored private var activeSince: Double?
    @ObservationIgnored private var elapsed = 0.0
    @ObservationIgnored private var sessionID = UUID()

    init(catalog: CountryCatalog, now: @escaping () -> Double = { ProcessInfo.processInfo.systemUptime }) {
        self.catalog = catalog
        self.now = now
    }

    var target: WorldQuestCountry? {
        guard questions.indices.contains(questionIndex) else { return nil }
        return catalog.country(questions[questionIndex])
    }
    var selectableCountries: [WorldQuestCountry] { catalog.countries(in: pack) }
    var needsResume: Bool { suspensions.contains(.interruption) }
    var isSuspended: Bool { !suspensions.isEmpty }
    var prompt: String {
        guard let target else { return "Move around the map to discover countries." }
        return "Find \(target.name)."
    }
    var hintContinent: WorldQuestContinent? { usedHint ? target?.continent : nil }

    func start(pack: WorldQuestPack, mode: WorldQuestMode, seed: UInt64) {
        self.pack = pack
        self.mode = mode
        sessionID = UUID()
        answers = []
        questionIndex = 0
        completion = nil
        var random = WorldQuestRandom(state: seed)
        questions = mode == .explore ? [] : Array(catalog.countries(in: pack).map(\.id).shuffled(using: &random).prefix(10))
        if mode == .explore {
            phase = .exploring
            suspensions = []
            activeSince = nil
        } else {
            beginQuestion()
        }
    }

    func suspend(_ reason: Suspension) {
        guard phase == .answering else { return }
        captureElapsed()
        suspensions.insert(reason)
    }

    func resume(_ reason: Suspension) {
        guard phase == .answering else { return }
        suspensions.remove(reason)
        if suspensions.isEmpty, activeSince == nil { activeSince = now() }
    }

    /// Called by the UI clock; answer submission also checks the same deadline.
    func tick() {
        guard phase == .answering else { return }
        let duration = currentElapsed
        remainingSeconds = max(0, 20 - duration)
        if mode == .timed, duration >= 20 { finish(.revealed) }
    }

    @discardableResult
    func submit(countryID: String) -> Bool {
        tick()
        guard phase == .answering, !isSuspended, selectableCountries.contains(where: { $0.id == countryID }) else { return false }
        attempts += 1
        if countryID == target?.id {
            finish(usedHint ? .assisted : .independent)
            return true
        }
        lastWrongID = countryID
        return false
    }

    func hint() {
        tick()
        guard phase == .answering, !isSuspended else { return }
        usedHint = true
    }

    func reveal() {
        tick()
        guard phase == .answering, !isSuspended else { return }
        finish(.revealed)
    }

    func advance() {
        guard phase == .feedback else { return }
        if questionIndex + 1 == questions.count {
            phase = .completed
            completion = WorldQuestSession(id: sessionID, pack: pack, mode: mode, answers: answers, completedAt: Date())
        } else {
            questionIndex += 1
            beginQuestion()
        }
    }

    func returnToSetup() {
        phase = .setup
        activeSince = nil
        suspensions = []
        completion = nil
    }

    private var currentElapsed: Double { elapsed + (activeSince.map { max(0, now() - $0) } ?? 0) }

    private func captureElapsed() {
        elapsed = currentElapsed
        activeSince = nil
    }

    private func beginQuestion() {
        attempts = 0
        usedHint = false
        lastWrongID = nil
        elapsed = 0
        activeSince = nil
        remainingSeconds = 20
        suspensions = [.narration]
        phase = .answering
    }

    private func finish(_ outcome: WorldQuestOutcome) {
        guard let target, phase == .answering else { return }
        captureElapsed()
        answers.append(WorldQuestAnswer(countryID: target.id, outcome: outcome, attempts: attempts,
                                        seconds: mode == .timed ? min(elapsed, 20) : elapsed))
        remainingSeconds = max(0, 20 - elapsed)
        suspensions = []
        phase = .feedback
    }
}
