import Foundation
import Observation

/// Device-local exploration history for the TV camp. A sticker means explored, not mastered.
@MainActor
@Observable
final class CompareCampPassportStore {
    static let storageKey = "mather.compareCamp.passport.v1"

    private(set) var progress: CompareCampProgress
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(CompareCampProgress.self, from: data),
           saved.schemaVersion == 1 {
            progress = saved
        } else {
            progress = CompareCampProgress()
        }
    }

    func record(_ result: CompareCampSessionResult) {
        var updated = progress
        updated.record(result)
        guard updated != progress,
              let data = try? JSONEncoder().encode(updated) else { return }
        defaults.set(data, forKey: Self.storageKey)
        progress = updated
    }
}
