-- ai/personalities/SilexPersonality.lua
-- AI personality module for Silex, the salt mage

local Constants = require("core.Constants")
local PersonalityBase = require("ai.PersonalityBase")

-- Define the SilexPersonality module
local SilexPersonality = PersonalityBase.new("Silex")

-- Get the best offensive spell for the current situation
-- @param ai - The OpponentAI instance
-- @param perception - The current perception data
-- @param spellbook - The wizard's spellbook
-- @return - A spell object or nil if no suitable spell found
function SilexPersonality:getAttackSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}

    -- Big area damage when we have plenty of tokens
    if p.totalFreeTokens >= 3 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["123"]) -- Salt Storm
    end

    -- Use Shield Breaker to punish opponents hiding behind shields
    if p.totalFreeTokens >= 3 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["23"]) -- Shield Breaker
    end

    -- Trap the opponent to maintain advantage
    if p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["3"]) -- Imprison
    end

    -- Quick poke
    if p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["2"]) -- Glitter Fang
    end

    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end

    return nil
end

-- Get the best defensive spell for the current situation
function SilexPersonality:getDefenseSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}

    -- Always try to keep a Salt Circle up
    if not p.hasActiveShield and p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["12"]) -- Salt Circle
    end

    -- Add Stone Shield as backup protection
    if p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["13"]) -- Stone Shield
    end

    -- Build resources if we can't shield
    if p.totalFreeTokens == 0 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["1"]) -- Conjure Salt
    end

    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end

    return nil
end

-- Get the best counter spell for the current situation
function SilexPersonality:getCounterSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}

    if p.opponentHasDangerousSpell then
        -- Put up Salt Circle to ward off incoming spells
        if p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
            table.insert(spellsToTry, spellbook["12"]) -- Salt Circle
        end
        -- Try to break the spell with Shield Breaker
        if p.totalFreeTokens >= 3 and ai:hasAvailableSpellSlot() then
            table.insert(spellsToTry, spellbook["23"]) -- Shield Breaker
        end
    end

    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end

    return self:getDefenseSpell(ai, perception, spellbook)
end

-- Get the best escape spell for the current situation
function SilexPersonality:getEscapeSpell(ai, perception, spellbook)
    local p = perception
    local spellsToTry = {}

    if not p.hasActiveShield and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["13"]) -- Stone Shield
    end

    if not p.hasActiveShield and p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        table.insert(spellsToTry, spellbook["12"]) -- Salt Circle
    end

    for _, spell in ipairs(spellsToTry) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end

    return nil
end

-- Get the best conjuration spell for the current situation
function SilexPersonality:getConjureSpell(ai, perception, spellbook)
    print("Silex:getConjureSpell")
    if ai:hasAvailableSpellSlot() then
        local spell = spellbook["1"] -- Conjure Salt
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end

    return nil
end

-- Positioning is not a focus for Silex
function SilexPersonality:getPositioningSpell(ai, perception, spellbook)
    return nil
end

-- Suggest AI state based on Silex's strategy
function SilexPersonality:suggestState(ai, perception)
    local p = perception

    -- Prioritize keeping a shield up
    if not p.hasActiveShield and p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        return ai.STATE.DEFEND
    end

    -- If shielded and have resources, press the attack
    if p.hasActiveShield and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        return ai.STATE.ATTACK
    end

    -- Build resources when low
    if p.totalFreeTokens == 0 and ai:hasAvailableSpellSlot() then
        return ai.STATE.IDLE
    end

    return nil
end

return SilexPersonality
