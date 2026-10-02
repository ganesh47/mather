import SwiftUI

struct LabLaneDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel
    let laneID: CapabilityLaneID

    @State private var expandedReview = false
    @State private var expandedSupport = false
    @State private var expandedPlanDetails: Set<String> = []
    @State private var sensorCapabilities = DeviceSensorCapabilities.unavailable

    private var lane: CapabilityLane {
        CapabilityLane.defaultExplorerLanes.first { $0.id == laneID } ?? CapabilityLane.defaultExplorerLanes[0]
    }

    private var sessionPlans: [LabConceptSessionPlan] {
        GuidedLabPath.phaseOne.first { $0.laneID == laneID }?.sessionPlans ?? []
    }

    var body: some View {
        let selectedLane = lane
        let tint = selectedLane.id.themeColor
        let progress = progress(for: selectedLane)
        let presentation = LabLaneDetailPresentation(lane: selectedLane)

        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header(selectedLane, presentation: presentation, progress: progress, tint: tint)
                    pilotQuestSection(tint: tint)
                    moreTopicCards
                    guidedSessionSection(tint: tint)
                    gamesSection(selectedLane, tint: tint)
                    supportPanel(selectedLane, progress: progress, tint: tint)
                    recallSection(selectedLane, tint: tint)
                }
                .padding(24)
                .safeAreaPadding(.top, 12)
                .safeAreaPadding(.bottom, 24)
            }
        }
        .onAppear {
            sensorCapabilities = SensorCapabilityService().currentCapabilities()
            appModel.laneRecallReviewEngine.beginVisit(laneID)
        }
        .onDisappear { appModel.laneRecallReviewEngine.finishVisit(title: "\(lane.title) review") }
        .onChange(of: appModel.profileStore.activeProfileId) { _, _ in appModel.laneRecallReviewEngine.beginVisit(laneID) }
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
        .accessibilityLabel("\(lane.title). \(lane.promise). \(presentation.activityCountLabel). \(progress.progressSummaryLabel).")
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

    @ViewBuilder
    private func pilotQuestSection(tint: Color) -> some View {
        let quests = LearningQuestID.pilots.filter { $0.laneID == laneID }
        if !quests.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tiny quests").font(.title3.bold()).foregroundStyle(MatherTheme.ink)
                ForEach(quests) { quest in
                    Button { appModel.launchLearningQuest(quest, returnLaneID: laneID) } label: {
                        HStack { Text(quest.emoji).font(.largeTitle); Text(quest.title).font(.headline.bold()); Spacer(); Image(systemName: "play.circle.fill") }
                            .foregroundStyle(tint).padding(16).frame(maxWidth: .infinity, minHeight: 80)
                            .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain).accessibilityIdentifier("lab-quest-\(quest.rawValue)")
                }
            }
        }
    }

    @ViewBuilder
    private func guidedSessionSection(tint: Color) -> some View {
        if !sessionPlans.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Guided path")
                    .font(.title3.weight(.black))
                    .foregroundStyle(MatherTheme.ink)

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
        let progress = appModel.labConceptSessionProgressStore.progress(for: plan)
        let detailsExpanded = expandedPlanDetails.contains(plan.id)
        let presentation = plan.cardPresentation

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: presentation.symbolName)
                    .font(.title2.weight(.black))
                    .foregroundStyle(tint)
                    .frame(width: 56, height: 56)
                    .background(MatherTheme.card.opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)

                Text(presentation.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button {
                    start(plan)
                } label: {
                    Label(visibleStartLabel(for: plan), systemImage: appModel.labConceptSessionProgressStore.hasProgress(for: plan) ? "arrow.clockwise.circle.fill" : "play.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .frame(minWidth: 92, minHeight: 80)
                        .background(tint, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(startLabel(for: plan)) \(plan.title)")
                .accessibilityHint("This is the primary next action for the guided path. Games remain directly playable below.")
                .accessibilityIdentifier("guided-plan-action-\(plan.id)")
            }

            if let progress {
                Label(progress.resumeCopy, systemImage: "bookmark.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint)
                    .accessibilityLabel("Resume \(plan.title). \(progress.resumeCopy).")
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    if detailsExpanded {
                        expandedPlanDetails.remove(plan.id)
                    } else {
                        expandedPlanDetails.insert(plan.id)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Label(detailsExpanded ? "Hide path details" : "Show path details", systemImage: detailsExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(tint)
                    Spacer(minLength: 0)
                }
                .padding(9)
                .background(MatherTheme.card.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(detailsExpanded ? "Hide guided path details" : "Show guided path details")

            if detailsExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(presentation.hiddenDetailAccessibilityLabel)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                    ForEach(plan.stages) { stage in
                        stagePlanCard(stage, progress: progress, tint: tint)
                    }
                }
            }
        }
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(presentation.hiddenDetailAccessibilityLabel) Primary action: \(startLabel(for: plan)).")
        .accessibilityIdentifier("guided-plan-card-\(plan.id)")
    }

    private func stagePlanCard(_ stage: LabSessionStagePlan, progress: LabConceptSessionProgress?, tint: Color) -> some View {
        let state = progressState(for: stage.stage, progress: progress)
        return VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: stage.stage.symbolName)
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint)
                Text(stage.stage.childTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Spacer(minLength: 0)
            }

            Text(stage.title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(2)

            Text(stage.childCopy)
                .font(.caption)
                .foregroundStyle(MatherTheme.cardSubtitle)
                .lineLimit(3)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatherTheme.card.opacity(0.76), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if stage.route != nil {
                Image(systemName: "arrow.up.forward.circle.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint.opacity(0.82))
                    .padding(8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage.accessibilityLabel(withProgressState: state))
    }

    private func gamesSection(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Games")
                .font(.title3.weight(.black))
                .foregroundStyle(MatherTheme.ink)

            if lane.isReady {
                LazyVGrid(columns: gameLauncherColumns, spacing: 12) {
                    ForEach(lane.activities) { activity in
                        activityCard(activity, lane: lane, tint: tint)
                    }
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
        GameActivityCard(
            activity: activity,
            tint: tint,
            canLaunch: activity.id.canDirectLaunch(with: sensorCapabilities),
            layoutMode: .grid,
            sensorCapabilities: sensorCapabilities
        ) {
            launch(activity.id)
        }
    }

    private var gameLauncherColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 132, maximum: 220), spacing: 12)]
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
                    if expandedReview, let entry = lane.firstRecallEntry { appModel.laneRecallReviewEngine.speakPrompt(entry.card) }
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
        .accessibilityLabel("Lane exploration \(progress.masteryPercentLabel)")
    }

    private func recallReviewPanel(_ lane: CapabilityLane, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let entry = lane.firstRecallEntry {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let asset = entry.card.prompt.assetName {
                        LearningContentImage(name: asset).scaledToFit().frame(maxHeight: 130)
                    }
                    Button { appModel.laneRecallReviewEngine.speakPrompt(entry.card) } label: {
                        Label("Listen", systemImage: "speaker.wave.2.fill").frame(minWidth: 80, minHeight: 80)
                    }.buttonStyle(.plain)
                    LabDetailFlowLayout(spacing: 12) {
                        ForEach(entry.card.choices) { choice in
                            Button { appModel.laneRecallReviewEngine.select(choice.id, card: entry.card) } label: {
                                Text(choice.answer.displayText ?? choice.answer.speechText)
                                    .font(.headline.bold()).foregroundStyle(tint)
                                    .frame(minWidth: 80, minHeight: 80).padding(.horizontal, 12)
                                    .background(appModel.laneRecallReviewEngine.selectedChoices[entry.card.id] == choice.id ? tint.opacity(0.22) : MatherTheme.card, in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain).disabled(appModel.laneRecallReviewEngine.completedCards.contains(entry.card.id))
                                .accessibilityLabel("Listen and choose: \(choice.answer.speechText)")
                                .accessibilityIdentifier("lane-review-choice-\(choice.id)")
                        }
                    }
                    HStack {
                        Button { appModel.laneRecallReviewEngine.help(entry.card) } label: { Label("Help", systemImage: "hand.raised.fill").frame(minWidth: 80, minHeight: 80) }.buttonStyle(.plain).disabled(appModel.laneRecallReviewEngine.completedCards.contains(entry.card.id))
                        Button { submitReview(entry) } label: {
                            Label(appModel.laneRecallReviewEngine.completedCards.contains(entry.card.id) ? "Done" : "Check", systemImage: "checkmark.circle.fill").font(.headline.bold()).frame(maxWidth: .infinity, minHeight: 80)
                        }.buttonStyle(.plain)
                            .disabled(appModel.laneRecallReviewEngine.selectedChoices[entry.card.id] == nil || appModel.laneRecallReviewEngine.completedCards.contains(entry.card.id))
                            .accessibilityIdentifier("lane-review-check")
                    }
                    if let feedback = appModel.laneRecallReviewEngine.feedback[entry.card.id] { Text(feedback).font(.headline).foregroundStyle(tint) }

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
        .accessibilityLabel("Lab artwork for \(lane.title)")
    }

    @ViewBuilder private var moreTopicCards: some View {
        let threads: [GameplayThreadID] = switch lane.id { case .geometry: [.shapes]; case .physics: [.waterCycle]; case .electronics: [.electronics]; default: [] }
        if !threads.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("More topic cards").font(.title3.bold()).foregroundStyle(MatherTheme.ink)
                ForEach(threads, id: \.self) { thread in
                    Button {
                        appModel.pickProfileThenRun { appModel.engine.showGameplayThread(thread, returnRoute: .labLane(lane.id)) }
                    } label: {
                        Label("Explore \(appModel.iosLearningContentStore.catalog.thread(for: thread).title)", systemImage: "rectangle.stack.fill")
                            .font(.headline).frame(maxWidth: .infinity, minHeight: 80).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain).accessibilityIdentifier("lane-more-cards-\(thread.rawValue)")
                }
            }
        }
    }

    private func startLabel(for plan: LabConceptSessionPlan) -> String {
        if appModel.labConceptSessionProgressStore.progress(for: plan)?.completedStages.count == plan.stages.count { return "Play again" }
        return appModel.labConceptSessionProgressStore.resumeLabel(for: plan)
    }

    private func visibleStartLabel(for plan: LabConceptSessionPlan) -> String {
        if appModel.labConceptSessionProgressStore.progress(for: plan)?.completedStages.count == plan.stages.count { return "Play again" }
        return appModel.labConceptSessionProgressStore.hasProgress(for: plan)
            ? plan.continueAffordanceLabel
            : plan.startAffordanceLabel
    }

    private func progressState(for stage: GuidedLabStage, progress: LabConceptSessionProgress?) -> String? {
        guard let progress else { return nil }
        if progress.completedStages.contains(stage) { return "Done" }
        if progress.currentStage == stage { return "Resume" }
        return nil
    }

    private func start(_ plan: LabConceptSessionPlan) {
        guard let quest = LearningQuestID.guided(plan.id) else { return }
        appModel.launchLearningQuest(quest, guidedPlanID: plan.id, returnLaneID: plan.laneID)
    }

    private func launch(_ activityID: LabActivityID) {
        if let quest = activityID.pilotQuest {
            appModel.launchLearningQuest(quest, returnLaneID: lane.id); return
        }
        appModel.pickProfileThenRun {
            appModel.clearLabGameplayCompletion()
            let activityRoute = route(for: activityID, laneID: lane.id)
            showActivityRoute(activityRoute, returnLaneID: lane.id)
            switch activityID {
            case .sumSprint:
                appModel.sumSprintEngine.showDifficultyPick()
            case .roomQuest, .symmetryFold, .rectangleFactory, .factoryCards, .angleCannon,
                 .twoFingerProtractor, .gravityArtist, .compassAngles, .shapeGeometry, .waterCycle, .soundVolume, .memoryMatch, .countryCards, .worldAnimalCards, .worldBirdCards, .fruitCards, .circuitSpark:
                break
            }
        }
    }

    private func showActivityRoute(_ route: AppRoute, returnLaneID: CapabilityLaneID) {
        if case let .gameplayThread(threadID) = route {
            appModel.engine.showGameplayThread(threadID, returnRoute: .labLane(returnLaneID))
        } else {
            appModel.engine.showActivity(route, returnRoute: .labLane(returnLaneID))
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

    private func submitReview(_ entry: LaneRecallEntry) {
        guard let attempt = appModel.laneRecallReviewEngine.submit(entry.card) else { return }
        appModel.markExplorerLabReviewedCard(laneID: entry.laneID, cardID: entry.card.id)
        if attempt.outcome == .independentCorrect || attempt.outcome == .supportedCorrect {
            appModel.markExplorerLabModeCompleted(laneID: entry.laneID, mode: .review)
        }
    }

}
