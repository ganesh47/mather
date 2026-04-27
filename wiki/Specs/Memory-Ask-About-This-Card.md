# Spec: Memory Ask About This Card

**Issue**: #380  
**Status**: UI slice implemented
**Author**: Codex  
**Date**: 2026-04-27

## Overview

Memory Match should let a child ask a few safe, card-grounded questions from the Learn sheet, such as asking about Jupiter's size, color, place in the solar system, or special fact. The interaction is not an open chat box. The app presents bounded suggested turns, speaks the chosen answer, and falls back to deterministic card metadata whenever Apple Intelligence or future on-device generation is unavailable.

## User Stories

- As a child, I want to tap "Ask about this card" and choose a spoken question so I can learn a little more without needing to read or type.
- As a parent, I want the feature to stay grounded in the current card and avoid unrestricted conversation, microphone input, or retained transcripts.
- As a developer, I want the generated path to be replaceable while deterministic fallback behavior remains stable and testable.

## Acceptance Criteria

- [x] The child can only choose from app-provided suggested turns for the visible Memory card.
- [x] Jupiter and other planet cards have deterministic fallback turns for order/type, size, and a special fact when metadata exists.
- [x] If Apple Intelligence or a future suggested-turn provider is unavailable, empty, or unsafe, the app uses curated metadata fallback.
- [x] Off-card or unsupported requests receive a short refusal that redirects the child to card questions.
- [x] The app stores only lightweight session state such as `cardId` and selected turn IDs; it does not retain a conversation transcript.
- [x] The child flow has no freeform text input, no microphone input, and no unrestricted generated chat.
- [x] Spoken answers use `SpeechService` read-aloud behavior and respect the existing parent audio toggle for in-session prompts.

## Design

### SwiftUI Views

- `MemoryView.learningSheet(for:)`: adds an "Ask about this card" entry point below existing Learn content.
- `MemoryAskConversationSection`: shows 2-3 large suggested-question buttons and a replay button for the latest spoken answer. Buttons must meet the 80 pt touch target guidance.
- No keyboard, dictation button, chat transcript, or microphone affordance appears in the child flow.

### Data Model

- `MemoryAskConversationPolicy`: starts a session from a `MemoryAnimal`, chooses safe suggested turns, and falls back to deterministic metadata.
- `MemoryAskConversationSession`: stores `cardId`, `source`, `suggestedTurns`, and selected turn IDs only.
- `MemoryAskSuggestedTurn`: bounded `question` and `answer` strings generated from metadata or a safe provider.
- `MemoryAskConversationTurnProvider`: future adapter boundary for Apple Intelligence suggested turns. It supplies candidate turns only; it does not accept child-authored prompts.

### Navigation

The feature starts from a visible Memory Learn card. Closing the sheet returns to the current Memory round. Starting a new round clears the session.

### State Management

The session is local to the Learn sheet. `MemoryAskConversationPolicy` owns no persistence. If telemetry is later added, it may record aggregate events such as `ask_card_turn_selected` with card ID and turn ID, but not the spoken answer or any transcript text.

## Feature Flag

Flag name: `FeatureFlags.memoryCardAppleIntelligenceEnabled` gates any future Apple Intelligence suggested-turn provider. Deterministic fallback remains available when the Learn sheet is available.

## Out of Scope

- Speech recognition, dictation, microphone-driven questions, or live voice conversation.
- Freeform text entry by the child.
- Unrestricted chat completion or multi-turn generated conversation.
- Persisted conversation transcripts.
- Cloud AI providers or network calls.
- Fact expansion beyond the current card's curated metadata unless separately specified and sourced.

## Open Questions

- [ ] Should parent settings expose a separate Ask toggle, or is the existing Learn/Apple Intelligence flag enough for the first implementation?
- [ ] What telemetry event names should be used if aggregate turn-selection analytics are added?

## References

- Related triage: [TestFlight-Feedback-Triage-349-368-372](TestFlight-Feedback-Triage-349-368-372.md)
- Related implementation baseline: `MemoryCardDescribeService` in `Services/SpeechService.swift`
