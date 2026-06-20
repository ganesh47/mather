import SwiftUI

struct MatherTVRootView: View {
    var body: some View {
        MemoryGalleryTVView()
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
