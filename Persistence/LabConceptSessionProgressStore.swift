import Foundation

final class LabConceptSessionProgressStore {
    static let defaultStorageKey = "labConceptSessionProgress.v1"

    private let storage: ExplorerLabMasteryKeyValueStore
    private let storageKey: String
    private let activeProfileIdProvider: () -> String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        storage: ExplorerLabMasteryKeyValueStore = UserDefaults.standard,
        storageKey: String = LabConceptSessionProgressStore.defaultStorageKey,
        activeProfileIdProvider: @escaping () -> String = { KidProfilePersistence.defaultProfileId },
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.storage = storage
        self.storageKey = storageKey
        self.activeProfileIdProvider = activeProfileIdProvider
        self.encoder = encoder
        self.decoder = decoder
    }

    func progress(for plan: LabConceptSessionPlan) -> LabConceptSessionProgress? {
        loadProfile()[plan.id]
    }

    func hasProgress(for plan: LabConceptSessionPlan) -> Bool {
        progress(for: plan) != nil
    }

    func currentStage(for plan: LabConceptSessionPlan) -> GuidedLabStage? {
        progress(for: plan)?.currentStage
    }

    func resumeLabel(for plan: LabConceptSessionPlan) -> String {
        progress(for: plan)?.resumeCopy ?? plan.startAffordanceLabel
    }

    @discardableResult
    func beginGuidedStage(
        _ stage: GuidedLabStage? = nil,
        in plan: LabConceptSessionPlan,
        at date: Date = Date()
    ) -> LabConceptSessionProgress {
        update(plan: plan, at: date) { progress in
            let chosenStage = stage ?? progress.currentStage
            progress.markLaunched(chosenStage, in: plan, at: date)
        }
    }

    @discardableResult
    func markCompleted(
        _ stage: GuidedLabStage,
        in plan: LabConceptSessionPlan,
        at date: Date = Date(),
        summary: LabStageTimingScoreSummary? = nil
    ) -> LabConceptSessionProgress {
        update(plan: plan, at: date) { progress in
            progress.markCompleted(stage, in: plan, at: date, summary: summary)
        }
    }

    @discardableResult
    func markLabLaunchedGameplayCompleted(
        _ context: LabGameplayCompletionContext?,
        at date: Date = Date(),
        summary: LabStageTimingScoreSummary? = nil
    ) -> LabConceptSessionProgress? {
        guard let context,
              [.play, .blast].contains(context.stage),
              let plan = LabConceptSessionPlan.plan(for: context.conceptPlanID),
              plan.stageOrder.contains(context.stage)
        else { return nil }

        return update(plan: plan, at: date) { progress in
            progress.markCompleted(context.stage, in: plan, at: date, summary: summary)
            if let completedIndex = plan.stageOrder.firstIndex(of: context.stage),
               plan.stageOrder.indices.contains(completedIndex + 1) {
                progress.currentStage = plan.stageOrder[completedIndex + 1]
            }
        }
    }

    func reset() {
        var all = loadAll()
        all[activeProfileIdProvider()] = [:]
        saveAll(all)
    }

    private func update(
        plan: LabConceptSessionPlan,
        at date: Date,
        mutation: (inout LabConceptSessionProgress) -> Void
    ) -> LabConceptSessionProgress {
        var all = loadAll()
        let profileId = activeProfileIdProvider()
        var profile = all[profileId] ?? [:]
        var progress = profile[plan.id] ?? LabConceptSessionProgress(plan: plan, startedAt: date)
        mutation(&progress)
        profile[plan.id] = progress
        all[profileId] = profile
        saveAll(all)
        return progress
    }

    private func loadProfile() -> [String: LabConceptSessionProgress] {
        loadAll()[activeProfileIdProvider()] ?? [:]
    }

    private func loadAll() -> [String: [String: LabConceptSessionProgress]] {
        guard let data = storage.data(forKey: storageKey),
              let progress = try? decoder.decode([String: [String: LabConceptSessionProgress]].self, from: data)
        else { return [:] }
        return progress
    }

    private func saveAll(_ progress: [String: [String: LabConceptSessionProgress]]) {
        guard let data = try? encoder.encode(progress) else { return }
        storage.set(data, forKey: storageKey)
    }
}
