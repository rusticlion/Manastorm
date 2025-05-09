-- initializeParticles.lua
-- Centralized function for initializing particles for each effect type

-- Import dependencies
local Constants = require("core.Constants")

-- Initialize particles function
local function initializeParticles(effect)
    -- Import the appropriate effect module
    local effectModule
    
    -- Different initialization based on effect type
    if effect.type == Constants.AttackType.PROJECTILE then
        effectModule = require("vfx.effects.projectile")
    elseif effect.type == "impact" then
        effectModule = require("vfx.effects.impact")
    elseif effect.type == "cone" then
        effectModule = require("vfx.effects.cone")
    elseif effect.type == "aura" then
        effectModule = require("vfx.effects.aura")
    elseif effect.type == "remote" then
        effectModule = require("vfx.effects.remote")
    elseif effect.type == "beam" then
        effectModule = require("vfx.effects.beam")
    elseif effect.type == "conjure" then
        effectModule = require("vfx.effects.conjure")
    elseif effect.type == "surge" then
        effectModule = require("vfx.effects.surge")
    elseif effect.type == "meteor" then
        effectModule = require("vfx.effects.meteor")
    else
        print("[VFX] Warning: Unknown effect type: " .. tostring(effect.type))
        return
    end
    
    -- Call the module's initialize function if it exists
    if effectModule and effectModule.initialize then
        effectModule.initialize(effect)
    else
        print("[VFX] Warning: No initialize function found for effect type: " .. tostring(effect.type))
    end
end

-- Return the function
return initializeParticles