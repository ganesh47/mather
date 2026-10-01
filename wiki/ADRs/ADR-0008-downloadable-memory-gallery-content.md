# ADR-0008: Downloadable Memory Gallery Content

**Date**: 2026-10-01
**Status**: Proposed

## Context

Memory Gallery currently obtains cards, facts, and artwork from Swift constants and the app asset catalog. Corrections and additions require an app release. Content should be independently publishable without introducing a service dependency into play.

## Decision

Implement an app-side prototype of a versioned JSON content pack delivered from a configurable HTTPS URL. A pack replaces the four existing TV gallery decks together. PNG artwork is listed by stable asset ID, relative filename, byte count, and SHA-256. Existing bundled artwork may also be referenced by its stable ID.

- Keep bundled decks as the first-launch and failure fallback.
- Use explicit `schemaVersion` and monotonically increasing `contentVersion` fields. Reject unsupported schemas and invalid cards or asset references.
- Download into a staging directory, verify all artwork, then atomically replace the active-pack pointer. A failed update leaves the last complete pack available.
- Keep a snapshot of cards for each play session. Start refresh when the gallery opens and download at most six images concurrently. Continue downloads if a child starts playing; persist a complete pending pack and activate it at the next category chooser or app launch. Never replace cards or artwork during play.
- Use Application Support for downloaded content. tvOS storage can be purged; always retain bundled fallback.
- Keep executable logic, scoring, and supported categories in the app. JSON contains declarative content only.
- Configure the feed with `MemoryGalleryContentURL` in the TV app's Info.plist. The default feed is `https://raw.githubusercontent.com/ganesh47/mather-content/main/memory-gallery/pack.json`, hosted in the separate public `ganesh47/mather-content` repository at the user's request. Git tags preserve content releases; the main-branch URL delivers updates.
- Fetch only HTTPS resources on the configured feed's host, including redirects. Hashes detect corruption; the HTTPS publisher is the trust boundary. A signing/key-rotation system is deferred.

## Rationale

JSON and PNG are portable, easy to review in Git, and require no database, account, or proprietary content tool. A full-pack transaction avoids mismatched facts and artwork. Existing `MemoryAnimal` values remain the rendering interface, limiting changes to gallery loading and image resolution.

## Alternatives Considered

- **Remote text only**: simpler, but new picture cards would still require app releases.
- **ZIP archives**: compact, but require archive tooling and additional extraction/path validation.
- **Live remote queries during play**: rejected because play must work offline and remain stable.
- **Remote game definitions/code**: deferred; this change distributes content for existing mechanics.

## Consequences

One app update is required to add the loader. Subsequent card, fact, and illustration updates can be published independently. Content authors must validate packs before publishing. New categories, new interactions, and schema changes unsupported by installed apps require an app update. The iPad Memory flow remains bundled in this prototype; it can adopt the same pack format later.
