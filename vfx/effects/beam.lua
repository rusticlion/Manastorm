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
        
        -- Add many new particles for dense swarm effect
        local particleRate = 3.0 -- Much higher rate for particle swarm
        
        -- Generate multiple particles per frame
        local particlesThisFrame = math.floor(particleRate)
        if math.random() < (particleRate - particlesThisFrame) then
            particlesThisFrame = particlesThisFrame + 1
        end
        
        for i = 1, particlesThisFrame do
            -- Add particles at source with variety
            local sourceParticle = {
                x = effect.sourceX + math.random(-8, 8),
                y = effect.sourceY + math.random(-8, 8),
                scale = math.random(1, 3),
                startScale = math.random(1, 3),
                alpha = 1.0,
                life = 0,
                maxLife = math.random() * 0.3 + 0.15,
                active = true,
                spriteType = ({"pixel", "twinkle1", "twinkle2"})[math.random(3)]
            }
            table.insert(effect.particles, sourceParticle)
            
            -- Add particles along the beam path
            if effect.beamProgress > 0.1 then
                local beamPos = math.random() * effect.beamProgress
                local beamX = effect.sourceX + math.cos(effect.beamAngle) * (effect.beamLength * beamPos)
                local beamY = effect.sourceY + math.sin(effect.beamAngle) * (effect.beamLength * beamPos)
                
                -- Perpendicular offset for beam width
                local perpAngle = effect.beamAngle + math.pi/2
                local perpOffset = (math.random() - 0.5) * effect.beamWidth
                
                local beamParticle = {
                    x = beamX + math.cos(perpAngle) * perpOffset,
                    y = beamY + math.sin(perpAngle) * perpOffset,
                    scale = math.random(1, 2),
                    startScale = math.random(1, 2),
                    alpha = 1.0,
                    life = 0,
                    maxLife = math.random() * 0.2 + 0.1,
                    active = true,
                    spriteType = ({"pixel", "twinkle1", "twinkle2"})[math.random(3)]
                }
                table.insert(effect.particles, beamParticle)
            end
            
            -- Add particles at impact point (if beam has traveled that far)
            if effect.beamProgress > 0.5 then
                local impactX = effect.sourceX + math.cos(effect.beamAngle) * (effect.beamLength * effect.beamProgress)
                local impactY = effect.sourceY + math.sin(effect.beamAngle) * (effect.beamLength * effect.beamProgress)
                
                local impactParticle = {
                    x = impactX + math.random(-12, 12),
                    y = impactY + math.random(-12, 12),
                    scale = math.random(2, 4),
                    startScale = math.random(2, 4),
                    alpha = 1.0,
                    life = 0,
                    maxLife = math.random() * 0.25 + 0.15,
                    active = true,
                    spriteType = ({"pixel", "twinkle1", "twinkle2"})[math.random(3)]
                }
                table.insert(effect.particles, impactParticle)
            end
        end
    end
end

