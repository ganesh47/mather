import SwiftUI
import UIKit

@MainActor
struct ShapeDetectiveTVView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.resetFocus) private var resetFocus
    @Namespace private var focusScope
    @FocusState private var focusedAction: String?
    @State private var session: ShapeDetectiveTVSession
    @State private var narration = TVNarrationController()
    @State private var focusTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss
    private let onExit: (() -> Void)?
    private static var didResetUITestProgress = false

    init(profileID: String = "tv-family", familyMode: Bool = true,
         onAttempt: @escaping (ItemAttempt) -> Void = { _ in }, onResult: @escaping (ActivityResult) -> Void = { _ in }, onExit: (() -> Void)? = nil) {
        self.onExit = onExit
        var store: ShapeDetectiveTVSessionStore?
        if ProcessInfo.processInfo.arguments.contains("-shape-detective-ui-test"),
           let defaults = UserDefaults(suiteName: "mather.shapeDetective.tvUITests") {
            if ProcessInfo.processInfo.arguments.contains("-shape-detective-reset-progress"), !Self.didResetUITestProgress {
                defaults.removePersistentDomain(forName: "mather.shapeDetective.tvUITests")
                if ProcessInfo.processInfo.arguments.contains("-shape-detective-corrupt-checkpoint") {
                    defaults.set(Data("unreadable saved investigation".utf8), forKey: "mather.shape-detective.v1.\(profileID)")
                }
                Self.didResetUITestProgress = true
            }
            store = .init(defaults: defaults, profileID: profileID)
        }
        _session = State(initialValue: .init(profileID: profileID, familyMode: familyMode, store: store,
                                             onAttempt: onAttempt, onResult: onResult))
    }

    private var motionReduced: Bool {
        reduceMotion || (ProcessInfo.processInfo.arguments.contains("-shape-detective-ui-test") &&
                         ProcessInfo.processInfo.arguments.contains("-shape-detective-reduce-motion"))
    }

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            VStack(alignment: .leading, spacing: 26) {
                header
                if session.storageIssue != nil { storageNotice }
                else if session.isComplete { finale }
                else if let item = session.current {
                    clueCard(item)
                    shapeChoices(item)
                    feedback
                }
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.top, 85)
            .padding(.bottom, 55)
        }
        .focusScope(focusScope)
        .onAppear { restoreFocus(); announce(session.prompt) }
        .onChange(of: focusedAction) { _, action in narration.focus(focusDescription(action)) }
        .onPlayPauseCommand { announce(session.prompt) }
        .onMoveCommand(perform: move)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { restoreFocus() } else { stopTransientWork() }
        }
        .onDisappear { stopTransientWork() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shape Detective")
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 9) {
                Text("Shape Detective")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .accessibilityIdentifier("tv-shape-title")
                Text(session.storageIssue != nil ? "Saved investigation paused" : session.isComplete ? "Investigation complete" : "Check the sides and corners. A turn does not change a shape.")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .accessibilityIdentifier("tv-shape-phase")
                    .accessibilityValue(session.storageIssue != nil ? "Needs parent" : session.isComplete ? "Complete" : session.checkpoint.solved ? "Solved" : "Investigating")
            }
            Spacer()
            if session.storageIssue == nil {
                VStack(alignment: .trailing, spacing: 10) {
                    Label("\(session.checkpoint.completedIDs.count) of 7 solved", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.82, green: 0.94, blue: 0.73))
                        .accessibilityIdentifier("tv-shape-progress")
                }
            }
        }
        .foregroundStyle(.white)
    }

    private func clueCard(_ item: ShapeDetectiveInvestigation) -> some View {
        HStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 43, weight: .bold))
                .foregroundStyle(Color(red: 0.86, green: 0.74, blue: 1))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 9) {
                Text(item.isProbe ? (session.checkpoint.probeIsFresh ? "A new shape check" : "Another shape check") : "Clue \(session.checkpoint.index + 1) of 6")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Text(item.clue)
                    .font(.system(size: 33, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("tv-shape-clue")
    }

    private func shapeChoices(_ item: ShapeDetectiveInvestigation) -> some View {
        HStack(spacing: 28) {
            ForEach(item.choices) { choice in
                Button {
                    let correct = session.choose(choice.id)
                    announce(session.feedback)
                    if correct { restoreFocus() }
                } label: {
                    VStack(spacing: 16) {
                        ShapeDetectiveArtwork(figure: choice.figure, traceCorners: session.checkpoint.hintLevel > 1)
                            .frame(width: 220, height: 200)
                            .foregroundStyle(figureColor(choice.figure.kind))
                            .accessibilityHidden(true)
                        HStack(spacing: 10) {
                            Text(choice.label)
                            if session.checkpoint.lastChoiceID == choice.id {
                                Image(systemName: session.checkpoint.solved ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                            }
                        }
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                    }
                    .frame(width: 372, height: 290)
                }
                .buttonStyle(ShapeDetectiveButtonStyle(reduceMotion: motionReduced))
                .focused($focusedAction, equals: choice.id)
                .prefersDefaultFocus(choice.id == item.choices.first?.id && !session.checkpoint.solved, in: focusScope)
                .disabled(session.checkpoint.solved)
                .accessibilityIdentifier("tv-shape-choice-\(choice.letter)")
                .accessibilityLabel(choice.spokenDescription)
                .accessibilityValue(session.checkpoint.lastChoiceID == choice.id ? (session.checkpoint.solved ? "Solved" : "Try a different shape") : "")
                .accessibilityHint("Select if these properties match the clue.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var feedback: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.checkpoint.solved ? "Mystery solved!" : session.checkpoint.misses > 0 ? "Keep investigating" : "Look closely")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(session.feedback.replacingOccurrences(of: "Mystery solved! ", with: ""))
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.83))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("tv-shape-feedback")
            }
            Spacer(minLength: 15)
            if session.checkpoint.solved {
                actionButton(session.current?.isProbe == true ? "Finish investigation" : "Next clue", id: "next", symbol: "arrow.right") {
                    session.advance(); announce(session.prompt); restoreFocus()
                }
            } else {
                actionButton("Hint", id: "hint", symbol: "lightbulb.fill") {
                    session.requestHint(); announce(session.prompt)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(25)
        .frame(maxWidth: .infinity, minHeight: 157, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26))
        .overlay(alignment: .bottomLeading) {
            Text("Play/Pause · Repeat clue")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
                .offset(y: 31)
        }
    }

    private var storageNotice: some View {
        VStack(alignment: .leading, spacing: 26) {
            Label("A parent can help", systemImage: "lock.shield")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            Text("Your saved investigation is kept safe. A parent can review and reset it when ready.")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("tv-shape-storage-notice")
            actionButton("All games", id: "paused-exit", symbol: "chevron.backward") {
                if let onExit { onExit() } else { dismiss() }
            }
        }
        .foregroundStyle(.white)
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30))
        .padding(.top, 35)
    }

    private var finale: some View {
        VStack(alignment: .leading, spacing: 26) {
            Label("Seven mysteries checked", systemImage: "checkmark.seal.fill")
                .font(.system(size: 45, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.82, green: 0.94, blue: 0.73))
            Text("Turning or resizing a shape keeps its sides and corners.")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
            Text("\(session.unaidedCount) correct without app hints or retry · \(session.supportedCount) correct with app support")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .accessibilityIdentifier("tv-shape-summary")
            Text(session.checkpoint.familyMode ? "Family exploration. Adult help was not recorded." : "Adult help was not recorded.")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.77))
            if session.checkpoint.roomPromptShown {
                Text("Optional: look around together. Find the flat face of a book or box. Which sides and corners make it look like a rectangle? You can skip this.")
                    .font(.system(size: 29, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("tv-shape-room-prompt")
            }
            HStack(spacing: 24) {
                actionButton("All done", id: "done", symbol: "checkmark") {
                    if let onExit { onExit() } else { dismiss() }
                }
                actionButton("Room shape", id: "room", symbol: "house") {
                    session.showRoomPrompt()
                    announce("Optional room shape. Find the flat face of a book or box together. Talk about its sides and corners. You can skip this and select All done.")
                }
                actionButton("Investigate again", id: "replay", symbol: "arrow.clockwise") {
                    session.replay(); announce(session.prompt); restoreFocus()
                }
            }
        }
        .foregroundStyle(.white)
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30))
        .padding(.top, 35)
    }

    private func actionButton(_ title: String, id: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.horizontal, 25)
                .frame(minHeight: 84)
        }
        .buttonStyle(ShapeDetectiveButtonStyle(reduceMotion: motionReduced))
        .focused($focusedAction, equals: id)
        .prefersDefaultFocus(id == (session.storageIssue != nil ? "paused-exit" : session.isComplete ? "done" : "next"), in: focusScope)
        .accessibilityIdentifier("tv-shape-\(id)")
    }

    private func figureColor(_ kind: ShapeDetectiveKind) -> Color {
        switch kind {
        case .circle: Color(red: 0.18, green: 0.72, blue: 0.82)
        case .triangle: Color(red: 0.96, green: 0.48, blue: 0.15)
        case .square: Color(red: 0.65, green: 0.39, blue: 0.85)
        case .rectangle: Color(red: 0.32, green: 0.70, blue: 0.28)
        case .nonSquareRhombus: Color(red: 0.91, green: 0.36, blue: 0.54)
        }
    }

    private func focusDescription(_ action: String?) -> String? {
        guard let action else { return nil }
        if let choice = session.current?.choices.first(where: { $0.id == action }) { return choice.spokenDescription }
        switch action {
        case "hint": return "Hint. Hear a clue about the sides and corners."
        case "next": return session.current?.isProbe == true ? "Finish investigation." : "Next clue."
        case "paused-exit": return "All games. Return while your saved investigation stays safe."
        case "done": return "All done. Return to all games."
        case "room": return "Optional room shape. Look around and talk about an object together."
        case "replay": return "Investigate again. Begin a new investigation."
        default: return nil
        }
    }

    private func move(_ direction: MoveCommandDirection) {
        // Horizontal navigation belongs to the native focus engine. Only bridge
        // the distant lower action row, which directional geometry can miss.
        guard !session.isComplete, !session.checkpoint.solved, let item = session.current else { return }
        if direction == .down { focusedAction = "hint" }
        if direction == .up, focusedAction == "hint" { focusedAction = item.choices.first?.id }
    }

    private func announce(_ text: String) {
        narration.presentPrompt(text)
        if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: text) }
    }

    private func restoreFocus() {
        focusTask?.cancel()
        focusedAction = nil
        focusTask = Task { @MainActor in
            do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
            guard !Task.isCancelled, scenePhase == .active else { return }
            focusedAction = session.storageIssue != nil ? "paused-exit" : session.isComplete ? "done" : session.checkpoint.solved ? "next" : session.current?.choices.first?.id
            resetFocus(in: focusScope)
        }
    }

    private func stopTransientWork() {
        focusTask?.cancel(); focusTask = nil; focusedAction = nil; narration.stop()
    }
}

