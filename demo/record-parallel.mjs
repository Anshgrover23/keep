import { createServer } from "node:http";
import { readFileSync, mkdirSync, rmSync } from "node:fs";
import { join, extname, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const HERE = dirname(fileURLToPath(import.meta.url));
const arg = (name, dflt) => {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : dflt;
};
const NOCAP = process.argv.includes("--no-captions");
const FPS = Number(arg("--fps", 60));
const SCALE = Number(arg("--scale", 2));
const WORKERS = Math.max(1, Number(arg("--workers", 8)));
const OUT = join(HERE, "out", NOCAP ? "frames-nocap" : "frames");
rmSync(OUT, { recursive: true, force: true });
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

const url = await new Promise((resolve) => {
  srv.on("listening", () => resolve(`http://127.0.0.1:${srv.address().port}/composition/index.html`));
});

async function bootPage(browser) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: SCALE });
  await page.addInitScript(() => {
    window.__NO_PREVIEW_SOUND = true;
    window.__NO_BURST_EDIT = true;
  });
  if (NOCAP) await page.addInitScript(() => { window.__NO_CAPTIONS = true; });
  page.on("pageerror", (e) => console.error("[js]", String(e).slice(0, 240)));
  await page.goto(url, { waitUntil: "networkidle", timeout: 90_000 });
  await page.waitForSelector("[data-om-exportable-video-with-duration-secs]", { timeout: 90_000 });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(400);
  return page;
}

async function seekShot(page, t, outPath) {
  await page.evaluate((time) => {
    const el = document.querySelector("#stage");
    el.dispatchEvent(new CustomEvent("data-om-seek-to-time-frame", { detail: { time, sync: true } }));
    for (const a of document.getAnimations()) {
      try { a.pause(); a.currentTime = time * 1000; } catch { /* detached */ }
    }
  }, t);
  await page.screenshot({ path: outPath, clip: { x: 0, y: 0, width: 1280, height: 720 } });
}

const probe = await chromium.launch();
const probePage = await bootPage(probe);
const duration = Number(await probePage.evaluate(() =>
  document.querySelector("#stage").getAttribute("data-om-exportable-video-with-duration-secs")));
await probe.close();

const frames = Math.round(duration * FPS);
console.log(`duration=${duration}s frames=${frames} fps=${FPS} scale=${SCALE}x workers=${WORKERS} captions=${!NOCAP}`);

const ranges = [];
const chunk = Math.ceil((frames + 1) / WORKERS);
for (let w = 0; w < WORKERS; w++) {
  const start = w * chunk;
  const end = Math.min(frames, start + chunk - 1);
  if (start <= frames) ranges.push({ start, end });
}

await Promise.all(ranges.map(async ({ start, end }, i) => {
  const browser = await chromium.launch();
  const page = await bootPage(browser);
  for (let f = start; f <= end; f++) {
    const t = Math.min(f / FPS, duration - 1e-4);
    const outPath = join(OUT, `f${String(f).padStart(5, "0")}.png`);
    await seekShot(page, t, outPath);
  }
  console.log(`worker ${i} done ${start}-${end}`);
  await browser.close();
}));

console.log(`done → ${OUT}`);
srv.close();
