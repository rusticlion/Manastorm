# Combat Authority

This document defines which layer is allowed to change combat state in Manastorm.

## Goal

Combat bugs have mostly come from state being mutated in multiple places with overlapping timing rules. The fix is not more conditionals. The fix is a clear authority boundary.

The intended rule is:

- Keywords describe effects by emitting events.
- The spell compiler gathers those events.
- The event runner applies combat state changes.
- Other systems may decide when to emit events, but should avoid directly mutating combat state.

## Authority Rules

### EventRunner is authoritative for combat resolution

`systems/EventRunner.lua` is the source of truth for:

- health changes
- status application
- range and elevation changes
- token locking, shifting, dissipation, and consumption
- spell timing changes
- shield creation

If a gameplay effect can affect match outcome, it should be represented as an event and resolved there.

### Wizard owns local lifecycle, not combat outcomes

`wizard.lua` should own:

- input-facing state
- keyed spell selection
- slot occupancy and slot reset
- cast progress bookkeeping
- local animation timers
- delegating queued spells into the event pipeline

`Wizard` should not be the place where ongoing combat effects independently decide damage, defeat, or status resolution.

### Sustained systems emit or schedule, they do not adjudicate

`systems/SustainedSpellManager.lua`, `systems/ShieldSystem.lua`, and related helpers may:

- track active sustained entries
- decide when a trap or field should trigger
- prepare metadata or callbacks
- request cleanup for slot/token lifecycle

They should avoid directly applying combat results that belong in the event layer.

### Visual systems read combat state, they do not define it

`systems/VisualResolver.lua`, `vfx.lua`, and related effect renderers should:

- derive visuals from events and spell metadata
- preserve timing hooks such as `onComplete`
- never become the place where gameplay is decided

## Current Hotspots To Migrate

These are the main places where the repo still violates or blurs the authority boundary:

- `wizard.lua`
  - blocked-cast timing still has local queue state, but cleanup now resolves through `CLEANUP_SLOT`
  - update/cast orchestration remains a coordinator; cast completion now emits `CAST_COMPLETE` instead of directly notifying trap systems
- `systems/SustainedSpellManager.lua`
  - trap state still lives here, but trigger dispatch now depends on explicit runtime signals instead of per-frame polling
- `systems/ShieldSystem.lua`
  - shield detection still lives here, but resolution should stay limited to emitting shield events into `EventRunner`
- `systems/EventRunner.lua`
  - gameplay handlers should keep routing visuals through `EFFECT`; the final `EFFECT` handler remains the only place that should talk to `vfx.createEffect`

## Near-Term Migration Order

1. Keep `EFFECT` as the single VFX boundary in combat code; new gameplay handlers should emit `EFFECT` instead of talking to `vfx` directly.
2. Keep `wizard.lua` as a thin coordinator and push any new lifecycle branches into helper modules or event handlers.
3. Continue tightening sustained-spell bookkeeping so more trigger types can be expressed without custom manager logic.

## Practical Rule For New Work

When adding or debugging a mechanic, ask:

1. What event describes this outcome?
2. Which system emits that event?
3. Does any other module still apply the same outcome directly?

If the answer to question 3 is yes, that overlap should be treated as technical debt and a likely bug source.
