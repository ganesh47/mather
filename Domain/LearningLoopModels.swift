import AVFoundation
import Foundation

/// Reusable deterministic content for learn → quiz → match loops.
struct LearningConceptCard: Identifiable, Equatable {
    let id: String
    let title: String
    let explanation: String
    let visualKey: String
    let audioPrompt: String
    let soundExample: SoundExampleKind?

    init(
        id: String,
        title: String,
        explanation: String,
        visualKey: String,
        audioPrompt: String? = nil,
        soundExample: SoundExampleKind? = nil
    ) {
        self.id = id
        self.title = title
        self.explanation = explanation
        self.visualKey = visualKey
        self.audioPrompt = audioPrompt ?? "Learn about \(title)."
        self.soundExample = soundExample
    }
}

struct SoundExamplePlaybackProfile: Equatable {
    let durationSeconds: Double
    let peakAmplitude: Double
    let primaryFrequency: Double
    let secondaryFrequency: Double?

    init(durationSeconds: Double, peakAmplitude: Double, primaryFrequency: Double, secondaryFrequency: Double? = nil) {
        self.durationSeconds = min(max(durationSeconds, 0.12), SoundExampleKind.hearingSafeMaximumDurationSeconds)
        self.peakAmplitude = min(max(peakAmplitude, 0.01), SoundExampleKind.hearingSafeMaximumPeakAmplitude)
        self.primaryFrequency = primaryFrequency
        self.secondaryFrequency = secondaryFrequency
    }
}

enum SoundExampleKind: String, CaseIterable, Equatable {
    case decibelPulse
    case quietChime
    case conversationPulse
    case trafficRumble
    case sirenSweep
    case headphonesLow
    case pleasantBirds
    case noisyBurst
    case protectEarsMuffle

    static let hearingSafeMaximumDurationSeconds = 0.65
    static let hearingSafeMaximumPeakAmplitude = 0.18

    var label: String {
        switch self {
        case .decibelPulse: return "dB pulse"
        case .quietChime: return "quiet chime"
        case .conversationPulse: return "talking pulse"
        case .trafficRumble: return "traffic rumble"
        case .sirenSweep: return "soft siren sweep"
        case .headphonesLow: return "low headphone tone"
        case .pleasantBirds: return "bird chirp"
        case .noisyBurst: return "short noise burst"
        case .protectEarsMuffle: return "muffled warning"
        }
    }

    var accessibilityLabel: String {
        "Play hearing-safe \(label) example"
    }

    var profile: SoundExamplePlaybackProfile {
        switch self {
        case .decibelPulse:
            return SoundExamplePlaybackProfile(durationSeconds: 0.38, peakAmplitude: 0.12, primaryFrequency: 660, secondaryFrequency: 880)
        case .quietChime:
            return SoundExamplePlaybackProfile(durationSeconds: 0.46, peakAmplitude: 0.08, primaryFrequency: 523.25, secondaryFrequency: 659.25)
        case .conversationPulse:
            return SoundExamplePlaybackProfile(durationSeconds: 0.52, peakAmplitude: 0.11, primaryFrequency: 220, secondaryFrequency: 330)
        case .trafficRumble:
            return SoundExamplePlaybackProfile(durationSeconds: 0.48, peakAmplitude: 0.13, primaryFrequency: 110, secondaryFrequency: 165)
        case .sirenSweep:
            return SoundExamplePlaybackProfile(durationSeconds: 0.50, peakAmplitude: 0.12, primaryFrequency: 520, secondaryFrequency: 860)
        case .headphonesLow:
            return SoundExamplePlaybackProfile(durationSeconds: 0.42, peakAmplitude: 0.09, primaryFrequency: 440, secondaryFrequency: 554.37)
        case .pleasantBirds:
            return SoundExamplePlaybackProfile(durationSeconds: 0.50, peakAmplitude: 0.10, primaryFrequency: 980, secondaryFrequency: 1320)
        case .noisyBurst:
            return SoundExamplePlaybackProfile(durationSeconds: 0.32, peakAmplitude: 0.10, primaryFrequency: 260, secondaryFrequency: 520)
        case .protectEarsMuffle:
            return SoundExamplePlaybackProfile(durationSeconds: 0.44, peakAmplitude: 0.08, primaryFrequency: 320, secondaryFrequency: 180)
        }
    }
}

