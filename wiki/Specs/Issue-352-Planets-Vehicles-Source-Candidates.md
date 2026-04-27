# Issue 352 — Planets + Vehicles Source Candidates

This is the source-candidate/provenance artifact for the next image-backed Memory Match slice. It intentionally does **not** approve or import any image binary. Each row points to source families that are likely to be public-domain or permissively reusable, then lists the exact checks required before an asset can move from `needsVettedSource` to imported `.asset(...)` usage.

Related plan: `wiki/Specs/Issue-352-Planets-Vehicles-Asset-Plan.md`.

## License guardrails

### NASA / JPL / USGS planetary imagery

Preferred for Planets.

- NASA media: NASA content is generally not subject to copyright in the United States and may be used for educational/informational purposes when used factually and without implying endorsement. NASA should be acknowledged as the source. NASA logos/insignia/logotypes are not public-domain assets and should not be included in card crops.
- JPL public web images: unless otherwise noted, images/video on public `jpl.nasa.gov` sites may be used without prior permission. Use the page credit line, commonly `Courtesy NASA/JPL-Caltech`, and do not imply endorsement. Watch for third-party ownership notes in captions.
- USGS Astrogeology/PDS products are strong candidates only when the product page states public-domain/no-use-constraint terms or points back to NASA mission data with no third-party restriction.

Primary policy references:

- <https://www.nasa.gov/nasa-brand-center/images-and-media/>
- <https://www.jpl.nasa.gov/jpl-image-use-policy/>

### Wikimedia Commons / public-domain / CC0 / Creative Commons vehicle imagery

Preferred for Vehicles only after file-level verification.

- Use Commons file pages, not copied thumbnails from random mirrors.
- Acceptable first-pass licenses: Public Domain, CC0, CC BY, CC BY-SA, or equivalent compatible free license.
- Avoid non-free, fair-use, editorial-only, no-derivatives, non-commercial, personality-rights-heavy, trademark-forward, logo-forward, license-plate-visible, or uploader-unclear images.
- CC BY / CC BY-SA assets require attribution metadata in the provenance record and likely an in-app/docs attribution surface before import. Prefer PD/CC0 where visual quality is sufficient.

Primary policy reference:

- <https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia>

## Provenance record required before import

Create or update a future provenance manifest before any card references a vetted asset. Minimum fields per asset:

```yaml
assetName: MemoryPlanetEarth
cardId: planet-earth
sourceUrl: https://...
sourcePageTitle: ...
creator: ...
creditLine: ...
license: Public Domain | CC0 | CC BY 4.0 | CC BY-SA 4.0 | ...
licenseUrl: https://...
retrievedAt: YYYY-MM-DD
originalFileName: ...
originalSha256: ...
derivativeFileName: MemoryPlanetEarth.png
derivativeSha256: ...
derivativeChanges: square crop, resize, background cleanup, no semantic alteration
verification:
  sourcePageArchived: false
  licenseAllowsReuse: true
  noThirdPartyRestrictionFound: true
  noLogoOrEndorsementRisk: true
  noPeopleOrPrivacyRisk: true
  childCardLegibilityChecked: true
```

## Global verification checklist for every asset

Before import, the asset owner must verify all items below and record the answer in the provenance manifest:

1. Open the original source page and capture the canonical URL.
2. Record source page title, creator/agency/uploader, mission/source collection where applicable, license label, license URL, and credit line.
3. Confirm reuse terms allow this app/repo use. Reject if the page says copyright-protected third-party material, non-commercial only, no-derivatives, editorial-only, unknown license, or unclear permission.
4. Confirm the crop does not include NASA/JPL logos, vehicle manufacturer logos as the focal point, readable license plates, identifiable private people, watermarks, or misleading fantasy art.
5. Download from the source page's original/high-resolution file link, not a search-result thumbnail.
6. Save original filename and SHA-256 before editing.
7. Export a square derivative with the subject centered and readable at Memory card size.
8. Save derivative filename and SHA-256.
9. Add attribution/provenance metadata in repo docs/manifest before adding `App/Assets.xcassets/<assetName>.imageset`.
10. Only then switch the deck card from `.emoji`/`.text` to `.asset(assetName)` and update tests from planned coverage to actual asset-reference coverage.

