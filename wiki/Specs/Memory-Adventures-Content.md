# Memory Adventures content refresh

Date: 2026-10-02

## Purpose

Make memory play inviting through large, clear storybook pictures, spoken discoveries, and short pretend-play invitations. Preserve existing card IDs so recent-card history and stored selections continue to work.

## Artwork direction

Animals, birds, fruit, and fish use warm painterly storybook art with recognizable silhouettes. Each image contains one isolated subject, generous clear margins, no labels, medallions, watermarks, neighboring fragments, or misleading extra objects. Fruit grapes form one recognizable bunch. Birds retain recognizable beaks, feet, and feather colors. Fish retain their distinctive bands, fins, barbels, or curled tails. Existing NASA planet images and vehicle artwork remain unchanged.

The existing Memory bird images visibly contain numbered medallions and clipped neighboring birds. The refreshed catalog never references that sheet-derived artwork. Five visually similar pairs share a canonical identity so round selection can avoid presenting ambiguous pictures together: blue-and-gold macaws, yellow-crested cockatoos, black cockatoos, ibises, and green-yellow songbirds. Their visible labels and card IDs remain distinct. B09 is explicitly named “Storybook Golden Bird,” with a make-believe fact and imaginary-world metadata; it is not presented as a real species.

Stable bird IDs remain `bird-a01` through `bird-b18`. Repeated common labels now use short visual descriptors so answer choices remain distinct. Descriptors such as “Yellow-billed Toucan” describe the illustration; they do not claim a taxonomic identification or introduce new species facts.

## Asset mapping

| Collection | New artwork names | Existing artwork reused |
| --- | --- | --- |
| Animals | `MemoryAnimalCow`, `Dog`, `Cat`, `Pig`, `Horse`, `Rabbit`, `Duck`, `Rooster`, `Goat`, `Turkey`, `Goldfish`, `Mouse`, `Frog`, `Camel`, `Llama`, `Donkey`, `Ox` (each prefixed `MemoryAnimal`) | Sheep uses `CompareCampSheep` |
| Fruits | `MemoryFruitBanana`, `Mango`, `Orange`, `Grape`, `Watermelon`, `Pineapple`, `Strawberry` (each prefixed `MemoryFruit`) | Apple uses `CompareCampApple` |
| Birds | `MemoryBirdCleanA02`–`A11`, `A13`–`A18`, `B01`–`B10`, `B12`–`B15`, `B17`–`B18` | A01 uses `CompareCampMacaw`; A12 `CompareCampFlamingo`; B11 `CompareCampPeafowl`; B16 `CompareCampPuffin` |
| Fish | `MemoryFishClownfishStorybook`, `MemoryFishGoldfishStorybook`, `MemoryFishBettaStorybook`, `MemoryFishAngelfishStorybook`, `MemoryFishCatfishStorybook`, `MemoryFishSwordtailStorybook`, `MemoryFishTunaStorybook`, `MemoryFishSeahorseStorybook` | None |

The clean reused assets were generated for Compare Camp and retain their original provenance in [Compare Camp generated asset provenance](Compare-Camp-Generated-Asset-Provenance.md). Reuse must not be described as new generation. New generation and any derivatives must be recorded using their actual files and SHA-256 hashes; old deterministic fish provenance must not be attached to new storybook images.

## Spoken discoveries

Every refreshed animal, bird, fruit, and fish has `Look closely` and `Try it` fact cards alongside its existing facts. Vehicle and planet cards also invite observation and pretend journeys. Activities use hands, fingers, voices, or movement in place, require no reading, and avoid directing the child to touch real vehicles, machinery, or animals. Each card remains within the portable content pack’s twelve-fact limit.

Examples include finding a cat’s whiskers, making finger rabbit ears, curling a finger like a seahorse’s tail, fanning fingers like betta fins, and tracing a planet’s orbit in the air. Vehicle observation points to its existing key-part description; NASA pictures remain factual learning evidence.

## Acceptance checks

- IDs and catalog counts remain stable; visible answer names are distinct within each refreshed deck.
- Every picture reference resolves to a real catalog PNG; fish references use the new Storybook names.
- Each refreshed card has two short spoken discoveries and no more than twelve facts.
- Individual artwork is visually checked at small iOS card size and at TV distance; generated contact sheets are never shipped as card faces.
- Image provenance hashes match installed files. Reused assets retain original authorship and generation history.
- Exported downloadable content is refreshed only after the asset catalog is complete, with actual byte counts and hashes.

## Fact review and sources

Reviewed on 2026-10-02. New discovery prompts describe visible anatomy or invite clearly marked pretend play. They do not establish the species represented by a generated picture. Generic bird descriptions now report home and measurements as “Varies by species” instead of repeating precise unsupported ranges. Animals in the shared family deck are called animals rather than universally domestic animals.

