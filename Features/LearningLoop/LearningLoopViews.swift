import Observation
import SwiftUI

struct LearningCardIntroView: View {
    let cards: [LearningConceptCard]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Learn")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(cards) { card in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.visualKey)
                            .font(.system(size: 44))
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(card.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text(card.explanation)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                    .background(MatherTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(card.title). \(card.explanation)")
                }
            }
        }
    }
}

struct ConceptQuizRoundView: View {
    let questions: [ConceptQuizQuestion]
    @Binding var answersByQuestionId: [String: String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quiz")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            ForEach(questions) { question in
                VStack(alignment: .leading, spacing: 10) {
                    Text(question.prompt)
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    HStack(spacing: 8) {
                        ForEach(question.choices, id: \.self) { choice in
                            Button {
                                answersByQuestionId[question.id] = choice
                            } label: {
                                Text(choice)
                                    .font(.subheadline.weight(.bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(choiceFill(for: choice, in: question))
                                    .foregroundStyle(MatherTheme.ink)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(choice) answer")
                        }
                    }
                    if let selected = answersByQuestionId[question.id] {
                        Text(question.isCorrect(selected) ? question.feedback : "Try again — look back at the learn cards.")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(question.isCorrect(selected) ? .green : MatherTheme.coral)
                    }
                }
                .padding(14)
                .background(MatherTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func choiceFill(for choice: String, in question: ConceptQuizQuestion) -> Color {
        guard let selected = answersByQuestionId[question.id], selected == choice else {
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
    case quiz
    case match
    case summary

    var title: String {
        switch self {
        case .quiz: return "Quiz"
        case .match: return "Mix + Match"
        case .summary: return "Stars"
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .quiz: return "Go to Mix + Match"
        case .match: return "See Sound Score"
        case .summary: return "Review Quiz"
        }
    }

    var primaryActionIcon: String {
        switch self {
        case .quiz: return "rectangle.grid.2x2.fill"
        case .match: return "star.fill"
        case .summary: return "arrow.counterclockwise"
        }
    }

    var next: SoundVolumeActivityStage {
        switch self {
        case .quiz: return .match
        case .match: return .summary
        case .summary: return .quiz
        }
    }

    var previous: SoundVolumeActivityStage {
        switch self {
        case .quiz: return .summary
        case .match: return .quiz
        case .summary: return .match
        }
    }
}

struct SoundVolumeLabView: View {
    @Bindable var appModel: AppModel
    @State private var introPageIndex = 0
    @State private var hasStartedActivities = false
    @State private var activityStage: SoundVolumeActivityStage = .quiz
    @State private var answersByQuestionId: [String: String] = [:]
    @State private var selectedMatchPairId: String?
    @State private var matchedPairIds: Set<String> = []
    @State private var matchShuffleSeed = UInt64.random(in: UInt64.min...UInt64.max)
    @State private var feedback = SoundVolumeContent.safetyNote

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
            activityStage = .quiz
            feedback = "Start with the quiz. Mix + Match comes on the next screen."
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
            if activityStage != .quiz {
                Button {
                    activityStage = activityStage.previous
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Button {
                activityStage = activityStage.next
                if activityStage == .match {
                    feedback = "Now match each sound clue to its safe idea."
                } else if activityStage == .summary {
                    feedback = "Review your Sound Lab score."
                }
            } label: {
                Label(activityStage.primaryActionTitle, systemImage: activityStage.primaryActionIcon)
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
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
                        Text("Quiz and match safe listening clues. No microphone permission or live meter is used.")
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
                Text("No microphone permission, no live meter, and no loud-noise challenge in this round. Match the clues and choose safe actions.")
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
            Text("These are learning examples, not a calibrated sound meter.")
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

struct ShapeGeometryLabView: View {
    @Bindable var appModel: AppModel
    @State private var levelIndex = 0
    @State private var stage: ShapeGeometryStage = .learn
    @State private var answersByQuestionId: [String: String] = [:]
    @State private var selectedMatchPairId: String?
    @State private var matchedPairIds: Set<String> = []
    @State private var feedback = "Start with one playful shape screen at a time."

    private enum ShapeGeometryStage: Int, CaseIterable {
        case learn, quiz, match, summary

        var title: String {
            switch self {
            case .learn: "Look"
            case .quiz: "Quiz"
            case .match: "Match"
            case .summary: "Stars"
            }
        }

        var nextTitle: String {
            switch self {
            case .learn: "Start quiz"
            case .quiz: "Play match"
            case .match: "See stars"
            case .summary: "Play again"
            }
        }
    }

    private var level: ShapeGeometryContent.Level {
        ShapeGeometryContent.levels[levelIndex]
    }

    private var summary: LearningLoopSummary {
        LearningLoopScoring.summary(
            questions: level.quizQuestions,
            answersByQuestionId: answersByQuestionId,
            matchedPairIds: matchedPairIds,
            pairs: level.matchPairs
        )
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 14) {
                header
                levelPicker
                stageProgress

                ViewThatFits(in: .vertical) {
                    currentStageView
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .frame(maxHeight: max(260, proxy.size.height - 330), alignment: .top)

                    ScrollView {
                        currentStageView
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: max(260, proxy.size.height - 330))
                }

                stageControls
            }
            .padding(.horizontal, proxy.size.width < 420 ? 14 : 24)
            .padding(.vertical, 18)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(MatherTheme.background.ignoresSafeArea())
        }
        .navigationTitle("Shape Lab")
        .safeAreaInset(edge: .top) {
            HStack {
                Button { appModel.engine.showLabLane(.geometry) } label: {
                    Label("Geometry", systemImage: "chevron.left")
                        .font(.subheadline.weight(.black))
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .onDisappear {
            if summary.starCount > 0 || matchedPairIds.count == level.matchPairs.count {
                appModel.markExplorerLabModeCompleted(laneID: .geometry, mode: .review)
                appModel.setExplorerLabConceptConfidence(.steady, for: ConceptId(rawValue: "shape-names"), laneID: .geometry)
            }
        }
    }

    private var header: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Text("🔷")
                        .font(.system(size: 58))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Shape Names Lab")
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                            .minimumScaleFactor(0.75)
                        Text("Learn circles, triangles, squares, rectangles, ovals, stars, hearts, and diamonds — then play Bond Blast-style matches.")
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

    private var levelPicker: some View {
        HStack(spacing: 10) {
            ForEach(Array(ShapeGeometryContent.levels.enumerated()), id: \.element.id) { index, level in
                Button {
                    levelIndex = index
                    answersByQuestionId = [:]
                    selectedMatchPairId = nil
                    matchedPairIds = []
                    stage = .learn
                    feedback = "Now playing \(level.title), one screen at a time."
                } label: {
                    Text(level.title)
                        .font(.subheadline.weight(.black))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(index == levelIndex ? MatherTheme.accent.opacity(0.26) : MatherTheme.card)
                        .foregroundStyle(MatherTheme.ink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel("Shape Lab level picker")
    }

    private var stageProgress: some View {
        HStack(spacing: 8) {
            ForEach(ShapeGeometryStage.allCases, id: \.rawValue) { shapeStage in
                Text(shapeStage.title)
                    .font(.caption.weight(.black))
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(shapeStage == stage ? MatherTheme.accent.opacity(0.24) : MatherTheme.card)
                    .foregroundStyle(shapeStage == stage ? MatherTheme.ink : MatherTheme.cardSubtitle)
                    .clipShape(Capsule())
            }
        }
        .accessibilityIdentifier("shape-lab-stage-progress")
    }

    @ViewBuilder
    private var currentStageView: some View {
        switch stage {
        case .learn:
            LearningCardIntroView(cards: level.cards)
        case .quiz:
            ConceptQuizRoundView(questions: level.quizQuestions, answersByQuestionId: $answersByQuestionId)
        case .match:
            ConceptMixMatchRoundView(
                pairs: level.matchPairs,
                selectedLeft: $selectedMatchPairId,
                matchedPairIds: $matchedPairIds,
                onFeedback: { feedback = $0 }
            )
        case .summary:
            summaryCard
        }
    }

    private var stageControls: some View {
        HStack(spacing: 12) {
            Button {
                if let previous = ShapeGeometryStage(rawValue: stage.rawValue - 1) {
                    stage = previous
                    feedback = "Back to \(previous.title.lowercased()) mode."
                }
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.panelDeep.opacity(0.24)))
            .disabled(stage == .learn)

            Button {
                if stage == .summary {
                    answersByQuestionId = [:]
                    selectedMatchPairId = nil
                    matchedPairIds = []
                    stage = .learn
                    feedback = "New round: look, quiz, match, then stars."
                } else if let next = ShapeGeometryStage(rawValue: stage.rawValue + 1) {
                    stage = next
                    feedback = "Now playing \(next.title.lowercased()) mode."
                }
            } label: {
                Label(stage.nextTitle, systemImage: stage == .summary ? "arrow.counterclockwise" : "arrow.right.circle.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .accessibilityIdentifier("shape-lab-stage-controls")
    }

    private var summaryCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shape Score")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("Quiz: \(summary.quizCorrect)/\(summary.quizTotal) • Matches: \(summary.matchedPairs)/\(summary.totalPairs) • Stars: \(summary.starCount)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text(summary.starCount >= 2 ? "Shape detective mode unlocked." : "Try another level or match again.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.panelDeep)
            }
        }
    }
}
