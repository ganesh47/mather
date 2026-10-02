import SwiftUI

struct TVFamilyLearningView: View {
    @Bindable var store: TVLearningStore
    let onExit: () -> Void
    @State private var newName = ""
    @State private var narration = TVNarrationController()

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Family learning guide").font(.system(size: 52, weight: .bold, design: .rounded))
                        .accessibilityIdentifier("tv-family-title")
                    Text("Choose who is playing before starting a game. Family play stays separate from each learner's history.")
                        .font(.system(size: 26)).foregroundStyle(.white.opacity(0.8))
                    HStack(alignment: .top, spacing: 36) {
                        profileControls.frame(width: 540)
                        evidence.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button("All games", action: onExit)
                        .accessibilityIdentifier("tv-family-back")
                }.padding(60).frame(maxWidth: 1680, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
        .buttonStyle(TVFamilyButtonStyle())
        .onExitCommand(perform: onExit)
        .onAppear { narration.presentPrompt("Family learning guide. Choose family play or a learner before starting a game. Learning here is saved only on this TV. Menu returns to all games.") }
        .onPlayPauseCommand { narration.repeatPrompt() }
        .onDisappear { narration.stop() }
    }

    private var profileControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Playing: \(store.context.name)").font(.system(size: 30, weight: .bold))
                .accessibilityIdentifier("tv-family-selected")
            Button("Family play\(store.context.familyMode ? " · selected" : "")") { store.selectLearner(nil) }
                .accessibilityIdentifier("tv-family-select-family")
            ForEach(store.learners) { learner in
                Button("\(learner.name)\(store.context.profileID == learner.id ? " · selected" : "")") { store.selectLearner(learner.id) }
                    .accessibilityIdentifier("tv-family-select-\(learner.id)")
            }
            TextField("Learner name", text: $newName)
                .accessibilityLabel("New learner name")
                .accessibilityIdentifier("tv-family-new-name")
            Button("Add learner") {
                if store.addLearner(name: newName) { newName = "" }
            }.disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.learners.count >= 8 || store.storageMessage != nil)
                .accessibilityIdentifier("tv-family-add")
            Text("Names and learning stay on this device. Earlier device scores have unknown ownership and are never assigned to a learner.")
                .font(.system(size: 23)).foregroundStyle(.white.opacity(0.75))
            if let message = store.storageMessage {
                Text(message).font(.system(size: 23)).foregroundStyle(.yellow)
            }
        }.padding(24).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
    }

    private var evidence: some View {
        let attempts = store.attempts(for: store.context.profileID)
        let successes = attempts.filter { $0.outcome == .independentCorrect }
        let helped = attempts.filter { $0.outcome == .supportedCorrect }
        let probes = successes.filter { $0.isFreshProbe == true }
        return VStack(alignment: .leading, spacing: 18) {
            Text(store.context.familyMode ? "Family discoveries" : "\(store.context.name)'s discoveries")
                .font(.system(size: 32, weight: .bold))
            Text("\(successes.count) answers without app help · \(helped.count) with help · \(probes.count) fresh probes without app help")
                .font(.system(size: 25)).accessibilityIdentifier("tv-family-evidence")
            Text("Adult assistance is unknown. A correct choice or completed game is not proof of independent mastery.")
                .font(.system(size: 23)).foregroundStyle(.white.opacity(0.75))
            if attempts.isEmpty {
                Text("Start a short Sum Sprint or Shape Detective journey to collect actual choices and attempts.")
                    .font(.system(size: 26))
            } else {
                Text(nextAction(attempts)).font(.system(size: 26, weight: .semibold))
                    .accessibilityIdentifier("tv-family-next")
            }
            ForEach(store.results(for: store.context.profileID).prefix(4)) { result in
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.title).font(.system(size: 26, weight: .bold))
                    Text(result.endedAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 21))
                    Text("\(result.attempts.filter { $0.outcome == .independentCorrect }.count) without app help · \(result.attempts.filter { $0.outcome == .supportedCorrect }.count) with help")
                        .font(.system(size: 22))
                }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
            }
            Text("Compare Camp, Angle Arcade and earlier scores remain device activity. Their completion stickers are separate from this learning evidence.")
                .font(.system(size: 22)).foregroundStyle(.white.opacity(0.7))
        }.padding(24).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
    }

    private func nextAction(_ attempts: [ItemAttempt]) -> String {
        guard let last = attempts.last else { return "Next: try one short journey." }
        let needsSupport = last.outcome == .help || last.outcome == .incorrect || last.outcome == .supportedCorrect
        if last.activityID.lowercased().contains("shape") {
            return needsSupport ? "Next: trace the sides and corners of a real box together, then try a new shape." : "Next: find a rectangle in the room. Turn it and explain which properties stay the same."
        }
        return needsSupport ? "Next: count two small groups together, join them, and try the through-5 journey." : "Next: split five real objects into two groups. Ask how many altogether, then change the split."
    }
}

struct TVFamilyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TVFamilyButtonBody(configuration: configuration)
    }
}

private struct TVFamilyButtonBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isFocused) private var focused
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        configuration.label
            .font(.system(size: 25, weight: .bold, design: .rounded))
            .foregroundStyle(focused ? Color(red: 0.06, green: 0.1, blue: 0.16) : .white)
            .padding(.horizontal, 24).padding(.vertical, 18)
            .frame(minHeight: 80)
            .background(focused ? Color(red: 0.8, green: 0.95, blue: 0.68) : .white.opacity(0.13), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(focused ? .white : .clear, lineWidth: 3))
            .opacity(enabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