struct ConceptQuizQuestion: Identifiable, Equatable {
    let id: String
    let prompt: String
    let choices: [String]
    let correctChoice: String
    let feedback: String

    init(id: String, prompt: String, choices: [String], correctChoice: String, feedback: String) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctChoice = correctChoice
        self.feedback = feedback
    }

    func isCorrect(_ choice: String) -> Bool {
        choice == correctChoice
    }
}

struct ConceptMatchPair: Identifiable, Equatable {
    let id: String
    let left: String
    let right: String
    let feedback: String
    let leftVisualKey: String?
    let rightVisualKey: String?

    init(
        id: String,
        left: String,
        right: String,
        feedback: String,
        leftVisualKey: String? = nil,
        rightVisualKey: String? = nil
    ) {
        self.id = id
        self.left = left
        self.right = right
        self.feedback = feedback
        self.leftVisualKey = leftVisualKey
        self.rightVisualKey = rightVisualKey
    }
}

enum ConceptMatchAttempt: Equatable {
    case locked(pairId: String, feedback: String)
    case mismatch(feedback: String)
    case alreadyMatched
    case missingSelection
}

struct ConceptMatchRowOrder: Equatable {
    let leftPairIds: [String]
    let rightPairIds: [String]
}

struct LearningLoopSeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var result = state
        result = (result ^ (result >> 30)) &* 0xBF58476D1CE4E5B9
        result = (result ^ (result >> 27)) &* 0x94D049BB133111EB
        return result ^ (result >> 31)
    }
}

struct LearningLoopSummary: Equatable {
    let quizCorrect: Int
    let quizTotal: Int
    let matchedPairs: Int
    let totalPairs: Int

    var starCount: Int {
        guard quizTotal + totalPairs > 0 else { return 0 }
        let earned = quizCorrect + matchedPairs
        let possible = quizTotal + totalPairs
        switch Double(earned) / Double(possible) {
        case 0.85...: return 3
        case 0.55...: return 2
        case 0.01...: return 1
        default: return 0
        }
    }
}

enum LearningLoopScoring {
    static func scoreQuiz(questions: [ConceptQuizQuestion], answersByQuestionId: [String: String]) -> Int {
        questions.reduce(0) { score, question in
            guard let answer = answersByQuestionId[question.id] else { return score }
            return score + (question.isCorrect(answer) ? 1 : 0)
        }
    }

    static func isMatch(left: String, right: String, pairs: [ConceptMatchPair]) -> Bool {
        pairs.contains { $0.left == left && $0.right == right }
    }

    static func matchAttempt(
        selectedPairId: String?,
        targetPairId: String,
        pairs: [ConceptMatchPair],
        matchedPairIds: Set<String>
    ) -> ConceptMatchAttempt {
        guard let selectedPairId else { return .missingSelection }
        guard !matchedPairIds.contains(selectedPairId), !matchedPairIds.contains(targetPairId) else {
            return .alreadyMatched
        }
        guard selectedPairId == targetPairId, let pair = pairs.first(where: { $0.id == targetPairId }) else {
            return .mismatch(feedback: "Not that pair yet — try another match.")
        }
        return .locked(pairId: pair.id, feedback: pair.feedback)
    }

    static func shuffledMatchRowOrder(pairs: [ConceptMatchPair], seed: UInt64) -> ConceptMatchRowOrder {
        var leftGenerator = LearningLoopSeededRandomGenerator(seed: seed)
        var rightGenerator = LearningLoopSeededRandomGenerator(seed: seed ^ 0xD1B54A32D192ED03)
        return ConceptMatchRowOrder(
            leftPairIds: pairs.map(\.id).shuffled(using: &leftGenerator),
            rightPairIds: pairs.map(\.id).shuffled(using: &rightGenerator)
        )
    }

    static func orderedMatchRowOrder(pairs: [ConceptMatchPair]) -> ConceptMatchRowOrder {
        ConceptMatchRowOrder(leftPairIds: pairs.map(\.id), rightPairIds: pairs.map(\.id))
    }

