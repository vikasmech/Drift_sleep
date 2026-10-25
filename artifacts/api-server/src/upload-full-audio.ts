import { audioFile, fullTrackAudioNames } from "./lib/audio-storage";
import { readFile } from "node:fs/promises";

for (const name of fullTrackAudioNames) {
  const bytes = await readFile(`generated-artifacts/full-audio/${name}.mp3`);
  await audioFile(name).save(bytes, {
    resumable: false,
    metadata: { contentType: "audio/mpeg", cacheControl: "public, max-age=86400" },
  });
  console.log(`Uploaded ${name}: ${bytes.length} bytes`);
}
