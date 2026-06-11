# AS-3: Extract Battle Update Orchestration From `main.lua`

**Goal:** Move battle-specific update flow out of the giant `love.update(...)` branch while preserving `main.lua` as the top-level state router.

## Tasks

### 1. Identify The Battle Surface
- Audit normal battle and attract battle update branches in `main.lua`.
- Separate battle simulation from menu state, transitions, and mode glue.

### 2. Add A Battle Update Module
- Create a focused module under `systems/`.
- Prefer a narrow API such as:
  - `updateBattle(game, dt)`
  - `updateAttractBattle(game, dt)`

### 3. Extract Shared Logic
- Centralize repeated update work:
  - wizard updates
  - mana pool update
  - VFX update
  - sustained manager update
  - win checks
  - health UI bookkeeping

### 4. Preserve Runtime Behavior
- Avoid large behavior changes during this extraction.
- Keep global-state access no broader than it already is.

## Acceptance Criteria

- Battle branches in `main.lua` are materially smaller.
- Normal battle and attract battle share the same extracted update logic where appropriate.
- Core validation commands pass.

