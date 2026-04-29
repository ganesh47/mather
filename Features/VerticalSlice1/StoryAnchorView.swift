import SwiftUI

struct StoryAnchorView: View {
    let prompt: NumberStoryPrompt
    let onStartBuilding: () -> Void

    var body: some View {
        VS1Card {
            VStack(alignment: .leading, spacing: 18) {
                Text(prompt.title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text(prompt.spokenIntro)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("story-anchor-spoken-intro")

                Text(prompt.reminder)
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule(style: .continuous)
                            .fill(MatherTheme.accent.opacity(0.14))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(MatherTheme.accent.opacity(0.35), lineWidth: 2)
                    )
                    .accessibilityIdentifier("story-anchor-reminder-pill")

                VS1PrimaryButton(title: "Start building", systemImage: "play.fill", action: onStartBuilding)
                    .accessibilityIdentifier("story-anchor-start-button")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("story-anchor-card")
    }
}
