import SwiftUI

struct SumSprintPartyTVView: View {
    @FocusState private var focusedAnswer: Int?
    @FocusState private var nextButtonFocused: Bool

    @AppStorage("tv.sumSprintParty.personalBest") private var personalBest = 0

    @State private var roundIndex = 0
    @State private var selectedAnswer: Int?
    @State private var streak = 0

    private var round: SumSprintPartyTVRound {
        SumSprintPartyTVRound.make(index: roundIndex)
    }

    private var answeredCorrectly: Bool {
        SumSprintPartyTVRound.isCorrect(selection: selectedAnswer, for: round)
    }

    var body: some View {
        ZStack {
            MatherTVBackdrop()

            VStack(alignment: .leading, spacing: 36) {
                header
                stage
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.vertical, 66)
        }
        .onAppear {
            focusedAnswer = round.answerChoices.first
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sum Sprint Party")
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-sum-sprint-title")

                Text("Four answers, no countdown. Build a calm streak together.")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .accessibilityIdentifier("tv-sum-sprint-no-timer-copy")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sum Sprint Party. Four answers. No countdown.")

            Spacer(minLength: 24)

            HStack(spacing: 18) {
                metricPill(title: "Streak", value: "\(streak)", color: Color(red: 0.78, green: 0.94, blue: 0.66))
                metricPill(title: "Best", value: "\(personalBest)", color: Color(red: 1.0, green: 0.82, blue: 0.44))
            }
        }
    }

