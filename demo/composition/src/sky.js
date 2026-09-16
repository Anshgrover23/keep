// Canvas port of Keep/Scene/DaySceneView.swift, SkyAppearance.swift, WeatherParticles.swift.
// Tokens copied from those files. Motion is a function of civil hour so a seek is deterministic.

import { solarAtHour } from "./solar.js";

const u64 = (n) => BigInt.asUintN(64, n);
const GOLDEN = 0x9e3779b97f4a7c15n;
const PARTICLE_SALT = 0xa5a5a5a5a5a5a5a5n;
const MIX1 = 0xbf58476d1ce4e5b9n;
const MIX2 = 0x94d049bb133111ebn;

function SceneRNG(seed, salt = GOLDEN) {
  let state = u64(BigInt(seed) + salt);
  return {
    next() {
      state = u64(state + GOLDEN);
      let z = state;
      z = u64((z ^ (z >> 30n)) * MIX1);
      z = u64((z ^ (z >> 27n)) * MIX2);
      z = z ^ (z >> 31n);
      return Number(z % 10000n) / 10000;
    },
  };
}

const rgb = (r, g, b) => [r, g, b];
const white = (v) => [v, v, v];
const mix = (a, b, t) => {
  const u = Math.min(1, Math.max(0, t));
  return [a[0] * (1 - u) + b[0] * u, a[1] * (1 - u) + b[1] * u, a[2] * (1 - u) + b[2] * u];
};
const css = ([r, g, b], a = 1) => `rgba(${Math.round(r * 255)},${Math.round(g * 255)},${Math.round(b * 255)},${a})`;

const PHASE = {
  night: {
    top: rgb(0.04, 0.06, 0.14),
    mid: rgb(0.08, 0.10, 0.22),
    horizon: rgb(0.12, 0.12, 0.24),
    sun: rgb(0.86, 0.88, 0.94),
    glow: rgb(0.35, 0.40, 0.62),
    starOpacity: 0.9,
    haze: 0.08,
  },
  dawn: {
    top: rgb(0.18, 0.12, 0.32),
    mid: rgb(0.78, 0.32, 0.34),
    horizon: rgb(1.0, 0.72, 0.42),
    sun: rgb(1.0, 0.86, 0.62),
    glow: rgb(1.0, 0.55, 0.32),
    starOpacity: 0.15,
    haze: 0.18,
  },
  morning: {
    top: rgb(0.56, 0.78, 0.94),
    mid: rgb(0.82, 0.91, 0.98),
    horizon: rgb(0.97, 0.96, 0.94),
    sun: rgb(1.0, 0.96, 0.82),
    glow: rgb(1.0, 0.93, 0.74),
    starOpacity: 0,
    haze: 0.10,
  },
  noon: {
    top: rgb(0.14, 0.40, 0.80),
    mid: rgb(0.36, 0.66, 0.92),
    horizon: rgb(0.70, 0.86, 0.96),
    sun: rgb(1.0, 0.97, 0.88),
    glow: rgb(1.0, 0.96, 0.84),
    starOpacity: 0,
    haze: 0.26,
  },
  afternoon: {
    top: rgb(0.34, 0.48, 0.68),
    mid: rgb(0.78, 0.66, 0.52),
    horizon: rgb(0.98, 0.76, 0.46),
    sun: rgb(1.0, 0.80, 0.44),
    glow: rgb(1.0, 0.62, 0.28),
    starOpacity: 0,
    haze: 0.18,
  },
  dusk: {
    top: rgb(0.12, 0.10, 0.28),
    mid: rgb(0.72, 0.28, 0.22),
    horizon: rgb(0.95, 0.48, 0.22),
    sun: rgb(1.0, 0.70, 0.38),
    glow: rgb(0.95, 0.35, 0.18),
    starOpacity: 0.25,
    haze: 0.2,
  },
};

const CYCLE_KEYS = [
  { u: 0.00, phase: "dawn" },
  { u: 0.10, phase: "morning" },
  { u: 0.26, phase: "noon" },
  { u: 0.44, phase: "afternoon" },
  { u: 0.58, phase: "dusk" },
  { u: 0.72, phase: "night" },
  { u: 0.88, phase: "dawn" },
  { u: 1.00, phase: "morning" },
];

