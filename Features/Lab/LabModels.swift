import Foundation

enum ChildAgeBand: String, CaseIterable, Hashable {
    case toddler = "2–3"
    case preschool = "4–5"
    case earlyElementary = "6–7"
    case upperElementary = "8–10"
    case preteen = "11–12"

    var label: String { "Ages \(rawValue)" }
}

struct CapabilityAgeEntry: Identifiable, Equatable {
    var id: ChildAgeBand { ageBand }
    let ageBand: ChildAgeBand
    let posture: String
    let entryPlay: String

    var summaryLabel: String {
        "\(ageBand.label): \(entryPlay)"
    }
}


struct MixMatchCard: Identifiable, Equatable {
    var id: String { "\(laneID.rawValue)-\(concept)-\(prompt)" }
    let laneID: CapabilityLaneID
    let concept: String
    let prompt: String
    let match: String

    init(laneID: CapabilityLaneID, concept: String, prompt: String, match: String) {
        self.laneID = laneID
        self.concept = concept
        self.prompt = prompt
        self.match = match
    }

    var accessibilityLabel: String {
        "\(prompt), matches \(match)"
    }
}


struct MixMatchReviewSampler: Equatable {
    let laneID: CapabilityLaneID
    let cards: [MixMatchCard]
    private(set) var currentIndex: Int

    init(laneID: CapabilityLaneID, cards: [MixMatchCard], currentIndex: Int = 0) {
        self.laneID = laneID
        self.cards = cards
        if cards.isEmpty {
            self.currentIndex = 0
        } else {
            self.currentIndex = min(max(currentIndex, 0), cards.count - 1)
        }
    }

    var currentCard: MixMatchCard? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var progressLabel: String {
        guard !cards.isEmpty else { return "0 / 0" }
        return "\(currentIndex + 1) / \(cards.count)"
    }

    mutating func advance() {
        guard !cards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % cards.count
    }

    mutating func rewind() {
        guard !cards.isEmpty else { return }
        currentIndex = (currentIndex - 1 + cards.count) % cards.count
    }
}



// MARK: - Guided Remember stage foundation

enum LabRememberStageDeckID: String, Codable, Hashable, Identifiable {
    case numbersNumberBondsTo10 = "numbers-number-bonds-to-10-remember"

    var id: String { rawValue }
}

struct LabRememberStageCard: Codable, Equatable, Identifiable, Hashable {
    let id: String
    let laneID: CapabilityLaneID
    let concept: String
    let prompt: String
    let answer: String
    let supportCopy: String

    init(
        id: String,
        laneID: CapabilityLaneID,
        concept: String,
        prompt: String,
        answer: String,
        supportCopy: String
    ) {
        self.id = id
        self.laneID = laneID
        self.concept = concept
        self.prompt = prompt
        self.answer = answer
        self.supportCopy = supportCopy
    }

    init(mixMatchCard: MixMatchCard, supportCopy: String) {
        self.init(
            id: mixMatchCard.id,
            laneID: mixMatchCard.laneID,
            concept: mixMatchCard.concept,
            prompt: mixMatchCard.prompt,
            answer: mixMatchCard.match,
            supportCopy: supportCopy
        )
    }

    var accessibilityLabel: String {
        "Remember card. \(prompt), answer \(answer). \(supportCopy)"
    }
}

struct LabRememberStageDeck: Equatable, Identifiable {
    let id: LabRememberStageDeckID
    let planID: String
    let stage: GuidedLabStage
    let laneID: CapabilityLaneID
    let concept: String
    let title: String
    let subtitle: String
    let timerPolicy: LabSessionTimerPolicy
    let cards: [LabRememberStageCard]

    var route: AppRoute { .labRememberStage(id) }
    var hasPunitiveCountdown: Bool { timerPolicy.showsCountdown || timerPolicy.isPunitive }

    static func deck(for id: LabRememberStageDeckID) -> LabRememberStageDeck {
        switch id {
        case .numbersNumberBondsTo10:
            return .numbersNumberBondsTo10
        }
    }

    static let numbersNumberBondsTo10 = LabRememberStageDeck(
        id: .numbersNumberBondsTo10,
        planID: "numbers-number-bonds-to-10",
        stage: .remember,
        laneID: .numbers,
        concept: "number-bond",
        title: "Remember pairs to 10",
        subtitle: "Flip friendly bond facts back into memory — no countdown, no penalty.",
        timerPolicy: .calmNoCountdown,
        cards: Self.numberBondCardsTo10()
    )

    private static func numberBondCardsTo10() -> [LabRememberStageCard] {
        let mixMatchSupport = "Picture the two parts snapping into one full ten-frame."
        let existingNumberBondCards = CapabilityLane.starterMixMatchCardsByLane[.numbers, default: []]
            .filter { $0.concept == "number-bond" && $0.match == "10" }
            .map { LabRememberStageCard(mixMatchCard: $0, supportCopy: mixMatchSupport) }
        let existingIDs = Set(existingNumberBondCards.map(\.id))
        let supplementalPairs: [(String, String)] = [
            ("0 + 10", "empty and full ten-frame"),
            ("1 + 9", "one dot plus nine more fills ten"),
            ("2 + 8", "two dots need eight friends"),
            ("3 + 7", "three and seven make a full row pair"),
            ("4 + 6", "four dots need six to make ten"),
            ("5 + 5", "five-frame plus five-frame makes ten"),
            ("6 + 4", "six and four are switch partners"),
            ("7 + 3", "seven and three are switch partners"),
            ("8 + 2", "eight and two are switch partners"),
            ("9 + 1", "nine needs one more"),
            ("10 + 0", "full ten-frame plus none stays ten"),
        ]
        let supplemental = supplementalPairs.map { prompt, clue in
            LabRememberStageCard(
                id: "numbers-number-bond-\(prompt.replacingOccurrences(of: " + ", with: "-plus-"))",
                laneID: .numbers,
                concept: "number-bond",
                prompt: prompt,
                answer: "10",
                supportCopy: clue
            )
        }
        return existingNumberBondCards + supplemental.filter { !existingIDs.contains($0.id) }
    }
}

