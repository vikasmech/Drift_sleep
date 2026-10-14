---
name: GitHub authentication checks
description: Distinguishing connected GitHub metadata from working workspace CLI authentication.
---

Verify GitHub API access through the intended execution path before creating a repository or claiming code was pushed.

**Why:** The source-control integration reported an active, healthy OAuth connection with repository permissions, but GitHub CLI requests through both shell execution interfaces returned an authentication-required error.

**How to apply:** Treat connection status as metadata, not proof that an upload can succeed. Confirm a cheap authenticated read first, and distinguish authentication failures from repository permissions or a nonexistent remote. Do not claim that reconnecting has fixed access until a request actually succeeds.
