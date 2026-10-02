import Testing
@testable import Mather

/// The UI journeys use these authored solutions. Keep this contract explicit so
/// a catalog revision cannot silently turn a successful remote/touch flow into a miss.
struct AngleCannonTests {
    @Test func authoredCampaignSolutionsMatchTheTouchAndRemoteJourneys() throws {
        let fixtures: [(String, Double, Double, Double, Double)] = [
            ("garden-guided", 35, 75, 35, 75),
            ("garden-raised", 35, 75, 45, 75),
            ("garden-fence", 35, 70, 45, 80),
            ("builder-corner", 15, 75, 45, 75),
            ("builder-quarter-turn", 0, 75, 90, 75),
            ("builder-transfer", 90, 75, 30, 75),
            ("moon-earth", 45, 70, 45, 80),
            ("moon-compare", 45, 80, 45, 70),
            ("moon-transfer", 40, 70, 50, 80)
        ]
        #expect(AngleArcadeCampaign.levels.map(\.id) == fixtures.map { $0.0 })
        for (id, startingAngle, startingPower, angle, power) in fixtures {
            let level = try #require(AngleArcadeCampaign.levels.first { $0.id == id })
            #expect(level.startingAngle == startingAngle)
            #expect(level.startingPower == startingPower)
            #expect(level.authoredSolution == AngleArcadeAim(angle: angle, power: power))
            #expect(level.succeeds(angle: angle, power: power))
            #expect((angle - startingAngle).truncatingRemainder(dividingBy: level.angleStep) == 0)
            #expect((power - startingPower).truncatingRemainder(dividingBy: AngleArcadeModel.powerStep) == 0)
        }
    }
}
