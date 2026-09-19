import { useEffect, useRef, useState } from "react";
import {
  ABS, UI, INK_DIMMER, WASH,
  MOTION, clamp, Stamp, SlideIn, WordStamp, StoryGuide, PAPER_INK,
} from "./kit.jsx";
import { KeepSky } from "./KeepSky.jsx";
import { cinematicAt } from "./sky.js";
import { MacMenuBar, MacDock, MENU_H, KEEP_EXTRA_X, KEEP_EXTRA_Y } from "./macChrome.jsx";

const SCENES = [
  { name: "TheMark", secs: 5.6 },
  { name: "TheExtra", secs: 5.0 },
  { name: "TheDay", secs: 4.4 },
];
export const CUES = {};
{
  let acc = 0;
  for (const s of SCENES) { CUES[s.name] = acc; acc += s.secs; }
  CUES.End = acc;
}

const CLICK_AT = 0.72;
const BURST_AT = 0.72;
const COLLAPSE_AT = 1.96;
const COLLAPSE_DUR = 0.7;
const TITLE_AT = COLLAPSE_AT + COLLAPSE_DUR + 0.2;
const TAG_AT = TITLE_AT + 0.32;
const TITLE_FOLD_AT = TAG_AT + 0.48;
const TITLE_FOLD_DUR = 0.38;
const K_FLY_AT = TITLE_FOLD_AT + TITLE_FOLD_DUR + 0.08;
const K_FLY_DUR = 1.28;
const K_LAND = K_FLY_AT + K_FLY_DUR;
const CHROME_AT = K_FLY_AT + 0.1;
const OVERLAY_AT = K_LAND;
const KEEP_LINE = "Ship the demo";
const EXTRA_CLICK_AT = K_LAND + 0.48;
const EXTRA_IN = EXTRA_CLICK_AT + 0.08;
const TYPE_AT = EXTRA_IN + 0.42;
const EXTRA_OUT = CUES.TheExtra + 4.2;
const SIT_AT = EXTRA_OUT;

const EXTRA_W = 320;
const EXTRA_RIGHT = 24;
const EXTRA_TOP = MENU_H + 6;
const EXTRA_LEFT = 1280 - EXTRA_RIGHT - EXTRA_W;
const FIELD_X = EXTRA_LEFT + 16;
const FIELD_Y = EXTRA_TOP + 16 + 22 + 16 + 12 + 4 + 20 + 16 + 16 + 8;

const STORY_CAPTIONS = [
  { at: TYPE_AT, until: SIT_AT, text: "You type today’s line" },
  { at: SIT_AT, until: SIT_AT + 1.7, text: "It sits on the desktop" },
  { at: SIT_AT + 1.7, until: CUES.End, text: "The day keeps moving" },
];

function cycleU(T) {
  if (T < SIT_AT) return 0.22;
  const p = clamp((T - SIT_AT) / (CUES.End - SIT_AT), 0, 1);
  return 0.22 + 0.78 * (p * p);
}

export function captionAt(T) {
  const hit = STORY_CAPTIONS.reduce((acc, it) => (T + 1e-3 >= it.at && T < it.until ? it : acc), null);
  return hit?.text ?? "";
}

export const CAPTIONS = STORY_CAPTIONS;

function FilmSky({ T }) {
  return <KeepSky cycle={cycleU(T)} weather="clear" clock={T * 9} />;
}

function typedKeep(T, at, text, rate = 5) {
  if (T < at) return "";
  return text.slice(0, Math.min(text.length, 1 + Math.floor((T - at) * rate)));
}

function easeInOutCubic(p) {
  return p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2;
}

function easeInOutQuart(p) {
  return p < 0.5 ? 8 * p * p * p * p : 1 - Math.pow(-2 * p + 2, 4) / 2;
}

function easeOutBack(p) {
  const c1 = 1.22;
  const c3 = c1 + 1;
  return 1 + c3 * Math.pow(p - 1, 3) + c1 * Math.pow(p - 1, 2);
}

