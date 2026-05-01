import SwiftUI

enum WaterCycleStage: String, CaseIterable, Equatable {
    case wonder
    case evaporation
    case condensation
    case precipitation
    case collection
    case complete

    var title: String {
        switch self {
        case .wonder: "Wonder"
        case .evaporation: "Evaporation"
        case .condensation: "Condensation"
        case .precipitation: "Precipitation"
        case .collection: "Collection"
        case .complete: "Cycle complete"
        }
    }
}


struct WaterCycleConceptFlashcard: Equatable, Identifiable {
    let id: String
    let concept: String
    let question: String
    let answer: String
    let connection: String

    static let reviewDeck: [WaterCycleConceptFlashcard] = [
        WaterCycleConceptFlashcard(
            id: "sun-heat",
            concept: "Sun Heat",
            question: "What gives pond water the energy to start moving?",
            answer: "The sun warms the water.",
            connection: "Warm water can change into vapor and rise."
        ),
        WaterCycleConceptFlashcard(
            id: "evaporation",
            concept: "Evaporation",
            question: "What do we call water going up as tiny vapor?",
            answer: "Evaporation.",
            connection: "The vapor leaves the pond and travels into the air."
        ),
        WaterCycleConceptFlashcard(
            id: "condensation",
            concept: "Condensation",
            question: "What happens when tiny vapor drops gather together?",
            answer: "They make a cloud.",
            connection: "This gathering step is condensation."
        ),
        WaterCycleConceptFlashcard(
            id: "precipitation",
            concept: "Precipitation",
            question: "What happens when a cloud gets heavy with drops?",
            answer: "Rain falls down.",
            connection: "Rain, snow, sleet, and hail are precipitation."
        ),
        WaterCycleConceptFlashcard(
            id: "collection",
            concept: "Collection",
            question: "Where does rainwater wait after it falls?",
            answer: "It gathers in ponds, lakes, rivers, puddles, and the ground.",
            connection: "Then the sun can warm it and the cycle begins again."
        )
    ]
}

struct WaterCycleInterestingFact: Equatable, Identifiable {
    let id: String
    let title: String
    let detail: String

    var accessibilityText: String {
        "Interesting water fact: \(title). \(detail)"
    }

    static let completionFacts: [WaterCycleInterestingFact] = [
        WaterCycleInterestingFact(
            id: "rainiest-place",
            title: "Rainiest place",
            detail: "Mawsynram, India is famous for some of the highest average yearly rainfall on Earth."
        ),
        WaterCycleInterestingFact(
            id: "driest-desert",
            title: "Driest desert",
            detail: "Parts of the Atacama Desert can go years with almost no rain."
        ),
        WaterCycleInterestingFact(
            id: "ocean-evaporation",
            title: "Ocean engine",
            detail: "Most water vapor that becomes rain starts by evaporating from the ocean."
        ),
        WaterCycleInterestingFact(
            id: "tiny-freshwater",
            title: "Freshwater is rare",
            detail: "Only a tiny part of Earth’s water is fresh water we can easily use."
        )
    ]
}

struct WaterCycleLabState: Equatable {
    private(set) var stage: WaterCycleStage = .wonder
    private(set) var vaporDrops = 0
    private(set) var cloudDrops = 0
    private(set) var rainDrops = 0
    private(set) var pondDrops = 4
    private(set) var cyclesCompleted = 0
    private(set) var flashcardIndex = 0
    private(set) var isFlashcardAnswerRevealed = false
    private(set) var lessonThread = WaterCycleLessonThread.thread
    private(set) var lessonCardIndex = 0
    private(set) var isRecallCardRevealed = false
    private(set) var askSession = WaterCycleLessonThread.askSession(for: WaterCycleLessonThread.cards[0])
    private(set) var latestAskResponse: LessonSafeAskResponse?
    private(set) var mixMatchIndex = 0
    private(set) var mixMatchCorrectCardIDs: Set<String> = []
    private(set) var interestingFactIndex = 0

