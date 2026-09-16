// Retimes the generated MiniMax voiceover onto the authored clock.
// TTS compresses pause tags, so the raw read drifts; we cut the file at its
// detected silences and place every segment at its authored timecode.
// Segment map verified by pause rank-ordering (the five big pauses survive
// compression in the same order as authored).
// Usage: node retime-vo.mjs /path/to/vo.mp3   → vo-final.wav
import { execFileSync } from "node:child_process";

const SRC = process.argv[2];
if (!SRC) throw new Error("pass the VO mp3 path");

// [srcStart, srcEnd, timelineAt] — measured with silencedetect=-32dB:d=0.25
const SEGS = [
  [0.257, 2.779, 0.60],   // Your library lives in five different apps.
  [3.484, 4.565, 3.20],   // Five catalogues.
  [4.873, 6.527, 4.55],   // Five ideas of progress.
  [8.455, 9.935, 6.60],   // This is Colosseum.
  [10.973, 13.611, 8.60], // One fullscreen home for everything you read,
  [13.926, 14.373, 11.44],// watch,
  [14.662, 15.190, 12.09],// and hear.
  [17.288, 18.969, 13.80],// Three worlds. One shell.
  [19.676, 21.230, 15.80],// Manga and comics.
  [22.203, 23.782, 17.75],// Books and audiobooks.
  [24.734, 26.037, 20.45],// Film and TV.  (lands with the Theatre panel)
  [29.579, 30.934, 22.80],// The comic reader is real.
  [31.281, 33.235, 24.70],// Long strip. Paired pages.
  [33.556, 34.538, 26.75],// Right to left.  (RTL badge stamps 26.8)
  [36.370, 38.190, 28.60],// It resumes on the exact page.
  [41.275, 42.412, 33.00],// The player is real too.
  [42.746, 43.725, 34.35],// Built on mpv.
  [45.202, 46.860, 36.60],// What you download stays on disk.
  [47.330, 47.876, 38.60],// Offline.
  [48.269, 48.761, 39.50],// Yours.  (Ready pop lands 40.34)
  [54.679, 55.577, 44.80],// Every medium.
  [56.104, 56.450, 45.85],// One
  [56.842, 57.731, 46.35],// Continue row.
  [58.054, 59.058, 47.39],// One home.  (ends 48.39; silence to 54)
];

const PRE = 0.08, POST = 0.06; // padding into the surrounding silences
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
  `apad=whole_dur=54,alimiter=limit=0.95[o]`;
execFileSync("ffmpeg", ["-y", "-v", "error", "-i", SRC, "-filter_complex", graph,
  "-map", "[o]", "-ar", "48000", "vo-final.wav"], { stdio: "inherit" });
console.log("retimed → vo-final.wav (24 segments on the authored clock)");