struct LabRememberStageExecution: Equatable {
    let deck: LabRememberStageDeck
    private(set) var currentIndex: Int
    private(set) var reviewedCardIDs: [String]
    private(set) var correctCardIDs: Set<String>
    private(set) var selectedAnswer: String?

    init(deck: LabRememberStageDeck, currentIndex: Int = 0, reviewedCardIDs: [String] = [], correctCardIDs: Set<String> = []) {
        self.deck = deck
        self.currentIndex = deck.cards.isEmpty ? 0 : min(max(currentIndex, 0), deck.cards.count - 1)
        self.reviewedCardIDs = reviewedCardIDs
        self.correctCardIDs = correctCardIDs
        self.selectedAnswer = nil
    }

    var currentCard: LabRememberStageCard? {
        guard deck.cards.indices.contains(currentIndex) else { return nil }
        return deck.cards[currentIndex]
    }

    var progressLabel: String {
        guard !deck.cards.isEmpty else { return "0 / 0" }
        return "\(min(currentIndex + 1, deck.cards.count)) / \(deck.cards.count)"
    }

    var isComplete: Bool {
        !deck.cards.isEmpty && Set(reviewedCardIDs).isSuperset(of: deck.cards.map(\.id))
    }

    var usesPunitiveCountdown: Bool { deck.hasPunitiveCountdown }

    mutating func submit(answer: String) -> Bool {
        guard let card = currentCard else { return false }
        selectedAnswer = answer
        if !reviewedCardIDs.contains(card.id) {
            reviewedCardIDs.append(card.id)
        }
        let isCorrect = answer.trimmingCharacters(in: .whitespacesAndNewlines) == card.answer
        if isCorrect {
            correctCardIDs.insert(card.id)
        }
        return isCorrect
    }

    mutating func advance() {
        selectedAnswer = nil
        guard !deck.cards.isEmpty else { return }
        currentIndex = min(currentIndex + 1, deck.cards.count - 1)
    }
}

struct LaneRecallEntry: Identifiable, Equatable {
    let laneID: CapabilityLaneID
    let card: LearningCard

    var id: String { card.id }

    var title: String {
        card.prompt.displayText ?? card.prompt.speechText
    }

    var answerLabel: String {
        card.answer.displayText ?? card.answer.speechText
    }

    var choiceActions: [LaneRecallReviewAction] {
        card.choices.map { choice in
            LaneRecallReviewAction(
                laneID: laneID,
                cardID: card.id,
                choiceID: choice.id,
                isCorrect: choice.isCorrect
            )
        }
    }
}

struct LaneRecallReviewAction: Equatable {
    let laneID: CapabilityLaneID
    let cardID: String
    let choiceID: String
    let isCorrect: Bool
}

enum LabActivityID: String, CaseIterable, Hashable {
    case sumSprint
    case roomQuest
    case symmetryFold
    case rectangleFactory
    case factoryCards
    case angleCannon
    case twoFingerProtractor
    case gravityArtist
    case compassAngles
    case shapeGeometry
    case waterCycle
    case soundVolume
    case memoryMatch
    case countryCards
    case fruitCards
}

extension LabActivityID {
    var appRoute: AppRoute {
        switch self {
        case .sumSprint:
            return .sumSprint
        case .roomQuest:
            return .roomQuest
        case .symmetryFold:
            return .symmetryFold
        case .rectangleFactory:
            return .rectangleFactory
        case .factoryCards:
            return .factoryCards
        case .angleCannon:
            return .angleCannon
        case .twoFingerProtractor:
            return .twoFingerProtractor
        case .gravityArtist:
            return .gravityArtist
        case .compassAngles:
            return .compassAngles
        case .shapeGeometry:
            return .shapeGeometry
        case .waterCycle:
            return .gameplayThread(.waterCycle)
        case .soundVolume:
            return .soundVolume
        case .memoryMatch:
            return .memory
        case .countryCards:
            return .gameplayThread(.countries)
        case .fruitCards:
            return .gameplayThread(.fruits)
        }
    }
}

struct LabActivity: Identifiable, Equatable {
    let id: LabActivityID
    let emoji: String
    let title: String
    let tagline: String
    let modes: [PlayMode]

    init(id: LabActivityID, emoji: String, title: String, tagline: String, modes: [PlayMode]) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.tagline = tagline
        self.modes = modes
    }

    var accessibilityLabel: String {
        "\(title). \(tagline)"
    }

    var accessibilityHint: String {
        "Launches \(title). Modes: \(modes.map(\.rawValue).joined(separator: ", "))."
    }
}


enum ExplorerPathID: String, CaseIterable, Hashable, Identifiable {
    case labs
    case games

    var id: String { rawValue }
}

struct ExplorerPathPresentation: Identifiable, Equatable {
    let id: ExplorerPathID
    let emoji: String
    let title: String
    let subtitle: String
    let callToAction: String

    static let all: [ExplorerPathPresentation] = [
        ExplorerPathPresentation(
            id: .labs,
            emoji: "🧭",
            title: "Labs",
            subtitle: "Guided sessions that move from learning to remembering, playful practice, blast rounds, and score.",
            callToAction: "Start a learning path"
        ),
        ExplorerPathPresentation(
            id: .games,
            emoji: "🎮",
            title: "Games",
            subtitle: "Jump straight into the games you already love — no staged lesson required.",
            callToAction: "Play now"
        ),
    ]
}

enum GuidedLabStage: String, CaseIterable, Codable, Hashable, Identifiable {
    case learn = "Learn"
    case remember = "Remember"
    case play = "Play"
    case blast = "Blast"
    case score = "Score"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .learn: return "📖"
        case .remember: return "🧠"
        case .play: return "🕹️"
        case .blast: return "🚀"
        case .score: return "⭐"
        }
    }

    var microcopy: String {
        switch self {
        case .learn: return "See the idea"
        case .remember: return "Recall cards"
        case .play: return "Practice calmly"
        case .blast: return "Fast round"
        case .score: return "Celebrate progress"
        }
    }
}