function chipHeft(dx, dy) {
  return 0.68 + 0.5 * clamp((Math.hypot(dx, dy) - 90) / 230, 0, 1);
}

function burstSeat(T, delay, dx, dy, rot0) {
  if (T < BURST_AT) return { x: 640, y: 360, rot: 0, scale: 0.02, hide: true };
  const out = clamp((T - (BURST_AT + delay)) / 0.5, 0, 1);
  const e = easeOutBack(out);
  const wig = T < COLLAPSE_AT ? Math.sin((T - BURST_AT) * 8.5 + delay * 16) * (1 - out) * 3 : 0;
  return {
    x: 640 + dx * e,
    y: 360 + dy * e,
    rot: rot0 * out + wig,
    scale: (0.18 + 0.82 * out) * chipHeft(dx, dy),
    hide: false,
  };
}

function placeChip(T, c) {
  const seated = burstSeat(T, c.delay, c.dx, c.dy, c.rot);
  if (seated.hide) return seated;
  const start = COLLAPSE_AT + c.go;
  if (T < start) return seated;
  const p = clamp((T - start) / c.dur, 0, 1);
  const e = easeInOutCubic(p);
  const suck = e * e * (1.12 - 0.12 * e);
  const x0 = 640 + c.dx;
  const y0 = 360 + c.dy;
  return {
    x: x0 + (640 - x0) * suck,
    y: y0 + (360 - y0) * suck,
    rot: seated.rot * (1 - suck),
    scale: seated.scale * (1 - 0.96 * suck),
    hide: p >= 1,
  };
}

function viewFrame(T) {
  const p = easeInOutCubic(clamp((T - K_FLY_AT) / 0.48, 0, 1));
  const x = 160 * (1 - p);
  const y = 90 * (1 - p);
  const w = 960 + 320 * p;
  const h = 540 + 180 * p;
  return { p, x, y, w, h, r: 28 * (1 - p) };
}

const SPARKS = [
  { dx: -78, dy: -96, delay: 0.02, sz: 16 },
  { dx: 92, dy: -78, delay: 0.05, sz: 12 },
  { dx: -118, dy: 36, delay: 0.08, sz: 14 },
  { dx: 108, dy: 48, delay: 0.04, sz: 10 },
  { dx: 28, dy: -128, delay: 0.1, sz: 9 },
  { dx: -36, dy: 118, delay: 0.07, sz: 13 },
  { dx: 140, dy: -20, delay: 0.03, sz: 8 },
  { dx: -150, dy: -28, delay: 0.11, sz: 11 },
];

function Sparkle({ x, y, s, o, rot }) {
  return (
    <svg
      width={s}
      height={s}
      viewBox="0 0 24 24"
      style={{
        ...ABS,
        left: x,
        top: y,
        opacity: o,
        transform: `translate(-50%, -50%) rotate(${rot}deg)`,
        pointerEvents: "none",
        zIndex: 6,
        filter: "drop-shadow(0 0 6px rgba(255,255,255,0.9))",
      }}
    >
      <path fill="#fff" d="M12 1.2l1.35 8.05L21.5 12l-8.15 2.75L12 22.8l-1.35-8.05L2.5 12l8.15-2.75Z" />
    </svg>
  );
}

