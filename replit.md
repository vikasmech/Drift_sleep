# Drift — One-Tap Sleep Sounds

A mobile-friendly web prototype: your favourite sound, one tap, then put the phone down.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the audio API via its managed workflow
- `pnpm --filter @workspace/drift run dev` — run Drift via its managed workflow (supplies PORT and BASE_PATH)
- `pnpm --filter @workspace/drift-mobile run dev` — run the native Expo companion via its managed workflow
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- Audio assets use Replit App Storage. No product database, login or checkout is required for the free prototype.

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (CJS bundle)

## Where things live

_Populate as you build — short repo map plus pointers to the source-of-truth file for DB schema, API contracts, theme files, etc._

## Architecture decisions

- Keep Drift's web prototype and native iPhone companion alongside one another; neither replaces the other.
- Browser background/locked-screen playback and timer scheduling vary, so never claim overnight reliability without real-device testing.
- Payments have not been connected. Premium sounds are previews only; no fake checkout or browser-local premium entitlement.

## Product

Thirty soundscapes: five free unlimited sounds and twenty-five preview-only tonal variations. Web and native iPhone versions include one-tap usual sound, favourites, sleep timer with fade and offline saving. Native playback uses an iOS background audio session and lock-screen controls, with downloads stored in the app's documents directory.
Rain, ocean, forest and ambient masters are AI-generated; noise/fan are synthesized. These are not thirty unique licensed field recordings.

## User preferences

- “Your favourite sound, one tap, then put the phone down.”
- Start with 24–36 carefully curated soundscapes, not hundreds of clips.
- Prioritize seamless audio with no audible pause between repeats, consistent volume, offline listening and reliable locked-screen playback.
- Keep the first five sounds free.
- Keep the UI elegant and lightweight.
- Test a one-time collection purchase before adding a subscription. Do not add subscriptions to this initial version.

## Gotchas

- Generated audio source files and processing outputs belong in ignored `generated-artifacts/`; runtime masters are served from App Storage.
- The collection is not commercially complete until purchase verification and protected premium delivery are implemented.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
