import { type Soundscape } from "./sounds";

export const AUDIO_CACHE = "drift-rendered-audio-v1";
export const SHELL_CACHE = "drift-shell-v1";
const RAW_CACHE = "drift-master-audio-v1";
const RATE = 32000;
const pending = new Map<string, Promise<Blob>>();
export const renderedKey = (id: string) => `${import.meta.env.BASE_URL}offline-audio/${id}.wav`;

function periodicNoise(kind: string): Float32Array {
  const data = new Float32Array(RATE * 30);
  let state = 2943721;
  let brown = 0;
  let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
  for (let i = 0; i < data.length; i++) {
    state ^= state << 13; state ^= state >>> 17; state ^= state << 5;
    const white = (state >>> 0) / 2147483648 - 1;
    brown = (brown + white * 0.02) / 1.02;
    b0 = 0.99886 * b0 + white * 0.0555179;
    b1 = 0.99332 * b1 + white * 0.0750759;
    b2 = 0.969 * b2 + white * 0.153852;
    b3 = 0.8665 * b3 + white * 0.3104856;
    b4 = 0.55 * b4 + white * 0.5329522;
    b5 = -0.7616 * b5 - white * 0.016898;
    const pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11;
    b6 = white * 0.115926;
    const t = i / RATE;
    if (kind === "white") data[i] = white * 0.3;
    else if (kind === "brown" || kind === "velvet") data[i] = brown * 3.5;
    else if (kind.startsWith("fan")) {
      // Broadband airflow plus a quiet motor fundamental.
      data[i] = pink * 0.7 + Math.sin(2 * Math.PI * 60 * t) * 0.025 + Math.sin(2 * Math.PI * 120 * t) * 0.01;
    } else data[i] = pink;
  }
  return data;
}

async function masterAudio(name: string): Promise<ArrayBuffer> {
  const url = `${import.meta.env.BASE_URL}api/audio/${name}.mp3`;
  let cache: Cache | undefined;
  if ("caches" in window) cache = await caches.open(RAW_CACHE);
  const stored = await cache?.match(url);
  if (stored) return stored.arrayBuffer();
  const res = await fetch(url);
  if (!res.ok) throw new Error("This sound could not be loaded. Check your connection and try again.");
  if (cache) await cache.put(url, res.clone());
  return res.arrayBuffer();
}

function finishLoop(channels: Float32Array[], rate: number, seconds: number): Float32Array[] {
  const n = Math.min(...channels.map(c => c.length));
  const overlap = Math.min(Math.floor(rate * seconds), Math.floor(n / 4));
  const out = channels.map(input => {
    const output = input.slice(0, n - overlap);
    for (let i = 0; i < overlap; i++) {
      const w = (1 - Math.cos(Math.PI * i / overlap)) / 2;
      output[i] = input[n - overlap + i] * (1 - w) + input[i] * w;
    }
    return output;
  });
  let sum = 0, peak = 0;
  for (const c of out) for (const v of c) { sum += v * v; peak = Math.max(peak, Math.abs(v)); }
  const rms = Math.sqrt(sum / (out.length * out[0].length));
  const gain = Math.min(0.09 / Math.max(rms, 0.00001), 0.65 / Math.max(peak, 0.00001));
  for (const c of out) for (let i = 0; i < c.length; i++) c[i] *= gain;
  return out;
}

function wav(channels: Float32Array[], rate: number): Blob {
  const n = channels[0].length;
  const count = channels.length;
  const size = n * count * 2;
  const bytes = new ArrayBuffer(44 + size);
  const view = new DataView(bytes);
  const text = (offset: number, s: string) => [...s].forEach((c, i) => view.setUint8(offset + i, c.charCodeAt(0)));
  text(0, "RIFF"); view.setUint32(4, size + 36, true); text(8, "WAVE");
  text(12, "fmt "); view.setUint32(16, 16, true); view.setUint16(20, 1, true);
  view.setUint16(22, count, true); view.setUint32(24, rate, true);
  view.setUint32(28, rate * count * 2, true); view.setUint16(32, count * 2, true);
  view.setUint16(34, 16, true); text(36, "data"); view.setUint32(40, size, true);
  let offset = 44;
  for (let i = 0; i < n; i++) for (const c of channels) {
    view.setInt16(offset, Math.round(Math.max(-1, Math.min(1, c[i])) * 32767), true);
    offset += 2;
  }
  return new Blob([bytes], { type: "audio/wav" });
}

