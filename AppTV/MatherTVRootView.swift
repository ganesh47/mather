import SwiftUI

struct MatherTVRootView: View {
    @FocusState private var focusedAction: MatherTVAction.ID?
    @State private var selectedAction = MatherTVAction.angle

    private let actions = MatherTVAction.allCases

    var body: some View {
        ZStack {
            MatherTVBackdrop()

            VStack(alignment: .leading, spacing: 42) {
                header

                HStack(alignment: .center, spacing: 34) {
                    actionMenu
                    selectedActionPanel
                }
            }
            .frame(maxWidth: 1480, alignment: .leading)
            .padding(.horizontal, 92)
            .padding(.vertical, 76)
        }
        .onAppear {
            focusedAction = selectedAction.id
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mather TV Lab")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("A couch-ready shell for focus/select math play.")
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
        }
        .accessibilityElement(children: .combine)
    }

    private var actionMenu: some View {
        VStack(spacing: 24) {
            ForEach(actions) { action in
                Button {
                    selectedAction = action
                } label: {
                    MatherTVActionRow(
                        action: action,
                        isFocused: focusedAction == action.id,
                        isSelected: selectedAction == action
                    )
                }
                .buttonStyle(.plain)
                .focused($focusedAction, equals: action.id)
                .accessibilityHint(action.accessibilityHint)
                .accessibilityIdentifier("tv-mode-\(action.id)")
            }
        }
        .frame(width: 560)
    }

    @ViewBuilder
    private var selectedActionPanel: some View {
        switch selectedAction {
        case .memory:
            MemoryGalleryTVView()
        case .angle:
            AngleArcadeTVView()
        case .sprint:
            SumSprintPartyTVView()
        }
    }
}

private struct MatherTVActionRow: View {
    let action: MatherTVAction
    let isFocused: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 22) {
            Image(systemName: action.symbolName)
                .font(.system(size: 42, weight: .bold))
                .frame(width: 70, height: 70)
                .foregroundStyle(isFocused ? Color(red: 0.09, green: 0.13, blue: 0.19) : .white)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(action.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(isFocused ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)

                Text(action.subtitle)
                    .font(.system(size: 21, weight: .medium, design: .rounded))
                    .foregroundStyle(isFocused ? Color(red: 0.15, green: 0.20, blue: 0.29) : .white.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 560, height: 132)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(rowStroke)
        .scaleEffect(isFocused ? 1.055 : 1.0)
        .shadow(color: .black.opacity(isFocused ? 0.35 : 0.16), radius: isFocused ? 24 : 10, x: 0, y: isFocused ? 18 : 8)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isFocused)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }

    private var iconBackground: some ShapeStyle {
        isFocused ? .white : .white.opacity(0.12)
    }

    private var rowBackground: some ShapeStyle {
        if isFocused {
            return AnyShapeStyle(.white)
        }
        if isSelected {
            return AnyShapeStyle(Color(red: 0.10, green: 0.32, blue: 0.42).opacity(0.74))
        }
        return AnyShapeStyle(.white.opacity(0.08))
    }

    private var rowStroke: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(isSelected ? Color(red: 0.55, green: 0.88, blue: 1.0).opacity(0.78) : .white.opacity(0.12), lineWidth: 2)
    }
}

struct MatherTVBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.13),
                Color(red: 0.08, green: 0.20, blue: 0.24),
                Color(red: 0.13, green: 0.10, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            VStack(spacing: 0) {
                Color.white.opacity(0.08)
                    .frame(height: 1)
                Spacer()
                Color.white.opacity(0.10)
                    .frame(height: 1)
            }
            .padding(.vertical, 116)
        }
    }
}

private enum MatherTVAction: String, CaseIterable, Identifiable {
    case memory
    case angle
    case sprint

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memory: "Memory Gallery"
        case .angle: "Angle Arcade"
        case .sprint: "Sum Sprint Party"
        }
    }

    var subtitle: String {
        switch self {
        case .memory: "Picture-name matching"
        case .angle: "Predict, aim, launch"
        case .sprint: "Big answer tiles"
        }
    }

    var symbolName: String {
        switch self {
        case .memory: "rectangle.stack.fill"
        case .angle: "scope"
        case .sprint: "square.grid.2x2.fill"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .memory: "Selects the Memory Gallery picture matching game."
        case .angle: "Selects the Angle Arcade prototype."
        case .sprint: "Selects the Sum Sprint Party answer game."
        }
    }
}

#Preview {
    MatherTVRootView()
}
