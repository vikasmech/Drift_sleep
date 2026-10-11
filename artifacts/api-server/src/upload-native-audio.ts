import { audioFile, nativeSoundIds } from "./lib/audio-storage";
import { readFile } from "node:fs/promises";

for (let start = 0; start < nativeSoundIds.length; start += 5) {
  await Promise.all(nativeSoundIds.slice(start, start + 5).map(async id => {
    const name = `native-${id}`;
    const bytes = await readFile(`generated-artifacts/native-audio/${name}.mp3`);
    await audioFile(name).save(bytes, {
      resumable: false,
      metadata: { contentType: "audio/mpeg", cacheControl: "public, max-age=86400" },
    });
    console.log(`Uploaded ${name}`);
  }));
}
