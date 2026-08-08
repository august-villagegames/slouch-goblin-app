#!/usr/bin/env bash
set -euo pipefail

# Packages a built "Slouch Goblin.app" and publishes it as a public GitHub
# Release.  Usage:
#
#   ./scripts/publish_release.sh [path-to-.app] [--yes]
#
# The version comes from the bundle's Info.plist; bump app_version.py in the
# source repository to cut a new one.

cd "$(dirname "$0")/.."
repo_root="$PWD"

repo="${SLOUCH_GOBLIN_REPO:-august-villagegames/slouch-goblin-app}"
assume_yes=0
app_path=""

for arg in "$@"; do
  case "$arg" in
    --yes|-y) assume_yes=1 ;;
    *) app_path="$arg" ;;
  esac
done

app_path="${app_path:-${SLOUCH_GOBLIN_APP:-../hunch/dist/Slouch Goblin.app}}"

if ! command -v gh >/dev/null 2>&1; then
  echo "The GitHub CLI (gh) is required to publish a release." >&2
  exit 2
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Not authenticated. Run: gh auth login" >&2
  exit 2
fi

if [[ ! -f "$app_path/Contents/Info.plist" ]]; then
  echo "Not an app bundle: $app_path" >&2
  exit 2
fi

version="$(plutil -extract CFBundleShortVersionString raw -o - "$app_path/Contents/Info.plist")"
tag="v$version"

if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
  echo "Release $tag already exists in $repo." >&2
  echo "Bump __version__ in app_version.py in the source repository, rebuild, and retry." >&2
  exit 2
fi

"$repo_root/scripts/package_dmg.sh" "$app_path"

dmg_path="$repo_root/dist/Slouch-Goblin-$version-arm64.dmg"
notes_file="$repo_root/notes/$tag.md"

if [[ ! -f "$notes_file" ]]; then
  echo "No release notes at notes/$tag.md; using the generic template." >&2
  notes_file="$(mktemp "${TMPDIR:-/tmp}/slouch-goblin-notes.XXXXXX")"
  cat > "$notes_file" <<EOF
Slouch Goblin $version for Apple Silicon Macs running macOS 13 or later.

Download \`$(basename "$dmg_path")\`, open it, and drag Slouch Goblin to
Applications, then open it from there. Allow camera access when macOS asks.

This build is signed and notarized by Apple, so it opens without any security
warning. See [the install instructions](https://github.com/$repo#install) if
anything is unclear.
EOF
fi

# Refuse to publish an unstapled image: it would look correct here and then
# warn on every machine that downloads it.
if ! xcrun stapler validate "$dmg_path" >/dev/null 2>&1; then
  echo "Disk image has no stapled notarization ticket; refusing to publish." >&2
  echo "Re-run ./scripts/package_dmg.sh without --skip-notarize." >&2
  exit 1
fi

echo
echo "About to publish a PUBLIC release:"
echo "  repo:  $repo"
echo "  tag:   $tag"
echo "  asset: $(basename "$dmg_path") ($(du -h "$dmg_path" | cut -f1))"
echo "  notes: $notes_file"
echo "  state: signed, notarized, stapled"
echo

if [[ "$assume_yes" -ne 1 ]]; then
  read -r -p "Publish? [y/N] " reply
  [[ "$reply" == "y" || "$reply" == "Y" ]] || { echo "Aborted."; exit 1; }
fi

# Deliberately NOT --prerelease. GitHub's /releases/latest endpoint skips
# pre-releases, and two things depend on it: the README download link, and the
# app's own update check in update_check.py. Marking a beta as a pre-release
# makes both 404, so nobody can find the build and nobody is ever told an
# update exists. Signal beta status with the 0.x version and the title instead.
gh release create "$tag" \
  --repo "$repo" \
  --title "Slouch Goblin $version" \
  --notes-file "$notes_file" \
  "$dmg_path" \
  "$dmg_path.sha256"

echo
echo "Published: https://github.com/$repo/releases/tag/$tag"
echo "Share:     https://github.com/$repo/releases/latest"