function mixPal(a, b, t) {
  const s = t * t * (3 - 2 * t);
  return {
    top: mix(a.top, b.top, s),
    mid: mix(a.mid, b.mid, s),
    horizon: mix(a.horizon, b.horizon, s),
    sun: mix(a.sun, b.sun, s),
    glow: mix(a.glow, b.glow, s),
    starOpacity: a.starOpacity * (1 - s) + b.starOpacity * s,
    haze: a.haze * (1 - s) + b.haze * s,
  };
}

export function cinematicAt(u) {
  const t = Math.min(1, Math.max(0, u));
  let i = 0;
  while (i < CYCLE_KEYS.length - 1 && t >= CYCLE_KEYS[i + 1].u) i++;
  const a = CYCLE_KEYS[i];
  const b = CYCLE_KEYS[Math.min(i + 1, CYCLE_KEYS.length - 1)];
  const span = Math.max(1e-6, b.u - a.u);
  const pal = mixPal(PHASE[a.phase], PHASE[b.phase], (t - a.u) / span);
  const firstSun = t < 0.62;
  const nightMoon = t >= 0.66 && t < 0.86;
  const secondSun = t >= 0.88;
  const sunP = secondSun
    ? 0.20 + 0.22 * ((t - 0.88) / 0.12)
    : (t - 0.06) / 0.56;
  const moonP = 0.32 + 0.38 * ((t - 0.66) / 0.20);
  const sunOn = firstSun || secondSun;
  const moonOn = nightMoon && !secondSun;
  const lum = (c) => 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
  let local = lum(pal.horizon) * 0.7 + lum(pal.mid) * 0.3;
  if (sunOn) {
    const p = bodyPoint(1280, 720, sunP);
    const near = Math.max(0, 1 - Math.hypot(p.x - 240, p.y - 590) / 360);
    local += near * 0.55;
  }
  const nightInk = local < 0.45;
  return { pal, sunP, moonP, sunOn, moonOn, phase: a.phase, nightInk };
}

export function paletteFor(phase, weather) {
  const p = { ...PHASE[phase] };
  switch (weather) {
    case "cloudy":
      p.top = mix(p.top, white(0.42), 0.35);
      p.mid = mix(p.mid, white(0.55), 0.4);
      p.horizon = mix(p.horizon, white(0.62), 0.3);
      p.haze += 0.18;
      p.starOpacity *= 0.15;
      break;
    case "fog":
      p.top = mix(p.top, white(0.55), 0.45);
      p.mid = white(0.62);
      p.horizon = white(0.72);
      p.haze = 0.55;
      p.starOpacity = 0;
      break;
    case "rain":
    case "storm":
      p.top = mix(p.top, rgb(0.12, 0.16, 0.22), 0.55);
      p.mid = mix(p.mid, rgb(0.22, 0.26, 0.32), 0.5);
      p.horizon = mix(p.horizon, rgb(0.28, 0.32, 0.36), 0.4);
      p.haze += 0.2;
      p.starOpacity = 0;
      break;
    case "snow":
      p.top = mix(p.top, rgb(0.55, 0.62, 0.72), 0.4);
      p.mid = mix(p.mid, white(0.78), 0.35);
      p.horizon = white(0.88);
      p.haze += 0.15;
      p.starOpacity *= 0.2;
      break;
    default:
      break;
  }
  return p;
}

const R = {
  wallpaper: { body: 1, glow: 1, particle: 1, stroke: 1, particleOp: 1, star: 1, band: 1 },
  social: { body: 2.7, glow: 1.45, particle: 3.2, stroke: 3.6, particleOp: 1.35, star: 2.2, band: 1.7 },
};

function bodyPoint(w, h, progress) {
  const clamped = Math.min(1.15, Math.max(-0.15, progress));
  const x = w * (0.12 + 0.76 * clamped);
  const arc = Math.sin(clamped * Math.PI);
  const y = h * (0.72 - 0.48 * arc);
  return { x, y };
}

function drawRadial(ctx, x, y, radius, stops) {
  const g = ctx.createRadialGradient(x, y, 0, x, y, radius);
  for (const [t, color] of stops) g.addColorStop(t, color);
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.fill();
}

