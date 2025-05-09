-- remote.lua
-- Remote VFX module for handling teleport/warp effects

-- Import dependencies
local Constants = require("core.Constants")
local ParticleManager = require("vfx.ParticleManager")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for remote effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for remote effects
local function updateRemote(effect, dt)
    -- Initialize effect default values
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.useSourcePosition = (effect.useSourcePosition ~= false) -- Default to true
    effect.useTargetPosition = (effect.useTargetPosition ~= false) -- Default to true
    effect.followSourceEntity = (effect.followSourceEntity ~= false) -- Default to true
    effect.followTargetEntity = (effect.followTargetEntity ~= false) -- Default to true
    effect.useSprites = effect.useSprites or false -- Default for sprite usage
    effect.frameTimer = effect.frameTimer or 0 -- Animation timer
    effect.currentFrame = effect.currentFrame or 1 -- Current animation frame
    effect.frameDuration = effect.frameDuration or 0.1 -- Duration between frames
    
    -- Update source position if we're tracking an entity
    if effect.useSourcePosition and effect.followSourceEntity and effect.sourceEntity then
        -- If the source entity has a position, update our source position
        if effect.sourceEntity.x and effect.sourceEntity.y then
            effect.sourceX = effect.sourceEntity.x
            effect.sourceY = effect.sourceEntity.y
            
            -- Apply any entity offsets if present
            if effect.sourceEntity.currentXOffset and effect.sourceEntity.currentYOffset then
                effect.sourceX = effect.sourceX + effect.sourceEntity.currentXOffset
                effect.sourceY = effect.sourceY + effect.sourceEntity.currentYOffset
            end
        end
    end
    
    -- Update target position if we're tracking an entity
    if effect.useTargetPosition and effect.followTargetEntity and effect.targetEntity then
        -- If the target entity has a position, update our target position
        if effect.targetEntity.x and effect.targetEntity.y then
            effect.targetX = effect.targetEntity.x
            effect.targetY = effect.targetEntity.y
            
            -- Apply any entity offsets if present
            if effect.targetEntity.currentXOffset and effect.targetEntity.currentYOffset then
                effect.targetX = effect.targetX + effect.targetEntity.currentXOffset
                effect.targetY = effect.targetY + effect.targetEntity.currentYOffset
            end
        end
    end
    
    -- Update particles for the warp/remote effect
    for i, particle in ipairs(effect.particles) do
        -- Skip invalid particles
        if not particle then
            goto next_particle
        end
        
        -- Initialize particle properties if missing
        particle.delay = particle.delay or 0
        particle.active = particle.active or false
        
        -- Activate particles based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update particle position based on type
            if particle.type == "source" then
                -- Source particles expand outward
                local dist = particle.maxDist * particleProgress
                particle.x = effect.sourceX + math.cos(particle.angle) * dist
                particle.y = effect.sourceY + math.sin(particle.angle) * dist
                
                -- Fade out as they expand
                particle.alpha = 1.0 - particleProgress
            elseif particle.type == "target" then
                -- Target particles converge inward
                local dist = particle.maxDist * (1.0 - particleProgress)
                particle.x = effect.targetX + math.cos(particle.angle) * dist
                particle.y = effect.targetY + math.sin(particle.angle) * dist
                
                -- Fade in as they converge
                particle.alpha = particleProgress
            end
            
            -- Update particle scale
            local scaleFactor = 1.0 - math.abs(particleProgress - 0.5) * 0.6
            particle.scale = (particle.baseScale or 0.3) * scaleFactor
        end
        
        ::next_particle::
    end
    
    -- Update sprite animation for warp effect
    if effect.useSprites then
        effect.frameTimer = effect.frameTimer + dt
        if effect.frameTimer >= effect.frameDuration then
            effect.frameTimer = 0
            effect.currentFrame = effect.currentFrame + 1
            if effect.currentFrame > 3 then
                effect.currentFrame = 1
            end
        end
    end
end

