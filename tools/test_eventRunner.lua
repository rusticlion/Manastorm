-- test_eventRunner.lua
-- Unit tests for the EventRunner system

local EventRunner = require("systems.EventRunner")

-- Create mock game objects for testing
local function createMockGameState()
    -- Create mock mana pool
    local manaPool = {
        tokens = {},
        addToken = function(self, tokenType, imagePath)
            table.insert(self.tokens, {
                type = tokenType,
                image = imagePath,
                state = "FREE",
                x = 0,
                y = 0
            })
        end
    }
    
    -- Add some initial tokens
    for i = 1, 5 do
        manaPool:addToken("fire", "assets/sprites/fire-token.png")
    end
    
    -- Create mock VFX system
    local vfx = {
        effects = {},
        createDamageNumber = function(x, y, amount, type)
            print("VFX: Creating damage number " .. amount .. " at " .. x .. "," .. y)
        end,
        createStatusEffect = function(target, statusType)
            print("VFX: Creating status effect " .. statusType .. " on " .. target.name)
        end,
        createElevationEffect = function(target, elevation)
            print("VFX: Creating elevation effect " .. elevation .. " on " .. target.name)
        end,
        createRangeChangeEffect = function(position)
            print("VFX: Creating range change effect to " .. position)
        end,
        createPositionForceEffect = function()
            print("VFX: Creating position force effect")
        end,
        createTokenLockEffect = function(token)
            print("VFX: Creating token lock effect for " .. token.type .. " token")
        end,
        createSpellDelayEffect = function(wizard, slotIndex)
            print("VFX: Creating spell delay effect on " .. wizard.name .. "'s slot " .. slotIndex)
        end,
        createSpellAccelerateEffect = function(wizard, slotIndex)
            print("VFX: Creating spell accelerate effect on " .. wizard.name .. "'s slot " .. slotIndex)
        end,
        createSpellCancelEffect = function(wizard, slotIndex, returnMana)
            print("VFX: Creating spell cancel effect on " .. wizard.name .. "'s slot " .. slotIndex .. " with mana " .. (returnMana and "returned" or "destroyed"))
        end,
        createSpellFreezeEffect = function(wizard, slotIndex)
            print("VFX: Creating spell freeze effect on " .. wizard.name .. "'s slot " .. slotIndex)
        end,
        createReflectEffect = function(target)
            print("VFX: Creating reflect effect on " .. target.name)
        end,
        createEchoEffect = function(wizard, slotIndex)
            print("VFX: Creating echo effect on " .. wizard.name .. "'s slot " .. slotIndex)
        end
    }
    
    -- Create mock game state
    local gameState = {
        rangeState = "FAR",
        vfx = vfx,
        wizards = {}
    }
    
    -- Create mock spell slot
    local createMockSpellSlot = function(active, spell)
        return {
            active = active,
            spell = spell,
            castTimeRemaining = 3.0,
            tokens = {},
            frozen = false,
            freezeTimer = 0,
            isShield = false
        }
    end
    
    -- Create mock wizard
    local createMockWizard = function(name, health, manaPool, gameState)
        local wizard = {
            name = name,
            health = health,
            elevation = "GROUNDED",
            manaPool = manaPool,
            gameState = gameState,
            statusEffects = {},
            spellSlots = {
                createMockSpellSlot(true, {id = "fireball", name = "Fireball"}),
                createMockSpellSlot(false, nil),
                createMockSpellSlot(true, {id = "iceblast", name = "Ice Blast"})
            },
            resetSpellSlot = function(self, slotIndex)
                self.spellSlots[slotIndex].active = false
                self.spellSlots[slotIndex].spell = nil
                self.spellSlots[slotIndex].castTimeRemaining = 0
                self.spellSlots[slotIndex].tokens = {}
                self.spellSlots[slotIndex].frozen = false
                self.spellSlots[slotIndex].freezeTimer = 0
                self.spellSlots[slotIndex].isShield = false
            end,
            createShield = function(self, slotIndex, shieldParams)
                print("Creating shield in slot " .. slotIndex .. " of type " .. shieldParams.defenseType)
                self.spellSlots[slotIndex].isShield = true
                self.spellSlots[slotIndex].defenseType = shieldParams.defenseType
                self.spellSlots[slotIndex].blocksAttackTypes = shieldParams.blocksAttackTypes
                self.spellSlots[slotIndex].reflect = shieldParams.reflect
                
                -- Mark tokens as shielding
                for _, tokenData in ipairs(self.spellSlots[slotIndex].tokens) do
                    if tokenData.token then
                        tokenData.token.state = "SHIELDING"
                    end
                end
            end,
            x = 100,
            y = 200
        }
        
        return wizard
    end
    
    -- Create mock caster and target
    local caster = createMockWizard("Wizard1", 100, manaPool, gameState)
    local target = createMockWizard("Wizard2", 100, manaPool, gameState)
    
    -- Add wizards to game state
    gameState.wizards = {caster, target}
    
    -- Add some tokens to spell slots for testing
    for i = 1, 3 do
        caster.spellSlots[1].tokens[i] = {
            token = {
                type = "fire",
                state = "CHANNELED",
                x = 0,
                y = 0
            }
        }
    end
    
    return {
        gameState = gameState,
        caster = caster,
        target = target,
        manaPool = manaPool
    }
