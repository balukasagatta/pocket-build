#!/usr/bin/env bash
# Local / CI helper: pod install → simulator build → unit tests
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SCHEME="${SCHEME:-Pocket Contacts Pro}"
WORKSPACE="${WORKSPACE:-Pocket Contacts Pro.xcworkspace}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16,OS=latest}"
DERIVED_DATA="${DERIVED_DATA:-build/DerivedData}"

echo "==> Installing Ruby gems (bundler)"
if command -v bundle >/dev/null 2>&1; then
  bundle check >/dev/null 2>&1 || bundle install
  POD_CMD=(bundle exec pod)
else
  POD_CMD=(pod)
fi

echo "==> CocoaPods install"
"${POD_CMD[@]}" install

mkdir -p artifacts build

echo "==> Building ${SCHEME}"
set -o pipefail
xcodebuild \
  -workspace "${WORKSPACE}" \
  -scheme "${SCHEME}" \
  -configuration Debug \
  -destination "${DESTINATION}" \
  -derivedDataPath "${DERIVED_DATA}" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  build | tee artifacts/xcodebuild-build.log

echo "==> Running unit tests"
xcodebuild \
  -workspace "${WORKSPACE}" \
  -scheme "${SCHEME}" \
  -configuration Debug \
  -destination "${DESTINATION}" \
  -derivedDataPath "${DERIVED_DATA}" \
  -resultBundlePath artifacts/PocketContactsPro.xcresult \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  test | tee artifacts/xcodebuild-test.log

echo "==> Done. Artifacts in ./artifacts"
