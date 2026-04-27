import SwiftUI

struct StoryAnchorView: View {
    let prompt: NumberStoryPrompt
    let onStartBuilding: () -> Void

    var body: some View {
        VS1Card {
            VStack(alignment: .leading, spacing: 22) {
                Text(prompt.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(prompt.spokenIntro)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(prompt.reminder)
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.accent)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
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
