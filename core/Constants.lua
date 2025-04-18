-- core/Constants.lua
-- Centralized constants for Manastorm
-- Replaces string literals with structured tables for better typesafety and autocomplete

local Constants = {}

-- Token types (mana/resource types)
Constants.TokenType = {
    FIRE = "fire",
    FORCE = "force",
    MOON = "moon",
    NATURE = "nature",
    STAR = "star",
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
    FORCE = "force", 
    MOON = "moon",
    NATURE = "nature",
    STAR = "star",
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
        Constants.TokenType.FORCE,
        Constants.TokenType.MOON,
        Constants.TokenType.NATURE,
        Constants.TokenType.STAR
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