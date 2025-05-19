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
    APPEARING = "APPEARING",   -- Animating into existence from wizard to pool (transition state)
    RETURNING = "RETURNING",   -- Animating back to pool center (transition state)
    ORBITING = "ORBITING",     -- Animating from pool center to orbit (transition state)
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
-- Constants.Color = {
--     BLACK = {0, 0, 0, 1},                    -- #000000
--     MAROON = {0.592, 0.184, 0.278, 1},       -- #972f47
--     FOREST = {0.482, 0.620, 0.145, 1},       -- #7b9e25
--     OCEAN = {0.282, 0.184, 0.745, 1},        -- #482fbe
--     SMOKE = {0.557, 0.475, 0.420, 1},        -- #8e796b
--     CRIMSON = {0.906, 0.122, 0.231, 1},      -- #e71f3b
--     LIME = {0.651, 0.871, 0, 1},             -- #a6de00
--     SKY = {0.365, 0.459, 0.745, 1},          -- #5d75be
--     SAND = {0.906, 0.722, 0.427, 1},         -- #e7b86d
--     OCHRE = {0.847, 0.349, 0.024, 1},        -- #d85906
--     ORANGE = {0.984, 0.675, 0.043, 1},       -- #fbac0b
--     PUCE = {0.851, 0.502, 0.494, 1},         -- #d9807e
--     BONE = {0.906, 0.890, 0.745, 1},         -- #e7e3be
--     YELLOW = {0.984, 0.941, 0.024, 1},       -- #fbf006
--     MINT = {0.502, 0.953, 0.561, 1},         -- #80f38f
--     PINK = {1, 0.820, 1, 1}                  -- #ffd1ff
-- }

Constants.Color = {
    BLACK          = {0.000, 0.000, 0.000, 1}, -- #000000
    VOID           = {0.102, 0.043, 0.118, 1}, -- #1a0b1e
    GRAY           = {0.620, 0.620, 0.620, 1}, -- #9e9e9e
    WHITE          = {1.000, 1.000, 1.000, 1}, -- #ffffff
    RED_HERO       = {1.000, 0.290, 0.141, 1}, -- #ff4a24
    RED_SHADE      = {0.765, 0.212, 0.094, 1}, -- #c33618
    GREEN_HERO     = {0.651, 0.871, 0.000, 1}, -- #a6de00
    GREEN_SHADE    = {0.275, 0.400, 0.000, 1}, -- #466600
    BLUE_HERO      = {0.000, 0.573, 0.875, 1}, -- #0092df
    BLUE_SHADE     = {0.000, 0.322, 0.600, 1}, -- #005299
    YELLOW_HERO    = {1.000, 0.843, 0.000, 1}, -- #ffd700
    YELLOW_SHADE   = {0.784, 0.651, 0.000, 1}, -- #c8a600
    LAVENDER_HERO  = {0.788, 0.722, 1.000, 1}, -- #c9b8ff
    LAVENDER_SHADE = {0.478, 0.424, 0.769, 1}, -- #7a6cc4
    PURPLE_HERO    = {0.353, 0.204, 0.769, 1}, -- #5a34c4
    MAGENTA_HERO   = {0.820, 0.145, 0.659, 1}, -- #d125a8
}

-- Default color for unknown types
Constants.Color.DEFAULT = Constants.Color.SMOKE

-- Helper function to get color based on token type
-- Added mappings for types found in manapool.lua (Nature, Force)
function Constants.getColorForTokenType(tokenType)
    if tokenType == Constants.TokenType.FIRE then return Constants.Color.RED_HERO
    elseif tokenType == Constants.TokenType.WATER then return Constants.Color.BLUE_HERO
    elseif tokenType == Constants.TokenType.SALT then return Constants.Color.GRAY
    elseif tokenType == Constants.TokenType.SUN then return Constants.Color.YELLOW_HERO
    elseif tokenType == Constants.TokenType.MOON then return Constants.Color.LAVENDER_HERO
    elseif tokenType == Constants.TokenType.STAR then return Constants.Color.YELLOW_HERO
    elseif tokenType == Constants.TokenType.LIFE then return Constants.Color.GREEN_HERO
    elseif tokenType == Constants.TokenType.MIND then return Constants.Color.MAGENTA_HERO
    elseif tokenType == Constants.TokenType.VOID then return Constants.Color.WHITE
    else
        print("Warning: Unknown token type for color lookup: " .. tostring(tokenType))
        return Constants.Color.DEFAULT
    end
end

