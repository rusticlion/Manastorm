# M2-3: Split `EventRunner` Handlers By Domain

**Goal:** Preserve `EventRunner.processEvents(...)` as the authoritative combat entry point while moving handler implementations into smaller domain modules.

## Tasks

### 1. Define Handler Domains
- Split current handlers into coherent groups such as:
  - damage/status
  - range/movement
  - resources/tokens
  - shields/defense
  - sustained/traps
  - visuals/effects

### 2. Create Domain Modules
- Add modules under `systems/event_handlers/`.
- Export handler tables or registration helpers that `EventRunner.lua` can compose.

### 3. Keep Combat Authority Centralized
- `EventRunner.processEvents(...)` should still own:
  - event ordering
  - result aggregation
  - nested/deferred event batch handling
- Do not turn the split into multiple competing event runners.

### 4. Preserve Testability
- Maintain the ability to call handlers headlessly from `tools/test_hardening_pipeline.lua`.
- Keep file-level coupling low enough that individual domains can be read in isolation.

## Acceptance Criteria

- `systems/EventRunner.lua` is materially smaller and easier to navigate.
- Handler logic is organized by domain rather than by one huge monolithic table.
- Existing combat tests still pass after the split.

## Dependencies

- Strongly recommended after M1 hardening so handler behavior is locked in before moving code around.

## Validation

- `lua tools/test_hardening_pipeline.lua`
- `lua tools/test_vfx_events.lua`
