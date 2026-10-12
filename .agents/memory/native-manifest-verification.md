---
name: Native manifest verification
description: Distinguishing working web previews from valid Expo Go launch responses.
---

A working browser preview does not establish that Expo Go can launch the app. Check the native manifest response, its protocol and MIME headers, and the referenced iOS launch bundle.

**Why:** Drift's published preview and Metro used different manifest response formats even though both JSON bodies parsed successfully. iPhone launch errors can involve response negotiation rather than syntax in app.json.

**How to apply:** Fetch the actual failing endpoint with iOS Expo headers and native Accept types. Verify both multipart and plain manifest responses against Metro's format. Development preview and published preview are separate endpoints; changes to the production server only reach the published copy after the user publishes again. Run Expo Doctor after installing native modules to catch missing native peers.

Check the preview panel's privacy warning before changing manifest code.

**Why:** An iOS simulator reported malformed manifest JSON while the manifest and bundle fetched successfully from the workspace. The user's screenshot showed “Private preview is on” and explicitly warned that private previews are unsupported in Expo Go and simulators.

**How to apply:** When that warning is present, ask the user to turn off private preview and reload the simulator. Explain that anyone with the preview URL can then access the app. Do not change privacy settings without informed consent or treat a workspace-side HTTP check as proof that the simulator can access the same response.
