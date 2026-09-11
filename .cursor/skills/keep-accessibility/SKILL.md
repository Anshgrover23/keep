---
name: keep-accessibility
description: >-
  Keep accessibility: VoiceOver labels, Settings and onboarding navigation,
  keyboard focus, IntentionEditorWindow, Reduce Motion, menu bar interaction.
  Use when changing extra, overlay, Settings, onboarding, or the intention
  panel. Do not use typing into MenuBarExtra as proof of keyboard behavior.
---

# Keep accessibility

Accessibility is a product requirement (`keep-product`), not a polish pass.

> Do not use typing into `MenuBarExtra` as proof of keyboard behavior. The editor window owns text input.

## Surfaces

| Surface | Expectation |
| --- | --- |
| Wallpaper overlay | VoiceOver can reach memory lines if we expose them; do not steal desktop icon AX. Overlay is visual atmosphere first; do not add a hidden web document tree. |
| Menu extra | Buttons and toggles have labels that name the job. Glance status is readable. |
| Settings | Full keyboard navigation. Grants are invitational (`prose-copy`). |
| Onboarding | Intention required field is reachable. Optional calendar and location are not focus traps. |
| `IntentionEditorWindow` | Becomes key. Typing, cancel, save. This is the text input Lab. |

## Reduce Motion

If Reduce Motion is on, do not add extra scene thrash to “prove” the wallpaper is alive. Pause and hide still follow `WallpaperDisplayLinkPolicy`. Do not invent a second animation stack.

## VoiceOver

* Labels match on-screen job names, not type names (`WeatherService`, `EKEvent`).
* Do not announce HTTP codes.
* Denied optional calendar: invitation copy, not “not granted.”
* Approximate weather: do not imply GPS lock.

## Keyboard

* Extra `.window` is for display. Do not isa-swap it to steal first responder.
* Tab order in Settings and onboarding must hit every control that a pointer can hit.
* Escape closes the intention panel without saving if that is current behavior; do not “improve” by changing save semantics unless asked.

## Menu bar

Inactive accessory app (`LSUIElement`): extra still opens. Wallpaper is not a key window. Do not flip activation policy every extra frame to fake focus.

## Related

`apple-macos` for window ownership. `keep-testing` for VO and Reduce Motion as failure modes. SwiftUI Pro a11y notes are specialists; reject iPhone only Dynamic Type recipes as the whole story.
