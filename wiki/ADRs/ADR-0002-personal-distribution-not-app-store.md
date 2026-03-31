# ADR-0002: Personal Distribution — Not App Store

**Date**: 2026-03-31
**Status**: Accepted
**Deciders**: @ganesh47

## Context

Mather is being built to test with the author's own children (currently ages ~5). The goal is rapid iteration and personal learning, not public distribution. Publishing to the App Store introduces significant overhead: Kids Category review requirements, parental gate implementation, COPPA compliance, StoreKit Ask to Buy, third-party SDK restrictions, and human review turnaround time.

## Decision

Distribute exclusively via direct device install from Xcode (USB or WiFi) using a personal Apple Developer team certificate. Do not target App Store distribution at this stage.

## Rationale

- Eliminates all App Store Kids Category requirements
- No parental gate implementation needed
- No StoreKit / Ask to Buy integration
- No COPPA / data privacy compliance overhead
- No restriction on third-party libraries
- Faster iteration: deploy in seconds from Xcode, no review queue
- Free tier Apple Developer account supports up to 3 registered devices for direct install

## What This Removes From Scope

| Requirement | Now Needed? |
|---|---|
| Parental gate before IAP/links | No |
| StoreKit Ask to Buy | No |
| FamilyControls / PermissionKit | No (nice-to-have, not required) |
| COPPA-compliant analytics | No |
| Kids Category age band selection | No |
| App Store privacy policy URL | No |
| Human review of ads | No (no ads at all) |

## What Remains Relevant From Research

- UX design principles (touch targets, no buzzers, voice instructions) still apply — they're about the child's experience, not compliance
- Session length recommendations still apply
- CPA pedagogy still applies
- Parent dashboard is still desirable (just simpler — no privacy policy needed)

## Consequences

- Positive: dramatically simpler architecture; can focus entirely on learning experience
- Positive: can use any Swift packages freely (no SDK restriction)
- Positive: rapid deploy-and-test loop with the actual target users
- Negative: device limit (3 devices on free Apple ID; 100 on paid $99/year developer account)
- Neutral: if publishing becomes desirable later, the above requirements would need to be retrofitted — but that is a future decision

## If This Changes

A future ADR (ADR-00XX) would supersede this if the decision to publish to the App Store is made. The main retrofit costs would be: parental gate, StoreKit, and a privacy policy.
