# M1-2: Add Shield Regression Coverage

**Goal:** Expand combat hardening coverage around shield creation, blocking, reflect behavior, and on-block side effects.

## Tasks

### 1. Inventory Current Shield Cases
- Review existing shield-related tests in `tools/test_hardening_pipeline.lua`.
- Map those tests against current shield mechanics in:
  - `systems/ShieldSystem.lua`
  - `systems/EventRunner.lua`
  - spell definitions with `block` keywords

### 2. Add Missing Runtime Cases
- Add tests for:
  - projectile blocked by barrier
  - zone blocked by barrier
  - shield token consumption and shield break/fizzle
  - `onBlock` callback event dispatch
  - reflect-capable shield behavior, if implemented for active content

### 3. Verify Cleanup And Visual Routing
- Ensure shield-related blocked events still route through `EFFECT`.
- Confirm slot cleanup and token return/destruction behavior remain event-driven rather than direct state mutation in tests.

### 4. Keep Test Data Minimal
- Use small local spell/wizard stubs where possible.
- Only pull in real spell definitions when the interaction depends on authored content.

## Acceptance Criteria

- Shield behavior is covered by a focused cluster of headless regression tests.
- New tests describe the intended rules clearly enough to function as executable documentation.
- Test names make it obvious which shield rule failed when a regression occurs.

## Dependencies

- Can begin in parallel with M1-1, but should be finalized after the zone/barrier bug fix lands.

## Validation

- `lua tools/test_hardening_pipeline.lua`
