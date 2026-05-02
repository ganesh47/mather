import SwiftUI

/// The Explorer Lab — a capability playground for maths, physics, geometry, and science inquiry.
struct LabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel
    @State private var playfulPulse = false

    private let lanes = CapabilityLane.defaultExplorerLanes

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            playgroundBackdrop
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
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                playfulPulse = true
            }
        }
    }

    private var playgroundBackdrop: some View {
        ZStack {
            Circle()
                .fill(MatherTheme.warm.opacity(0.10))
                .frame(width: 180, height: 180)
                .offset(x: -170, y: -260)
            Circle()
                .fill(MatherTheme.softBlue.opacity(0.12))
                .frame(width: 220, height: 220)
                .offset(x: 180, y: 120)
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(MatherTheme.accent.opacity(0.16))
                .offset(x: 130, y: -210)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Explorer Lab")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Choose a world to explore")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text("Missions, mini cards, and sensor-powered experiments wait inside")
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
                    Label(lane.isReady ? "\(lane.activities.count) mission\(lane.activities.count == 1 ? "" : "s")" : "Missions coming soon", systemImage: lane.isReady ? "gamecontroller.fill" : "sparkles")
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
            .scaleEffect(playfulPulse ? 1.01 : 0.995, anchor: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(presentation.accessibilityLabel)
        .accessibilityHint(presentation.accessibilityHint)
    }

    private func laneVisual(_ lane: CapabilityLane, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.28), tint.opacity(0.10), MatherTheme.card.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            laneMiniScene(lane.id, tint: tint)
            Text(lane.emoji)
                .font(.system(size: 46))
                .scaleEffect(playfulPulse ? 1.06 : 0.98)
                .rotationEffect(.degrees(playfulPulse ? 2 : -2))
        }
        .frame(width: 84, height: 84)
    }

    @ViewBuilder
    private func laneMiniScene(_ laneID: CapabilityLaneID, tint: Color) -> some View {
        switch laneID {
        case .numbers:
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(tint.opacity(0.22))
                        .frame(width: 12, height: 12)
                        .offset(y: playfulPulse ? CGFloat(-index * 3) : CGFloat(index * 2))
                }
            }
            .offset(x: 16, y: 22)
        case .geometry:
            Image(systemName: "triangle.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(tint.opacity(0.24))
                .rotationEffect(.degrees(playfulPulse ? 12 : -6))
                .offset(x: 20, y: 18)
        case .physics:
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(tint.opacity(0.24))
                .offset(x: 20, y: -18)
            Circle()
                .fill(MatherTheme.warm.opacity(0.32))
                .frame(width: 16, height: 16)
                .offset(x: playfulPulse ? 24 : 10, y: playfulPulse ? 20 : 8)
        case .mapWorld:
            Image(systemName: "map.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(tint.opacity(0.24))
                .offset(x: 18, y: 18)
        case .discoveryCards:
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(tint.opacity(0.24))
                .offset(x: 18, y: 18)
        case .chemistry, .electronics:
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(tint.opacity(0.24))
                .offset(x: 18, y: 18)
        }
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
