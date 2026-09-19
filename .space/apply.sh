#!/bin/bash
# Applies every patch in .space/patches onto a pristine upstream checkout, in name order.
# --3way falls back to a merge when the context drifted, so only a real conflict fails.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
for patch in .space/patches/*.patch; do
  echo "applying ${patch##*/}"
  git apply --3way --whitespace=nowarn "$patch"
done

# Optional rewrites: wherever upstream links its releases page (the Changelog menu item and
# whatever comes next), point it here. Nothing to rewrite is not an error.
{ grep -rlF --include='*.swift' 'github.com/abue-ammar/tinycast/releases' Tinycast || true; } | while read -r file; do
  echo "rewriting releases link in $file"
  sed -i.bak 's#github\.com/abue-ammar/tinycast/releases#github.com/sermelipharo/tinycast-space/releases#g' "$file"
  rm -f "$file.bak"
done
