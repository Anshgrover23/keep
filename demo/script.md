# Keep — launch demo script (18s)

Made with the product-demo skill (Showreel). One claim per scene.
Rhythm grid: 0.6s = 100 BPM.

One sentence a cold scroller can repeat: Keep puts today on your Mac
desktop: the living sky, your next event, and one line you type.

Hockey stick: smash the living day (open), type in the extra (turn),
overlay on a day that turns (payoff). One shared guide: a large cursor
from frame 0 to Keep. No drag. No grant cards. No wallpaper store.

Keep is a native macOS agent. Surfaces are rebuilt from the app’s own
tokens, extra chrome, and the living-day film.

## Scene table

| # | Scene      | Secs | Starts | Claim |
|---|------------|------|--------|-------|
| 1 | TheMark    | 5.6  | 0.0    | Smash. Pieces swing home: sky, overlay, dock, menu. K lands in the extra last. |
| 2 | TheExtra   | 5.0  | 5.6    | Introducing Keep. You type today’s line. Intro Call is already the next event. |
| 3 | TheDay     | 4.4  | 10.6   | Overlay sits. The day races. |

Total: 15s. End cue = 15. Overlay lands at K land, extra out at 9.8. Day cycle is the last 5s.

## Voiceover (deadpan; timecodes are line START times)

Mute-first captions. Paste the tag block into MiniMax or ElevenLabs. Do not paste the sync notes.

KEEP, 18.0s DEMO, VOICEOVER SCRIPT
(read deadpan; timecodes are line START times)

```
[00:02.7]  Introducing Keep
[00:06.05] You type today’s line
[00:09.8]  It sits on the desktop
[00:11.5]  The day keeps moving
```

Paste this only (Neutral on every chip; a period is a breath inside the line):

```
{neutral}Introducing Keep.{/neutral}<#2.8#>{neutral}You type . today’s line.{/neutral}<#2.2#>{neutral}It sits . on the desktop.{/neutral}<#1.4#>{neutral}The day . keeps moving.{/neutral}
```

Do not caption Introducing Keep. Do not caption the typed line. Do not caption solar phases.
Do not caption Calendar, Reminders, or Location as nouns.

Sync notes (never paste into the voice tool):
Introducing Keep is spoken at 2.70 after the smash SFX. Do not caption it.
You type today’s line starts at 6.05 with the field click. Do not speak “Ship the demo”.
It sits on the desktop starts at extra out, 9.80.
The day keeps moving covers the sped cycle. Do not speak Keep at the end.
TTS will shrink the long pause tags. Cut on silences and place each line with retime-vo.mjs.

## Rhythm grid

- Frozen Sequoia desktop 0.0 to 2.0. Still rips at 1.82.
- Extra in at 2.0, top right, real menu extra chrome. Field click 2.45. Type from 2.45.
- Overlay Intro Call is already on the desktop. The typed line appears on the wallpaper as it is typed.
- Extra closes at 6.2. Day cycle runs to 15.0. No closing Keep line.

## Fixture honesty

- Intention: Ship the demo (overlay and extra field, never a caption).
- Next event: Intro Call, in 2h, 11 Sep 2026.
- Extra prompt: Today’s Keep.
- Sky after land is a compressed civil day, Keep palettes, not GPS hour.

## Sync notes (frame contracts)

- Frame 0 is one full-bleed macOS still. No shopping row of wallpapers.
- No grant cards. No drag chip. No fake TCC sheets. No Quit.
- Extra chrome matches MenuBarView: glance, Today’s Keep, three toggles, Settings, Lab, Quit Keep.
- Overlay is MemoryOverlay, leading 80, bottom 100. It is on screen while the extra is open.
- No fake full width Keep bar. Mac menu bar only. One StoryGuide cursor. I-beam only while typing.
