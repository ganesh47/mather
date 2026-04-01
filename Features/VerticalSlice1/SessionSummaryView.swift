import SwiftUI

struct SessionSummaryView: View {
    @Bindable var appModel: AppModel
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Warm gradient backdrop — feels festive without being alarming
            LinearGradient(
                colors: [MatherTheme.warm.opacity(0.4), MatherTheme.accent.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Central celebration — animates in on appear
                VStack(spacing: 16) {
                    Text("⭐️")
                        .font(.system(size: 96))
                        .scaleEffect(scale)
                        .opacity(opacity)

                    Text("Amazing!")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)

                    Text("You did it!")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }

                Spacer()

                VStack(spacing: 14) {
                    Button("Play again") {
                        appModel.engine.showSessionConfig()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    HStack(spacing: 14) {
                        Button("Parent summary") {
                            appModel.engine.showParentSummary()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.6)))

                        Button("Done") {
                            appModel.engine.showHome()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.55)))
                    }
                }
            }
            .padding(24)
        }
    }
}
