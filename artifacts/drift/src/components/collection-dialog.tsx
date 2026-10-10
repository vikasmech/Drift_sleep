import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

export function CollectionDialog({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent data-testid="dialog-collection" className="border-border bg-popover">
        <DialogHeader>
          <p className="text-xs uppercase tracking-[0.2em] text-primary">
            One-time collection · coming soon
          </p>
          <DialogTitle className="text-3xl">The other twenty-five</DialogTitle>
          <DialogDescription className="text-base leading-relaxed text-muted-foreground">
            The first five sounds are free and always will be. The remaining 25 are planned as a
            single collection you buy once, with no subscription and no account.
          </DialogDescription>
        </DialogHeader>
        <p
          className="rounded-xl border border-border bg-muted/60 p-4 text-sm text-muted-foreground"
          data-testid="text-payments-disabled"
        >
          Payments are not enabled in this preview. Nothing can be bought or unlocked yet, and no
          price has been set. You can still play a 30-second preview of any sound.
        </p>
        <button
          onClick={() => onOpenChange(false)}
          className="rounded-full bg-secondary px-5 py-3 text-sm font-medium hover:bg-accent"
          data-testid="button-close-collection"
        >
          Back to sounds
        </button>
      </DialogContent>
    </Dialog>
  );
}
