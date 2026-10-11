---
name: Native manifest verification
description: Distinguishing working web previews from valid Expo Go launch responses.
---

A working browser preview does not establish that Expo Go can launch the app. Check the native manifest response, its protocol and MIME headers, and the referenced iOS launch bundle.

**Why:** Drift's published preview and Metro used different manifest response formats even though both JSON bodies parsed successfully. iPhone launch errors can involve response negotiation rather than syntax in app.json.

**How to apply:** Fetch the actual failing endpoint with iOS Expo headers and native Accept types. Verify both multipart and plain manifest responses against Metro's format. Development preview and published preview are separate endpoints; changes to the production server only reach the published copy after the user publishes again. Run Expo Doctor after installing native modules to catch missing native peers.