enum LabSessionTimerPressure: String, Equatable {
    case trackedOnly
    case none
    case readinessGated
}

struct LabSessionTimerPolicy: Equatable {
    let pressure: LabSessionTimerPressure
    let tracksElapsedTime: Bool
    let showsCountdown: Bool
    let isPunitive: Bool
    let childCopy: String

    static let learnTrackedOnly = LabSessionTimerPolicy(
        pressure: .trackedOnly,
        tracksElapsedTime: true,
        showsCountdown: false,
        isPunitive: false,
        childCopy: "No rush — I’ll just remember how long you explored."
    )

    static let calmNoCountdown = LabSessionTimerPolicy(
        pressure: .none,
        tracksElapsedTime: true,
        showsCountdown: false,
        isPunitive: false,
        childCopy: "Take your time. Memory grows with calm practice."
    )

    static let readinessGatedBlast = LabSessionTimerPolicy(
        pressure: .readinessGated,
        tracksElapsedTime: true,
        showsCountdown: false,
        isPunitive: false,
        childCopy: "Blast is a celebration after you feel ready — not a test."
    )
}

struct LabSessionStagePlan: Identifiable, Equatable {
    let stage: GuidedLabStage
    let title: String
    let childCopy: String
    let parentCopy: String
    let timerPolicy: LabSessionTimerPolicy
    let route: AppRoute?

    var id: GuidedLabStage { stage }

    var actionLabel: String {
        route == nil ? "Preview" : (stage == .learn ? "Start" : "Continue")
    }

    var accessibilityLabel: String {
        "\(stage.rawValue). \(title). \(childCopy)"
    }
}

struct LabConceptSessionPlan: Identifiable, Equatable {
    let id: String
    let laneID: CapabilityLaneID
    let title: String
    let subtitle: String
    let estimatedLength: String
    let masteryStateLabel: String
    let recommendedNextActivity: String
    let stages: [LabSessionStagePlan]

    var stageOrder: [GuidedLabStage] { stages.map(\.stage) }
    var startRoute: AppRoute? { stages.first(where: { $0.route != nil })?.route }
    var startAffordanceLabel: String { "Start" }
    var continueAffordanceLabel: String { "Continue" }
    var pathLabel: String { stageOrder.map(\.rawValue).joined(separator: " → ") }

    static func plan(for id: String) -> LabConceptSessionPlan? {
        if id == numbersNumberBondsTo10.id {
            return .numbersNumberBondsTo10
        }
        return nil
    }

    static let numbersNumberBondsTo10 = LabConceptSessionPlan(
        id: "numbers-number-bonds-to-10",
        laneID: .numbers,
        title: "Number Bonds to 10",
        subtitle: "Build pairs that make ten, remember friendly facts, then celebrate with Bond Blast.",
        estimatedLength: "8–10 min",
        masteryStateLabel: "Recommended first",
        recommendedNextActivity: "Make & Break warm-up",
        stages: [
            LabSessionStagePlan(
                stage: .learn,
                title: "Build ten",
                childCopy: "Move counters and see two parts make one ten.",
                parentCopy: "Concrete/pictorial discovery before symbols; elapsed time is tracked only.",
                timerPolicy: .learnTrackedOnly,
                route: .sessionConfig
            ),
            LabSessionStagePlan(
                stage: .remember,
                title: "Bring pairs back",
                childCopy: "Use friendly picture clues to remember ten pairs.",
                parentCopy: "Soft retrieval with visual support; no punitive countdown.",
                timerPolicy: .calmNoCountdown,
                route: .labRememberStage(.numbersNumberBondsTo10)
            ),
            LabSessionStagePlan(
                stage: .play,
                title: "Try it for real",
                childCopy: "Practice bonds inside playful number games.",
                parentCopy: "Application stays calm before any readiness-gated speed round.",
                timerPolicy: .calmNoCountdown,
                route: .sumSprint
            ),
            LabSessionStagePlan(
                stage: .blast,
                title: "Bond Blast",
                childCopy: "A rocket round appears when you’re ready to celebrate.",
                parentCopy: "Blast is celebratory and readiness gated; countdown pressure is not default.",
                timerPolicy: .readinessGatedBlast,
                route: nil
            ),
            LabSessionStagePlan(
                stage: .score,
                title: "Spark score",
                childCopy: "See what grew and pick the next tiny quest.",
                parentCopy: "Child score stays encouraging; richer analytics can live in parent detail later.",
                timerPolicy: .calmNoCountdown,
                route: nil
            ),
        ]
    )
}

struct GuidedLabPath: Identifiable, Equatable {
    let laneID: CapabilityLaneID
    let title: String
    let subtitle: String
    let stages: [GuidedLabStage]
    let sessionPlans: [LabConceptSessionPlan]

    var id: CapabilityLaneID { laneID }
    var primaryPlan: LabConceptSessionPlan? { sessionPlans.first }

    init(
        laneID: CapabilityLaneID,
        title: String,
        subtitle: String,
        stages: [GuidedLabStage],
        sessionPlans: [LabConceptSessionPlan] = []
    ) {
        self.laneID = laneID
        self.title = title
        self.subtitle = subtitle
        self.stages = stages
        self.sessionPlans = sessionPlans
    }

    static let phaseOne: [GuidedLabPath] = [
        GuidedLabPath(
            laneID: .numbers,
            title: "Numbers Path",
            subtitle: "A first guided loop for Number Bonds to 10.",
            stages: LabConceptSessionPlan.numbersNumberBondsTo10.stageOrder,
            sessionPlans: [.numbersNumberBondsTo10]
        ),
    ]
}

struct RoundTimerSnapshot: Equatable {
    let startedAt: Date
    let now: Date
    let limitSeconds: TimeInterval?
    let timerPolicy: LabSessionTimerPolicy

    init(startedAt: Date, now: Date, limitSeconds: TimeInterval? = nil, timerPolicy: LabSessionTimerPolicy) {
        self.startedAt = startedAt
        self.now = now
        self.limitSeconds = limitSeconds
        self.timerPolicy = timerPolicy
    }

