# M1-1: Fix Barrier Handling For Zone Spells

**Goal:** Resolve the known rules bug where Barrier-style shields fail to stop zone spells that they are intended to block.

## Context

- Known issue recorded in `docs/Bugs.md`: `Zone spells not blocked by Barriers - found with Eruption vs. Wrap in Moonlight`
- This is a core trust problem for the combat model and should be fixed before broader playtesting.

## Tasks

### 1. Reproduce The Bug
- Confirm the current failing interaction using the relevant spell pair:
  - `eruption` / `Molten Ash`
  - `wrapinmoonlight` / `Wings of Moonlight`
- Trace the flow through:
  - `systems/ShieldSystem.lua`
  - `systems/EventRunner.lua`
  - any blocked-cast helpers under `systems/wizard/`

### 2. Fix Shield Evaluation For Zone Attacks
- Ensure barrier block checks look at the actual incoming spell attack type and route zone spells through the same authoritative shield/block flow as projectile spells.
- Preserve existing reflect and `onBlock` behavior for attacks that are still validly blocked.

### 3. Add Regression Coverage
- Extend `tools/test_hardening_pipeline.lua` with at least one failing-then-passing test covering the zone-vs-barrier case.
- Verify the blocked flow still cleans up or preserves slot/token state correctly.

### 4. Update Bug Tracking
- Remove or mark the issue as resolved in `docs/Bugs.md` once the fix lands.

## Acceptance Criteria

- A Barrier that claims to block zone attacks actually blocks them in runtime behavior.
- The zone-vs-barrier interaction is covered by a headless regression test.
- No existing shield regression in `tools/test_hardening_pipeline.lua` breaks as a result.

## Validation

- `lua tools/test_hardening_pipeline.lua`
- `lua tools/test_vfx_events.lua`