end

-- Test functions
local tests = {}

-- Test damage event
function tests.testDamageEvent()
    print("\n=== Testing DAMAGE Event ===")
    local testState = createMockGameState()
    
    -- Create a damage event
    local events = {
        {
            type = "DAMAGE",
            source = "caster",
            target = "enemy",
            amount = 10,
            damageType = "fire"
        }
    }
    
    -- Initial health
    print("Target initial health: " .. testState.target.health)
    
    -- Process the event
    local results = EventRunner.processEvents(events, testState.caster, testState.target, 1)
    
    -- Check results
    print("Events processed: " .. results.eventsProcessed)
    print("Damage dealt: " .. results.damageDealt)
    print("Target health after: " .. testState.target.health)
    
    -- Verify damage was applied
    assert(testState.target.health == 90, "Target health should be 90 after 10 damage")
    assert(results.damageDealt == 10, "Results should show 10 damage dealt")
    
    print("DAMAGE event test passed")
end

-- Test status effect event
function tests.testStatusEffectEvent()
    print("\n=== Testing APPLY_STATUS Event ===")
    local testState = createMockGameState()
    
    -- Create a status effect event
    local events = {
        {
            type = "APPLY_STATUS",
            source = "caster",
            target = "enemy",
            statusType = "burn",
            duration = 3.0,
            tickDamage = 2,
            tickInterval = 1.0
        }
    }
    
    -- Process the event
    local results = EventRunner.processEvents(events, testState.caster, testState.target, 1)
    
    -- Check results
    print("Events processed: " .. results.eventsProcessed)
    print("Status effects applied: " .. #results.statusEffectsApplied)
    
    -- Check if status effect was applied
    assert(testState.target.statusEffects.burn, "Burn status effect should be applied")
    assert(testState.target.statusEffects.burn.duration == 3.0, "Burn duration should be 3.0")
    assert(testState.target.statusEffects.burn.tickDamage == 2, "Burn tick damage should be 2")
    
    print("APPLY_STATUS event test passed")
end

-- Test elevation event
function tests.testElevationEvent()
    print("\n=== Testing SET_ELEVATION Event ===")
    local testState = createMockGameState()
    
    -- Initial elevation
    print("Initial elevation: " .. testState.caster.elevation)
    
    -- Create an elevation event
    local events = {
        {
            type = "SET_ELEVATION",
            source = "caster",
            target = "self",
            elevation = "AERIAL",
            duration = 5.0
        }
    }
    
    -- Process the event
    local results = EventRunner.processEvents(events, testState.caster, testState.target, 1)
    
    -- Check results
    print("Events processed: " .. results.eventsProcessed)
    print("Elevation after: " .. testState.caster.elevation)
    
    -- Check if elevation was changed
    assert(testState.caster.elevation == "AERIAL", "Caster elevation should be AERIAL")
    assert(testState.caster.elevationEffects.AERIAL.duration == 5.0, "Elevation effect duration should be 5.0")
    
    print("SET_ELEVATION event test passed")
end

-- Test range event
function tests.testRangeEvent()
    print("\n=== Testing SET_RANGE Event ===")
    local testState = createMockGameState()
    
    -- Initial range
    print("Initial range: " .. testState.gameState.rangeState)
    
    -- Create a range event
    local events = {
        {
            type = "SET_RANGE",
            source = "caster",
            target = "both",
            position = "NEAR"
        }
    }
    
    -- Process the event
    local results = EventRunner.processEvents(events, testState.caster, testState.target, 1)
    
    -- Check results
    print("Events processed: " .. results.eventsProcessed)
    print("Range after: " .. testState.gameState.rangeState)
    
    -- Check if range was changed
    assert(testState.gameState.rangeState == "NEAR", "Game state range should be NEAR")
    
    print("SET_RANGE event test passed")
end

-- Test token creation event
function tests.testConjureTokenEvent()
    print("\n=== Testing CONJURE_TOKEN Event ===")
    local testState = createMockGameState()
    
    -- Initial token count
    local initialTokenCount = #testState.manaPool.tokens
    print("Initial token count: " .. initialTokenCount)
    
    -- Create a conjure token event
    local events = {
        {
            type = "CONJURE_TOKEN",
            source = "caster",
            target = "pool",
            tokenType = "fire",
            amount = 3
        }
    }
    
    -- Process the event
    local results = EventRunner.processEvents(events, testState.caster, testState.target, 1)
    
    -- Check results
    print("Events processed: " .. results.eventsProcessed)
    print("Tokens affected: " .. results.tokensAffected)
    print("Token count after: " .. #testState.manaPool.tokens)
    
    -- Check if tokens were added
    assert(#testState.manaPool.tokens == initialTokenCount + 3, "Should have 3 more tokens")
    assert(results.tokensAffected == 3, "Results should show 3 tokens affected")
    
    print("CONJURE_TOKEN event test passed")
end

-- Test shield creation event
function tests.testCreateShieldEvent()
    print("\n=== Testing CREATE_SHIELD Event ===")
    local testState = createMockGameState()
    
    -- Create a shield event
    local events = {
        {
            type = "CREATE_SHIELD",
            source = "caster",
            target = "self_slot",
            slotIndex = 1,
            defenseType = "barrier",
            blocksAttackTypes = {"projectile", "zone"},
            reflect = false
        }
    }
    
    -- Process the event
    local results = EventRunner.processEvents(events, testState.caster, testState.target, 1)
    
    -- Check results
    print("Events processed: " .. results.eventsProcessed)
    print("Shield created: " .. tostring(results.shieldCreated))
    
    -- Check if shield was created
    assert(testState.caster.spellSlots[1].isShield, "Slot 1 should now be a shield")
    assert(testState.caster.spellSlots[1].defenseType == "barrier", "Shield should be a barrier")
    
    print("CREATE_SHIELD event test passed")
end

-- Test spell cancel event
function tests.testCancelSpellEvent()
    print("\n=== Testing CANCEL_SPELL Event ===")
    local testState = createMockGameState()
    
    -- Initial state
    print("Target slot 1 active: " .. tostring(testState.target.spellSlots[1].active))
    
    -- Create a cancel spell event
    local events = {
        {
            type = "CANCEL_SPELL",
            source = "caster",
            target = "enemy_slot",
            slotIndex = 1,
            returnMana = true
        }
    }
    
    -- Process the event
    local results = EventRunner.processEvents(events, testState.caster, testState.target, 1)
    
    -- Check results
    print("Events processed: " .. results.eventsProcessed)
    print("Target slot 1 active after: " .. tostring(testState.target.spellSlots[1].active))
    
    -- Check if spell was canceled
    assert(not testState.target.spellSlots[1].active, "Target slot 1 should be inactive")
    
    print("CANCEL_SPELL event test passed")
end

-- Test compatibility with old results format
function tests.testCompatibilityWithOldResults()
    print("\n=== Testing Compatibility with Old Results Format ===")
    
    -- Create an old-style results table
    local oldResults = {
        damage = 15,
        damageType = "fire",
        burnApplied = true,
        burnDuration = 4.0,
        burnTickDamage = 3,
        burnTickInterval = 1.0
    }
    
    -- Generate events from old results
    local events = EventRunner.generateEventsFromResults(oldResults, nil, nil, 1)
    
    -- Debug print the events
    EventRunner.debugPrintEvents(events)
    
    -- Verify events were generated correctly
    assert(#events == 2, "Should have generated 2 events")
    assert(events[1].type == "DAMAGE", "First event should be DAMAGE")
    assert(events[1].amount == 15, "Damage amount should be 15")
    assert(events[2].type == "APPLY_STATUS", "Second event should be APPLY_STATUS")
    assert(events[2].statusType == "burn", "Status type should be burn")
    
    print("Old results compatibility test passed")
end

-- Run all tests
function runAllTests()
    print("===== EventRunner Test Suite =====")
    local passCount = 0
    local failCount = 0
    
    for name, testFunc in pairs(tests) do
        local success, error = pcall(testFunc)
        if success then
            passCount = passCount + 1
        else
            failCount = failCount + 1
            print("TEST FAILED: " .. name)
            print(error)
        end
    end
    
    print("\n===== Test Results =====")
    print("Tests passed: " .. passCount)
    print("Tests failed: " .. failCount)
    print("======================")
end

-- Run the tests
runAllTests()