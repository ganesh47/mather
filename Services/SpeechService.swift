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
    var hasSpokenSessionIntro = false

    init() {
        // Use .playback category so prompts are audible even when the hardware
        // ringer/silent switch is off. .spokenAudio mode pauses other audio
        // during speech; .duckOthers lowers (rather than cuts) background audio.
        // The in-app audio toggle (speak(_:enabled:)) remains the parent's control.
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: .duckOthers
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func speak(_ text: String, enabled: Bool) {
        guard enabled, !text.isEmpty else { return }
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

@MainActor
protocol MemoryCardAIAdapter {
    var isAvailable: Bool { get }
    func shortDescription(for animal: MemoryAnimal) async throws -> String?
}

private struct NullMemoryCardAIAdapter: MemoryCardAIAdapter {
    var isAvailable: Bool { false }
    func shortDescription(for animal: MemoryAnimal) async throws -> String? { nil }
}

#if canImport(FoundationModels)
private struct FoundationModelsMemoryCardAIAdapter: MemoryCardAIAdapter {
    var isAvailable: Bool {
        if #available(iOS 26.0, macOS 26.0, *) {
            return false
        }
        return false
    }

    func shortDescription(for animal: MemoryAnimal) async throws -> String? {
        guard isAvailable else { return nil }
        // Intentionally guarded and fallback-first for Slice A. A future slice can
        // replace this stub with a live Foundation Models request without changing
        // the service API or the curated fallback path.
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
        if appleIntelligenceEnabled(), aiAdapter.isAvailable,
           let generated = try? await aiAdapter.shortDescription(for: animal),
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
        }

        let secondParts = [
            metadata.colors.map { "It can show \($0.lowercased()) colors" },
            metadata.movement.map { "It often \($0.lowercased())" },
            metadata.size.map { "It can be about \($0.lowercased())" }
        ].compactMap { $0 }

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
        let collapsed = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return collapsed.isEmpty ? nil : collapsed
    }

    private static func makeDefaultAIAdapter() -> any MemoryCardAIAdapter {
        #if canImport(FoundationModels)
        FoundationModelsMemoryCardAIAdapter()
        #else
        NullMemoryCardAIAdapter()
        #endif
    }
}
