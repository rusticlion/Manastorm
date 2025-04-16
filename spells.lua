-- Spells.lua
-- Contains data for all spells in the game

local Spells = {}

-- Schema for spell object:
-- id: Unique identifier for the spell (string)
-- name: Display name of the spell (string)
-- description: Text description of what the spell does (string)
-- attackType: How the spell is delivered - "projectile", "remote", "zone", "utility" (string)
-- castTime: Duration in seconds to cast the spell (number)
-- cost: Array of token types required (simple array of strings like {"fire", "fire", "moon"})
-- keywords: Table of effect keywords and their parameters (table)
--   - Available keywords: conjure, dissipate, damage, lock, delay, accelerate, dispel, disjoint, 
--     stagger, elevate, ground, rangeShift, forcePull, reflect, block, echo, zoneAnchor,
--     zoneMulti, manaLeak, tokenShift, overcharge, rebound
-- vfx: Visual effect identifier (string, optional)
-- sfx: Sound effect identifier (string, optional)
-- blockableBy: Array of shield types that can block this spell (array, optional)

-- Spell resolution functions - these implement keyword functionality
local SpellKeywords = {
    -- Resource manipulation
    tokenShift = function(params, caster, target, results)
        local tokenType = params.type or "fire"
        local amount = params.amount or 1
        
        if tokenType == "random" then
            -- Implement random token shifting
            results.tokenShift = true
            results.tokenShiftType = "random"
            results.tokenShiftAmount = amount
        else
            -- Implement specific token shifting
            results.tokenShift = true
            results.tokenShiftType = tokenType
            results.tokenShiftAmount = amount
        end
        
        return results
    end,
    conjure = function(params, caster, target, results)
        local tokenType = params.token or "fire"
        local amount = params.amount or 1
        
        for i = 1, amount do
            local assetPath = "assets/sprites/" .. tokenType .. "-token.png"
            caster.manaPool:addToken(tokenType, assetPath)
        end
        
        return results
    end,
    
    dissipate = function(params, caster, target, results)
        local tokenType = params.token or "any"
        local amount = params.amount or 1
        
        -- Logic to remove tokens would go here
        -- This would need a helper in manaPool to find and remove tokens
        
        return results
    end,
    
    -- Damage effects
    damage = function(params, caster, target, results)
        results.damage = params.amount or 0
        results.damageType = params.type
        return results
    end,
    
    -- Token manipulation
    lock = function(params, caster, target, results)
        results.lockToken = true
        results.lockDuration = params.duration or 5.0
        return results
    end,
    
    -- Spell timing effects
    delay = function(params, caster, target, results)
        results.delayApplied = true
        results.targetSlot = params.slot or 0  -- 0 means random or auto-select
        results.delayAmount = params.duration or 1.0
        return results
    end,
    
    accelerate = function(params, caster, target, results)
        -- This would need implementation in wizard.lua to accelerate spell progress
        results.accelerate = true
        results.targetSlot = params.slot or 0  -- 0 means self or current slot
        results.accelerateAmount = params.amount or 1.0
        return results
    end,
    
    -- Spell cancellation effects
    dispel = function(params, caster, target, results)
        results.dispel = true
        results.targetSlot = params.slot or 0  -- 0 means random active slot
        return results
    end,
    
    disjoint = function(params, caster, target, results)
        results.disjoint = true
        results.targetSlot = params.slot or 0
        return results
    end,
    
    stagger = function(params, caster, target, results)
        results.stagger = true
        results.targetSlot = params.slot or 0
        results.staggerDuration = params.duration or 3.0
        return results
    end,
    
    -- Movement and position effects
    elevate = function(params, caster, target, results)
        results.setElevation = "AERIAL"
        results.elevationDuration = params.duration or 5.0
        return results
    end,
    
    ground = function(params, caster, target, results)
        results.setElevation = "GROUNDED"
        return results
    end,
    
    rangeShift = function(params, caster, target, results)
        results.setPosition = params.position or "NEAR"
        return results
    end,
    
    forcePull = function(params, caster, target, results)
        -- Force opponent to move to caster's range
        results.forcePosition = true
        return results
    end,
    
    -- Defense mechanisms
    reflect = function(params, caster, target, results)
        results.reflect = true
        results.reflectDuration = params.duration or 3.0
        return results
    end,
    
    block = function(params, caster, target, results)
        results.isShield = true
        results.defenseType = params.type or "barrier"
        results.blockTypes = params.blocks or {"projectile"}
        results.manaLinked = params.manaLinked or false
        results.reflect = params.reflect or false
        return results
    end,
    
    -- Special effects
    echo = function(params, caster, target, results)
        results.echo = true
        results.echoDelay = params.delay or 2.0
        return results
    end,
    
    -- Zone mechanics
    zoneAnchor = function(params, caster, target, results)
        results.zoneAnchor = true
        return results
    end,
    
    zoneMulti = function(params, caster, target, results)
        results.zoneMulti = true
        return results
    end
}

