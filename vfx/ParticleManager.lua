-- ParticleManager.lua
-- Centralized system for managing VFX particles using the Pool system

local Pool = require("core.Pool")
local Constants = require("core.Constants")
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

-- Create a projectile trail particle
function ParticleManager.createProjectileTrailParticle(effect, headX, headY)
    local particle = ParticleManager.createParticle()

    -- Set trail-specific properties
    particle.x = headX
    particle.y = headY
    particle.xVel = math.random(-30, 30)
    particle.yVel = math.random(-30, 30)
    particle.size = math.random(5, 15) * (effect.size or 1.0)
    particle.alpha = math.random() * 0.5 + 0.5
    particle.life = 0
    particle.maxLife = math.random() * 0.3 + 0.1
    particle.color = effect.color or {1, 1, 1}

    -- Use pixel primitive sprites for the trail
    if math.random() < 0.2 then
        -- Occasional sparkle highlight
        particle.assetId = math.random() < 0.5 and "twinkle1" or "twinkle2"
        particle.size = 3
    else
        particle.assetId = "onePx"
        particle.size = 1
    end

    return particle
end

-- Create an impact particle
function ParticleManager.createImpactParticle(effect, angle, delay)
    local particle = ParticleManager.createParticle()

    -- Set impact-specific properties
    particle.baseX = effect.targetX
    particle.baseY = effect.targetY
    particle.x = effect.targetX
    particle.y = effect.targetY
    particle.angle = angle
    particle.delay = delay or 0
    particle.active = false
    particle.animType = "expand"
    particle.maxDist = effect.radius * (0.5 + math.random() * 0.5)
    particle.baseScale = 0.5 + math.random() * 0.5
    particle.scale = particle.baseScale
    particle.alpha = 1.0

    return particle
end

-- Create an aura particle
function ParticleManager.createAuraParticle(effect, angle, orbitId)
    local particle = ParticleManager.createParticle()

    -- Set aura-specific properties
    local distance = effect.radius * (0.6 + math.random() * 0.4)
    local orbitalSpeed = 0.5 + math.random() * 1.5

    particle.angle = angle
    particle.distance = distance
    particle.orbitalSpeed = orbitalSpeed
    particle.scale = effect.startScale
    particle.baseScale = effect.startScale
    particle.alpha = 0 -- Start invisible and fade in
    particle.baseAlpha = 1.0
    particle.rotation = 0
    particle.delay = (angle / (2 * math.pi)) * 0.5
    particle.active = false
    particle.orbitId = orbitId or math.random(1, effect.orbitCount or 2)
    particle.baseX = effect.sourceX
    particle.baseY = effect.sourceY

    return particle
end

-- Create a beam particle
function ParticleManager.createBeamParticle(effect, position, offset)
    local particle = ParticleManager.createParticle()

    -- Set beam-specific properties
    particle.position = position -- 0 to 1 along beam
    particle.offset = offset -- Perpendicular to beam
    particle.scale = effect.startScale * (0.7 + math.random() * 0.6)
    particle.alpha = 0.8
    particle.rotation = math.random() * math.pi * 2
    particle.delay = math.random() * 0.3
    particle.active = false

    return particle
end

-- Create a cone particle
function ParticleManager.createConeParticle(effect, angle, distance, isWaveParticle, waveIndex)
    local particle = ParticleManager.createParticle()

    -- Common properties
    particle.angle = angle
    particle.rotation = angle -- Align rotation with direction
    particle.delay = math.random() * 0.3 -- Staggered start
    particle.active = false
    particle.motion = effect.motionStyle or Constants.MotionStyle.DIRECTIONAL
    particle.intensityMultiplier = 1.0

    -- Set position at source
    particle.x = effect.sourceX
    particle.y = effect.sourceY

    -- Additional properties for motion
    particle.startTime = 0
    particle.baseX = effect.sourceX
    particle.baseY = effect.sourceY

    -- Wave-specific properties
    if isWaveParticle then
        particle.isWave = true
        particle.waveIndex = waveIndex
        particle.waveTime = waveIndex / (effect.waveCount or 3) -- Staggered wave timing

        -- Calculate wave speed and distance based on wave index
        local speedMultiplier = 1.0 + (waveIndex - 1) * 0.15
        particle.distance = (effect.coneLength or 320) * 0.95 -- Waves extend almost to max distance
        particle.speed = (effect.waveSpeed or 350) * speedMultiplier
        particle.scale = effect.startScale * (1.5 + waveIndex * 0.1)
        particle.alpha = 0.9

        -- Special effects
        if effect.wavePersistence then
            particle.persistenceFactor = effect.wavePersistence
        end

        if effect.trailingGlowStrength then
            particle.trailGlow = effect.trailingGlowStrength
        end
    else
        -- Regular fill particles
        particle.distance = distance
        particle.speed = math.random(100, 250)

        -- Size variance
        local sizeVariance = effect.particleSizeVariance or 0.6
        particle.scale = effect.startScale * (0.7 + math.random() * sizeVariance)
        particle.alpha = 0.6 + math.random() * 0.4
        particle.isWave = false
    end

    -- Target destination for the particle
    particle.targetX = effect.sourceX + math.cos(angle) * particle.distance
    particle.targetY = effect.sourceY + math.sin(angle) * particle.distance

    return particle
