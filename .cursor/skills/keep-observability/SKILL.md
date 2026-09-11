---
name: keep-observability
description: >-
  Keep diagnostics: KeepLog, os.Logger, OSSignposter, privacy safe logs,
  Instruments on the wallpaper NSWindow. Use when adding logs, signposts,
  energy traces, display rebuild diagnostics, or when measuring pause,
  attach, detach, or weather refresh. Never signpost per frame. Never log
  precise location or event titles.
---

# Keep observability

Separate from generic `production-app` guidance.

> Measure the wallpaper `NSWindow`, not the Lab preview.

Lab preview (`NSScreen.displayLink`) is a different clock. Instruments on that preview do not prove desktop energy or attach/detach.

## KeepLog

Subsystem: `app.keep.desktop` (bundle id, fallback string in `KeepLog`).

Categories: `wallpaper`, `calendar`, `weather`, `location`, `session`, `power`.

`os.Logger` for human diagnostics in Console.app. Filter by that subsystem.

## Signposts

`OSSignposter` on the same subsystem:

* `wallpaper`: intervals only on **transitions**: `attach`, `pause`, `resume`, `detach`. Optional rebuild log already exists as Logger info when screen parameters change. Do not add a signpost per `CADisplayLink` step.
* `weather`: one interval `refresh` around a real HTTP attempt. Cache skip is not an interval.

Do not signpost per frame. Do not wrap `FrameClock.step`.

Pause **reasons** belong in existing power/session logs (lock, sleep, LPM, fullscreen). Do not invent a second pause taxonomy.

## Privacy

Never log:

* Precise latitude or longitude
* Event titles, attendees, notes
* Intention body
* Tokens, cookies, full URLs with query coordinates

Weather may log `WeatherKind` and WMO with `privacy: .public`. HTTP status belongs in Logger error strings for developers, never on product UI (`prose-copy`).

Signpost names are StaticString tokens (`attach`, `refresh`), not interpolated locations.

## Instruments workflow

1. Launch the binary from `build/DerivedData/Build/Products/Debug/Keep.app` (same as `keep-process`).
2. Points of Interest, subsystem `app.keep.desktop`.
3. Hide wallpaper: expect `detach`. Show: `attach`. Pause: `pause`. Fail next weather: `refresh` then error log, sky kind unchanged.
4. Do not attach Instruments only to Lab preview and call it wallpaper.

## Reproducible diagnostics

A useful report is: macOS version, Keep build path, display count, what you hid or locked, Console filter, signpost names seen. Not a screenshot of test diamonds.

## Related

`keep-testing` for failure modes to record. `keep-release` if you need dSYMs for crashes. Do not add MetricKit, Sentry, or analytics unless asked.
