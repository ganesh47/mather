import SwiftUI

/// The photo bank is captured on entry; browsing never swaps the current quiz's content.
@MainActor
struct AnimalExplorerTVView: View {
    let entries: [AnimalExplorerEntry]
    let collections: [AnimalExplorerCollection]
    let contentVersion: Int
    let onClose: () -> Void
    let onClassicQuiz: () -> Void
    var onLearningEvent: (AnimalExplorerLearningEvent) -> Void = { _ in }

    @Environment(MemoryGalleryContentStore.self) private var contentStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focusedID: String?
    @State private var phase = Phase.browsing
    @State private var collectionID = "india-wildlife"
    @State private var detailID: String?
    @State private var game = MemoryGalleryTVGame()
    @State private var clock = TVFriendlyChallengeClock()
    @State private var narration = TVNarrationController()
    @State private var timerSeconds: Int?
    @State private var isMuted = false
    @State private var showsOptions = false
    @State private var showsHint = false
    @State private var returnFocusID: String?
    @State private var sessionID = UUID().uuidString
    @State private var sessionStartedAt = Date()
    @State private var viewedVariants = Set<String>()
    @State private var hintedRounds = Set<Int>()
    @State private var didComplete = false
    @State private var isVisible = false
    @State private var focusGeneration = 0

    private enum Phase: Equatable { case browsing, detail, quiz, completed }

    private var motionReduced: Bool {
        reduceMotion || (uiTesting && ProcessInfo.processInfo.arguments.contains("-animal-explorer-reduce-motion"))
    }

