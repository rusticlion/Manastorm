-- beam.lua
-- Beam VFX module for handling beam/laser effects

-- Import dependencies
local Constants = require("core.Constants")
local ParticleManager = require("vfx.ParticleManager")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for beam effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for beam effects
local function updateBeam(effect, dt)
    -- Initialize effect default values if not already set
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.beamWidth = effect.beamWidth or 15 -- Default beam width
    effect.sourceX = effect.sourceX or 0 -- Default source position
    effect.sourceY = effect.sourceY or 0 -- Default source position
    effect.targetX = effect.targetX or 400 -- Default target position
    effect.targetY = effect.targetY or 0 -- Default target position
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
    
    -- Enhanced beam update with shield block handling
    local Constants = require("core.Constants")

    -- Update beam properties based on current source and target positions
    -- This ensures the beam adjusts if the wizards move due to range/elevation changes
    effect.beamLength = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
    effect.beamAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)

    -- Determine which progress value to use (normal vs. visualProgress for blocked beams)
    local baseProgress = effect.visualProgress or effect.progress

    -- Apply pulsing effect
    effect.pulseTimer = (effect.pulseTimer or 0) + dt * 10
    effect.pulseFactor = 0.7 + 0.3 * math.sin(effect.pulseTimer)

    -- Handle beam progress for blocked beams
    local blockPoint = effect.blockPoint or 1.0

    -- Handle shield block specific effects
    if effect.isBlocked and not effect.impactEffectCreated and baseProgress >= blockPoint then
        -- Create shield impact effect
        effect.impactEffectCreated = true

        -- Calculate impact position
        local impactX = effect.sourceX + math.cos(effect.beamAngle) * (effect.beamLength * blockPoint)
        local impactY = effect.sourceY + math.sin(effect.beamAngle) * (effect.beamLength * blockPoint)

        print(string.format("[BEAM] Creating shield impact effect at (%.1f, %.1f)", impactX, impactY))

        -- Get the VFX module (should be loaded by now)
        if not VFX then VFX = require("vfx") end

        -- Determine shield color based on shield type
        local shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Default yellow
        local shieldType = effect.blockType or (effect.options and effect.options.shieldType)
        if shieldType == "ward" then
            shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
        elseif shieldType == "field" then
            shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
        end

        -- Create shield impact effect
        if VFX.createEffect then
            -- Impact flash effect
            local flashParams = {
                duration = 0.3,
                scale = (effect.startScale or 1.0) * 1.5,
                color = {shieldColor[1], shieldColor[2], shieldColor[3], 0.9},
                particleCount = 8
            }
            VFX.createEffect("impact_base", impactX, impactY, impactX, impactY, flashParams)

            -- Particle burst effect
            local burstParams = {
                duration = 0.8,
                scale = (effect.startScale or 1.0) * 1.2,
                color = shieldColor,
                particleCount = 30
            }
            VFX.createEffect("impact_base", impactX, impactY, impactX, impactY, burstParams)
        end

        -- Trigger screen shake for beam impact
        local gameState = nil

        -- Try to find the game state through various references
        if effect.options and effect.options.gameState then
            gameState = effect.options.gameState
        elseif effect.options and effect.options.sourceEntity and effect.options.sourceEntity.gameState then
            gameState = effect.options.sourceEntity.gameState
        elseif effect.options and effect.options.targetEntity and effect.options.targetEntity.gameState then
            gameState = effect.options.targetEntity.gameState
        elseif _G.game then
            gameState = _G.game
        elseif VFX.gameState then
            gameState = VFX.gameState
        end

        -- Determine impact amount for shake intensity
        local amount = effect.options and effect.options.amount or 12  -- Beams are powerful
        local intensity = math.min(5, 2.5 + (amount / 20))  -- Slightly more intense than projectiles
        local shakeDuration = 0.25  -- Longer duration for beam

        -- Trigger shake if we have access to game state
        if gameState and gameState.triggerShake then
            gameState.triggerShake(shakeDuration, intensity)
            print(string.format("[BEAM] Shield block impact! Triggered shake (%.2f, %.2f) at blockPoint=%.2f",
                shakeDuration, intensity, blockPoint))
        elseif VFX.triggerShake then
            VFX.triggerShake(shakeDuration, intensity)
        end
    end

    -- If beam is blocked, it should stop at the block point
    if effect.isBlocked and baseProgress > blockPoint then
        effect.beamProgress = blockPoint
    else
        effect.beamProgress = baseProgress
    end
    
    -- Update beam particles
    if effect.particles then
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
            particle.maxLife = particle.maxLife or 0.5
            particle.alpha = particle.alpha or 1.0
            particle.scale = particle.scale or 1.0
            particle.startScale = particle.startScale or particle.scale
            
            -- Update particle lifetime
            particle.life = particle.life + dt
            
            -- Remove expired particles
            if particle.life >= particle.maxLife then
                table.remove(effect.particles, i)
            else
                -- Update particle position and alpha
                local lifeProgress = particle.life / particle.maxLife
                
                -- Update alpha (fade out)
                particle.alpha = 1.0 - lifeProgress
                
                -- Update scale (grow slightly then shrink)
                particle.scale = particle.startScale * (1.0 + lifeProgress * 0.5 - lifeProgress * lifeProgress)
                
                -- Move to next particle
                i = i + 1
            end
            
            ::next_particle::
        end
        
        -- Add new particles at source and impact point
        if math.random() < 0.3 then
            -- Add particle at source
            local sourceParticle = {
                x = effect.sourceX + math.random(-5, 5),
                y = effect.sourceY + math.random(-5, 5),
                scale = math.random(5, 15) / 100,
                startScale = math.random(5, 15) / 100,
                alpha = 1.0,
                life = 0,
                maxLife = math.random() * 0.2 + 0.1,
                active = true -- Ensure particle is marked as active
            }
            table.insert(effect.particles, sourceParticle)
            
            -- Add particle at impact point (if beam has traveled that far)
            if effect.beamProgress > 0.5 then
                local impactX = effect.sourceX + math.cos(effect.beamAngle) * (effect.beamLength * effect.beamProgress)
                local impactY = effect.sourceY + math.sin(effect.beamAngle) * (effect.beamLength * effect.beamProgress)
                
                local impactParticle = {
                    x = impactX + math.random(-10, 10),
                    y = impactY + math.random(-10, 10),
                    scale = math.random(5, 15) / 100,
                    startScale = math.random(5, 15) / 100, 
                    alpha = 1.0,
                    life = 0,
                    maxLife = math.random() * 0.2 + 0.1,
                    active = true -- Ensure particle is marked as active
                }
                table.insert(effect.particles, impactParticle)
            end
        end
    end
