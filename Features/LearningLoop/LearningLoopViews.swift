import Observation
import SwiftUI

struct LearningCardIntroView: View {
    let cards: [LearningConceptCard]
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 14) {
            if !compact {
                Text("Learn")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? 128 : 150), spacing: compact ? 8 : 12)], spacing: compact ? 8 : 12) {
                ForEach(cards) { card in
                    VStack(alignment: .leading, spacing: compact ? 5 : 8) {
                        Text(card.visualKey)
                            .font(.system(size: compact ? 34 : 44))
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(card.title)
                            .font((compact ? Font.subheadline : .headline).weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text(card.explanation)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .lineLimit(compact ? 2 : nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(compact ? 10 : 14)
                    .frame(maxWidth: .infinity, minHeight: compact ? 118 : 150, alignment: .topLeading)
                    .background(MatherTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: compact ? 16 : 20, style: .continuous))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(card.title). \(card.explanation)")
                }
            }
        }
    }
}

struct SoundConceptFlashcardCarouselView: View {
    let cards: [LearningConceptCard]
    @Binding var selectedIndex: Int
    let onPlaySound: (LearningConceptCard) -> Void

    private var safeIndex: Int {
        guard !cards.isEmpty else { return 0 }
        return min(max(selectedIndex, 0), cards.count - 1)
    }

    private var activeCard: LearningConceptCard? {
        guard cards.indices.contains(safeIndex) else { return nil }
        return cards[safeIndex]
    }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Flashcards")
                            .font(.title2.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text(cards.isEmpty ? "No cards" : "Card \(safeIndex + 1) of \(cards.count)")
                            .font(.caption.weight(.black).monospacedDigit())
                            .foregroundStyle(MatherTheme.accent)
                    }
                    Spacer()
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .font(.title2.weight(.black))
                        .foregroundStyle(MatherTheme.accent)
                        .accessibilityHidden(true)
                }

                if let card = activeCard {
                    HStack(alignment: .center, spacing: 14) {
                        Text(card.visualKey)
                            .font(.system(size: 48, weight: .bold))
                            .frame(width: 64, height: 64)
                            .background(MatherTheme.softBlue.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.title)
                                .font(.title3.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text(card.explanation)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            selectedIndex = max(0, safeIndex - 1)
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: true))
                        .disabled(safeIndex == 0)

                        Button {
                            onPlaySound(card)
                        } label: {
                            Label("Play sound", systemImage: "speaker.wave.2.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: true))
                        .accessibilityLabel(card.soundExample?.accessibilityLabel ?? "Play hearing-safe sound example")
                        .accessibilityIdentifier("SoundLabPlaySound-\(card.id)")
                        .disabled(card.soundExample == nil)

                        Button {
                            selectedIndex = min(cards.count - 1, safeIndex + 1)
                        } label: {
                            Label("Next", systemImage: "chevron.right")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: true))
                        .disabled(safeIndex >= cards.count - 1)
                    }

                    Text("Short, low-volume examples only. No microphone or live loudness meter is used.")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatherTheme.panelDeep)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MatherTheme.warm.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .onChange(of: cards.count) { _, _ in
            selectedIndex = safeIndex
        }
        .accessibilityElement(children: .contain)
    }
}


struct ConceptQuizRoundView: View {
    let questions: [ConceptQuizQuestion]
    @Binding var answersByQuestionId: [String: String]
    @State private var activeIndex = 0
    @State private var selectedChoice: String?
    @State private var celebratingQuestionId: String?

    private var safeIndex: Int {
        guard !questions.isEmpty else { return 0 }
        return min(max(activeIndex, 0), questions.count - 1)
    }

    private var activeQuestion: ConceptQuizQuestion? {
        guard questions.indices.contains(safeIndex) else { return nil }
        return questions[safeIndex]
    }

