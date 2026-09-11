# Keep architecture

Keep is a macOS agent app. `KeepApp` / `AppDelegate` owns one `AppSession`. The session coordinates services; it does not talk to EventKit, CoreLocation, or URLSession itself.

```
KeepApp
  AppSession (MainActor coordinator)
    CalendarReading     CalendarService → CalendarCataloging → EventKitCatalog (one EKEventStore)
    WeatherFetching     WeatherService → HTTPClient (actor) → HTTPTransport (URLSession)
    LocationProviding   LocationProvider → LocationFix (GPS or TZ longitude)
    SolarEngine         Daylight (no CoreLocation; observer is geographic or solarTime)
    WallpaperController NSWindow per display
    PowerMonitor        lock, sleep, LPM; occupancy via FullscreenClassification
    IntentionStore      via SettingsStore
```

Views observe `AppSession`. Wallpaper windows sit at `desktopIconWindow` minus 1. Scene frames come from that window’s `NSWindow.displayLink` (`FrameClock`). Lab preview uses `NSScreen.displayLink` and is not proof of desktop lifecycle.

Domain models (`MemoryItem`, `CalendarOccurrence`, `DayPhase`, `WeatherKind`, `SolarContext`) do not import SwiftUI, AppKit, or EventKit. Sky colors live in `SkyAppearance`.

## Why not extra libraries

* **TCA:** too much for one session and six services.
* **ceeK/Solar:** sunrise/sunset only; we need elevation for midday vs morning.
* **WeatherKit:** Apple capability / paid team; Open Meteo is the v1 source.
* **Alamofire:** one GET with an explicit timeout and one retry on 5xx/transport only.

## HTTP

`HTTPClient` owns request policy (timeout, Accept, cache, max attempts). `WeatherService` never sees `URLSession`. Lab “fail next weather” queues an HTTP 503 on that same client; retries do not fall through to Open Meteo.

* **4xx including 429:** not retried. 429 is treated as a client error, not a delayed 5xx. We do not honor the Retry After header until Open Meteo actually rate limits Keep.
* **3xx:** no custom redirect delegate. `URLSession` follows redirects; `HTTPClient` grades the **final** response.

## Calendar (“next memory”)

`EventKit` types stay in `EventKitCatalog`. Selection is `NextMemoryPolicy` over `CalendarSnapshot`.

The table below is **Keep product policy**, except where it names an EventKit API. EventKit does not define the 12 hour lookback, all day fallback, reminder ranking, or title placeholders.

| Rule | Behavior | Authority |
| --- | --- | --- |
| Reference time | The `now` passed into select/refresh | Keep |
| Timed events | `end > now`, `start` within last **12h** through next **36h** | Keep policy |
| In progress | Qualifies; overlay caption is `now` | Keep policy |
| Midnight crossing | Same as in progress; `MemoryItem.date` is original start | Keep policy |
| All day | Only if no eligible timed event; overlap local day | Keep policy |
| Cancelled / declined | Excluded | Keep policy (uses EventKit status/attendee when mapping) |
| Calendars | All calendars EventKit can read (`calendars: nil`) | EventKit query |
| Ordering | Earliest start among eligible timed events | Keep policy |
| Reminders | Incomplete with due date; overdue beats a non imminent event | Keep policy |
| Empty / denied / restricted / write only / not determined | `nextItem == nil` | Keep and EventKit auth mapping |
| Authorization | Read again on every refresh. Prompt only from onboarding / Settings / Lab | EventKit and Keep |
| Store changes | `EKEventStoreChanged` on the single store triggers refresh | EventKit API; handler wiring unit/boundary tested; live store change Lab 11 Sep 2026 |

**Evidence (11 Sep 2026):** Lab/system checks passed for real denial, grant without relaunch, empty calendar, store changed update, and midnight spanning event.

## Location and solar

CoreLocation stays in `LocationProvider`. Solar math takes a `SolarObserver` and never imports CoreLocation.

| Situation | Behavior | Authority |
| --- | --- | --- |
| GPS granted and a fix | `LocationFix.gps` → elevation model | CoreLocation and astronomy |
| Denied / restricted / not determined / no fix | `LocationFix.timeZone` longitude = GMT offset × 15° (DST aware) | Keep fallback policy |
| Fake latitude 23° | **Removed.** It invented tropic geography and made Iceland June midnight look like night | n/a |
| Unknown latitude sky | Phase from solar time at TZ longitude (12h visual day). Polar day/night is wrong until GPS | Keep policy |
| Weather without GPS | Open Meteo query uses equator and TZ longitude, labeled approximate | Keep policy |
| Prompt | Only onboarding / Settings / Lab | Apple location prompt |