-- Draw function for remote effects
local function drawRemote(effect)
    -- Initialize effect default values
    effect.color = effect.color or {1, 1, 1} -- Default color
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.sourceX = effect.sourceX or 0 -- Default source position
    effect.sourceY = effect.sourceY or 0 -- Default source position
    effect.targetX = effect.targetX or 0 -- Default target position
    effect.targetY = effect.targetY or 0 -- Default target position
    effect.progress = effect.progress or 0 -- Default progress
    effect.useSprites = effect.useSprites or false -- Default for sprite usage
    effect.currentFrame = effect.currentFrame or 1 -- Current animation frame
    
    local particleImage = getAssetInternal("sparkle")
    local glowImage = getAssetInternal("fireGlow")
    local impactImage = getAssetInternal("impactRing")
    
    -- Get warp frames if needed
    local warpFrames = nil
    if effect.useSprites then
        warpFrames = getAssetInternal("warpFrames")
    end
    
    -- Draw effects at source position
    if effect.progress < 0.6 then
        -- Fade out as effect progresses
        local sourceAlpha = 1.0 - (effect.progress / 0.6)
        
        -- Draw glow effect at source with additive blending
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        -- Draw expanding ring for warp-out effect
        local ringSize = 30 + effect.progress * 60
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.5 * sourceAlpha)
        love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
        
        -- Draw bright glow core
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.8 * sourceAlpha)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 25 * (1.0 - effect.progress/0.6))
        
        -- Draw inner bright center
        love.graphics.setColor(1, 1, 1, 0.9 * sourceAlpha)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 10 * (1.0 - effect.progress/0.6))
        
        -- Restore blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
        
        -- Draw sprite-based warp effect if enabled
        if effect.useSprites and warpFrames then
            local frame = warpFrames[effect.currentFrame]
            local scale = 1.0 * (1.0 - effect.progress/0.6)
            
            -- Draw the warp sprite
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], sourceAlpha)
            love.graphics.draw(
                frame,
                effect.sourceX, effect.sourceY,
                0,
                scale, scale,
                frame:getWidth()/2, frame:getHeight()/2
            )
        end
    end
    
    -- Draw effects at target position
    if effect.progress > 0.4 then
        -- Fade in at target position
        local targetAlpha = math.min(1.0, (effect.progress - 0.4) / 0.6)
        
        -- Draw glow effect at target with additive blending
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        -- Draw converging ring for warp-in effect
        local ringSize = 90 - (effect.progress - 0.4) * 60
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.5 * targetAlpha)
        love.graphics.circle("line", effect.targetX, effect.targetY, ringSize)
        
        -- Draw bright glow core
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.8 * targetAlpha)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 25 * ((effect.progress - 0.4)/0.6))
        
        -- Draw inner bright center
        love.graphics.setColor(1, 1, 1, 0.9 * targetAlpha)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 10 * ((effect.progress - 0.4)/0.6))
        
        -- Restore blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
        
        -- Draw sprite-based warp effect if enabled
        if effect.useSprites and warpFrames then
            local frame = warpFrames[effect.currentFrame]
            local scale = 1.0 * ((effect.progress - 0.4)/0.6)
            
            -- Draw the warp sprite
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], targetAlpha)
            love.graphics.draw(
                frame,
                effect.targetX, effect.targetY,
                0,
                scale, scale,
                frame:getWidth()/2, frame:getHeight()/2
            )
        end
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        -- Skip invalid or inactive particles
        if not particle or not particle.active then
            goto next_draw_particle
        end
        
        -- Ensure required properties exist
        particle.alpha = particle.alpha or 0
        particle.scale = particle.scale or 0.3
        particle.x = particle.x or effect.sourceX
        particle.y = particle.y or effect.sourceY
        
        -- Draw particle with additive blending for brighter effect
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha * 0.7)
        
        if particleImage then
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                0,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        else
            -- Fallback if particle image is missing
            love.graphics.circle("fill", particle.x, particle.y, particle.scale * 30)
        end
        
        -- Restore blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
        
        ::next_draw_particle::
    end
end

-- Initialize function for remote effects
local function initializeRemote(effect)
    -- For remote effects like warp, create particles at the target location
    -- Set flags for position tracking
    effect.useTargetPosition = true  -- This tells the system to use the current target position

    -- Make sure to use the initial position with offsets if available
    local centerX = effect.targetX
    local centerY = effect.targetY

    -- Initialize with offset if the target entity has position offsets
    if effect.targetEntity and effect.targetEntity.currentXOffset and effect.targetEntity.currentYOffset then
        centerX = effect.targetEntity.x + effect.targetEntity.currentXOffset
        centerY = effect.targetEntity.y + effect.targetEntity.currentYOffset

        -- Update effect's target position to include offsets
        effect.targetX = centerX
        effect.targetY = centerY

        print(string.format("[VFX] Initializing warp at (%d, %d) with offsets (%d, %d)",
            centerX, centerY, effect.targetEntity.currentXOffset, effect.targetEntity.currentYOffset))
    end

    local radius = effect.radius or 60

    -- Calculate how many particles to create based on density
    local particlesToCreate = effect.particleCount
    if effect.particleDensity then
        particlesToCreate = math.floor(effect.particleCount * effect.particleDensity)
    end

    for i = 1, particlesToCreate do
        -- Create particles in a circular pattern around the target
        local angle = (i / particlesToCreate) * math.pi * 2
        -- Random distance from center
        local distance = math.random(10, radius)
        -- Random speed for movement
        local speed = math.random(10, 70)

        -- Create particle using ParticleManager
        local particle = ParticleManager.createRemoteParticle(effect, angle, distance, speed)

        table.insert(effect.particles, particle)
    end

    -- Initialize sprite rotation angle if needed
    if effect.rotateSprite then
        effect.spriteAngle = 0
    end
end

-- Return the module
return {
    initialize = initializeRemote,
    update = updateRemote,
    draw = drawRemote
}