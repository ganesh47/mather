import SwiftUI

/// Paths are built once from the bundle, rather than rebuilding geometry on timer ticks.
@MainActor
final class WorldMapGeometry {
    let catalog: CountryCatalog
    let paths: [(String, Path)]
    let countries: [String: WorldQuestCountry]

    init(catalog: CountryCatalog) {
        self.catalog = catalog
        countries = Dictionary(uniqueKeysWithValues: catalog.countries.map { ($0.id, $0) })
        paths = catalog.features.map { feature in
            let path = Path { path in
                for ring in feature.rings {
                    guard let first = ring.first else { continue }
                    path.move(to: CGPoint(x: first.x, y: first.y))
                    for point in ring.dropFirst() { path.addLine(to: CGPoint(x: point.x, y: point.y)) }
                    path.closeSubpath()
                }
            }
            return (feature.id, path)
        }
    }

    func viewport(for zoom: WorldQuestZoom, focusedID: String?, pack: WorldQuestPack) -> CGRect {
        guard zoom != .world, let country = focusedID.flatMap({ countries[$0] }) else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        if zoom == .close {
            // A focus-centered lens is available for every candidate, never target-centered.
            let width = 0.13
            let height = 0.22
            return CGRect(x: min(1-width, max(0, country.anchor.x-width/2)),
                          y: min(1-height, max(0, country.anchor.y-height/2)), width: width, height: height)
        }
        let region = catalog.countries.filter { $0.continent == country.continent }
        let xs = region.map(\.anchor.x), ys = region.map(\.anchor.y)
        let left = max(0, (xs.min() ?? 0) - 0.045)
        let right = min(1, (xs.max() ?? 1) + 0.045)
        let top = max(0, (ys.min() ?? 0) - 0.07)
        let bottom = min(1, (ys.max() ?? 1) + 0.07)
        return CGRect(x: left, y: top, width: right-left, height: bottom-top)
    }
}

enum WorldQuestZoom: String, CaseIterable { case world = "World", region = "Region", close = "Closer" }

@MainActor
struct WorldQuestMapView: View, Equatable {
    let geometry: WorldMapGeometry
    let selectableIDs: Set<String>
    let focusedID: String?
    let revealedID: String?
    let hintContinent: WorldQuestContinent?
    let viewport: CGRect

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.geometry === rhs.geometry && lhs.selectableIDs == rhs.selectableIDs &&
        lhs.focusedID == rhs.focusedID && lhs.revealedID == rhs.revealedID &&
        lhs.hintContinent == rhs.hintContinent && lhs.viewport == rhs.viewport
    }

    var body: some View {
        Canvas { context, size in
            draw(context: context, size: size, viewport: viewport, inset: false)
            if viewport.width < 0.99 || viewport.height < 0.99 {
                let insetSize = CGSize(width: 230, height: 125)
                var insetContext = context
                insetContext.translateBy(x: size.width - 248, y: size.height - 143)
                insetContext.fill(Path(roundedRect: CGRect(origin: .zero, size: insetSize), cornerRadius: 12),
                                  with: .color(Color(red: 0.025, green: 0.08, blue: 0.13).opacity(0.95)))
                draw(context: insetContext, size: insetSize, viewport: CGRect(x: 0, y: 0, width: 1, height: 1), inset: true)
            }
        }
        .background(Color(red: 0.025, green: 0.09, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.15), lineWidth: 2))
        .accessibilityHidden(true)
    }

    private func draw(context: GraphicsContext, size: CGSize, viewport: CGRect, inset: Bool) {
        let scale = min((size.width - 24) / (viewport.width * geometry.catalog.aspectRatio),
                        (size.height - 24) / viewport.height)
        let sx = scale * geometry.catalog.aspectRatio
        let sy = scale
        let origin = CGPoint(x: (size.width-viewport.width*sx)/2 - viewport.minX*sx,
                             y: (size.height-viewport.height*sy)/2 - viewport.minY*sy)
        var mapContext = context
        mapContext.clip(to: Path(CGRect(origin: .zero, size: size)))
        mapContext.translateBy(x: origin.x, y: origin.y)
        mapContext.scaleBy(x: sx, y: sy)
        for (id, path) in geometry.paths {
            let isRevealed = id == revealedID
            let isFocused = id == focusedID
            let isPlayable = selectableIDs.contains(id)
            let isHint = hintContinent != nil && geometry.countries[id]?.continent == hintContinent
            let color: Color
            if isRevealed { color = .green }
            else if isFocused { color = .yellow }
            else if isHint { color = Color(red: 0.34, green: 0.66, blue: 0.76) }
            else if isPlayable { color = Color(red: 0.40, green: 0.58, blue: 0.57) }
            else { color = Color(red: 0.19, green: 0.30, blue: 0.34) }
            mapContext.fill(path, with: .color(color), style: FillStyle(eoFill: true))
            mapContext.stroke(path, with: .color(.white.opacity(0.48)), lineWidth: (inset ? 0.3 : 0.75)/sx)
        }
        // Markers are locations, not country-sized hit areas or altered boundaries.
        for country in geometry.catalog.countries where selectableIDs.contains(country.id) {
            let focus = country.id == focusedID
            let reveal = country.id == revealedID
            guard country.area < 2 || focus || reveal else { continue }
            let center = CGPoint(x: origin.x + country.anchor.x*sx, y: origin.y + country.anchor.y*sy)
            guard CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4).contains(center) else { continue }
            let radius: CGFloat = inset ? (focus || reveal ? 3 : 1.5) : (focus || reveal ? 10 : 3)
            let marker = Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2))
            context.fill(marker, with: .color(reveal ? .green : focus ? .yellow : .white.opacity(0.8)))
            if (focus || reveal) && !inset {
                context.stroke(marker, with: .color(.white), lineWidth: 3)
                let ring = Path(ellipseIn: CGRect(x: center.x-17, y: center.y-17, width: 34, height: 34))
                context.stroke(ring, with: .color(reveal ? .green : .yellow), lineWidth: 2)
            }
        }
        if inset {
            let rect = CGRect(x: origin.x+self.viewport.minX*sx, y: origin.y+self.viewport.minY*sy,
                              width: self.viewport.width*sx, height: self.viewport.height*sy)
            context.stroke(Path(rect), with: .color(.yellow), lineWidth: 1.5)
        }
    }
}

/// The map supplies its own focus ring; do not scale or plate the geographic canvas.
struct WorldQuestMapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label }
}
