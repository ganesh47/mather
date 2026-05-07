import Foundation

extension GameplayThreadCatalog {
    /// Basic shape names thread (circle, triangle, square, rectangle, oval, diamond, star, heart).
    /// Replaces the System-A ShapeGeometryContent / LearningCardIntroView pipeline so all
    /// subject-card threads share the single GameplayThreadView infrastructure.
    static let shapes: GameplayThreadDefinition = GameplayThreadDefinition(
        id: "shapes",
        title: "Shape Names",
        category: GameplayCategory(
            id: "geometry",
            title: "Geometry",
            subtitle: "Shapes and their clues"
        ),
        propertyTypes: [
            GameplayPropertyType(id: "name",  displayName: "Name",  prompt: "Find the shape name."),
            GameplayPropertyType(id: "clue",  displayName: "Clue",  prompt: "Find the matching clue."),
            GameplayPropertyType(id: "sides", displayName: "Sides", prompt: "Find the sides clue."),
        ],
        entities: [
            GameplayEntity(id: "shape-circle", name: "Circle", summary: "Round with no corners or sides.", visualKey: "●", properties: [
                GameplayProperty(id: "shape-circle-name",  typeID: "name",  value: "Circle",          explanation: "Circle is this shape's name.",                  visualKey: "●"),
                GameplayProperty(id: "shape-circle-clue",  typeID: "clue",  value: "Round, no corners", explanation: "A circle is round with no corners."),
                GameplayProperty(id: "shape-circle-sides", typeID: "sides", value: "0 sides",          explanation: "A circle has no straight sides."),
            ]),
            GameplayEntity(id: "shape-triangle", name: "Triangle", summary: "Three sides and three corners.", visualKey: "▲", properties: [
                GameplayProperty(id: "shape-triangle-name",  typeID: "name",  value: "Triangle",       explanation: "Triangle is this shape's name.",                 visualKey: "▲"),
                GameplayProperty(id: "shape-triangle-clue",  typeID: "clue",  value: "3 corners",      explanation: "A triangle has three corners."),
                GameplayProperty(id: "shape-triangle-sides", typeID: "sides", value: "3 sides",        explanation: "A triangle has three straight sides."),
            ]),
            GameplayEntity(id: "shape-square", name: "Square", summary: "Four equal sides and four square corners.", visualKey: "■", properties: [
                GameplayProperty(id: "shape-square-name",  typeID: "name",  value: "Square",           explanation: "Square is this shape's name.",                   visualKey: "■"),
                GameplayProperty(id: "shape-square-clue",  typeID: "clue",  value: "4 equal sides",    explanation: "All four sides of a square are the same length."),
                GameplayProperty(id: "shape-square-sides", typeID: "sides", value: "4 sides",          explanation: "A square has four straight sides."),
            ]),
            GameplayEntity(id: "shape-rectangle", name: "Rectangle", summary: "Four square corners, opposite sides matching.", visualKey: "▭", properties: [
                GameplayProperty(id: "shape-rectangle-name",  typeID: "name",  value: "Rectangle",      explanation: "Rectangle is this shape's name.",                visualKey: "▭"),
                GameplayProperty(id: "shape-rectangle-clue",  typeID: "clue",  value: "Long box",       explanation: "A rectangle is like a stretched square."),
                GameplayProperty(id: "shape-rectangle-sides", typeID: "sides", value: "4 sides",        explanation: "A rectangle has four straight sides."),
            ]),
            GameplayEntity(id: "shape-oval", name: "Oval", summary: "Stretched like an egg, no corners.", visualKey: "⬭", properties: [
                GameplayProperty(id: "shape-oval-name",  typeID: "name",  value: "Oval",               explanation: "Oval is this shape's name.",                     visualKey: "⬭"),
                GameplayProperty(id: "shape-oval-clue",  typeID: "clue",  value: "Egg shape",          explanation: "An oval is round and stretched like an egg."),
                GameplayProperty(id: "shape-oval-sides", typeID: "sides", value: "0 sides",            explanation: "An oval has no straight sides."),
            ]),
            GameplayEntity(id: "shape-diamond", name: "Diamond", summary: "A square turned onto a point.", visualKey: "◆", properties: [
                GameplayProperty(id: "shape-diamond-name",  typeID: "name",  value: "Diamond",          explanation: "Diamond is this shape's name.",                  visualKey: "◆"),
                GameplayProperty(id: "shape-diamond-clue",  typeID: "clue",  value: "Point on top",     explanation: "A diamond sits with a point at top and bottom."),
                GameplayProperty(id: "shape-diamond-sides", typeID: "sides", value: "4 sides",          explanation: "A diamond has four straight sides."),
            ]),
            GameplayEntity(id: "shape-star", name: "Star", summary: "Points reaching out from the middle.", visualKey: "★", properties: [
                GameplayProperty(id: "shape-star-name",  typeID: "name",  value: "Star",               explanation: "Star is this shape's name.",                     visualKey: "★"),
                GameplayProperty(id: "shape-star-clue",  typeID: "clue",  value: "Points out",         explanation: "A star has sharp points reaching outward."),
                GameplayProperty(id: "shape-star-sides", typeID: "sides", value: "5+ points",          explanation: "A star has five or more pointed tips."),
            ]),
            GameplayEntity(id: "shape-heart", name: "Heart", summary: "Two bumps on top and one point below.", visualKey: "♥", properties: [
                GameplayProperty(id: "shape-heart-name",  typeID: "name",  value: "Heart",             explanation: "Heart is this shape's name.",                    visualKey: "♥"),
                GameplayProperty(id: "shape-heart-clue",  typeID: "clue",  value: "2 bumps, 1 point",  explanation: "A heart has two bumps at the top and a point at the bottom."),
                GameplayProperty(id: "shape-heart-sides", typeID: "sides", value: "Curved",            explanation: "A heart is made of curved lines, not straight sides."),
            ]),
        ],
        stages: [
            GameplayStageDefinition(
                id: "shapes-flashcards",
                kind: .flashcards,
                title: "Shape Names",
                prompt: "Meet each shape and its name.",
                maximumItemCount: 8
            ),
            GameplayStageDefinition(
                id: "shapes-easy-memory",
                kind: .easyMemory,
                title: "Name Match",
                prompt: "Match each shape to its clue.",
                propertyTypeIDs: ["name", "clue"],
                maximumItemCount: 6
            ),
            GameplayStageDefinition(
                id: "shapes-bond-blast",
                kind: .bondBlast,
                title: "Shape Blast",
                prompt: "Connect shapes, names, and clues.",
                propertyTypeIDs: ["name", "clue", "sides"],
                maximumItemCount: 6
            ),
        ]
    )
}
