import SwiftUI

/// The Explorer Lab — a capability playground for maths, physics, geometry, and science inquiry.
struct LabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel

    private let lanes = CapabilityLane.defaultExplorerLanes

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        LazyVGrid(columns: labColumns(for: proxy.size.width), spacing: 16) {
                            ForEach(lanes) { lane in
                                laneCard(lane)
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Explorer Lab")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Pick a capability lane")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text("Games, review cards, play styles, and sensors live inside each lane")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
            }
            Spacer()
            Button {
                appModel.engine.showHome()
            } label: {
                Image(systemName: "house.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(MatherTheme.accent)
                    .frame(width: 56, height: 56)
            }
            .accessibilityLabel("Home")
        }
    }

    private func labColumns(for availableWidth: CGFloat) -> [GridItem] {
        availableWidth < 700
            ? [GridItem(.flexible(), spacing: 16)]
            : ResponsiveLayout.labColumns(for: availableWidth)
    }

    private func laneCard(_ lane: CapabilityLane) -> some View {
        let progress = progress(for: lane)
        let presentation = LabLaneCardPresentation(lane: lane, progress: progress)
        let tint = laneColor(lane.id)

        return Button {
            appModel.engine.showLabLane(lane.id)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    laneVisual(lane, tint: tint)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(presentation.title)
                                .font(.headline.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text(lane.ageBandHint)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(tint)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(tint.opacity(0.12), in: Capsule())
                        }
                        Text(presentation.promiseLine)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                progressPreview(progress, tint: tint)

                HStack(spacing: 10) {
                    Label(lane.isReady ? "\(lane.activities.count) game\(lane.activities.count == 1 ? "" : "s")" : "Games coming soon", systemImage: lane.isReady ? "gamecontroller.fill" : "sparkles")
                        .font(.caption.weight(.black))
                        .foregroundStyle(tint)
                    Spacer(minLength: 8)
                    Label(presentation.openAffordanceLabel, systemImage: "chevron.right.circle.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(tint)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
                radius: 8, y: 4
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(presentation.accessibilityLabel)
        .accessibilityHint(presentation.accessibilityHint)
    }

    private func laneVisual(_ lane: CapabilityLane, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.14))
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 48, height: 48)
                .offset(x: 18, y: -18)
            Text(lane.emoji)
                .font(.system(size: 46))
        }
        .frame(width: 84, height: 84)
    }

    private func progress(for lane: CapabilityLane) -> CapabilityLaneProgress {
        guard let masteryState = appModel.explorerLabMasteryProfile[lane.id] else {
            return lane.emptyProgress
        }
        return CapabilityLaneProgress(masteryState: masteryState)
    }

    private func progressPreview(_ progress: CapabilityLaneProgress, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(progress.progressSummaryLabel)
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(progress.nextRecommendedModeLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(MatherTheme.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lane progress \(progress.progressSummaryLabel). \(progress.nextRecommendedModeLabel)")
    }

    private func laneColor(_ laneID: CapabilityLaneID) -> Color {
        switch laneID {
        case .numbers:
            return MatherTheme.warm
        case .geometry:
            return MatherTheme.coral
        case .physics:
            return MatherTheme.panelDeep
        case .mapWorld:
            return MatherTheme.softBlue
        case .discoveryCards:
            return MatherTheme.accent
        case .chemistry:
            return MatherTheme.warm
        case .electronics:
            return MatherTheme.accent
        }
    }
}
