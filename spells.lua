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
    spellType = "projectile",  -- Mark as a projectile spell
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
    description = "Projectile block, grants AERIAL",
    castTime = 5.0,
    cost = {
        {type = "moon", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            elevationDuration = 4.0,  -- AERIAL effect lasts for 4 seconds
            block = "projectile",
            blockDuration = 5.0  -- Block projectiles for 5 seconds
        }
    end
}

Spells.gravity = {
    name = "Gravity Pin",
    description = "Traps AERIAL enemies",
    castTime = 7.0,
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
    description = "Delays central queued spell",
    castTime = 6.0,
    cost = {
        {type = "moon", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        return {
            delaySpell = 2  -- Targets spell slot 2 (middle)
        }
    end
}

Spells.fullmoonbeam = {
    name = "Full Moon Beam",
    description = "Channels moonlight into a powerful beam",
    castTime = 7.0,    -- Long cast time
    cost = {
        {type = "moon", count = 5}  -- Costs 5 moon mana
    },
    effect = function(caster, target)
        return {
            damage = 25,     -- Deals 25 damage
            damageType = "moon"
        }
    end
}

return Spells