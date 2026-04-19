import SwiftUI

/// Top-level coordinator for a Room Quest session.
/// Routes between all `RoomPhase` states — from safety acknowledgement through
/// room phase to on-screen CPA stages and completion.
struct RoomSessionView: View {
    @Bindable var engine: RoomQuestEngine
    let vsEngine: VerticalSliceEngine

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            phaseContent
        }
        .overlay(alignment: .topTrailing) {
            sessionChromeOverlay
        }
        .onAppear { engine.startSession() }
    }

    /// Home / Pause chrome buttons overlaid on top of phases that don't manage their own chrome.
    @ViewBuilder
    private var sessionChromeOverlay: some View {
        switch engine.phase {

        case .safetyAck:
            // Parent-only screen — Home only (can't pause, session barely started)
            roomLightChromeButton(title: "Home", systemImage: "house.circle.fill", accessibilityID: "room-home-safetyack") {
                engine.onExitToHome?()
            }
            .padding(24)

        case .setup, .onScreenPictorial, .onScreenAbstract, .onScreenTransfer:
            HStack(spacing: 12) {
                roomLightChromeButton(title: "Pause", systemImage: "pause.circle.fill", accessibilityID: "room-pause-session") {
                    engine.pauseSession()
                }
                roomLightChromeButton(title: "Home", systemImage: "house.circle.fill", accessibilityID: "room-home-session") {
                    engine.abandonSession(reason: "parent_home")
                }
            }
            .padding(24)

        case .paused:
            roomLightChromeButton(title: "Home", systemImage: "house.circle.fill", accessibilityID: "room-home-paused") {
                engine.abandonSession(reason: "parent_home")
            }
            .padding(24)

        case .spot, .returning, .complete:
            // These views manage their own chrome buttons
            EmptyView()
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch engine.phase {
        case .safetyAck:
            SafetyAckView(engine: engine)

        case .setup:
            RoomSetupView(engine: engine)

        case .spot(let idx):
            SpotPromptView(engine: engine, spotIndex: idx)

        case .returning:
            ReturningView(engine: engine)

        case .onScreenPictorial:
            onScreenPictorialView

        case .onScreenAbstract:
            onScreenAbstractView

        case .onScreenTransfer:
            onScreenTransferView

        case .paused(let resumeTo):
            RoomPausedView(engine: engine, resumingTo: resumeTo)

        case .complete:
            RoomCompleteView(engine: engine, vsEngine: vsEngine)
        }
    }

    // MARK: - On-screen CPA views (reuse VS1 views)

    @ViewBuilder
    private var onScreenPictorialView: some View {
        if let p = engine.problem {
            ScrollView {
                VStack(spacing: 20) {
                    FeedbackBannerView(message: engine.feedbackMessage, isCelebrating: engine.showCelebration)
                    SplitView(
                        target: p.target,
                        leftCount: engine.splitLeftCount,
                        onAdjust: { _ in },     // read-only — split determined by room phase
                        onSubmit: { engine.submitPictorial() },
                        isLocked: true
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private var onScreenAbstractView: some View {
        if let p = engine.problem {
            ScrollView {
                VStack(spacing: 20) {
                    FeedbackBannerView(message: engine.feedbackMessage, isCelebrating: engine.showCelebration)
                    EquationResolveView(
                        target: p.target,
                        leftInput: engine.equationLeftInput,
                        rightInput: engine.equationRightInput,
                        onAppend: { digit, side in
                            switch side {
                            case .left:
                                engine.equationLeftInput = appendDigit(to: engine.equationLeftInput, digit: digit)
                            case .right:
                                engine.equationRightInput = appendDigit(to: engine.equationRightInput, digit: digit)
                            }
                        },
                        onClear: { side in
                            switch side {
                            case .left: engine.equationLeftInput = ""
                            case .right: engine.equationRightInput = ""
                            }
                        },
                        onSubmit: { engine.submitAbstract() }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private var onScreenTransferView: some View {
        if let p = engine.problem {
            ScrollView {
                VStack(spacing: 20) {
                    FeedbackBannerView(message: engine.feedbackMessage, isCelebrating: engine.showCelebration)
                    TransferCheckView(
                        problem: p,
                        leftCount: engine.transferLeftCount,
                        rightCount: engine.transferRightCount,
                        onAdjust: { delta, side in
                            switch side {
                            case .left:
                                let next = engine.transferLeftCount + delta
                                if next >= 0 && next <= p.target { engine.transferLeftCount = next }
                            case .right:
                                let next = engine.transferRightCount + delta
                                if next >= 0 && next <= p.target { engine.transferRightCount = next }
                            }
                        },
                        onSubmit: { engine.submitTransfer() }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Helpers

private func appendDigit(to string: String, digit: Int) -> String {
    let candidate = (string + String(digit)).prefix(2)
    let numeric = Int(candidate) ?? 0
    return numeric > 10 ? string : String(candidate)
}

// MARK: - Inline sub-views

/// One-time parent safety acknowledgement — shown before the first Room Quest session.
private struct SafetyAckView: View {
    @Bindable var engine: RoomQuestEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before you start")
                        .font(.largeTitle.weight(.black))
                    Text("Read this once before your first Room Quest session. It only appears once.")
                        .font(.subheadline)
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                CardSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Safety checklist", systemImage: "checklist")
                            .font(.headline.weight(.semibold))
                        safetyItem("Both spot-cards in the same room as this iPad")
                        safetyItem("Spots are away from stairs, windows, and balconies")
                        safetyItem("Spots are away from the kitchen")
                        safetyItem("A parent stays nearby during the room phase")
                        safetyItem("Nothing in the activity rewards running or jumping")
                    }
                }

                Button("I understand — let's go") {
                    engine.acknowledgedSafety()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
            .padding(24)
        }
    }

    private func safetyItem(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(MatherTheme.ink)
    }
}

/// Screen shown while child walks back to the iPad after collecting from both spots.
private struct ReturningView: View {
    @Bindable var engine: RoomQuestEngine

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MatherTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("Bring them back!")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let p = engine.problem {
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(MatherTheme.accent)
                        VStack(spacing: 4) {
                            Text("\(p.target)")
                                .font(.system(size: 80, weight: .black, design: .rounded))
                                .foregroundStyle(MatherTheme.accent)
                            Text(p.target == 1 ? "token" : "tokens")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(MatherTheme.ink.opacity(0.7))
                        }
                    }
                } else {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(MatherTheme.accent)
                }

                Spacer()

                Button("We're back!") {
                    engine.markReturned()
                }
                .accessibilityIdentifier("room-return-confirm-button")
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }

            // Pause always accessible
            HStack(spacing: 12) {
                roomReturningChromeButton(title: "Pause", systemImage: "pause.circle.fill", accessibilityID: "room-pause-button-returning") {
                    engine.pauseSession()
                }

                roomReturningChromeButton(title: "Home", systemImage: "house.circle.fill", accessibilityID: "room-home-button-returning") {
                    engine.onExitToHome?()
                }
            }
            .padding(24)
        }
    }
}

/// Chrome button for light-background Room Quest screens (dark ink, white pill).
/// Used for Safety Ack, Setup, CPA phases, and Paused screen.
private func roomLightChromeButton(title: String, systemImage: String, accessibilityID: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Label(title, systemImage: systemImage)
            .font(.title2.weight(.semibold))
            .foregroundStyle(MatherTheme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.black.opacity(0.06), in: Capsule())
    }
    .accessibilityIdentifier(accessibilityID)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
}

/// Hard pause screen — resume or abandon.
private func roomReturningChromeButton(title: String, systemImage: String, accessibilityID: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Label(title, systemImage: systemImage)
            .font(.title2.weight(.semibold))
            .foregroundStyle(MatherTheme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white.opacity(0.9), in: Capsule())
    }
    .accessibilityIdentifier(accessibilityID)
    .accessibilityLabel(accessibilityID)
    .accessibilityAddTraits(.isButton)
}

private struct RoomPausedView: View {
    @Bindable var engine: RoomQuestEngine
    let resumingTo: RoomPhase

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "pause.circle")
                .font(.system(size: 72))
                .foregroundStyle(MatherTheme.accent)

            Text("Paused")
                .font(.system(size: 42, weight: .black, design: .rounded))

            Text(engine.feedbackMessage)
                .font(.headline)
                .foregroundStyle(MatherTheme.cardSubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                Button("Resume") {
                    engine.resumeSession()
                }
                .buttonStyle(PrimaryActionButtonStyle())

                Button("End session & go home") {
                    engine.abandonSession(reason: "parent_abort")
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.danger.opacity(0.45)))
                .foregroundStyle(MatherTheme.danger)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

/// Session complete screen — shows feedback and routes back to Home.
private struct RoomCompleteView: View {
    @Bindable var engine: RoomQuestEngine
    let vsEngine: VerticalSliceEngine

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(MatherTheme.accent)

            Text(engine.feedbackMessage)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button("Done") {
                vsEngine.showHome()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
