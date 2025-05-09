-- projectile.lua
-- Projectile VFX module for handling spell projectiles

-- Import dependencies
local Constants = require("core.Constants")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for projectile effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for projectile effects
local function updateProjectile(effect, dt)
    -- Initialize effect default values if not already set
    effect.trailLength = effect.trailLength or 10 -- Default trail length
    effect.trailPoints = effect.trailPoints or {} -- Initialize trail points array if nil
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.color = effect.color or {1, 1, 1} -- Default color (white)
    effect.size = effect.size or 1.0 -- Default size
    effect.arcHeight = effect.arcHeight or 60 -- Default arc height
    effect.frameDuration = effect.frameDuration or 0.1 -- Default frame duration
    effect.currentFrame = effect.currentFrame or 1 -- Default current frame
    effect.frameTimer = effect.frameTimer or 0 -- Default frame timer
    effect.visualProgress = effect.visualProgress or effect.progress -- Default visual progress
    
    -- Ensure path-related properties are set
    effect.useSourcePosition = (effect.useSourcePosition ~= false) -- Default to true
    effect.useTargetPosition = (effect.useTargetPosition ~= false) -- Default to true
    effect.useCurvedPath = (effect.useCurvedPath ~= false) -- Default to true for bolt effects
    effect.useTrail = (effect.useTrail ~= false) -- Default to true
    
    if #effect.trailPoints == 0 then
        -- Initialize trail with source position
        for i = 1, effect.trailLength do
            table.insert(effect.trailPoints, {
                x = effect.sourceX, 
                y = effect.sourceY,
                alpha = i == 1 and 1.0 or (1.0 - (i-1)/effect.trailLength)
            })
        end
    end
    
    -- Get effect parameters with defaults
    local arcHeight = effect.arcHeight or 60
    
    -- Use visualProgress for blocked effects, otherwise use normal progress
    -- IMPORTANT: Only use visualProgress if the effect is blocked
    local baseProgress = effect.isBlocked and effect.visualProgress or effect.progress
    
    print(string.format("[PROJECTILE PROGRESS] isBlocked=%s, progress=%.2f, visualProgress=%.2f, baseProgress=%.2f",
        tostring(effect.isBlocked), effect.progress or 0, effect.visualProgress or 0, baseProgress))
    
    -- Calculate projectile position along the path
    local startX, startY = effect.sourceX, effect.sourceY
    local endX, endY = effect.targetX, effect.targetY
    
    -- For remote casting, override startX/Y to be the actual cast position
    if effect.useSourcePosition and effect.remoteSourceX and effect.remoteSourceY then
        startX = effect.remoteSourceX
        startY = effect.remoteSourceY
    end
    
    -- Special case for parabolic block
    local blockPoint = effect.blockPoint or 1.0
    
    -- Adjust the trajectory for blocked projectiles
    if effect.isBlocked and baseProgress > blockPoint then
        baseProgress = blockPoint
    end
    
    -- Calculate the current position of the projectile head
    local head = { 
        x = startX, 
        y = startY 
    }
    
    -- Ensure we're using a valid progress value
    baseProgress = baseProgress or (effect.progress or 0)
    
    -- Now calculate the position along the path
    if effect.useCurvedPath then
        -- Use a parabolic path
        head.x = startX + (endX - startX) * baseProgress
        head.y = startY + (endY - startY) * baseProgress
        
        -- Apply parabolic arc
        -- Calculate a parabola that starts at source, ends at target, and peaks at height
        local arcProgress = baseProgress
        
        if effect.isBlocked and blockPoint < 1.0 then
            -- The arc should complete over the shorter range to the block point
            arcProgress = baseProgress / blockPoint
        end
        
        -- Standard parabola: 4 * h * x * (1-x) where h is height and x is [0,1] progress
        local arcFactor = 4 * arcHeight * arcProgress * (1 - arcProgress)
        
        -- Apply the vertical offset
        head.y = head.y - arcFactor
    else
        -- Use a straight-line path
        head.x = startX + (endX - startX) * baseProgress
        head.y = startY + (endY - startY) * baseProgress
    end
    
    -- For source tracking, update the source position if needed
    if effect.useSourcePosition and effect.followSourceEntity and effect.sourceEntity then
        if effect.sourceEntity.x and effect.sourceEntity.y then
            effect.sourceX = effect.sourceEntity.x
            effect.sourceY = effect.sourceEntity.y
        end
    end
    
    -- For target tracking, update the target position if needed
    if effect.useTargetPosition and effect.followTargetEntity and effect.targetEntity then
        if effect.targetEntity.x and effect.targetEntity.y then
            effect.targetX = effect.targetEntity.x
            effect.targetY = effect.targetEntity.y
        end
    end
    
    -- Update trail points (shifting all points to make room for the new head)
    if #effect.trailPoints > 0 then
        -- For trail with length n, we want to preserve n points
        -- Remove the last point
        table.remove(effect.trailPoints)
        
        -- Insert the new head position at the beginning
        table.insert(effect.trailPoints, 1, {
            x = head.x,
            y = head.y,
            alpha = 1.0
        })
        
        -- Update alpha values for the trail
        for i = 2, #effect.trailPoints do
            effect.trailPoints[i].alpha = 1.0 - (i-1)/effect.trailLength
        end
    end
    
    -- Update particles for the projectile trail
    if effect.particles then
        -- Add new particles at the current head position
        local particleRate = effect.particleRate or 0.3 -- Default rate if not provided
        if math.random() < particleRate then
            -- Create a new particle
            local particle = {
                x = head.x,
                y = head.y,
                xVel = math.random(-30, 30),
                yVel = math.random(-30, 30),
                size = math.random(5, 15) * (effect.size or 1.0),
                alpha = math.random() * 0.5 + 0.5,
                life = 0,
                maxLife = math.random() * 0.3 + 0.1,
                color = effect.color or {1, 1, 1} -- Default to white if no color specified
            }
            
            -- Add the particle to the effect
            table.insert(effect.particles, particle)
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
            
            -- Ensure particle has all needed properties
            particle.x = particle.x or head.x
            particle.y = particle.y or head.y
            particle.xVel = particle.xVel or 0
            particle.yVel = particle.yVel or 0
            particle.life = particle.life or 0
            particle.maxLife = particle.maxLife or 0.5
            
            -- Update particle physics
            particle.x = particle.x + particle.xVel * dt
            particle.y = particle.y + particle.yVel * dt
            particle.life = particle.life + dt
            
            -- Calculate fade based on life
            particle.alpha = 1.0 - (particle.life / particle.maxLife)
            
            -- Remove dead particles
            if particle.life >= particle.maxLife then
                table.remove(effect.particles, i)
            else
                i = i + 1
            end
            
            ::next_particle::
        end
    end
    
    -- Update bolt animation frame (if using sprites)
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
    
    -- Write the head position to the effect for drawing
    effect.headX = head.x
    effect.headY = head.y
