-- system_test_event_integration.lua
-- System test for validating the integration of the event system
-- This script simulates a sequence of spells to ensure everything works correctly

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local EventRunner = require("systems.EventRunner")

print("===== MANASTORM EVENT SYSTEM INTEGRATION TEST =====")

-- Create a full game simulation environment
local function createGameEnvironment()
    -- Create mana pool
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
    
    -- Add initial tokens to the pool
    for i = 1, 5 do
        manaPool:addToken("fire")
        manaPool:addToken("force")
        manaPool:addToken("moon")
        manaPool:addToken("nature")
        manaPool:addToken("star")
    end
    
    -- Create VFX system stub
    local vfx = {
        effects = {},
        createEffect = function(self, effectType, x, y, targetX, targetY, params)
            print("VFX: Creating " .. effectType .. " effect")
            table.insert(self.effects, {
                type = effectType,
                x = x,
                y = y,
                targetX = targetX,
                targetY = targetY,
                params = params
            })
        end,
        createDamageNumber = function(self, x, y, amount, damageType)
            print("VFX: Creating damage number " .. amount .. " of type " .. (damageType or "generic"))
        end,
        update = function(self, dt)
            -- Simulate updating effects
            for i = #self.effects, 1, -1 do
                self.effects[i].timer = (self.effects[i].timer or 1.0) - dt
                if self.effects[i].timer <= 0 then
                    table.remove(self.effects, i)
                end
            end
        end
    }
    
    -- Create game state
    local gameState = {
        rangeState = "FAR",
        vfx = vfx,
        wizards = {},
        
        -- Simulated game loop time tracking
        time = 0,
        update = function(self, dt)
            self.time = self.time + dt
            
            -- Update VFX
            self.vfx:update(dt)
            
            -- Update wizards
            for _, wizard in ipairs(self.wizards) do
                wizard:update(dt)
            end
        end
    }
    
    -- Create a wizard object
    local function createWizard(name, x, y, color)
        local wizard = {
            name = name,
            health = 100,
            maxHealth = 100,
            elevation = "GROUNDED",
            manaPool = manaPool,
            gameState = gameState,
            statusEffects = {},
            reflectActive = false,
            reflectDuration = 0,
            spellSlots = {},
            echoQueue = {},
            x = x,
            y = y,
            color = color,
            
            -- Initialize spell slots
            initializeSpellSlots = function(self)
                for i = 1, 3 do
                    self.spellSlots[i] = {
                        index = i,
                        active = false,
                        spell = nil,
                        castProgress = 0,
                        castTimeRemaining = 0,
                        tokens = {},
                        frozen = false,
                        freezeTimer = 0,
                        isShield = false,
                        x = self.x + (i - 2) * 50,
                        y = self.y - 40,
                        willBecomeShield = false
                    }
                end
            end,
            
            -- Reset a spell slot
            resetSpellSlot = function(self, slotIndex)
                local slot = self.spellSlots[slotIndex]
                if not slot then return end
                
                -- Return tokens to pool if not a shield
                if not slot.isShield then
                    for _, tokenData in ipairs(slot.tokens) do
                        if tokenData.token then
                            tokenData.token.state = "FREE"
                        end
                    end
                end
                
                -- Reset the slot
                slot.active = false
                slot.spell = nil
                slot.castProgress = 0
                slot.castTimeRemaining = 0
                slot.tokens = {}
                slot.frozen = false
                slot.freezeTimer = 0
                slot.isShield = false
                slot.willBecomeShield = false
            end,
            
            -- Queue a spell in a slot
            queueSpell = function(self, spellId, slotIndex)
                -- Check if the slot is available
                if self.spellSlots[slotIndex].active then
                    print(self.name .. " slot " .. slotIndex .. " is already active")
                    return false
                end
                
                -- Get the spell definition
                local spellDef = testSpells[spellId]
                if not spellDef then
                    print("Unknown spell: " .. spellId)
                    return false
                end
                
                -- Compile the spell if needed
                local compiledSpell = SpellCompiler.compileSpell(spellDef, Keywords)
                
                -- Queue the spell
                local slot = self.spellSlots[slotIndex]
                slot.active = true
                slot.spell = compiledSpell
                slot.castProgress = 0
                slot.castTimeRemaining = compiledSpell.castTime
                slot.willBecomeShield = compiledSpell.isShield or (compiledSpell.behavior and compiledSpell.behavior.block ~= nil)
                
                -- Add tokens
                for i, tokenType in ipairs(compiledSpell.cost) do
                    -- Find a token of the right type (or any type if 'any')
                    local token = nil
                    for _, t in ipairs(manaPool.tokens) do
                        if t.state == "FREE" and (tokenType == "any" or t.type == tokenType) then
                            token = t
                            break
                        end
                    end
                    
                    if token then
                        -- Add token to the slot
                        token.state = "CHANNELED"
                        table.insert(slot.tokens, {
                            token = token,
                            angle = (i - 1) * (2 * math.pi / #compiledSpell.cost)
                        })
                    else
                        print("Not enough tokens for spell!")
                        -- Reset the slot on failure
                        self:resetSpellSlot(slotIndex)
                        return false
                    end
                end
                
                print(self.name .. " queued " .. spellDef.name .. " in slot " .. slotIndex)
                return true
            end,
            
            -- Cast a spell from a slot
            castSpell = function(self, slotIndex)
                local slot = self.spellSlots[slotIndex]
                if not slot or not slot.active or not slot.spell then 
                    print(self.name .. ": No active spell in slot " .. slotIndex)
                    return 
                end
                
                print(self.name .. " cast " .. slot.spell.name .. " from slot " .. slotIndex)
                
                -- Get the opponent wizard
                local target = nil
                for _, w in ipairs(gameState.wizards) do
                    if w ~= self then
                        target = w
                        break
                    end
                end
                
                if not target then
                    print("No target found")
                    return
                end
                
                -- Execute the spell
                local spellToUse = slot.spell
                local attackType = spellToUse.attackType or "projectile"
                
                -- Execute spell behavior using the event system
                print("Executing spell via event system...")
                local effect = spellToUse.executeAll(self, target, {}, slotIndex)
                
                -- Print results summary
                if effect.events then
                    print("Events generated: " .. #effect.events)
                    print("Events processed: " .. (effect.eventsProcessed or 0))
                end
                
                if effect.damageDealt then
                    print("Damage dealt: " .. effect.damageDealt)
                end
                
                -- Reset the slot unless it became a shield
                if not (effect.isShield or slot.isShield) then
                    self:resetSpellSlot(slotIndex)
                end
                
                return effect
            end,
            
            -- Create a shield
            createShield = function(self, slotIndex, shieldParams)
                print(self.name .. " creating shield in slot " .. slotIndex)
                local slot = self.spellSlots[slotIndex]
                if not slot then return end
                
                -- Set shield properties
                slot.isShield = true
                slot.defenseType = shieldParams.defenseType
                slot.blocksAttackTypes = shieldParams.blocksAttackTypes
                slot.reflect = shieldParams.reflect
                
                -- Mark tokens as shielding
                for _, tokenData in ipairs(slot.tokens) do
                    if tokenData.token then
                        tokenData.token.state = "SHIELDING"
                    end
                end
                
                -- Create shield visual effect
                local shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Yellow for barriers
                if shieldParams.defenseType == "ward" then
                    shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
                elseif shieldParams.defenseType == "field" then
                    shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
                end
                
                gameState.vfx:createEffect("shield", self.x, self.y, nil, nil, {
                    duration = 1.0,
                    color = shieldColor,
                    shieldType = shieldParams.defenseType
                })
            end,
            
            -- Update wizard state
            update = function(self, dt)
                -- Update status effects
                for statusType, effect in pairs(self.statusEffects) do
                    -- Update duration
                    effect.duration = effect.duration - dt
                    
                    -- Process DoT effects
                    if effect.tickDamage and effect.tickInterval then
                        effect.tickTimer = (effect.tickTimer or 0) + dt
                        
                        if effect.tickTimer >= effect.tickInterval then
                            -- Apply damage tick
                            self.health = math.max(0, self.health - effect.tickDamage)
                            print(string.format("%s took %d %s tick damage (health: %d)",
                                self.name, effect.tickDamage, statusType, self.health))
                            
                            -- Reset tick timer
                            effect.tickTimer = effect.tickTimer - effect.tickInterval
                            
                            -- Create damage number
                            gameState.vfx:createDamageNumber(self.x, self.y, effect.tickDamage, "dot")
                        end
                    end
                    
                    -- Remove expired effects
                    if effect.duration <= 0 then
                        print(self.name .. "'s " .. statusType .. " effect expired")
                        self.statusEffects[statusType] = nil
                    end
                end
                
                -- Update reflect status
                if self.reflectActive then
                    self.reflectDuration = self.reflectDuration - dt
                    if self.reflectDuration <= 0 then
                        self.reflectActive = false
                        print(self.name .. "'s reflect effect expired")
                    end
                end
                
                -- Update spell slots
                for i, slot in ipairs(self.spellSlots) do
                    if slot.active and not slot.isShield and not slot.frozen then
                        -- Progress the cast
                        slot.castTimeRemaining = slot.castTimeRemaining - dt
                        slot.castProgress = 1 - (slot.castTimeRemaining / slot.spell.castTime)
                        
                        -- Check if the spell is ready to cast
                        if slot.castTimeRemaining <= 0 then
                            print(self.name .. "'s spell in slot " .. i .. " is ready to cast")
                            self:castSpell(i)
                        end
                    end
                    
                    -- Update frozen timer
                    if slot.frozen then
                        slot.freezeTimer = slot.freezeTimer - dt
                        if slot.freezeTimer <= 0 then
                            slot.frozen = false
                            print(self.name .. "'s spell in slot " .. i .. " is unfrozen")
                        end
                    end
                end
                
                -- Update echo queue
                for i = #self.echoQueue, 1, -1 do
                    local echo = self.echoQueue[i]
                    echo.timer = echo.timer - dt
                    
                    if echo.timer <= 0 then
                        print(self.name .. " activating echo for " .. echo.spell.name)
                        
                        -- Find an available slot
                        local availableSlot = nil
                        for j = 1, #self.spellSlots do
                            if not self.spellSlots[j].active then
                                availableSlot = j
                                break
                            end
                        end
                        
                        if availableSlot then
                            -- Queue the echoed spell
                            local slot = self.spellSlots[availableSlot]
                            slot.active = true
                            slot.spell = echo.spell
                            slot.castProgress = 1.0  -- Immediately ready to cast
                            slot.castTimeRemaining = 0
                            
                            -- Cast it immediately
                            self:castSpell(availableSlot)
                        else
                            print(self.name .. " has no available slot for echo")
                        end
                        
                        -- Remove the echo
                        table.remove(self.echoQueue, i)
                    end
                end
            end
        }
        
        -- Initialize spell slots
        wizard:initializeSpellSlots()
        
        return wizard
    end
    
    -- Create wizards
    local wizard1 = createWizard("Ashgar", 200, 300, {255, 120, 50})
    local wizard2 = createWizard("Selene", 600, 300, {50, 120, 255})
    
    -- Add wizards to game state
    gameState.wizards = {wizard1, wizard2}
    
    return {
        wizard1 = wizard1,
        wizard2 = wizard2,
        gameState = gameState,
        manaPool = manaPool
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
        castTime = 3.0,
        cost = {"fire", "fire"},
        keywords = {
            damage = {
                amount = 12,
                type = "fire"
            },
            burn = {
                duration = 3.0,
                tickDamage = 2,
                tickInterval = 1.0
            }
        }
    },
    
    -- 2. Barrier Shield - defense spell
    barrier = {
        id = "barrier",
        name = "Barrier Shield",
        description = "Creates a barrier that blocks projectiles",
        attackType = "utility",
        castTime = 2.0,
        cost = {"force", "force"},
        keywords = {
            block = {
                type = "barrier",
                blocks = {"projectile", "zone"}
            }
        }
    },
    
    -- 3. Flame Burst - multi-effect spell
    flameBurst = {
        id = "flame_burst",
        name = "Flame Burst",
        description = "Damages enemy and conjures new fire tokens",
        attackType = "remote",
        castTime = 4.0,
        cost = {"fire", "moon"},
        keywords = {
            damage = {
                amount = 8,
                type = "fire"
            },
            conjure = {
                token = "fire",
                amount = 1
            }
        }
    },
    
    -- 4. Aerial Shift - movement/positioning spell
    aerialShift = {
        id = "aerial_shift",
        name = "Aerial Shift",
        description = "Elevates caster and shifts range",
        attackType = "utility",
        castTime = 2.5,
        cost = {"force"},
        keywords = {
            elevate = {
                duration = 4.0
            },
            rangeShift = {
                position = "FAR"
            }
        }
    },
    
    -- 5. Time Echo - spell recast effect
    timeEcho = {
        id = "time_echo",
        name = "Time Echo",
        description = "Recasts this spell after a delay",
        attackType = "utility",
        castTime = 3.0,
        cost = {"moon", "star"},
        keywords = {
            damage = {
                amount = 5,
                type = "force"
            },
            echo = {
                delay = 2.0
            }
        }
    }
}

-- Run a simulation of multiple spells being cast
function runSpellSimulation()
    print("\n----- STARTING SPELL SIMULATION -----")
    
    -- Create game environment
    local env = createGameEnvironment()
    local wizard1 = env.wizard1
    local wizard2 = env.wizard2
    local gameState = env.gameState
    
    -- Enable event system and debugging
    SpellCompiler.setUseEventSystem(true)
    SpellCompiler.setDebugEvents(true)
    
    -- Helper function to print game state
    local function printGameState()
        print("\n=== GAME STATE ===")
        print("Time: " .. string.format("%.1f", gameState.time))
        print("Range: " .. gameState.rangeState)
        print("Wizards:")
        for _, wizard in ipairs(gameState.wizards) do
            print(string.format("- %s: Health=%d, Elevation=%s", 
                wizard.name, wizard.health, wizard.elevation))
            
            local statusEffects = ""
            for effect, _ in pairs(wizard.statusEffects) do
                statusEffects = statusEffects .. effect .. " "
            end
            
            if statusEffects ~= "" then
                print("  Status Effects: " .. statusEffects)
            end
            
            for i, slot in ipairs(wizard.spellSlots) do
                if slot.active then
                    if slot.isShield then
                        print(string.format("  Slot %d: SHIELD (%s) with %d tokens", 
                            i, slot.defenseType, #slot.tokens))
                    else
                        print(string.format("  Slot %d: %s - %.0f%% ready", 
                            i, slot.spell.name, slot.castProgress * 100))
                    end
                else
                    print("  Slot " .. i .. ": Empty")
                end
            end
        end
        
        -- Count token types
        local tokenCounts = {}
        for _, token in ipairs(env.manaPool.tokens) do
            tokenCounts[token.type] = (tokenCounts[token.type] or 0) + 1
        end
        
        print("Mana Pool:")
        for tokenType, count in pairs(tokenCounts) do
            print("  " .. tokenType .. ": " .. count)
        end
        print("==================")
    end
    
    -- Set up initial spells
    print("\n[Time 0.0] Setting up initial spells...")
    wizard1:queueSpell("fireball", 1)
    wizard2:queueSpell("barrier", 2)
    
    -- Simulation step 1: Initial update
    print("\n[Time 0.0] Initial state:")
    printGameState()
    
    -- Update for 2 seconds - barrier should complete
    gameState:update(2.0)
    print("\n[Time 2.0] After 2 seconds (barrier should complete):")
    printGameState()
    
    -- Update for 1 more second - fireball should complete
    gameState:update(1.0)
    print("\n[Time 3.0] After 1 more second (fireball should complete):")
    printGameState()
    
    -- Queue new spells
    print("\n[Time 3.0] Queuing new spells...")
    wizard1:queueSpell("flameBurst", 2)
    wizard2:queueSpell("aerialShift", 1)
    
    -- Update for 2.5 seconds - aerial shift should complete
    gameState:update(2.5)
    print("\n[Time 5.5] After 2.5 seconds (aerial shift should complete):")
    printGameState()
    
    -- Update for 1.5 more seconds - flame burst should complete
    gameState:update(1.5)
    print("\n[Time 7.0] After 1.5 more seconds (flame burst should complete):")
    printGameState()
    
    -- Queue time echo spell
    print("\n[Time 7.0] Queuing time echo spell...")
    wizard1:queueSpell("timeEcho", 3)
    
    -- Update for 3 seconds - time echo should complete
    gameState:update(3.0)
    print("\n[Time 10.0] After 3 seconds (time echo should complete):")
    printGameState()
    
    -- Update for 2 more seconds - echo should trigger
    gameState:update(2.0)
    print("\n[Time 12.0] After 2 more seconds (echo should trigger):")
    printGameState()
    
    -- Update for 2 more seconds - finish simulation
    gameState:update(2.0)
    print("\n[Time 14.0] Final state:")
    printGameState()
    
    print("\n----- SPELL SIMULATION COMPLETE -----")
    print("Simulation ran for " .. gameState.time .. " seconds")
    print("Final health: " .. wizard1.name .. "=" .. wizard1.health .. ", " .. wizard2.name .. "=" .. wizard2.health)
end

-- Run the simulation
runSpellSimulation()