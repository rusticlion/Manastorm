-- systems/AttractModeInput.lua
-- Keeps attract-mode input route mutations centralized and reversible.

local AttractModeInput = {}

local ROUTE_KEYS = {
    "p1_kb",
    "p2_kb",
    "gp1",
    "gp2",
    -- Legacy aliases kept for compatibility with older route layouts.
    "p1",
    "p2",
}

-- Snapshot active routes and disable them for attract mode.
function AttractModeInput.snapshotAndDisable(routes)
    if not routes then
        return nil
    end

    local snapshot = {}
    for _, key in ipairs(ROUTE_KEYS) do
        if routes[key] ~= nil then
            snapshot[key] = routes[key]
            routes[key] = {}
        end
    end
    return snapshot
end

-- Restore routes from a previous snapshot.
function AttractModeInput.restore(routes, snapshot)
    if not routes or not snapshot then
        return false
    end

    for _, key in ipairs(ROUTE_KEYS) do
        if snapshot[key] ~= nil then
            routes[key] = snapshot[key]
        end
    end
    return true
end

return AttractModeInput
