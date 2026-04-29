# Multiplication Array Prelude

## Status

Implementation slice for TestFlight feedback issue #767. This is the first small slice, not the full multiplication curriculum.

## Goal

Teach multiplication as equal rows and packing before asking the child to resize rectangles in Rectangle Factory.

The prelude should make this sequence visible and speakable:

1. See boxes packed in equal rows.
2. Count the packed total.
3. Hear row language such as "2 rows of 3 makes 6."
4. Move to Rectangle Factory as reinforcement.

## Product Shape

- Name: Packing Cards.
- Entry: Explorer Lab tile next to Rectangle Factory.
- Exit: completion screen offers the Rectangle Factory challenge.
- Direct Rectangle Factory entry remains available for older or ready children.

## Difficulty Progression

- Easy: 3 face-up picture-first cards. No multiplication symbol is required.
- Standard: 4 face-up cards. The equation appears after the picture and row language.
- Flip mode: 4 cards that begin face-down before revealing the same picture/equation pairing.

The TestFlight note used "fillipi"; this slice maps that to the existing Memory Match idea of "Flip mode" without exposing the typo.

## Fact Set

First teaching avoids `1 x n`, primes, and large products. The initial fact pool uses small rectangles such as `2 x 2`, `2 x 3`, `3 x 2`, `2 x 4`, `3 x 3`, `3 x 4`, and `4 x 3`.

## Asset Policy

This slice uses project-owned SwiftUI drawings for trays and packages. No bitmap or third-party image assets are added, so no external asset provenance is required.

## Follow-Ups

- Route Rectangle Factory to start with a product just practiced in Packing Cards.
- Add memory-pair matching instead of single-card total choices for a richer Flip mode.
- Add local telemetry for facts seen, first-try choices, hand-off, and first Rectangle Factory factor latency after prelude.
- Add UI screenshot coverage for compact phone and iPad layouts.
