import React, {
  createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useRef, useState,
} from 'react';
import { AppState, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AudioPlayer, createAudioPlayer, setAudioModeAsync } from 'expo-audio';
import * as FileSystem from 'expo-file-system/legacy';
import { audioUrl, FREE_SOUNDS, getSound, sounds } from '@/constants/sounds';

export type PlayStatus = 'idle' | 'loading' | 'playing' | 'paused' | 'ended' | 'error';
export const TIMER_OPTIONS = [15, 30, 45, 60, 90, 0] as const;

const STORE_KEY = 'drift.native.prefs.v1';
const FADE_MS = 8000;
const LOAD_TIMEOUT_MS = 20000;
const IS_NATIVE = Platform.OS !== 'web';
const DIR = IS_NATIVE ? `${FileSystem.documentDirectory ?? ''}drift-audio/` : '';
const localPath = (id: string) => `${DIR}native-${id}.mp3`;

interface Ctx {
  hydrated: boolean;
  currentId: string | null;
  status: PlayStatus;
  errorMessage: string | null;
  usualId: string;
  timerMinutes: number;
  timerDeadline: number | null;
  volume: number;
  favourites: string[];
  offlineSupported: boolean;
  offlineReady: Record<string, boolean>;
  downloadProgress: Record<string, number>;
  downloadErrors: Record<string, string>;
  play: (id: string) => Promise<void>;
  toggle: (id: string) => Promise<void>;
  pause: () => void;
  stop: () => void;
  setUsual: (id: string) => void;
  setTimerMinutes: (m: number) => void;
  setVolume: (v: number) => void;
  toggleFavourite: (id: string) => void;
  download: (id: string) => Promise<void>;
  removeDownload: (id: string) => Promise<void>;
  downloadAll: () => Promise<void>;
}

const AudioCtx = createContext<Ctx | null>(null);

