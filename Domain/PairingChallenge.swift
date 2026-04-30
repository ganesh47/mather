import Foundation

enum PairingChallengeKind: String, Codable, Equatable, Hashable {
    case numberBond
    case geometry
    case physics
    case mapWorld
}

struct PairingChallengeItem<ID: Codable & Hashable>: Identifiable, Codable, Equatable, Hashable {
    let id: ID
    let title: String
    let spokenPrompt: String
    let symbol: String?

    init(id: ID, title: String, spokenPrompt: String, symbol: String? = nil) {
        self.id = id
        self.title = title
        self.spokenPrompt = spokenPrompt
        self.symbol = symbol
    }
}

struct PairingChallengePair<ID: Codable & Hashable>: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let leftID: ID
    let rightID: ID
    let successPrompt: String

    init(id: String, leftID: ID, rightID: ID, successPrompt: String) {
        self.id = id
        self.leftID = leftID
        self.rightID = rightID
        self.successPrompt = successPrompt
    }

    var key: PairingChallengePairKey<ID> {
        PairingChallengePairKey(leftID: leftID, rightID: rightID)
    }
}

struct PairingChallengePairKey<ID: Codable & Hashable>: Codable, Equatable, Hashable {
    let leftID: ID
    let rightID: ID
}

struct PairingChallengeTimerConfig: Equatable {
    let playMode: PlayMode
    let policy: TimerChallengePolicy

    init(playMode: PlayMode = .challenge, policy: TimerChallengePolicy? = nil) {
        self.playMode = playMode
        self.policy = policy ?? TimerChallengePolicy.policy(for: playMode)
    }

    var usesTimer: Bool {
        policy.usesTimer
    }

    var durationSeconds: Int? {
        policy.timerSeconds
    }
}

struct PairingChallengeConfig: Equatable {
    let kind: PairingChallengeKind
    let timer: PairingChallengeTimerConfig
    let startPrompt: String
    let completionPrompt: String
    let retryPrompt: String

    init(
        kind: PairingChallengeKind,
        timer: PairingChallengeTimerConfig = PairingChallengeTimerConfig(),
        startPrompt: String = "Find the pairs.",
        completionPrompt: String? = nil,
        retryPrompt: String = "Try another pair."
    ) {
        self.kind = kind
        self.timer = timer
        self.startPrompt = startPrompt
        self.completionPrompt = completionPrompt ?? timer.policy.completionMessage
        self.retryPrompt = retryPrompt
    }
}

struct PairingChallenge<ID: Codable & Hashable>: Identifiable, Equatable {
    let id: String
    let title: String
    let config: PairingChallengeConfig
    let leftItems: [PairingChallengeItem<ID>]
    let rightItems: [PairingChallengeItem<ID>]
    let pairs: [PairingChallengePair<ID>]

    init(
        id: String,
        title: String,
        config: PairingChallengeConfig,
        leftItems: [PairingChallengeItem<ID>],
        rightItems: [PairingChallengeItem<ID>],
        pairs: [PairingChallengePair<ID>]
    ) {
        self.id = id
        self.title = title
        self.config = config
        self.leftItems = leftItems
        self.rightItems = rightItems
        self.pairs = pairs
    }

    func pair(leftID: ID, rightID: ID) -> PairingChallengePair<ID>? {
        pairs.first { $0.leftID == leftID && $0.rightID == rightID }
    }

    func containsLeftItem(_ id: ID) -> Bool {
        leftItems.contains { $0.id == id }
    }

    func containsRightItem(_ id: ID) -> Bool {
        rightItems.contains { $0.id == id }
    }
}

enum PairingChallengeFeedback: Equatable {
    case ready(String)
    case matched(String)
    case tryAgain(String)
    case alreadyMatched(String)
    case completed(String)
    case timeExpired(String)

    var spokenPrompt: String {
        switch self {
        case let .ready(prompt),
             let .matched(prompt),
             let .tryAgain(prompt),
             let .alreadyMatched(prompt),
             let .completed(prompt),
             let .timeExpired(prompt):
            return prompt
        }
    }
}

enum PairingChallengeHapticCue: Equatable {
    case none
    case pickup
    case match
    case mismatch
    case complete
}

enum PairingChallengeAttemptResult: Equatable {
    case matched
    case mismatch
    case alreadyMatched
    case unknownItem
    case completed
    case timeExpired
}

struct PairingChallengeAttemptOutcome<ID: Codable & Hashable>: Equatable {
    let result: PairingChallengeAttemptResult
    let pairID: String?
    let selectedKey: PairingChallengePairKey<ID>
    let feedback: PairingChallengeFeedback
    let hapticCue: PairingChallengeHapticCue
}

