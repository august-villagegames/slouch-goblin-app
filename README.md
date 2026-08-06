# Slouch Goblin

A private, real-time posture reminder for MacBooks. It lives in your menu bar,
watches for forward lean through the built-in camera, and nudges you when you
start hunching.

Everything happens on your Mac. No video, image, or posture data ever leaves the
machine, and the app makes no network requests while it runs.

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

### Getting past the macOS warning

Slouch Goblin is signed, but it is **not notarized by Apple** — notarization
requires a paid Apple Developer account. macOS therefore blocks it on first
launch. This is expected, and there are two ways through it.

**Most of the time,** right-click the app in Applications and choose **Open**,
then click **Open** again in the dialog. If no Open button appears, go to
 > System Settings → Privacy & Security, scroll to the message about Slouch
Goblin, and click **Open Anyway**.

**If macOS says the app "is damaged and can't be opened,"** that is macOS's
wording for an app it cannot verify, not a corrupted download. Remove the
download quarantine flag in Terminal:

```bash
xattr -dr com.apple.quarantine "/Applications/Slouch Goblin.app"
```

Then open the app normally. You only need to do this once per install.

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

The menu bar item gives you Monitoring, Show Video Feed, Show Diagnostics,
Re-calibrate, Launch at Login, and Quit. Clicking the Dock icon reopens the
video feed.

If Zoom, Google Meet, QuickTime, or another app takes the camera, Slouch Goblin
releases it and pauses, then resumes once the camera has been free for two
seconds. Screen-only recording does not pause it.

## Uninstall

Drag `Slouch Goblin.app` from Applications to the Trash. To also remove your
saved calibration:

```bash
rm -rf ~/Library/Application\ Support/Posture\ Probe
```

## About this repository

This repository hosts the released builds and the packaging scripts that
produce them. The application source is maintained separately.

Releases are built and published with:

```bash
./scripts/publish_release.sh "/path/to/Slouch Goblin.app"
```

`scripts/package_dmg.sh` turns a built app bundle into a versioned disk image:
it reads the version from the bundle's `Info.plist`, verifies the code
signature, stages the app alongside an `/Applications` shortcut, builds the
image, mounts it to confirm the contents, and writes a SHA-256 checksum.

---

© 2026 August Comstock. All rights reserved.
