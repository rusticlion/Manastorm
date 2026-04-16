# M1-5: Add A Combat Smoke Script

**Goal:** Provide a single command that runs the core headless checks needed to trust combat, spell, and visual pipeline changes.

## Tasks

### 1. Define The Smoke Suite
- Include:
  - `lua tools/lint_spell_enums.lua`
  - `lua tools/test_hardening_pipeline.lua`
  - `lua tools/test_vfx_events.lua`

### 2. Create A Wrapper Script
- Add a small script under `tools/` that runs the suite and exits non-zero on failure.
- Keep output compact and readable enough for frequent local use.

### 3. Document Usage
- Add the smoke command to `README.md` or another obvious developer entry point.
- Note when contributors should run it:
  - after combat rule changes
  - after spell content changes
  - after VFX pipeline changes

### 4. Make Failures Actionable
- Preserve individual tool output so the failing area is obvious.
- Avoid hiding which underlying command failed.

## Acceptance Criteria

- One command runs the core combat verification suite.
- The smoke script is documented and easy to remember.
- Developers can use it as the default pre-commit sanity check for gameplay work.

## Dependencies

- Best completed after M1-2 and M1-3 so the smoke suite captures the expanded test surface.
