# Compare Camp generated asset provenance

Date: 2026-10-02. Generated with the built-in ImageGen tool for this overhaul. All eleven assets are copied into the app asset catalog; no project reference depends on the generator's private output directory.

| Asset | Purpose | Output |
| --- | --- | --- |
| CompareCampLandscape | Decorative twilight camp background; separate from exact counting evidence | 1672 x 941, opaque RGB |
| CompareCampGuide | Welcoming fox guide with teal scarf and gold backpack | 1254 x 1254, transparent RGBA |
| CompareCampBadge | Adventure completion patch | 1254 x 1254, transparent RGBA |
| CompareCampApple | Exactly one red apple | 1254 x 1254, transparent RGBA |
| CompareCampFlower | Exactly one yellow flower head on a stem | 1254 x 1254, transparent RGBA |
| CompareCampLeaf | Exactly one broad green leaf | 1254 x 1254, transparent RGBA |
| CompareCampSheep | Exactly one full-body lamb | 1254 x 1254, transparent RGBA |
| CompareCampMacaw | Exactly one full-body scarlet macaw | 1254 x 1254, transparent RGBA |
| CompareCampPeafowl | Exactly one full-body peacock | 1254 x 1254, transparent RGBA |
| CompareCampFlamingo | Exactly one full-body pink flamingo | 1254 x 1254, transparent RGBA |
| CompareCampPuffin | Exactly one full-body Atlantic puffin | 1254 x 1254, transparent RGBA |

Art direction: warm rounded children's storybook art, painterly texture, clear silhouettes, teal/mint/honey accents. Transparent assets preserve the generated alpha channel. The backdrop provides low-detail negative space for overlaid UI. No generated image contains required text or mathematical answer evidence.

Counting assets were inspected individually before import: one intended subject, readable shape, no extra separate objects. The flower's friendly face is decorative, not an additional countable object. Runtime groups render each whole subject in an equal-size distinct tile using aspect-fit.

The bird set was generated after simulator inspection found numbered medallions and a cropped fragment in reused bird art. Each replacement is a single isolated bird without numbers or extra objects.

The other sixteen camp subject images reuse existing Memory assets in this repository. Their existing provenance remains with those assets; this overhaul does not relicense them or claim they were newly generated. The machine-readable `output/compare-camp/content-manifest.json` lists every camp's asset and SHA-256 hashes for the eleven new files.