function drawMoon(ctx, w, h, progress, pal, scale) {
  const { x, y } = bodyPoint(w, h, progress);
  const r = 34 * Math.min(scale.body, 1.7);
  drawRadial(ctx, x, y, r * 2.4, [
    [0, css(rgb(0.72, 0.78, 0.92), 0.16)],
    [0.45, css(rgb(0.32, 0.36, 0.58), 0.05)],
    [1, css(pal.top, 0)],
  ]);
  const disc = ctx.createRadialGradient(x - r * 0.12, y - r * 0.14, 0, x, y, r);
  disc.addColorStop(0, css(rgb(0.93, 0.93, 0.90)));
  disc.addColorStop(0.62, css(rgb(0.84, 0.84, 0.81)));
  disc.addColorStop(0.92, css(rgb(0.74, 0.75, 0.76)));
  disc.addColorStop(1, css(rgb(0.58, 0.60, 0.66)));
  ctx.fillStyle = disc;
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.save();
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.clip();
  drawRadial(ctx, x - r * 0.28, y + r * 0.04, r * 0.62, [
    [0, css(rgb(0.58, 0.60, 0.64), 0.38)],
    [1, css(rgb(0.58, 0.60, 0.64), 0)],
  ]);
  drawRadial(ctx, x + r * 0.3, y - r * 0.22, r * 0.38, [
    [0, css(rgb(0.56, 0.58, 0.62), 0.28)],
    [1, css(rgb(0.56, 0.58, 0.62), 0)],
  ]);
  drawRadial(ctx, x + r * 0.08, y + r * 0.34, r * 0.28, [
    [0, css(rgb(0.54, 0.56, 0.60), 0.22)],
    [1, css(rgb(0.54, 0.56, 0.60), 0)],
  ]);
  ctx.restore();
}

function drawSun(ctx, w, h, progress, pal, scale) {
  const { x, y } = bodyPoint(w, h, progress);
  const radius = 38 * scale.body;
  const glowR = 320 * scale.glow;
  drawRadial(ctx, x, y, glowR, [
    [0, css(pal.glow, 0.48)],
    [0.16, css(pal.glow, 0.28)],
    [0.42, css(mix(pal.glow, pal.sun, 0.45), 0.12)],
    [1, css(pal.sun, 0)],
  ]);
  const corona = radius * 2.85;
  drawRadial(ctx, x, y, corona, [
    [0, css(mix(pal.sun, white(1), 0.72), 1)],
    [0.14, css(mix(pal.sun, white(1), 0.35), 0.98)],
    [0.32, css(pal.sun, 0.72)],
    [0.52, css(mix(pal.sun, pal.glow, 0.25), 0.32)],
    [0.74, css(pal.glow, 0.1)],
    [1, css(pal.sun, 0)],
  ]);
}

function drawBody(ctx, w, h, progress, pal, { moon, scale }) {
  if (moon) drawMoon(ctx, w, h, progress, pal, scale);
  else drawSun(ctx, w, h, progress, pal, scale);
}

function fillEllipse(ctx, x, y, rw, rh, color) {
  ctx.beginPath();
  ctx.ellipse(x, y, rw, rh, 0, 0, Math.PI * 2);
  ctx.fillStyle = color;
  ctx.fill();
}

