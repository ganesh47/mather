import SwiftUI

struct SliceSessionView: View {
    @Bindable var appModel: AppModel
    @State private var celebrationScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MatherTheme.background, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 20) {
                        FeedbackBannerView(message: appModel.engine.feedbackMessage, isCelebrating: appModel.engine.showCelebration)

                        if let currentProblem = appModel.engine.currentProblem {
                            stageView(for: currentProblem)
                        } else {
                            CardSurface { Text("No problem loaded.") }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }

            // Fullscreen celebration overlay — appears on every correct stage answer.
            // The engine delays stage transition by 1.5s so the child sees the reward
            // before the screen changes. Non-interactive so taps pass through.
            if appModel.engine.showCelebration {
                Text(appModel.engine.activeTheme.celebrationEmoji)
                    .font(.system(size: 120))
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

    @ViewBuilder
    private func stageView(for problem: SliceProblem) -> some View {
        switch appModel.engine.currentStage {
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
            SplitView(
                target: problem.target,
                leftCount: appModel.engine.splitLeftCount,
                onAdjust: appModel.engine.moveSplit,
                onSubmit: appModel.engine.submitCurrentStage,
                theme: appModel.engine.activeTheme
            )
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
        case .bondMatch:
            if let bondState = appModel.engine.bondMatchState {
                BondMatchView(
                    state: bondState,
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
            }
        case .done:
            CardSurface { Text("Moving to the next problem...") }
        }
    }

    private var header: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Problem \(appModel.engine.progressLabel)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(appModel.engine.currentStage.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(stageColour(appModel.engine.currentStage))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer()
                    Button {
                        appModel.featureFlags.audioEnabled.toggle()
                    } label: {
                        Image(systemName: appModel.featureFlags.audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(appModel.featureFlags.audioEnabled ? MatherTheme.softBlue : .secondary)
                            .frame(width: 44, height: 44)
                            .background(MatherTheme.softBlue.opacity(0.18))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(appModel.featureFlags.audioEnabled ? "Mute audio" : "Enable audio")
                    Button {
                        appModel.engine.replayPrompt()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(MatherTheme.warm)
                            .frame(width: 44, height: 44)
                            .background(MatherTheme.warm.opacity(0.18))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Replay prompt")
                    // Adult escape hatch — secondary styling so child ignores it
                    Button {
                        appModel.engine.showHome()
                    } label: {
                        Image(systemName: "house.circle.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Go to Home")
                }

                ProgressView(value: Double(appModel.engine.currentProblemIndex + 1), total: Double(max(appModel.engine.problems.count, 1)))
                    .tint(stageColour(appModel.engine.currentStage))
                    .animation(.easeInOut(duration: 0.4), value: appModel.engine.currentProblemIndex)
            }
        }
    }

    private func stageColour(_ stage: SliceStage) -> Color {
        switch stage {
        case .concrete:  MatherTheme.warm
        case .pictorial: MatherTheme.softBlue
        case .abstract:  MatherTheme.accent
        case .transfer:  MatherTheme.coral
        case .bondMatch: MatherTheme.accent
        case .done:      .secondary
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
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
}
