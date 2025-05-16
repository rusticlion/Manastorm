-- ai/PersonalityBase.lua
-- Interface for wizard AI personalities in Manastorm
-- Defines the contract for how personality modules interact with the OpponentAI system

local PersonalityBase = {}

-- Constructor for personality modules
-- @param name - A string identifier for the personality
function PersonalityBase.new(name)
    local personality = {
        name = name or "Generic",
        description = "Base personality module - meant to be extended"
    }
    
    -- Set metatable to use PersonalityBase methods
    setmetatable(personality, {__index = PersonalityBase})
    
    return personality
end

-- Get the best offensive spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function PersonalityBase:getAttackSpell(ai, perception, spellbook)
    -- Base implementation returns nil - should be overridden by derived personalities
    return nil
end

-- Get the best defensive spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function PersonalityBase:getDefenseSpell(ai, perception, spellbook)
    -- Base implementation returns nil - should be overridden by derived personalities
    return nil
end

-- Get the best counter spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function PersonalityBase:getCounterSpell(ai, perception, spellbook)
    -- Base implementation returns nil - should be overridden by derived personalities
    return nil
end

-- Get the best escape spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function PersonalityBase:getEscapeSpell(ai, perception, spellbook)
    -- Base implementation returns nil - should be overridden by derived personalities
    return nil
end

-- Get the best conjuration spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function PersonalityBase:getConjureSpell(ai, perception, spellbook)
    -- Base implementation returns nil - should be overridden by derived personalities
    return nil
end

-- Get the best positioning spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function PersonalityBase:getPositioningSpell(ai, perception, spellbook)
    -- Base implementation returns nil - should be overridden by derived personalities
    return nil
end

-- Get best spell for a given intent/state when no specific spell was found
-- @param state - The AI state (from OpponentAI.STATE)
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function PersonalityBase:getBestSpellForIntent(state, ai, perception, spellbook)
    -- This is a fallback method for when more specific methods don't find a suitable spell
    -- Each personality can implement custom fallback logic
    
    -- Base implementation tries to match the state to a specific spell getter
    if state == "ATTACK" then
        return self:getAttackSpell(ai, perception, spellbook)
    elseif state == "DEFEND" then
        return self:getDefenseSpell(ai, perception, spellbook)
    elseif state == "COUNTER" then
        return self:getCounterSpell(ai, perception, spellbook)
    elseif state == "ESCAPE" then
        return self:getEscapeSpell(ai, perception, spellbook)
    elseif state == "IDLE" then
        return self:getConjureSpell(ai, perception, spellbook)
    elseif state == "POSITION" then
        return self:getPositioningSpell(ai, perception, spellbook)
    end
    
    return nil
end

-- Can be used to provide character-specific customizations to FSM state selection
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @return - A string state name or nil to use default state selection logic
function PersonalityBase:suggestState(ai, perception)
    -- Base implementation returns nil, letting the core AI decide
    -- Derived personalities can override this to customize state selection
    return nil
end

return PersonalityBase