## Planet candidates

| Card id | Planned asset | Preferred candidate sources | License constraints to verify | Per-asset visual checks |
| --- | --- | --- | --- | --- |
| `planet-mercury` | `MemoryPlanetMercury` | NASA Photojournal Mercury global mosaics, especially MESSENGER/Mariner products such as <https://science.nasa.gov/photojournal/a-world-view/> and <https://science.nasa.gov/photojournal/full-global-mercury-mosaic/> | Must be NASA/mission imagery with no third-party restriction; credit exact source page/mission; avoid NASA logos. | Gray cratered disk reads as Mercury, not Moon; full disk or clean crop; no over-colorized fantasy treatment. |
| `planet-venus` | `MemoryPlanetVenus` | JPL/NASA Magellan Venus global views such as <https://www.jpl.nasa.gov/images/pia00252-venus-computer-simulated-global-view-of-northern-hemisphere/> and <https://www.jpl.nasa.gov/images/pia00478-venus-global-view-centered-at-180-degrees/> | Verify JPL page has no third-party restriction and use its credit line. Note if colors are radar/simulated rather than true optical color. | Pale yellow/orange cloud or radar globe remains distinct from Mars; avoid scary lava-only imagery for ages 5–8 unless metadata explains it. |
| `planet-earth` | `MemoryPlanetEarth` | NASA Visible Earth / Blue Marble family, e.g. <https://visibleearth.nasa.gov/images/57752/blue-marble-land-surface-shallow-water-and-shaded-topography> and NASA image/article pages for full-disk Earth. | Verify NASA/Visible Earth terms and credit; avoid agency insignia in crop. | Blue oceans, clouds, and land are recognizable; square crop keeps the globe centered. |
| `planet-mars` | `MemoryPlanetMars` | NASA/JPL Mars global views from Viking/MGS/Mars missions via NASA Photojournal/JPL image pages; start from <https://science.nasa.gov/photojournal/galleries/pj-mars/>. | Must be NASA/JPL mission product with no third-party restriction; record mission and processing notes. | Rust-red disk with darker markings; distinct from Venus; no rover landscape unless intentionally changing card concept. |
| `planet-jupiter` | `MemoryPlanetJupiter` | NASA/JPL Jupiter global portraits from Cassini/Juno/Voyager via <https://science.nasa.gov/photojournal/galleries/jupiter/> and JPL image search. | Verify source image is NASA/JPL/mission public imagery; note any citizen-scientist processing or third-party credit before accepting. | Bands and Great Red Spot visible at card size; avoid busy spacecraft/black border compositions. |
| `planet-saturn` | `MemoryPlanetSaturn` | NASA/JPL Cassini Saturn portraits via <https://science.nasa.gov/photojournal/galleries/saturn/> and JPL image pages. | Verify JPL/NASA credit and no third-party restriction; avoid images where logos/annotations are embedded. | Rings fit fully inside square crop; planet remains large enough for kids to identify. |
| `planet-uranus` | `MemoryPlanetUranus` | NASA/JPL Voyager 2 Uranus image pages via <https://science.nasa.gov/photojournal/galleries/uranus/>. | Verify Voyager/NASA/JPL source and credit line; no third-party restriction. | Pale cyan/blue-green disk, visually calmer/lighter than Neptune; do not over-enhance into fantasy colors. |
| `planet-neptune` | `MemoryPlanetNeptune` | NASA/JPL Voyager 2 Neptune image pages via <https://science.nasa.gov/photojournal/galleries/neptune/>. | Verify Voyager/NASA/JPL source and credit line; no third-party restriction. | Deep blue disk with subtle cloud/storm texture; visually distinct from Uranus. |

## Vehicle candidates

Use file-level pages from Wikimedia Commons or similarly clear PD/CC0 sources. The links below are candidate search/category entry points, not approvals.

