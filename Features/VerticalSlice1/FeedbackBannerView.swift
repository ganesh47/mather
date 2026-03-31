import SwiftUI

struct FeedbackBannerView: View {
    let message: String
    let isCelebrating: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isCelebrating ? "hands.clap.fill" : "sparkles")
                .font(.title2)
            Text(message)
                .font(.headline.weight(.semibold))
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(MatherTheme.ink)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCelebrating ? MatherTheme.warm.opacity(0.65) : MatherTheme.softBlue.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
