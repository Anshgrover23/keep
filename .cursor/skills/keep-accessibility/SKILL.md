---
name: keep-accessibility
description: >-
  Keep accessibility: VoiceOver labels, Settings and onboarding navigation,
  keyboard focus, extra TextField, Reduce Motion, menu bar interaction.
  Use when changing extra, overlay, Settings, or onboarding.
  Lab typing proof is the extra field, not a unit test.
---

# Keep accessibility

Accessibility is a product requirement (`keep-product`), not a polish pass.

> Lab typing proof is the extra field on the real menu extra.

## Surfaces

| Surface | Expectation |
| --- | --- |
| Wallpaper overlay | VoiceOver can reach memory lines if we expose them; do not steal desktop icon AX. Overlay is visual atmosphere first; do not add a hidden web document tree. |
| Menu extra | Buttons and toggles have labels that name the job. Glance status is readable. |
| Settings | Full keyboard navigation. Grants are invitational (`prose-copy`). |
| Onboarding | Intention required field is reachable. Optional calendar and location are not focus traps. |
| Extra field | Today’s Keep. Becomes regular while the extra is open. Return commits. Closing the extra commits. This is the text input Lab. |

## Reduce Motion

If Reduce Motion is on, do not add extra scene thrash to “prove” the wallpaper is alive. Pause and hide still follow `WallpaperDisplayLinkPolicy`. Do not invent a second animation stack.

## VoiceOver

* Labels match on-screen job names, not type names (`WeatherService`, `EKEvent`).
* Do not announce HTTP codes.
* Denied optional calendar: invitation copy, not “not granted.”
* Approximate weather: do not imply GPS lock.

## Keyboard

* Extra `.window` hosts today’s Keep. Activate while it is open. Do not isa-swap it.
* Tab order in Settings and onboarding must hit every control that a pointer can hit.
* Closing the extra commits today’s Keep.

## Menu bar

Inactive accessory app (`LSUIElement`): extra still opens. Wallpaper is not a key window. Do not flip activation policy every extra frame to fake focus.

## Related

`apple-macos` for window ownership. `keep-testing` for VO and Reduce Motion as failure modes. SwiftUI Pro a11y notes are specialists; reject iPhone only Dynamic Type recipes as the whole story.
