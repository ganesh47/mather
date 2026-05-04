import SwiftUI

struct LabLaneDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel
    let laneID: CapabilityLaneID

    @State private var expandedReview = false
    @State private var expandedSupport = false
    @State private var sensorCapabilities = DeviceSensorCapabilities.unavailable

    private var lane: CapabilityLane {
        CapabilityLane.defaultExplorerLanes.first { $0.id == laneID } ?? CapabilityLane.defaultExplorerLanes[0]
    }

    private var sessionPlans: [LabConceptSessionPlan] {
        GuidedLabPath.phaseOne.first { $0.laneID == laneID }?.sessionPlans ?? []
    }

    var body: some View {
        let selectedLane = lane
        let tint = laneColor(selectedLane.id)
        let progress = progress(for: selectedLane)
        let presentation = LabLaneDetailPresentation(lane: selectedLane)

        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header(selectedLane, presentation: presentation, progress: progress, tint: tint)
                    guidedSessionSection(tint: tint)
                    gamesSection(selectedLane, tint: tint)
                    supportPanel(selectedLane, progress: progress, tint: tint)
                    researchQuestSection(selectedLane, tint: tint)
                    recallSection(selectedLane, tint: tint)
                }
                .padding(24)
            }
        }
        .onAppear {
            sensorCapabilities = SensorCapabilityService().currentCapabilities()
        }
    }

    private func header(
        _ lane: CapabilityLane,
        presentation: LabLaneDetailPresentation,
        progress: CapabilityLaneProgress,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    appModel.engine.showLab()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.black))
                        .foregroundStyle(tint)
                        .frame(width: 80, height: 80)
                        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to Explorer Lab lanes")

                Spacer(minLength: 0)

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

            HStack(alignment: .top, spacing: 14) {
                laneHeroVisual(lane, tint: tint)

                VStack(alignment: .leading, spacing: 6) {
                    Text(presentation.title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(lane.promise)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(presentation.activityCountLabel, systemImage: lane.isReady ? "gamecontroller.fill" : "sparkles")
                        .font(.caption.weight(.black))
                        .foregroundStyle(tint)
                }

                Spacer(minLength: 0)
            }

        }
        .padding(16)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08), radius: 8, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(lane.title). \(lane.promise). \(progress.progressSummaryLabel).")
    }

    private func supportPanel(_ lane: CapabilityLane, progress: CapabilityLaneProgress, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    expandedSupport.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Label("Lane details", systemImage: "slider.horizontal.3")
                        .font(.headline.weight(.black))
                        .foregroundStyle(tint)
                    Spacer(minLength: 0)
                    Image(systemName: expandedSupport ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3.weight(.black))
                        .foregroundStyle(tint)
                }
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(expandedSupport ? "Hide \(lane.title) lane details" : "Show \(lane.title) lane details")
            .accessibilityHint("Shows play styles, age entry points, and progress after the game choices.")

            if expandedSupport {
                modeChips(lane.modes, tint: tint)
                modeChoicePreview(lane, tint: tint)
                ageEntryPreview(lane, tint: tint)
                progressPreview(progress, tint: tint)
            }
        }
        .padding(14)
        .background(MatherTheme.card.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func researchQuestSection(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Research quest", systemImage: "sparkles")
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
            Text("Try one tiny experiment, notice what changed, then earn a discovery spark.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
            HStack(spacing: 10) {
                researchQuestChip(icon: "lightbulb.fill", title: "Wonder", detail: lane.promise, tint: tint)
                researchQuestChip(icon: "hand.tap.fill", title: "Try", detail: lane.isReady ? "Play a game" : "Preview ideas", tint: tint)
                researchQuestChip(icon: "star.fill", title: "Notice", detail: "Collect a spark", tint: tint)
            }
        }
        .padding(14)
        .background(MatherTheme.card.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Research quest. Try one tiny experiment, notice what changed, then earn a discovery spark.")
    }

    private func researchQuestChip(icon: String, title: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Text(detail)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func guidedSessionSection(tint: Color) -> some View {
        if !sessionPlans.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Guided path")
                            .font(.title3.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text("Learn → Remember → Play → Blast → Score")
                            .font(.caption.weight(.black))
                            .foregroundStyle(tint)
                    }
                    Spacer(minLength: 0)
                }

                ForEach(sessionPlans) { plan in
                    conceptSessionPlanCard(plan, tint: tint)
                }
            }
            .padding(14)
            .background(MatherTheme.card.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Guided path for \(lane.title).")
        }
    }

    private func conceptSessionPlanCard(_ plan: LabConceptSessionPlan, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text(plan.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(plan.masteryStateLabel) • \(plan.estimatedLength) • Next: \(plan.recommendedNextActivity)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(tint)
                }

                Spacer(minLength: 0)

                Button {
                    start(plan)
                } label: {
                    Label(plan.startAffordanceLabel, systemImage: "play.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(tint, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(plan.title)")
                .accessibilityHint("Opens the first available stage. Games remain directly playable below.")
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                ForEach(plan.stages) { stage in
                    stagePlanCard(stage, tint: tint)
                }
            }
        }
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(plan.title). \(plan.pathLabel).")
    }

    private func stagePlanCard(_ stage: LabSessionStagePlan, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(stage.stage.emoji)
                Text(stage.stage.rawValue)
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Spacer(minLength: 0)
            }
            Text(stage.title)
                .font(.caption.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Text(stage.childCopy)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
            Text(stage.timerPolicy.childCopy)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .background(MatherTheme.card.opacity(0.78), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage.accessibilityLabel)
    }

    private func gamesSection(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Games")
                .font(.title3.weight(.black))
                .foregroundStyle(MatherTheme.ink)

            if lane.isReady {
                ForEach(lane.activities) { activity in
                    activityCard(activity, lane: lane, tint: tint)
                }
            } else {
                Label("Games coming soon", systemImage: "sparkles")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                    .padding(16)
                    .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityLabel("\(lane.title) games coming soon")
            }
        }
    }

    private func activityCard(_ activity: LabActivity, lane: CapabilityLane, tint: Color) -> some View {
        Button {
            launch(activity.id)
        } label: {
            HStack(alignment: .center, spacing: 14) {
                activityVisual(activity, tint: tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.title3.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text(activity.tagline)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .lineLimit(2)
                    sensorAffordanceRow(activity, tint: tint)
                }

                Spacer(minLength: 6)

                ZStack {
                    Circle()
                        .fill(tint)
                    Image(systemName: "play.fill")
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                        .offset(x: 2)
                }
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(tint.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Launch \(activity.title). \(activity.tagline)")
        .accessibilityHint("Starts this \(lane.title) game. Modes: \(activity.modes.map(\.rawValue).joined(separator: ", ")). \(sensorAccessibilitySummary(for: activity)).")
    }

    private func recallSection(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(lane.recallReadinessLabel, systemImage: "rectangle.on.rectangle.angled")
                    .font(.headline.weight(.black))
                    .foregroundStyle(tint)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        expandedReview.toggle()
                    }
                } label: {
                    Text(expandedReview ? "Hide review" : "Review cards")
                        .font(.caption.weight(.black))
                        .foregroundStyle(tint)
                        .frame(minWidth: 140, minHeight: 80)
                        .background(tint.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(expandedReview ? "Hide \(lane.title) review cards" : "Open \(lane.title) review cards")
            }

            if expandedReview {
                if !lane.starterMixMatchConceptPreview.isEmpty {
                    Text(lane.starterMixMatchConceptPreview)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }

                recallReviewPanel(lane, tint: tint)
            }
        }
        .padding(14)
        .background(MatherTheme.card.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(lane.recallAccessibilityLabel)
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

    private func progressBar(_ progress: CapabilityLaneProgress, tint: Color) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MatherTheme.panel.opacity(0.8))
                Capsule()
                    .fill(tint.opacity(0.72))
                    .frame(width: max(12, proxy.size.width * progress.masteryFraction))
            }
        }
        .frame(height: 10)
        .accessibilityLabel("Lane mastery \(progress.masteryPercentLabel)")
    }

    private func recallReviewPanel(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let entry = lane.firstRecallEntry {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    LabDetailFlowLayout(spacing: 6) {
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

            ForEach(Array(lane.starterMixMatchCards.prefix(4))) { card in
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
        LabDetailFlowLayout(spacing: 6) {
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

    private func sensorAffordanceRow(_ activity: LabActivity, tint: Color) -> some View {
        LabDetailFlowLayout(spacing: 4) {
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

    private func sensorAccessibilitySummary(for activity: LabActivity) -> String {
        activity.id
            .sensorAffordances(with: sensorCapabilities)
            .map(\.displayLabel)
            .joined(separator: ". ")
    }

    private func laneHeroVisual(_ lane: CapabilityLane, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.14))
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 54, height: 54)
                .offset(x: 22, y: -18)
            Text(lane.emoji)
                .font(.system(size: 42))
        }
        .frame(width: 76, height: 76)
    }

    private func activityVisual(_ activity: LabActivity, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.12))
            visualMotif(for: activity.id, tint: tint)
            Text(activity.emoji)
                .font(.system(size: 38))
                .offset(x: -18, y: -14)
        }
        .frame(width: 104, height: 96)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func visualMotif(for activityID: LabActivityID, tint: Color) -> some View {
        switch activityID {
        case .sumSprint:
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(tint.opacity(0.18 + Double(index) * 0.08))
                        .frame(width: 8, height: CGFloat(24 + index * 10))
                }
            }
            .offset(x: 18, y: 12)
        case .roomQuest, .compassAngles:
            Image(systemName: "location.north.line.fill")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .shapeGeometry, .symmetryFold, .twoFingerProtractor:
            Image(systemName: "angle")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 18, y: 12)
        case .rectangleFactory, .factoryCards:
            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                ForEach(0..<2, id: \.self) { _ in
                    GridRow {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tint.opacity(0.28))
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .offset(x: 20, y: 12)
        case .angleCannon, .gravityArtist:
            Image(systemName: "circle.dotted")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .waterCycle:
            Image(systemName: "cloud.rain.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .soundVolume:
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .memoryMatch, .countryCards, .fruitCards:
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
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

    private func start(_ plan: LabConceptSessionPlan) {
        guard let route = plan.startRoute else { return }
        appModel.pickProfileThenRun {
            if plan.id == LabConceptSessionPlan.numbersNumberBondsTo10.id {
                appModel.engine.updateConfig(problemCount: 4, minTarget: 1, maxTarget: 10)
            }
            appModel.engine.show(route)
            if route == .sumSprint {
                appModel.sumSprintEngine.showDifficultyPick()
            }
        }
    }

    private func launch(_ activityID: LabActivityID) {
        appModel.pickProfileThenRun {
            appModel.engine.show(route(for: activityID, laneID: lane.id))
            switch activityID {
            case .sumSprint:
                appModel.sumSprintEngine.showDifficultyPick()
            case .roomQuest, .symmetryFold, .rectangleFactory, .factoryCards, .angleCannon,
                 .twoFingerProtractor, .gravityArtist, .compassAngles, .shapeGeometry, .waterCycle, .soundVolume, .memoryMatch, .countryCards, .fruitCards:
                break
            }
        }
    }

    private func route(for activityID: LabActivityID, laneID: CapabilityLaneID) -> AppRoute {
        guard activityID == .memoryMatch else { return activityID.appRoute }
        switch laneID {
        case .chemistry:
            return .gameplayThread(.fruits)
        case .mapWorld:
            return .gameplayThread(.countries)
        default:
            return .memory
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

private struct LabDetailFlowLayout: Layout {
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
