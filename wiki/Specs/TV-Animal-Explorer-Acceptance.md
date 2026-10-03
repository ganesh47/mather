# TV Animal Explorer acceptance

The Animals gallery adds a frozen bank of licensed real photographs and a photo
name quiz. The original illustrated animal name quiz remains reachable through
“Illustrated animal quiz”. Memory Adventures picture pairs and their quizzes
remain separate. No shared pair-matching mechanics change.

## Browsing and content

- Opening `tv-memory-category-animals` captures photo entries, explicit curated
  collections, and the independent `AnimalExplorerCatalog.contentVersion`.
- India means species found in India. It does not claim every photograph was
  taken in India. This distinction appears beside the collection title.
- Collection membership comes from the catalog, without guessing habitat or
  India membership from names or free text. Each species appears once per shelf.
- Named photos that appear in the browser emit exposure events. Detail selection
  also emits exposure if that exact photograph has not already appeared.
- Detail shows the animal name, visible photo description, grounded facts, and
  offline photo credit, license, license URL, source URL and derivative changes.
- Bundled photos work on first launch without a network connection. Image lookup
  also supports the existing verified content-store asset resolution.
- Pending dynamic packs cannot activate while Explorer is open. Closing Explorer
  activates a pending pack at the gallery boundary and restores Animals focus.

## Photo name quiz

- Quiz this collection uses up to six distinct species, with four distinct name
  choices each round. A collection needs at least four species to offer a quiz.
- Preserve the visual task: a large photograph on the left and name choices on
  the right, with Picture N of 6, Matched and Streak indicators.
- Preserve `tv-memory-answer-*`, `tv-memory-picture-prompt`, next/results,
  completion/replay, and no-timer identifiers used by gallery clients.
- The picture accessibility description conveys visible features without naming
  the answer before selection. Correct name and learning fact appear afterward.
- Actual correct and wrong choices determine score. One round accepts one answer.
  Repeated selection cannot duplicate score or learning events.
- Hints pause the clock, convey curated visible features, and emit help once per
  round. Play Pause opens that same paused hint screen during an unanswered quiz.
- Browsing is exposure, not mastery. The callback reports prior named-photo
  exposure and app hints, and never declares an answer to be a fresh probe.
- Coordinator-owned learning integration attributes evidence to the captured
  learner, deduplicates attempts, and keeps unknown adult help explicit. Timer
  speed does not establish mastery or change answer outcomes.

## Pace, accessibility and lifecycle

- Default is untimed. Options explicitly select a two-minute friendly timer.
- The shared `TVFriendlyChallengeClock` pauses independently for options, hints,
  background, feedback and expiry. A new round clears feedback pause; interruption
  pauses remain in effect until their screens or background state end.
- Expiry never submits an answer or lowers score. Choices stay usable. More time
  and Play untimed preserve the same unanswered picture and choices.
- Mute stops queued narration and blocks automatic/focus/repeated speech. VoiceOver
  remains supported through normal labels. No sound is needed to complete play.
- Reduce Motion suppresses focus scaling and screen transitions. Focus borders,
  answer icons and feedback remain visible without animation or color alone.
- Menu closes options/hint first, detail returns to its previous photo, quiz or
  completion returns to the photo browser, and browser returns to the gallery.
- Leaving Explorer stops timer and narration. Background pauses the timer and
  narration; returning clears only the background pause.

## Native verification

`AnimalExplorerUITests` covers India browsing, the complete photo bank, detail
credits, gallery focus restoration, four unique answers, safe picture labels,
actual score/feedback, duplicate-answer rejection, paused hints/options, mute,
Reduce Motion, timer expiry/recovery, completion/replay and the original quiz.

Coordinator should run these tests on the reserved 1080p tvOS simulator and
inspect retained screenshots for photo legibility, clipping, credits and remote
focus. Existing MemoryGalleryContentUITests remain the regression gate for dynamic
pack caching and adventure picture pairs/quizzes. Shared domain checks cover
clock pause nesting and lifecycle without depending on real-time UI delays.

Additional acceptance checks: first launch offline, verified-cache fallback,
background/foreground during timed play, pending pack activation only after
Explorer closes, profile-attributed exposure/help/answer deduplication, and
physical Siri Remote and VoiceOver/mute behavior. No native checks are claimed
complete merely because source or test code is present.

## Integration hooks

`MemoryGalleryTVView(onAnimalLearningEvent:)` forwards `AnimalExplorerLearningEvent`
to the coordinator-owned root adapter. `AnimalExplorerTVView` accepts captured
entries, collections, contentVersion, onClose, onClassicQuiz and onLearningEvent.
It writes no learning ledger or profile store directly. Photo catalog, attribution
DTOs, shared timer and project generation remain independently owned dependencies.

UI-test launch arguments are scoped to `-animal-explorer-ui-test`; the seed is 42.
Optional `-animal-explorer-fast-timer` uses three seconds solely to reach expiry
in a native test. `-animal-explorer-reduce-motion` exercises the same reduced-motion
path as the system setting. Neither flag changes correctness or learning outcomes.
