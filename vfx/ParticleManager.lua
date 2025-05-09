-- ParticleManager.lua
-- Centralized system for managing VFX particles using the Pool system

local Pool = require("core.Pool")
local ParticleManager = {}

-- Create a new particle from the pool
function ParticleManager.createParticle()
    local particle = Pool.acquire("vfx_particle")
    -- Initialize with default values to avoid nil errors
    particle.x = 0
    particle.y = 0
    particle.scale = 1.0
    particle.alpha = 1.0
    particle.rotation = 0
    particle.active = false
    
    return particle
end

-- Release a particle back to the pool
function ParticleManager.releaseParticle(particle)
    if not particle then return false end
    return Pool.release("vfx_particle", particle)
end

-- Safe clean up function for particles in an effect
function ParticleManager.cleanupEffectParticles(particles, condition)
    local i = 1
    local removedCount = 0
    
    while i <= #particles do
        local particle = particles[i]
        
        -- Check if this particle should be removed based on the provided condition function
        if condition(particle) then
            -- Release the particle back to the pool
            ParticleManager.releaseParticle(particle)
            table.remove(particles, i)
            removedCount = removedCount + 1
        else
            i = i + 1
        end
    end
    
    return removedCount
end

-- Release all particles in an array
function ParticleManager.releaseAllParticles(particles)
    -- Go backward through the array to avoid index issues during removal
    for i = #particles, 1, -1 do
        local particle = particles[i]
        if particle then
            ParticleManager.releaseParticle(particle)
        end
        particles[i] = nil
    end
end

-- Clone particle data (copy from one particle to another)
function ParticleManager.cloneParticleData(sourceParticle, targetParticle)
    -- Copy all fields
    for k, v in pairs(sourceParticle) do
        targetParticle[k] = v
    end
    return targetParticle
end

-- Create a meteor particle
function ParticleManager.createMeteorParticle(effect, offsetX, offsetY)
    local particle = ParticleManager.createParticle()
    
    -- Set meteor-specific properties
    particle.type = "meteor"
    particle.offsetX = offsetX
    particle.offsetY = offsetY
    particle.startX = effect.targetX + offsetX  -- Start above the target
    particle.startY = effect.targetY - effect.height + offsetY
    particle.endX = effect.targetX + offsetX * 0.3  -- End at target with reduced offset
    particle.endY = effect.targetY + offsetY * 0.1
    particle.x = particle.startX
    particle.y = particle.startY
    particle.rotation = math.random() * math.pi * 2
    particle.rotationSpeed = (math.random() - 0.5) * 4
    particle.baseScale = 0.3 + math.random() * 0.3
    particle.scale = 0.3 + math.random() * 0.3
    particle.alpha = 1.0
    particle.timeCreated = effect.timer or 0
    particle.lifespan = (effect.duration or 1.4) * (0.7 + math.random() * 0.6)
    particle.assetId = "fireParticle"
    particle.color = effect.color
    
    return particle
end

-- Create a meteor trail particle
function ParticleManager.createMeteorTrailParticle(effect, parentParticle)
    local particle = ParticleManager.createParticle()
    
    -- Set trail-specific properties
    particle.type = "trail"
    particle.x = parentParticle.x + math.random(-5, 5)
    particle.y = parentParticle.y + math.random(-5, 5)
    particle.scale = parentParticle.scale * 0.6
    particle.baseScale = parentParticle.scale * 0.6
    particle.alpha = 0.7
    particle.baseAlpha = 0.7
    particle.timeCreated = effect.timer
    particle.lifespan = 0.2 + math.random() * 0.2
    particle.assetId = "fireParticle"
    particle.color = effect.color
    
    return particle
end

-- Create a meteor impact particle
function ParticleManager.createMeteorImpactParticle(effect, angle)
    local particle = ParticleManager.createParticle()
    
    -- Set impact-specific properties
    particle.type = "impact"
    particle.angle = angle
    particle.x = effect.targetX
    particle.y = effect.targetY
    particle.maxDist = 40 + math.random() * 20
    particle.scale = 0.3 + math.random() * 0.2
    particle.baseScale = 0.3 + math.random() * 0.2
    particle.alpha = 0.7
    particle.baseAlpha = 0.7
    particle.timeCreated = effect.timer
    particle.lifespan = 0.4 + math.random() * 0.2
    particle.assetId = "sparkle"
    particle.color = effect.color
    
    return particle
end

-- Get particle stats
function ParticleManager.getStats()
    return {
        poolSize = Pool.size("vfx_particle"),
        available = Pool.available("vfx_particle"),
        active = Pool.activeCount("vfx_particle")
    }
end

-- Print particle stats to console
function ParticleManager.printStats()
    local stats = ParticleManager.getStats()
    print(string.format("[PARTICLE MANAGER] Pool: %d total (%d active, %d available)", 
        stats.poolSize, stats.active, stats.available))
end

return ParticleManager