#!/usr/bin/env bash
set -euo pipefail

# Submits a signed artifact to Apple's notary service and staples the ticket
# to it.  Usage:
#
#   ./scripts/notarize.sh "/path/to/Slouch Goblin.app"
#   ./scripts/notarize.sh "dist/Slouch-Goblin-1.0.0-arm64.dmg"
#
# Stapling is what lets the app open on a Mac that has never seen it before,
# including one that is offline.  Without it macOS shows a Gatekeeper warning
# even though the artifact is notarized.
#
# One-time setup, which stores an app-specific password in the keychain:
#
#   xcrun notarytool store-credentials "slouch-goblin" \
#     --apple-id "<your-apple-id>" \
#     --team-id 4VS9K4RWP9 \
#     --password "<app-specific-password>"
#
# Generate the app-specific password at appleid.apple.com, under
# Sign-In and Security.

KEYCHAIN_PROFILE="${SLOUCH_GOBLIN_NOTARY_PROFILE:-slouch-goblin}"
artifact="${1:-}"

if [[ -z "$artifact" ]]; then
  echo "Usage: ./scripts/notarize.sh <path-to-.app-or-.dmg>" >&2
  exit 2
fi

if [[ ! -e "$artifact" ]]; then
  echo "Not found: $artifact" >&2
  exit 2
fi

if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" >/dev/null 2>&1; then
  echo "No notarization credentials stored for profile '$KEYCHAIN_PROFILE'." >&2
  echo >&2
  echo "Store them once with:" >&2
  echo "  xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" \\" >&2
  echo "    --apple-id \"<your-apple-id>\" \\" >&2
  echo "    --team-id 4VS9K4RWP9 \\" >&2
  echo "    --password \"<app-specific-password>\"" >&2
  exit 2
fi

submission_path="$artifact"
cleanup_zip=""
if [[ -d "$artifact" ]]; then
  # The notary service does not accept a bare .app directory; it has to be
  # zipped, and ditto is the only zip that preserves the code signature.
  cleanup_zip="$(mktemp -d "${TMPDIR:-/tmp}/slouch-goblin-notarize.XXXXXX")/upload.zip"
  echo "Compressing $(basename "$artifact") for submission"
  ditto -c -k --keepParent "$artifact" "$cleanup_zip"
  submission_path="$cleanup_zip"
fi

cleanup() {
  if [[ -n "$cleanup_zip" ]]; then
    rm -rf "$(dirname "$cleanup_zip")"
  fi
  # An EXIT trap's final status becomes the script's exit status. Without this
  # the empty-cleanup_zip case (any .dmg, which is never zipped) would report
  # failure after a successful notarization.
  return 0
}
trap cleanup EXIT

echo "Submitting $(basename "$artifact") to Apple; this usually takes 1-5 minutes"
if ! xcrun notarytool submit "$submission_path" \
  --keychain-profile "$KEYCHAIN_PROFILE" \
  --wait; then
  echo >&2
  echo "Notarization failed. Fetch the details with:" >&2
  echo "  xcrun notarytool log <submission-id> --keychain-profile \"$KEYCHAIN_PROFILE\"" >&2
  echo "(the submission id is printed above)" >&2
  exit 1
fi

echo "Stapling the ticket to $(basename "$artifact")"
xcrun stapler staple "$artifact"
xcrun stapler validate "$artifact"

echo "Notarized and stapled: $artifact"
