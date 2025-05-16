-- ai/personalities/SelenePersonality.lua
-- AI personality module for Selene of the Veil

local Constants = require("core.Constants")
local PersonalityBase = require("ai.PersonalityBase")

-- Define the SelenePersonality module
local SelenePersonality = PersonalityBase.new("Selene of the Veil")

-- Get the best offensive spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function SelenePersonality:getAttackSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}
    
    -- CORE STRATEGY: 
    -- 1. Save up for Full Moon Beam
    -- 2. Try to queue Full Moon Beam in the middle slot
    -- 3. Use Eclipse to boost its damage
    
    -- Track what spells we already have active
    local fullMoonBeamActive = false
    local eclipseActive = false
    local moonDanceActive = false
    local gravityTrapActive = false
    local fullMoonBeamSlot = nil
    
    for i, slot in ipairs(p.spellSlots) do
        if slot.active then
            if slot.spellType == "fullmoonbeam" then
                fullMoonBeamActive = true
                fullMoonBeamSlot = i
            elseif slot.spellType == "eclipse" then
                eclipseActive = true
            elseif slot.spellType == "moondance" then
                moonDanceActive = true
            elseif slot.spellType == "gravityTrap" then
                gravityTrapActive = true
            end
        end
    end
    
    -- Check if we have enough resources for Full Moon Beam
    if p.totalFreeTokens >= 4 and not fullMoonBeamActive and ai:hasAvailableSpellSlot() then
        -- We have enough tokens for Full Moon Beam, prioritize it
        local fullMoonBeam = spellbook["123"] -- Full Moon Beam
        if fullMoonBeam and ai.wizard:canPayManaCost(fullMoonBeam.cost) then
            -- We're specifically looking for this, so prioritize it highly
            return fullMoonBeam
        end
    end
    
    -- If we have Full Moon Beam active, follow up with Eclipse to enhance it
    if fullMoonBeamActive and not eclipseActive and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        local eclipse = spellbook["13"] -- Eclipse
        if eclipse and ai.wizard:canPayManaCost(eclipse.cost) then
            return eclipse
        end
    end
    
    -- If opponent is aerial, consider Gravity Trap
    if p.opponentElevation == Constants.ElevationState.AERIAL and p.totalFreeTokens >= 2 and 
       not gravityTrapActive and ai:hasAvailableSpellSlot() then
        local gravityTrap = spellbook["23"] -- gravityTrap
        if gravityTrap and ai.wizard:canPayManaCost(gravityTrap.cost) then
            table.insert(spellsToTry, gravityTrap)
        end
    end
    
    -- If we have a shield up and < 3 tokens, consider Moon Dance for chip damage
    if p.hasActiveShield and p.totalFreeTokens >= 1 and p.totalFreeTokens < 3 and 
       not moonDanceActive and ai:hasAvailableSpellSlot() then
        local moonDance = spellbook["3"] -- moondance
        if moonDance and ai.wizard:canPayManaCost(moonDance.cost) then
            table.insert(spellsToTry, moonDance)
        end
    end
    
    -- If we have 3+ tokens but can't do Full Moon Beam for some reason, try Eclipse
    if not eclipseActive and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        local eclipse = spellbook["13"] -- eclipse
        if eclipse and ai.wizard:canPayManaCost(eclipse.cost) then
            table.insert(spellsToTry, eclipse)
        end
    end
    
    -- Return the first affordable spell from our priority list
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
function SelenePersonality:getDefenseSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}

    -- ENHANCED STRATEGY: Prioritize defense more - try to keep a shield up at all times
    -- Put up a shield whenever we don't have one and can afford it, not just when low health
    if p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() and not p.hasActiveShield then
        -- Try shield spell (wrapinmoonlight) - Selene's primary advantage
        table.insert(spellsToTry, spellbook["2"]) -- wrapinmoonlight
    end

    -- Secondary options if shield isn't possible
    if p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        -- If health is starting to get low, consider evasive maneuvers
        if p.selfHealth < 75 and not p.hasActiveShield then
            table.insert(spellsToTry, spellbook["3"]) -- moondance (position change for evasion)
        end

        -- Building resources is also defensive when we need tokens for shield
        if p.totalFreeTokens < 2 then
            table.insert(spellsToTry, spellbook["1"]) -- conjuremoonlight
        end
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
function SelenePersonality:getCounterSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}
    
    -- Check if there's something to counter and we have enough resources
    if p.opponentHasDangerousSpell and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        -- For Selene, try using eclipse or moondance
        table.insert(spellsToTry, spellbook["13"]) -- eclipse (freezes crown slot)
        table.insert(spellsToTry, spellbook["3"])  -- moondance (can disrupt by changing range)
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
function SelenePersonality:getEscapeSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}
    
    -- When in critical health, try shield, range change, or free all slots
    
    -- First priority: shields if not already shielded
    if not p.hasActiveShield and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["2"]) -- wrapinmoonlight
    end
    
    -- Second priority: change range/position
    if p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["3"]) -- moondance
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
function SelenePersonality:getConjureSpell(ai, perception, spellbook)
    local p = perception
    
    -- Try conjuration spell if a slot is available
    if ai:hasAvailableSpellSlot() then
        local conjureSpell = spellbook["1"] -- conjuremoonlight
        
        if conjureSpell and ai.wizard:canPayManaCost(conjureSpell.cost) then
            return conjureSpell
        end
    end
    
    return nil
