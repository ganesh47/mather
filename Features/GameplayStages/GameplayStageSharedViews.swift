import SwiftUI

struct GameplayStageTitle: View {
    let title: String
    let prompt: String
    let detail: String

    init(stage: GameplayStageDefinition, detail: String) {
        self.title = stage.title
        self.prompt = stage.prompt
        self.detail = detail
    }

    init(title: String, prompt: String, detail: String = "") {
        self.title = title
        self.prompt = prompt
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(MatherTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(prompt)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink.opacity(0.72))
            }
            Spacer()
            if !detail.isEmpty {
                Text(detail)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(MatherTheme.softBlue.opacity(0.5)))
            }
        }
    }
}

struct GameplayStagePanel: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(MatherTheme.panel.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(MatherTheme.panelDeep.opacity(0.18), lineWidth: 1)
            )
    }
}

struct GameplayDisplayCard: View {
    let item: GameplayDisplayItem
    let compact: Bool
    var showsSubtitle = true
    var selected = false
    var matched = false
    var concealed = false

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            Text(concealed ? "?" : item.visualKey ?? "✦")
                .font(.system(size: compact ? 40 : 58, weight: concealed ? .black : .regular, design: .rounded))
                .foregroundStyle(concealed ? MatherTheme.accent : MatherTheme.ink)
                .frame(width: compact ? 64 : 86, height: compact ? 58 : 78)
                .background(Circle().fill(MatherTheme.softBlue.opacity(0.45)))
            Text(concealed ? "Hidden match" : item.title)
                .font(compact ? .headline.bold() : .title3.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
            let subtitle = concealed ? "Tap to check" : item.subtitle
            if showsSubtitle && !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MatherTheme.ink.opacity(0.68))
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: compact ? 132 : 164)
        .padding(compact ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(matched ? MatherTheme.accent.opacity(0.22) : selected ? MatherTheme.softBlue : MatherTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(selected ? MatherTheme.accent : .clear, lineWidth: 3)
        )
    }
}

struct GameplayPairingStageShell: View {
    let title: String
    let prompt: String
    let compact: Bool
    @Binding var viewModel: GameplayMatchStageViewModel
    let actions: GameplayStageFeedbackActions
    let onComplete: (Int, Int, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
            GameplayStageTitle(title: title, prompt: prompt, detail: "\(viewModel.correctCount)/\(viewModel.pairs.count)")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.pairs) { pair in
                    Button {
                        viewModel.selectLeft(pairID: pair.id)
                    } label: {
                        GameplayDisplayCard(
                            item: pair.left,
                            compact: compact,
                            selected: viewModel.selectedLeftID == pair.id,
                            matched: viewModel.matchedPairIDs.contains(pair.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.accessibilityLabel(for: pair.left, side: .left))
                }
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.shuffledRights) { item in
                    Button {
                        let correct = viewModel.chooseRight(item)
                        if correct { actions.success() } else { actions.failure() }
                        if viewModel.isComplete { onComplete(viewModel.correctCount, viewModel.mismatchCount, viewModel.hintCount) }
                    } label: {
                        GameplayDisplayCard(
                            item: item,
                            compact: compact,
                            showsSubtitle: true,
                            matched: viewModel.matchedPairIDs.contains(pairID(for: item)),
                            concealed: viewModel.shouldConcealRight(item)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.accessibilityLabel(for: item, side: .right))
                }
            }
            HStack {
                Button("Hint") { viewModel.hintCount += 1 }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                Spacer()
                Button("Finish stage") { onComplete(viewModel.correctCount, viewModel.mismatchCount, viewModel.hintCount) }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                    .disabled(!viewModel.isComplete)
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: compact ? 132 : 176), spacing: 12)]
    }

    private func pairID(for item: GameplayDisplayItem) -> String {
        viewModel.pairs.first(where: { $0.right.id == item.id })?.id ?? item.id
    }
}
