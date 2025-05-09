-- surge.lua
-- Surge VFX module for handling fountain/burst effects

-- Import dependencies
local Constants = require("core.Constants")
local ParticleManager = require("vfx.ParticleManager")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for surge effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for surge effects
local function updateSurge(effect, dt)
    -- Initialize effect default values
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.centerGlow = (effect.centerGlow ~= false) -- Default to true
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
    
    -- Update center glow animation
    if effect.centerGlow then
        effect.centerParticleTimer = (effect.centerParticleTimer or 0) + dt
    end
    
    -- Fountain style upward burst with gravity pull and enhanced effects
    for _, particle in ipairs(effect.particles) do
        -- Skip invalid particles
        if not particle then
            goto next_particle
        end
        
        -- Initialize particle properties if missing
        particle.delay = particle.delay or 0
        particle.active = particle.active or false
        
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Apply gravity and update movement
            if not particle.x then
                -- Initialize particle position if missing
                particle.x = effect.sourceX
                particle.y = effect.sourceY
                particle.baseX = effect.sourceX
                particle.baseY = effect.sourceY
            end
            
            -- Get particle age
            local particleAge = effect.timer - particle.delay
            
            -- Get velocities or initialize them
            particle.vx = particle.vx or (math.random() * 2 - 1) * 100
            particle.vy = particle.vy or -80 - math.random() * 120 -- Initial upward velocity
            
            -- Apply gravity over time
            local gravity = 150
            particle.vy = particle.vy + gravity * dt
            
            -- Apply velocities to position
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            
            -- Apply drag to slow particles
            local drag = 0.98
            particle.vx = particle.vx * drag
            particle.vy = particle.vy * drag
            
            -- Calculate alpha based on lifetime (fade in, then fade out)
            local alphaPeak = 0.3 -- Peak opacity at 30% of life
            local alphaValue = 0
            
            if particleProgress < alphaPeak then
                -- Fade in
                alphaValue = particleProgress / alphaPeak
            else
                -- Fade out
                alphaValue = 1.0 - ((particleProgress - alphaPeak) / (1.0 - alphaPeak))
            end
            
            -- Apply the calculated alpha
            particle.alpha = alphaValue * (particle.baseAlpha or 1.0)
            
            -- Update size based on life (grow slightly, then shrink)
            local sizeCurve = 1.0 + math.sin(particleProgress * math.pi) * 0.5
            particle.scale = (particle.baseScale or 0.3) * sizeCurve
        end
        
        ::next_particle::
    end
    
    -- Update center glow pulsing if enabled
    if effect.centerGlow then
        local pulseSpeed = 5
        effect.centerGlowPulse = 0.7 + 0.3 * math.sin(effect.centerParticleTimer * pulseSpeed)
    end
end

-- Draw function for surge effects
local function drawSurge(effect)
    -- Initialize effect default values
    effect.color = effect.color or {1, 1, 1} -- Default color
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.sourceX = effect.sourceX or 0 -- Default position
    effect.sourceY = effect.sourceY or 0 -- Default position
    effect.progress = effect.progress or 0 -- Default progress
    effect.centerGlow = (effect.centerGlow ~= false) -- Default to true
    effect.centerGlowPulse = effect.centerGlowPulse or 1.0 -- Default pulse value
    
    local particleImage = getAssetInternal("sparkle")
    
    -- Draw expanding ground effect ring at source
    if effect.progress < 0.7 then
        local ringProgress = effect.progress / 0.7
        local ringSize = 30 + ringProgress * 40 -- Grows from 30 to 70 pixels
        local ringAlpha = 0.5 * (1 - ringProgress)
        
        love.graphics.setColor(effect.color[1] * 0.8, effect.color[2] * 0.8, effect.color[3] * 0.8, ringAlpha)
        love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
    end
    
    -- Draw center glow effect with additive blending
    if effect.centerGlow then
        -- Calculate glow size based on progress
        -- Stronger at the start, then fades
        local glowProgress = math.max(0, 1.0 - effect.progress * 1.5)
        local centerGlowSize = 30 * glowProgress
        
        -- Calculate pulsing and intensity
        local glowPulse = effect.centerGlowPulse or 1.0
        local glowIntensity = 1.0 + 0.5 * glowPulse
        local glowAlpha = 0.7 * glowProgress
        
        -- Save current blend mode and set to additive for the brightest elements
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        -- Draw outer glow layers with additive blending
        love.graphics.setColor(effect.color[1] * 0.5, effect.color[2] * 0.5, effect.color[3] * 0.5, glowAlpha * 0.4)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 1.2 * glowPulse)
        
        -- Middle glow layer
        love.graphics.setColor(effect.color[1] * 0.8, effect.color[2] * 0.8, effect.color[3] * 0.8, glowAlpha * 0.6)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 0.8 * glowPulse)
        
        -- Bright core
        love.graphics.setColor(effect.color[1] * glowIntensity, effect.color[2] * glowIntensity, 
                              effect.color[3] * glowIntensity, glowAlpha * 0.8)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 0.5 * glowPulse)
        
        -- White inner core
        love.graphics.setColor(1, 1, 1, glowAlpha * 0.9 * glowPulse)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 0.2 * glowPulse)
        
        -- Restore previous blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
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
        
        -- Draw particle with additive blending for extra brightness
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

-- Initialize function for surge effects
local function initializeSurge(effect)
    -- Pre-load center particle
    effect.centerParticleTimer = 0

    -- Create particles with varied properties using ParticleManager
    for i = 1, effect.particleCount do
        local particle = ParticleManager.createSurgeParticle(effect)
        table.insert(effect.particles, particle)
    end
end

-- Return the module
return {
    initialize = initializeSurge,
    update = updateSurge,
    draw = drawSurge
}