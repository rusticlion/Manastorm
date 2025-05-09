# VFX System Overview

The VFX (Visual Effects) system handles all visual effects in Manastorm, from projectiles and beams to explosions and auras. This document provides guidelines on how to work with the VFX system, particularly focusing on proper particle management to avoid memory leaks and performance issues.

## Architecture

The VFX system is organized around these components:

1. **Main VFX Module** (`vfx.lua`) - Coordinates visual effects and provides core functionality
2. **Effect Modules** (in `vfx/effects/`) - Individual effect types with specialized logic
3. **ParticleManager** (`vfx/ParticleManager.lua`) - Centralized particle handling
4. **Pool System** (`core/Pool.lua`) - Object pooling to reduce garbage collection

## Particle Management

The most critical aspect of the VFX system is proper particle management. All particles MUST be:

1. Created using `ParticleManager.createParticle()` or a specific factory function
2. Released back to the pool when no longer needed
3. Never created directly as tables `{}` as this bypasses the pool system

### Common Issues

- **WARNING: Object being released was not acquired from pool** - This indicates that a particle was created directly (using `{}`) instead of using `Pool.acquire()` or `ParticleManager.createParticle()`
- **Memory leaks** - If particles are not properly released, they remain in memory and can cause gradual slowdown

### Best Practices

1. **Always use the ParticleManager:**
   ```lua
   local particle = ParticleManager.createParticle()
   -- or use specialized factory functions
   local meteorParticle = ParticleManager.createMeteorParticle(effect, offsetX, offsetY)
   ```

2. **Always clean up particles:**
   ```lua
   -- Individual particles
   ParticleManager.releaseParticle(particle)
   
   -- Multiple particles
   ParticleManager.cleanupEffectParticles(particles, function(p)
       return p.alpha <= 0.05  -- Condition for removal
   end)
   
   -- All particles in an array
   ParticleManager.releaseAllParticles(particles)
   ```

3. **Use the diagnostic tools:**
   ```lua
   -- Show detailed pool statistics
   VFX.showPoolStats()
   
   -- Run full diagnostic
   VFX.runParticlePoolDiagnostic()
   ```

## Creating New Effect Types

When creating a new effect type:

1. Create a new file in `vfx/effects/` (e.g., `tornado.lua`)
2. Implement `update` and `draw` functions
3. Register the effect type in `vfx.lua`
4. Use `ParticleManager` for all particle operations
5. Set up particle cleanup to release particles when effects end

### Template for Effect Module

```lua
-- tornado.lua
-- Tornado VFX module

local Constants = require("core.Constants")
local ParticleManager = require("vfx.ParticleManager")

-- Lazy-loaded VFX reference to avoid circular dependencies
local VFX
local function getAsset(assetId)
    if not VFX then VFX = require("vfx") end
    return VFX.getAsset(assetId)
end

-- Update function
local function updateTornado(effect, dt)
    -- Initialize particles if needed
    if #effect.particles == 0 then
        -- Create particles using ParticleManager
        for i = 1, effect.particleCount do
            local particle = ParticleManager.createParticle()
            -- Set particle properties
            particle.type = "tornado"
            -- ... other properties
            table.insert(effect.particles, particle)
        end
    end
    
    -- Update particles
    for _, particle in ipairs(effect.particles) do
        -- Update logic
    end
    
    -- Clean up expired particles
    ParticleManager.cleanupEffectParticles(effect.particles, function(p)
        return p.alpha <= 0.05
    end)
end

-- Draw function
local function drawTornado(effect)
    -- Drawing code
end

-- Return the module
return {
    update = updateTornado,
    draw = drawTornado
}
```

## Debugging

If you encounter particle pool warnings:

1. Run `VFX.showPoolStats()` to check the current state
2. Look for discrepancies between pool counts and actual particles
3. Run `VFX.runParticlePoolDiagnostic()` to test and potentially fix issues
4. Check effect modules for direct table creation (`{}`) instead of pool usage
5. Verify all particles are being released when effects end

## Performance Considerations

- The particle pool size (currently 100) can be adjusted based on game needs
- Consider implementing particle limits for specific effect types
- Use `effect.particleCount` scaling based on performance settings
- Implement LOD (Level of Detail) for effects based on distance or importance