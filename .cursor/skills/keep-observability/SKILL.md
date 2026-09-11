---
name: keep-observability
description: >-
  Keep diagnostics: KeepLog, os.Logger, OSSignposter, privacy safe logs,
  Instruments on the wallpaper NSWindow. Use when adding logs or measuring
  attach, pause, detach, or weather refresh. Never signpost per frame.
---

# Keep observability

Measure the wallpaper `NSWindow`. Lab preview (`NSScreen.displayLink`) is a different clock.

## KeepLog

Subsystem: `app.keep.desktop`. Categories: `wallpaper`, `calendar`, `weather`, `location`, `session`, `power`.

## Signposts

Same subsystem. Wallpaper intervals only on `attach`, `pause`, `resume`, `detach`. Weather: one `refresh` interval around a real HTTP attempt. Cache skip is not an interval. Do not wrap `FrameClock.step`.

Pause reasons stay in power and session logs. Do not invent a second taxonomy.

## Privacy

Never log precise latitude or longitude, event titles, attendees, notes, intention body, tokens, or URLs with query coordinates.

Weather may log `WeatherKind` and WMO with `privacy: .public`. HTTP status may appear in Logger for developers, never on product UI.

## Instruments

Launch `build/DerivedData/Build/Products/Debug/Keep.app`. Points of Interest, subsystem `app.keep.desktop`. Hide: `detach`. Show: `attach`. Pause: `pause`.

Do not add MetricKit, Sentry, or analytics unless asked.