-- Function to validate spell schema
local function validateSpell(spell, spellId)
    assert(spell.id, "Spell " .. spellId .. " missing required property: id")
    assert(spell.name, "Spell " .. spellId .. " missing required property: name")
    assert(spell.description, "Spell " .. spellId .. " missing required property: description")
    assert(spell.castTime, "Spell " .. spellId .. " missing required property: castTime")
    assert(type(spell.castTime) == "number", "Spell " .. spellId .. " castTime must be a number")
    
    -- Either cost must be a table or an array (empty cost is allowed)
    assert(type(spell.cost) == "table", "Spell " .. spellId .. " cost must be a table")
    
    -- Check attackType is valid
    if spell.attackType then
        local validTypes = {
            projectile = true,
            remote = true,
            zone = true,
            utility = true
        }
        assert(validTypes[spell.attackType], "Spell " .. spellId .. " has invalid attackType: " .. spell.attackType)
    end
    
    -- Check keywords are valid (if present)
    if spell.keywords then
        assert(type(spell.keywords) == "table", "Spell " .. spellId .. " keywords must be a table")
        for keyword, _ in pairs(spell.keywords) do
            assert(SpellKeywords[keyword], "Spell " .. spellId .. " has unimplemented keyword: " .. keyword)
        end
    end
    
    -- Check blockableBy (if present)
    if spell.blockableBy then
        assert(type(spell.blockableBy) == "table", "Spell " .. spellId .. " blockableBy must be a table")
    end
    
    return true
end

-- Function to resolve spell effects based on keywords
local function resolveSpellEffect(spell, caster, target, slot)
    -- Validate spell before attempting to resolve
    validateSpell(spell, spell.id or "unknown")
    
    local results = {
        damage = 0,
        spellType = spell.attackType
    }
    
    -- Process each keyword in the spell
    if spell.keywords then
        for keyword, params in pairs(spell.keywords) do
            -- Handle dynamic parameter functions for keywords
            local processedParams = {}
            for paramKey, paramValue in pairs(params) do
                if type(paramValue) == "function" then
                    processedParams[paramKey] = paramValue(caster, target)
                else
                    processedParams[paramKey] = paramValue
                end
            end
            
            -- Check if this keyword has an implementation
            if SpellKeywords[keyword] then
                -- Process this keyword
                results = SpellKeywords[keyword](processedParams, caster, target, results)
            end
        end
    end
    
    -- For backward compatibility - delegate to effect function if present
    if spell.effect then
        local effectResults = spell.effect(caster, target, slot)
        -- Merge effect results with keyword results
        for k, v in pairs(effectResults) do
            results[k] = v
        end
    end
    
    return results
end

-- Ashgar's Spells (Fire-focused)
Spells.conjurefire = {
    id = "conjurefire",
    name = "Conjure Fire",
    description = "Creates a new Fire mana token",
    attackType = "utility",
    castTime = 2.0,
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = "fire",
            amount = 1
        }
    },
    vfx = "fire_conjure",
    blockableBy = {}  -- Unblockable
}

Spells.firebolt = {
    id = "firebolt",
    name = "Firebolt",
    description = "Quick ranged hit, more damage at FAR range",
    castTime = 5.0,
    attackType = "projectile",
    cost = {"fire", "any"},
    keywords = {
        damage = {
            amount = function(caster, target)
                -- Access shared range state from game state reference
                return caster.gameState.rangeState == "FAR" and 15 or 10
            end,
            type = "fire"
        }
    },
    vfx = "fire_bolt",
    sfx = "fire_whoosh",
    blockableBy = {"barrier", "ward"}
}

