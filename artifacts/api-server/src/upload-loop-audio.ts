import { audioFile, audioStorage, loopAudioNames } from "./lib/audio-storage";
import { readFile } from "node:fs/promises";

audioStorage.retryOptions.autoRetry = false;
for (const name of loopAudioNames) {
  const bytes = await readFile(`generated-artifacts/native-audio/${name}.wav`);
  console.log(`Uploading ${name}`);
  await audioFile(name, "wav").save(bytes, {
    resumable: true,
    chunkSize: 256 * 1024,
    metadata: { contentType: "audio/wav", cacheControl: "public, max-age=86400" },
  }).catch((error: { code?: number }) => {
    throw new Error(`Loop upload failed (${error.code ?? "unknown"}).`);
  });
  console.log(`Uploaded ${name}: ${bytes.length} bytes`);
}