    var currentFlashcard: WaterCycleConceptFlashcard {
        WaterCycleConceptFlashcard.reviewDeck[flashcardIndex % WaterCycleConceptFlashcard.reviewDeck.count]
    }

    var currentLessonCard: LessonPlayCard {
        lessonThread.cards[lessonCardIndex % lessonThread.cards.count]
    }

    var currentMixMatchCard: LearningCard {
        WaterCycleLessonThread.mixMatchCards[mixMatchIndex % WaterCycleLessonThread.mixMatchCards.count]
    }

    var currentInterestingFact: WaterCycleInterestingFact {
        WaterCycleInterestingFact.completionFacts[interestingFactIndex % WaterCycleInterestingFact.completionFacts.count]
    }

    var interestingFactProgressLabel: String {
        "Fact \(interestingFactIndex + 1) of \(WaterCycleInterestingFact.completionFacts.count)"
    }

    var flashcardProgressLabel: String {
        "Card \(flashcardIndex + 1) of \(WaterCycleConceptFlashcard.reviewDeck.count)"
    }

    var lessonCardProgressLabel: String {
        "Card \(lessonCardIndex + 1) of \(lessonThread.cards.count)"
    }

    var mixMatchProgressLabel: String {
        "Match \(mixMatchCorrectCardIDs.count) of \(WaterCycleLessonThread.mixMatchCards.count)"
    }

    var isOnLastLessonCard: Bool {
        lessonCardIndex == lessonThread.cards.count - 1
    }

    var activeLessonProgressLabel: String {
        "\(lessonThread.progressLabel) - \(lessonCardProgressLabel)"
    }

    var activeLessonPrimaryActionTitle: String {
        switch lessonThread.activeStage.kind {
        case .lookLearnFlashcards:
            return isOnLastLessonCard ? "Start flip recall" : "Next look card"
        case .invertedRecall:
            if !isRecallCardRevealed { return "Flip recall card" }
            return isOnLastLessonCard ? "Ask this card" : "Next recall"
        case .contextualAsk:
            if latestAskResponse == nil { return "Ask suggested question" }
            return isOnLastLessonCard ? "Start mix-match" : "Next ask card"
        case .mixMatchFinale:
            return lessonThread.isComplete ? "Try the cycle again" : "Hear match clue"
        }
    }

    var activeLessonPrimaryActionIcon: String {
        switch lessonThread.activeStage.kind {
        case .lookLearnFlashcards: "arrow.right.circle.fill"
        case .invertedRecall: isRecallCardRevealed ? "arrow.right.circle.fill" : "rectangle.on.rectangle.angled.fill"
        case .contextualAsk: latestAskResponse == nil ? "questionmark.bubble.fill" : "arrow.right.circle.fill"
        case .mixMatchFinale: lessonThread.isComplete ? "arrow.counterclockwise" : "speaker.wave.2.fill"
        }
    }

    var progress: Double {
        switch stage {
        case .wonder: 0.0
        case .evaporation: 0.25
        case .condensation: 0.5
        case .precipitation: 0.75
        case .collection, .complete: 1.0
        }
    }

    var prompt: String {
        switch stage {
        case .wonder:
            "First, predict: what will the warm sun do to the pond? Tap Make a prediction."
        case .evaporation:
            "evaporation: warm water rises as tiny vapor. Tap Warm the pond."
        case .condensation:
            "condensation: tiny drops gather to make a cloud. Tap Gather the cloud."
        case .precipitation:
            "precipitation: a heavy cloud drops rain. Tap Make rain fall."
        case .collection:
            "Collection: rain fills the pond again. Tap Fill the pond."
        case .complete:
            "Full cycle complete: water went up, made a cloud, fell as rain, and filled the pond."
        }
    }

    var actionTitle: String {
        switch stage {
        case .wonder: "Make a prediction"
        case .evaporation: "Warm the pond"
        case .condensation: "Gather the cloud"
        case .precipitation: "Make rain fall"
        case .collection: "Fill the pond"
        case .complete: "Try the cycle again"
        }
    }

