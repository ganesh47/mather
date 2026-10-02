import SwiftUI
import UIKit

/// The original Angle Cannon route now opens the shared geometry adventure.
@MainActor
struct AngleCannonView: View {
    @Bindable var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flightTask: Task<Void, Never>?
    @State private var flightProgress = 0.0
    @State private var tiltEnabled = false
    @State private var neutralRoll: Double?
    @State private var neutralAngle = 45.0
    @State private var sessionEngine: AngleArcadeEngine?
    @State private var evidenceProfileID: String
    @State private var evidenceSessionID = UUID().uuidString
    @State private var evidenceStartedAt = Date.now
    @State private var attempts: [ItemAttempt] = []
    @State private var completedMissionIDs: [String] = []
    @State private var helpedMissionIDs: Set<String> = []
    @State private var pendingAttempt: ItemAttempt?
    @State private var pendingAttemptID: Int?

    init(appModel: AppModel) {
        self.appModel = appModel
        _evidenceProfileID = State(initialValue: appModel.profileStore.activeProfileId)
    }

    private var engine: AngleArcadeEngine { sessionEngine ?? appModel.angleArcadeEngine }
    private var isActiveProfile: Bool { appModel.profileStore.activeProfileId == evidenceProfileID }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                header.padding(.horizontal, 18)
                if engine.phase == .worldSelection {
                    ScrollView { worldPicker.padding(18) }
                        .accessibilityIdentifier("angle-arcade-scroll")
                        .disabled(!isActiveProfile)
                } else if engine.phase == .worldComplete {
                    ScrollView { celebration.padding(18) }
                        .accessibilityIdentifier("angle-arcade-scroll")
                        .disabled(!isActiveProfile)
                } else if UIDevice.current.userInterfaceIdiom == .pad && geometry.size.width > geometry.size.height && geometry.size.width >= 750 {
                    HStack(alignment: .top, spacing: 22) {
                        VStack(spacing: 14) {
                            missionHeader
                            missionScene
                                .frame(maxHeight: .infinity)
                        }
                        controls.frame(width: 350).disabled(!isActiveProfile)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            missionHeader
                            missionScene.frame(height: max(240, min(380, geometry.size.height * 0.34)))
                            controls.disabled(!isActiveProfile)
                        }
                        .padding(18)
                    }
                    .accessibilityIdentifier("angle-arcade-scroll")
                }
            }
            .padding(.top, 12)
            .frame(maxWidth: 1150)
            .frame(maxWidth: .infinity)
            .background(MatherTheme.background.ignoresSafeArea())
        }
        .onAppear {
            guard sessionEngine == nil, isActiveProfile else { return }
            appModel.prepareAngleArcadeProfile()
            sessionEngine = appModel.angleArcadeEngine
            evidenceStartedAt = .now
            engine.beginSession()
            narrate()
        }
        .onChange(of: engine.phase) { _, phase in
            if phase == .flying { animateDelivery() }
            else {
                if phase == .result { recordCompletedAttempt() }
                narrate()
            }
        }
        .onChange(of: engine.level.id) { _, _ in
            stopTilt()
            flightProgress = 0
            narrate()
        }
        .onChange(of: appModel.motionService.tiltRoll) { _, roll in
            guard isActiveProfile, tiltEnabled, engine.phase == .aiming,
                  engine.level.kind == .launch, engine.level.allowsAngle else { return }
            guard let neutralRoll else {
                self.neutralRoll = roll
                neutralAngle = engine.angle
                return
            }
            engine.setAngle(neutralAngle + (roll - neutralRoll) / (.pi / 4) * 30)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                cancelFlight()
                stopTilt()
                appModel.speechService.stop()
            } else { narrate() }
        }
        .onChange(of: appModel.profileStore.activeProfileId) { _, _ in
            guard !isActiveProfile else { return }
            cancelFlight()
            stopTilt()
            appModel.speechService.stop()
        }
        .onDisappear {
            recordCompletedAttempt()
            cancelFlight()
            stopTilt()
            appModel.speechService.stop()
            guard isActiveProfile else { return }
            saveEvidenceResult()
            if engine.sessionCompletionCount > 0 {
                appModel.gameSessionStore.save(
                    gameName: "Angle Cannon", startedAt: engine.sessionStartedAt,
                    scoreValue: engine.sessionCompletionCount, scoreLabel: "missions explored",
                    detail: "This play: \(attempts.filter { $0.outcome == .supportedCorrect }.count) missions completed with support; \(attempts.filter { $0.outcome == .independentCorrect }.count) independently. Completion records exploration, not mastery."
                )
            }
        }
    }

    private var missionScene: some View {
        AngleArcadeScene(engine: engine, flightProgress: flightProgress)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(engine.level.title)
            .accessibilityValue(engine.phase == .result ? engine.feedback : engine.hint)
            .accessibilityIdentifier("angle-cannon-canvas")
    }

    private var phaseName: String {
        switch engine.phase {
        case .worldSelection: "Choose a world"
        case .aiming: "Aiming"
        case .flying: "Flying"
        case .result: "Result"
        case .worldComplete: "World complete"
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Angle Arcade")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Text("Launch • Turn • Discover")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .accessibilityValue(phaseName)
                    .accessibilityIdentifier("angle-arcade-phase")
            }
            Spacer()
            Button {
                recordCompletedAttempt()
                cancelFlight()
                stopTilt()
                appModel.engine.returnFromGameplay(defaultRoute: .home)
            } label: {
                Image(systemName: "xmark.circle.fill").font(.title2)
                    .frame(width: 80, height: 80)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Done")
            .accessibilityIdentifier("angle-cannon-done-button")
        }
        .foregroundStyle(MatherTheme.ink)
    }

    private var worldPicker: some View {
        VStack(spacing: 16) {
            Button { engine.startSuggested() } label: {
                Label("Continue your adventure", systemImage: "play.circle.fill")
                    .font(.title3.bold()).frame(maxWidth: .infinity, minHeight: 80)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("angle-arcade-continue")
            Text("Choose an adventure")
                .font(.title2.bold())
                .accessibilityIdentifier("angle-arcade-world-selector")
            ForEach(AngleArcadeWorld.allCases, id: \.self) { world in
                Button { engine.selectWorld(world) } label: {
                    HStack(spacing: 18) {
                        AngleArcadeWorldArtwork(world: world, completedCount: engine.progress.completedCount(in: world))
                            .frame(width: 95, height: 95)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(world.title).font(.title2.bold())
                            Text(world.subtitle).font(.subheadline)
                            Text("\(engine.progress.completedCount(in: world)) of 3 pieces collected")
                                .font(.subheadline.weight(.semibold))
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill").font(.largeTitle)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
                    .background(MatherTheme.panel, in: RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(world.title). \(world.subtitle). \(engine.progress.completedCount(in: world)) of three pieces collected. Play.")
                .accessibilityIdentifier("angle-world-\(world.rawValue)")
            }
            Text("Every world is open. Come back and play again!")
                .font(.subheadline).foregroundStyle(MatherTheme.cardSubtitle)
        }
        .foregroundStyle(MatherTheme.ink)
    }

    private var missionHeader: some View {
        VStack(spacing: 8) {
            Text(engine.level.title).font(.title2.bold())
                .accessibilityIdentifier("angle-mission-\(engine.level.id)")
            Text(engine.phase == .result ? (engine.success ? "A new discovery!" : "Try another idea") : engine.level.prompt).font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Mission \((AngleArcadeCampaign.levels(in: engine.level.world).firstIndex(where: { $0.id == engine.level.id }) ?? 0) + 1) of 3")
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("angle-arcade-mission-progress")

        }
        .foregroundStyle(MatherTheme.ink)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { angleMetric; if engine.level.kind == .launch { powerMetric } }
                VStack(spacing: 16) { angleMetric; if engine.level.kind == .launch { powerMetric } }
            }
            Text(engine.phase == .result && engine.success ? "Great work!" : engine.feedback).font(.headline)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("angle-arcade-result")
            if engine.phase == .result {
                Text(engine.success ? engine.level.successExplanation : engine.hint)
                    .font(.body).multilineTextAlignment(.center)
            }
            Button(action: primaryAction) {
                Label(primaryLabel, systemImage: engine.success && engine.phase == .result ? "arrow.right.circle.fill" : "paperplane.fill")
                    .font(.title2.bold()).frame(maxWidth: .infinity, minHeight: 80)
            }
            .buttonStyle(.borderedProminent).tint(MatherTheme.accent)
            .disabled(engine.phase == .flying)
            .accessibilityIdentifier("angle-arcade-primary")
            HStack(spacing: 12) {
                utilityButton("Help", symbol: "ear.badge.waveform", identifier: "angle-arcade-help") {
                    requestHelp()
                }
                utilityButton("Worlds", symbol: "square.grid.2x2.fill", identifier: "angle-arcade-worlds") {
                    cancelFlight(); stopTilt(); engine.showWorlds()
                }
                if engine.level.kind == .launch && engine.level.allowsAngle {
                    utilityButton(tiltEnabled ? "Touch" : "Tilt", symbol: tiltEnabled ? "hand.tap.fill" : "gyroscope", identifier: "angle-arcade-tilt") {
                        if tiltEnabled { stopTilt(); speak("Touch the arrows to aim.") }
                        else {
                            guard appModel.motionService.isDeviceMotionAvailable else {
                                speak("This device uses touch. The arrows are ready to aim.")
                                return
                            }
                            tiltEnabled = true
                            appModel.motionService.startUpdates()
                            neutralRoll = nil
                            neutralAngle = engine.angle
                            speak("Hold your iPad comfortably. This is your starting aim. Tilt gently to change the angle. Touch the arrows anytime, or choose Touch to stop tilting.")
                        }
                    }
                }
            }
        }
        .foregroundStyle(MatherTheme.ink)
    }

    private var angleMetric: some View {
        metric(title: engine.level.kind == .rotation ? (engine.level.id == "builder-quarter-turn" ? "Turn" : "Direction") : "Angle", value: "\(Int(engine.angle))", enabled: engine.level.allowsAngle,
               identifier: "angle-arcade-angle", decreaseID: "angle-angle-decrease", increaseID: "angle-angle-increase") { engine.adjustAngle($0) }
    }

    private var powerMetric: some View {
        metric(title: "Push", value: "\(Int(engine.power))", enabled: engine.level.allowsPower,
               identifier: "angle-arcade-power", decreaseID: "angle-power-decrease", increaseID: "angle-power-increase") { engine.adjustPower($0) }
    }

    private func metric(title: String, value: String, enabled: Bool, identifier: String,
                        decreaseID: String, increaseID: String, action: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.headline)
            // Numbers label the child's discovery after success, rather than being the task.
            Text(engine.phase == .result && engine.success ? "\(value)\(title == "Push" ? "" : "°")" : (enabled ? "Try the arrows" : "Stays the same"))
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier(identifier)
                .accessibilityLabel(title)
                .accessibilityValue(value)
            HStack(spacing: 4) {
                Button { action(-1); recenterTilt() } label: {
                    Image(systemName: "minus").font(.title2.bold()).frame(width: 80, height: 80)
                }
                .accessibilityLabel("Decrease \(title.lowercased())")
                .accessibilityIdentifier(decreaseID)
                Button { action(1); recenterTilt() } label: {
                    Image(systemName: "plus").font(.title2.bold()).frame(width: 80, height: 80)
                }
                .accessibilityLabel("Increase \(title.lowercased())")
                .accessibilityIdentifier(increaseID)
            }
            .buttonStyle(.bordered)
            .disabled(!enabled || engine.phase == .flying || (engine.phase == .result && engine.success))
        }
        .frame(maxWidth: .infinity)
    }

    private func utilityButton(_ title: String, symbol: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) { Image(systemName: symbol).font(.title2); Text(title).font(.caption.bold()) }
                .frame(maxWidth: .infinity, minHeight: 80)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(identifier)
    }

    private var celebration: some View {
        VStack(spacing: 20) {
            Text("You built it!").font(.largeTitle.bold())
            AngleArcadeWorldArtwork(world: engine.currentWorld, completedCount: 3)
                .frame(height: 330)
                .background(MatherTheme.panel, in: RoundedRectangle(cornerRadius: 24))
            Text("Three discoveries, one wonderful creation.")
                .font(.title3.bold()).multilineTextAlignment(.center)
            Button { engine.selectWorld(engine.level.world) } label: {
                Label("Play again", systemImage: "arrow.clockwise").frame(maxWidth: .infinity, minHeight: 80)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("angle-arcade-replay-world")
            utilityButton("Choose world", symbol: "square.grid.2x2.fill", identifier: "angle-arcade-worlds") { engine.showWorlds() }
        }
        .foregroundStyle(MatherTheme.ink)
    }

    private var primaryLabel: String {
        if engine.phase == .flying { return "Flying…" }
        if engine.phase == .result { return engine.success ? "Next mission" : "Try again" }
        return engine.level.kind == .rotation ? "Check my turn" : "Launch"
    }

    private func primaryAction() {
        guard isActiveProfile else { return }
        if engine.phase == .result {
            if engine.success { engine.nextMission() } else { engine.retry() }
        } else if engine.phase == .aiming {
            let level = engine.level
            let angle = engine.angle
            let power = engine.power
            let misses = engine.misses
            let preview = engine.showsFullPreview
            let helped = helpedMissionIDs.contains(level.id)
            let earlierSupport = attempts.contains {
                $0.entityID == level.id && ($0.outcome == .help || $0.outcome == .incorrect || $0.outcome == .supportedCorrect)
            }
            guard engine.submit() else { return }
            pendingAttemptID = engine.attemptID
            pendingAttempt = ItemAttempt(
                activityID: LabActivityID.angleCannon.rawValue,
                conceptID: level.kind == .rotation ? "rotation" : "angle-and-power",
                entityID: level.id, propertyID: level.kind == .rotation ? "turn" : "launch",
                stageID: level.id,
                outcome: level.guided || preview || helped || earlierSupport || misses > 0 ? .supportedCorrect : .independentCorrect,
                response: "attempt=\(engine.attemptID); angle=\(angle); push=\(power); input=\(tiltEnabled ? "tilt enabled" : "touch"); guided=\(level.guided); fullPreview=\(preview); help=\(helped); earlierSupport=\(earlierSupport); priorMisses=\(misses)",
                profileID: evidenceProfileID, sessionID: evidenceSessionID, contentVersion: 1
            )
            // Rotation checks resolve synchronously; launches resolve after their flight.
            recordCompletedAttempt()
        }
    }

    private func requestHelp() {
        guard isActiveProfile, engine.phase == .aiming || engine.phase == .result, !engine.success else { return }
        engine.requestHelp()
        if helpedMissionIDs.insert(engine.level.id).inserted {
            record(ItemAttempt(
                activityID: LabActivityID.angleCannon.rawValue,
                conceptID: engine.level.kind == .rotation ? "rotation" : "angle-and-power",
                entityID: engine.level.id, propertyID: engine.level.kind == .rotation ? "turn" : "launch",
                stageID: engine.level.id, outcome: .help, response: engine.hint,
                profileID: evidenceProfileID, sessionID: evidenceSessionID, contentVersion: 1
            ))
            saveEvidenceResult()
        }
        speak(engine.prompt + " " + engine.hint)
    }

    private func recordCompletedAttempt() {
        guard isActiveProfile, engine.phase == .result,
              pendingAttemptID == engine.attemptID, let pendingAttempt else { return }
        let outcome = engine.success ? pendingAttempt.outcome : .incorrect
        record(pendingAttempt.withOutcome(outcome))
        if engine.success, !completedMissionIDs.contains(engine.level.id) {
            completedMissionIDs.append(engine.level.id)
        }
        self.pendingAttempt = nil
        pendingAttemptID = nil
        saveEvidenceResult()
    }

    private func record(_ attempt: ItemAttempt) {
        attempts.append(attempt)
        appModel.gameplayProgressStore.recordAttempts([attempt], sessionID: evidenceSessionID)
    }

    private func saveEvidenceResult() {
        guard isActiveProfile, !attempts.isEmpty else { return }
        appModel.gameplayProgressStore.saveActivityResult(ActivityResult(
            id: evidenceSessionID, activityID: LabActivityID.angleCannon.rawValue,
            title: "Angle Arcade", startedAt: evidenceStartedAt, attempts: attempts,
            completedStageIDs: completedMissionIDs, profileID: evidenceProfileID, contentVersion: 1
        ))
    }

    private func animateDelivery() {
        flightTask?.cancel()
        flightProgress = reduceMotion ? 1 : 0
        let attempt = engine.attemptID
        let currentEngine = engine
        let reduced = reduceMotion
        flightTask = Task { @MainActor in
            let steps = reduced ? 1 : 40
            for step in 1...steps {
                do { try await Task.sleep(for: .milliseconds(reduced ? 300 : 30)) }
                catch { return }
                guard !Task.isCancelled, isActiveProfile,
                      currentEngine.attemptID == attempt, currentEngine.phase == .flying else { return }
                flightProgress = Double(step) / Double(steps)
            }
            currentEngine.finishFlight(expectedAttemptID: attempt)
            recordCompletedAttempt()
            flightTask = nil
        }
    }

    private func cancelFlight() {
        flightTask?.cancel(); flightTask = nil
        engine.cancelFlight()
        pendingAttempt = nil
        pendingAttemptID = nil
        if engine.phase != .result { flightProgress = 0 }
    }

    private func recenterTilt() {
        guard tiltEnabled else { return }
        neutralRoll = appModel.motionService.tiltRoll
        neutralAngle = engine.angle
    }

    private func stopTilt() {
        tiltEnabled = false; neutralRoll = nil
        appModel.motionService.stopUpdates()
    }

    private func narrate() {
        guard isActiveProfile else { return }
        switch engine.phase {
        case .worldSelection: speak("Choose Garden deliveries, Builder bay, or Moon parcels. Every world is open. Touch a picture to play.")
        case .worldComplete: speak("You built it! Three discoveries made a wonderful creation. Play again or choose another world.")
        case .result: speak(engine.success ? "\(engine.feedback) Touch Next mission." : "\(engine.feedback) \(engine.hint) Touch the arrows to try another idea.")
        case .aiming: speak(engine.prompt)
        case .flying: break
        }
    }

    private func speak(_ text: String) {
        guard scenePhase == .active else { return }
        if UIAccessibility.isVoiceOverRunning {
            appModel.speechService.stop()
            UIAccessibility.post(notification: .announcement, argument: text)
        } else { appModel.speechService.speak(text, enabled: appModel.featureFlags.audioEnabled) }
    }
}