end

-- Draw function for beam effects
local function drawBeam(effect)
    -- Make sure essential properties exist
    effect.color = effect.color or {1, 1, 1} -- Default color
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.sourceX = effect.sourceX or 0 -- Default position
    effect.sourceY = effect.sourceY or 0 -- Default position
    effect.beamLength = effect.beamLength or 400 -- Default length
    effect.beamAngle = effect.beamAngle or 0 -- Default angle
    effect.beamProgress = effect.beamProgress or effect.progress or 1.0 -- Default progress
    effect.beamWidth = effect.beamWidth or 15 -- Default width
    effect.pulseFactor = effect.pulseFactor or 1.0 -- Default pulse
    
    local particleImage = getAssetInternal("sparkle")
    
    -- Use current beam properties (which have been updated in updateBeam)
    local beamLength = effect.beamLength * effect.beamProgress
    
    -- Draw base beam
    local beamEndX = effect.sourceX + math.cos(effect.beamAngle) * beamLength
    local beamEndY = effect.sourceY + math.sin(effect.beamAngle) * beamLength
    
    -- Calculate beam width with pulse
    local pulseValue = effect.pulseFactor or 1.0
    local beamWidth = (effect.beamWidth or 15) * pulseValue
    
    -- Draw outer beam glow
    love.graphics.setColor(effect.color[1] * 0.3, effect.color[2] * 0.3, effect.color[3] * 0.3, 0.3)
    love.graphics.setLineWidth(beamWidth * 1.5)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Save current blend mode and set to additive for the brightest elements
    local prevMode = {love.graphics.getBlendMode()}
    love.graphics.setBlendMode("add")
    
    -- Draw inner beam core with additive blending
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, 0.7)
    love.graphics.setLineWidth(beamWidth * 0.7)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw brightest beam center with additive blending
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(beamWidth * 0.3)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Restore previous blend mode
    love.graphics.setBlendMode(prevMode[1], prevMode[2])
    
    -- Draw source glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.7 * pulseValue)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, beamWidth * 0.7)
    
    -- Draw impact glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.8 * pulseValue)
    love.graphics.circle("fill", beamEndX, beamEndY, beamWidth * 0.9)
    
    -- Draw particles
    if effect.particles then
        for _, particle in ipairs(effect.particles) do
            -- Skip invalid or inactive particles
            if not particle or not particle.active then
                goto next_draw_particle
            end
            
            -- Ensure required properties exist
            particle.alpha = particle.alpha or 1.0
            particle.scale = particle.scale or 1.0
            particle.x = particle.x or effect.sourceX
            particle.y = particle.y or effect.sourceY
            
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
                -- Fallback if image is missing
                love.graphics.circle("fill", particle.x, particle.y, particle.scale * 50)
            end
            
            ::next_draw_particle::
        end
    end
    
    -- Draw blocked impact flash if beam hit a shield
    if effect.isBlocked and effect.blockPoint and effect.progress > effect.blockPoint then
        -- Calculate impact point
        local blockX = effect.sourceX + math.cos(effect.beamAngle) * (effect.beamLength * effect.blockPoint)
        local blockY = effect.sourceY + math.sin(effect.beamAngle) * (effect.beamLength * effect.blockPoint)

        -- Calculate impact flash size and alpha
        local impactProgress = (effect.progress - effect.blockPoint) / (1 - effect.blockPoint)
        local flashSize = 40 * (1.0 - impactProgress) * effect.pulseFactor
        local flashAlpha = 0.7 * (1.0 - impactProgress)

        -- Set to additive blending for bright flash
        love.graphics.setBlendMode("add")

        -- Draw impact flash
        love.graphics.setColor(1, 1, 1, flashAlpha)
        love.graphics.circle("fill", blockX, blockY, flashSize)

        -- Get shield color based on type for distinctive visuals
        local shieldR, shieldG, shieldB = 1.0, 1.0, 0.3 -- Default yellow
        local shieldType = effect.blockType or (effect.options and effect.options.shieldType)
        if shieldType == "ward" then
            shieldR, shieldG, shieldB = 0.3, 0.3, 1.0 -- Blue for wards
        elseif shieldType == "field" then
            shieldR, shieldG, shieldB = 0.3, 1.0, 0.3 -- Green for fields
        end

        -- Draw colored shield impact ring
        love.graphics.setColor(shieldR, shieldG, shieldB, flashAlpha * 0.9)
        local ringSize = flashSize * 1.2
        local ringWidth = 3
        love.graphics.setLineWidth(ringWidth)
        love.graphics.circle("line", blockX, blockY, ringSize)

        -- Draw radial beams emanating from impact point
        local beamCount = 8
        for i = 1, beamCount do
            local angle = (i / beamCount) * math.pi * 2 + (effect.progress * 3)
            local rayLength = ringSize * (0.8 + 0.4 * math.sin(impactProgress * math.pi * 6))
            local x2 = blockX + math.cos(angle) * rayLength
            local y2 = blockY + math.sin(angle) * rayLength

            love.graphics.setLineWidth(ringWidth * 0.6)
            love.graphics.line(blockX, blockY, x2, y2)
        end

        -- Draw shield specific effects if applicable
        if shieldType and (shieldType == "ward" or shieldType == "barrier") then
            -- Shield-specific visualization
            local runeImages = getAssetInternal("runes")
            if runeImages and #runeImages > 0 then
                -- Get a deterministic rune index
                local runeIndex
                if effect.id then
                    runeIndex = (effect.id % #runeImages) + 1
                else
                    -- Calculate a stable index from the positions
                    local posHash = math.floor(effect.sourceX + effect.sourceY + effect.targetX + effect.targetY)
                    runeIndex = (posHash % #runeImages) + 1
                end
                local runeImage = runeImages[runeIndex]

                -- Draw the rune with rotation and pulsing
                local runeSize = 0.5 * (1 + 0.3 * math.sin(impactProgress * math.pi * 4))
                local runeAlpha = flashAlpha * 0.9

                love.graphics.setColor(1, 1, 1, runeAlpha)

                if runeImage then
                    love.graphics.draw(
                        runeImage,
                        blockX, blockY,
                        impactProgress * math.pi * 2,
                        runeSize, runeSize,
                        runeImage:getWidth()/2, runeImage:getHeight()/2
                    )
                end
            end
        end

        -- Restore blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
    end
end

-- Initialize function for beam effects
local function initializeBeam(effect)
    -- First create the main beam shape
    effect.beamProgress = 0
    effect.beamLength = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
    effect.beamAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)

    -- Check for block info and set block properties
    if effect.options and effect.options.blockPoint then
        print(string.format("[BEAM INIT] Detected block at point %.2f", effect.options.blockPoint))
        effect.isBlocked = true
        effect.blockPoint = effect.options.blockPoint
        effect.blockType = effect.options.shieldType or "ward"
    end

    -- Then add particles along the beam
    for i = 1, effect.particleCount do
        local position = math.random()
        local offset = math.random(-10, 10)

        -- Create particle using ParticleManager
        local particle = ParticleManager.createBeamParticle(effect, position, offset)

        table.insert(effect.particles, particle)
    end
end

-- Return the module
return {
    initialize = initializeBeam,
    update = updateBeam,
    draw = drawBeam
}