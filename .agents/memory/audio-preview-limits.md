---
name: Audio preview limits
description: Why premium audio previews must have an intrinsic duration limit on both web and native platforms.
---

Premium previews must be duration-bounded audio files with a gentle ending, not full-length tracks stopped only by a JavaScript timer. Only the five free sounds may loop in the unpaid app.

**Why:** iPhone background execution can delay JavaScript callbacks. A file-level limit prevents a short preview from becoming indefinite playback while the screen is locked.

**How to apply:** Preserve the intrinsic preview limit when changing the player, downloads, audio delivery or purchase flow. Verified purchases may receive separate full-length assets; an unverified local preference must never grant premium playback.