    static func summary(
        questions: [ConceptQuizQuestion],
        answersByQuestionId: [String: String],
        matchedPairIds: Set<String>,
        pairs: [ConceptMatchPair]
    ) -> LearningLoopSummary {
        LearningLoopSummary(
            quizCorrect: scoreQuiz(questions: questions, answersByQuestionId: answersByQuestionId),
            quizTotal: questions.count,
            matchedPairs: matchedPairIds.count,
            totalPairs: pairs.count
        )
    }
}

enum SoundLoudnessZone: String, CaseIterable, Equatable {
    case quiet
    case normal
    case loud
    case tooLoud

    var label: String {
        switch self {
        case .quiet: return "Quiet"
        case .normal: return "Normal talking"
        case .loud: return "Loud"
        case .tooLoud: return "Too loud"
        }
    }

    var estimatedRangeLabel: String {
        switch self {
        case .quiet: return "about 30–40 dB"
        case .normal: return "about 55–65 dB"
        case .loud: return "about 70–85 dB"
        case .tooLoud: return "90 dB or more"
        }
    }

    var safetyCopy: String {
        switch self {
        case .quiet:
            return "Soft sounds are gentle for ears."
        case .normal:
            return "Talking voice is a safe middle zone."
        case .loud:
            return "Loud places can feel tiring — take breaks."
        case .tooLoud:
            return "Move away, lower the volume, or protect your ears."
        }
    }
}


enum SoundMeterPermissionState: String, Equatable {
    case notStarted
    case requestingPermission
    case listening
    case unavailable
    case denied

    var title: String {
        switch self {
        case .notStarted: return "Meter off"
        case .requestingPermission: return "Microphone check"
        case .listening: return "Meter listening"
        case .unavailable: return "Microphone unavailable"
        case .denied: return "Microphone off"
        }
    }

    var guidance: String {
        switch self {
        case .notStarted:
            return "Start only when a grown-up says it is okay. Mather reads a local loudness number and does not record audio."
        case .requestingPermission:
            return "Mather is checking microphone access. If it is off, Sound Lab still works in no-mic learning mode."
        case .listening:
            return "Use normal room sounds only. Do not shout — quieter is safer."
        case .unavailable:
            return "This device cannot read the microphone right now. You can still learn with the safe example cards."
        case .denied:
            return "Microphone access is off. Mather will keep the Sound Lab in no-mic learning mode."
        }
    }
}

enum SoundMeterMicrophoneAuthorization: Equatable {
    case undetermined
    case denied
    case granted
    case unknown
}


enum SoundMeterStartupPhase: String, Equatable {
    case idle
    case preflight
    case requestingPermission
    case permissionDenied
    case activatingSession
    case sessionActivationFailed
    case routeUnavailable
    case checkingInputFormat
    case inputFormatUnavailable
    case installingAudioTap
    case startingAudioEngine
    case engineStartFailed
    case preparingRecorder
    case recorderStartFailed
    case listening
}

enum SoundMeterStartupFailure: String, Equatable {
    case permissionDenied
    case sessionActivation
    case routeUnavailable
    case inputFormatUnavailable
    case engineStart
    case recorderStart
}

struct SoundMeterAudioFormatSnapshot: Equatable {
    let sampleRate: Double
    let channelCount: UInt32
    let commonFormat: AVAudioCommonFormat
    let isInterleaved: Bool

    init(sampleRate: Double, channelCount: UInt32, commonFormat: AVAudioCommonFormat = .pcmFormatFloat32, isInterleaved: Bool = false) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.commonFormat = commonFormat
        self.isInterleaved = isInterleaved
    }

    init(format: AVAudioFormat) {
        self.sampleRate = format.sampleRate
        self.channelCount = format.channelCount
        self.commonFormat = format.commonFormat
        self.isInterleaved = format.isInterleaved
    }

    var isUsableForAudioTap: Bool {
        sampleRate.isFinite
            && sampleRate > 0
            && channelCount > 0
            && commonFormat == .pcmFormatFloat32
            && !isInterleaved
    }
}

struct SoundMeterStartupDiagnostics: Equatable {
    let phase: SoundMeterStartupPhase
    let authorization: SoundMeterMicrophoneAuthorization?
    let isInputAvailable: Bool?
    let routeInputCount: Int?
    let inputSampleRate: Double?
    let inputChannelCount: UInt32?
    let failure: SoundMeterStartupFailure?

