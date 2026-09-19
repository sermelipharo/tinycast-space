# .space

Everything that makes this fork differ from [abue-ammar/tinycast](https://github.com/abue-ammar/tinycast).
`main` is never edited by hand beyond this folder: it is regenerated as *upstream main + these patches*.

| File | What it does |
| --- | --- |
| `patches/0001-alias-space.patch` | An exact user alias + Space opens its entry: rows with inline arguments focus the first field, everything else runs (apps and settings panes keep searching). |
| `patches/0002-updater-and-links.patch` | The in-app updater and the About link point at this fork. |
| `patches/0003-readme-banner.patch` | The banner at the top of the README. |
| `apply.sh` | Applies the patches in order with `git apply --3way`, then points any upstream releases-page link (the Changelog menu item) at this fork — a rewrite, not a patch, so a tag without that link still applies. |
| `gate.sh` | Release build + upstream's `Scripts/run-tests.sh`. A harness that also fails on the pristine upstream commit is ignored. |
| `report.sh` | Opens / closes the "blocked" issue. |
| `UPSTREAM` | The upstream commit `main` was last built from. |

## Automation

- **`space-sync.yml`** — every 10 minutes checks upstream `main`. On a new commit (or a manual commit on top
  of the generated one) it rebuilds `main` = upstream + patches on macOS, builds, runs the tests and
  force-pushes `main`. On failure nothing is pushed and a `space-sync` issue is opened.
- **`space-release.yml`** — twice an hour checks upstream's latest stable release. For a tag not yet released
  here it applies the patches to that tag, builds, tests, signs with this fork's `Tinycast Self-Signed`
  identity and publishes the same tag with a DMG and the zip the in-app updater installs.

Upstream's own workflows (`release.yml`, `website*.yml`, `triage.yml`, `coauthors.yml`) are disabled in this
repository's Actions settings.

Secrets: `SIGNING_P12_BASE64`, `SIGNING_P12_PASSWORD` (the signing identity, never rotate it casually —
installed copies only accept updates signed with the same certificate) and `SPACE_PUSH_TOKEN`
(fine-grained token for this repository: Contents + Workflows read/write).

## Changing the patch

Edit the code on `main`, regenerate the affected file with `git diff <upstream-sha> -- <paths> > .space/patches/…`,
commit, and push; the next sync run rebuilds `main` from upstream with the new patch.