Spells.meteor = {
    id = "meteor",
    name = "Meteor Dive",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = 8.0,
    attackType = "zone",
    cost = {"fire", "force", "star"},
    keywords = {
        damage = {
            amount = function(caster, target)
                return target.elevation == "GROUNDED" and 20 or 0
            end,
            type = "fire",
            conditional = "target.GROUNDED"
        },
        rangeShift = {
            position = "NEAR"
        }
    },
    vfx = "meteor_dive",
    sfx = "meteor_impact",
    blockableBy = {"barrier", "field"}
}

Spells.combust = {
    id = "combust",
    name = "Combust Lock",
    description = "Locks opponent mana token, punishes overqueueing",
    castTime = 6.0,
    attackType = "remote",
    cost = {"fire", "force"},
    keywords = {
        lock = {
            duration = 10.0
        },
        damage = {
            amount = function(caster, target)
                -- Count active spell slots
                local activeSlots = 0
                for _, slot in ipairs(target.spellSlots) do
                    if slot.active then
                        activeSlots = activeSlots + 1
                    end
                end
                return activeSlots * 3
            end,
            type = "fire",
            scalesWithOpponentSlots = true
        }
    },
    vfx = "combust_lock",
    blockableBy = {"ward", "field"}
}

Spells.emberlift = {
    id = "emberlift",
    name = "Emberlift",
    description = "Launches caster into the air and increases range",
    castTime = 2.5,
    attackType = "utility",
    cost = {"fire", "force"},
    keywords = {
        elevate = {
            duration = 5.0
        },
        rangeShift = {
            position = "FAR"
        }
    },
    vfx = "ember_lift",
    sfx = "whoosh_up",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Selene's Spells (Moon-focused)
Spells.conjuremoonlight = {
    name = "Conjure Moonlight",
    description = "Creates a new Moon mana token",
    castTime = 2.0,  -- Fast cast time
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Create a moon token in the mana pool
        caster.manaPool:addToken("moon", "assets/sprites/moon-token.png")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.volatileconjuring = {
    name = "Volatile Conjuring",
    description = "Creates a random mana token",
    castTime = 1.4,  -- Shorter cast time than the dedicated conjuring spells
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Available token types and their image paths
        local tokenTypes = {
            {type = "fire", path = "assets/sprites/fire-token.png"},
            {type = "force", path = "assets/sprites/force-token.png"},
            {type = "moon", path = "assets/sprites/moon-token.png"},
            {type = "nature", path = "assets/sprites/nature-token.png"},
            {type = "star", path = "assets/sprites/star-token.png"}
        }
        
        -- Select a random token type
        local randomIndex = math.random(#tokenTypes)
        local selectedToken = tokenTypes[randomIndex]
        
        -- Create the token in the mana pool
        caster.manaPool:addToken(selectedToken.type, selectedToken.path)
        
        -- Display a message about which token was created (optional)
        print(caster.name .. " conjured a random " .. selectedToken.type .. " token")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.mist = {
    name = "Mist Veil",
    description = "A ward of mist that blocks projectiles and remotes",
    castTime = 5.0,
    isShield = true,
    defenseType = "ward",
    blocksAttackTypes = {"projectile", "remote"},
    cost = {
        {type = "moon", count = 2}  -- Explicitly define cost as 2 moon
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            elevationDuration = 4.0,  -- AERIAL effect lasts for 4 seconds
            isShield = true,
            defenseType = "ward",
            -- Shield strength is based on token count (handled in castSpell)
        }
    end
}

Spells.gravity = {
    name = "Gravity Pin",
    description = "Traps AERIAL enemies",
    castTime = 7.0,
    attackType = "zone",  -- Area effect attack
    cost = {
        {type = "moon", count = 1},
        {type = "nature", count = 1}
    },
    effect = function(caster, target)
        if target.elevation ~= "AERIAL" then return {damage = 0} end
        
        return {
            damage = 15,
            setElevation = "GROUNDED",
            stun = 2.0  -- Stun for 2 seconds
        }
    end
}

Spells.eclipse = {
    name = "Eclipse Echo",
    description = "Freezes caster's central queued spell for 2 seconds",
    castTime = 6.0,
    attackType = "remote",  -- Direct manipulation of spell effects
    cost = {
        {type = "moon", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        -- Directly modify the middle spell slot if it's active
        if caster.spellSlots[2] and caster.spellSlots[2].active then
            local slot = caster.spellSlots[2]
            local originalCastTime = slot.castTime
            local currentProgress = slot.progress
            
            -- Instead of adding to the cast time, we're just freezing progress
            -- The spell's total cast time remains the same, but progress will freeze for 2 seconds
            
            -- Add a "frozen" flag and freeze timer
            slot.frozen = true
            slot.freezeTimer = 2.0  -- Freeze for 2 seconds
            
            print("Eclipse Echo froze " .. caster.name .. "'s spell in slot 2 for 2 seconds")
            print("Spell will be frozen at " .. currentProgress .. " / " .. originalCastTime .. " for 2 seconds")
            
            return {
                delayApplied = true,
                targetSlot = 2,
                delayAmount = 2.0
            }
        else
            print("Eclipse Echo found no spell to delay in slot 2")
            return {
                delayApplied = false
            }
        end
    end
}

Spells.fullmoonbeam = {
    name = "Full Moon Beam",
    description = "Channels moonlight into a beam that deals damage equal to its cast time",
    castTime = 7.0,    -- Base cast time
    attackType = "projectile",  -- Beam attack
    cost = {
        {type = "moon", count = 5}  -- Costs 5 moon mana
    },
    effect = function(caster, target, spellSlot)
        -- Find the slot this spell was cast from to get its actual cast time
        local actualCastTime = 7.0  -- Default/base cast time
        
        -- If we know which slot this spell was cast from
        if spellSlot and caster.spellSlots[spellSlot] then
            -- Use the actual cast time of the spell which may have been modified
            actualCastTime = caster.spellSlots[spellSlot].castTime
        end
        
        -- Calculate damage based on cast time (roughly 3.5 damage per second)
        local damage = math.floor(actualCastTime * 3.5)
        
        -- Log the damage calculation
        print("Full Moon Beam cast time: " .. actualCastTime .. "s, dealing " .. damage .. " damage")
        
        return {
            damage = damage,     -- Damage scales with cast time
            damageType = "moon",
            scaledDamage = true  -- Flag to indicate this used a scaled damage value
        }
    end
}

-- New shield spells

Spells.forcebarrier = {
    id = "forcebarrier",
    name = "Force Barrier",
    description = "A protective barrier that blocks projectiles and zones",
    castTime = 4.0,
    attackType = "utility",
    cost = {"force", "force"},
    keywords = {
        block = {
            type = "barrier",
            blocks = {"projectile", "zone"},
            manaLinked = true
        }
    },
    vfx = "force_barrier",
    sfx = "shield_up",
    blockableBy = {}  -- Utility spell, can't be blocked
}

Spells.moonward = {
    name = "Moon Ward",
    description = "A mystical ward that blocks projectiles and remotes",
    castTime = 4.5,
    isShield = true,
    defenseType = "ward",
    blocksAttackTypes = {"projectile", "remote"},
    cost = {
        {type = "moon", count = 1},
        {type = "star", count = 1}
    },
    effect = function(caster, target)
        return {
            isShield = true,
            defenseType = "ward",
            -- Shield strength based on token count
        }
    end
}

Spells.naturefield = {
    name = "Nature Field",
    description = "A field of natural energy that blocks remotes and zones",
    castTime = 4.0,
    isShield = true,
    defenseType = "field",
    blocksAttackTypes = {"remote", "zone"},
    cost = {
        {type = "nature", count = 2}
    },
    effect = function(caster, target)
        return {
            isShield = true,
            defenseType = "field",
            -- Shield strength based on token count
        }
    end
}

-- Prepare the return table with all spells and utility functions
local SpellsModule = {
    spells = Spells,
    resolveSpellEffect = resolveSpellEffect,
    validateSpell = validateSpell,
    keywords = SpellKeywords
}

-- Validate all spells at module load time to catch errors early
for spellId, spell in pairs(Spells) do
    validateSpell(spell, spellId)
end

-- Add a new spell using the new schema to test the system
Spells.stormMeld = {
    id = "stormmeld",
    name = "Storm Meld",
    description = "An elemental fusion spell that changes tokens to random types",
    attackType = "utility",
    castTime = 3.0,
    cost = {"fire", "moon"},
    keywords = {
        tokenShift = {
            type = "random",
            amount = 3
        },
        damage = {
            amount = 5,
            type = "mixed"
        },
        echo = {
            delay = 3.0
        }
    },
    vfx = "storm_meld",
    sfx = "elemental_fusion",
    blockableBy = {}  -- Utility spells can't be blocked
}

return SpellsModule