-- Shield types for blocking spells
Constants.ShieldType = {
    BARRIER = "barrier",    -- Physical barrier (blocks projectiles)
    WARD = "ward",          -- Magical ward (blocks remote spells)
    FIELD = "field"         -- Magical field (flexible defense)
}

-- Attack types for spells
-- TODO: handle "beam" and "blast", which are purely visual variants of projectile. Maybe other hooks into them from non-Shield rules.
-- This makes the overall palette: Projectiles, Beams, and Blasts beat nothing, Remotes beat Barriers, Zones beat Wards.
Constants.AttackType = {
    PROJECTILE = "projectile",  -- Magic flies toward a target, blocked by all shield types but efficient
    REMOTE = "remote",          -- Magic directly affects target, beats Barriers, expensive or slow
    ZONE = "zone",              -- Magic affects a physical area, beats Wards, position-dependent
    UTILITY = "utility"         -- Non-damaging effect, can't be blocked
}

Constants.VisualShape = {
    BOLT = "bolt",
    BEAM = "beam",
    BLAST = "blast",
    CONE = "cone",
    REMOTE = "remote",
    METEOR = "meteor",
    CONJURE_BASE = "conjure",
    SURGE = "surge",
    AURA = "aura",
    VORTEX = "vortex",
    TORNADO = "tornado",
    WAVE = "wave",
}

Constants.CastSpeed = {
    VERY_SLOW = 15,
    SLOW = 12,
    NORMAL = 9,
    FAST = 6,
    VERY_FAST = 3,
    ONE_TIER = 3
}

