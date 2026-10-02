import SwiftUI

@MainActor
struct SumSprintPartyTVView: View {
    private static var didResetUITestProgress = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedControl: String?
    @State private var session: SumSprintPartyTVSession
    @State private var narration = TVNarrationController()
    private let onExit: (() -> Void)?

    init(profileID: String = "tv-family", familyMode: Bool = true,
         onAttempt: @escaping (ItemAttempt) -> Void = { _ in },
         onResult: @escaping (ActivityResult) -> Void = { _ in },
         onExit: (() -> Void)? = nil) {
        self.onExit = onExit
        let arguments = ProcessInfo.processInfo.arguments
        var store: SumSprintPartyTVSessionStore?
        if arguments.contains("-sum-sprint-ui-test"), let defaults = UserDefaults(suiteName: "mather.sumSprint.ui.tests") {
            if arguments.contains("-sum-sprint-reset-progress"), !Self.didResetUITestProgress {
                defaults.removePersistentDomain(forName: "mather.sumSprint.ui.tests")
                Self.didResetUITestProgress = true
            }
            store = SumSprintPartyTVSessionStore(defaults: defaults, profileID: familyMode ? "tv-family" : profileID, familyMode: familyMode)
        }
        _session = State(initialValue: SumSprintPartyTVSession(profileID: profileID, familyMode: familyMode,
            store: store, onAttempt: onAttempt, onResult: onResult))
    }

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            VStack(alignment: .leading, spacing: 28) {
                header
                if !session.isSessionOpen {
                    rangeChooser
                } else if session.checkpoint?.isComplete == true {
                    finish
                } else if let item = session.currentItem, let progress = session.currentProgress {
                    learningStage(item: item, progress: progress)
                }
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.top, 86)
            .padding(.bottom, 50)
        }
        .onAppear {
            session.replayEvidence()
            presentPrompt()
            restoreFocus()
        }
        .onDisappear { narration.stop() }
        .onPlayPauseCommand { narration.repeatPrompt() }
        .onChange(of: focusedControl) { _, _ in narration.focus(focusedNarration) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { restoreFocus() } else { narration.stop() }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sum Sprint Party")
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .accessibilityIdentifier("tv-sum-sprint-title")
                Text("Join number parts. Take your time.")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .accessibilityIdentifier("tv-sum-sprint-no-timer-copy")
            }
            Spacer(minLength: 20)
            if session.isSessionOpen, let checkpoint = session.checkpoint {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(checkpoint.isComplete ? "Session complete" : "\(checkpoint.currentIndex + 1) of 6")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .accessibilityIdentifier("tv-sum-sprint-progress")
                    Text(checkpoint.range.title)
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .foregroundStyle(.white)
    }

    private var rangeChooser: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Choose with a grown-up")
                .font(.system(size: 38, weight: .bold, design: .rounded))
            Text("Five practice ideas, then one new puzzle. No countdown.")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
            if session.canResume, let checkpoint = session.checkpoint {
                actionButton("Resume \(checkpoint.range.title)", symbol: "play.fill", id: "resume") {
                    session.resume(); presentPrompt(); restoreFocus()
                }
                .accessibilityIdentifier("tv-sum-sprint-resume")
            }
            HStack(spacing: 30) {
                ForEach(SumSprintPartyTVRange.allCases) { range in
                    actionButton(range.title, symbol: "circle.grid.2x2.fill", id: "range-\(range.rawValue)", width: 400) {
                        if ProcessInfo.processInfo.arguments.contains("-sum-sprint-ui-test") {
                            session.start(range: range, seed: 17)
                        } else {
                            session.start(range: range)
                        }
                        presentPrompt(); restoreFocus()
                    }
                    .accessibilityLabel("Start a new session with totals through \(range.rawValue)")
                    .accessibilityIdentifier("tv-sum-sprint-range-\(range.rawValue)")
                }
            }
            Text(session.canResume ? "Resume keeps the same puzzle and any counting help. Starting a new session keeps your earlier session in history." : "Explore two groups, rows of five, and a number-parts picture.")
                .font(.system(size: 25, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .frame(maxWidth: 1350, alignment: .leading)
            let earlierBest = UserDefaults.standard.integer(forKey: "tv.sumSprintParty.personalBest")
            if earlierBest > 0 {
                Text("Earlier personal best: \(earlierBest)")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .foregroundStyle(.white)
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 30))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tv-sum-sprint-range-chooser")
    }

    private func learningStage(item: SumSprintPartyTVItem, progress: SumSprintPartyTVItemProgress) -> some View {
        HStack(alignment: .top, spacing: 40) {
            factPanel(item: item, progress: progress)
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose the whole")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                LazyVGrid(columns: [GridItem(.fixed(390), spacing: 22), GridItem(.fixed(390), spacing: 22)], spacing: 22) {
                    ForEach(item.round.answerChoices, id: \.self) { answer in
                        Button {
                            session.choose(answer)
                            narration.presentPrompt(session.prompt)
                            if session.currentProgress?.outcome != nil { focusedControl = "next" }
                        } label: {
                            answerTile(answer, item: item, progress: progress)
                        }
                        .buttonStyle(.plain)
                        .focused($focusedControl, equals: "answer-\(answer)")
                        .disabled(progress.outcome != nil)
                        .accessibilityLabel("\(answer)")
                        .accessibilityHint("Select this total. You can try again.")
                        .accessibilityIdentifier("tv-sum-sprint-answer-\(answer)")
                    }
                }
                feedback(item: item, progress: progress)
                if progress.outcome == nil {
                    HStack(spacing: 22) {
                        actionButton("Guide me", symbol: "hand.point.up.left.fill", id: "help", width: 330) {
                            session.requestHelp(); presentPrompt()
                        }
                        .accessibilityIdentifier("tv-sum-sprint-help")
                        if progress.support == .countOn {
                            actionButton("Count one", symbol: "plus.circle.fill", id: "count", width: 330) {
                                session.countNext()
                                let counted = session.currentProgress?.counted ?? 0
                                narration.presentPrompt("\(item.round.fact.addendA + counted). \(counted == item.round.fact.addendB ? "All counters are counted. Choose the whole." : "Select Count one to keep counting, or choose the whole.")")
                                if counted == item.round.fact.addendB { focusedControl = "answer-\(item.round.answerChoices[0])" }
                            }
                            .disabled(progress.counted == item.round.fact.addendB)
                            .accessibilityIdentifier("tv-sum-sprint-count")
                        }
                    }
                }
            }
            .frame(width: 802, alignment: .leading)
        }
    }

    private func factPanel(item: SumSprintPartyTVItem, progress: SumSprintPartyTVItemProgress) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(item.isProbe ? (item.isFreshProbe ? "New puzzle" : "Number-parts puzzle") : "Two parts")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.55, green: 0.88, blue: 1))
                .accessibilityIdentifier("tv-sum-sprint-stage")
            Text(item.round.fact.promptText)
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("tv-sum-sprint-fact")
            if item.representation == .numberParts && progress.support == .none {
                numberParts(item.round.fact)
            } else {
                SumSprintPartyTVPartsPicture(fact: item.round.fact, representation: item.representation,
                    support: progress.support, counted: progress.counted)
            }
            if progress.support == .countOn {
                Text("\(item.round.fact.addendA) → \(item.round.fact.addendA + progress.counted)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-sum-sprint-counted")
            } else {
                Text(item.isProbe ? "Two number parts make one whole." : "Keep both parts. Find the whole.")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(36)
        .frame(width: 600, height: 580, alignment: .topLeading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.15), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.representation.spokenDescription). \(item.round.fact.spokenPrompt) \(session.scaffold)")
        .accessibilityValue("Part \(item.round.fact.addendA) and part \(item.round.fact.addendB). Idea \(item.round.index + 1) of 6.")
        .accessibilityIdentifier("tv-sum-sprint-picture-prompt")
    }

    private func numberParts(_ fact: SumSprintPartyTVFact) -> some View {
        VStack(spacing: 8) {
            Text("?")
                .font(.system(size: 65, weight: .black, design: .rounded))
                .frame(width: 140, height: 105)
                .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 25))
            HStack(spacing: 90) {
                Image(systemName: "arrow.up.right"); Image(systemName: "arrow.up.left")
            }
            .font(.system(size: 35, weight: .bold))
            HStack(spacing: 65) {
                partLabel(fact.addendA, tint: .orange)
                partLabel(fact.addendB, tint: .cyan)
            }
        }
        .foregroundStyle(.white)
        .frame(width: 500, height: 260)
        .accessibilityHidden(true)
    }
    private func partLabel(_ number: Int, tint: Color) -> some View {
        Text("\(number)")
            .font(.system(size: 55, weight: .black, design: .rounded))
            .frame(width: 150, height: 100)
            .background(tint.opacity(0.22), in: RoundedRectangle(cornerRadius: 24))
    }

    private func answerTile(_ answer: Int, item: SumSprintPartyTVItem, progress: SumSprintPartyTVItemProgress) -> some View {
        let focused = focusedControl == "answer-\(answer)"
        let solved = progress.outcome != nil && answer == item.round.correctAnswer
        let tried = progress.outcome == nil && progress.selectedAnswer == answer
        return HStack(spacing: 22) {
            Image(systemName: solved ? "checkmark.circle.fill" : tried ? "arrow.uturn.backward.circle" : "circle")
                .font(.system(size: 34, weight: .bold))
            Text("\(answer)")
                .font(.system(size: 58, weight: .black, design: .rounded))
                .monospacedDigit()
            Spacer(minLength: 0)
        }
        .foregroundStyle(focused ? Color(red: 0.08, green: 0.12, blue: 0.18) : .white)
        .padding(28)
        .frame(width: 390, height: 140)
        .background(focused ? .white : solved ? Color.green.opacity(0.3) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(focused ? .white : .white.opacity(0.18), lineWidth: 3))
        .scaleEffect(focused && !reduceMotion ? 1.035 : 1)
    }

    private func feedback(item: SumSprintPartyTVItem, progress: SumSprintPartyTVItemProgress) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let outcome = progress.outcome {
                Text(outcome == .independentCorrect ? "You joined the parts!" : "Counting helped you join the parts!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("\(item.round.fact.promptText) = \(item.round.correctAnswer)")
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                actionButton(item.isProbe ? "Finish" : "Next", symbol: "arrow.right", id: "next", width: 350) {
                    session.advance(); presentPrompt(); restoreFocus()
                }
                .accessibilityIdentifier("tv-sum-sprint-next-fact")
            } else {
                Text(progress.missCount > 0 ? "Try counting the parts" : progress.support != .none ? "Let's count together" : "No timer. You can count, think, or ask for help.")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                Text(session.scaffold.isEmpty ? "Menu saves your place. Play Pause repeats the question." : session.scaffold)
                    .font(.system(size: 23, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(3)
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(width: 802)
        .frame(minHeight: 150, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 25))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tv-sum-sprint-feedback")
    }

    private var finish: some View {
        VStack(alignment: .leading, spacing: 26) {
            Label("You explored six number ideas", systemImage: "sparkles")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            if let checkpoint = session.checkpoint {
                Text("\(checkpoint.unaidedCount) without app hints · \(checkpoint.helpedCount) with counting help")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .accessibilityIdentifier("tv-sum-sprint-outcomes")
                Text(probeRecap(checkpoint))
                    .font(.system(size: 27, weight: .medium, design: .rounded))
                Text("Family play may include grown-up help. This session shows what you explored.")
                    .font(.system(size: 23, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
            HStack(spacing: 26) {
                actionButton("Choose another session", symbol: "circle.grid.2x2", id: "ranges", width: 700) {
                    session.showRanges(); presentPrompt(); restoreFocus()
                }
                .accessibilityIdentifier("tv-sum-sprint-another-session")
                actionButton("All done", symbol: "checkmark.circle", id: "done", width: 350) {
                    if let onExit { narration.stop(); onExit() }
                    else { session.showRanges(); presentPrompt(); restoreFocus() }
                }
                .accessibilityIdentifier("tv-sum-sprint-all-done")
            }
            Text("Or press Menu to finish playing.")
                .font(.system(size: 25, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(44)
        .frame(maxWidth: .infinity, minHeight: 460, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 32))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tv-sum-sprint-finish")
    }

    private func actionButton(_ title: String, symbol: String, id: String, width: CGFloat = 650, action: @escaping () -> Void) -> some View {
        let focused = focusedControl == id
        return Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .padding(.horizontal, 24)
                .frame(width: width, height: 90, alignment: .leading)
                .foregroundStyle(focused ? Color(red: 0.08, green: 0.12, blue: 0.18) : .white)
                .background(focused ? .white : .white.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(focused ? 1 : 0.22), lineWidth: 3))
        }
        .buttonStyle(.plain)
        .focused($focusedControl, equals: id)
    }
    private var focusedNarration: String? {
        guard let focusedControl else { return nil }
        if focusedControl.hasPrefix("answer-") { return String(focusedControl.dropFirst(7)) }
        switch focusedControl {
        case "help": return "Guide me. Select for counting help."
        case "count": return "Count one more counter."
        case "resume": return "Resume your saved puzzle."
        case "next": return session.currentItem?.isProbe == true ? "Finish this session." : "Next number idea."
        case "ranges": return "Choose another session."
        case "done": return "All done. Finish playing Sum Sprint."
        default: return focusedControl.hasPrefix("range-") ? "Start a new session with totals through \(focusedControl.dropFirst(6))." : nil
        }
    }
    private func presentPrompt() {
        if !session.isSessionOpen {
            narration.presentPrompt("Choose a number range with a grown-up. Five practice ideas and one new puzzle. \(session.canResume ? "Resume keeps your saved puzzle. " : "")Take your time. Play Pause repeats these instructions.")
        } else if session.checkpoint?.isComplete == true {
            narration.presentPrompt("You explored six number ideas. Some you solved without app hints, and counting helped with others. Choose another session, or press Menu to finish playing.")
        } else { narration.presentPrompt(session.prompt) }
    }
    private func restoreFocus() {
        if !session.isSessionOpen { focusedControl = session.canResume ? "resume" : "range-5" }
        else if session.checkpoint?.isComplete == true { focusedControl = "ranges" }
        else if session.currentProgress?.outcome != nil { focusedControl = "next" }
        else if let answer = session.currentItem?.round.answerChoices.first { focusedControl = "answer-\(answer)" }
    }
    private func probeRecap(_ checkpoint: SumSprintPartyTVCheckpoint) -> String {
        if checkpoint.freshProbeUnaided { return "You solved the new number-parts puzzle without app hints." }
        if checkpoint.items.last?.isFreshProbe == false { return "You revisited a number-parts puzzle. Familiar puzzles help us practice." }
        return "You explored a new puzzle with help. Try a new one another day."
    }
}

private struct SumSprintPartyTVPartsPicture: View {
    let fact: SumSprintPartyTVFact
    let representation: SumSprintPartyTVRepresentation
    let support: SumSprintPartyTVSupport
    let counted: Int
    private let first = Color(red: 0.98, green: 0.73, blue: 0.34)
    private let second = Color(red: 0.42, green: 0.82, blue: 0.9)

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            group(count: fact.addendA, tint: first, isCounting: false)
            Text("+").font(.system(size: 42, weight: .bold, design: .rounded)).padding(.top, 60)
            group(count: fact.addendB, tint: second, isCounting: support == .countOn)
        }
        .foregroundStyle(.white)
        .frame(width: 500, height: 265)
        .accessibilityHidden(true)
    }
    private func group(count: Int, tint: Color, isCounting: Bool) -> some View {
        let structured = representation != .counterTrays || support != .none
        return VStack(spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: structured || count > 16 ? 5 : 4), spacing: 9) {
                ForEach(0..<(structured ? ((count + 4) / 5) * 5 : count), id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(structured ? 0.25 : 0), lineWidth: 1)
                        if index < count {
                            Circle().fill(tint)
                                .frame(width: 23, height: 23)
                                .opacity(isCounting && index >= counted ? 0.38 : 1)
                            if isCounting && index < counted {
                                Image(systemName: "checkmark").font(.system(size: 13, weight: .black)).foregroundStyle(.black)
                            }
                        }
                    }
                    .frame(width: 28, height: 28)
                }
            }
            .frame(width: 174, height: 150, alignment: .topLeading)
            .padding(14)
            .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 22))
            Text("\(count)").font(.system(size: 38, weight: .bold, design: .rounded))
        }
    }
}

#Preview { SumSprintPartyTVView() }
