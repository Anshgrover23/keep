// Apple Liquid Glass displacement maps (kube.io / WWDC 25 recipe).
// Signed-distance bevel → RG offset field. Neutral 128. Alpha 255 so Chromium
// does not premultiply the map to zero. Driven by the authored clock, not rAF.

function sdRoundBox(px, py, cx, cy, hw, hh, r) {
  const dx = Math.abs(px - cx) - hw + r;
  const dy = Math.abs(py - cy) - hh + r;
  const ox = Math.max(dx, 0);
  const oy = Math.max(dy, 0);
  return Math.min(Math.max(dx, dy), 0) + Math.hypot(ox, oy) - r;
}

function sdCircle(px, py, cx, cy, rad) {
  return Math.hypot(px - cx, py - cy) - rad;
}

function smin(a, b, k) {
  const h = Math.max(k - Math.abs(a - b), 0) / k;
  return Math.min(a, b) - h * h * k * 0.25;
}

const cache = new Map();

export function liquidDisplacementDataUrl({
  width,
  height,
  radius = 22,
  drip = 0,
  bevel = 18,
}) {
  const w = Math.max(8, Math.round(width));
  const h = Math.max(8, Math.round(height));
  const dripPx = Math.round(drip);
  const key = `${w}x${h}r${radius}d${dripPx}b${bevel}`;
  const hit = cache.get(key);
  if (hit) return hit;

  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d", { willReadFrequently: true });
  const img = ctx.createImageData(w, h);
  const data = img.data;
  const cx = w / 2;
  const extra = Math.max(0, dripPx);
  const cy = (h - extra) / 2;
  const hw = w / 2 - 1.5;
  const hh = (h - extra) / 2 - 1.5;
  const dripCx = cx;
  const dripCy = cy + hh - 6 + extra * 0.72;
  const dripR = 7 + extra * 0.38;

  const sample = (x, y) => {
    let d = sdRoundBox(x, y, cx, cy, hw, hh, Math.min(radius, hw, hh));
    if (extra > 0.5) d = smin(d, sdCircle(x, y, dripCx, dripCy, dripR), 16 + extra * 0.2);
    return d;
  };

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const d = sample(x + 0.5, y + 0.5);
      const e = 0.75;
      const nx = sample(x + 0.5 + e, y + 0.5) - sample(x + 0.5 - e, y + 0.5);
      const ny = sample(x + 0.5, y + 0.5 + e) - sample(x + 0.5, y + 0.5 - e);
      const len = Math.hypot(nx, ny) || 1;
      let rim = 0;
      if (d < 0 && d > -bevel) rim = 1 + d / bevel;
      else if (d >= 0 && d < 2.2) rim = 1 - d / 2.2;
      const mag = rim * rim * 48;
      const i = (y * w + x) * 4;
      data[i] = Math.max(0, Math.min(255, 128 + (nx / len) * mag));
      data[i + 1] = Math.max(0, Math.min(255, 128 + (ny / len) * mag));
      data[i + 2] = 128;
      data[i + 3] = 255;
    }
  }
  ctx.putImageData(img, 0, 0);
  const url = canvas.toDataURL("image/png");
  cache.set(key, url);
  return url;
}
