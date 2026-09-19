import { createServer } from "node:http";
import { readFileSync, mkdirSync } from "node:fs";
import { join, extname, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = join(HERE, "out", "layouts");
mkdirSync(OUT, { recursive: true });
const MIME = {
  ".html": "text/html", ".js": "text/javascript", ".css": "text/css",
  ".woff2": "font/woff2", ".woff": "font/woff", ".ttf": "font/ttf", ".otf": "font/otf",
  ".png": "image/png", ".jpg": "image/jpeg", ".svg": "image/svg+xml",
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

const names = ["ring", "wings", "canopy", "split", "slash"];
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
await page.addInitScript(() => {
  window.__NO_PREVIEW_SOUND = true;
  window.__NO_CAPTIONS = true;
  window.__NO_BURST_EDIT = true;
});
page.on("pageerror", (e) => console.error("[js]", String(e).slice(0, 300)));
const port = srv.address().port;
for (let i = 0; i < names.length; i++) {
  await page.goto(`http://127.0.0.1:${port}/composition/index.html?burst=${i}`, { waitUntil: "networkidle", timeout: 90_000 });
  await page.waitForSelector("[data-om-exportable-video-with-duration-secs]", { timeout: 90_000 });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(400);
  await page.evaluate(() => {
    const el = document.querySelector("#stage");
    el.dispatchEvent(new CustomEvent("data-om-seek-to-time-frame", { detail: { time: 1.72, sync: true } }));
  });
  await page.waitForTimeout(80);
  const dest = join(OUT, `${i}-${names[i]}.png`);
  await page.screenshot({ path: dest, clip: { x: 0, y: 0, width: 1280, height: 720 } });
  console.log(dest);
}
await browser.close();
srv.close();
