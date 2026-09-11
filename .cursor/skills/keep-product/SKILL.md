---
name: keep-product
description: >-
  Keep v1: menu bar agent and living desktop wallpaper, invitational
  permissions. Use for extra, overlay, Settings, onboarding, empty and error
  copy. Do not expand features unless asked.
---

# Keep product

Keep is a menu bar agent and a living desktop. Glance job: atmosphere, next event, Keep. Not a widget dashboard.

The user can change this. Update this file when they do.

## Surfaces

| Surface | Role |
| --- | --- |
| Wallpaper | Primary product. AppKit `NSWindow` under Finder icons. Living sky plus at most two memory lines. |
| Menu extra | Glance, today’s Keep field (store and edit here), pause, Settings, Lab, Quit. |
| Settings and onboarding | Grants, wallpaper toggle, first run. |
| Lab | Drive the same production path. Not a second weather client. |

## In v1

* Living Day: sky from solar time or GPS elevation. Weather from Open Meteo.
* Ambient Memory: at most two lines. Next calendar item (or due reminder) and today’s Keep.
* Agent (`LSUIElement`): extra as above.
* First run: intention required. Calendar and location optional, as two actions.
* Pause: lock, sleep, extra Pause wallpaper. Fullscreen and Low Power Mode only if Settings opt in.
* Display link: preferred 60 fps, range 60 to 120, unless the user asks otherwise.
* Weather status: available, approximate, stale, unavailable. Last `WeatherKind` kept on HTTP failure. No HTTP codes on product UI.
* Overlay titles: regular serif, not ultralight.

No feature expansion unless they ask.

## Leave out until asked

Custom video wallpaper, widgets, Screenpipe, contacts, streaks, iCloud, iOS companion, EventKitUI, WeatherKit, MapKit UI, launch at login, Sparkle, App Store listing, Hallmark on the Mac UI, SwiftData, CloudKit, TCA.

## Permissions

Invitational. Optional means they can continue. Name what the grant enables. Do not threaten a skip.

Right: button `Show next event`. Helper `Keep can show your next event from Calendar.`
Right: button `Use local weather`. Helper `Keep can use your location for weather and daylight where you are.`

Empty calendar: quiet day. Calendar off: `Keep can show your next event.` Approximate weather is still weather. Helper text wraps.

Purpose strings: one sentence, what Keep uses the data for.
