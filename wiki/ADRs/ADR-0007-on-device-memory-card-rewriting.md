# ADR-0007: On-Device Memory Card Rewriting

**Status**: Accepted
**Date**: 2026-08-08
**Deciders**: ganesh47

## Context

Mather embeds curated Memory Match descriptions and facts so learning never depends on a network or generative model. On Apple Intelligence-capable devices, the Foundation Models framework can make those descriptions warmer and easier for a young child to understand. The framework starts at iOS 26, while Mather supports iOS 18 and devices that are not eligible for Apple Intelligence.

The feature is for children ages 5–8, so generated text must remain bounded, attributable, disposable, and unable to affect game rules or factual source cards.

## Decision

Use the on-device `SystemLanguageModel` only to rewrite an already-curated Memory card description.

- Keep the deployment target at iOS 18.
- Compile the adapter when `FoundationModels` is present and guard execution with iOS 26 availability.
- Check `SystemLanguageModel.default.availability` before creating a session.
- Use a fresh `LanguageModelSession` with deterministic greedy sampling and a small response-token limit.
- Supply the curated description plus bounded card facts; request at most two sentences and no new facts.
- Apply Mather's output sanitizer. Any unavailable state, error, empty output, unsafe output, or overlong output returns the embedded description.
- Cache an accepted rewrite in memory for the current app process only. Do not persist prompts, transcripts, or generated text.
- Label accepted generated copy as Apple Intelligence in the Learn sheet.
- Never use generated output for answers, scoring, progression, or card facts.

## Rationale

This is a text-transformation task grounded in app-owned content, which matches the on-device model better than asking it for world knowledge. The current Learn sheet already paints deterministic content synchronously and replaces it asynchronously, so model latency and availability never block the child.

The system framework keeps inference on-device and requires no API key or cloud service. Runtime availability—not a hard-coded device list—correctly handles ineligible devices, disabled Apple Intelligence, and a model that is not ready.

## Alternatives Considered

- **Generate facts or answers**: rejected because model output must not become Mather's source of truth.
- **Open-ended child chat**: rejected because it expands safety, moderation, retention, and interaction risks without a clear learning benefit.
- **Cloud model service**: rejected for this slice because it introduces networking, credentials, child-data handling, and an unnecessary availability dependency.
- **Raise the minimum OS to iOS 26**: rejected because curated content works on iOS 18 and unsupported devices should retain the complete experience.

## Consequences

- iPhone 15 Pro models and iPhone 16 models, including iPhone 16e, can use the rewrite when running a compatible OS with Apple Intelligence enabled and ready.
- Other devices and configurations receive the same curated content as before.
- Simulator and unit tests validate fallback and policy seams; final model quality, latency, and availability require an eligible physical device.
- Prompts need regression testing when Apple updates the system model.

## References

- [Apple: Foundation Models](https://developer.apple.com/documentation/FoundationModels)
- [Apple: Generate content and perform tasks](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models)
- [Apple: Improve generative output safety](https://developer.apple.com/documentation/FoundationModels/improving-the-safety-of-generative-model-output)
- [Apple Intelligence device requirements](https://support.apple.com/121115)
- Related spec: [Memory Ask About This Card](../Specs/Memory-Ask-About-This-Card.md)