end

-- Create a remote effect particle
function ParticleManager.createRemoteParticle(effect, angle, distance, speed)
    local particle = ParticleManager.createParticle()

    -- Calculate center position
    local centerX = effect.targetX
    local centerY = effect.targetY

    -- Set remote-specific properties
    particle.x = centerX
    particle.y = centerY
    particle.targetX = centerX + math.cos(angle) * distance
    particle.targetY = centerY + math.sin(angle) * distance
    particle.speed = speed
    particle.scale = effect.startScale * (0.5 + math.random() * 0.5) -- Varied scales
    particle.alpha = 0.7 + math.random() * 0.3 -- Slightly varied alpha
    particle.rotation = angle
    particle.delay = math.random() * 0.4
    particle.active = false
    particle.motion = effect.motion
    particle.angle = angle
    particle.distance = distance

    return particle
end

-- Create a conjure particle
function ParticleManager.createConjureParticle(effect, startX, startY, dirX, dirY, speed, delay)
    local particle = ParticleManager.createParticle()

    -- Set conjure-specific properties
    particle.x = startX
    particle.y = startY
    particle.speedX = dirX * speed
    particle.speedY = dirY * speed
    particle.scale = effect.startScale
    particle.alpha = 0 -- Start transparent and fade in
    particle.rotation = math.random() * math.pi * 2
    particle.rotSpeed = math.random(-3, 3)
    particle.delay = delay
    particle.active = false
    particle.finalPulse = false
    particle.finalPulseTime = 0

    return particle
end

-- Create a surge particle
function ParticleManager.createSurgeParticle(effect)
    local particle = ParticleManager.createParticle()

    -- Get effect properties
    local spread = effect.spread or 45
    local riseFactor = effect.riseFactor or 1.4
    local gravity = effect.gravity or 180
    local particleSizeVariance = effect.particleSizeVariance or 0.6
    local useSprites = effect.useSprites

    -- Start at source position with slight random offset
    local startOffsetX = math.random(-10, 10)
    local startOffsetY = math.random(-10, 10)
    particle.x = effect.sourceX + startOffsetX
    particle.y = effect.sourceY + startOffsetY

    -- Store initial position for spiral motion calculations
    particle.initialX = particle.x
    particle.initialY = particle.y

    -- Create upward velocity with variety
    -- More focused in the center for a fountain effect
    local horizontalBias = math.pow(math.random(), 1.5) -- Bias toward lower values
    particle.speedX = (math.random() - 0.5) * spread * horizontalBias

    -- Vertical speed with some variance and acceleration
    local riseSpeed = math.random(220, 320) * riseFactor
    if effect.riseAcceleration then
        particle.riseAcceleration = math.random() * effect.riseAcceleration
    end

    particle.speedY = -riseSpeed
    particle.gravity = gravity * (0.8 + math.random() * 0.4) -- Slight variance in gravity

    -- Visual properties with variance
    local sizeVariance = 1.0 + (math.random() * 2 - 1) * particleSizeVariance
    particle.scale = effect.startScale * sizeVariance
    particle.baseScale = particle.scale -- Store for pulsation

    particle.alpha = 0.9 + math.random() * 0.1
    particle.rotation = math.random() * math.pi * 2
    particle.rotationSpeed = math.random(-4, 4) -- Random rotation speed

    -- Staggered appearance
    particle.delay = math.random() * 0.4
    particle.active = false

    -- Add sprite animation if enabled
    if useSprites then
        particle.useSprite = true
        particle.frameIndex = 1
        particle.frameTimer = 0
        particle.frameRate = effect.spriteFrameRate or 8
    end

    -- Special properties based on effect template settings
    if effect.spiralMotion then
        particle.spiral = true
        particle.spiralFrequency = 5 + math.random() * 3
        particle.spiralAmplitude = 10 + math.random() * 20
        particle.spiralPhase = math.random() * math.pi * 2
        particle.spiralTightness = effect.spiralTightness or 2.5
    end

    if effect.pulsateParticles and math.random() < 0.7 then
        particle.pulsate = true
        particle.pulseRate = 3 + math.random() * 5
        particle.pulseAmount = 0.2 + math.random() * 0.3
    end

    -- Chance for special sparkle particles
    if effect.sparkleChance and math.random() < effect.sparkleChance then
        particle.sparkle = true
        particle.sparkleIntensity = 0.7 + math.random() * 0.3
    end

    -- Add bloom glow effect
    if effect.bloomEffect then
        particle.bloom = true
        particle.bloomIntensity = (effect.bloomIntensity or 0.8) * (0.7 + math.random() * 0.6)
    end

    return particle
