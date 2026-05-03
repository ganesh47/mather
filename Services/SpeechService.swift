import AVFoundation
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
@Observable
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastUtteranceID = UUID()
    private(set) var lastSpokenText: String?
    private(set) var lastSpeechDiagnostic: String?
    var hasSpokenSessionIntro = false

    init() {
        // Use .playback category so prompts are audible even when the hardware
        // ringer/silent switch is off. .spokenAudio mode pauses other audio
        // during speech; .duckOthers lowers (rather than cuts) background audio.
        // The in-app audio toggle (speak(_:enabled:)) remains the parent's control.
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: .duckOthers
            )
            try AVAudioSession.sharedInstance().setActive(true)
            lastSpeechDiagnostic = nil
        } catch {
            lastSpeechDiagnostic = "Audio session setup failed: \(error.localizedDescription)"
            print("[Mather][SpeechService] \(lastSpeechDiagnostic!)")
        }
    }

    func speak(_ text: String, enabled: Bool) {
        guard !text.isEmpty else { return }
        guard enabled else {
            lastSpeechDiagnostic = "Speech skipped because audio prompts are disabled."
            print("[Mather][SpeechService] \(lastSpeechDiagnostic!)")
            return
        }
        lastSpokenText = text
        lastSpeechDiagnostic = nil
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        lastUtteranceID = UUID()
        synthesizer.speak(utterance)
    }

    // Always speaks the session intro regardless of the audio toggle — the child
    // should always hear a spoken start cue. The parent's mute toggle applies to
    // in-session prompts only (via speak(_:enabled:)).
    func speakSessionIntro(_ phrase: String) {
        guard !hasSpokenSessionIntro else { return }
        hasSpokenSessionIntro = true
        speak(phrase, enabled: true)
    }

    func speakLearningDetails(_ text: String, enabled: Bool) {
        speak(text, enabled: enabled)
    }

    func resetSession() {
        hasSpokenSessionIntro = false
    }
}

enum MemoryCardDescriptionSource: String, Equatable {
    case appleIntelligence
    case curatedFallback
}

struct MemoryFactChip: Equatable {
    let title: String
    let value: String
}

struct MemoryCardDescription: Equatable {
    let title: String
    let shortDescription: String
    let factChips: [MemoryFactChip]
    let source: MemoryCardDescriptionSource
}

struct MemoryCardAIPrompt: Equatable {
    static let maxGeneratedCharacters = 220
    static let maxGeneratedSentences = 2
    static let maxGeneratedSentenceCharacters = 120

    let systemInstruction: String
    let userPrompt: String

    static func childSafePrompt(for animal: MemoryAnimal) -> MemoryCardAIPrompt {
        let facts = animal.detailCards
            .prefix(5)
            .map { "\($0.title): \($0.value)" }
            .joined(separator: "; ")
        let deckName = animal.metadata.deck.displayName
        return MemoryCardAIPrompt(
            systemInstruction: "Write for a child age 5 to 8. Be factual, warm, and concise. Use no more than two short sentences and 220 total characters. Do not ask questions, roleplay, invent facts, mention AI, use markdown, emoji, lists, or include unsafe instructions.",
            userPrompt: "Explain this Memory Match card in simple factual words. Deck: \(deckName). Card: \(animal.canonicalName). Only use these known facts: \(facts)."
        )
    }
}

@MainActor
protocol MemoryCardAIAdapter {
    var isAvailable: Bool { get }
    func shortDescription(for animal: MemoryAnimal, prompt: MemoryCardAIPrompt) async throws -> String?
}

private struct NullMemoryCardAIAdapter: MemoryCardAIAdapter {
    var isAvailable: Bool { false }
    func shortDescription(for animal: MemoryAnimal, prompt: MemoryCardAIPrompt) async throws -> String? { nil }
}

#if canImport(FoundationModels)
private struct FoundationModelsMemoryCardAIAdapter: MemoryCardAIAdapter {
    var isAvailable: Bool {
        if #available(iOS 26.0, macOS 26.0, *) {
            return false
        }
        return false
    }

    func shortDescription(for animal: MemoryAnimal, prompt: MemoryCardAIPrompt) async throws -> String? {
        guard isAvailable else { return nil }
        _ = prompt
        // Intentionally guarded and fallback-first until the FoundationModels API
        // is enabled for this app target. The prompt and sanitizer are production
        // boundaries: short, factual, child-safe copy in; deterministic fallback out
        // whenever the platform model is unavailable or returns unsuitable text.
        return nil
    }
}
#endif