    private var progressText: String {
        guard !questions.isEmpty else { return "0 of 0" }
        return "Question \(safeIndex + 1) of \(questions.count)"
    }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quiz")
                            .font(.title2.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text(progressText)
                            .font(.caption.weight(.black).monospacedDigit())
                            .foregroundStyle(MatherTheme.accent)
                    }
                    Spacer()
                    if isComplete {
                        Label("Done", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.black))
                            .foregroundStyle(MatherTheme.accent)
                    }
                }

                if let question = activeQuestion, !isComplete {
                    activeQuestionCard(question)
                } else {
                    Text("Quiz complete — great listening detective work!")
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MatherTheme.softBlue.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .sensoryFeedback(.success, trigger: celebratingQuestionId)
        .onChange(of: questions.count) { _, _ in
            activeIndex = min(activeIndex, max(questions.count - 1, 0))
            selectedChoice = nil
            celebratingQuestionId = nil
        }
    }

    private var isComplete: Bool {
        !questions.isEmpty && activeIndex >= questions.count
    }

    private func activeQuestionCard(_ question: ConceptQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.prompt)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 8) {
                ForEach(question.choices, id: \.self) { choice in
                    Button {
                        choose(choice, for: question)
                    } label: {
                        HStack(spacing: 8) {
                            Text(choice)
                                .font(.subheadline.weight(.bold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.76)
                            Spacer(minLength: 0)
                            if selectedChoice == choice {
                                Image(systemName: question.isCorrect(choice) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.headline.weight(.black))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(choiceFill(for: choice, in: question))
                        .foregroundStyle(MatherTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .scaleEffect(celebratingQuestionId == question.id && selectedChoice == choice ? 1.04 : 1.0)
                        .animation(.spring(response: 0.24, dampingFraction: 0.62), value: celebratingQuestionId)
                    }
                    .buttonStyle(.plain)
                    .disabled(celebratingQuestionId == question.id)
                    .accessibilityLabel("\(choice) answer")
                }
            }
            if let selectedChoice {
                Text(question.isCorrect(selectedChoice) ? question.feedback : "Try again — this question stays here until you find the safe answer.")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(question.isCorrect(selectedChoice) ? .green : MatherTheme.coral)
                    .accessibilityIdentifier("SoundVolumeQuizFeedback")
            }
        }
        .padding(14)
        .background(MatherTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func choose(_ choice: String, for question: ConceptQuizQuestion) {
        guard celebratingQuestionId == nil else { return }
        selectedChoice = choice
        answersByQuestionId[question.id] = choice
        if question.isCorrect(choice) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
                celebratingQuestionId = question.id
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 650_000_000)
                guard celebratingQuestionId == question.id else { return }
                activeIndex = min(activeIndex + 1, questions.count)
                selectedChoice = nil
                celebratingQuestionId = nil
            }
        }
    }

    private func choiceFill(for choice: String, in question: ConceptQuizQuestion) -> Color {
        guard selectedChoice == choice else {
            return MatherTheme.softBlue.opacity(0.45)
        }
        return question.isCorrect(choice) ? .green.opacity(0.28) : MatherTheme.coral.opacity(0.28)
    }
}

enum ConceptMixMatchHapticCue {
    case select
    case success
    case error
    case complete
}

struct ConceptMixMatchRoundView: View {
    let pairs: [ConceptMatchPair]
    let shuffleSeed: UInt64?
    @Binding var selectedLeft: String?
    @Binding var matchedPairIds: Set<String>
    let onFeedback: (String) -> Void
    let onHapticCue: (ConceptMixMatchHapticCue) -> Void

    init(
        pairs: [ConceptMatchPair],
        shuffleSeed: UInt64? = nil,
        selectedLeft: Binding<String?>,
        matchedPairIds: Binding<Set<String>>,
        onFeedback: @escaping (String) -> Void,
        onHapticCue: @escaping (ConceptMixMatchHapticCue) -> Void = { _ in }
    ) {
        self.pairs = pairs
        self.shuffleSeed = shuffleSeed
        self._selectedLeft = selectedLeft
        self._matchedPairIds = matchedPairIds
        self.onFeedback = onFeedback
        self.onHapticCue = onHapticCue
    }

