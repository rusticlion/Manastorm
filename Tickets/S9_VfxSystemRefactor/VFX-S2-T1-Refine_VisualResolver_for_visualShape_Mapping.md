# Ticket #VFX-S2-T1: Refine VisualResolver for visualShape Mapping

## Goal
Make the VisualResolver prioritize visualShape over attackType for selecting the base VFX template and centralize this mapping logic.

## Background
The VisualResolver currently relies primarily on attackType to determine the base VFX template. We want to shift toward using the visualShape property as the primary determinant, which will allow for more consistent and intuitive visual effects based on the spell's shape rather than its combat mechanics.

## Tasks

### Define Mapping Table (VisualResolver.lua)
- Create a private table `TEMPLATE_BY_SHAPE` mapping visualShape strings (e.g., "beam", "bolt", "blast") to Constants.VFXType base template names
- Include all shapes from docs/visualShape.md
- Example mapping:
  - "beam" -> Constants.VFXType.BEAM_BASE
  - "bolt" -> Constants.VFXType.PROJ_BASE
  - "blast" -> Constants.VFXType.IMPACT_BASE
  - etc.

### Modify VisualResolver.pick(event)
- Implement priority logic for determining baseTemplate:
  1. Check event.effectOverride first
  2. If no override, check event.visualShape and look it up in TEMPLATE_BY_SHAPE
  3. If no match or no visualShape, fall back to BASE_BY_ATTACK[event.attackType]
  4. If still no match, use DEFAULT_BASE
- Ensure the rest of the function (color, scale, motion, addons) uses the final resolved baseTemplate consistently
- Add debug prints to clearly show which logic path (override, shape, attackType, default) determined the baseTemplate

## Acceptance Criteria
- VisualResolver.pick correctly uses event.visualShape to determine the base template when present
- The fallback logic to attackType and default still works correctly
- Debug logs clearly indicate the selection path
- Spells defined with visualShape (e.g., Full Moon Beam) now use the corresponding base template according to the new mapping table

## Technical Notes
This change isolates the shape-to-template logic, making it easier to manage and extend visualShape support. The refactoring should maintain backward compatibility with spells that don't yet have visualShape defined.

## Dependencies
- Requires Constants.VFXType to be properly defined
- Should be implemented before other VFX system refactoring tickets