const CHIP_META = [
  { delay: 0.00, kind: "event", go: 0.04, dur: 0.76 },
  { delay: 0.04, kind: "weather", go: 0.05, dur: 0.76 },
  { delay: 0.08, kind: "line", go: 0.06, dur: 0.74 },
  { delay: 0.06, kind: "dock", src: "../assets/macos/icons/calendar.png", go: 0.08, dur: 0.72 },
  { delay: 0.10, kind: "dock", src: "../assets/macos/icons/reminders.png", go: 0.09, dur: 0.7 },
  { delay: 0.07, kind: "dock", src: "../assets/macos/icons/maps.png", go: 0.08, dur: 0.72 },
  { delay: 0.05, kind: "coin", src: "../assets/macos/symbols/sun-max-fill.png", go: 0.02, dur: 0.7 },
  { delay: 0.06, kind: "coin", src: "../assets/macos/symbols/cloud-sun-fill.png", go: 0.03, dur: 0.7 },
  { delay: 0.09, kind: "coin", src: "../assets/macos/symbols/moon-stars-fill.png", go: 0.01, dur: 0.68 },
  { delay: 0.03, kind: "location", go: 0.05, dur: 0.74 },
  { delay: 0.05, kind: "sky", src: "../assets/sky/hours/h12.png", go: 0.04, dur: 0.74 },
  { delay: 0.07, kind: "sky", src: "../assets/sky/hours/h17.png", go: 0.04, dur: 0.74 },
  { delay: 0.08, kind: "dock", src: "../assets/macos/icons/photos.png", go: 0.08, dur: 0.72 },
  { delay: 0.09, kind: "dock", src: "../assets/macos/icons/mail.png", go: 0.08, dur: 0.72 },
  { delay: 0.04, kind: "coin", src: "../assets/macos/symbols/cloud-rain-fill.png", go: 0.02, dur: 0.7 },
];

export const BURST_LAYOUT_NAMES = ["Ring", "Wings", "Canopy", "Split", "Slash"];

const CHIP_POSES = [
  [
    { dx: -360, dy: -110, rot: -7 },
    { dx: 370, dy: -130, rot: 6 },
    { dx: 390, dy: 95, rot: -5 },
    { dx: -350, dy: 145, rot: 8 },
    { dx: 430, dy: 195, rot: -6 },
    { dx: -230, dy: 40, rot: 7 },
    { dx: 150, dy: -175, rot: 9 },
    { dx: -155, dy: -168, rot: -10 },
    { dx: 175, dy: 185, rot: 8 },
    { dx: -90, dy: 200, rot: 4 },
    { dx: -430, dy: 18, rot: -8 },
    { dx: 445, dy: 22, rot: 7 },
    { dx: -90, dy: 40, rot: 4 },
    { dx: 90, dy: 40, rot: -4 },
    { dx: 0, dy: -200, rot: 6 },
  ],
  [
    { dx: -450, dy: -55, rot: -5 },
    { dx: 455, dy: -60, rot: 5 },
    { dx: 448, dy: 88, rot: -4 },
    { dx: -430, dy: 125, rot: 6 },
    { dx: 435, dy: 170, rot: -5 },
    { dx: -300, dy: 8, rot: 5 },
    { dx: 210, dy: -145, rot: 8 },
    { dx: -215, dy: -148, rot: -8 },
    { dx: 40, dy: 205, rot: 4 },
    { dx: -40, dy: 205, rot: -3 },
    { dx: -510, dy: 12, rot: -6 },
    { dx: 515, dy: 10, rot: 6 },
    { dx: -120, dy: 30, rot: 4 },
    { dx: 120, dy: 30, rot: -4 },
    { dx: 0, dy: -160, rot: 5 },
  ],
  [
    { dx: 395, dy: 55, rot: -5 },
    { dx: -428, dy: 19, rot: 5 },
    { dx: 341, dy: 222, rot: 4 },
    { dx: -217, dy: -216, rot: -7 },
    { dx: 206, dy: -203, rot: 7 },
    { dx: -5, dy: -296, rot: 2 },
    { dx: 118, dy: 284, rot: -5 },
    { dx: -266, dy: 270, rot: 6 },
    { dx: -6, dy: 298, rot: 3 },
    { dx: -410, dy: 169, rot: -4 },
    { dx: 352, dy: -100, rot: -3 },
    { dx: -387, dy: -129, rot: 3 },
    { dx: -114, dy: -264, rot: -4 },
    { dx: 104, dy: -264, rot: 4 },
    { dx: -135, dy: 292, rot: 7 },
  ],
  [
    { dx: -390, dy: -140, rot: -6 },
    { dx: 395, dy: -145, rot: 6 },
    { dx: -385, dy: 165, rot: -4 },
    { dx: -230, dy: 170, rot: 8 },
    { dx: 400, dy: 175, rot: -6 },
    { dx: -240, dy: -15, rot: 5 },
    { dx: 165, dy: -168, rot: 9 },
    { dx: -165, dy: -170, rot: -9 },
    { dx: 210, dy: 185, rot: 7 },
    { dx: -385, dy: 20, rot: 3 },
    { dx: 430, dy: 15, rot: 6 },
    { dx: 250, dy: 40, rot: -5 },
    { dx: -100, dy: 40, rot: 4 },
    { dx: 100, dy: -20, rot: -4 },
    { dx: 0, dy: -190, rot: 6 },
  ],
  [
    { dx: -410, dy: -155, rot: -8 },
    { dx: 405, dy: -150, rot: 7 },
    { dx: 390, dy: 145, rot: -5 },
    { dx: -395, dy: 160, rot: 8 },
    { dx: 255, dy: 195, rot: -6 },
    { dx: -255, dy: 25, rot: 6 },
    { dx: 125, dy: -175, rot: 10 },
    { dx: -250, dy: -165, rot: -10 },
    { dx: 45, dy: 200, rot: 5 },
    { dx: -70, dy: 195, rot: 3 },
    { dx: -470, dy: -25, rot: -7 },
    { dx: 470, dy: 30, rot: 7 },
    { dx: -140, dy: 50, rot: 4 },
    { dx: 140, dy: 55, rot: -4 },
    { dx: 0, dy: -188, rot: 6 },
  ],
];