-- Target types for keywords
Constants.TargetType = {
    -- Simple targeting - used in spell definitions
    SELF = "SELF",             -- Target the caster
    ENEMY = "ENEMY",           -- Target the opponent
    ALL = "ALL",               -- Target all wizards
    
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

-- Status effect types applied to wizards
Constants.StatusType = {
    BURN = "burn",       -- Damage over time
    SLOW = "slow",       -- Increases next cast time
    STUN = "stun",       -- Prevents actions
    REFLECT = "reflect"  -- Reflects incoming spells
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
-- Spell metadata field names for consistent reference
Constants.SpellMetadata = {
    ID = "id",
    NAME = "name",
    AFFINITY = "affinity",
    DESCRIPTION = "description",
    ATTACK_TYPE = "attackType",
    CAST_TIME = "castTime",
    COST = "cost",
    KEYWORDS = "keywords",
    VISUAL_SHAPE = "visualShape",
    VFX = "vfx",
    SFX = "sfx",
    ZONE = "zone"
}

-- Utility function to get all spell metadata field names
function Constants.getAllSpellMetadataFields()
    local fields = {}
    for _, value in pairs(Constants.SpellMetadata) do
        table.insert(fields, value)
    end
    return fields
end

-- Keyword metadata field names for consistent reference
Constants.KeywordMetadata = {
    BEHAVIOR = "behavior",
    EXECUTE = "execute",
    TARGET_TYPE = "targetType",
    CATEGORY = "category",
    PARAMS = "params",
    ENABLED = "enabled",
    VALUE = "value"
}

-- Utility function to get all keyword metadata field names
function Constants.getAllKeywordMetadataFields()
    local fields = {}
    for _, value in pairs(Constants.KeywordMetadata) do
        table.insert(fields, value)
    end
    return fields
end

-- Event metadata field names for consistent reference
Constants.EventMetadata = {
    TYPE = "type",
    SOURCE = "source",
    TARGET = "target",
    AMOUNT = "amount",
    DAMAGE_TYPE = "damageType",
    TOKEN_TYPE = "tokenType",
    DURATION = "duration",
    POSITION = "position",
    ELEVATION = "elevation",
    SLOT_INDEX = "slotIndex",
    VFX = "vfx",
    SFX = "sfx",
    AFFINITY = "affinity",
    ATTACK_TYPE = "attackType",
    TAGS = "tags"
}

-- Utility function to get all event metadata field names
function Constants.getAllEventMetadataFields()
    local fields = {}
    for _, value in pairs(Constants.EventMetadata) do
        table.insert(fields, value)
    end
    return fields
end

-- Visual effect types for consistent usage across the codebase
Constants.VFXType = {
    -- General effects
    IMPACT = "impact",
    
    -- Base template effects (used by VisualResolver)
    PROJ_BASE = "proj_base",       -- Base projectile effect
    BOLT_BASE = "bolt_base",       -- Base bolt effect
    BEAM_BASE = "beam_base",       -- Base beam effect
    REMOTE_BASE = "remote_base",   -- Base remote effect (explosion/flash)
    WARP_BASE = "warp_base",       -- Base warp effect (reality distortion)
    ZONE_BASE = "zone_base",       -- Base zone/area effect
    BLAST_BASE = "blast_base",     -- Base conical blast effect
    UTIL_BASE = "util_base",       -- Base utility effect
    SURGE_BASE = "surge_base",      -- Base surge fountain effect
    CONJURE_BASE = "conjure_base", -- Base token conjuration effect
    IMPACT_BASE = "impact_base",   -- Base impact effect
    
    -- Overlay addon effects (used by VisualResolver)
    DAMAGE_OVERLAY = "damage_overlay",
    EMBER_OVERLAY = "ember_overlay",
    DOT_OVERLAY = "dot_overlay",
    SPARKLE_OVERLAY = "sparkle_overlay",
    RESOURCE_OVERLAY = "resource_overlay",
    MOVEMENT_OVERLAY = "movement_overlay",
    RISE_OVERLAY = "rise_overlay",
    FALL_OVERLAY = "fall_overlay",
    SHIELD_OVERLAY = "shield_overlay",
    BARRIER_OVERLAY = "barrier_overlay",
    
    -- Movement and positioning effects
    TIDAL_FORCE_GROUND = "tidal_force_ground",
    GRAVITY_PIN_GROUND = "gravity_pin_ground",
    GRAVITY_TRAP_SET = "gravity_trap_set",
    FORCE_BLAST = "force_blast",
    
    -- Special fire effects
    FORCE_BLAST_UP = "force_blast_up",
    ELEVATION_UP = "elevation_up",
    ELEVATION_DOWN = "elevation_down",
    RANGE_CHANGE = "range_change",
    FORCE_POSITION = "force_position",
    
    -- Resource effects
    FREE_MANA = "free_mana",
    TOKEN_LOCK = "token_lock",
    TOKEN_SHIFT = "token_shift",
    TOKEN_CONSUME = "token_consume",
    
    -- Projectile spells
    FIREBOLT = "firebolt",
    METEOR = "meteor",
    TIDAL_FORCE = "tidal_force",
    LUNARDISJUNCTION = "lunardisjunction",
    
    -- Area/zone effects
    MISTVEIL = "mistveil",
    EMBERLIFT = "emberlift",
    FULLMOONBEAM = "fullmoonbeam",
    DISJOINT_CANCEL = "disjoint_cancel",
    
    -- Conjuration effects
    CONJUREFIRE = "conjurefire",
    CONJUREMOONLIGHT = "conjuremoonlight",
    FORCE_CONJURE = "force_conjure",
    STAR_CONJURE = "star_conjure",
    VOLATILECONJURING = "volatileconjuring",
    NOVA_CONJURE = "nova_conjure",
    WITCH_CONJURE = "witch_conjure",
    
    -- Defense effects
    SHIELD = "shield",
    REFLECT = "reflect",
    
    -- Spell timing effects
    SPELL_ACCELERATE = "spell_accelerate",
    SPELL_CANCEL = "spell_cancel",
    SPELL_FREEZE = "spell_freeze",
    SPELL_ECHO = "spell_echo"
}

-- Utility function to get all VFX types
function Constants.getAllVFXTypes()
    local types = {}
    for _, value in pairs(Constants.VFXType) do
        table.insert(types, value)
    end
    return types
end

-- Utility function to check if a value exists in VFXType
function Constants.isValidVFXType(value)
    for _, v in pairs(Constants.VFXType) do
        if v == value then
            return true
        end
    end
    return false
end

-- Motion styles for VFX particles
Constants.MotionStyle = {
    RADIAL = "radial",     -- Particles expand outward in all directions (default)
    DIRECTIONAL = "directional", -- Particles move in a specific direction
    SWIRL = "swirl",       -- Particles move in a circular/spiral pattern
    RISE = "rise",         -- Particles float upward
    FALL = "fall",         -- Particles fall downward
    PULSE = "pulse",       -- Particles expand and contract rhythmically
    RIPPLE = "ripple",     -- Particles move in wave-like patterns
    STATIC = "static"      -- Particles stay in place with minimal motion
}

-- Utility function to get all motion styles
function Constants.getAllMotionStyles()
    local styles = {}
    for _, value in pairs(Constants.MotionStyle) do
        table.insert(styles, value)
    end
    return styles
end

return Constants