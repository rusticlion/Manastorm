-- impact.lua
-- Impact VFX module for handling impact/explosion effects

-- Import dependencies
local Constants = require("core.Constants")
local ParticleManager = require("vfx.ParticleManager")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for impact effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for impact effects
local function updateImpact(effect, dt)
    -- Initialize effect default values if not already set
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.radius = effect.radius or 50 -- Default radius
    effect.useTargetPosition = (effect.useTargetPosition ~= false) -- Default to true
    effect.followTargetEntity = (effect.followTargetEntity ~= false) -- Default to true
    
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
    
    -- Create impact wave that expands outward
    -- For effects with useTargetPosition=true, ensure particles use target position
    local useTargetPosition = effect.useTargetPosition
    
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
            
            -- Update particle base position to current target position for effects that track target
            if useTargetPosition then
                particle.baseX = effect.targetX
                particle.baseY = effect.targetY
            end
            
            -- Calculate particle progress
            local particleProgress = (effect.timer - particle.delay) / (effect.duration - particle.delay)
            particleProgress = math.min(particleProgress, 1.0)
            
            -- Update particle based on its specific animation type
            if particle.animType == "expand" then
                -- Expand outward from center
                local distProgress = particleProgress -- Distance progress
                local fadeProgress = particleProgress ^ 0.7 -- Fade progress (start faster)
                
                -- Calculate distance from center
                local angle = particle.angle
                local dist = particle.maxDist * distProgress
                
                -- Update position
                particle.x = particle.baseX + math.cos(angle) * dist
                particle.y = particle.baseY + math.sin(angle) * dist
                
                -- Update alpha (fade out)
                particle.alpha = (1.0 - fadeProgress)
                
                -- Update scale (grow slightly, then shrink)
                local scaleProgress = particleProgress
                particle.scale = particle.baseScale * (1.0 + scaleProgress * 0.5) * (1.0 - scaleProgress * 0.8)
            end
        end
    end
end

-- Draw function for impact effects
local function drawImpact(effect)
    -- Make sure essential properties exist
    effect.color = effect.color or {1, 1, 1} -- Default color
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.targetX = effect.targetX or 0 -- Default position
    effect.targetY = effect.targetY or 0 -- Default position
    effect.radius = effect.radius or 50 -- Default radius
    
    local particleImage = getAssetInternal("fireParticle")
    local impactImage = getAssetInternal("impactRing")
    
    -- Draw expanding ring
    local ringProgress = math.min(effect.progress * 1.5, 1.0) -- Ring expands faster than full effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - ringProgress)) -- Use base color, apply ring alpha
    local ringScale = effect.radius * 0.02 * ringProgress
    love.graphics.draw(
        impactImage,
        effect.targetX, effect.targetY,
        0,
        ringScale, ringScale,
        impactImage:getWidth()/2, impactImage:getHeight()/2
    )
    
    -- Draw central flash with additive blending for extra brightness
    if effect.progress < 0.3 then
        local flashIntensity = 1.0 - (effect.progress / 0.3)
        love.graphics.setColor(1, 1, 1, flashIntensity * 0.7)
        
        -- Save current blend mode and set to additive for the brightest elements
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        love.graphics.circle("fill", effect.targetX, effect.targetY, 30 * flashIntensity)
        
        -- Restore previous blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha * 0.7)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                0,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
end

-- Initialize function for impact effects
local function initializeImpact(effect)
    -- For impact effects, create a radial explosion using ParticleManager
    for i = 1, effect.particleCount do
        local angle = (i / effect.particleCount) * math.pi * 2
        local delay = math.random() * 0.2 -- Slight random delay

        -- Create particle using specialized helper
        local particle = ParticleManager.createImpactParticle(effect, angle, delay)

        -- Additional motion-related properties
        particle.motion = effect.motion -- Store motion style on particle

        -- Additional properties for special motion
        particle.startTime = 0
        particle.baseX = effect.targetX
        particle.baseY = effect.targetY
        particle.angle = angle

        table.insert(effect.particles, particle)
    end
end

-- Return the module
return {
    initialize = initializeImpact,
    update = updateImpact,
    draw = drawImpact
}