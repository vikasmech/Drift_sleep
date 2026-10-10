import { useState } from 'react';
import { sounds } from '@/lib/sounds';
import type { AudioApi } from '@/components/audio-types';
import { SoundRow } from '@/components/sound-row';
import { CollectionDialog } from '@/components/collection-dialog';

const CATS = ['All', 'Rain', 'Water', 'Noise', 'Nature', 'Music'] as const;

export default function Sounds({ audio }: { audio: AudioApi }) {
  const [cat, setCat] = useState<(typeof CATS)[number]>('All');
  const [open, setOpen] = useState(false);
  const list = sounds.filter((s) => cat === 'All' || s.category === cat);
  const free = list.filter((s) => s.free);
  const paid = list.filter((s) => !s.free);

  return (
    <div>
      <h1 className="text-4xl">All sounds</h1>
      <p className="mt-2 text-muted-foreground">
        {sounds.filter((s) => s.free).length} free, always. The rest are previewable for 30 seconds.
      </p>

      <div className="-mx-5 mt-6 flex gap-2 overflow-x-auto px-5 pb-2" role="group" aria-label="Filter by category">
        {CATS.map((c) => (
          <button
            key={c}
            onClick={() => setCat(c)}
            aria-pressed={cat === c}
            className={`shrink-0 rounded-full border px-4 py-2 text-sm ${
              cat === c ? 'border-primary bg-primary/15 text-primary' : 'border-border text-muted-foreground'
            }`}
            data-testid={`filter-${c.toLowerCase()}`}
          >
            {c}
          </button>
        ))}
      </div>

      {list.length === 0 && (
        <p className="mt-10 text-muted-foreground" data-testid="text-empty">Nothing here.</p>
      )}

      {free.length > 0 && (
        <section className="mt-6">
          <h2 className="mb-3 text-sm tracking-[0.18em] text-muted-foreground uppercase">Free</h2>
          <ul className="grid gap-3 md:grid-cols-2">
            {free.map((s) => (
              <SoundRow key={s.id} sound={s} audio={audio} onCollection={() => setOpen(true)} />
            ))}
          </ul>
        </section>
      )}

      {paid.length > 0 && (
        <section className="mt-10">
          <div className="mb-3 flex items-end justify-between gap-3">
            <h2 className="text-sm tracking-[0.18em] text-muted-foreground uppercase">The collection</h2>
            <button
              onClick={() => setOpen(true)}
              className="text-sm text-primary underline-offset-4 hover:underline"
              data-testid="button-about-collection"
            >
              About the collection
            </button>
          </div>
          <ul className="grid gap-3 md:grid-cols-2">
            {paid.map((s) => (
              <SoundRow key={s.id} sound={s} audio={audio} onCollection={() => setOpen(true)} />
            ))}
          </ul>
        </section>
      )}
      <CollectionDialog open={open} onOpenChange={setOpen} />
    </div>
  );
}
