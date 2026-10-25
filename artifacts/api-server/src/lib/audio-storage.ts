import { Storage } from "@google-cloud/storage";

// Replit sidecar authentication; never persist or expose credentials.
export const audioStorage = new Storage({
  credentials: {
    audience: "replit",
    subject_token_type: "access_token",
    token_url: "http://127.0.0.1:1106/token",
    type: "external_account",
    credential_source: {
      url: "http://127.0.0.1:1106/credential",
      format: { type: "json", subject_token_field_name: "access_token" },
    },
    universe_domain: "googleapis.com",
  },
  projectId: "",
});

export const nativeSoundIds = [
  "gentle-rain", "ocean-waves", "brown-noise", "pink-noise", "soft-fan",
  "rain-on-glass", "warm-rain", "distant-rain", "evening-shower", "rainy-room",
  "quiet-cove", "distant-surf", "moonlit-sea", "soft-tide", "deep-water",
  "white-noise", "velvet-noise", "warm-static", "cabin-fan", "airflow",
  "night-forest", "woodland-hush", "distant-crickets", "sheltered-grove", "evening-breeze",
  "soft-ambient", "low-glow", "quiet-orbit", "stillness", "last-light",
];
export const audioNames = [
  "gentle-rain", "ocean-waves", "night-forest", "soft-ambient",
  ...nativeSoundIds.map(id => `native-${id}`),
];
export const loopAudioNames = nativeSoundIds.slice(0, 5).map(id => `loop-v2-${id}`);
export const fullTrackAudioNames = nativeSoundIds.slice(5).map(id => `full-${id}`);

export function audioFile(name: string, extension: "mp3" | "wav" = "mp3") {
  const bucket = process.env.DEFAULT_OBJECT_STORAGE_BUCKET_ID;
  if (!bucket) throw new Error("Audio storage is not configured.");
  return audioStorage.bucket(bucket).file(`public/drift/audio/${name}.${extension}`);
}
