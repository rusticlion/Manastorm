# M2-1: Extract Battle Update Flow From `main.lua`

**Goal:** Remove battle-specific orchestration from the giant `love.update(...)` branch and relocate it into a dedicated module with a smaller public surface.

## Tasks

### 1. Identify The Battle Update Surface
- Audit the `BATTLE` and `BATTLE_ATTRACT` branches in `main.lua`.
- Separate true battle simulation from menu flow, win-state transitions, and mode-specific glue.

### 2. Introduce A Battle State Module
- Create a dedicated module under `systems/` for battle update orchestration.
- Give it a narrow API such as:
  - `updateBattle(game, dt)`
  - `updateAttractBattle(game, dt)`
  - helper functions for win-condition checks if needed

### 3. Move Shared Battle Logic Out Of `main.lua`
- Centralize repeated logic currently duplicated between normal battle and attract battle:
  - win checks
  - timed effect updates
  - wizard updates
  - mana pool update
  - VFX update
  - sustained manager update
  - health UI update

### 4. Keep `main.lua` As The Orchestrator
- `main.lua` should still choose the current state, but it should delegate battle work instead of embedding it.
- Avoid pulling more global state into other modules while doing the extraction.

## Acceptance Criteria

- The battle-state branches in `main.lua` are materially smaller and mostly delegating.
- Shared battle logic is not duplicated between `BATTLE` and `BATTLE_ATTRACT`.
- Runtime behavior remains unchanged aside from the structural cleanup.

## Dependencies

- Recommended after M1 combat hardening so behavior is stable during the extraction.
