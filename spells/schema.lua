-- spells/schema.lua
-- Contains schema definition and validation for spells

local Constants = require("core.Constants")

local Schema = {}

-- Schema for spell object:
-- id: Unique identifier for the spell (string)
-- name: Display name of the spell (string)
-- affinity: The element of the spell (string)
-- description: Text description of what the spell does (string)
-- attackType: How the spell is delivered - Constants.AttackType.PROJECTILE, REMOTE, ZONE, UTILITY
--   * PROJECTILE: Physical projectile attacks - can be blocked by barriers and wards
--   * REMOTE:     Magical attacks at a distance - can only be blocked by wards
--   * ZONE:       Area effect attacks - can be blocked by barriers and fields
--   * UTILITY:    Non-offensive spells that affect the caster - cannot be blocked
-- castTime: Duration in seconds to cast the spell (number)
-- cost: Array of token types required (array using Constants.TokenType.FIRE, etc.)
-- getCost: Optional function(caster, target) -> cost table for dynamic costs
-- keywords: Table of effect keywords and their parameters (table)
--   - Available keywords: damage, burn, stagger, elevate, ground, rangeShift, forcePull, 
--     tokenShift, conjure, dissipate, lock, delay, accelerate, dispel, disjoint, freeze,
--     block, reflect, echo, zoneAnchor, zoneMulti
-- visualShape: Visual shape identifier to override default template based on attackType (string, optional)
-- vfx: Visual effect identifier (string, optional)
-- sfx: Sound effect identifier (string, optional)
--
-- Shield Types and Blocking Rules:
-- * barrier: Physical shield that blocks projectiles and zones
-- * ward:    Magical shield that blocks projectiles and remotes
-- * field:   Energy field that blocks remotes and zones

-- Function to validate spell schema - Basic schema validation
function Schema.validateSpell(spell, spellId)
    -- Add a missing ID based on spell name if needed
    if not spell.id and spell.name then
        spell.id = spell.name:lower():gsub(" ", "")
        print("INFO: Added missing ID for spell: " .. spell.name .. " -> " .. spell.id)
    end
    
    -- Check essential properties with better error handling
    if not spell.id then
        print("WARNING: Spell " .. spellId .. " missing required property: id, creating a default")
        spell.id = "spell_" .. spellId
    end
    
    if not spell.name then
        print("WARNING: Spell " .. spellId .. " missing required property: name, creating a default")
        spell.name = "Unnamed Spell " .. spellId
    end

    if not spell.affinity then
        print("WARNING: Spell " .. spellId .. " missing required property: affinity, creating a default")
        spell.affinity = "fire"
    end
    
    if not spell.description then
        print("WARNING: Spell " .. spellId .. " missing required property: description, creating a default")
        spell.description = "No description available for " .. spell.name
    end
    
    if not spell.castTime then
        print("WARNING: Spell " .. spellId .. " missing required property: castTime, setting default")
        spell.castTime = 5.0 -- Default cast time
    end
    
    if type(spell.castTime) ~= "number" then
        print("WARNING: Spell " .. spellId .. " castTime must be a number, fixing")
        spell.castTime = tonumber(spell.castTime) or 5.0
    end
    
    -- Ensure cost is a table if provided, or create an empty table when neither
    -- cost nor getCost are specified. When getCost exists it's considered the
    -- runtime source of truth so we don't warn about a missing cost table.
    if not spell.cost then
        if spell.getCost and type(spell.getCost) == "function" then
            spell.cost = {}
        else
            print("WARNING: Spell " .. spellId .. " missing required property: cost, creating empty cost")
            spell.cost = {}
        end
    elseif type(spell.cost) ~= "table" then
        print("WARNING: Spell " .. spellId .. " cost must be a table, fixing")
        -- Try to convert to a table if possible
        local originalCost = spell.cost
        spell.cost = {}
        if originalCost then
            print("INFO: Converting non-table cost to table for: " .. spell.name)
            table.insert(spell.cost, tostring(originalCost))
        end
    end
    
    -- Check attackType is valid
    if spell.attackType then
        local validTypes = {
            projectile = true,
            remote = true,
            zone = true,
            utility = true
        }
        
        if not validTypes[spell.attackType] then
            print("WARNING: Spell " .. spellId .. " has invalid attackType: " .. spell.attackType .. ", fixing to utility")
            spell.attackType = "utility" -- Default to utility
        end
    else
        -- Default to utility if not specified
        print("WARNING: Spell " .. spellId .. " missing attackType, setting to utility")
        spell.attackType = "utility"
    end
    
    -- Check keywords are valid (if present)
    if spell.keywords then
        if type(spell.keywords) ~= "table" then
            print("WARNING: Spell " .. spellId .. " keywords must be a table, fixing")
            spell.keywords = {}
        else
            -- Keyword validation is done in the Keywords module
        end
    else
        -- Create empty keywords table if missing
        spell.keywords = {}
    end
    
    return true
end

return Schema