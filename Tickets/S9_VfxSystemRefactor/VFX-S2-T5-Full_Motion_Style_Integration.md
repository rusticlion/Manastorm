# Ticket #VFX-S2-T5: Full Motion Style Integration

## Goal
Fully integrate the defined motion styles into the particle update logic, ensuring particles behave correctly according to the style determined by the VisualResolver.

## Background
The VisualResolver determines motion styles based on spell properties, but the VFX module needs to be enhanced to fully implement these styles. This ticket focuses on refactoring the particle update logic to support different motion behaviors based on the assigned style.

## Tasks

### Refactor update* Functions (vfx.lua)
- Review VFX.updateProjectile, VFX.updateImpact, VFX.updateAura, etc.
- Ensure particle movement logic is delegated to a common helper function:
  ```lua
  -- In update functions, focus on effect-level progression
  for i, particle in ipairs(effect.particles) do
    if particle.active then
      local particleProgress = (effect.elapsedTime - particle.startTime) / particle.lifespan
      VFX.updateParticle(particle, effect, dt, particleProgress)
    end
  end
  ```
- The main update* functions should focus on:
  - Overall effect progression (beam extension, projectile trajectory)
  - Particle lifecycle management (activation, deactivation)

### Enhance VFX.updateParticle (vfx.lua)
- Implement or refine logic for each Constants.MotionStyle:
  ```lua
  function VFX.updateParticle(particle, effect, dt, progress)
    -- Base updates common to all styles
    particle.alpha = VFX.calculateAlpha(progress, effect.fadeIn, effect.fadeOut)
    
    -- Apply motion style-specific updates
    if effect.motion == Constants.MotionStyle.RISE then
      -- Particles gradually rise upward
      particle.y = particle.y - (particle.speed * dt)
      particle.rotation = particle.rotation + (dt * 0.5)
    elseif effect.motion == Constants.MotionStyle.SWIRL then
      -- Particles move in a circular pattern
      local radius = particle.distance * (1 - 0.5 * progress) -- Decreasing radius
      local angle = particle.angle + (dt * particle.speed)
      particle.angle = angle
      particle.x = effect.x + math.cos(angle) * radius
      particle.y = effect.y + math.sin(angle) * radius
    elseif effect.motion == Constants.MotionStyle.PULSE then
      -- Particles expand and contract
      local scale = 1 + 0.5 * math.sin(progress * math.pi * 2)
      particle.scale = particle.baseScale * scale
    elseif effect.motion == Constants.MotionStyle.DIRECTIONAL then
      -- Particles move in their assigned direction
      particle.x = particle.x + math.cos(particle.angle) * particle.speed * dt
      particle.y = particle.y + math.sin(particle.angle) * particle.speed * dt
    else -- DEFAULT motion
      -- Simple motion outward from center
      particle.x = particle.x + particle.dx * dt
      particle.y = particle.y + particle.dy * dt
    end
  end
  ```

## Acceptance Criteria
- Particles in different effects clearly exhibit the motion behavior associated with their spell's affinity
- Motion styles are applied correctly regardless of the base effect type
- update* functions are cleaner, primarily managing effect state and calling updateParticle
- Different spells with the same base template but different affinities show visually distinct particle behaviors

## Technical Notes
- This refactoring separates effect-level progression from particle-level movement
- Consider adding comments explaining each motion style's visual intention
- The implementation should be efficient and avoid unnecessary calculations

## Dependencies
- This ticket builds upon VFX-S2-T3
- Should be implemented before VFX-S2-T6 (final cleanup)