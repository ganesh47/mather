import SwiftUI

struct BondBlastStageView: View {
    let stage: GameplayStageDefinition
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void
    @State private var viewModel: GameplayMatchStageViewModel

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, actions: GameplayStageFeedbackActions, compact: Bool, onComplete: @escaping (Int, Int, Int) -> Void) {
        self.stage = stage
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        _viewModel = State(initialValue: GameplayMatchStageViewModel(thread: thread, round: round, mode: .bondBlast, turnItemCount: stage.recommendedTurnItemCount))
    }

    var body: some View {
        ReusableBondBlastBoard(
            title: stage.title,
            prompt: stage.prompt.isEmpty ? "Pick a card, then tap its matching bond." : stage.prompt,
            compact: compact,
            viewModel: $viewModel,
            actions: actions,
            onComplete: onComplete
        )
    }
}

/// A reusable, data-agnostic Bond Blast board for non-number gameplay threads.
///
/// This intentionally mirrors the VS1 number `BondMatchView` interaction language
/// without depending on number-specific `BondMatchState`: a focused left column,
/// a center connection cue, right-side target slots that reveal after selection,
/// progress dots, and turn-sized boards instead of generic scrolling grids.
struct ReusableBondBlastBoard: View {
    let title: String
    let prompt: String
    let compact: Bool
    @Binding var viewModel: GameplayMatchStageViewModel
    let actions: GameplayStageFeedbackActions
    let onComplete: (Int, Int, Int) -> Void

    @State private var mismatchedRightID: String?
    @State private var autoProgressTask: Task<Void, Never>?
    @State private var autoProgressSignature: String?

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
            GameplayStageTitle(
                title: title,
                prompt: instructionText,
                detail: "\(viewModel.turnProgressText) • \(viewModel.correctCount)/\(viewModel.pairs.count)"
            )

            HStack(alignment: .top, spacing: compact ? 10 : 16) {
                VStack(spacing: compact ? 8 : 12) {
                    columnLabel("Pick")
                    ForEach(viewModel.activePairs) { pair in
                        leftCard(pair)
                    }
                }

                VStack(spacing: compact ? 8 : 12) {
                    columnLabel(" ")
                    ForEach(viewModel.activePairs) { pair in
                        connectionCue(matched: viewModel.matchedPairIDs.contains(pair.id))
                    }
                }
                .frame(width: compact ? 34 : 46)

                VStack(spacing: compact ? 8 : 12) {
                    columnLabel("Match")
                    ForEach(viewModel.shuffledRights) { item in
                        rightCard(item)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            progressDots

            if autoProgressSignature != nil {
                GameplayMatchRewardBanner(text: viewModel.canAdvanceTurn ? "Great matches! Next turn is coming…" : "Great matches! Your reward is coming…")
            }

            if let item = viewModel.inspectedItem, shouldShowDetail(for: item) {
                GameplayBondBlastDetailCallout(item: item, compact: compact)
            }

            HStack {
                Button("Hint") { viewModel.hintCount += 1 }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                Spacer()
                if viewModel.canAdvanceTurn {
                    Button("Next turn") {
                        cancelAutoProgress()
                        viewModel.advanceTurn()
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                } else {
                    Button("Finish stage") {
                        cancelAutoProgress()
                        onComplete(viewModel.correctCount, viewModel.mismatchCount, viewModel.hintCount)
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                    .disabled(!viewModel.isComplete)
                }
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
        .accessibilityLabel("\(title). \(viewModel.correctCount) of \(viewModel.pairs.count) bonds matched.")
        .onDisappear { cancelAutoProgress() }
    }


    private func scheduleAutoProgressIfReady() {
        let signature: String?
        if viewModel.canAdvanceTurn {
            signature = "turn-\(viewModel.activeTurnIndex)-\(viewModel.correctCount)"
        } else if viewModel.isComplete {
            signature = "complete-\(viewModel.correctCount)"
        } else {
            signature = nil
        }
        guard let signature else { return }
        guard autoProgressSignature != signature else { return }
        cancelAutoProgress()
        autoProgressSignature = signature
        autoProgressTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_200))
            guard autoProgressSignature == signature else { return }
            if viewModel.canAdvanceTurn {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    viewModel.advanceTurn()
                }
            } else if viewModel.isComplete {
                onComplete(viewModel.correctCount, viewModel.mismatchCount, viewModel.hintCount)
            }
            autoProgressSignature = nil
            autoProgressTask = nil
        }
    }

    private func cancelAutoProgress() {
        autoProgressTask?.cancel()
        autoProgressTask = nil
        autoProgressSignature = nil
    }

    private var instructionText: String {
        viewModel.selectedLeftID == nil ? prompt : "Now find its match."
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.activePairs) { pair in
                Circle()
                    .fill(viewModel.matchedPairIDs.contains(pair.id) ? MatherTheme.accent : Color.secondary.opacity(0.25))
                    .frame(width: compact ? 10 : 14, height: compact ? 10 : 14)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: viewModel.matchedPairIDs)
    }

