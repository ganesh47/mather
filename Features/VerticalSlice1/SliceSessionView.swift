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
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Problem \(appModel.engine.progressLabel)")
                            .font(.headline.weight(.bold))
                        Text(appModel.engine.currentStage.title)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                    }
                    Spacer()
                    Button {
                        appModel.featureFlags.audioEnabled.toggle()
                    } label: {
                        Image(systemName: appModel.featureFlags.audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2.weight(.bold))
                            .frame(width: 56, height: 56)
                            .background(MatherTheme.softBlue.opacity(0.45))
                            .clipShape(Circle())
                    }
                    Button {
                        appModel.engine.replayPrompt()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title2.weight(.bold))
                            .frame(width: 56, height: 56)
                            .background(MatherTheme.warm.opacity(0.55))
                            .clipShape(Circle())
                    }
                }

                ProgressView(value: Double(appModel.engine.currentProblemIndex + 1), total: Double(max(appModel.engine.problems.count, 1)))
                    .tint(MatherTheme.accent)
            }
        }
    }
}