struct PairingChallengeSession<ID: Codable & Hashable>: Equatable {
    let challenge: PairingChallenge<ID>
    private(set) var matchedPairs: Set<PairingChallengePairKey<ID>>
    private(set) var attemptCount: Int
    private(set) var timerStarted: Bool
    private(set) var timerExpired: Bool
    private(set) var feedback: PairingChallengeFeedback

    init(challenge: PairingChallenge<ID>) {
        self.challenge = challenge
        self.matchedPairs = []
        self.attemptCount = 0
        self.timerStarted = false
        self.timerExpired = false
        self.feedback = .ready(challenge.config.startPrompt)
    }

    var matchCount: Int {
        matchedPairs.count
    }

    var isComplete: Bool {
        matchCount == challenge.pairs.count
    }

    var remainingPairCount: Int {
        max(challenge.pairs.count - matchCount, 0)
    }

    mutating func startTimerIfNeeded() {
        guard challenge.config.timer.usesTimer else { return }
        timerStarted = true
    }

    mutating func expireTimer() -> PairingChallengeFeedback? {
        guard challenge.config.timer.usesTimer, !isComplete else { return nil }
        timerExpired = true
        let prompt = challenge.config.timer.policy.timeExpiredMessage ?? "Time is up. Try another round."
        feedback = .timeExpired(prompt)
        return feedback
    }

    mutating func attempt(leftID: ID, rightID: ID) -> PairingChallengeAttemptOutcome<ID> {
        if challenge.config.timer.usesTimer {
            timerStarted = true
        }

        let selectedKey = PairingChallengePairKey(leftID: leftID, rightID: rightID)

        guard !timerExpired else {
            let prompt = challenge.config.timer.policy.timeExpiredMessage ?? "Time is up. Try another round."
            feedback = .timeExpired(prompt)
            return PairingChallengeAttemptOutcome(
                result: .timeExpired,
                pairID: nil,
                selectedKey: selectedKey,
                feedback: feedback,
                hapticCue: .none
            )
        }

        guard challenge.containsLeftItem(leftID), challenge.containsRightItem(rightID) else {
            feedback = .tryAgain(challenge.config.retryPrompt)
            return PairingChallengeAttemptOutcome(
                result: .unknownItem,
                pairID: nil,
                selectedKey: selectedKey,
                feedback: feedback,
                hapticCue: .mismatch
            )
        }

        guard let pair = challenge.pair(leftID: leftID, rightID: rightID) else {
            attemptCount += 1
            feedback = .tryAgain(challenge.config.retryPrompt)
            return PairingChallengeAttemptOutcome(
                result: .mismatch,
                pairID: nil,
                selectedKey: selectedKey,
                feedback: feedback,
                hapticCue: .mismatch
            )
        }

        guard !matchedPairs.contains(pair.key) else {
            feedback = .alreadyMatched("That pair is already together.")
            return PairingChallengeAttemptOutcome(
                result: .alreadyMatched,
                pairID: pair.id,
                selectedKey: selectedKey,
                feedback: feedback,
                hapticCue: .none
            )
        }

        attemptCount += 1
        matchedPairs.insert(pair.key)

        if isComplete {
            feedback = .completed(challenge.config.completionPrompt)
            return PairingChallengeAttemptOutcome(
                result: .completed,
                pairID: pair.id,
                selectedKey: selectedKey,
                feedback: feedback,
                hapticCue: .complete
            )
        }

        feedback = .matched(pair.successPrompt)
        return PairingChallengeAttemptOutcome(
            result: .matched,
            pairID: pair.id,
            selectedKey: selectedKey,
            feedback: feedback,
            hapticCue: .match
        )
    }
}

extension PairingChallenge where ID == String {
    static func numberBonds(target: Int, playMode: PlayMode = .challenge) -> PairingChallenge<String> {
        let leftValues = target >= 2 ? (1...(target - 1)).filter { $0 <= target - $0 } : []
        let leftItems = leftValues.map { value in
            PairingChallengeItem(id: "left-\(value)", title: "\(value)", spokenPrompt: "\(value)")
        }
        let rightItems = leftValues.map { value in
            let complement = target - value
            return PairingChallengeItem(
                id: "right-\(complement)",
                title: "\(complement)",
                spokenPrompt: "\(complement)"
            )
        }
        let pairs = leftValues.map { value in
            let complement = target - value
            return PairingChallengePair(
                id: "bond-\(value)-\(complement)",
                leftID: "left-\(value)",
                rightID: "right-\(complement)",
                successPrompt: "\(value) and \(complement) make \(target)."
            )
        }

        return PairingChallenge(
            id: "number-bonds-\(target)",
            title: "Make \(target)",
            config: PairingChallengeConfig(
                kind: .numberBond,
                timer: PairingChallengeTimerConfig(playMode: playMode),
                startPrompt: "Find pairs that make \(target)."
            ),
            leftItems: leftItems,
            rightItems: rightItems,
            pairs: pairs
        )
    }