    mutating func advance() {
        switch stage {
        case .wonder:
            stage = .evaporation
        case .evaporation:
            vaporDrops = 3
            pondDrops = 2
            stage = .condensation
        case .condensation:
            cloudDrops = vaporDrops
            vaporDrops = 0
            stage = .precipitation
        case .precipitation:
            rainDrops = max(cloudDrops, 3)
            cloudDrops = 0
            stage = .collection
        case .collection:
            pondDrops = 4
            rainDrops = 0
            cyclesCompleted += 1
            flashcardIndex = 0
            isFlashcardAnswerRevealed = false
            resetLessonThread()
            interestingFactIndex = max(cyclesCompleted - 1, 0) % WaterCycleInterestingFact.completionFacts.count
            stage = .complete
        case .complete:
            reset()
        }
    }

    mutating func revealFlashcardAnswer() {
        guard stage == .complete else { return }
        isFlashcardAnswerRevealed = true
    }

    mutating func advanceFlashcard() {
        guard stage == .complete else { return }
        flashcardIndex = (flashcardIndex + 1) % WaterCycleConceptFlashcard.reviewDeck.count
        isFlashcardAnswerRevealed = false
    }

    mutating func advanceInterestingFact() {
        guard stage == .complete, lessonThread.isComplete else { return }
        interestingFactIndex = (interestingFactIndex + 1) % WaterCycleInterestingFact.completionFacts.count
    }

    mutating func advanceLessonCard() {
        guard stage == .complete else { return }
        lessonCardIndex = (lessonCardIndex + 1) % lessonThread.cards.count
        isRecallCardRevealed = false
        askSession = WaterCycleLessonThread.askSession(for: currentLessonCard)
        latestAskResponse = nil
    }

    mutating func revealRecallCard() {
        guard stage == .complete, lessonThread.activeStage.kind == .invertedRecall else { return }
        isRecallCardRevealed = true
    }

    mutating func selectAskTurn(id: String) -> LessonSafeAskResponse? {
        guard stage == .complete, lessonThread.activeStage.kind == .contextualAsk else { return nil }
        var session = askSession
        let response = session.respond(to: .suggestedTurn(id: id))
        askSession = session
        latestAskResponse = response
        return response
    }

    mutating func completeCurrentLessonStage() {
        guard stage == .complete else { return }
        lessonThread.completeActiveStage()
        lessonCardIndex = 0
        isRecallCardRevealed = false
        askSession = WaterCycleLessonThread.askSession(for: currentLessonCard)
        latestAskResponse = nil
    }

    mutating func recordMixMatchAttempt(_ attempt: MixMatchRecallAttempt) {
        guard stage == .complete, lessonThread.activeStage.kind == .mixMatchFinale, attempt.isCorrect else { return }
        mixMatchCorrectCardIDs.insert(currentMixMatchCard.answer.id)
        if mixMatchCorrectCardIDs.count == WaterCycleLessonThread.mixMatchCards.count {
            lessonThread.completeActiveStage()
        } else {
            mixMatchIndex = nextUnmatchedMixMatchIndex()
        }
    }

    private func nextUnmatchedMixMatchIndex() -> Int {
        let cards = WaterCycleLessonThread.mixMatchCards
        guard let next = cards.indices.first(where: { !mixMatchCorrectCardIDs.contains(cards[$0].answer.id) }) else {
            return mixMatchIndex
        }
        return next
    }

    mutating func reset() {
        stage = .wonder
        vaporDrops = 0
        cloudDrops = 0
        rainDrops = 0
        pondDrops = 4
        flashcardIndex = 0
        isFlashcardAnswerRevealed = false
        resetLessonThread()
    }

    private mutating func resetLessonThread() {
        lessonThread.resetProgress()
        lessonCardIndex = 0
        isRecallCardRevealed = false
        askSession = WaterCycleLessonThread.askSession(for: currentLessonCard)
        latestAskResponse = nil
        mixMatchIndex = 0
        mixMatchCorrectCardIDs = []
        interestingFactIndex = 0
    }
}

