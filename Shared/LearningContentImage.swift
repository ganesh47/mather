import SwiftUI

private struct LearningContentAssetURLsKey: EnvironmentKey {
    static let defaultValue: [String: URL] = [:]
}

extension EnvironmentValues {
    var learningContentAssetURLs: [String: URL] {
        get { self[LearningContentAssetURLsKey.self] }
        set { self[LearningContentAssetURLsKey.self] = newValue }
    }
}

/// Only verified catalog assets enter this environment. Bundled artwork is the fallback.
@MainActor
struct LearningContentImage: View {
    let name: String
    @Environment(\.learningContentAssetURLs) private var assetURLs

    private var image: Image {
        if let url = assetURLs[name], let downloaded = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: downloaded)
        }
        return Image(name)
    }

    var body: some View { image.resizable() }
}
