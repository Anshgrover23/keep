export const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const easeOutQuart = (p) => 1 - Math.pow(1 - p, 4);
const easeOutBack = (p) => {
  const c1 = 1.15;
  const c3 = c1 + 1;
  return 1 + c3 * Math.pow(p - 1, 3) + c1 * Math.pow(p - 1, 2);
};

export const SUN = "#f2c56b";
export const INK = "#1c2430";
export const INK_DIM = "#4a5868";
export const INK_DIMMER = "#6a7a8c";
export const EDGE = "rgba(28,36,48,0.14)";
export const WASH = "#eef3f8";
export const PAPER = "#f6f1e8";
export const PAPER_INK = "#1c2430";
export const SKY_NOON = "#4b7cbf";

export const DISP = {
  fontFamily: "Fraunces, serif",
  fontWeight: 400,
  letterSpacing: "-0.01em",
  lineHeight: 1.04,
  color: PAPER_INK,
};
export const UI = { fontFamily: "Inter, system-ui, sans-serif", color: PAPER_INK };
export const ABS = { position: "absolute" };

export const MOTION = {
  stamp(T, at, dur = 0.18, from = 1.14) {
    const p = clamp((T - at) / dur, 0, 1);
    const e = easeOutQuart(p);
    return { on: T >= at, p, e, style: { opacity: T < at ? 0 : 1, transform: `scale(${from - (from - 1) * e})` } };
  },
  slide(T, at, dur, from, to) {
    const p = clamp((T - at) / dur, 0, 1);
    return { on: T >= at, p, done: p >= 1, v: from + (to - from) * easeOutQuart(p) };
  },
  press(T, at, dur = 0.16) {
    if (T < at || T > at + dur) return 1;
    const p = (T - at) / dur;
    return p < 0.5 ? 1 - 0.1 * (p / 0.5) : 0.9 + 0.1 * ((p - 0.5) / 0.5);
  },
};

const settle = (T, at) => (T >= at ? Math.sin((T - at) * 26) * 1.5 * Math.exp(-(T - at) * 7) : 0);

export function Stamp({ T, at, dur = 0.18, from = 1.14, style, children, wobble = false }) {
  const s = MOTION.stamp(T, at, dur, from);
  if (!s.on) return null;
  const rot = wobble ? settle(T, at + dur) : 0;
  return (
    <div style={{ ...style, opacity: s.style.opacity, transform: `${style?.transform ?? ""} ${s.style.transform} rotate(${rot}deg)` }}>
      {children}
    </div>
  );
}

export function SlideIn({ T, at, dur = 0.4, from = [0, 40], style, children }) {
  const s = MOTION.slide(T, at, dur, 1, 0);
  if (!s.on) return null;
  return (
    <div style={{ ...style, transform: `${style?.transform ?? ""} translate(${from[0] * s.v}px, ${from[1] * s.v}px)` }}>
      {children}
    </div>
  );
}

export function WordStamp({ T, at, text, rate = 8, style, wordStyle }) {
  if (T < at) return null;
  const words = text.split(" ");
  const n = Math.min(words.length, 1 + Math.floor((T - at) * rate));
  return (
    <div style={{ display: "flex", flexWrap: "wrap", columnGap: "0.32em", rowGap: 0, justifyContent: "inherit", ...style }}>
      {words.slice(0, n).map((w, i) => {
        const s = MOTION.stamp(T, at + i / rate, 0.14, 1.08);
        return (
          <span key={i} style={{ display: "inline-block", transformOrigin: "0% 80%", ...s.style, ...wordStyle }}>
            {w}
          </span>
        );
      })}
    </div>
  );
}

const CURSOR_SCALE = 1.65;
const ARROW = { src: "../assets/macos/cursors/tahoe/default.svg", w: 17, h: 24, hx: 0.32, hy: 0.192 };
const IBEAM = { src: "../assets/macos/cursors/tahoe/text.svg", w: 14, h: 25, hx: 0.493, hy: 0.464 };

function MacPointer({ spec, x, y, pressScale = 1, opacity = 1, z = 70 }) {
  const w = spec.w * CURSOR_SCALE;
  const h = spec.h * CURSOR_SCALE;
  return (
    <img
      src={spec.src}
      alt=""
      draggable={false}
      style={{
        ...ABS,
        left: x - w * spec.hx,
        top: y - h * spec.hy,
        width: w,
        height: h,
        zIndex: z,
        opacity,
        transform: `scale(${pressScale})`,
        transformOrigin: `${spec.hx * 100}% ${spec.hy * 100}%`,
        pointerEvents: "none",
        display: "block",
      }}
    />
  );
}

export function Cursor({ x, y, pressScale = 1, opacity = 1 }) {
  return <MacPointer spec={ARROW} x={x} y={y} pressScale={pressScale} opacity={opacity} />;
}

export function IBeam({ x, y }) {
  return <MacPointer spec={IBEAM} x={x} y={y} />;
}

export function GrabCursor({ x, y, pressScale = 1 }) {
  return (
    <svg width="54" height="54" viewBox="0 0 32 32" style={{ ...ABS, left: x - 8, top: y - 8, zIndex: 71, transform: `scale(${pressScale})`, filter: "drop-shadow(1px 3px 4px rgba(0,0,0,0.5))" }}>
      <path
        d="M9 14 V8 a2 2 0 0 1 4 0 v4 M13 12 V7 a2 2 0 0 1 4 0 v6 M17 12 V8 a2 2 0 0 1 4 0 v5 M21 13.5 V10 a2 2 0 0 1 4 0 v7 c0 5-3.5 8-9 8 s-9-3-9-8 v-3.5 a2 2 0 0 1 4 0 V14"
        fill="#1c2430"
        stroke="#f6f1e8"
        strokeWidth="1.7"
        strokeLinejoin="round"
        strokeLinecap="round"
      />
    </svg>
  );
}

