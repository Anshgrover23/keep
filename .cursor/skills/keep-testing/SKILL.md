---
name: keep-testing
description: >-
  Keep failure-mode testing: permission deny and grant after launch, empty
  and stale data, malformed HTTP, sleep lock display and fullscreen, hidden
  wallpaper, accessory focus, accessibility, Release compile. Use when adding
  tests, Lab, or writing an evidence report. Prohibits N tests passed as the
  primary evidence.
---

# Keep testing

Not another architecture or testing framework. Swift Testing stays. This is **failure-mode testing discipline**.

Explicitly prohibit:

> "N tests passed" as the primary evidence.

Report behaviors. Map each to a claim in `keep-process` (unit, boundary, Lab, or distribution).

## Where tests live

| Kind | For | Not for |
| --- | --- | --- |
| Unit | Policy, solar bands, glance copy, schema version | AppKit windows, TCC, display link |
| Boundary | `HTTPClient` stubs, EventKit catalog fakes | Pretending the live store was called |
| Lab | Real wallpaper `NSWindow`, extra, sleep, lock, CoreLocation | Lab preview as desktop proof |
| Release compile | `xcodebuild` Release `build` | Treating compile as Lab |

Do not add test-only methods to production types unless Lab is the harness (`failNextRefresh`, `markStaleForTesting` allowed; `pinReykjavikJuneMidnight()` not allowed).

## Failure modes to cover (when the slice touches them)

* Permission denied (calendar, location) and product still runs
* Permission granted after launch (no “relaunch Keep” as the only path; CoreLocation Lab already verified this)
* Empty data vs invitation copy vs stale vs approximate vs unavailable
* Malformed response and transport failure (same `HTTPClient`; last weather kind kept)
* Sleep / wake and lock / unlock as **separate** assertions (wake must not clear a lock still asserted)
* Display removal and addition (rebuild windows; occupancy per display)
* True fullscreen vs maximized
* Hidden wallpaper: display link **detached**
* Inactive accessory application: extra and wallpaper still correct
* Accessibility: VO labels, Reduce Motion, extra field keys
* Release build: compiles; do not skip Debug tests

YAGNI on Lab chrome: one control per class of cases. Clock: midnight and noon or a phase picker. Weather: live, kind, fail next. Calendar: soon, overdue, all day, then live.

## Evidence shape

Wrong: `42 tests passed, including accessibility.`
Right: `Unit: rain remains after 503. Boundary: stubbed HTTPClient. Lab (wallpaper window): hide detached the link. Release compile: not run this slice.`

## Related

`keep-observability` if the failure is energy or attach. `keep-release` if the failure is Gatekeeper. twostraws Swift Testing Pro for library syntax only.
