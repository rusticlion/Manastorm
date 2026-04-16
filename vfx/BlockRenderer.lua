-- vfx/BlockRenderer.lua
-- Helpers for drawing sharp, chunky blocks with integer snapping

local BlockRenderer = {}

-- Snap a float position to integer pixels (optionally to a grid size)
function BlockRenderer.snap(v, grid)
    if grid and grid > 1 then
        return math.floor(v / grid + 0.5) * grid
    end
    return math.floor(v + 0.5)
end

-- Draw a filled block (rectangle) centered at x,y with size in pixels
function BlockRenderer.drawBlock(x, y, size, color)
    local s = math.max(1, math.floor(size))
    local half = s * 0.5
    local rx = BlockRenderer.snap(x - half)
    local ry = BlockRenderer.snap(y - half)
    if color then love.graphics.setColor(color[1], color[2], color[3], color[4] or 1) end
    love.graphics.rectangle("fill", rx, ry, s, s)
end

-- Draw a batch of blocks with the same size/color
function BlockRenderer.drawBlocks(points, size, color)
    if not points or #points == 0 then return end
    local s = math.max(1, math.floor(size))
    if color then love.graphics.setColor(color[1], color[2], color[3], color[4] or 1) end
    for i = 1, #points do
        local p = points[i]
        local half = s * 0.5
        local rx = BlockRenderer.snap((p.x or 0) - half)
        local ry = BlockRenderer.snap((p.y or 0) - half)
        love.graphics.rectangle("fill", rx, ry, s, s)
    end
end

return BlockRenderer