    var elapsedSeconds: TimeInterval {
        max(0, now.timeIntervalSince(startedAt))
    }

    var remainingSeconds: TimeInterval? {
        guard timerPolicy.showsCountdown, let limitSeconds else { return nil }
        return max(0, limitSeconds - elapsedSeconds)
    }

    var childFacingLabel: String {
        if let remainingSeconds {
            return "Final round: \(Self.format(remainingSeconds)) left"
        }
        return "Time spent: \(Self.format(elapsedSeconds))"
    }

    static func format(_ seconds: TimeInterval) -> String {
        let clamped = max(0, Int(seconds.rounded()))
        return "\(clamped / 60):" + String(format: "%02d", clamped % 60)
    }
}

struct LabSessionScoreSummary: Codable, Equatable {
    let conceptTitle: String
    let stageDurations: [GuidedLabStage: TimeInterval]
    let accuracy: Double
    let streak: Int
    let weakAreas: [String]
    let nextRecommendation: String

    var totalSeconds: TimeInterval {
        stageDurations.values.reduce(0, +)
    }

    var childCelebrationLine: String {
        if weakAreas.isEmpty {
            return "Session Complete 🎉 You powered up \(conceptTitle)!"
        }
        return "Session Complete 🎉 \(weakAreas.count) tricky \(weakAreas.count == 1 ? "idea" : "ideas") will come back soon."
    }

    var parentDetailLines: [String] {
        [
            "Total time: \(RoundTimerSnapshot.format(totalSeconds))",
            "Accuracy: \(Int((accuracy * 100).rounded()))%",
            "Best streak: \(streak)",
            "Next: \(nextRecommendation)",
        ] + GuidedLabStage.allCases.compactMap { stage in
            guard let seconds = stageDurations[stage] else { return nil }
            return "\(stage.rawValue): \(RoundTimerSnapshot.format(seconds))"
        } + (weakAreas.isEmpty ? ["Weak areas: none flagged"] : ["Coming back soon: \(weakAreas.joined(separator: ", "))"])
    }
}

struct ExplorerGameEntry: Identifiable, Equatable {
    let laneID: CapabilityLaneID
    let activity: LabActivity

    var id: LabActivityID { activity.id }
    var directRoute: AppRoute { activity.id.appRoute }
}

enum ExplorerGameRegistry {
    static let directLaunchEntries: [ExplorerGameEntry] = CapabilityLane.defaultExplorerLanes.flatMap { lane in
        lane.activities.map { ExplorerGameEntry(laneID: lane.id, activity: $0) }
    }
}

enum LabSensorNeed: CaseIterable, Equatable {
    case noSpecialSensor
    case motion
    case compass
    case cameraMarkerMode
    case haptics

    func isAvailable(with capabilities: DeviceSensorCapabilities) -> Bool {
        switch self {
        case .noSpecialSensor:
            return true
        case .motion:
            return capabilities.supportsMotion
        case .compass:
            return capabilities.supportsHeading
        case .cameraMarkerMode:
            return capabilities.supportsCamera
        case .haptics:
            return capabilities.supportsHaptics
        }
    }

    func copy(with capabilities: DeviceSensorCapabilities) -> LabSensorAffordance {
        let available = isAvailable(with: capabilities)
        switch self {
        case .noSpecialSensor:
            return LabSensorAffordance(
                need: self,
                isAvailable: true,
                label: "No special sensor needed",
                fallback: nil
            )
        case .motion:
            return LabSensorAffordance(
                need: self,
                isAvailable: available,
                label: available ? "Motion ready" : "Motion unavailable",
                fallback: available ? nil : "Touch fallback available"
            )
        case .compass:
            return LabSensorAffordance(
                need: self,
                isAvailable: available,
                label: available ? "Compass ready" : "Compass unavailable",
                fallback: available ? nil : "Use on-screen turns"
            )
        case .cameraMarkerMode:
            return LabSensorAffordance(
                need: self,
                isAvailable: available,
                label: available ? "Camera marker mode ready" : "Camera marker mode unavailable",
                fallback: available ? nil : "Use tap-to-place stations"
            )
        case .haptics:
            return LabSensorAffordance(
                need: self,
                isAvailable: available,
                label: available ? "Haptics ready" : "Haptics unavailable",
                fallback: available ? nil : "Visual feedback stays available"
            )
        }
    }
}

struct LabSensorAffordance: Identifiable, Equatable {
    var id: LabSensorNeed { need }
    let need: LabSensorNeed
    let isAvailable: Bool
    let label: String
    let fallback: String?

    var displayLabel: String {
        guard let fallback else { return label }
        return "\(label): \(fallback)"
    }

    var accessibilityLabel: String {
        displayLabel
    }

    var accessibilityHint: String {
        if need == .noSpecialSensor {
            return "Works with touch only."
        }
        if isAvailable {
            return "Sensor is ready for this activity."
        }
        guard let fallback else {
            return "This activity still works without extra setup."
        }
        return fallback
    }
}

enum LabLaneCardSection: Equatable {
    case visualSummary
    case promise
    case progressStatus
    case modes
    case playStyles
    case ageEntries
    case recall
    case activities
    case comingSoon
}

struct LabLaneCardPresentation: Equatable {
    let laneID: CapabilityLaneID
    let title: String
    let promiseLine: String
    let progressMicrocopy: String
    let openAffordanceLabel: String
    let accessibilityLabel: String
    let accessibilityHint: String
    let sections: [LabLaneCardSection]

    init(lane: CapabilityLane, progress: CapabilityLaneProgress) {
        self.laneID = lane.id
        title = lane.title
        promiseLine = lane.promise
        progressMicrocopy = "\(progress.progressSummaryLabel) • \(progress.nextRecommendedModeLabel)"
        openAffordanceLabel = "Enter world"
        accessibilityLabel = "\(lane.title). \(lane.ageBandHint). \(lane.promise)"
        accessibilityHint = "Opens \(lane.title) to choose missions, review cards, play styles, and sensor options."
        sections = [
            .visualSummary,
            .promise,
            .progressStatus,
        ]
    }