    @State private var mismatchedPairId: String?

    private var matchCount: Int {
        pairs.filter { matchedPairIds.contains($0.id) }.count
    }

    private var isComplete: Bool {
        matchCount == pairs.count
    }

    private var rowOrder: ConceptMatchRowOrder {
        if let shuffleSeed {
            return LearningLoopScoring.shuffledMatchRowOrder(pairs: pairs, seed: shuffleSeed)
        }
        return LearningLoopScoring.orderedMatchRowOrder(pairs: pairs)
    }

    private var pairsById: [String: ConceptMatchPair] {
        Dictionary(uniqueKeysWithValues: pairs.map { ($0.id, $0) })
    }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                headerView
                matchBoard
                progressDots
            }
        }
        .sensoryFeedback(.success, trigger: matchCount)
        .accessibilityLabel("Mix and Match. \(matchCount) of \(pairs.count) matched.")
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Mix + Match")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Spacer()
                Text("\(matchCount)/\(pairs.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(MatherTheme.accent.opacity(0.16))
                    .clipShape(Capsule())
            }
            Text(isComplete ? "All matches locked — nice cycle work!" : selectedLeft == nil ? "Pick a picture card, then tap its matching name." : "Now find its match.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
    }

    private var matchBoard: some View {
        HStack(alignment: .top, spacing: 10) {
            matchColumn(title: "Picture", side: .left)
            VStack(spacing: 8) {
                Text(" ")
                    .font(.caption.weight(.black))
                ForEach(rightPairs) { pair in
                    Image(systemName: matchedPairIds.contains(pair.id) ? "checkmark.circle.fill" : "arrow.right")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(matchedPairIds.contains(pair.id) ? MatherTheme.accent : Color.secondary.opacity(0.45))
                        .frame(height: 58)
                }
            }
            .accessibilityHidden(true)
            matchColumn(title: "Name", side: .right)
        }
    }

    private enum MatchSide {
        case left
        case right
    }

    private func matchColumn(title: String, side: MatchSide) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(MatherTheme.cardSubtitle)
            ForEach(side == .left ? leftPairs : rightPairs) { pair in
                matchCard(pair: pair, side: side)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var leftPairs: [ConceptMatchPair] {
        rowOrder.leftPairIds.compactMap { pairsById[$0] }
    }

    private var rightPairs: [ConceptMatchPair] {
        rowOrder.rightPairIds.compactMap { pairsById[$0] }
    }

    private func matchCard(pair: ConceptMatchPair, side: MatchSide) -> some View {
        let isLeft = side == .left
        let isMatched = matchedPairIds.contains(pair.id)
        let isSelected = isLeft && selectedLeft == pair.id
        let isMismatched = !isLeft && mismatchedPairId == pair.id
        let visualKey = isLeft ? pair.leftVisualKey : pair.rightVisualKey
        let label = isLeft ? pair.left : pair.right

        return Button {
            handleTap(pair: pair, side: side)
        } label: {
            HStack(spacing: 8) {
                if let visualKey {
                    Text(visualKey)
                        .font(.title3)
                        .frame(width: 28)
                }
                Text(label)
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity, alignment: visualKey == nil ? .center : .leading)
                if isMatched {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MatherTheme.accent)
                        .font(.caption.weight(.black))
                }
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(tileFill(isMatched: isMatched, isSelected: isSelected, isMismatched: isMismatched, side: side))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(tileStroke(isMatched: isMatched, isSelected: isSelected), lineWidth: isSelected ? 3 : isMatched ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: isSelected ? MatherTheme.warm.opacity(0.30) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isSelected)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isMatched)
        .accessibilityLabel("\(label)\(isMatched ? ", matched" : isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(pairs) { pair in
                Circle()
                    .fill(matchedPairIds.contains(pair.id) ? MatherTheme.accent : Color.secondary.opacity(0.24))
                    .frame(width: 10, height: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: matchCount)
    }

    private func handleTap(pair: ConceptMatchPair, side: MatchSide) {
        guard !matchedPairIds.contains(pair.id) else { return }
        switch side {
        case .left:
            selectedLeft = selectedLeft == pair.id ? nil : pair.id
            mismatchedPairId = nil
            if selectedLeft != nil {
                onHapticCue(.select)
            }
            onFeedback(selectedLeft == nil ? "Pick a picture card." : "Now pick what goes with \(pair.left).")
        case .right:
            switch LearningLoopScoring.matchAttempt(
                selectedPairId: selectedLeft,
                targetPairId: pair.id,
                pairs: pairs,
                matchedPairIds: matchedPairIds
            ) {
            case .locked(let pairId, let feedback):
                matchedPairIds.insert(pairId)
                selectedLeft = nil
                mismatchedPairId = nil
                onHapticCue(matchedPairIds.count == pairs.count ? .complete : .success)
                onFeedback(feedback)
            case .mismatch(let feedback):
                mismatchedPairId = pair.id
                onHapticCue(.error)
                onFeedback(feedback)
            case .missingSelection:
                onHapticCue(.error)
                onFeedback("Pick a picture card first.")
            case .alreadyMatched:
                break
            }
        }
    }

    private func tileFill(isMatched: Bool, isSelected: Bool, isMismatched: Bool, side: MatchSide) -> Color {
        if isMatched { return MatherTheme.accent.opacity(0.18) }
        if isMismatched { return MatherTheme.coral.opacity(0.22) }
        if isSelected { return MatherTheme.warm.opacity(0.62) }
        return side == .left ? MatherTheme.warm.opacity(0.18) : MatherTheme.softBlue.opacity(0.18)
    }

    private func tileStroke(isMatched: Bool, isSelected: Bool) -> Color {
        if isMatched { return MatherTheme.accent.opacity(0.75) }
        if isSelected { return MatherTheme.warm }
        return Color.secondary.opacity(0.12)
    }
}


