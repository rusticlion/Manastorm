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
    effect.particles = effect.particles or {}

    local coreCount = math.floor(effect.particleCount * 0.3)
    local wakeCount = effect.particleCount - coreCount

    for i = 1, coreCount do
        local p = ParticleManager.createParticle()
        p.isFront = true
        p.initialAngle = (math.random() - 0.5) * 1.2
        p.initialSpeed = 150 + math.random() * 50
        p.scale = effect.startScale * (1.2 + math.random() * 0.3)
        p.lifespan = effect.duration * (0.8 + math.random() * 0.2)
        -- Use turbulence to vary how far particles spread along the wavefront
        p.turbulenceFactor = (math.random() - 0.5) * (effect.turbulence * 2)
        table.insert(effect.particles, p)
    end

    for i = 1, wakeCount do
        local p = ParticleManager.createParticle()
        p.isWake = true
        p.initialAngle = math.random() * math.pi * 2
        p.initialSpeed = 50 + math.random() * 40
        p.scale = effect.startScale * (0.5 + math.random() * 0.5)
        p.lifespan = effect.duration * (0.5 + math.random() * 0.3)
        p.turbulenceFactor = (math.random() - 0.5) * (effect.turbulence * 2)
        table.insert(effect.particles, p)
    end
end

--- Update wave effect
-- @param effect table Effect instance
-- @param dt number Delta time
local function updateWave(effect, dt)
    local progress = effect.progress

    for i = #effect.particles, 1, -1 do
        local p = effect.particles[i]
        p.age = (p.age or 0) + dt

        if p.age >= p.lifespan then
            ParticleManager.releaseParticle(p)
            table.remove(effect.particles, i)
        else
            if progress < effect.coalescePoint then
                if not p.velX then
                    p.velX = math.cos(p.initialAngle) * p.initialSpeed
                    p.velY = math.sin(p.initialAngle) * p.initialSpeed
                    p.x = effect.sourceX
                    p.y = effect.sourceY
                end
                p.x = p.x + p.velX * dt
                p.y = p.y + p.velY * dt
            else
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

                local targetVelX = (targetX - p.x) * 2
                local targetVelY = (targetY - p.y) * 2

                p.velX = (p.velX or 0) + (targetVelX - (p.velX or 0)) * dt * 3.0
                p.velY = (p.velY or 0) + (targetVelY - (p.velY or 0)) * dt * 3.0

                p.x = p.x + p.velX * dt
                p.y = p.y + p.velY * dt
            end

            local lifeProg = p.age / p.lifespan
            p.alpha = math.sin(lifeProg * math.pi)
        end
    end
end

--- Draw wave effect
-- @param effect table Effect instance
local function drawWave(effect)
    local glowAsset = getAsset(effect.glowAssetKey or "twinkle1")
    local sparkleAsset = getAsset(effect.sparkleAssetKey or "pixel")

    love.graphics.setBlendMode("add")
    for _, p in ipairs(effect.particles) do
        if p.alpha and p.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], p.alpha)
            local asset = p.isFront and sparkleAsset or glowAsset
            if asset then
                love.graphics.draw(asset, p.x, p.y, 0, p.scale, p.scale, asset:getWidth() / 2, asset:getHeight() / 2)
            end
        end
    end
    love.graphics.setBlendMode("alpha")
end

return {
    initialize = initializeWave,
    update = updateWave,
    draw = drawWave,
}

