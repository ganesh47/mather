import SwiftUI

/// The Explorer Lab — a capability playground for maths, physics, geometry, and science inquiry.
struct LabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel
    @State private var playfulPulse = false
    @State private var selectedPath: ExplorerPathID = .labs
    @State private var sensorCapabilities = DeviceSensorCapabilities.unavailable

    private let lanes = CapabilityLane.defaultExplorerLanes
    private let guidedPaths = GuidedLabPath.phaseOne
    private let gameEntries = ExplorerGameRegistry.directLaunchEntries

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            playgroundBackdrop
            GeometryReader { proxy in
                let compactGrid = proxy.size.width < 700
                let horizontalPadding: CGFloat = compactGrid ? 18 : 24

                ScrollView {
                    VStack(alignment: .leading, spacing: compactGrid ? 16 : 20) {
                        header
                        pathSelector(compact: compactGrid)

                        if selectedPath == .labs {
                            guidedLabsIntro(compact: compactGrid)

                            LazyVGrid(columns: labColumns(for: proxy.size.width), spacing: compactGrid ? 14 : 16) {
                                ForEach(lanes) { lane in
                                    laneCard(lane, compact: compactGrid)
                                }
                            }
                        } else {
                            directGamesSection(compact: compactGrid, width: proxy.size.width)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 24)
                }
            }
        }
        .onAppear {
            sensorCapabilities = SensorCapabilityService().currentCapabilities()
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

    private func pathSelector(compact: Bool) -> some View {
        let columns = compact
            ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            : [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

        return LazyVGrid(columns: columns, spacing: compact ? 12 : 16) {
            ForEach(ExplorerPathPresentation.all) { path in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        selectedPath = path.id
                    }
                } label: {
                    explorerPathCard(path, isSelected: selectedPath == path.id, compact: compact)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Explorer path: \(path.title). \(path.subtitle)")
                .accessibilityHint(path.callToAction)
            }
        }
    }

    private func explorerPathCard(_ path: ExplorerPathPresentation, isSelected: Bool, compact: Bool) -> some View {
        let tint = path.id == .labs ? MatherTheme.accent : MatherTheme.warm

        return VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack(spacing: 10) {
                Text(path.emoji)
                    .font(.system(size: compact ? 30 : 38))
                VStack(alignment: .leading, spacing: 2) {
                    Text(path.title)
                        .font(.system(size: compact ? 22 : 26, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                    Text(path.callToAction)
                        .font(.caption.weight(.black))
                        .foregroundStyle(tint)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.black))
                    .foregroundStyle(tint)
            }

            Text(path.subtitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(compact ? 3 : 2)
        }
        .padding(compact ? 12 : 16)
        .frame(maxWidth: .infinity, minHeight: compact ? 146 : 136, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [tint.opacity(isSelected ? 0.18 : 0.08), MatherTheme.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(isSelected ? 0.50 : 0.16), lineWidth: isSelected ? 2 : 1)
        )
    }

    private func guidedLabsIntro(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Labs build in stages")
                        .font(.title3.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text("Learn → Remember → Play → Blast → Score")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.accent)
                }
                Spacer(minLength: 0)
            }

            stageStrip(compact: compact)

            ForEach(guidedPaths) { path in
                guidedPathCard(path)
            }
        }
        .padding(16)
        .background(MatherTheme.card.opacity(0.86), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(MatherTheme.accent.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private func stageStrip(compact: Bool) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: compact ? 6 : 8), count: compact ? 3 : 5)
        return LazyVGrid(columns: columns, spacing: compact ? 6 : 8) {
            ForEach(GuidedLabStage.allCases) { stage in
                VStack(spacing: 4) {
                    Text(stage.emoji)
                        .font(.title3)
                    Text(stage.rawValue)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text(stage.microcopy)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(8)
                .frame(maxWidth: .infinity, minHeight: 82)
                .background(MatherTheme.panel.opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func guidedPathCard(_ path: GuidedLabPath) -> some View {
        let lane = lanes.first { $0.id == path.laneID }
        let tint = laneColor(path.laneID)

        return Button {
            appModel.engine.showLabLane(path.laneID)
        } label: {
            HStack(spacing: 12) {
                Text(lane?.emoji ?? "🧪")
                    .font(.system(size: 34))
                    .frame(width: 58, height: 58)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(path.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text(path.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                    if let primaryPlan = path.primaryPlan {
                        Text("First quest: \(primaryPlan.title) • \(primaryPlan.estimatedLength)")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(tint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    Text(path.stages.map(\.rawValue).joined(separator: " → "))
                        .font(.caption2.weight(.black))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3.weight(.black))
                    .foregroundStyle(tint)
            }
            .padding(12)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(path.title). \(path.subtitle). Stages: \(path.stages.map(\.rawValue).joined(separator: ", "))")
    }

    private func directGamesSection(compact: Bool, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Games")
                    .font(.title3.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("Direct launch stays one tap away. Pick any game without entering a staged lab session.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }

            LazyVGrid(columns: labColumns(for: width), spacing: compact ? 12 : 14) {
                ForEach(gameEntries) { entry in
                    directGameCard(entry)
                }
            }
        }
    }

    private func directGameCard(_ entry: ExplorerGameEntry) -> some View {
        let tint = laneColor(entry.laneID)
        let activity = entry.activity

        let canLaunch = activity.id.canDirectLaunch(with: sensorCapabilities)
        let capabilitySummary = activity.id.capabilitySummary(with: sensorCapabilities)

        return Button {
            launchDirectGame(entry)
        } label: {
            HStack(spacing: 12) {
                Text(activity.emoji)
                    .font(.system(size: 36))
                    .frame(width: 62, height: 62)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(canLaunch ? MatherTheme.ink : MatherTheme.ink.opacity(0.55))
                        .lineLimit(2)
                    Text(activity.tagline)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .lineLimit(2)
                    Text(canLaunch ? "Direct game" : "Needs a sensor on this device")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(canLaunch ? tint : MatherTheme.cardSubtitle)
                    Text(capabilitySummary)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: canLaunch ? "play.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(canLaunch ? tint : MatherTheme.cardSubtitle)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
            .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke((canLaunch ? tint : MatherTheme.cardSubtitle).opacity(0.16), lineWidth: 1)
            )
            .opacity(canLaunch ? 1 : 0.78)
        }
        .buttonStyle(.plain)
        .disabled(!canLaunch)
        .accessibilityLabel("Launch game \(activity.title). \(activity.tagline). \(capabilitySummary)")
        .accessibilityHint(canLaunch ? "Directly starts the existing game route without a staged lab session." : "This game needs a device sensor that is not available here; no score is lost.")
    }

    private func launchDirectGame(_ entry: ExplorerGameEntry) {
        appModel.pickProfileThenRun {
            appModel.clearLabGameplayCompletion()
            appModel.engine.show(entry.directRoute)
            if entry.activity.id == .sumSprint {
                appModel.sumSprintEngine.showDifficultyPick()
            }
        }
    }

    private func labColumns(for availableWidth: CGFloat) -> [GridItem] {
        availableWidth < 700
            ? [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
            : ResponsiveLayout.labColumns(for: availableWidth)
    }

    private func laneCard(_ lane: CapabilityLane, compact: Bool) -> some View {
        let progress = progress(for: lane)
        let presentation = LabLaneCardPresentation(lane: lane, progress: progress)
        let tint = laneColor(lane.id)

        return Button {
            appModel.engine.showLabLane(lane.id)
        } label: {
            Group {
                if compact {
                    compactLaneTile(lane, presentation: presentation, progress: progress, tint: tint)
                } else {
                    fullLaneCard(lane, presentation: presentation, progress: progress, tint: tint)
                }
            }
            .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(tint.opacity(compact ? 0.28 : 0.18), lineWidth: compact ? 1.5 : 1)
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
                radius: compact ? 7 : 8, y: compact ? 3 : 4
            )
            .scaleEffect(playfulPulse ? 1.01 : 0.995, anchor: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(presentation.accessibilityLabel). \(progress.progressSummaryLabel). \(progress.nextRecommendedModeLabel).")
        .accessibilityHint(presentation.accessibilityHint)
    }

    private func compactLaneTile(
        _ lane: CapabilityLane,
        presentation: LabLaneCardPresentation,
        progress: CapabilityLaneProgress,
        tint: Color
    ) -> some View {
        VStack(spacing: 10) {
            laneVisual(lane, tint: tint, size: 72)

            VStack(spacing: 4) {
                Text(presentation.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.center)

                Text(lane.ageBandHint)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }

            compactProgressBadge(progress, tint: tint)

            Image(systemName: "chevron.right.circle.fill")
                .font(.title3.weight(.black))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .center)
    }

    private func fullLaneCard(
        _ lane: CapabilityLane,
        presentation: LabLaneCardPresentation,
        progress: CapabilityLaneProgress,
        tint: Color
    ) -> some View {
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
    }

    private func compactProgressBadge(_ progress: CapabilityLaneProgress, tint: Color) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 3) {
                ForEach(0..<max(progress.availableModes.count, 1), id: \.self) { index in
                    Image(systemName: index < progress.completedModeCount ? "star.fill" : "star")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(tint)
                }
            }
            Text("\(progress.completedModeCount)/\(progress.availableModes.count) missions")
                .font(.caption2.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(tint.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.completedModeCount) of \(progress.availableModes.count) missions complete")
    }

    private func laneVisual(_ lane: CapabilityLane, tint: Color, size: CGFloat = 84) -> some View {
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
                .font(.system(size: size * 0.55))
                .scaleEffect(playfulPulse ? 1.06 : 0.98)
                .rotationEffect(.degrees(playfulPulse ? 2 : -2))
        }
        .frame(width: size, height: size)
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
