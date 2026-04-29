# Water Cycle Lab

## Purpose

Water Cycle Lab is a small Explorer Lab inquiry activity for issue #753. It introduces evaporation, condensation, and precipitation through a concrete play loop instead of a quiz.

## V1 child loop

1. **Wonder** — ask what the warm sun might do to the pond.
2. **Evaporation** — child warms the pond; droplets rise as vapor.
3. **Condensation** — child gathers droplets into a cloud.
4. **Precipitation** — child makes rain fall from the heavy cloud.
5. **Collection** — rain refills the pond and the cycle can repeat.

## Design boundaries

- Child-facing flow uses short spoken prompts and large buttons; formal vocabulary is introduced after the action.
- The screen uses project-owned SwiftUI vector drawing only: sun, cloud, drops, rain, and pond are rendered with SF Symbols and shapes. No external or generated binary assets are imported, so no asset provenance file is required for v1.
- No timer, negative scoring, camera, location, network, or free-form child data.
- The activity broadens Explorer Lab copy to maths and science; future work can add a parent-facing note if more science inquiry activities are added.

## Proof

- Unit tests cover stage order, reset behavior, and completion count.
- Manual proof should include tapping the Explorer Lab tile and completing one cycle on compact phone and iPad layouts.
