-- systems/VisualResolver.lua
-- Resolves events to appropriate visual effects based on event metadata

local Constants = require("core.Constants")

local VisualResolver = {}

-- Map visualShape strings to base VFX template names
-- This is the primary mapping table for determining visual template from spell shape
local TEMPLATE_BY_SHAPE = {
    -- Beam-like effects
    ["beam"] = Constants.VFXType.BEAM_BASE,
    
    -- Projectile-like effects
    ["bolt"] = Constants.VFXType.BOLT_BASE,
    ["orb"] = Constants.VFXType.PROJ_BASE,
    ["zap"] = Constants.VFXType.PROJ_BASE,
    
    -- Area/zone effects
    ["blast"] = Constants.VFXType.BLAST_BASE,  -- Updated to new BLAST_BASE template
    ["cone"] = Constants.VFXType.BLAST_BASE,   -- Alternative name for same template
    ["groundBurst"] = Constants.VFXType.ZONE_BASE,
    ["meteor"] = Constants.VFXType.METEOR,
    
    -- Remote/direct effects
    ["warp"] = Constants.VFXType.WARP_BASE,
    
    -- Utility effects
    ["surge"] = Constants.VFXType.SURGE_BASE,
    ["affectManaPool"] = Constants.VFXType.UTIL_BASE,
    
    -- Shield-like effects
    ["wings"] = Constants.VFXType.SHIELD_OVERLAY,
    ["mirror"] = Constants.VFXType.SHIELD_OVERLAY,
    
    -- Special effects with unique templates
    ["eclipse"] = "eclipse_base"
}

