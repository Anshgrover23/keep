import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { flushSync } from "react-dom";

const DURATION = 10;
const PILL = { left: 268, top: 348, w: 744, h: 156 };
const stageEl = document.getElementById("stage");
stageEl.setAttribute("data-om-exportable-video-with-duration-secs", String(DURATION));

const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const easeInOut = (p) => (p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2);
const easeOut = (p) => 1 - Math.pow(1 - p, 3);

function sunAt(T) {
  const p = easeInOut(clamp(T / DURATION, 0, 1));
  return {
    x: 318 + Math.sin(p * Math.PI) * 18,
    y: 118 + p * 560,
    r: 118 - p * 22,
  };
}

function GlassCycle({ T }) {
  const p = clamp(T / DURATION, 0, 1);
  const sun = sunAt(T);
  const done = p >= 0.86;
  const stamp = easeOut(clamp((T - 8.4) / 0.28, 0, 1));
  const daylight = Math.round(12 + p * 88);
  const lx = sun.x - PILL.left;
  const ly = sun.y - PILL.top;
  const near = clamp(1 - Math.hypot(lx - 78, ly - 78) / 280, 0, 1);

  return (
    <div style={{ position: "relative", width: 1280, height: 720, overflow: "hidden", fontFamily: "Inter, system-ui" }}>
      <img
        src="../assets/sky/glass-cycle.png"
        alt=""
        style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover" }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `linear-gradient(180deg, rgba(40,18,40,${0.08 + p * 0.18}) 0%, rgba(255,140,70,${0.04 + p * 0.08}) 55%, rgba(255,160,80,0.12) 100%)`,
          pointerEvents: "none",
        }}
      />

      <div
        style={{
          position: "absolute",
          left: sun.x - sun.r * 1.8,
          top: sun.y - sun.r * 1.8,
          width: sun.r * 3.6,
          height: sun.r * 3.6,
          borderRadius: "50%",
          background: `radial-gradient(circle, rgba(255,248,220,0.95) 0%, rgba(255,230,160,0.7) 16%, rgba(255,190,90,0.35) 34%, rgba(255,150,60,0.0) 58%)`,
          filter: "blur(2px)",
          zIndex: 2,
          pointerEvents: "none",
        }}
      />

      <div
        style={{
          position: "absolute",
          left: PILL.left,
          top: PILL.top,
          width: PILL.w,
          height: PILL.h,
          borderRadius: 999,
          zIndex: 4,
          overflow: "hidden",
          background: "rgba(255, 200, 160, 0.10)",
          border: "1px solid rgba(255,255,255,0.42)",
          boxShadow: "0 22px 60px rgba(40,16,8,0.22), inset 0 1px 0 rgba(255,255,255,0.78), inset 0 -14px 28px rgba(90,30,8,0.08)",
          backdropFilter: "blur(44px) saturate(1.65) brightness(1.08)",
          WebkitBackdropFilter: "blur(44px) saturate(1.65) brightness(1.08)",
        }}
      >
        <div
          style={{
            position: "absolute",
            left: lx - 160,
            top: ly - 160,
            width: 320,
            height: 320,
            borderRadius: "50%",
            background: `radial-gradient(circle, rgba(255,255,236,${0.85 * near}) 0%, rgba(255,220,150,${0.4 * near}) 32%, transparent 64%)`,
            mixBlendMode: "plus-lighter",
            pointerEvents: "none",
          }}
        />
        <div
          style={{
            position: "absolute",
            left: 10,
            top: 12,
            width: 70,
            height: 70,
            borderRadius: "50%",
            background: "radial-gradient(circle at 28% 24%, rgba(255,255,255,0.55), rgba(255,255,255,0.04) 46%, transparent 62%)",
            pointerEvents: "none",
          }}
        />

        <div style={{ position: "relative", zIndex: 1, height: "100%", display: "flex", alignItems: "center", padding: "0 28px 0 22px", color: "rgba(255,248,240,0.96)" }}>
          <svg width="72" height="72" viewBox="0 0 72 72" aria-hidden>
            <circle cx="36" cy="36" r="26" fill="none" stroke="rgba(255,255,255,0.28)" strokeWidth="2.4" strokeDasharray="6 7" />
            <circle
              cx="36"
              cy="36"
              r="26"
              fill="none"
              stroke="rgba(255,255,255,0.92)"
              strokeWidth="2.4"
              strokeLinecap="round"
              strokeDasharray={`${p * 163.4} 163.4`}
              transform="rotate(-90 36 36)"
            />
          </svg>
          <div style={{ width: 1, height: 54, margin: "0 22px", background: "rgba(255,255,255,0.28)" }} />
          <div style={{ flex: 1, textAlign: "center", fontFamily: "Fraunces, serif", fontSize: 72, fontWeight: 400, letterSpacing: "-0.03em", lineHeight: 1 }}>
            Keep
          </div>
          <div style={{ width: 1, height: 54, margin: "0 22px", background: "rgba(255,255,255,0.28)" }} />
          <div style={{ width: 118, textAlign: "right", fontSize: 28, fontWeight: 500, letterSpacing: "-0.02em" }}>
            {daylight}%
          </div>
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 248,
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          gap: 12,
          opacity: done ? stamp : 0,
          transform: `scale(${0.92 + 0.08 * stamp})`,
          zIndex: 5,
          color: "#fff",
          fontSize: 34,
          fontWeight: 600,
          letterSpacing: "-0.03em",
          textShadow: "0 8px 28px rgba(40,10,0,0.35)",
        }}
      >
        <span
          style={{
            width: 34,
            height: 34,
            borderRadius: "50%",
            background: "rgba(255,255,255,0.22)",
            border: "1.5px solid rgba(255,255,255,0.7)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 18,
          }}
        >
          ✓
        </span>
          Completed
      </div>
    </div>
  );
}

let setTimeExternal = null;

function Root() {
  const [T, setT] = useState(0);
  useEffect(() => {
    setTimeExternal = (time, sync) => {
      const t = Math.max(0, Math.min(time, DURATION - 1e-4));
      if (sync) flushSync(() => setT(t));
      else setT(t);
    };
    const onSeek = (e) => setTimeExternal(e.detail.time, e.detail.sync);
    stageEl.addEventListener("data-om-seek-to-time-frame", onSeek);
    return () => stageEl.removeEventListener("data-om-seek-to-time-frame", onSeek);
  }, []);
  return <GlassCycle T={T} />;
}

createRoot(stageEl).render(<Root />);

const bar = document.getElementById("transport");
if (bar) {
  let playing = false;
  let last = 0;
  let cur = 0;
  const scrub = document.getElementById("scrub");
  const label = document.getElementById("timelabel");
  const step = (now) => {
    if (playing) {
      cur = Math.min(DURATION, cur + (now - last) / 1000);
      if (cur >= DURATION) playing = false;
      setTimeExternal?.(cur, false);
      scrub.value = String(cur);
      label.textContent = cur.toFixed(2) + "s";
    }
    last = now;
    requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
  document.getElementById("play").onclick = () => {
    if (cur >= DURATION - 0.05) cur = 0;
    playing = !playing;
  };
  scrub.oninput = () => {
    playing = false;
    cur = Number(scrub.value);
    setTimeExternal?.(cur, false);
    label.textContent = cur.toFixed(2) + "s";
  };
  window.addEventListener("keydown", (e) => {
    if (e.key === " ") {
      e.preventDefault();
      document.getElementById("play").click();
    }
  });
}
