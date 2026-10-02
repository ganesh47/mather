# ADR-0011: Local TV learning context and assistance evidence

Status: accepted for the October enrichment release.

TV games currently keep device scores. Those scores cannot identify a child or establish transfer. We retain them unchanged, and add a separate local ledger for the new finite Sum Sprint and Shape Detective sessions. Family play is the default; selecting a named learner scopes new attempts and checkpoints. Switching learners happens in the launcher, outside an active session.

Existing ItemAttempt and ActivityResult envelopes are reused. Optional variant, app-hint, fresh-probe and adult-help fields decode older journals unchanged. Correct without an app hint is observable; adult assistance remains unknown unless reported. Parent observations and imported continuity are separate evidence, never rewritten as direct app performance.

The TV ledger uses versioned Codable data in UserDefaults, with immutable event/session IDs, duplicate rejection, profile validation and conservative decoding. Unsupported data is preserved and blocks writes instead of silently replacing history. Existing device progress is displayed as device history with unknown ownership. There is no cloud account, automatic sync, or new entitlement. A manual parent-approved handoff can provide a later continuity proof with explicit recipient mapping.

Each activity owns and validates its frozen typed checkpoint. The coordinator owns profile context, ledger, root wiring, project generation and release. Tests cover decoding old evidence, duplicate/resumed events, mixed profiles, family separation, unsupported storage and support carried across resume.
