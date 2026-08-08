# slouch-goblin-app — working notes

**This repository is public.** Anything committed here is visible to everyone.
It hosts released builds and the packaging scripts that produce them. The
application source is private, in `slouch-goblin` (`~/Documents/hunch`).

**August is not an engineer.** Explain in plain language, and prefer running
the mechanical steps yourself over writing instructions for him to follow.

## What lives here

- `scripts/package_dmg.sh` — turns a signed `.app` into a notarized, stapled,
  versioned disk image with a SHA-256 checksum
- `scripts/notarize.sh` — submits an artifact to Apple and staples the ticket
- `scripts/publish_release.sh` — packages, then creates the GitHub Release
- `notes/v<version>.md` — release notes, read by `publish_release.sh`

The `.app` bundle is the only interface to the source repo. Version is read
from its `Info.plist`; nothing here knows about Python or PyInstaller.

## Publishing

```bash
cd ~/Documents/slouch-goblin-app && ./scripts/publish_release.sh
```

Defaults to `../hunch/dist/Slouch Goblin.app` — do not pass a path unless the
app is somewhere unusual. Takes ~10 minutes, pauses twice while Apple
notarizes, and stops at `Publish? [y/N]`. Nothing is public until that `y`.

Write `notes/v<version>.md` first, or it falls back to generic notes.

**Publishing is irreversible in practice.** A release can be deleted, but it
may already have been downloaded or indexed. Always confirm with August
before the final step, and never pass `--yes` on his behalf.

### The order matters

Sign app → notarize app → staple app → build image from the **stapled** app →
sign image → notarize image → staple image. Stapling is what lets the app open
on a Mac that has never seen it, including one that is offline. Signing after
notarizing invalidates the ticket.

## Invariants

- **Never `--prerelease`.** GitHub's `/releases/latest` excludes pre-releases,
  which 404s both the README download link and the app's in-app update check.
  Even betas ship as normal releases; signal status with the `0.x` version and
  the title.
- **Never publish an ad-hoc or unstapled build.** It produces "Slouch Goblin
  is damaged and can't be opened" for every downloader. The scripts refuse
  it — don't work around the refusal, fix the build.
- Refusals here almost always mean the source repo was on an old branch when
  the app was built. Check `git branch --show-current` in `~/Documents/hunch`.

## Notarization credentials

Keychain profile `slouch-goblin`. Check with
`xcrun notarytool history --keychain-profile slouch-goblin`.

Re-storing requires an app-specific password from account.apple.com, which
only August can generate. Never ask him to paste it into chat, and never put
it in a file. A 403 "required agreement is missing or has expired" is an Apple
Developer Program agreement or membership problem, not a bad password.

## Verifying a build before publishing

The real test is a quarantined copy, which is what a browser download produces:

```bash
cp dist/Slouch-Goblin-*.dmg /tmp/q.dmg
xattr -w com.apple.quarantine "0083;00000000;Safari;" /tmp/q.dmg
spctl -a -vvv -t open --context context:primary-signature /tmp/q.dmg
```

Want `accepted` and `source=Notarized Developer ID`. Mount it and run
`spctl -a -vvv -t exec` against the app inside too.

## Shell gotcha

Under `set -o pipefail`, `cmd | grep -q pattern` fails intermittently — `grep
-q` exits on first match and SIGPIPEs `cmd`. Capture output first, then match
against the string. Likewise, a function ending in `[[ -n "$x" ]] && ...`
returns 1 when `$x` is empty; in an `EXIT` trap that becomes the script's exit
status. End such functions with `return 0`.

Background-task completion notifications have reported the wrong exit code.
Read the command's actual output before concluding a run succeeded.
