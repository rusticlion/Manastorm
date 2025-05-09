-- conjure.lua
-- Conjure VFX module for handling conjuration/summoning effects

-- Import dependencies
local Constants = require("core.Constants")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for conjure effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for conjure effects
local function updateConjure(effect, dt)
    -- Initialize effect default values
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.sourceGlow = effect.sourceGlow or 0 -- Default source glow
    effect.poolGlow = effect.poolGlow or 0 -- Default pool glow
    effect.pulseRate = effect.pulseRate or 5 -- Default pulse rate
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
    
    -- Update particles rising toward mana pool
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
        particle.targetX = particle.targetX or effect.targetX
        particle.targetY = particle.targetY or effect.targetY
        
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update position - moving from source to target (mana pool)
            local startX = particle.baseX
            local startY = particle.baseY
            local endX = particle.targetX
            local endY = particle.targetY
            
            -- For a more interesting path, add some curves
            local bezierT = particleProgress
            local invT = 1.0 - bezierT
            
            -- Calculate bezier curve with randomized control points
            if not particle.ctrlPoint1X then
                -- Midpoint distance between source and target
                local midX = (startX + endX) / 2
                local midY = (startY + endY) / 2
                local dist = math.sqrt((endX - startX)^2 + (endY - startY)^2)
                
                -- Add random offset for natural path variation
                local offsetX = (math.random() - 0.5) * dist * 0.5
                local offsetY = (math.random() - 0.5) * dist * 0.5
                
                -- Store the control points for this particle's path
                particle.ctrlPoint1X = midX + offsetX
                particle.ctrlPoint1Y = midY + offsetY
            end
            
            -- Calculate quadratic bezier curve position
            particle.x = invT * invT * startX + 2 * invT * bezierT * particle.ctrlPoint1X + bezierT * bezierT * endX
            particle.y = invT * invT * startY + 2 * invT * bezierT * particle.ctrlPoint1Y + bezierT * bezierT * endY
            
            -- Calculate fade alpha based on progress
            -- Full opacity in the middle of the journey
            local fadeProgress = math.abs(particleProgress - 0.5) * 2 -- 0 at middle, 1 at start/end
            particle.alpha = 1.0 - fadeProgress * 0.7
            
            -- Update size - grow then shrink
            local sizeFactor = 1.0 - fadeProgress * 0.5
            particle.scale = (particle.baseScale or 0.3) * sizeFactor
        end
        
        ::next_particle::
    end
    
    -- Update glow at source position (starts strong, then fades)
    local sourceGlowProgress = math.min(effect.progress * 2, 1.0) -- 0->1 over first half
    effect.sourceGlow = 1.0 - sourceGlowProgress -- Fade from 1->0
    
    -- Update glow at mana pool (grows as particles converge)
    local poolGlowProgress = math.max(0, effect.progress * 2 - 1.0) -- 0->1 over second half
    effect.poolGlow = poolGlowProgress -- Grow from 0->1
    
    -- Create final pulse particles at the end
    if effect.progress > 0.85 and not effect.finalPulseCreated then
        -- Create a burst of particles radiating outward from mana pool
        local burstCount = 12
        for i = 1, burstCount do
            local angle = (i-1) * (2 * math.pi / burstCount)
            local particle = {
                x = effect.targetX,
                y = effect.targetY,
                angle = angle,
                speed = 80 + math.random() * 50,
                baseScale = 0.3 + math.random() * 0.2,
                scale = 0.3 + math.random() * 0.2,
                alpha = 0.8,
                life = 0,
                maxLife = 0.3 + math.random() * 0.2,
                active = true,
                type = "burst"  -- Mark these as burst particles
            }
            table.insert(effect.particles, particle)
        end
        
        effect.finalPulseCreated = true
    end
    
    -- Update final pulse particles (they move outward)
    for _, particle in ipairs(effect.particles) do
        if particle.type == "burst" and particle.active then
            -- Update position based on angle and speed
            particle.x = particle.x + math.cos(particle.angle) * particle.speed * dt
            particle.y = particle.y + math.sin(particle.angle) * particle.speed * dt
            
            -- Update lifecycle
            particle.life = particle.life + dt
            particle.alpha = 1.0 - (particle.life / particle.maxLife)
            particle.scale = particle.baseScale * (1.0 - particle.life / particle.maxLife)
            
            -- Deactivate if expired
            if particle.life >= particle.maxLife then
                particle.active = false
            end
        end
    end
end

-- Draw function for conjure effects
local function drawConjure(effect)
    -- Initialize effect default values
    effect.color = effect.color or {1, 1, 1} -- Default color
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.sourceX = effect.sourceX or 0 -- Default source position
    effect.sourceY = effect.sourceY or 0 -- Default source position
    effect.targetX = effect.targetX or 0 -- Default target position
    effect.targetY = effect.targetY or 0 -- Default target position
    effect.sourceGlow = effect.sourceGlow or 0 -- Default source glow
    effect.poolGlow = effect.poolGlow or 0 -- Default pool glow
    effect.timer = effect.timer or 0 -- Default timer
    
    local particleImage = getAssetInternal("sparkle")
    local glowImage = getAssetInternal("fireGlow")  -- We'll use this for all conjure types
    
    -- Draw source glow if active with additive blending
    if effect.sourceGlow and effect.sourceGlow > 0 then
        -- Save current blend mode and set to additive for the brightest elements
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.sourceGlow * 0.6)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 50 * effect.sourceGlow)
        
        -- Draw expanding rings from source (hint at conjuration happening)
        local ringCount = 3
        for i = 1, ringCount do
            local ringProgress = ((effect.timer * 1.5) % 1.0) + (i-1) / ringCount
            if ringProgress < 1.0 then
                local ringSize = 60 * ringProgress
                local ringAlpha = 0.5 * (1.0 - ringProgress) * effect.sourceGlow
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], ringAlpha)
                love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
            end
        end
        
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
        
        -- Draw particle with additive blending for brighter appearance
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha * 0.8)
        
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
    
    -- Draw mana pool glow with additive blending (grows at the end of the effect)
    if effect.poolGlow and effect.poolGlow > 0 then
        -- Save current blend mode and set to additive for the brightest elements
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        -- Add some pulsing to the glow
        local pulseOffset = math.sin(effect.timer * 8) * 0.2
        local finalGlowScale = effect.poolGlow * (1.0 + pulseOffset)
        
        -- Draw outer glow
        love.graphics.setColor(effect.color[1] * 0.6, effect.color[2] * 0.6, effect.color[3] * 0.6, effect.poolGlow * 0.7)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 50 * finalGlowScale)
        
        -- Draw inner glow (brighter)
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.poolGlow * 0.9)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 30 * finalGlowScale)
        
        -- Draw bright center
        love.graphics.setColor(1, 1, 1, effect.poolGlow * 0.95)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 15 * finalGlowScale)
        
        -- Restore blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
    end
end

-- Return the module
return {
    update = updateConjure,
    draw = drawConjure
}