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

struct WaterCycleLabView: View {
    @Bindable var appModel: AppModel
    @State private var state = WaterCycleLabState()
    @State private var sessionStartedAt = Date()
    @State private var savedCompletionCount = 0

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        inquiryCard
                        waterCycleScene(height: min(max(proxy.size.height * 0.46, 360), 520))
                        actionControls
                    }
                    .padding(24)
                }
            }
        }
        .onAppear {
            sessionStartedAt = .now
            speakPrompt()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Water Cycle Lab")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Predict, try, observe, name")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
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
                HStack {
                    Label(state.stage.title, systemImage: stageIcon)
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Spacer()
                    Text("Cycle \(state.cyclesCompleted + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
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

    private func waterCycleScene(height: CGFloat) -> some View {
        ZStack {
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
                    sunView
                    Spacer()
                    cloudView
                }
                .padding(.horizontal, 30)
                .padding(.top, 28)

                Spacer()

                HStack(alignment: .bottom) {
                    vaporColumn
                    Spacer()
                    rainColumn
                }
                .padding(.horizontal, 44)

                pondView
                    .padding(.horizontal, 34)
                    .padding(.bottom, 24)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Water cycle picture with sun, vapor, cloud, rain, and pond")
    }

    private var sunView: some View {
        ZStack {
            Circle().fill(MatherTheme.warm.opacity(0.28)).frame(width: 136, height: 136)
            Circle().fill(MatherTheme.warm).frame(width: 92, height: 92)
            Image(systemName: "sun.max.fill")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var cloudView: some View {
        VStack(spacing: 8) {
            ZStack {
                Capsule().fill(MatherTheme.card).frame(width: 172, height: 78)
                HStack(spacing: -18) {
                    Circle().fill(MatherTheme.card).frame(width: 72, height: 72)
                    Circle().fill(MatherTheme.card).frame(width: 96, height: 96)
                    Circle().fill(MatherTheme.card).frame(width: 70, height: 70)
                }
                HStack(spacing: 10) {
                    ForEach(0..<state.cloudDrops, id: \.self) { _ in
                        Circle().fill(MatherTheme.softBlue).frame(width: 18, height: 18)
                    }
                }
                .offset(y: 18)
            }
            Text("cloud")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
    }

    private var vaporColumn: some View {
        VStack(spacing: 12) {
            ForEach(0..<state.vaporDrops, id: \.self) { index in
                Image(systemName: "drop.fill")
                    .font(.system(size: 26 + CGFloat(index * 3), weight: .bold))
                    .foregroundStyle(MatherTheme.softBlue.opacity(0.72))
            }
            Text("water goes up")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
        .frame(width: 140, minHeight: 138)
    }

    private var rainColumn: some View {
        VStack(spacing: 10) {
            ForEach(0..<state.rainDrops, id: \.self) { _ in
                Image(systemName: "drop.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(MatherTheme.accent)
            }
            Text("rain falls down")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
        .frame(width: 140, minHeight: 138)
    }

    private var pondView: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(MatherTheme.softBlue.opacity(0.25)).frame(height: 92)
            Capsule().fill(MatherTheme.softBlue).frame(height: CGFloat(32 + state.pondDrops * 10))
            HStack(spacing: 12) {
                ForEach(0..<state.pondDrops, id: \.self) { _ in
                    Circle().fill(.white.opacity(0.65)).frame(width: 18, height: 18)
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

    private var actionControls: some View {
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

            HStack(spacing: 12) {
                Button {
                    speakPrompt()
                } label: {
                    Label("Replay prompt", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.panelDeep.opacity(0.28)))

                Button {
                    state.reset()
                    speakPrompt()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.coral.opacity(0.42)))
            }
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
