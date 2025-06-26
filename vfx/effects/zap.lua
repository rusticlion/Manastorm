-- zap.lua
-- Simple lightning zap effect drawing tiled sprites between source and target

local VFX

local function getAssetInternal(assetId)
    if not VFX then
        VFX = require("vfx")
    end
    return VFX.getAsset(assetId)
end

local function initializeZap(effect)
    effect.timer = 0
end

local function updateZap(effect, dt)
    -- ensure defaults
    effect.useSourcePosition = (effect.useSourcePosition ~= false)
    effect.useTargetPosition = (effect.useTargetPosition ~= false)
    effect.followSourceEntity = (effect.followSourceEntity ~= false)
    effect.followTargetEntity = (effect.followTargetEntity ~= false)
    effect.color = effect.color or {1,1,1}
    effect.segmentLength = effect.segmentLength or 20

    if effect.useSourcePosition and effect.followSourceEntity and effect.sourceEntity then
        if effect.sourceEntity.x and effect.sourceEntity.y then
            effect.sourceX = effect.sourceEntity.x
            effect.sourceY = effect.sourceEntity.y
        end
    end
    if effect.useTargetPosition and effect.followTargetEntity and effect.targetEntity then
        if effect.targetEntity.x and effect.targetEntity.y then
            effect.targetX = effect.targetEntity.x
            effect.targetY = effect.targetEntity.y
        end
    end

    local dx = (effect.targetX or 0) - (effect.sourceX or 0)
    local dy = (effect.targetY or 0) - (effect.sourceY or 0)
    effect.angle = math.atan2(dy, dx)
    effect.length = math.sqrt(dx*dx + dy*dy)
    effect.headX = (effect.sourceX or 0) + dx * (effect.progress or 0)
    effect.headY = (effect.sourceY or 0) + dy * (effect.progress or 0)
end

local function drawZap(effect)
    local frames = getAssetInternal("zapFrames")
    if not frames or #frames < 3 then return end
    local seg1, seg2, terminus = frames[1], frames[2], frames[3]

    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 1)

    local segLen = effect.segmentLength or seg1:getWidth()
    local drawn = 0
    local maxLen = math.min(effect.length, effect.length * (effect.progress or 0))

    while drawn + segLen < maxLen do
        local img = (math.floor(drawn/segLen) % 2 == 0) and seg1 or seg2
        local x = effect.sourceX + math.cos(effect.angle) * drawn
        local y = effect.sourceY + math.sin(effect.angle) * drawn
        love.graphics.draw(img, x, y, effect.angle, 1, 1, 0, img:getHeight()/2)
        drawn = drawn + segLen
    end

    -- draw terminus at head
    love.graphics.draw(terminus, effect.headX, effect.headY, effect.angle, 1, 1,
        terminus:getWidth()/2, terminus:getHeight()/2)
end

return {
    initialize = initializeZap,
    update = updateZap,
    draw = drawZap
}
