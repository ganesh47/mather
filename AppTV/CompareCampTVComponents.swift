import SwiftUI
import UIKit

@MainActor
enum CompareCampPalette {
    static let ink = Color(red: 0.06, green: 0.12, blue: 0.17)
    static let mint = Color(red: 0.73, green: 0.94, blue: 0.76)
    static let sky = Color(red: 0.53, green: 0.85, blue: 0.97)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.42)

    static func color(_ hex: String) -> Color {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x90DDBD
        return Color(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}

/// Owns the label appearance without tvOS adding a second material focus card.
@MainActor
struct CompareCampButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(enabled ? configuration.isPressed ? 0.92 : 1 : 0.62)
    }
}

/// Manual focus treatment keeps large TV cards from blooming over their neighbours.
@MainActor
struct CompareCampControlSurface: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let focused: Bool
    var selected = false
    var accent = CompareCampPalette.mint
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .foregroundStyle(focused ? CompareCampPalette.ink : .white)
            .background(focused ? .white : selected ? accent.opacity(0.19) : .white.opacity(0.07), in: RoundedRectangle(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(focused ? accent : selected ? accent.opacity(0.75) : .white.opacity(0.16), lineWidth: focused ? 4 : 2)
            }
            .shadow(color: focused ? accent.opacity(0.14) : .clear, radius: 15)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: focused)
    }
}

@MainActor
struct CompareCampArtwork: View {
    let assetName: String?
    let symbolName: String
    var accent = CompareCampPalette.mint

    var body: some View {
        Group {
            if let assetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: symbolName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(accent)
                    .padding(10)
            }
        }
        .accessibilityHidden(true)
    }
}

@MainActor
struct CompareCampCategoryCard: View {
    let category: CompareCampCategory
    let focused: Bool
    let explored: Bool

    private var accent: Color { CompareCampPalette.color(category.accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                CompareCampArtwork(assetName: category.artAssetName, symbolName: category.tokenSymbol, accent: accent)
                    .frame(width: 156, height: 120)
                Spacer(minLength: 0)
                Image(systemName: explored ? "checkmark.seal.fill" : "sparkle")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(focused ? CompareCampPalette.ink : accent)
                    .padding(.top, 7)
            }
            Text(category.title)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(category.subtitle)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(focused ? CompareCampPalette.ink.opacity(0.72) : .white.opacity(0.64))
                .lineLimit(2)
                .frame(height: 54, alignment: .topLeading)
        }
        .padding(26)
        .frame(width: 402, height: 288, alignment: .topLeading)
        .modifier(CompareCampControlSurface(focused: focused, accent: accent, radius: 28))
    }
}

@MainActor
struct CompareCampTokenTray: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let category: CompareCampCategory
    let title: String
    let count: Int
    let maxCount: Int
    let counted: Int
    let arranged: Bool
    let pairedCount: Int
    let showCount: Bool
    let isBuilding: Bool
    var accent = CompareCampPalette.gold

    private var columns: Int { maxCount <= 5 ? 3 : maxCount <= 10 ? 4 : 5 }
    private var tileWidth: CGFloat { maxCount <= 5 ? 112 : maxCount <= 10 ? 88 : 70 }
    private var tileHeight: CGFloat { maxCount <= 5 ? 112 : maxCount <= 10 ? 88 : 66 }

    var body: some View {
        VStack(spacing: 13) {
            HStack {
                Label(title, systemImage: title == "Left camp" ? "arrow.left" : "arrow.right")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                Spacer()
                if showCount {
                    Text("\(count)")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                        .accessibilityIdentifier(title == "Left camp" ? "tv-compare-left-count" : "tv-compare-right-count")
                }
            }
            .foregroundStyle(.white)
            .frame(height: 42)

            if count == 0 {
                VStack(spacing: 14) {
                    Image(systemName: "circle.dashed")
                        .font(.system(size: 66, weight: .regular))
                        .foregroundStyle(accent.opacity(0.7))
                    Text("An empty camp")
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .frame(height: 302)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(tileWidth), spacing: 12), count: columns), spacing: 10) {
                    ForEach(0..<count, id: \.self) { index in
                        token(index)
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .frame(width: 398, height: 302, alignment: .topLeading)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: count)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: counted)
            }

            HStack(spacing: 9) {
                Image(systemName: arranged ? "link" : isBuilding ? "hand.draw.fill" : "hand.tap.fill")
                Text(arranged ? "Line them up, pair them up" : isBuilding ? "Add or take one away" : "Count one at a time")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.62))
            .frame(height: 28)
        }
        .padding(20)
        .frame(width: 478, height: 438, alignment: .top)
        .background(.black.opacity(0.23), in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).stroke(accent.opacity(0.42), lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(count) \(category.tokenPlural). \(counted) counted. \(arranged ? "Paired arrangement. \(min(count, pairedCount)) have partners. \(max(0, count - pairedCount)) have no partner." : "")")
    }

    private func token(_ index: Int) -> some View {
        let isCounted = index < counted
        let isExtra = arranged && index >= pairedCount
        return CompareCampArtwork(assetName: category.tokenAssetName, symbolName: category.tokenSymbol, accent: CompareCampPalette.color(category.accentHex))
            .padding(7)
            .frame(width: tileWidth, height: tileHeight)
            .background(isCounted ? accent.opacity(0.26) : .white.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isExtra ? CompareCampPalette.gold : arranged ? CompareCampPalette.sky.opacity(0.8) : isCounted ? accent : .clear, lineWidth: 3)
            }
            .overlay(alignment: .topTrailing) {
                if arranged {
                    Image(systemName: isExtra ? "plus" : "link")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(CompareCampPalette.ink)
                        .frame(width: 22, height: 22)
                        .background(isExtra ? CompareCampPalette.gold : CompareCampPalette.sky, in: Circle())
                        .offset(x: 3, y: -3)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isCounted {
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(CompareCampPalette.ink)
                        .frame(width: 24, height: 24)
                        .background(accent, in: Circle())
                        .offset(x: 3, y: 3)
                }
            }
    }
}

@MainActor
struct CompareCampTrailProgress: View {
    let completed: Int
    let goal: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<goal, id: \.self) { index in
                Image(systemName: index < completed ? "checkmark" : index == completed ? "pawprint.fill" : "circle.fill")
                    .font(.system(size: index < completed ? 19 : 21, weight: .black))
                    .foregroundStyle(index <= completed ? CompareCampPalette.ink : .white.opacity(0.30))
                    .frame(width: 40, height: 40)
                    .background(index < completed ? CompareCampPalette.mint : index == completed ? CompareCampPalette.gold : .white.opacity(0.06), in: Circle())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(completed) of \(goal) trail stops completed.")
    }
}