    private var uiTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-animal-explorer-ui-test")
    }

    private var collection: AnimalExplorerCollection? {
        collections.first { $0.id == collectionID }
    }

    private var collectionEntries: [AnimalExplorerEntry] {
        var species = Set<String>()
        return entries.filter {
            $0.collectionIDs.contains(collectionID) && species.insert($0.speciesID).inserted
        }
    }

    private var detailEntry: AnimalExplorerEntry? { entries.first { $0.id == detailID } }
    private var promptEntry: AnimalExplorerEntry? { entries.first { $0.card.id == game.round?.promptCard.id } }

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            if showsOptions {
                optionsScreen
            } else if showsHint, let entry = promptEntry {
                hintScreen(entry)
            } else {
                switch phase {
                case .browsing: browseScreen
                case .detail: if let entry = detailEntry { detailScreen(entry) }
                case .quiz: if let round = game.round, let entry = promptEntry { quizScreen(round, entry: entry) }
                case .completed: completionScreen
                }
            }
        }
        .animation(motionReduced ? nil : .easeOut(duration: 0.18), value: phase)
        .onAppear {
            isVisible = true
            if collectionEntries.isEmpty { collectionID = "all-animals" }
            present("Welcome to Animals. Explore real photographs of species found in India. Swipe to choose a collection or an animal. Choose Photo name quiz when you are ready. Press Play Pause to hear the instructions again.")
            focus("tv-animal-start-quiz")
        }
        .onChange(of: scenePhase) { _, value in
            if value == .active {
                clock.resume(.background)
            } else {
                focusGeneration += 1
                clock.pause(.background)
                narration.stop()
            }
        }
        .onChange(of: focusedID) { _, id in
            narration.focus(focusNarration(id))
        }
        .onPlayPauseCommand {
            if phase == .quiz, !game.hasAnsweredCurrentRound, !showsOptions { openHint() }
            else { narration.repeatPrompt() }
        }
        .onExitCommand(perform: exit)
        .onDisappear {
            isVisible = false
            focusGeneration += 1
            clock.stop()
            narration.stop()
        }
    }

    private var browseScreen: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animals").font(.system(size: 58, weight: .black, design: .rounded))
                        .accessibilityIdentifier("tv-animal-explorer-title")
                    Text("Real photos. Big discoveries.").font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                action("Photo name quiz", symbol: "questionmark.circle.fill", id: "tv-animal-start-quiz", enabled: collectionEntries.count >= 4, perform: startQuiz)
                action("Options", symbol: "slider.horizontal.3", id: "tv-animal-options", perform: openOptions)
            }

            HStack(spacing: 14) {
                ForEach(collections) { item in
                    Button { chooseCollection(item) } label: {
                        VStack(spacing: 5) {
                            Text(item.title).font(.system(size: 21, weight: .black, design: .rounded))
                            Text("\(entryCount(for: item.id)) photos").font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 68)
                        .padding(.horizontal, 12)
                        .background(collectionID == item.id ? Color(red: 0.22, green: 0.49, blue: 0.39) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(AnimalExplorerButtonStyle(reduceMotion: motionReduced))
                    .focused($focusedID, equals: "tv-animal-collection-\(item.id)")
                    .accessibilityLabel("\(item.title). \(entryCount(for: item.id)) animal photos. \(item.spokenDescription)")
                    .accessibilityAddTraits(collectionID == item.id ? .isSelected : [])
                    .accessibilityIdentifier("tv-animal-collection-\(item.id)")
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text(collection?.title ?? "Animals").font(.system(size: 30, weight: .black, design: .rounded))
                Text(collectionID == "india-wildlife" ? "Species found in India; photos may be taken elsewhere." : (collection?.spokenDescription ?? ""))
                    .font(.system(size: 21, weight: .semibold)).foregroundStyle(.white.opacity(0.65))
            }
            .accessibilityIdentifier("tv-animal-collection-description")

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: 4), spacing: 24) {
                    ForEach(collectionEntries) { entry in
                        Button { openDetail(entry) } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                photo(entry).frame(height: 172).clipShape(RoundedRectangle(cornerRadius: 16))
                                Text(entry.card.name).font(.system(size: 26, weight: .black, design: .rounded)).lineLimit(2)
                            }
                            .padding(16).frame(maxWidth: .infinity, minHeight: 245, alignment: .topLeading)
                            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(AnimalExplorerButtonStyle(reduceMotion: motionReduced))
                        .focused($focusedID, equals: cardFocusID(entry))
                        .accessibilityLabel("\(entry.card.name). Real animal photograph.")
                        .accessibilityHint("Select to explore the animal and its photo credits.")
                        .accessibilityIdentifier(cardFocusID(entry))
                        .onAppear { recordExposure(entry) }
                    }
                }
                .padding(12)
            }
            .accessibilityIdentifier("tv-animal-photo-bank-v\(contentVersion)")

            HStack(spacing: 24) {
                Text(collectionEntries.count >= 4 ? "Choose a photo to look closer. Quiz whenever you feel ready." : "Explore these photos. A name quiz needs four different animals.")
                    .font(.system(size: 21, weight: .semibold)).foregroundStyle(.white.opacity(0.66))
                Spacer()
                action("Illustrated animal quiz", symbol: "rectangle.stack", id: "tv-animal-classic-quiz") {
                    clock.stop(); narration.stop(); onClassicQuiz()
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 90).padding(.vertical, 58)
    }

    private func detailScreen(_ entry: AnimalExplorerEntry) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.card.name).font(.system(size: 56, weight: .black, design: .rounded))
                        .accessibilityIdentifier("tv-animal-detail-title")
                    Text("Look closer").font(.system(size: 27, weight: .bold)).foregroundStyle(.white.opacity(0.68))
                }
                Spacer()
                action("Back to photos", symbol: "arrow.left", id: "tv-animal-detail-back", perform: returnToBrowse)
                action("Photo name quiz", symbol: "questionmark.circle", id: "tv-animal-detail-quiz", enabled: collectionEntries.count >= 4, perform: startQuiz)
            }
            HStack(alignment: .top, spacing: 42) {
                VStack(alignment: .leading, spacing: 16) {
                    photo(entry).frame(width: 820, height: 535).clipShape(RoundedRectangle(cornerRadius: 28))
                    Text(entry.neutralPhotoDescription).font(.system(size: 24, weight: .semibold)).foregroundStyle(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 820).accessibilityElement(children: .combine)
                .accessibilityLabel("\(entry.card.name). \(entry.neutralPhotoDescription)")
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(Array(entry.card.detailCards.prefix(3).enumerated()), id: \.offset) { _, fact in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(fact.title).font(.system(size: 21, weight: .bold)).foregroundStyle(Color(red: 0.60, green: 0.90, blue: 0.77))
                                Text(fact.value).font(.system(size: 26, weight: .semibold, design: .rounded))
                            }
                        }
                        credits(entry)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 650)
                .focusable()
                .focused($focusedID, equals: "tv-animal-detail-reading")
                .accessibilityLabel("Animal facts and photo credits. Swipe up or down to read.")
            }
        }
        .foregroundStyle(.white).frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 90).padding(.vertical, 65)
    }

    private func credits(_ entry: AnimalExplorerEntry) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Photo credits").font(.system(size: 25, weight: .black, design: .rounded))
            if let credit = entry.photoAttribution {
                Text(credit.creditLine)
                Text("License: \(credit.licenseName)")
                Text("License terms: \(credit.licenseURL)")
                Text("Source: \(credit.sourceURL)")
                Text("Photo changes: \(credit.modificationDescription)")
            } else if let text = entry.photoCredit {
                Text(text)
            }
        }
        .font(.system(size: 18, weight: .medium)).foregroundStyle(.white.opacity(0.74))
        .fixedSize(horizontal: false, vertical: true)
        .padding(24).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("tv-animal-photo-credits")
    }

    private func quizScreen(_ round: MemoryGalleryTVRound, entry: AnimalExplorerEntry) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack(spacing: 25) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Animals · Photo name quiz").font(.system(size: 42, weight: .black, design: .rounded))
                    Text(game.progressText).font(.system(size: 24, weight: .bold)).foregroundStyle(.white.opacity(0.66))
                        .accessibilityIdentifier("tv-animal-quiz-progress")
                }
                Spacer()
                stat("Matched", value: game.correctCount, symbol: "checkmark")
                stat("Streak", value: game.streak, symbol: "flame.fill")
                TVFriendlyTimerView(clock: clock)
                    .accessibilityIdentifier("tv-animal-timer")
            }
            HStack(alignment: .top, spacing: 42) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(game.hasAnsweredCurrentRound ? entry.card.name : "Look closely")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.62, green: 0.90, blue: 0.81))
                    photo(entry).frame(width: 710, height: 440).clipShape(RoundedRectangle(cornerRadius: 24))
                    if game.hasAnsweredCurrentRound, let fact = round.learningFacts.first {
                        Text("\(fact.title): \(fact.value)").font(.system(size: 24, weight: .semibold))
                    } else {
                        Text("Which animal is in the photograph?").font(.system(size: 24, weight: .semibold))
                    }
                }
                .padding(28).frame(width: 766).frame(minHeight: 590, alignment: .topLeading)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(game.hasAnsweredCurrentRound ? "Picture prompt. \(entry.card.name). \(entry.neutralPhotoDescription)" : "Picture prompt. \(entry.neutralPhotoDescription) Choose the matching animal name.")
                .accessibilityIdentifier("tv-memory-picture-prompt")

                VStack(alignment: .leading, spacing: 24) {
                    Text("Choose the matching name").font(.system(size: 31, weight: .black, design: .rounded))
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                        ForEach(round.answerChoices) { answer in
                            Button { select(answer, round: round) } label: {
                                HStack(spacing: 15) {
                                    Image(systemName: answerSymbol(answer, round: round))
                                    Text(answer.name).lineLimit(2).minimumScaleFactor(0.72)
                                    Spacer(minLength: 0)
                                }
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .padding(24).frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                                .background(answerColor(answer, round: round), in: RoundedRectangle(cornerRadius: 22))
                            }
                            .buttonStyle(AnimalExplorerButtonStyle(reduceMotion: motionReduced))
                            .focused($focusedID, equals: "tv-memory-answer-\(answer.id)")
                            .disabled(game.hasAnsweredCurrentRound)
                            .accessibilityLabel(answer.name)
                            .accessibilityHint("Select this name for the photograph.")
                            .accessibilityIdentifier("tv-memory-answer-\(answer.id)")
                        }
                    }
                    quizFeedback(round, entry: entry)
                    if !game.hasAnsweredCurrentRound {
                        HStack(spacing: 20) {
                            action("Look closely hint", symbol: "lightbulb", id: "tv-animal-hint", perform: openHint)
                            action("Options", symbol: "slider.horizontal.3", id: "tv-animal-quiz-options", perform: openOptions)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .topLeading)
            }
            Text("Menu returns to photos. Play Pause opens a paused picture hint.")
                .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white.opacity(0.60))
        }
        .foregroundStyle(.white).frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 90).padding(.vertical, 65)
    }

    @ViewBuilder
    private func quizFeedback(_ round: MemoryGalleryTVRound, entry: AnimalExplorerEntry) -> some View {
        if game.hasAnsweredCurrentRound {
            VStack(alignment: .leading, spacing: 18) {
                Text(game.lastAnswerWasCorrect == true ? "Matched! You found \(entry.card.name)." : "Good try. This is \(entry.card.name).")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .accessibilityIdentifier("tv-animal-answer-feedback")
                    .accessibilityLabel(game.lastAnswerWasCorrect == true ? "Correct. \(entry.card.name) matched." : "Not a match. This is \(entry.card.name).")
                action(game.completedRoundCount == game.roundGoal ? "See results" : "Next picture", symbol: "arrow.right", id: nextFocusID, perform: advance)
            }
        } else if clock.isExpired {
            VStack(alignment: .leading, spacing: 16) {
                Text("Take more time. This picture is still yours.").font(.system(size: 23, weight: .bold))
                    .accessibilityIdentifier("tv-animal-time-expired")
                HStack(spacing: 18) {
                    action("More time", symbol: "plus.circle", id: "tv-animal-more-time") {
                        clock.addMoreTime()
                        focusFirstAnswer()
                    }
                    action("Play untimed", symbol: "infinity", id: "tv-animal-untimed") {
                        timerSeconds = nil
                        clock.chooseUntimed()
                        focusFirstAnswer()
                    }
                }
            }
        } else {
            Text(clock.isEnabled ? "A friendly timer. Hints pause it; more time is always available." : "No timer. Take your time and choose when you are ready.")
                .font(.system(size: 23, weight: .semibold)).foregroundStyle(.white.opacity(0.68))
                .accessibilityIdentifier(clock.isEnabled ? "tv-animal-timer-copy" : "tv-memory-no-timer-copy")
        }
    }

    private var optionsScreen: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Animal options").font(.system(size: 54, weight: .black, design: .rounded))
                .accessibilityIdentifier("tv-animal-options-title")
            Text("Choose your pace. Your answers stay the same.").font(.system(size: 26, weight: .semibold))
            action("No timer\(timerSeconds == nil ? " · selected" : "")", symbol: "infinity", id: "tv-animal-option-no-timer") {
                timerSeconds = nil
                clock.chooseUntimed()
                present("No timer selected. Take your time.")
            }
            action("Friendly timer · 2 minutes\(timerSeconds != nil ? " · selected" : "")", symbol: "timer", id: "tv-animal-option-friendly-timer") {
                timerSeconds = uiTesting && ProcessInfo.processInfo.arguments.contains("-animal-explorer-fast-timer") ? 3 : 120
                clock.configure(seconds: timerSeconds)
                if phase == .quiz, !game.hasAnsweredCurrentRound { clock.start(); clock.pause(.options) }
                present("Friendly timer selected. Hints and options pause it. When time runs out you can take more time or play untimed.")
            }
            action(isMuted ? "Sound off · turn on" : "Sound on · mute", symbol: isMuted ? "speaker.slash" : "speaker.wave.2", id: "tv-animal-option-sound") {
                isMuted.toggle()
                narration.setAudioEnabled(!isMuted)
                if !isMuted { present("Sound is on. Press Play Pause to hear instructions.") }
            }
            action("Back", symbol: "arrow.left", id: "tv-animal-options-back", perform: closeOptions)
        }
        .foregroundStyle(.white).frame(width: 1150, alignment: .leading).padding(50)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 32))
    }

    private func hintScreen(_ entry: AnimalExplorerEntry) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Look closely").font(.system(size: 54, weight: .black, design: .rounded))
            Text(entry.hint ?? entry.neutralPhotoDescription).font(.system(size: 32, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("tv-animal-hint-copy")
            Text("The timer is paused while you look. Hints count as help.")
                .font(.system(size: 24, weight: .semibold)).foregroundStyle(.white.opacity(0.68))
            action("Back to choices", symbol: "arrow.left", id: "tv-animal-hint-back", perform: closeHint)
        }
        .foregroundStyle(.white).frame(width: 1150, alignment: .leading).padding(50)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 32))
    }

    private var completionScreen: some View {
        VStack(spacing: 28) {
            Image(systemName: "sparkles").font(.system(size: 88, weight: .black)).foregroundStyle(.yellow)
            Text("Animals explored!").font(.system(size: 60, weight: .black, design: .rounded))
                .accessibilityIdentifier("tv-memory-completion-title")
            Text("You explored \(game.roundGoal) real animal photographs.")
                .font(.system(size: 28, weight: .semibold)).foregroundStyle(.white.opacity(0.74))
            HStack(spacing: 26) {
                stat("Matched", value: game.correctCount, symbol: "checkmark")
                stat("Best streak", value: game.bestStreak, symbol: "flame.fill")
            }
            Text("Keep noticing shapes, markings and animal homes.").font(.system(size: 25, weight: .semibold))
            HStack(spacing: 26) {
                action("Play this gallery again", symbol: "arrow.clockwise", id: "tv-memory-replay", perform: startQuiz)
                action("Back to photos", symbol: "photo.on.rectangle", id: "tv-memory-choose-gallery", perform: returnToBrowse)
            }
        }.foregroundStyle(.white).frame(maxWidth: 1600, maxHeight: .infinity)
    }

    private func action(_ title: String, symbol: String, id: String, enabled: Bool = true, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Label(title, systemImage: symbol).font(.system(size: 22, weight: .black, design: .rounded))
                .padding(.horizontal, 25).frame(minHeight: 72)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(AnimalExplorerButtonStyle(reduceMotion: motionReduced))
        .focused($focusedID, equals: id).disabled(!enabled).accessibilityIdentifier(id)
    }

    private func stat(_ title: String, value: Int, symbol: String) -> some View {
        Label("\(value) \(title)", systemImage: symbol)
            .font(.system(size: 23, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.78, green: 0.94, blue: 0.66))
            .padding(18).background(.white.opacity(0.08), in: Capsule())
            .accessibilityIdentifier("tv-animal-stat-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }

    private func photo(_ entry: AnimalExplorerEntry) -> some View {
        Group {
            if let name = entry.card.imageAssetName {
                if let url = contentStore.assetURL(named: name), let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image).resizable().scaledToFit()
                } else {
                    Image(name).resizable().scaledToFit()
                }
            } else {
                Image(systemName: "photo").resizable().scaledToFit().padding(45)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.20)).accessibilityHidden(true)
    }

    private func chooseCollection(_ item: AnimalExplorerCollection) {
        collectionID = item.id
        present("\(item.title). \(item.spokenDescription) \(collectionEntries.count) animal photographs. Choose a photo or start a photo name quiz.")
    }

    private func openDetail(_ entry: AnimalExplorerEntry) {
        detailID = entry.id
        phase = .detail
        recordExposure(entry)
        let facts = entry.card.detailCards.prefix(2).map { "\($0.title). \($0.value)." }.joined(separator: " ")
        present("\(entry.card.name). \(entry.neutralPhotoDescription) \(facts) Select Back to photos to keep exploring.")
        focus("tv-animal-detail-back")
    }

    private func startQuiz() {
        let deck = collectionEntries.map(\.card)
        guard deck.count >= MemoryGalleryTVRound.choiceCount else { return }
        sessionID = UUID().uuidString
        sessionStartedAt = Date()
        hintedRounds = []
        didComplete = false
        detailID = nil
        game.start(category: .animals, deck: deck, seed: uiTesting ? 42 : nil, roundLimit: min(6, deck.count))
        phase = .quiz
        startRound()
    }

    private func startRound() {
        clock.resume(.feedback)
        clock.configure(seconds: timerSeconds)
        clock.start()
        if scenePhase != .active { clock.pause(.background) }
        present("\(game.progressText). Which animal is in the photograph? Swipe to hear the names, then press select. Take your time. Hints are available.")
        focusFirstAnswer()
    }

    private func select(_ answer: MemoryAnimal, round: MemoryGalleryTVRound) {
        guard phase == .quiz, !showsHint, !showsOptions, !game.hasAnsweredCurrentRound,
              round.index == game.round?.index, let entry = promptEntry else { return }
        let correct = game.select(answerID: answer.id)
        clock.pause(.feedback)
        emit(.answer, entry: entry, roundIndex: game.roundIndex, responseID: answer.id, correct: correct,
             appHintUsed: hintedRounds.contains(game.roundIndex), wasExplored: viewedVariants.contains(variantID(entry)))
        present(correct ? "Matched! You found \(entry.card.name). Select to continue." : "Good try. This is \(entry.card.name). Select to continue.")
        focus(nextFocusID)
    }

    private var nextFocusID: String { game.completedRoundCount == game.roundGoal ? "tv-memory-see-results" : "tv-memory-next-picture" }

    private func advance() {
        guard game.hasAnsweredCurrentRound else { return }
        game.advance()
        if game.phase == .completed {
            clock.stop()
            phase = .completed
            if !didComplete {
                didComplete = true
                emit(.completed, completedRoundCount: game.completedRoundCount, correctCount: game.correctCount)
            }
            present("Animals explored. You matched \(game.correctCount) of \(game.roundGoal). Play again, or return to the photos.")
            focus("tv-memory-replay")
        } else { startRound() }
    }

    private func returnToBrowse() {
        clock.stop()
        let previousDetail = detailID.flatMap { id in entries.first { $0.id == id } }
        detailID = nil
        phase = .browsing
        sessionID = UUID().uuidString
        sessionStartedAt = Date()
        present("\(collection?.title ?? "Animals"). Choose a photo, or start a photo name quiz.")
        focus(previousDetail.map(cardFocusID) ?? "tv-animal-start-quiz")
    }

    private func openOptions() {
        returnFocusID = focusedID
        clock.pause(.options)
        showsOptions = true
        present("Animal options. Choose no timer, a friendly timer, or sound. Your current picture stays the same.")
        focus("tv-animal-option-no-timer")
    }

    private func closeOptions() {
        showsOptions = false
        clock.resume(.options)
        focus(returnFocusID ?? "tv-animal-options")
    }

    private func openHint() {
        guard phase == .quiz, !game.hasAnsweredCurrentRound, !showsHint, !showsOptions, let entry = promptEntry else { return }
        returnFocusID = focusedID
        clock.pause(.hint)
        showsHint = true
        if hintedRounds.insert(game.roundIndex).inserted { emit(.help, entry: entry, roundIndex: game.roundIndex, appHintUsed: true) }
        present("Look closely. \(entry.hint ?? entry.neutralPhotoDescription) The timer is paused. Select Back to choices when you are ready.")
        focus("tv-animal-hint-back")
    }

    private func closeHint() {
        showsHint = false
        clock.resume(.hint)
        focus(returnFocusID ?? game.round?.answerChoices.first.map { "tv-memory-answer-\($0.id)" })
    }

    private func exit() {
        if showsOptions { closeOptions() }
        else if showsHint { closeHint() }
        else if phase != .browsing { returnToBrowse() }
        else { clock.stop(); narration.stop(); onClose() }
    }

    private func emit(_ kind: AnimalExplorerLearningEvent.Kind, entry: AnimalExplorerEntry? = nil, roundIndex: Int? = nil,
                      responseID: String? = nil, correct: Bool? = nil, appHintUsed: Bool = false, wasExplored: Bool = false,
                      completedRoundCount: Int? = nil, correctCount: Int? = nil) {
        onLearningEvent(AnimalExplorerLearningEvent(kind: kind, sessionID: sessionID, startedAt: sessionStartedAt,
            contentVersion: contentVersion, cardID: entry?.card.id, speciesID: entry?.speciesID,
            itemVariantID: entry.map(variantID), roundIndex: roundIndex, responseID: responseID, correct: correct,
            appHintUsed: appHintUsed, wasExploredBeforeAnswer: wasExplored,
            completedRoundCount: completedRoundCount, correctCount: correctCount))
    }

    private func variantID(_ entry: AnimalExplorerEntry) -> String { entry.card.imageAssetName ?? entry.card.id }
    private func recordExposure(_ entry: AnimalExplorerEntry) {
        if viewedVariants.insert(variantID(entry)).inserted { emit(.exposure, entry: entry) }
    }
    private func cardFocusID(_ entry: AnimalExplorerEntry) -> String { "tv-animal-card-\(entry.id)" }
    private func entryCount(for id: String) -> Int { Set(entries.filter { $0.collectionIDs.contains(id) }.map(\.speciesID)).count }
    private func focusFirstAnswer() { focus(game.round?.answerChoices.first.map { "tv-memory-answer-\($0.id)" }) }
    private func focus(_ id: String?) {
        focusGeneration += 1
        let generation = focusGeneration
        Task { @MainActor in
            await Task.yield()
            guard isVisible, scenePhase == .active, focusGeneration == generation else { return }
            focusedID = id
        }
    }
    private func present(_ text: String) { narration.presentPrompt(text) }

    private func focusNarration(_ id: String?) -> String? {
        guard let id else { return nil }
        if id.hasPrefix("tv-memory-answer-") { return game.round?.answerChoices.first { "tv-memory-answer-\($0.id)" == id }?.name }
        if let entry = collectionEntries.first(where: { cardFocusID($0) == id }) { return "\(entry.card.name). Select to explore this photograph." }
        if let collection = collections.first(where: { "tv-animal-collection-\($0.id)" == id }) { return "\(collection.title). \(collection.spokenDescription)" }
        switch id {
        case "tv-animal-start-quiz", "tv-animal-detail-quiz": return "Photo name quiz. Match six animal photographs with their names."
        case "tv-animal-options", "tv-animal-quiz-options": return "Options. Choose a timer or change sound."
        case "tv-animal-hint": return "Look closely hint. The timer pauses while you look."
        case "tv-animal-detail-back": return "Back to the animal photographs."
        case "tv-animal-detail-reading": return detailEntry.map {
            $0.card.detailCards.prefix(3).map { "\($0.title). \($0.value)." }.joined(separator: " ")
        }
        case "tv-animal-classic-quiz": return "Illustrated animal quiz. Play the original picture name quiz."
        default: return nil
        }
    }

    private func answerSymbol(_ answer: MemoryAnimal, round: MemoryGalleryTVRound) -> String {
        guard game.hasAnsweredCurrentRound else { return "circle" }
        if answer.id == round.correctAnswerID { return "checkmark.circle.fill" }
        return answer.id == game.selectedAnswerID ? "xmark.circle.fill" : "circle"
    }

    private func answerColor(_ answer: MemoryAnimal, round: MemoryGalleryTVRound) -> Color {
        guard game.hasAnsweredCurrentRound else { return .white.opacity(0.08) }
        if answer.id == round.correctAnswerID { return Color(red: 0.18, green: 0.43, blue: 0.30) }
        if answer.id == game.selectedAnswerID { return Color(red: 0.46, green: 0.22, blue: 0.20) }
        return .white.opacity(0.04)
    }
}

private struct AnimalExplorerButtonStyle: ButtonStyle {
    let reduceMotion: Bool
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isFocused ? Color.white : .clear, lineWidth: 4))
            .background(isFocused ? Color.white.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 20))
            .scaleEffect(isFocused && !reduceMotion ? 1.025 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isFocused)
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}