@MainActor
final class MemoryCardDescribeService {
    private let appleIntelligenceEnabled: () -> Bool
    private let aiAdapter: any MemoryCardAIAdapter

    init(
        appleIntelligenceEnabled: @escaping () -> Bool = { true },
        aiAdapter: (any MemoryCardAIAdapter)? = nil
    ) {
        self.appleIntelligenceEnabled = appleIntelligenceEnabled
        self.aiAdapter = aiAdapter ?? Self.makeDefaultAIAdapter()
    }

    func describe(_ animal: MemoryAnimal) async -> MemoryCardDescription {
        let prompt = MemoryCardAIPrompt.childSafePrompt(for: animal)
        if appleIntelligenceEnabled(), aiAdapter.isAvailable,
           let generated = try? await aiAdapter.shortDescription(for: animal, prompt: prompt),
           let sanitized = sanitizeGeneratedDescription(generated) {
            return MemoryCardDescription(
                title: animal.canonicalName,
                shortDescription: sanitized,
                factChips: fallbackFactChips(for: animal),
                source: .appleIntelligence
            )
        }

        return fallbackDescription(for: animal)
    }

    func fallbackDescription(for animal: MemoryAnimal) -> MemoryCardDescription {
        MemoryCardDescription(
            title: animal.canonicalName,
            shortDescription: buildFallbackDescription(for: animal),
            factChips: fallbackFactChips(for: animal),
            source: .curatedFallback
        )
    }

    private func buildFallbackDescription(for animal: MemoryAnimal) -> String {
        let metadata = animal.metadata
        let firstSentence: String
        switch metadata.deck {
        case .birds:
            if let habitat = metadata.habitat {
                firstSentence = "\(animal.canonicalName) is a bird that lives in \(habitat.lowercased())."
            } else {
                firstSentence = "\(animal.canonicalName) is a colorful bird."
            }
        case .domesticAnimals:
            if let habitat = metadata.habitat {
                firstSentence = "\(animal.canonicalName) is a domestic animal you might find in \(habitat.lowercased())."
            } else {
                firstSentence = "\(animal.canonicalName) is a friendly domestic animal."
            }
        case .vehicles:
            if let use = metadata.use {
                firstSentence = "\(animal.canonicalName) is a vehicle that \(use.lowercased())."
            } else {
                firstSentence = "\(animal.canonicalName) is a helpful vehicle."
            }
        case .planets:
            firstSentence = "\(animal.canonicalName) is a planet in our solar system."
        case .fishes:
            if let habitat = metadata.habitat {
                firstSentence = "\(animal.canonicalName) is a fish that lives in \(habitat.lowercased())."
            } else {
                firstSentence = "\(animal.canonicalName) is a fish that swims with fins."
            }
        case .countries:
            if let continent = metadata.habitat {
                firstSentence = "\(animal.canonicalName) is a country in \(continent.lowercased()) and its capital is \(animal.name)."
            } else {
                firstSentence = "\(animal.canonicalName) is a country and its capital is \(animal.name)."
            }
        case .countryFlags:
            if let continent = metadata.habitat {
                firstSentence = "This card shows the flag of \(animal.canonicalName), a country in \(continent.lowercased())."
            } else {
                firstSentence = "This card shows the flag of \(animal.canonicalName)."
            }
        case .indiaStates:
            if let region = metadata.habitat {
                firstSentence = "\(animal.canonicalName) is an Indian state in \(region.lowercased()) and its capital is \(animal.name)."
            } else {
                firstSentence = "\(animal.canonicalName) is an Indian state and its capital is \(animal.name)."
            }
        case .waterCycle:
            if let action = metadata.movement {
                firstSentence = "\(animal.canonicalName) is part of the water cycle: \(action.lowercased())."
            } else {
                firstSentence = "\(animal.canonicalName) is part of the water cycle."
            }
        case .fruits:
            if let foundIn = metadata.habitat {
                firstSentence = "\(animal.canonicalName) is a fruit usually found in \(foundIn.lowercased())."
            } else {
                firstSentence = "\(animal.canonicalName) is a fruit with shape, color, taste, and smell clues."
            }
        }

        let secondParts: [String]
        if metadata.deck == .waterCycle {
            secondParts = [
                metadata.habitat.map { "You can notice it \($0.lowercased())" },
                animal.detailCards.first { $0.title == "Everyday Words" }.map(\.value)
            ].compactMap { $0 }
        } else {
            secondParts = [
                metadata.colors.map { "It can show \($0.lowercased()) colors" },
                metadata.movement.map { "It often \($0.lowercased())" },
                metadata.size.map { "It can be about \($0.lowercased())" }
            ].compactMap { $0 }
        }

        let secondSentence: String
        if secondParts.count >= 2 {
            secondSentence = secondParts[0] + " " + secondParts[1] + "."
        } else if let only = secondParts.first {
            secondSentence = only + "."
        } else if let sound = metadata.sound {
            secondSentence = "It is easy to imagine it making a \(sound.lowercased())."
        } else {
            secondSentence = "It is fun to spot and talk about while you play."
        }

        if let lifespan = metadata.lifespan {
            return "\(firstSentence) \(secondSentence) Some can live for \(lifespan.lowercased())."
        }
        if let use = metadata.use, metadata.deck != .vehicles {
            return "\(firstSentence) \(secondSentence) People often notice how it \(use.lowercased())."
        }
        return "\(firstSentence) \(secondSentence)"
    }

