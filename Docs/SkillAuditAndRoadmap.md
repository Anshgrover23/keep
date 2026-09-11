# Keep skill audit and production roadmap

Discovery only. No product code in this pass. Stages 1 through 8 stay frozen. Do not add `AtmosphereEngine`.

The brief’s line that CoreLocation Lab is outstanding and that product work has not started is **stale**. Operator Lab 11 Sep 2026 covered the wallpaper `NSWindow` and CoreLocation deny / grant / approximate weather. App Store shipping is still not claimed.

Open the visual report beside chat: `.cursor/projects/Users-ansh-mac-live-wallpaper/canvases/keep-skill-audit.canvas.tsx`.

## Locations

| Location | Result |
| --- | --- |
| `mac-live-wallpaper/.cursor/skills` | keep-process, keep-product, production-app, prose-copy, apple-macos |
| `mac-live-wallpaper/.cursor/rules` | Missing |
| `AGENTS.md`, `CLAUDE.md`, `CURSOR.md`, repo `skills/` | Missing |
| `mac-live-wallpaper/.claude` | Missing |
| `~/.cursor/skills` | Keep five plus Firecrawl, Hyperframes, Screenpipe |
| `~/.claude/skills` | Keep five plus web UI taste packs, find-skills |
| `~/.agents/skills` | Keep five, Axiom suite, EventKit, menubar, twostraws Pro packs |
| `~/.cursor/skills-cursor` | Cursor product (canvas, Bugbot, security review) |
| `~/.codex/skills` | Firecrawl family |
| `~/.config/skills` | Missing |
| `~/.config` | Present (goose, opencode, raycast). Not walked as a Keep skill tree |
| Keep CI | `.github/workflows/ci.yml` macos-15 Debug test |

Not inspected this turn: Xcode AdditionalDocumentation bundle, skills.sh live index, Raycast/Goose plugin trees.

## Always apply

keep-process, keep-product, production-app, prose-copy, apple-macos.

## Consult for the slice (already installed)

* macos-menubar-app-development: LSUIElement, menu bar visibility. Do not scaffold a new app. Do not adopt SMAppService or NSStatusItem unless Keep asks.
* eventkit: one store, auth. Do not adopt EventKitUI.
* axiom-location `core-location.md`: When In Use, deny while running. No MapKit UI. No Always.
* axiom-macos sandbox and direct-distribution: entitlements, notarytool (Apple TN3147). Sparkle is a later product ask.
* axiom-security code-signing: Developer ID. Current project uses `CODE_SIGN_IDENTITY = "-"`.
* axiom-performance energy and memory: Instruments on the wallpaper window, not Lab preview.
* swift-concurrency-pro and axiom-concurrency: new isolation errors only. No `@unchecked Sendable`. Keep Swift 6.0; ignore “target 6.2” if the toolchain is 6.0.
* swift-testing-pro and axiom-testing: async tests. XCUI is not wallpaper proof.
* axiom-accessibility: extra, Settings, first run. Reduce Motion already on particles.
* axiom-networking: only if HTTPClient policy is reopened. Policy is frozen.
* axiom-apple-docs: official API text when Axiom and Apple disagree. Apple wins on APIs. Keep wins on product policy.
* Cursor review-bugbot / review-security: on request for a PR, not always on.

## Do not apply to Keep

Hallmark, design-taste, Firecrawl, Hyperframes, Screenpipe, WeatherKit, MapKit UI, Liquid Glass wallpaper, SwiftData, CloudKit, TCA, Alamofire, ceeK/Solar, TimelineView desktop, SpriteKit wallpaper, EventKitUI.

## Gaps (not defects in Stage 1–8)

* Distribution: ad hoc sign, hardened runtime on, sandbox on. No notary.
* CI: Debug test, no `-derivedDataPath`, no Release compile.
* Observability: `KeepLog` exists. No `os.signpost`, no MetricKit.
* Settings: explicit pause defaults. No schema version.
* Crash and version pipeline: `CURRENT_PROJECT_VERSION` 1. No dSYM release flow.
* Localization catalog: English only.
* Launch at login: out of v1 until asked.

## Roadmap (wait for an explicit go)

1. Observability signposts on attach, pause, detach, weather refresh. Boundary: KeepLog.
2. Settings schema version on AppSettings. Unit missing keys and unknown version.
3. CI: derivedDataPath plus Release compile without shipping.
4. Energy Lab on the wallpaper `NSWindow` (Instruments). Policy already detaches on hide.
5. VoiceOver on extra and Settings. Do not type in MenuBarExtra.
6. Choose Mac App Store or Developer ID plus notary. Then signing skill. Sparkle separate.
7. Crash/version policy after a channel exists.

Defer: SMAppService, NSStatusItem migration, Metal, localization catalog.
