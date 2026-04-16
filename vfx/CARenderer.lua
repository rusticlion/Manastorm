-- vfx/CARenderer.lua
-- Lightweight per-effect cellular automata overlay (small local grid)

local CARenderer = {}

-- Initialize a small CA grid for an effect if missing
function CARenderer.ensure(effect)
    effect.ca = effect.ca or {}
    local ca = effect.ca
    if ca.inited then return ca end
    ca.cellSize = (effect.options and effect.options.caProfile and effect.options.caProfile.cellSize) or 3
    ca.gridSize = (effect.options and effect.options.caProfile and effect.options.caProfile.gridSize) or 24
    ca.alpha = (effect.options and effect.options.caProfile and effect.options.caProfile.alpha) or 0.22
    ca.stepRate = (effect.options and effect.options.caProfile and effect.options.caProfile.stepRate) or 2.0 -- generations/sec
    ca.timer = 0
    ca.grid = {}
    for y = 1, ca.gridSize do
        ca.grid[y] = {}
        for x = 1, ca.gridSize do
            ca.grid[y][x] = math.random() < 0.5 and 1 or 0
        end
    end
    ca.inited = true
    return ca
end

-- Single neighborhood sum (Moore)
local function neighborSum(grid, x, y, n)
    local sum = 0
    for j = -1, 1 do
        for i = -1, 1 do
            if not (i == 0 and j == 0) then
                local cx = x + i
                local cy = y + j
                if cx >= 1 and cy >= 1 and cx <= n and cy <= n then
                    sum = sum + (grid[cy][cx] or 0)
                end
            end
        end
    end
    return sum
end

-- Update CA a small number of generations based on a simple rule set
function CARenderer.update(effect, dt)
    if not (effect.options and effect.options.enableCA) then return end
    local ca = CARenderer.ensure(effect)
    ca.timer = ca.timer + dt
    local stepInterval = 1.0 / ca.stepRate
    while ca.timer >= stepInterval do
        ca.timer = ca.timer - stepInterval
        local n = ca.gridSize
        local nextGrid = {}
        if effect.options.caProfile and effect.options.caProfile.rule == "ripple" then
            -- Procedural ripple rings: encode radius bands over time
            local t = (effect.timer or 0)
            local wavelength = effect.options.caProfile.wavelength or (ca.cellSize * 5)
            local speed = effect.options.caProfile.speed or 2.0
            local thickness = effect.options.caProfile.thickness or 0.2
            local centerX = math.floor(n / 2)
            local centerY = math.floor(n / 2)
            for y = 1, n do
                nextGrid[y] = {}
                for x = 1, n do
                    local dx = x - centerX
                    local dy = y - centerY
                    local r = math.sqrt(dx*dx + dy*dy)
                    local phase = (r - (t * speed * (wavelength / ca.cellSize))) / (wavelength / ca.cellSize)
                    local ring = math.abs(phase - math.floor(phase + 0.5)) -- distance to nearest integer ring
                    nextGrid[y][x] = (ring < thickness) and 1 or 0
                end
            end
        else
            for y = 1, n do
                nextGrid[y] = {}
                for x = 1, n do
                    local s = neighborSum(ca.grid, x, y, n)
                    local v = ca.grid[y][x]
                    -- Generic B3/S23 (Conway-like) with mild decay toward zeros
                    local alive = (v == 1 and (s == 2 or s == 3)) or (v == 0 and s == 3)
                    nextGrid[y][x] = alive and 1 or 0
                end
            end
        end
        ca.grid = nextGrid
    end
end

-- Draw CA overlay centered around the effect’s main point
function CARenderer.draw(effect)
    if not (effect.options and effect.options.enableCA) then return end
    local ca = CARenderer.ensure(effect)
    local n = ca.gridSize
    local cell = ca.cellSize
    local alpha = ca.alpha
    local cx = (effect.headX or effect.targetX or effect.sourceX or 0)
    local cy = (effect.headY or effect.targetY or effect.sourceY or 0)
    local half = (n * cell) * 0.5
    local startX = math.floor(cx - half + 0.5)
    local startY = math.floor(cy - half + 0.5)
    love.graphics.setColor(1, 1, 1, alpha)
    for y = 1, n do
        local py = startY + (y - 1) * cell
        for x = 1, n do
            if ca.grid[y][x] == 1 then
                local px = startX + (x - 1) * cell
                love.graphics.rectangle("fill", px, py, cell, cell)
            end
        end
    end
end

return CARenderer


