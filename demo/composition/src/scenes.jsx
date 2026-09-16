import {
  ABS, UI, INK_DIMMER, WASH,
  MOTION, clamp, Stamp, SlideIn, StoryGuide, PAPER_INK,
} from "./kit.jsx";
import { KeepSky } from "./KeepSky.jsx";
import { cinematicAt } from "./sky.js";
import { MacStill } from "./MacStill.jsx";
import { MacMenuBar, MacDock, MENU_H, KEEP_EXTRA_X, KEEP_EXTRA_Y } from "./macChrome.jsx";

const SCENES = [
  { name: "DeadWall", secs: 2.0 },
  { name: "TheExtra", secs: 5.0 },
  { name: "TheDay", secs: 11.0 },
];
export const CUES = {};
{
  let acc = 0;
  for (const s of SCENES) { CUES[s.name] = acc; acc += s.secs; }
  CUES.End = acc;
}

const KEEP_LINE = "Ship the demo";
const TYPE_AT = CUES.TheExtra + 0.45;
const EXTRA_OUT = 6.2;
const SIT_AT = EXTRA_OUT;

const EXTRA_W = 320;
const EXTRA_RIGHT = 24;
const EXTRA_TOP = MENU_H + 6;
const EXTRA_LEFT = 1280 - EXTRA_RIGHT - EXTRA_W;
const FIELD_X = EXTRA_LEFT + 16;
const FIELD_Y = EXTRA_TOP + 16 + 22 + 16 + 12 + 4 + 20 + 16 + 16 + 8;

const STORY_CAPTIONS = [
  { at: 0, until: CUES.TheExtra, text: "Your wallpaper does not know today" },
  { at: CUES.TheExtra, until: SIT_AT, text: "You type today’s line" },
  { at: SIT_AT, until: 12.0, text: "It sits on the desktop" },
  { at: 12.0, until: 16.8, text: "The day keeps moving" },
  { at: 16.8, until: CUES.End, text: "Keep" },
];

function cycleU(T) {
  if (T < SIT_AT) return 0.22;
  return 0.22 + 0.78 * clamp((T - SIT_AT) / (CUES.End - SIT_AT), 0, 1);
}

export function captionAt(T) {
  const hit = STORY_CAPTIONS.reduce((acc, it) => (T + 1e-3 >= it.at && T < it.until ? it : acc), null);
  return hit?.text ?? STORY_CAPTIONS[0].text;
}

export const CAPTIONS = STORY_CAPTIONS;

function FilmSky({ T }) {
  return <KeepSky cycle={cycleU(T)} weather="clear" clock={T * 9} />;
}

function typedKeep(T, at, text, rate = 5) {
  if (T < at) return "";
  return text.slice(0, Math.min(text.length, 1 + Math.floor((T - at) * rate)));
}

function SceneDeadWall({ T }) {
  const out = MOTION.slide(T, 1.82, 0.28, 0, 1);
  const lift = out.on ? out.v : 0;
  return (
    <div style={{ ...ABS, inset: 0, overflow: "hidden", pointerEvents: "none", zIndex: 18 }}>
      <div style={{ ...ABS, inset: 0, transform: `translateY(${-760 * lift}px)` }}>
        <MacStill src="../assets/macos/sequoia-grove.jpg" />
        <div style={{ ...ABS, left: 0, right: 0, bottom: 0, height: 120, background: "linear-gradient(transparent, rgba(20,24,18,0.35))" }} />
      </div>
    </div>
  );
}

function overlayColors(T) {
  const c = cinematicAt(cycleU(T));
  return c.nightInk
    ? { ink: "#f4efe4", cap: "rgba(244,239,228,0.78)" }
    : { ink: PAPER_INK, cap: "rgba(28,36,48,0.72)" };
}