private enum SoundVolumeActivityStage: CaseIterable {
    case flashcards
    case meterPitch
    case quiz
    case match
    case summary

    var title: String {
        switch self {
        case .flashcards: return "Flashcards"
        case .meterPitch: return "Meter + Pitch"
        case .quiz: return "Quiz"
        case .match: return "Mix + Match"
        case .summary: return "Stars"
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .flashcards: return "Try Meter + Pitch"
        case .meterPitch: return "Go to Quiz"
        case .quiz: return "Go to Mix + Match"
        case .match: return "See Sound Score"
        case .summary: return "Review Flashcards"
        }
    }

    var primaryActionIcon: String {
        switch self {
        case .flashcards: return "waveform"
        case .meterPitch: return "checkmark.circle.fill"
        case .quiz: return "rectangle.grid.2x2.fill"
        case .match: return "star.fill"
        case .summary: return "arrow.counterclockwise"
        }
    }

    var next: SoundVolumeActivityStage {
        switch self {
        case .flashcards: return .meterPitch
        case .meterPitch: return .quiz
        case .quiz: return .match
        case .match: return .summary
        case .summary: return .flashcards
        }
    }

    var previous: SoundVolumeActivityStage {
        switch self {
        case .flashcards: return .summary
        case .meterPitch: return .flashcards
        case .quiz: return .meterPitch
        case .match: return .quiz
        case .summary: return .match
        }
    }
}

struct SoundVolumeLabView: View {
    @Bindable var appModel: AppModel
    @State private var introPageIndex = 0
    @State private var hasStartedActivities = false
    @State private var activityStage: SoundVolumeActivityStage = .flashcards
    @State private var selectedSoundCardIndex = 0
    @State private var answersByQuestionId: [String: String] = [:]
    @State private var selectedMatchPairId: String?
    @State private var matchedPairIds: Set<String> = []
    @State private var matchShuffleSeed = UInt64.random(in: UInt64.min...UInt64.max)
    @State private var feedback = SoundVolumeContent.safetyNote
    @State private var pitchChallengeState = SoundPitchChallengeState(challenge: SoundVolumeContent.pitchChallenge)

