import SwiftUI
import UIKit

/// Remote-friendly picture adventures share the same pairing rules as touch play.
@MainActor
struct MemoryPairsTVView: View {
    let adventure: MemoryAdventure
    let quiz: ([MemoryAnimal]) -> Void
    @Environment(MemoryGalleryContentStore.self) private var contentStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.resetFocus) private var resetFocus
    @Namespace private var focusScope
    @State private var session = MemoryPairsTVSession()
    @State private var clock = TVFriendlyChallengeClock()
    @State private var narration = TVNarrationController()
    @State private var playing = false
    @State private var hidden = false
    @State private var pairCount = 3
    @State private var gentleTimer = false
    @State private var audioEnabled = true
    @State private var explored: MemoryAnimal?
    @State private var lastCardIndex: Int?
    @State private var focusTask: Task<Void, Never>?
    @FocusState private var focusedID: String?

    private var engine: MemoryPairingEngine { session.engine }
    private var testMode: Bool { ProcessInfo.processInfo.arguments.contains("-memory-pairs-ui-test") }
    private var motionReduced: Bool {
        reduceMotion || (testMode && ProcessInfo.processInfo.arguments.contains("-memory-pairs-reduce-motion"))
    }
    private var visibleExplored: MemoryAnimal? {
        guard let explored else { return nil }
        return !hidden || engine.cards.contains(where: {
            $0.animal.id == explored.id && ($0.isSelected || $0.isMatched || engine.hintIDs.contains($0.id))
        }) ? explored : nil
    }
    private var availableCards: [MemoryAnimal] {
        if testMode { return adventure.cards }
        let category: MemoryGalleryTVCategory = adventure.deckKind == .planets ? .planets : .vehicles
        let downloaded = contentStore.cards(for: category).filter { adventure.cardIDs.contains($0.id) }
        return downloaded.count >= 4 ? downloaded : adventure.cards
    }

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            VStack(spacing: 16) {
                Text(adventure.title)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .accessibilityIdentifier("tv-memory-pairs-title")
                if playing { board } else { options }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: 1680, maxHeight: .infinity)
            .padding(.horizontal, 80)
            .padding(.vertical, 50)
        }
        .focusScope(focusScope)
        .onAppear {
            if testMode && ProcessInfo.processInfo.arguments.contains("-memory-pairs-muted") { audioEnabled = false }
            narration.setAudioEnabled(audioEnabled)
            present("\(adventure.introduction) Choose picture pairs or a picture quiz. Swipe to hear the options. Press Play Pause to repeat.")
            restoreFocus(to: "start")
        }
        .onPlayPauseCommand { narration.repeatPrompt() }
        .onExitCommand { leave() }
        .onChange(of: focusedID) { _, id in narration.focus(focusDescription(id)) }
        .onChange(of: engine.isProcessing) { _, processing in
            if !processing {
                session.settleFeedback(reduceMotion: motionReduced)
                if visibleExplored == nil { explored = nil }
            }
        }
        .onChange(of: session.isFeedbackActive) { _, active in
            if active { clock.pause(.feedback) } else { clock.resume(.feedback) }
        }
        .onChange(of: engine.hintIDs) { _, ids in
            if ids.isEmpty { clock.resume(.hint) }
            else { clock.pause(.hint) }
            if let card = engine.cards.first(where: { $0.id.uuidString == focusedID }) {
                narration.focus(cardLabel(card))
            }
        }
        .onChange(of: session.collectionRevision) { _, _ in
            guard playing, scenePhase == .active else { return }
            if session.isComplete {
                clock.stop()
                present("\(adventure.celebration) \(engine.matchedPairs) of \(engine.totalPairs) pairs found. \(adventure.tryIt) Play again or choose another adventure.")
                restoreFocus(to: "again")
            } else if engine.matchedPairs > 0 {
                present("A pair! \(engine.matchedPairs) of \(engine.totalPairs) found.")
                restoreFocus(to: nextCardID)
            }
        }
        .onChange(of: clock.isExpired) { _, expired in
            guard expired, playing, !session.isComplete else { return }
            present("Take a breath. Add more time or keep matching without a timer.")
            restoreFocus(to: "more-time")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                clock.resume(.background)
                restoreFocus(to: playing ? (session.isComplete ? "again" : clock.isExpired ? "more-time" : nextCardID) : resumeID)
            } else {
                suspendRound(reason: .background)
            }
        }
        .onDisappear {
            suspendRound(reason: .background)
            clock.stop()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(adventure.title)
        .accessibilityValue(motionReduced ? "Reduced motion" : "Standard motion")
    }

    private var options: some View {
        VStack(spacing: 22) {
            Image(adventure.sceneAssetName).resizable().scaledToFit().frame(height: 220)
                .accessibilityHidden(true)
            Text(adventure.introduction)
                .font(.system(size: 25, weight: .semibold, design: .rounded))
            if engine.totalPairs > 0 {
                action("Resume \(engine.matchedPairs) of \(engine.totalPairs) pairs", id: "resume") {
                    playing = true
                    clock.resume(.options)
                    present(session.isComplete ? adventure.celebration : "Find two matching pictures. Your cards are ready.")
                    restoreFocus(to: session.isComplete ? "again" : clock.isExpired ? "more-time" : nextCardID)
                }
            }
            HStack(spacing: 22) {
                action("3 pairs • pictures stay visible", id: "start") { begin(count: 3, faceDown: false) }
                action("4 pairs • pictures stay visible", id: "four") { begin(count: 4, faceDown: false) }
                action("Hide and seek • \(min(6, availableCards.count)) pairs", id: "hidden") { begin(count: 6, faceDown: true) }
            }
            HStack(spacing: 22) {
                action(gentleTimer ? "Gentle timer: 2 minutes" : "Timer off • Take your time", id: "timer") {
                    gentleTimer.toggle()
                    clock.configure(seconds: gentleTimer ? timerDuration : nil)
                    if engine.totalPairs > 0 && !session.isComplete {
                        clock.start()
                        clock.pause(.options)
                    }
                    present(gentleTimer ? "Optional gentle timer. Two minutes, with more time whenever you need it." : "Timer off. Take your time.")
                }
                action(audioEnabled ? "Audio on" : "Audio off", id: "audio") {
                    audioEnabled.toggle()
                    narration.setAudioEnabled(audioEnabled)
                    present(audioEnabled ? "Audio on. Swipe to hear the choices." : "Audio off. VoiceOver remains available.")
                }
                action("Picture quiz", id: "quiz") {
                    suspendRound(reason: .options)
                    clock.stop()
                    quiz(availableCards)
                }
                action("Choose another adventure", id: "back") { leave() }
            }
            Text("Starting a new choice deals new cards. Resume keeps this round.")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxHeight: .infinity)
    }

    private var board: some View {
        VStack(spacing: 16) {
            status
            if session.isComplete { finale }
            else { cardGrid.frame(maxHeight: .infinity) }
            if clock.isExpired && !session.isComplete { expiryRecovery }
            Text(session.isComplete ? adventure.tryIt : session.feedback)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .lineLimit(2)
                .frame(minHeight: 34)
                .accessibilityIdentifier("tv-memory-pairs-feedback")
            HStack(spacing: 22) {
                if session.isComplete {
                    action("Play again", id: "again") { begin(count: pairCount, faceDown: hidden) }
                } else {
                    action("Show a pair", id: "hint") {
                        guard !session.isFeedbackActive, !clock.isExpired else { return }
                        engine.hint()
                        if !engine.hintIDs.isEmpty {
                            clock.pause(.hint)
                            present("Look for the two glowing cards.")
                        }
                    }
                    if let animal = visibleExplored {
                        action("Explore \(animal.canonicalName)", id: "explore") { explore(animal) }
                    }
                }
                action("Adventure options", id: "options") {
                    suspendRound(reason: .options)
                    playing = false
                    restoreFocus(to: "resume")
                    present("Adventure options. Resume keeps your cards and collected pairs.")
                }
                action("Choose another adventure", id: "back") { leave() }
            }
        }
    }

    private var status: some View {
        HStack(spacing: 18) {
            Text("\(engine.matchedPairs) of \(engine.totalPairs) pairs")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .accessibilityIdentifier("tv-memory-pairs-progress")
            HStack(spacing: 10) {
                ForEach(session.collectedAnimals) { animal in
                    picture(animal.picture).frame(width: 46, height: 46).accessibilityHidden(true)
                }
                if !session.collectedAnimals.isEmpty {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green.opacity(0.85))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Collected pairs")
            .accessibilityValue("\(session.collectedAnimals.count) of \(engine.totalPairs)")
            .accessibilityIdentifier("tv-memory-pairs-collection")
            Spacer()
            TVFriendlyTimerView(clock: clock)
        }
        .frame(height: 52)
    }

    private var cardGrid: some View {
        GeometryReader { geometry in
            let columns = gridColumns
            let rows = max(1, (engine.cards.count + columns - 1) / columns)
            let gap: CGFloat = 22
            let width = (geometry.size.width - CGFloat(columns - 1) * gap) / CGFloat(columns)
            let height = (geometry.size.height - CGFloat(rows - 1) * gap) / CGFloat(rows)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(width), spacing: gap), count: columns), spacing: gap) {
                ForEach(engine.cards) { card in
                    if session.collectedIDs.contains(card.id) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white.opacity(0.025))
                            .overlay {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 32)).foregroundStyle(.white.opacity(0.16))
                            }
                            .frame(width: width, height: height)
                            .accessibilityHidden(true)
                            .allowsHitTesting(false)
                    } else {
                        cardButton(card, width: width, height: height)
                            .transition(motionReduced ? .identity : .opacity)
                    }
                }
            }
            .animation(motionReduced ? nil : .easeOut(duration: 0.22), value: session.collectedIDs)
        }
        .accessibilityIdentifier("tv-memory-pairs-grid")
    }

    private func cardButton(_ card: MemoryPairingEngine.Card, width: CGFloat, height: CGFloat) -> some View {
        let successful = session.successIDs.contains(card.id)
        let concealed = hidden && !card.isSelected && !card.isMatched && !engine.hintIDs.contains(card.id)
        return Button { select(card) } label: {
            ZStack {
                if concealed {
                    Image(systemName: "sparkles").font(.system(size: 66)).foregroundStyle(.white.opacity(0.85))
                } else {
                    picture(card.animal.picture)
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if successful {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 38)).foregroundStyle(Color(red: 0.68, green: 0.98, blue: 0.7))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(14)
                }
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(MemoryPairsTVCardStyle(reduceMotion: motionReduced, cue: successful ? .green :
            engine.hintIDs.contains(card.id) ? .yellow : engine.mismatchIDs.contains(card.id) ? .orange : card.isSelected ? .cyan : nil))
        .focused($focusedID, equals: card.id.uuidString)
        .prefersDefaultFocus(!clock.isExpired && card.id.uuidString == nextCardID, in: focusScope)
        .accessibilityLabel(cardLabel(card))
        .accessibilityValue(successful ? "Pair found" : card.isSelected ? "Selected" : "Ready")
        .accessibilityIdentifier("tv-memory-pair-\(card.id.uuidString)")
    }

    private var finale: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color(red: 0.7, green: 0.98, blue: 0.76))
                .scaleEffect(session.celebrationVisible && !motionReduced ? 1.06 : 1)
                .animation(motionReduced ? nil : .easeOut(duration: 0.3), value: session.celebrationVisible)
                .accessibilityHidden(true)
            Text(adventure.celebration)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("tv-memory-pairs-completion")
                .accessibilityValue(session.celebrationVisible ? "Celebrating" : "Complete")
            HStack(spacing: 28) {
                ForEach(session.collectedAnimals) { animal in
                    picture(animal.picture).frame(width: engine.totalPairs > 4 ? 170 : 245, height: 245)
                        .accessibilityLabel("\(animal.canonicalName). Collected pair.")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var expiryRecovery: some View {
        HStack(spacing: 22) {
            Text("Take a breath. Your pairs are safe.")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .accessibilityIdentifier("tv-memory-pairs-expired")
            action("More time", id: "more-time") {
                clock.addMoreTime(seconds: 60)
                present("One more minute. Keep matching.")
                restoreFocus(to: nextCardID)
            }
            action("Keep matching • Timer off", id: "untimed") {
                gentleTimer = false
                clock.chooseUntimed()
                present("Timer off. Keep matching at your own pace.")
                restoreFocus(to: nextCardID)
            }
        }
    }

    private var timerDuration: Int {
        testMode && ProcessInfo.processInfo.arguments.contains("-memory-pairs-short-timer") ? 2 : 120
    }
    private var resumeID: String { engine.totalPairs > 0 ? "resume" : "start" }
    private var gridColumns: Int { engine.totalPairs == 5 ? 5 : engine.totalPairs <= 3 ? 3 : 4 }
    private var nextCardID: String? {
        let remaining = engine.cards.indices.filter { !engine.cards[$0].isMatched && !session.collectedIDs.contains(engine.cards[$0].id) }
        guard let origin = lastCardIndex else { return remaining.first.map { engine.cards[$0].id.uuidString } }
        let columns = gridColumns
        let closest = remaining.min { first, second in
            let firstDistance = abs(first / columns - origin / columns) + abs(first % columns - origin % columns)
            let secondDistance = abs(second / columns - origin / columns) + abs(second % columns - origin % columns)
            return firstDistance == secondDistance ? first < second : firstDistance < secondDistance
        }
        return closest.map { engine.cards[$0].id.uuidString }
    }

    private func begin(count: Int, faceDown: Bool) {
        pairCount = min(count, availableCards.count)
        hidden = faceDown
        explored = nil
        lastCardIndex = nil
        let animals = testMode ? Array(availableCards.prefix(pairCount)) : Array(availableCards.shuffled().prefix(pairCount))
        session.begin(animals: animals, hidden: faceDown)
        clock.configure(seconds: gentleTimer ? timerDuration : nil)
        clock.resume(.options)
        clock.resume(.feedback)
        clock.resume(.hint)
        clock.start()
        playing = true
        restoreFocus(to: nextCardID)
        present("\(faceDown ? "Choose two cards to find matching pictures. Show a pair gives a clue." : "Find two matching pictures. Swipe to a picture and press select.") \(gentleTimer ? "The gentle timer is ready. More time is always available." : "No timer. Take your time.")")
    }

    private func select(_ card: MemoryPairingEngine.Card) {
        guard !clock.isExpired, scenePhase == .active else { return }
        switch session.select(card.id) {
        case .ignored: return
        case .first(let selected):
            lastCardIndex = engine.cards.firstIndex { $0.id == card.id }
            explored = selected.animal
            announce(selected.animal.canonicalName)
        case .pair(_, let second, let matches):
            lastCardIndex = engine.cards.firstIndex { $0.id == card.id }
            explored = second.animal
            clock.pause(.feedback)
            if !matches { announce("Different pictures. Keep looking.") }
        }
    }

    private func cardLabel(_ card: MemoryPairingEngine.Card) -> String {
        let position = (engine.cards.firstIndex(where: { $0.id == card.id }) ?? 0) + 1
        if hidden && !card.isSelected && !card.isMatched && !engine.hintIDs.contains(card.id) {
            return "Hidden card \(position). Select to turn over."
        }
        return "\(card.animal.canonicalName). Select to find its pair."
    }

    private func focusDescription(_ id: String?) -> String? {
        guard let id else { return nil }
        if let card = session.remainingCards.first(where: { $0.id.uuidString == id }) { return cardLabel(card) }
        let labels = ["start": "Three pairs. Pictures stay visible.", "four": "Four pairs. Pictures stay visible.",
            "hidden": "Hide and seek. Up to six hidden pairs.", "quiz": "Picture quiz.", "back": "Choose another adventure.",
            "again": "Play again.", "hint": "Show a pair. Two matching cards glow.", "options": "Adventure options. Resume keeps these cards.",
            "audio": audioEnabled ? "Audio on. Select to mute app narration." : "Audio off. Select to hear app narration.",
            "resume": "Resume the same cards and collected pairs.", "explore": "Explore this picture.",
            "timer": gentleTimer ? "Gentle timer on. Two minutes with more time available." : "Timer off. Take your time.",
            "more-time": "Add one more minute. Your cards stay the same.", "untimed": "Keep matching with the timer off."]
        return labels[id]
    }

    private func explore(_ animal: MemoryAnimal) {
        let facts = animal.detailCards.filter { ["look closely", "try it", "fun fact"].contains($0.title.lowercased()) }
        let text = facts.prefix(2).map { "\($0.title). \($0.value)" }.joined(separator: ". ")
        present("\(animal.canonicalName). \(text)")
    }

    private func present(_ text: String) {
        narration.presentPrompt(text)
        if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: text) }
    }
    private func announce(_ text: String) {
        narration.announce(text)
        if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: text) }
    }

    private func restoreFocus(to id: String?) {
        focusTask?.cancel()
        focusedID = nil
        let round = engine.roundID
        focusTask = Task { @MainActor in
            do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
            guard !Task.isCancelled, scenePhase == .active, engine.roundID == round else { return }
            focusedID = id
            resetFocus(in: focusScope)
            focusTask = nil
        }
    }

    private func suspendRound(reason: TVFriendlyChallengeClock.PauseReason) {
        focusTask?.cancel()
        focusTask = nil
        focusedID = nil
        session.cancelTransientWork()
        clock.resume(.feedback)
        clock.resume(.hint)
        clock.pause(reason)
        narration.stop()
    }
    private func leave() {
        suspendRound(reason: .background)
        clock.stop()
        dismiss()
    }

    private func action(_ title: String, id: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.horizontal, 24)
                .frame(minHeight: 66)
        }
            .buttonStyle(MemoryPairsTVCardStyle(reduceMotion: motionReduced, cue: nil))
            .focused($focusedID, equals: id)
            .prefersDefaultFocus(id == (playing ? session.isComplete ? "again" : clock.isExpired ? "more-time" : "" : resumeID), in: focusScope)
            .accessibilityIdentifier("tv-memory-adventure-\(id)")
    }

    @ViewBuilder private func picture(_ picture: MemoryPicture) -> some View {
        switch picture {
        case .asset(let name):
            if let url = contentStore.assetURL(named: name), let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFit()
            } else { Image(name).resizable().scaledToFit() }
        case .emoji(let value): Text(value).font(.system(size: 115))
        case .text(let value): Text(value).font(.system(size: 32, weight: .black, design: .rounded)).minimumScaleFactor(0.8)
        }
    }
}

private struct MemoryPairsTVCardStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    let reduceMotion: Bool
    let cue: Color?
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(isFocused ? Color.white.opacity(0.23) : Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(cue ?? (isFocused ? .white : .white.opacity(0.13)), lineWidth: cue != nil || isFocused ? 5 : 2))
            .scaleEffect(isFocused && !reduceMotion ? 1.018 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isFocused)
    }
}