| Card id | Planned asset | Candidate source entry points | License constraints to verify | Per-asset visual checks |
| --- | --- | --- | --- | --- |
| `car` | `MemoryVehicleCar` | Commons media search: <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20car%20side%20view>; Commons categories for automobiles/side views. | Prefer PD/CC0. If CC BY/SA, attribution required. Reject visible plates, brand-logo-forward crops, private people, or non-free auto brochure images. | Four wheels or clear car silhouette; child-friendly, uncluttered; not confused with taxi/truck. |
| `bus` | `MemoryVehicleBus` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20bus%20side%20view>; Commons school bus/city bus categories. | Prefer PD/CC0/government images; reject readable route ads/plates/logos unless crop removes them and license permits derivatives. | Long body, many windows, large wheels readable; visually different from truck/train. |
| `train` | `MemoryVehicleTrain` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20train%20locomotive>; Commons locomotive/train categories. | Verify license at file page; avoid modern operator logos/trademark-forward liveries unless incidental and licensed. | Rails or locomotive shape visible; not a bus-like crop; square crop keeps nose/cars recognizable. |
| `plane` | `MemoryVehiclePlane` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20airplane%20in%20flight>; NASA aircraft photos only if no logos/people issues. | Prefer U.S. government/NASA/PD or CC0. Reject airline-logo-forward photos and airport scenes with people/privacy issues. | Wingspan readable in square crop; simple sky/runway background; not too tiny. |
| `boat` | `MemoryVehicleBoat` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20boat%20sailboat>; Commons sailboat/boat categories. | Verify free license; reject watermarked stock images and identifiable people as primary subject. | Hull/waterline visible; simple boat shape; not a distant speck. |
| `bike` | `MemoryVehicleBike` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20bicycle%20side%20view>; Commons bicycle side-view/diagrams. | Prefer PD/CC0 diagrams/photos; reject brand-advertising catalog images. | Two wheels and handlebar clear; no rider needed; distinct from scooter. |
| `truck` | `MemoryVehicleTruck` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20box%20truck%20side%20view>; Commons truck categories. | Verify free license; crop/remove readable plates/logos if license permits derivative crop. | Cargo box/bed obvious; larger/heavier than car; clean silhouette. |
| `tractor` | `MemoryVehicleTractor` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20tractor%20side%20view>; Commons tractor categories. | Prefer PD/CC0 or government/agricultural extension images with clear terms; avoid manufacturer-promo photos. | Big rear tire is visible; farm context okay if uncluttered; no logo focal point. |
| `helicopter` | `MemoryVehicleHelicopter` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20helicopter%20side%20view>; NASA/U.S. government helicopter images when terms are clear. | Verify government image is actually public-domain and not contractor-owned; avoid agency logos as focal point. | Main rotor and tail boom fit inside square crop; aircraft not too small. |
| `rocket` | `MemoryVehicleRocket` | NASA/JPL/Kennedy public images and Commons PD rocket images, e.g. <https://images.nasa.gov/search-results?q=rocket%20launch> and <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20rocket%20launch>. | NASA logo/mission patch/contractor logo cannot be focal point; credit NASA page; verify no third-party restriction. | Upright rocket or clear launch plume; high contrast; child-safe, not explosion-like. |
| `scooter` | `MemoryVehicleScooter` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20scooter%20side%20view>; Commons scooter/moped categories. | Prefer PD/CC0; reject modern brand-catalog images and visible plates. | Seat/motor body makes it distinct from bike; clean side view; no rider required. |
| `taxi` | `MemoryVehicleTaxi` | <https://commons.wikimedia.org/wiki/Special:MediaSearch?type=image&search=public%20domain%20yellow%20taxi%20side%20view>; Commons taxi categories. | Harder licensing/trademark/privacy case: reject readable plates, operator branding, and people; CC BY/SA requires attribution. If no clean source is found, use project-owned/generated-and-approved art instead. | Yellow/checker/taxi sign cue visible; not just a generic car; crop removes license plates. |

## Recommended next slice

1. Pick **one planet** and **one vehicle** as a pilot import, preferably `MemoryPlanetEarth` from NASA Visible Earth and a PD/CC0 `MemoryVehicleBike` or `MemoryVehicleBoat` from Commons.
2. Create the provenance manifest with the fields above.
3. Import only those two verified derivatives into `App/Assets.xcassets`.
4. Switch only those two cards to `.asset(...)`.
5. Update tests to assert imported asset references have provenance entries and non-imported planned assets still remain `needsVettedSource`.

Do not bulk-import until the pilot validates attribution, asset-catalog naming, card legibility, and test shape.
