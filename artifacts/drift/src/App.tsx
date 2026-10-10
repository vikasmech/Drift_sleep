import { type ReactNode } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Heart, Moon, Pause, Play, Settings as Cog, Waves } from 'lucide-react';
import { ErrorBoundary } from '@/components/error-boundary';
import { Toaster } from '@/components/ui/toaster';
import { TooltipProvider } from '@/components/ui/tooltip';
import NotFound from '@/pages/not-found';
import Tonight from '@/pages/tonight';
import Sounds from '@/pages/sounds';
import Favourites from '@/pages/favourites';
import Settings from '@/pages/settings';
import { useSleepAudio } from '@/hooks/use-sleep-audio';
import {
  Link,
  Route,
  Switch,
  useLocation,
  Router as WouterRouter,
} from 'wouter';

const queryClient = new QueryClient();

const NAV = [
  { href: '/', label: 'Tonight', icon: Moon },
  { href: '/sounds', label: 'Sounds', icon: Waves },
  { href: '/favourites', label: 'Favourites', icon: Heart },
  { href: '/settings', label: 'Settings', icon: Cog },
];

function Shell() {
  const audio = useSleepAudio();
  const [location] = useLocation();
  const showMini = audio.isPlaying && location !== '/';

  return (
    <div className="min-h-[100dvh]">
      <header className="mx-auto flex max-w-4xl items-center justify-between px-5 pt-6">
        <Link href="/" className="font-display text-2xl italic" data-testid="link-home">
          drift
        </Link>
        <nav className="hidden gap-1 md:flex" aria-label="Main">
          {NAV.map((n) => (
            <Link
              key={n.href}
              href={n.href}
              className={`rounded-full px-4 py-2 text-sm ${location === n.href ? 'bg-secondary text-foreground' : 'text-muted-foreground hover:text-foreground'}`}
              data-testid={`nav-${n.label.toLowerCase()}`}
            >
              {n.label}
            </Link>
          ))}
        </nav>
      </header>

      <main className="mx-auto max-w-4xl px-5 pb-48 pt-8 md:pb-32">
        <RoutedErrorBoundary>
          <Switch>
            <Route path="/">{() => <Tonight audio={audio} />}</Route>
            <Route path="/sounds">{() => <Sounds audio={audio} />}</Route>
            <Route path="/favourites">{() => <Favourites audio={audio} />}</Route>
            <Route path="/settings">{() => <Settings audio={audio} />}</Route>
            <Route component={NotFound} />
          </Switch>
        </RoutedErrorBoundary>
      </main>

      {showMini && (
        <div className="fixed inset-x-3 bottom-24 z-30 mx-auto flex max-w-md items-center gap-3 rounded-full border border-border bg-popover/95 p-2 pl-5 backdrop-blur md:bottom-6" data-testid="mini-player">
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm">{audio.current.title}</p>
            <p className="text-xs text-muted-foreground">{audio.isPreview ? 'Preview' : 'Playing'}</p>
          </div>
          <button onClick={audio.toggle} aria-label="Pause" className="grid size-11 place-items-center rounded-full bg-primary text-primary-foreground" data-testid="button-mini-toggle">
            {audio.isPlaying ? <Pause className="size-5" /> : <Play className="size-5" />}
          </button>
        </div>
      )}

      <nav className="fixed inset-x-0 bottom-0 z-20 border-t border-border bg-background/90 pb-[env(safe-area-inset-bottom)] backdrop-blur md:hidden" aria-label="Main">
        <ul className="mx-auto grid max-w-md grid-cols-4">
          {NAV.map((n) => {
            const on = location === n.href;
            return (
              <li key={n.href}>
                <Link
                  href={n.href}
                  className={`flex flex-col items-center gap-1 py-3 text-[11px] ${on ? 'text-primary' : 'text-muted-foreground'}`}
                  data-testid={`tab-${n.label.toLowerCase()}`}
                >
                  <n.icon className="size-5" />
                  {n.label}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </div>
  );
}

function RoutedErrorBoundary({ children }: { children: ReactNode }) {
  const [location] = useLocation();
  return <ErrorBoundary resetKey={location}>{children}</ErrorBoundary>;
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, '')}>
          <Shell />
        </WouterRouter>
        <Toaster />
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