    init(
        phase: SoundMeterStartupPhase = .idle,
        authorization: SoundMeterMicrophoneAuthorization? = nil,
        isInputAvailable: Bool? = nil,
        routeInputCount: Int? = nil,
        inputSampleRate: Double? = nil,
        inputChannelCount: UInt32? = nil,
        failure: SoundMeterStartupFailure? = nil
    ) {
        self.phase = phase
        self.authorization = authorization
        self.isInputAvailable = isInputAvailable
        self.routeInputCount = routeInputCount
        self.inputSampleRate = inputSampleRate
        self.inputChannelCount = inputChannelCount
        self.failure = failure
    }

    func updating(
        phase: SoundMeterStartupPhase? = nil,
        routeInputCount: Int? = nil,
        format: SoundMeterAudioFormatSnapshot? = nil,
        failure: SoundMeterStartupFailure? = nil
    ) -> SoundMeterStartupDiagnostics {
        SoundMeterStartupDiagnostics(
            phase: phase ?? self.phase,
            authorization: authorization,
            isInputAvailable: isInputAvailable,
            routeInputCount: routeInputCount ?? self.routeInputCount,
            inputSampleRate: format?.sampleRate ?? inputSampleRate,
            inputChannelCount: format?.channelCount ?? inputChannelCount,
            failure: failure ?? self.failure
        )
    }
}

enum SoundMeterStartupDecision: Equatable {
    case requestPermission
    case startMeter
    case fail(SoundMeterPermissionState)
}

struct SoundMeterStartupPreflight: Equatable {
    let isInputAvailable: Bool
    let authorization: SoundMeterMicrophoneAuthorization

    func startupDecision() -> SoundMeterStartupDecision {
        guard isInputAvailable else { return .fail(.unavailable) }

        switch authorization {
        case .undetermined:
            return .requestPermission
        case .granted:
            return .startMeter
        case .denied:
            return .fail(.denied)
        case .unknown:
            return .fail(.unavailable)
        }
    }
}

enum SoundMeterLevelBucket: String, CaseIterable, Equatable {
    case quiet
    case comfortable
    case busy
    case protect

    var label: String {
        switch self {
        case .quiet: return "Quiet"
        case .comfortable: return "Comfortable"
        case .busy: return "Busy"
        case .protect: return "Protect ears"
        }
    }

    var targetCopy: String {
        switch self {
        case .quiet: return "Soft room sounds. Great for reading."
        case .comfortable: return "Normal talking zone. Keep it easy."
        case .busy: return "Busy room. Take breaks if it feels tiring."
        case .protect: return "Too much sound. Move away, lower volume, or cover ears."
        }
    }

    var fillFraction: Double {
        switch self {
        case .quiet: return 0.22
        case .comfortable: return 0.46
        case .busy: return 0.70
        case .protect: return 0.92
        }
    }
}

struct SoundMeterReading: Equatable {
    let rms: Float
    let estimatedDecibels: Double
    let bucket: SoundMeterLevelBucket

    static let privacyCopy = "Local microphone meter only: Mather computes an RMS loudness number on this device, stores no audio, and sends no audio anywhere."
    static let safetyCopy = "Use normal room sounds. Do not shout, scream, or try to make the meter higher. Quieter is safer."

    var roundedEstimatedDecibels: Int {
        Int(estimatedDecibels.rounded())
    }

    init(rms: Float) {
        let clampedRMS = SoundMeterReading.normalizedRMS(rms)
        self.rms = clampedRMS
        self.estimatedDecibels = SoundMeterReading.estimatedDecibels(forRMS: clampedRMS)
        self.bucket = SoundMeterReading.bucket(forRMS: clampedRMS)
    }

    static func estimatedDecibels(forRMS rms: Float) -> Double {
        let normalized = normalizedRMS(rms)
        let clamped = max(Double(normalized), 0.000_001)
        let decibels = 20 * log10(clamped) + 94
        guard decibels.isFinite else { return 20 }
        return min(max(decibels, 20), 100)
    }

    static func bucket(forRMS rms: Float) -> SoundMeterLevelBucket {
        let db = estimatedDecibels(forRMS: rms)
        switch db {
        case ..<50: return .quiet
        case ..<70: return .comfortable
        case ..<85: return .busy
        default: return .protect
        }
    }

