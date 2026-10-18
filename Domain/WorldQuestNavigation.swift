import Foundation

/// Geographic directional focus, independent of the question and answer.
struct WorldQuestNavigation {
    enum Direction: CaseIterable, Hashable { case up, down, left, right }
    let countries: [WorldQuestCountry]
    let aspectRatio: Double
    private let neighbors: [String: [Direction: String]]

    init(countries: [WorldQuestCountry], aspectRatio: Double) {
        self.countries = countries
        self.aspectRatio = aspectRatio
        var graph: [String: [Direction: String]] = [:]
        for origin in countries {
            for direction in Direction.allCases {
                let candidates = countries.filter { $0.id != origin.id }.compactMap { country -> (String, Double)? in
                    let dx = (country.anchor.x-origin.anchor.x)*aspectRatio
                    let dy = country.anchor.y-origin.anchor.y
                    let forward: Double
                    let sideways: Double
                    switch direction {
                    case .up: forward = -dy; sideways = dx
                    case .down: forward = dy; sideways = dx
                    case .left: forward = -dx; sideways = dy
                    case .right: forward = dx; sideways = dy
                    }
                    guard forward > 0.00000001 else { return nil }
                    return (country.id, hypot(forward, sideways) + 3*abs(sideways))
                }
                if let nearest = candidates.min(by: { a, b in a.1 == b.1 ? a.0 < b.0 : a.1 < b.1 }) {
                    graph[origin.id, default: [:]][direction] = nearest.0
                }
            }
        }
        neighbors = graph
    }

    /// Stable neutral westernmost start, never derived from the target.
    var initialID: String? { countries.min { $0.anchor.x < $1.anchor.x }?.id }

    func neighbor(from id: String, direction: Direction) -> String? { neighbors[id]?[direction] }

    func reachable(from id: String) -> Set<String> {
        var visited: Set<String> = [id]
        var queue = [id]
        while let current = queue.popLast() {
            for next in neighbors[current, default: [:]].values where visited.insert(next).inserted {
                queue.append(next)
            }
        }
        return visited
    }
}