- [NASA/JPL planet definitions](https://ssd.jpl.nasa.gov/planets/) supports planets going around the Sun. The hand activity uses a “loop,” avoiding a claim that actual orbits are perfect circles. Planet color observations refer to the displayed pictures; [NASA’s Neptune image caption](https://science.nasa.gov/resource/neptune-full-disk-view/) identifies the green/orange-filter Voyager composite rather than promising true-color imagery.
- [San Diego Zoo goat and sheep anatomy](https://animals.sandiegozoo.org/animals/goat-and-sheep) supports the illustrated goat’s beard, horns, and climbing/balancing cues. These prompts describe the depicted animal, not a claim that every domestic goat has identical horns.
- [National Aquarium freshwater angelfish](https://aqua.org/explore/animals/freshwater-angelfish) supports the imported tall-fin freshwater illustration’s South American river habitat. The previous coral-reef description was corrected; the card says Angelfish without claiming a precise generated species identity.
- [NOAA catfish identification](https://www.fisheries.noaa.gov/species/blue-catfish/commercial) supports the whisker-like barbels around the mouth. The pretend-play prompt imitates those visible feelers.
- [Aquarium of the Pacific seahorse observation](https://www.aquariumofpacific.org/news/story/pacific_seahorses_introduced_to_southern_california_gallery) supports a grasping tail; [University of Florida ornamental fish extension](https://ask.ifas.ufl.edu/publication/FA224.pdf) describes upright orientation, elongated snouts, and prehensile tails.
- [BirdLife Pied Kingfisher factsheet](https://datazone.birdlife.org/species/factsheet/pied-kingfisher-ceryle-rudis) supports water-body habitat across Africa and Asia; [SANBI biodiversity education](https://www.sanbi.org/wp-content/uploads/2018/03/havens-biodiversity.pdf) identifies its black-and-white plumage. [Hong Kong Bird Watching Society’s species account](https://avifauna.hkbws.org.hk/species/0200/028600) gives 25–30 cm length, correcting the old undersized range; unsupported weight and lifespan values were removed.
- [Birds Canada’s Asia checklist](https://avibase.bsc-eoc.org/checklist.jsp?region=asi) and [BirdLife’s African sunbird factsheet](https://datazone.birdlife.org/species/factsheet/plain-backed-sunbird-anthreptes-reichenowi) support sunbirds occurring in Asia and Africa rather than South American cloud forests. The card does not claim a particular sunbird species.

## Finalizing generated provenance

Run `python3 scripts/finalize_memory_adventure_art.py output/memory-adventures/generated-art.json` after import. The manifest’s records name the actual generated source file, installed PNG hash, and any real derivative changes. The script verifies those files, hashes, and catalog references before embedding constants in `MemoryContent.swift`. It also records unchanged reuse of Compare Camp PNGs. No runtime access to repository files is required.

Visual-review flags default to false. Set individual record `reviewed: true`, list individually reviewed reused assets in `reviewedReused`, or pass `--reviewed` only after inspecting every included asset. `--check` verifies that the checked-in Swift provenance matches the same manifest and review options without changing files.

The generated manifest may also supply three decorative `scenes` records for Builders, Rescue, and Space. The finalizer verifies their actual PNGs and emits all seventy card illustrations plus three scenes into `Memory-Adventures-Art-Provenance.json`, with source filenames and hashes rather than private absolute source paths. Scenes are decorative illustrations, not planet-scale diagrams or counting evidence.

## Public-domain donkey illustration

`MemoryAnimalDonkey` reuses the 960-pixel Wikimedia raster preview of [Donkey cartoon 04 by LadyofHats](https://commons.wikimedia.org/wiki/File:Donkey_cartoon_04.svg), unchanged. The file page identifies LadyofHats as the author and explicitly releases the illustration into the public domain worldwide. This card is third-party public-domain artwork, not generated art. Its attribution and real source PNG hash are retained separately in the generated Swift/JSON provenance. The installed image has one complete long-eared donkey with no labels or neighboring fragments.

## Validation and remaining follow-up

The implementation was checked with 116 memory-related unit tests, native iPhone/iPad/tvOS adventure UI tests, reviewed screenshots, and a loader smoke test that verifies all 100 exported PNGs and offline restoration. The v3 export is about 37.6 MB.

Integration onto v2.11 retains its missing-part Number Bonds prompts and distinct answers (0–9), rather than restoring the earlier repeated-total cards. Name matching also continues to accept equivalent visible answers across IDs. New engine regressions cover both equivalent and different missing-part answers.
