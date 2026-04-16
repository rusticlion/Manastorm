-- test_vfx_events.lua
-- Audits whether spells drive visuals directly or via EventRunner-visible events.

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

local VISUAL_EVENT_TYPES = {
    EFFECT = true,
    DAMAGE = true,
    BLOCKED_DAMAGE = true,
    APPLY_STATUS = true,
    SET_ELEVATION = true,
    SET_RANGE = true,
    FORCE_POSITION = true,
    CONJURE_TOKEN = true,
    DISSIPATE_TOKEN = true,
    SHIFT_TOKEN = true,
    LOCK_TOKEN = true,
    CONSUME_TOKENS = true,
    ACCELERATE_SPELL = true,
    CANCEL_SPELL = true,
    FREEZE_SPELL = true,
    DISRUPT_AND_SHIFT = true,
    CREATE_SHIELD = true,
    REFLECT = true,
    ECHO = true
}

local function inspectEvents(events)
    local info = {
        hasDirectEffect = false,
        hasVisualDriver = false,
        eventTypes = {}
    }

    for _, event in ipairs(events or {}) do
        if event and event.type then
            info.eventTypes[event.type] = true
            if event.type == "EFFECT" then
                info.hasDirectEffect = true
            end
            if VISUAL_EVENT_TYPES[event.type] then
                info.hasVisualDriver = true
            end
        end
    end

    return info
end

local function listEventTypes(eventTypes)
    local names = {}
    for eventType, present in pairs(eventTypes) do
        if present then
            table.insert(names, eventType)
        end
    end
    table.sort(names)
    return table.concat(names, ", ")
end

local function hasDeferredOnlyUtilityShape(spell)
    if not spell or spell.attackType ~= Constants.AttackType.UTILITY then
        return false
    end

    if spell.id == "none" then
        return false
    end

    return spell.visualShape ~= nil
        or spell.vfx ~= nil
        or (spell.keywords and spell.keywords.vfx ~= nil)
        or (spell.keywords and spell.keywords.sustain ~= nil)
        or (spell.keywords and spell.keywords.trap_trigger ~= nil)
        or (spell.keywords and spell.keywords.trap_effect ~= nil)
        or (spell.keywords and spell.keywords.field_status ~= nil)
end

-- Main test function
local function runTest()
    print("=== VFX Events Test ===")
    print("Testing all spells for direct or EventRunner-driven visual events...")
    
    local results = {
        total = 0,
        directEffects = 0,
        eventDriven = 0,
        failed = 0,
        skipped = 0,
        warned = 0,
        utilityDeferred = 0
    }
    
    local failures = {}
    local warnings = {}
    
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

        local audit = inspectEvents(events)
        local eventTypeList = listEventTypes(audit.eventTypes)

        if audit.hasDirectEffect then
            print(string.format("[PASS] %s emits direct EFFECT (%s)", spell.name, eventTypeList))
            results.directEffects = results.directEffects + 1
        elseif audit.hasVisualDriver then
            print(string.format("[PASS] %s emits visual-driving gameplay events (%s)", spell.name, eventTypeList))
            results.eventDriven = results.eventDriven + 1
        elseif spell.attackType ~= Constants.AttackType.UTILITY then
            table.insert(
                failures,
                string.format("%s: no visual-driving events generated (%s)", spell.name, eventTypeList ~= "" and eventTypeList or "none")
            )
            results.failed = results.failed + 1
        elseif hasDeferredOnlyUtilityShape(spell) then
            table.insert(
                warnings,
                string.format("%s: utility/sustained spell has visual intent but no immediate visual-driving event", spell.name)
            )
            print(string.format("[WARN] %s has no immediate visual-driving event", spell.name))
            results.warned = results.warned + 1
            results.utilityDeferred = results.utilityDeferred + 1
        else
            print(string.format("[INFO] Utility spell with no immediate visual-driving event: %s", spell.name))
        end
        
        ::continue::
    end
    
    -- Print test results
    print("\n=== Test Results ===")
    print(string.format("Total spells tested: %d", results.total))
    print(string.format("Direct EFFECT spells: %d", results.directEffects))
    print(string.format("Event-driven visual spells: %d", results.eventDriven))
    print(string.format("Failed: %d (%.1f%%)", results.failed, (results.failed / results.total) * 100))
    print(string.format("Skipped: %d", results.skipped))
    print(string.format("Warnings: %d", results.warned))
    print(string.format("Deferred utility visuals: %d", results.utilityDeferred))
    
    -- Print failures if any
    if #failures > 0 then
        print("\n=== Failed Spells ===")
        for _, failure in ipairs(failures) do
            print(failure)
        end
    end

    if #warnings > 0 then
        print("\n=== Warnings ===")
        for _, warning in ipairs(warnings) do
            print(warning)
        end
    end
    
    return results.failed == 0
end

-- Run the test
-- Optional visual sweep runner: spawn base templates at NEAR/FAR with CA on/off
local function visualSweep()
    local VFX = require("vfx")
    local Constants = require("core.Constants")
    local VisualResolver = require("systems.VisualResolver")

    local centerX, centerY = 400, 300
    local offsets = {
        {dx = -200, dy = -120},
        {dx =  200, dy = -120},
        {dx = -200, dy =  120},
        {dx =  200, dy =  120},
    }

    local bases = {
        Constants.VFXType.PROJ_BASE,
        Constants.VFXType.BEAM_BASE,
        Constants.VFXType.BLAST_BASE,
        Constants.VFXType.REMOTE_BASE,
        Constants.VFXType.ZONE_BASE,
    }

    local ranges = {Constants.RangeState.NEAR, Constants.RangeState.FAR}
    local caModes = {false, true}

    for r = 1, #ranges do
        for c = 1, #caModes do
            for i = 1, #bases do
                local off = offsets[((i - 1) % #offsets) + 1]
                local sx = centerX + off.dx * 0.6
                local sy = centerY + off.dy * 0.6
                local tx = centerX + off.dx
                local ty = centerY + off.dy
                local event = {
                    type = "EFFECT",
                    attackType = (i == 2 and Constants.AttackType.REMOTE) or (i == 5 and Constants.AttackType.ZONE) or Constants.AttackType.PROJECTILE,
                    affinity = Constants.TokenType.FIRE,
                    manaCost = 3,
                    rangeBand = ranges[r]
                }
                local base, opts = VisualResolver.pick(event)
                opts.enableCA = caModes[c]
                opts.blockSize = opts.blockSize or 3
                VFX.createEffect(bases[i], sx, sy, tx, ty, opts)
            end
        end
    end
    print("[VFX SWEEP] Spawned base templates across range/CA modes")
end

-- Entry: run textual event test, then (optionally) a visual sweep when running in-game
local success = runTest()
print(string.format("\nTest %s!", success and "PASSED" or "FAILED"))

-- If running under Love with a window, schedule the sweep once
if love and love.timer and love.graphics then
    visualSweep()
end

return success
