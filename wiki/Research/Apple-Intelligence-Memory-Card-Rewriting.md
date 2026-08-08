# Research: Apple Intelligence for Memory Card Descriptions

**Issue**: n/a
**Status**: Completed
**Date**: 2026-08-08

## Question

What is the safest useful Apple Intelligence feature Mather can introduce while preserving full operation on iPhone 16e, iPhone 15 Pro, older devices, and iOS 18?

## Findings

### Platform and device support

The Foundation Models framework exposes the on-device language model behind Apple Intelligence on iOS 26 and later. Mather can continue targeting iOS 18 by weak-linking the framework, compiling conditionally, and guarding all use with `#available(iOS 26.0, *)`.

Apple Intelligence-capable phones include iPhone 15 Pro and 15 Pro Max and iPhone 16 models or later, including iPhone 16e. Eligibility alone is insufficient: Apple Intelligence must be enabled and its model must be ready for the current language and region.

Code must use `SystemLanguageModel.default.availability`, which distinguishes a ready model from an ineligible device, disabled Apple Intelligence, or a model that is not ready. Device-name checks would be incomplete and fragile.

### Product fit

Apple describes the on-device model as optimized for tasks such as summarization, extraction, and text generation, not as a source of authoritative world knowledge. Rewriting Mather's own curated card description is therefore a better first use than generating facts, answers, or an open-ended chat.

The Memory Learn sheet already shows deterministic content immediately and can update asynchronously. This naturally hides model load time and keeps unsupported-device behavior complete.

### Safety for a child audience

Apple's model and guardrails are baseline protections, not substitutes for app-specific safety. Mather should:

- accept no child-authored prompt;
- provide only bundled card content;
- request a short rewrite rather than new knowledge;
- retain the default system guardrails;
- cap tokens, sentences, and characters;
- reject unsafe, conversational, linked, markdown, emoji, and malformed output;
- use curated content on every failure;
- keep generated prose out of questions, answers, scoring, and progression.

A generated rewrite still cannot be mathematically proven to preserve every fact by a lexical sanitizer. Physical-device prompt regression testing remains a release requirement, and the curated fact chips remain the visible source of truth.

### Privacy and review

The system model runs on-device and can operate offline after its assets are ready. Mather does not need an API key or external AI service. Apple says data processed only on-device is not considered collected for App Privacy disclosure. Mather should nevertheless explain the feature in its privacy policy, visibly identify generated copy, offer the non-AI fallback, and never upload Foundation Models feedback attachments, prompts, transcripts, or outputs.

This design adds limited review documentation rather than a new data-collection category: explain the bounded on-device transformation, the label, and the fallback in review notes.

### Verification boundary

Simulator and injected adapters can prove compilation, UI behavior, sanitization, caching, and fallback paths. Actual model availability, latency, safety behavior, and language quality require an eligible physical device with model assets installed. Prompts should be rechecked after OS model updates because Apple documents model-behavior changes across system releases.

## Options Evaluated

| Option | Learning value | Safety/privacy | Unsupported devices | Decision |
|---|---|---|---|---|
| Rewrite curated Memory descriptions | Small but visible | Strongly bounded and on-device | Complete curated fallback | Adopt |
| Generate Memory facts or answers | Higher novelty | Hallucination can become teaching content | Requires fallback and validation | Reject |
| Open child chat | Broad interaction | Large safety and retention surface | Uneven experience | Reject |
| Cloud-generated descriptions | Similar visible result | Adds network, credentials, and child-data handling | Network dependency | Reject |

## Recommendation and Decision

Implement only the Memory Learn description rewrite as an optional enhancement. Preserve Mather's iOS 18 target and bundled content. Use a fresh one-shot session for each uncached card, greedy sampling, a small token budget, Mather's sanitizer, and in-memory-only caching. Cancel and identity-check asynchronous UI work so stale responses cannot replace another card.

Decision recorded in [ADR-0007](../ADRs/ADR-0007-on-device-memory-card-rewriting.md).

## Primary Sources

- [Apple Foundation Models overview](https://developer.apple.com/documentation/FoundationModels)
- [SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)
- [LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)
- [Improving the safety of generative model output](https://developer.apple.com/documentation/FoundationModels/improving-the-safety-of-generative-model-output)
- [Generative AI Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/generative-ai)
- [Foundation Models updates](https://developer.apple.com/documentation/updates/foundationmodels)
- [Apple Intelligence requirements](https://support.apple.com/121115)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
