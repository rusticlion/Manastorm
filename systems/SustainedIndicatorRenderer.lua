local SustainedIndicatorRenderer = {}

local Constants = require("core.Constants")

local SLOT_Y_OFFSETS = {30, 0, -30}

local DEFAULT_TYPE_COLORS = {
    trap = {0.72, 0.42, 0.95, 1.0},
    field = {0.98, 0.84, 0.34, 1.0},
}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function withAlpha(color, alpha)
    return {color[1] or 1, color[2] or 1, color[3] or 1, alpha or color[4] or 1}
end

local function getEntryColor(entry)
    if entry and entry.spell and entry.spell.affinity then
        return withAlpha(Constants.getColorForTokenType(entry.spell.affinity), 1.0)
    end

    return DEFAULT_TYPE_COLORS[entry and entry.type] or {0.85, 0.85, 0.85, 1.0}
end

local function getWizardSide(wizard)
    if not wizard or not wizard.gameState or not wizard.gameState.wizards then
        return -1
    end

    for _, other in ipairs(wizard.gameState.wizards) do
        if other ~= wizard then
            return wizard.x <= other.x and -1 or 1
        end
    end

    return -1
end

local function getOpponent(wizard)
    if not wizard or not wizard.gameState or not wizard.gameState.wizards then
        return nil
    end

    for _, other in ipairs(wizard.gameState.wizards) do
        if other ~= wizard then
            return other
        end
    end

    return nil
end

local function getSlotAnchor(entry)
    local wizard = entry and entry.wizard
    if not wizard then
        return 0, 0
    end

    local slotIndex = clamp(entry.slotIndex or 2, 1, 3)
    local xOffset = wizard.currentXOffset or 0
    local yOffset = wizard.currentYOffset or 0

    return wizard.x + xOffset, wizard.y + SLOT_Y_OFFSETS[slotIndex] + yOffset
end

local function getArenaFloorY(gameState)
    if gameState and gameState.wizards and #gameState.wizards > 0 then
        local total = 0
        local count = 0
        for _, wizard in ipairs(gameState.wizards) do
            total = total + wizard.y + (wizard.currentYOffset or 0) + 40
            count = count + 1
        end

        if count > 0 then
            return total / count
        end
    end

    return love.graphics.getHeight() * 0.68
end

local function getArenaHalfWidth(gameState)
    if gameState and gameState.wizards and #gameState.wizards >= 2 then
        local left = gameState.wizards[1]
        local right = gameState.wizards[2]
        local leftX = left.x + (left.currentXOffset or 0)
        local rightX = right.x + (right.currentXOffset or 0)
        return math.abs(rightX - leftX) * 0.5 + 90
    end

    return love.graphics.getWidth() * 0.28
end

local function drawGlowLine(points, color, width, glowAlpha)
    local prevWidth = love.graphics.getLineWidth()
    local blendMode, alphaMode = love.graphics.getBlendMode()

    love.graphics.setBlendMode("add")
    love.graphics.setLineWidth(width + 3)
    love.graphics.setColor(color[1], color[2], color[3], glowAlpha)
    love.graphics.line(points)

    love.graphics.setBlendMode(blendMode, alphaMode)
    love.graphics.setLineWidth(width)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.line(points)
    love.graphics.setLineWidth(prevWidth)
end

local function drawPulseOnPath(points, color, phase)
    local t = (love.timer.getTime() * 0.45 + phase) % 1.0
    local px
    local py

    if t < 0.5 then
        local localT = t * 2
        px = lerp(points[1], points[3], localT)
        py = lerp(points[2], points[4], localT)
    else
        local localT = (t - 0.5) * 2
        px = lerp(points[3], points[5], localT)
        py = lerp(points[4], points[6], localT)
    end

    love.graphics.setColor(color[1], color[2], color[3], 0.85)
    love.graphics.circle("fill", px, py, 2.5)

    local blendMode, alphaMode = love.graphics.getBlendMode()
    love.graphics.setBlendMode("add")
    love.graphics.setColor(color[1], color[2], color[3], 0.22)
    love.graphics.circle("fill", px, py, 6)
    love.graphics.setBlendMode(blendMode, alphaMode)
end

local function drawMarkerLabel(label, x, y, color, width)
    width = width or 56

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.printf(label, x - width / 2 + 1, y + 1, width, "center")
    love.graphics.setColor(color[1], color[2], color[3], 0.88)
    love.graphics.printf(label, x - width / 2, y, width, "center")
