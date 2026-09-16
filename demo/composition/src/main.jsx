import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { flushSync } from "react-dom";
import { Demo, captionAt, CUES } from "./scenes.jsx";
import { CaptionStamp } from "./kit.jsx";

const DURATION = CUES.End;
const stageEl = document.getElementById("stage");
stageEl.setAttribute("data-om-exportable-video-with-duration-secs", String(DURATION));

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
  useEffect(() => {
    if (window.__SFX_TICK) window.__SFX_TICK(T);
    window.__T = T;
  }, [T]);
  return (
    <div style={{ position: "relative", width: 1280, height: 720, overflow: "hidden", pointerEvents: "none" }}>
      <Demo T={T} />
      <CaptionStamp T={T} text={captionAt(T)} />
    </div>
  );
}

createRoot(stageEl).render(<Root />);

const bar = document.getElementById("transport");
if (bar) {
  let playing = false;
  let last = 0;
  let cur = 0;
  const scrub = document.getElementById("scrub");
  const label = document.getElementById("timelabel");
  scrub.max = String(DURATION);
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
    if (e.key === " ") { e.preventDefault(); document.getElementById("play").click(); }
    if (e.key === "ArrowRight") { cur = Math.min(DURATION, cur + (e.shiftKey ? 1 : 1 / 30)); setTimeExternal?.(cur, false); scrub.value = String(cur); label.textContent = cur.toFixed(2) + "s"; }
    if (e.key === "ArrowLeft") { cur = Math.max(0, cur - (e.shiftKey ? 1 : 1 / 30)); setTimeExternal?.(cur, false); scrub.value = String(cur); label.textContent = cur.toFixed(2) + "s"; }
  });
}
