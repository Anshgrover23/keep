---
name: production-app
description: >-
  Keep production quality: runtime lifecycle energy permissions network stale
  data recovery, Debug tests, Release compile, derivedDataPath, plus anti-slop
  Lab vs product chrome. Use when shipping Keep, adding Lab or Settings, naming
  UI, or when a user example might be pasted into chrome. Production quality
  does not mean adding frameworks. Signing and notary live in keep-release.
---

# Production app

You are shipping software people run, not a demo of the prompt.

The failure this skill exists to stop: **the user's example taken too seriously, their words taken for granted, too much shitty talk.**

> Production quality does not mean adding frameworks.

Do not respond to “make it production” with TCA, SwiftData, Sentry, WeatherKit, or a new engine. Close the named runtime, build, or copy gap on the frozen shape (`keep-process`).

This file is the keep-production node. Distribution mechanics: `keep-release`. Logs: `keep-observability`. VO: `keep-accessibility`. Failure modes: `keep-testing`.

Related public skills are listed in [sources.md](sources.md). Steal the discipline. Do not steal landing-page chrome into a macOS agent.

## Before you type code

1. State the **job** in one sentence.
2. State the **example** separately.
3. Implement the job. Put the example in a **test**.

If those two sentences are the same, you are about to ship slop.

### Pressure scenario (this repo)

User needed proof that **midnight is not noon**. They said pin 12:01 AM vs PM.

* Test: IST `00:01` is night; `12:01` is day.
* Lab: **Pin midnight** and **Pin noon** (class of clock states). Phase picker already covers bands.
* Product: real clock. No 12:01.

Wrong: `Pin 12:01 AM (00:01)` and `Pin 12:01 PM (12:01)`.

## Runtime checklist (Mac)

Name the gap. Do not boil the ocean.

* **Lifecycle:** launch accessory, quit, hide wallpaper detaches, show attaches, extra opens while inactive.
* **Memory:** no unbounded event caches; display link not retained after detach.
* **CPU / GPU / energy:** 20 to 30 fps preferred 24; no work per frame beyond the scene; Instruments on the wallpaper window (`keep-observability`).
* **Display changes:** rebuild per `NSScreen`; occupancy per display.
* **Sleep / wake, lock / unlock:** separate; wake does not clear lock.
* **Accessibility:** `keep-accessibility`.
* **Permissions:** invitational; grant after launch works; deny is not a crash.
* **Network failure:** last weather kind; status stale or unavailable; no HTTP on UI.
* **Stale data:** schema stamp; weather lastUpdated; calendar refresh on extra appear.
* **Recovery:** fail next uses production `HTTPClient`; no second client.

## Build checklist

* Debug tests: `xcodebuild … -configuration Debug -derivedDataPath build/DerivedData -destination 'platform=macOS' test`
* Release compilation: same path, `-configuration Release` `build` (CI already). Release tests are not required.
* Always pass `-derivedDataPath` so `open` matches the binary they run.
* Signing configuration, archives, dSYMs, version numbers: `keep-release`. Do not invent identities.

## Distribution

See `keep-release`. Developer ID, hardened runtime, sandbox, notarization, stapling, Gatekeeper, clean machine.

> Do not claim "shippable" merely because `xcodebuild test` passes.

## Observability and release policy

* Structured `os.Logger` and signposts: `keep-observability`. Privacy: no precise location, no event titles.
* Crash policy, version policy, settings migration, rollback: `keep-release`. Missing schema version stamps `1` without wiping other keys.

## What to show whom

| Surface | Show | Hide |
| --- | --- | --- |
| Product | Short copy. One job per control. Current state. | Debug, golden cases, dual formats, API names, essays |
| Lab | Controls that drive behavior. Status that is true now. | Unit tests as buttons. Duplicate clocks. Copy that lectures |
| Tests | Exact times, zones, status codes, fixtures | UI labels copied from fixtures. Call-count theater |
| Docs | Decisions and what is not proven | Marketing. The same paragraph twice |

If a string would look embarrassing in a screenshot, do not ship it.

Each string does **one job**. Name the user job, not the system. Errors and empty states give a next action. They do not apologize and they do not teach architecture.

## Do not take words for granted

Casual speech is **intent**.

* "like 12:01 AM vs PM" means two distinguishable clock states.
* "the edit box" means typing must work on that surface.
* "check it all again" means search and fix, not a speech.
* "give me the command" means one command that opens the binary they run.

Pick the production reading. Ask only when two readings change architecture.

Rationalizations that already failed here:

| Excuse | Reality |
| --- | --- |
| Lab can be ugly | Ugly is fine. Stupid dual labels are not |
| I documented 24h in the button | That is the test leaking into chrome |
| They listed those two times | They illustrated a class |
| Helper text prevents mistakes | Status rows already say desktop vs preview |
| TextField in the extra should work if I activate | MenuBarExtra is not a key window. Do not isa-swap it |
| Lab's field works so product works | Different window |
| Form `TextField("Placeholder")` | macOS grouped Form uses that string as a leading label. The caret sits on the trailing edge. Use an empty title, `labelsHidden()`, rounded border |
| Lab Timer for fps while observing `FrameClock.date` | Body rebuilds every frame and restarts the timer. Count fps on the display link |
| Lifetime display link step totals | Frame ticks, not a leak. Show running or paused and fps |
| Preferred 24 fps | Range is 20 to 30. On 60 Hz, Core Animation often picks 30 |
| `HStack { label; Spacer(); yes }` | Inspector dump. Use Form `LabeledContent` or stacked facts. Real words, not yes or no |
| Hallmark on Keep | Hallmark is for web pages. Native Lab and wallpaper stay AppKit and SwiftUI |
| Plan said skip consequences | Customer copy names what they get. Loss framed skip lines are threats |
| Production means more frameworks | Close the gap on the locked architecture |

## Copy

Follow `prose-copy`. Optional grants name the gift.

## How to test

Follow `keep-testing`. Four Lab claims plus distribution stay separate from unit counts.

Lab preview (`NSScreen.displayLink`) is not the wallpaper window (`NSWindow.displayLink`).

## How to reduce ambiguity

* Name the surface: product, Lab, test, docs.
* Crash on tray click: fix the object you broke. Do not add another hack on a window SwiftUI owns.
* Old copy on screen: wrong binary. `pgrep -lf Keep`, build with `-derivedDataPath` matching `open`, kill the old process.
* Boring control that works beats clever AppKit.

Do not isa-swap foreign windows. Do not flip activation on every extra frame. Do not recap architecture unasked.

## Talk

Lead with the answer. Smallest next step.

No process theater. No "great question". No stacked disclaimers.

If you changed UI, they need a launch of **this** build:

```bash
killall Keep 2>/dev/null; xcodebuild -project Keep.xcodeproj -scheme Keep -configuration Debug -derivedDataPath build/DerivedData && open build/DerivedData/Build/Products/Debug/Keep.app
```

## Pre-ship look

If the Lab shows dual times, lecture paragraphs, or prompt leftovers, you failed the skill even if tests pass. If you only compiled Release, you have not notarized.