    private var stage: some View {
        HStack(alignment: .top, spacing: 42) {
            factPanel

            VStack(alignment: .leading, spacing: 22) {
                Text("Choose the total")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                answerGrid

                feedbackBar
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var factPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Fact")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.55, green: 0.88, blue: 1.0))

            Text(round.fact.promptText)
                .font(.system(size: 82, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("tv-sum-sprint-fact")

            SumSprintPartyTokensView(fact: round.fact)
                .frame(width: 500, height: 294)
                .accessibilityHidden(true)

            Text("Look at the two groups, then pick the total.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(2)
        }
        .padding(36)
        .frame(width: 600, height: 590, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(round.fact.spokenPrompt) Picture support shows \(round.fact.addendA) counters plus \(round.fact.addendB) counters.")
        .accessibilityHint("Move right to choose the total.")
        .accessibilityIdentifier("tv-sum-sprint-picture-prompt")
    }

    private var answerGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(390), spacing: 22),
                GridItem(.fixed(390), spacing: 22)
            ],
            spacing: 22
        ) {
            ForEach(round.answerChoices, id: \.self) { answer in
                Button {
                    choose(answer)
                } label: {
                    SumSprintPartyAnswerTile(
                        answer: answer,
                        isFocused: focusedAnswer == answer,
                        state: answerState(for: answer)
                    )
                }
                .buttonStyle(.plain)
                .focused($focusedAnswer, equals: answer)
                .disabled(selectedAnswer != nil)
                .accessibilityLabel("\(answer)")
                .accessibilityHint("Select \(answer) as the total.")
                .accessibilityIdentifier("tv-sum-sprint-answer-\(answer)")
            }
        }
    }

    @ViewBuilder
    private var feedbackBar: some View {
        if let selectedAnswer {
            HStack(spacing: 20) {
                Image(systemName: answeredCorrectly ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(answeredCorrectly ? Color(red: 0.78, green: 0.94, blue: 0.66) : Color(red: 1.0, green: 0.78, blue: 0.42))

                VStack(alignment: .leading, spacing: 4) {
                    Text(answeredCorrectly ? "Nice total!" : "Good try")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(answeredCorrectly ? "\(round.fact.promptText) = \(round.correctAnswer). Keep the streak going." : "\(selectedAnswer) is not it yet. \(round.fact.promptText) = \(round.correctAnswer).")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer(minLength: 18)

                Button {
                    nextRound()
                } label: {
                    Label("Next fact", systemImage: "forward.fill")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.plain)
                .focused($nextButtonFocused)
                .background(nextButtonFocused ? .white : Color(red: 0.55, green: 0.88, blue: 1.0).opacity(0.20), in: Capsule())
                .foregroundStyle(nextButtonFocused ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                .accessibilityIdentifier("tv-sum-sprint-next-fact")
            }
            .padding(24)
            .frame(width: 802)
            .frame(minHeight: 120)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(feedbackAccessibilityLabel(selectedAnswer: selectedAnswer))
        } else {
            Text("No timer. The only counters here are your streak and your personal best.")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 802, alignment: .leading)
                .frame(minHeight: 120, alignment: .leading)
                .accessibilityIdentifier("tv-sum-sprint-calm-copy")
        }
    }

    private func metricPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(value)
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(minWidth: 150, alignment: .trailing)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    private func choose(_ answer: Int) {
        selectedAnswer = answer
        if answer == round.correctAnswer {
            streak += 1
            personalBest = max(personalBest, streak)
        } else {
            streak = 0
        }
        nextButtonFocused = true
    }

    private func nextRound() {
        let nextIndex = roundIndex + 1
        let nextRound = SumSprintPartyTVRound.make(index: nextIndex)
        roundIndex = nextIndex
        selectedAnswer = nil
        focusedAnswer = nextRound.answerChoices.first
        nextButtonFocused = false
    }

    private func answerState(for answer: Int) -> SumSprintPartyAnswerTile.State {
        guard let selectedAnswer else { return .idle }
        if answer == round.correctAnswer { return .correct }
        if answer == selectedAnswer { return .incorrect }
        return .dimmed
    }

    private func feedbackAccessibilityLabel(selectedAnswer: Int) -> String {
        if selectedAnswer == round.correctAnswer {
            return "Correct. \(round.fact.promptText) equals \(round.correctAnswer). Streak \(streak)."
        }
        return "Not yet. \(round.fact.promptText) equals \(round.correctAnswer). Streak reset to zero."
    }
}

private struct SumSprintPartyTokensView: View {
    let fact: SumSprintPartyTVFact

    var body: some View {
        HStack(spacing: 22) {
            tokenGroup(count: fact.addendA, tint: Color(red: 0.98, green: 0.73, blue: 0.34), label: "\(fact.addendA)")

            Text("+")
                .font(.system(size: 50, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 42)

            tokenGroup(count: fact.addendB, tint: Color(red: 0.42, green: 0.82, blue: 0.90), label: "\(fact.addendB)")
        }
    }

    private func tokenGroup(count: Int, tint: Color, label: String) -> some View {
        VStack(spacing: 16) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: 5),
                spacing: 8
            ) {
                ForEach(0..<count, id: \.self) { index in
                    Circle()
                        .fill(tint)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(.white.opacity(index % 2 == 0 ? 0.45 : 0.18), lineWidth: 2))
                }
            }
            .frame(width: 174, height: 122, alignment: .top)
            .padding(18)
            .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(label)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct SumSprintPartyAnswerTile: View {
    enum State {
        case idle
        case correct
        case incorrect
        case dimmed
    }

    let answer: Int
    let isFocused: Bool
    let state: State

    var body: some View {
        HStack(spacing: 18) {
            statusIcon

            Text("\(answer)")
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundStyle(foregroundColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .frame(width: 390, height: 150, alignment: .leading)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(strokeColor, lineWidth: 3)
        )
        .scaleEffect(isFocused ? 1.055 : 1.0)
        .opacity(state == .dimmed ? 0.45 : 1)
        .shadow(color: .black.opacity(isFocused ? 0.28 : 0.12), radius: isFocused ? 20 : 8, x: 0, y: isFocused ? 14 : 5)
        .animation(.spring(response: 0.26, dampingFraction: 0.78), value: isFocused)
        .animation(.easeInOut(duration: 0.16), value: state)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .correct:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(Color(red: 0.36, green: 0.63, blue: 0.30))
        case .incorrect:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(Color(red: 0.80, green: 0.28, blue: 0.22))
        case .idle, .dimmed:
            Image(systemName: "circle")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(foregroundColor.opacity(0.72))
        }
    }

    private var foregroundColor: Color {
        isFocused ? Color(red: 0.08, green: 0.12, blue: 0.18) : .white
    }

    private var strokeColor: Color {
        switch state {
        case .correct: return Color(red: 0.78, green: 0.94, blue: 0.66)
        case .incorrect: return Color(red: 1.0, green: 0.60, blue: 0.50)
        case .idle, .dimmed:
            return isFocused ? .white : .white.opacity(0.12)
        }
    }

    private var backgroundStyle: some ShapeStyle {
        if isFocused {
            return AnyShapeStyle(.white)
        }
        switch state {
        case .correct:
            return AnyShapeStyle(Color(red: 0.20, green: 0.50, blue: 0.32).opacity(0.82))
        case .incorrect:
            return AnyShapeStyle(Color(red: 0.52, green: 0.17, blue: 0.17).opacity(0.78))
        case .idle, .dimmed:
            return AnyShapeStyle(.white.opacity(0.08))
        }
    }
}

#Preview {
    SumSprintPartyTVView()
}
