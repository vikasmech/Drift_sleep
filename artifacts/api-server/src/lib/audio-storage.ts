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

export const audioNames = ["gentle-rain", "ocean-waves", "night-forest", "soft-ambient"] as const;

export function audioFile(name: string) {
  const bucket = process.env.DEFAULT_OBJECT_STORAGE_BUCKET_ID;
  if (!bucket) throw new Error("Audio storage is not configured.");
  return audioStorage.bucket(bucket).file(`public/drift/audio/${name}.mp3`);
}
