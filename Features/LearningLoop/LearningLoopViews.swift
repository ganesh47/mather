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

struct SoundVolumeLabView: View {
    @Bindable var appModel: AppModel
    @State private var answersByQuestionId: [String: String] = [:]
    @State private var selectedMatchPairId: String?
    @State private var matchedPairIds: Set<String> = []
    @State private var matchShuffleSeed = UInt64.random(in: UInt64.min...UInt64.max)
    @State private var feedback = SoundVolumeContent.safetyNote

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
                    header
                    safetyBanner
                    loudnessZones
                    LearningCardIntroView(cards: SoundVolumeContent.cards)
                    ConceptQuizRoundView(
                        questions: SoundVolumeContent.quizQuestions,
                        answersByQuestionId: $answersByQuestionId
                    )
                    ConceptMixMatchRoundView(
                        pairs: SoundVolumeContent.matchPairs,
                        shuffleSeed: matchShuffleSeed,
                        selectedLeft: $selectedMatchPairId,
                        matchedPairIds: $matchedPairIds,
                        onFeedback: { feedback = $0 },
                        onHapticCue: playSoundMatchHaptic
                    )
                    summaryCard
                }
                .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                .padding(.vertical, 22)
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
        .onDisappear {
            if summary.starCount > 0 || matchedPairIds.count == SoundVolumeContent.matchPairs.count {
                appModel.markExplorerLabModeCompleted(laneID: .physics, mode: .review)
                appModel.setExplorerLabConceptConfidence(.steady, for: ConceptId(rawValue: "sound-volume"), laneID: .physics)
            }
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

    private var header: some View {
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
                        Text("Learn quiet, conversation, traffic, sirens, headphones, pleasant sounds, noisy sounds, and hearing safety.")
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
    @State private var stage: ShapeGeometryLabStage = .launch
    @State private var cardIndex = 0
    @State private var quizQuestionIndex = 0
    @State private var answersByQuestionId: [String: String] = [:]
    @State private var selectedMatchPairId: String?
    @State private var matchedPairIds: Set<String> = []
    @State private var matchShuffleSeed = UInt64.random(in: UInt64.min...UInt64.max)
    @State private var feedback = "Start a shape mission — one playful screen at a time."

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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    levelPicker
                    stageProgress
                    activeStageCard
                }
                .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                .padding(.vertical, 18)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.28, dampingFraction: 0.82), value: stage)
            }
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
        .safeAreaInset(edge: .bottom) {
            stageControls
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
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
                        Text("Shape Mission Lab")
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                            .minimumScaleFactor(0.75)
                        Text("No giant worksheet. Kids clear short screens: mission, card quest, shape check, Bond Blast, victory board.")
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
                    resetRun(message: "Now playing \(level.title).")
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(stage.title)
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Spacer()
                Text(stage.progressLabel)
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(MatherTheme.accent.opacity(0.16))
                    .clipShape(Capsule())
            }
            HStack(spacing: 8) {
                ForEach(ShapeGeometryLabStage.allCases) { item in
                    Capsule()
                        .fill(stageFill(for: item))
                        .frame(height: 8)
                        .accessibilityLabel("\(item.shortTitle) screen")
                }
            }
        }
        .padding(14)
        .background(MatherTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private var activeStageCard: some View {
        switch stage {
        case .launch:
            shapeMissionBrief
        case .learn:
            ShapeCardQuestView(cards: level.cards, cardIndex: $cardIndex)
        case .quiz:
            ShapeScreenQuizView(
                questions: level.quizQuestions,
                questionIndex: $quizQuestionIndex,
                answersByQuestionId: $answersByQuestionId
            )
        case .match:
            ConceptMixMatchRoundView(
                pairs: level.matchPairs,
                shuffleSeed: matchShuffleSeed,
                selectedLeft: $selectedMatchPairId,
                matchedPairIds: $matchedPairIds,
                onFeedback: { feedback = $0 },
                onHapticCue: playShapeMatchHaptic
            )
        case .score:
            summaryCard
        }
    }

    private var shapeMissionBrief: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text("🕵️‍♀️")
                        .font(.system(size: 54))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shape detective mission")
                            .font(.title.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text("Clear one screen, earn a badge, then move forward. No long scrolling hunt.")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    missionBadge("1", "Peek", "Study one card at a time")
                    missionBadge("2", "Pick", "Answer quick clues")
                    missionBadge("3", "Blast", "Snap matching shapes")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func missionBadge(_ number: String, _ title: String, _ copy: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(number)
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .padding(8)
                .background(MatherTheme.accent)
                .clipShape(Circle())
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Text(copy)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .background(MatherTheme.softBlue.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var summaryCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text(summary.starCount >= 2 ? "🏆 Shape detective mode unlocked" : "⭐ Keep collecting shape clues")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("Quiz: \(summary.quizCorrect)/\(summary.quizTotal) • Matches: \(summary.matchedPairs)/\(summary.totalPairs) • Stars: \(summary.starCount)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text(summary.starCount >= 2 ? "Nice work — try another level for a fresh card quest." : "Replay the cards or try Bond Blast again to earn more stars.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.panelDeep)
                Button {
                    resetRun(message: "New shape mission ready.")
                } label: {
                    Label("Replay as a new mission", systemImage: "arrow.clockwise")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var stageControls: some View {
        HStack(spacing: 12) {
            Button {
                goBack()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.subheadline.weight(.black))
            }
            .buttonStyle(.bordered)
            .disabled(stage.previous == nil)

            Button {
                goForward()
            } label: {
                Label(nextButtonTitle, systemImage: stage.next == nil ? "checkmark.seal.fill" : "chevron.right")
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var nextButtonTitle: String {
        switch stage {
        case .launch: return "Start card quest"
        case .learn: return cardIndex < level.cards.count - 1 ? "Next card" : "Start shape check"
        case .quiz: return quizQuestionIndex < level.quizQuestions.count - 1 ? "Next clue" : "Start Bond Blast"
        case .match: return matchedPairIds.count == level.matchPairs.count ? "See victory board" : "Skip to score"
        case .score: return "Done"
        }
    }

    private func goForward() {
        switch stage {
        case .learn where cardIndex < level.cards.count - 1:
            cardIndex += 1
            feedback = "Card \(cardIndex + 1) of \(level.cards.count): \(level.cards[cardIndex].title)."
        case .quiz where quizQuestionIndex < level.quizQuestions.count - 1:
            quizQuestionIndex += 1
            feedback = "Shape clue \(quizQuestionIndex + 1) of \(level.quizQuestions.count)."
        case .score:
            appModel.engine.showLabLane(.geometry)
        default:
            if let next = stage.next {
                stage = next
                feedback = feedbackForStage(next)
            }
        }
    }

    private func goBack() {
        switch stage {
        case .learn where cardIndex > 0:
            cardIndex -= 1
            feedback = "Reviewing card \(cardIndex + 1) of \(level.cards.count)."
        case .quiz where quizQuestionIndex > 0:
            quizQuestionIndex -= 1
            feedback = "Reviewing clue \(quizQuestionIndex + 1) of \(level.quizQuestions.count)."
        default:
            if let previous = stage.previous {
                stage = previous
                feedback = feedbackForStage(previous)
            }
        }
    }

    private func resetRun(message: String) {
        stage = .launch
        cardIndex = 0
        quizQuestionIndex = 0
        answersByQuestionId = [:]
        selectedMatchPairId = nil
        matchedPairIds = []
        matchShuffleSeed = UInt64.random(in: UInt64.min...UInt64.max)
        feedback = message
    }

    private func feedbackForStage(_ stage: ShapeGeometryLabStage) -> String {
        switch stage {
        case .launch: return "Start a shape mission — one playful screen at a time."
        case .learn: return "Card quest started: one shape clue per screen."
        case .quiz: return "Shape check: answer one clue at a time."
        case .match: return "Bond Blast time: snap each picture to its name."
        case .score: return "Victory board ready."
        }
    }

    private func playShapeMatchHaptic(_ cue: ConceptMixMatchHapticCue) {
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

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < 420 ? 14 : 24
    }

    private func stageFill(for item: ShapeGeometryLabStage) -> Color {
        guard let current = ShapeGeometryLabStage.allCases.firstIndex(of: stage),
              let target = ShapeGeometryLabStage.allCases.firstIndex(of: item)
        else { return Color.secondary.opacity(0.22) }
        return target <= current ? MatherTheme.accent : Color.secondary.opacity(0.22)
    }
}

private struct ShapeCardQuestView: View {
    let cards: [LearningConceptCard]
    @Binding var cardIndex: Int

    private var currentCard: LearningConceptCard { cards[cardIndex] }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Card quest")
                        .font(.title2.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Spacer()
                    Text("\(cardIndex + 1)/\(cards.count)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.accent)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(MatherTheme.accent.opacity(0.16))
                        .clipShape(Capsule())
                }
                Text(currentCard.visualKey)
                    .font(.system(size: 92, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(MatherTheme.warm.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                Text(currentCard.title)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(currentCard.explanation)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    ForEach(cards.indices, id: \.self) { index in
                        Circle()
                            .fill(index == cardIndex ? MatherTheme.accent : Color.secondary.opacity(0.24))
                            .frame(width: 9, height: 9)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shape card \(cardIndex + 1) of \(cards.count). \(currentCard.title). \(currentCard.explanation)")
    }
}

private struct ShapeScreenQuizView: View {
    let questions: [ConceptQuizQuestion]
    @Binding var questionIndex: Int
    @Binding var answersByQuestionId: [String: String]

    private var question: ConceptQuizQuestion { questions[questionIndex] }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Shape check")
                        .font(.title2.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Spacer()
                    Text("\(questionIndex + 1)/\(questions.count)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.accent)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(MatherTheme.accent.opacity(0.16))
                        .clipShape(Capsule())
                }
                Text(question.prompt)
                    .font(.title3.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                VStack(spacing: 10) {
                    ForEach(question.choices, id: \.self) { choice in
                        Button {
                            answersByQuestionId[question.id] = choice
                        } label: {
                            HStack {
                                Text(choice)
                                    .font(.headline.weight(.black))
                                Spacer()
                                if answersByQuestionId[question.id] == choice {
                                    Image(systemName: question.isCorrect(choice) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity)
                            .background(choiceFill(for: choice))
                            .foregroundStyle(MatherTheme.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(choice) answer")
                    }
                }
                if let selected = answersByQuestionId[question.id] {
                    Text(question.isCorrect(selected) ? question.feedback : "Try again — use the card clue.")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(question.isCorrect(selected) ? .green : MatherTheme.coral)
                }
            }
        }
    }

    private func choiceFill(for choice: String) -> Color {
        guard let selected = answersByQuestionId[question.id], selected == choice else {
            return MatherTheme.softBlue.opacity(0.45)
        }
        return question.isCorrect(choice) ? .green.opacity(0.28) : MatherTheme.coral.opacity(0.28)
    }
}