end

-- Create a projectile core particle
function ParticleManager.createProjectileCoreParticle(effect, baseAngle, turbulence)
    local particle = ParticleManager.createParticle()

    -- Random position near the projectile core
    local spreadFactor = 4 * turbulence
    local offsetX = math.random(-spreadFactor, spreadFactor)
    local offsetY = math.random(-spreadFactor, spreadFactor)

    -- Set initial state
    particle.x = effect.sourceX + offsetX
    particle.y = effect.sourceY + offsetY
    particle.scale = effect.startScale * (0.9 + math.random() * 0.5) -- Slightly larger scales
    particle.alpha = 1.0
    particle.rotation = math.random() * math.pi * 2

    -- Create leading-edge cluster with minimal delay
    particle.delay = math.random() * 0.05
    particle.active = false
    particle.isCore = true -- Mark as core particle for special rendering
    particle.motion = effect.motion -- Store motion style

    -- Motion properties
    particle.startTime = 0
    particle.baseX = effect.sourceX
    particle.baseY = effect.sourceY
    particle.targetX = effect.targetX
    particle.targetY = effect.targetY

    -- Add less randomness to motion for more focused projectile
    local angleVar = (math.random() - 0.5) * 0.2 * turbulence
    particle.angle = baseAngle + angleVar
    particle.speed = math.random(200, 260) -- Significantly faster speeds

    -- Life cycle control
    particle.lifespan = (effect.particleLifespan or 0.6) * effect.duration
    particle.timeOffset = math.random() * 0.1
    particle.turbulence = turbulence

    return particle
end

-- Create a projectile trail particle (using core system, not the same as createProjectileTrailParticle)
function ParticleManager.createProjectileFullTrailParticle(effect, baseAngle, turbulence, trailIndex, trailCount)
    local particle = ParticleManager.createParticle()

    -- Trail particles start closer to the core
    local spreadRadius = 6 * (effect.trailDensity or 0.4) * turbulence -- Tighter spread
    local spreadAngle = math.random() * math.pi * 2
    local spreadDist = math.random() * spreadRadius

    -- Set initial state - more directional alignment
    particle.x = effect.sourceX + math.cos(spreadAngle) * spreadDist
    particle.y = effect.sourceY + math.sin(spreadAngle) * spreadDist
    particle.scale = effect.startScale * (0.7 + math.random() * 0.2) -- Slightly smaller
    particle.alpha = 0.7 -- Lower alpha for less visibility
    particle.rotation = math.random() * math.pi * 2

    -- Much shorter staggered delay for trail particles
    particle.delay = (trailIndex / trailCount) * 0.15 -- Cut delay in half for faster response
    particle.active = false
    particle.isCore = false -- Mark as trail particle
    particle.motion = effect.motion

    -- Motion properties
    particle.startTime = 0
    particle.baseX = effect.sourceX
    particle.baseY = effect.sourceY
    particle.targetX = effect.targetX
    particle.targetY = effect.targetY

    -- Reduce trail spread angle for more directional appearance
    local angleVar = (math.random() - 0.5) * 0.3 * turbulence -- Half the angle variance
    particle.angle = baseAngle + angleVar
    particle.speed = math.random(150, 200) -- Faster than before, closer to core speed

    -- Trail particles have shorter lifespans for smoother fade
    particle.lifespan = (effect.particleLifespan or 0.6) * effect.duration * 0.8
    particle.timeOffset = math.random() * 0.2
    particle.turbulence = turbulence

    -- Which segment of the trail this particle belongs to
    particle.trailSegment = math.random()

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