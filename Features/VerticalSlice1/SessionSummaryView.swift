import SwiftUI

struct SessionSummaryView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 80))
                    Text("Amazing work!")
                        .font(.largeTitle.weight(.black))
                    Text("You did it!")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(MatherTheme.warm.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                Spacer()

                Button("Play again") {
                    appModel.engine.showSessionConfig()
                }
                .buttonStyle(PrimaryActionButtonStyle())

                HStack(spacing: 16) {
                    Button("Parent summary") {
                        appModel.engine.showParentSummary()
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.75)))

                    Button("Done") {
                        appModel.engine.showHome()
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.75)))
                }
            }
            .padding(24)
        }
    }
}
