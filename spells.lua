-- Spells.lua
-- Contains data for all spells in the game

local Spells = {}

-- Spell costs are defined as tables with mana type and count
-- For generic/any mana, use "any" as the type
-- For modal costs (can be paid with subset of types), use a table of types

-- Ashgar's Spells (Fire-focused)
Spells.conjurefire = {
    name = "Conjure Fire",
    description = "Creates a new Fire mana token",
    castTime = 2.0,  -- Fast cast time
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Create a fire token in the mana pool
        caster.manaPool:addToken("fire", "assets/sprites/fire-token.png")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.firebolt = {
    name = "Firebolt",
    description = "Quick ranged hit, more damage at FAR range",
    castTime = 5.0,  -- seconds
    attackType = "projectile",  -- Mark as a projectile attack
    cost = {
        {type = "fire", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        -- Access shared range state from game state reference
        local damage = 10
        if caster.gameState.rangeState == "FAR" then damage = 15 end
        return {
            damage = damage,
            damageType = "fire",  -- Type of damage
            spellType = "projectile"  -- Include in effect for blocking check
        }
    end
}

Spells.meteor = {
    name = "Meteor Dive",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = 8.0,
    attackType = "zone",  -- Area attack that affects a zone
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1},
        {type = "star", count = 1}
    },
    effect = function(caster, target)
        if target.elevation ~= "GROUNDED" then return {damage = 0} end
        
        return {
            damage = 20,
            type = "fire",
            setPosition = "NEAR"  -- Moves caster to NEAR
        }
    end
}

Spells.combust = {
    name = "Combust Lock",
    description = "Locks opponent mana token, punishes overqueueing",
    castTime = 6.0,
    attackType = "remote",  -- Direct effect on opponent's resources 
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        -- Count active spell slots
        local activeSlots = 0
        for _, slot in ipairs(target.spellSlots) do
            if slot.active then
                activeSlots = activeSlots + 1
            end
        end
        
        return {
            lockToken = true,
            lockDuration = 10.0,  -- Lock mana token for 10 seconds
            damage = activeSlots * 3  -- More damage if target has many active spells
        }
    end
}

Spells.emberlift = {
    name = "Emberlift",
    description = "Launches caster into the air and increases range",
    castTime = 2.5,  -- Short cast time
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            elevationDuration = 5.0,  -- Sets AERIAL for 5 seconds
            setPosition = "FAR",      -- Sets range to FAR
            damage = 0
        }
    end
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
            shieldStrength = 2  -- Shield lasts for 2 hits
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
    name = "Force Barrier",
    description = "A protective barrier that blocks projectiles and zones",
    castTime = 4.0,
    isShield = true,
    defenseType = "barrier",
    blocksAttackTypes = {"projectile", "zone"},
    cost = {
        {type = "force", count = 2}  -- Costs 2 force mana
    },
    effect = function(caster, target)
        return {
            isShield = true,
            defenseType = "barrier",
            shieldStrength = 2  -- Shield blocks 2 attacks
        }
    end
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
            shieldStrength = 2  -- Shield blocks 2 attacks
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
            shieldStrength = 2  -- Shield blocks 2 attacks
        }
    end
}

return Spells