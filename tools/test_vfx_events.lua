-- test_vfx_events.lua
-- Test script to verify all spells generate VFX events correctly

local SpellCompiler = require("spellCompiler")
local Spells = require("spells").spells
local Keywords = require("keywords")
local Constants = require("core.Constants")

-- Create dummy caster/target/slot objects for testing
local dummyCaster = {
    name = "Test Caster",
    elevation = Constants.ElevationState.GROUNDED,
    gameState = {
        rangeState = Constants.RangeState.NEAR
    },
    spellSlots = {
        { active = false },
        { active = false },
        { active = false }
    },
    manaPool = {
        tokens = {}
    }
}

local dummyTarget = {
    name = "Test Target",
    elevation = Constants.ElevationState.GROUNDED,
    gameState = {
        rangeState = Constants.RangeState.NEAR
    },
    spellSlots = {
        { active = false },
        { active = false },
        { active = false }
    },
    manaPool = {
        tokens = {}
    }
}

local dummySlot = 1

-- Main test function
local function runTest()
    print("=== VFX Events Test ===")
    print("Testing all spells for EFFECT events...")
    
    local results = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        utilityNoVfx = 0
    }
    
    local failures = {}
    
    -- Process all spells
    for spellId, spell in pairs(Spells) do
        results.total = results.total + 1
        
        -- Skip certain spells known to have no visuals
        if spell.skipVfxTest then
            results.skipped = results.skipped + 1
            print(string.format("[SKIP] %s (marked to skip VFX test)", spell.name))
            goto continue
        end
        
        -- Compile the spell
        local compiledSpell = SpellCompiler.compileSpell(spell, Keywords)
        if not compiledSpell then
            table.insert(failures, string.format("Failed to compile spell: %s", spell.name))
            results.failed = results.failed + 1
            goto continue
        end
        
        -- Generate events but don't execute them
        local events = compiledSpell.generateEvents(dummyCaster, dummyTarget, dummySlot)
        
        -- Check for at least one EFFECT event
        local hasEffectEvent = false
        if events then
            for _, event in ipairs(events) do
                if event.type == "EFFECT" then
                    hasEffectEvent = true
                    break
                end
            end
        end
        
        -- Handle utility spells without VFX specially 
        if not hasEffectEvent and spell.attackType == Constants.AttackType.UTILITY and not spell.vfx then
            print(string.format("[INFO] Utility spell with no VFX: %s", spell.name))
            results.utilityNoVfx = results.utilityNoVfx + 1
            goto continue
        end
        
        -- Check if the spell has a VFX defined at the top level
        local hasTopLevelVfx = (spell.vfx ~= nil)
        
        -- Check if the spell has keywords that should generate VFX
        local hasVfxKeyword = false
        if spell.keywords and spell.keywords.vfx then
            hasVfxKeyword = true
        end
        
        -- Check for keywords that have built-in VFX
        local hasBuiltInVfx = false
        if spell.keywords then
            for keyword, _ in pairs(spell.keywords) do
                if keyword == "ground" or keyword == "elevate" then
                    hasBuiltInVfx = true
                    break
                end
            end
        end
        
        -- Test result
        if hasEffectEvent then
            print(string.format("[PASS] %s generates EFFECT events", spell.name))
            results.passed = results.passed + 1
        else
            -- Log what's missing
            local missing = ""
            if not hasTopLevelVfx and not hasVfxKeyword and not hasBuiltInVfx then
                missing = "both top-level VFX and VFX keyword"
            elseif not hasVfxKeyword then
                missing = "VFX keyword (has top-level VFX)"
            else
                missing = "proper event generation"
            end
            
            table.insert(failures, string.format("%s: Missing %s", spell.name, missing))
            results.failed = results.failed + 1
        end
        
        ::continue::
    end
    
    -- Print test results
    print("\n=== Test Results ===")
    print(string.format("Total spells tested: %d", results.total))
    print(string.format("Passed: %d (%.1f%%)", results.passed, (results.passed / results.total) * 100))
    print(string.format("Failed: %d (%.1f%%)", results.failed, (results.failed / results.total) * 100))
    print(string.format("Skipped: %d", results.skipped))
    print(string.format("Utility spells without VFX: %d", results.utilityNoVfx))
    
    -- Print failures if any
    if #failures > 0 then
        print("\n=== Failed Spells ===")
        for _, failure in ipairs(failures) do
            print(failure)
        end
    end
    
    return results.failed == 0
end

-- Run the test
local success = runTest()
print(string.format("\nTest %s!", success and "PASSED" and "FAILED"))

-- Return success status (for automated testing)
return success