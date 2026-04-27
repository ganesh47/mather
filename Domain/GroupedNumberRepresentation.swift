import Foundation

/// Place-value representation for VS1 targets and build counts.
///
/// This model derives only from numeric truth already owned by the problem or
/// current build state. It is intentionally bounded to summary units so high
/// targets never require hundreds of loose counters in SwiftUI.
struct GroupedNumberRepresentation: Equatable {
    enum Band: Equatable {
        case zero
        case ones
        case teenTenFrames
        case tensOnes
        case hundredsTensOnes
        case thousand
    }

    enum UnitKind: String, Equatable {
        case thousand
        case hundred
        case ten
        case tenFrame
        case one
    }

    struct UnitGroup: Equatable, Identifiable {
        var id: UnitKind { kind }
        let kind: UnitKind
        let count: Int
        let valuePerUnit: Int

        var totalValue: Int { count * valuePerUnit }

        var label: String {
            switch kind {
            case .thousand:
                return count == 1 ? "1 thousand" : "\(count) thousands"
            case .hundred:
                return count == 1 ? "1 hundred" : "\(count) hundreds"
            case .ten:
                return count == 1 ? "1 ten" : "\(count) tens"
            case .tenFrame:
                return count == 1 ? "1 ten-frame" : "\(count) ten-frames"
            case .one:
                return count == 1 ? "1 one" : "\(count) ones"
            }
        }
    }

    let value: Int
    let band: Band
    let groups: [UnitGroup]
    /// Teen values still live visually in two ten-frame slots without creating
    /// one loose cell per value above 10.
    let tenFrameSlots: Int

    init(_ rawValue: Int) {
        value = min(max(rawValue, 0), 1000)

        switch value {
        case 0:
            band = .zero
            groups = []
            tenFrameSlots = 0
        case 1...10:
            band = .ones
            groups = [UnitGroup(kind: .one, count: value, valuePerUnit: 1)]
            tenFrameSlots = 1
        case 11...20:
            band = .teenTenFrames
            let ones = value - 10
            groups = [
                UnitGroup(kind: .tenFrame, count: 1, valuePerUnit: 10),
                UnitGroup(kind: .one, count: ones, valuePerUnit: 1)
            ].filter { $0.count > 0 }
            tenFrameSlots = 2
        case 21...100:
            band = .tensOnes
            groups = Self.placeValueGroups(value: value, includeHundreds: false)
            tenFrameSlots = 0
        case 101...999:
            band = .hundredsTensOnes
            groups = Self.placeValueGroups(value: value, includeHundreds: true)
            tenFrameSlots = 0
        default:
            band = .thousand
            groups = [UnitGroup(kind: .thousand, count: 1, valuePerUnit: 1000)]
            tenFrameSlots = 0
        }
    }

    var accessibilityText: String {
        guard !groups.isEmpty else { return "0" }
        return groups.map(\.label).joined(separator: ", ")
    }

    var suggestedSteps: [Int] {
        switch band {
        case .zero, .ones, .teenTenFrames:
            return [1]
        case .tensOnes:
            return [10, 1]
        case .hundredsTensOnes, .thousand:
            return [100, 10, 1]
        }
    }

    private static func placeValueGroups(value: Int, includeHundreds: Bool) -> [UnitGroup] {
        let hundreds = includeHundreds ? value / 100 : 0
        let tens = includeHundreds ? (value % 100) / 10 : value / 10
        let ones = value % 10

        return [
            UnitGroup(kind: .hundred, count: hundreds, valuePerUnit: 100),
            UnitGroup(kind: .ten, count: tens, valuePerUnit: 10),
            UnitGroup(kind: .one, count: ones, valuePerUnit: 1)
        ].filter { $0.count > 0 }
    }
}
