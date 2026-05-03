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

struct ConceptMixMatchRoundView: View {
    let pairs: [ConceptMatchPair]
    @Binding var selectedLeft: String?
    @Binding var matchedPairIds: Set<String>
    let onFeedback: (String) -> Void

    private var leftItems: [String] { Array(Set(pairs.map(\.left))).sorted() }
    private var rightItems: [String] { Array(Set(pairs.map(\.right))).sorted() }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mix + Match")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            HStack(alignment: .top, spacing: 14) {
                matchColumn(title: "Start", items: leftItems, isLeft: true)
                matchColumn(title: "Goes with", items: rightItems, isLeft: false)
            }
        }
    }

    private func matchColumn(title: String, items: [String], isLeft: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(MatherTheme.cardSubtitle)
            ForEach(items, id: \.self) { item in
                Button {
                    handleTap(item, isLeft: isLeft)
                } label: {
                    Text(item)
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(tileFill(item: item, isLeft: isLeft))
                        .foregroundStyle(MatherTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func handleTap(_ item: String, isLeft: Bool) {
        if isLeft {
            selectedLeft = item
            onFeedback("Now pick what goes with \(item).")
            return
        }
        guard let left = selectedLeft else {
            onFeedback("Pick a start card first.")
            return
        }
        if let pair = pairs.first(where: { $0.left == left && $0.right == item }) {
            matchedPairIds.insert(pair.id)
            selectedLeft = nil
            onFeedback(pair.feedback)
        } else {
            onFeedback("Not that pair yet — try another match.")
        }
    }

    private func tileFill(item: String, isLeft: Bool) -> Color {
        let isMatched = pairs.contains { pair in
            matchedPairIds.contains(pair.id) && (isLeft ? pair.left == item : pair.right == item)
        }
        if isMatched { return .green.opacity(0.28) }
        if isLeft, selectedLeft == item { return MatherTheme.warm.opacity(0.6) }
        return MatherTheme.card
    }
}
