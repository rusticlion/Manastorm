-- wave.lua
-- Flowing wave visual effect for spells with a "wave" shape

local ParticleManager = require("vfx.ParticleManager")
local VFX

-- Lazily require VFX to avoid circular dependency
local function getAsset(assetId)
    if not VFX then VFX = require("vfx") end
    return VFX.getAsset(assetId)
end

--- Initialize wave effect particles
-- @param effect table Effect instance
local function initializeWave(effect)
    print("[WAVE EFFECT] ===== WAVE EFFECT INITIALIZED =====")
    print("[WAVE EFFECT] Particle count: " .. tostring(effect.particleCount))
    print("[WAVE EFFECT] Duration: " .. tostring(effect.duration))
    print("[WAVE EFFECT] Start scale: " .. tostring(effect.startScale))
    print("[WAVE EFFECT] Source position: (" .. tostring(effect.sourceX) .. ", " .. tostring(effect.sourceY) .. ")")
    print("[WAVE EFFECT] Target position: (" .. tostring(effect.targetX) .. ", " .. tostring(effect.targetY) .. ")")
    
    effect.particles = effect.particles or {}

    -- Calculate distance from source to target for proper particle travel
    local distance = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
    print("[WAVE EFFECT] Distance to target: " .. string.format("%.1f", distance))

    local coreCount = math.floor(effect.particleCount * 0.4)  -- Increased core particles
    local wakeCount = effect.particleCount - coreCount

    print("[WAVE EFFECT] Creating " .. coreCount .. " core particles and " .. wakeCount .. " wake particles")

    for i = 1, coreCount do
        local p = ParticleManager.createParticle()
        p.isFront = true
        p.initialAngle = (math.random() - 0.5) * 1.2
        p.initialSpeed = 200 + math.random() * 100  -- Increased speed
        
        -- Calculate proper lifespan based on distance and speed
        local particleSpeed = p.initialSpeed
        local travelTime = distance / particleSpeed
        -- Add some variance but ensure minimum time to reach target
        p.lifespan = travelTime * (1.0 + math.random() * 0.3)  -- 0-30% extra time
        
        p.scale = effect.startScale * (3.0 + math.random() * 1.0)  -- Much larger scale
        -- Use turbulence to vary how far particles spread along the wavefront
        p.turbulenceFactor = (math.random() - 0.5) * (effect.turbulence * 2)
        table.insert(effect.particles, p)
    end

    for i = 1, wakeCount do
        local p = ParticleManager.createParticle()
        p.isWake = true
        p.initialAngle = math.random() * math.pi * 2
        p.initialSpeed = 100 + math.random() * 80  -- Increased speed
        
        -- Calculate proper lifespan based on distance and speed
        local particleSpeed = p.initialSpeed
        local travelTime = distance / particleSpeed
        -- Wake particles can have more variance since they're less critical
        p.lifespan = travelTime * (0.8 + math.random() * 0.6)  -- 80-140% of travel time
        
        p.scale = effect.startScale * (2.5 + math.random() * 1.0)  -- Much larger scale
        p.turbulenceFactor = (math.random() - 0.5) * (effect.turbulence * 2)
        table.insert(effect.particles, p)
    end

    print("[WAVE EFFECT] Created " .. #effect.particles .. " total particles")
    print("[WAVE EFFECT] ===== WAVE EFFECT INITIALIZATION COMPLETE =====")
end

--- Update wave effect
-- @param effect table Effect instance
-- @param dt number Delta time
local function updateWave(effect, dt)
    local progress = effect.progress

    -- Debug output every few frames
    if effect.timer and effect.timer % 0.5 < dt then
        print("[WAVE EFFECT] Progress: " .. string.format("%.2f", progress) .. ", Particles: " .. #effect.particles)
    end

    for i = #effect.particles, 1, -1 do
        local p = effect.particles[i]
        p.age = (p.age or 0) + dt

        if p.age >= p.lifespan then
            ParticleManager.releaseParticle(p)
            table.remove(effect.particles, i)
        else
            -- Initialize particle position and velocity if not already set
            if not p.velX then
                -- Calculate direction from source to target
                local dirX = effect.targetX - effect.sourceX
                local dirY = effect.targetY - effect.sourceY
                local distance = math.sqrt(dirX^2 + dirY^2)
                
                if distance > 0 then
                    -- Normalize direction
                    dirX = dirX / distance
                    dirY = dirY / distance
                    
                    -- Add some spread to the initial direction
                    local spreadAngle = p.initialAngle
                    local cosSpread = math.cos(spreadAngle)
                    local sinSpread = math.sin(spreadAngle)
                    
                    -- Combine base direction with spread
                    local finalDirX = dirX * cosSpread - dirY * sinSpread
                    local finalDirY = dirX * sinSpread + dirY * cosSpread
                    
                    p.velX = finalDirX * p.initialSpeed
                    p.velY = finalDirY * p.initialSpeed
                else
                    -- Fallback if target is at same position as source
                    p.velX = math.cos(p.initialAngle) * p.initialSpeed
                    p.velY = math.sin(p.initialAngle) * p.initialSpeed
                end
                
                p.x = effect.sourceX
                p.y = effect.sourceY
            end

            -- Calculate current distance to target
            local currentDistance = math.sqrt((effect.targetX - p.x)^2 + (effect.targetY - p.y)^2)
            local lifeProg = p.age / p.lifespan

            if progress < effect.coalescePoint then
                -- Initial expansion phase - particles move outward from source
                p.x = p.x + p.velX * dt
                p.y = p.y + p.velY * dt
            else
                -- Coalescence phase - particles converge toward target
                local targetX, targetY
                if p.isFront then
                    local angleToTarget = math.atan2(effect.targetY - p.y, effect.targetX - p.x)
                    -- Default turbulenceFactor to 0 to avoid nil errors
                    local tf = p.turbulenceFactor or 0
                    targetX = effect.targetX + math.cos(angleToTarget + math.pi / 2) * (tf * effect.wavefrontWidth)
                    targetY = effect.targetY + math.sin(angleToTarget + math.pi / 2) * (tf * effect.wavefrontWidth)
                else
                    targetX = effect.targetX
                    targetY = effect.targetY
                end

                -- Calculate convergence speed based on remaining time
                local remainingTime = p.lifespan - p.age
                local convergenceSpeed = currentDistance / math.max(remainingTime, 0.1)  -- Avoid division by zero
                
                local targetVelX = (targetX - p.x) * convergenceSpeed
                local targetVelY = (targetY - p.y) * convergenceSpeed

                -- Smooth transition to target velocity
                local convergenceRate = 5.0  -- How quickly to converge
                p.velX = p.velX + (targetVelX - p.velX) * dt * convergenceRate
                p.velY = p.velY + (targetVelY - p.velY) * dt * convergenceRate

                p.x = p.x + p.velX * dt
                p.y = p.y + p.velY * dt
            end

            -- Use a smoother alpha curve that starts higher and stays visible longer
            -- Fade out more gradually as particles approach target
            local fadeStart = 0.8  -- Start fading at 80% of lifespan
            if lifeProg < fadeStart then
                p.alpha = 0.4 + 0.6 * (lifeProg / fadeStart)
            else
                local fadeProg = (lifeProg - fadeStart) / (1.0 - fadeStart)
                p.alpha = 1.0 * (1.0 - fadeProg)
            end
        end
    end
end

--- Draw wave effect
-- @param effect table Effect instance
local function drawWave(effect)
    local glowAsset = getAsset(effect.glowAssetKey or "twinkle1")
    local sparkleAsset = getAsset(effect.sparkleAssetKey or "pixel")

    -- Debug output only if assets are missing
    if not glowAsset or not sparkleAsset then
        print("[WAVE EFFECT] Missing assets - Glow: " .. tostring(glowAsset) .. ", Sparkle: " .. tostring(sparkleAsset))
    end

    love.graphics.setBlendMode("add")
    local drawnCount = 0
    for _, p in ipairs(effect.particles) do
        if p.alpha and p.alpha > 0 then
            -- Use effect color but ensure it's bright enough
            local color = effect.color or {1.0, 1.0, 1.0}
            -- Boost brightness for better visibility
            local r = math.min(1.0, color[1] * 1.5)
            local g = math.min(1.0, color[2] * 1.5)
            local b = math.min(1.0, color[3] * 1.5)
            love.graphics.setColor(r, g, b, p.alpha)
            
            local asset = p.isFront and sparkleAsset or glowAsset
            if asset then
                love.graphics.draw(asset, p.x, p.y, 0, p.scale, p.scale, asset:getWidth() / 2, asset:getHeight() / 2)
                drawnCount = drawnCount + 1
            end
        end
    end
    love.graphics.setBlendMode("alpha")
    
    -- Only report if we drew particles
    if drawnCount > 0 and effect.timer and effect.timer % 1.0 < 0.016 then
        print("[WAVE EFFECT] Drew " .. drawnCount .. " particles")
    end
end

return {
    initialize = initializeWave,
    update = updateWave,
    draw = drawWave,
}

