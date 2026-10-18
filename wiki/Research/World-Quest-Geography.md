# World Quest geography research

Date: 2026-10-18

- Natural Earth 1:10m admin-0 countries supplies geographic polygons and India-viewpoint variants: https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-countries/
- Default data describes de facto boundaries; viewpoint choice must be explicit: https://www.naturalearthdata.com/about/disputed-boundaries-policy/
- Natural Earth data is public domain: https://www.naturalearthdata.com/about/terms-of-use/
- Country quiz roster: 193 UN member states plus the two observer states. https://www.un.org/en/about-us/member-states and https://www.un.org/en/about-us/non-member-states
- Apple supports remote directional input via onMoveCommand: https://developer.apple.com/documentation/swiftui/view/onmovecommand(perform:)

## Decisions

Use the v5.1.2 tagged India GeoJSON from Natural Earth's maintainer repository; pin its SHA-256. All 195 roster entries have polygons in this source. Preserve background territories separately from the quiz roster. Use Natural Earth's UN regions, splitting the Americas into North/South; Russia belongs to Europe, Turkey/Cyprus/Armenia/Azerbaijan/Georgia to Asia. Country names are curated English names, independent of source feature names.

Equal Earth provides a whole-world view with consistent relative areas. Focus anchors use Natural Earth's label coordinates; anchors outside their owning polygon are moved to a representative interior point on the nearest component. A marker denotes location, not territory size. The map never zooms toward an unanswered target. Quiz navigation must not speak candidate country names, otherwise it tests scanning a list rather than geographic recall.