export function cursorAt(T, path) {
  if (!path.length || T < path[0].t) return null;
  let i = 0;
  while (i < path.length - 1 && T >= path[i + 1].t) i++;
  const a = path[i];
  const b = path[Math.min(i + 1, path.length - 1)];
  const span = Math.max(0.0001, b.t - a.t);
  const p = clamp((T - a.t) / span, 0, 1);
  const e = easeOutQuart(p);
  return { x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e };
}

export function PathCursor({ T, path, until, ibeam = false }) {
  if (T < path[0].t) return null;
  if (until != null && T >= until) return null;
  const pos = cursorAt(T, path);
  if (!pos) return null;
  let press = 1;
  for (const w of path) if (w.press) press = Math.min(press, MOTION.press(T, w.t));
  if (ibeam) return <IBeam x={pos.x} y={pos.y} />;
  return <Cursor x={pos.x} y={pos.y} pressScale={press * 1.55} />;
}

export function StoryGuide({ T, path, kind = "arrow", night = false }) {
  const pos = cursorAt(T, path);
  if (!pos) return null;
  let press = 1;
  for (const w of path) if (w.press) press = Math.min(press, MOTION.press(T, w.t, 0.14));
  return (
    <div style={{ ...ABS, inset: 0, zIndex: 72, pointerEvents: "none" }}>
      {path.map((w, i) => {
        if (!w.press) return null;
        const age = T - w.t;
        if (age < 0 || age > 0.32) return null;
        const k = age / 0.32;
        return (
          <div
            key={i}
            style={{
              ...ABS,
              left: w.x - 14,
              top: w.y - 14,
              width: 28,
              height: 28,
              borderRadius: 99,
              background: night ? "rgba(255,255,255,0.22)" : "rgba(255,255,255,0.38)",
              boxShadow: `0 0 0 1.5px ${night ? "rgba(255,255,255,0.45)" : "rgba(0,0,0,0.18)"}`,
              transform: `scale(${1 + k * 1.35})`,
              opacity: 1 - k,
            }}
          />
        );
      })}
      {kind === "ibeam" ? <IBeam x={pos.x} y={pos.y} /> : <Cursor x={pos.x} y={pos.y} pressScale={press} />}
    </div>
  );
}

export function Badge({ T, at, until = 1e9, x, y, children, tone = "sun", size = 13, rot = -1.5, z = 56 }) {
  const tones = {
    sun: { background: SUN, color: "#141210", border: "none" },
    quiet: { background: "rgba(255,255,255,0.88)", color: PAPER_INK, border: `1px solid ${EDGE}` },
  };
  const s = MOTION.stamp(T, at, 0.16, 1.35);
  if (!s.on || T >= until) return null;
  return (
    <div style={{ ...ABS, left: x, top: y, ...UI, fontWeight: 600, fontSize: size, padding: "6px 12px", borderRadius: 8, zIndex: z, ...tones[tone], transform: `rotate(${rot + settle(T, at + 0.16)}deg) ${s.style.transform}`, opacity: s.style.opacity, boxShadow: "0 2px 12px rgba(0,0,0,0.45)" }}>
      {children}
    </div>
  );
}

export function BrandWipe({ T, at, dur = 0.72 }) {
  if (T < at || T > at + dur) return null;
  const x = MOTION.slide(T, at, dur, 1500, -3600).v;
  const rows = [0, 1, 2, 3, 4];
  return (
    <div style={{ ...ABS, top: -60, left: 0, height: 840, width: 3400, zIndex: 90, transform: `rotate(-1.2deg) translateX(${x}px)`, background: PAPER, borderLeft: `6px solid ${SUN}`, borderRight: `6px solid ${SUN}`, overflow: "hidden" }}>
      {rows.map((r) => (
        <div key={r} style={{ ...DISP, color: "rgba(242,197,107,0.55)", fontSize: 64, fontStyle: "italic", whiteSpace: "nowrap", marginTop: r ? 76 : 60, marginLeft: -(r * 220) }}>
          {"Keep · ".repeat(18)}
        </div>
      ))}
    </div>
  );
}

export function CaptionStamp({ T, items, text, y = 500 }) {
  if (typeof window !== "undefined" && window.__NO_CAPTIONS) return null;
  const fromItems = items?.reduce((acc, it) => (T + 1e-3 >= it.at && T < it.until ? it : acc), null);
  const resolved = text || fromItems?.text;
  if (!resolved) return null;
  return (
    <div style={{ ...ABS, left: 32, right: 32, top: fromItems?.y ?? y, display: "flex", justifyContent: "center", zIndex: 70 }}>
      <div style={{ background: "rgba(255,255,255,0.92)", border: `1px solid ${EDGE}`, borderRadius: 18, padding: "12px 24px", boxShadow: "0 8px 24px rgba(28,36,48,0.12)", maxWidth: 1180 }}>
        <div style={{ ...DISP, fontSize: 32, lineHeight: 1.15, textAlign: "center", color: PAPER_INK }}>{resolved}</div>
      </div>
    </div>
  );
}

export function SkyWash({ children, blur = 28, brightness = 1.08 }) {
  return (
    <>
      <div style={{ ...ABS, inset: -30, filter: `blur(${blur}px) brightness(${brightness}) saturate(1.08)` }}>
        {children}
      </div>
      <div style={{ ...ABS, inset: 0, background: "radial-gradient(ellipse 85% 75% at 50% 42%, rgba(255,255,255,0.18), rgba(238,243,248,0.55))" }} />
    </>
  );
}
