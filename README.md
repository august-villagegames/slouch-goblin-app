# Slouch Goblin

A private, real-time posture reminder for MacBooks. It lives in your menu bar,
watches for forward lean through the built-in camera, and nudges you when you
start hunching.

Your camera stays on your Mac. No video, image, or posture data ever leaves the
machine. The app makes exactly one kind of network request — an optional daily
check for a newer version, which sends nothing about you and can be switched off
from the menu.

`GOOD` means close to the comfortable upright reference you choose at setup. It
is not a medical diagnosis, an ergonomic certification, or a claim that one
posture is universally correct.

## Download

**[Download the latest release](https://github.com/august-villagegames/slouch-goblin-app/releases/latest)**

### Requirements

- Apple Silicon Mac (M1 or later) — Intel Macs are not supported
- macOS 13 Ventura or later
- A built-in or connected camera

## Install

1. Open the downloaded `.dmg`.
2. Drag **Slouch Goblin** onto the **Applications** shortcut.
3. Open Slouch Goblin from your Applications folder.
4. Allow camera access when macOS asks. Slouch Goblin cannot detect posture
   without it.

Slouch Goblin is signed with an Apple Developer ID and notarized by Apple, so it
opens normally — no right-clicking, no Terminal commands, no security warnings.

### Verifying your download

Each release includes a `.sha256` file. To confirm the disk image is intact,
run this in the folder holding both files:

```bash
shasum -a 256 -c Slouch-Goblin-*-arm64.dmg.sha256
```

## Using it

Slouch Goblin runs from the menu bar. On first launch it walks you through a
short two-pose calibration: your comfortable upright posture, and the first
forward lean you want to be nudged about. After that it monitors quietly with
no window open.

The menu bar item shows the current status, a contextual action for whatever it
is doing right now (open the window, pause, resume, retry the camera), and then:

- **Recalibrate…** — redo the two-pose setup
- **Open at login** — start Slouch Goblin automatically
- **Check for updates** — turn the daily version check on or off
- **Diagnostics…** — live detector values, with a button to copy them
- **About Slouch Goblin** — version and build number
- **Report an issue** — opens this repository's issue tracker
- **Quit Slouch Goblin**

Clicking the Dock icon reopens the window.

When you have been hunching for a while, the screen takes on a soft green blur,
and a goblin turns up in the corner if you keep at it. A **Not hunching** button
appears alongside the blur so you can flag a wrong alert; the video window has an
**I'm hunching** button for the opposite case. Both are stored locally only.

If Zoom, Google Meet, QuickTime, or another app takes the camera, Slouch Goblin
releases it and pauses, then resumes once the camera has been free for two
seconds. Screen-only recording does not pause it.

## Uninstall

Drag `Slouch Goblin.app` from Applications to the Trash. To also remove your
saved calibration and any feedback you flagged:

```bash
rm -rf ~/Library/Application\ Support/Slouch\ Goblin
```

If you used a build from before this was renamed, also remove
`~/Library/Application\ Support/Posture\ Probe`.

## About this repository

This repository hosts the released builds and the packaging scripts that
produce them. The application source is maintained separately.

Releases are built and published with:

```bash
./scripts/publish_release.sh "/path/to/Slouch Goblin.app"
```

`scripts/package_dmg.sh` turns a built app bundle into a versioned disk image:
it reads the version from the bundle's `Info.plist`, refuses anything that is
not Developer ID signed with the hardened runtime, notarizes and staples the
app, stages it alongside an `/Applications` shortcut, builds the image,
notarizes and staples that too, mounts it to confirm the contents, checks
Gatekeeper accepts it, and writes a SHA-256 checksum.

`scripts/notarize.sh` handles submission and stapling on its own, and documents
the one-time `xcrun notarytool store-credentials` setup it needs.

Release notes come from `notes/v<version>.md`; see `notes/TEMPLATE.md`.

## License

Slouch Goblin is free to use but not open source — see [LICENSE](LICENSE).

Bundled open source components and their licenses are listed in
[THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt).

---

© 2026 August Comstock. All rights reserved.
