-- systems/VisualResolver.lua
-- Resolves events to appropriate visual effects based on event metadata

local Constants = require("core.Constants")

local VisualResolver = {}

-- Map attack types to base VFX template names
local BASE_BY_ATTACK = {
    [Constants.AttackType.PROJECTILE] = Constants.VFXType.PROJ_BASE,
    [Constants.AttackType.REMOTE] = Constants.VFXType.BEAM_BASE,
    [Constants.AttackType.ZONE] = Constants.VFXType.ZONE_BASE,
    [Constants.AttackType.UTILITY] = Constants.VFXType.UTIL_BASE
}

-- Map affinities (token types) to colors
local COLOR_BY_AFF = {
    [Constants.TokenType.FIRE] = Constants.Color.CRIMSON,
    [Constants.TokenType.WATER] = Constants.Color.OCEAN,
    [Constants.TokenType.SALT] = Constants.Color.SAND,
    [Constants.TokenType.SUN] = Constants.Color.ORANGE,
    [Constants.TokenType.MOON] = Constants.Color.SKY,
    [Constants.TokenType.STAR] = Constants.Color.YELLOW,
    [Constants.TokenType.LIFE] = Constants.Color.LIME,
    [Constants.TokenType.MIND] = Constants.Color.PINK,
    [Constants.TokenType.VOID] = Constants.Color.BONE
}

-- Map specific tags to overlay visual effects
local TAG_ADDONS = {
    DAMAGE = Constants.VFXType.DAMAGE_OVERLAY,
    BURN = Constants.VFXType.EMBER_OVERLAY,
    DOT = Constants.VFXType.DOT_OVERLAY,
    CONJURE = Constants.VFXType.SPARKLE_OVERLAY,
    RESOURCE = Constants.VFXType.RESOURCE_OVERLAY,
    MOVEMENT = Constants.VFXType.MOVEMENT_OVERLAY,
    ELEVATE = Constants.VFXType.RISE_OVERLAY,
    GROUND = Constants.VFXType.FALL_OVERLAY,
    SHIELD = Constants.VFXType.SHIELD_OVERLAY,
    DEFENSE = Constants.VFXType.BARRIER_OVERLAY
}

-- Map affinities to motion styles
local AFFINITY_MOTION = {
    [Constants.TokenType.FIRE] = Constants.MotionStyle.RISE,
    [Constants.TokenType.WATER] = Constants.MotionStyle.SWIRL,
    [Constants.TokenType.SALT] = Constants.MotionStyle.FALL,
    [Constants.TokenType.SUN] = Constants.MotionStyle.PULSE,
    [Constants.TokenType.MOON] = Constants.MotionStyle.RIPPLE,
    [Constants.TokenType.STAR] = Constants.MotionStyle.DIRECTIONAL,
    [Constants.TokenType.LIFE] = Constants.MotionStyle.RISE,
    [Constants.TokenType.MIND] = Constants.MotionStyle.SWIRL,
    [Constants.TokenType.VOID] = Constants.MotionStyle.STATIC
}

-- Default values
local DEFAULT_BASE = Constants.VFXType.IMPACT_BASE
local DEFAULT_COLOR = Constants.Color.SMOKE
local DEFAULT_MOTION = Constants.MotionStyle.RADIAL

-- Helper function for debug output without requiring vfx module dependency
function VisualResolver.debug(message)
    print("[VisualResolver] " .. message)
end

