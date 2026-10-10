import { useState } from 'react';
import { Heart } from 'lucide-react';
import { Link } from 'wouter';
import { sounds } from '@/lib/sounds';
import type { AudioApi } from '@/components/audio-types';
import { SoundRow } from '@/components/sound-row';
import { CollectionDialog } from '@/components/collection-dialog';

export default function Favourites({ audio }: { audio: AudioApi }) {
  const [open, setOpen] = useState(false);
  const list = sounds.filter((s) => audio.favourites.includes(s.id));

  return (
    <div>
      <h1 className="text-4xl">Favourites</h1>
      <p className="mt-2 text-muted-foreground">Saved on this device only.</p>
      {list.length === 0 ? (
        <div className="mt-10 grid place-items-center rounded-3xl border border-dashed border-border px-6 py-14 text-center" data-testid="empty-favourites">
          <Heart className="size-8 text-primary" />
          <p className="font-display mt-4 text-2xl">Nothing saved yet</p>
          <p className="mt-2 max-w-xs text-sm text-muted-foreground">
            Tap the heart beside a sound and it will wait for you here.
          </p>
          <Link href="/sounds" className="mt-6 rounded-full bg-primary px-5 py-3 text-sm font-medium text-primary-foreground" data-testid="link-browse">
            Browse sounds
          </Link>
        </div>
      ) : (
        <ul className="mt-6 grid gap-3 md:grid-cols-2">
          {list.map((s) => (
            <SoundRow key={s.id} sound={s} audio={audio} onCollection={() => setOpen(true)} />
          ))}
        </ul>
      )}
      <CollectionDialog open={open} onOpenChange={setOpen} />
    </div>
  );
}
