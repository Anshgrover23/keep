# Sources

Public skills this file distilled. Read them when doing web UI or strict TDD; do not import their landing-page defaults into Keep.

## Anti-slop and writing

* [anthropics/claude-code frontend-design](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md): one job per string; name the user job; empty and error are direction; no default AI chrome. Install: `npx skills add anthropics/skills --skill frontend-design` (packaging varies by index).
* [Vinayak-Shukla-03/anti-ai-slop](https://github.com/Vinayak-Shukla-03/anti-ai-slop): no benefit-speak; no fabricated precision; pre-ship look.
* [jhuse25/anti-slop-kit](https://github.com/jhuse25/anti-slop-kit): ban tells, then one signature; pre-flight is a gate.
* [loreleiweb/triumphoid-anti-slop-frontend](https://github.com/loreleiweb/triumphoid-anti-slop-frontend): zero-tolerance em dash in web copy; progressive disclosure of references.
* Hallmark (`npx skills add nutlope/hallmark`): web pages. Not a native wallpaper license.

## Apple, Swift, SwiftUI, AppKit

See [apple-macos](../apple-macos/SKILL.md) and [apple-macos/sources.md](../apple-macos/sources.md). Short list:

* twostraws SwiftUI Pro, Swift Testing Pro, Swift Concurrency Pro
* AvdLee SwiftUI Expert (`macos-scenes.md`)
* zhutao100 macos-menubar-app-development
* CharlesWiltgen/Axiom
* dpearson2699/swift-ios-skills (`eventkit`, not WeatherKit)
* Directory: https://github.com/twostraws/Swift-Agent-Skills

## Engineering process

* [obra/superpowers](https://github.com/obra/Superpowers) `test-driven-development`: behavior names; watch a test fail; do not test the mock; YAGNI. `writing-skills`: pressure-test the skill itself.
* [finfin/awesome-frontend-skills](https://github.com/finfin/awesome-frontend-skills): index of `npx skills add` packages (webapp-testing, ui engineering). Use `webapp-testing` only for web. Keep is AppKit Lab plus Swift Testing.

## This repo

Local pressure scenarios live in the table in `SKILL.md`. Add new excuses there, not as Lab helper text.

Also see `keep-process` (frozen OS), `keep-product` (v1 lock), `keep-skill-selection` (arbitration), `keep-release`, `keep-observability`, `keep-accessibility`, `keep-testing`. Copy: `prose-copy`.
