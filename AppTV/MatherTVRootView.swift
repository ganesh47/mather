import SwiftUI

struct MatherTVRootView: View {
    @FocusState private var focusedAction: MatherTVAction.ID?
    @State private var selectedAction = MatherTVAction.memory

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
            }
        }
        .frame(width: 560)
    }

    private var selectedActionPanel: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text(selectedAction.eyebrow)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.55, green: 0.88, blue: 1.0))
                .textCase(.uppercase)

            Text(selectedAction.title)
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(selectedAction.detail)
                .font(.system(size: 31, weight: .medium, design: .rounded))
                .lineSpacing(6)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                ForEach(selectedAction.chips, id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.12), in: Capsule())
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 0)

            Text("Use the remote to move focus. Press select to preview a mode.")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
        }
        .padding(42)
        .frame(width: 790, height: 520, alignment: .leading)
        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
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

private struct MatherTVBackdrop: View {
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

    var detail: String {
        switch self {
        case .memory:
            "Start with large visual cards and focusable answers so a family can play from the couch."
        case .angle:
            "Turn the remote into a simple angle and power controller for prediction-first geometry."
        case .sprint:
            "Keep recall playful with four clear choices, pictorial support, and no pressure timer."
        }
    }

    var eyebrow: String {
        switch self {
        case .memory: "First prototype"
        case .angle: "Flagship mode"
        case .sprint: "Shared recall"
        }
    }

    var symbolName: String {
        switch self {
        case .memory: "rectangle.stack.fill"
        case .angle: "scope"
        case .sprint: "square.grid.2x2.fill"
        }
    }

    var chips: [String] {
        switch self {
        case .memory: ["Animals", "Planets", "No timer"]
        case .angle: ["D-pad", "Replay", "Targets"]
        case .sprint: ["Four choices", "Streaks", "Support fade"]
        }
    }

    var accessibilityHint: String {
        switch self {
        case .memory: "Selects the Memory Gallery preview."
        case .angle: "Selects the Angle Arcade preview."
        case .sprint: "Selects the Sum Sprint Party preview."
        }
    }
}

#Preview {
    MatherTVRootView()
}