    var showsDetails: Bool {
        sections.contains(.activities) || sections.contains(.comingSoon)
    }
}

struct LabLaneDetailPresentation: Equatable {
    let laneID: CapabilityLaneID
    let title: String
    let activityCountLabel: String
    let sections: [LabLaneCardSection]

    init(lane: CapabilityLane) {
        laneID = lane.id
        title = lane.title
        activityCountLabel = lane.activities.isEmpty
            ? "Games coming soon"
            : "\(lane.activities.count) game\(lane.activities.count == 1 ? "" : "s") ready"
        sections = [
            .visualSummary,
            lane.isReady ? .activities : .comingSoon,
            .modes,
            .playStyles,
            .ageEntries,
            .recall,
        ]
    }
}

extension LabActivityID {
    var sensorNeeds: [LabSensorNeed] {
        switch self {
        case .sumSprint, .rectangleFactory, .factoryCards, .twoFingerProtractor, .shapeGeometry, .waterCycle, .soundVolume, .memoryMatch, .countryCards, .fruitCards:
            return [.noSpecialSensor]
        case .symmetryFold, .angleCannon, .gravityArtist:
            return [.motion]
        case .roomQuest:
            return [.cameraMarkerMode, .haptics]
        case .compassAngles:
            return [.compass]
        }
    }

    func sensorAffordances(with capabilities: DeviceSensorCapabilities) -> [LabSensorAffordance] {
        sensorNeeds.map { $0.copy(with: capabilities) }
    }
}


struct CapabilityLaneProgress: Equatable {
    let laneID: CapabilityLaneID
    let availableModes: [PlayMode]
    var completedModes: Set<PlayMode>
    var reviewedCardIDs: Set<String>

    init(
        laneID: CapabilityLaneID,
        availableModes: [PlayMode],
        completedModes: Set<PlayMode> = [],
        reviewedCardIDs: Set<String> = []
    ) {
        self.laneID = laneID
        self.availableModes = availableModes
        self.completedModes = completedModes
        self.reviewedCardIDs = reviewedCardIDs
    }

    init(masteryState: LaneMasteryState) {
        self.init(
            laneID: masteryState.id,
            availableModes: masteryState.availableModes,
            completedModes: masteryState.completedModes,
            reviewedCardIDs: masteryState.reviewedCardIDs
        )
    }

    var completedModeCount: Int {
        availableModes.filter { completedModes.contains($0) }.count
    }

    var progressLabel: String {
        "\(completedModeCount) / \(availableModes.count) modes"
    }

    var masteryFraction: Double {
        guard !availableModes.isEmpty else { return 0 }
        return Double(completedModeCount) / Double(availableModes.count)
    }

    var masteryPercentLabel: String {
        "\(Int((masteryFraction * 100).rounded()))% ready"
    }

    var progressSummaryLabel: String {
        "🚀 \(completedModeCount)/\(availableModes.count) missions unlocked"
    }

    var nextRecommendedModeLabel: String {
        guard let nextRecommendedMode else { return "⭐ Choose any mission" }
        return completedModeCount == 0
            ? "⭐ First \(nextRecommendedMode.rawValue) mission waiting"
            : "⭐ Try \(nextRecommendedMode.rawValue) next"
    }

    var nextRecommendedMode: PlayMode? {
        availableModes.first { !completedModes.contains($0) } ?? availableModes.last
    }

    mutating func markCompleted(_ mode: PlayMode) {
        guard availableModes.contains(mode) else { return }
        completedModes.insert(mode)
    }

    mutating func markReviewed(_ card: MixMatchCard) {
        guard card.laneID == laneID else { return }
        reviewedCardIDs.insert(card.id)
    }
}

struct CapabilityLane: Identifiable, Equatable {
    let id: CapabilityLaneID
    let emoji: String
    let promise: String
    let ageBandHint: String
    let modes: [PlayMode]
    let ageEntries: [CapabilityAgeEntry]
    let activities: [LabActivity]

    var title: String { id.title }
    var isReady: Bool { !activities.isEmpty }

    var accessibilityLabel: String {
        "\(title). \(ageBandHint). \(promise)"
    }

    var accessibilityHint: String {
        isReady ? "Choose an activity or review cards." : "Activities are coming soon. Review cards are available."
    }

    var ageEntryPreview: String {
        ageEntries.prefix(2).map(\.summaryLabel).joined(separator: " • ")
    }

    var modeChoiceCards: [PlayModeChoiceCard] {
        TimerChallengePolicy.choiceCards(for: modes)
    }

    var modeChoicePreviewLabel: String {
        modeChoiceCards.prefix(2).map(\.summaryLabel).joined(separator: " • ")
    }

    var starterMixMatchCards: [MixMatchCard] {
        Self.starterMixMatchCardsByLane[id, default: []]
    }

    var recallEntries: [LaneRecallEntry] {
        Self.starterLearningCardProvider
            .starterCards(for: id)
            .map { LaneRecallEntry(laneID: id, card: $0) }
    }

    var firstRecallEntry: LaneRecallEntry? {
        recallEntries.first
    }

    var starterMixMatchCount: Int { starterMixMatchCards.count }

    var starterMixMatchConceptPreview: String {
        var seen: Set<String> = []
        let concepts = starterMixMatchCards.compactMap { card -> String? in
            guard !seen.contains(card.concept) else { return nil }
            seen.insert(card.concept)
            return card.concept
        }
        return concepts.prefix(3).joined(separator: " • ")
    }

    var recallReadinessLabel: String {
        let learningCardCount = recallEntries.count
        guard learningCardCount > 0 else {
            return "\(starterMixMatchCount) Mix-Match cards ready"
        }
        return "\(learningCardCount) recall card + \(starterMixMatchCount) Mix-Match ready"
    }

    var recallAccessibilityLabel: String {
        "\(title) recall. \(recallReadinessLabel). Concepts: \(starterMixMatchConceptPreview)"
    }

