import SwiftUI

/// The Explorer Lab — a capability playground for maths, physics, geometry, and science inquiry.
struct LabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel
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

                        LazyVGrid(columns: ResponsiveLayout.labColumns(for: proxy.size.width), spacing: 16) {
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
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Home")
        }
    }

    private func laneCard(_ lane: CapabilityLane) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(lane.emoji)
                    .font(.system(size: 42))
                    .frame(width: 56, height: 56)
                    .background(laneColor(lane.id).opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(lane.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(lane.ageBandHint)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(laneColor(lane.id))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(laneColor(lane.id).opacity(0.12), in: Capsule())
                    }
                    Text(lane.promise)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            modeChips(lane.modes, tint: laneColor(lane.id))
            modeChoicePreview(lane, tint: laneColor(lane.id))
            ageEntryPreview(lane, tint: laneColor(lane.id))
            progressPreview(progress(for: lane), tint: laneColor(lane.id))
            recallPreview(lane, tint: laneColor(lane.id))
            if expandedReviewLaneID == lane.id {
                mixMatchSampler(lane, tint: laneColor(lane.id))
            }

            if lane.isReady {
                VStack(spacing: 8) {
                    ForEach(lane.activities) { activity in
                        activityButton(activity, tint: laneColor(lane.id))
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(laneColor(lane.id).opacity(0.18), lineWidth: 1)
        )
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
            radius: 8, y: 4
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(lane.title)
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
                    .padding(.vertical, 6)
                    .background(MatherTheme.card.opacity(0.8), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Review \(lane.title) Mix-Match cards")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func mixMatchSampler(_ lane: CapabilityLane, tint: Color) -> some View {
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
            }
        }
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(lane.title) Mix-Match review sample")
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
            .background(MatherTheme.panel.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(activity.title)
        .accessibilityHint(activity.modes.map(\.rawValue).joined(separator: ", "))
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