    private func fallbackFactChips(for animal: MemoryAnimal) -> [MemoryFactChip] {
        animal.detailCards
            .filter { $0.title != "Name" }
            .prefix(4)
            .map { MemoryFactChip(title: $0.title, value: $0.value) }
    }

    private func sanitizeGeneratedDescription(_ text: String?) -> String? {
        guard let text else { return nil }
        guard isGeneratedDescriptionAllowed(text) else { return nil }
        let collapsed = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !collapsed.isEmpty else { return nil }
        guard isGeneratedDescriptionAllowed(collapsed) else { return nil }

        let sentences = collapsed
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let limitedSentences = Array(sentences.prefix(MemoryCardAIPrompt.maxGeneratedSentences))
        guard limitedSentences.allSatisfy({ $0.count <= MemoryCardAIPrompt.maxGeneratedSentenceCharacters }) else { return nil }
        let sentenceLimited = limitedSentences.isEmpty ? collapsed : limitedSentences.joined(separator: ". ") + "."
        guard sentenceLimited.count <= MemoryCardAIPrompt.maxGeneratedCharacters else {
            let endIndex = sentenceLimited.index(sentenceLimited.startIndex, offsetBy: MemoryCardAIPrompt.maxGeneratedCharacters)
            let clipped = String(sentenceLimited[..<endIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: ",;:-"))
            return clipped.isEmpty ? nil : clipped + "…"
        }
        return sentenceLimited
    }

    private func isGeneratedDescriptionAllowed(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let disallowedFragments = [
            "as an ai",
            "language model",
            "i cannot",
            "i can't",
            "ask an adult",
            "click here",
            "http://",
            "https://",
            "pretend",
            "roleplay",
            "role-play",
            "imagine you are",
            "let's",
            "we are going to",
            "scary",
            "violent",
            "weapon"
        ]
        guard !disallowedFragments.contains(where: { lowercased.contains($0) }) else { return false }
        guard !text.contains("?") else { return false }
        guard !text.unicodeScalars.contains(where: Self.isEmojiOrSymbolicPictograph) else { return false }

        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let markdownPrefixes = ["#", ">", "-", "*", "•", "1.", "2.", "3."]
        guard !lines.contains(where: { line in
            markdownPrefixes.contains(where: { line.hasPrefix($0) })
        }) else { return false }
        guard !text.contains("```") && !text.contains("**") && !text.contains("__") else { return false }
        return true
    }

    private static func isEmojiOrSymbolicPictograph(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x1F000...0x1FAFF, 0x2600...0x27BF, 0xFE00...0xFE0F:
            return true
        default:
            return false
        }
    }

    private static func makeDefaultAIAdapter() -> any MemoryCardAIAdapter {
        #if canImport(FoundationModels)
        FoundationModelsMemoryCardAIAdapter()
        #else
        NullMemoryCardAIAdapter()
        #endif
    }
}
