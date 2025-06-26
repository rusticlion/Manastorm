local ParticleManager = require("vfx.ParticleManager")
local VFX

local function getAsset(assetId)
    if not VFX then
        VFX = require("vfx")
    end
    return VFX.getAsset(assetId)
end

-- Initialize particles for a cone or blast effect
local function initializeCone(effect)
    effect.particles = {}

    local dirX = effect.targetX - effect.sourceX
    local dirY = effect.targetY - effect.sourceY
    local baseAngle = math.atan2(dirY, dirX)
    local halfConeAngle = (effect.coneAngle * math.pi / 180) / 2

    for i = 1, effect.particleCount do
        local angle = baseAngle + (math.random() * 2 - 1) * halfConeAngle
        local distance = math.random() * effect.coneLength
        local waveIndex = math.floor(math.random() * (effect.waveCount or 3)) + 1

        local p = ParticleManager.createConeParticle(effect, angle, distance, true, waveIndex)
        p.delay = (waveIndex / effect.waveCount) * (effect.duration * 0.4)
        table.insert(effect.particles, p)
    end
end

-- Update all particles in the cone each frame
local function updateCone(effect, dt)
    local i = 1
    while i <= #effect.particles do
        local p = effect.particles[i]

        if effect.timer >= p.delay and not p.active then
            p.active = true
            p.age = 0
            p.startX = effect.sourceX
            p.startY = effect.sourceY
        end

        if p.active then
            p.age = p.age + dt
            local lifeProgress = math.min(1.0, p.age / (effect.duration - p.delay))
            local currentDist = p.distance * lifeProgress
            p.x = p.startX + math.cos(p.angle) * currentDist
            p.y = p.startY + math.sin(p.angle) * currentDist
            p.alpha = math.sin(lifeProgress * math.pi)
        end

        i = i + 1
    end
end

-- Draw all particles for the cone effect
local function drawCone(effect)
    local sparkleAsset = getAsset(effect.sparkleAssetKey or "sparkle")
    love.graphics.setBlendMode("add")

    for _, p in ipairs(effect.particles) do
        if p.active and p.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], p.alpha)
            if sparkleAsset then
                love.graphics.draw(
                    sparkleAsset,
                    p.x,
                    p.y,
                    p.angle,
                    p.scale,
                    p.scale,
                    sparkleAsset:getWidth() / 2,
                    sparkleAsset:getHeight() / 2
                )
            end
        end
    end

    love.graphics.setBlendMode("alpha")
end

return {
    initialize = initializeCone,
    update = updateCone,
    draw = drawCone,
}
