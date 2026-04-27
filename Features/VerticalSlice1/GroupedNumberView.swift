import SwiftUI

struct GroupedNumberView: View {
    let representation: GroupedNumberRepresentation
    let fill: Color

    init(value: Int, fill: Color) {
        self.representation = GroupedNumberRepresentation(value)
        self.fill = fill
    }

    var body: some View {
        HStack(spacing: 8) {
            if representation.groups.isEmpty {
                unitToken(text: "0", symbol: "circle")
            } else {
                ForEach(representation.groups) { group in
                    unitToken(text: groupText(for: group), symbol: symbol(for: group.kind))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(representation.accessibilityText)
    }

    private func unitToken(text: String, symbol: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption.weight(.black))
            Text(text)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .foregroundStyle(fill)
        .frame(minHeight: 44)
        .padding(.horizontal, 10)
        .background(fill.opacity(0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(fill.opacity(0.26), lineWidth: 1.5)
        )
    }

    private func groupText(for group: GroupedNumberRepresentation.UnitGroup) -> String {
        switch group.kind {
        case .thousand:
            return "1000"
        case .hundred:
            return "\(group.count)x100"
        case .ten, .tenFrame:
            return "\(group.count)x10"
        case .one:
            return "\(group.count)"
        }
    }

    private func symbol(for kind: GroupedNumberRepresentation.UnitKind) -> String {
        switch kind {
        case .thousand:
            return "cube.fill"
        case .hundred:
            return "square.grid.3x3.fill"
        case .ten, .tenFrame:
            return "rectangle.grid.1x2.fill"
        case .one:
            return "circle.fill"
        }
    }
}