    var starterMixMatchSampler: MixMatchReviewSampler {
        MixMatchReviewSampler(laneID: id, cards: starterMixMatchCards)
    }

    var emptyProgress: CapabilityLaneProgress {
        CapabilityLaneProgress(laneID: id, availableModes: modes)
    }

    static let defaultExplorerLanes: [CapabilityLane] = [
        CapabilityLane(
            id: .numbers,
            emoji: "🔢",
            promise: "Build number bonds, fast facts, arrays, and whole-part thinking.",
            ageBandHint: "Ages 4–12",
            modes: [.learn, .challenge, .timed, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "count and pair", entryPlay: "Bond Blast pairs"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "CPA number bonds", entryPlay: "Make & Break"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "strategy and factors", entryPlay: "arrays and races"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "mastery and mental math", entryPlay: "personal-best challenges"),
            ],
            activities: [
                LabActivity(
                    id: .sumSprint,
                    emoji: "⚡",
                    title: "Sum Sprint",
                    tagline: "Race through sums 11–20",
                    modes: [.challenge, .timed, .review]
                ),
                LabActivity(
                    id: .rectangleFactory,
                    emoji: "🏭",
                    title: "Rectangle Factory",
                    tagline: "Drag frames to find factors",
                    modes: [.learn, .explore, .challenge]
                ),
                LabActivity(
                    id: .factoryCards,
                    emoji: "📦",
                    title: "Packing Cards",
                    tagline: "Practice equal rows first",
                    modes: [.learn, .review]
                ),
            ]
        ),
        CapabilityLane(
            id: .geometry,
            emoji: "📐",
            promise: "Fold, measure, aim, and transform shapes with touch and motion.",
            ageBandHint: "Ages 4–12",
            modes: [.learn, .explore, .challenge, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "shape discovery", entryPlay: "shape sort"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "fold and compare", entryPlay: "symmetry play"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "measure and transform", entryPlay: "angles and arrays"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "systems and coordinates", entryPlay: "puzzle challenges"),
            ],
            activities: [
                LabActivity(
                    id: .shapeGeometry,
                    emoji: "🔷",
                    title: "Shape Lab",
                    tagline: "Learn shape names, clues, and picture matches",
                    modes: [.learn, .review]
                ),
                LabActivity(
                    id: .symmetryFold,
                    emoji: "🪞",
                    title: "Symmetry Fold",
                    tagline: "Tilt to fold shapes in half",
                    modes: [.explore, .challenge]
                ),
                LabActivity(
                    id: .angleCannon,
                    emoji: "💥",
                    title: "Angle Cannon",
                    tagline: "Tilt to aim — hit the target",
                    modes: [.explore, .challenge, .timed]
                ),
                LabActivity(
                    id: .twoFingerProtractor,
                    emoji: "📐",
                    title: "Protractor",
                    tagline: "Spread two fingers to measure angles",
                    modes: [.learn, .explore]
                ),
            ]
        ),
        CapabilityLane(
            id: .physics,
            emoji: "🧪",
            promise: "Predict motion, gravity, water, sound, and cause-and-effect systems.",
            ageBandHint: "Ages 2–12",
            modes: [.explore, .challenge, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .toddler, posture: "cause and effect", entryPlay: "tap, drop, splash"),
                CapabilityAgeEntry(ageBand: .preschool, posture: "predict and observe", entryPlay: "roll and rain"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "forces and systems", entryPlay: "cannon strategy"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "model and explain", entryPlay: "energy puzzles"),
            ],
            activities: [
                LabActivity(
                    id: .gravityArtist,
                    emoji: "🎨",
                    title: "Gravity Artist",
                    tagline: "Predict where the ball lands",
                    modes: [.explore, .challenge]
                ),
                LabActivity(
                    id: .waterCycle,
                    emoji: "💧",
                    title: "Water Cycle Lab",
                    tagline: "Predict, make clouds, then rain",
                    modes: [.learn, .explore, .review]
                ),
                LabActivity(
                    id: .soundVolume,
                    emoji: "🔊",
                    title: "Sound Lab",
                    tagline: "Match quiet, noisy, and safe listening clues",
                    modes: [.learn, .review]
                ),
            ]
        ),
        CapabilityLane(
            id: .mapWorld,
            emoji: "🗺️",
            promise: "Use rooms, compass turns, direction words, and route clues.",
            ageBandHint: "Ages 4–12",
            modes: [.explore, .challenge, .timed, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "left/right and finding", entryPlay: "room clues"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "directions and turns", entryPlay: "compass walk"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "maps and scale", entryPlay: "route planning"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "coordinates and strategy", entryPlay: "map challenges"),
            ],
            activities: [
                LabActivity(
                    id: .roomQuest,
                    emoji: "🗺️",
                    title: "Room Quest",
                    tagline: "Collect tokens around the room",
                    modes: [.explore, .challenge]
                ),
                LabActivity(
                    id: .compassAngles,
                    emoji: "🧭",
                    title: "Compass Walk",
                    tagline: "Turn your body to match the angle",
                    modes: [.explore, .challenge, .timed]
                ),
                LabActivity(
                    id: .countryCards,
                    emoji: "🌍",
                    title: "Country Cards",
                    tagline: "Flashcards for capitals, flags, languages, currency, and continents",
                    modes: [.learn, .review, .challenge]
                ),
            ]
        ),
        CapabilityLane(
            id: .discoveryCards,
            emoji: "🃏",
            promise: "Practice names, pictures, categories, and Mix-Match recall.",
            ageBandHint: "Ages 2–12",
            modes: [.learn, .review, .challenge],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .toddler, posture: "name and notice", entryPlay: "big picture cards"),
                CapabilityAgeEntry(ageBand: .preschool, posture: "sort and match", entryPlay: "Mix-Match"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "facts and categories", entryPlay: "choice cards"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "explain and connect", entryPlay: "systems cards"),
            ],
            activities: [
                LabActivity(
                    id: .memoryMatch,
                    emoji: "🃏",
                    title: "Memory Match",
                    tagline: "Match pictures and words",
                    modes: [.learn, .review, .challenge]
                ),
            ]
        ),
        CapabilityLane(
            id: .chemistry,
            emoji: "⚗️",
            promise: "Future: sort materials, mix safely, and predict properties.",
            ageBandHint: "Future lane",
            modes: [.explore, .challenge, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "material sorting", entryPlay: "color and texture"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "states and mixtures", entryPlay: "mix and separate"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "properties and prediction", entryPlay: "safe reaction cards"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "families and systems", entryPlay: "property puzzles"),
            ],
            activities: [
                LabActivity(
                    id: .fruitCards,
                    emoji: "🍎",
                    title: "Fruit Cards",
                    tagline: "Match fruit shape, color, taste, smell, and where it is found",
                    modes: [.learn, .review, .challenge]
                ),
            ]
        ),
        CapabilityLane(
            id: .electronics,
            emoji: "💡",
            promise: "Future: switches, circuits, sensors, and input/output systems.",
            ageBandHint: "Future lane",
            modes: [.explore, .challenge, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "switch and output", entryPlay: "light on/off"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "circuits and components", entryPlay: "wire paths"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "debug and sensors", entryPlay: "input/output"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "logic and systems", entryPlay: "gate puzzles"),
            ],
            activities: []
        ),
    ]

    static let starterLearningCardProvider = DeterministicStarterLearningCardProvider()

    static let starterMixMatchCardsByLane: [CapabilityLaneID: [MixMatchCard]] = [
        .numbers: [
            MixMatchCard(laneID: .numbers, concept: "number-bond", prompt: "6 + 4", match: "10"),
            MixMatchCard(laneID: .numbers, concept: "number-bond", prompt: "7 + 3", match: "10"),
            MixMatchCard(laneID: .numbers, concept: "number-bond", prompt: "8 + 5", match: "13"),
            MixMatchCard(laneID: .numbers, concept: "dot-pattern", prompt: "five-frame full", match: "5"),
            MixMatchCard(laneID: .numbers, concept: "dot-pattern", prompt: "ten-frame 8 dots", match: "8"),
            MixMatchCard(laneID: .numbers, concept: "array", prompt: "3 rows of 4", match: "12"),
            MixMatchCard(laneID: .numbers, concept: "factor-pair", prompt: "2 × 6", match: "12"),
            MixMatchCard(laneID: .numbers, concept: "story-equation", prompt: "9 birds, 2 fly away", match: "9 − 2 = 7"),
        ],
        .geometry: [
            MixMatchCard(laneID: .geometry, concept: "shape", prompt: "3 sides", match: "triangle"),
            MixMatchCard(laneID: .geometry, concept: "shape", prompt: "4 equal sides", match: "square"),
            MixMatchCard(laneID: .geometry, concept: "symmetry", prompt: "butterfly fold", match: "line of symmetry"),
            MixMatchCard(laneID: .geometry, concept: "angle", prompt: "square corner", match: "90°"),
            MixMatchCard(laneID: .geometry, concept: "angle", prompt: "straight line", match: "180°"),
            MixMatchCard(laneID: .geometry, concept: "array-shape", prompt: "2 by 5 rectangle", match: "10 squares"),
            MixMatchCard(laneID: .geometry, concept: "transformation", prompt: "slide", match: "translation"),
            MixMatchCard(laneID: .geometry, concept: "transformation", prompt: "turn", match: "rotation"),
        ],
        .physics: [
            MixMatchCard(laneID: .physics, concept: "motion", prompt: "push harder", match: "moves faster"),
            MixMatchCard(laneID: .physics, concept: "motion", prompt: "steeper ramp", match: "rolls farther"),
            MixMatchCard(laneID: .physics, concept: "gravity", prompt: "drop ball", match: "falls down"),
            MixMatchCard(laneID: .physics, concept: "prediction", prompt: "aim higher", match: "lands farther"),
            MixMatchCard(laneID: .physics, concept: "water-cycle", prompt: "sun warms water", match: "evaporation"),
            MixMatchCard(laneID: .physics, concept: "water-cycle", prompt: "cloud gets heavy", match: "rain"),
            MixMatchCard(laneID: .physics, concept: "sound", prompt: "whisper", match: "quiet"),
            MixMatchCard(laneID: .physics, concept: "sound", prompt: "busy road", match: "noise pollution"),
            MixMatchCard(laneID: .physics, concept: "hearing-safety", prompt: "headphones", match: "keep volume low"),
            MixMatchCard(laneID: .physics, concept: "hearing-safety", prompt: "siren", match: "protect ears"),
            MixMatchCard(laneID: .physics, concept: "float-sink", prompt: "wood block", match: "float"),
            MixMatchCard(laneID: .physics, concept: "balance", prompt: "same weight both sides", match: "level"),
        ],
        .mapWorld: [
            MixMatchCard(laneID: .mapWorld, concept: "direction", prompt: "sunrise", match: "east"),
            MixMatchCard(laneID: .mapWorld, concept: "direction", prompt: "sunset", match: "west"),
            MixMatchCard(laneID: .mapWorld, concept: "turn", prompt: "quarter turn right", match: "90° clockwise"),
            MixMatchCard(laneID: .mapWorld, concept: "turn", prompt: "half turn", match: "180°"),
            MixMatchCard(laneID: .mapWorld, concept: "route", prompt: "start → clue → treasure", match: "path"),
            MixMatchCard(laneID: .mapWorld, concept: "map-symbol", prompt: "star on map", match: "special place"),
            MixMatchCard(laneID: .mapWorld, concept: "scale", prompt: "small map step", match: "big real step"),
            MixMatchCard(laneID: .mapWorld, concept: "compass", prompt: "N", match: "north"),
        ],
        .discoveryCards: [
            MixMatchCard(laneID: .discoveryCards, concept: "animal", prompt: "striped big cat", match: "tiger"),
            MixMatchCard(laneID: .discoveryCards, concept: "animal", prompt: "long-neck animal", match: "giraffe"),
            MixMatchCard(laneID: .discoveryCards, concept: "habitat", prompt: "fish home", match: "water"),
            MixMatchCard(laneID: .discoveryCards, concept: "category", prompt: "apple", match: "fruit"),
            MixMatchCard(laneID: .discoveryCards, concept: "category", prompt: "bus", match: "vehicle"),
            MixMatchCard(laneID: .discoveryCards, concept: "body", prompt: "we hear with", match: "ears"),
            MixMatchCard(laneID: .discoveryCards, concept: "world", prompt: "very cold place", match: "Arctic"),
            MixMatchCard(laneID: .discoveryCards, concept: "vocabulary", prompt: "tiny", match: "small"),
        ],
        .chemistry: [
            MixMatchCard(laneID: .chemistry, concept: "state", prompt: "ice", match: "solid"),
            MixMatchCard(laneID: .chemistry, concept: "state", prompt: "water", match: "liquid"),
            MixMatchCard(laneID: .chemistry, concept: "state", prompt: "steam", match: "gas"),
            MixMatchCard(laneID: .chemistry, concept: "property", prompt: "metal spoon", match: "shiny"),
            MixMatchCard(laneID: .chemistry, concept: "property", prompt: "sponge", match: "soaks water"),
            MixMatchCard(laneID: .chemistry, concept: "mixture", prompt: "sand + pebbles", match: "can separate"),
            MixMatchCard(laneID: .chemistry, concept: "mixture", prompt: "sugar + water", match: "dissolves"),
            MixMatchCard(laneID: .chemistry, concept: "safety", prompt: "unknown liquid", match: "ask grown-up"),
        ],
        .electronics: [
            MixMatchCard(laneID: .electronics, concept: "component", prompt: "battery", match: "power"),
            MixMatchCard(laneID: .electronics, concept: "component", prompt: "wire", match: "path"),
            MixMatchCard(laneID: .electronics, concept: "component", prompt: "switch", match: "open or close"),
            MixMatchCard(laneID: .electronics, concept: "output", prompt: "lamp", match: "light"),
            MixMatchCard(laneID: .electronics, concept: "circuit", prompt: "closed loop", match: "works"),
            MixMatchCard(laneID: .electronics, concept: "circuit", prompt: "broken loop", match: "off"),
            MixMatchCard(laneID: .electronics, concept: "sensor", prompt: "microphone", match: "hears sound"),
            MixMatchCard(laneID: .electronics, concept: "logic", prompt: "two switches both on", match: "AND"),
        ],
    ]

}

