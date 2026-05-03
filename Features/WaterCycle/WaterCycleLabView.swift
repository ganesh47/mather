import SwiftUI

struct WaterCycleLabView: View {
    @Bindable var appModel: AppModel
    @State private var answersByQuestionId: [String: String] = [:]
    @State private var selectedLeft: String?
    @State private var matchedPairIds: Set<String> = []
    @State private var feedback = "Learn the water cycle, then try the quiz and matches."

    private var summary: LearningLoopSummary {
        LearningLoopScoring.summary(
            questions: WaterCycleContent.quizQuestions,
            answersByQuestionId: answersByQuestionId,
            matchedPairIds: matchedPairIds,
            pairs: WaterCycleContent.matchPairs
        )
    }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    LearningCardIntroView(cards: WaterCycleContent.cards)
                    ConceptQuizRoundView(
                        questions: WaterCycleContent.quizQuestions,
                        answersByQuestionId: $answersByQuestionId
                    )
                    ConceptMixMatchRoundView(
                        pairs: WaterCycleContent.matchPairs,
                        selectedLeft: $selectedLeft,
                        matchedPairIds: $matchedPairIds,
                        onFeedback: { feedback = $0 }
                    )
                    summaryCard
                }
                .padding(24)
            }
        }
        .accessibilityIdentifier("water-cycle-lab")
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Water Cycle Lab")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Sun → vapour → cloud → rain → pond")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text(feedback)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
            }
            Spacer()
            Button {
                appModel.engine.showLab()
            } label: {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(MatherTheme.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Explorer Lab")
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(repeating: "⭐️", count: summary.starCount).isEmpty ? "Keep exploring" : String(repeating: "⭐️", count: summary.starCount))
                .font(.title.weight(.black))
            Text("Quiz: \(summary.quizCorrect)/\(summary.quizTotal) • Matches: \(summary.matchedPairs)/\(summary.totalPairs)")
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Text("Water keeps moving: the sun warms it, vapour rises, clouds form, rain falls, and ponds fill again.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatherTheme.warm.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier("water-cycle-summary")
    }
}