end

-- Get the best positioning spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function SelenePersonality:getPositioningSpell(ai, perception, spellbook)
    local p = perception
    
    -- If at NEAR range, prioritize Moon Dance to get back to FAR
    if p.rangeState == Constants.RangeState.NEAR then
        local moonDance = spellbook["3"] -- moondance
        if moonDance and ai.wizard:canPayManaCost(moonDance.cost) and ai:hasAvailableSpellSlot() then
            return moonDance
        end
    end
    
    -- Default behavior - try to use moondance to change range if needed
    if p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        local posSpell = spellbook["3"] -- moondance
        
        if posSpell and ai.wizard:canPayManaCost(posSpell.cost) then
            return posSpell
        end
    end
    
    return nil
end

-- Override suggestState to provide Selene-specific state suggestions
function SelenePersonality:suggestState(ai, perception)
    local p = perception
    
    -- If at NEAR range, prioritize positioning to get back to FAR
    if p.rangeState == Constants.RangeState.NEAR and p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        -- 80% chance to prioritize positioning when at NEAR range
        if math.random() < 0.5 then
            return ai.STATE.POSITION
        end
    end
    
    -- NEW CORE STRATEGY: Focus on resource accumulation for Full Moon Beam + Eclipse combo
    -- If we have a shield up and 3+ tokens, focus on attacking to try our combo
    if p.hasActiveShield and p.totalFreeTokens >= 3 and ai:hasAvailableSpellSlot() then
        -- With a shield up and enough tokens, we should try our combo
        return ai.STATE.ATTACK
    end
    
    -- If we have a lot of tokens, prioritize attacking to use them
    if p.totalFreeTokens >= 4 and ai:hasAvailableSpellSlot() then
        -- We have enough tokens for our most powerful spells
        return ai.STATE.ATTACK
    end
    
    -- ENHANCED STRATEGY: More proactive shield usage
    -- Prioritize defense if we don't have a shield and have enough resources
    if not p.hasActiveShield and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        -- 70% chance to prioritize defense when we don't have a shield (increased from 60%)
        if math.random() < 0.7 then
            return ai.STATE.DEFEND
        end
    end
    
    -- ENHANCED STRATEGY: Resource accumulation when we have a shield but not enough tokens
    -- If we have a shield but less than 3 tokens, focus on resource gathering
    if p.hasActiveShield and p.totalFreeTokens < 3 then
        -- 70% chance to focus on resource gathering when we have a shield but few tokens
        if math.random() < 0.7 then
            return ai.STATE.IDLE
        end
    end
    
    -- ENHANCED STRATEGY: Prioritize Counter when opponent is casting
    -- If opponent is casting and we have enough tokens, counter them
    if p.opponentHasDangerousSpell and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        -- 80% chance to try countering dangerous spells
        if math.random() < 0.8 then
            return ai.STATE.COUNTER
        end
    end
    
    -- Let the default AI logic handle other cases
    return nil
end

return SelenePersonality