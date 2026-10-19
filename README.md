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

## Cross-repo hook (pocket container → this pipeline)

The **artifact is built from the iOS / pocket container repo**, not only from files vendored here.

1. Pocket container pushes code  
2. Its workflow sends `repository_dispatch` (`pocket-ios-build`) to this repo  
3. **iOS CI** clones that commit, builds, uploads `PocketContactsPro-simulator`

**iOS source fork:** [balukasagatta/Pocket-Contacts-Pro_devops](https://github.com/balukasagatta/Pocket-Contacts-Pro_devops)  
**GitHub pipeline:** [balukasagatta/pocket-build](https://github.com/balukasagatta/pocket-build)  
Hook template: [`hooks/pocket-container-trigger.yml`](hooks/pocket-container-trigger.yml) → install with `./scripts/install-hook-on-fork.sh`  
Setup: [docs/CROSS-REPO-HOOK.md](docs/CROSS-REPO-HOOK.md)  
**Full solution write-up (stuck points + sequencing):** [docs/SOLUTION-WALKTHROUGH.md](docs/SOLUTION-WALKTHROUGH.md)

## GitHub Actions — get an automated artifact

**Full setup guide:** [docs/SETUP-GITHUB-ACTIONS.md](docs/SETUP-GITHUB-ACTIONS.md)

Short version:

1. **Host this repo on GitHub** (Create repo / push `main`). Workflows only run on GitHub, not on Origin-only remotes.
2. Enable **Settings → Actions → Allow actions**.
3. Push to `main` (or **Actions → iOS CI → Run workflow**).
4. Open the green run → download artifact **`PocketContactsPro-simulator`** (`PocketContactsPro-simulator.app.zip`).

### Workflows

| Workflow | File | When | Artifact |
| --- | --- | --- | --- |
| **iOS CI** | `.github/workflows/ios-ci.yml` | push / PR / manual | Simulator `.app` zip + logs |
| **iOS Release** | `.github/workflows/ios-release.yml` | manual only | IPA (needs signing secrets) |

### Release IPA secrets (optional)

| Secret | Description |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded `.p12` signing certificate |
| `P12_PASSWORD` | Password for the `.p12` |
| `KEYCHAIN_PASSWORD` | Temporary CI keychain password |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded `.mobileprovision` |

## Project notes

- Bundle ID: `Zuooi.Pocket-Contacts-Pro`
- Deployment target: iOS 13.0
- CocoaPods: no active pods by default (JPush left commented in history); `pod install` still required because the Xcode project is wired to the Pods workspace
- UI tests are present but skipped in the shared scheme’s default test action (enable when you have stable UI fixtures)
- CI builds set `CODE_SIGNING_ALLOWED=NO` for Simulator

## App overview

Native Swift phonebook demo: list contacts, filter emails/numbers, UIKit storyboards. Needs the Contacts permission (`NSContactsUsageDescription`).
