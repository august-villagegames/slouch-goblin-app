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
  notes_file="$(mktemp "${TMPDIR:-/tmp}/slouch-goblin-notes.XXXXXX")"
  cat > "$notes_file" <<EOF
Slouch Goblin $version for Apple Silicon Macs running macOS 13 or later.

Download \`$(basename "$dmg_path")\`, open it, and drag Slouch Goblin to
Applications. The app is not notarized, so macOS will warn on first launch —
see [the install instructions](https://github.com/$repo#install) for the two
ways to get past it.
EOF
fi

echo
echo "About to publish a PUBLIC release:"
echo "  repo:  $repo"
echo "  tag:   $tag"
echo "  asset: $(basename "$dmg_path") ($(du -h "$dmg_path" | cut -f1))"
echo

if [[ "$assume_yes" -ne 1 ]]; then
  read -r -p "Publish? [y/N] " reply
  [[ "$reply" == "y" || "$reply" == "Y" ]] || { echo "Aborted."; exit 1; }
fi

gh release create "$tag" \
  --repo "$repo" \
  --title "Slouch Goblin $version" \
  --notes-file "$notes_file" \
  "$dmg_path" \
  "$dmg_path.sha256"

echo
echo "Published: https://github.com/$repo/releases/tag/$tag"
echo "Share:     https://github.com/$repo/releases/latest"