function MemoryLines({ T, intention }) {
  const c = overlayColors(T);
  const night = cinematicAt(cycleU(T)).nightInk;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 22, maxWidth: 720, textShadow: night ? "0 2px 16px rgba(0,0,0,0.7), 0 0 2px rgba(0,0,0,0.9)" : "0 1px 0 rgba(255,255,255,0.35), 0 6px 18px rgba(0,0,0,0.22)" }}>
      <div>
        <div style={{ ...UI, fontSize: 13, fontWeight: 500, letterSpacing: "0.32em", textTransform: "uppercase", color: c.cap }}>In 2h</div>
        <div style={{ fontFamily: "Fraunces, serif", fontSize: 34, fontWeight: 400, color: c.ink, marginTop: 8 }}>Intro Call</div>
      </div>
      {intention ? (
        <div>
          <div style={{ ...UI, fontSize: 12, fontWeight: 500, letterSpacing: "0.36em", textTransform: "uppercase", color: c.cap }}>Keep</div>
          <div style={{ fontFamily: "Fraunces, serif", fontSize: 28, fontWeight: 400, color: c.ink, marginTop: 8 }}>{intention}</div>
        </div>
      ) : null}
    </div>
  );
}

function DesktopMemory({ T }) {
  if (T < CUES.TheExtra) return null;
  const typed = typedKeep(T, TYPE_AT, KEEP_LINE, 5);
  const s = MOTION.stamp(T, CUES.TheExtra, 0.16, 1.04);
  return (
    <div style={{ ...ABS, left: 80, bottom: 128, zIndex: 28, ...s.style }}>
      <MemoryLines T={T} intention={typed} />
    </div>
  );
}

function ExtraPanel({ typed, typing, T }) {
  const night = cinematicAt(cycleU(T)).nightInk;
  const ink = night ? "#f4efe4" : PAPER_INK;
  const dim = night ? "rgba(244,239,228,0.62)" : INK_DIMMER;
  const pane = night
    ? {
        background: "rgba(18, 18, 18, 0.75)",
        border: "1px solid rgba(255,255,255,0.10)",
        boxShadow: "0 18px 48px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.12)",
      }
    : {
        background: "rgba(245, 245, 247, 0.72)",
        border: "1px solid rgba(255,255,255,0.60)",
        boxShadow: "0 18px 48px rgba(20,28,40,0.22), inset 0 1px 0 rgba(255,255,255,0.9)",
      };
  const fieldBg = night ? "rgba(255,255,255,0.12)" : "#fff";
  const btn = night
    ? { background: "rgba(255,255,255,0.12)", border: "1px solid rgba(255,255,255,0.14)", color: ink }
    : { background: "rgba(255,255,255,0.7)", border: "1px solid rgba(28,36,48,0.12)", color: PAPER_INK };
  return (
    <div
      style={{
        width: EXTRA_W,
        padding: 16,
        borderRadius: 16,
        boxSizing: "border-box",
        ...pane,
        backdropFilter: "blur(32px) saturate(1.8)",
        WebkitBackdropFilter: "blur(32px) saturate(1.8)",
        color: ink,
      }}
    >
      <div style={{ fontFamily: "Fraunces, serif", fontSize: 22, fontWeight: 400, lineHeight: "22px" }}>Keep</div>
      <div style={{ ...UI, fontSize: 10, fontWeight: 600, letterSpacing: "0.16em", textTransform: "uppercase", color: dim, marginTop: 16 }}>In 2h</div>
      <div style={{ fontFamily: "Fraunces, serif", fontSize: 16, marginTop: 4, color: ink }}>Intro Call</div>
      <div style={{ ...UI, fontSize: 12, fontWeight: 500, marginTop: 16, color: ink }}>Today’s Keep</div>
      <div
        style={{
          marginTop: 8,
          height: 28,
          borderRadius: 6,
          border: typing || typed ? "2px solid #0a84ff" : night ? "1px solid rgba(255,255,255,0.18)" : "1px solid rgba(28,36,48,0.22)",
          background: fieldBg,
          display: "flex",
          alignItems: "center",
          padding: "0 8px",
          fontFamily: "Inter, system-ui",
          fontSize: 13,
          color: ink,
          boxShadow: typing ? "0 0 0 3px rgba(10,132,255,0.22)" : "none",
        }}
      >
        {T < TYPE_AT && !typed ? <span style={{ color: dim }}>Today’s Keep</span> : typed}
        {typing ? (
          <span style={{ width: 1, height: 14, background: "#0a84ff", marginLeft: 1, opacity: Math.floor(T * 2.4) % 2 === 0 ? 1 : 0 }} />
        ) : null}
      </div>
      <div style={{ marginTop: 16, display: "flex", alignItems: "center", gap: 8 }}>
        {["Settings", "Lab"].map((b) => (
          <span key={b} style={{ fontSize: 12, padding: "4px 10px", borderRadius: 8, ...btn }}>{b}</span>
        ))}
        <span style={{ marginLeft: "auto", fontSize: 12, padding: "4px 10px", borderRadius: 8, ...btn }}>Quit Keep</span>
      </div>
    </div>
  );
}

