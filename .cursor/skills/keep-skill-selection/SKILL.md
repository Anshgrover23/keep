---
name: keep-skill-selection
description: >-
  Keep skill arbitration: load few skills, prefer Apple docs and this repo,
  never import an external architecture. User intent beats Keep skills.
  Use before installing public Swift or web skills.
---

# Keep skill selection

Do not install 30 more skills. A public skill is a specialist, not project authority.

If Keep skills and the user disagree, the user wins. Then fix the Keep skill so the next agent is not gaslit.

## Hazard this file exists to stop

Agents treated Keep notes as physics:

* Class swapping the extra window crashed, so they claimed extra fields cannot type.
* Energy folklore became pause on fullscreen, pause on Low Power Mode, and a 24 fps cap.
* “Implement only after approval” blocked the slice the user had already named.

Do not recreate that. Record the crash. Do not invent a second ban next to it.

## Authority

1. The user, for product.
2. Apple docs, for API semantics.
3. This repo’s code, for what Keep actually does.
4. Keep skills, as short overlays.
5. Public skills, consult only. Launch video is Showreel (`Anshgrover23/product-demo-playbook`). Do not load HyperFrames for Keep.

## Load for the slice

| Slice | Load |
| --- | --- |
| Any Keep code | `keep-process`, this file, `prose-copy` |
| Product copy, onboarding, Settings | `keep-product` |
| Lab chrome, runtime talk | `production-app` |
| Signing, notary, CI secrets | `keep-release` |
| Logger, signposts, Instruments | `keep-observability` |
| VoiceOver, Reduce Motion, focus | `keep-accessibility` |
| Tests and Lab matrix | `keep-testing` |
| AppKit, EventKit, CoreLocation | `apple-macos`, then one specialist if the API is unfamiliar |
| Launch / product demo video | `product-demo-playbook` only (Vouch, Colosseum, Excalidraw). Never HyperFrames. |
| X posts, build in public, Liquid Glass essays | `original-content` plus at most one source skill from that table |

Skip the rest. Do not load all original-content source skills in one turn.

## Do not pull in unless the user named it

WeatherKit, EventKitUI, MapKit UI, WidgetKit, SwiftData, CloudKit, TCA, Alamofire, `AtmosphereEngine`, Liquid Glass wallpaper, SpriteKit `SKView`, `TimelineView` particles, Screenpipe, Hallmark on the Mac app, `SMAppService` launch at login, a new menu bar scaffold, HyperFrames.

Installing a skill is not adopting its default architecture.
