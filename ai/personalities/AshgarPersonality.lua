-- ai/personalities/AshgarPersonality.lua
-- AI personality module for Ashgar the Emberfist

local Constants = require("core.Constants")
local PersonalityBase = require("ai.PersonalityBase")

-- Define the AshgarPersonality module
local AshgarPersonality = PersonalityBase.new("Ashgar the Emberfist")

-- Ashgar's Spellbook:
-- "1": Conjure Fire (Conjure)
-- "2": Nova Conjuring (Resource Management/Setup)
-- "3": Firebolt (Attack)
-- "12": Battle Shield (Defense)
-- "13": Blast Wave (Attack - Zone, good vs NEAR)
-- "23": Emberlift (Positioning/Utility, Conjure Fire)
-- "123": Meteor (Attack - Aerial Finisher, requires AERIAL setup)

-- Get the best offensive spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function AshgarPersonality:getAttackSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}
    
    -- Meteor (powerful aerial finisher) - if both conditions are met:
    -- 1. AI is in AERIAL state
    -- 2. Opponent is in GROUNDED state
    if p.ownElevation == Constants.ElevationState.AERIAL and 
       p.opponentElevation == Constants.ElevationState.GROUNDED and
       p.totalFreeTokens >= 3 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["123"]) -- Meteor
    end
    
    -- Blast Wave (good at NEAR range)
    if p.rangeState == Constants.RangeState.NEAR and 
       p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["13"]) -- Blast Wave
    end
    
    -- Firebolt (basic attack, better at FAR range)
    if p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["3"]) -- Firebolt 
    end
    
    -- Return the first affordable spell
    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end
    
    return nil
end

-- Get the best defensive spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function AshgarPersonality:getDefenseSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}
    
    -- Battle Shield is Ashgar's primary defense
    if p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() and not p.hasActiveShield then
        table.insert(spellsToTry, spellbook["12"]) -- Battle Shield
    end
    
    -- Emberlift can be used to escape by changing elevation
    if p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() and 
       p.ownElevation == Constants.ElevationState.GROUNDED then
        table.insert(spellsToTry, spellbook["23"]) -- Emberlift
    end
    
    -- If we don't have enough tokens for a shield
    if p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        -- Try to gain tokens
        table.insert(spellsToTry, spellbook["1"]) -- Conjure Fire
    end
    
    -- Return the first affordable spell
    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end
    
    return nil
end

-- Get the best counter spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function AshgarPersonality:getCounterSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}
    
    -- Ashgar doesn't have direct counter spells like Selene's Eclipse,
    -- but he can use Blast Wave to disrupt opponents at NEAR range
    -- or Emberlift to change position
    
    if p.opponentHasDangerousSpell then
        -- If near, use Blast Wave as a counter
        if p.rangeState == Constants.RangeState.NEAR and p.totalFreeTokens >= 2 then
            table.insert(spellsToTry, spellbook["13"]) -- Blast Wave
        end
        
        -- Use Emberlift to change position and potentially disrupt
        if p.totalFreeTokens >= 2 and p.ownElevation == Constants.ElevationState.GROUNDED then
            table.insert(spellsToTry, spellbook["23"]) -- Emberlift
        end
        
        -- Simple attack may also work as disruption
        if p.totalFreeTokens >= 1 then
            table.insert(spellsToTry, spellbook["3"]) -- Firebolt
        end
    end
    
    -- Return the first affordable spell
    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end
    
    -- If no counter spell is available, fall back to a defensive option
    return self:getDefenseSpell(ai, perception, spellbook)
end

-- Get the best escape spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function AshgarPersonality:getEscapeSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}
    
    -- When in critical health
    
    -- First priority: Battle Shield if not already shielded
    if not p.hasActiveShield and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["12"]) -- Battle Shield
    end
    
    -- Second priority: Emberlift to change elevation (if grounded)
    if p.ownElevation == Constants.ElevationState.GROUNDED and
       p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["23"]) -- Emberlift
    end
    
    -- Return the first affordable spell
    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end
    
    return nil
end

-- Get the best conjuration spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function AshgarPersonality:getConjureSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}
    
    -- Try to use Nova Conjuring for more advanced resource generation
    -- when we already have some tokens
    if p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["2"]) -- Nova Conjuring
    end
    
    -- Basic conjuration spell - always useful
    if ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["1"]) -- Conjure Fire
    end
    
    -- Return the first affordable spell
    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end
    
    return nil
end

-- Get the best positioning spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function AshgarPersonality:getPositioningSpell(ai, perception, spellbook)
    local p = perception
    
    -- Emberlift is Ashgar's primary positioning spell
    -- Use it when grounded to gain aerial advantage
    if p.ownElevation == Constants.ElevationState.GROUNDED and
       p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        local posSpell = spellbook["23"] -- Emberlift
        
        if posSpell and ai.wizard:canPayManaCost(posSpell.cost) then
            return posSpell
        end
    end
    
    return nil
end

-- Suggest custom state based on Ashgar's special capabilities
function AshgarPersonality:suggestState(ai, perception)
    local p = perception
    
    -- Consider positioning to setup an aerial meteor attack
    if not p.selfCriticalHealth and -- not in emergency
       p.ownElevation == Constants.ElevationState.GROUNDED and
       p.totalFreeTokens >= 2 and 
       ai:hasAvailableSpellSlot() then
        
        -- 20% chance to try positioning for a meteor setup when conditions are good
        if math.random(1, 5) == 1 then
            return ai.STATE.POSITION
        end
    end
    
    -- Let the core AI decide in other cases
    return nil
end

return AshgarPersonality