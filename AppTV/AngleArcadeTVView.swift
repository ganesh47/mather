import SwiftUI
import UIKit

@MainActor
struct AngleArcadeTVView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.resetFocus) private var resetFocus
    @Namespace private var actionFocusScope
    @State private var engine = Self.makeEngine()
    @State private var narration = TVNarrationController()
    @State private var flightTask: Task<Void, Never>?
    @State private var focusTask: Task<Void, Never>?
    @State private var flightProgress = 0.0
    @FocusState private var focusedAction: String?
    var onExit: () -> Void = {}

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            VStack(alignment: .leading, spacing: 24) {
                header
                if engine.phase == .worldSelection {
                    worldSelector
                } else if engine.phase == .worldComplete {
                    finale
                } else {
                    mission
                }
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.top, 90)
            .padding(.bottom, 50)
        }
        .focusScope(actionFocusScope)
        .onAppear { restoreFocus(); narration.presentPrompt(engine.prompt) }
        .onChange(of: engine.phase) { _, phase in
            if phase != .flying { restoreFocus() }
            if phase == .result { announce(resultMessage) }
            else if phase != .flying { narration.presentPrompt(engine.prompt) }
        }
        .onChange(of: focusedAction) { _, action in
            guard let action else { narration.focus(nil); return }
            guard engine.phase == .worldSelection || engine.phase == .worldComplete else { return }
            if let world = AngleArcadeWorld.allCases.first(where: { $0.id == action }) {
                narration.focus("\(world.title). \(world.subtitle). Select to explore.")
            } else {
                narration.focus(action == "replay" ? "Replay this world." : "Choose another world.")
            }
        }
        .onMoveCommand(perform: move)
        .onPlayPauseCommand { help() }
        .onExitCommand {
            stopTransientWork()
            if engine.phase == .worldSelection { onExit() }
            else { engine.showWorlds() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { stopTransientWork() }
            else { restoreFocus() }
        }
        .onDisappear { stopTransientWork() }
    }

    private static func makeEngine() -> AngleArcadeEngine {
        guard ProcessInfo.processInfo.arguments.contains("-angle-arcade-ui-test"),
              let defaults = UserDefaults(suiteName: "mather.angleArcade.tvUITests") else { return .init() }
        if ProcessInfo.processInfo.arguments.contains("-angle-arcade-reset-progress") {
            defaults.removePersistentDomain(forName: "mather.angleArcade.tvUITests")
        }
        return .init(store: .init(defaults: defaults, scope: "tv-ui-test"))
    }

    private var motionReduced: Bool {
        reduceMotion || (ProcessInfo.processInfo.arguments.contains("-angle-arcade-ui-test") &&
                         ProcessInfo.processInfo.arguments.contains("-angle-arcade-reduce-motion"))
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Angle Arcade")
                    .font(.system(size: 58, weight: .heavy, design: .rounded))
                Text(engine.phase == .worldSelection ? "Three worlds. Nine little adventures." : engine.currentWorld.title)
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .accessibilityIdentifier("angle-arcade-phase")
                    .accessibilityValue(phaseName)
            }
            Spacer()
            Label(engine.phase == .worldSelection ? "Menu · All games" : "Menu · Worlds", systemImage: "chevron.backward")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
                .padding(.top, 12)
        }
        .foregroundStyle(.white)
    }

    private var worldSelector: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label(allWorldsComplete ? "Every creation is ready! Pick a world to play again." : "Try next: \(suggestedLevel.world.title) · \(suggestedLevel.title)", systemImage: allWorldsComplete ? "checkmark.seal.fill" : "play.circle.fill")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.78, green: 0.94, blue: 0.66))
            HStack(spacing: 32) {
                ForEach(AngleArcadeWorld.allCases) { world in
                    let count = engine.progress.completedCount(in: world)
                    Button {
                        flightProgress = 0
                        engine.selectWorld(world)
                    } label: {
                        VStack(alignment: .leading, spacing: 16) {
                            AngleArcadeWorldArtwork(world: world, completedCount: count)
                                .frame(height: 270)
                            Label(world.title, systemImage: world.symbolName)
                                .font(.system(size: 31, weight: .bold, design: .rounded))
                            Text(world.subtitle)
                                .font(.system(size: 23, weight: .semibold, design: .rounded))
                                .lineLimit(2)
                                .frame(height: 60, alignment: .topLeading)
                            HStack(spacing: 12) {
                                ForEach(0..<3) { index in
                                    Image(systemName: index < count ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(focusedAction == world.id ? Color(red: 0.10, green: 0.34, blue: 0.24) : index < count ? Color.green : Color.white.opacity(0.75))
                                }
                                Text("\(count) of 3 complete").font(.system(size: 21, weight: .semibold, design: .rounded))
                            }
                        }
                        .padding(28)
                        .frame(width: 475, height: 490, alignment: .topLeading)
                    }
                    .buttonStyle(AngleArcadeWorldCardStyle(reduceMotion: motionReduced))
                    .focused($focusedAction, equals: world.id)
                    .prefersDefaultFocus(world == suggestedLevel.world, in: actionFocusScope)
                    .accessibilityLabel("\(world.title). \(world.subtitle). \(count) of 3 missions complete")
                    .accessibilityIdentifier("angle-world-\(world.id)")
                }
            }
            Text("Swipe to choose  •  Select to explore  •  Play/Pause to hear help")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
        }
        .padding(.top, 18)
    }

    private var mission: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text(engine.level.title)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .accessibilityIdentifier("angle-mission-\(engine.level.id)")
                    Text(engine.level.prompt)
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }
                Spacer()
                Text("Mission \(missionNumber) of 3")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .accessibilityIdentifier("angle-arcade-target-progress")
            }
            .foregroundStyle(.white)

            AngleArcadeTVScene(engine: engine, flightProgress: flightProgress, reduceMotion: motionReduced)
                .frame(height: 455)
            HStack(spacing: 18) {
                controlTile(title: engine.level.kind == .rotation ? (engine.level.id == "builder-quarter-turn" ? "Turn" : "Direction") : "Angle", value: angleValue, symbol: engine.level.allowsAngle ? "arrow.left.and.right" : "lock.fill", id: "angle-arcade-angle") { direction in
                    changeAngle(direction == .increment ? 1 : -1)
                }
                if engine.level.allowsPower {
                    controlTile(title: "Power", value: "\(Int(engine.power))", symbol: "arrow.up.and.down", id: "angle-arcade-power") { direction in
                        changePower(direction == .increment ? 1 : -1)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(engine.phase == .result ? (engine.success ? "Great work!" : "Try a new aim") : engine.phase == .flying ? "Flying…" : "Ready")
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .accessibilityIdentifier("angle-arcade-result")
                    Text("\(engine.progress.completedCount(in: engine.currentWorld)) of 3 complete")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                        .accessibilityIdentifier("angle-arcade-hit-count")
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(minWidth: 230, minHeight: 105, alignment: .leading)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
                Spacer()
                Button(action: primaryAction) {
                    Label(primaryLabel, systemImage: engine.phase == .result && engine.success ? "arrow.right" : engine.level.kind == .rotation ? "checkmark" : "paperplane.fill")
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .frame(width: 240, height: 90)
                }
                .buttonStyle(.borderedProminent)
                .focused($focusedAction, equals: "primary")
                .prefersDefaultFocus(true, in: actionFocusScope)
                .accessibilityIdentifier("angle-arcade-primary")
                .accessibilityHint(engine.hint)
            }
            Text(engine.phase == .result ? resultMessage : controlHint)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(2)
        }
    }

    private var finale: some View {
        HStack(spacing: 60) {
            AngleArcadeWorldArtwork(world: engine.currentWorld, completedCount: 3)
                .frame(width: 530, height: 510)
            VStack(alignment: .leading, spacing: 24) {
                Text(rewardTitle)
                    .font(.system(size: 49, weight: .heavy, design: .rounded))
                Text("Three missions complete. You made this!")
                    .font(.system(size: 29, weight: .semibold, design: .rounded))
                HStack(spacing: 18) {
                    Button {
                        engine.showWorlds()
                    } label: {
                        Label("Other worlds", systemImage: "map.fill")
                            .foregroundStyle(focusedAction == "worlds" ? Color(red: 0.10, green: 0.20, blue: 0.25) : .white)
                            .frame(minWidth: 230, minHeight: 90)
                    }
                    .focused($focusedAction, equals: "worlds")
                    .prefersDefaultFocus(true, in: actionFocusScope)
                    .accessibilityIdentifier("angle-arcade-worlds")
                    Button {
                        flightProgress = 0
                        engine.selectLevel(AngleArcadeCampaign.levels(in: engine.currentWorld)[0].id)
                    } label: {
                        Label("Play again", systemImage: "arrow.clockwise")
                            .foregroundStyle(focusedAction == "replay" ? Color(red: 0.10, green: 0.20, blue: 0.25) : .white)
                            .frame(minWidth: 230, minHeight: 90)
                    }
                    .focused($focusedAction, equals: "replay")
                    .accessibilityIdentifier("angle-arcade-replay-world")
                }
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .buttonStyle(.borderedProminent)
            }
            .foregroundStyle(.white)
        }
        .padding(.top, 35)
    }

    private var allWorldsComplete: Bool {
        AngleArcadeWorld.allCases.allSatisfy { engine.progress.completedCount(in: $0) == 3 }
    }

    private var suggestedLevel: AngleArcadeLevel {
        if let last = engine.progress.lastLevelID, !engine.progress.hasCompleted(last),
           let level = AngleArcadeCampaign.level(id: last) { return level }
        return AngleArcadeCampaign.level(id: engine.progress.nextSuggestedLevelID) ?? AngleArcadeCampaign.levels[0]
    }

    private var rewardTitle: String {
        switch engine.currentWorld {
        case .garden: "Your garden is blooming!"
        case .builder: "Your clubhouse is ready!"
        case .moon: "Your rocket is ready!"
        }
    }

    private var missionNumber: Int {
        (AngleArcadeCampaign.levels(in: engine.currentWorld).firstIndex(where: { $0.id == engine.level.id }) ?? 0) + 1
    }

    private var angleValue: String {
        if engine.phase == .result && engine.success { return "\(Int(engine.angle))°" }
        if engine.level.kind == .rotation { return "Turn" }
        return engine.angle < 35 ? "Low" : engine.angle < 55 ? "Middle" : "Steep"
    }

    private var controlHint: String {
        if engine.phase == .flying { return "Watch your delivery!" }
        if !engine.level.allowsAngle && !engine.level.allowsPower { return "Your seed is ready!  •  Select → launch  •  Play/Pause → help" }
        if !engine.level.allowsAngle { return "↑ ↓ Power  •  The angle stays fixed  •  Select → launch  •  Play/Pause → help" }
        return engine.level.allowsPower
            ? "← → Angle  •  ↑ ↓ Power  •  Select → launch  •  Play/Pause → help"
            : "← → \(engine.level.kind == .rotation ? "Turn" : "Angle")  •  Select → \(engine.level.kind == .rotation ? "check" : "launch")  •  Play/Pause → help"
    }

    private var resultMessage: String {
        engine.success ? engine.feedback : engine.feedback + " " + engine.hint
    }

    private var primaryLabel: String {
        if engine.phase == .flying { return "Flying…" }
        if engine.phase == .result { return engine.success ? "Next mission" : "Try again" }
        return engine.level.kind == .rotation ? "Check turn" : "Launch"
    }

    private func controlTile(title: String, value: String, symbol: String, id: String, action: @escaping (AccessibilityAdjustmentDirection) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol).font(.system(size: 21, weight: .semibold, design: .rounded))
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(width: 185, height: 105, alignment: .leading)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(id == "angle-arcade-angle" ? "\(Int(engine.angle)) degrees" : value)
        .accessibilityIdentifier(id)
        .accessibilityHint(id == "angle-arcade-angle" && !engine.level.allowsAngle ? "The angle stays fixed in this mission." : "Use the arrows to adjust.")
        .accessibilityAdjustableAction(action)
    }

    private func primaryAction() {
        if engine.phase == .result {
            flightProgress = 0
            if engine.success { engine.nextMission() } else { engine.retry() }
            return
        }
        guard engine.submit() else { return }
        guard engine.phase == .flying else { return }
        narration.stop()
        flightProgress = motionReduced ? 1 : 0
        let attempt = engine.attemptID
        let reduced = motionReduced
        flightTask?.cancel()
        flightTask = Task { @MainActor in
            let steps = reduced ? 1 : 40
            for step in 1...steps {
                do { try await Task.sleep(for: .milliseconds(reduced ? 300 : 30)) }
                catch { return }
                guard !Task.isCancelled, engine.attemptID == attempt, engine.phase == .flying else { return }
                flightProgress = Double(step) / Double(steps)
            }
            engine.finishFlight(expectedAttemptID: attempt)
            flightTask = nil
        }
    }

    private func move(_ direction: MoveCommandDirection) {
        guard engine.phase == .aiming || (engine.phase == .result && !engine.success) else { return }
        switch direction {
        case .left: changeAngle(-1)
        case .right: changeAngle(1)
        case .up: changePower(1)
        case .down: changePower(-1)
        @unknown default: return
        }
    }

    private func changeAngle(_ direction: Int) {
        if engine.phase == .result && !engine.success { engine.retry(); flightProgress = 0 }
        engine.adjustAngle(direction)
        narration.focus(engine.hint)
    }

    private func changePower(_ direction: Int) {
        if engine.phase == .result && !engine.success { engine.retry(); flightProgress = 0 }
        engine.adjustPower(direction)
        narration.focus(engine.level.allowsPower ? engine.hint : "Use left and right to change the angle. Play Pause gives help.")
    }

    private func help() {
        guard engine.phase != .flying else { narration.announce("Watch the delivery fly."); return }
        if engine.phase == .aiming || engine.phase == .result {
            engine.requestHelp()
            announce(engine.phase == .result ? resultMessage : engine.prompt + " " + engine.hint)
        } else { narration.repeatPrompt() }
    }

    private func announce(_ message: String) {
        narration.presentPrompt(message)
        if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: message) }
    }

    private func restoreFocus() {
        focusTask?.cancel()
        focusTask = Task { @MainActor in
            do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
            guard !Task.isCancelled, scenePhase == .active else { return }
            focusedAction = engine.phase == .worldSelection ? suggestedLevel.world.id : engine.phase == .worldComplete ? "worlds" : "primary"
            resetFocus(in: actionFocusScope)
        }
    }

    private func stopTransientWork() {
        // tvOS can discard actual focus while the binding still names the old action.
        focusedAction = nil
        flightTask?.cancel(); flightTask = nil
        focusTask?.cancel(); focusTask = nil
        let wasFlying = engine.phase == .flying
        engine.cancelFlight()
        if wasFlying { flightProgress = 0 }
        narration.stop()
    }
}

/// Own both colors so tvOS never puts forced white labels on its pale focus fill.
private struct AngleArcadeWorldCardStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isFocused ? Color(red: 0.06, green: 0.10, blue: 0.16) : .white)
            .background(isFocused ? Color(red: 0.95, green: 0.97, blue: 0.98) : Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(isFocused ? Color.orange : .white.opacity(0.18), lineWidth: isFocused ? 5 : 2))
            .scaleEffect(isFocused && !reduceMotion ? 1.035 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isFocused)
    }
}
