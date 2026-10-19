#!/usr/bin/env bash
# One-time local bootstrap for Pocket Contacts Pro + build pipeline tooling
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Checking Xcode"
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found. Install Xcode from the App Store / Apple Developer."
  exit 1
fi
xcodebuild -version

echo "==> Installing Bundler gems (Fastlane + CocoaPods)"
gem install bundler --no-document >/dev/null 2>&1 || true
bundle install

echo "==> Installing CocoaPods dependencies"
bundle exec pod install

echo "==> Shared scheme present:"
ls -la "Pocket Contacts Pro.xcodeproj/xcshareddata/xcschemes/"

echo
echo "Bootstrap complete."
echo "  Open:  open \"Pocket Contacts Pro.xcworkspace\""
echo "  Build: ./scripts/ci_build.sh"
echo "  Or:    bundle exec fastlane ci"