    static func rms(fromDecibelFS decibelFS: Float) -> Float {
        guard decibelFS.isFinite else { return 0 }
        return normalizedRMS(pow(10, decibelFS / 20))
    }

    private static func normalizedRMS(_ rms: Float) -> Float {
        guard rms.isFinite else { return rms == .infinity ? 1 : 0 }
        return min(max(rms, 0), 1)
    }
}

enum SoundPitchBand: String, CaseIterable, Equatable, Identifiable {
    case low
    case middle
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "Low pitch"
        case .middle: return "Middle pitch"
        case .high: return "High pitch"
        }
    }

    var visualKey: String {
        switch self {
        case .low: return "🐘"
        case .middle: return "🎵"
        case .high: return "🐦"
        }
    }

    var teachingCopy: String {
        switch self {
        case .low: return "Low pitch sounds deep, like a drum or a big animal."
        case .middle: return "Middle pitch sits near many singing and talking notes."
        case .high: return "High pitch sounds bright, like a tiny bell or bird chirp."
        }
    }

    var frequencyRangeLabel: String {
        switch self {
        case .low: return "about 80–250 Hz"
        case .middle: return "about 250–900 Hz"
        case .high: return "about 900 Hz or more"
        }
    }
}

struct SoundPitchChallenge: Identifiable, Equatable {
    let id: String
    let prompt: String
    let correctBand: SoundPitchBand
    let options: [SoundPitchBand]
    let feedback: String

    func isCorrect(_ band: SoundPitchBand) -> Bool {
        band == correctBand
    }
}

struct SoundPitchChallengeState: Equatable {
    let challenge: SoundPitchChallenge
    var selectedBand: SoundPitchBand?

    var isAnswered: Bool { selectedBand != nil }
    var isCorrect: Bool { selectedBand.map(challenge.isCorrect) ?? false }

    var feedback: String {
        guard let selectedBand else { return "Tap the pitch you think matches. No microphone is needed for this part." }
        return challenge.isCorrect(selectedBand) ? challenge.feedback : "Not that one yet — listen for whether the sound is deep, middle, or bright."
    }

    mutating func select(_ band: SoundPitchBand) {
        selectedBand = band
    }
}

struct SoundVolumeIntroPage: Identifiable, Equatable {
    let id: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let visualKey: String
    let primaryActionTitle: String
    let primaryActionIcon: String
}

enum SoundVolumeContent {
    static let safetyNote = "Use hearing-safe clues only — no screaming, no shouting, and no points for loudness. Protect your ears."

    static func clampedIntroPageIndex(_ index: Int) -> Int {
        min(max(index, 0), introPages.count - 1)
    }

    static func introPage(for index: Int) -> SoundVolumeIntroPage {
        introPages[clampedIntroPageIndex(index)]
    }

    static let introPages: [SoundVolumeIntroPage] = [
        SoundVolumeIntroPage(
            id: "welcome",
            eyebrow: "Step 1 of 5",
            title: "Meet sound and volume",
            subtitle: "Sound can be soft, comfy, noisy, or too loud. We will learn one small idea at a time.",
            visualKey: "🔊",
            primaryActionTitle: "Next: listening rules",
            primaryActionIcon: "arrow.right.circle.fill"
        ),
        SoundVolumeIntroPage(
            id: "safety",
            eyebrow: "Step 2 of 5",
            title: "Use hearing-safe play",
            subtitle: "Use normal room sounds only — no screaming, no shouting, no loud-noise challenge, and no points for making the meter higher.",
            visualKey: "👂",
            primaryActionTitle: "Next: decibels",
            primaryActionIcon: "arrow.right.circle.fill"
        ),
        SoundVolumeIntroPage(
            id: "decibels",
            eyebrow: "Step 3 of 5",
            title: "What is a decibel?",
            subtitle: "A decibel, written dB, is a number people use to talk about how loud a sound is. Bigger dB usually means louder sound.",
            visualKey: "dB",
            primaryActionTitle: "Next: loudness zones",
            primaryActionIcon: "arrow.right.circle.fill"
        ),
        SoundVolumeIntroPage(
            id: "zones",
            eyebrow: "Step 4 of 5",
            title: "Sort sounds into zones",
            subtitle: "The live meter is an estimate, not a calibrated safety tool. If a sound hurts, move away or protect your ears.",
            visualKey: "📊",
            primaryActionTitle: "Next: sound clues",
            primaryActionIcon: "arrow.right.circle.fill"
        ),
        SoundVolumeIntroPage(
            id: "clues",
            eyebrow: "Step 5 of 5",
            title: "Ready for quiz and match",
            subtitle: "Look for picture clues like whisper, traffic, siren, headphones, birds, and protect ears.",
            visualKey: "🧩",
            primaryActionTitle: "Start Sound Lab",
            primaryActionIcon: "play.fill"
        ),
    ]

