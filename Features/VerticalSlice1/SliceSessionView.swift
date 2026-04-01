import SwiftUI

struct SliceSessionView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MatherTheme.background, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    FeedbackBannerView(message: appModel.engine.feedbackMessage, isCelebrating: appModel.engine.showCelebration)

                    if let currentProblem = appModel.engine.currentProblem {
                        stageView(for: currentProblem)
                    } else {
                        CardSurface { Text("No problem loaded.") }
                    }
                }
                .padding(20)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private func stageView(for problem: SliceProblem) -> some View {
        switch appModel.engine.currentStage {
        case .concrete:
            ConcreteBuildView(target: problem.target, concreteCount: appModel.engine.concreteCount, onAdjust: appModel.engine.adjustConcrete, onSubmit: appModel.engine.submitCurrentStage)
        case .pictorial:
            SplitView(target: problem.target, leftCount: appModel.engine.splitLeftCount, onAdjust: appModel.engine.moveSplit, onSubmit: appModel.engine.submitCurrentStage)
        case .abstract:
            EquationResolveView(target: problem.target, leftInput: appModel.engine.equationLeftInput, rightInput: appModel.engine.equationRightInput, onAppend: appModel.engine.appendEquationDigit, onClear: appModel.engine.clearEquation, onSubmit: appModel.engine.submitCurrentStage)
        case .transfer:
            TransferCheckView(problem: problem, transferCount: appModel.engine.transferCount, onAdjust: appModel.engine.adjustTransfer, onSubmit: appModel.engine.submitCurrentStage)
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
                    }
                    Spacer()
                    Button {
                        appModel.featureFlags.audioEnabled.toggle()
                    } label: {
                        Image(systemName: appModel.featureFlags.audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(appModel.featureFlags.audioEnabled ? MatherTheme.softBlue : .secondary)
                            .frame(width: 52, height: 52)
                            .background(MatherTheme.softBlue.opacity(0.18))
                            .clipShape(Circle())
                    }
                    Button {
                        appModel.engine.replayPrompt()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(MatherTheme.warm)
                            .frame(width: 52, height: 52)
                            .background(MatherTheme.warm.opacity(0.18))
                            .clipShape(Circle())
                    }
                }

                ProgressView(value: Double(appModel.engine.currentProblemIndex + 1), total: Double(max(appModel.engine.problems.count, 1)))
                    .tint(stageColour(appModel.engine.currentStage))
                    .animation(.easeInOut(duration: 0.4), value: appModel.engine.currentProblemIndex)
            }
        }
    }

    private func stageColour(_ stage: SliceStage) -> Color {
        switch stage {
        case .concrete: MatherTheme.warm
        case .pictorial: MatherTheme.softBlue
        case .abstract: MatherTheme.accent
        case .transfer: MatherTheme.coral
        case .done: .secondary
        }
    }
}
