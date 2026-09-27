#!/usr/bin/env bash
# Keep Gabriel's build on top of the newest official Aerion release.
#
#   bash gabriel/update.sh           rebase onto the latest release if there is one, then build
#   bash gabriel/update.sh --build   just build what is checked out
#
# Gabriel's changes live on the `gabriel` branch as ordinary commits. The tag
# `gabriel-base` marks the release they currently sit on. A new release means
# replaying those commits onto it, which is one rebase.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PATH:$(go env GOPATH)/bin"

if [ "${1:-}" != "--build" ]; then
  git fetch -q upstream --tags
  latest=$(git tag -l 'v*' --sort=-v:refname | grep -v -- '-' | head -1)
  if [ "$(git rev-parse "$latest^{commit}")" = "$(git rev-parse 'gabriel-base^{commit}')" ]; then
    echo "Already on the latest release, $latest."
  else
    echo "New release $latest. Replaying your changes onto it."
    git checkout -q gabriel
    if ! git rebase --onto "$latest" gabriel-base gabriel; then
      echo
      echo "A change of yours conflicts with $latest. Ask Claude to resolve it,"
      echo "or run 'git rebase --abort' to go back to how it was."
      exit 1
    fi
    git tag -f gabriel-base "$latest" >/dev/null
    git push -q --force-with-lease origin gabriel
    git push -q -f origin gabriel-base
  fi
fi

if [ -f .env ]; then
  set -a; . ./.env; set +a
else
  echo "No .env with sign-in IDs, so Google and Outlook sign-in will not work in this build."
fi

(cd frontend && npx svelte-check --threshold error >/dev/null) || { echo "Type check failed."; exit 1; }

MODULE=github.com/hkdb/aerion
LDFLAGS="-X '$MODULE/internal/oauth2.GoogleClientID=${GOOGLE_CLIENT_ID:-}' \
-X '$MODULE/internal/oauth2.GoogleClientSecret=${GOOGLE_CLIENT_SECRET:-}' \
-X '$MODULE/internal/oauth2.MicrosoftClientID=${MICROSOFT_CLIENT_ID:-}'"

wails build -ldflags "$LDFLAGS" -tags webkit2_41 -o aerion-gabriel.exe > build/bin/gabriel-build.log 2>&1 \
  || { echo "Build failed, see build/bin/gabriel-build.log"; exit 1; }

# The build regenerates bindings and touches go.mod. None of that is ours.
git checkout -q -- frontend/package.json.md5 frontend/wailsjs go.mod 2>/dev/null || true

echo "Built build/bin/aerion-gabriel.exe on $(git describe --tags --exclude gabriel-base gabriel-base) plus:"
git log --oneline gabriel-base..gabriel