    static let cards: [LearningConceptCard] = [
        LearningConceptCard(id: "decibel", title: "Decibel (dB)", explanation: "A decibel is a number for loudness. Bigger dB usually means a louder sound.", visualKey: "dB", audioPrompt: "A decibel, or dB, is a number for loudness.", soundExample: .decibelPulse),
        LearningConceptCard(id: "quiet", title: "Quiet", explanation: "Quiet sounds are soft and gentle, like a whisper or leaves.", visualKey: "🍃", audioPrompt: "Quiet sounds are soft and gentle.", soundExample: .quietChime),
        LearningConceptCard(id: "conversation", title: "Conversation", explanation: "A talking voice sits in the middle loudness zone.", visualKey: "💬", audioPrompt: "Conversation is a middle loudness zone.", soundExample: .conversationPulse),
        LearningConceptCard(id: "traffic", title: "Traffic", explanation: "Busy traffic is loud and can turn into noise pollution.", visualKey: "🚗", audioPrompt: "Traffic can be loud and unwanted.", soundExample: .trafficRumble),
        LearningConceptCard(id: "siren", title: "Siren", explanation: "Sirens warn us, but they are very loud. Move away and protect ears.", visualKey: "🚨", audioPrompt: "Sirens are very loud warning sounds.", soundExample: .sirenSweep),
        LearningConceptCard(id: "headphones", title: "Headphones", explanation: "Keep headphones low, take breaks, and never play a volume that hurts.", visualKey: "🎧", audioPrompt: "Headphones should stay low and safe.", soundExample: .headphonesLow),
        LearningConceptCard(id: "pleasant", title: "Pleasant Sound", explanation: "Pleasant sounds feel nice and safe, like birds or soft music.", visualKey: "🐦", audioPrompt: "Pleasant sounds feel nice and safe.", soundExample: .pleasantBirds),
        LearningConceptCard(id: "unpleasant", title: "Noisy Sound", explanation: "Noisy sounds feel harsh, distracting, or unwanted.", visualKey: "📣", audioPrompt: "Noisy sounds are unwanted or harsh.", soundExample: .noisyBurst),
        LearningConceptCard(id: "protect-ears", title: "Protect Ears", explanation: "Lower volume, move away, cover ears, or ask a grown-up for help.", visualKey: "👂", audioPrompt: "Protect ears when sound is too loud.", soundExample: .protectEarsMuffle),
    ]

    static let quizQuestions: [ConceptQuizQuestion] = [
        ConceptQuizQuestion(
            id: "quiet-example",
            prompt: "Which sound belongs in the quiet zone?",
            choices: ["Whisper", "Siren", "Busy traffic"],
            correctChoice: "Whisper",
            feedback: "Yes — a whisper is soft and gentle."
        ),
        ConceptQuizQuestion(
            id: "safe-headphones",
            prompt: "What is the safest headphone choice?",
            choices: ["Turn it up until it hurts", "Keep volume low and take breaks", "Try to be louder than traffic"],
            correctChoice: "Keep volume low and take breaks",
            feedback: "Right — low volume and breaks help protect hearing."
        ),
        ConceptQuizQuestion(
            id: "noise-pollution",
            prompt: "What does noise pollution mean?",
            choices: ["Too much unwanted sound", "Only music you like", "A silent room"],
            correctChoice: "Too much unwanted sound",
            feedback: "Yes — noise pollution is unwanted sound around us."
        ),
        ConceptQuizQuestion(
            id: "too-loud-action",
            prompt: "What should you do if a sound hurts your ears?",
            choices: ["Move away or protect ears", "Make a louder sound", "Stand closer"],
            correctChoice: "Move away or protect ears",
            feedback: "Correct — move away, lower volume, or protect ears."
        ),
    ]

