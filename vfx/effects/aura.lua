-- aura.lua
-- Aura VFX module for handling aura/circle effects

-- Import dependencies
local Constants = require("core.Constants")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for aura effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for aura effects
local function updateAura(effect, dt)
    -- Initialize effect default values
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.radius = effect.radius or 50 -- Default radius
    effect.pulseRate = effect.pulseRate or 5 -- Default pulse rate
    effect.angularSpeed = effect.angularSpeed or 1.5 -- Default angular speed
    effect.orbitCount = effect.orbitCount or 2 -- Default orbit count
    effect.useSourcePosition = (effect.useSourcePosition ~= false) -- Default to true
    effect.followSourceEntity = (effect.followSourceEntity ~= false) -- Default to true
    
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
    
    -- Update orbital particles
    for i, particle in ipairs(effect.particles) do
        -- Skip invalid particles
        if not particle then
            goto next_particle
        end
        
        -- Initialize particle properties if missing
        particle.delay = particle.delay or 0
        particle.active = particle.active or false
        particle.angle = particle.angle or 0
        particle.radius = particle.radius or effect.radius
        particle.orbitId = particle.orbitId or 1
        
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update orbital position
            particle.angle = particle.angle + dt * (effect.angularSpeed or 1.5)
            
            -- Different orbits have different radii and move in opposite directions
            local orbitRadius = effect.radius * (0.8 + 0.4 * (particle.orbitId / (effect.orbitCount or 2)))
            
            -- Alternate direction for different orbits
            if particle.orbitId % 2 == 0 then
                particle.angle = particle.angle - dt * (effect.angularSpeed or 1.5) * 2
            end
            
            -- Update particle position
            particle.x = effect.sourceX + math.cos(particle.angle) * orbitRadius
            particle.y = effect.sourceY + math.sin(particle.angle) * orbitRadius
            
            -- Calculate fade based on progress
            -- Start visible, peak at 50%, then fade out
            local fadeProgress = 1.0 - math.abs(particleProgress - 0.5) * 2
            particle.alpha = fadeProgress * (particle.baseAlpha or 1.0)
            
            -- Pulse size
            local pulse = math.sin(effect.timer * (effect.pulseRate or 5) + particle.angle) * 0.3 + 0.7
            particle.scale = (particle.baseScale or 0.3) * pulse
        end
        
        ::next_particle::
    end
end

-- Draw function for aura effects
local function drawAura(effect)
    -- Initialize effect default values
    effect.color = effect.color or {1, 1, 1} -- Default color
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.sourceX = effect.sourceX or 0 -- Default position
    effect.sourceY = effect.sourceY or 0 -- Default position
    effect.radius = effect.radius or 50 -- Default radius
    effect.pulseRate = effect.pulseRate or 5 -- Default pulse rate
    
    local particleImage = getAssetInternal("sparkle")
    
    -- Draw base aura circle
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.2
    local baseAlpha = 0.3 * (1 - (math.abs(effect.progress - 0.5) * 2)^2) -- Peak at middle of effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], baseAlpha)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, baseAlpha * 1.5)
    love.graphics.circle("line", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    
    -- Draw particles with additive blending for brighter core
    local prevMode = {love.graphics.getBlendMode()}
    love.graphics.setBlendMode("add")
    
    -- Draw central glow
    local centerGlowSize = effect.radius * 0.4
    local centerPulse = math.sin(effect.timer * effect.pulseRate * 1.5) * 0.2 + 0.8
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], baseAlpha * 1.2)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * centerPulse)
    
    -- Draw bright center
    love.graphics.setColor(1, 1, 1, baseAlpha * 1.5)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 0.3 * centerPulse)
    
    -- Restore blend mode
    love.graphics.setBlendMode(prevMode[1], prevMode[2])
    
    -- Draw individual particles
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
        
        -- Draw particle
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha)
        
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
        
        ::next_draw_particle::
    end
end

-- Return the module
return {
    update = updateAura,
    draw = drawAura
}