    private var introPages: [SoundVolumeIntroPage] { SoundVolumeContent.introPages }
    private var safeIntroPageIndex: Int { SoundVolumeContent.clampedIntroPageIndex(introPageIndex) }
    private var introPage: SoundVolumeIntroPage { SoundVolumeContent.introPage(for: introPageIndex) }
    private var isFirstIntroPage: Bool { safeIntroPageIndex == 0 }
    private var isLastIntroPage: Bool { safeIntroPageIndex == introPages.count - 1 }

    private var summary: LearningLoopSummary {
        LearningLoopScoring.summary(
            questions: SoundVolumeContent.quizQuestions,
            answersByQuestionId: answersByQuestionId,
            matchedPairIds: matchedPairIds,
            pairs: SoundVolumeContent.matchPairs
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if hasStartedActivities {
                        activityHeader
                        activityStagePicker
                        currentActivityStage
                        activityStageControls
                    } else {
                        stagedIntroCard
                    }
                }
                .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                .padding(.top, 22)
                .padding(.bottom, hasStartedActivities ? 22 : 118)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .background(MatherTheme.background.ignoresSafeArea())
        }
        .navigationTitle("Sound Lab")
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    appModel.engine.showLabLane(.physics)
                } label: {
                    Label("Physics", systemImage: "chevron.left")
                        .font(.subheadline.weight(.black))
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .safeAreaInset(edge: .bottom) {
            if !hasStartedActivities {
                introControls
            }
        }
        .onDisappear {
            appModel.soundDetectionService.stopSoundLabMeter()
            if summary.starCount > 0 || matchedPairIds.count == SoundVolumeContent.matchPairs.count {
                appModel.markExplorerLabModeCompleted(laneID: .physics, mode: .review)
                appModel.setExplorerLabConceptConfidence(.steady, for: ConceptId(rawValue: "sound-volume"), laneID: .physics)
            }
        }
    }

    private var stagedIntroCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 16) {
                Text(introPage.eyebrow.uppercased())
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.accent)
                    .tracking(1.3)
                HStack(alignment: .top, spacing: 14) {
                    Text(introPage.visualKey)
                        .font(.system(size: 64))
                        .frame(width: 76)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(introPage.title)
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                            .minimumScaleFactor(0.72)
                        Text(introPage.subtitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                introPageContent
                introProgressDots
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var introPageContent: some View {
        switch introPage.id {
        case "welcome":
            soundClueChips(SoundVolumeContent.cards.prefix(4).map { ($0.visualKey, $0.title) })
        case "safety":
            safetyBanner
        case "decibels":
            decibelTeachingCard
        case "zones":
            loudnessZones
        default:
            soundClueChips(SoundVolumeContent.cards.map { ($0.visualKey, $0.title) })
        }
    }

    private var introProgressDots: some View {
        HStack(spacing: 8) {
            ForEach(introPages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == safeIntroPageIndex ? MatherTheme.accent : MatherTheme.softBlue.opacity(0.35))
                    .frame(width: index == safeIntroPageIndex ? 28 : 10, height: 10)
                    .accessibilityLabel("Intro step \(index + 1) of \(introPages.count)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var introControls: some View {
        VStack(spacing: 10) {
            Button {
                advanceIntro()
            } label: {
                Label(introPage.primaryActionTitle, systemImage: introPage.primaryActionIcon)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("SoundVolumeIntroPrimaryAction")

            if !isFirstIntroPage {
                Button {
                    introPageIndex = SoundVolumeContent.clampedIntroPageIndex(introPageIndex - 1)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.thinMaterial)
    }

    private func advanceIntro() {
        if isLastIntroPage {
            hasStartedActivities = true
            activityStage = .flashcards
            feedback = "Start with flashcards. Tap Play sound for a short, hearing-safe example."
        } else {
            introPageIndex = SoundVolumeContent.clampedIntroPageIndex(safeIntroPageIndex + 1)
        }
    }

    private func soundClueChips(_ chips: [(String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                HStack(spacing: 8) {
                    Text(chip.0)
                    Text(chip.1)
                        .font(.caption.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MatherTheme.softBlue.opacity(0.20))
                .clipShape(Capsule())
                .accessibilityElement(children: .combine)
            }
        }
    }


    private var activityStagePicker: some View {
        HStack(spacing: 8) {
            ForEach(SoundVolumeActivityStage.allCases, id: \.self) { stage in
                Text(stage.title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(stage == activityStage ? .white : MatherTheme.accent)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(stage == activityStage ? MatherTheme.accent : MatherTheme.accent.opacity(0.14))
                    .clipShape(Capsule())
                    .accessibilityLabel("Sound Lab stage \(stage.title)\(stage == activityStage ? ", current" : "")")
            }
        }
    }

    @ViewBuilder
    private var currentActivityStage: some View {
        switch activityStage {
        case .flashcards:
            SoundConceptFlashcardCarouselView(
                cards: SoundVolumeContent.cards,
                selectedIndex: $selectedSoundCardIndex,
                onPlaySound: playSoundExample
            )
        case .meterPitch:
            soundMeterPitchActivity
        case .quiz:
            ConceptQuizRoundView(
                questions: SoundVolumeContent.quizQuestions,
                answersByQuestionId: $answersByQuestionId
            )
        case .match:
            ConceptMixMatchRoundView(
                pairs: SoundVolumeContent.matchPairs,
                shuffleSeed: matchShuffleSeed,
                selectedLeft: $selectedMatchPairId,
                matchedPairIds: $matchedPairIds,
                onFeedback: { feedback = $0 },
                onHapticCue: playSoundMatchHaptic
            )
        case .summary:
            summaryCard
        }
    }

    private var activityStageControls: some View {
        HStack(spacing: 10) {
            if activityStage != .flashcards {
                Button {
                    setActivityStage(activityStage.previous)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Button {
                setActivityStage(activityStage.next)
            } label: {
                Label(activityStage.primaryActionTitle, systemImage: activityStage.primaryActionIcon)
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!canAdvanceCurrentActivity)
        }
    }

    private var canAdvanceCurrentActivity: Bool {
        switch activityStage {
        case .quiz:
            return SoundVolumeContent.quizQuestions.allSatisfy { answersByQuestionId[$0.id] == $0.correctChoice }
        default:
            return true
        }
    }

    private func setActivityStage(_ newStage: SoundVolumeActivityStage) {
        if activityStage == .meterPitch && newStage != .meterPitch {
            appModel.soundDetectionService.stopSoundLabMeter()
        }
        activityStage = newStage
        updateFeedbackForCurrentStage()
    }

    private func updateFeedbackForCurrentStage() {
        switch activityStage {
        case .flashcards:
            feedback = "Tap Play sound on each card for a short, hearing-safe example."
        case .meterPitch:
            feedback = "Try the local-only meter with normal room sounds, then answer the pitch card."
        case .quiz:
            feedback = "Now try the quiz. Use the flashcard clues you heard."
        case .match:
            feedback = "Now match each sound clue to its safe idea."
        case .summary:
            feedback = "Review your Sound Lab score."
        }
    }

    private func playSoundExample(for card: LearningConceptCard) {
        guard let soundExample = card.soundExample else { return }
        appModel.speechService.playSoundExample(soundExample, enabled: appModel.featureFlags.audioEnabled)
        appModel.hapticsService.cardPickup(enabled: appModel.featureFlags.hapticsEnabled)
        feedback = "Played a short, hearing-safe \(soundExample.label) example for \(card.title)."
    }

    private func playSoundMatchHaptic(_ cue: ConceptMixMatchHapticCue) {
        let enabled = appModel.featureFlags.hapticsEnabled
        switch cue {
        case .select:
            appModel.hapticsService.cardPickup(enabled: enabled)
        case .success:
            appModel.hapticsService.cardSnapCorrect(enabled: enabled)
        case .error:
            appModel.hapticsService.cardSnapMismatch(enabled: enabled)
        case .complete:
            appModel.hapticsService.cardSnapCorrect(enabled: enabled)
            appModel.hapticsService.bondMatchComplete(enabled: enabled)
        }
    }

    private var activityHeader: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Text("🔊")
                        .font(.system(size: 58))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sound + Volume Lab")
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                            .minimumScaleFactor(0.75)
                        Text("Try a local-only meter, pitch cards, quiz, and safe listening matches. No recording, no loudness rewards.")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }
                Text(feedback)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MatherTheme.panelDeep)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MatherTheme.softBlue.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var safetyBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "ear")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Hearing-safe play")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("The meter asks for microphone access only after you tap Start. Audio stays on this device as a loudness number only: no recording, no storage, no sending. No shouting or loud-noise challenge.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
        }
        .padding(14)
        .background(MatherTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }


    private var decibelTeachingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Decibel = dB")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Text("A decibel is a loudness number. A whisper has a small dB number. A siren has a big dB number. We use dB cards only after learning what the unit means.")
                .font(.headline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Label("small dB = softer", systemImage: "speaker.fill")
                Label("big dB = louder", systemImage: "speaker.wave.3.fill")
            }
            .font(.caption.weight(.black))
            .foregroundStyle(MatherTheme.accent)
        }
        .padding(14)
        .background(MatherTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var loudnessZones: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Estimated loudness zones")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Text("These are learning examples. The live meter is estimated, not calibrated safety equipment.")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(SoundVolumeContent.estimatedZones, id: \.self) { zone in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(zone.label)
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text(zone.estimatedRangeLabel)
                            .font(.caption.weight(.black))
                            .foregroundStyle(MatherTheme.accent)
                        Text(zone.safetyCopy)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
                    .background(zoneFill(zone))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(zone.label), estimated \(zone.estimatedRangeLabel). \(zone.safetyCopy)")
                }
            }
        }
    }


    private var soundMeterPitchActivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            soundMeterCard
            pitchFollowUpRouteCard
        }
    }

    private var soundMeterCard: some View {
        let reading = appModel.soundDetectionService.meterReading
        let permissionState = appModel.soundDetectionService.meterPermissionState
        return CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .font(.title.weight(.black))
                        .foregroundStyle(MatherTheme.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hearing-safe sound meter")
                            .font(.title2.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text(SoundMeterReading.privacyCopy)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(SoundMeterReading.safetyCopy)
                            .font(.caption.weight(.black))
                            .foregroundStyle(MatherTheme.panelDeep)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(permissionState.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Spacer()
                        Text("~\(reading.roundedEstimatedDecibels) dB")
                            .font(.headline.monospacedDigit().weight(.black))
                            .foregroundStyle(MatherTheme.accent)
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(MatherTheme.softBlue.opacity(0.30))
                            Capsule()
                                .fill(meterFill(reading.bucket))
                                .frame(width: max(CGFloat(12), proxy.size.width * CGFloat(reading.bucket.fillFraction)))
                        }
                    }
                    .frame(height: 18)
                    Text("\(reading.bucket.label): \(reading.bucket.targetCopy)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
                .padding(12)
                .background(MatherTheme.card.opacity(0.70))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(permissionState.guidance)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button {
                        appModel.soundDetectionService.startSoundLabMeter()
                        feedback = soundMeterStartFeedback(for: appModel.soundDetectionService.meterPermissionState)
                    } label: {
                        Label("Start local meter", systemImage: "mic.circle.fill")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityIdentifier("SoundLabStartLocalMeter")

                    Button {
                        appModel.soundDetectionService.stopSoundLabMeter()
                        feedback = "Meter stopped. Audio was not recorded or saved."
                    } label: {
                        Label("Stop", systemImage: "stop.circle.fill")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("SoundLabStopLocalMeter")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var pitchFollowUpRouteCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text(SoundVolumeContent.pitchFollowUpTitle)
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("Open a focused pitch screen after the meter. Pitch is separate from loudness, so no microphone or louder sound is needed.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    SoundPitchFollowUpView(
                        pitchChallengeState: $pitchChallengeState,
                        onFeedback: { feedback = $0 }
                    )
                } label: {
                    Label(SoundVolumeContent.pitchFollowUpRouteTitle, systemImage: "music.note.list")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("SoundPitchFollowUpRoute")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func meterFill(_ bucket: SoundMeterLevelBucket) -> Color {
        switch bucket {
        case .quiet: return MatherTheme.softBlue
        case .comfortable: return MatherTheme.accent
        case .busy: return MatherTheme.warm
        case .protect: return MatherTheme.coral
        }
    }

    private func soundMeterStartFeedback(for state: SoundMeterPermissionState) -> String {
        switch state {
        case .notStarted:
            return "Meter is off. Sound Lab still works with hearing-safe examples and pitch cards."
        case .requestingPermission:
            return "Checking microphone access. If it is off, keep using no-mic learning mode."
        case .listening:
            return "Meter started. Use normal room sounds only — no shouting and no points for loudness."
        case .unavailable:
            return "Microphone is unavailable right now. Keep using no-mic learning mode with the safe example cards."
        case .denied:
            return "Microphone access is off. Keep using no-mic learning mode with the safe example cards."
        }
    }

    private var summaryCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound Lab Score")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("Quiz: \(summary.quizCorrect)/\(summary.quizTotal) • Matches: \(summary.matchedPairs)/\(summary.totalPairs) • Stars: \(summary.starCount)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text("Remember: safe listening beats loud listening.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.panelDeep)
            }
        }
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < 420 ? 14 : 24
    }

    private func zoneFill(_ zone: SoundLoudnessZone) -> Color {
        switch zone {
        case .quiet:
            return MatherTheme.softBlue.opacity(0.22)
        case .normal:
            return MatherTheme.accent.opacity(0.14)
        case .loud:
            return MatherTheme.warm.opacity(0.24)
        case .tooLoud:
            return MatherTheme.coral.opacity(0.20)
        }
    }
}

private struct SoundPitchFollowUpView: View {
    @Binding var pitchChallengeState: SoundPitchChallengeState
    let onFeedback: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(SoundVolumeContent.pitchFollowUpTitle)
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                            .minimumScaleFactor(0.75)
                        Text("Pitch means how deep or bright a sound is. It is different from loudness, so you never need to be louder to learn pitch.")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(SoundVolumeContent.pitchBands) { band in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(band.visualKey).font(.largeTitle)
                            Text(band.title)
                                .font(.headline.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                            Text(band.frequencyRangeLabel)
                                .font(.caption.weight(.black))
                                .foregroundStyle(MatherTheme.accent)
                            Text(band.teachingCopy)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                        .background(MatherTheme.softBlue.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .accessibilityElement(children: .combine)
                    }
                }

                CardSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(pitchChallengeState.challenge.prompt)
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)

                        HStack(spacing: 8) {
                            ForEach(pitchChallengeState.challenge.options) { band in
                                Button {
                                    pitchChallengeState.select(band)
                                    onFeedback(pitchChallengeState.feedback)
                                } label: {
                                    Text("\(band.visualKey) \(band.title)")
                                        .font(.caption.weight(.black))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(pitchChallengeState.selectedBand == band ? MatherTheme.accent : MatherTheme.softBlue)
                                .accessibilityIdentifier("SoundPitchChoice-\(band.rawValue)")
                            }
                        }

                        Text(pitchChallengeState.feedback)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(pitchChallengeState.isCorrect ? MatherTheme.accent : MatherTheme.cardSubtitle)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 32)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(MatherTheme.background.ignoresSafeArea())
        .navigationTitle(SoundVolumeContent.pitchFollowUpTitle)
        .accessibilityIdentifier("SoundPitchFollowUpScreen")
    }

}