    static let matchPairs: [ConceptMatchPair] = [
        ConceptMatchPair(id: "whisper-quiet", left: "Whisper", right: "Quiet", feedback: "A whisper belongs in the quiet zone.", leftVisualKey: "🤫", rightVisualKey: "🍃"),
        ConceptMatchPair(id: "talk-normal", left: "Friend talking", right: "Conversation", feedback: "Talking voice is a middle loudness clue.", leftVisualKey: "🗣️", rightVisualKey: "💬"),
        ConceptMatchPair(id: "traffic-loud", left: "Busy road", right: "Traffic noise", feedback: "Busy roads can be loud and distracting.", leftVisualKey: "🚗", rightVisualKey: "📣"),
        ConceptMatchPair(id: "siren-too-loud", left: "Siren", right: "Protect ears", feedback: "Sirens are useful warnings, but they are too loud up close.", leftVisualKey: "🚨", rightVisualKey: "👂"),
        ConceptMatchPair(id: "birds-pleasant", left: "Birds", right: "Pleasant sound", feedback: "Birds can be a pleasant, gentle sound.", leftVisualKey: "🐦", rightVisualKey: "😊"),
        ConceptMatchPair(id: "headphones-safe", left: "Headphones", right: "Keep volume low", feedback: "Low volume and breaks are safer for headphones.", leftVisualKey: "🎧", rightVisualKey: "🔉"),
    ]

    static let estimatedZones: [SoundLoudnessZone] = [.quiet, .normal, .loud, .tooLoud]

    static let pitchBands = SoundPitchBand.allCases

    static let pitchChallenge = SoundPitchChallenge(
        id: "bird-high-pitch",
        prompt: "A tiny bird chirp is usually which pitch?",
        correctBand: .high,
        options: [.low, .middle, .high],
        feedback: "Yes — tiny chirps are bright, high-pitch sounds."
    )

    static func zone(forEstimatedDecibels decibels: Double) -> SoundLoudnessZone {
        switch decibels {
        case ..<50: return .quiet
        case ..<70: return .normal
        case ..<90: return .loud
        default: return .tooLoud
        }
    }
}

enum ShapeGeometryContent {
    struct Level: Identifiable, Equatable {
        let id: String
        let title: String
        let cards: [LearningConceptCard]
        let quizQuestions: [ConceptQuizQuestion]
        let matchPairs: [ConceptMatchPair]
    }

    static let basicCards: [LearningConceptCard] = [
        LearningConceptCard(id: "circle", title: "Circle", explanation: "A circle is round with no corners or sides.", visualKey: "●", audioPrompt: "Circle is round with no corners."),
        LearningConceptCard(id: "triangle", title: "Triangle", explanation: "A triangle has three sides and three corners.", visualKey: "▲", audioPrompt: "Triangle has three sides."),
        LearningConceptCard(id: "square", title: "Square", explanation: "A square has four equal sides and four square corners.", visualKey: "■", audioPrompt: "Square has four equal sides."),
        LearningConceptCard(id: "rectangle", title: "Rectangle", explanation: "A rectangle has four square corners with opposite sides matching.", visualKey: "▭", audioPrompt: "Rectangle has four square corners."),
        LearningConceptCard(id: "oval", title: "Oval", explanation: "An oval is stretched like an egg and has no corners.", visualKey: "⬭", audioPrompt: "Oval is a stretched round shape."),
        LearningConceptCard(id: "diamond", title: "Diamond", explanation: "A diamond is a square turned onto a point.", visualKey: "◆", audioPrompt: "Diamond sits on a point."),
        LearningConceptCard(id: "star", title: "Star", explanation: "A star has points that reach out from the middle.", visualKey: "★", audioPrompt: "Star has points."),
        LearningConceptCard(id: "heart", title: "Heart", explanation: "A heart has two bumps on top and one point below.", visualKey: "♥", audioPrompt: "Heart has two bumps and one point."),
    ]

    static let huntCards: [LearningConceptCard] = [
        LearningConceptCard(id: "clock", title: "Clock", explanation: "A wall clock can show a circle in the room.", visualKey: "🕘"),
        LearningConceptCard(id: "pizza", title: "Pizza Slice", explanation: "A pizza slice can look like a triangle.", visualKey: "🍕"),
        LearningConceptCard(id: "window", title: "Window", explanation: "A window often looks like a rectangle.", visualKey: "🪟"),
        LearningConceptCard(id: "kite", title: "Kite", explanation: "A kite can look like a diamond in the sky.", visualKey: "🪁"),
    ]

