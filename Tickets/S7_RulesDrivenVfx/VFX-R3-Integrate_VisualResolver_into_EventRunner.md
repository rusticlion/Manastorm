# Ticket #VFX-R3: Integrate VisualResolver into EventRunner

## Goal
Use the new `VisualResolver` to determine which VFX to trigger for gameplay events, replacing hard-coded effect look-ups in `EventRunner`.

## Tasks
1. **Modify `EventRunner.lua`:**
   * `require("systems.VisualResolver")` at the top.
   * In the `EFFECT` handler within `EventRunner.EVENT_HANDLERS`:
     * Remove old logic that directly looked at `event.effectType` / `vfxParams`.
     * Call `local baseEffectName, vfxOpts = VisualResolver.pick(event)`.
     * If `baseEffectName` is falsy, log and return (skip VFX).
     * Determine coordinates (srcX, srcY, tgtX, tgtY) based on `event.source`, `event.target`, `caster`, `target` (reuse existing helper or logic).
     * Call `VFX.createEffect(baseEffectName, srcX, srcY, tgtX, tgtY, vfxOpts)`.

2. **Review Other Event Handlers:**
   * Identify handlers that currently call `safeCreateVFX` or `VFX.createEffect` directly (e.g., `SET_ELEVATION`, shield-related logic).
   * For each, choose either:
     * (Preferred) Generate an `EFFECT` event and let the main handler process it.
     * (Interim) Call `VisualResolver.pick` directly to obtain parameters, then create the effect.
   * Document decisions in comments.

## Acceptance Criteria
* The `EFFECT` handler in `EventRunner` now exclusively relies on `VisualResolver.pick` to decide visuals.
* Visual effects for core gameplay events (damage, status, conjure, etc.) still trigger correctly in-game.
* Legacy direct VFX calls in other handlers are removed or routed through the resolver.

## Design Notes / Pitfalls
* Coordinate resolution is non-trivial; ensure consistency with previous visuals.
* Consider staging changes—first update `EFFECT` handler, then gradually refactor other direct calls. 