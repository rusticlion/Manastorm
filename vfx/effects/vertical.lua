-- vertical.lua
-- Vertical VFX module for handling vertical/rising effects

-- Import dependencies
local Constants = require("core.Constants")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for vertical effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for vertical effects
local function updateVertical(effect, dt)
    -- Initialize effect default values
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.height = effect.height or 200 -- Default height
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
    
    for i, particle in ipairs(effect.particles) do
        -- Skip invalid particles
        if not particle then
            goto next_particle
        end
        
        -- Initialize particle properties if missing
        particle.delay = particle.delay or 0
        particle.active = particle.active or false
        particle.baseX = particle.baseX or effect.sourceX
        particle.baseY = particle.baseY or effect.sourceY
        
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update position - moving upward
            local height = effect.height or 200
            local baseX = particle.baseX
            local baseY = particle.baseY
            
            -- Apply wind effects
            local windOffset = math.sin(effect.timer * 3 + particle.id * 0.7) * 10 * particleProgress
            
            -- Update position - moving upward with slight wind
            particle.x = baseX + windOffset
            particle.y = baseY - height * particleProgress
            
            -- Calculate fade
            -- Start visible, then fade out near the end
            local fadeStart = 0.7
            local fadeAlpha = (particleProgress < fadeStart) 
                            and 1.0 
                            or (1.0 - (particleProgress - fadeStart) / (1.0 - fadeStart))
            particle.alpha = fadeAlpha * (particle.baseAlpha or 1.0)
            
            -- Update size - grow slightly then shrink
            local sizeFactor = 1.0 + math.sin(particleProgress * math.pi) * 0.5
            particle.scale = (particle.baseScale or 0.3) * sizeFactor
        end
        
        ::next_particle::
    end
end

-- Draw function for vertical effects
local function drawVertical(effect)
    -- Initialize effect default values
    effect.color = effect.color or {1, 1, 1} -- Default color
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.sourceX = effect.sourceX or 0 -- Default position
    effect.sourceY = effect.sourceY or 0 -- Default position
    effect.progress = effect.progress or 0 -- Default progress
    
    local particleImage = getAssetInternal("fireParticle")
    
    -- Draw base effect at source
    local baseProgress = math.min(effect.progress * 3, 1.0) -- Quick initial flash
    if baseProgress < 1.0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - baseProgress) * 0.7)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 40 * baseProgress)
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
    
    -- Draw vertical column glow (fades in then out)
    local columnAlpha = 0.2 * math.sin(effect.progress * math.pi)
    if columnAlpha > 0.01 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], columnAlpha)
        
        -- Draw a vertical rectangle
        local height = effect.height or 200
        local width = 40
        love.graphics.rectangle("fill", 
                              effect.sourceX - width/2, 
                              effect.sourceY - height * effect.progress, 
                              width, 
                              height * effect.progress)
    end
end

-- Return the module
return {
    update = updateVertical,
    draw = drawVertical
}