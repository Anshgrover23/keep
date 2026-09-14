---
name: keep-testing
description: >-
  Keep failure-mode testing: deny and grant after launch, empty and stale
  data, malformed HTTP, sleep lock display, hidden wallpaper, extra field.
  Use when adding tests or Lab. Do not report N tests passed as the evidence.
---

# Keep testing

Swift Testing stays (`@Test`, `#expect`). Report behaviors, not a passing count.

## Where

| Kind | For | Not for |
| --- | --- | --- |
| Unit | Policy, solar bands, glance copy, schema | AppKit windows, TCC, display link |
| Boundary | `HTTPClient` stubs, EventKit catalog fakes | Pretending the live store was called |
| Lab | Real wallpaper `NSWindow`, extra, sleep, lock, CoreLocation | Lab preview as desktop proof |
| Release compile | `xcodebuild` Release `build` | Treating compile as Lab |

Lab harness on production types is allowed (`failNextRefresh`, `markStaleForTesting`). Do not add `pinReykjavikJuneMidnight()` as product API.

## When the slice touches them

* Permission denied and the product still runs. Grant after launch without requiring a relaunch as the only path.
* Empty vs invitation vs stale vs approximate vs unavailable.
* Malformed HTTP and transport failure on the same `HTTPClient`. Last weather kind kept.
* Sleep and lock as separate assertions. Wake does not clear a lock still asserted.
* Display add and remove. Occupancy per display. True fullscreen vs maximized.
* Hidden wallpaper: display link detached.
* Extra field can type while accessory at rest.
* Release still compiles. Do not skip Debug tests.

Lab chrome: one control per class. Clock: midnight and noon or a phase picker. Weather: live, kind, fail next.

A Lab date in a doc is history. Retest if the behavior changed.

Day film: CI stills at six hours prove `ImageRenderer` returns a frame. The full PNG and MP4 pass is opt in (`KEEP_DAY_FILM=1`, `Tools/export-day-film.sh`). Film frames use `SceneReadability.socialPreview`. That is not Lab proof of the desktop `NSWindow`.
