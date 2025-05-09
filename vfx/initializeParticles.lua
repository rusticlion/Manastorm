-- initializeParticles.lua
-- Centralized function for initializing particles for each effect type

-- Import dependencies
local Constants = require("core.Constants")

-- Initialize particles function
local function initializeParticles(effect)
    -- Import the appropriate effect module
    local effectModule

    -- Extract the base effect type for loading the proper module
    local effectType = effect.type

    -- Map template names directly to module paths
    local typeToModuleMap = {
        -- Base templates
        ["proj_base"] = "projectile",
        ["bolt_base"] = "projectile",
        ["impact_base"] = "impact",
        ["beam_base"] = "beam",
        ["blast_base"] = "cone",
        ["zone_base"] = "aura",
        ["util_base"] = "aura",
        ["surge_base"] = "surge",
        ["conjure_base"] = "conjure",
        ["remote_base"] = "remote",
        ["warp_base"] = "remote",
        ["shield_hit_base"] = "impact",

        -- Specific effect templates
        ["meteor"] = "meteor",
        ["impact"] = "impact",
        ["force_blast"] = "impact",
        ["free_mana"] = "aura",
        ["shield"] = "aura",
        ["emberlift"] = "surge",
        ["range_change"] = "surge",

        -- Critical backward compatibility (to be removed in future)
        [Constants.AttackType.PROJECTILE] = "projectile"
    }

    local moduleName = typeToModuleMap[effectType]

    -- If type isn't in our map, attempt a direct match with module name
    if not moduleName then
        -- Try using type as direct module name
        if effectType and (effectType == "projectile" or
                         effectType == "impact" or
                         effectType == "beam" or
                         effectType == "cone" or
                         effectType == "aura" or
                         effectType == "remote" or
                         effectType == "meteor" or
                         effectType == "surge" or
                         effectType == "conjure") then
            moduleName = effectType
            print(string.format("[VFX] Using effect.type '%s' directly as module name", effectType))
        else
            -- Last fallback to avoid crashes - default to impact effect
            print(string.format("[VFX] Warning: Unknown effect type: '%s' - falling back to impact", tostring(effectType)))
            moduleName = "impact"
        end
    end

    -- Load the module based on name
    effectModule = require("vfx.effects." .. moduleName)

    -- Call the module's initialize function if it exists
    if effectModule and effectModule.initialize then
        effectModule.initialize(effect)
    else
        print("[VFX] Warning: No initialize function found for effect type: " .. tostring(effectType))
    end
end

-- Return the function
return initializeParticles