#!/usr/bin/env bash
set -euo pipefail

# Packages a built "Slouch Goblin.app" into a versioned, distributable disk
# image.  The app bundle is the only interface to the source repository: the
# version is read back out of its Info.plist, so this script needs no knowledge
# of Python, PyInstaller, or the source tree.

cd "$(dirname "$0")/.."
repo_root="$PWD"

app_path="${1:-${SLOUCH_GOBLIN_APP:-../hunch/dist/Slouch Goblin.app}}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Disk images must be packaged on macOS." >&2
  exit 2
fi

if [[ ! -d "$app_path" || ! -f "$app_path/Contents/Info.plist" ]]; then
  echo "Not an app bundle: $app_path" >&2
  echo "Build it first with ./scripts/build_macos_app.sh in the source repository," >&2
  echo "then pass its path or set SLOUCH_GOBLIN_APP." >&2
  exit 2
fi

app_path="$(cd "$(dirname "$app_path")" && pwd)/$(basename "$app_path")"
version="$(plutil -extract CFBundleShortVersionString raw -o - "$app_path/Contents/Info.plist")"

if [[ -z "$version" ]]; then
  echo "Could not read CFBundleShortVersionString from $app_path" >&2
  exit 2
fi

# An invalid signature is what macOS later reports as "damaged" once a download
# has quarantined the app, and the user cannot recover from that without the
# command line.  Refuse to publish one.
echo "Verifying signature"
if ! verify_output="$(codesign --verify --deep --strict "$app_path" 2>&1)"; then
  echo "$verify_output" >&2
  echo "Signature verification failed; refusing to package $app_path" >&2
  exit 1
fi

# Capture first rather than piping into grep -q: under `set -o pipefail` the
# early exit of grep -q can SIGPIPE codesign and fail the whole pipeline.
signature_info="$(codesign --display --verbose=2 "$app_path" 2>&1 || true)"
if [[ "$signature_info" == *"Signature=adhoc"* ]]; then
  echo "Note: ad-hoc signature. Downloaders must clear Gatekeeper manually."
else
  echo "Note: bundle carries a non-ad-hoc signature."
fi

staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/slouch-goblin-dmg.XXXXXX")"
cleanup() {
  rm -rf "$staging_dir"
  # create-dmg leaves a large read-write scratch image behind when it fails.
  rm -f "$repo_root"/dist/rw.*.dmg
}
trap cleanup EXIT

# ditto --rsrc preserves the code signature and extended attributes.  The
# /Applications shortcut is added per-backend below: create-dmg makes its own
# with --app-drop-link and errors if one is already staged.
ditto --rsrc "$app_path" "$staging_dir/Slouch Goblin.app"

mkdir -p "$repo_root/dist"
dmg_path="$repo_root/dist/Slouch-Goblin-$version-arm64.dmg"
rm -f "$dmg_path"

vol_icon="$(find "$app_path/Contents/Resources" -maxdepth 1 -name '*.icns' | head -1 || true)"

if command -v create-dmg >/dev/null 2>&1; then
  echo "Building disk image with create-dmg"
  create_dmg_args=(
    --volname "Slouch Goblin $version"
    --window-pos 200 140
    --window-size 540 380
    --icon-size 128
    --icon "Slouch Goblin.app" 140 190
    --app-drop-link 400 190
    --no-internet-enable
  )
  if [[ -n "$vol_icon" ]]; then
    create_dmg_args+=(--volicon "$vol_icon")
  fi
  # create-dmg exits non-zero on cosmetic Finder/.DS_Store warnings while still
  # producing a valid image, so judge it by the artifact rather than the status.
  create-dmg "${create_dmg_args[@]}" "$dmg_path" "$staging_dir" || true
fi

if [[ ! -f "$dmg_path" ]]; then
  echo "Building disk image with hdiutil"
  ln -sfn "/Applications" "$staging_dir/Applications"
  hdiutil create \
    -volname "Slouch Goblin $version" \
    -srcfolder "$staging_dir" \
    -ov \
    -format UDZO \
    "$dmg_path" >/dev/null
fi

# Confirm the image actually mounts and carries what a user needs to drag.
echo "Verifying disk image"
mount_point="$(mktemp -d "${TMPDIR:-/tmp}/slouch-goblin-verify.XXXXXX")"
hdiutil attach "$dmg_path" -nobrowse -readonly -mountpoint "$mount_point" >/dev/null
verify_status=0
[[ -d "$mount_point/Slouch Goblin.app" ]] || { echo "Disk image is missing Slouch Goblin.app" >&2; verify_status=1; }
[[ -L "$mount_point/Applications" ]] || { echo "Disk image is missing the /Applications shortcut" >&2; verify_status=1; }
hdiutil detach "$mount_point" >/dev/null
rmdir "$mount_point"
if [[ "$verify_status" -ne 0 ]]; then
  rm -f "$dmg_path"
  exit 1
fi

(cd "$repo_root/dist" && shasum -a 256 "$(basename "$dmg_path")" > "$(basename "$dmg_path").sha256")

echo "Packaged: $dmg_path"
echo "Checksum: $dmg_path.sha256"
echo "Version:  $version"
