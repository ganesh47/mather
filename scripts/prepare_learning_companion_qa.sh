#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
qa_dir="${1:?Pass a dedicated temporary QA directory}"
mkdir -p "$qa_dir"
REPO_FOR_COMPANION_QA="$repo_dir" OUTPUT_FOR_COMPANION_QA="$qa_dir" python3 - <<'PY'
import json, os, pathlib
repo = pathlib.Path(os.environ['REPO_FOR_COMPANION_QA'])
out = pathlib.Path(os.environ['OUTPUT_FOR_COMPANION_QA']).resolve()
def p(path): return json.dumps(str(repo/path))
common = f'''      - path: {p('Domain/LearningHandoff.swift')}
      - path: {p('Services/LearningHandoffStore.swift')}
      - path: {p('Features/LearningCompanion/LearningCompanionView.swift')}
      - path: {p('scripts/CompanionProofApp.swift')}
'''
spec = f'''name: CompanionProofQA
settings:
  base:
    SWIFT_VERSION: 6.0
    CODE_SIGNING_ALLOWED: NO
    GENERATE_INFOPLIST_FILE: YES
targets:
  CompanionIOS:
    type: application
    platform: iOS
    deploymentTarget: "18.0"
    sources:
      - path: {p('App')}
        excludes: [MatherApp.swift, Info.plist]
      - path: {p('Domain')}
      - path: {p('Features')}
      - path: {p('Services')}
      - path: {p('Persistence')}
      - path: {p('Shared')}
      - path: {p('scripts/CompanionProofApp.swift')}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ganesh47.MatherCompanionIOSProof
    scheme:
      testTargets: [CompanionIOSUITests]
  CompanionTV:
    type: application
    platform: tvOS
    deploymentTarget: "18.0"
    sources:
{common}      - path: {p('Services/SpeechService.swift')}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ganesh47.MatherCompanionTVProof
    scheme:
      testTargets: [CompanionTVUITests]
  CompanionIOSUITests:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "18.0"
    sources:
      - path: {p('Tests/CompanionProofUITests')}
    dependencies:
      - target: CompanionIOS
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ganesh47.MatherCompanionIOSProofTests
        TEST_TARGET_NAME: CompanionIOS
  CompanionTVUITests:
    type: bundle.ui-testing
    platform: tvOS
    deploymentTarget: "18.0"
    sources:
      - path: {p('Tests/CompanionProofUITests')}
    dependencies:
      - target: CompanionTV
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ganesh47.MatherCompanionTVProofTests
        TEST_TARGET_NAME: CompanionTV
'''
(out/'project.yml').write_text(spec)
PY
xcodegen generate --spec "$qa_dir/project.yml" --project "$qa_dir"
