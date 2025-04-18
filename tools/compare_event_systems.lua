-- compare_event_systems.lua
-- Compares the legacy direct-execution system to the new event-based system

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local EventRunner = require("systems.EventRunner")

-- Create test wizard objects
local function createTestEnvironment()
    -- Create mana pool for testing
    local manaPool = {
        tokens = {},
        addToken = function(self, tokenType, imagePath)
            local token = {
                type = tokenType,
                image = imagePath or "assets/sprites/" .. tokenType .. "-token.png",
                state = "FREE",
                x = 400 + math.random(-50, 50),
                y = 300 + math.random(-50, 50),
                angle = math.random() * math.pi * 2,
                scale = 1.0,
                alpha = 1.0,
                vx = 0,
                vy = 0,
                rotSpeed = 0
            }
            table.insert(self.tokens, token)
            return token
        end
    }
    
    -- Add some tokens to the pool
    for i = 1, 3 do
        manaPool:addToken("fire")
        manaPool:addToken("force")
        manaPool:addToken("moon")
    end
    
    -- Create mock game state
    local vfx = {
        createEffect = function() end,
        createDamageNumber = function() end
    }
    
    local gameState = {
        rangeState = "FAR",
        vfx = vfx,
        wizards = {}
    }
    
    -- Create mock spell slots
    local function createSpellSlots()
        local slots = {}
        for i = 1, 3 do
            slots[i] = {
                index = i,
                active = false,
                spell = nil,
                castProgress = 0,
                castTimeRemaining = 0,
                tokens = {},
                frozen = false,
                freezeTimer = 0,
                isShield = false,
                x = 0,
                y = 0
            }
        end
        return slots
    end
    
    -- Create wizards
    local caster = {
        name = "TestCaster",
        health = 100,
        elevation = "GROUNDED",
        manaPool = manaPool,
        gameState = gameState,
        statusEffects = {},
        spellSlots = createSpellSlots(),
        createShield = function(self, slotIndex, shieldParams)
            print("Creating shield in slot " .. slotIndex .. " of type " .. shieldParams.defenseType)
            self.spellSlots[slotIndex].isShield = true
            self.spellSlots[slotIndex].defenseType = shieldParams.defenseType
            self.spellSlots[slotIndex].blocksAttackTypes = shieldParams.blocksAttackTypes
            self.spellSlots[slotIndex].reflect = shieldParams.reflect
        end,
        resetSpellSlot = function(self, slotIndex)
            self.spellSlots[slotIndex].active = false
            self.spellSlots[slotIndex].spell = nil
            self.spellSlots[slotIndex].castProgress = 0
            self.spellSlots[slotIndex].castTimeRemaining = 0
            self.spellSlots[slotIndex].tokens = {}
            self.spellSlots[slotIndex].frozen = false
            self.spellSlots[slotIndex].freezeTimer = 0
            self.spellSlots[slotIndex].isShield = false
        end,
        x = 200,
        y = 300
    }
    
    local target = {
        name = "TestTarget",
        health = 100,
        elevation = "GROUNDED",
        manaPool = manaPool,
        gameState = gameState,
        statusEffects = {},
        spellSlots = createSpellSlots(),
        createShield = function(self, slotIndex, shieldParams)
            print("Creating shield in slot " .. slotIndex .. " of type " .. shieldParams.defenseType)
            self.spellSlots[slotIndex].isShield = true
            self.spellSlots[slotIndex].defenseType = shieldParams.defenseType
            self.spellSlots[slotIndex].blocksAttackTypes = shieldParams.blocksAttackTypes
            self.spellSlots[slotIndex].reflect = shieldParams.reflect
        end,
        resetSpellSlot = function(self, slotIndex)
            self.spellSlots[slotIndex].active = false
            self.spellSlots[slotIndex].spell = nil
            self.spellSlots[slotIndex].castProgress = 0
            self.spellSlots[slotIndex].castTimeRemaining = 0
            self.spellSlots[slotIndex].tokens = {}
            self.spellSlots[slotIndex].frozen = false
            self.spellSlots[slotIndex].freezeTimer = 0
            self.spellSlots[slotIndex].isShield = false
        end,
        x = 600,
        y = 300
    }
    
    -- Add wizards to game state
    gameState.wizards = {caster, target}
    
    -- Prepare the first spell slot for testing
    caster.spellSlots[1].active = true
    
    -- Add some tokens to the slots
    for i = 1, 2 do
        table.insert(caster.spellSlots[1].tokens, {
            token = {
                type = "fire",
                state = "CHANNELED"
            }
        })
    end
    
    return {
        caster = caster,
        target = target,
        manaPool = manaPool,
        gameState = gameState
    }
