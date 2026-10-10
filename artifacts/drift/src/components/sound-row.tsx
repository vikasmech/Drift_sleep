import { Heart, Lock, Pause, Play } from 'lucide-react';
import type { Soundscape } from '@/lib/sounds';
import type { AudioApi } from '@/components/audio-types';

export function SoundRow({
  sound,
  audio,
  onCollection,
}: {
  sound: Soundscape;
  audio: AudioApi;
  onCollection: () => void;
}) {
  const active = audio.current.id === sound.id && audio.isPlaying;
  const fav = audio.favourites.includes(sound.id);
  const isUsual = audio.usualId === sound.id;

  const onPlay = () => {
    if (active) audio.pause();
    else audio.play(sound, !sound.free);
  };

  return (
    <li
      className="rise flex items-center gap-3 rounded-2xl border border-border bg-card/70 p-3"
      data-testid={`row-sound-${sound.id}`}
    >
      <button
        onClick={onPlay}
        aria-label={
          active ? `Pause ${sound.title}` : sound.free ? `Play ${sound.title}` : `Preview ${sound.title}`
        }
        className="relative grid size-14 shrink-0 place-items-center overflow-hidden rounded-xl text-foreground"
        style={{ background: `radial-gradient(circle at 30% 25%, ${sound.color}, hsl(233 40% 10%) 95%)` }}
        data-testid={`button-play-${sound.id}`}
      >
        <span className="grid size-8 place-items-center rounded-full bg-background/55">
          {active ? <Pause className="size-4" /> : <Play className="ml-0.5 size-4" />}
        </span>
      </button>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <h3 className="truncate text-lg leading-tight">{sound.title}</h3>
          {!sound.free && (
            <button
              onClick={onCollection}
              className="inline-flex shrink-0 items-center gap-1 rounded-full border border-border px-2 py-0.5 text-[11px] text-muted-foreground hover:text-foreground"
              data-testid={`button-collection-${sound.id}`}
            >
              <Lock className="size-3" /> Collection
            </button>
          )}
        </div>
        <p className="truncate text-sm text-muted-foreground">
          {sound.category} · {sound.free ? 'Free' : active && audio.isPreview ? 'Previewing 30s' : '30s preview'}
        </p>
        <p className="line-clamp-1 text-xs text-muted-foreground/80">{sound.description}</p>
        {sound.free && (
          <button
            onClick={() => audio.setUsual(sound.id)}
            disabled={isUsual}
            className="mt-1 text-xs text-primary underline-offset-4 hover:underline disabled:text-muted-foreground disabled:no-underline"
            data-testid={`button-usual-${sound.id}`}
          >
            {isUsual ? 'Your usual' : 'Make this my usual'}
          </button>
        )}
      </div>
      <button
        onClick={() => audio.toggleFavourite(sound.id)}
        aria-pressed={fav}
        aria-label={fav ? `Remove ${sound.title} from favourites` : `Save ${sound.title} to favourites`}
        className="grid size-11 shrink-0 place-items-center rounded-full hover:bg-secondary"
        data-testid={`button-favourite-${sound.id}`}
      >
        <Heart className={`size-5 ${fav ? 'fill-primary text-primary' : 'text-muted-foreground'}`} />
      </button>
    </li>
  );
}