    private func leftCard(_ pair: GameplayMatchPair) -> some View {
        let isSelected = viewModel.selectedLeftID == pair.id
        let isMatched = viewModel.matchedPairIDs.contains(pair.id)
        return Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.66)) {
                viewModel.selectLeft(pairID: pair.id)
            }
        } label: {
            GameplayDisplayCard(
                item: pair.left,
                compact: compact,
                selected: isSelected,
                matched: isMatched,
                prominence: .normal
            )
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.66), value: isSelected)
        .accessibilityLabel(viewModel.accessibilityLabel(for: pair.left, side: .left))
    }

    private func rightCard(_ item: GameplayDisplayItem) -> some View {
        let pairID = viewModel.pairID(forRight: item)
        let isMatched = viewModel.matchedPairIDs.contains(pairID)
        let isRevealed = Self.shouldRevealRightCard(selectedPairID: viewModel.selectedLeftID, pairID: pairID, isMatched: isMatched)
        let isMismatched = mismatchedRightID == item.id
        return Button {
            let hadSelection = viewModel.selectedLeftID != nil
            let correct = viewModel.chooseRight(item)
            if correct {
                actions.success()
            } else if hadSelection {
                actions.failure()
                triggerMismatch(for: item.id)
            }
            scheduleAutoProgressIfReady()
        } label: {
            GameplayDisplayCard(
                item: item,
                compact: compact,
                showsSubtitle: isRevealed,
                selected: viewModel.inspectedItemID == item.id && isRevealed,
                matched: isMatched,
                concealed: !isRevealed,
                prominence: .normal
            )
            .overlay(targetSlotOverlay(active: viewModel.selectedLeftID != nil && !isMatched, matched: isMatched))
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .offset(x: isMismatched ? 8 : 0)
        .animation(isMismatched ? .easeInOut(duration: 0.08).repeatCount(5, autoreverses: true) : .default, value: isMismatched)
        .accessibilityLabel(isRevealed ? viewModel.accessibilityLabel(for: item, side: .right) : "Hidden match target")
    }

    @ViewBuilder
    private func connectionCue(matched: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous)
                .fill(matched ? MatherTheme.accent.opacity(0.16) : MatherTheme.softBlue.opacity(0.18))
                .frame(height: compact ? 132 : 164)
            Image(systemName: matched ? "checkmark" : "arrow.right")
                .font(.system(size: compact ? 16 : 22, weight: .black, design: .rounded))
                .foregroundStyle(matched ? MatherTheme.accent : MatherTheme.ink.opacity(0.45))
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func targetSlotOverlay(active: Bool, matched: Bool) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                matched ? MatherTheme.accent : (active ? MatherTheme.softBlue : Color.secondary.opacity(0.28)),
                style: StrokeStyle(lineWidth: active || matched ? 3 : 2, dash: active || matched ? [] : [7, 4])
            )
    }

    private func columnLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(height: 20)
    }

    private func shouldShowDetail(for item: GameplayDisplayItem) -> Bool {
        guard viewModel.activePairs.contains(where: { $0.left.id == item.id || $0.right.id == item.id }) else { return false }
        if viewModel.activePairs.contains(where: { $0.left.id == item.id }) { return true }
        let pairID = viewModel.pairID(forRight: item)
        return Self.shouldRevealRightCard(selectedPairID: viewModel.selectedLeftID, pairID: pairID, isMatched: viewModel.matchedPairIDs.contains(pairID))
    }

    private func triggerMismatch(for itemID: String) {
        mismatchedRightID = itemID
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            mismatchedRightID = nil
        }
    }

    nonisolated static func shouldRevealRightCard(selectedPairID: String?, pairID: String, isMatched: Bool) -> Bool {
        isMatched || selectedPairID == pairID || selectedPairID != nil
    }
}

private struct GameplayBondBlastDetailCallout: View {
    let item: GameplayDisplayItem
    let compact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(item.visualKey ?? "✦")
                .font(.system(size: compact ? 24 : 30, weight: .semibold, design: .rounded))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.headline.bold())
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.ink.opacity(0.72))
                }
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(MatherTheme.softBlue.opacity(0.5)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Card details: \(item.title), \(item.subtitle)")
    }
}
