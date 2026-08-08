<!--
Release notes template.

publish_release.sh looks for notes/v<version>.md — for example notes/v1.0.1.md
for version 1.0.1. If that file is missing it falls back to a generic
description, so copy this file and edit it before cutting a release.

This file itself is never published; only v*.md files are.
-->

Slouch Goblin VERSION for Apple Silicon Macs running macOS 13 or later.

## What's new

-

## Install

Download the `.dmg`, open it, and drag Slouch Goblin to Applications, then open
it from there. Allow camera access when macOS asks.

This build is signed and notarized by Apple, so it opens without any security
warning.

## Verifying the download

```bash
shasum -a 256 -c Slouch-Goblin-VERSION-arm64.dmg.sha256
```
