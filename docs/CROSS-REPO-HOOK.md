# Cross-repo hook: pocket container → pocket-build

Goal: a push in the **pocket container / iOS app repo** starts a build in **pocket-build**, and the downloaded artifact is compiled from that iOS source (not from a stale vendored copy).

```
┌─────────────────────────┐         repository_dispatch          ┌──────────────────────────┐
│  Pocket container / iOS │  ─────────────────────────────────►  │  pocket-build (this repo)│
│  (app source of truth)  │     event: pocket-ios-build          │  clones iOS @ SHA        │
└─────────────────────────┘                                      │  uploads .app.zip        │
                                                                  └──────────────────────────┘
```

## 1. What pocket-build listens for

In `.github/workflows/ios-ci.yml`:

| Trigger | Source |
| --- | --- |
| `repository_dispatch` type `pocket-ios-build` | Hook from pocket container |
| `workflow_dispatch` (+ `ios_repo` / `ios_ref`) | Manual run in pocket-build |
| `push` / `pull_request` | Changes to pipeline itself (still builds default iOS repo) |

Dispatch payload:

```json
{
  "event_type": "pocket-ios-build",
  "client_payload": {
    "ios_repo": "your-org/pocket-container",
    "ios_ref": "abc123def",
    "sha": "abc123def"
  }
}
```

Build steps clone `ios_repo` @ `ios_ref`, overlay the shared Xcode scheme from pocket-build, then upload:

- **PocketContactsPro-simulator** → `.app.zip` + `BUILD_INFO.txt` (records which iOS SHA was built)

## 2. Wire the pocket container repo

1. Copy [`hooks/pocket-container-trigger.yml`](../hooks/pocket-container-trigger.yml) into the iOS / pocket container repo as:

   `.github/workflows/trigger-pocket-build.yml`

2. In the **pocket container** repo → Settings → Secrets → Actions, add:

   | Secret | Purpose |
   | --- | --- |
   | `POCKET_BUILD_TOKEN` | Token that can call dispatch on `mcdonald-s-cursor-tenant/pocket-build` |

3. Optional Actions variables on the pocket container repo:

   | Variable | Default |
   | --- | --- |
   | `POCKET_BUILD_REPO` | `mcdonald-s-cursor-tenant/pocket-build` |
   | `POCKET_BUILD_API` | `https://api.github.com` (set to Origin API if dispatch goes through Origin) |

4. Push to `main` on the pocket container repo → Actions should show **Trigger pocket-build** → then open **pocket-build → iOS CI** and download the artifact.

## 3. Secrets on pocket-build

| Secret | When needed |
| --- | --- |
| `IOS_REPO_TOKEN` | iOS / pocket container repo is **private** (clone rights). Public GitHub upstream can omit this. |

## 4. Manual test (no hook yet)

In **pocket-build** → Actions → **iOS CI** → **Run workflow**:

- `ios_repo`: your pocket container `owner/name`
- `ios_ref`: branch or SHA

Confirm the artifact’s `BUILD_INFO.txt` lists that repo and commit.

## 5. Origin note

`pocket-build` currently lives on Cursor Origin. `repository_dispatch` works when the forge exposes a GitHub-compatible dispatches API and CI runners pick up `.github/workflows`. If Origin dispatch URLs differ, set `POCKET_BUILD_API` on the pocket container side to the correct endpoint, or use **workflow_dispatch** via the forge API as a fallback.
