# Ticket #VFX-R4: Adapt VFX Module for Resolver Output & Motion Styles

## Goal
Update the `vfx.lua` system to consume the generic templates and option table produced by `VisualResolver`, while introducing motion styles and improved scaling/trajectory logic.

## Tasks
1. **Define Motion Styles (`core/Constants.lua`):**
   * Add `Constants.MotionStyle` enum with `RADIAL`, `SWIRL`, `HEX`, `SPIRAL`, `TWINKLE`.

2. **Create Base Templates (`vfx.lua`):**
   * Ensure `VFX.effects` includes `proj_base`, `beam_base`, `impact_base`, `aura_base`, and `shield_hit_base` with minimal defaults.

3. **Modify `VFX.createEffect` (`vfx.lua`):**
   * Accept `opts` table as the last parameter.
   * Apply `opts.color` as tint; `opts.scale` to particle counts, sizes, radii; store `opts.motion`, `opts.rangeBand`, `opts.elevation` on the effect instance.
   * If `opts.addons` exists, iterate and (initially) `print("TODO addon", addon)` – full addon support comes later.

4. **Implement Motion Styles:**
   * In `VFX.initializeParticles`, store `effect.motion` onto each particle (`p.motion`).
   * Extend `VFX.updateParticle` (or create if absent) with branching logic for each motion style:
     * `RADIAL`: linear outward velocity.
     * `SWIRL`: tangential swirl using sine/cosine.
     * `HEX`: hex-grid jitter (approx via snapped angles).
     * `SPIRAL`: particles accelerate outward in a spiral.
     * `TWINKLE`: oscillating alpha/scale.

5. **Refine Basic Trajectory:**
   * In `VFX.updateProjectile`, adjust start/end Y positions based on `effect.rangeBand` (`NEAR`, `FAR`) and `effect.elevation` (`GROUNDED`, `AERIAL`). Simple offsets are fine.

## Acceptance Criteria
* `VFX.createEffect` consumes `opts` correctly.
* Particles move following the selected motion styles.
* Projectiles visually differentiate between range bands and elevations.
* Addon list is logged for future work.

## Design Notes / Pitfalls
* Math heavy work—validate with debug visuals.
* Keep default behaviors identical to previous visuals until options provided. 