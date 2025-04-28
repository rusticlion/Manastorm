-- fix_vfx_events.lua
-- Script to update spells to properly use the event system for VFX

local Spells = require("spells").spells
local Keywords = require("keywords")
local Constants = require("core.Constants")
local SpellCompiler = require("spellCompiler")

-- Color formatting for console output
local colors = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m"
}

-- Convert a spell's top-level VFX property to a vfx keyword
local function updateSpellVfx(spell)
    if not spell then return false end
    
    -- Skip spells that already use the vfx keyword properly
    if spell.keywords and spell.keywords.vfx then
        print(colors.green .. "✓ " .. spell.name .. " already using vfx keyword" .. colors.reset)
        return false
    end
    
    -- Skip utility spells without VFX if they're not meant to have visuals
    if spell.attackType == Constants.AttackType.UTILITY and not spell.vfx then
        print(colors.yellow .. "⚠ Skipping utility spell without VFX: " .. spell.name .. colors.reset)
        return false
    end
    
    -- If the spell has a top-level VFX property but no vfx keyword,
    -- add the vfx keyword using the top-level VFX value
    if spell.vfx then
        -- Create the keywords table if it doesn't exist
        spell.keywords = spell.keywords or {}
        
        -- Different handling based on attack type to determine target
        local targetType = Constants.TargetType.ENEMY
        if spell.attackType == Constants.AttackType.UTILITY then
            -- For utility spells, target self
            targetType = Constants.TargetType.SELF
        elseif spell.vfx:find("conjure") then
            -- For conjuration effects, target the pool
            targetType = "POOL_SELF"
        end
        
        -- Get the proper VFX type from Constants if possible
        local effectType = spell.vfx
        for typeName, typeValue in pairs(Constants.VFXType) do
            if typeValue == spell.vfx then
                effectType = typeValue
                break
            end
        end
        
        -- Add the vfx keyword with appropriate parameters
        spell.keywords.vfx = {
            effect = effectType,
            target = targetType
        }
        
        print(colors.green .. "✓ Added vfx keyword to " .. spell.name .. 
              " with effect=" .. effectType .. ", target=" .. targetType .. colors.reset)
        return true
    end
    
    -- Check for special cases like ground/elevate that have built-in VFX
    local hasBuiltInVfx = false
    if spell.keywords then
        for keyword, _ in pairs(spell.keywords) do
            if keyword == "ground" or keyword == "elevate" then
                hasBuiltInVfx = true
                break
            end
        end
    end
    
    if hasBuiltInVfx then
        print(colors.blue .. "ℹ " .. spell.name .. " uses keywords with built-in VFX" .. colors.reset)
        return false
    end
    
    -- If we get here, the spell has no VFX defined and should probably have one
    print(colors.red .. "✗ " .. spell.name .. " has no VFX defined" .. colors.reset)
    return false
end

-- Main function to update all spells
local function updateAllSpells()
    print(colors.cyan .. "=== Updating Spells VFX Events ===" .. colors.reset)
    
    local stats = {
        total = 0,
        updated = 0,
        alreadyCorrect = 0,
        skipped = 0,
        noVfx = 0
    }
    
    -- Process all spells
    for spellId, spell in pairs(Spells) do
        stats.total = stats.total + 1
        
        local updated = updateSpellVfx(spell)
        if updated then
            stats.updated = stats.updated + 1
        elseif spell.keywords and spell.keywords.vfx then
            stats.alreadyCorrect = stats.alreadyCorrect + 1
        elseif spell.attackType == Constants.AttackType.UTILITY and not spell.vfx then
            stats.skipped = stats.skipped + 1
        else
            stats.noVfx = stats.noVfx + 1
        end
    end
    
    -- Print summary statistics
    print(colors.cyan .. "\n=== Summary ===" .. colors.reset)
    print("Total spells: " .. stats.total)
    print(colors.green .. "Already using vfx keyword: " .. stats.alreadyCorrect .. colors.reset)
    print(colors.green .. "Updated to use vfx keyword: " .. stats.updated .. colors.reset)
    print(colors.yellow .. "Skipped (utility without VFX): " .. stats.skipped .. colors.reset)
    print(colors.red .. "Still missing VFX: " .. stats.noVfx .. colors.reset)
    
    return stats
end

-- Run the update process
local stats = updateAllSpells()

-- Return stats for use in automated systems
return stats