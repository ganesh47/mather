import SwiftUI

struct LabRememberStageView: View {
    @Bindable var appModel: AppModel
    let deckID: LabRememberStageDeckID

    @State private var execution: LabRememberStageExecution
    @State private var feedback: String = "Choose the match when you remember it."

    init(appModel: AppModel, deckID: LabRememberStageDeckID) {
        self.appModel = appModel
        self.deckID = deckID
        _execution = State(initialValue: LabRememberStageExecution(deck: LabRememberStageDeck.deck(for: deckID)))
    }

    var body: some View {
        let deck = execution.deck
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button {
                        appModel.engine.showLabLane(deck.laneID)
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.accent)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(execution.progressLabel)
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("🧠 Remember")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.accent)
                    Text(deck.title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                    Text(deck.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                    Label(deck.timerPolicy.childCopy, systemImage: "timer")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.accent)
                }

                if let card = execution.currentCard {
                    rememberCard(card)
                }

                Text(feedback)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                Button {
                    finishRemember(deck)
                } label: {
                    Label(execution.isComplete ? "Finish Remember" : "Save and continue later", systemImage: "checkmark.circle.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(MatherTheme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .accessibilityLabel("Remember stage. No countdown. \(deck.title).")
    }

    private func rememberCard(_ card: LabRememberStageCard) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(card.prompt)
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(card.supportCopy)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(answerChoices(for: card), id: \.self) { choice in
                    Button {
                        answer(choice)
                    } label: {
                        Text(choice)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(MatherTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Answer \(choice)")
                }
            }
        }
        .padding(16)
        .background(MatherTheme.card.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(card.accessibilityLabel)
    }

    private func answer(_ choice: String) {
        let correct = execution.submit(answer: choice)
        feedback = correct ? "Yes — keep that idea for the Play stage." : "Try again calmly. Look back at the clue and choose the best match."
        if correct {
            execution.advance()
        }
    }

    private func answerChoices(for card: LabRememberStageCard) -> [String] {
        let siblingAnswers = execution.deck.cards
            .filter { $0.id != card.id }
            .map(\.answer)
        return Array(Set([card.answer] + Array(siblingAnswers.prefix(3)))).sorted()
    }

    private func finishRemember(_ deck: LabRememberStageDeck) {
        guard let plan = LabConceptSessionPlan.plan(for: deck.planID) else {
            appModel.engine.showLabLane(deck.laneID)
            return
        }
        if execution.isComplete {
            _ = appModel.labConceptSessionProgressStore.markCompleted(deck.stage, in: plan)
        } else {
            _ = appModel.labConceptSessionProgressStore.beginGuidedStage(deck.stage, in: plan)
        }
        appModel.engine.showLabLane(deck.laneID)
    }
}
