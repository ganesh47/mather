import SwiftUI

@MainActor
enum ResponsiveLayout {

    // MARK: - Max widths

    static func contentMaxWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 1_100 : 760
    }

    static func concreteGridMaxWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 560 : 400
    }

    // MARK: - Padding

    static func contentPadding(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 48 : 24
    }

    // MARK: - Grid columns

    static func labColumns(for availableWidth: CGFloat) -> [GridItem] {
        let minimumTileWidth: CGFloat = availableWidth >= 1_100 ? 260 : 220
        return [GridItem(.adaptive(minimum: minimumTileWidth, maximum: 340), spacing: 16)]
    }

    static func statColumns(for horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    static func summaryFactColumns(for horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    // MARK: - Layout style

    static func isWide(_ horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }
}