struct WaterCycleSceneMetrics: Equatable {
    let availableWidth: CGFloat
    let scale: CGFloat
    let horizontalInset: CGFloat
    let sunHaloSize: CGFloat
    let sunCoreSize: CGFloat
    let sunIconSize: CGFloat
    let cloudCapsuleWidth: CGFloat
    let cloudCapsuleHeight: CGFloat
    let cloudCircleSizes: [CGFloat]
    let cloudDropSize: CGFloat
    let columnWidth: CGFloat
    let columnMinHeight: CGFloat
    let vaporBaseIconSize: CGFloat
    let rainIconSize: CGFloat
    let pondHorizontalInset: CGFloat
    let pondHeight: CGFloat
    let pondDropSize: CGFloat

    init(availableWidth: CGFloat) {
        self.availableWidth = availableWidth
        scale = min(max(availableWidth / 430, 0.72), 1.0)
        horizontalInset = max(12, 30 * scale)
        sunHaloSize = 136 * scale
        sunCoreSize = 92 * scale
        sunIconSize = 52 * scale
        cloudCapsuleWidth = 172 * scale
        cloudCapsuleHeight = 78 * scale
        cloudCircleSizes = [72 * scale, 96 * scale, 70 * scale]
        cloudDropSize = 18 * scale
        columnWidth = min(140 * scale, max(112, (availableWidth - horizontalInset * 2 - 24) / 2))
        columnMinHeight = 138 * scale
        vaporBaseIconSize = 26 * scale
        rainIconSize = 28 * scale
        pondHorizontalInset = max(12, 34 * scale)
        pondHeight = 92 * scale
        pondDropSize = 18 * scale
    }
}

struct WaterCycleLabView: View {
    @Bindable var appModel: AppModel
    @State private var state = WaterCycleLabState()
    @State private var sessionStartedAt = Date()
    @State private var savedCompletionCount = 0

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                let horizontalPadding = waterCycleHorizontalPadding(for: proxy.size.width)
                let contentWidth = max(proxy.size.width - horizontalPadding * 2, 0)
                let sceneHeight = contentWidth < 340
                    ? min(max(proxy.size.height * 0.28, 230), 300)
                    : min(max(proxy.size.height * 0.42, 300), 480)

                if state.stage == .complete {
                    lessonPlayScene(
                        availableWidth: contentWidth,
                        availableHeight: proxy.size.height,
                        horizontalPadding: horizontalPadding
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            header(availableWidth: contentWidth)
                            inquiryCard
                            waterCycleScene(width: contentWidth, height: sceneHeight)
                            actionControls(availableWidth: contentWidth)
                        }
                        .frame(maxWidth: contentWidth, alignment: .leading)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .onAppear {
            sessionStartedAt = .now
            speakPrompt()
        }
    }

    private func waterCycleHorizontalPadding(for width: CGFloat) -> CGFloat {
        if width < 360 { return 12 }
        if width < 430 { return 16 }
        return 24
    }

