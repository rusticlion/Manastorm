# Manastorm VFX Refactoring: Rule-Driven System - Game Plan
**Version:** 2.0  
**Date:** Thu May 1 13:36:18 CDT 2025  
**Context:** This document outlines the plan for Sprint 2 of the VFX refactoring, focusing on implementing a rule-driven visual system.

## 1. Purpose & Problem Statement

### Goal
To refactor Manastorm's Visual Effects (VFX) system so that visuals are primarily derived from gameplay rules and metadata (affinity, attack type, visual shape, cost, tags), rather than being manually specified for every spell. This aims to improve consistency, maintainability, and designer workflow.

### Current Problem
The existing system relies heavily on manual VFX specification (vfx property or keyword) for most spells. This couples visual decisions tightly to gameplay definitions, leading to:
- **Inconsistency:** Visuals can easily mismatch a spell's element or type.
- **Maintenance Burden:** Changing a spell's affinity requires manually updating its VFX.
- **Scalability Issues:** Adding new elements/shapes requires widespread manual updates.
- **Scattered Logic:** VFX triggers are distributed, making the flow hard to follow.

## 2. Target Architecture: Rule-Driven Visuals

We are moving to a system where gameplay events imply the necessary visuals.

### Core Components & Flow:

#### Enriched Events
Gameplay keywords (damage, conjure, etc.) generate events containing rich metadata:
- **affinity:** (Fire, Moon, etc.) -> Determines Color & Motion
- **attackType:** (Projectile, Zone, etc.) -> Determines Base Structure (if visualShape absent)
- **visualShape:** (Beam, Bolt, Blast, etc.) -> Overrides Base Structure
- **manaCost:** (Number) -> Determines Scale/Intensity
- **tags:** ({ BURN=true, SHIELD=true }) -> Determines Additive Overlays (Future)
- **Context:** (rangeBand, elevation) -> Influences Trajectory/Appearance

#### VisualResolver (systems/VisualResolver.lua)
- Acts as the central mapping service.
- Takes an enriched event as input.
- Uses internal mapping tables (TEMPLATE_BY_SHAPE, BASE_BY_ATTACK, COLOR_BY_AFF, AFFINITY_MOTION) and logic (scaling by manaCost) to determine visual parameters.
- Outputs: baseTemplateName (String), opts (Table: { color, scale, motion, addons, rangeBand, elevation, particleAsset, ... }).
- Handles effectOverride as the highest priority bypass.

#### EventRunner (systems/EventRunner.lua)
- Processes all game events, including EFFECT events.
- For EFFECT events, calls VisualResolver.pick(event) to get visual parameters.
- Calls VFX.createEffect(baseTemplateName, ..., opts) to trigger the visual.

#### VFX Module (vfx.lua)
- VFX.effects registry contains primarily base templates (proj_base, beam_base, impact_base, etc.) defining structure and default particle assets.
- VFX.createEffect consumes the baseTemplateName and the opts table.
- Initializes effect instances using parameters from opts (overriding template defaults for color, scale, motion, particle asset, etc.).
- update*/draw* functions render the effect based on the instance's parameters and motion style.

### Key Principle
Define the gameplay, get consistent visuals for free. Override only when necessary.

## 3. Sprint Ticket Breakdown (VFX-S2-T1 to VFX-S2-T6)

This sprint builds the rule-driven system step-by-step:
1. **T1 (Refine Resolver):** Implement visualShape mapping in VisualResolver and clarify priority (override > shape > attackType).
2. **T2 (Decouple Assets):** Make particle/asset choice in vfx.lua data-driven via templates and opts. Remove hardcoded asset names from draw*.
3. **T3 (Consume Params):** Ensure VFX.createEffect fully uses all parameters from opts (color, scale, motion, overrides) and passes them to the effect instance.
4. **T4 (Purge Registry):** Clean VFX.effects, leaving mostly base templates and a few truly unique named effects.
5. **T5 (Motion Styles):** Fully implement the particle movement logic for different motion styles in VFX.updateParticle.
6. **T6 (Deprecate Old Specs):** Remove legacy vfx properties from spells, ensuring reliance on the resolver.

## 4. Example Flow (Post-Refactor)

1. **Spell Def:** `MySpells.AquaBlast = { affinity=WATER, attackType=ZONE, visualShape="blast", keywords={damage={...}} }`
2. **Event:** DAMAGE event generated with `{ affinity=WATER, attackType=ZONE, visualShape="blast", manaCost=3, tags={DAMAGE=true} }`
3. **EventRunner:** Processes EFFECT event derived from DAMAGE.
4. **Resolver:** VisualResolver.pick(event):
   - Sees visualShape="blast", maps to baseTemplate="zone_base".
   - Sees affinity=WATER, maps to color=OCEAN, motion=SWIRL.
   - Sees manaCost=3, calculates scale=1.25.
   - Sees tags={DAMAGE=true}, adds addon=DAMAGE_OVERLAY.
   - Returns ("zone_base", {color=OCEAN, scale=1.25, motion=SWIRL, addons={...}, ...}).
5. **VFX:** VFX.createEffect("zone_base", ..., {color=OCEAN, ...}). Renders a zone effect, tinted blue, 25% larger, with swirling particles.

## 5. Guidance & Notes

- **Focus on Base Templates:** Make proj_base, beam_base, etc., robust and parameterizable.
- **Use Constants:** Heavily rely on core/Constants.lua.
- **Incremental Testing:** Test visuals after each ticket, ensuring the resolver and VFX module interact correctly.
- **Visual Language Doc:** Refer to docs/Visual_Language.md to guide parameter choices (default particle assets, motion styles per affinity).

## 6. Conclusion

This sprint fundamentally shifts how VFX are handled, moving from manual specification to a rule-driven, metadata-based system. This will improve consistency, reduce maintenance, and make adding visually appropriate effects for new spells significantly easier.