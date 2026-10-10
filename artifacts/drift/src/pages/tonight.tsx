import { Download, Moon, Pause, Play, Volume1 } from 'lucide-react';
import { Link } from 'wouter';
import { sounds } from '@/lib/sounds';
import type { AudioApi } from '@/components/audio-types';

const TIMERS = [
  { m: 15, label: '15 min' },
  { m: 30, label: '30 min' },
  { m: 45, label: '45 min' },
  { m: 60, label: '1 hour' },
  { m: 90, label: '1.5 hours' },
  { m: 0, label: 'All night' },
];

export function formatRemaining(s: number) {
  const m = Math.floor(s / 60);
  const sec = s % 60;
  return `${m}:${String(sec).padStart(2, '0')}`;
}

export default function Tonight({ audio }: { audio: AudioApi }) {
  const usual = sounds.find((s) => s.id === audio.usualId) ?? sounds[0];
  const onUsual = audio.current.id === usual.id;
  const playing = audio.isPlaying;

  const bigPress = () => {
    if (playing && audio.current.id === usual.id && !audio.isPreview) audio.pause();
    else audio.play(usual);
  };

  return (
    <div className="flex flex-col items-center pt-6 text-center">
      <p className="rise text-sm tracking-[0.18em] text-muted-foreground uppercase">Tonight</p>

      <div className="relative mt-8 grid place-items-center">
        <span className="moon-ring absolute size-72 rounded-full bg-primary/30 blur-sm sm:size-80" />
        <button
          onClick={bigPress}
          className="relative grid size-60 place-items-center rounded-full text-primary-foreground shadow-2xl sm:size-64"
          style={{
            background:
              'radial-gradient(circle at 35% 30%, hsl(42 85% 86%), hsl(38 70% 68%) 55%, hsl(30 50% 48%))',
          }}
          aria-label={playing && !audio.isPreview ? 'Pause' : `Play your usual, ${usual.title}`}
          data-testid="button-play-usual"
        >
          <span className="flex flex-col items-center gap-2 px-6">
            {playing && onUsual ? <Pause className="size-9" /> : <Play className="ml-1 size-9" />}
            <span className="font-display text-2xl leading-tight">
              {playing && onUsual ? 'Pause' : 'Play your usual'}
            </span>
            <span className="text-sm opacity-75" data-testid="text-usual-title">
              {usual.title}
            </span>
          </span>
        </button>
      </div>

      <div className="mt-10 min-h-16" aria-live="polite">
        {audio.isLoading && <p className="text-muted-foreground" data-testid="status-loading">Warming up the sound...</p>}
        {audio.error && (
          <div className="space-y-2" data-testid="status-error">
            <p className="text-destructive">{audio.error}</p>
            <button
              onClick={() => audio.play(audio.current)}
              className="rounded-full border border-border px-4 py-2 text-sm hover:bg-secondary"
              data-testid="button-retry"
            >
              Try again
            </button>
          </div>
        )}
        {!audio.isLoading && !audio.error && (
          <>
            <p className="font-display text-xl" data-testid="text-now-playing">
              {playing ? audio.current.title : 'Quiet for now'}
            </p>
            <p className="text-sm text-muted-foreground" data-testid="text-timer-status">
              {playing && audio.isPreview
                ? 'Previewing for 30 seconds'
                : playing && audio.remainingSeconds !== null
                  ? `Fading out in ${formatRemaining(audio.remainingSeconds)}`
                  : playing
                    ? 'Playing until you stop it'
                    : 'One tap. Then put the phone down.'}
            </p>
          </>
        )}
      </div>

      <section className="mt-6 w-full max-w-md space-y-8 text-left">
        <div>
          <label htmlFor="vol" className="mb-1 flex items-center gap-2 text-sm text-muted-foreground">
            <Volume1 className="size-4" /> Volume
          </label>
          <input
            id="vol"
            type="range"
            min={0}
            max={1}
            step={0.01}
            value={audio.volume}
            onChange={(e) => audio.setVolume(Number(e.target.value))}
            className="drift-range"
            data-testid="input-volume"
          />
        </div>

        <div>
          <p className="mb-3 flex items-center gap-2 text-sm text-muted-foreground">
            <Moon className="size-4" /> Gentle sleep timer
          </p>
          <div className="flex flex-wrap gap-2" role="group" aria-label="Sleep timer">
            {TIMERS.map((t) => (
              <button
                key={t.m}
                onClick={() => audio.setTimer(t.m)}
                aria-pressed={audio.timerMinutes === t.m}
                className={`rounded-full border px-4 py-2 text-sm ${
                  audio.timerMinutes === t.m
                    ? 'border-primary bg-primary/15 text-primary'
                    : 'border-border text-muted-foreground hover:text-foreground'
                }`}
                data-testid={`button-timer-${t.m}`}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border pt-5 text-sm">
          <Link href="/sounds" className="text-primary underline-offset-4 hover:underline" data-testid="link-choose-sound">
            Choose a different sound
          </Link>
          <button
            onClick={() => audio.saveOffline()}
            disabled={audio.offlineReady || audio.offlineSaving}
            className="inline-flex items-center gap-2 rounded-full border border-border px-4 py-2 text-muted-foreground hover:text-foreground disabled:opacity-70"
            data-testid="button-save-offline"
          >
            <Download className="size-4" />
            {audio.offlineReady ? 'Saved for offline' : audio.offlineSaving ? 'Saving...' : 'Save for offline'}
          </button>
        </div>
      </section>
    </div>
  );
}