-- Draw function for beam effects
local function drawBeam(effect)
    -- Preserve the current line width and blend mode so we can restore them after drawing
    local prevLineWidth = love.graphics.getLineWidth()
    local prevBlendMode = {love.graphics.getBlendMode()}
    
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
    local onePxImage = getAssetInternal("pixel")
    local twinkle1Image = getAssetInternal("twinkle1")
    local twinkle2Image = getAssetInternal("twinkle2")
    
    -- Use current beam properties (which have been updated in updateBeam)
    local beamLength = effect.beamLength * effect.beamProgress
    
    -- Draw particle-based beam core instead of line shapes
    local beamEndX = effect.sourceX + math.cos(effect.beamAngle) * beamLength
    local beamEndY = effect.sourceY + math.sin(effect.beamAngle) * beamLength
    
    -- Calculate beam width with pulse
    local pulseValue = effect.pulseFactor or 1.0
    local beamWidth = (effect.beamWidth or 15) * pulseValue
    
    -- Draw beam using dense particle chains
    local particlesAlongBeam = math.floor(beamLength / 3) -- One particle every 3 pixels
    
    for i = 0, particlesAlongBeam do
        local t = i / math.max(1, particlesAlongBeam)
        local coreX = effect.sourceX + (beamEndX - effect.sourceX) * t
        local coreY = effect.sourceY + (beamEndY - effect.sourceY) * t
        
        -- Perpendicular angle for beam width spread
        local perpAngle = effect.beamAngle + math.pi/2
        
        -- Draw outer glow particles
        local outerParticles = math.floor(beamWidth / 4)
        for j = 1, outerParticles do
            local offset = (j / outerParticles - 0.5) * beamWidth * 1.5
            local px = coreX + math.cos(perpAngle) * offset
            local py = coreY + math.sin(perpAngle) * offset
            
            love.graphics.setColor(
                effect.color[1] * 0.4, 
                effect.color[2] * 0.4, 
                effect.color[3] * 0.4, 
                0.3 * (1 - math.abs(offset) / (beamWidth * 0.75))
            )
            
            local sprite = onePxImage or twinkle1Image
            if sprite then
                love.graphics.draw(
                    sprite, px, py, 0,
                    1.5 + math.random() * 0.5, 1.5 + math.random() * 0.5,
                    sprite:getWidth()/2, sprite:getHeight()/2
                )
            end
        end
        
        -- Save current blend mode and set to additive for core
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        -- Draw inner core particles with additive blending
        local innerParticles = math.floor(beamWidth / 6)
        for j = 1, innerParticles do
            local offset = (j / innerParticles - 0.5) * beamWidth * 0.7
            local px = coreX + math.cos(perpAngle) * offset
            local py = coreY + math.sin(perpAngle) * offset
            
            love.graphics.setColor(
                math.min(1.0, effect.color[1] * 1.3), 
                math.min(1.0, effect.color[2] * 1.3), 
                math.min(1.0, effect.color[3] * 1.3), 
                0.7 * (1 - math.abs(offset) / (beamWidth * 0.35))
            )
            
            local sprite = (j % 2 == 0) and twinkle1Image or twinkle2Image
            if sprite then
                love.graphics.draw(
                    sprite, px, py, 0,
                    1.2 + math.random() * 0.3, 1.2 + math.random() * 0.3,
                    sprite:getWidth()/2, sprite:getHeight()/2
                )
            end
        end
        
        -- Draw brightest center particles
        local centerParticles = math.floor(beamWidth / 10) + 1
        for j = 1, centerParticles do
            local offset = (j / centerParticles - 0.5) * beamWidth * 0.3
            local px = coreX + math.cos(perpAngle) * offset
            local py = coreY + math.sin(perpAngle) * offset
            
            love.graphics.setColor(1, 1, 1, 0.9 * (1 - math.abs(offset) / (beamWidth * 0.15)))
            
            local sprite = twinkle2Image or onePxImage
            if sprite then
                love.graphics.draw(
                    sprite, px, py, 0,
                    1 + math.random() * 0.2, 1 + math.random() * 0.2,
                    sprite:getWidth()/2, sprite:getHeight()/2
                )
            end
        end
        
        -- Restore previous blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
    end
    
    -- Draw source glow using particle swarm
    local sourceParticleCount = 15
    local sourceRadius = beamWidth * 0.7
    
    for i = 1, sourceParticleCount do
        local angle = (i / sourceParticleCount) * math.pi * 2 + love.timer.getTime() * 3
        local radius = sourceRadius * (0.4 + math.random() * 0.6)
        local px = effect.sourceX + math.cos(angle) * radius
        local py = effect.sourceY + math.sin(angle) * radius
        
        love.graphics.setColor(
            effect.color[1], 
            effect.color[2], 
            effect.color[3], 
            (0.5 + math.random() * 0.3) * pulseValue
        )
        
        local sprite = (i % 3 == 0) and twinkle1Image or ((i % 3 == 1) and onePxImage or twinkle2Image)
        if sprite then
            love.graphics.draw(
                sprite, px, py, 0,
                1 + math.random() * 0.5, 1 + math.random() * 0.5,
                sprite:getWidth()/2, sprite:getHeight()/2
            )
        end
    end
    
    -- Draw impact glow using particle swarm
    local impactParticleCount = 18
    local impactRadius = beamWidth * 0.9
    
    for i = 1, impactParticleCount do
        local angle = (i / impactParticleCount) * math.pi * 2 + love.timer.getTime() * 4
        local radius = impactRadius * (0.3 + math.random() * 0.7)
        local px = beamEndX + math.cos(angle) * radius
        local py = beamEndY + math.sin(angle) * radius
        
        love.graphics.setColor(
            effect.color[1], 
            effect.color[2], 
            effect.color[3], 
            (0.6 + math.random() * 0.4) * pulseValue
        )
        
        local sprite = (i % 3 == 0) and twinkle2Image or ((i % 3 == 1) and twinkle1Image or onePxImage)
        if sprite then
            love.graphics.draw(
                sprite, px, py, 0,
                1.2 + math.random() * 0.8, 1.2 + math.random() * 0.8,
                sprite:getWidth()/2, sprite:getHeight()/2
            )
        end
    end
    
    -- Draw particles using primitive sprites
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
            
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha * 0.9)
            
            -- Choose sprite based on particle type
            local sprite = nil
            if particle.spriteType == "pixel" and onePxImage then
                sprite = onePxImage
            elseif particle.spriteType == "twinkle1" and twinkle1Image then
                sprite = twinkle1Image
            elseif particle.spriteType == "twinkle2" and twinkle2Image then
                sprite = twinkle2Image
            else
                -- Fallback to any available primitive
                sprite = onePxImage or twinkle1Image or twinkle2Image or particleImage
            end
            
            if sprite then
                love.graphics.draw(
                    sprite,
                    particle.x, particle.y,
                    0,
                    particle.scale / 3, particle.scale / 3,
                    sprite:getWidth()/2, sprite:getHeight()/2
                )
            else
                -- Final fallback
                love.graphics.circle("fill", particle.x, particle.y, particle.scale)
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

        -- Draw impact flash using particle swarm
        local flashParticleCount = math.floor(flashSize / 3)
        for i = 1, flashParticleCount do
            local angle = (i / flashParticleCount) * math.pi * 2
            local radius = flashSize * (0.2 + math.random() * 0.8)
            local px = blockX + math.cos(angle) * radius
            local py = blockY + math.sin(angle) * radius
            
            love.graphics.setColor(1, 1, 1, flashAlpha * (0.6 + math.random() * 0.4))
            
            local sprite = (i % 3 == 0) and twinkle1Image or ((i % 3 == 1) and onePxImage or twinkle2Image)
            if sprite then
                love.graphics.draw(
                    sprite, px, py, 0,
                    2 + math.random() * 2, 2 + math.random() * 2,
                    sprite:getWidth()/2, sprite:getHeight()/2
                )
            end
        end

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

    -- Restore the previous line width, blend mode, and color to avoid affecting other draw calls
    love.graphics.setLineWidth(prevLineWidth)
    love.graphics.setBlendMode(prevBlendMode[1], prevBlendMode[2])
    love.graphics.setColor(1, 1, 1, 1)
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