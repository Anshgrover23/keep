---
name: production-app
description: >-
  Keep production quality: runtime, Debug tests, Release compile,
  derivedDataPath, Lab vs product chrome. Use when shipping Keep or naming
  Lab and Settings. Production quality does not mean adding frameworks.
---

# Production app

Ship software people run. Close the named gap. Do not answer “make it production” with TCA, SwiftData, Sentry, WeatherKit, or a new engine.

Casual speech is intent. “The edit box” means typing on that surface. “Give me the command” means one command that opens the binary they run.

## Runtime

* Launch accessory. Quit from the extra. Hide wallpaper detaches. Show attaches. Extra still opens while inactive.
* Display link: `FrameRateMeter` preferred 60, min 60, max 120. No extra work per frame beyond the scene.
* Rebuild per `NSScreen`. Occupancy per display.
* Sleep and lock are separate. Wake does not clear a lock that is still asserted.
* Permissions: invitational. Grant after launch works. Deny is not a crash.
* Network: last weather kind. Status stale or unavailable. No HTTP on UI.
* Fail next weather uses production `HTTPClient`.

## Build

Always `-derivedDataPath build/DerivedData` so `open` matches the binary.

```bash
killall Keep 2>/dev/null; xcodebuild -project Keep.xcodeproj -scheme Keep -configuration Debug -derivedDataPath build/DerivedData && open build/DerivedData/Build/Products/Debug/Keep.app
```

Debug tests: add `-destination 'platform=macOS' test`. Release compile: `-configuration Release` `build`. Signing: `keep-release`.

## Surfaces

| Surface | Show | Hide |
| --- | --- | --- |
| Product | Short copy. One job per control. | Debug, dual formats, API names |
| Lab | Controls that drive behavior. Status that is true now. | Unit tests as buttons. Prompt leftovers |
| Tests | Exact times, zones, status codes | Those strings on Lab buttons |
| Docs | What the code does now | Forever freezes, marketing |

Lab preview (`NSScreen.displayLink`) is not the wallpaper window (`NSWindow.displayLink`).

If they said pin 12:01 AM vs PM they wanted midnight vs noon. Test IST `00:01` and `12:01`. Lab: Pin midnight and Pin noon. Product: real clock.

macOS Form `TextField("Placeholder")` uses that string as a leading label. Empty title, `labelsHidden()`, rounded border.

Do not `object_setClass` a SwiftUI extra window. That crashed. Becoming regular while the extra is open is how the extra field takes keys.

Do not flip activation on every extra frame. Do not recap architecture unasked. Green tests are not notarization.
