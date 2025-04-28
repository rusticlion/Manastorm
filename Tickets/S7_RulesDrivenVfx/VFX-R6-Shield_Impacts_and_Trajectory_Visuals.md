# Ticket #VFX-R6: Handle Shield Impacts & Basic Trajectory Visuals

## Goal
Provide clear visual feedback when shields block attacks and fine-tune projectile trajectories based on range and elevation.

## Tasks
1. **Emit Shield Hit Event (`systems/ShieldSystem.lua`):**
   * In `ShieldSystem.handleShieldBlock` (or equivalent), create an `EFFECT` event instead of direct VFX:
     ```lua
     local shieldHitEvent = {
         type        = "EFFECT",
         source      = Constants.TargetType.TARGET,  -- defender is both source & target visually
         target      = Constants.TargetType.TARGET,
         effectType  = "shield_hit", -- logical tag for VisualResolver
         affinity    = target.affinity,
         tags        = { SHIELD_HIT = true },
         shieldType  = blockInfo.blockType,
         posX        = target.x,
         posY        = target.y,
     }
     EventRunner.processEvents({ shieldHitEvent }, target, caster, blockInfo.blockingSlot)
     ```

2. **Update `VisualResolver` (`systems/VisualResolver.lua`):**
   * Add handling for `event.effectType == "shield_hit"`.
   * Map to base template `shield_hit_base` and pick color via `event.shieldType` (use helper from ShieldSystem).

3. **Add Shield Hit Template (`vfx.lua`):**
   * Define `VFX.effects["shield_hit_base"]` – quick radial burst (reuse `impactRing` sprite).

4. **Refine Trajectory Logic (`vfx.lua`):**
   * Confirm `VFX.updateProjectile` offsets source/target based on `effect.rangeBand` and `effect.elevation`.
   * Tweak numbers so visual difference is noticeable but not exaggerated.

## Acceptance Criteria
* Blocking a spell produces a colored shield hit visual at the defender.
* Projectile trajectories respect range/elevation parameters set via `opts`.

## Design Notes / Pitfalls
* Ensure shield color derives from shield type, not affinity.
* Event-based triggering keeps visuals consistent with other systems. 