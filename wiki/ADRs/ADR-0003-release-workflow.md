# ADR-0003: Semantic Versioned Release Workflow

**Date**: 2026-04-02
**Status**: Accepted
**Deciders**: @ganesh47

---

## Context

Mather is distributed as a personal/family sideload (ADR-0002). Without a defined versioning scheme, it is impossible to know which build a device is running, making it hard to correlate observed child behaviour with specific code changes. Alpha testing with a real child requires build provenance.

---

## Decision

Use **semantic versioning** (`vMAJOR.MINOR.PATCH`) with a GitHub Actions release workflow triggered by git tags.

### Version Scheme

| Component | Meaning | Example |
|---|---|---|
| `MAJOR` | Vertical slice milestone | `1` = VS1 Make & Break to 10 |
| `MINOR` | Feature addition within a milestone | `1` = new problem type added |
| `PATCH` | Bug fix or polish within a minor | `1` = ten-frame layout fix |

- `CFBundleShortVersionString` (`MARKETING_VERSION`) = `MAJOR.MINOR.PATCH` from the git tag
- `CFBundleVersion` (`CURRENT_PROJECT_VERSION`) = `GITHUB_RUN_NUMBER` (monotonically increasing integer)
- Local development builds default to `0.1.0-dev` (defined in `project.yml`)

### Tagging Convention

```bash
git tag v1.0.0 -m "VS1 Make & Break to 10 — first real-child pilot release"
git push origin v1.0.0
```

This triggers `.github/workflows/release.yml`, which:
1. Stamps `Info.plist` with the version from the tag
2. Builds an `.xcarchive` targeting the iOS Simulator (no code signing required)
3. Compresses the archive and attaches it to a GitHub Release

### Why Simulator Archive (Not IPA)

Full IPA export (`xcodebuild -exportArchive`) requires a development certificate and provisioning profile. These are device-specific credentials that cannot be stored in CI without significant setup (Fastlane match, or manual secrets management). Since sideloading is done from the developer's machine via Xcode, the GitHub Release serves as a **source-of-truth marker** — the developer checks out the tag and deploys from Xcode, knowing exactly which code version is on the device.

IPA export can be added later if a paid Apple Developer account and CI-safe certificate management is set up.

### First Release Target

`v1.0.0` — when VS1 polish issues (#44–#49) are all closed.

---

## Consequences

**Positive**:
- Every build running on the test iPad has a traceable version string in Settings → General → About
- Telemetry JSONL exports include `appVersion` in `session_start` events — correlating session data with code versions becomes possible
- GitHub Releases provide a changelog anchor point per milestone

**Negative / Limitations**:
- The CI archive targets the Simulator (not a real device) — it validates that the build compiles and archives, but the actual device deployment is still manual from Xcode
- No IPA attached to the release until certificate management is set up

**Neutral**:
- `project.yml` `MARKETING_VERSION` is overridden at tag time; local builds show `0.1.0-dev`
- The release workflow does not run on pushes to `main` — it is tag-only
