# S15: Vertical Slice Push

**Goal:** Convert Manastorm from a promising late prototype into a polished, test-backed vertical slice that is ready for broader external playtesting.

## Milestones

### M1. Combat Hardening
- Focus: rules correctness, regression coverage, and stable developer validation.
- Exit Criteria:
  - Known combat edge cases are fixed or captured by tests.
  - Shield, trap, sustained, and cleanup interactions have headless regression coverage.
  - A single smoke command runs the core verification scripts.

### M2. Architecture Cleanup
- Focus: reduce the amount of orchestration concentrated in `main.lua`, `wizard.lua`, and `systems/EventRunner.lua`.
- Exit Criteria:
  - Battle update flow is no longer embedded directly in the giant `love.update` branch.
  - Spell queueing/token prep is extracted from `Wizard:queueSpell`.
  - Event handlers are split by domain while preserving `EventRunner.processEvents(...)` as the combat authority boundary.

### M3. Readability And Feel
- Focus: make combat exchanges legible and satisfying for non-authors.
- Exit Criteria:
  - Players can quickly tell when an effect was blocked, fizzled, frozen, grounded, or trap-triggered.
  - Spell text is consistent and player-facing.
  - Core VFX, SFX, and baseline animation support the intended combat readability.

### M4. Demo Slice
- Focus: package a constrained but compelling version of the game around a polished roster.
- Exit Criteria:
  - Only finished characters and content are exposed in the demo flow.
  - Four polished wizards support solo play, attract mode, and guided first-session onboarding.
  - External playtests produce structured findings that feed the next balancing pass.

## Recommended Order

1. Finish all M1 tickets.
2. Complete M2-1 through M2-4 before adding major new content.
3. Execute M3-1 and M3-2 before the heavier polish work in M3-3 through M3-5.
4. Start M4 only after M1 and the bulk of M2 are complete.

## Demo Scope Guardrails

- Limit the playable roster to four polished wizards.
- Prefer improving existing spell clarity and matchup quality over adding new mechanics.
- Keep unfinished characters, placeholder loadouts, and partially communicated rules out of the primary demo loop.

## Core Validation Commands

- `lua tools/lint_spell_enums.lua`
- `lua tools/test_hardening_pipeline.lua`
- `lua tools/test_vfx_events.lua`

These should remain green throughout S15 and should be extended whenever a ticket changes combat rules or the spell/VFX pipeline.
