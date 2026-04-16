# M2-5: Document The Combat Authority Boundary

**Goal:** Bring the combat authority docs fully in sync with the post-refactor code so future work does not reintroduce overlapping state mutation.

## Tasks

### 1. Reconcile Docs With The Current Runtime
- Re-read:
  - `docs/combat_authority.md`
  - `docs/combat_events.md`
  - `CrashCourse.md`
  - `DevelopmentGuidelines.md`
- Compare their rules against the current post-M2 implementation.

### 2. Update Ownership Rules
- Clearly document which layer owns:
  - combat outcomes
  - slot lifecycle
  - token lifecycle
  - sustained bookkeeping
  - visual dispatch

### 3. Call Out Known Exceptions
- If there are still transitional exceptions, document them explicitly rather than implying purity that the code does not yet enforce.

### 4. Add Practical Guidance
- Include short rules for contributors adding new mechanics:
  - what event should represent the outcome
  - where that event should be emitted
  - where direct mutation is still acceptable vs. prohibited

## Acceptance Criteria

- The docs accurately describe the implemented combat authority boundary.
- A contributor can read the docs and know where to put new combat logic.
- The updated docs reduce the chance of logic drifting back into ad hoc state mutation.

## Dependencies

- Should be completed after the main M2 refactors, not before.
