import { sounds } from '@/lib/sounds';
import type { AudioApi } from '@/components/audio-types';

const TIMERS = [
  { m: 0, label: 'Continuous' },
  { m: 15, label: '15 minutes' },
  { m: 30, label: '30 minutes' },
  { m: 45, label: '45 minutes' },
  { m: 60, label: '1 hour' },
  { m: 90, label: '1.5 hours' },
];

export default function Settings({ audio }: { audio: AudioApi }) {
  const free = sounds.filter((s) => s.free);
  return (
    <div className="max-w-xl">
      <h1 className="text-4xl">Settings</h1>

      <section className="mt-8 space-y-6">
        <div>
          <label htmlFor="usual" className="mb-2 block text-sm text-muted-foreground">Your usual sound</label>
          <select
            id="usual"
            value={audio.usualId}
            onChange={(e) => audio.setUsual(e.target.value)}
            className="w-full rounded-xl border border-input bg-card px-4 py-3"
            data-testid="select-usual"
          >
            {free.map((s) => (
              <option key={s.id} value={s.id}>{s.title}</option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="timer" className="mb-2 block text-sm text-muted-foreground">Default sleep timer</label>
          <select
            id="timer"
            value={audio.timerMinutes}
            onChange={(e) => audio.setTimer(Number(e.target.value))}
            className="w-full rounded-xl border border-input bg-card px-4 py-3"
            data-testid="select-timer"
          >
            {TIMERS.map((t) => (
              <option key={t.m} value={t.m}>{t.label}</option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="v" className="mb-1 block text-sm text-muted-foreground">
            Volume: {Math.round(audio.volume * 100)}%
          </label>
          <input id="v" type="range" min={0} max={1} step={0.01} value={audio.volume} onChange={(e) => audio.setVolume(Number(e.target.value))} className="drift-range" data-testid="input-settings-volume" />
        </div>
      </section>

      <section className="mt-10 rounded-2xl border border-border bg-card/70 p-5">
        <h2 className="text-2xl">Offline</h2>
        <p className="mt-2 text-sm text-muted-foreground" data-testid="text-offline-status">
          {audio.offlineReady
            ? 'Your free sounds are saved on this device and can play without a connection.'
            : 'Save the five free sounds and the app on this device before listening without a connection.'}
        </p>
        <button
          onClick={() => audio.saveOffline()}
          disabled={audio.offlineReady || audio.offlineSaving}
          className="mt-4 rounded-full bg-primary px-5 py-3 text-sm font-medium text-primary-foreground disabled:opacity-60"
          data-testid="button-settings-offline"
        >
          {audio.offlineReady ? 'Saved' : audio.offlineSaving ? 'Saving...' : 'Save for offline'}
        </button>
        {audio.error && <p role="alert" className="mt-3 text-sm text-destructive">{audio.error}</p>}
      </section>

      <section className="mt-6 space-y-3 text-sm leading-relaxed text-muted-foreground" data-testid="text-honesty">
        <h2 className="text-2xl text-foreground">Plainly</h2>
        <p>Rain, ocean, forest and ambient music are original AI-generated audio. Noise and fan sounds are synthesized. The collection includes carefully softened tonal variations of these sounds, not 30 separate field recordings.</p>
        <p>Background playback varies by browser and device. When the screen locks, some browsers pause audio.</p>
        <p>Sleep timers fade out during active browser playback. If the browser suspends the app, the timer is enforced when it resumes. On iPhone, use your device's volume buttons.</p>
        <p>Offline copies stay in this browser and may be removed if storage is cleared or your device needs space.</p>
        <p>Overnight and native-app reliability has not been tested yet, so do not rely on it for a full night until it has.</p>
        <p>No account. Favourites and preferences live in this browser's local storage and are lost if you clear it.</p>
      </section>
    </div>
  );
}