**Evidence:** Golden tests cover TZ longitude, DST, denied discards GPS, IST solar time bands, and Reykjavik vs 23°. Operator Lab 11 Sep 2026: deny, grant without relaunch, and approximate weather with denied GPS on the real CoreLocation path.

## Desktop display link lifecycle

`WallpaperDisplayLinkPolicy` decides CADisplayLink state. `WallpaperController` applies it to **wallpaper windows only**.

| Situation | Display link | Window |
| --- | --- | --- |
| Visible, session running | `NSWindow.displayLink`, not paused | ordered in |
| Visible, paused (user / lock / sleep; fullscreen or Low Power Mode only if Settings opt in) | attached, paused | stays ordered in |
| Hidden (Lab toggle) or display gone | **detached** (invalidated) | `orderOut` |
| App accessory / inactive | no extra pause; `hidesOnDeactivate` is false | stays under icons |
| Screen parameters change | rebuild windows; leftover displays detach | Lab/system passed 11 Sep 2026 |

Sleep is not lock: `willSleep` / `screensDidSleep` set asleep; lock notifications set locked. Wake does not clear a lock that is still asserted.

**Evidence (11 Sep 2026):** Desktop Lab passed on the wallpaper `NSWindow`: rain while accessory, pause/resume of the desktop (not only Lab preview), lock/unlock and sleep/wake, hide (Finder picture and frozen desktop steps), and plug/unplug display. Lab preview remains `NSScreen.displayLink` and is not that proof.

## Fullscreen occupancy

There is no public “any app is fullscreen” API. Keep classifies layer 0 windows (CGWindowList, Cocoa converted bounds) against each `NSScreen`:

| Covering | Geometry | Wallpaper on that display |
| --- | --- | --- |
| True fullscreen | bounds ≈ `screen.frame` | pause if “Pause in fullscreen” |
| Maximized / zoomed | bounds ≈ `visibleFrame` | do not pause |
| Keep Lab / our PID | ignored | never counts as covering |
| Other display | classified independently | only the covered display pauses |

Lock and sleep pause every display. Low Power Mode and true fullscreen do not, unless Settings opt in. Simulated fullscreen pauses every display (Lab). If menu bar and Dock are hidden, `visibleFrame` can equal `frame` and maximized is indistinguishable from fullscreen.

**Evidence (11 Sep 2026):** Lab on the wallpaper window: zoomed/Fill does not pause; Keep Lab does not count as covering. Native Full Screen pauses that display only when Pause in fullscreen is on.

## Menu extra keyboard

Keep launches as `LSUIElement` (accessory). Today’s Keep is a field in the window style extra. While the extra is open Keep becomes regular and asks that window to take keys. Do not change the extra window’s class. That swap crashed in `WindowMenuBarExtraBehavior.configuration.setter`. Closing the extra writes the intention.

## Logging

`KeepLog` categories (`wallpaper`, `calendar`, `weather`, `location`, `session`, `power`) via `os.Logger`. Same subsystem `app.keep.desktop` owns `OSSignposter` intervals: wallpaper `attach`, `pause`, `resume`, `detach` on display link policy changes only (never on each frame), and weather `refresh` around one HTTP attempt (no coordinates). Filter Console.app and Instruments Points of Interest by that subsystem.

## Tests

Tests describe behavior. A passing count is not coverage. Implemented, unit, boundary, Lab, and distribution stay separate claims. In process tests are not proof of process kill or a TCC identity change.

## Product weather and glance

Sky still uses last `WeatherKind`. Failures do not reset to clear. Open Meteo runs only for a GPS fix. Time zone fallback does not fetch equator weather. Extra does not show approximate, stale, or unavailable weather lines. Settings shows `WeatherStatus` as Status. Approximate means time zone location, not an HTTP error. Calendar extra copy: toggle off has no glance. Toggle on and granted with nothing upcoming is a quiet day. Toggle on asks Calendar and Reminders. Extra `calendarGlance` uses wall clock `Date()`. Overlay titles use regular serif, not ultralight.

Lab Status uses Granted or Off for calendar and reminders. Product extra uses invitation copy when calendar is off.