const BURST_VARIANT = (() => {
  try {
    const raw = new URLSearchParams(location.search).get("burst");
    if (raw == null || raw === "") return 2;
    const n = Number(raw);
    return Number.isFinite(n) ? Math.max(0, Math.min(CHIP_POSES.length - 1, n)) : 2;
  } catch {
    return 2;
  }
})();

const POSE_KEY = `keep-burst-layout-${BURST_VARIANT}-v4`;

function burstEditOn() {
  try {
    if (window.__NO_BURST_EDIT) return false;
    if (new URLSearchParams(location.search).get("edit") === "0") return false;
    return true;
  } catch {
    return false;
  }
}

function defaultPoses() {
  return CHIP_POSES[BURST_VARIANT].map((p) => ({ ...p }));
}

function readSavedPoses() {
  try {
    const parsed = JSON.parse(localStorage.getItem(POSE_KEY) || "null");
    if (!Array.isArray(parsed) || parsed.length !== CHIP_META.length) return defaultPoses();
    return parsed.map((p, i) => ({
      dx: Number(p.dx) || 0,
      dy: Number(p.dy) || 0,
      rot: Number.isFinite(Number(p.rot)) ? Number(p.rot) : CHIP_POSES[BURST_VARIANT][i].rot,
    }));
  } catch {
    return defaultPoses();
  }
}

function persistPoses(poses) {
  try {
    localStorage.setItem(POSE_KEY, JSON.stringify(poses.map(({ dx, dy, rot }) => ({
      dx: Math.round(dx),
      dy: Math.round(dy),
      rot,
    }))));
  } catch {
    /* ignore */
  }
}

const INK = PAPER_INK;
const capStyle = { ...UI, fontSize: 11, fontWeight: 600, letterSpacing: "0.22em", textTransform: "uppercase", color: "rgba(28,36,48,0.55)" };
const GLASS = {
  background: "rgba(236, 244, 252, 0.78)",
  border: "1px solid rgba(255,255,255,0.92)",
  boxShadow: "0 18px 40px rgba(80,120,160,0.18), inset 0 1px 0 rgba(255,255,255,0.95)",
  backdropFilter: "blur(22px) saturate(1.35)",
  WebkitBackdropFilter: "blur(22px) saturate(1.35)",
};

function BurstPane({ w, h, r = 24, pad = 16, children }) {
  return (
    <div
      style={{
        width: w,
        minHeight: h,
        borderRadius: r,
        padding: pad,
        boxSizing: "border-box",
        ...GLASS,
        color: INK,
      }}
    >
      {children}
    </div>
  );
}