    static func geometryShapes(playMode: PlayMode = .challenge) -> PairingChallenge<String> {
        PairingChallenge(
            id: "geometry-shapes",
            title: "Shape Pairs",
            config: PairingChallengeConfig(
                kind: .geometry,
                timer: PairingChallengeTimerConfig(playMode: playMode),
                startPrompt: "Match each shape to what you notice."
            ),
            leftItems: [
                PairingChallengeItem(id: "circle", title: "Circle", spokenPrompt: "Circle", symbol: "circle"),
                PairingChallengeItem(id: "triangle", title: "Triangle", spokenPrompt: "Triangle", symbol: "triangle"),
                PairingChallengeItem(id: "square", title: "Square", spokenPrompt: "Square", symbol: "square")
            ],
            rightItems: [
                PairingChallengeItem(id: "round", title: "Round", spokenPrompt: "Round"),
                PairingChallengeItem(id: "three-sides", title: "3 sides", spokenPrompt: "Three sides"),
                PairingChallengeItem(id: "four-sides", title: "4 sides", spokenPrompt: "Four sides")
            ],
            pairs: [
                PairingChallengePair(id: "circle-round", leftID: "circle", rightID: "round", successPrompt: "A circle is round."),
                PairingChallengePair(id: "triangle-three", leftID: "triangle", rightID: "three-sides", successPrompt: "A triangle has three sides."),
                PairingChallengePair(id: "square-four", leftID: "square", rightID: "four-sides", successPrompt: "A square has four sides.")
            ]
        )
    }

    static func physicsCauseEffect(playMode: PlayMode = .challenge) -> PairingChallenge<String> {
        PairingChallenge(
            id: "physics-cause-effect",
            title: "What Happens?",
            config: PairingChallengeConfig(
                kind: .physics,
                timer: PairingChallengeTimerConfig(playMode: playMode),
                startPrompt: "Match each action to what happens."
            ),
            leftItems: [
                PairingChallengeItem(id: "push", title: "Push", spokenPrompt: "Push"),
                PairingChallengeItem(id: "drop", title: "Drop", spokenPrompt: "Drop"),
                PairingChallengeItem(id: "tilt", title: "Tilt", spokenPrompt: "Tilt")
            ],
            rightItems: [
                PairingChallengeItem(id: "moves", title: "Moves away", spokenPrompt: "Moves away"),
                PairingChallengeItem(id: "falls", title: "Falls down", spokenPrompt: "Falls down"),
                PairingChallengeItem(id: "rolls", title: "Rolls", spokenPrompt: "Rolls")
            ],
            pairs: [
                PairingChallengePair(id: "push-moves", leftID: "push", rightID: "moves", successPrompt: "A push can move it away."),
                PairingChallengePair(id: "drop-falls", leftID: "drop", rightID: "falls", successPrompt: "When you drop it, it falls down."),
                PairingChallengePair(id: "tilt-rolls", leftID: "tilt", rightID: "rolls", successPrompt: "A tilt can make it roll.")
            ]
        )
    }

    static func mapPlaces(playMode: PlayMode = .challenge) -> PairingChallenge<String> {
        PairingChallenge(
            id: "map-places",
            title: "Map Pairs",
            config: PairingChallengeConfig(
                kind: .mapWorld,
                timer: PairingChallengeTimerConfig(playMode: playMode),
                startPrompt: "Match each map clue to its place."
            ),
            leftItems: [
                PairingChallengeItem(id: "river", title: "River", spokenPrompt: "River"),
                PairingChallengeItem(id: "mountain", title: "Mountain", spokenPrompt: "Mountain"),
                PairingChallengeItem(id: "road", title: "Road", spokenPrompt: "Road")
            ],
            rightItems: [
                PairingChallengeItem(id: "blue-line", title: "Blue line", spokenPrompt: "Blue line"),
                PairingChallengeItem(id: "triangle-peak", title: "Triangle peak", spokenPrompt: "Triangle peak"),
                PairingChallengeItem(id: "path", title: "Path", spokenPrompt: "Path")
            ],
            pairs: [
                PairingChallengePair(id: "river-blue", leftID: "river", rightID: "blue-line", successPrompt: "A river is often a blue line on a map."),
                PairingChallengePair(id: "mountain-peak", leftID: "mountain", rightID: "triangle-peak", successPrompt: "A mountain can be shown with a peak."),
                PairingChallengePair(id: "road-path", leftID: "road", rightID: "path", successPrompt: "A road is a path people can follow.")
            ]
        )
    }
}
