# Drift — One-Tap Sleep Sounds

**Your favourite sound, one tap, then put the phone down.**

Drift includes a native iPhone app, a web prototype, and a small audio API. This
guide explains how to install the project and build the iPhone app on a Mac.

## What is included?

- Thirty curated soundscapes across rain, ocean, noise, fans, forest, and ambient music.
- Five free sounds: Gentle rain, Ocean waves, Brown noise, Pink noise, and Soft fan.
- Unlimited playback and offline downloads for the five free sounds.
- Twenty-five premium previews, limited to 30 seconds. Purchases are **not implemented**.
- Favourites, a usual sound, sleep timers, and a gentle fade-out.
- Native background audio and lock-screen controls.
- Lossless WAV loops for the free native sounds, downloaded before playback to
  avoid repeated network buffering.

Audio includes generated rain/ocean/forest/ambient masters and synthesized noise
and fan sounds. The collection is not thirty separate licensed field recordings.
Overnight playback should still be tested on a physical iPhone.

## Important: what works outside Replit

The iPhone interface and native app can be built on macOS. However:

1. The workspace currently excludes macOS native package binaries. **Complete
   the Mac dependency adjustment below before installing packages.**
2. Sound files are stored in Replit App Storage, **not in this Git repository**.
3. The API's storage authentication depends on a Replit-only local service.
   Running that API on your Mac does **not** automatically give it access to the audio.

**Recommended first setup:** build the iPhone app on your Mac and point it at
your existing, publicly reachable HTTPS audio backend.

Running everything independently of Replit requires migrating the storage
authentication and copying the audio assets. This README documents that boundary;
it does not claim that migration is already implemented.

## 1. Mac prerequisites

Install:

- **Node.js 24**.
- **pnpm 10**; this workspace uses pnpm **10.26.1**.
- **Git**.
- **Full Xcode**, including an iOS Simulator runtime. Command Line Tools alone
  cannot build the iPhone app. Use an Xcode version compatible with Expo SDK 57
  and React Native 0.86.
- **CocoaPods**, for installing the native iOS dependencies.

Apple Silicon and Intel Macs both need the dependency adjustment in step 3.

