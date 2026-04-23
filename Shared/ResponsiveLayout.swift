import SwiftUI

@MainActor
enum ResponsiveLayout {
    static func contentMaxWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 1_100 : 760
    }

    static func concreteGridMaxWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 560 : 400
    }

    static func labColumns(for availableWidth: CGFloat) -> [GridItem] {
        let minimumTileWidth: CGFloat = availableWidth >= 1_100 ? 260 : 220
        return [GridItem(.adaptive(minimum: minimumTileWidth, maximum: 340), spacing: 16)]
    }
}