export function AudioProvider({ children }: { children: ReactNode }) {
  const [hydrated, setHydrated] = useState<boolean>(false);
  const [currentId, setCurrentId] = useState<string | null>(null);
  const [status, setStatus] = useState<PlayStatus>('idle');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [usualId, setUsualId] = useState<string>(FREE_SOUNDS[0].id);
  const [timerMinutes, setTimerMinutesState] = useState<number>(30);
  const [timerDeadline, setTimerDeadline] = useState<number | null>(null);
  const [volume, setVolumeState] = useState<number>(0.7);
  const [favourites, setFavourites] = useState<string[]>([]);
  const [offlineReady, setOfflineReady] = useState<Record<string, boolean>>({});
  const [downloadProgress, setDownloadProgress] = useState<Record<string, number>>({});
  const [downloadErrors, setDownloadErrors] = useState<Record<string, string>>({});

  const playerRef = useRef<AudioPlayer | null>(null);
  const subRef = useRef<{ remove: () => void } | null>(null);
  const loadTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const deadlineRef = useRef<number | null>(null);
  const volumeRef = useRef<number>(0.7);
  const timerMinRef = useRef<number>(30);
  const currentRef = useRef<string | null>(null);
  const readyRef = useRef<Record<string, boolean>>({});
  const statusRef = useRef<PlayStatus>('idle');
  const playToken = useRef<number>(0);

  const setStatusBoth = (s: PlayStatus) => { statusRef.current = s; setStatus(s); };
  const clearLoadTimer = () => { if (loadTimer.current) clearTimeout(loadTimer.current); loadTimer.current = null; };
  const setDeadline = (d: number | null) => { deadlineRef.current = d; setTimerDeadline(d); };

  // Hydrate prefs and verify real files before any write.
  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const raw = await AsyncStorage.getItem(STORE_KEY);
        if (raw && alive) {
          const p = JSON.parse(raw) as Partial<{ usualId: string; timerMinutes: number; volume: number; favourites: string[] }>;
          if (p.usualId && getSound(p.usualId)?.free) setUsualId(p.usualId);
          if (typeof p.timerMinutes === 'number' && [0, 15, 30, 45, 60, 90].includes(p.timerMinutes)) {
            setTimerMinutesState(p.timerMinutes); timerMinRef.current = p.timerMinutes;
          }
          if (typeof p.volume === 'number' && Number.isFinite(p.volume)) {
            const validVolume = Math.max(0, Math.min(1, p.volume));
            setVolumeState(validVolume); volumeRef.current = validVolume;
          }
          if (Array.isArray(p.favourites)) setFavourites(p.favourites.filter((id) => !!getSound(id)));
        }
      } catch {}
      if (IS_NATIVE) {
        const found: Record<string, boolean> = {};
        for (const s of FREE_SOUNDS) {
          try {
            const info = await FileSystem.getInfoAsync(localPath(s.id));
            found[s.id] = info.exists && ((info as { size?: number }).size ?? 0) > 0;
          } catch { found[s.id] = false; }
        }
        if (alive) { readyRef.current = found; setOfflineReady(found); }
      }
      if (alive) setHydrated(true);
    })();
    return () => { alive = false; };
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    AsyncStorage.setItem(STORE_KEY, JSON.stringify({ usualId, timerMinutes, volume, favourites })).catch(() => {});
  }, [hydrated, usualId, timerMinutes, volume, favourites]);

  useEffect(() => {
    setAudioModeAsync({
      playsInSilentMode: true,
      shouldPlayInBackground: true,
      interruptionMode: 'doNotMix',
    }).catch((error) => {
      console.warn('Drift audio session setup failed', error);
      setErrorMessage('The audio session could not be configured. Tap play to retry.');
    });
  }, []);

  const clearLock = () => {
    try { playerRef.current?.clearLockScreenControls(); } catch {}
  };

  const stop = useCallback(() => {
    playToken.current += 1;
    clearLoadTimer();
    setDeadline(null);
    const p = playerRef.current;
    if (p) {
      try { p.pause(); p.volume = volumeRef.current; } catch {}
      clearLock();
    }
    setCurrentId(null); currentRef.current = null;
    setErrorMessage(null);
    setStatusBoth('idle');
  }, []);

  const stopRef = useRef(stop);
  stopRef.current = stop;

  const checkDeadline = useCallback(() => {
    const d = deadlineRef.current;
    const p = playerRef.current;
    if (d == null || !p) return;
    const left = d - Date.now();
    if (left <= 0) { stopRef.current(); return; }
    if (left <= FADE_MS) {
      try { p.volume = Math.max(0, volumeRef.current * (left / FADE_MS)); } catch {}
    }
  }, []);

  useEffect(() => {
    if (timerDeadline == null) return;
    const t = setInterval(checkDeadline, 1000);
    return () => clearInterval(t);
  }, [timerDeadline, checkDeadline]);

  useEffect(() => {
    const sub = AppState.addEventListener('change', (s) => { if (s === 'active') checkDeadline(); });
    return () => sub.remove();
  }, [checkDeadline]);

  const ensurePlayer = (): AudioPlayer => {
    if (!playerRef.current) {
      const p = createAudioPlayer(null, { updateInterval: 1000 });
      playerRef.current = p;
      subRef.current = p.addListener('playbackStatusUpdate', (st) => {
        checkDeadline();
        if (!currentRef.current) return;
        if (st.didJustFinish && !p.loop) {
          clearLoadTimer(); setDeadline(null); clearLock();
          setStatusBoth('ended');
          return;
        }
        if (st.playing) {
          clearLoadTimer(); setErrorMessage(null); setStatusBoth('playing');
          // The OS play button bypasses app callbacks. Restore the configured timer on resume.
          if (deadlineRef.current == null && getSound(currentRef.current)?.free && timerMinRef.current > 0) {
            setDeadline(Date.now() + timerMinRef.current * 60000);
          }
        }
        else if (st.isLoaded && statusRef.current === 'playing') setStatusBoth('paused');
      });
    }
    return playerRef.current;
  };

  const play = useCallback(async (id: string) => {
    const snd = getSound(id);
    if (!snd) return;
    const token = ++playToken.current;
    clearLoadTimer();
    const p = ensurePlayer();
    const resumeLoaded = currentRef.current === id && statusRef.current === 'paused';
    setCurrentId(id); currentRef.current = id;
    setErrorMessage(null);
    setStatusBoth('loading');
    try {
      p.pause();
      await setAudioModeAsync({
        playsInSilentMode: true,
        shouldPlayInBackground: true,
        interruptionMode: 'doNotMix',
      });
      if (token !== playToken.current) return;
      p.volume = volumeRef.current;
      p.loop = snd.free;
      if (!resumeLoaded) {
        let saved = readyRef.current[id];
        if (IS_NATIVE && saved) {
          const info = await FileSystem.getInfoAsync(localPath(id));
          saved = info.exists && ((info as { size?: number }).size ?? 0) > 0;
          if (!saved) {
            readyRef.current = { ...readyRef.current, [id]: false };
            setOfflineReady(readyRef.current);
          }
        }
        if (token !== playToken.current) return;
        const uri = saved ? localPath(id) : audioUrl(id);
        p.replace({ uri });
      }
      p.play();
      try {
        p.setActiveForLockScreen(true, { title: snd.title, artist: 'Drift', albumTitle: snd.category });
      } catch {}
      const m = timerMinRef.current;
      setDeadline(snd.free && m > 0 ? Date.now() + m * 60000 : null);
      loadTimer.current = setTimeout(() => {
        if (playToken.current !== token || statusRef.current !== 'loading') return;
        try { p.pause(); } catch {}
        setErrorMessage('This sound could not be loaded. Check your connection and try again.');
        setStatusBoth('error');
      }, LOAD_TIMEOUT_MS);
    } catch (e) {
      if (token !== playToken.current) return;
      console.warn('Drift playback failed', e);
      clearLoadTimer();
      setDeadline(null);
      setErrorMessage('Playback failed to start. Try again.');
      setStatusBoth('error');
    }
  }, []);

  const pause = useCallback(() => {
    playToken.current += 1;
    clearLoadTimer();
    try { playerRef.current?.pause(); } catch {}
    setDeadline(null);
    if (statusRef.current === 'playing' || statusRef.current === 'loading') setStatusBoth('paused');
  }, []);

  const toggle = useCallback(async (id: string) => {
    if (currentRef.current === id && (statusRef.current === 'playing' || statusRef.current === 'loading')) pause();
    else await play(id);
  }, [pause, play]);

  const setUsual = useCallback((id: string) => { if (getSound(id)?.free) setUsualId(id); }, []);

  const setTimerMinutes = useCallback((m: number) => {
    if (![0, 15, 30, 45, 60, 90].includes(m)) return;
    timerMinRef.current = m;
    setTimerMinutesState(m);
    if (statusRef.current === 'playing' || statusRef.current === 'loading') {
      try { if (playerRef.current) playerRef.current.volume = volumeRef.current; } catch {}
      setDeadline(currentRef.current && getSound(currentRef.current)?.free && m > 0 ? Date.now() + m * 60000 : null);
    }
  }, []);

  const setVolume = useCallback((v: number) => {
    if (!Number.isFinite(v)) return;
    v = Math.max(0, Math.min(1, v));
    volumeRef.current = v;
    setVolumeState(v);
    try { if (playerRef.current) playerRef.current.volume = v; } catch {}
  }, []);

  const toggleFavourite = useCallback((id: string) => {
    setFavourites((f) => (f.includes(id) ? f.filter((x) => x !== id) : [...f, id]));
  }, []);

  const markReady = (id: string, v: boolean) => {
    readyRef.current = { ...readyRef.current, [id]: v };
    setOfflineReady(readyRef.current);
  };

  const download = useCallback(async (id: string) => {
    if (!IS_NATIVE || !getSound(id)?.free) return;
    setDownloadErrors((e) => { const n = { ...e }; delete n[id]; return n; });
    setDownloadProgress((p) => ({ ...p, [id]: 0 }));
    try {
      await FileSystem.makeDirectoryAsync(DIR, { intermediates: true }).catch(() => {});
      const tmp = `${localPath(id)}.part`;
      const dl = FileSystem.createDownloadResumable(audioUrl(id), tmp, {}, (pr) => {
        const total = pr.totalBytesExpectedToWrite;
        const frac = total > 0 ? pr.totalBytesWritten / total : 0;
        setDownloadProgress((p) => ({ ...p, [id]: Math.min(0.99, frac) }));
      });
      const res = await dl.downloadAsync();
      if (!res || res.status !== 200) throw new Error('bad status');
      await FileSystem.deleteAsync(localPath(id), { idempotent: true });
      await FileSystem.moveAsync({ from: tmp, to: localPath(id) });
      const info = await FileSystem.getInfoAsync(localPath(id));
      if (!info.exists || ((info as { size?: number }).size ?? 0) <= 0) throw new Error('empty');
      markReady(id, true);
    } catch {
      await FileSystem.deleteAsync(`${localPath(id)}.part`, { idempotent: true }).catch(() => {});
      markReady(id, false);
      setDownloadErrors((e) => ({ ...e, [id]: 'Download failed. Try again.' }));
    } finally {
      setDownloadProgress((p) => { const n = { ...p }; delete n[id]; return n; });
    }
  }, []);

  const removeDownload = useCallback(async (id: string) => {
    if (!IS_NATIVE) return;
    if (currentRef.current === id) stopRef.current();
    await FileSystem.deleteAsync(localPath(id), { idempotent: true }).catch(() => {});
    const info = await FileSystem.getInfoAsync(localPath(id)).catch(() => null);
    markReady(id, !!info && info.exists);
  }, []);

  const downloadAll = useCallback(async () => {
    for (const s of FREE_SOUNDS) if (!readyRef.current[s.id]) await download(s.id);
  }, [download]);

  useEffect(() => () => {
    clearLoadTimer();
    subRef.current?.remove();
    try { playerRef.current?.remove(); } catch {}
  }, []);

  const value = useMemo<Ctx>(() => ({
    hydrated, currentId, status, errorMessage, usualId, timerMinutes, timerDeadline, volume, favourites,
    offlineSupported: IS_NATIVE, offlineReady, downloadProgress, downloadErrors,
    play, toggle, pause, stop, setUsual, setTimerMinutes, setVolume, toggleFavourite,
    download, removeDownload, downloadAll,
  }), [hydrated, currentId, status, errorMessage, usualId, timerMinutes, timerDeadline, volume, favourites,
    offlineReady, downloadProgress, downloadErrors, play, toggle, pause, stop, setUsual, setTimerMinutes,
    setVolume, toggleFavourite, download, removeDownload, downloadAll]);

  return <AudioCtx.Provider value={value}>{children}</AudioCtx.Provider>;
}

export function useAudio(): Ctx {
  const c = useContext(AudioCtx);
  if (!c) throw new Error('useAudio must be used within AudioProvider');
  return c;
}

/** Isolated ticking hook so only the countdown re-renders each second. */
export function useTimerRemaining(): number | null {
  const { timerDeadline } = useAudio();
  const [now, setNow] = useState<number>(Date.now());
  useEffect(() => {
    if (timerDeadline == null) return;
    setNow(Date.now());
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, [timerDeadline]);
  return timerDeadline == null ? null : Math.max(0, timerDeadline - now);
}

export const ALL_SOUND_COUNT = sounds.length;
