# Ticket #VFX-S2-T4: Purge Specific Effects from VFX Registry

## Goal
Clean up the VFX.effects registry in vfx.lua, removing specific named effects and leaving only parameterized base templates.

## Background
The VFX.effects registry currently contains many specific named effect definitions (firebolt, meteor, emberlift, etc.) alongside base templates. This approach has led to code duplication and made it difficult to maintain consistency. With the VisualResolver now handling template selection and parameter generation, we can simplify by focusing on base templates.

## Tasks

### Identify Base Templates (vfx.lua)
- Clearly mark the essential base templates that should be kept:
  - proj_base
  - beam_base
  - impact_base
  - aura_base
  - util_base
  - shield_hit_base
  - vertical_base
  - conjure_base
  - Any other truly essential base templates

### Remove Specific Definitions (vfx.lua)
- Delete specific named effect entries from VFX.effects, such as:
  - firebolt
  - meteor
  - emberlift
  - conjurefire
  - tidal_force
  - shield
  - Any other effect that can be represented as a base template + parameters

### Review Constants.VFXType (core/Constants.lua)
- Review Constants.VFXType to ensure consistency with the new approach:
  - Keep constants for base templates
  - Keep constants for any truly unique effects that are maintained as overrides
  - Ensure constants are used consistently throughout the codebase

### Update Override Examples
- Identify any remaining spells using overrides
- Ensure they reference a valid Constants.VFXType value
- Document the override approach for the few cases where it's still needed

## Acceptance Criteria
- VFX.effects registry primarily contains base template definitions
- The game runs without errors related to missing effect definitions
- Spells previously using removed named effects correctly resolve to a base template via VisualResolver
- Explicit override spells (if any were kept) still function correctly

## Technical Notes
- This is a significant removal step that should be done carefully
- Thorough testing is needed to catch spells whose visuals might break
- Consider backup/documentation of removed templates before deletion
- This change simplifies the VFX system but requires all visual effects to be properly parameterized through the VisualResolver

## Dependencies
- This ticket should be implemented after VFX-S2-T1, VFX-S2-T2, and VFX-S2-T3
- Should be completed before VFX-S2-T6 (final cleanup)