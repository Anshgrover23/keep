---
name: apple-macos
description: >-
  Keep macOS overlay: LSUIElement, MenuBarExtra, wallpaper NSWindow,
  NSWindow.displayLink, per display lifecycle, desktop window levels,
  sleep lock, CoreLocation, EventKit, sandbox, accessibility, notarization.
  Use when writing Swift AppKit SwiftUI EventKit CoreLocation or Swift Testing
  for Keep. Apple docs win for API semantics; Keep product contract wins for
  product behavior.
---

# Apple macOS (Keep)

Public Swift and Apple skills exist. Install them only for the slice, then reconcile (`keep-skill-selection`). This file is the **Keep overlay**: wallpaper windows, accessory apps, and what those skills get wrong for this product.

> Apple documentation wins for API semantics. Keep's product contract wins for product behavior.

Index of packages: [sources.md](sources.md).

## Load first for Keep

1. `keep-skill-selection` and `keep-process`.
2. This skill.
3. `production-app` for chrome, Lab vs product.
4. One published skill only if the slice needs API depth (SwiftUI views, Swift 6, EventKit, tests). Do not dump 80 iOS skills into a menu bar wallpaper app.

## Accessory and activation

* `LSUIElement` is the contract: menu bar agent, Quit, Settings, Lab. Not `LSBackgroundOnly`.
* Do not flip `NSApplication.activationPolicy` on every extra frame.
* Wallpaper windows are not key. `IntentionEditorWindow` becomes regular while open.

## Shell choice (menu extra)

From [zhutao100/macos-menubar-app-dev-skill](https://github.com/zhutao100/macos-menubar-app-dev-skill), plus our crash:

| Need | Shell |
| --- | --- |
| Toggles and buttons only | `MenuBarExtra` `.menu` |
| Glance panel (Keep extra) | `MenuBarExtra` `.window` is fine for **display** |
| Typing, first responder, left vs right click, hotkeys | `NSStatusItem` and `NSPopover` or a Keep owned `NSPanel` |

Keep today: extra is `.window` for glance. **Today’s Keep** edits in `IntentionEditorWindow` (`NSPanel` we own). Do not `object_setClass` SwiftUI’s extra window. That crashed in `WindowMenuBarExtraBehavior.configuration.setter`.

> Do not use typing into `MenuBarExtra` as proof of keyboard behavior. The editor window owns text input.

AvdLee `macos-scenes` prefers `MenuBarExtra` over `NSStatusItem`. True for simple menus. Keep already hit the exception: focusable fields. Do not rewrite the extra to `NSStatusItem` unless the user asked.

Do not add `SMAppService` launch at login because a menubar skill scaffolds it.

## Wallpaper window

* AppKit `NSWindow` at `desktopIconWindow` minus 1.
* Desktop clock: `NSWindow.displayLink`. Lab preview: `NSScreen.displayLink`. Not the same clock.
* Hide **detaches**. Pause stays attached (`WallpaperDisplayLinkPolicy`).
* Per display lifecycle: rebuild on screen change; occupancy and true fullscreen classified per display; own PID ignored.
* Sleep and lock: `PowerMonitor` notifications. Treat as separate reasons.

[ckorhonen macos-apps](https://github.com/ckorhonen/claude-skills/blob/main/skills/macos-apps/references/swiftui-patterns.md): if SwiftUI hosts the window, do not fight it with more AppKit. If **we** created the `NSWindow`, AppKit is the owner. Wallpaper and intention panel are ours. Menu extra is SwiftUI’s.

Do not use `TimelineView` for desktop particles. Do not use SpriteKit `SKView` (pauses when inactive).

## Swift 6

Keep is language mode 6. HTTP is an `actor`. Session stays `@MainActor`. No `@unchecked Sendable`. No `nonisolated(unsafe)`. EventKit values are copied into Sendable drafts. For concurrency depth use twostraws Swift Concurrency Pro or Axiom, then still obey this repo.

## EventKit

One `EKEventStore`. Prompt only from onboarding, Settings, Lab. Re-read auth on refresh. Domain types do not import EventKit. Next event rules are Keep policy (`NextMemoryPolicy`), not Apple’s UI.

Published `eventkit` skills include EventKitUI. Keep does not ship EventKitUI.

## CoreLocation

Prompt on user action only. No fake latitude 23°. Unauthorized sky is solar time at TZ longitude. Approximate weather is a product status, not an API error. CoreLocation Lab is verified (11 Sep 2026). Do not reopen “we still need a location Lab.”

WeatherKit skills: **do not adopt.** Weather is Open Meteo through `HTTPClient`.

## Sandbox and notarization

Entitlements live in `Keep/Keep.entitlements` (sandbox, network client, calendars, location, reminders). Hardened runtime is on. Signing identity is still `-` until `keep-release` work is requested.

Apple docs win for sandbox exception semantics. Do not copy Axiom or iOS entitlement templates wholesale.

Accessibility: `keep-accessibility`. Notarization: `keep-release`.

## Tests

Swift Testing (`@Test`, `#expect`). Behavior, not counts (`keep-testing`). Lab on the wallpaper window is still required for display link and fullscreen.

## Do not import from iOS skills

Liquid Glass as the whole UI. WeatherKit as default weather. `NavigationStack` as app chrome. iPhone Dynamic Type recipes as the only a11y story. Catalyst. StoreKit. WidgetKit (out of Keep v1).

## Install (only when the slice needs them)

```bash
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro
npx skills add https://github.com/twostraws/swift-testing-agent-skill --skill swift-testing-pro
npx skills add https://github.com/twostraws/swift-concurrency-agent-skill --skill swift-concurrency-pro
npx skills add https://github.com/avdlee/swiftui-agent-skill --skill swiftui-expert-skill
npx skills add https://github.com/zhutao100/macos-menubar-app-dev-skill --skill macos-menubar-app-development
npx skills add dpearson2699/swift-ios-skills --skill eventkit
npx skills add CharlesWiltgen/Axiom
```

Directory of more packages: https://github.com/twostraws/Swift-Agent-Skills

Installing is not adopting. Reconcile, then reject conflicts out loud.
