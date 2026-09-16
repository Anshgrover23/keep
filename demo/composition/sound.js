(() => {
  if (typeof window === 'undefined' || window.__NO_PREVIEW_SOUND) return;
  let ctx = null;
  const buffers = {};
  let cues = [];
  let lastT = -1;

  fetch('./sfx-cues.json').then((r) => r.json()).then(async (j) => {
    cues = j.cues;
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    await Promise.all(Object.entries(j.sounds).map(async ([name, snd]) => {
      const buf = await fetch(snd.file).then((r) => r.arrayBuffer());
      buffers[name] = { buf: await ctx.decodeAudioData(buf), hit: snd.hit ?? 0 };
    }));
  }).catch(() => {});

  window.__SFX_TICK = (T) => {
    if (!ctx || !cues.length) return;
    const dt = T - lastT;
    if (dt > 0 && dt < 0.25) {
      for (const c of cues) {
        if (c.t > lastT && c.t <= T && buffers[c.sound]) {
          if (ctx.state === 'suspended') ctx.resume();
          const { buf, hit } = buffers[c.sound];
          const src = ctx.createBufferSource();
          src.buffer = buf;
          const g = ctx.createGain();
          g.gain.value = Math.pow(10, (c.db ?? -12) / 20);
          src.connect(g).connect(ctx.destination);
          src.start(0, Math.max(0, hit - 0.06));
        }
      }
    }
    lastT = T;
  };
})();