    private func header(availableWidth: CGFloat) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Water Cycle Lab")
                    .font(.system(size: availableWidth < 340 ? 32 : 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                Text("Predict, try, observe, name")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                appModel.engine.showLab()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
                    .frame(width: 52, height: 52)
            }
            .accessibilityLabel("Back to Explorer Lab")
        }
    }

    private var inquiryCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        stageLabel
                        Spacer()
                        cycleLabel
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        stageLabel
                        cycleLabel
                    }
                }

                Text(state.prompt)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: state.progress)
                    .tint(MatherTheme.accent)
                    .accessibilityLabel("Water cycle progress")
            }
        }
    }

    private var stageLabel: some View {
        Label(state.stage.title, systemImage: stageIcon)
            .font(.headline.weight(.black))
            .foregroundStyle(MatherTheme.ink)
    }

    private var cycleLabel: some View {
        Text("Cycle \(state.cyclesCompleted + 1)")
            .font(.caption.weight(.bold))
            .foregroundStyle(MatherTheme.cardSubtitle)
    }

    private var stageIcon: String {
        switch state.stage {
        case .wonder: "questionmark.bubble.fill"
        case .evaporation: "sun.max.fill"
        case .condensation: "cloud.fill"
        case .precipitation: "cloud.rain.fill"
        case .collection: "drop.fill"
        case .complete: "checkmark.seal.fill"
        }
    }

    private func waterCycleScene(width: CGFloat, height: CGFloat) -> some View {
        let metrics = WaterCycleSceneMetrics(availableWidth: width)

        return ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MatherTheme.softBlue.opacity(0.35), MatherTheme.card],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(MatherTheme.panelDeep.opacity(0.22), lineWidth: 2)
                )

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    sunView(metrics)
                    Spacer()
                    cloudView(metrics)
                }
                .padding(.horizontal, metrics.horizontalInset)
                .padding(.top, 28)

                Spacer()

                HStack(alignment: .bottom) {
                    vaporColumn(metrics)
                    Spacer()
                    rainColumn(metrics)
                }
                .padding(.horizontal, metrics.horizontalInset)

                pondView(metrics)
                    .padding(.horizontal, metrics.pondHorizontalInset)
                    .padding(.bottom, 24)
            }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Water cycle picture with sun, vapor, cloud, rain, and pond")
    }

    private func sunView(_ metrics: WaterCycleSceneMetrics) -> some View {
        ZStack {
            Circle().fill(MatherTheme.warm.opacity(0.28)).frame(width: metrics.sunHaloSize, height: metrics.sunHaloSize)
            Circle().fill(MatherTheme.warm).frame(width: metrics.sunCoreSize, height: metrics.sunCoreSize)
            Image(systemName: "sun.max.fill")
                .font(.system(size: metrics.sunIconSize, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func cloudView(_ metrics: WaterCycleSceneMetrics) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Capsule().fill(MatherTheme.card).frame(width: metrics.cloudCapsuleWidth, height: metrics.cloudCapsuleHeight)
                HStack(spacing: -18 * metrics.scale) {
                    Circle().fill(MatherTheme.card).frame(width: metrics.cloudCircleSizes[0], height: metrics.cloudCircleSizes[0])
                    Circle().fill(MatherTheme.card).frame(width: metrics.cloudCircleSizes[1], height: metrics.cloudCircleSizes[1])
                    Circle().fill(MatherTheme.card).frame(width: metrics.cloudCircleSizes[2], height: metrics.cloudCircleSizes[2])
                }
                HStack(spacing: 10) {
                    ForEach(0..<state.cloudDrops, id: \.self) { _ in
                        Circle().fill(MatherTheme.softBlue).frame(width: metrics.cloudDropSize, height: metrics.cloudDropSize)
                    }
                }
                .offset(y: 18)
            }
            Text("cloud")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
    }

    private func vaporColumn(_ metrics: WaterCycleSceneMetrics) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<state.vaporDrops, id: \.self) { index in
                Image(systemName: "drop.fill")
                    .font(.system(size: metrics.vaporBaseIconSize + CGFloat(index * 3), weight: .bold))
                    .foregroundStyle(MatherTheme.softBlue.opacity(0.72))
            }
            Text("water goes up")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .multilineTextAlignment(.center)
        }
        .frame(width: metrics.columnWidth)
        .frame(minHeight: metrics.columnMinHeight)
    }

    private func rainColumn(_ metrics: WaterCycleSceneMetrics) -> some View {
        VStack(spacing: 10) {
            ForEach(0..<state.rainDrops, id: \.self) { _ in
                Image(systemName: "drop.fill")
                    .font(.system(size: metrics.rainIconSize, weight: .bold))
                    .foregroundStyle(MatherTheme.accent)
            }
            Text("rain falls down")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .multilineTextAlignment(.center)
        }
        .frame(width: metrics.columnWidth)
        .frame(minHeight: metrics.columnMinHeight)
    }

    private func pondView(_ metrics: WaterCycleSceneMetrics) -> some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(MatherTheme.softBlue.opacity(0.25)).frame(height: metrics.pondHeight)
            Capsule().fill(MatherTheme.softBlue).frame(height: CGFloat(32 + state.pondDrops * 10) * metrics.scale)
            HStack(spacing: 12) {
                ForEach(0..<state.pondDrops, id: \.self) { _ in
                    Circle().fill(.white.opacity(0.65)).frame(width: metrics.pondDropSize, height: metrics.pondDropSize)
                }
            }
            .padding(.bottom, 28)
        }
        .overlay(alignment: .topLeading) {
            Text("pond")
                .font(.caption.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .padding(.leading, 24)
                .padding(.top, 14)
        }
    }

    private var lessonStageIcon: String {
        switch state.lessonThread.activeStage.kind {
        case .lookLearnFlashcards: "photo.stack.fill"
        case .invertedRecall: "rectangle.on.rectangle.angled.fill"
        case .contextualAsk: "bubble.left.and.text.bubble.right.fill"
        case .mixMatchFinale: "rectangle.2.swap"
        }
    }

    private func lessonPlayScene(
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        horizontalPadding: CGFloat
    ) -> some View {
        let boardHeight = max(260, availableHeight - 244)

        return VStack(alignment: .leading, spacing: 12) {
            header(availableWidth: availableWidth)
            lessonStageStatusBar

            ViewThatFits(in: .vertical) {
                activeLessonStageBoard
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(height: boardHeight, alignment: .top)

                ScrollView {
                    activeLessonStageBoard
                }
                .frame(maxWidth: .infinity)
                .frame(height: boardHeight)
            }

            lessonPlayActionBar(availableWidth: availableWidth)
        }
        .frame(maxWidth: availableWidth, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityIdentifier("water-cycle-playable-lesson")
    }

    private var lessonStageStatusBar: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Label(state.lessonThread.activeStage.title, systemImage: lessonStageIcon)
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Spacer()
                        Text(state.activeLessonProgressLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Label(state.lessonThread.activeStage.title, systemImage: lessonStageIcon)
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text(state.activeLessonProgressLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }

                ProgressView(value: state.lessonThread.progress)
                    .tint(MatherTheme.accent)
                    .accessibilityLabel("Lesson thread progress")
            }
        }
    }

    @ViewBuilder
    private var activeLessonStageBoard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text(state.lessonThread.activeStage.prompt)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)

                switch state.lessonThread.activeStage.kind {
                case .lookLearnFlashcards:
                    lookLearnLevel
                case .invertedRecall:
                    invertedRecallLevel
                case .contextualAsk:
                    safeAskLevel
                case .mixMatchFinale:
                    mixMatchFinaleLevel
                }
            }
        }
        .accessibilityIdentifier("water-cycle-active-lesson-stage")
    }

    private var lookLearnLevel: some View {
        let card = state.currentLessonCard

        return VStack(alignment: .leading, spacing: 12) {
            if let assetName = card.assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }

            Text(card.title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.accent)

            Text(card.prompt)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text(card.answer)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text(card.detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
        }
    }

    private var invertedRecallLevel: some View {
        let card = state.currentLessonCard
        let model = LearningCardViewModel(
            id: card.id,
            display: card.assetName.map(LearningCardDisplay.asset) ?? .text(card.title),
            accessibilityLabel: card.title,
            accessibilityHint: "Flip to recall this water cycle idea.",
            isFaceDown: !state.isRecallCardRevealed,
            isSelected: state.isRecallCardRevealed,
            isMatched: false,
            isIncorrect: false
        )

        return VStack(alignment: .leading, spacing: 12) {
            Button {
                state.revealRecallCard()
                speakLessonCard()
            } label: {
                LearningCardView(model: model)
                    .frame(minHeight: 150)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("water-cycle-recall-card")

            Text(state.isRecallCardRevealed ? card.answer : "Say the idea before you flip.")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if state.isRecallCardRevealed {
                Text(card.detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var safeAskLevel: some View {
        let card = state.currentLessonCard

        return VStack(alignment: .leading, spacing: 12) {
            Text(card.title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.accent)

            ForEach(state.askSession.suggestedTurns) { turn in
                Button {
                    if let response = state.selectAskTurn(id: turn.id) {
                        appModel.speechService.speak(response.spokenText, enabled: appModel.featureFlags.audioEnabled)
                    }
                } label: {
                    Label(turn.question, systemImage: "questionmark.bubble.fill")
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.panelDeep.opacity(0.28)))
                .accessibilityIdentifier("water-cycle-safe-ask-\(turn.id)")
            }

            if let latestAskResponse = state.latestAskResponse {
                Text(latestAskResponse.spokenText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("water-cycle-safe-ask-response")
            }
        }
    }

    private var mixMatchFinaleLevel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(state.mixMatchProgressLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)

            if state.lessonThread.isComplete {
                Label("Lesson thread complete", systemImage: "checkmark.seal.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.ink)

                completionFactCard
            } else {
                MixMatchRecallView(
                    learningCard: state.currentMixMatchCard,
                    onCorrect: { attempt in
                        state.recordMixMatchAttempt(attempt)
                        speakLessonText(attempt.isCorrect ? "Correct match." : "Try another match.")
                    },
                    onIncorrect: { attempt in
                        state.recordMixMatchAttempt(attempt)
                        speakLessonText("Try another match.")
                    }
                )
                .accessibilityIdentifier("water-cycle-mix-match-finale")
            }
        }
    }

    private var completionFactCard: some View {
        let fact = state.currentInterestingFact

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Interesting fact", systemImage: "sparkles")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.accent)
                Spacer()
                Text(state.interestingFactProgressLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }

            Text(fact.title)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)

            Text(fact.detail)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                state.advanceInterestingFact()
                speakLessonText(state.currentInterestingFact.accessibilityText)
            } label: {
                Label("Next fact", systemImage: "sparkles")
            }
            .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.panelDeep.opacity(0.28)))
            .accessibilityIdentifier("water-cycle-next-interesting-fact")
        }
        .padding(14)
        .background(MatherTheme.warm.opacity(0.18), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(fact.accessibilityText)
        .accessibilityIdentifier("water-cycle-interesting-fact-card")
    }

    private func lessonPlayActionBar(availableWidth: CGFloat) -> some View {
        VStack(spacing: 10) {
            Button {
                performLessonPrimaryAction()
            } label: {
                Label(state.activeLessonPrimaryActionTitle, systemImage: state.activeLessonPrimaryActionIcon)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("water-cycle-lesson-primary-action")

            if availableWidth < 390 {
                HStack(spacing: 10) {
                    replayLessonButton(compact: true)
                    resetButton(compact: true)
                }
            } else {
                HStack(spacing: 12) {
                    replayLessonButton(compact: false)
                    resetButton(compact: false)
                }
            }
        }
    }

    private func replayLessonButton(compact: Bool) -> some View {
        Button {
            speakLessonStage()
        } label: {
            secondaryActionLabel("Replay stage", systemImage: "speaker.wave.2.fill", compact: compact)
        }
        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.panelDeep.opacity(0.28)))
        .accessibilityIdentifier("water-cycle-replay-lesson-stage")
    }

    private func performLessonPrimaryAction() {
        switch state.lessonThread.activeStage.kind {
        case .lookLearnFlashcards:
            if state.isOnLastLessonCard {
                state.completeCurrentLessonStage()
                speakLessonStage()
            } else {
                state.advanceLessonCard()
                speakLessonCard()
            }
        case .invertedRecall:
            if !state.isRecallCardRevealed {
                state.revealRecallCard()
                speakLessonCard()
            } else if state.isOnLastLessonCard {
                state.completeCurrentLessonStage()
                speakLessonStage()
            } else {
                state.advanceLessonCard()
                speakLessonCard()
            }
        case .contextualAsk:
            if state.latestAskResponse == nil, let turn = state.askSession.suggestedTurns.first {
                if let response = state.selectAskTurn(id: turn.id) {
                    appModel.speechService.speak(response.spokenText, enabled: appModel.featureFlags.audioEnabled)
                }
            } else if state.isOnLastLessonCard {
                state.completeCurrentLessonStage()
                speakLessonStage()
            } else {
                state.advanceLessonCard()
                speakLessonCard()
            }
        case .mixMatchFinale:
            if state.lessonThread.isComplete {
                state.advance()
                speakPrompt()
            } else {
                speakLessonText(state.currentMixMatchCard.prompt.speechText)
            }
        }
    }

    private func actionControls(availableWidth: CGFloat) -> some View {
        VStack(spacing: 12) {
            Button {
                state.advance()
                speakPrompt()
                saveIfCompleted()
            } label: {
                Label(state.actionTitle, systemImage: "hand.tap.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("water-cycle-primary-action")

            if availableWidth < 390 {
                VStack(spacing: 12) {
                    replayPromptButton(compact: false)
                    resetButton(compact: false)
                }
            } else {
                HStack(spacing: 12) {
                    replayPromptButton(compact: availableWidth < 360)
                    resetButton(compact: availableWidth < 360)
                }
            }
        }
    }

    private func replayPromptButton(compact: Bool) -> some View {
        Button {
            speakPrompt()
        } label: {
            secondaryActionLabel("Replay prompt", systemImage: "speaker.wave.2.fill", compact: compact)
        }
        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.panelDeep.opacity(0.28)))
        .accessibilityIdentifier("water-cycle-replay-prompt")
    }

    private func resetButton(compact: Bool) -> some View {
        Button {
            state.reset()
            speakPrompt()
        } label: {
            secondaryActionLabel("Reset", systemImage: "arrow.counterclockwise", compact: compact)
        }
        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.coral.opacity(0.42)))
        .accessibilityIdentifier("water-cycle-reset")
    }

    @ViewBuilder
    private func secondaryActionLabel(_ title: String, systemImage: String, compact: Bool) -> some View {
        if compact {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                    .multilineTextAlignment(.center)
            }
        } else {
            Label(title, systemImage: systemImage)
        }
    }

    private func speakPrompt() {
        appModel.speechService.speak(state.prompt, enabled: appModel.featureFlags.audioEnabled)
    }

    private func speakFlashcard() {
        let flashcard = state.currentFlashcard
        let spokenText = state.isFlashcardAnswerRevealed
            ? "\(flashcard.question) \(flashcard.answer) \(flashcard.connection)"
            : flashcard.question
        appModel.speechService.speak(spokenText, enabled: appModel.featureFlags.audioEnabled)
    }

    private func speakLessonStage() {
        let stage = state.lessonThread.activeStage
        appModel.speechService.speak("\(stage.title). \(stage.prompt)", enabled: appModel.featureFlags.audioEnabled)
    }

    private func speakLessonCard() {
        let card = state.currentLessonCard
        appModel.speechService.speak("\(card.title). \(card.prompt) \(card.answer) \(card.detail)", enabled: appModel.featureFlags.audioEnabled)
    }

    private func speakLessonText(_ text: String) {
        appModel.speechService.speak(text, enabled: appModel.featureFlags.audioEnabled)
    }

    private func saveIfCompleted() {
        guard state.stage == .complete, state.cyclesCompleted > savedCompletionCount else { return }
        savedCompletionCount = state.cyclesCompleted
        appModel.gameSessionStore.save(
            gameName: "Water Cycle Lab",
            startedAt: sessionStartedAt,
            scoreValue: state.cyclesCompleted,
            scoreLabel: "cycle completed"
        )
    }
}
