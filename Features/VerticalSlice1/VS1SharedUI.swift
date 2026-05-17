import SwiftUI

struct VS1Card<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(MatherTheme.panel.opacity(colorScheme == .dark ? 0.96 : 0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? MatherTheme.panelDeep.opacity(0.82) : MatherTheme.panelDeep.opacity(0.45),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(colorScheme == .dark ? 0.06 : 0), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.22 : 0.08), radius: colorScheme == .dark ? 22 : 18, x: 0, y: colorScheme == .dark ? 10 : 8)
    }
}

struct VS1TitleBlock: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.warm)
                .tracking(1.5)
            Text(title)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
            Text(subtitle)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(MatherTheme.ink.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct VS1PrimaryButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.bold))
                }
                Text(title)
                    .font(.headline.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 72)
            .padding(.horizontal, 18)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(MatherTheme.accent)
            )
            .overlay(DarkModeCTAOverlay())
            .shadow(color: colorScheme == .dark ? MatherTheme.accent.opacity(0.28) : .clear, radius: colorScheme == .dark ? 14 : 0, y: colorScheme == .dark ? 6 : 0)
        }
        .buttonStyle(.plain)
    }
}

struct VS1SecondaryButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .padding(.horizontal, 16)
            .foregroundStyle(MatherTheme.ink)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(MatherTheme.panel.opacity(colorScheme == .dark ? 1 : 0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(colorScheme == .dark ? MatherTheme.panelDeep.opacity(0.85) : MatherTheme.panelDeep.opacity(0.5), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(colorScheme == .dark ? 0.06 : 0), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct VS1ToggleRow: View {
    let title: String
    let subtitle: String
    var accessibilityIdentifier: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
        .tint(MatherTheme.accent)
        .padding(.vertical, 10)
    }
}

struct VS1CounterChip: View {
    let value: Int
    let isFilled: Bool

    var body: some View {
        Circle()
            .fill(isFilled ? MatherTheme.accent : MatherTheme.accent.opacity(0.18))
            .overlay(
                Text(isFilled ? "\(value)" : "")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            )
            .frame(width: 58, height: 58)
            .accessibilityLabel(isFilled ? "Counter \(value)" : "Empty slot")
    }
}

struct VS1MetricBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(MatherTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(MatherTheme.panel.opacity(colorScheme == .dark ? 0.98 : 0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(colorScheme == .dark ? MatherTheme.panelDeep.opacity(0.72) : .clear, lineWidth: 1)
        )
    }
}

struct VS1StepPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isActive: Bool

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(isActive ? MatherTheme.accent : MatherTheme.panel.opacity(colorScheme == .dark ? 0.98 : 0.75))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        isActive ? .white.opacity(colorScheme == .dark ? 0.14 : 0) : MatherTheme.panelDeep.opacity(colorScheme == .dark ? 0.8 : 0.4),
                        lineWidth: 1
                    )
            )
            .foregroundStyle(isActive ? .white : MatherTheme.ink)
    }
}

struct VS1StageRail: View {
    let currentStage: SliceStage

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SliceStage.allCases) { stage in
                VS1StepPill(title: stage.title, isActive: stage == currentStage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ParentUnlockRequest: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let unlockLabel: String
}

struct ParentUnlockSheet: View {
    let request: ParentUnlockRequest
    var onCancel: () -> Void
    var onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(MatherTheme.softBlue)
                .frame(width: 72, height: 72)
                .background(MatherTheme.softBlue.opacity(0.14), in: Circle())

            VStack(spacing: 8) {
                Text("Parent unlock")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(request.detail)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HoldToUnlockButton(title: request.unlockLabel, action: onUnlock)

            Button("Cancel", action: onCancel)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.softBlue)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(MatherTheme.softBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .buttonStyle(.plain)
                .accessibilityIdentifier("parent-unlock-cancel-button")
        }
        .padding(24)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("parent-unlock-sheet")
    }
}

private struct HoldToUnlockButton: View {
    let title: String
    var action: () -> Void

    @State private var isPressing = false

    var body: some View {
        Button(action: {}) {
            Label(title, systemImage: isPressing ? "lock.open.fill" : "lock.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(MatherTheme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(DarkModeCTAOverlay())
                .scaleEffect(isPressing ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("parent-unlock-hold-button")
        .accessibilityLabel(title)
        .onLongPressGesture(
            minimumDuration: 0.9,
            maximumDistance: 48,
            pressing: { pressing in
                withAnimation(.easeOut(duration: 0.12)) {
                    isPressing = pressing
                }
            },
            perform: action
        )
    }
}
