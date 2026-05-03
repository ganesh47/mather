import SwiftUI

/// The Explorer Lab — capability-first worlds that route kids into staged play.
struct LabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel
    @State private var selectedWorld: ExplorerWorld?

    private struct ExplorerWorld: Identifiable {
        let id: String
        let emoji: String
        let title: String
        let subtitle: String
        let badge: String
        let fill: Color
        let activities: [ExplorerActivity]
    }

    private struct ExplorerActivity: Identifiable, Equatable {
        let id: String
        let emoji: String
        let title: String
        let subtitle: String
        let isRecommended: Bool
        let action: (AppModel) -> Void

        init(emoji: String, title: String, subtitle: String, isRecommended: Bool, action: @escaping (AppModel) -> Void) {
            self.id = title.lowercased().replacingOccurrences(of: " ", with: "-")
            self.emoji = emoji
            self.title = title
            self.subtitle = subtitle
            self.isRecommended = isRecommended
            self.action = action
        }

        static func == (lhs: ExplorerActivity, rhs: ExplorerActivity) -> Bool { lhs.id == rhs.id }
    }

    private var worlds: [ExplorerWorld] {
        [
            ExplorerWorld(
                id: "numbers",
                emoji: "🔢",
                title: "Numbers",
                subtitle: "Sums, bonds, and fast recall",
                badge: "★★☆",
                fill: MatherTheme.warm,
                activities: [
                    ExplorerActivity(emoji: "⚡", title: "Sum Sprint", subtitle: "Race through sums 11–20", isRecommended: true) { appModel in
                        appModel.pickProfileThenRun {
                            appModel.engine.showSumSprint()
                            appModel.sumSprintEngine.showDifficultyPick()
                        }
                    },
                    ExplorerActivity(emoji: "🧱", title: "Make & Break", subtitle: "Build numbers with counters", isRecommended: false) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showSessionConfig() }
                    },
                ]
            ),
            ExplorerWorld(
                id: "geometry",
                emoji: "📐",
                title: "Geometry",
                subtitle: "Shapes, angles, and symmetry",
                badge: "★☆☆",
                fill: MatherTheme.coral,
                activities: [
                    ExplorerActivity(emoji: "🪞", title: "Symmetry Fold", subtitle: "Tilt to fold shapes in half", isRecommended: true) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showSymmetryFold() }
                    },
                    ExplorerActivity(emoji: "🏭", title: "Rectangle Factory", subtitle: "Drag frames to find factors", isRecommended: false) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showRectangleFactory() }
                    },
                    ExplorerActivity(emoji: "📐", title: "Protractor", subtitle: "Spread two fingers to measure angles", isRecommended: false) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showTwoFingerProtractor() }
                    },
                ]
            ),
            ExplorerWorld(
                id: "physics",
                emoji: "🌦️",
                title: "Physics",
                subtitle: "Forces, motion, and science loops",
                badge: "★★☆",
                fill: MatherTheme.softBlue,
                activities: [
                    ExplorerActivity(emoji: "💧", title: "Water Cycle Lab", subtitle: "Learn, quiz, and match the cycle", isRecommended: true) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showWaterCycle() }
                    },
                    ExplorerActivity(emoji: "💥", title: "Angle Cannon", subtitle: "Tilt to aim — hit the target", isRecommended: false) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showAngleCannon() }
                    },
                    ExplorerActivity(emoji: "🎨", title: "Gravity Artist", subtitle: "Predict where the ball lands", isRecommended: false) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showGravityArtist() }
                    },
                ]
            ),
            ExplorerWorld(
                id: "maps",
                emoji: "🗺️",
                title: "Maps",
                subtitle: "Rooms, places, and directions",
                badge: "★☆☆",
                fill: MatherTheme.accent,
                activities: [
                    ExplorerActivity(emoji: "🗺️", title: "Room Quest", subtitle: "Collect tokens around the room", isRecommended: true) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showRoomQuest() }
                    },
                    ExplorerActivity(emoji: "🧭", title: "Compass Walk", subtitle: "Turn your body to match the angle", isRecommended: false) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showCompassAngles() }
                    },
                ]
            ),
            ExplorerWorld(
                id: "discovery",
                emoji: "🃏",
                title: "Discovery",
                subtitle: "Cards, memory, and review",
                badge: "★☆☆",
                fill: MatherTheme.panelDeep,
                activities: [
                    ExplorerActivity(emoji: "🃏", title: "Memory Match", subtitle: "Match pictures, words, and ideas", isRecommended: true) { appModel in
                        appModel.pickProfileThenRun { appModel.engine.showMemory() }
                    },
                ]
            ),
        ]
    }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        if let selectedWorld {
                            worldDetail(selectedWorld)
                        } else {
                            worldGrid(width: proxy.size.width)
                        }
                    }
                    .padding(24)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Explorer Lab")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text(selectedWorld == nil ? "Pick a world" : "Pick a way to play")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
            Spacer()
            if selectedWorld != nil {
                Button { selectedWorld = nil } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(MatherTheme.accent)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("All Worlds")
            }
            Button { appModel.engine.showHome() } label: {
                Image(systemName: "house.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(MatherTheme.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Home")
        }
    }

    private func worldGrid(width: CGFloat) -> some View {
        LazyVGrid(columns: ResponsiveLayout.labColumns(for: width), spacing: 16) {
            ForEach(worlds) { world in
                Button { selectedWorld = world } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Text(world.emoji)
                                .font(.system(size: 54))
                            Spacer()
                            Text(world.badge)
                                .font(.caption.weight(.black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.65))
                                .clipShape(Capsule())
                        }
                        Text(world.title)
                            .font(.title2.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text(world.subtitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .lineLimit(2)
                        Text("Enter world")
                            .font(.caption.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.55))
                            .clipShape(Capsule())
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 178, alignment: .topLeading)
                    .background(world.fill.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(world.title) World")
                .accessibilityIdentifier("explorer-world-\(world.id)")
            }
        }
    }

    private func worldDetail(_ world: ExplorerWorld) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(world.emoji).font(.system(size: 48))
                VStack(alignment: .leading) {
                    Text("\(world.title) World")
                        .font(.title.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text(world.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
            }
            ForEach(world.activities) { activity in
                Button { activity.action(appModel) } label: {
                    HStack(spacing: 14) {
                        Text(activity.emoji).font(.system(size: 38))
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(activity.title)
                                    .font(.headline.weight(.black))
                                if activity.isRecommended {
                                    Text("Recommended next")
                                        .font(.caption2.weight(.black))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(MatherTheme.warm.opacity(0.45))
                                        .clipShape(Capsule())
                                }
                            }
                            Text(activity.subtitle)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }
                        Spacer()
                        Image(systemName: "play.fill")
                            .foregroundStyle(MatherTheme.accent)
                    }
                    .padding(16)
                    .background(MatherTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(activity.title)
            }
        }
    }
}
