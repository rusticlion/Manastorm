# Ticket #VFX-S2-T2: Decouple Particle Assets in VFX Module

## Goal
Remove hardcoded particle asset names from vfx.lua's draw* functions, making particle choice data-driven via templates and options.

## Background
Currently, the vfx.lua module has hardcoded asset names in its drawing functions, limiting flexibility and making it difficult to vary particle appearances based on spell properties. This refactoring will make the particle asset selection configurable through templates and options.

## Tasks

### Add Default Assets to Templates (vfx.lua)
- For each base template definition in VFX.effects (e.g., proj_base, impact_base), add a defaultParticleAsset field
- Example changes:
  ```lua
  VFX.effects = {
    proj_base = {
      -- existing properties
      defaultParticleAsset = "sparkle",
      defaultGlowAsset = "fireGlow",
    },
    impact_base = {
      -- existing properties
      defaultParticleAsset = "sparkle",
    },
    -- other templates
  }
  ```
- Consider adding fields for secondary assets if needed (e.g., defaultGlowAsset)

### Modify VFX.createEffect (vfx.lua)
- When processing the opts table, look for optional opts.particleAsset (and opts.glowAsset, etc.)
- Store the chosen asset key on the effect instance:
  ```lua
  effect.particleAssetKey = opts.particleAsset or template.defaultParticleAsset
  effect.glowAssetKey = opts.glowAsset or template.defaultGlowAsset
  ```

### Update draw* Functions (vfx.lua)
- Modify functions like drawProjectile, drawImpact, drawAura etc.
- Replace direct asset references:
  ```lua
  -- Before
  local particleImage = getAssetInternal("fireParticle")
  
  -- After
  local particleImage = getAssetInternal(effect.particleAssetKey)
  ```
- Handle cases where an asset might be missing gracefully
- Update logic for glow images and impact rings similarly

## Acceptance Criteria
- Base templates in vfx.lua define default particle/glow asset keys
- VFX.createEffect stores the correct asset key based on options or template defaults
- draw* functions dynamically load assets using the stored key via getAssetInternal
- Visual effects render using the particle assets defined by their templates (no visual change expected yet, just refactoring)

## Technical Notes
- Ensure getAssetInternal handles nil paths gracefully
- Consistent naming of asset keys is important
- This change will enable future improvements where particle appearance can be determined by spell properties

## Dependencies
- This change should be implemented after VFX-S2-T1 since it builds on the template selection logic