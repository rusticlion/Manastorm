# M3-1: Finish The "Why Did That Happen?" Feedback Pass

**Goal:** Make the cause of major combat outcomes legible enough that a non-author can explain the last exchange without opening the code.

## Tasks

### 1. Identify Opaque Outcomes
- Audit the player-facing clarity of:
  - blocked spells
  - fizzled spells
  - frozen slots
  - grounded/elevated targets
  - trap-triggered effects
  - sustained field effects

### 2. Add Clear In-Match Feedback
- Improve the existing battlefield/UI feedback in:
  - `ui.lua`
  - `systems/WizardVisuals.lua`
  - `systems/SustainedIndicatorRenderer.lua`
- Favor short, readable battlefield cues over large abstract HUD additions.

### 3. Align Visuals With Rules
- Ensure the feedback appears at the moment the underlying event resolves.
- Reuse existing event/VFX routing where possible instead of introducing side-channel UI hacks.

### 4. Playtest For Explanation Quality
- Run quick internal checks asking: “Can I explain why that spell failed or succeeded in one sentence?”
- Capture any still-opaque interactions for follow-up tickets if needed.

## Acceptance Criteria

- Major combat outcomes have clear player-facing cues.
- Visual feedback aligns with actual rules timing rather than delayed or misleading presentation.
- Internal playtests surface fewer “what just happened?” moments.

## Dependencies

- Best started after M1 and once M2 has reduced the chance of behavior shifting underneath the feedback pass.
