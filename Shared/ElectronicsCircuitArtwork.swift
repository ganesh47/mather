import SwiftUI

struct ElectronicsCircuitArtwork: View {
    nonisolated static let canvasSize: CGFloat = 120

    let key: ElectronicsArtworkKey
    var tint: Color = MatherTheme.accent

    nonisolated static func fittingScale(for proposedSize: CGSize) -> CGFloat {
        let availableSize = min(proposedSize.width, proposedSize.height)
        guard availableSize > 0 else { return 0 }
        return availableSize / canvasSize
    }

    var body: some View {
        GeometryReader { proxy in
            let lineWidth = Self.canvasSize * 0.055
            ZStack {
                artwork(lineWidth: lineWidth)
            }
            .frame(width: Self.canvasSize, height: Self.canvasSize)
            .scaleEffect(Self.fittingScale(for: proxy.size))
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var wireColor: Color { MatherTheme.panelDeep.opacity(0.82) }
    private var glowColor: Color { MatherTheme.warm }
    private var dangerColor: Color { MatherTheme.coral }

    @ViewBuilder
    private func artwork(lineWidth: CGFloat) -> some View {
        switch key {
        case .battery:
            battery(lineWidth: lineWidth)
        case .bulb:
            bulb(lineWidth: lineWidth)
        case .wire:
            wire(lineWidth: lineWidth)
        case .switchControl:
            switchControl(lineWidth: lineWidth)
        case .closedCircuit:
            circuit(closed: true, lineWidth: lineWidth)
        case .openCircuit:
            circuit(closed: false, lineWidth: lineWidth)
        case .safeCircuit:
            safeCircuit(lineWidth: lineWidth)
        case .outletSafety:
            outletSafety(lineWidth: lineWidth)
        }
    }

    @ViewBuilder
    private func battery(lineWidth: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(tint.opacity(0.22))
            .frame(width: 72, height: 46)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(wireColor, lineWidth: lineWidth)
            )
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(wireColor)
            .frame(width: 8, height: 24)
            .offset(x: 44)
        Rectangle()
            .fill(wireColor)
            .frame(width: 18, height: lineWidth)
            .offset(x: -20)
        Rectangle()
            .fill(wireColor)
            .frame(width: lineWidth, height: 18)
            .offset(x: -20)
        Rectangle()
            .fill(wireColor)
            .frame(width: 18, height: lineWidth)
            .offset(x: 18)
    }

    @ViewBuilder
    private func bulb(lineWidth: CGFloat) -> some View {
        Circle()
            .fill(glowColor.opacity(0.28))
            .frame(width: 72, height: 72)
        Circle()
            .stroke(glowColor, lineWidth: lineWidth)
            .frame(width: 54, height: 54)
            .offset(y: -10)
        Capsule()
            .fill(wireColor)
            .frame(width: 30, height: 16)
            .offset(y: 30)
        ForEach([-24, 0, 24], id: \.self) { x in
            Capsule()
                .fill(glowColor)
                .frame(width: lineWidth, height: 14)
                .offset(x: CGFloat(x), y: -48)
        }
        Path { path in
            path.move(to: CGPoint(x: 38, y: 55))
            path.addLine(to: CGPoint(x: 50, y: 43))
            path.move(to: CGPoint(x: 58, y: 80))
            path.addLine(to: CGPoint(x: 74, y: 80))
        }
        .stroke(wireColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .frame(width: 112, height: 112)
    }

    @ViewBuilder
    private func wire(lineWidth: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 14, y: 62))
            path.addCurve(to: CGPoint(x: 42, y: 32), control1: CGPoint(x: 18, y: 32), control2: CGPoint(x: 34, y: 24))
            path.addCurve(to: CGPoint(x: 74, y: 70), control1: CGPoint(x: 54, y: 44), control2: CGPoint(x: 42, y: 78))
            path.addCurve(to: CGPoint(x: 102, y: 48), control1: CGPoint(x: 88, y: 62), control2: CGPoint(x: 90, y: 42))
        }
        .stroke(wireColor, style: StrokeStyle(lineWidth: lineWidth * 1.25, lineCap: .round, lineJoin: .round))
        .frame(width: 116, height: 104)
        Circle().fill(tint).frame(width: 13, height: 13).offset(x: -46, y: 10)
        Circle().fill(tint).frame(width: 13, height: 13).offset(x: 46, y: -4)
    }

    @ViewBuilder
    private func switchControl(lineWidth: CGFloat) -> some View {
        Capsule().fill(wireColor).frame(width: 28, height: lineWidth).offset(x: -34, y: 20)
        Capsule().fill(wireColor).frame(width: 28, height: lineWidth).offset(x: 34, y: 20)
        Circle().fill(wireColor).frame(width: 14, height: 14).offset(x: -18, y: 20)
        Circle().fill(wireColor).frame(width: 14, height: 14).offset(x: 48, y: 20)
        Capsule()
            .fill(tint)
            .frame(width: 60, height: lineWidth * 1.45)
            .rotationEffect(.degrees(-24))
            .offset(x: 12, y: 4)
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(tint.opacity(0.42), lineWidth: lineWidth)
            .frame(width: 96, height: 62)
    }

    @ViewBuilder
    private func circuit(closed: Bool, lineWidth: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .trim(from: closed ? 0 : 0.10, to: closed ? 1 : 0.84)
            .stroke(wireColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: 104, height: 78)
        battery(lineWidth: lineWidth * 0.70)
            .scaleEffect(0.45)
            .offset(x: -34, y: 16)
        bulb(lineWidth: lineWidth * 0.68)
            .scaleEffect(0.46)
            .offset(x: 30, y: -18)
        if closed {
            Circle()
                .fill(glowColor.opacity(0.42))
                .frame(width: 32, height: 32)
                .offset(x: 30, y: -22)
        } else {
            Path { path in
                path.move(to: CGPoint(x: 28, y: 28))
                path.addLine(to: CGPoint(x: 84, y: 84))
                path.move(to: CGPoint(x: 84, y: 28))
                path.addLine(to: CGPoint(x: 28, y: 84))
            }
            .stroke(dangerColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: 112, height: 112)
        }
    }

    @ViewBuilder
    private func safeCircuit(lineWidth: CGFloat) -> some View {
        circuit(closed: true, lineWidth: lineWidth)
        Circle()
            .fill(MatherTheme.card.opacity(0.94))
            .frame(width: 38, height: 38)
            .offset(x: 30, y: 30)
        Image(systemName: "checkmark")
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundStyle(tint)
            .offset(x: 30, y: 30)
    }

    @ViewBuilder
    private func outletSafety(lineWidth: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(MatherTheme.card.opacity(0.86))
            .frame(width: 62, height: 78)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(wireColor, lineWidth: lineWidth)
            )
        Capsule().fill(wireColor).frame(width: 9, height: 22).offset(x: -12, y: -8)
        Capsule().fill(wireColor).frame(width: 9, height: 22).offset(x: 12, y: -8)
        Path { path in
            path.move(to: CGPoint(x: 28, y: 28))
            path.addLine(to: CGPoint(x: 84, y: 84))
            path.move(to: CGPoint(x: 84, y: 28))
            path.addLine(to: CGPoint(x: 28, y: 84))
        }
        .stroke(dangerColor, style: StrokeStyle(lineWidth: lineWidth * 1.15, lineCap: .round))
        .frame(width: 112, height: 112)
        Circle()
            .stroke(dangerColor, lineWidth: lineWidth)
            .frame(width: 96, height: 96)
    }
}
