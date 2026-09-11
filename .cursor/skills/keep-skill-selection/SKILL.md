---
name: keep-skill-selection
description: >-
  Keep skill arbitration: identify the slice, load only relevant skills,
  reject conflicts with frozen Keep decisions, never blindly import external
  architecture. Use before searching or installing skills, when Axiom EventKit
  menubar SwiftUI or web skills appear, or when an agent might rewrite Keep
  to match a specialist default.
---

# Keep skill selection

Do not simply install 30 more skills. Make Keep skills better at **skill arbitration**.

Otherwise you get: skill A says use X → skill B says use Y → skill C scaffolds Z → agent rewrites existing architecture.

Desired behavior:

> Keep contract → identify slice → consult specialist skill → reconcile → propose smallest change → implement only after approval.

## Hierarchy (project authority)

```
KEEP PROJECT AUTHORITY
│
├── keep-process
│   └── project lifecycle / evidence / frozen decisions
│
├── keep-product
│   └── product contract / scope / UX
│
├── production-app
│   └── production quality / runtime / release readiness
│   └── (this is the keep-production node; do not rename the skill)
│
├── keep-release
│   └── signing / notarization / archives / distribution
│
├── keep-observability
│   └── logs / signposts / diagnostics / Instruments
│
├── keep-accessibility
│   └── VoiceOver / keyboard / reduced motion
│
├── keep-testing
│   └── failure-mode verification
│
├── apple-macos
│   └── Apple platform constraints
│
└── prose-copy
    └── Keep's writing rules
```

Global skills (Axiom, EventKit, menubar, Swift concurrency, Swift Testing, Hallmark, Firecrawl, Hyperframes, Vercel, web anti slop) remain **consulted specialists**, never project authorities.

## Procedure

1. Identify the slice (one production gap).
2. Search available skills.
3. Load only skills relevant to that slice.
4. Compare their recommendations against Keep's locked decisions (`keep-process`, `keep-product`).
5. Reject conflicting recommendations explicitly (name the skill and the conflict).
6. Never blindly import an external skill's architecture.
7. Prefer Apple documentation for API behavior.
8. Prefer Keep skills for Keep product decisions.

Apple documentation wins for API semantics. Keep's product contract wins for product behavior.

## Slice → load

| Slice | Load |
| --- | --- |
| Any Keep code | `keep-process`, `keep-skill-selection`, `prose-copy` |
| Product copy, onboarding, Settings | `keep-product`, `prose-copy` |
| Runtime quality, Lab chrome, talk | `production-app` |
| Signing, notary, archives, CI secrets | `keep-release` |
| Logger, signposts, Instruments | `keep-observability` |
| VoiceOver, Reduce Motion, focus | `keep-accessibility` |
| Tests, Lab matrix, failure modes | `keep-testing` |
| AppKit, EventKit, CoreLocation APIs | `apple-macos`, then one specialist if needed |
| Swift 6 concurrency depth | twostraws or Axiom concurrency, then still obey Keep HTTP actor |
| Menu extra shell debate | `apple-macos` first; zhutao100 only for the table Keep already reconciled |
| Web, canvas, landing pages | Hallmark / Firecrawl **never** for wallpaper or extra |

## Reject on sight (unless the user named it)

* Scaffold a new menu bar app or `SMAppService` because a menubar skill says so.
* WeatherKit, EventKitUI, MapKit UI, WidgetKit, SwiftData, CloudKit, TCA, Alamofire.
* `AtmosphereEngine` or a new store as cleanup.
* Liquid Glass wallpaper, SpriteKit `SKView`, `TimelineView` particles.
* Typing proof via `MenuBarExtra`.
* iOS `NavigationStack` as app chrome.
* Installing Axiom’s full suite “for production.”

Discovery is not approval. After reconcile, propose. Wait for the named slice.
