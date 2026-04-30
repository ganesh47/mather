import SwiftUI

/// The Explorer Lab — a capability playground for maths, physics, geometry, and science inquiry.
struct LabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel
    @State private var expandedLaneIDs: Set<CapabilityLaneID> = []
    @State private var expandedReviewLaneID: CapabilityLaneID?
    @State private var sensorCapabilities = DeviceSensorCapabilities.unavailable

    private let lanes = CapabilityLane.defaultExplorerLanes

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        let isCompact = Self.usesCollapsedLaneCards(for: proxy.size.width)

                        LazyVGrid(columns: labColumns(for: proxy.size.width), spacing: 16) {
                            ForEach(lanes) { lane in
                                laneCard(lane, isCompact: isCompact)
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .onAppear {
            sensorCapabilities = SensorCapabilityService().currentCapabilities()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Explorer Lab")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Pick a capability, then choose how you want to play")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text("Learn • Explore • Challenge • Timed • Review")
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

    private static func usesCollapsedLaneCards(for availableWidth: CGFloat) -> Bool {
        availableWidth < 700
    }

    private func labColumns(for availableWidth: CGFloat) -> [GridItem] {
        Self.usesCollapsedLaneCards(for: availableWidth)
            ? [GridItem(.flexible(), spacing: 16)]
            : ResponsiveLayout.labColumns(for: availableWidth)
    }

    private func laneCard(_ lane: CapabilityLane, isCompact: Bool) -> some View {
        let isExpanded = !isCompact || expandedLaneIDs.contains(lane.id)
        let progress = progress(for: lane)
        let presentation = LabLaneCardPresentation(lane: lane, progress: progress, isExpanded: isExpanded)
        let tint = laneColor(lane.id)

        return VStack(alignment: .leading, spacing: 14) {
            laneSummaryHeader(lane, presentation: presentation, tint: tint, isCompact: isCompact)

            if isExpanded {
                modeChips(lane.modes, tint: tint)
                modeChoicePreview(lane, tint: tint)
                ageEntryPreview(lane, tint: tint)
                progressPreview(progress, tint: tint)
                recallPreview(lane, tint: tint)
                if expandedReviewLaneID == lane.id {
                    recallReviewPanel(lane, tint: tint)
                }

                if lane.isReady {
                    VStack(spacing: 8) {
                        ForEach(lane.activities) { activity in
                            activityButton(activity, tint: tint)
                        }
                    }
                } else {
                    Label("Coming soon", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(MatherTheme.panel.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel("\(lane.title) coming soon")
                }
            }
        }
        .padding(isCompact ? 16 : 14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(isExpanded ? 0.22 : 0.16), lineWidth: 1)
        )
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
            radius: 8, y: 4
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(lane.accessibilityLabel)
        .accessibilityHint(isCompact && !isExpanded ? "Show details to choose activities, review cards, and sensor options." : lane.accessibilityHint)
    }

    private func laneSummaryHeader(
        _ lane: CapabilityLane,
        presentation: LabLaneCardPresentation,
        tint: Color,
        isCompact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                Text(lane.emoji)
                    .font(.system(size: isCompact ? 58 : 42))
                    .frame(width: isCompact ? 84 : 56, height: isCompact ? 84 : 56)
                    .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: isCompact ? 18 : 16, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
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
                        .lineLimit(isCompact ? 1 : 3)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard isCompact else { return }
                toggleLaneDetails(lane.id)
            }

            if isCompact {
                HStack(spacing: 10) {
                    Label(presentation.progressMicrocopy, systemImage: "chart.bar.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 8)

                    Button {
                        toggleLaneDetails(lane.id)
                    } label: {
                        Label(presentation.detailAffordanceLabel, systemImage: presentation.isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.black))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minHeight: 56)
                            .background(tint.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(presentation.detailAffordanceLabel) for \(lane.title)")
                }
            }
        }
    }

    private func modeChoicePreview(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Choose your play style", systemImage: "slider.horizontal.3")
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
            ForEach(lane.modeChoiceCards.prefix(3)) { card in
                HStack(spacing: 6) {
                    Text(card.title)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text(card.flavor)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                    Spacer(minLength: 0)
                    if card.policy.usesTimer {
                        Text("opt-in timer")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(tint)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(card.accessibilityLabel)
                .accessibilityHint(card.policy.usesTimer ? "Timer starts only after this mode is chosen." : "No timer in this mode.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(MatherTheme.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lane.title) play styles: \(lane.modeChoicePreviewLabel)")
    }

    private func ageEntryPreview(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Age entry points", systemImage: "person.2.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
            Text(lane.ageEntryPreview)
                .font(.caption2.weight(.medium))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lane.title) age entry points: \(lane.ageEntryPreview)")
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

    private func recallPreview(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(lane.recallReadinessLabel, systemImage: "rectangle.on.rectangle.angled")
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
            if !lane.starterMixMatchConceptPreview.isEmpty {
                Text(lane.starterMixMatchConceptPreview)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .lineLimit(1)
            }
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    expandedReviewLaneID = expandedReviewLaneID == lane.id ? nil : lane.id
                }
            } label: {
                Text(expandedReviewLaneID == lane.id ? "Hide review cards" : "Review cards")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minWidth: 120, minHeight: 56)
                    .background(MatherTheme.card.opacity(0.8), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Review \(lane.title) Mix-Match cards")
            .accessibilityHint(expandedReviewLaneID == lane.id ? "Hides the sample review cards." : "Shows sample cards for quick recall practice.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(lane.recallAccessibilityLabel)
    }

    private func recallReviewPanel(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Review sample")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Spacer()
                Text(lane.starterMixMatchSampler.progressLabel)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(tint)
            }

            if let entry = lane.firstRecallEntry {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    FlowLayout(spacing: 6) {
                        ForEach(entry.card.choices) { choice in
                            Button {
                                recordReviewAction(
                                    LaneRecallReviewAction(
                                        laneID: entry.laneID,
                                        cardID: entry.card.id,
                                        choiceID: choice.id,
                                        isCorrect: choice.isCorrect
                                    )
                                )
                            } label: {
                                Text(choice.answer.displayText ?? choice.answer.speechText)
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(tint)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(MatherTheme.card.opacity(0.86), in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Review \(lane.title): \(choice.answer.speechText)")
                        }
                    }
                }
                .padding(8)
                .background(MatherTheme.card.opacity(0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            ForEach(Array(lane.starterMixMatchCards.prefix(3))) { card in
                HStack(spacing: 8) {
                    Text(card.prompt)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatherTheme.ink)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(tint)
                    Text(card.match)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatherTheme.ink)
                    Spacer(minLength: 0)
                }
                .padding(8)
                .background(MatherTheme.card.opacity(0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(card.accessibilityLabel)
            }
        }
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(lane.title) recall review sample")
    }

    private func modeChips(_ modes: [PlayMode], tint: Color) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(modes, id: \.self) { mode in
                Text(mode.rawValue)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.10), in: Capsule())
            }
        }
    }

    private func activityButton(_ activity: LabActivity, tint: Color) -> some View {
        Button {
            launch(activity.id)
        } label: {
            HStack(spacing: 10) {
                Text(activity.emoji)
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(1)
                    Text(activity.tagline)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .lineLimit(2)
                    sensorAffordanceRow(activity, tint: tint)
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(MatherTheme.panel.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(activity.accessibilityLabel)
        .accessibilityHint(activity.accessibilityHint)
    }

    private func sensorAffordanceRow(_ activity: LabActivity, tint: Color) -> some View {
        FlowLayout(spacing: 4) {
            ForEach(activity.id.sensorAffordances(with: sensorCapabilities)) { affordance in
                Label {
                    Text(affordance.displayLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                } icon: {
                    Image(systemName: sensorIcon(for: affordance.need, isAvailable: affordance.isAvailable))
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(affordance.isAvailable ? tint : MatherTheme.cardSubtitle)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    (affordance.isAvailable ? tint.opacity(0.10) : MatherTheme.panel.opacity(0.72)),
                    in: Capsule()
                )
                .accessibilityLabel(affordance.accessibilityLabel)
                .accessibilityHint(affordance.accessibilityHint)
            }
        }
    }

    private func sensorIcon(for need: LabSensorNeed, isAvailable: Bool) -> String {
        if !isAvailable {
            return "exclamationmark.triangle.fill"
        }

        switch need {
        case .noSpecialSensor:
            return "hand.tap.fill"
        case .motion:
            return "gyroscope"
        case .compass:
            return "location.north.line.fill"
        case .cameraMarkerMode:
            return "camera.viewfinder"
        case .haptics:
            return "waveform"
        }
    }

    private func launch(_ activityID: LabActivityID) {
        appModel.pickProfileThenRun {
            appModel.engine.show(activityID.appRoute)
            switch activityID {
            case .sumSprint:
                appModel.sumSprintEngine.showDifficultyPick()
            case .roomQuest, .symmetryFold, .rectangleFactory, .factoryCards, .angleCannon,
                 .twoFingerProtractor, .gravityArtist, .compassAngles, .waterCycle, .memoryMatch:
                break
            }
        }
    }

    private func toggleLaneDetails(_ laneID: CapabilityLaneID) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            if expandedLaneIDs.contains(laneID) {
                expandedLaneIDs.remove(laneID)
                if expandedReviewLaneID == laneID {
                    expandedReviewLaneID = nil
                }
            } else {
                expandedLaneIDs.insert(laneID)
            }
        }
    }

    private func recordReviewAction(_ action: LaneRecallReviewAction) {
        appModel.markExplorerLabReviewedCard(laneID: action.laneID, cardID: action.cardID)
        appModel.markExplorerLabModeCompleted(laneID: action.laneID, mode: .review)

        if action.isCorrect,
           let card = CapabilityLane.defaultExplorerLanes
            .first(where: { $0.id == action.laneID })?
            .recallEntries
            .first(where: { $0.card.id == action.cardID })?
            .card {
            appModel.setExplorerLabConceptConfidence(.steady, for: card.conceptID, laneID: action.laneID)
        }
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

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        let rows = rows(in: width, subviews: subviews)
        return CGSize(width: width, height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func rows(in width: CGFloat, subviews: Subviews) -> [CGSize] {
        var rows: [CGSize] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentWidth == 0 ? size.width : currentWidth + spacing + size.width
            if currentWidth > 0, nextWidth > width {
                rows.append(CGSize(width: currentWidth, height: currentHeight))
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentWidth = nextWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if currentWidth > 0 {
            rows.append(CGSize(width: currentWidth, height: currentHeight))
        }
        return rows
    }
}
