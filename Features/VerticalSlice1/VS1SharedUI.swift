import SwiftUI

struct VS1Palette {
    static let background = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let panel = Color(red: 0.93, green: 0.89, blue: 0.80)
    static let panelDeep = Color(red: 0.87, green: 0.81, blue: 0.69)
    static let accent = Color(red: 0.14, green: 0.48, blue: 0.35)
    static let accentSoft = Color(red: 0.74, green: 0.89, blue: 0.82)
    static let text = Color(red: 0.18, green: 0.15, blue: 0.11)
    static let caution = Color(red: 0.61, green: 0.38, blue: 0.14)
}

struct VS1Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(VS1Palette.panelDeep.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
            .overlay(content.padding(24))
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
                .foregroundStyle(VS1Palette.caution)
                .tracking(1.5)
            Text(title)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(VS1Palette.text)
            Text(subtitle)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(VS1Palette.text.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct VS1PrimaryButton: View {
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
                    .fill(VS1Palette.accent)
            )
        }
        .buttonStyle(.plain)
    }
}

struct VS1SecondaryButton: View {
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
            .foregroundStyle(VS1Palette.text)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(VS1Palette.panel.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(VS1Palette.panelDeep.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct VS1ToggleRow: View {
    let title: String
    let subtitle: String
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
        .tint(VS1Palette.accent)
        .padding(.vertical, 10)
    }
}

struct VS1CounterChip: View {
    let value: Int
    let isFilled: Bool

    var body: some View {
        Circle()
            .fill(isFilled ? VS1Palette.accent : VS1Palette.accentSoft.opacity(0.35))
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
                .foregroundStyle(VS1Palette.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(VS1Palette.panel.opacity(0.55)))
    }
}

struct VS1StepPill: View {
    let title: String
    let isActive: Bool

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(isActive ? VS1Palette.accent : VS1Palette.panel.opacity(0.75))
            )
            .foregroundStyle(isActive ? .white : VS1Palette.text)
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