private struct ShapeDetectiveButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isFocused ? Color(red: 0.06, green: 0.10, blue: 0.16) : .white)
            .background(isFocused ? Color.white : Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(isFocused ? Color.orange : .white.opacity(0.18), lineWidth: isFocused ? 5 : 2))
            .scaleEffect(isFocused && !reduceMotion ? 1.025 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isFocused)
    }
}

private struct ShapeDetectiveArtwork: View {
    let figure: ShapeDetectiveFigure
    let traceCorners: Bool
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height) * 0.76 * figure.scale
            ZStack {
                ShapeDetectiveOutline(figure: figure).fill()
                if traceCorners {
                    ShapeDetectiveOutline(figure: figure).stroke(Color.white, lineWidth: 4)
                    ForEach(Array(ShapeDetectiveOutline.vertices(for: figure).enumerated()), id: \.offset) { _, point in
                        Circle().fill(Color.white).frame(width: 12, height: 12)
                            .position(x: point.x * side, y: point.y * side)
                    }
                }
            }
            .frame(width: side, height: side)
            .rotationEffect(.degrees(figure.rotation))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ShapeDetectiveOutline: Shape {
    let figure: ShapeDetectiveFigure
    static func vertices(for figure: ShapeDetectiveFigure) -> [CGPoint] {
        figure.vertices.map { CGPoint(x: $0.x, y: $0.y) }
    }
    func path(in rect: CGRect) -> Path {
        if figure.kind == .circle { return Path(ellipseIn: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08)) }
        let points = Self.vertices(for: figure)
        var path = Path()
        for (index, point) in points.enumerated() {
            let position = CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height)
            if index == 0 { path.move(to: position) } else { path.addLine(to: position) }
        }
        path.closeSubpath()
        return path
    }
}

#Preview { ShapeDetectiveTVView() }
