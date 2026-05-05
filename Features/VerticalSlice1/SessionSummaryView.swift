import SwiftUI

struct SessionSummaryView: View {
    @Bindable var appModel: AppModel
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0
    @State private var confettiBurst = false

    private var summary: SessionSummaryDraft? { appModel.engine.completedSummary }
    private var problemsSolvedText: String {
        let completed = summary?.problemsCompleted ?? appModel.engine.problems.count
        let maxTarget = appModel.engine.problems.map(\.target).max() ?? appModel.engine.config.parentTargetCap
        return "\(completed) problems solved · Target up to \(maxTarget)"
    }
    private var firstTryText: String {
        guard let summary else { return "Great effort all session" }
        return "\(Int((summary.firstAttemptAccuracy * 100).rounded()))% first try"
    }
    private var transferText: String {
        guard let summary else { return "Number bonds practised" }
        return "\(summary.transferCorrectCount) review checks correct"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MatherTheme.warm.opacity(0.4), MatherTheme.accent.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            celebrationSprinkles

            VStack(spacing: 24) {
                Spacer(minLength: 18)

                VStack(spacing: 14) {
                    Text("⭐️")
                        .font(.system(size: 96))
                        .scaleEffect(scale)
                        .opacity(opacity)

                    Text("Amazing!")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)

                    Text("You did it!")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(problemsSolvedText)
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.52), in: Capsule())
                        .accessibilityIdentifier("session-summary-progress-subtitle")
                }
                .multilineTextAlignment(.center)

                progressCard

                Spacer(minLength: 12)

                VStack(spacing: 12) {
                    Button("Play again") {
                        appModel.engine.showSessionConfig()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityIdentifier("session-summary-play-again-button")

                    Button("Done") {
                        appModel.engine.showHome()
                    }
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.softBlue)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(MatherTheme.softBlue.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("session-summary-done-button")

                    Button("Parent summary") {
                        appModel.engine.showParentSummary()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("session-summary-parent-summary-button")
                }
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.9)) {
                confettiBurst = true
            }
        }
    }

    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                progressMetric(value: firstTryText, label: "accuracy", fill: MatherTheme.accent)
                progressMetric(value: transferText, label: "review", fill: MatherTheme.warm)
            }
            if let next = summary?.nextTargetHint, !next.isEmpty {
                Text(next)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
        )
        .accessibilityIdentifier("session-summary-progress-card")
    }

    private func progressMetric(value: String, label: String, fill: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(fill)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            Text(label.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(.horizontal, 8)
        .background(fill.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var celebrationSprinkles: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? MatherTheme.accent.opacity(0.45) : MatherTheme.warm.opacity(0.45))
                    .frame(width: 10 + CGFloat(index % 3) * 4, height: 10 + CGFloat(index % 3) * 4)
                    .offset(
                        x: confettiBurst ? CGFloat((index % 5) - 2) * 58 : 0,
                        y: confettiBurst ? CGFloat((index / 5) == 0 ? -150 : 150) : 0
                    )
                    .opacity(confettiBurst ? 0.15 : 0.8)
            }
        }
        .allowsHitTesting(false)
    }
}
