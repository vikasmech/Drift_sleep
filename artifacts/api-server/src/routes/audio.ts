import { Router } from "express";
import { audioFile, audioNames } from "../lib/audio-storage";

const router = Router();

router.get("/audio/:name", async (req, res) => {
  const name = req.params.name.replace(/\.mp3$/, "");
  if (!audioNames.includes(name as (typeof audioNames)[number])) {
    res.status(404).json({ error: "Sound not found." });
    return;
  }
  try {
    const file = audioFile(name);
    const [metadata] = await file.getMetadata();
    const size = Number(metadata.size);
    let start = 0;
    let end = size - 1;
    const range = req.headers.range;
    if (range) {
      const match = /^bytes=(\d*)-(\d*)$/.exec(range);
      if (!match || (!match[1] && !match[2])) {
        res.status(416).set("Content-Range", `bytes */${size}`).end();
        return;
      }
      if (!match[1]) start = Math.max(0, size - Number(match[2]));
      else {
        start = Number(match[1]);
        if (match[2]) end = Math.min(end, Number(match[2]));
      }
      if (start > end || start >= size) {
        res.status(416).set("Content-Range", `bytes */${size}`).end();
        return;
      }
      res.status(206).set("Content-Range", `bytes ${start}-${end}/${size}`);
    }
    res.set({
      "Content-Type": "audio/mpeg",
      "Content-Length": String(end - start + 1),
      "Accept-Ranges": "bytes",
      "Cache-Control": "public, max-age=86400",
    });
    const stream = file.createReadStream({ start, end });
    stream.on("error", (error) => {
      req.log.error({ err: error }, "Audio stream failed");
      if (!res.headersSent) res.status(503).json({ error: "Audio is temporarily unavailable." });
      else res.destroy(error);
    });
    res.on("close", () => stream.destroy());
    stream.pipe(res);
  } catch (error) {
    req.log.error({ err: error }, "Audio file unavailable");
    res.status(503).json({ error: "This audio is not available yet. Please try again shortly." });
  }
});

export default router;
