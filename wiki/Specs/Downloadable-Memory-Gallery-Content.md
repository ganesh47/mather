# Downloadable Memory Gallery Content

The TV gallery accepts a JSON document and PNG files from a static HTTPS host. The format is Mather's versioned content contract, using standard JSON and PNG, rather than a third-party learning-content standard. See [ADR-0008](../ADRs/ADR-0008-downloadable-memory-gallery-content.md).

## Authoring

The published content source is `memory-gallery/pack.json` in [ganesh47/mather-content](https://github.com/ganesh47/mather-content). Edit cards and facts there without editing Swift or building the app; its standalone validator and CI check publications. `Content/MemoryGallery/pack.json` in this app repository is the initial bootstrap snapshot. Keep card IDs stable across revisions. For a new illustration, place `ASSET_ID.png` next to the source JSON and add an asset entry and attribution record. Use a new asset ID whenever an illustration changes, so an existing file can remain immutable on the host.

Export and validate a release:

```bash
bash scripts/export_memory_gallery_pack.sh /tmp/mather-gallery-release 2
```

The exporter is a bootstrap/migration tool. It reads the JSON source, resolves new artwork next to it and existing artwork from the asset catalog, validates the pack and PNGs, and writes `pack.json` with exact byte counts and SHA-256 hashes plus `attribution.json`. An optional third argument selects a different source JSON and uses its adjacent attribution records. The initial export contains 76 cards and 82 PNGs, about 14 MB. Routine content updates use the content repository's Python validator and do not depend on this Swift exporter.

## Contract, schema version 1

Top-level fields:

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | integer | Must be `1`; change only for incompatible format changes. |
| `contentVersion` | positive integer | Increase on every publication. Bundled content starts at `1`. |
| `decks` | array | Exactly one deck each for `domesticAnimals`, `vehicles`, `planets`, and `countryFlags`. |
| `assets` | array | Downloaded PNG manifest; bundled image IDs may be referenced without entries. |

Each deck has `kind` and `cards`. Each card has `id`, `name`, `canonicalName`, `picture`, `metadata`, and `learningArtwork` (use an empty array when absent). Pictures have `kind` (`emoji`, `asset`, or `text`) and `value`:

```json
{"kind": "asset", "value": "crane-v2"}
```

Metadata requires `deck`, `category`, `kind`, and `factCards`. Facts have `title` and `value`. Optional metadata strings are `habitat`, `lifespan`, `weight`, `size`, `colors`, `use`, `movement`, and `sound`. Each learning artwork entry has `title` and `assetName`.

Asset entries have `id`, `file`, `byteCount`, and `sha256`. The filename must be `ID.png`; IDs use ASCII letters, digits, hyphens, or underscores. The hash is lowercase hexadecimal. Each country card requires Capital, Language, Currency, and Monument facts. Their titles currently drive existing game logic, so preserve those titles.

Limits: 4–250 cards per deck; unique card IDs across decks; 1–12 facts per card; nonempty required text with at most 500 characters; at most four learning artwork references per card; 200 PNGs maximum; 10 MB per PNG; 100 MB artwork total; 4096 pixels maximum on either dimension; 5 MB JSON maximum. The Swift validator is the authoritative contract.

## Hosting and configuration

Serve the exported files on the same HTTPS host, with `pack.json` and artwork in the same directory. Upload new immutable artwork first, then replace `pack.json`. Keep old artwork available for downloads already in progress. The current loader does not follow redirects to a different host; GitHub Release asset redirects therefore need a same-host static proxy or a future transport change.

The separate public repository [ganesh47/mather-content](https://github.com/ganesh47/mather-content) holds published JSON, PNGs, and image credits. The TV build setting `MEMORY_GALLERY_CONTENT_URL` defaults to `https://raw.githubusercontent.com/ganesh47/mather-content/main/memory-gallery/pack.json`. XcodeGen carries it into `MemoryGalleryContentURL` in Info.plist. One app update is required to install and configure the loader; later content publications require no app update. Set the build setting to an empty string to disable remote refresh.

Content releases use Git tags such as `memory-gallery-v2`; installed apps keep the stable main-branch URL. The content repository includes its own Python validator and CI so publishing new content does not require building Mather. Preserve attribution records for supplied artwork. No GitHub API token is needed by the app for this public raw-file feed.

The gallery checks when entering its category chooser. Updates are staged, validated, and committed only while the chooser is active. A session snapshots its cards; failed, cancelled, outdated, oversized, or incompatible updates preserve the previous complete pack. On first launch or cache loss, bundled content remains available. The iPad Memory flow has not yet adopted remote packs.

## Versioning and recovery

Installed apps ignore equal or lower content versions. To roll back faulty content, republish the previous content under a higher content version. Unsupported schema versions retain the installed pack. Future mechanics or categories require an app update. Content is curated by the publisher; structural validation and hashes do not fact-check it or authenticate a compromised publisher.

## End-to-end verification

`bash scripts/test_memory_gallery_content.sh` compiles the production loader, downloads the public feed and every PNG, plays a full session in each category, restores the disk cache, and verifies that an offline refresh retains it. CI runs this live test alongside the unit tests.

The `MatherTVUITests` target opens the real TV app, waits for the published pack version to activate, selects and answers a downloaded card, and relaunches to verify cache restoration. CI retains its screenshots in `TVContentResults.xcresult`. TestFlight delivery uses the existing tag-triggered release workflow for iOS and tvOS. Physical-device audio and Siri Remote feel still need a family-device check.
