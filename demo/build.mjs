import { build } from "esbuild";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));

await build({
  entryPoints: [join(HERE, "composition/src/main.jsx")],
  outdir: join(HERE, "composition/dist"),
  bundle: true,
  format: "iife",
  jsx: "automatic",
  minify: false,
  sourcemap: false,
  logLevel: "info",
  define: { "process.env.NODE_ENV": '"production"' },
});
console.log("built → composition/dist");
