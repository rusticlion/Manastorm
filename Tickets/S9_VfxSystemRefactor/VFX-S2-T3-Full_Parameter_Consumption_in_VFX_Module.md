# Ticket #VFX-S2-T3: Full Parameter Consumption in VFX Module

## Goal
Ensure VFX.createEffect and the corresponding update*/draw* functions fully utilize the parameters provided in the opts table from the VisualResolver.

## Background
Currently, the VFX module only partially consumes parameters from the opts table produced by the VisualResolver. This ticket aims to enhance parameter utilization to allow for more nuanced control over visual effects based on spell properties.

## Tasks

### Enhance VFX.createEffect (vfx.lua)
- Explicitly read and store all relevant parameters from the opts table:
  ```lua
  -- Read and store all parameters from opts
  effect.color = opts.color or template.defaultColor
  effect.scale = opts.scale or 1.0
  effect.motion = opts.motion or template.defaultMotion or Constants.MotionStyle.DEFAULT
  effect.duration = opts.duration or template.duration
  effect.particleCount = opts.particleCount or template.particleCount
  effect.rangeBand = opts.rangeBand -- for trajectory calculation
  effect.elevation = opts.elevation -- for trajectory calculation
  effect.addons = opts.addons or {} -- for future extensions
  ```
- Apply opts.scale more comprehensively:
  - Define scaling rules for different properties (radius, beamWidth, height, impactSize)
  - Example: 
    ```lua
    effect.radius = template.radius * effect.scale
    effect.beamWidth = template.beamWidth * effect.scale
    effect.particleSize = template.particleSize * math.sqrt(effect.scale) -- Non-linear scaling option
    ```

### Adapt update*/draw* Functions (vfx.lua)
- Ensure all update* and draw* functions read parameters from the effect instance rather than using template values directly
- Update position/trajectory logic to account for rangeBand and elevation:
  ```lua
  -- In updateProjectile for example:
  local distance = effect.rangeBand and (effect.rangeBand * Constants.RANGE_BAND_PIXELS) or defaultDistance
  local height = effect.elevation and (effect.elevation * Constants.ELEVATION_PIXELS) or 0
  ```
- Ensure color tinting is properly applied in all drawing functions

## Acceptance Criteria
- VFX.createEffect correctly initializes effect instances based on the full opts table
- Color tints are applied correctly based on opts.color
- Visual scale (size, count, radius) reflects opts.scale
- Particle motion reflects opts.motion (basic integration with VFX-S2-T5)
- Trajectory reflects opts.rangeBand and opts.elevation
- All parameters from the VisualResolver are meaningfully utilized

## Technical Notes
- Define clear rules for how opts.scale affects different geometric properties
- Consider documenting the scaling behavior for future reference
- This change is foundational for rule-driven visual effects

## Dependencies
- This ticket builds upon VFX-S2-T2
- Should be implemented before VFX-S2-T5 (Full Motion Style Integration)