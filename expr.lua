-- expr.lua
-- Expression helper functions for spell parameter evaluation

local Constants = require("core.Constants")
local ManaHelpers = require("systems.ManaHelpers")

local expr = {}

-- Choose whichever token is more abundant in the shared pool
function expr.more(a, b)
    return function(caster)
        local manaPool = caster and caster.manaPool
        return ManaHelpers.count(a, manaPool) > ManaHelpers.count(b, manaPool) and b or a
    end
end

-- Choose the scarcer token
function expr.less(a, b)
    return function(caster)
        local manaPool = caster and caster.manaPool
        return ManaHelpers.count(a, manaPool) < ManaHelpers.count(b, manaPool) and a or b
    end
end

-- Choose a token type based on a condition
function expr.ifCond(condition, trueValue, falseValue)
    return function(caster, target, slot)
        if condition(caster, target, slot) then
            return trueValue
        else
            return falseValue
        end
    end
end

-- Choose a value based on elevation state
function expr.byElevation(elevationValues)
    return function(caster, target, slot)
        local entityToCheck = target or caster
        local elevation = entityToCheck and entityToCheck.elevation or "GROUNDED"
        return elevationValues[elevation] or elevationValues.default
    end
end

-- Choose a value based on range state
function expr.byRange(rangeValues)
    return function(caster, target, slot)
        local rangeState = caster and caster.gameState and caster.gameState.rangeState or "NEAR"
        return rangeValues[rangeState] or rangeValues.default
    end
end

-- Choose a value based on which wizard has more tokens
function expr.whoHasMore(tokenType, casterValue, targetValue)
    return function(caster, target, slot)
        if not caster or not target or not caster.manaPool or not target.manaPool then
            return casterValue -- Default to caster value if we can't determine
        end
        
        local casterCount = ManaHelpers.count(tokenType, caster.manaPool)
        local targetCount = ManaHelpers.count(tokenType, target.manaPool)
        
        return casterCount >= targetCount and casterValue or targetValue
    end
end

-- Calculate a value based on the number of tokens
function expr.countScale(tokenType, baseValue, multiplier)
    return function(caster, target, slot)
        if not caster or not caster.manaPool then 
            return baseValue
        end
        
        local count = ManaHelpers.count(tokenType, caster.manaPool)
        return baseValue + (count * multiplier)
    end
end

return expr