async function render(sound: Soundscape): Promise<Blob> {
  let cache: Cache | undefined;
  if ("caches" in window) cache = await caches.open(AUDIO_CACHE);
  const cached = await cache?.match(renderedKey(sound.id));
  if (cached) return cached.blob();
  let channels: Float32Array[];
  let rate = RATE;
  if (sound.category === "Noise") {
    channels = [periodicNoise(sound.kind)];
  } else {
    const master = sound.category === "Rain" ? "gentle-rain" : sound.category === "Water" ? "ocean-waves" :
      sound.category === "Nature" ? "night-forest" : "soft-ambient";
    const context = new AudioContext({ sampleRate: RATE });
    try {
      const buffer = await context.decodeAudioData(await masterAudio(master));
      channels = Array.from({ length: buffer.numberOfChannels }, (_, i) => new Float32Array(buffer.getChannelData(i)));
      rate = buffer.sampleRate;
    } finally {
      await context.close();
    }
  }
  const filters: Record<string, number> = {
    "rain-glass": 3800, "rain-warm": 1800, "rain-distant": 950, "rain-light": 7000, "rain-room": 2600,
    "ocean-cove": 2500, "ocean-distant": 850, "ocean-moon": 4500, "ocean-soft": 1900, "ocean-deep": 650,
    velvet: 550, static: 2900, "fan-deep": 1300, air: 6000,
    "forest-hush": 2200, "forest-distant": 1200, "forest-grove": 3300, "forest-breeze": 5500,
    "music-low": 800, "music-air": 5000, "music-still": 2100, "music-warm": 1300,
  };
  if (filters[sound.kind]) {
    const offline = new OfflineAudioContext(channels.length, channels[0].length, rate);
    const buffer = offline.createBuffer(channels.length, channels[0].length, rate);
    channels.forEach((c, i) => buffer.copyToChannel(c as Float32Array<ArrayBuffer>, i));
    const source = offline.createBufferSource();
    source.buffer = buffer;
    const filter = offline.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.value = filters[sound.kind];
    filter.Q.value = 0.6;
    source.connect(filter).connect(offline.destination);
    source.start();
    const filtered = await offline.startRendering();
    channels = Array.from({ length: filtered.numberOfChannels }, (_, i) => new Float32Array(filtered.getChannelData(i)));
  }
  const blob = wav(finishLoop(channels, rate, sound.category === "Music" ? 6 : 1), rate);
  if (cache) await cache.put(renderedKey(sound.id), new Response(blob, { headers: { "Content-Type": "audio/wav" } }));
  return blob;
}

export function renderSound(sound: Soundscape) {
  const existing = pending.get(sound.id);
  if (existing) return existing;
  const result = render(sound).finally(() => pending.delete(sound.id));
  pending.set(sound.id, result);
  return result;
}

export function silentAudio(): string {
  return URL.createObjectURL(wav([new Float32Array(RATE)], RATE));
}

export async function previewAudio(blob: Blob): Promise<Blob> {
  // Bound playback in the media file itself, even when background JS is suspended.
  const source = new DataView(await blob.arrayBuffer());
  const rate = source.getUint32(24, true);
  const count = source.getUint16(22, true);
  const length = Math.floor((source.byteLength - 44) / (count * 2));
  const frames = rate * 30;
  const channels = Array.from({ length: count }, () => new Float32Array(frames));
  for (let i = 0; i < frames; i++) {
    const fade = Math.min(1, (frames - i) / (rate * 2));
    for (let c = 0; c < count; c++) {
      channels[c][i] = source.getInt16(44 + ((i % length) * count + c) * 2, true) / 32768 * fade;
    }
  }
  return wav(channels, rate);
}
