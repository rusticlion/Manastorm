-- cone.lua
-- Cone VFX module for handling cone/blast effects

-- Import dependencies
local Constants = require("core.Constants")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for cone effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for cone effects
local function updateCone(effect, dt)
    -- Initialize effect default values if not already set
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.waveCount = effect.waveCount or 3 -- Default wave count
    effect.coneAngle = effect.coneAngle or 70 -- Default cone angle (degrees)
    effect.beamDist = effect.beamDist or 200 -- Default beam distance
    effect.waveCrestSize = effect.waveCrestSize or 1.0 -- Default wave crest size
    effect.useSourcePosition = (effect.useSourcePosition ~= false) -- Default to true
    effect.useTargetPosition = (effect.useTargetPosition ~= false) -- Default to true
    effect.followSourceEntity = (effect.followSourceEntity ~= false) -- Default to true
    effect.followTargetEntity = (effect.followTargetEntity ~= false) -- Default to true
    
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
    
    -- Calculate the base direction from source to target
    local dirX = effect.targetX - effect.sourceX
    local dirY = effect.targetY - effect.sourceY
    local baseAngle = math.atan2(dirY, dirX)
    
    -- Update wave timing
    local waveCount = effect.waveCount or 3
    for i = 1, waveCount do
        -- Calculate when this wave should start
        local waveStartTime = (i - 1) * effect.duration * 0.3 / waveCount
        
        -- Update wave progress
        if effect.timer >= waveStartTime then
            -- Calculate how far this wave has traveled
            local waveProgress = math.min(1.0, (effect.timer - waveStartTime) / (effect.duration * 0.8))
            
            -- Store wave progress for drawing
            effect.waves = effect.waves or {}
            effect.waves[i] = {
                progress = waveProgress,
                startTime = waveStartTime,
                crestDelay = i * 0.05, -- Slight delay for the wave crest visualization
                age = effect.timer - waveStartTime
            }
        end
    end
    
    -- Apply intensity multiplier based on range band
    -- This makes close-range cones more powerful (wider, more intense colors)
    if not effect.rangeFactorApplied then
        if effect.rangeBand == "CLOSE" then
            effect.coneAngle = effect.coneAngle * 1.2
            effect.waveCrestSize = effect.waveCrestSize * 1.3
            effect.currentIntensityMultiplier = 1.3
        elseif effect.rangeBand == "MID" then
            effect.coneAngle = effect.coneAngle * 1.1
            effect.waveCrestSize = effect.waveCrestSize * 1.15
            effect.currentIntensityMultiplier = 1.15
        elseif effect.rangeBand == "FAR" then
            -- Default, no change
            effect.currentIntensityMultiplier = 1.0
        else
            -- Default, no change
            effect.currentIntensityMultiplier = 1.0
        end
        
        effect.rangeFactorApplied = true
    end
    
    -- Add particles at cone edges and along the waves
    if math.random() < 0.3 then
        -- Calculate cone properties
        local coneAngleRad = (effect.coneAngle or 70) * math.pi / 180
        local beamDist = effect.beamDist or 200
        
        -- Spawn particles along current wave fronts
        if effect.waves then
            for i, wave in ipairs(effect.waves) do
                -- Only add particles if the wave has started but not fully dissipated
                if wave.progress > 0 and wave.progress < 0.9 then
                    -- Calculate wave position (distance from source)
                    local waveDist = beamDist * wave.progress
                    
                    -- Add particles along the wave front
                    local numParticles = math.random(1, 3)
                    for j = 1, numParticles do
                        -- Calculate random angle within the cone
                        local randomAngleOffset = (math.random() * 2 - 1) * coneAngleRad / 2
                        local particleAngle = baseAngle + randomAngleOffset
                        
                        -- Calculate position
                        local distanceVariation = math.random() * 10 - 5
                        local particleDist = waveDist + distanceVariation
                        local particleX = effect.sourceX + math.cos(particleAngle) * particleDist
                        local particleY = effect.sourceY + math.sin(particleAngle) * particleDist
                        
                        -- Create particle
                        local particle = {
                            x = particleX,
                            y = particleY,
                            angle = particleAngle,
                            scale = math.random(10, 30) / 100,
                            alpha = math.random() * 0.7 + 0.3,
                            life = 0,
                            maxLife = math.random() * 0.2 + 0.1,
                            active = true
                        }
                        
                        table.insert(effect.particles, particle)
                    end
                end
            end
        end
    end
    
    -- Update existing particles
    local i = 1
    while i <= #effect.particles do
        local particle = effect.particles[i]
        
        -- Skip invalid particles
        if not particle then
            table.remove(effect.particles, i)
            goto next_particle
        end
        
        -- Initialize any missing particle properties
        particle.life = particle.life or 0
        particle.maxLife = particle.maxLife or 0.3
        particle.alpha = particle.alpha or 1.0
        particle.scale = particle.scale or 0.2
        
        -- Update particle lifetime
        particle.life = particle.life + dt
        
        -- Remove expired particles
        if particle.life >= particle.maxLife then
            table.remove(effect.particles, i)
        else
            -- Update particle properties
            local lifeProgress = particle.life / particle.maxLife
            
            -- Fade out
            particle.alpha = (1.0 - lifeProgress) * particle.alpha
            
            -- Grow slightly then shrink
            particle.scale = particle.scale * (1.0 + lifeProgress * 0.3 - lifeProgress * lifeProgress * 0.6)
            
            -- Move to next particle
            i = i + 1
        end
        
        ::next_particle::
    end
