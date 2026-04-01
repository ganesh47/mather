import SwiftUI

struct FeedbackBannerView: View {
    let message: String
    let isCelebrating: Bool

    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isCelebrating ? "hands.clap.fill" : "sparkles")
                .font(.title2)
                .scaleEffect(iconScale)
            Text(message)
                .font(.headline.weight(.semibold))
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(MatherTheme.ink)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCelebrating ? MatherTheme.warm.opacity(0.65) : MatherTheme.softBlue.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.easeInOut(duration: 0.25), value: isCelebrating)
        .onChange(of: isCelebrating) { _, celebrating in
            guard celebrating else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { iconScale = 1.5 }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55).delay(0.18)) { iconScale = 1.0 }
        }
    }
}
