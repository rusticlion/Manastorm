# M1-4: Reduce Runtime Debug Spam Behind A Single Toggle

**Goal:** Make normal gameplay logs readable while preserving deep diagnostics behind one explicit debug switch.

## Tasks

### 1. Inventory Current Runtime Spam
- Review noisy `print(...)` usage in:
  - `spellCompiler.lua`
  - `wizard.lua`
  - `systems/EventRunner.lua`
  - `systems/ShieldSystem.lua`
  - VFX effect modules with always-on debug traces

### 2. Define A Consistent Logging Rule
- Route verbose diagnostics through `core/Log.lua` or an equivalent single-toggle mechanism.
- Keep unconditional prints only for true warnings/errors that should appear in normal play.

### 3. Convert High-Volume Traces
- Move compiler/event/shield debug statements behind the toggle.
- Remove stale one-off debug strings that no longer support active workflows.

### 4. Preserve Targeted Debugging
- Keep it easy to enable verbose traces for:
  - spell compilation
  - event processing
  - blocked cast/shield interactions
  - VFX resolver/effect debugging

## Acceptance Criteria

- Running the game in normal mode does not spam the terminal with routine combat traces.
- Developers can still turn on deep logging from one obvious place.
- Warnings and errors remain visible without enabling verbose mode.

## Dependencies

- Should happen before external playtests and before adding new instrumentation.
