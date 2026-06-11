# S16: Architecture Showcase Sprint

**Goal:** Use the pre-showtime polish window to make Manastorm's architecture cleaner, quieter, and easier to explain as a software architecture show-and-tell project.

## North Star

The interview story should be clear in one pass:

> Data-driven spell definitions are compiled into keyword behavior, emitted as combat events, resolved by an authoritative EventRunner, and interpreted into visuals by a rule-driven VisualResolver/VFX pipeline.

This sprint is not about adding more game content. It is about making that story true, legible, and demonstrable.

## Milestones

### A1. Quiet Runtime, Visible Diagnostics
- Focus: move noisy prototype traces behind `core/Log.lua` while keeping warnings and errors visible.
- Exit Criteria:
  - Normal play does not spam the terminal with routine combat, VFX, or input traces.
  - Deep diagnostics can be enabled from one obvious logging toggle.
  - Existing headless validation still passes.

### A2. Architecture Documentation That Matches The Code
- Focus: create a concise architecture one-pager and spell lifecycle trace for interview use.
- Exit Criteria:
  - The spell pipeline can be explained from one document.
  - Combat authority ownership is current and concrete.
  - Known exceptions are called out honestly instead of hidden.

### A3. Smaller Orchestration Surfaces
- Focus: reduce the size and responsibility concentration of `main.lua`, `systems/EventRunner.lua`, and `spellCompiler.lua`.
- Exit Criteria:
  - Battle update flow is delegated out of the giant `love.update` branch.
  - Event handler logic is organized by domain while `EventRunner.processEvents(...)` stays authoritative.
  - `spellCompiler.lua` no longer masks EventRunner load-order problems with a dummy fallback.

### A4. Demo-Ready Architecture Slice
- Focus: prepare one small duel scenario that proves the architecture without requiring the audience to understand every spell.
- Exit Criteria:
  - A 4-6 spell demo path shows mana, cast timing, movement/range, shields or blocks, event resolution, and VFX.
  - The repo has an interview script that links the demo to concrete code paths.
  - Validation commands are documented and green.

## Sprint Tickets

1. `AS-1`: Reduce runtime debug spam behind `core/Log.lua`.
2. `AS-2`: Create the architecture one-pager and spell lifecycle trace.
3. `AS-3`: Extract battle update orchestration from `main.lua`.
4. `AS-4`: Split `EventRunner` handlers by domain.
5. `AS-5`: Remove the compiler circular-dependency fallback.
6. `AS-6`: Prepare the demo architecture slice and interview script.

## Recommended Order

1. Start with `AS-1`; quieter logs make every later verification run easier to read.
2. Do `AS-2` early, then update it as refactors land.
3. Tackle `AS-3` before `AS-4`; it is lower risk and makes the top-level loop easier to discuss.
4. Do `AS-4` incrementally by handler domain.
5. Handle `AS-5` after the handler split clarifies the real dependency boundaries.
6. Finish with `AS-6` so the demo script reflects the cleaned-up code.

## Scope Guardrails

- Do not add new spells, characters, or mechanics during this sprint unless a ticket explicitly needs a tiny fixture.
- Prefer boring, well-tested extractions over clever rewrites.
- Preserve `EventRunner.processEvents(...)` as the combat authority boundary.
- Keep transitional exceptions documented when removing them would be risky.

## Core Validation Commands

- `lua tools/lint_spell_enums.lua`
- `lua tools/test_hardening_pipeline.lua`
- `lua tools/test_vfx_events.lua`