    static let cards = basicCards

    static let quizQuestions: [ConceptQuizQuestion] = [
        ConceptQuizQuestion(id: "three-sides", prompt: "Which shape has three sides?", choices: ["Triangle", "Circle", "Oval"], correctChoice: "Triangle", feedback: "Yes — a triangle has three sides."),
        ConceptQuizQuestion(id: "no-corners", prompt: "Which shape is round with no corners?", choices: ["Circle", "Square", "Diamond"], correctChoice: "Circle", feedback: "Correct — circles have no corners."),
        ConceptQuizQuestion(id: "four-equal-sides", prompt: "Which shape has four equal sides?", choices: ["Square", "Rectangle", "Heart"], correctChoice: "Square", feedback: "Yes — every side of a square matches."),
        ConceptQuizQuestion(id: "two-bumps", prompt: "Which shape has two bumps on top and one point below?", choices: ["Heart", "Star", "Oval"], correctChoice: "Heart", feedback: "Right — that is the heart outline clue."),
    ]

    static let matchPairs: [ConceptMatchPair] = [
        ConceptMatchPair(id: "circle-round", left: "Circle picture", right: "Circle", feedback: "Circle locked — round with no corners.", leftVisualKey: "●", rightVisualKey: "⭕"),
        ConceptMatchPair(id: "triangle-three", left: "Triangle picture", right: "Triangle", feedback: "Triangle locked — three sides.", leftVisualKey: "▲", rightVisualKey: "3"),
        ConceptMatchPair(id: "square-equal", left: "Square picture", right: "Square", feedback: "Square locked — four equal sides.", leftVisualKey: "■", rightVisualKey: "4"),
        ConceptMatchPair(id: "rectangle-long", left: "Rectangle picture", right: "Rectangle", feedback: "Rectangle locked — long box shape.", leftVisualKey: "▭", rightVisualKey: "▭"),
        ConceptMatchPair(id: "oval-egg", left: "Oval picture", right: "Oval", feedback: "Oval locked — stretched round shape.", leftVisualKey: "⬭", rightVisualKey: "🥚"),
        ConceptMatchPair(id: "diamond-point", left: "Diamond picture", right: "Diamond", feedback: "Diamond locked — point on top and bottom.", leftVisualKey: "◆", rightVisualKey: "💎"),
    ]

    static let huntMatchPairs: [ConceptMatchPair] = [
        ConceptMatchPair(id: "clock-circle", left: "Clock", right: "Circle", feedback: "A clock can show a circle.", leftVisualKey: "🕘", rightVisualKey: "●"),
        ConceptMatchPair(id: "pizza-triangle", left: "Pizza slice", right: "Triangle", feedback: "A pizza slice can show a triangle.", leftVisualKey: "🍕", rightVisualKey: "▲"),
        ConceptMatchPair(id: "window-rectangle", left: "Window", right: "Rectangle", feedback: "A window can show a rectangle.", leftVisualKey: "🪟", rightVisualKey: "▭"),
        ConceptMatchPair(id: "kite-diamond", left: "Kite", right: "Diamond", feedback: "A kite can show a diamond.", leftVisualKey: "🪁", rightVisualKey: "◆"),
    ]

    static let levels: [Level] = [
        Level(id: "shape-names", title: "Level 1: Shape names", cards: basicCards, quizQuestions: quizQuestions, matchPairs: matchPairs),
        Level(id: "shape-hunt", title: "Level 2: Shape hunt", cards: huntCards, quizQuestions: [
            ConceptQuizQuestion(id: "clock-shape", prompt: "What shape can a clock show?", choices: ["Circle", "Triangle", "Star"], correctChoice: "Circle", feedback: "Yes — many clocks are circles."),
            ConceptQuizQuestion(id: "kite-shape", prompt: "What shape can a kite show?", choices: ["Diamond", "Oval", "Heart"], correctChoice: "Diamond", feedback: "Correct — a kite can look like a diamond."),
        ], matchPairs: huntMatchPairs),
    ]
}