-- Map attack types to base VFX template names
-- This is used as a fallback when visualShape is not specified
local BASE_BY_ATTACK = {
    [Constants.AttackType.PROJECTILE] = Constants.VFXType.PROJ_BASE,
    [Constants.AttackType.REMOTE] = Constants.VFXType.REMOTE_BASE,
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
    
    -- Debug output for visualShape if present
    if event.visualShape then
        VisualResolver.debug("Event contains visualShape: " .. tostring(event.visualShape))
    end
    
    -- Step 1: Determine base template with priority: effectOverride > legacy > shield_hit > visualShape > attackType > default
    local baseTemplate = DEFAULT_BASE
    local selectionPath = "DEFAULT" -- Track which path determined the template
    
    -- PRIORITY 1: Handle manual override: If the event has an effectOverride, use it directly
    -- This handles the manual vfx specifications from the vfx keyword
    if event.effectOverride then
        baseTemplate = event.effectOverride
        selectionPath = "EFFECT_OVERRIDE"
        
        VisualResolver.debug("Using explicit effect override: " .. event.effectOverride)
        VisualResolver.debug("Effect override source event details:")
        VisualResolver.debug("  - Event type: " .. (event.type or "nil"))
        VisualResolver.debug("  - Affinity: " .. (event.affinity or "nil"))
        VisualResolver.debug("  - Attack type: " .. (event.attackType or "nil"))
        VisualResolver.debug("  - Tags: " .. (event.tags and "present" or "nil"))
        
        -- Use the specified effect but still use the new parameter system
        return baseTemplate, {
            color = COLOR_BY_AFF[event.affinity] or DEFAULT_COLOR,
            scale = 1.0,
            motion = AFFINITY_MOTION[event.affinity] or DEFAULT_MOTION,
            addons = {},
            rangeBand = event.rangeBand,
            elevation = event.elevation
        }
    end
    
    -- PRIORITY 2: Also handle the case where we get the effect directly within an event.effect property
    -- This is needed for the showcase examples in spells.lua
    if event.effect and type(event.effect) == "string" then
        baseTemplate = event.effect
        selectionPath = "EVENT_EFFECT"
        
        VisualResolver.debug("Using effect from direct event.effect property: " .. event.effect)
        return baseTemplate, {
            color = COLOR_BY_AFF[event.affinity] or DEFAULT_COLOR,
            scale = 1.0, 
            motion = AFFINITY_MOTION[event.affinity] or DEFAULT_MOTION,
            addons = {},
            rangeBand = event.rangeBand,
            elevation = event.elevation
        }
    end
    
    -- PRIORITY 3: Handle shield hit event (from shield system)
    if event.effectType == "shield_hit" then
        baseTemplate = "shield_hit_base"
        selectionPath = "SHIELD_HIT"
        
        VisualResolver.debug("Handling shield hit effect")
        
        -- Determine shield color based on shield type
        local color = DEFAULT_COLOR
        
        if event.shieldType == Constants.ShieldType.BARRIER then
            color = {1.0, 1.0, 0.3, 0.8}  -- Yellow for barriers
        elseif event.shieldType == Constants.ShieldType.WARD then 
            color = {0.3, 0.3, 1.0, 0.8}  -- Blue for wards
        elseif event.shieldType == Constants.ShieldType.FIELD then
            color = {0.3, 1.0, 0.3, 0.8}  -- Green for fields
        end
        
        -- Build options with shield-specific values
        local opts = {
            color = color,
            scale = 1.2,  -- Slightly larger scale for impact emphasis
            motion = Constants.MotionStyle.PULSE,
            addons = {},
            rangeBand = event.rangeBand,
            elevation = event.elevation,
            -- VFX system will use vfxParams.x/y first, so we don't need to duplicate
        }
        
        VisualResolver.debug(string.format(
            "Resolved shield hit event to base=%s via %s, color=%s, scale=%.2f, motion=%s",
            baseTemplate,
            selectionPath,
            table.concat(color, ","),
            opts.scale,
            opts.motion
        ))
        
        return baseTemplate, opts
    end
    
    -- PRIORITY 4: Legacy manual VFX: If the event has manualVfx flag and effectType
    if event.manualVfx and event.effectType then
        baseTemplate = event.effectType
        selectionPath = "LEGACY_MANUAL"
        
        VisualResolver.debug("Using legacy manual effect via effectType: " .. event.effectType)
        -- Use the specified effect but still use the new parameter system
        return baseTemplate, {
            color = COLOR_BY_AFF[event.affinity] or DEFAULT_COLOR,
            scale = 1.0,
            motion = AFFINITY_MOTION[event.affinity] or DEFAULT_MOTION,
            addons = {},
            rangeBand = event.rangeBand,
            elevation = event.elevation
        }
    end
    
    -- PRIORITY 5: Use visualShape to look up template in TEMPLATE_BY_SHAPE
    if event.visualShape then
        local visualShape = event.visualShape
        local template = TEMPLATE_BY_SHAPE[visualShape]
        
        if template then
            baseTemplate = template
            selectionPath = "VISUAL_SHAPE"
            VisualResolver.debug("Using visualShape mapping: " .. visualShape .. " -> " .. baseTemplate)
        else
            -- For unknown visualShapes, log warning and fall back to attackType
            VisualResolver.debug("Unknown visualShape: " .. visualShape .. ", falling back to attackType")
        end
    end
    
    -- PRIORITY 6: If no visualShape match, use attack type mapping
    if selectionPath == "DEFAULT" and event.attackType and BASE_BY_ATTACK[event.attackType] then
        baseTemplate = BASE_BY_ATTACK[event.attackType]
        selectionPath = "ATTACK_TYPE"
        VisualResolver.debug("Using attackType mapping: " .. event.attackType .. " -> " .. baseTemplate)
    end
    
    -- If we still have no valid template, use the default
    if selectionPath == "DEFAULT" then
        VisualResolver.debug("No mapping found, using DEFAULT_BASE: " .. DEFAULT_BASE)
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
        "Resolved event to base=%s via %s, color=%s, scale=%.2f, motion=%s, addons=%d",
        baseTemplate,
        selectionPath,
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
        -- Test 1: Fire projectile spell (using attackType)
        {
            type = "DAMAGE",
            affinity = Constants.TokenType.FIRE,
            attackType = Constants.AttackType.PROJECTILE,
            manaCost = 2,
            tags = { DAMAGE = true },
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 2: Water remote spell with higher cost (using attackType)
        {
            type = "DAMAGE",
            affinity = Constants.TokenType.WATER,
            attackType = Constants.AttackType.REMOTE,
            manaCost = 4,
            tags = { DAMAGE = true },
            rangeBand = Constants.RangeState.FAR,
            elevation = Constants.ElevationState.AERIAL
        },
        -- Test 3: Moon-based shield (using attackType)
        {
            type = "CREATE_SHIELD",
            affinity = Constants.TokenType.MOON,
            attackType = Constants.AttackType.UTILITY,
            manaCost = 3,
            tags = { SHIELD = true, DEFENSE = true },
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 4: Manually specified effect (vfx keyword)
        {
            type = "EFFECT",
            effectOverride = Constants.VFXType.FIREBOLT,
            affinity = Constants.TokenType.FIRE,
            attackType = Constants.AttackType.PROJECTILE,
            manaCost = 2,
            tags = { VFX = true },
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 5: Legacy manual VFX
        {
            type = "EFFECT",
            effectType = Constants.VFXType.METEOR,
            manualVfx = true,
            affinity = Constants.TokenType.FIRE,
            attackType = Constants.AttackType.PROJECTILE,
            manaCost = 3,
            tags = { VFX = true },
            rangeBand = Constants.RangeState.FAR,
            elevation = Constants.ElevationState.AERIAL
        },
        -- Test 6: REMOTE attack with "beam" visualShape override
        {
            type = "DAMAGE",
            affinity = Constants.TokenType.MOON,
            attackType = Constants.AttackType.REMOTE,
            visualShape = "beam",
            manaCost = 3,
            tags = { DAMAGE = true },
            rangeBand = Constants.RangeState.FAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 7: Projectile attack with "blast" visualShape override
        {
            type = "DAMAGE",
            affinity = Constants.TokenType.FIRE,
            attackType = Constants.AttackType.PROJECTILE,
            visualShape = "blast",
            manaCost = 3,
            tags = { DAMAGE = true },
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 8: Testing "orb" visualShape
        {
            type = "DAMAGE",
            affinity = Constants.TokenType.STAR,
            attackType = Constants.AttackType.ZONE, -- This would normally use ZONE_BASE
            visualShape = "orb",                    -- But visualShape overrides to PROJ_BASE
            manaCost = 2,
            tags = { DAMAGE = true },
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 9: Testing "warp" visualShape
        {
            type = "EFFECT",
            affinity = Constants.TokenType.VOID,
            attackType = Constants.AttackType.PROJECTILE, -- This would normally use PROJ_BASE
            visualShape = "warp",                         -- But visualShape overrides to UTIL_BASE
            manaCost = 1,
            tags = { MOVEMENT = true },
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 10: Testing "mirror" visualShape
        {
            type = "CREATE_SHIELD",
            affinity = Constants.TokenType.WATER,
            attackType = Constants.AttackType.UTILITY,
            visualShape = "mirror",
            manaCost = 2,
            tags = { SHIELD = true, DEFENSE = true },
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 11: Testing "eclipse" visualShape
        {
            type = "DAMAGE",
            affinity = Constants.TokenType.VOID,
            attackType = Constants.AttackType.ZONE,
            visualShape = "eclipse",
            manaCost = 5,
            tags = { DAMAGE = true, DOT = true },
            rangeBand = Constants.RangeState.FAR,
            elevation = Constants.ElevationState.AERIAL
        },
        -- Test 12: Testing unknown visualShape (should fall back to attackType)
        {
            type = "DAMAGE",
            affinity = Constants.TokenType.FIRE,
            attackType = Constants.AttackType.PROJECTILE,
            visualShape = "unknown_shape",  -- Not in TEMPLATE_BY_SHAPE
            manaCost = 2,
            tags = { DAMAGE = true },
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        },
        -- Test 13: Shield hit effect
        {
            type = "SHIELD_HIT",
            effectType = "shield_hit",
            shieldType = Constants.ShieldType.BARRIER,
            rangeBand = Constants.RangeState.NEAR,
            elevation = Constants.ElevationState.GROUNDED
        }
    }
    
    print("===== VisualResolver Test =====")
    for i, event in ipairs(testEvents) do
        print("\nTest " .. i .. ": " .. event.type .. " event with " .. (event.affinity or "unknown") .. " affinity")
        if event.visualShape then
            print("visualShape: " .. event.visualShape)
        end
        if event.attackType then
            print("attackType: " .. event.attackType)
        end
        
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

-- Execute test function if called directly
-- Only run if arg exists and this file is being run directly
if arg and arg[0] and type(arg[0]) == "string" and arg[0]:find("VisualResolver.lua") then
    VisualResolver.test()
end

return VisualResolver