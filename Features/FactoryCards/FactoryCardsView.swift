import SwiftUI

struct FactoryCardsView: View {
    @Bindable var appModel: AppModel

    @State private var difficulty: ArrayPreludeDifficulty = .easy
    @State private var round = ArrayPreludeRound.make(difficulty: .easy)
    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var attemptedStepIds: Set<String> = []
    @State private var selectedTotal: Int?
    @State private var faceUp = true
    @State private var sessionStart: Date = .now
    @State private var savedSession = false
    @State private var didCompleteFirstLook = false

    private var currentStep: ArrayPreludeRound.Step? {
        guard round.steps.indices.contains(currentIndex) else { return nil }
        return round.steps[currentIndex]
    }

    private var roundComplete: Bool {
        currentIndex >= round.steps.count
    }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                header
                difficultyPicker

                if let step = currentStep {
                    cardSurface(for: step)
                    if didCompleteFirstLook {
                        totalChoices(for: step)
                    } else {
                        firstLookStep(for: step)
                    }
                } else {
                    completionView
                }

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .onAppear {
            sessionStart = .now
            resetRound(speak: true)
        }
        .onDisappear {
            saveIfNeeded()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Packing Cards")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("Build equal rows before the factory challenge")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                appModel.engine.showLab()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Done")
        }
    }

    private var difficultyPicker: some View {
        HStack(spacing: 8) {
            ForEach(ArrayPreludeDifficulty.allCases, id: \.rawValue) { option in
                Button {
                    difficulty = option
                    resetRound(speak: true)
                } label: {
                    Text(option.menuLabel)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(option == difficulty ? .white : MatherTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .padding(.horizontal, 8)
                        .background(option == difficulty ? MatherTheme.accent : MatherTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityLabel("\(option.menuLabel) packing cards")
            }
        }
    }

    private func cardSurface(for step: ArrayPreludeRound.Step) -> some View {
        VStack(spacing: 14) {
            HStack {
                Label("Factory order \(currentIndex + 1) of \(round.steps.count)", systemImage: "shippingbox.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.coral)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MatherTheme.coral.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                Text("\(correctCount) packed")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(MatherTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(MatherTheme.panelDeep.opacity(0.22), lineWidth: 1)
                    )

                if faceUp {
                    VStack(spacing: 14) {
                        PackingArrayView(fact: step.fact)
                            .frame(maxWidth: 320, minHeight: 180, maxHeight: 240)
                            .padding(.top, 18)

                        Text(step.fact.rowColumnPhrase)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(MatherTheme.ink)
                            .minimumScaleFactor(0.72)

                        if difficulty.showsEquation {
                            Text(step.fact.equationText)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(MatherTheme.accent)
                                .minimumScaleFactor(0.72)
                        }
                    }
                    .padding(18)
                } else {
                    Button {
                        faceUp = true
                        speakCurrentPrompt()
                    } label: {
                        VStack(spacing: 14) {
                            Image(systemName: "rectangle.grid.2x2.fill")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundStyle(MatherTheme.softBlue)
                            Text("Tap to see the packing card")
                                .font(.headline.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 260)
                    }
                    .accessibilityLabel("Flip packing card")
                }
            }
            .frame(maxHeight: 360)
        }
    }

    private func firstLookStep(for step: ArrayPreludeRound.Step) -> some View {
        let concept = LabActivityID.factoryCards.introConceptCard

        return VStack(alignment: .leading, spacing: 10) {
            Label("First look", systemImage: "eye.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.accent)
            Text(concept?.principle ?? "Equal rows make one packed total.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("This card shows \(step.fact.rowColumnPhrase). Count each row before choosing the total.")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                didCompleteFirstLook = true
                speakCurrentPrompt()
            } label: {
                Label("I found the rows", systemImage: "checkmark.circle.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(MatherTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete first look for \(step.fact.rowColumnPhrase)")
        }
        .padding(14)
        .background(MatherTheme.card.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(concept?.accessibilityLabel ?? "First look. \(step.fact.rowColumnPhrase)")
    }

    private func totalChoices(for step: ArrayPreludeRound.Step) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose the packed total")
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)

            HStack(spacing: 12) {
                ForEach(step.totalChoices, id: \.self) { total in
                    Button {
                        choose(total, for: step)
                    } label: {
                        Text("\(total)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(choiceForeground(total: total, step: step))
                            .frame(maxWidth: .infinity, minHeight: 84)
                            .background(choiceBackground(total: total, step: step))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .disabled(selectedTotal != nil || !faceUp)
                    .accessibilityLabel("\(total) boxes")
                }
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 18) {
            Image(systemName: "shippingbox.and.arrow.backward.fill")
                .font(.system(size: 62, weight: .bold))
                .foregroundStyle(MatherTheme.coral)
            Text("Cards packed")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
            Text(LabActivityID.factoryCards.learningLoopSummaryPrompt ?? "Now resize rectangles for the same factory idea.")
                .font(.headline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .multilineTextAlignment(.center)

            Button {
                saveIfNeeded()
                appModel.engine.showRectangleFactory()
            } label: {
                Label("Factory Challenge", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button {
                saveIfNeeded()
                resetRound(speak: true)
            } label: {
                Label("Play Cards Again", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(MatherTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func resetRound(speak: Bool) {
        round = ArrayPreludeRound.make(difficulty: difficulty, seed: Int(Date().timeIntervalSince1970))
        currentIndex = 0
        correctCount = 0
        attemptedStepIds = []
        selectedTotal = nil
        faceUp = !difficulty.startsFaceDown
        savedSession = false
        didCompleteFirstLook = false
        if speak {
            appModel.speechService.speak(
                LabActivityID.factoryCards.introConceptCard?.childPrompt ?? "First, find the rows and columns.",
                enabled: appModel.featureFlags.audioEnabled
            )
        }
    }

    private func choose(_ total: Int, for step: ArrayPreludeRound.Step) {
        selectedTotal = total
        attemptedStepIds.insert(step.id)

        if step.fact.matches(product: total) {
            correctCount += 1
            appModel.hapticsService.cardSnapCorrect(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak("Yes. \(step.fact.rowColumnPhrase) makes \(step.fact.product).", enabled: appModel.featureFlags.audioEnabled)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 750_000_000)
                currentIndex += 1
                selectedTotal = nil
                if roundComplete {
                    appModel.hapticsService.bondMatchComplete(enabled: appModel.featureFlags.hapticsEnabled)
                    appModel.speechService.speak("Cards packed. Ready for the factory challenge.", enabled: appModel.featureFlags.audioEnabled)
                } else {
                    faceUp = !difficulty.startsFaceDown
                    if Self.shouldRequireFirstLook(forAdvancedIndex: currentIndex, totalSteps: round.steps.count) {
                        didCompleteFirstLook = false
                    }
                    speakCurrentPrompt()
                }
            }
        } else {
            appModel.hapticsService.cardSnapMismatch(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak("Try again. Count each row.", enabled: appModel.featureFlags.audioEnabled)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 550_000_000)
                selectedTotal = nil
            }
        }
    }

    private func speakCurrentPrompt() {
        guard let currentStep else { return }
        appModel.speechService.speak(currentStep.fact.spokenPrompt, enabled: appModel.featureFlags.audioEnabled)
    }

    private func choiceForeground(total: Int, step: ArrayPreludeRound.Step) -> Color {
        guard let selectedTotal else { return MatherTheme.ink }
        if total == selectedTotal, step.fact.matches(product: total) { return .white }
        if total == selectedTotal { return .white }
        return MatherTheme.ink
    }

    private func choiceBackground(total: Int, step: ArrayPreludeRound.Step) -> Color {
        guard let selectedTotal else { return MatherTheme.softBlue.opacity(0.34) }
        if total == selectedTotal, step.fact.matches(product: total) { return MatherTheme.accent }
        if total == selectedTotal { return MatherTheme.danger }
        return MatherTheme.softBlue.opacity(0.18)
    }

    nonisolated static func shouldRequireFirstLook(forAdvancedIndex index: Int, totalSteps: Int) -> Bool {
        index < totalSteps
    }

    private func saveIfNeeded() {
        guard !savedSession, correctCount > 0 else { return }
        savedSession = true
        appModel.gameSessionStore.save(
            gameName: "Packing Cards",
            startedAt: sessionStart,
            scoreValue: correctCount,
            scoreLabel: "cards packed",
            detail: difficulty.rawValue
        )
    }
}

private struct PackingArrayView: View {
    let fact: ArrayFact

    var body: some View {
        GeometryReader { proxy in
            let cell = min(
                proxy.size.width / CGFloat(fact.columns),
                proxy.size.height / CGFloat(fact.rows)
            )
            let packageSize = max(18, min(48, cell * 0.58))
            let gap = max(8, cell * 0.16)

            VStack(spacing: gap) {
                ForEach(0..<fact.rows, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<fact.columns, id: \.self) { column in
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill((row + column).isMultiple(of: 2) ? MatherTheme.warm : MatherTheme.softBlue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(MatherTheme.ink.opacity(0.12), lineWidth: 1)
                                )
                                .frame(width: packageSize, height: packageSize)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MatherTheme.panel.opacity(0.68))
            )
            .accessibilityLabel("\(fact.rows) rows of \(fact.columns) boxes")
        }
    }
}
