import SwiftUI

struct FeedbackBannerView: View {
    let message: String
    let isCelebrating: Bool

    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isCelebrating ? "star.fill" : "arrow.forward.circle.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(isCelebrating ? MatherTheme.warm : MatherTheme.softBlue)
                .scaleEffect(iconScale)
            Text(message)
                .font(.headline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isCelebrating
                ? MatherTheme.warm.opacity(0.88)
                : MatherTheme.softBlue.opacity(0.18)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    isCelebrating ? MatherTheme.warm : MatherTheme.softBlue.opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isCelebrating)
        .onChange(of: isCelebrating) { _, celebrating in
            guard celebrating else { return }
            withAnimation(.spring(response: 0.22, dampingFraction: 0.38)) { iconScale = 1.6 }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.16)) { iconScale = 1.0 }
        }
    }
}
