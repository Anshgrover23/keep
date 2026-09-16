import { createServer } from "node:http";
import { readFileSync, mkdirSync, existsSync } from "node:fs";
import { join, extname, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const HERE = dirname(fileURLToPath(import.meta.url));
const arg = (name, dflt) => {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : dflt;
};
const NOCAP = process.argv.includes("--no-captions");
const SMOKE = process.argv.includes("--smoke");
const FPS = Number(arg("--fps", 60));
const SCALE = Number(arg("--scale", 2));
const OUT = join(HERE, "out", SMOKE ? "smoke" : NOCAP ? "frames-nocap" : "frames");
mkdirSync(OUT, { recursive: true });

const MIME = {
  ".html": "text/html", ".js": "text/javascript", ".css": "text/css",
  ".woff2": "font/woff2", ".woff": "font/woff", ".ttf": "font/ttf", ".otf": "font/otf",
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp",
  ".svg": "image/svg+xml", ".json": "application/json",
  ".mp3": "audio/mpeg", ".wav": "audio/wav", ".mp4": "video/mp4",
};
const srv = createServer((req, res) => {
  const p = join(HERE, decodeURIComponent(req.url.split("?")[0]));
  try {
    res.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream");
    res.end(readFileSync(p));
  } catch {
    res.statusCode = 404;
    res.end();
  }
}).listen(0);

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: SCALE });
await page.addInitScript(() => { window.__NO_PREVIEW_SOUND = true; });
if (NOCAP) await page.addInitScript(() => { window.__NO_CAPTIONS = true; });
page.on("pageerror", (e) => console.error("[js]", String(e).slice(0, 400)));
page.on("console", (m) => { if (m.type() === "error") console.error("[console]", m.text().slice(0, 300)); });
await page.goto(`http://127.0.0.1:${srv.address().port}/composition/index.html`, { waitUntil: "networkidle", timeout: 90_000 });
await page.waitForSelector("[data-om-exportable-video-with-duration-secs]", { timeout: 90_000 });
await page.evaluate(() => document.fonts.ready);
await page.waitForTimeout(2500);

const stage = await page.$("#stage");
const duration = Number(await stage.getAttribute("data-om-exportable-video-with-duration-secs"));
const SMOKE_TIMES = [
  0.05, 0.9, 1.7,
  2.2, 3.4, 4.8, 6.3,
  7.0, 9.0, 12.0, 14.2, 16.2, 17.5,
];
const frames = SMOKE ? SMOKE_TIMES.length - 1 : Math.round(duration * FPS);
console.log(`duration=${duration}s frames=${frames} fps=${FPS} scale=${SCALE}x captions=${!NOCAP}`);
for (let f = 0; f <= frames; f++) {
  const t = SMOKE ? SMOKE_TIMES[f] : Math.min(f / FPS, duration - 1e-4);
  if (t === undefined) break;
  const outPath = join(OUT, SMOKE ? `smoke-${t}.png` : `f${String(f).padStart(5, "0")}.png`);
  if (!SMOKE && existsSync(outPath)) continue;
  await page.evaluate((time) => {
    const el = document.querySelector("#stage");
    el.dispatchEvent(new CustomEvent("data-om-seek-to-time-frame", { detail: { time, sync: true } }));
    for (const a of document.getAnimations()) {
      try { a.pause(); a.currentTime = time * 1000; } catch { /* detached */ }
    }
  }, t);
  await page.evaluate(async () => {
    const vids = [...document.querySelectorAll("video")];
    await Promise.all(vids.map((v) => new Promise((resolve) => {
      if (v.readyState >= 2 && !v.seeking) { resolve(); return; }
      const done = () => resolve();
      v.addEventListener("seeked", done, { once: true });
      v.addEventListener("loadeddata", done, { once: true });
      setTimeout(done, 700);
    })));
  });
  if (SMOKE) await page.waitForTimeout(120);
  await page.screenshot({ path: outPath, clip: { x: 0, y: 0, width: 1280, height: 720 } });
  if (!SMOKE && f % 300 === 0) console.log(`frame ${f}/${frames}`);
}
console.log(`done → ${OUT}`);
await browser.close();
srv.close();