function SceneExtra({ T }) {
  const typed = typedKeep(T, TYPE_AT, KEEP_LINE, 5);
  const typing = T >= TYPE_AT && T < EXTRA_OUT;
  const extraOut = MOTION.slide(T, EXTRA_OUT, 0.28, 0, 1);
  const lift = extraOut.on ? extraOut.v : 0;

  return (
    <div style={{ ...ABS, inset: 0, zIndex: 36 }}>
      <div style={{ ...ABS, left: EXTRA_LEFT, top: EXTRA_TOP, width: EXTRA_W, transform: `translate(${-12 * lift}px, ${-20 * lift}px) scale(${1 - 0.04 * lift})`, opacity: 1 - lift, transformOrigin: "100% 0%" }}>
        <SlideIn T={T} at={CUES.TheExtra} dur={0.16} from={[-10, -12]}>
          <Stamp T={T} at={CUES.TheExtra} dur={0.16} from={1.03}>
            <ExtraPanel typed={typed} typing={typing} T={T} />
          </Stamp>
        </SlideIn>
      </div>
    </div>
  );
}

function StoryCursor({ T }) {
  const typed = typedKeep(T, TYPE_AT, KEEP_LINE, 5);
  const caretX = FIELD_X + 8 + Math.max(0, typed.length) * 7.2;
  const path = [
    { t: 0, x: 640, y: 400 },
    { t: 1.55, x: KEEP_EXTRA_X, y: KEEP_EXTRA_Y, press: true },
    { t: CUES.TheExtra + 0.08, x: KEEP_EXTRA_X, y: KEEP_EXTRA_Y },
    { t: TYPE_AT - 0.1, x: FIELD_X + 40, y: FIELD_Y + 6, press: true },
    { t: TYPE_AT, x: FIELD_X + 12, y: FIELD_Y + 6 },
    { t: EXTRA_OUT - 0.12, x: caretX, y: FIELD_Y + 6 },
    { t: SIT_AT + 0.35, x: 980, y: 390 },
    { t: CUES.End - 0.08, x: 1020, y: 360 },
  ];
  const kind = T >= TYPE_AT && T < EXTRA_OUT ? "ibeam" : "arrow";
  const night = cinematicAt(cycleU(T)).nightInk;
  return <StoryGuide T={T} path={path} kind={kind} night={night} />;
}

export function Demo({ T }) {
  const extraOpen = T >= CUES.TheExtra && T < EXTRA_OUT + 0.12;
  const night = cinematicAt(cycleU(T)).nightInk;
  return (
    <div style={{ ...ABS, inset: 0, background: WASH, ...UI }}>
      <FilmSky T={T} />
      {T < CUES.TheExtra + 0.12 && <SceneDeadWall T={T} />}
      <MacMenuBar app={extraOpen ? "Keep" : "Finder"} phase={cinematicAt(cycleU(T)).phase} extraOpen={extraOpen} />
      <DesktopMemory T={T} />
      {extraOpen ? <SceneExtra T={T} /> : null}
      <MacDock night={night} keepOpen={extraOpen} />
      <StoryCursor T={T} />
    </div>
  );
}