If you already use [Homebrew](https://brew.sh), one way to install the tools is:

```bash
brew install node@24 cocoapods
export PATH="$(brew --prefix node@24)/bin:$PATH"
npm install --global pnpm@10.26.1
```

The global npm command installs **pnpm itself**. Use pnpm, not npm, to install
this project's dependencies.

Install Xcode separately, open it once, and finish its component installation.
Select Xcode under **Xcode → Settings → Locations → Command Line Tools**.
Install an iOS runtime under Xcode's platform/component settings if needed.

Check your tools:

```bash
node --version
pnpm --version
git --version
xcodebuild -version
pod --version
```

## 2. Get the complete project

If the project has been uploaded to GitHub:

```bash
git clone https://github.com/vikasmech/Drift_sleep.git
cd Drift_sleep
```

Otherwise, obtain a copy of the complete workspace and open its root directory
in Terminal. Copying only `artifacts/drift-mobile` is not enough: the app depends
on shared workspace packages in `lib/`.

**If the GitHub repository is still empty, cloning it will not download this
project.** The source files, including this README, must be uploaded first.

All commands below are run from the repository root unless stated otherwise.

## 3. Restore macOS package binaries and install dependencies

`pnpm-workspace.yaml` contains Replit-specific overrides that disable Darwin
(macOS) binaries for esbuild, Rollup, Lightning CSS, Tailwind, and related tools.
Without changing these, installation or compilation on a Mac can fail.

Run this **on your Mac copy** to remove only the macOS binary exclusions:

```bash
node --input-type=module <<'NODE'
import fs from 'node:fs';

const file = 'pnpm-workspace.yaml';
const original = fs.readFileSync(file, 'utf8');
const updated = original
  .split('\n')
  .filter(line => !(
    line.includes('darwin-') &&
    /:\s*['"]-['"]\s*$/.test(line)
  ))
  .join('\n');

fs.writeFileSync(file, updated);
console.log('macOS package exclusions removed.');
NODE

pnpm install --no-frozen-lockfile
```

Keep `pnpm-workspace.yaml` and the lockfile. Do not replace the workspace with a
standalone npm project. Installation may update `pnpm-lock.yaml` because the
platform overrides changed; review those changes before committing them.

## 4. Configure the audio backend

Use the hostname of your published HTTPS backend. Do not use a private Replit
preview URL, and do not assume the development preview is a permanent backend.

In the same Terminal where you will launch the app:

```bash
# Replace this placeholder with your actual backend hostname.
# No https:// prefix, trailing slash, or /api path.
export EXPO_PUBLIC_DOMAIN="YOUR_PUBLISHED_BACKEND_HOST"
```

The native app constructs audio URLs as:

```text
https://YOUR_PUBLISHED_BACKEND_HOST/api/audio/loop-v2-gentle-rain.wav
```

Check that the backend is reachable and has the new WAV files:

```bash
curl --fail --silent --show-error \
  "https://$EXPO_PUBLIC_DOMAIN/api/healthz"

curl --fail --silent --show-error \
  --range 0-77 \
  "https://$EXPO_PUBLIC_DOMAIN/api/audio/loop-v2-gentle-rain.wav" \
  --output /tmp/drift-audio-header.wav
```

The health endpoint should return `{"status":"ok"}`. The second request should
download the beginning of a WAV file, not an HTML login page or JSON error.
For a range request, the audio route normally responds with HTTP 206.

An older backend release may have the MP3 files but lack the `loop-v2-*.wav`
routes. Update the backend before testing continuous free playback.

`EXPO_PUBLIC_DOMAIN` is public configuration bundled into the app. **Never put
passwords, API keys, or storage credentials in `EXPO_PUBLIC_*` variables.**

The current native URL helper always uses HTTPS. Setting this value to
`localhost:8080` will not work with an ordinary local HTTP server.

## 5. Build and run the iPhone app in Simulator

Open Simulator:

```bash
open -a Simulator
```

With `EXPO_PUBLIC_DOMAIN` still exported, run:

```bash
pnpm --filter @workspace/drift-mobile exec expo run:ios
```

Expo generates the native iOS project if needed, installs pods, builds the app,
and starts the development server. The first build takes longer than subsequent
builds. Keep its Terminal running while developing.

If prompted to choose a bundle identifier on the first native build, configure
your app's identifier and keep it consistent for subsequent builds.

This is a **local native build**, rather than relying on the hosted Replit
simulator or Expo Go. It needs Xcode, but running in Simulator does not require
a paid Apple Developer membership.

### Test on a physical iPhone

Connect and trust the iPhone, enable Developer Mode when required, then run:

```bash
pnpm --filter @workspace/drift-mobile exec expo run:ios --device
```

Physical-device builds require valid Xcode signing configuration. You may need
to select your Apple development team in Xcode. The backend must be reachable
from the phone, not just from your Mac.

### Make a local release build

```bash
pnpm --filter @workspace/drift-mobile exec expo run:ios --configuration Release
```

This builds and launches a local release configuration. It does **not** submit
the app to the App Store or produce an App Store distribution automatically.

### Why not use the existing `dev` or `build` scripts?

- `artifacts/drift-mobile`'s `dev` script is configured for Replit's managed Expo
  session, proxy hostname, and injected port. It is not the Mac launch command.
- Its `build` script creates hosted Expo preview bundles. It is **not** an Xcode
  native build or an IPA export.
- Avoid the root `pnpm build` command as the first Mac build: it recursively
  invokes the hosted-preview build too.

Use the targeted `expo run:ios` command above for local iPhone development.

## Optional: run the web prototype

```bash
PORT=5173 BASE_PATH=/ pnpm --filter @workspace/drift run dev
```

Open `http://localhost:5173`.

Vite does not currently proxy `/api` on a Mac. To route web audio requests to
the same published backend, add this `proxy` option **inside the existing
`server` object** in `artifacts/drift/vite.config.ts`:

```ts
proxy: {
  '/api': {
    target: `https://${process.env.EXPO_PUBLIC_DOMAIN}`,
    changeOrigin: true,
  },
},
```

Export `EXPO_PUBLIC_DOMAIN` in that Terminal too, then restart Vite. This is a
Mac configuration change; the Replit workspace routes its services separately.

To build only the web prototype:

```bash
PORT=5173 BASE_PATH=/ pnpm --filter @workspace/drift run build
```

Output: `artifacts/drift/dist/public`.

## Optional: run the API locally

```bash
PORT=8080 pnpm --filter @workspace/api-server run dev
```

In another Terminal:

```bash
curl --fail http://localhost:8080/api/healthz
```

The health endpoint can run locally. **Audio storage is not portable yet.**
`artifacts/api-server/src/lib/audio-storage.ts` authenticates through a
Replit-only sidecar on `127.0.0.1:1106`; that service does not exist on your Mac.
Setting a bucket name alone will not fix authentication.

For a fully independent backend, you must:

1. Configure a storage provider and authentication suitable for your environment.
2. Obtain and copy the audio assets into your own storage.
3. Replace the Replit-specific storage client while preserving audio MIME types
   and byte-range responses.
4. Expose the API over HTTPS and set the app's backend hostname accordingly.

Expected storage paths in the current implementation:

```text
public/drift/audio/loop-v2-gentle-rain.wav
public/drift/audio/loop-v2-ocean-waves.wav
public/drift/audio/loop-v2-brown-noise.wav
public/drift/audio/loop-v2-pink-noise.wav
public/drift/audio/loop-v2-soft-fan.wav
public/drift/audio/native-<sound-id>.mp3
```

The web prototype also uses the unprefixed master MP3 files, including
`gentle-rain.mp3`, `ocean-waves.mp3`, `night-forest.mp3`, and `soft-ambient.mp3`.

The free sound prototype does not require a product database, login, or checkout.
`lib/db` is workspace scaffolding; database setup is only needed if you start
using its runtime modules.

## Checks and tests

```bash
# All workspace TypeScript checks
pnpm run typecheck

