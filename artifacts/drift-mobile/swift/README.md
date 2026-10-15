# Drift — Swift / SwiftUI iPhone app

This directory is a native rewrite of Drift in **SwiftUI, AVFoundation and MediaPlayer**.
There is no React Native, Expo, JavaScript runtime, CocoaPods, XcodeGen or third-party
Swift package dependency in this target. The original Expo and web apps are preserved
elsewhere in the repository.

**Validation status:** written and statically checked in a Linux workspace. It has
not been compiled, launched in an iOS simulator, tested on an iPhone, or submitted
to the App Store. Run the Xcode build and device checks below before relying on it.

## Open on your Mac

1. Install **Xcode 16 or later** and an iOS simulator runtime. This project uses
   Xcode 16's synchronized folders and targets **iOS 17 or later**.
2. Unzip the supplied Mac project download. It includes the five lossless free
   sounds, so they work offline from the first launch.
3. Open **DriftSleep.xcodeproj**. Select the **DriftSleep** scheme and an iPhone
   simulator, then press **Run**.
4. For your own iPhone, choose your Apple development team in **Signing &
   Capabilities**, replace `com.drift.sleep.native` with a bundle identifier you
   control, connect your phone, and select it as the run destination. Enable
   Developer Mode on the phone if Xcode asks.

No Node, pnpm or backend process is needed to build this Swift target.

### If you clone the repository instead of using the ZIP

Audio files are intentionally excluded from Git. The canonical masters remain
in App Storage. To put the five WAVs in the application bundle, run:

```sh
cd artifacts/drift-mobile/swift
bash scripts/prepare-audio.sh https://YOUR-UPDATED-HTTPS-BACKEND
open DriftSleep.xcodeproj
```

The script needs `curl` and Python 3. It validates mono 16-bit 32 kHz lossless
WAVs before moving each file into Resources. Do not substitute MP3s or add
intro/outro fades to looping assets.

The bundled Mac ZIP already contains these files; this step is not necessary
for that download. Xcode automatically includes Resources through its
synchronized source folder.

## Features implemented in source

- Tonight: one tap for the usual sound, play/pause/resume, stop, retry and timer.
- Sounds: all 30 existing entries and category filters.
- Five free sounds use local lossless PCM and `AVAudioPlayer.numberOfLoops = -1`.
  Repetition does not depend on a network request or a seek/restart callback.
- Remaining 25 entries play **bounded, non-looping previews**, not full premium
  masters. The decoder rejects previews over 31 seconds. No purchase/unlock flow
  has been added.
- Favourites, usual sound, timer, volume and backend preference persist locally.
- Bundled sounds are offline-ready immediately. A build without bundled files
  can download the five free sounds from an updated backend, validate them,
  and keep them in Application Support, excluded from backups.
- Save-all, individual saves, removal of downloaded copies, errors and retry.
  Bundled sounds are marked “Included in app” rather than offering a misleading
  removal action; bundled resources cannot be deleted from the installed app.
- Native background playback, lock-screen play/pause/stop, audio interruption
  handling, and pause on disconnected headphones.
- 15/30/45/60/90-minute timers or no timer, with an eight-second ending fade.
  Pausing cancels the countdown; resuming starts the selected timer again.
- NSDR/Yoga Nidra are **original scripts only**, not recordings or playable
  library entries. No third-party guided recording has been copied.

## Backend

The default is the published Drift API:

```text
https://one-tap-sleep-sounds.replit.app
```

This URL was obtained from the deployment service, not inferred from a preview URL.
At preparation time its health route and premium preview route responded, but its
new `loop-v2-*.wav` route returned 404. The ZIP's bundled WAVs avoid that problem
for the five free sounds. To support downloads after a Git clone, the backend must
first be updated to serve the current WAV assets.

You can edit the full HTTPS base address in the app's **Settings → Audio server**,
or change `DriftAudioServer` in `DriftSleep/Info.plist` before building. Do not put
API keys or protection-bypass tokens in the app. Previews require an internet
connection; errors are shown instead of silently substituting another sound.

The API routes remain:

```text
GET /api/healthz
GET /api/audio/loop-v2-gentle-rain.wav
GET /api/audio/native-rain-on-glass.mp3
```

The iPhone app does not require direct storage credentials. Keep App Storage
access on the server.

## Build and tests on macOS

Build an unsigned simulator app:

```sh
cd artifacts/drift-mobile/swift
bash scripts/validate-mac.sh
```

List installed simulators, then run the included XCTest target on one:

```sh
xcrun simctl list devices available
bash scripts/validate-mac.sh 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID'
```

You can also press **Command-U** in Xcode. Tests cover the catalogue/free boundary,
asset filenames, timer/fade math, backend address validation, packaged PCM files,
and rejection of HTML masquerading as audio. These tests are included, **not
claimed to have run in Linux**.

## Required device checks

Before an overnight session or release:

1. Put the phone in airplane mode. Start each included free sound. Listen across
   several 24–25-second boundaries and confirm no gap or volume jump.
2. Play for at least 30 minutes with the screen locked, including Bluetooth
   headphones. Verify lock-screen pause/resume/stop and output controls.
3. Verify a sleep timer fades and stops with the screen locked. Check the
   eight-second fade near the deadline in a debug build with a shortened timer.
4. Receive a call or Siri interruption; confirm pause and permitted resume.
   Disconnect headphones and confirm that playback pauses, not suddenly plays
   through the speaker.
5. Try each premium preview. Confirm it ends naturally in around 30 seconds,
   cannot repeat automatically and is not available as an offline free loop.
6. Test font sizes, VoiceOver, narrow iPhones, saved preferences after relaunch,
   download failures and rapid play/pause/sound switching.

## App Store preparation still needed

Select a signing team and final bundle identifier, verify privacy disclosures
against the finished app/backend, supply screenshots and store metadata, and
perform the device tests above. The included privacy manifest declares no
tracking and local UserDefaults use; the backend may still maintain ordinary
server access logs. Review that behavior before submitting privacy answers.

No App Store submission, TestFlight upload, purchase verification, paid unlock
or human/AI narration recording is performed by this rewrite.
