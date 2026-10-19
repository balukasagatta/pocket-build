# Pocket Contacts Pro — Build Pipeline

CI/CD and local build tooling for the [Pocket Contacts Pro](https://github.com/sahmadmustafa/Pocket-Contacts-Pro) iOS demo (Swift / UIKit contacts app).

## What this adds

| Piece | Purpose |
| --- | --- |
| `.github/workflows/ios-ci.yml` | On every push/PR: `pod install` → Simulator build → unit tests |
| `.github/workflows/ios-release.yml` | Manual Release archive / IPA (signing secrets optional) |
| `fastlane/` | `pods`, `build`, `test`, `ci`, `release` lanes |
| `scripts/bootstrap.sh` | One-time local setup (Bundler + CocoaPods) |
| `scripts/ci_build.sh` | Same build+test flow as CI, runnable on a Mac |
| Shared Xcode scheme | `Pocket Contacts Pro` under `xcshareddata` (required for headless builds) |

Upstream app sources are included so the pipeline is self-contained. Original project: [sahmadmustafa/Pocket-Contacts-Pro](https://github.com/sahmadmustafa/Pocket-Contacts-Pro).

## Requirements

- macOS with Xcode 15+ (CI uses `macos-15` + Xcode 16.2)
- Ruby 3.3+
- CocoaPods (installed via Bundler)

## Quick start (local Mac)

```bash
./scripts/bootstrap.sh
open "Pocket Contacts Pro.xcworkspace"
```

Or run the full CI path locally:

```bash
./scripts/ci_build.sh
# or
bundle exec fastlane ci
```

## Fastlane lanes

```bash
bundle exec fastlane pods      # pod install
bundle exec fastlane build     # Debug Simulator build (unsigned)
bundle exec fastlane test      # Unit tests
bundle exec fastlane ci        # pods + build + test
bundle exec fastlane release   # Release IPA (needs signing)
```

Environment overrides:

- `DESTINATION` — xcodebuild destination (default `platform=iOS Simulator,name=iPhone 16`)
- `TEST_DEVICE` — Simulator device name for `scan`
- `EXPORT_METHOD` — `ad-hoc` / `app-store` / `development` / `enterprise`
- `SKIP_CODESIGNING=1` — archive without signing (not for distribution)

## GitHub Actions

### `iOS CI` (automatic)

Triggers on push/PR to `main`/`master` and `workflow_dispatch`.

1. Select Xcode 16.2  
2. Bundle install + cache CocoaPods  
3. `pod install`  
4. Unsigned Debug build for iPhone Simulator  
5. Unit tests with code coverage + JUnit  
6. Upload `artifacts/` (logs, `.xcresult`, junit)

### `iOS Release` (manual)

Run from the Actions tab. Provide an export method. For real distribution, add repository secrets:

| Secret | Description |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded `.p12` signing certificate |
| `P12_PASSWORD` | Password for the `.p12` |
| `KEYCHAIN_PASSWORD` | Temporary CI keychain password |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded `.mobileprovision` |

Without those secrets, re-run with **skip_codesigning** for a non-distributable archive smoke test.

## Project notes

- Bundle ID: `Zuooi.Pocket-Contacts-Pro`
- Deployment target: iOS 13.0
- CocoaPods: no active pods by default (JPush left commented in history); `pod install` still required because the Xcode project is wired to the Pods workspace
- UI tests are present but skipped in the shared scheme’s default test action (enable when you have stable UI fixtures)
- CI builds set `CODE_SIGNING_ALLOWED=NO` for Simulator

## App overview

Native Swift phonebook demo: list contacts, filter emails/numbers, UIKit storyboards. Needs the Contacts permission (`NSContactsUsageDescription`).
