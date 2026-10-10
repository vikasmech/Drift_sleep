import { useCallback, useEffect, useRef, useState } from "react";
import { sounds, type Soundscape } from "@/lib/sounds";
import { AUDIO_CACHE, SHELL_CACHE, renderedKey, renderSound, silentAudio, previewAudio } from "@/lib/audio-renderer";

type Preferences = { volume: number; timerMinutes: number; favourites: string[]; usualId: string };
const defaultPrefs: Preferences = { volume: 0.5, timerMinutes: 30, favourites: [], usualId: sounds[0].id };
function loadPrefs(): Preferences {
  try {
    const p = JSON.parse(localStorage.getItem("drift-preferences") || "{}");
    return {
      volume: typeof p.volume === "number" && Number.isFinite(p.volume) ? Math.max(0, Math.min(1, p.volume)) : 0.5,
      timerMinutes: [0, 15, 30, 45, 60, 90].includes(p.timerMinutes) ? p.timerMinutes : 30,
      favourites: Array.isArray(p.favourites) ? p.favourites.filter((id: string) => sounds.some(s => s.id === id)) : [],
      usualId: sounds.some(s => s.id === p.usualId && s.free) ? p.usualId : sounds[0].id,
    };
  } catch { return defaultPrefs; }
}

export function useSleepAudio() {
  const [prefs, setPrefs] = useState(loadPrefs);
  const prefsRef = useRef(prefs);
  prefsRef.current = prefs;
  const [current, setCurrent] = useState(() => sounds.find(s => s.id === prefs.usualId)!);
  const currentRef = useRef(current);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isPreview, setIsPreview] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [remainingSeconds, setRemainingSeconds] = useState<number | null>(null);
  const [offlineReady, setOfflineReady] = useState(false);
  const [offlineSaving, setOfflineSaving] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const urlRef = useRef<string | null>(null);
  const playingRef = useRef(false);
  const previewRef = useRef(false);
  const deadline = useRef<number | null>(null);
  const version = useRef(0);
  const registration = useRef<Promise<ServiceWorkerRegistration> | null>(null);
  const actions = useRef<{ play: () => void; pause: () => void }>({ play: () => {}, pause: () => {} });

  useEffect(() => {
    try { localStorage.setItem("drift-preferences", JSON.stringify(prefs)); }
    catch { /* Playback still works when browser preference storage is disabled. */ }
  }, [prefs]);

  const pause = useCallback(() => {
    version.current++;
    audioRef.current?.pause();
    playingRef.current = false;
    setIsPlaying(false);
    setIsLoading(false);
    deadline.current = null;
    setRemainingSeconds(null);
    if ("mediaSession" in navigator) navigator.mediaSession.playbackState = "paused";
  }, []);

  const play = useCallback(async (sound = currentRef.current, preview = false) => {
    const known = sounds.find(s => s.id === sound.id);
    if (!known) { setError("This sound is not in the collection."); return; }
    // All premium paths are time-limited, including media-session resume/retry.
    preview = !known.free || preview;
    const request = ++version.current;
    if (!audioRef.current) {
      const element = new Audio();
      element.loop = true;
      element.preload = "auto";
      audioRef.current = element;
      element.addEventListener("ended", () => {
        if (previewRef.current) pause();
      });
      element.addEventListener("error", () => {
        if (playingRef.current) {
          setError("Playback stopped. Tap play to try again.");
          pause();
        }
      });
    }
    const element = audioRef.current;
    element.pause();
    playingRef.current = false;
    setIsPlaying(false);
    setIsLoading(true);
    setError(null);
    setCurrent(known);
    currentRef.current = known;
    previewRef.current = preview;
    setIsPreview(preview);
    deadline.current = null;
    setRemainingSeconds(null);
    // Start the same HTML media element in the user's gesture, before decoding.
    const warmup = silentAudio();
    element.src = warmup;
    element.loop = true;
    element.volume = 0;
    const activation = element.play().catch(() => {});
    let sourceUrl: string | null = null;
    try {
      const fullBlob = await renderSound(known);
      const blob = preview ? await previewAudio(fullBlob) : fullBlob;
      await activation;
      if (request !== version.current) return;
      sourceUrl = URL.createObjectURL(blob);
      const old = urlRef.current;
      element.src = sourceUrl;
      element.loop = !preview;
      element.volume = prefsRef.current.volume;
      await element.play();
      if (request !== version.current) { URL.revokeObjectURL(sourceUrl); return; }
      urlRef.current = sourceUrl;
      if (old) URL.revokeObjectURL(old);
      playingRef.current = true;
      setIsPlaying(true);
      const seconds = preview ? 30 : prefsRef.current.timerMinutes * 60;
      deadline.current = seconds ? Date.now() + seconds * 1000 : null;
      setRemainingSeconds(seconds || null);
      if ("mediaSession" in navigator) {
        navigator.mediaSession.metadata = new MediaMetadata({ title: known.title, artist: "Drift", album: "One-tap sleep sounds" });
        navigator.mediaSession.playbackState = "playing";
      }
    } catch (err) {
      if (sourceUrl) URL.revokeObjectURL(sourceUrl);
      if (request === version.current) {
        element.pause();
        setError(err instanceof Error && err.name === "NotAllowedError"
          ? "Your browser needs another tap to start audio. Please tap play."
          : err instanceof Error ? err.message : "Audio could not start. Please try again.");
        playingRef.current = false;
        setIsPlaying(false);
      }
    } finally {
      URL.revokeObjectURL(warmup);
      if (request === version.current) setIsLoading(false);
    }
  }, [pause]);

  actions.current = { play: () => { void play(currentRef.current, previewRef.current); }, pause };
  const toggle = useCallback(() => {
    if (playingRef.current) pause();
    else void play(currentRef.current, previewRef.current);
  }, [pause, play]);

  const setVolume = useCallback((volume: number) => {
    if (!Number.isFinite(volume)) return;
    volume = Math.max(0, Math.min(1, volume));
    setPrefs(p => ({ ...p, volume }));
    if (audioRef.current) audioRef.current.volume = volume;
  }, []);
  const setTimer = useCallback((timerMinutes: number) => {
    if (![0, 15, 30, 45, 60, 90].includes(timerMinutes)) return;
    setPrefs(p => ({ ...p, timerMinutes }));
    if (playingRef.current && !previewRef.current) {
      deadline.current = timerMinutes ? Date.now() + timerMinutes * 60000 : null;
      setRemainingSeconds(timerMinutes ? timerMinutes * 60 : null);
      if (audioRef.current) audioRef.current.volume = prefsRef.current.volume;
    }
  }, []);
  const toggleFavourite = useCallback((id: string) => {
    if (!sounds.some(s => s.id === id)) return;
    setPrefs(p => ({ ...p, favourites: p.favourites.includes(id) ? p.favourites.filter(x => x !== id) : [...p.favourites, id] }));
  }, []);
  const setUsual = useCallback((id: string) => {
    if (sounds.some(s => s.id === id && s.free)) setPrefs(p => ({ ...p, usualId: id }));
  }, []);

  const saveOffline = useCallback(async () => {
    setOfflineSaving(true);
    setError(null);
    try {
      if (!("caches" in window) || !registration.current) throw new Error("Offline saving is not available in this browser.");
      await registration.current;
      await navigator.serviceWorker.ready;
      for (const sound of sounds.filter(s => s.free)) await renderSound(sound);
      const cache = await caches.open(SHELL_CACHE);
      const origin = location.origin;
      const resources = performance.getEntriesByType("resource")
        .map(e => e.name)
        .filter(url => url.startsWith(origin) && !url.includes("/api/") && !url.includes("/@vite/") && !url.includes("/@react-refresh"));
      const targets = [...new Set([new URL(import.meta.env.BASE_URL, origin).href, ...resources])];
      await Promise.all(targets.map(async url => {
        const res = await fetch(url, { cache: "reload" });
        if (!res.ok) throw new Error("Part of the app could not be saved. Please try again online.");
        await cache.put(url, res);
      }));
      await cache.put(`${import.meta.env.BASE_URL}offline-complete`, new Response("saved"));
      setOfflineReady(true);
    } catch (err) {
      setOfflineReady(false);
      setError(err instanceof Error ? err.message : "Offline saving failed. Please try again.");
    } finally { setOfflineSaving(false); }
  }, []);

  useEffect(() => {
    if ("serviceWorker" in navigator) {
      registration.current = navigator.serviceWorker.register(`${import.meta.env.BASE_URL}sw.js`, { scope: import.meta.env.BASE_URL });
      registration.current.catch(() => { registration.current = null; });
    }
    if ("caches" in window) {
      void (async () => {
        const audio = await caches.open(AUDIO_CACHE);
        const shell = await caches.open(SHELL_CACHE);
        const entries = await Promise.all(sounds.filter(s => s.free).map(s => audio.match(renderedKey(s.id))));
        if (entries.every(Boolean) && await shell.match(`${import.meta.env.BASE_URL}offline-complete`) &&
            await shell.match(import.meta.env.BASE_URL)) setOfflineReady(true);
      })().catch(() => {});
    }
    if ("mediaSession" in navigator) {
      navigator.mediaSession.setActionHandler("play", () => actions.current.play());
      navigator.mediaSession.setActionHandler("pause", () => actions.current.pause());
      navigator.mediaSession.setActionHandler("stop", () => actions.current.pause());
    }
    const checkTime = () => {
      if (!playingRef.current || !deadline.current) return;
      const left = Math.max(0, (deadline.current - Date.now()) / 1000);
      setRemainingSeconds(Math.ceil(left));
      if (audioRef.current) audioRef.current.volume = prefsRef.current.volume * Math.min(1, left / (previewRef.current ? 2 : 20));
      if (left <= 0) pause();
    };
    const timer = setInterval(checkTime, 500);
    document.addEventListener("visibilitychange", checkTime);
    return () => {
      clearInterval(timer);
      document.removeEventListener("visibilitychange", checkTime);
      audioRef.current?.pause();
      if (urlRef.current) URL.revokeObjectURL(urlRef.current);
      if ("mediaSession" in navigator) {
        for (const action of ["play", "pause", "stop"] as const) navigator.mediaSession.setActionHandler(action, null);
      }
    };
  }, [pause]);

  return { current, isPlaying, isLoading, isPreview, error, remainingSeconds, offlineReady, offlineSaving,
    volume: prefs.volume, timerMinutes: prefs.timerMinutes, favourites: prefs.favourites, usualId: prefs.usualId,
    play, pause, toggle, setVolume, setTimer, toggleFavourite, setUsual, saveOffline };
}
