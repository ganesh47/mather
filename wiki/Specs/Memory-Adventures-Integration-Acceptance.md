# Memory Adventures integration acceptance

This change reconciles the preserved Memory Adventures work with Mather v2.11.0,
rather than replacing the newer app with the older feature checkout.

## Source accounting

The preserved boundary contains 24 modified tracked files, 147 new source/art
files and two ignored provenance/source inputs. The generated Xcode project is
regenerated from the merged project.yml. The ignored generated-art manifest and
donkey source stay local; the portable provenance JSON and actual asset catalog
files are published. Generated build products and simulator data are excluded.

The new authored code is MemoryAdventure, MemoryPairingEngine,
MemoryDeckChooserView and MemoryPairsTVView, plus their focused tests, exporter
finalizer and content/architecture documents. All three decorative adventure
scenes and the new animal, bird, fruit and fish images are retained. Unchanged
Compare Camp artwork retains its original provenance. The donkey retains its
public-domain author attribution.

## Released behavior retained

- iOS Memory uses a frozen IOSLearningCatalog snapshot, including corrections
  selected by the deck chooser and adventure card IDs.
- LearningContentImage resolves verified downloaded artwork.
- Child-scoped attempts and completed activity evidence remain recorded. Hint,
  exploration and spoken-answer support are recorded as help.
- The missing-part Number Bonds content and distinct answers from v2.11 remain.
  The engine accepts equivalent visible answers, while two label cards and
  different missing-part answers cannot form a match.
- Direct staged entry, country clue chapters, learning details, spoken discovery,
  Reduce Motion and delayed-feedback cancellation remain available.
- Existing TV launcher, profiles, evidence, quests and Room Quest are retained.
  New TV picture adventures and quiz sessions activate content at boundaries.

## Separate legacy Memory checkout

Its six changed files contributed country facts/16 flags, fact-strip presentation,
restart variety and tests. The released country catalog already retains all 16
IDs and richer Capital/Language/Currency/Monument facts and reveal presentation.
The new seeded session preserves the replay-variety intent without reinstating
the old hard-coded Canada assertion or the older three-fact presentation.
The original six-file patch and separate history remain preserved.

## Content compatibility

Both feeds stay at schema 1 and advance from version 2 to version 3. They retain
previously published asset bytes and files. TV supplies 76 cards/100 PNGs; iOS
supplies 170 cards/160 PNGs and all seven topics. iOS export derivatives are
documented in attribution and keep artwork below the existing 100 MB limit.

Both bundles use content version 3. Older valid caches/feeds cannot override the
refreshed bundle; newer complete verified packs still activate between sessions.
Old iOS artwork directories remain available for paused session snapshots.

## Validation gates

- All source/art hashes and provenance match preserved or documented derivatives.
- Python validators accept both feeds and stable shared asset hashes.
- Production loaders accept both candidates, validate every PNG, defer updates,
  restore offline and preserve newer bundles over older caches.
- iOS domain and native compact/iPad Memory, quest, evidence and migration checks.
- tvOS domain and real remote adventure/quiz/launcher regression checks.
- Repeated XcodeGen generation is stable; workflow lint and release-helper tests.
- Independent review of exact app/content/dependency heads precedes merge.