function BurstEventCard() {
  return (
    <BurstPane w={304} r={28}>
      <div style={capStyle}>In 2h</div>
      <div style={{ fontFamily: "Fraunces, serif", fontSize: 34, color: INK, marginTop: 6 }}>Intro Call</div>
    </BurstPane>
  );
}

function BurstWeatherCard() {
  return (
    <BurstPane w={228}>
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <img src="../assets/macos/symbols/sun-max-fill.png" width={36} height={36} alt="" style={{ display: "block", filter: "brightness(0) opacity(0.72)" }} />
        <div>
          <div style={capStyle}>Clear</div>
          <div style={{ fontFamily: "Fraunces, serif", fontSize: 36, color: INK, lineHeight: 1 }}>72°</div>
        </div>
      </div>
    </BurstPane>
  );
}

function BurstLineCard() {
  return (
    <BurstPane w={280} r={28}>
      <div style={capStyle}>Keep</div>
      <div style={{ fontFamily: "Fraunces, serif", fontSize: 26, color: INK, marginTop: 6 }}>Ship the demo</div>
    </BurstPane>
  );
}

function BurstLocationCard() {
  return (
    <BurstPane w={244} r={26} pad={16}>
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <img src="../assets/icons/location.png" width={32} height={32} alt="" style={{ display: "block" }} />
        <div>
          <div style={capStyle}>Location</div>
          <div style={{ fontFamily: "Fraunces, serif", fontSize: 22, color: INK, marginTop: 2 }}>Local weather</div>
        </div>
      </div>
    </BurstPane>
  );
}

function BurstSkyChip({ src }) {
  return (
    <div
      style={{
        width: 176,
        height: 108,
        borderRadius: 22,
        overflow: "hidden",
        border: "1px solid rgba(255,255,255,0.85)",
        boxShadow: "0 16px 36px rgba(80,120,160,0.2)",
      }}
    >
      <img src={src} width={176} height={108} alt="" style={{ display: "block", objectFit: "cover" }} />
    </div>
  );
}

function AppGlyph({ src, size, shadow }) {
  const r = Math.round(size * 0.223);
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: r,
        overflow: "hidden",
        boxShadow: shadow,
        flexShrink: 0,
      }}
    >
      <img
        src={src}
        width={size}
        height={size}
        alt=""
        style={{
          display: "block",
          width: size,
          height: size,
          transform: "scale(1.22)",
          transformOrigin: "center center",
        }}
      />
    </div>
  );
}

function BurstCoin({ src }) {
  return (
    <div
      style={{
        width: 64,
        height: 64,
        borderRadius: 32,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "#eef3f9",
        border: "1px solid rgba(255,255,255,0.95)",
        boxShadow: "0 12px 28px rgba(80,120,160,0.16)",
      }}
    >
      <img src={src} width={34} height={34} alt="" style={{ display: "block", filter: "brightness(0) opacity(0.72)" }} />
    </div>
  );
}

function BurstDockIcon({ src }) {
  return <AppGlyph src={src} size={88} shadow="0 14px 28px rgba(80,120,160,0.22)" />;
}

function BurstChipBody(c) {
  if (c.kind === "event") return <BurstEventCard />;
  if (c.kind === "weather") return <BurstWeatherCard />;
  if (c.kind === "line") return <BurstLineCard />;
  if (c.kind === "location") return <BurstLocationCard />;
  if (c.kind === "coin") return <BurstCoin src={c.src} />;
  if (c.kind === "dock") return <BurstDockIcon src={c.src} />;
  if (c.kind === "sky") return <BurstSkyChip src={c.src} />;
  return null;
}

