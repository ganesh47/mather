import SwiftUI

struct MatherTVRootView: View {
    @State private var selectedMode: MatherTVMode = .sumSprintParty

    var body: some View {
        ZStack {
            switch selectedMode {
            case .memoryGallery:
                MemoryGalleryTVView()
            case .sumSprintParty:
                SumSprintPartyTVView()
            }

            VStack {
                modeShelf
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 28)
        }
    }

    private var modeShelf: some View {
        HStack(spacing: 14) {
            ForEach(MatherTVMode.allCases) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    MatherTVModeTile(mode: mode, isSelected: selectedMode == mode)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
                .accessibilityHint(mode.accessibilityHint)
                .accessibilityIdentifier("tv-mode-\(mode.id)")
            }
        }
        .padding(8)
        .background(.black.opacity(0.20), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mather TV mode picker")
    }
}

private struct MatherTVModeTile: View {
    let mode: MatherTVMode
    let isSelected: Bool

    var body: some View {
        Label(mode.title, systemImage: mode.symbolName)
            .font(.system(size: 24, weight: .black, design: .rounded))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(width: 250)
            .background(backgroundStyle, in: Capsule())
            .foregroundStyle(.white)
    }

    private var backgroundStyle: some ShapeStyle {
        if isSelected { return AnyShapeStyle(Color(red: 0.55, green: 0.88, blue: 1.0).opacity(0.24)) }
        return AnyShapeStyle(.white.opacity(0.08))
    }
}

private enum MatherTVMode: String, CaseIterable, Identifiable {
    case memoryGallery
    case sumSprintParty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memoryGallery: return "Memory Gallery"
        case .sumSprintParty: return "Sum Sprint"
        }
    }

    var symbolName: String {
        switch self {
        case .memoryGallery: return "photo.on.rectangle.angled"
        case .sumSprintParty: return "plus.forwardslash.minus"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .memoryGallery: return "Shows the picture matching game."
        case .sumSprintParty: return "Shows the no timer addition answer game."
        }
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

#Preview {
    MatherTVRootView()
}
