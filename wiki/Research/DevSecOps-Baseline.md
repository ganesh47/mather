# Research: DevSecOps Baseline for Public GitHub Repository

**Issue**: n/a
**Status**: Completed
**Date**: 2026-03-31

## Question

What GitHub-native and OSS DevSecOps controls should be enabled for `ganesh47/mather`, given that it is a free public repository in early implementation?

## Context

The repository is public, uses GitHub Actions, and currently contains planning docs plus automation. This creates a meaningful supply-chain and repository-hardening surface before substantial Swift application code exists.

## Current Baseline Implemented

Repo-side controls added:

- `SECURITY.md`
- `.github/CODEOWNERS`
- `.github/dependabot.yml`
- Dependency review workflow
- Workflow lint workflow
- CodeQL workflow for GitHub Actions workflow analysis
- OSSF Scorecard workflow
- Pinned GitHub-owned actions in existing workflows where practical
- Explicit workflow `permissions:` in repository workflows

GitHub-side controls enabled:

- Vulnerability alerts
- Automated security fixes
- Private vulnerability reporting
- Secret scanning
- Secret scanning push protection
- Branch protection admin enforcement on `main`
- Code owner review requirement on `main`

## Recommended GitHub-Native Features

Enable or keep enabled:

- Branch protection or rulesets for `main`
- Required CI checks
- Required PR review
- Code owner review for sensitive paths
- Vulnerability alerts
- Automated security fixes
- Private vulnerability reporting
- Secret scanning
- Secret scanning push protection
- Code scanning / CodeQL
- Dependency review on pull requests

## Recommended OSS Tooling

Current OSS and open workflows chosen:

- `actionlint` for workflow linting
- OSSF Scorecard for public OSS posture checks
- GitHub dependency review action for PR-time dependency checks

Optional later additions:

- `gitleaks` for repository-history secret scans
- `osv-scanner` for additional advisory coverage once Swift dependencies land
- `zizmor` for deeper GitHub Actions security linting if workflow complexity grows

## Remaining Manual or Deferred Hardening

These items were not completed automatically in this pass:

- Require conversation resolution before merge
- Require SHA pinning from repository settings if GitHub exposes the setting in UI before the REST API stabilizes for this repo
- Restrict allowed actions instead of allowing all actions and workflows
- Move from classic branch protection to repository rulesets
- Add code-scanning merge protection once CodeQL results exist
- Add Swift dependency automation in Dependabot after `Package.swift` or package manifests exist
- Add artifact attestations once the repo produces meaningful release or build artifacts

## Decision

Use GitHub-native security features first, then layer OSS workflow tooling on top. For this repo stage, the highest-value controls are repository hardening, workflow analysis, dependency review, and vulnerability intake, not heavyweight application scanning.
