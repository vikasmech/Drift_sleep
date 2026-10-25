# Drift

One tap, then put the phone down. Drift is a sleep-sounds app: thirty soundscapes, five of them free to loop, and a small audio API.

This repository is a pnpm workspace. The iPhone app to open is the native Swift project. The Expo app and the web prototype are still here.

## What’s in the app

- Thirty sounds: rain, water, noise, fans, forest, and ambient music.
- Five free loops: Gentle rain, Ocean waves, Brown noise, Pink noise, and Soft fan. These can play offline once the WAV files are in the app, and they repeat until you stop them or a sleep timer ends.
- Twenty-five other sounds play a short preview, about 30 seconds. There is no purchase flow on this branch.
- Favourites, a usual sound, volume, and a sleep timer (15, 30, 45, 60, or 90 minutes, or off) with a short fade at the end.
- Playback continues with the screen locked. The lock screen can play, pause, and stop.

NSDR and Yoga Nidra are playable. **A little space** plays `DriftSleep/Resources/nsdr.mp3`. **Nothing more tonight** plays `DriftSleep/Resources/yoga-nidra.mp3`. The original scripts are in `content/guided-rest`.

The sounds are generated and synthesized beds, not a set of separately licensed field recordings.

## Open the iPhone app

You need a Mac with **Xcode 16** and an iOS 17 simulator. The Swift app does not use Node, Expo, or CocoaPods.

```sh
cd artifacts/drift-mobile/swift
open DriftSleep.xcodeproj
```

Choose the **DriftSleep** scheme and an iPhone simulator, then press Run.

More detail, including a physical device and the test script, is in [`artifacts/drift-mobile/swift/README.md`](artifacts/drift-mobile/swift/README.md).

### Free loops

These five files are in `artifacts/drift-mobile/swift/DriftSleep/Resources` and ship with the app:

- `loop-v2-gentle-rain.wav`
- `loop-v2-ocean-waves.wav`
- `loop-v2-brown-noise.wav`
- `loop-v2-pink-noise.wav`
- `loop-v2-soft-fan.wav`

Each one is mono 16-bit 32 kHz PCM, about half a minute, and the app loops it. The other twenty-five sounds still stream a short MP3 from the audio server.

## Other apps in this repo

These are the earlier surfaces. They are not required to build the Swift app.

| Path | What it is |
| --- | --- |
| `artifacts/drift-mobile` | Expo / React Native app |
| `artifacts/drift` | Vite web prototype |
| `artifacts/api-server` | Express API that serves audio |
| `artifacts/mockup-sandbox` | Design sandbox |
| `lib/` | Shared API spec, client, and validation |
| `content/guided-rest` | NSDR and Yoga Nidra scripts |

### Expo app on a Mac

Node.js 24, pnpm 10.26.1, full Xcode, and CocoaPods. `pnpm-workspace.yaml` excludes some macOS package binaries. On a Mac, remove only the `darwin-` lines whose value is `"-"`, then install:

```sh
pnpm install --no-frozen-lockfile
export EXPO_PUBLIC_DOMAIN="YOUR_PUBLISHED_BACKEND_HOST"
pnpm --filter @workspace/drift-mobile exec expo run:ios
```

`EXPO_PUBLIC_DOMAIN` is the hostname only: no `https://`, no trailing slash, no `/api`. The app requests `https://<host>/api/audio/loop-v2-gentle-rain.wav`.

### Web and API

```sh
PORT=5173 BASE_PATH=/ pnpm --filter @workspace/drift run dev
PORT=8080 pnpm --filter @workspace/api-server run dev
```

The API health route can run locally: `GET /api/healthz`. Audio files live in Replit App Storage. The storage client talks to a Replit sidecar on `127.0.0.1:1106`, so a Mac process will not serve those files until storage is moved.

Expected object names:

```text
public/drift/audio/loop-v2-gentle-rain.wav
public/drift/audio/native-<sound-id>.mp3
public/drift/audio/full-<paid-sound-id>.mp3
```

The iPhone app uses `native-<sound-id>.mp3` as a short preview during the trial.
After the one-time Drift Plus purchase, paid sounds use the separate
`full-<sound-id>.mp3` objects. Add those full tracks under
`artifacts/api-server/generated-artifacts/full-audio/` and upload them with the
API server's full-audio upload script before enabling the purchase in production.

## Checks

```sh
pnpm run typecheck
cd artifacts/drift-mobile/swift && bash scripts/validate-mac.sh
```

Before trusting overnight playback, listen to a free loop across a loop boundary with the screen locked, and confirm a timer fades out.
