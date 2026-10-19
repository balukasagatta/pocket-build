# Pocket Contacts Pro — CI/CD solution walkthrough

This document captures what we built, how it fits together, where we got stuck, and what to do next time. It is a retrospective for the **pocket-build** pipeline and the **Pocket-Contacts-Pro_devops** fork.

---

## Goal

Automate an iOS build so that:

1. Changes in the app repo can trigger CI.
2. CI produces a downloadable artifact from that app source.
3. The pipeline lives in a dedicated repo we control (`pocket-build`), not only in the original upstream demo.

---

## Final architecture

```
┌─────────────────────────────────────┐
│  balukasagatta/Pocket-Contacts-Pro  │
│  _devops  (fork of upstream iOS app)│
│                                     │
│  .github/workflows/                 │
│    trigger-pocket-build.yml  ───────┼── repository_dispatch
└─────────────────────────────────────┘         │
                                                ▼
┌─────────────────────────────────────┐
│  balukasagatta/pocket-build         │
│  (pipeline on GitHub)               │
│                                     │
│  .github/workflows/ios-ci.yml       │
│    - clones the fork @ SHA          │
│    - builds Simulator app           │
│    - uploads artifact               │
└─────────────────────────────────────┘
                │
                ▼
     Artifact: PocketContactsPro-simulator
     (zip of .app — Simulator only, not IPA)
```

**Also exists:** `mcdonald-s-cursor-tenant/pocket-build` on Cursor Origin (same pipeline history). GitHub Actions `repository_dispatch` must target the **GitHub** copy (`balukasagatta/pocket-build`), because `api.github.com` cannot see Origin-only repos (that caused the **404**).

---

## Repos involved

| Repo | Role |
| --- | --- |
| [sahmadmustafa/Pocket-Contacts-Pro](https://github.com/sahmadmustafa/Pocket-Contacts-Pro) | Upstream iOS demo (no write access for us) |
| [balukasagatta/Pocket-Contacts-Pro_devops](https://github.com/balukasagatta/Pocket-Contacts-Pro_devops) | **Our fork** — source of truth for app builds + hook |
| [balukasagatta/pocket-build](https://github.com/balukasagatta/pocket-build) | **Pipeline on GitHub** — iOS CI / artifacts |
| Origin `mcdonald-s-cursor-tenant/pocket-build` | Cursor/Origin copy of the pipeline (dev history) |

---

## What the successful run gives you

Example: https://github.com/balukasagatta/pocket-build/actions/runs/39267410594

| Artifact | Meaning |
| --- | --- |
| **PocketContactsPro-simulator** | Zip of `Pocket Contacts Pro.app` for **iOS Simulator** (unsigned) |
| **ios-ci-logs** | Build/test logs |

**Not included:** an **IPA**. IPA needs Apple signing certificates and the **iOS Release** workflow + secrets.

Analogy: Android CI often yields an **APK**; this iOS CI yields the Simulator **`.app`** equivalent, not the store/device package.

---

## Setup pieces that had to be in place

### On the fork (`Pocket-Contacts-Pro_devops`)

1. Workflow: `.github/workflows/trigger-pocket-build.yml`  
   (from `hooks/pocket-container-trigger.yml` in pocket-build)
2. **Repository secret:** `POCKET_BUILD_TOKEN`  
   - GitHub PAT with `repo` + `workflow`  
   - Must be able to call dispatch on `balukasagatta/pocket-build`
3. **Repository variable:** `POCKET_BUILD_REPO` = `balukasagatta/pocket-build`

### On the pipeline (`balukasagatta/pocket-build`)

1. Workflows: `ios-ci.yml`, `ios-release.yml`
2. Actions enabled
3. CI clones the fork, overlays a shared Xcode scheme, deintegrates empty CocoaPods linkage, builds for Simulator, uploads the artifact

---

## What worked (happy path)

1. Fork the upstream app under a **personal** GitHub account.
2. Create empty GitHub repo `balukasagatta/pocket-build` and push the pipeline there.
3. Add hook YAML + `POCKET_BUILD_TOKEN` + `POCKET_BUILD_REPO` on the fork.
4. Push (or “Run workflow”) on the fork → dispatch **HTTP 204** → iOS CI runs on pocket-build → download **PocketContactsPro-simulator**.

---

## Where we got stuck (and how it was resolved)

### 1. No write access to the upstream repo

We could not add the hook to `sahmadmustafa/Pocket-Contacts-Pro` (not an owner/collaborator).  
**Resolution:** use a **fork** we own.

### 2. Forking blocked / no Fork button — org account vs personal account

**Stuck here:** logged into GitHub with an **organization** account. The Fork UI / ability to fork into a place we control was not available or unclear.

**Resolution:** switch back to the **personal** GitHub account (`balukasagatta`), then fork to:

`https://github.com/balukasagatta/Pocket-Contacts-Pro_devops`

Lesson: for personal forks and PATs used by Actions, prefer the **personal** account (or an org where you explicitly have create-repo + Actions rights).

### 3. `repository_dispatch` returned 404

The hook initially targeted `mcdonald-s-cursor-tenant/pocket-build` via `https://api.github.com/.../dispatches`.  
That name exists on **Cursor Origin**, not on github.com → **404**.

**Resolution:** host the same pipeline on **GitHub** as `balukasagatta/pocket-build` and set `POCKET_BUILD_REPO` accordingly.

### 4. Missing / unclear `POCKET_BUILD_TOKEN`

The secret must be a **repository secret** (not an environment secret), and the value is a **PAT** (`ghp_...`), not a password from pocket-build.

### 5. First-time sequencing felt hard

Because this was the **first time** wiring cross-repo Actions end-to-end, the order of steps was easy to scramble (fork → pipeline repo on GitHub → secret → variable → re-run → interpret Simulator vs IPA).

That sequencing gets easier with practice. A stable order for next time:

1. Personal GitHub login  
2. Fork app repo  
3. Create GitHub `pocket-build` and push workflows  
4. Add fork secret + variable  
5. Run hook / push  
6. Download artifact from pocket-build Actions  
7. (Later) signing secrets if you need IPA  

### 6. Build failures after dispatch worked

- Wrong Simulator destination on the runner → fixed with id-based `xcodebuild -showdestinations`  
- `Pods_Pocket_Contacts_Pro` linker error (empty/stale CocoaPods) → deintegrate Pods on CI and build the `.xcodeproj`

---

## Security note

If a PAT was pasted into chat or logs, **revoke it** at https://github.com/settings/tokens and create a new one for `POCKET_BUILD_TOKEN`.

---

## Related docs in this repo

| Doc | Topic |
| --- | --- |
| [CROSS-REPO-HOOK.md](./CROSS-REPO-HOOK.md) | How the hook payload works |
| [FIX-404-DISPATCH.md](./FIX-404-DISPATCH.md) | Why Origin-only names 404 on api.github.com |
| [SETUP-GITHUB-ACTIONS.md](./SETUP-GITHUB-ACTIONS.md) | Enabling Actions / artifacts |
| `hooks/pocket-container-trigger.yml` | Hook file to install on the fork |

---

## Outcome

We have a working path:

**Personal fork (app) → hook → GitHub pocket-build → Simulator `.app` artifact.**

Org-login forking friction and first-time step order were the main human blockers; once the personal fork and GitHub pipeline repo existed, the remaining issues were configuration (404 target, secrets) and iOS CI build fixes.
