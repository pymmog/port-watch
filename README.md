# PortWatch VI Menu Bar

A small native macOS menu bar app that shows [PortWatch VI](https://portwatch-vi.xyz) overall progress toward playable GTA VI on PC — a template-friendly progress ring plus optional percentage text in the menu bar.

## Requirements

- macOS 14 or newer (Apple Silicon or Intel)
- Swift 5.9+ (Xcode 15+ command line tools, or a recent Swift toolchain)
- No Xcode project required — pure Swift Package Manager

## Build & run (Mac)

```bash
# Run unit tests (core scoring/parsing; works on Linux CI too)
swift test

# Debug-run from the command line (shows menu bar item; no Dock icon)
swift run PortWatch

# Release .app bundle (ad-hoc signed) in dist/
chmod +x build-app.sh
./build-app.sh

# Optional: copy PortWatch.app to ~/Applications
./build-app.sh --install
```

Then open `dist/PortWatch.app` or launch from `~/Applications` after `--install`.

### Headless UI snapshots (no screen, no permissions)

Renders off-screen PNGs from live tracker data (menu bar glyph on light/dark chrome + detail popover in each appearance):

```bash
swift build -c release
mkdir -p /tmp/portwatch-shots
.build/release/PortWatch --snapshot /tmp/portwatch-shots
# or: ~/Applications/PortWatch.app/Contents/MacOS/PortWatch --snapshot /tmp/portwatch-shots
```

Snapshot mode never opens a SwiftUI scene (60 s timeout); normal launch uses `PortWatchApp.main()` from `Launcher`.

Writes `menubar-light.png`, `menubar-dark.png`, `popover-light.png`, `popover-dark.png`, `appicon.png` and exits without a menu bar icon.

### App icon

Regenerate the committed `.iconset` from the source artwork (requires Python 3 + Pillow):

```bash
python3 scripts/generate_app_icon.py
./build-app.sh   # runs iconutil on macOS to produce AppIcon.icns
```

## Features

- Fetches `tracker.json` and live `scoring.js` from portwatch-vi.xyz
- Evaluates the site’s scoring script in **JavaScriptCore** when possible so the headline % matches the website
- Falls back to the latest `history` row in `tracker.json`, then to an embedded Swift mirror of the scoring model
- Menu bar ring + optional `%` text; click for a popover with leader, top-3 average, furthest milestone, exe status, local “updated” time, and the three newest news links
- Auto-refresh every 5/10/30/60 minutes (default 10), plus refresh on wake from sleep
- Optional notifications when overall % or furthest milestone changes (default on)
- Launch at login via `SMAppService`
- Keeps the last good value when offline (orange dot on the menu bar icon)

## Project layout

| Path | Purpose |
|------|---------|
| `Sources/PortWatchCore/` | Models, Swift scoring mirror, JS evaluator, fetch/build logic (testable) |
| `Sources/PortWatch/` | SwiftUI menu bar app (AppKit / ServiceManagement / UserNotifications) |
| `Tests/PortWatchCoreTests/` | Parsing & scoring tests against a captured `tracker-sample.json` |
| `build-app.sh` | Produces `dist/PortWatch.app` with `LSUIElement` (no Dock icon) |

## Verifying the score

With the bundled fixture (snapshot from 2026-11-24), the Swift mirror reports:

- **72%** overall (leader **CGBJ**, milestone **In-game**)
- **67.2%** top-3 average
- Playable answer: **Sort of**

That matches the live site when using the same `scoring.js` logic.

## Notes for contributors

- The menu bar glyph is rendered with `ImageRenderer` and marked template when only the ring is shown, so it respects light/dark menu bars.
- `PortWatchCore` avoids AppKit so `swift test` can run on Linux in CI; the `PortWatch` executable target is macOS-only.
- This repository was built in a Linux cloud environment; the `.app` bundle script and macOS-specific paths are provided for local Mac validation (signing, menu bar, notifications, launch at login).