**Evidence:** Unit and HTTP boundary tests keep rain after 503 or malformed JSON, mark stale after a prior success, mark approximate on a time zone fix, and split calendar glance copy.

## Product Lab (wallpaper window)

**Evidence (11 Sep 2026, operator Lab on the desktop `NSWindow`, not Lab preview):**

* Fail next weather: sky kept last kind; extra showed stale or unavailable, never HTTP 503.
* Hide detached the desktop display link; show attached it again.
* Lock, sleep, and wake stayed separate. Wake did not clear a lock that was still asserted.
* Occupancy treats native Full Screen as true fullscreen on that display. Pause only if Pause in fullscreen is on. Maximized does not pause. Keep Lab is ignored.
* Extra typing is the extra field (Return or close commits).
* First run: intention required; calendar and location optional; invitational copy.

Keep runs as a menu bar agent with wallpaper beneath Finder, atmosphere driven by solar state and weather, calendar glance, graceful weather and location denial, pause behavior, per display fullscreen handling, and production Settings and first run.

CoreLocation Lab (deny, grant without relaunch, approximate weather with denied GPS) passed 11 Sep 2026 on the real location path. App Store shipping is not claimed.

## Swift 6 concurrency

`SWIFT_VERSION` is **6.0** for Keep and KeepTests. There is no `@unchecked Sendable` and no `nonisolated(unsafe)`. `EventKitCatalog` imports EventKit with `@preconcurrency` so Xcode 16.4 does not treat `requestFullAccessToEvents` as sending the main actor store.

| Boundary | Isolation | Why |
| --- | --- | --- |
| AppSession, wallpaper, EventKit catalog, location, weather UI state, settings | `@MainActor` | AppKit, EventKit store, SwiftUI |
| HTTPClient stub/retry/exchange state | `actor` | Swift 6 forbids `NSLock` in async contexts; shared mutable HTTP state is not Sendable |
| EventKit reminder fetch | Copy `title`/`due` into Sendable drafts on the callback queue; `OSAllocatedUnfairLock` for single resume | `EKReminder` is not Sendable |
| CoreLocation delegate | Copy status/lat/lon, then hop to MainActor | `CLLocationManager` is not Sendable |

NotificationCenter still hops with `Task { @MainActor in … }` onto already main queues. That is a hop, not an unsafe silence.

## Failure modes

Tests are grouped by what can go wrong, not by how many `@Test`s exist. Lab/system rows are not unit tests.

| Failure mode | Evidence | Where |
| --- | --- | --- |
| Midnight vs noon (IST) | Unit | `KeepTests`, `LocationSolarTests` |
| Timezone / DST longitude | Unit | `LocationSolarTests` |
| Location denied / not determined / no fix | Unit | `LocationSolarTests`, `FailureModeTests` |
| Fake tropic latitude 23° | Unit (rejected) | `LocationSolarTests` |
| Real CoreLocation prompt/grant | Lab 11 Sep 2026 | `LocationProvider` |
| Malformed weather / missing WMO | Unit | `WeatherBoundaryTests` |
| Weather product status (available, approximate, stale, unavailable) | Unit, HTTP boundary, Lab 11 Sep 2026 (fail next on wallpaper) | `WeatherStatus`, `WeatherBoundaryTests` |
| HTTP 4xx / 429 / 5xx / timeout / cancel / 503 then 404 | Unit | `HTTPBoundaryTests`, `FailureModeTests` |
| Final 3xx graded, not retried | Unit | `FailureModeTests` (URLSession still follows live redirects) |
| Calendar denied / empty / midnight crossing | Unit and Lab 11 Sep 2026 | `CalendarBoundaryTests` |
| Sleep vs lock; wake does not clear lock | Unit and Lab 11 Sep 2026 | `WallpaperLifecycleTests`, `FailureModeTests` |
| Hide wallpaper / display loss | Unit and Lab 11 Sep 2026 | `WallpaperLifecycleTests` |
| True FS vs maximized vs Lab vs other display | Unit and Lab 11 Sep 2026 | `FullscreenClassificationTests` |
| Extra typing vs MenuBarExtra | Extra field; become regular while open | `MenuBarView` |
| First run optional grants | Lab 11 Sep 2026 | onboarding |
| Settings missing keys / relaunch persistence | Unit | `FailureModeTests` |
| Process death | Not simulated beyond new `AppSettings`/`AppSession` on the same suite | `FailureModeTests` |
