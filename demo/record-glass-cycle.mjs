import { createServer } from "node:http";
import { readFileSync, mkdirSync } from "node:fs";
import { join, extname, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = join(HERE, "out/glass-cycle");
mkdirSync(OUT, { recursive: true });
const SCALE = 2;
const MIME = {
  ".html": "text/html", ".js": "text/javascript", ".css": "text/css",
  ".woff2": "font/woff2", ".woff": "font/woff", ".ttf": "text/ttf", ".otf": "font/otf",
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp",
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
await page.goto(`http://127.0.0.1:${srv.address().port}/glass-cycle/index.html`, { waitUntil: "networkidle", timeout: 90_000 });
await page.waitForSelector("[data-om-exportable-video-with-duration-secs]", { timeout: 90_000 });
await page.evaluate(() => document.fonts.ready);
await page.waitForTimeout(400);

const times = [0.2, 2.4, 4.8, 6.6, 8.8, 9.6];
for (const t of times) {
  await page.evaluate((time) => {
    const el = document.querySelector("#stage");
    el.dispatchEvent(new CustomEvent("data-om-seek-to-time-frame", { detail: { time, sync: true } }));
  }, t);
  await page.waitForTimeout(80);
  await page.screenshot({ path: join(OUT, `t${t}.png`), clip: { x: 0, y: 0, width: 1280, height: 720 } });
}

const FPS = 30;
const frames = Math.round(10 * FPS);
const frameDir = join(OUT, "frames");
mkdirSync(frameDir, { recursive: true });
for (let f = 0; f <= frames; f++) {
  const t = Math.min(f / FPS, 10 - 1e-4);
  await page.evaluate((time) => {
    const el = document.querySelector("#stage");
    el.dispatchEvent(new CustomEvent("data-om-seek-to-time-frame", { detail: { time, sync: true } }));
  }, t);
  await page.screenshot({ path: join(frameDir, `f${String(f).padStart(4, "0")}.png`), clip: { x: 0, y: 0, width: 1280, height: 720 } });
}

await browser.close();
srv.close();
console.log("frames", frames + 1);