end

local function drawTrapTriggerIcon(condition, x, y, color, intensity)
    local prevWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(2)
    love.graphics.setColor(color[1], color[2], color[3], 0.9)

    if condition == "on_opponent_elevate" then
        love.graphics.line(x - 7, y + 5, x, y - 7, x + 7, y + 5)
        love.graphics.line(x - 7, y + 5, x - 2, y + 5)
        love.graphics.line(x + 2, y + 5, x + 7, y + 5)
    elseif condition == "on_opponent_far" then
        love.graphics.line(x - 11, y, x - 2, y)
        love.graphics.line(x + 2, y, x + 11, y)
        love.graphics.line(x - 11, y, x - 7, y - 4)
        love.graphics.line(x - 11, y, x - 7, y + 4)
        love.graphics.line(x + 11, y, x + 7, y - 4)
        love.graphics.line(x + 11, y, x + 7, y + 4)
    elseif condition == "on_opponent_cast" then
        love.graphics.circle("line", x, y, 4 + intensity)
        love.graphics.circle("line", x, y, 8 + intensity * 1.5)
    else
        love.graphics.circle("fill", x, y, 3)
    end

    love.graphics.setLineWidth(prevWidth)
end

local function getTrapLabel(condition)
    if condition == "on_opponent_elevate" then
        return "AIR"
    end
    if condition == "on_opponent_far" then
        return "FAR"
    end
    if condition == "on_opponent_cast" then
        return "CAST"
    end
    return "TRAP"
end

local function isTrapHot(entry)
    local condition = entry and entry.triggerData and entry.triggerData.condition
    local wizard = entry and entry.wizard
    local opponent = getOpponent(wizard)

    if condition == "on_opponent_elevate" then
        return opponent and opponent.elevation == Constants.ElevationState.AERIAL
    end

    if condition == "on_opponent_far" then
        return wizard and wizard.gameState and wizard.gameState.rangeState == Constants.RangeState.FAR
    end

    if condition == "on_opponent_cast" then
        return opponent and opponent.justCastSpellThisFrame
    end

    return false
end

local function drawTrapMarker(entry, screenCenterX, arenaFloorY)
    local slotX, slotY = getSlotAnchor(entry)
    local side = getWizardSide(entry.wizard)
    local markerX = lerp(slotX, screenCenterX + side * 28, 0.58)
    local markerY = lerp(slotY, arenaFloorY - 18, 0.72) + ((entry.slotIndex or 2) - 2) * 8
    local color = getEntryColor(entry)
    local hot = isTrapHot(entry)
    local pulse = hot and 0.9 or (0.35 + math.abs(math.sin(love.timer.getTime() * 1.8 + (entry.slotIndex or 0))) * 0.3)
    local lineColor = withAlpha(color, hot and 0.72 or 0.42)
    local curveY = math.min(slotY, markerY) - 24
    local tetherPoints = {
        slotX, slotY,
        lerp(slotX, markerX, 0.5), curveY,
        markerX, markerY
    }

    drawGlowLine(tetherPoints, lineColor, 1.5, hot and 0.22 or 0.1)
    drawPulseOnPath(tetherPoints, color, (entry.slotIndex or 0) * 0.17 + (side > 0 and 0.2 or 0.0))

    local diamondRadius = hot and 18 or 15
    local diamondPoints = {
        markerX, markerY - diamondRadius,
        markerX + diamondRadius, markerY,
        markerX, markerY + diamondRadius,
        markerX - diamondRadius, markerY
    }

    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.polygon("fill",
        markerX, markerY - diamondRadius - 2,
        markerX + diamondRadius + 2, markerY,
        markerX, markerY + diamondRadius + 2,
        markerX - diamondRadius - 2, markerY
    )

    love.graphics.setColor(color[1], color[2], color[3], hot and 0.18 or 0.12)
    love.graphics.polygon("fill", diamondPoints)

    local prevWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(hot and 2.5 or 2)
    love.graphics.setColor(color[1], color[2], color[3], hot and 0.92 or 0.72)
    love.graphics.polygon("line", diamondPoints)
    love.graphics.setLineWidth(prevWidth)

    if hot then
        local blendMode, alphaMode = love.graphics.getBlendMode()
        love.graphics.setBlendMode("add")
        love.graphics.setColor(color[1], color[2], color[3], 0.16)
        love.graphics.circle("line", markerX, markerY, diamondRadius + 8 + pulse * 4)
        love.graphics.setBlendMode(blendMode, alphaMode)
    end

    drawTrapTriggerIcon(entry.triggerData and entry.triggerData.condition, markerX, markerY, color, pulse)
    drawMarkerLabel(getTrapLabel(entry.triggerData and entry.triggerData.condition), markerX, markerY + 18, color, 44)
