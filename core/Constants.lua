-- core/Constants.lua
-- Centralized constants for Manastorm
-- Replaces string literals with structured tables for better typesafety and autocomplete

local Constants = {}

-- Token types (mana/resource types)
Constants.TokenType = {
    FIRE = "fire",
    WATER = "water",
    SALT = "salt",
    SUN = "sun",
    MOON = "moon",
    STAR = "star",
    LIFE = "life",
    MIND = "mind",
    VOID = "void",
    RANDOM = "random",   -- Special: used in spell costs to indicate any token
    ANY = "any"          -- Special: used in keywords for wildcard matching
}

-- Token states in the mana pool
Constants.TokenState = {
    FREE = "FREE",             -- Available in the pool
    CHANNELED = "CHANNELED",   -- Being used in a spell slot
    SHIELDING = "SHIELDING",   -- Being used for a shield spell
    LOCKED = "LOCKED",         -- Temporarily unavailable
    DESTROYED = "DESTROYED"    -- Removed from play (legacy state for backwards compatibility)
}

-- Token status in the lifecycle state machine
Constants.TokenStatus = {
    FREE = "FREE",             -- Available in the pool
    CHANNELED = "CHANNELED",   -- Being used in a spell slot
    SHIELDING = "SHIELDING",   -- Being used for a shield spell
    LOCKED = "LOCKED",         -- Temporarily unavailable
    RETURNING = "RETURNING",   -- Animating back to pool (transition state)
    DISSOLVING = "DISSOLVING", -- Animating destruction (transition state)
    POOLED = "POOLED"          -- Released to the object pool
}

-- Range positioning between wizards
Constants.RangeState = {
    NEAR = "NEAR",
    FAR = "FAR"
}

-- Elevation positioning of wizards
Constants.ElevationState = {
    GROUNDED = "GROUNDED",
    AERIAL = "AERIAL"
}

-- Color Palette (RGBA, 0-1 range)
Constants.Color = {
    BLACK = {0, 0, 0, 1},                    -- #000000
    MAROON = {0.592, 0.184, 0.278, 1},       -- #972f47
    FOREST = {0.482, 0.620, 0.145, 1},       -- #7b9e25
    OCEAN = {0.282, 0.184, 0.745, 1},        -- #482fbe
    SMOKE = {0.557, 0.475, 0.420, 1},        -- #8e796b
    CRIMSON = {0.906, 0.122, 0.231, 1},      -- #e71f3b
    LIME = {0.651, 0.871, 0, 1},             -- #a6de00
    SKY = {0.365, 0.459, 0.745, 1},          -- #5d75be
    SAND = {0.906, 0.722, 0.427, 1},         -- #e7b86d
    OCHRE = {0.847, 0.349, 0.024, 1},        -- #d85906
    ORANGE = {0.984, 0.675, 0.043, 1},       -- #fbac0b
    PUCE = {0.851, 0.502, 0.494, 1},         -- #d9807e
    BONE = {0.906, 0.890, 0.745, 1},         -- #e7e3be
    YELLOW = {0.984, 0.941, 0.024, 1},       -- #fbf006
    MINT = {0.502, 0.953, 0.561, 1},         -- #80f38f
    PINK = {1, 0.820, 1, 1}                  -- #ffd1ff
}

-- Default color for unknown types
Constants.Color.DEFAULT = Constants.Color.SMOKE

-- Helper function to get color based on token type
-- Added mappings for types found in manapool.lua (Nature, Force)
function Constants.getColorForTokenType(tokenType)
    if tokenType == Constants.TokenType.FIRE then return Constants.Color.CRIMSON
    elseif tokenType == Constants.TokenType.WATER then return Constants.Color.OCEAN
    elseif tokenType == Constants.TokenType.SALT then return Constants.Color.SAND
    elseif tokenType == Constants.TokenType.SUN then return Constants.Color.ORANGE
    elseif tokenType == Constants.TokenType.MOON then return Constants.Color.SKY
    elseif tokenType == Constants.TokenType.STAR then return Constants.Color.YELLOW
    elseif tokenType == Constants.TokenType.LIFE then return Constants.Color.LIME
    elseif tokenType == Constants.TokenType.MIND then return Constants.Color.PINK
    elseif tokenType == Constants.TokenType.VOID then return Constants.Color.BONE
    elseif tokenType == "nature" then return Constants.Color.FOREST -- Found in manapool.lua draw
    elseif tokenType == "force" then return Constants.Color.YELLOW -- Found in manapool.lua draw
    else
        print("Warning: Unknown token type for color lookup: " .. tostring(tokenType))
        return Constants.Color.DEFAULT
    end
