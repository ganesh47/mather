import SwiftUI
import UIKit

/// Parent-controlled entry point. The caller chooses a LOCAL learner before presenting it.
@MainActor
struct LearningCompanionView: View {
    private let profileID: String
    private let displayName: String
    private let audioEnabled: Bool
    private let onClose: (() -> Void)?
    @Bindable private var store: LearningHandoffStore
    @State private var codeInput = ""
    @State private var parentConfirmed = false
    @State private var review: Review?
    @State private var message = ""
    @State private var exportCode: String?
    @State private var showingMission = false
    @State private var showingPicture = false
    @State private var deletion: Deletion?
    @State private var showingDeletionConfirmation = false
    @State private var speech = SpeechService()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    private struct Review {
        let payload: LearningHandoffPayload
        let sourceCode: String?
        let replacingReceiptID: UUID?
    }
    private enum Deletion: String, Identifiable {
        case unlink, learnerData, allData
        var id: String { rawValue }
    }

    init(profileID: String, displayName: String, store: LearningHandoffStore = .init(), audioEnabled: Bool = true, onClose: (() -> Void)? = nil) {
        self.profileID = profileID
        self.displayName = displayName
        self.store = store
        self.audioEnabled = audioEnabled
        self.onClose = onClose
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(showingMission ? "Room Quest companion" : "Continue an idea")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Local recipient: \(displayName)")
                    .font(.title2.bold())
                    .accessibilityIdentifier("companion-recipient")
                action("Done", id: "companion-close", perform: close)
                if showingMission, let current = store.assignment(profileID: profileID) {
                    mission(current)
                } else {
                    parentControls
                }
                if !message.isEmpty {
                    Text(message).font(.headline)
                        .accessibilityIdentifier("companion-message")
                }
            }
            .frame(maxWidth: contentWidth, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
        }
        .background(backgroundColor)
        .onChange(of: profileID) { _, _ in clearTransientState() }
        .onChange(of: store.assignment(profileID: profileID)?.payload.receiptID) { _, _ in
            showingPicture = false
            exportCode = nil
            speech.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { speech.stop(); parentConfirmed = false; review = nil; showingMission = false; exportCode = nil }
        }
        .onChange(of: audioEnabled) { _, enabled in if !enabled { speech.stop() } }
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIAccessibility.voiceOverStatusDidChangeNotification) {
                if UIAccessibility.isVoiceOverRunning { speech.stop() }
            }
        }
        .onDisappear { speech.stop() }
        .confirmationDialog("Parent: confirm local deletion", isPresented: $showingDeletionConfirmation, titleVisibility: .visible, presenting: deletion) { choice in
            Button("Confirm deletion", role: .destructive) { performDeletion(choice) }
            Button("Cancel", role: .cancel) { deletion = nil }
        } message: { choice in
            Text(deletionMessage(choice))
        }
        #if os(tvOS)
        .onExitCommand {
            speech.stop()
            if showingMission { showingMission = false; parentConfirmed = false }
            else if review != nil || exportCode != nil { review = nil; exportCode = nil }
            else { close() }
        }
        #endif
    }

    private var parentControls: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Parent-controlled manual mission continuation. Choose the local learner before entering this screen. This code carries a mission, not learner history or test results.")
            Text("Both devices work offline. A code check catches typing mistakes; it does not verify who created the code. Review the mission yourself.")
                .font(.subheadline)
            if let error = store.storageError {
                Text(error.localizedDescription).foregroundStyle(.red)
            } else {
                Toggle("I am the parent and I chose \(displayName) on this device", isOn: $parentConfirmed)
                    .frame(minHeight: 80)
                    .accessibilityIdentifier("companion-parent-confirmation")
                    .onChange(of: parentConfirmed) { _, value in
                        if !value { review = nil; exportCode = nil }
                    }
                if let review {
                    reviewControls(review)
                } else {
                    if let current = store.assignment(profileID: profileID) {
                        Text("Current mission: \(current.payload.title)").font(.title3.bold())
                        action("Parent: start the physical mission", id: "companion-start") {
                            guard parentConfirmed else { report(LearningHandoffError.parentApprovalRequired); return }
                            showingMission = true
                            showingPicture = false
                            speak(current.payload.safetyPrompt + " " + current.payload.childPrompt)
                        }
                        action("Parent: show code for another device", id: "companion-export") {
                            perform {
                                exportCode = try store.exportCode(profileID: profileID, parentApproved: parentConfirmed)
                            }
                        }
                    }
                    if let exportCode { exportControls(exportCode) }
                    Text("Prepare a safe mission here").font(.title3.bold())
                    HStack {
                        action("Build 5", id: "companion-build-5") { prepare(target: 5) }
                        action("Build 10", id: "companion-build-10") { prepare(target: 10) }
                    }
                    Text("Receive a mission from another device").font(.title3.bold())
                    codeField
                    action("Parent: review entered code", id: "companion-review-code") {
                        perform {
                            guard parentConfirmed else { throw LearningHandoffError.parentApprovalRequired }
                            review = Review(payload: try store.preview(code: codeInput), sourceCode: codeInput,
                                            replacingReceiptID: store.assignment(profileID: profileID)?.payload.receiptID)
                            exportCode = nil
                        }
                    }
                    Text("On Apple TV, select the code field to open the TV keyboard. Enter six groups of six symbols. Spaces and dashes are optional. A paired remote keyboard can also type the code.")
                        .font(.subheadline)
                }
            }
            deletionControls
        }
    }

    private var codeField: some View {
        TextField("Mission code: six groups of six", text: $codeInput)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .font(.system(.body, design: .monospaced))
            .padding(16)
            .frame(minHeight: 80)
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("Enter 36-symbol mission code")
            .accessibilityIdentifier("companion-code-field")
            .onChange(of: codeInput) { _, _ in review = nil }
    }

    private func reviewControls(_ pending: Review) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Parent review for \(displayName)").font(.title2.bold())
            Text(pending.payload.title).font(.title3.bold())
            Text("Two groups: \(pending.payload.firstGroup) and \(pending.payload.secondGroup). Mission content version 1.")
            Text(pending.payload.safetyPrompt)
            Text("No source learner identity is carried. Approving assigns this idea only to \(displayName) on this device.")
            if pending.replacingReceiptID != nil {
                Text("This will replace this learner's current mission. Any saved parent observations stay local.")
            }
            action(pending.replacingReceiptID == nil ? "Parent: approve this mission" : "Parent: replace current mission", id: "companion-approve") {
                perform {
                    if let source = pending.sourceCode {
                        try store.approveImport(code: source, recipientProfileID: profileID, parentApproved: parentConfirmed,
                                                replacingReceiptID: pending.replacingReceiptID)
                    } else {
                        try store.createMission(profileID: profileID, target: pending.payload.target, parentApproved: parentConfirmed,
                                                replacingReceiptID: pending.replacingReceiptID)
                    }
                    review = nil
                    codeInput = ""
                    exportCode = nil
                    message = "Mission approved for \(displayName) on this device. No history or results were imported."
                }
            }
            action("Cancel review", id: "companion-cancel-review") { review = nil; message = "" }
        }
    }

    private func exportControls(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parent: type this code on the other device").font(.headline)
            ForEach(Array(code.split(separator: "-").enumerated()), id: \.offset) { index, group in
                Text("\(index + 1).  \(group)")
                    .font(.system(.title2, design: .monospaced).bold())
                    .accessibilityLabel("Group \(index + 1): " + group.map(String.init).joined(separator: ", "))
                    .accessibilityIdentifier("companion-code-group-\(index + 1)")
            }
            Text("36 symbols, with a typing checksum. The other parent must choose a local learner and approve. No automatic transfer happens.")
                .font(.subheadline)
            #if !os(tvOS)
            Text(code).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                .accessibilityIdentifier("companion-export-code")
            ShareLink(item: code) {
                Label("Parent: share mission code", systemImage: "square.and.arrow.up")
                    .frame(minHeight: 80)
            }.buttonStyle(.bordered)
            #endif
            action("Hide code", id: "companion-hide-code") { exportCode = nil }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }

    private func mission(_ current: LearningHandoffAssignment) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(current.payload.title).font(.title.bold())
            Text(current.payload.safetyPrompt).font(.headline)
            Text(current.payload.childPrompt).font(.title3)
            action("Listen again", id: "companion-repeat-prompt") {
                speak(current.payload.safetyPrompt + " " + current.payload.childPrompt)
            }
            if showingPicture {
                VStack(alignment: .leading, spacing: 16) {
                    groupPicture(count: current.payload.firstGroup, color: .blue)
                    groupPicture(count: current.payload.secondGroup, color: .orange)
                    Text("\(current.payload.firstGroup) + \(current.payload.secondGroup) = \(current.payload.target)")
                        .font(.title.bold())
                        .accessibilityLabel("\(current.payload.firstGroup) plus \(current.payload.secondGroup) equals \(current.payload.target). Example only, not a test.")
                }
                Text("Picture example after object play. This screen does not score the child.").font(.subheadline)
            } else {
                action("Parent: show a group picture after object play", id: "companion-show-picture") {
                    showingPicture = true
                    speak("Here are two groups. \(current.payload.firstGroup) and \(current.payload.secondGroup) make \(current.payload.target). Moving the groups does not change how many we have.")
                }
            }
            Text("Parent observation").font(.title2.bold())
            Text(current.payload.parentObservationPrompt)
            if let observation = store.observation(profileID: profileID, receiptID: current.payload.receiptID) {
                Text("Parent reported: \(observation.outcome.title). \(observation.helpDescription).")
                    .font(.headline)
                    .accessibilityIdentifier("companion-observation")
            } else {
                Text("Nothing reported yet. Assistance is unknown. App performance: not measured.").font(.subheadline)
                ForEach(ParentRoomQuestOutcome.allCases, id: \.rawValue) { outcome in
                    action("Parent reports: \(outcome.title)", id: "companion-report-\(outcome.rawValue)") {
                        perform {
                            try store.recordObservation(profileID: profileID, receiptID: current.payload.receiptID,
                                                        outcome: outcome, parentApproved: parentConfirmed)
                            message = "Parent observation saved only on this device. It is separate from app performance."
                        }
                    }
                }
            }
            action("Return to parent controls", id: "companion-parent-controls") {
                speech.stop()
                showingMission = false
                parentConfirmed = false
                message = ""
            }
        }
    }

    private func groupPicture(count: Int, color: Color) -> some View {
        // Two rows stay bounded at a compact phone width even for a group of nine.
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), alignment: .leading, spacing: 8) {
            ForEach(0..<count, id: \.self) { _ in
                Circle().fill(color).frame(width: 36, height: 36)
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Group of \(count) objects")
    }

    private var deletionControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parent data controls").font(.headline)
            if store.assignment(profileID: profileID) != nil {
                action("Unlink current mission", id: "companion-unlink") { requestDeletion(.unlink) }
            }
            action("Delete this learner's companion data", id: "companion-delete-learner") { requestDeletion(.learnerData) }
            action("Delete all local companion data", id: "companion-delete-all") { requestDeletion(.allData) }
        }
    }

    private func action(_ title: String, id: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title).font(.headline).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 80)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(id)
    }

    private func prepare(target: Int) {
        guard parentConfirmed else { report(LearningHandoffError.parentApprovalRequired); return }
        review = Review(payload: .init(target: target, firstGroup: target == 5 ? 2 : 4), sourceCode: nil,
                        replacingReceiptID: store.assignment(profileID: profileID)?.payload.receiptID)
        exportCode = nil
        message = ""
    }

    private func perform(_ operation: () throws -> Void) {
        do { message = ""; try operation() } catch { report(error) }
    }

    private func report(_ error: Error) { message = error.localizedDescription }

    private func speak(_ prompt: String) {
        guard !UIAccessibility.isVoiceOverRunning else { return }
        speech.speak(prompt, enabled: audioEnabled)
    }

    private func clearTransientState() {
        speech.stop()
        review = nil
        exportCode = nil
        showingMission = false
        showingPicture = false
        parentConfirmed = false
        codeInput = ""
        message = ""
        deletion = nil
        showingDeletionConfirmation = false
    }

    private func close() {
        speech.stop()
        if let onClose { onClose() } else { dismiss() }
    }

    private func deletionMessage(_ choice: Deletion) -> String {
        switch choice {
        case .unlink: "Unlink this learner's current mission. Parent observations stay local. The code remains retired on this device."
        case .learnerData: "Delete this learner's assignments and observations. Keep only anonymous receipt codes to prevent replay."
        case .allData: "Delete all companion assignments, observations and anonymous receipt codes on this device. Old codes can be entered again after this deletion. Other app history is not affected."
        }
    }

    private func requestDeletion(_ choice: Deletion) {
        // The confirmation dialog is itself an explicit parent approval, including damaged-store recovery.
        deletion = choice
        showingDeletionConfirmation = true
    }

    private func performDeletion(_ choice: Deletion) {
        perform {
            switch choice {
            case .unlink: try store.unlink(profileID: profileID)
            case .learnerData: try store.reset(profileID: profileID)
            case .allData: store.resetAll()
            }
            clearTransientState()
            message = "Local companion data updated."
        }
    }

    private var contentWidth: CGFloat {
        #if os(tvOS)
        1200
        #else
        760
        #endif
    }
    private var horizontalPadding: CGFloat {
        #if os(tvOS)
        80
        #else
        20
        #endif
    }
    private var backgroundColor: Color {
        #if os(tvOS)
        Color.black
        #else
        Color(.systemBackground)
        #endif
    }
}