end

-- Draw function for projectile effects
local function drawProjectile(effect)
    -- Make sure essential properties exist
    effect.color = effect.color or {1, 1, 1} -- Default color
    effect.size = effect.size or 1.0 -- Default size
    effect.particles = effect.particles or {} -- Initialize particles array if nil
    effect.trailPoints = effect.trailPoints or {} -- Initialize trail points array if nil
    effect.currentFrame = effect.currentFrame or 1 -- Default current frame
    effect.useCurvedPath = (effect.useCurvedPath ~= false) -- Default to true for bolt effects
    effect.useTrail = (effect.useTrail ~= false) -- Default to true
    
    -- Debug info for drawing
    print(string.format("[PROJECTILE DRAW] Effect: %s, Timer: %.2f, Progress: %.2f", 
        effect.name or "unnamed", effect.timer or 0, effect.progress or 0))
    print(string.format("[PROJECTILE DRAW] Head Position: (%.0f, %.0f), Source: (%.0f, %.0f), Target: (%.0f, %.0f)", 
        effect.headX or 0, effect.headY or 0, 
        effect.sourceX or 0, effect.sourceY or 0,
        effect.targetX or 0, effect.targetY or 0))
    
    -- Ensure the head position exists
    if not effect.headX or not effect.headY then
        -- If no head position, calculate it based on progress
        local progress = effect.isBlocked and effect.visualProgress or effect.progress or 0
        effect.headX = effect.sourceX + (effect.targetX - effect.sourceX) * progress
        effect.headY = effect.sourceY + (effect.targetY - effect.sourceY) * progress
        
        print(string.format("[PROJECTILE DRAW] Recalculated head position to (%.0f, %.0f) with progress %.2f", 
            effect.headX, effect.headY, progress))
    end
    
    -- Get assets
    local particleImage = getAssetInternal("fireParticle")
    local glowImage = getAssetInternal("fireGlow")
    local impactImage = getAssetInternal("impactRing")
    
    -- Get bolt frames if needed
    local boltFrames = nil
    if effect.useSprites then
        boltFrames = getAssetInternal("boltFrames")
    end
    
    -- Calculate the actual trajectory angle for aimed shots
    -- This will be used for sprite rotation if it's a bolt
    local trajectoryAngle = nil
    if effect.useSourcePosition and effect.useTargetPosition then
        -- Calculate direction vector from current source to target
        local dirX = effect.targetX - effect.sourceX
        local dirY = effect.targetY - effect.sourceY
        
        -- Calculate the angle
        trajectoryAngle = math.atan2(dirY, dirX)
    end
    
    -- Get the head position (calculated in update)
    local head = {
        x = effect.headX or effect.sourceX,
        y = effect.headY or effect.sourceY
    }
    
    -- If we have a trail, draw it
    if effect.useTrail and #effect.trailPoints > 1 then
        -- Draw trail (from oldest to newest)
        for i = #effect.trailPoints, 1, -1 do
            local point = effect.trailPoints[i]
            local trailSize = (effect.size or 1.0) * 3 * (1 - (i-1)/#effect.trailPoints)
            local trailAlpha = point.alpha * 0.4
            
            -- Draw trail glow at each point
            local color = effect.color or {1, 1, 1} -- Default to white if no color
            love.graphics.setColor(
                color[1], 
                color[2], 
                color[3], 
                trailAlpha
            )
            
            -- Draw a circle for each trail point
            if glowImage then
                love.graphics.draw(
                    glowImage,
                    point.x, point.y,
                    0,
                    trailSize, trailSize,
                    glowImage:getWidth()/2, glowImage:getHeight()/2
                )
            else
                -- Fallback to a circle if glow asset is missing
                love.graphics.circle("fill", point.x, point.y, trailSize * 10)
            end
        end
    end
    
    -- Draw the particles
    if effect.particles then
        for _, particle in ipairs(effect.particles) do
            -- Skip invalid particles
            if not particle then
                goto next_draw_particle
            end
            
            local particleColor = particle.color or effect.color or {1, 1, 1}
            love.graphics.setColor(
                particleColor[1],
                particleColor[2],
                particleColor[3],
                (particle.alpha or 0.5) * 0.7
            )
            
            -- Draw particle
            if particleImage then
                love.graphics.draw(
                    particleImage,
                    particle.x, particle.y,
                    0,
                    (particle.size or 5)/20, (particle.size or 5)/20,
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
            else
                -- Fallback to a circle if particle asset is missing
                love.graphics.circle("fill", particle.x, particle.y, particle.size or 5)
            end
            
            ::next_draw_particle::
        end
    end
    
    -- Draw the projectile head
    local leadingIntensity = 1.3 -- Make the leading edge brighter
    
    -- Draw sprite-based projectile (like a lightning bolt)
    if effect.useSprites and boltFrames then
        -- Use projectile sprites (like lightning bolt)
        local frame = boltFrames[effect.currentFrame]
        local scale = effect.size * 2
        
        -- Rotate the bolt based on trajectory
        local rotation = trajectoryAngle or 0
        
        love.graphics.setColor(
            effect.color[1], 
            effect.color[2], 
            effect.color[3], 
            0.9
        )
        
        love.graphics.draw(
            frame, 
            head.x, head.y,
            rotation,
            scale, scale,
            frame:getWidth()/2, frame:getHeight()/2
        )
    else
        -- Draw particle-based projectile
        
        -- Draw outer glow
        local color = effect.color or {1, 1, 1}
        love.graphics.setColor(
            color[1] * 0.8, 
            color[2] * 0.8, 
            color[3] * 0.8, 
            0.5
        )
        local outerGlowScale = (effect.size or 1.0) * 5
        
        if glowImage then
            love.graphics.draw(
                glowImage,
                head.x, head.y,
                0,
                outerGlowScale, outerGlowScale,
                glowImage:getWidth()/2, glowImage:getHeight()/2
            )
        else
            -- Fallback
            love.graphics.circle("fill", head.x, head.y, outerGlowScale * 10)
        end
        
        -- Inner glow (brightest) - uses additive blending for extra brightness
        local color = effect.color or {1, 1, 1}
        love.graphics.setColor(
            math.min(1.0, color[1] * leadingIntensity), 
            math.min(1.0, color[2] * leadingIntensity), 
            math.min(1.0, color[3] * leadingIntensity), 
            0.7
        )
        local innerGlowScale = (effect.size or 1.0) * 2
        
        -- Save current blend mode and set to additive for the brightest elements
        local prevMode = {love.graphics.getBlendMode()}
        love.graphics.setBlendMode("add")
        
        if glowImage then
            love.graphics.draw(
                glowImage,
                head.x, head.y,
                0,
                innerGlowScale, innerGlowScale,
                glowImage:getWidth()/2, glowImage:getHeight()/2
            )
        else
            -- Fallback
            love.graphics.circle("fill", head.x, head.y, innerGlowScale * 10)
        end
        
        -- Restore previous blend mode
        love.graphics.setBlendMode(prevMode[1], prevMode[2])
        
        -- Core (solid center)
        love.graphics.setColor(1, 1, 1, 0.9)
        local coreScale = (effect.size or 1.0) * 0.5
        
        if particleImage then
            love.graphics.draw(
                particleImage,
                head.x, head.y,
                0,
                coreScale, coreScale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        else
            -- Fallback
            love.graphics.circle("fill", head.x, head.y, coreScale * 10)
        end
    end
    
    -- Draw block impact if projectile was blocked
    if effect.isBlocked and effect.blockPoint and effect.progress > effect.blockPoint then
        -- Calculate the impact position at the block point
        local blockX = effect.sourceX + (effect.targetX - effect.sourceX) * effect.blockPoint
        local blockY = effect.sourceY + (effect.targetY - effect.sourceY) * effect.blockPoint
        
        -- If using curved path, apply the arc height
        if effect.useCurvedPath then
            -- Apply parabolic arc at block point
            local arcFactor = 4 * (effect.arcHeight or 60) * effect.blockPoint * (1 - effect.blockPoint)
            blockY = blockY - arcFactor
        end
        
        -- Draw impact flash
        local impactProgress = (effect.progress - effect.blockPoint) / (1 - effect.blockPoint)
        local impactSize = 20 * (1 - impactProgress) * effect.size
        local impactAlpha = 0.7 * (1 - impactProgress)
        
        if impactAlpha > 0 then
            love.graphics.setColor(1, 1, 1, impactAlpha)
            
            -- Save current blend mode and set to additive for the brightest elements
            local prevMode = {love.graphics.getBlendMode()}
            love.graphics.setBlendMode("add")
            
            if impactImage then
                love.graphics.draw(
                    impactImage,
                    blockX, blockY,
                    0,
                    impactSize/10, impactSize/10,
                    impactImage:getWidth()/2, impactImage:getHeight()/2
                )
            else
                -- Fallback
                love.graphics.circle("fill", blockX, blockY, impactSize)
            end
            
            -- Draw shield runes if this was blocked by a shield
            local shieldType = effect.blockType or effect.options.shieldType
            if shieldType and (shieldType == "ward" or shieldType == "barrier") then
                -- Shield-specific visualization
                local runeImages = getAssetInternal("runes")
                if runeImages and #runeImages > 0 then
                    -- Get a random rune
                    local runeIndex = (effect.id % #runeImages) + 1
                    local runeImage = runeImages[runeIndex]
                    
                    -- Draw the rune
                    local runeSize = 0.5 * impactSize * (1 + 0.5 * math.sin(impactProgress * math.pi * 4))
                    local runeAlpha = impactAlpha * 0.8
                    love.graphics.setColor(1, 1, 1, runeAlpha)
                    
                    if runeImage then
                        love.graphics.draw(
                            runeImage,
                            blockX, blockY,
                            math.pi * 2 * impactProgress,
                            runeSize, runeSize,
                            runeImage:getWidth()/2, runeImage:getHeight()/2
                        )
                    end
                end
            end
            
            -- Restore previous blend mode
            love.graphics.setBlendMode(prevMode[1], prevMode[2])
        end
    end
end

-- Return the module
return {
    update = updateProjectile,
    draw = drawProjectile
}