# M3-5: Raise Baseline Character Animation Quality

**Goal:** Improve baseline character motion so the active roster feels deliberate rather than placeholder-driven during combat.

## Tasks

### 1. Audit Current Animation Coverage
- Review the current state of:
  - idle frames
  - cast frames
  - position/elevation-specific variants
- Compare the active roster against the expectations in `docs/VerticalSliceMustHaves.md`.

### 2. Set The Minimum Demo Bar
- Define what counts as “good enough” for the demo slice, for example:
  - stable idle coverage for the active roster
  - readable cast pose timing
  - no glaring missing-frame fallback behavior in active characters

### 3. Improve Runtime Presentation
- Tighten sprite switching, positional animation selection, and timing behavior in the character rendering path.
- Remove obviously rough fallback behavior where it hurts the most.

### 4. Coordinate With Roster Scope
- Do not over-polish unfinished or cut characters before the demo roster is locked.
- Focus animation effort where it will actually ship in M4.

## Acceptance Criteria

- The active roster has a credible animation baseline for the vertical slice.
- Character motion supports combat readability instead of distracting from it.
- Obvious placeholder/fallback animation behavior is reduced in the shippable flow.

## Dependencies

- Strongly coupled with M4-1 roster locking.