function BurstRays({ T }) {
  if (T >= CUES.TheExtra) return null;
  const n = 8;
  const sweep = 360 / n;
  const spin = T < BURST_AT ? T * 16 : 12 + (T - BURST_AT) * 78;
  const pop = T < BURST_AT ? 0.92 : 0.92 + 0.2 * clamp((T - BURST_AT) / 0.28, 0, 1);
  const liveAmp = T < BURST_AT ? 0 : 3.2;
  const nodes = [];
  for (let i = 0; i < n; i++) {
    const go = ((i * 3) % n) * 0.05;
    const dur = 0.48 + (i % 4) * 0.09;
    const retract = easeInOutCubic(clamp((T - COLLAPSE_AT - go) / dur, 0, 1));
    if (retract >= 0.995) continue;
    const wig = Math.sin(T * (6.4 + (i % 5) * 0.85) + i * 1.55) * liveAmp * (1 - retract);
    const mask = `conic-gradient(from ${i * sweep}deg, #000 0deg ${sweep}deg, transparent ${sweep}deg 360deg)`;
    nodes.push(
      <div
        key={i}
        style={{
          ...ABS,
          inset: 0,
          transformOrigin: "50% 50%",
          transform: `rotate(${wig}deg) scale(${Math.max(0.02, pop * (1 - retract))})`,
          background: `repeating-conic-gradient(from ${spin}deg, rgba(244,197,106,0.42) 0deg 7deg, rgba(255,255,255,0.1) 7deg 14deg)`,
          WebkitMaskImage: mask,
          maskImage: mask,
        }}
      />
    );
  }
  if (!nodes.length) return null;
  return (
    <div style={{ ...ABS, inset: "-48%", pointerEvents: "none", zIndex: 1 }}>
      {nodes}
    </div>
  );
}

