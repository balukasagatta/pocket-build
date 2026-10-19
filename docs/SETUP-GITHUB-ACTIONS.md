# Setup: automate builds and download artifacts

The workflow YAML files under `.github/workflows/` are already correct for GitHub Actions.
Nothing else needs to “register” them — GitHub picks them up automatically **once this code is on GitHub** and Actions is enabled.

## 1. Put the repo on GitHub

This project must live in a **GitHub** repository (public or private). GitHub Actions does not run on Cursor Origin-only remotes.

1. In Cursor, use **Create repo** (or create an empty repo on github.com).
2. Push `main` (workflows included):

```bash
git remote -v   # should show github.com/...
git push -u origin main
```

Confirm these paths exist on GitHub:

- `.github/workflows/ios-ci.yml` → automatic build + **Simulator `.app` zip**
- `.github/workflows/ios-release.yml` → manual **IPA** (needs signing secrets)

## 2. Enable Actions

1. Open the GitHub repo → **Settings** → **Actions** → **General**
2. Under *Actions permissions*, choose **Allow all actions and reusable workflows** (or allow listed actions)
3. Save

Free / Pro GitHub accounts include macOS minutes; org plans may need billing enabled for Actions.

## 3. Trigger the automated build

Any of these starts `iOS CI`:

| Trigger | How |
| --- | --- |
| Push | `git push origin main` |
| Pull request | Open a PR into `main` |
| Manual | **Actions** → **iOS CI** → **Run workflow** |

## 4. Download the artifact (end result)

After the run is green:

1. Open **Actions** → latest **iOS CI** run
2. Scroll to **Artifacts**
3. Download **`PocketContactsPro-simulator`**

That zip contains `Pocket Contacts Pro.app` (iOS **Simulator** build — install via Xcode / `xcrun simctl`, not a physical iPhone).

Logs (if you need them) are in the separate **`ios-ci-logs`** artifact.

### Install the Simulator app on a Mac

```bash
unzip PocketContactsPro-simulator.app.zip
xcrun simctl boot "iPhone 16" || true
xcrun simctl install booted "Pocket Contacts Pro.app"
xcrun simctl launch booted "Zuooi.Pocket-Contacts-Pro"
```

## 5. (Optional) Device / TestFlight IPA

Simulator zips do **not** install on real devices. For a distributable IPA:

1. Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret | Value |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | `base64 -i YourCert.p12 \| pbcopy` |
| `P12_PASSWORD` | `.p12` password |
| `KEYCHAIN_PASSWORD` | any strong temp password for CI |
| `BUILD_PROVISION_PROFILE_BASE64` | `base64 -i profile.mobileprovision \| pbcopy` |

2. **Actions** → **iOS Release** → **Run workflow**
3. Pick export method (`ad-hoc` / `app-store` / …)
4. Download artifact **`release-artifacts`** → `PocketContactsPro.ipa`

Without secrets, you can still smoke-test the release job with **skip_codesigning** checked (no installable IPA).

## Checklist

- [ ] Code is on **github.com** (not only Origin)
- [ ] `.github/workflows/ios-ci.yml` is on `main`
- [ ] Actions permissions allowed
- [ ] Push or **Run workflow** succeeded on `macos-15`
- [ ] Artifact **PocketContactsPro-simulator** downloaded
- [ ] (Optional) Signing secrets added for IPA