// MARK: - Lab concept session progress

struct LabGameplayCompletionContext: Codable, Equatable {
    let conceptPlanID: String
    let stage: GuidedLabStage

    init(conceptPlanID: String, stage: GuidedLabStage) {
        self.conceptPlanID = conceptPlanID
        self.stage = stage
    }

    init(plan: LabConceptSessionPlan, stage: GuidedLabStage) {
        self.init(conceptPlanID: plan.id, stage: stage)
    }
}

struct LabStageTimingScoreSummary: Codable, Equatable {
    let durationSeconds: TimeInterval?
    let scoreSummary: LabSessionScoreSummary?

    init(durationSeconds: TimeInterval? = nil, scoreSummary: LabSessionScoreSummary? = nil) {
        self.durationSeconds = durationSeconds
        self.scoreSummary = scoreSummary
    }
}

struct LabConceptSessionProgress: Codable, Equatable, Identifiable {
    let conceptPlanID: String
    var currentStage: GuidedLabStage
    private(set) var completedStages: [GuidedLabStage]
    var lastActivityAt: Date
    var stageSummaries: [GuidedLabStage: LabStageTimingScoreSummary]

    var id: String { conceptPlanID }
    var hasStarted: Bool { true }

    init(
        conceptPlanID: String,
        currentStage: GuidedLabStage,
        completedStages: [GuidedLabStage] = [],
        lastActivityAt: Date,
        stageSummaries: [GuidedLabStage: LabStageTimingScoreSummary] = [:]
    ) {
        self.conceptPlanID = conceptPlanID
        self.currentStage = currentStage
        self.completedStages = Self.uniqueStages(completedStages)
        self.lastActivityAt = lastActivityAt
        self.stageSummaries = stageSummaries
    }