# Native app only
pnpm --filter @workspace/drift-mobile run typecheck

# Published manifest response tests
node artifacts/drift-mobile/server/serve.test.cjs

# Offline audio cache tests: compile the helper, then run the tests
pnpm --filter @workspace/api-server exec esbuild \
  ../drift-mobile/lib/audio-cache.ts \
  --bundle --platform=node --format=cjs \
  --external:expo-file-system/legacy \
  --outfile=/tmp/drift-audio-cache.cjs
node artifacts/drift-mobile/lib/audio-cache.test.cjs /tmp/drift-audio-cache.cjs

# Regenerate shared API clients after changing the OpenAPI specification
pnpm --filter @workspace/api-spec run codegen
```

Before relying on the app overnight, test free playback, loop boundaries, lock
screen controls, offline playback, and sleep timers on a real iPhone.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| Missing `esbuild`, Rollup, Lightning CSS, or Tailwind Darwin binary | Complete step 3 and reinstall dependencies. |
| `PORT environment variable is required` | Use the port-prefixed API/web commands above. |
| `BASE_PATH environment variable is required` | Set `BASE_PATH=/` for the local web app. |
| Xcode or Simulator not found | Install full Xcode, select its Command Line Tools, and install an iOS runtime. |
| CocoaPods installation fails | Check `pod --version`, Xcode selection, and CocoaPods' error output. |
| App opens but sounds fail | Verify `EXPO_PUBLIC_DOMAIN`, HTTPS access, and both audio checks in step 4. Restart the app's development server after changing the hostname. |
| A free sound still has old audio | Connect once and let the updated WAV download finish. Old native MP3 downloads are replaced after the new download succeeds. |
| Sound ends after 30 seconds | Premium previews are intentionally limited; use one of the five free sounds for unlimited playback. |
| Sound ends after the selected duration | Check the sleep timer. Timer stops are intentional. |
| Hosted iOS preview says “Failed to parse manifest JSON” | Check the preview panel's privacy warning. Private Replit previews are unsupported by its native simulator/Expo Go flow; turn off private preview only if you accept making the preview accessible to anyone with its URL. |
| GitHub clone is empty or this README is missing | The workspace changes have not been uploaded to the repository yet. |

## Repository layout

```text
artifacts/
  drift/                 React + Vite web prototype
  drift-mobile/          Expo + React Native iPhone app
    app/                 Expo Router screens
    context/             Playback and preferences
    lib/                 Audio download cache and tests
    scripts/             Hosted preview build tooling
    server/              Hosted preview server
  api-server/            Express audio API
  mockup-sandbox/        Design preview sandbox, not required for iPhone builds
lib/
  api-spec/              OpenAPI contract and code generation
  api-client-react/      Shared generated API client
  api-zod/               Shared API validation schemas
  db/                    Database scaffolding
pnpm-workspace.yaml      Workspace packages and platform overrides
pnpm-lock.yaml           Dependency lockfile
```

Keep dependencies, generated builds, audio masters, credentials, and signing
files out of source control. Never copy Replit session secrets into your Mac
project. The hosted audio files are not included automatically by a Git clone.
