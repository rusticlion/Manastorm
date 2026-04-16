# M2-2: Extract Wizard Spell Queueing

**Goal:** Pull spell queueing, cost resolution, token acquisition, and slot initialization out of `Wizard:queueSpell(...)` into a focused helper module.

## Tasks

### 1. Define The Queueing Boundary
- Audit `Wizard:queueSpell(...)` in `wizard.lua`.
- Separate responsibilities into:
  - spell resolution/compilation lookup
  - affordability and dynamic cost evaluation
  - token acquisition/prep
  - slot initialization and cast-time setup

### 2. Create A Wizard Queue Helper Module
- Add a helper module under `systems/wizard/`.
- Expose a small entry point that takes the wizard, target spell, and queue slot context and returns success/failure plus any needed slot payload.

### 3. Preserve Existing Behavior
- Maintain support for:
  - static costs
  - dynamic `getCost(...)`
  - dynamic `getCastTime(...)`
  - Slow status interaction
  - shield preparation and token handling

### 4. Keep `Wizard` Thin
- `Wizard:queueSpell(...)` should remain the public API used by player input and AI.
- The method should mostly validate, delegate, and update wizard-local state rather than embedding all queue mechanics.

## Acceptance Criteria

- `Wizard:queueSpell(...)` is substantially smaller and easier to read.
- Queueing behavior for existing spells is preserved.
- The new helper module is cohesive enough to support future queueing-related features without growing `wizard.lua` again.

## Dependencies

- Recommended after M2-1 and before deeper battle/system feature work.
