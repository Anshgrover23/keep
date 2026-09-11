---
name: keep-process
description: >-
  Keep project operating system: frozen Stages 1 to 8, five claim levels,
  Lab on the real wallpaper NSWindow, discovery is not a license to code.
  Use when refactoring Keep, staging architecture, unlocking product work,
  responding to production concerns, or when an agent might reopen accepted
  decisions, invent AtmosphereEngine, or treat test count or Lab preview as proof.
---

# Keep process

This is the authoritative project operating system. Other skills are specialists. They do not outrank this file.

You are in **A (foundations)** and **B (behavioral confidence)** until the user opens **C (product)** as a separate named slice.

## Frozen architecture

Stages 1 through 8 of the architecture review are **frozen**. Never reopen an accepted architecture decision without contradictory evidence.

First product pass is **implemented and verified** (operator Lab, 11 Sep 2026).

CoreLocation Lab is **verified**, not outstanding: deny, grant without relaunch, approximate weather with denied GPS (11 Sep 2026).

Wallpaper `NSWindow` lifecycle is Lab verified on that date. Lab preview (`NSScreen.displayLink`) is not that proof.

## Before any code

1. Identify the **exact production gap**. If you cannot name it in one sentence, you are not ready to edit.
2. Discovery, audits, skill search, and reviews **do not authorize code changes**.
3. Never respond to a production concern by replacing an already accepted architecture.
4. Never create `AtmosphereEngine` as a cleanup abstraction. Never add a new composition root to “clean up” `AppSession`.
5. Load `keep-skill-selection`. Consult specialist skills for the slice only. Reconcile with this contract. Propose the smallest change. Implement only the named slice the user asked for.

Desired loop:

> Keep contract → identify slice → consult specialist skill → reconcile → propose smallest change → implement only after approval.

## Order (when implementing an approved slice)

1. Research official Apple docs and more than one real implementation. GitHub is an example, not authority.
2. Name the decision, evidence, alternatives, why rejected, confidence.
3. Implement **one** subsystem boundary.
4. Report evidence with the five claims below. Then continue only if the user named the next slice.

If evidence contradicts the current architecture, **stop and investigate**. Do not defend generated code.

Do not wait for a review after every tiny file. Do wait at a **subsystem** boundary if the user asked to stop there.

## Five claims (never collapse)

| Claim | Means |
| --- | --- |
| Implemented | Code exists on the intended production path |
| Unit tested | Pure policy, golden times, decoding |
| Boundary tested | Adapter against a scripted seam, not a fake of the whole system |
| Lab verified | Operator exercised the **real wallpaper `NSWindow`**, extra, TCC, sleep, lock, or the named Lab control. Product Lab means that window, not the Lab preview. |
| Production / distribution verified | Signing, notarization, Gatekeeper, or clean machine as named in `keep-release`. Passing tests is not this claim. |

Do not report success as "N tests passed." Report the **behaviors** verified.

Do not claim shippable, App Store ready, or distribution complete unless `keep-release` claims are actually met.

## Target shape (locked)

```
KeepApp → AppSession
  CalendarReading     CalendarService → EventKitCatalog (one EKEventStore)
  WeatherFetching     WeatherService → HTTPClient → HTTPTransport
  LocationProviding   LocationProvider
  SettingsStore       AppSettings
  SolarEngine         Foundation only Daylight
  WallpaperController NSWindow.displayLink
```

`AppSession` coordinates. It is not `AppStore.shared` renamed. Protocols exist at I/O boundaries, not on every type.

HTTP: URLSession, not Alamofire. Retry 5xx and listed transport once. No retry on 4xx including 429, cancel, or malformed. Lab fail next must stub the same `HTTPClient`.

EventKit: one store, domain types without EventKit, prompt only from onboarding / Settings / Lab. Next event rules in `NextMemoryPolicy` are **Keep policy**, not Apple facts.

Location: no latitude 23°. No GPS → TZ longitude, solar time bands.

Wallpaper: `desktopIconWindow` minus 1. Hide **detaches**. Pause stays attached. Occupancy is per display; true fullscreen ≈ `screen.frame`; maximized ≈ `visibleFrame` does not pause; own PID ignored.

Observability: `KeepLog` plus `OSSignposter` on subsystem `app.keep.desktop`. Intervals on attach, pause, resume, detach, and weather refresh. Never per frame. See `keep-observability`.

Settings: `keep.schemaVersion`. Missing stamps `1` without rewriting other keys. Do not downgrade a higher version. `SettingsStore` protocol stays.

Swift 6 on. No `@unchecked Sendable`. No `nonisolated(unsafe)`.

## Do not adopt

TCA, Alamofire, ceeK/Solar, WeatherKit, SpriteKit wallpaper, EventKitUI, WidgetKit, Liquid Glass as the wallpaper, isa-swap on SwiftUI `MenuBarExtra` windows, SwiftData, CloudKit, Hallmark, Firecrawl, Hyperframes, Screenpipe.

Do not install a pile of extra skills to “make it more production.” Strengthen behavior on this shape. Production quality does not mean adding frameworks.

## Build they actually run

```bash
killall Keep 2>/dev/null; xcodebuild -project Keep.xcodeproj -scheme Keep -configuration Debug -derivedDataPath build/DerivedData && open build/DerivedData/Build/Products/Debug/Keep.app
```

Old copy on screen means the wrong binary.

CI: `.github/workflows/ci.yml` only. `macos-15`. Debug `test`. Release `build`. No Release tests. No signing secrets in CI until `keep-release` says otherwise.

## Related

`keep-skill-selection` first. `keep-product` for v1. `production-app` for production quality (that is the keep-production node). `keep-release`, `keep-observability`, `keep-accessibility`, `keep-testing` for those slices. `apple-macos` for platform. `prose-copy` for copy.
