import SwiftUI

struct CompareCampTVView: View {
    @FocusState private var focusedAnswer: CompareAnswer?
    @FocusState private var nextFocused: Bool

    @State private var roundIndex = 0
    @State private var selectedAnswer: CompareAnswer?
    @State private var streak = 0

    private var round: CompareRound { CompareRound.rounds[roundIndex % CompareRound.rounds.count] }
    private var isCorrect: Bool { selectedAnswer == round.answer }

    var body: some View {
        ZStack {
            MatherTVBackdrop()

            VStack(alignment: .leading, spacing: 30) {
                header

                HStack(alignment: .top, spacing: 36) {
                    groupsPanel
                    answerPanel
                }
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.vertical, 66)
        }
        .onAppear { focusedAnswer = .left }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Compare Camp")
                    .font(.system(size: 68, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-compare-title")

                Text("Which campsite has more? Count, compare, choose.")
                    .font(.system(size: 29, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.76))
            }

            Spacer()

            Label("\(streak) streak", systemImage: "flame.fill")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.98, green: 0.78, blue: 0.36))
                .padding(.horizontal, 24)
                .padding(.vertical, 15)
                .background(.white.opacity(0.08), in: Capsule())
        }
    }

    private var groupsPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Count the lanterns")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.55, green: 0.88, blue: 1.0))

            HStack(spacing: 24) {
                tokenCamp(label: "Left", count: round.left, color: Color(red: 0.98, green: 0.68, blue: 0.32))
                tokenCamp(label: "Right", count: round.right, color: Color(red: 0.39, green: 0.84, blue: 0.88))
            }

            Text(selectedAnswer == nil ? "Take your time. You can count each light." : "\(round.left) compared with \(round.right)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.60))
        }
        .padding(34)
        .frame(width: 790, height: 610, alignment: .topLeading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.14), lineWidth: 2))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Left campsite has \(round.left) lanterns. Right campsite has \(round.right) lanterns.")
    }

    private func tokenCamp(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 20) {
            Text(label)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(58), spacing: 14), count: 3), spacing: 14) {
                ForEach(0..<count, id: \.self) { _ in
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(color)
                        .frame(width: 58, height: 58)
                }
            }
            .frame(width: 210, height: 300, alignment: .top)

            if selectedAnswer != nil {
                Text("\(count)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .padding(26)
        .frame(width: 345, height: 470, alignment: .top)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 26))
    }

    private var answerPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose your answer")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            ForEach(CompareAnswer.allCases) { answer in
                Button {
                    choose(answer)
                } label: {
                    HStack(spacing: 18) {
                        Image(systemName: answer.symbol)
                            .font(.system(size: 34, weight: .black))
                        Text(answer.title)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .frame(width: 650, height: 118)
                }
                .buttonStyle(.plain)
                .focused($focusedAnswer, equals: answer)
                .disabled(selectedAnswer != nil)
                .foregroundStyle(answerForeground(answer))
                .background(answerBackground(answer), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(answerStroke(answer), lineWidth: 3))
                .scaleEffect(focusedAnswer == answer ? 1.035 : 1)
                .accessibilityLabel(answer.accessibilityLabel)
            }

            feedback
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if selectedAnswer != nil {
            HStack(spacing: 18) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(isCorrect ? Color(red: 0.78, green: 0.94, blue: 0.66) : Color(red: 1.0, green: 0.72, blue: 0.38))

                Text(isCorrect ? "You found the bigger camp!" : "Nice counting—let’s compare them.")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button("Next") { nextRound() }
                    .buttonStyle(.plain)
                    .focused($nextFocused)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(nextFocused ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 16)
                    .background(nextFocused ? .white : .white.opacity(0.12), in: Capsule())
            }
            .padding(20)
            .frame(width: 650)
            .frame(minHeight: 92)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
        } else {
            Text("No timer. Press select when you’re ready.")
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .frame(height: 92)
        }
    }

    private func choose(_ answer: CompareAnswer) {
        selectedAnswer = answer
        streak = answer == round.answer ? streak + 1 : 0
        nextFocused = true
    }

    private func nextRound() {
        roundIndex += 1
        selectedAnswer = nil
        nextFocused = false
        focusedAnswer = .left
    }

    private func answerForeground(_ answer: CompareAnswer) -> Color {
        if selectedAnswer == answer && answer == round.answer { return Color(red: 0.12, green: 0.32, blue: 0.16) }
        if focusedAnswer == answer { return Color(red: 0.07, green: 0.10, blue: 0.16) }
        return .white
    }

    private func answerBackground(_ answer: CompareAnswer) -> Color {
        if selectedAnswer == answer && answer == round.answer { return Color(red: 0.78, green: 0.94, blue: 0.66) }
        if selectedAnswer == answer { return Color(red: 1.0, green: 0.72, blue: 0.38).opacity(0.75) }
        return focusedAnswer == answer ? .white : .white.opacity(0.08)
    }

    private func answerStroke(_ answer: CompareAnswer) -> Color {
        focusedAnswer == answer ? .white : .white.opacity(0.14)
    }
}

private enum CompareAnswer: String, CaseIterable, Identifiable {
    case left
    case same
    case right

    var id: String { rawValue }
    var title: String { self == .left ? "Left has more" : self == .right ? "Right has more" : "They are the same" }
    var symbol: String { self == .left ? "arrow.left.circle.fill" : self == .right ? "arrow.right.circle.fill" : "equal.circle.fill" }
    var accessibilityLabel: String { title }
}

private struct CompareRound {
    let left: Int
    let right: Int
    let answer: CompareAnswer

    static let rounds: [CompareRound] = [
        .init(left: 4, right: 7, answer: .right),
        .init(left: 8, right: 5, answer: .left),
        .init(left: 6, right: 6, answer: .same),
        .init(left: 3, right: 5, answer: .right),
        .init(left: 9, right: 7, answer: .left),
        .init(left: 4, right: 4, answer: .same)
    ]
}

#Preview { CompareCampTVView() }
