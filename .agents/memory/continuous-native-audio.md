---
name: Continuous native audio
description: Why free sleep sounds use locally saved lossless loops instead of repeating streamed MP3 files.
---

Use complete, locally saved lossless PCM audio for free native sleep sounds, with a native queue handling repeats. Avoid introductory/outro fades in the repeating section, and do not implement repeats with JavaScript seek/replay timers.

**Why:** The user reported “Sound stop and restart... I don't want that pause.” Native repeated streaming can require buffering at each transition, and compressed files can introduce padding. A small one-time preparation delay is preferable to recurring interruptions during sleep.

**How to apply:** Preserve download-before-play and codec-level continuity when changing the player or audio format. Version improved assets so old cached files cannot silently retain the problem. Keep existing files until replacements finish successfully. User-selected sleep timers and intrinsically bounded premium previews are intentional stops, not loop gaps.

Lossless audio files are larger than the previous previews. Prefer resumable uploads for these assets.

**Why:** A buffered upload stalled during the PCM asset transfer; chunked resumable transfers completed. This is not evidence of a particular maximum file-size limit.

**How to apply:** Choose an upload strategy suitable for larger audio files without assuming a stalled transfer means credentials are missing.
