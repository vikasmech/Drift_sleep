# Drift — Swift / SwiftUI iPhone app

This directory is a native rewrite of Drift in **SwiftUI, AVFoundation and MediaPlayer**.
There is no React Native, Expo, JavaScript runtime, CocoaPods, XcodeGen or third-party
Swift package dependency in this target. The original Expo and web apps are preserved
elsewhere in the repository.

**Validation status:** Debug builds have been launched on the iPhone 16 Pro
simulator. This is not an App Store submission build and has not been tested on a
physical iPhone. Apple currently requires Xcode 26 and the iOS 26 SDK for uploads.

## Open on your Mac

1. Install **Xcode 16 or later** and an iOS simulator runtime for development. Use
   **Xcode 26 or later with the iOS 26 SDK** for App Store uploads. This project uses
   synchronized folders and targets **iOS 17 or later**.
2. Unzip the supplied Mac project download. It includes the five lossless free
   sounds, so they work offline from the first launch.
3. Open **DriftSleep.xcodeproj**. Select the **DriftSleep** scheme and an iPhone
   simulator, then press **Run**.
4. For your own iPhone, choose your Apple development team in **Signing &
   Capabilities**, replace `com.drift.sleep.native` with a bundle identifier you
   control, connect your phone, and select it as the run destination. Enable
   Developer Mode on the phone if Xcode asks.

No Node, pnpm or backend process is needed to build this Swift target.

The five free WAV loops are in `DriftSleep/Resources` and are included in a
clone. Xcode picks them up through its synchronized source folder. `scripts/prepare-audio.sh`
can still download and check those files if you need to replace them.

## Features implemented in source

- Tonight: one tap for the usual sound, play/pause/resume, stop, retry and timer.
- Sounds: all 30 existing entries and category filters.
- Five free sounds use local lossless PCM and `AVAudioPlayer.numberOfLoops = -1`.
  Repetition does not depend on a network request or a seek/restart callback.
- Remaining 25 entries play bounded, non-looping previews during the free trial.
  Drift Plus customers use separate full-length tracks named
  `full-<sound-id>.mp3`; the decoder rejects a preview as a full track.
- The five free sounds stay available after the trial. The seven-day preview is
  a free, one-time StoreKit non-consumable; Drift Plus is a separate paid
  non-consumable with a restore action.
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
- NSDR and Yoga Nidra play from the bundled recordings `nsdr.mp3` and
  `yoga-nidra.mp3`. The original scripts are in `content/guided-rest`.

## Backend

The default is the published Drift API:

```text
https://one-tap-sleep-sounds.replit.app
```

This URL was obtained from the deployment service, not inferred from a preview URL.
The five free loops are bundled. Twenty paid sounds also include a bundled
`full-<sound-id>.mp3` bed. The five music sounds still use the short server
preview until a longer file is added. The upload script reads
`generated-artifacts/full-audio/full-<sound-id>.mp3`.

You can edit the full HTTPS base address in the app's **Settings → Audio server**,
or change `DriftAudioServer` in `DriftSleep/Info.plist` before building. Do not put
API keys or protection-bypass tokens in the app. Previews require an internet
connection; errors are shown instead of silently substituting another sound.

The API routes remain:

```text
GET /api/healthz
GET /api/audio/loop-v2-gentle-rain.wav
GET /api/audio/native-rain-on-glass.mp3
GET /api/audio/full-rain-on-glass.mp3
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
5. Confirm each preview ends once, and that purchased full tracks loop only when
   the Loop control is on. Verify locked content and restore using StoreKit sandbox.
6. Test font sizes, VoiceOver, narrow iPhones, saved preferences after relaunch,
   download failures and rapid play/pause/sound switching.

## App Store preparation still needed

Select a signing team and final bundle identifier. Configure `com.drift.sleep.trial7days`
as a zero-price non-consumable named **7-day Trial**, and `com.drift.sleep.plus`
as the paid non-consumable. Verify privacy disclosures against the finished
app/backend, supply screenshots and store metadata, and perform the device tests
above. Ensure trial duration, post-trial access, and the one-time price are clear
before the trial begins. The included privacy manifest declares no
tracking and local UserDefaults use; the backend may still maintain ordinary
server access logs. Review that behavior before submitting privacy answers.

No App Store submission or TestFlight upload has been performed.
