# M3-4: Add The First Real SFX Pass

**Goal:** Establish a baseline sound layer that makes casting, blocking, hitting, canceling, and triggering traps feel materially more alive.

## Tasks

### 1. Define The Minimum SFX Surface
- Prioritize:
  - spell queue/cast
  - hit confirm
  - shield block
  - spell cancel/disjoint
  - mana conjure/consume
  - trap trigger

### 2. Audit Current Audio Hook Points
- Review current sound fields and playback paths in:
  - spell definitions
  - VFX/effect creation flow
  - asset loading/preloading utilities

### 3. Implement Reliable Playback Hooks
- Make sure the first pass is dependable before it is broad.
- Avoid scattering ad hoc sound calls everywhere; keep playback tied to stable combat or VFX events where possible.

### 4. Add Asset And Loading Support
- Route new sound assets through the existing cache/preload flow.
- Ensure the first use of common combat sounds does not hitch.

## Acceptance Criteria

- Core combat actions have audible feedback.
- Audio playback uses the repo’s asset management path instead of direct one-off loads.
- The game feels materially better even before a full sound design pass.

## Dependencies

- Pairs well with M3-1 and M3-3; should land before demo-focused external playtests.
