# Fix: curl 404 on repository_dispatch

## Cause

The fork hook called:

`https://api.github.com/repos/mcdonald-s-cursor-tenant/pocket-build/dispatches`

`mcdonald-s-cursor-tenant/pocket-build` lives on **Cursor Origin**, not github.com, so GitHub returns **404**. The `POCKET_BUILD_TOKEN` secret is fine.

## Fix (recommended)

### 1. Create a GitHub pipeline repo

1. https://github.com/new → name: **`pocket-build`** (under `balukasagatta`)
2. Public or private; **do not** add a README if you will push an existing history

### 2. Push this pipeline to that GitHub repo

```bash
origin repo clone mcdonald-s-cursor-tenant/pocket-build
cd pocket-build

git remote add github https://github.com/balukasagatta/pocket-build.git
git push -u github main
```

Enable **Settings → Actions** on `balukasagatta/pocket-build`.

### 3. Point the fork at the GitHub pipeline

On https://github.com/balukasagatta/Pocket-Contacts-Pro_devops/settings/variables/actions

| Variable | Value |
| --- | --- |
| `POCKET_BUILD_REPO` | `balukasagatta/pocket-build` |

(Optional) update `.github/workflows/trigger-pocket-build.yml` on the fork to the latest hook from this repo.

Keep secret `POCKET_BUILD_TOKEN` = your GitHub PAT (`repo` + `workflow`). The PAT owner must have access to `balukasagatta/pocket-build`.

### 4. Re-run

Fork → Actions → **Trigger pocket-build** → Run workflow  

Expect HTTP **204**, then an **iOS CI** run on `balukasagatta/pocket-build` with artifact **PocketContactsPro-simulator**.
