import SwiftUI

struct ShapeGeometryLabView: View {
    @Bindable var appModel: AppModel

    @State private var selectedLevelIndex = 0
    @State private var answersByQuestionId: [String: String] = [:]
    @State private var selectedLeft: String?
    @State private var matchedPairIds: Set<String> = []
    @State private var feedback = "Pick a level, learn the shape cards, then match each picture to its name."

    private var level: ShapeGeometryLevel {
        ShapeGeometryContent.levels[selectedLevelIndex]
    }

    private var levelCards: [LearningConceptCard] {
        level.cards(from: ShapeGeometryContent.cards)
    }

    private var levelQuestions: [ConceptQuizQuestion] {
        level.quizQuestions(from: ShapeGeometryContent.quizQuestions)
    }

    private var levelPairs: [ConceptMatchPair] {
        level.matchPairs(from: ShapeGeometryContent.matchPairs)
    }

    private var quizCorrect: Int {
        LearningLoopScoring.scoreQuiz(questions: levelQuestions, answersByQuestionId: answersByQuestionId)
    }

    private var summary: LearningLoopSummary {
        LearningLoopScoring.summary(
            questions: levelQuestions,
            answersByQuestionId: answersByQuestionId,
            matchedPairIds: matchedPairIds,
            pairs: levelPairs
        )
    }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    levelPicker
                    LearningCardIntroView(cards: levelCards)
                    ConceptQuizRoundView(questions: levelQuestions, answersByQuestionId: $answersByQuestionId)
                    ConceptMixMatchRoundView(
                        pairs: levelPairs,
                        selectedLeft: $selectedLeft,
                        matchedPairIds: $matchedPairIds,
                        onFeedback: { feedback = $0 }
                    )
                    summaryCard
                }
                .padding(24)
            }
        }
        .navigationTitle("Shape Cards")
        .onChange(of: selectedLevelIndex) { _, _ in
            resetLevelState()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    appModel.engine.showLabLane(.geometry)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.black))
                        .foregroundStyle(MatherTheme.coral)
                        .frame(width: 64, height: 64)
                        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to Geometry Lab")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Shape Cards")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                    Text("Learn common shapes, answer quick questions, then lock picture/name pairs.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
            }

            Text(feedback)
                .font(.headline.weight(.bold))
                .foregroundStyle(MatherTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(MatherTheme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shape Cards. Geometry learning loop. \(feedback)")
    }

    private var levelPicker: some View {
        HStack(spacing: 10) {
            ForEach(Array(ShapeGeometryContent.levels.enumerated()), id: \.element.id) { index, candidate in
                Button {
                    selectedLevelIndex = index
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.title)
                            .font(.headline.weight(.black))
                        Text(candidate.subtitle)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                    }
                    .foregroundStyle(MatherTheme.ink)
                    .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
                    .padding(12)
                    .background(index == selectedLevelIndex ? MatherTheme.coral.opacity(0.22) : MatherTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(index == selectedLevelIndex ? MatherTheme.coral : Color.secondary.opacity(0.12), lineWidth: index == selectedLevelIndex ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select \(candidate.title). \(candidate.subtitle)")
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Level progress")
                .font(.title3.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Text("Quiz \(quizCorrect)/\(levelQuestions.count) • Matches \(matchedPairIds.count)/\(levelPairs.count) • Stars \(summary.starCount)")
                .font(.headline.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
            if matchedPairIds.count == levelPairs.count {
                Button {
                    if selectedLevelIndex < ShapeGeometryContent.levels.count - 1 {
                        selectedLevelIndex += 1
                    } else {
                        resetLevelState()
                    }
                } label: {
                    Label(selectedLevelIndex < ShapeGeometryContent.levels.count - 1 ? "Try Level 2" : "Practice again", systemImage: "arrow.right.circle.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(MatherTheme.coral, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func resetLevelState() {
        answersByQuestionId = [:]
        selectedLeft = nil
        matchedPairIds = []
        feedback = "Level \(selectedLevelIndex + 1) ready: learn, quiz, then match the shape pictures to names."
    }
}
