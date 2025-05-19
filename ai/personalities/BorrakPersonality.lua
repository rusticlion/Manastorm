-- ai/personalities/BorrakPersonality.lua
-- AI personality module for Borrak, the water warlock

local Constants = require("core.Constants")
local PersonalityBase = require("ai.PersonalityBase")
local ManaHelpers = require("systems.ManaHelpers")

-- Define the BorrakPersonality module
local BorrakPersonality = PersonalityBase.new("Borrak")

-- Utility to randomly choose a spell from a list that the wizard can afford
local function chooseRandomAffordable(ai, spells)
    -- shuffle order for randomness
    for i = #spells, 2, -1 do
        local j = math.random(i)
        spells[i], spells[j] = spells[j], spells[i]
    end

    for _, spell in ipairs(spells) do
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end
    return nil
end

-- Get the best offensive spell for the current situation
function BorrakPersonality:getAttackSpell(ai, perception, spellbook)
    local p = perception
    local options = {}

    if p.totalFreeTokens >= 3 and ai:hasAvailableSpellSlot() then
        table.insert(options, spellbook["123"]) -- Wave Crash
    end
    if p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        table.insert(options, spellbook["23"]) -- Maelstrom
        table.insert(options, spellbook["13"]) -- Brine Chain
        table.insert(options, spellbook["12"]) -- Tidal Force
    end
    if p.totalFreeTokens >= 1 and ai:hasAvailableSpellSlot() then
        table.insert(options, spellbook["2"]) -- Water Gun
    end

    return chooseRandomAffordable(ai, options)
end

-- Get the best defensive spell for the current situation
function BorrakPersonality:getDefenseSpell(ai, perception, spellbook)
    local p = perception
    if not p.hasActiveShield and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        local shield = spellbook["3"] -- Riptide Guard
        if shield and ai.wizard:canPayManaCost(shield.cost) then
            return shield
        end
    end
    return nil
end

-- Counters simply fall back to defensive options
function BorrakPersonality:getCounterSpell(ai, perception, spellbook)
    return self:getDefenseSpell(ai, perception, spellbook)
end

-- Escape behavior is also to put up a shield
function BorrakPersonality:getEscapeSpell(ai, perception, spellbook)
    return self:getDefenseSpell(ai, perception, spellbook)
end

-- Conjure Water whenever possible
function BorrakPersonality:getConjureSpell(ai, perception, spellbook)
    if ai:hasAvailableSpellSlot() then
        local spell = spellbook["1"] -- Conjure Water
        if spell and ai.wizard:canPayManaCost(spell.cost) then
            return spell
        end
    end
    return nil
end

-- Borrak generally has no special positioning logic
function BorrakPersonality:getPositioningSpell(ai, perception, spellbook)
    return nil
end

-- Suggest AI state based on Borrak's strategy
function BorrakPersonality:suggestState(ai, perception)
    local p = perception
    local waterCount = p.availableTokens[Constants.TokenType.WATER] or 0

    -- Focus on conjuring until we have at least 3 Water tokens
    if waterCount < 3 then
        return ai.STATE.IDLE
    end

    -- Maintain a shield if we don't have one
    if not p.hasActiveShield and p.totalFreeTokens >= 2 and ai:hasAvailableSpellSlot() then
        return ai.STATE.DEFEND
    end

    -- Alternate between attacking and conjuring
    if math.random() < 0.5 then
        return ai.STATE.ATTACK
    else
        return ai.STATE.IDLE
    end
end

return BorrakPersonality
