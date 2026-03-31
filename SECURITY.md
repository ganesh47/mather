# Security Policy

## Supported Scope

This repository is a public planning and implementation repo for `Mather`, an iPadOS app currently in local alpha use.

Supported security reporting scope:

- GitHub Actions workflows in `.github/workflows/`
- Repository automation and scripts
- Dependency and supply-chain issues
- Secrets accidentally committed to the repository
- Future Swift application code as it is added

Out of scope for urgent security handling:

- Local alpha UX bugs that do not create a security impact
- Personal device setup issues unrelated to the repository
- App Store policy topics, because this project is not being published to the App Store

## Reporting a Vulnerability

Please use GitHub's private vulnerability reporting flow for this repository when possible.

If private vulnerability reporting is unavailable, open a GitHub issue only for non-sensitive concerns. Do not post exploit details, secrets, tokens, or private device data in a public issue.

## Response Expectations

- Initial triage target: within 7 days
- Remediation target for confirmed high-severity issues: as quickly as practical for a solo-maintained alpha project
- Public disclosure: after a fix is available or the issue is otherwise mitigated

## Data Handling Notes

This project is currently intended for personal and family alpha testing on local devices.

- No remote analytics pipeline is intended for the alpha slice
- Session exports are expected to remain device-local unless explicitly exported by the maintainer
- If a reported issue includes local test data, share only the minimum details needed to reproduce the problem