export function drawKeepSky(ctx, {
  width: w,
  height: h,
  hour,
  weather,
  still = false,
  readability = "social",
  clock,
  cycle = null,
}) {
  const scale = R[readability] ?? R.social;
  const cine = cycle == null ? null : cinematicAt(cycle);
  const solar = cine ? null : solarAtHour(hour);
  const pal = cine ? cine.pal : paletteFor(solar.phase, weather);
  const t = still ? 0 : (clock ?? hour * 3600);

  const sky = ctx.createLinearGradient(w / 2, 0, w / 2, h);
  sky.addColorStop(0, css(pal.top));
  sky.addColorStop(0.5, css(pal.mid));
  sky.addColorStop(1, css(pal.horizon));
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, w, h);

  if (pal.starOpacity > 0.01) {
    const rng = SceneRNG(42);
    for (let i = 0; i < 90; i++) {
      const x = rng.next() * w;
      const y = rng.next() * h * 0.62;
      const twinkle = still ? 1 : 0.55 + 0.45 * Math.sin(t * 0.7 + i * 0.6);
      const radius = (0.6 + rng.next() * 1.4) * scale.star;
      ctx.globalAlpha = pal.starOpacity * twinkle;
      fillEllipse(ctx, x, y, radius / 2, radius / 2, "#fff");
    }
    ctx.globalAlpha = 1;
  }

  if (cine) {
    if (cine.moonOn) drawBody(ctx, w, h, cine.moonP, pal, { moon: true, scale });
    else if (cine.sunOn) drawBody(ctx, w, h, cine.sunP, pal, { moon: false, scale });
  } else {
    const moonP = solar.moonProgress < 0.82
      ? solar.moonProgress
      : 0.82 + (solar.moonProgress - 0.82) * 2.2;
    const moonVisible = !solar.isDay && moonP < 1.12;
    if (moonVisible) {
      drawBody(ctx, w, h, moonP, pal, { moon: true, scale });
    } else if (solar.sunProgress > -0.14) {
      drawBody(ctx, w, h, solar.sunProgress, pal, { moon: false, scale });
    }
  }

  const hazeHeight = h * (0.22 + pal.haze * 0.2);
  const haze = ctx.createLinearGradient(w / 2, h - hazeHeight, w / 2, h);
  haze.addColorStop(0, css(pal.horizon, 0));
  haze.addColorStop(1, css(pal.horizon, 0.55 + pal.haze));
  ctx.fillStyle = haze;
  ctx.fillRect(0, h - hazeHeight, w, hazeHeight);

  if (weather === "cloudy" || weather === "fog" || weather === "storm") {
    const bands = weather === "fog" ? 5 : 3;
    const fog = weather === "fog";
    for (let i = 0; i < bands; i++) {
      const y = h * (0.18 + i * 0.12);
      const drift = still ? 0 : Math.sin(t * 0.03 + i) * 40;
      ctx.save();
      ctx.globalAlpha = fog ? 0.14 : 0.08;
      ctx.filter = fog ? "blur(48px)" : "blur(32px)";
      const bh = (fog ? 90 : 56) * scale.band;
      ctx.fillStyle = css(pal.horizon);
      ctx.beginPath();
      ctx.roundRect(-80 + drift, y, w + 160, bh, 40);
      ctx.fill();
      ctx.restore();
    }
  }

  if (still) return;
  if (weather === "rain" || weather === "storm") {
    const storm = weather === "storm";
    const count = storm ? 140 : 90;
    const rng = SceneRNG(7, PARTICLE_SALT);
    ctx.strokeStyle = "#fff";
    ctx.lineWidth = 1 * scale.stroke;
    ctx.globalAlpha = Math.min(1, (storm ? 0.35 : 0.22) * scale.particleOp);
    for (let i = 0; i < count; i++) {
      const col = rng.next();
      const speed = 380 + rng.next() * 280;
      const length = (12 + rng.next() * 16) * scale.particle;
      const x = col * w + Math.sin(t * 0.4 + i) * 8 * scale.particle;
      const wrapH = h + 40 * scale.particle;
      const travel = (t * speed + rng.next() * h) % wrapH;
      const y = travel - 20 * scale.particle;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + 3 * scale.particle, y + length);
      ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }
  if (weather === "snow") {
    const rng = SceneRNG(19, PARTICLE_SALT);
    ctx.globalAlpha = Math.min(1, 0.7 * scale.particleOp);
    for (let i = 0; i < 70; i++) {
      const col = rng.next();
      const speed = 28 + rng.next() * 42;
      const flake = (2 + rng.next() * 3.2) * scale.particle;
      const drift = Math.sin(t * 0.6 + i * 0.4) * 18 * scale.particle;
      const x = col * w + drift;
      const wrapH = h + 20 * scale.particle;
      const y = (t * speed + rng.next() * h) % wrapH;
      fillEllipse(ctx, x, y, flake / 2, flake / 2, "#fff");
    }
    ctx.globalAlpha = 1;
  }
}
