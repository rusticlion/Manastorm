# AS-1: Reduce Runtime Debug Spam Behind `core/Log.lua`

**Goal:** Make normal gameplay and tool runs readable by routing verbose diagnostics through the existing `core/Log.lua` toggle.

## Tasks

### 1. Inventory High-Volume Prints
- Review noisy `print(...)` usage in:
  - `spellCompiler.lua`
  - `wizard.lua`
  - `systems/EventRunner.lua`
  - `systems/ShieldSystem.lua`
  - `systems/VisualResolver.lua`
  - `vfx.lua`
  - `vfx/effects/`
  - `core/Input.lua`

### 2. Keep Real Problems Visible
- Leave warnings and errors visible when they represent actionable problems.
- Convert routine state traces, lifecycle breadcrumbs, and VFX call dumps to `Log.debug(...)`.

### 3. Prefer One Logging Surface
- Use `core/Log.lua` for verbose logging.
- Avoid adding local debug flags unless a subsystem already has a clearly scoped public debug mode.

### 4. Validate Behavior
- Run the core validation commands.
- Check that the converted files still load in headless Lua.

## Acceptance Criteria

- Routine combat, compiler, input, and VFX traces are hidden unless verbose logging is enabled.
- Warnings and errors remain visible in normal mode.
- `Log.setVerbose(true)` restores deep diagnostic output.
- Existing validation commands pass.

## Notes

- This is intentionally low-risk and high-leverage. It makes the codebase feel more deliberate before deeper extraction work begins.

## Progress

- First high-volume logging pass complete.
- Routine compiler, wizard, shield, sustained, trap, input, EventRunner, VisualResolver, and core VFX traces now route through `core/Log.lua`.
- Warnings, errors, and explicit diagnostic helper output remain visible.
- Core validation commands are green after the pass.

## Remaining Follow-Up

- Continue the broader repo-wide `print(...)` audit opportunistically as later architecture tickets touch `main.lua`, `manapool.lua`, and remaining UI/debug routes.
