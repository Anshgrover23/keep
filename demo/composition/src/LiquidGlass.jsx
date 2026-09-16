import { useId, useLayoutEffect, useState } from "react";
import { liquidDisplacementDataUrl } from "./glass.js";

// UX Pilot glass rules: one light from top left, 10–30% tint, blur 10–20,
// 1px rim, glass only on the focal surface, translateZ(0). No drip blob.

const PANE = {
  background: "rgba(255, 255, 255, 0.42)",
  border: "1px solid rgba(255,255,255,0.7)",
  boxShadow:
    "inset 1px 1px 0 rgba(255,255,255,0.85), inset -1px -1px 0 rgba(28,36,48,0.06), 0 16px 40px rgba(80,100,130,0.14)",
  transform: "translateZ(0)",
};

export function LiquidGlass({
  width,
  height,
  radius = 22,
  scale = -28,
  blur = 16,
  children,
  style,
  pad = 0,
  tone: _tone = "light",
  dim = false,
}) {
  const reactId = useId().replace(/:/g, "");
  const fid = `lg-${reactId}`;
  const [href, setHref] = useState("");
  const mapW = Math.round(width * 2);
  const mapH = Math.round((height || 240) * 2);
  const pane = dim
    ? { ...PANE, background: "rgba(255,255,255,0.62)" }
    : PANE;
  useLayoutEffect(() => {
    setHref(liquidDisplacementDataUrl({
      width: mapW,
      height: mapH,
      radius: radius * 2,
      drip: 0,
      bevel: 28,
    }));
  }, [mapW, mapH, radius]);
  return (
    <div style={{ position: "relative", width, ...style }}>
      <svg width="0" height="0" style={{ position: "absolute" }} aria-hidden>
        <filter id={fid} x="-6%" y="-6%" width="112%" height="112%" colorInterpolationFilters="sRGB">
          {href ? <feImage href={href} x="0" y="0" width={mapW} height={mapH} result="map" /> : null}
          <feDisplacementMap in="SourceGraphic" in2="map" scale={scale} xChannelSelector="R" yChannelSelector="G" />
        </filter>
      </svg>
      <div
        style={{
          position: "relative",
          width: "100%",
          minHeight: height || undefined,
          borderRadius: radius,
          overflow: "hidden",
          isolation: "isolate",
          ...pane,
          backdropFilter: `blur(${blur}px) saturate(1.45) url(#${fid})`,
          WebkitBackdropFilter: `blur(${blur}px) saturate(1.45) url(#${fid})`,
        }}
      >
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: radius,
            pointerEvents: "none",
            background: "linear-gradient(135deg, rgba(255,255,255,0.28) 0%, transparent 42%)",
          }}
        />
        <div style={{ position: "relative", zIndex: 1, padding: pad }}>{children}</div>
      </div>
    </div>
  );
}

export function LiquidSearch({ children }) {
  return (
    <LiquidGlass width={348} height={56} radius={16} scale={-22} blur={12} dim style={{ width: "100%" }}>
      <div style={{
        minHeight: 56,
        display: "flex",
        alignItems: "center",
        padding: "0 18px",
        fontFamily: "Inter, system-ui",
        fontSize: 22,
        color: "#1c2430",
        width: "100%",
        boxSizing: "border-box",
      }}>
        {children}
      </div>
    </LiquidGlass>
  );
}
