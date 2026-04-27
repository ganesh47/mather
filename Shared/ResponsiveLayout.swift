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

    static func childSessionMaxWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 940 : CGFloat.infinity
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

    static func settingsColumns(for horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let count = horizontalSizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: 20, alignment: .top), count: count)
    }

    static func profileColumns(for horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let minimum = horizontalSizeClass == .regular ? 140.0 : 110.0
        let maximum = horizontalSizeClass == .regular ? 180.0 : 160.0
        return [GridItem(.adaptive(minimum: minimum, maximum: maximum), spacing: 16)]
    }

    static func roomQuestStationMinimumWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 240 : 170
    }

    static func roomQuestStationColumns(for horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let minimum = roomQuestStationMinimumWidth(for: horizontalSizeClass)
        let maximum: CGFloat = horizontalSizeClass == .regular ? 320 : CGFloat.infinity
        return [GridItem(.adaptive(minimum: minimum, maximum: maximum), spacing: 16, alignment: .top)]
    }

    static func profilePickerMaxWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 920 : .infinity
    }

    // MARK: - Layout style

    static func isWide(_ horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }
}
