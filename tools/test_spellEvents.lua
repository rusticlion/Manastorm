-- test_spellEvents.lua
-- Tests the event-based spell execution for common spells

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local EventRunner = require("systems.EventRunner")

-- Create test wizard objects
local function createTestWizards()
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
    for i = 1, 10 do
        local tokenTypes = {"fire", "force", "moon", "nature", "star"}
        local tokenType = tokenTypes[math.random(#tokenTypes)]
        manaPool:addToken(tokenType)
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
    for i = 1, 3 do
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

-- Test spell definitions
local testSpells = {
    -- 1. Fireball - basic damage + DoT spell
    fireball = {
        id = "fireball",
        name = "Fireball",
        description = "A ball of fire that deals damage and burns the target",
        attackType = "projectile",
        castTime = 5.0,
        cost = {"fire", "fire"},
        keywords = {
            damage = {
                amount = 10,
                type = "fire"
            },
            burn = {
                duration = 3.0,
                tickDamage = 2,
                tickInterval = 1.0
            }
        },
        vfx = "fireball_vfx",
        blockableBy = {"barrier", "ward"}
    },
    
    -- 2. Barrier Shield - defense spell
    barrierShield = {
        id = "barrier_shield",
        name = "Barrier Shield",
        description = "Creates a physical barrier that blocks projectiles",
        attackType = "utility",
        castTime = 4.0,
        cost = {"force", "force", "any"},
        keywords = {
            block = {
                type = "barrier",
                blocks = {"projectile", "zone"}
            }
        },
        vfx = "barrier_vfx"
    },
    
    -- 3. Mana Surge - resource spell
    manaSurge = {
        id = "mana_surge",
        name = "Mana Surge",
        description = "Conjures new mana tokens and shifts others",
        attackType = "utility",
        castTime = 3.0,
        cost = {"moon"},
        keywords = {
            conjure = {
                token = "fire",
                amount = 2
            },
            tokenShift = {
                type = "force",
                amount = 1
            }
        },
        vfx = "surge_vfx"
    },
    
    -- 4. Time Warp - spell slot manipulation
    timeWarp = {
        id = "time_warp",
        name = "Time Warp",
        description = "Accelerates own spells and delays enemy spells",
        attackType = "remote",
        castTime = 6.0,
        cost = {"star", "moon"},
        keywords = {
            accelerate = {
                slot = 3,
                amount = 2.0
            },
            delay = {
                slot = 1,
                duration = 2.0
            }
        },
        vfx = "warp_vfx",
        blockableBy = {"ward", "field"}
    },
    
    -- 5. Aerial Repositioning - movement spell
    aerialReposition = {
        id = "aerial_reposition",
        name = "Aerial Repositioning",
        description = "Elevates caster and changes range",
        attackType = "utility",
        castTime = 2.0,
        cost = {"force"},
        keywords = {
            elevate = {
                duration = 5.0,
                vfx = "wind_lift"
            },
            rangeShift = {
                position = "FAR"
            }
        },
        vfx = "reposition_vfx"
    }
}

-- Test function for a specific spell
local function testSpell(spellId, spellDef)
    print("\n=== Testing Spell: " .. spellDef.name .. " ===")
    
    -- Create clean test state
    local testState = createTestWizards()
    
    -- Compile the spell
    local compiledSpell = SpellCompiler.compileSpell(spellDef, Keywords)
    
    -- Generate events without executing (for inspection)
    local events = compiledSpell.generateEvents(testState.caster, testState.target, 1)
    
    -- Debug print the events
    print("\nEvents generated by spell:")
    EventRunner.debugPrintEvents(events)
    
    -- Execute the spell with event system
    print("\nExecuting spell...")
    local results = compiledSpell.executeAll(testState.caster, testState.target, {}, 1)
    
    -- Show key state changes
    print("\nSpell execution results:")
    print("Events processed: " .. (results.eventsProcessed or "unknown"))
    
    -- Print specific effects based on spell type
    if spellId == "fireball" then
        print("Target health: " .. testState.target.health)
        print("Burn status applied: " .. tostring(testState.target.statusEffects.burn ~= nil))
    elseif spellId == "barrier_shield" then
        print("Shield created in slot 1: " .. tostring(testState.caster.spellSlots[1].isShield))
        if testState.caster.spellSlots[1].isShield then
            print("Shield type: " .. testState.caster.spellSlots[1].defenseType)
        end
    elseif spellId == "mana_surge" then
        local fireCount = 0
        local forceCount = 0
        for _, token in ipairs(testState.manaPool.tokens) do
            if token.type == "fire" then fireCount = fireCount + 1 end
            if token.type == "force" then forceCount = forceCount + 1 end
        end
        print("Fire tokens in pool: " .. fireCount)
        print("Force tokens in pool: " .. forceCount)
    elseif spellId == "time_warp" then
        print("Target slot 1 cast time: " .. testState.target.spellSlots[1].castTimeRemaining)
        print("Caster slot 3 active: " .. tostring(testState.caster.spellSlots[3].active))
    elseif spellId == "aerial_reposition" then
        print("Caster elevation: " .. testState.caster.elevation)
        print("Game range state: " .. testState.gameState.rangeState)
    end
    
    print("=== Spell Test Complete ===")
end

-- Run all spell tests
local function runAllSpellTests()
    print("===== EVENT-BASED SPELL EXECUTION TEST SUITE =====")
    
    for spellId, spellDef in pairs(testSpells) do
        testSpell(spellId, spellDef)
    end
    
    print("\n===== ALL SPELL TESTS COMPLETED =====")
end

-- Run the tests
runAllSpellTests()