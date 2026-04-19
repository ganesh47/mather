import SwiftUI

/// The Explorer Lab — a game picker for all physics and geometry activities.
struct LabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel

    private struct GameTile {
        let emoji: String
        let name: String
        let tagline: String
        let fill: Color
        let action: () -> Void
    }

    private var tiles: [GameTile] {
        [
            GameTile(emoji: "⚡", name: "Sum Sprint",
                     tagline: "Race through sums 11–20",
                     fill: MatherTheme.warm) {
                appModel.engine.showSumSprint()
                appModel.sumSprintEngine.showDifficultyPick()
            },
            GameTile(emoji: "🗺️", name: "Room Quest",
                     tagline: "Collect tokens around the room",
                     fill: MatherTheme.accent) {
                appModel.engine.showRoomQuest()
            },
            GameTile(emoji: "🪞", name: "Symmetry Fold",
                     tagline: "Tilt to fold shapes in half",
                     fill: MatherTheme.coral) {
                appModel.engine.showSymmetryFold()
            },
            GameTile(emoji: "🏭", name: "Rectangle Factory",
                     tagline: "Drag frames to find factors",
                     fill: MatherTheme.softBlue) {
                appModel.engine.showRectangleFactory()
            },
            GameTile(emoji: "💥", name: "Angle Cannon",
                     tagline: "Tilt to aim — hit the target",
                     fill: MatherTheme.warm) {
                appModel.engine.showAngleCannon()
            },
            GameTile(emoji: "📐", name: "Protractor",
                     tagline: "Spread two fingers to measure angles",
                     fill: MatherTheme.accent) {
                appModel.engine.showTwoFingerProtractor()
            },
            GameTile(emoji: "🎨", name: "Gravity Artist",
                     tagline: "Predict where the ball lands",
                     fill: MatherTheme.panelDeep) {
                appModel.engine.showGravityArtist()
            },
            GameTile(emoji: "🧭", name: "Compass Walk",
                     tagline: "Turn your body to match the angle",
                     fill: MatherTheme.softBlue) {
                appModel.engine.showCompassAngles()
            },
            GameTile(emoji: "🃏", name: "Memory Match",
                     tagline: "Match animals to their names",
                     fill: MatherTheme.coral) {
                appModel.engine.showMemory()
            },
        ]
    }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Explorer Lab")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(MatherTheme.ink)
                            Text("Pick a game and discover maths")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }
                        Spacer()
                        Button {
                            appModel.engine.showHome()
                        } label: {
                            Image(systemName: "house.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(MatherTheme.accent)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Home")
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                            gameTileButton(tile)
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    private func gameTileButton(_ tile: GameTile) -> some View {
        Button(action: tile.action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    tile.fill.opacity(0.85)
                    Text(tile.emoji)
                        .font(.system(size: 52))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 16,
                        style: .continuous
                    )
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(tile.name)
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(tile.tagline)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MatherTheme.card)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 16,
                        bottomTrailingRadius: 16, topTrailingRadius: 0,
                        style: .continuous
                    )
                )
            }
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
                radius: 8, y: 4
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tile.name)
    }
}
