# Parent-controlled manual companion proof

Proposed 2026-10-02. Integration coordinator owns app entry points and project inclusion.

## Decision

Continue a reviewed Room Quest **idea**, not an exact session or mastered skill, between local iOS and TV devices. A parent manually enters a self-contained 36-symbol code using the Apple TV text-entry keyboard (or its paired remote keyboard). A parent reviews the decoded safe mission and explicitly maps it to a local learner before approving. No network, account, camera, microphone, entitlement or share-file importer is required.

The bounded payload contains schema version, a reviewed mission ID, total quantity (5 or 10), first-group quantity and an anonymous random receipt UUID. CRC-16 detects transcription errors; it is **not authentication, encryption or proof of origin**. No names, profiles, observations, attempts, dates, history or answers travel. Codes can be photographed or copied by a parent but the app does not share them externally. Receipt IDs identify assignments, not learners. The payload cannot carry full offline progress securely in a short code, so this proof does not claim sync or native Handoff.

Local import requires explicit recipient and parent approval. Consumed receipts are device-wide and cannot be imported twice or assigned to another learner. Replacement requires the current receipt ID from the review, so stale approvals cannot overwrite a newer mission. Local unlink retires the assignment but retains anonymous receipts. Profile reset removes assignments/observations and retains anonymous replay protection; resetAll deletes everything and necessarily removes replay protection. Storage corruption/future schema fails closed until explicit deletion.

A grown-up supplies large safe objects on a clear table; no searching, climbing, throwing or walking while looking at a screen. The child forms two groups and counts the whole. The parent can report “alone”, “with help” or “not yet” afterwards. This observation is local and distinct from direct app performance; absent reporting means unknown assistance. The proof creates no app correctness, mastery or historical child attribution.

## Consequences

A code is longer than a server-backed six-digit lookup code: 36 symbols (six groups of six) preserve a random 128-bit receipt and the entire mission offline. The TV keyboard route is available without a companion app connection. A parent may cancel at review or decline replacement. Conflicting device choices are resolved locally by explicit replacement; devices do not reconcile each other. Old device history remains family/device scoped. Integration must pass current learner ID/name and audio preference, expose this view only from parent-controlled navigation, include three new files on TV, and call deletion hooks on local learner deletion.