-- Main resolver function: Maps event data to visual parameters
-- Returns (baseTemplateName, options) as two separate values
function VisualResolver.pick(event)
    VisualResolver.debug("==========================================")
    VisualResolver.debug("VisualResolver.pick() called with event:")
    VisualResolver.debug("Event type: " .. (event and event.type or "nil"))
    VisualResolver.debug("Event source: " .. (event and event.source or "nil"))
    VisualResolver.debug("Event target: " .. (event and event.target or "nil"))
    VisualResolver.debug("==========================================")
    
    -- Validate event
    if not event or type(event) ~= "table" then
        VisualResolver.debug("Invalid event provided to pick()")
        return DEFAULT_BASE, { color = DEFAULT_COLOR, scale = 1.0, motion = DEFAULT_MOTION, addons = {} }
    end
    
    -- Handle manual override: If the event has an effectOverride, use it directly
    -- This handles the manual vfx specifications from the vfx keyword
    if event.effectOverride then
        VisualResolver.debug("Using explicit effect override: " .. event.effectOverride)
        
        -- Full event logging for debug
        VisualResolver.debug("Effect override source event details:")
        VisualResolver.debug("  - Event type: " .. (event.type or "nil"))
        VisualResolver.debug("  - Affinity: " .. (event.affinity or "nil"))
        VisualResolver.debug("  - Attack type: " .. (event.attackType or "nil"))
        VisualResolver.debug("  - Tags: " .. (event.tags and "present" or "nil"))
        
        -- Use the specified effect but still use the new parameter system
        return event.effectOverride, {
            color = COLOR_BY_AFF[event.affinity] or DEFAULT_COLOR,
            scale = 1.0,
            motion = AFFINITY_MOTION[event.affinity] or DEFAULT_MOTION,
            addons = {},
            rangeBand = event.rangeBand,
            elevation = event.elevation
        }
    end
    
    -- Also handle the case where we get the effect directly within an event.effect property
    -- This is needed for the showcase examples in spells.lua
    if event.effect and type(event.effect) == "string" then
        VisualResolver.debug("Using effect from direct event.effect property: " .. event.effect)
        return event.effect, {
            color = COLOR_BY_AFF[event.affinity] or DEFAULT_COLOR,
            scale = 1.0, 
            motion = AFFINITY_MOTION[event.affinity] or DEFAULT_MOTION,
            addons = {},
            rangeBand = event.rangeBand,
            elevation = event.elevation
        }
    end
    
    -- Handle shield hit event (from shield system)
    if event.effectType == "shield_hit" then
        VisualResolver.debug("Handling shield hit effect")
        
        -- Determine shield color based on shield type
        local color = DEFAULT_COLOR
        
        if event.shieldType == "barrier" then
            color = {1.0, 1.0, 0.3, 0.8}  -- Yellow for barriers
        elseif event.shieldType == "ward" then 
            color = {0.3, 0.3, 1.0, 0.8}  -- Blue for wards
        elseif event.shieldType == "field" then
            color = {0.3, 1.0, 0.3, 0.8}  -- Green for fields
        end
        
        -- Return shield hit template with proper color
        return "shield_hit_base", {
            color = color,
            scale = 1.2,  -- Slightly larger scale for impact emphasis
            motion = Constants.MotionStyle.PULSE,
            addons = {},
            rangeBand = event.rangeBand,
            elevation = event.elevation,
            -- VFX system will use vfxParams.x/y first, so we don't need to duplicate
        }
    end
    
    -- Legacy manual VFX: If the event has manualVfx flag and effectType
    if event.manualVfx and event.effectType then
        VisualResolver.debug("Using legacy manual effect via effectType: " .. event.effectType)
        -- Use the specified effect but still use the new parameter system
        return event.effectType, {
            color = COLOR_BY_AFF[event.affinity] or DEFAULT_COLOR,
            scale = 1.0,
            motion = AFFINITY_MOTION[event.affinity] or DEFAULT_MOTION,
            addons = {},
            rangeBand = event.rangeBand,
            elevation = event.elevation
        }
    end
    
    -- Step 1: Determine base template from attack type
    local baseTemplate = DEFAULT_BASE
    if event.attackType and BASE_BY_ATTACK[event.attackType] then
        baseTemplate = BASE_BY_ATTACK[event.attackType]
    end
    
    -- Step 2: Determine color from affinity
    local color = DEFAULT_COLOR
    if event.affinity and COLOR_BY_AFF[event.affinity] then
        color = COLOR_BY_AFF[event.affinity]
    end
    
    -- Step 3: Calculate scale based on mana cost
    local manaValue = event.manaCost or 1
    local scale = 0.8 + (0.15 * manaValue)
    if scale > 2.0 then scale = 2.0 end  -- Cap at 2.0x scale
    
    -- Step 4: Determine motion style from affinity
    local motion = DEFAULT_MOTION
    if event.affinity and AFFINITY_MOTION[event.affinity] then
        motion = AFFINITY_MOTION[event.affinity]
    end
    
    -- Step 5: Build addons list from tags
    local addons = {}
    if event.tags and type(event.tags) == "table" then
        for tag, _ in pairs(event.tags) do
            if TAG_ADDONS[tag] then
                table.insert(addons, TAG_ADDONS[tag])
            end
        end
    end
    
    -- Build and return the options table
    local opts = {
        color = color,
        scale = scale,
        motion = motion,
        addons = addons,
        rangeBand = event.rangeBand,
        elevation = event.elevation
    }
    
    VisualResolver.debug(string.format(
        "Resolved event to base=%s, color=%s, scale=%.2f, motion=%s, addons=%d",
        baseTemplate,
        table.concat(color, ","),
        scale,
        motion,
        #addons
    ))
    
    -- Additional debug for tag processing
    if event.tags and type(event.tags) == "table" then
        local tagList = ""
        for tag, _ in pairs(event.tags) do
            tagList = tagList .. tag .. ", "
        end
        VisualResolver.debug("Event tags: " .. tagList)
        
        local addonList = ""
        for _, addon in ipairs(addons) do
            addonList = addonList .. addon .. ", "
        end
        VisualResolver.debug("Resolved addons: " .. (addonList ~= "" and addonList or "none"))
    else
        VisualResolver.debug("Event has no tags")
    end
    
    VisualResolver.debug("==========================================")
    return baseTemplate, opts
