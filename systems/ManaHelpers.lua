-- systems/ManaHelpers.lua
-- Provides utility functions for working with tokens in the mana pool

local ManaHelpers = {}

-- Count tokens of a specific type in the mana pool
function ManaHelpers.count(tokenType, manaPool)
    local count = 0
    
    -- If the manaPool isn't provided directly, try to find it from the game state
    if not manaPool then return 0 end
    
    local Constants = require("core.Constants")
    
    for _, token in ipairs(manaPool.tokens or {}) do
        if token.type == tokenType and token.state == Constants.TokenState.FREE then
            count = count + 1
        end
    end
    
    return count
end

-- Get the most abundant token type from options
function ManaHelpers.most(tokenTypes, manaPool)
    local maxCount = -1
    local maxType = nil
    
    for _, tokenType in ipairs(tokenTypes) do
        local count = ManaHelpers.count(tokenType, manaPool)
        if count > maxCount then
            maxCount = count
            maxType = tokenType
        end
    end
    
    return maxType
end

-- Get the least abundant token type from options
function ManaHelpers.least(tokenTypes, manaPool)
    local minCount = math.huge
    local minType = nil
    
    for _, tokenType in ipairs(tokenTypes) do
        local count = ManaHelpers.count(tokenType, manaPool)
        if count < minCount and count > 0 then
            minCount = count
            minType = tokenType
        end
    end
    
    -- If no token was found with count > 0, return first type as fallback
    return minType or tokenTypes[1]
end

-- Find whether a specific token type exists in the pool
function ManaHelpers.exists(tokenType, manaPool)
    return ManaHelpers.count(tokenType, manaPool) > 0
end

-- Get a random token type from the mana pool
function ManaHelpers.random(manaPool)
    if not manaPool or not manaPool.tokens or #manaPool.tokens == 0 then 
        return nil
    end
    
    -- Get a list of free token types that are available
    local availableTypes = {}
    local typesPresent = {}
    
    local Constants = require("core.Constants")
    
    for _, token in ipairs(manaPool.tokens) do
        if token.state == Constants.TokenState.FREE and not typesPresent[token.type] then
            table.insert(availableTypes, token.type)
            typesPresent[token.type] = true
        end
    end
    
    -- Return a random token type from available types
    if #availableTypes > 0 then
        return availableTypes[math.random(#availableTypes)]
    end
    
    return nil
end

return ManaHelpers