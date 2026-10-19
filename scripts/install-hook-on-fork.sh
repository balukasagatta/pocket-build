#!/usr/bin/env bash
# Run this on your machine (you have write access to the fork).
# Adds .github/workflows/trigger-pocket-build.yml to
# https://github.com/balukasagatta/Pocket-Contacts-Pro_devops
set -euo pipefail

FORK_REPO="${FORK_REPO:-balukasagatta/Pocket-Contacts-Pro_devops}"
BRANCH="${BRANCH:-main}"
WORKFLOW_PATH=".github/workflows/trigger-pocket-build.yml"

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI: https://cli.github.com/"
  exit 1
fi
gh auth status >/dev/null

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENT_FILE="${ROOT}/hooks/pocket-container-trigger.yml"
if [ ! -f "${CONTENT_FILE}" ]; then
  echo "Missing ${CONTENT_FILE}"
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

gh repo clone "${FORK_REPO}" "${TMP}/repo" -- --branch "${BRANCH}" --single-branch
mkdir -p "${TMP}/repo/.github/workflows"
cp "${CONTENT_FILE}" "${TMP}/repo/${WORKFLOW_PATH}"

cd "${TMP}/repo"
git checkout -b chore/add-pocket-build-hook
git add "${WORKFLOW_PATH}"
git commit -m "Add trigger-pocket-build workflow hook for pocket-build CI"
git push -u origin HEAD

echo
echo "Pushed branch chore/add-pocket-build-hook"
echo "Open a PR or merge:"
echo "  gh pr create --repo ${FORK_REPO} --fill --base ${BRANCH}"
echo "  # or: git checkout ${BRANCH} && git merge chore/add-pocket-build-hook && git push"
echo
echo "Then add secret POCKET_BUILD_TOKEN on the fork:"
echo "  https://github.com/${FORK_REPO}/settings/secrets/actions"
