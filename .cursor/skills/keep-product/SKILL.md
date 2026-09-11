---
name: keep-product
description: >-
  Keep v1 product contract: menu bar agent and living desktop wallpaper,
  invitational permissions, no feature expansion unless asked. Use when adding
  features, onboarding, overlay copy, Settings, accessibility, empty or error
  states, or when tempted by widgets, video, streaks, iCloud, iOS, Screenpipe,
  or web app chrome.
---

# Keep product

Keep is a **menu bar agent and living desktop**, not a conventional desktop app.

Glance job: **atmosphere, next event, Keep.** The desktop remembers. It is not a widget dashboard.

## Surfaces

| Surface | Role |
| --- | --- |
| Wallpaper | Primary product. AppKit `NSWindow` under Finder icons. Living sky plus at most two memory lines. |
| Menu bar extra | Control and status. Glance, today’s Keep field, pause, Settings, Lab, Quit. Store and edit the intention here. |
| Settings and onboarding | Supporting. Grants, wallpaper toggle, first run. |
| Lab | Drive and break the **same** production path. Not a second weather client. Not golden test labels on buttons. |

Avoid web app UI conventions in the Mac app: no dashboard cards, no marketing hero, no “Get started” wizard chrome, no Hallmark layouts.

## In v1

* Living Day: sky from solar time or GPS elevation; weather from Open Meteo.
* Ambient Memory: at most two lines. Next calendar item (or due reminder) and today’s Keep.
* Menu extra agent (`LSUIElement`): glance, today’s Keep, pause, Settings, Lab, Quit.
* First run: intention required. Calendar and location optional, as two actions.
* Pause: lock, sleep, and the extra Pause wallpaper toggle. Fullscreen apps and Low Power Mode do not pause unless turned on in Settings.
* Weather status in extra and Settings: available, approximate, stale, unavailable. Last `WeatherKind` kept on HTTP failure. Never show `HTTP 503` on product UI.
* Overlay titles: regular serif, not ultralight.
* Accessibility is part of production quality: Reduce Motion, VoiceOver, keyboard focus, empty and error states, offline behavior, and permission denial. See `keep-accessibility`.

No feature expansion unless explicitly requested.

## Out of v1 (do not pull these in via skill discovery)

Custom video wallpaper, widgets, Screenpipe, contacts, streaks, iCloud, iOS companion, EventKitUI editors, WeatherKit, MapKit UI, launch at login until asked, Sparkle until asked, App Store listing until asked, Hallmark, Firecrawl, Hyperframes, Liquid Glass wallpaper, SwiftData, CloudKit, TCA.

External skills that default to those must be **rejected explicitly**.

## Permissions

Permissions are **invitational**, never threat based.

Optional permissions explain what additional experience they unlock. Optional already means they can continue.

Wrong: `If you skip this, Keep will not show a next event.`
Wrong: `Without location, weather stays approximate.`
Wrong: `Allow calendar` then a punishment line.
Right: button `Show next event`. Helper `Keep can show your next event from Calendar.`
Right: button `Use local weather`. Helper `Keep can use your location for weather and daylight where you are.`

Purpose strings match that voice. One sentence. What Keep uses the data for. No `so you don’t miss it`.

Empty calendar: quiet day. Calendar off: invitation (`Keep can show your next event.`). Never `Calendar not granted` on the extra.

Never imply the app is broken because an optional permission was denied. Approximate weather is still weather. Do not fake GPS precision.

Helper text wraps. Do not clip to a trailing ellipsis.

## Motivation

Temptation to install comes from **the glance doing work** (next meeting, one intention, living weather), not from streaks or slogans.

## Related

`prose-copy` for every string. `keep-accessibility` for VO and Reduce Motion. `keep-process` if a “product improvement” wants a new engine.