end

-- Shield types for blocking spells
Constants.ShieldType = {
    BARRIER = "barrier",    -- Physical barrier (blocks projectiles)
    WARD = "ward",          -- Magical ward (blocks remote spells)
    FIELD = "field"         -- Field (blocks zone effects)
}

-- Attack types for spells
Constants.AttackType = {
    PROJECTILE = "projectile",  -- Dodgeable, affected by range
    REMOTE = "remote",          -- Magic directly affects target
    ZONE = "zone",              -- Area effect, position-dependent
    UTILITY = "utility"         -- Non-damaging effect
}

Constants.CastSpeed = {
    VERY_SLOW = 13,
    SLOW = 10,
    NORMAL = 7,
    FAST = 4,
    VERY_FAST = 1,
    ONE_TIER = 3
}

-- Target types for keywords
Constants.TargetType = {
    -- Simple targeting - used in spell definitions
    SELF = "SELF",             -- Target the caster
    ENEMY = "ENEMY",           -- Target the opponent
    
    -- Complex targeting - used in keyword behaviors
    SLOT_SELF = "SLOT_SELF",     -- Target caster's spell slots
    SLOT_ENEMY = "SLOT_ENEMY",   -- Target opponent's spell slots
    POOL_SELF = "POOL_SELF",     -- Affect mana pool from caster's perspective
    POOL_ENEMY = "POOL_ENEMY",   -- Affect mana pool from opponent's perspective
    
    -- Legacy targeting (lowercase) - should be migrated to uppercase
    CASTER = "caster",         -- The casting wizard
    TARGET = "target"          -- The targeted wizard
}

-- Damage types for spells
Constants.DamageType = {
    FIRE = "fire",
    WATER = "water",
    SALT = "salt",
    SUN = "sun",
    MOON = "moon",
    STAR = "star",
    LIFE = "life",
    MIND = "mind",
    VOID = "void",
    GENERIC = "generic",
    MIXED = "mixed"
}

-- Player sides in battle
Constants.PlayerSide = {
    PLAYER = "PLAYER",
    OPPONENT = "OPPONENT",
    NEUTRAL = "NEUTRAL"
}

-- Helper functions for dynamic string generation
-- E.g., replaces patterns like "POOL_" .. side with Constants.poolSide(side)

-- Generate pool target based on side
function Constants.poolSide(side)
    if side == Constants.TargetType.SELF then
        return Constants.TargetType.POOL_SELF
    elseif side == Constants.TargetType.ENEMY then
        return Constants.TargetType.POOL_ENEMY
    else
        return nil
    end
end

-- Generate slot target based on side
function Constants.slotSide(side)
    if side == Constants.TargetType.SELF then
        return Constants.TargetType.SLOT_SELF
    elseif side == Constants.TargetType.ENEMY then
        return Constants.TargetType.SLOT_ENEMY
    else
        return nil
    end
end

-- Utility function to get all token types (excluding special types)
function Constants.getAllTokenTypes()
    return {
        Constants.TokenType.FIRE,
        Constants.TokenType.WATER,
        Constants.TokenType.SALT,
        Constants.TokenType.SUN,
        Constants.TokenType.MOON,
        Constants.TokenType.STAR,
        Constants.TokenType.LIFE,
        Constants.TokenType.MIND,
        Constants.TokenType.VOID
    }
end

-- Utility function to get all shield types
function Constants.getAllShieldTypes()
    return {
        Constants.ShieldType.BARRIER,
        Constants.ShieldType.WARD,
        Constants.ShieldType.FIELD
    }
end

-- Utility function to get all attack types
function Constants.getAllAttackTypes()
    return {
        Constants.AttackType.PROJECTILE,
        Constants.AttackType.REMOTE,
        Constants.AttackType.ZONE,
        Constants.AttackType.UTILITY
    }
end

return Constants