end

-- Draw function for cone effects
local function drawCone(effect)
    -- Initialize effect default values if not already set
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.waves = effect.waves or {} -- Initialize waves array if nil
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.coneAngle = effect.coneAngle or 70 -- Default cone angle (degrees)
    effect.beamDist = effect.beamDist or 200 -- Default beam distance
    effect.currentIntensityMultiplier = effect.currentIntensityMultiplier or 1.0 -- Default intensity multiplier
    
    -- Get assets
    local particleImage = getAssetInternal("sparkle")
    local glowImage = getAssetInternal("fireGlow") -- For enhanced glow effects
    
    -- Get intensity multiplier for range-based effects
    local intensityMult = effect.currentIntensityMultiplier or 1.0
    
    -- Draw background glow for the entire cone area at the beginning
    if effect.progress < 0.5 then
        -- Calculate cone properties
        local coneAngleRad = (effect.coneAngle or 70) * math.pi / 180
        local baseAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)
        local beamDist = effect.beamDist or 200
        
        -- Calculate glow alpha based on progress
        local glowAlpha = 0.3 * (0.5 - effect.progress) / 0.5
        
        -- Draw ambient background glow for the cone area
        local trianglePoints = {}
        
        -- Start from source point
        table.insert(trianglePoints, effect.sourceX)
        table.insert(trianglePoints, effect.sourceY)
        
        -- Number of points to create a smooth cone edge
        local numPoints = 10
        for i = 0, numPoints do
            local angle = baseAngle - coneAngleRad/2 + i * (coneAngleRad / numPoints)
            local x = effect.sourceX + math.cos(angle) * beamDist
            local y = effect.sourceY + math.sin(angle) * beamDist
            table.insert(trianglePoints, x)
            table.insert(trianglePoints, y)
        end
        
        -- Draw cone glow background
        love.graphics.setColor(effect.color[1] * 0.5, effect.color[2] * 0.5, effect.color[3] * 0.5, glowAlpha)
        love.graphics.polygon("fill", trianglePoints)
    end
    
    -- Draw the wave bands
    if effect.waves then
        for i, wave in ipairs(effect.waves) do
            -- Only draw if wave has started
            if wave.progress > 0 then
                -- Calculate wave properties
                local waveFront = wave.progress
                local waveBack = math.max(0, waveFront - 0.2)
                local waveFade = math.min(1.0, (1.0 - wave.progress) * 2)
                
                -- Calculate cone properties
                local coneAngleRad = (effect.coneAngle or 70) * math.pi / 180
                local baseAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)
                local beamDist = effect.beamDist or 200
                
                -- Calculate color based on effect color
                local r = effect.color[1] * intensityMult
                local g = effect.color[2] * intensityMult
                local b = effect.color[3] * intensityMult
                local a = 0.7 * waveFade
                
                -- Draw the wave segments
                local segments = 10
                local prevX1, prevY1, prevX2, prevY2 = nil, nil, nil, nil
                
                for j = 0, segments do
                    -- Calculate angle for this segment
                    local segmentAngle = baseAngle - coneAngleRad/2 + j * (coneAngleRad / segments)
                    
                    -- Calculate front and back points of the wave
                    local x1 = effect.sourceX + math.cos(segmentAngle) * (beamDist * waveFront)
                    local y1 = effect.sourceY + math.sin(segmentAngle) * (beamDist * waveFront)
                    local x2 = effect.sourceX + math.cos(segmentAngle) * (beamDist * waveBack)
                    local y2 = effect.sourceY + math.sin(segmentAngle) * (beamDist * waveBack)
                    
                    -- Draw the wave segment if we have a previous point
                    if prevX1 ~= nil then
                        -- Draw the wave segment
                        love.graphics.setColor(r, g, b, a)
                        love.graphics.polygon("fill", x1, y1, prevX1, prevY1, prevX2, prevY2, x2, y2)
                    end
                    
                    -- Add extra glow points at wave crest with additive blending
                    if waveFront > 0.2 and j % 3 == 1 then
                        local glowSize = waveFront * (effect.waveCrestSize or 1.0) * 15
                        love.graphics.setColor(r, g, b, waveFront * 0.7)
                        
                        -- Save current blend mode and set to additive for the brightest elements
                        local prevMode = {love.graphics.getBlendMode()}
                        love.graphics.setBlendMode("add")
                        
                        love.graphics.circle("fill", (x1 + prevX1)/2, (y1 + prevY1)/2, glowSize * intensityMult)
                        
                        -- Restore previous blend mode
                        love.graphics.setBlendMode(prevMode[1], prevMode[2])
                    end
                    
                    -- Store current points as previous for next segment
                    prevX1, prevY1, prevX2, prevY2 = x1, y1, x2, y2
                end
            end
        end
    end
    
    -- Draw source glow (brighter at the beginning)
    local sourceGlowSize = 10 + 40 * (1.0 - effect.progress)
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.7 * (1.0 - effect.progress))
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, sourceGlowSize)
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        -- Skip invalid or inactive particles
        if not particle or not particle.active then
            goto next_draw_particle
        end
        
        -- Ensure required properties exist
        particle.alpha = particle.alpha or 1.0
        particle.scale = particle.scale or 0.2
        particle.x = particle.x or effect.sourceX
        particle.y = particle.y or effect.sourceY
        
        -- Draw the particle
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
        
        ::next_draw_particle::
    end
end

-- Return the module
return {
    update = updateCone,
    draw = drawCone
}