import { useLayoutEffect, useRef } from "react";
import { ABS } from "./kit.jsx";
import { drawKeepSky } from "./sky.js";
import { filmWeather } from "./solar.js";

export function KeepSky({
  hour = 12,
  weather,
  still = false,
  readability = "social",
  saturate = 1,
  clock,
  cycle = null,
  style,
}) {
  const ref = useRef(null);
  const wx = weather ?? (cycle == null ? filmWeather(hour) : "clear");
  useLayoutEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const w = Math.max(1, canvas.clientWidth || 1280);
    const h = Math.max(1, canvas.clientHeight || 720);
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    const ctx = canvas.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    drawKeepSky(ctx, { width: w, height: h, hour, weather: wx, still, readability, clock, cycle });
  }, [hour, wx, still, readability, clock, cycle]);
  return (
    <canvas
      ref={ref}
      style={{
        ...ABS,
        inset: 0,
        width: "100%",
        height: "100%",
        display: "block",
        filter: saturate === 1 ? undefined : `saturate(${saturate})`,
        ...style,
      }}
    />
  );
}