    init(plan: LabConceptSessionPlan, startedAt: Date) {
        self.init(
            conceptPlanID: plan.id,
            currentStage: plan.stageOrder.first ?? .learn,
            lastActivityAt: startedAt
        )
    }

    var resumeCopy: String {
        if completedStages.isEmpty {
            return "Continue: \(currentStage.rawValue)"
        }
        return "Continue: \(currentStage.rawValue) next"
    }

    func currentStagePlan(in plan: LabConceptSessionPlan) -> LabSessionStagePlan? {
        plan.stages.first { $0.stage == currentStage }
    }

    func nextIncompleteStage(in plan: LabConceptSessionPlan) -> GuidedLabStage? {
        plan.stageOrder.first { !completedStages.contains($0) }
    }

    mutating func markLaunched(_ stage: GuidedLabStage, in plan: LabConceptSessionPlan, at date: Date) {
        guard plan.stageOrder.contains(stage) else { return }
        currentStage = stage
        lastActivityAt = date
    }

    mutating func markCompleted(
        _ stage: GuidedLabStage,
        in plan: LabConceptSessionPlan,
        at date: Date,
        summary: LabStageTimingScoreSummary? = nil
    ) {
        guard plan.stageOrder.contains(stage) else { return }
        if !completedStages.contains(stage) {
            completedStages.append(stage)
        }
        completedStages = plan.stageOrder.filter { completedStages.contains($0) }
        if let summary {
            stageSummaries[stage] = summary
        }
        currentStage = nextIncompleteStage(in: plan) ?? stage
        lastActivityAt = date
    }

    private static func uniqueStages(_ stages: [GuidedLabStage]) -> [GuidedLabStage] {
        var seen = Set<GuidedLabStage>()
        return stages.filter { seen.insert($0).inserted }
    }
}