end

-- Test spell definitions (simple but representative examples)
local testSpells = {
    -- 1. Fireball - damage spell
    fireball = {
        id = "fireball",
        name = "Fireball",
        description = "A ball of fire that deals damage",
        attackType = "projectile",
        castTime = 3.0,
        cost = {"fire", "fire"},
        keywords = {
            damage = {
                amount = 15,
                type = "fire"
            }
        }
    },
    
    -- 2. Barrier Shield - defensive spell
    barrierShield = {
        id = "barrier_shield",
        name = "Barrier Shield",
        description = "Creates a barrier shield",
        attackType = "utility",
        castTime = 4.0,
        cost = {"force", "force"},
        keywords = {
            block = {
                type = "barrier",
                blocks = {"projectile"}
            }
        }
    },
    
    -- 3. Conjure - resource spell
    conjureFlame = {
        id = "conjure_flame",
        name = "Conjure Flame",
        description = "Creates fire mana tokens",
        attackType = "utility",
        castTime = 5.0,
        cost = {"moon"},
        keywords = {
            conjure = {
                token = "fire",
                amount = 2
            }
        }
    }
}

-- Run a comparison test for a spell
local function runComparisonTest(spellId)
    local spellDef = testSpells[spellId]
    if not spellDef then
        print("Error: Spell ID " .. spellId .. " not found")
        return
    end
    
    print("\n=============================================")
    print("COMPARING EXECUTION MODES FOR: " .. spellDef.name)
    print("=============================================\n")
    
    -- Compile the spell
    local compiledSpell = SpellCompiler.compileSpell(spellDef, Keywords)
    
    -- Test with legacy system
    print("--- LEGACY DIRECT EXECUTION ---")
    local legacyEnv = createTestEnvironment()
    SpellCompiler.setUseEventSystem(false)
    local legacyResults = compiledSpell.executeAll(legacyEnv.caster, legacyEnv.target, {}, 1)
    
    -- Test with event system
    print("\n--- EVENT-BASED EXECUTION ---")
    local eventEnv = createTestEnvironment()
    SpellCompiler.setUseEventSystem(true)
    SpellCompiler.setDebugEvents(true)
    local eventResults = compiledSpell.executeAll(eventEnv.caster, eventEnv.target, {}, 1)
    
    -- Compare the results
    print("\n--- COMPARISON OF RESULTS ---")
    
    -- Compare game state changes
    if spellId == "fireball" then
        print("Target Health:")
        print("  Legacy: " .. legacyEnv.target.health)
        print("  Event:  " .. eventEnv.target.health)
    elseif spellId == "barrier_shield" then
        print("Shield Created:")
        print("  Legacy: " .. tostring(legacyEnv.caster.spellSlots[1].isShield))
        print("  Event:  " .. tostring(eventEnv.caster.spellSlots[1].isShield))
    elseif spellId == "conjure_flame" then
        local legacyFireCount = 0
        local eventFireCount = 0
        
        for _, token in ipairs(legacyEnv.manaPool.tokens) do
            if token.type == "fire" then legacyFireCount = legacyFireCount + 1 end
        end
        
        for _, token in ipairs(eventEnv.manaPool.tokens) do
            if token.type == "fire" then eventFireCount = eventFireCount + 1 end
        end
        
        print("Fire Tokens in Pool:")
        print("  Legacy: " .. legacyFireCount)
        print("  Event:  " .. eventFireCount)
    end
    
    -- Compare result tables
    print("\nResults Table Keys:")
    print("  Legacy: ")
    for k, _ in pairs(legacyResults) do
        print("    - " .. k)
    end
    
    print("  Event:  ")
    for k, _ in pairs(eventResults) do
        print("    - " .. k)
    end
    
    -- Show events if available
    if eventResults.events then
        print("\nEvents Generated:")
        print("  Count: " .. #eventResults.events)
        print("  Types: ")
        local eventTypes = {}
        for _, event in ipairs(eventResults.events) do
            eventTypes[event.type] = (eventTypes[event.type] or 0) + 1
        end
        
        for eventType, count in pairs(eventTypes) do
            print("    - " .. eventType .. ": " .. count)
        end
    end
    
    print("\n=============================================")
end

-- Parse command line argument to determine which test to run
local arg = arg or {}
local testId = arg[1] or "all"

if testId == "all" then
    -- Run all comparison tests
    for id, _ in pairs(testSpells) do
        runComparisonTest(id)
    end
else
    -- Run a specific test
    runComparisonTest(testId)
end