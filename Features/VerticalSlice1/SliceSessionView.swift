import SwiftUI

struct SliceSessionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel
    @State private var celebrationScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [MatherTheme.background, MatherTheme.panel]
                    : [MatherTheme.background, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                let horizontalPadding = childSessionHorizontalPadding(for: proxy.size.width)

                VStack(spacing: 0) {
                    header
                        .frame(maxWidth: ResponsiveLayout.childSessionMaxWidth(for: horizontalSizeClass))
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 14)

                    ScrollView {
                        VStack(spacing: 16) {
                            FeedbackBannerView(message: childFacingBannerMessage, isCelebrating: appModel.engine.showCelebration)

                            if let currentProblem = appModel.engine.currentProblem {
                                stageView(for: currentProblem)
                            } else {
                                CardSurface { Text("No problem loaded.") }
                            }
                        }
                        .frame(maxWidth: ResponsiveLayout.childSessionMaxWidth(for: horizontalSizeClass))
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            // Fullscreen celebration overlay — appears on every correct stage answer.
            // The engine delays stage transition by 1.5s so the child sees the reward
            // before the screen changes. Non-interactive so taps pass through.
            if appModel.engine.showCelebration {
                ZStack {
                    Circle()
                        .fill(MatherTheme.coral.opacity(colorScheme == .dark ? 0.18 : 0.12))
                        .frame(width: 180, height: 180)
                        .blur(radius: 6)
                    Text(appModel.engine.activeTheme.celebrationEmoji)
                        .font(.system(size: 120))
                }
                .scaleEffect(celebrationScale)
                .allowsHitTesting(false)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .onAppear {
                    celebrationScale = 0.3
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        celebrationScale = 1.0
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsPersistentSubmitBar {
                persistentSubmitBar
            }
        }
        .animation(.easeOut(duration: 0.25), value: appModel.engine.showCelebration)
    }


    private func childSessionHorizontalPadding(for width: CGFloat) -> CGFloat {
        guard horizontalSizeClass != .regular else { return ResponsiveLayout.contentPadding(for: horizontalSizeClass) }
        if width < 360 { return 12 }
        if width < 430 { return 16 }
        return 20
    }

    private var childFacingBannerMessage: String {
        if appModel.engine.currentStage == .storyAnchor,
           appModel.engine.currentStoryPrompt != nil,
           !appModel.engine.showCelebration {
            return "Listen for the numbers, then start building."
        }
        return appModel.engine.feedbackMessage
    }

    @ViewBuilder
    private var gravitySplitUITestControls: some View {
        if appModel.featureFlags.testModeEnabled {
            HStack(spacing: 32) {
                Button("Add left") {
                    appModel.engine.adjustGravitySplitByTap(delta: 1, side: .left)
                }
                .accessibilityIdentifier("gravity-left-add-button")

                Button("Add right") {
                    appModel.engine.adjustGravitySplitByTap(delta: 1, side: .right)
                }
                .accessibilityIdentifier("gravity-right-add-button")

                Button("Complete split") {
                    appModel.engine.completeGravitySplitForUITest()
                }
                .accessibilityIdentifier("gravity-complete-split-button")
            }
            .buttonStyle(.plain)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.clear)
            .frame(height: 44)
            .padding(.horizontal, 24)
            .background(Color.clear.contentShape(Rectangle()))
        }
    }

    private var shouldAutoCompleteGravitySplitForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTest.autoCompleteGravitySplit")
    }

    private func scheduleGravitySplitUITestAutoComplete() {
        guard shouldAutoCompleteGravitySplitForUITests else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            appModel.engine.completeGravitySplitForUITest()
        }
    }

    @ViewBuilder
    private func stageView(for problem: SliceProblem) -> some View {
        switch appModel.engine.currentStage {
        case .storyAnchor:
            if let prompt = appModel.engine.currentStoryPrompt {
                StoryAnchorView(
                    prompt: prompt,
                    onStartBuilding: appModel.engine.startBuildingFromStoryAnchor
                )
            } else {
                CardSurface { Text("Loading Story...") }
            }
        case .concrete:
            ConcreteBuildView(
                target: problem.target,
                warmCount: appModel.engine.concreteWarmCount,
                accentCount: appModel.engine.concreteAccentCount,
                onAdjust: appModel.engine.adjustConcrete,
                onSubmit: appModel.engine.submitCurrentStage,
                theme: appModel.engine.activeTheme
            )
        case .pictorial:
            if let bondState = appModel.engine.bondMatchState {
                BondMatchView(
                    state: bondState,
                    storyPrompt: appModel.engine.currentNumberStoryPrompt,
                    tiltPitch: appModel.motionService.tiltPitch,
                    tiltRoll: appModel.motionService.tiltRoll,
                    shakeDetected: appModel.motionService.shakeDetected,
                    clapDetected: appModel.soundDetectionService.clapDetected,
                    onMatch: appModel.engine.matchPair(id:),
                    onMismatch: appModel.engine.mismatchPair,
                    onDragStarted: appModel.engine.bondDragStarted(pairId:),
                    onNearTarget: appModel.engine.bondNearTarget,
                    onShakeHandled: appModel.motionService.resetShake,
                    onClapHandled: appModel.soundDetectionService.resetClap
                )
                .onAppear {
                    if appModel.featureFlags.motionControlsEnabled {
                        appModel.motionService.startUpdates()
                    }
                    if appModel.featureFlags.soundReactionEnabled {
                        appModel.soundDetectionService.startListening()
                    }
                }
                .onDisappear {
                    appModel.motionService.stopUpdates()
                    appModel.soundDetectionService.stopListening()
                }
            } else {
                CardSurface { Text("Loading Bond Blast...") }
            }
        case .abstract:
            EquationResolveView(
                target: problem.target,
                leftInput: appModel.engine.equationLeftInput,
                rightInput: appModel.engine.equationRightInput,
                onAppend: appModel.engine.appendEquationDigit,
                onClear: appModel.engine.clearEquation,
                onSubmit: appModel.engine.submitCurrentStage,
                showsInlineSubmit: false,
                theme: appModel.engine.activeTheme
            )
        case .transfer:
            TransferCheckView(
                problem: problem,
                leftCount: appModel.engine.transferLeftCount,
                rightCount: appModel.engine.transferRightCount,
                onAdjust: appModel.engine.adjustTransfer,
                onSubmit: appModel.engine.submitCurrentStage,
                theme: appModel.engine.activeTheme
            )
        case .gravitySplit:
            if let splitState = appModel.engine.gravitySplitState {
                GravitySplitView(
                    state: splitState,
                    storyPrompt: appModel.engine.currentNumberStoryPrompt,
                    tiltRoll: appModel.motionService.tiltRoll,
                    shakeDetected: appModel.motionService.shakeDetected,
                    onAdjustTilt: appModel.engine.adjustGravitySplitByTilt,
                    onTap: appModel.engine.adjustGravitySplitByTap,
                    onReset: appModel.engine.resetGravitySplit,
                    onShakeHandled: { appModel.motionService.resetShake(); appModel.engine.resetGravitySplit() },
                    onSubmit: appModel.engine.submitCurrentStage
                )
                .overlay(alignment: .bottom) {
                    gravitySplitUITestControls
                }
                .onAppear {
                    appModel.motionService.startUpdates()
                    scheduleGravitySplitUITestAutoComplete()
                }
                .onDisappear { appModel.motionService.stopUpdates() }
            } else {
                CardSurface { Text("Loading Balance...") }
            }
        case .sumSprint:
            if let burst = appModel.engine.sumSprintBurstState {
                let vocabulary = sumSprintVocabulary(target: burst.target)
                CardSurface {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(vocabulary.title)
                            .font(.title.weight(.black))
                        Text(vocabulary.targetReminder)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(MatherTheme.warm)
                        Text("Matches \(burst.progressLabel)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(vocabulary.instruction)
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                            ForEach(burst.cards) { card in
                                Button {
                                    appModel.engine.selectSumSprintCard(id: card.id)
                                } label: {
                                    Text(card.content.displayText)
                                        .font(.system(size: 26, weight: .black, design: .rounded))
                                        .foregroundStyle(cardForeground(for: card))
                                        .frame(maxWidth: .infinity, minHeight: 88)
                                        .padding(.horizontal, 12)
                                        .background(cardBackground(for: card))
                                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .stroke(cardBorder(for: card), lineWidth: card.isSelected ? 4 : 2)
                                        }
                                }
                                .accessibilityIdentifier(sumSprintCardIdentifier(for: card, in: burst))
                                .accessibilityLabel(sumSprintCardAccessibilityLabel(for: card, vocabulary: vocabulary))
                                .buttonStyle(.plain)
                                .disabled(card.isMatched)
                            }
                        }
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                CardSurface { Text("Loading Sum Sprint...") }
            }
        case .bondMatch:
            if let bondState = appModel.engine.bondMatchState {
                BondMatchView(
                    state: bondState,
                    storyPrompt: appModel.engine.currentNumberStoryPrompt,
                    tiltPitch: appModel.motionService.tiltPitch,
                    tiltRoll: appModel.motionService.tiltRoll,
                    shakeDetected: appModel.motionService.shakeDetected,
                    clapDetected: appModel.soundDetectionService.clapDetected,
                    onMatch: appModel.engine.matchPair(id:),
                    onMismatch: appModel.engine.mismatchPair,
                    onDragStarted: appModel.engine.bondDragStarted(pairId:),
                    onNearTarget: appModel.engine.bondNearTarget,
                    onShakeHandled: appModel.motionService.resetShake,
                    onClapHandled: appModel.soundDetectionService.resetClap
                )
                .onAppear {
                    if appModel.featureFlags.motionControlsEnabled {
                        appModel.motionService.startUpdates()
                    }
                    if appModel.featureFlags.soundReactionEnabled {
                        appModel.soundDetectionService.startListening()
                    }
                }
                .onDisappear {
                    appModel.motionService.stopUpdates()
                    appModel.soundDetectionService.stopListening()
                }
            } else {
                CardSurface { Text("Loading Bond Blast...") }
            }
        case .done:
            CardSurface { Text("Moving to the next problem...") }
        }
    }

    private func cardBackground(for card: SumSprintBurstCard) -> some ShapeStyle {
        if card.isMatched {
            return AnyShapeStyle(MatherTheme.softBlue.opacity(0.22))
        }
        if card.isSelected {
            return AnyShapeStyle(MatherTheme.accent.opacity(0.18))
        }
        return AnyShapeStyle(MatherTheme.panel)
    }

    private func cardBorder(for card: SumSprintBurstCard) -> Color {
        if card.isMatched { return MatherTheme.softBlue }
        if card.isSelected { return MatherTheme.accent }
        return MatherTheme.accent.opacity(0.18)
    }

    private func cardForeground(for card: SumSprintBurstCard) -> Color {
        card.isMatched ? MatherTheme.softBlue : .primary
    }

    private func sumSprintVocabulary(target: Int) -> NumberStoryStageVocabulary {
        if let prompt = appModel.engine.currentNumberStoryPrompt {
            return NumberStoryStageVocabulary.vocabulary(for: prompt, stage: .sumSprint)
        }
        return NumberStoryStageVocabulary.fallback(stage: .sumSprint, target: target)
    }

    private func sumSprintCardAccessibilityLabel(
        for card: SumSprintBurstCard,
        vocabulary: NumberStoryStageVocabulary
    ) -> String {
        "\(vocabulary.accessibilityLabel) Card \(card.content.displayText)\(card.isMatched ? ", matched" : "")"
    }

    private var header: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 8) {
                        headerTitleBlock
                        Spacer(minLength: 8)
                        headerActionButtons
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        headerTitleBlock
                        headerActionButtons
                    }
                }

                ProgressView(value: Double(appModel.engine.currentProblemIndex + 1), total: Double(max(appModel.engine.problems.count, 1)))
                    .tint(stageColour(appModel.engine.currentStage))
                    .animation(.easeInOut(duration: 0.4), value: appModel.engine.currentProblemIndex)
            }
        }
    }

    private var headerTitleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Problem \(appModel.engine.progressLabel)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(appModel.engine.currentStage.title)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(stageColour(appModel.engine.currentStage))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headerActionButtons: some View {
        HStack(spacing: 8) {
            Button {
                appModel.engine.playPromptFromSpeakerButton()
            } label: {
                Image(systemName: appModel.featureFlags.audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(appModel.featureFlags.audioEnabled ? MatherTheme.softBlue : .secondary)
                    .frame(width: 44, height: 44)
                    .background(MatherTheme.softBlue.opacity(colorScheme == .dark ? 0.24 : 0.18))
                    .overlay(Circle().strokeBorder(.white.opacity(colorScheme == .dark ? 0.08 : 0), lineWidth: 1))
                    .clipShape(Circle())
            }
            .accessibilityLabel(appModel.featureFlags.audioEnabled ? "Play prompt" : "Enable audio and play prompt")
            .accessibilityHint("Speaks the current instruction aloud.")

            Button {
                appModel.engine.playPromptFromSpeakerButton()
            } label: {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(MatherTheme.warm)
                    .frame(width: 44, height: 44)
                    .background(MatherTheme.warm.opacity(colorScheme == .dark ? 0.24 : 0.18))
                    .overlay(Circle().strokeBorder(.white.opacity(colorScheme == .dark ? 0.08 : 0), lineWidth: 1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Replay prompt")
            .accessibilityHint("Speaks the current instruction aloud.")

            Button {
                appModel.engine.showHome()
            } label: {
                Image(systemName: "house.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Color.secondary.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .overlay(Circle().strokeBorder(.white.opacity(colorScheme == .dark ? 0.06 : 0), lineWidth: 1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Go to Home")
        }
    }

    private func sumSprintCardIdentifier(for card: SumSprintBurstCard, in burst: SumSprintBurstState) -> String {
        switch card.content {
        case .prompt(let prompt):
            return "sumsprint-prompt-\(normalizedSumSprintToken(prompt))"
        case .sum(let value), .decoratedSum(let value, _):
            let prompt = burst.cards.compactMap { sibling -> String? in
                guard sibling.pairId == card.pairId,
                      case .prompt(let prompt) = sibling.content else { return nil }
                return prompt
            }.first ?? String(value)
            return "sumsprint-sum-\(value)-for-\(normalizedSumSprintToken(prompt))"
        }
    }

    private func normalizedSumSprintToken(_ value: String) -> String {
        let mapped = value.lowercased().map { character -> String in
            if character.isLetter || character.isNumber { return String(character) }
            if character == "+" { return "-plus-" }
            return "-"
        }.joined()
        return mapped
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func stageColour(_ stage: SliceStage) -> Color {
        switch stage {
        case .storyAnchor:   MatherTheme.accent
        case .concrete:  MatherTheme.warm
        case .pictorial: MatherTheme.softBlue
        case .abstract:  MatherTheme.accent
        case .transfer:      MatherTheme.coral
        case .gravitySplit:  MatherTheme.coral
        case .sumSprint:     MatherTheme.softBlue
        case .bondMatch:     MatherTheme.accent
        case .done:          .secondary
        }
    }

    private var showsPersistentSubmitBar: Bool {
        appModel.engine.currentStage == .abstract && appModel.engine.currentProblem != nil
    }

    private var persistentSubmitBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.secondary.opacity(0.08))

            Button("Check equation") {
                appModel.engine.submitCurrentStage()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .frame(maxWidth: ResponsiveLayout.childSessionMaxWidth(for: horizontalSizeClass))
            .padding(.horizontal, ResponsiveLayout.contentPadding(for: horizontalSizeClass))
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(persistentSubmitBarBackground)
    }

    @ViewBuilder
    private var persistentSubmitBarBackground: some View {
        if colorScheme == .dark {
            MatherTheme.panel.opacity(0.98)
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
    }
}
