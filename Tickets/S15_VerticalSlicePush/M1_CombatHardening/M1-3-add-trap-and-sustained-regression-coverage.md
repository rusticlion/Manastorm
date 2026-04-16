# M1-3: Add Trap And Sustained Regression Coverage

**Goal:** Make sustained spells trustworthy by expanding regression coverage around trap triggers, sustained slot registration, and cleanup behavior.

## Tasks

### 1. Review The Current Sustained Flow
- Trace how sustained spells move through:
  - `spellCompiler.lua`
  - `systems/EventRunner.lua`
  - `systems/SustainedSpellManager.lua`
- Confirm where trap triggers, field statuses, and slot cleanup are currently adjudicated.

### 2. Add Missing Trap Tests
- Add or extend tests covering:
  - `REGISTER_SUSTAINED` for traps
  - `CAST_COMPLETE` -> trap notification flow
  - elevation/range-based trap triggers
  - trap payload execution through `TRIGGER_TRAP`
  - cleanup after trap resolution

### 3. Add Missing Sustained Field Tests
- Cover field status application and removal for sustained non-trap effects.
- Verify sustained slots remain active when intended and reset when intended.

### 4. Verify Slot And Token Lifecycle
- Ensure sustained cleanup continues to respect event-driven slot cleanup rather than direct ad hoc mutation.
- Confirm token return/destruction behavior is explicit in test assertions.

## Acceptance Criteria

- Trap and sustained interactions are represented by clear regression tests.
- Trigger timing and cleanup behavior are captured in tests instead of tribal knowledge.
- Future changes to traps or sustained slots have an immediate safety net.

## Validation

- `lua tools/test_hardening_pipeline.lua`