function SceneKeepMark({ T }) {
  const edit = burstEditOn();
  const [poses, setPoses] = useState(readSavedPoses);
  const [dragging, setDragging] = useState(-1);
  const posesRef = useRef(poses);
  const dragRef = useRef(null);
  posesRef.current = poses;
  const arranging = edit && T >= BURST_AT + 0.55 && T < COLLAPSE_AT;

  useEffect(() => {
    if (!edit) return undefined;
    const reset = () => {
      const next = defaultPoses();
      setPoses(next);
      persistPoses(next);
    };
    const copy = async () => {
      const text = posesRef.current.map((p) => `    { dx: ${Math.round(p.dx)}, dy: ${Math.round(p.dy)}, rot: ${p.rot} },`).join("\n");
      try {
        await navigator.clipboard.writeText(text);
      } catch {
        console.log(text);
      }
    };
    const onReset = () => reset();
    const onCopy = () => { copy(); };
    window.addEventListener("keep-burst-reset", onReset);
    window.addEventListener("keep-burst-copy", onCopy);
    const resetBtn = document.getElementById("burst-reset");
    const copyBtn = document.getElementById("burst-copy");
    resetBtn?.addEventListener("click", onReset);
    copyBtn?.addEventListener("click", onCopy);
    return () => {
      window.removeEventListener("keep-burst-reset", onReset);
      window.removeEventListener("keep-burst-copy", onCopy);
      resetBtn?.removeEventListener("click", onReset);
      copyBtn?.removeEventListener("click", onCopy);
    };
  }, [edit]);

  useEffect(() => {
    if (!edit) return undefined;
    const move = (e) => {
      const d = dragRef.current;
      if (!d) return;
      const stage = document.getElementById("stage")?.getBoundingClientRect();
      if (!stage || stage.width < 1) return;
      const dx = clamp(d.dx0 + (e.clientX - d.px) * (1280 / stage.width), -640, 640);
      const dy = clamp(d.dy0 + (e.clientY - d.py) * (720 / stage.height), -380, 380);
      setPoses((prev) => prev.map((p, j) => (j === d.i ? { ...p, dx, dy } : p)));
    };
    const up = () => {
      if (!dragRef.current) return;
      dragRef.current = null;
      setDragging(-1);
      persistPoses(posesRef.current);
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    return () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
    };
  }, [edit]);

  if (T >= CUES.TheExtra) return null;

  const clickPress = MOTION.press(T, CLICK_AT, 0.18);
  const kp = clamp((T - K_FLY_AT) / K_FLY_DUR, 0, 1);
  const ke = easeInOutQuart(kp);
  const k0x = 640;
  const k0y = 360;
  const kcx = (k0x + KEEP_EXTRA_X) / 2 - 12;
  const kcy = 118;
  const kx = T < K_FLY_AT ? k0x : (1 - ke) * (1 - ke) * k0x + 2 * (1 - ke) * ke * kcx + ke * ke * KEEP_EXTRA_X;
  const ky = T < K_FLY_AT ? k0y : (1 - ke) * (1 - ke) * k0y + 2 * (1 - ke) * ke * kcy + ke * ke * KEEP_EXTRA_Y;
  const kScale = clickPress * (1 + (22 / 120 - 1) * ke);
  const kGone = kp >= 1;
  const foldP = clamp((T - TITLE_FOLD_AT) / TITLE_FOLD_DUR, 0, 1);
  const foldE = easeInOutCubic(foldP);
  const titleOn = T >= TITLE_AT && foldE < 1;
  const chips = CHIP_META.map((m, i) => ({ ...m, ...poses[i] }));

  return (
    <div style={{ ...ABS, inset: 0, overflow: "visible", pointerEvents: arranging ? "auto" : "none", zIndex: 52 }}>
      {SPARKS.map((s, i) => {
        if (T < BURST_AT) return null;
        const dummy = { delay: s.delay, dx: s.dx, dy: s.dy, rot: 18, go: 0.02, dur: 0.55 };
        const b = placeChip(T, dummy);
        if (b.hide) return null;
        const twinkle = 0.55 + 0.45 * Math.abs(Math.sin((T - BURST_AT) * 10 + i));
        return <Sparkle key={`sp${i}`} x={b.x} y={b.y} s={s.sz * (0.7 + b.scale)} o={twinkle * (b.scale > 0.08 ? 1 : b.scale / 0.08)} rot={T * 40 + i * 40} />;
      })}
      {chips.map((c, i) => {
        const b = placeChip(T, c);
        if (b.hide) return null;
        return (
          <div
            key={i}
            onPointerDown={arranging ? (e) => {
              e.preventDefault();
              e.stopPropagation();
              dragRef.current = { i, px: e.clientX, py: e.clientY, dx0: c.dx, dy0: c.dy };
              setDragging(i);
            } : undefined}
            style={{
              ...ABS,
              left: b.x,
              top: b.y,
              zIndex: dragging === i ? 24 : 2,
              transform: `translate(-50%, -50%) rotate(${b.rot}deg) scale(${b.scale})`,
              cursor: arranging ? (dragging === i ? "grabbing" : "grab") : "default",
              touchAction: "none",
              userSelect: "none",
              pointerEvents: arranging ? "auto" : "none",
            }}
          >
            <BurstChipBody {...c} />
          </div>
        );
      })}
      {kGone ? null : (
        <div
          style={{
            ...ABS,
            left: kx,
            top: ky,
            zIndex: 8,
            width: 120,
            height: 120,
            transform: `translate(-50%, -50%) scale(${kScale})`,
            pointerEvents: "none",
          }}
        >
          <AppGlyph src="../assets/macos/icons/keep.png" size={120} shadow="0 18px 40px rgba(80,120,160,0.28)" />
        </div>
      )}
      {titleOn ? (
        <div
          style={{
            ...ABS,
            left: 640,
            top: 438 + (360 - 438) * foldE,
            zIndex: 8,
            transform: `translate(-50%, 0) scale(${1 - 0.9 * foldE})`,
            opacity: 1 - foldE,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            transformOrigin: "50% 0%",
            pointerEvents: "none",
          }}
        >
          <SlideIn T={T} at={TITLE_AT} dur={0.2} from={[0, 18]}>
            <div style={{ fontFamily: "Fraunces, serif", fontSize: 56, fontWeight: 400, color: PAPER_INK, letterSpacing: "-0.02em", lineHeight: 1, textShadow: "0 1px 0 rgba(255,255,255,0.55), 0 10px 28px rgba(20,24,18,0.28)" }}>Keep</div>
          </SlideIn>
          <WordStamp
            T={T}
            at={TAG_AT}
            text="Today on Desktop"
            rate={7}
            style={{ ...UI, fontSize: 15, fontWeight: 500, letterSpacing: "0.08em", color: INK_DIMMER, marginTop: 12 }}
          />
        </div>
      ) : null}
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
  if (typeof window !== "undefined" && window.__NO_DESKTOP_LINES) return null;
  if (T < OVERLAY_AT) return null;
  const typed = typedKeep(T, TYPE_AT, KEEP_LINE, 5);
  const s = MOTION.stamp(T, OVERLAY_AT, 0.22, 1.04);
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
        <SlideIn T={T} at={EXTRA_IN} dur={0.16} from={[-10, -12]}>
          <Stamp T={T} at={EXTRA_IN} dur={0.16} from={1.03}>
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
  const night = cinematicAt(cycleU(T)).nightInk;
  if (T < K_LAND) {
    if (T > 1.38) return null;
    const path = [
      { t: 0.04, x: 1080, y: 590 },
      { t: CLICK_AT - 0.02, x: 640, y: 360, press: true },
      { t: CLICK_AT + 0.2, x: 708, y: 418 },
      { t: 1.32, x: 1220, y: 740 },
    ];
    return <StoryGuide T={T} path={path} kind="arrow" night={false} />;
  }
  const path = [
    { t: K_LAND + 0.16, x: 1040, y: 150 },
    { t: EXTRA_CLICK_AT, x: KEEP_EXTRA_X, y: KEEP_EXTRA_Y, press: true },
    { t: EXTRA_IN + 0.12, x: KEEP_EXTRA_X, y: KEEP_EXTRA_Y },
    { t: TYPE_AT - 0.08, x: FIELD_X + 40, y: FIELD_Y + 6, press: true },
    { t: TYPE_AT, x: FIELD_X + 12, y: FIELD_Y + 6 },
    { t: EXTRA_OUT - 0.12, x: caretX, y: FIELD_Y + 6 },
    { t: SIT_AT + 0.35, x: 980, y: 390 },
    { t: CUES.End - 0.08, x: 1020, y: 360 },
  ];
  const kind = T >= TYPE_AT && T < EXTRA_OUT ? "ibeam" : "arrow";
  return <StoryGuide T={T} path={path} kind={kind} night={night} />;
}

export function Demo({ T }) {
  const extraOpen = T >= EXTRA_IN && T < EXTRA_OUT + 0.12;
  const keepPressed = T >= EXTRA_CLICK_AT && T < EXTRA_OUT;
  const chromeOn = T >= CHROME_AT;
  const night = cinematicAt(cycleU(T)).nightInk;
  const chrome = MOTION.stamp(T, CHROME_AT, 0.28, 1.02);
  const fr = viewFrame(T);
  return (
    <div style={{ ...ABS, inset: 0, background: "#ffffff", ...UI }}>
      <div
        style={{
          ...ABS,
          left: fr.x,
          top: fr.y,
          width: fr.w,
          height: fr.h,
          overflow: "hidden",
          borderRadius: fr.r,
          boxShadow: fr.p < 1 ? "0 28px 80px rgba(30,40,60,0.12), 0 0 0 1px rgba(20,30,50,0.06)" : "none",
        }}
      >
        <div style={{ ...ABS, left: -fr.x, top: -fr.y, width: 1280, height: 720 }}>
          <FilmSky T={T} />
          <BurstRays T={T} />
          {chromeOn ? (
            <div style={{ ...ABS, inset: 0, zIndex: 30, pointerEvents: "none", ...chrome.style }}>
              <MacMenuBar app={extraOpen ? "Keep" : "Finder"} phase={cinematicAt(cycleU(T)).phase} extraOpen={keepPressed} keepMark={T >= K_LAND} />
            </div>
          ) : null}
          <DesktopMemory T={T} />
          {extraOpen ? <SceneExtra T={T} /> : null}
          {chromeOn ? (
            <div style={{ ...ABS, inset: 0, zIndex: 40, pointerEvents: "none", ...chrome.style }}>
              <MacDock night={night} keepOpen={extraOpen} />
            </div>
          ) : null}
        </div>
      </div>
      <SceneKeepMark T={T} />
      <StoryCursor T={T} />
    </div>
  );
}
