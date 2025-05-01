# Ticket #VFX-S2-T6: Deprecate Old VFX Specifications & Final Cleanup

## Goal
Remove remaining legacy ways of specifying VFX in spell definitions and ensure the codebase relies solely on the VisualResolver (plus explicit overrides via vfx keyword where necessary).

## Background
Currently, spells can specify visual effects in multiple ways, including a top-level vfx property and through the vfx keyword. This ticket aims to standardize on using the rule-driven VisualResolver, with overrides only as exceptions.

## Tasks

### Remove Top-Level vfx Properties
- Search all spell definition files (spells/*.lua) for top-level vfx = "effect_name" properties
- Remove these properties, instead relying on:
  - affinity (for color)
  - attackType (as fallback)
  - visualShape (as primary determinant)
- Example:
  ```lua
  -- Before
  {
    name = "Fire Bolt",
    affinity = "fire",
    attackType = Constants.AttackType.PROJECTILE,
    vfx = "firebolt", -- Remove this line
    -- Add this if not already present
    visualShape = "bolt",
    -- other properties
  }
  ```

### Review vfx Keyword Usage
- Examine all uses of the vfx keyword in spell definitions
- Remove most instances, relying on the resolver instead
- Keep only those intended as explicit overrides for unique spells:
  ```lua
  -- Example of a valid override that should be kept
  keywords = {
    vfx = { effectOverride = Constants.VFXType.METEOR } -- Intentional override for unique appearance
  }
  ```

### Code Search & Cleanup
- Search the codebase for any remaining logic that might read spell.vfx directly
- Look for instances in EventRunner, keywords.lua, and wizard.lua
- Remove or refactor these instances to use the VisualResolver

### Documentation Update
- Update docs/spellcasting.md to reflect that VFX are now primarily rule-driven
- Add or update documentation about visualShape's role in determining VFX
- Example addition:
  ```markdown
  ## Visual Effects
  
  Spell visual effects are now primarily determined through rule-based resolution using:
  
  1. **visualShape**: The primary determinant of effect type (beam, bolt, blast, etc.)
  2. **affinity**: Determines color and particle motion style
  3. **attackType**: Used as fallback when visualShape is not specified
  
  Manual specification via the `vfx` keyword should only be used for exceptional cases where 
  a completely unique visual effect is required.
  ```

## Acceptance Criteria
- No spells use the top-level vfx property
- The vfx keyword is used sparingly, only for intentional overrides
- The game relies on the VisualResolver for the vast majority of spell VFX
- Codebase is cleaner, with fewer ways to specify or trigger VFX
- Documentation accurately reflects the new standard

## Technical Notes
- This is the final cleanup step in the VFX refactoring process
- After this ticket, the visual effects system should be fully rule-driven
- Consider running tests with various spells to ensure visuals still appear correctly

## Dependencies
- This ticket should be implemented last, after all other VFX system refactoring tickets