end

-- Helper function to test the resolver with sample events
function VisualResolver.test()
    local testEvents = {
        -- Test 1: Fire projectile spell
        {
            type = "DAMAGE",
            affinity = "fire",
            attackType = "projectile",
            manaCost = 2,
            tags = { DAMAGE = true },
            rangeBand = "NEAR",
            elevation = "GROUNDED"
        },
        -- Test 2: Water remote spell with higher cost
        {
            type = "DAMAGE",
            affinity = "water",
            attackType = "remote",
            manaCost = 4,
            tags = { DAMAGE = true },
            rangeBand = "FAR",
            elevation = "AERIAL"
        },
        -- Test 3: Moon-based shield
        {
            type = "CREATE_SHIELD",
            affinity = "moon",
            attackType = "utility",
            manaCost = 3,
            tags = { SHIELD = true, DEFENSE = true },
            rangeBand = "NEAR",
            elevation = "GROUNDED"
        },
        -- Test 4: Manually specified effect (vfx keyword)
        {
            type = "EFFECT",
            effectType = "firebolt",
            manualVfx = true,
            affinity = "fire",
            attackType = "projectile",
            manaCost = 2,
            tags = { VFX = true },
            rangeBand = "NEAR",
            elevation = "GROUNDED"
        }
    }
    
    print("===== VisualResolver Test =====")
    for i, event in ipairs(testEvents) do
        print("\nTest " .. i .. ": " .. event.type .. " event with " .. (event.affinity or "unknown") .. " affinity")
        local base, opts = VisualResolver.pick(event)
        print("Base template: " .. base)
        print("Color: " .. table.concat(opts.color, ","))
        print("Scale: " .. opts.scale)
        print("Motion: " .. opts.motion)
        print("Addons: " .. (#opts.addons > 0 and table.concat(opts.addons, ", ") or "none"))
        print("Range: " .. (opts.rangeBand or "none"))
        print("Elevation: " .. (opts.elevation or "none"))
    end
    print("\n================================")
end

return VisualResolver