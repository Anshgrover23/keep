import { spawn } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const nocap = process.argv.includes("--no-captions");
const frames = join(HERE, "out", nocap ? "frames-nocap" : "frames", "f%05d.png");
const out = join(
  HERE,
  "out",
  nocap ? "keep-demo-1440p60-nocaptions.mp4" : "keep-demo-1440p60.mp4",
);

const child = spawn(
  "ffmpeg",
  [
    "-y",
    "-framerate",
    "60",
    "-i",
    frames,
    "-vf",
    "scale=2560:1440:flags=lanczos",
    "-c:v",
    "libx264",
    "-preset",
    "slow",
    "-crf",
    "12",
    "-pix_fmt",
    "yuv420p",
    "-movflags",
    "+faststart",
    out,
  ],
  { stdio: "inherit" },
);

child.on("exit", (code) => process.exit(code ?? 1));
