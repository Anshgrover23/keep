# Published Apple and Swift skills

Install with [skills CLI](https://github.com/vercel-labs/skills) (`npx skills add …`). Cursor, Claude Code, and Codex all read `SKILL.md`.

## Directories

| Package | What it is | Install |
| --- | --- | --- |
| [twostraws/Swift-Agent-Skills](https://github.com/twostraws/Swift-Agent-Skills) | Curated list: SwiftUI, concurrency, testing, SwiftData, a11y, App Intents | Browse, then install the child repo |
| [dpearson2699/swift-ios-skills](https://github.com/dpearson2699/swift-ios-skills) | Large iOS 26 plus SwiftUI plus EventKit, MapKit, WeatherKit, … | `npx skills add dpearson2699/swift-ios-skills` then pick skills |
| [CharlesWiltgen/Axiom](https://github.com/CharlesWiltgen/Axiom) | Big Apple OS suite (Swift 6, UI, data, auditors, xcodebuild helpers) | `npx skills add CharlesWiltgen/Axiom` |
| [rshankras/claude-code-apple-skills](https://github.com/rshankras/claude-code-apple-skills) | Many Claude Code skills: AppKit bridge, HIG, testing, App Store | Clone or marketplace; heavy |
| [efremidze/swift-patterns-skill](https://github.com/efremidze/swift-patterns-skill) | SwiftUI state, navigation, concurrency, testing DI | `npx skills add https://github.com/efremidze/swift-patterns-skill --skill swift-patterns` |

## SwiftUI

| Skill | Author | Install | Use for Keep |
| --- | --- | --- | --- |
| SwiftUI Pro | Paul Hudson / twostraws | `npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro` | Deprecated API, VoiceOver, performance mistakes LLMs make |
| SwiftUI Expert | AvdLee | `npx skills add https://github.com/avdlee/swiftui-agent-skill --skill swiftui-expert-skill` | State, lists, **macos-scenes.md**, macos-views, window styling |
| SwiftUI UI Patterns | Dimillian | See Swift-Agent-Skills | iOS-ish patterns; skim only |

AvdLee `references/macos-scenes.md`: `MenuBarExtra` `.menu` vs `.window`, `Settings`, `LSUIElement`. It prefers MenuBarExtra over NSStatusItem. Keep’s typing crash is the documented exception.

## macOS shells and HIG

| Skill | Install / URL | Notes |
| --- | --- | --- |
| macos-menubar-app-development | `npx skills add https://github.com/zhutao100/macos-menubar-app-dev-skill --skill macos-menubar-app-development` | Shell table, LSUIElement contract, escalate to NSStatusItem+popover when focus matters. Closest to Keep. |
| macos-app-best-practices | [duyet/codex-claude-plugins](https://github.com/duyet/codex-claude-plugins/blob/master/build-macos-apps/skills/macos-app-best-practices/SKILL.md) | Scene types, Catalyst warning |
| apple-hig-expert | [borghei/Claude-Skills](https://github.com/borghei/Claude-Skills/blob/main/product-team/apple-hig-expert/SKILL.md) | HIG across Apple platforms |
| macos-hig-designer | [designnotdrum/skills](https://github.com/designnotdrum/skills/blob/main/macos-hig-designer/SKILL.md) | Tahoe / Liquid Glass; do not restyle Keep wallpaper as glass |
| AppKit SwiftUI bridge | [rshankras hosting-controllers](https://github.com/rshankras/claude-code-apple-skills/blob/main/skills/macos/appkit-swiftui-bridge/hosting-controllers.md) | NSHostingController vs NSHostingView |
| SwiftUI vs AppKit debug | [ckorhonen swiftui-patterns](https://github.com/ckorhonen/claude-skills/blob/main/skills/macos-apps/references/swiftui-patterns.md) | Do not fight a SwiftUI-owned window with AppKit hacks |
| menubar (NSStatusItem recipe) | [KhanShaheb34/menubar SKILL.md](https://github.com/KhanShaheb34/menubar/blob/main/SKILL.md) | Explicit: MenuBarExtra is weaker for keyboard focus |

## Swift language, concurrency, tests

| Skill | Install |
| --- | --- |
| Swift Testing Pro | `npx skills add https://github.com/twostraws/swift-testing-agent-skill --skill swift-testing-pro` |
| Swift Concurrency Pro | `npx skills add https://github.com/twostraws/swift-concurrency-agent-skill --skill swift-concurrency-pro` |
| SwiftData Pro | `npx skills add https://github.com/twostraws/swiftdata-agent-skill --skill swiftdata-pro` (Keep does not use SwiftData) |
| twostraws AGENTS.md | https://github.com/twostraws/SwiftAgents |

## Frameworks Keep actually uses

| Skill | In dpearson2699 set | Keep overlay |
| --- | --- | --- |
| eventkit | `npx skills add dpearson2699/swift-ios-skills --skill eventkit` | One store, no EventKitUI, next-memory policy is ours |
| mapkit / CoreLocation | same pack `mapkit` | No fake lat 23°. Prompt only on user action |
| weatherkit | same pack | **Do not adopt.** Open Meteo plus HTTPClient |

## What is not a Mac wallpaper skill

Anthropic `frontend-design`, Hallmark, anti-slop-kit: web pages. Axiom and swift-ios-skills are iOS-heavy; use routers, do not apply Liquid Glass, WidgetKit, or WeatherKit as defaults.

## Keep local skills

Project authority: `keep-process`, `keep-product`, `production-app`, `keep-release`, `keep-observability`, `keep-accessibility`, `keep-testing`, `apple-macos` (this overlay), `prose-copy`, `keep-skill-selection`. Global Axiom EventKit menubar skills are specialists only.