end

local function getFieldLabel(entry)
    if entry and entry.fieldStatus and entry.fieldStatus.statusType then
        return string.upper(entry.fieldStatus.statusType)
    end

    return "FIELD"
end

local function drawFieldBand(entry, screenCenterX, arenaFloorY, arenaHalfWidth)
    local slotX, slotY = getSlotAnchor(entry)
    local color = getEntryColor(entry)
    local phase = (entry.slotIndex or 0) * 0.21
    local wave = math.sin(love.timer.getTime() * 1.4 + phase)
    local markerY = arenaFloorY - 66
    local tetherPoints = {
        slotX, slotY,
        lerp(slotX, screenCenterX, 0.4), math.min(slotY, markerY) - 22,
        screenCenterX, markerY
    }

    drawGlowLine(tetherPoints, withAlpha(color, 0.44), 1.6, 0.12)
    drawPulseOnPath(tetherPoints, color, phase)

    local blendMode, alphaMode = love.graphics.getBlendMode()
    local prevWidth = love.graphics.getLineWidth()

    love.graphics.setColor(color[1], color[2], color[3], 0.07)
    love.graphics.ellipse("fill", screenCenterX, arenaFloorY, arenaHalfWidth, 22)

    love.graphics.setBlendMode("add")
    love.graphics.setLineWidth(3)
    love.graphics.setColor(color[1], color[2], color[3], 0.1)
    love.graphics.ellipse("line", screenCenterX, arenaFloorY, arenaHalfWidth + 16, 24 + wave * 2)
    love.graphics.ellipse("line", screenCenterX, arenaFloorY, arenaHalfWidth - 20, 16)

    love.graphics.setBlendMode(blendMode, alphaMode)
    love.graphics.setLineWidth(1.4)
    love.graphics.setColor(color[1], color[2], color[3], 0.34)
    love.graphics.ellipse("line", screenCenterX, arenaFloorY, arenaHalfWidth, 22 + wave * 1.5)

    local markerRadius = 16
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.circle("fill", screenCenterX, markerY, markerRadius + 3)
    love.graphics.setColor(color[1], color[2], color[3], 0.14)
    love.graphics.circle("fill", screenCenterX, markerY, markerRadius)
    love.graphics.setColor(color[1], color[2], color[3], 0.82)
    love.graphics.circle("line", screenCenterX, markerY, markerRadius)
    love.graphics.line(screenCenterX - 9, markerY, screenCenterX + 9, markerY)
    love.graphics.line(screenCenterX, markerY - 9, screenCenterX, markerY + 9)
    love.graphics.setLineWidth(prevWidth)

    drawMarkerLabel(getFieldLabel(entry), screenCenterX, markerY + 22, color, 78)
end

function SustainedIndicatorRenderer.draw(gameState)
    if not love or not love.graphics then
        return
    end

    local manager = gameState and gameState.sustainedSpellManager
    if not manager or not manager.activeSpells then
        return
    end

    local entries = {}
    for _, entry in pairs(manager.activeSpells) do
        if entry and entry.type ~= "shield" and not entry.processed then
            table.insert(entries, entry)
        end
    end

    if #entries == 0 then
        return
    end

    table.sort(entries, function(a, b)
        local sideA = getWizardSide(a.wizard)
        local sideB = getWizardSide(b.wizard)
        if sideA ~= sideB then
            return sideA < sideB
        end
        if (a.slotIndex or 0) ~= (b.slotIndex or 0) then
            return (a.slotIndex or 0) < (b.slotIndex or 0)
        end
        return (a.id or "") < (b.id or "")
    end)

    local screenCenterX = love.graphics.getWidth() * 0.5
    local arenaFloorY = getArenaFloorY(gameState)
    local arenaHalfWidth = getArenaHalfWidth(gameState)

    love.graphics.push("all")
    for _, entry in ipairs(entries) do
        if entry.type == "trap" then
            drawTrapMarker(entry, screenCenterX, arenaFloorY)
        elseif entry.type == "field" then
            drawFieldBand(entry, screenCenterX, arenaFloorY, arenaHalfWidth)
        end
    end
    love.graphics.pop()
end

return SustainedIndicatorRenderer
