#!/bin/bash
# Build + upstream's test suite. A failing harness blocks only if it passes on the pristine
# upstream commit, so upstream's own flaky or environment-bound harnesses never stall the sync.
# Usage: gate.sh <upstream-sha>
set -uo pipefail
UP="${1:?upstream sha}"
cd "$(git rev-parse --show-toplevel)"
TMP="${RUNNER_TEMP:-$(mktemp -d)}"

echo "::group::xcodebuild"
if ! xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
  -derivedDataPath "$TMP/gate-dd" ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- build > "$TMP/gate-build.log" 2>&1; then
  echo "::endgroup::"
  grep -E 'error:' "$TMP/gate-build.log" | head -40
  tail -40 "$TMP/gate-build.log"
  echo "::error::build failed"
  exit 1
fi
echo "::endgroup::"

./Scripts/run-tests.sh 2>&1 | tee "$TMP/gate-tests.log"
failed=$(sed 's/\x1b\[[0-9;]*m//g' "$TMP/gate-tests.log" | sed -n 's/.*harness(es) failed in [0-9]*s: //p')
[ -z "$failed" ] && exit 0

still=()
for t in $failed; do ./Scripts/run-tests.sh "$t" > /dev/null 2>&1 || still+=("$t"); done
[ ${#still[@]} -eq 0 ] && { echo "::warning::flaky, passed on retry: $failed"; exit 0; }

wt="$TMP/gate-upstream"
git worktree add --force --detach "$wt" "$UP" > /dev/null
regressions=()
for t in "${still[@]}"; do
  if (cd "$wt" && ./Scripts/run-tests.sh "$t" > /dev/null 2>&1); then
    regressions+=("$t")
  else
    echo "::warning::$t fails on upstream ${UP:0:7} too — not ours, ignored"
  fi
done
git worktree remove --force "$wt"
[ ${#regressions[@]} -eq 0 ] && exit 0
echo "::error::the patch breaks: ${regressions[*]}"
exit 1
