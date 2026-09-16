---
name: keep-process
description: >-
  Keep operating notes: user intent beats skills, current AppSession shape,
  five evidence claims, the Debug build they run. Use on Keep work. Do not
  freeze guesses. Do not wait for a second approval after the user named the slice.
---

# Keep process

The person in the chat outranks every Keep skill. If a skill forbids what they just asked for, do that work and update the skill in the same slice.

Skills are notes about this repo. They are not evidence. A Lab date is not a forever freeze. One crash is not a neighboring prohibition.

## Do not do from skill panic

* Add `AtmosphereEngine` or a second composition root as cleanup.
* Replace `AppSession` because a public skill prefers TCA, SwiftData, or a new store.
* Install a pile of extra skills to look production.
* Defend generated code when the running app disagrees.

## Current shape

This is what the code does today. Change it when the product changes.

```
KeepApp → AppSession
  CalendarReading     CalendarService → EventKitCatalog (one EKEventStore)
  WeatherFetching     WeatherService → HTTPClient → HTTPTransport
  LocationProviding   LocationProvider
  SettingsStore       AppSettings
  SolarEngine         Foundation only Daylight
  WallpaperController NSWindow.displayLink
```

`AppSession` coordinates. Protocols sit at I/O boundaries, not on every type.

HTTP: URLSession. Retry 5xx and listed transport once. No retry on 4xx including 429, cancel, or malformed. Lab fail next stubs the same `HTTPClient`.

EventKit: one store. Domain types do not import EventKit. Prompt from onboarding, Settings, or Lab. Next event rules are Keep policy (`NextMemoryPolicy`).

Location: no fake latitude 23°. Without GPS, TZ longitude and solar time bands.

Wallpaper: `desktopIconWindow` minus 1. Extra “Show Keep on the desktop” off detaches. Lock and sleep pause while attached. Occupancy is per display. Own PID ignored. Fullscreen and Low Power Mode pause only if Settings opt in.

Today’s Keep is edited in the menu extra field. Same `IntentionStore` the wallpaper reads.

Observability: `KeepLog` and `OSSignposter`, subsystem `app.keep.desktop`. Intervals on attach, pause, resume, detach, and weather refresh. Never per frame.

Settings: `keep.schemaVersion`. Missing stamps `1` without rewriting other keys. Do not downgrade a higher version.

Swift 6. No `@unchecked Sendable`. No `nonisolated(unsafe)`.

## When you report

Keep these claims separate. Passing tests is not Lab. Lab on the preview is not the wallpaper window. Green CI is not notarization.

| Claim | Means |
| --- | --- |
| Implemented | Code exists on the intended production path |
| Unit tested | Pure policy, golden times, decoding |
| Boundary tested | Adapter against a scripted seam |
| Lab verified | Operator used the real wallpaper `NSWindow`, extra, TCC, sleep, or lock |
| Distribution verified | Signing, notary, Gatekeeper as named in `keep-release` |

Report behaviors, not a test count. Do not call it shippable unless `keep-release` work actually ran.

## Build they run

```bash
killall Keep 2>/dev/null; xcodebuild -project Keep.xcodeproj -scheme Keep -configuration Debug -derivedDataPath build/DerivedData && open build/DerivedData/Build/Products/Debug/Keep.app
```

Old copy on screen means the wrong binary.

CI: `.github/workflows/ci.yml`. `macos-15` with Xcode 26 selected so the linked SDK matches a local Xcode 26 Keep build. Debug `test`. Release `build`. Tag `v*.*.*` publishes a zip via `.github/workflows/release.yml`. Ad hoc only. No signing secrets.
