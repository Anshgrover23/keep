---
name: apple-macos
description: >-
  Keep macOS overlay: LSUIElement, MenuBarExtra, wallpaper NSWindow,
  NSWindow.displayLink, EventKit, CoreLocation, sandbox. Use when writing
  Swift AppKit SwiftUI for Keep. Apple docs win for APIs. The user wins for product.
---

# Apple macOS (Keep)

Apple docs win for API semantics. The user wins for product. Public Swift skills are optional specialists. Do not dump iOS defaults into this app.

## Accessory

`LSUIElement`: menu bar agent. Not `LSBackgroundOnly`. Wallpaper windows are not key. While the extra is open, Keep becomes regular so the extra field can take keys, then accessory again. Do not flip activation on every extra frame.

## Extra

Keep uses SwiftUI `MenuBarExtra` with `.window` for glance and today’s Keep. Become regular while it is open. `makeKeyAndOrderFront` is fine. `object_setClass` on that window crashed in `WindowMenuBarExtraBehavior.configuration.setter`. Do not do that.

Do not rewrite to `NSStatusItem` unless they ask. Do not add `SMAppService` because a menubar skill scaffolds it.

## Wallpaper

AppKit `NSWindow` at `desktopIconWindow` minus 1. Desktop clock: `NSWindow.displayLink`. Lab preview: `NSScreen.displayLink`. Hide detaches. Pause stays attached. Rebuild on screen change. Sleep and lock are separate notifications.

If we created the `NSWindow`, AppKit owns it. The extra is SwiftUI’s. SpriteKit `SKView` pauses when inactive. Do not use it for the desktop. Do not use `TimelineView` for desktop particles.

## Swift 6

Language mode 6. HTTP is an `actor`. Session is `@MainActor`. No `@unchecked Sendable`. No `nonisolated(unsafe)`. Copy EventKit values into Sendable drafts. EventKit import in the catalog is `@preconcurrency` so Xcode 16.4 can call `requestFullAccessToEvents`.

## EventKit

One `EKEventStore`. Prompt from onboarding, Settings, Lab. Domain types do not import EventKit. Keep does not ship EventKitUI.

## CoreLocation

Prompt on user action only. No fake latitude 23°. Unauthorized sky is solar time at TZ longitude. Approximate weather is a product status. Weather is Open Meteo through `HTTPClient`, not WeatherKit.

## Sandbox

Entitlements: `Keep/Keep.entitlements`. Hardened runtime is on. Signing identity is `-` until `keep-release` is requested. Do not copy iOS entitlement templates.

Published skill index: [sources.md](sources.md). Installing is not adopting.
