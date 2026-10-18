# World Quest v1

Status: Family TestFlight pilot; physical-device acceptance pending. Date: 2026-10-18.

## Experience

TV launcher → pack (Starter, six continents, Whole World) → Explore / Practice / Timed → map → results. Starter defaults to untimed Practice and includes India, China, Japan, Australia, Egypt, South Africa, France, Italy, United Kingdom, United States, Canada, Brazil. All packs are available without unlocking.

Explore reveals focused names and continent on Select. Practice and Timed ask ten shuffled questions without replacement, or every country when a pack has fewer than ten. Only pack countries are navigable; the complete background map stays visible. Incorrect submissions retry without ending the question. A continent hint and answer reveal mark an answer assisted. Timed questions allow 20 seconds, starting after prompt narration and viewport transitions. Expiration reveals the answer. Select advances after success/reveal. Repeat prompt suspends time while speaking. Background/system interruptions pause until explicit resume.

Up at the top edge of country navigation reaches the map toolbar; Down from the toolbar returns to the previous map focus. World/regional view controls never depend on the answer. Menu returns to the launcher; Play/Pause repeats current guidance. Names are hidden from quiz focus, both visually and in accessibility. Explore speaks country names. VoiceOver suppresses custom speech. Reduce Motion removes camera/celebration motion.

Results distinguish independent, assisted, and revealed answers; show first-attempt accuracy and mean successful response time in Timed. Completed sessions earn local passport stamps. No scores persist for abandoned games. No cloud or ongoing-session persistence.

## Map and acceptance

Explicit 195-country roster; India-viewpoint Natural Earth boundaries; shared-edge simplification; Equal Earth projection; islands, holes, and date-line parts preserved. Small country markers show locations, not enlarged geography. Regional view includes world inset. Parent information lists source/version/viewpoint and quiz roster convention.

Validate roster completeness, geometry validity, shared edges, focus reachability, seeded order, timing boundaries and interruption behavior, assistance accounting, duplicate submission/completion guards, and local storage recovery. TV UI tests cover launcher, quiz feedback, countdown, repeat, reveal, completion, and exit focus. Run existing iOS tests and TV build/tests. Before enabling by default, inspect actual Siri Remote navigation, VoiceOver, Reduce Motion, small-country visibility, and map performance at couch distance on Apple TV HD.
