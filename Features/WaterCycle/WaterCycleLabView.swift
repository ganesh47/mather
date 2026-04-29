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

struct WaterCycleLabState: Equatable {
    private(set) var stage: WaterCycleStage = .wonder
    private(set) var vaporDrops = 0
    private(set) var cloudDrops = 0
    private(set) var rainDrops = 0
    private(set) var pondDrops = 4
    private(set) var cyclesCompleted = 0

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
            "What do you think the warm sun will do to the pond?"
        case .evaporation:
            "Warm water goes up as tiny vapor. That is evaporation."
        case .condensation:
            "Tiny drops gather and make a cloud. That is condensation."
        case .precipitation:
            "The cloud is heavy. Tap it to make rain. That is precipitation."
        case .collection:
            "Rain fills the pond again. The cycle can start over."
        case .complete:
            "You made a full water cycle: up, cloud, rain, pond."
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
            stage = .complete
        case .complete:
            reset()
        }
    }

    mutating func reset() {
        stage = .wonder
        vaporDrops = 0
        cloudDrops = 0
        rainDrops = 0
        pondDrops = 4
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
                let horizontalPadding = proxy.size.width < 390 ? 16.0 : 24.0
                let contentWidth = max(proxy.size.width - horizontalPadding * 2, 0)
                let sceneHeight = contentWidth < 340
                    ? min(max(proxy.size.height * 0.32, 260), 330)
                    : min(max(proxy.size.height * 0.46, 320), 520)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(availableWidth: contentWidth)
                        inquiryCard
                        waterCycleScene(width: contentWidth, height: sceneHeight)
                        actionControls(availableWidth: contentWidth)
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            sessionStartedAt = .now
            speakPrompt()
        }
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
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink)
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

            if availableWidth < 280 {
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
