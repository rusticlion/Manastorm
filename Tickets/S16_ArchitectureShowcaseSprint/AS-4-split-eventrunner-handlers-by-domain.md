# AS-4: Split `EventRunner` Handlers By Domain

**Goal:** Keep `EventRunner.processEvents(...)` as the authoritative combat entry point while moving handler implementation details into smaller domain modules.

## Tasks

### 1. Define Handler Domains
- Use domains that match the combat model:
  - damage and status
  - range and movement
  - tokens and resources
  - shields and defense
  - sustained spells and traps
  - visuals and effects

### 2. Move One Domain At A Time
- Extract handlers into `systems/event_handlers/`.
- Compose the exported handler tables back into `EventRunner.EVENT_HANDLERS`.
- Keep each step small enough to validate independently.

### 3. Preserve Authority
- `EventRunner` still owns event ordering, result aggregation, nested event batches, and handler dispatch.
- Handler modules should not become independent event runners.

### 4. Preserve Testability
- Existing tool tests should still exercise the same combat path.
- Add focused coverage if an extraction reveals an untested edge case.

## Acceptance Criteria

- `systems/EventRunner.lua` is easier to navigate.
- Handler logic is organized by domain.
- Event processing behavior remains unchanged.
- Core validation commands pass after each extraction step.

