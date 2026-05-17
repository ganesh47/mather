import SwiftUI

/// The Explorer Lab — a capability playground for maths, physics, geometry, and science inquiry.
struct LabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var appModel: AppModel
    @State private var playfulPulse = false
    @State private var selectedPath: ExplorerPathID
    @State private var sensorCapabilities = DeviceSensorCapabilities.unavailable

    init(appModel: AppModel, initialPath: ExplorerPathID = .labs) {
        self.appModel = appModel
        _selectedPath = State(initialValue: initialPath)
    }

    private let lanes = CapabilityLane.labSubjectStreams
    private let guidedPaths = GuidedLabPath.phaseOne
    private let gameEntries = ExplorerGameRegistry.directLaunchEntries
    private var catalogPresentation: ExplorerCatalogRoutePresentation {
        ExplorerCatalogRoutePresentation(selectedPath: selectedPath)
    }

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

                        if catalogPresentation.showsLabStreams {
                            LazyVGrid(columns: labColumns(for: proxy.size.width), spacing: compactGrid ? 14 : 16) {
                                ForEach(lanes) { lane in
                                    laneCard(lane, compact: compactGrid)
                                }
                            }

                            guidedLabsIntro(compact: compactGrid)
                        } else if catalogPresentation.showsDirectGames {
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
            guard !reduceMotion else {
                playfulPulse = false
                return
            }
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
                Text(selectedPath == .labs ? "Labs" : "Games")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Explorer Lab")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                if catalogPresentation.showsDirectGames {
                    Text("Jump straight into a game")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatherTheme.accent)
                }
            }
            Spacer()
            Button {
                appModel.engine.showHome()
            } label: {
                Image(systemName: "house.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(MatherTheme.accent)
                    .frame(width: 80, height: 80)
            }
            .accessibilityLabel("Home")
        }
    }

    private func guidedLabsIntro(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guided path")
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text("Optional staged learning appears after the stream cards so other streams stay visible.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
                Spacer(minLength: 0)
            }

            compactStageStrip(compact: compact)

            ForEach(guidedPaths) { path in
                guidedPathCard(path)
            }
        }
        .padding(14)
        .background(MatherTheme.card.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(MatherTheme.accent.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private func compactStageStrip(compact: Bool) -> some View {
        LabDetailFlowLayout(spacing: compact ? 5 : 6) {
            ForEach(GuidedLabStage.allCases) { stage in
                Label(stage.rawValue, systemImage: stage.symbolName)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(MatherTheme.panel.opacity(0.62), in: Capsule())
            }
        }
        .accessibilityLabel(GuidedLabStage.allCases.map(\.rawValue).joined(separator: " to "))
    }

    private func stageArtwork(_ stage: GuidedLabStage, tint: Color, compact: Bool) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.12))
            Image(systemName: stage.symbolName)
                .font(.system(size: compact ? 14 : 16, weight: .black))
                .foregroundStyle(tint)
        }
        .frame(width: compact ? 30 : 34, height: compact ? 30 : 34)
        .accessibilityLabel(stage.artworkAccessibilityLabel)
    }

    private func guidedPathCard(_ path: GuidedLabPath) -> some View {
        let lane = lanes.first { $0.id == path.laneID }
        let tint = path.laneID.themeColor

        return Button {
            appModel.engine.showLabLane(path.laneID)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.12))
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.black))
                        .foregroundStyle(tint)
                    Text(lane?.emoji ?? "🧪")
                        .font(.system(size: 24))
                        .offset(x: 10, y: 10)
                }
                .frame(width: 58, height: 58)
                .accessibilityLabel("Guided lab artwork for \(path.title)")
                VStack(alignment: .leading, spacing: 4) {
                    Text(path.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text(path.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                    if let primaryPlan = path.primaryPlan {
                        Text("First: \(primaryPlan.title) • \(primaryPlan.estimatedLength)")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(tint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
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
        GameActivityCard(
            activity: entry.activity,
            tint: entry.laneID.themeColor,
            canLaunch: entry.activity.id.canDirectLaunch(with: sensorCapabilities),
            layoutMode: .grid,
            sensorCapabilities: sensorCapabilities
        ) {
            launchDirectGame(entry)
        }
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
        let tint = lane.id.themeColor

        return Button {
            appModel.engine.showLabLane(lane.id)
        } label: {
            laneStreamTile(lane, presentation: presentation, tint: tint, compact: compact)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.95), tint.opacity(0.70)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(colorScheme == .dark ? 0.10 : 0.0), lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
                radius: compact ? 7 : 8, y: compact ? 3 : 4
            )
            .scaleEffect(!reduceMotion && playfulPulse ? 1.01 : 1.0, anchor: .center)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("lab-stream-card-\(lane.id.rawValue)")
        .accessibilityLabel(presentation.accessibilityLabel)
        .accessibilityHint(presentation.accessibilityHint)
    }

    private func laneStreamTile(
        _ lane: CapabilityLane,
        presentation: LabLaneCardPresentation,
        tint: Color,
        compact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 12) {
            HStack(alignment: .top, spacing: 8) {
                laneVisual(lane, tint: .white, size: compact ? 56 : 68)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: compact ? 22 : 26, weight: .black))
                    .foregroundStyle(.white.opacity(0.86))
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                Text(presentation.title)
                    .font(.system(size: compact ? 18 : 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                    .multilineTextAlignment(.leading)

                Text(presentation.statusLine)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(compact ? 14 : 16)
        .frame(maxWidth: .infinity, minHeight: compact ? 150 : 174, alignment: .leading)
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
                .scaleEffect(!reduceMotion && playfulPulse ? 1.06 : 1.0)
                .rotationEffect(.degrees(!reduceMotion && playfulPulse ? 2 : 0))
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
                        .offset(y: !reduceMotion && playfulPulse ? CGFloat(-index * 3) : CGFloat(index * 2))
                }
            }
            .offset(x: 16, y: 22)
        case .geometry:
            Image(systemName: "triangle.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(tint.opacity(0.24))
                .rotationEffect(.degrees(!reduceMotion && playfulPulse ? 12 : -6))
                .offset(x: 20, y: 18)
        case .physics:
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(tint.opacity(0.24))
                .offset(x: 20, y: -18)
            Circle()
                .fill(MatherTheme.warm.opacity(0.32))
                .frame(width: 16, height: 16)
                .offset(x: !reduceMotion && playfulPulse ? 24 : 10, y: !reduceMotion && playfulPulse ? 20 : 8)
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

}
