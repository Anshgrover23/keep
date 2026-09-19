// Retimes the generated MiniMax voiceover onto the authored clock.
// TTS compresses pause tags, so the raw read drifts; we cut the file at its
// detected silences and place every segment at its authored timecode.
// Usage: node retime-vo.mjs /path/to/vo.mp3   → vo-final.wav
import { execFileSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const SRC = process.argv[2];
if (!SRC) throw new Error("pass the VO mp3 path");
const OUT = process.argv[3] ?? join(HERE, "vo-final.wav");
const FILM = 15;

const SEGS = [
  [3.779, 4.470, 6.40],   // You type
  [4.748, 5.683, 7.28],  // today’s line
  [9.466, 11.257, 9.80],  // It sits on the desktop
  [15.399, 15.923, 11.70], // The day
  [16.379, 17.056, 12.15], // keeps moving
];

const PRE = 0.06, POST = 0.05;
const chains = [];
const mixIns = [];
SEGS.forEach(([a, b, at], i) => {
  const s = Math.max(0, a - PRE);
  const e = b + POST;
  const ms = Math.round(at * 1000);
  chains.push(`[0]atrim=${s.toFixed(3)}:${e.toFixed(3)},asetpts=PTS-STARTPTS,adelay=${ms}|${ms}[v${i}]`);
  mixIns.push(`[v${i}]`);
});
const graph = chains.join(";") +
  `;${mixIns.join("")}amix=inputs=${SEGS.length}:duration=longest:normalize=0,` +
  `apad=whole_dur=${FILM},alimiter=limit=0.95[o]`;
execFileSync("ffmpeg", ["-y", "-v", "error", "-i", SRC, "-filter_complex", graph,
  "-map", "[o]", "-ar", "48000", OUT], { stdio: "inherit" });
console.log(`retimed → ${OUT} (${SEGS.length} segments on the authored clock)`);
