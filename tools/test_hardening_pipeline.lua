-- tools/test_hardening_pipeline.lua
-- Focused regression checks for combat pipeline hardening.

local Constants = require("core.Constants")
local SpellCompiler = require("spellCompiler")
local Keywords = require("keywords")
local FireSpells = require("spells/elements/fire")
local MoonSpells = require("spells/elements/moon")
local SunSpells = require("spells/elements/sun")
local ShieldSystem = require("systems.ShieldSystem")

local passed = 0
local failed = 0

local function runTest(name, fn)
    io.write(string.format("[RUN] %s\n", name))
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        io.write(string.format("[PASS] %s\n", name))
    else
        failed = failed + 1
        io.write(string.format("[FAIL] %s: %s\n", name, tostring(err)))
    end
end

local function assertTrue(condition, message)
    if not condition then
        error(message or "assertion failed")
    end
end

runTest("compileSpell fallback keyword loading", function()
    local compiled = SpellCompiler.compileSpell(FireSpells.firebolt)
    assertTrue(compiled ~= nil, "compileSpell returned nil")
    assertTrue(type(compiled.executeAll) == "function", "compiled spell missing executeAll")
    assertTrue(compiled.behavior and compiled.behavior.damage, "compiled spell missing damage behavior")
end)

runTest("blocked DAMAGE callback propagates to EFFECT onComplete", function()
    local captured = {}
    local eventRunnerStub = {
        processEvents = function(events)
            captured.events = events
            return { eventsProcessed = #events }
        end,
        handleEvent = function(event)
            captured.effectEvent = event
            return true
        end,
        debugPrintEvents = function() end
    }

    package.loaded["systems.EventRunner"] = eventRunnerStub

    local compiled = SpellCompiler.compileSpell(FireSpells.firebolt, Keywords)
    local caster = {
        name = "Caster",
        spellSlots = {
            { spell = compiled },
            {},
            {}
        }
    }
    local target = {
        name = "Target",
        elevation = Constants.ElevationState.GROUNDED,
        gameState = { rangeState = Constants.RangeState.FAR }
    }

    local callbackHit = false
    local results = {
        blockInfo = {
            blockable = true,
            blockType = Constants.ShieldType.WARD,
            blockPoint = 0.75,
            blockingSlot = 2,
            onBlockImpact = function()
                callbackHit = true
            end
        }
    }

    compiled.executeAll(caster, target, results, 1)
    local blockedEvent = captured.events and captured.events[1]
    assertTrue(blockedEvent ~= nil, "no blocked event captured")
    assertTrue(blockedEvent.type == "BLOCKED_DAMAGE", "expected BLOCKED_DAMAGE event")
    assertTrue(
        blockedEvent.blockInfo and type(blockedEvent.blockInfo.onBlockImpact) == "function",
        "missing blockInfo.onBlockImpact on BLOCKED_DAMAGE"
    )

    local realEventRunner = dofile("systems/EventRunner.lua")
    realEventRunner.handleEvent = function(event)
        captured.effectEvent = event
        return true
    end
    realEventRunner.EVENT_HANDLERS.BLOCKED_DAMAGE(blockedEvent, caster, target, 1, {})
    assertTrue(captured.effectEvent ~= nil, "no EFFECT event produced by BLOCKED_DAMAGE handler")
    assertTrue(type(captured.effectEvent.onComplete) == "function", "EFFECT event missing onComplete")

    captured.effectEvent.onComplete({})
    assertTrue(callbackHit, "onComplete did not invoke block callback")
end)

runTest("blocked cast lifecycle dispatches CLEANUP_SLOT event", function()
    local BlockedCastLifecycle = dofile("systems/wizard/BlockedCastLifecycle.lua")
    local captured = nil
    local slot = {
        tokens = {
            {
                token = {
                    requestReturnAnimation = function() end
                },
                index = 1
            }
        }
    }
    local wizard = {
        name = "Caster",
        gameState = {
            eventRunner = {
                processEvents = function(events, caster, target, spellSlot)
                    captured = {
                        events = events,
                        caster = caster,
                        target = target,
                        spellSlot = spellSlot
                    }
                    return { eventsProcessed = #events, slotsCleaned = 1 }
                end
            }
        }
    }

    BlockedCastLifecycle.begin(slot, 0.5)
    local callback = BlockedCastLifecycle.makeImpactCallback(wizard, slot, 2)
    callback()

    assertTrue(captured ~= nil, "blocked impact callback did not dispatch cleanup")
    assertTrue(#slot.tokens == 1, "blocked impact callback mutated slot tokens directly")
    assertTrue(slot.blockedPendingImpact == true, "blocked impact callback cleared pending state directly")
    assertTrue(captured.spellSlot == 2, "blocked impact cleanup used wrong slot context")
    assertTrue(captured.events[1].type == "CLEANUP_SLOT", "blocked impact cleanup used wrong event type")
    assertTrue(captured.events[1].slotIndex == 2, "blocked impact cleanup targeted wrong slot")
    assertTrue(captured.events[1].returnTokens == true, "blocked impact cleanup should return tokens")
    assertTrue(captured.events[1].resetSlot == true, "blocked impact cleanup should reset the slot")
    assertTrue(captured.events[1].requireBlockedPendingImpact == true, "blocked impact cleanup should guard on pending state")
end)

runTest("CastExecution configures blocked casts", function()
    local CastExecution = dofile("systems/wizard/CastExecution.lua")
    local realEventRunner = dofile("systems/EventRunner.lua")
    local capturedBlockInfo = nil

    local castSlot = {
        blockedPendingImpact = false,
        blockImpactTimer = 0,
        blockImpactTimeout = nil,
        tokens = {
            {
                token = {
                    requestReturnAnimation = function() end
                },
                index = 1
            }
        }
    }

    local shieldToken = {
        type = Constants.TokenType.MOON,
        requestReturnAnimation = function(self)
            self.returnRequested = true
        end
    }

    local caster = {
        name = "Caster",
        gameState = {
            wizards = {}
        }
    }

    local defender = {
        name = "Defender",
        x = 0,
        y = 0,
        spellSlots = {
            [1] = {
                active = true,
                isShield = true,
                defenseType = Constants.ShieldType.WARD,
                blocksAttackTypes = {
                    [Constants.AttackType.PROJECTILE] = true
                },
                tokens = { { token = shieldToken, index = 1 } }
            }
        },
        gameState = {
            eventRunner = realEventRunner
        },
        resetSpellSlot = function(self, slotIndex)
            local slot = self.spellSlots[slotIndex]
            slot.active = false
            slot.isShield = false
            slot.tokens = {}
        end
    }

    caster.gameState.wizards = { caster, defender }

    local spellToUse = {
        name = "Test Projectile",
        attackType = Constants.AttackType.PROJECTILE,
        shieldBreaker = 1,
        executeAll = function(castingWizard, targetWizard, results, spellSlot)
            capturedBlockInfo = results.blockInfo
            assertTrue(spellSlot == 2, "tryBlockedCast should preserve the spell slot index")
            return {}
        end
    }

    local effect = CastExecution.tryBlockedCast(
        caster,
        defender,
        castSlot,
        2,
        spellToUse,
        2.0
    )

    assertTrue(effect ~= nil, "tryBlockedCast should return an effect table for blocked casts")
    assertTrue(effect.blocked == true, "blocked effect should be marked as blocked")
    assertTrue(effect.blockType == Constants.ShieldType.WARD, "blocked effect should preserve shield type")
    assertTrue(castSlot.blockedPendingImpact == true, "blocked cast should mark the slot as pending impact")
    assertTrue(type(capturedBlockInfo.onBlockImpact) == "function", "blocked cast should inject an impact callback")
end)

runTest("CastExecution dispatches CAST_COMPLETE event", function()
    local CastExecution = dofile("systems/wizard/CastExecution.lua")
    local captured = nil

    local caster = {
        name = "Caster",
        gameState = {
            eventRunner = {
                processEvents = function(events, eventCaster, eventTarget, eventSpellSlot)
                    captured = {
                        events = events,
                        caster = eventCaster,
                        target = eventTarget,
                        spellSlot = eventSpellSlot
                    }
                    return { eventsProcessed = #events }
                end
            }
        }
    }

    local target = { name = "Target" }
    local spell = { id = "firebolt", name = "Firebolt" }
    local results = CastExecution.dispatchCastComplete(caster, target, 2, spell, {
        blocked = true,
        isShield = false,
        isSustained = true
    })

    assertTrue(results ~= nil and results.eventsProcessed == 1, "dispatchCastComplete should return event runner results")
    assertTrue(captured ~= nil, "dispatchCastComplete did not call the event runner")
    assertTrue(captured.caster == caster, "dispatchCastComplete used the wrong caster")
    assertTrue(captured.target == target, "dispatchCastComplete used the wrong target")
    assertTrue(captured.spellSlot == 2, "dispatchCastComplete used the wrong slot context")
    assertTrue(#captured.events == 1, "dispatchCastComplete should emit one event")
    assertTrue(captured.events[1].type == "CAST_COMPLETE", "dispatchCastComplete used the wrong event type")
    assertTrue(captured.events[1].slotIndex == 2, "CAST_COMPLETE targeted the wrong slot")
    assertTrue(captured.events[1].spellId == "firebolt", "CAST_COMPLETE should include the spell id")
    assertTrue(captured.events[1].spell == spell, "CAST_COMPLETE should preserve spell metadata")
    assertTrue(captured.events[1].blocked == true, "CAST_COMPLETE should preserve blocked state")
    assertTrue(captured.events[1].isSustained == true, "CAST_COMPLETE should preserve sustained state")
end)

runTest("shield onBlock receives attacker wizard", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local attacker = { name = "Attacker" }
    local seenAttacker = nil
    local onBlockCalls = 0
    local resetCalls = 0

    local shieldToken = {
        type = Constants.TokenType.MOON,
        requestReturnAnimation = function(self)
            self.returnRequested = true
        end
    }

    local defender = {
        name = "Defender",
        x = 0,
        y = 0,
        spellSlots = {
            [1] = {
                active = true,
                isShield = true,
                defenseType = Constants.ShieldType.WARD,
                tokens = { { token = shieldToken, index = 1 } },
                onBlock = function(defenderWizard, attackerWizard)
                    seenAttacker = attackerWizard
                    onBlockCalls = onBlockCalls + 1
                    return {}
                end
            }
        },
        gameState = {
            eventRunner = realEventRunner
        },
        resetSpellSlot = function(self, resetSlotIndex)
            resetCalls = resetCalls + 1
            local resetSlot = self.spellSlots[resetSlotIndex]
            resetSlot.active = false
            resetSlot.isShield = false
            resetSlot.tokens = {}
            resetSlot.onBlock = nil
        end
    }

    local ok = ShieldSystem.handleShieldBlock(
        defender,
        1,
        { name = "Test Projectile", shieldBreaker = 1 },
        attacker
    )

    assertTrue(ok == true, "handleShieldBlock returned false")
    assertTrue(onBlockCalls == 1, "onBlock was not called exactly once")
    assertTrue(seenAttacker == attacker, "attacker context was not forwarded to onBlock")
    assertTrue(resetCalls == 1, "shield collapse should reset the slot once")
    assertTrue(shieldToken.returnRequested == true, "consumed shield token was not returned to the pool")
end)

runTest("CREATE_SHIELD registers sustained shield once", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local sustainedAdds = 0
    local capturedSpellData = nil
    local createShieldCalls = 0

    local wizard = {
        name = "Caster",
        spellSlots = {
            [1] = {
                active = true,
                spell = { name = "Test Ward" },
                tokens = {
                    {
                        token = {
                            setState = function() end
                        },
                        index = 1
                    }
                }
            }
        },
        createShield = function(self, slotIndex, shieldParams)
            createShieldCalls = createShieldCalls + 1
            local slot = self.spellSlots[slotIndex]
            slot.isShield = true
            slot.defenseType = shieldParams.defenseType
            slot.blocksAttackTypes = shieldParams.blocksAttackTypes
            slot.reflect = shieldParams.reflect
            slot.onBlock = shieldParams.onBlock
            return { shieldCreated = true }
        end,
        gameState = {
            sustainedSpellManager = {
                addSustainedSpell = function(shieldWizard, slotIndex, spellData)
                    sustainedAdds = sustainedAdds + 1
                    capturedSpellData = spellData
                    return "shield-1"
                end
            }
        }
    }

    local results = realEventRunner.processEvents({
        {
            type = "CREATE_SHIELD",
            source = "caster",
            target = "self_slot",
            slotIndex = 1,
            defenseType = Constants.ShieldType.WARD,
            blocksAttackTypes = { Constants.AttackType.PROJECTILE },
        }
    }, wizard, nil, 1)

    assertTrue(results.shieldCreated == true, "CREATE_SHIELD should report success")
    assertTrue(createShieldCalls == 1, "wizard:createShield should run exactly once")
    assertTrue(sustainedAdds == 1, "shield should register with the sustained manager")
    assertTrue(wizard.spellSlots[1].sustainedId == "shield-1", "slot did not retain sustained id")
    assertTrue(capturedSpellData and capturedSpellData.isShield == true, "registered shield data missing isShield flag")
    assertTrue(capturedSpellData and capturedSpellData.isSustained == true, "registered shield data missing sustained flag")
end)

runTest("CastExecution keeps registered sustained slots active", function()
    local CastExecution = dofile("systems/wizard/CastExecution.lua")
    local resetCalls = 0
    local token = {
        requestReturnAnimation = function(self)
            self.returnRequested = true
        end
    }

    local wizard = {
        name = "Caster",
        resetSpellSlot = function()
            resetCalls = resetCalls + 1
        end
    }

    local slot = {
        sustainedId = "trap-1",
        tokens = {
            { token = token, index = 1 }
        }
    }

    local effect = CastExecution.finalizeCast(wizard, slot, 1, { id = "gravityTrap", name = "Icarus Trap" }, {
        isSustained = true
    })

    assertTrue(effect.isSustained == true, "finalizeCast should return the original effect")
    assertTrue(resetCalls == 0, "finalizeCast should not reset already-registered sustained slots")
    assertTrue(token.returnRequested ~= true, "finalizeCast should not return sustained-slot tokens")
end)

runTest("generateEvents appends REGISTER_SUSTAINED for trap spells", function()
    local compiled = SpellCompiler.compileSpell(MoonSpells.gravityTrap, Keywords)
    local events = compiled.generateEvents({
        name = "Caster",
        gameState = { rangeState = Constants.RangeState.NEAR }
    }, {
        name = "Target",
        gameState = { rangeState = Constants.RangeState.NEAR }
    }, 1)

    local found = nil
    for _, event in ipairs(events) do
        if event.type == "REGISTER_SUSTAINED" then
            found = event
            break
        end
    end

    assertTrue(found ~= nil, "trap spell did not generate REGISTER_SUSTAINED")
    assertTrue(found.slotIndex == 1, "REGISTER_SUSTAINED targeted wrong slot")
    assertTrue(found.sustainData and found.sustainData.trapTrigger ~= nil, "REGISTER_SUSTAINED missing trapTrigger")
    assertTrue(found.sustainData and found.sustainData.trapEffect ~= nil, "REGISTER_SUSTAINED missing trapEffect")
end)

runTest("REGISTER_SUSTAINED registers field slots once", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local sustainedAdds = 0

    local wizard = {
        name = "Caster",
        spellSlots = {
            [1] = {
                active = true,
                spell = { name = "Radiant Field" },
                tokens = {
                    {
                        token = {},
                        index = 1
                    }
                }
            }
        },
        gameState = {
            sustainedSpellManager = {
                addSustainedSpell = function(_, slotIndex, spellData)
                    sustainedAdds = sustainedAdds + 1
                    return "field-1"
                end
            }
        }
    }

    local results = realEventRunner.processEvents({
        {
            type = "REGISTER_SUSTAINED",
            source = "caster",
            target = "self_slot",
            slotIndex = 1,
            sustainData = {
                fieldStatus = SunSpells.radiantfield.keywords.field_status
            }
        }
    }, wizard, nil, 1)

    assertTrue(results.sustainedRegistered == true, "REGISTER_SUSTAINED should report success")
    assertTrue(results.sustainedId == "field-1", "REGISTER_SUSTAINED should return the sustained id")
    assertTrue(sustainedAdds == 1, "REGISTER_SUSTAINED should add exactly one sustained entry")
    assertTrue(wizard.spellSlots[1].sustainedId == "field-1", "REGISTER_SUSTAINED should store sustained id on the slot")
end)

runTest("CLEANUP_SLOT returns tokens and resets slot", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local resetCalls = 0
    local token = {
        requestReturnAnimation = function(self)
            self.returnRequested = true
        end
    }

    local wizard = {
        name = "Caster",
        spellSlots = {
            [1] = {
                active = true,
                blockedPendingImpact = true,
                blockImpactTimer = 0.4,
                blockImpactTimeout = 0.5,
                tokens = {
                    { token = token, index = 1 }
                }
            }
        },
        resetSpellSlot = function(self, slotIndex)
            resetCalls = resetCalls + 1
            local slot = self.spellSlots[slotIndex]
            slot.active = false
            slot.blockedPendingImpact = false
            slot.blockImpactTimer = 0
            slot.blockImpactTimeout = nil
            slot.tokens = {}
        end
    }

    local results = realEventRunner.processEvents({
        {
            type = "CLEANUP_SLOT",
            source = "caster",
            target = "self_slot",
            slotIndex = 1,
            returnTokens = true,
            resetSlot = true,
            clearBlockedPendingImpact = true,
            requireBlockedPendingImpact = true
        }
    }, wizard, nil, 1)

    assertTrue(results.slotsCleaned == 1, "CLEANUP_SLOT should report one cleaned slot")
    assertTrue(results.tokensAffected == 1, "CLEANUP_SLOT should report returned tokens")
    assertTrue(resetCalls == 1, "CLEANUP_SLOT should reset the slot exactly once")
    assertTrue(token.returnRequested == true, "CLEANUP_SLOT did not return the token")
    assertTrue(wizard.spellSlots[1].active == false, "CLEANUP_SLOT did not leave the slot reset")
end)

runTest("EFFECT delayedDamage preserves existing onComplete callback", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local firstCallbackCount = 0
    local target = {
        name = "Target",
        x = 300,
        y = 220,
        health = 25,
        gameState = {}
    }

    local capturedVfxOpts = nil
    local caster = {
        name = "Caster",
        x = 100,
        y = 220,
        spellSlots = {
            [1] = { spell = { visualShape = Constants.VisualShape.BOLT } }
        },
        gameState = {
            vfx = {
                createEffect = function(effectName, sx, sy, tx, ty, opts)
                    capturedVfxOpts = opts
                    return true
                end
            }
        }
    }

    local effectEvent = {
        type = "EFFECT",
        source = "caster",
        target = "enemy",
        affinity = Constants.TokenType.FIRE,
        attackType = Constants.AttackType.PROJECTILE,
        visualShape = Constants.VisualShape.BOLT,
        amount = 3,
        delayedDamage = 5,
        delayedDamageTarget = target,
        onComplete = function()
            firstCallbackCount = firstCallbackCount + 1
        end
    }

    local handled = realEventRunner.EVENT_HANDLERS.EFFECT(effectEvent, caster, target, 1, {})
    assertTrue(handled == true, "EFFECT handler returned false")
    assertTrue(capturedVfxOpts ~= nil, "vfx options were not captured")
    assertTrue(type(capturedVfxOpts.onComplete) == "function", "composed onComplete missing")

    capturedVfxOpts.onComplete({})
    assertTrue(firstCallbackCount == 1, "existing onComplete callback did not run")
    assertTrue(target.health == 20, "delayed damage callback did not apply expected damage")
end)

runTest("SET_RANGE delegation calls EventRunner.handleEvent", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local intercepted = nil

    realEventRunner.handleEvent = function(event)
        intercepted = event
        return true
    end

    local caster = {
        name = "Caster",
        elevation = Constants.ElevationState.GROUNDED,
        gameState = {
            rangeState = Constants.RangeState.NEAR,
            vfx = {} -- Presence enables range VFX event generation.
        }
    }
    local target = { name = "Target" }
    local setRangeEvent = {
        type = "SET_RANGE",
        target = Constants.TargetType.ALL,
        position = Constants.RangeState.FAR,
        affinity = Constants.TokenType.MOON
    }

    local handled = realEventRunner.EVENT_HANDLERS.SET_RANGE(setRangeEvent, caster, target, 1, {})
    assertTrue(handled == true, "SET_RANGE handler returned false")
    assertTrue(caster.gameState.rangeState == Constants.RangeState.FAR, "range state was not updated")
    assertTrue(intercepted ~= nil, "SET_RANGE did not route through handleEvent")
    assertTrue(intercepted.type == "EFFECT", "SET_RANGE did not emit EFFECT event")
    assertTrue(intercepted.target == Constants.TargetType.ALL, "SET_RANGE emitted wrong EFFECT target")
end)

runTest("FORCE_POSITION routes visuals through EFFECT", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local intercepted = nil

    realEventRunner.handleEvent = function(event)
        intercepted = event
        return true
    end

    local caster = {
        name = "Caster",
        x = 100,
        y = 200,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = {
            rangeState = Constants.RangeState.NEAR,
            vfx = {}
        }
    }
    local target = {
        name = "Target",
        x = 300,
        y = 220
    }

    local handled = realEventRunner.EVENT_HANDLERS.FORCE_POSITION({
        type = "FORCE_POSITION",
        source = "caster",
        target = Constants.TargetType.ENEMY
    }, caster, target, 1, {})

    assertTrue(handled == true, "FORCE_POSITION handler returned false")
    assertTrue(intercepted ~= nil, "FORCE_POSITION did not emit an EFFECT event")
    assertTrue(intercepted.type == "EFFECT", "FORCE_POSITION emitted the wrong event type")
    assertTrue(intercepted.effectOverride == Constants.VFXType.WARP_BASE, "FORCE_POSITION used the wrong visual override")
    assertTrue(intercepted.vfxParams.x == 200, "FORCE_POSITION used the wrong midpoint x coordinate")
    assertTrue(intercepted.vfxParams.y == 210, "FORCE_POSITION used the wrong midpoint y coordinate")
end)

runTest("APPLY_STATUS routes visuals through EFFECT", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local intercepted = nil
    local originalHandleEvent = realEventRunner.handleEvent

    realEventRunner.handleEvent = function(event, caster, target, spellSlot, results)
        if event.type == "EFFECT" then
            intercepted = event
            return true
        end
        return originalHandleEvent(event, caster, target, spellSlot, results)
    end

    local gameState = {
        rangeState = Constants.RangeState.NEAR,
        vfx = {}
    }

    local caster = {
        name = "Caster",
        elevation = Constants.ElevationState.GROUNDED,
        gameState = gameState
    }

    local target = {
        name = "Target",
        elevation = Constants.ElevationState.AERIAL,
        gameState = gameState,
        statusEffects = {}
    }

    local handled = realEventRunner.EVENT_HANDLERS.APPLY_STATUS({
        type = "APPLY_STATUS",
        source = "caster",
        target = Constants.TargetType.ENEMY,
        statusType = Constants.StatusType.BURN,
        duration = 3.0,
        tickDamage = 2,
        affinity = Constants.TokenType.FIRE,
        attackType = Constants.AttackType.UTILITY
    }, caster, target, 1, {
        statusEffectsApplied = {}
    })

    assertTrue(handled == true, "APPLY_STATUS handler returned false")
    assertTrue(intercepted ~= nil, "APPLY_STATUS did not emit an EFFECT event")
    assertTrue(intercepted.effectOverride == Constants.VFXType.EMBER_OVERLAY, "APPLY_STATUS used the wrong burn override")
    assertTrue(intercepted.tags.BURN == true, "APPLY_STATUS burn visuals should carry the BURN tag")
    assertTrue(intercepted.tags.DOT == true, "APPLY_STATUS burn visuals should carry the DOT tag")
    assertTrue(target.statusEffects[Constants.StatusType.BURN] ~= nil, "APPLY_STATUS did not store the status effect")
end)

runTest("LOCK_TOKEN routes visuals through EFFECT", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local intercepted = nil
    local originalHandleEvent = realEventRunner.handleEvent

    realEventRunner.handleEvent = function(event, caster, target, spellSlot, results)
        if event.type == "EFFECT" then
            intercepted = event
            return true
        end
        return originalHandleEvent(event, caster, target, spellSlot, results)
    end

    local token = {
        type = Constants.TokenType.MOON,
        status = Constants.TokenStatus.FREE,
        x = 140,
        y = 180,
        setState = function(self, nextState)
            self.status = nextState
        end
    }

    local caster = {
        name = "Caster",
        elevation = Constants.ElevationState.GROUNDED,
        gameState = {
            rangeState = Constants.RangeState.NEAR,
            vfx = {},
            manaPool = {
                tokens = { token }
            }
        }
    }

    local handled = realEventRunner.EVENT_HANDLERS.LOCK_TOKEN({
        type = "LOCK_TOKEN",
        source = "caster",
        tokenType = Constants.TokenType.MOON,
        amount = 1,
        duration = 2.5
    }, caster, nil, 1, {
        tokensAffected = 0
    })

    assertTrue(handled == true, "LOCK_TOKEN handler returned false")
    assertTrue(token.status == Constants.TokenStatus.LOCKED, "LOCK_TOKEN did not update token state")
    assertTrue(intercepted ~= nil, "LOCK_TOKEN did not emit an EFFECT event")
    assertTrue(intercepted.effectOverride == Constants.VFXType.RESOURCE_OVERLAY, "LOCK_TOKEN used the wrong visual override")
    assertTrue(intercepted.affinity == Constants.TokenType.MOON, "LOCK_TOKEN should color visuals by locked token type")
    assertTrue(intercepted.vfxParams.x == 140, "LOCK_TOKEN used the wrong x coordinate")
    assertTrue(intercepted.vfxParams.y == 180, "LOCK_TOKEN used the wrong y coordinate")
end)

runTest("ACCELERATE_SPELL routes visuals through EFFECT", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local intercepted = nil
    local originalHandleEvent = realEventRunner.handleEvent

    realEventRunner.handleEvent = function(event, caster, target, spellSlot, results)
        if event.type == "EFFECT" then
            intercepted = event
            return true
        end
        return originalHandleEvent(event, caster, target, spellSlot, results)
    end

    local targetWizard = {
        name = "Target",
        x = 320,
        y = 200,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = {
            rangeState = Constants.RangeState.FAR
        },
        spellSlots = {
            [1] = {
                active = true,
                isShield = false,
                progress = 1.0,
                tokens = { {}, {} },
                spell = {
                    affinity = Constants.TokenType.SUN,
                    attackType = Constants.AttackType.UTILITY,
                    visualShape = Constants.VisualShape.SURGE
                }
            }
        }
    }

    local caster = {
        name = "Caster",
        elevation = Constants.ElevationState.GROUNDED,
        gameState = {
            rangeState = Constants.RangeState.NEAR,
            vfx = {}
        }
    }

    local handled = realEventRunner.EVENT_HANDLERS.ACCELERATE_SPELL({
        type = "ACCELERATE_SPELL",
        source = "caster",
        target = Constants.TargetType.ENEMY,
        slotIndex = 1,
        amount = 0.75
    }, caster, targetWizard, 1, {})

    assertTrue(handled == true, "ACCELERATE_SPELL handler returned false")
    assertTrue(targetWizard.spellSlots[1].progress == 1.75, "ACCELERATE_SPELL did not update slot progress")
    assertTrue(intercepted ~= nil, "ACCELERATE_SPELL did not emit an EFFECT event")
    assertTrue(intercepted.effectOverride == Constants.VFXType.SURGE_BASE, "ACCELERATE_SPELL used the wrong visual override")
    assertTrue(intercepted.affinity == Constants.TokenType.SUN, "ACCELERATE_SPELL should inherit affinity from the affected spell")
    assertTrue(intercepted.manaCost == 2, "ACCELERATE_SPELL should scale visuals from slot token count")
end)

runTest("timed burn ticks route through EventRunner", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local createdEffects = 0

    local gameState = {
        rangeState = Constants.RangeState.NEAR,
        vfx = {
            createEffect = function(...)
                createdEffects = createdEffects + 1
                return true
            end
        },
        triggerShake = function() end,
        triggerHitstop = function() end
    }

    local burnedWizard = {
        name = "Burned",
        health = 20,
        hitFlashTimer = 0,
        x = 100,
        y = 200,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = gameState,
        statusEffects = {
            [Constants.StatusType.BURN] = {
                active = true,
                duration = 3,
                tickDamage = 4,
                tickInterval = 1.0,
                elapsed = 0,
                totalTime = 0,
                affinity = Constants.TokenType.FIRE,
                attackType = Constants.AttackType.UTILITY,
                tags = { BURN = true, DOT = true }
            }
        }
    }

    local opponent = {
        name = "Opponent",
        health = 20,
        x = 300,
        y = 200,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = gameState,
        statusEffects = {}
    }

    gameState.wizards = { burnedWizard, opponent }

    realEventRunner.updateTimedEffects(gameState, 1.0)

    assertTrue(burnedWizard.health == 16, "burn tick did not apply expected damage through EventRunner")
    assertTrue(burnedWizard.hitFlashTimer > 0, "burn tick did not trigger hit feedback")
    assertTrue(createdEffects >= 1, "burn tick did not create an event-driven visual effect")
end)

runTest("timed damage defeat sets winner through EventRunner", function()
    local realEventRunner = dofile("systems/EventRunner.lua")

    local gameState = {
        rangeState = Constants.RangeState.NEAR,
        gameOver = false,
        winner = nil,
        vfx = {
            createEffect = function()
                return true
            end
        },
        triggerShake = function() end,
        triggerHitstop = function() end
    }

    local doomedWizard = {
        name = "Doomed",
        health = 4,
        x = 100,
        y = 200,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = gameState,
        statusEffects = {
            [Constants.StatusType.BURN] = {
                active = true,
                duration = 3,
                tickDamage = 4,
                tickInterval = 1.0,
                elapsed = 0,
                totalTime = 0,
                affinity = Constants.TokenType.FIRE,
                attackType = Constants.AttackType.UTILITY,
                tags = { BURN = true, DOT = true }
            }
        }
    }

    local survivor = {
        name = "Survivor",
        health = 20,
        x = 300,
        y = 200,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = gameState,
        statusEffects = {}
    }

    gameState.wizards = { doomedWizard, survivor }

    realEventRunner.updateTimedEffects(gameState, 1.0)

    assertTrue(doomedWizard.health == 0, "timed damage did not reduce health to zero")
    assertTrue(gameState.gameOver == true, "EventRunner did not mark the game as over")
    assertTrue(gameState.winner == 2, "EventRunner did not assign the surviving wizard as winner")
end)

runTest("field status lifecycle emits apply/remove events", function()
    local manager = dofile("systems/SustainedSpellManager.lua")
    local captured = {}

    manager.activeSpells = {}

    local gameState = {
        eventRunner = {
            processEvents = function(events, caster, target, spellSlot)
                table.insert(captured, {
                    events = events,
                    caster = caster,
                    target = target,
                    spellSlot = spellSlot
                })
                return { eventsProcessed = #events }
            end
        }
    }

    local wizard = {
        name = "Caster",
        gameState = gameState,
        spellSlots = {
            [1] = {
                spell = {
                    name = "Radiant Field",
                    affinity = Constants.TokenType.SUN,
                    attackType = Constants.AttackType.UTILITY,
                    visualShape = Constants.VisualShape.BLAST
                },
                tokens = { {}, {} }
            }
        }
    }

    local opponent = {
        name = "Opponent",
        gameState = gameState,
        spellSlots = {}
    }

    gameState.wizards = { wizard, opponent }

    local id = manager.addSustainedSpell(wizard, 1, {
        fieldStatus = {
            statusType = Constants.StatusType.SLOW,
            magnitude = Constants.CastSpeed.ONE_TIER
        }
    })

    assertTrue(id ~= nil, "field sustained spell did not register")
    assertTrue(#captured == 1, "field apply did not emit exactly one event batch")
    assertTrue(#captured[1].events == 2, "field apply should target both wizards")
    assertTrue(captured[1].events[1].type == "APPLY_STATUS", "field apply did not emit APPLY_STATUS")
    assertTrue(captured[1].events[2].type == "APPLY_STATUS", "field apply did not emit APPLY_STATUS for opponent")

    local removed = manager.removeSustainedSpell(id)
    assertTrue(removed == true, "field sustained spell did not remove cleanly")
    assertTrue(#captured == 2, "field removal did not emit exactly one additional event batch")
    assertTrue(#captured[2].events == 2, "field removal should target both wizards")
    assertTrue(captured[2].events[1].type == "REMOVE_STATUS", "field removal did not emit REMOVE_STATUS")
    assertTrue(captured[2].events[2].type == "REMOVE_STATUS", "field removal did not emit REMOVE_STATUS for opponent")
end)

runTest("notifyTrapTrigger dispatches TRIGGER_TRAP event", function()
    local manager = dofile("systems/SustainedSpellManager.lua")
    local captured = {}

    manager.activeSpells = {}

    local gameState = {
        keywords = Keywords,
        eventRunner = {
            processEvents = function(events, caster, target, spellSlot)
                table.insert(captured, {
                    events = events,
                    caster = caster,
                    target = target,
                    spellSlot = spellSlot
                })
                return { eventsProcessed = #events, trapsTriggered = 1 }
            end
        }
    }

    local wizard = {
        name = "Trap Caster",
        gameState = gameState,
        spellSlots = {
            [1] = {
                active = true,
                spell = {
                    name = "Icarus Trap",
                    affinity = Constants.TokenType.MOON,
                    attackType = Constants.AttackType.UTILITY,
                    visualShape = Constants.VisualShape.WARP
                },
                tokens = {
                    {
                        token = {
                            requestReturnAnimation = function() end
                        },
                        index = 1
                    }
                }
            }
        }
    }

    local opponent = {
        name = "Opponent",
        gameState = gameState,
        spellSlots = {}
    }

    gameState.wizards = { wizard, opponent }

    local id = manager.addSustainedSpell(wizard, 1, {
        isSustained = true,
        trapTrigger = {
            condition = "on_opponent_cast"
        },
        trapEffect = {
            damage = {
                amount = 3,
                type = Constants.DamageType.MOON,
                target = Constants.TargetType.ENEMY
            }
        }
    })

    assertTrue(id ~= nil, "trap sustained spell did not register")
    wizard.spellSlots[1].sustainedId = id

    local triggered = manager.notifyTrapTrigger("on_opponent_cast", opponent)

    assertTrue(triggered == 1, "notifyTrapTrigger should report one triggered trap")
    assertTrue(#captured == 1, "trap trigger should emit one event batch")
    assertTrue(captured[1].spellSlot == 1, "trap trigger used wrong slot context")
    assertTrue(#captured[1].events == 1, "trap trigger should dispatch a single TRIGGER_TRAP event")
    assertTrue(captured[1].events[1].type == "TRIGGER_TRAP", "trap trigger used wrong event type")
    assertTrue(captured[1].events[1].slotIndex == 1, "TRIGGER_TRAP targeted wrong slot")
    assertTrue(captured[1].events[1].trapEffect ~= nil, "TRIGGER_TRAP missing trapEffect payload")
    assertTrue(captured[1].events[1].trapSpell == wizard.spellSlots[1].spell, "TRIGGER_TRAP missing trap spell context")
end)

runTest("CAST_COMPLETE forwards cast trap signal", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local notified = {}

    local gameState = {
        sustainedSpellManager = {
            notifyTrapTrigger = function(triggerCondition, targetWizard, context)
                notified.triggerCondition = triggerCondition
                notified.targetWizard = targetWizard
                notified.context = context
                return 1
            end
        }
    }

    local caster = {
        name = "Caster",
        gameState = gameState
    }

    local target = {
        name = "Target",
        gameState = gameState
    }

    gameState.wizards = { caster, target }

    local results = realEventRunner.processEvents({
        {
            type = "CAST_COMPLETE",
            source = "caster",
            target = Constants.TargetType.SELF,
            slotIndex = 2,
            spellId = "firebolt",
            spell = { name = "Firebolt" },
            blocked = true,
            isShield = false,
            isSustained = true
        }
    }, caster, target, 2)

    assertTrue(results.eventsProcessed == 1, "CAST_COMPLETE should count as a processed event")
    assertTrue(notified.triggerCondition == "on_opponent_cast", "CAST_COMPLETE should forward the cast trigger condition")
    assertTrue(notified.targetWizard == caster, "CAST_COMPLETE should use the casting wizard as the subject")
    assertTrue(notified.context ~= nil, "CAST_COMPLETE should forward context to notifyTrapTrigger")
    assertTrue(notified.context.type == "NOTIFY_TRAP_TRIGGER", "CAST_COMPLETE should delegate through NOTIFY_TRAP_TRIGGER")
    assertTrue(notified.context.spellId == "firebolt", "CAST_COMPLETE should preserve spell id in forwarded context")
    assertTrue(notified.context.blocked == true, "CAST_COMPLETE should preserve blocked state in forwarded context")
    assertTrue(notified.context.isSustained == true, "CAST_COMPLETE should preserve sustained state in forwarded context")
end)

runTest("SET_ELEVATION trap notifications use final batch state", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local manager = dofile("systems/SustainedSpellManager.lua")
    local captured = {}

    manager.activeSpells = {}

    local gameState = {
        keywords = Keywords,
        rangeState = Constants.RangeState.NEAR,
        eventRunner = {
            processEvents = function(events, caster, target, spellSlot)
                table.insert(captured, {
                    events = events,
                    caster = caster,
                    target = target,
                    spellSlot = spellSlot
                })
                return { eventsProcessed = #events, trapsTriggered = 1 }
            end
        },
        sustainedSpellManager = manager
    }

    local wizard = {
        name = "Trap Caster",
        x = 0,
        y = 0,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = gameState,
        spellSlots = {
            [1] = {
                active = true,
                spell = {
                    name = "Icarus Trap",
                    affinity = Constants.TokenType.MOON,
                    attackType = Constants.AttackType.UTILITY,
                    visualShape = Constants.VisualShape.WARP
                },
                tokens = {
                    {
                        token = {
                            requestReturnAnimation = function() end
                        },
                        index = 1
                    }
                }
            }
        }
    }

    local opponent = {
        name = "Opponent",
        x = 10,
        y = 0,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = gameState,
        spellSlots = {},
        statusEffects = {}
    }

    gameState.wizards = { wizard, opponent }

    local id = manager.addSustainedSpell(wizard, 1, {
        isSustained = true,
        trapTrigger = {
            condition = "on_opponent_elevate"
        },
        trapEffect = {
            damage = {
                amount = 3,
                type = Constants.DamageType.MOON,
                target = Constants.TargetType.ENEMY
            }
        }
    })

    assertTrue(id ~= nil, "elevation trap did not register")
    wizard.spellSlots[1].sustainedId = id

    realEventRunner.processEvents({
        {
            type = "SET_ELEVATION",
            source = "caster",
            target = Constants.TargetType.ENEMY,
            elevation = Constants.ElevationState.AERIAL
        },
        {
            type = "SET_ELEVATION",
            source = "caster",
            target = Constants.TargetType.ENEMY,
            elevation = Constants.ElevationState.GROUNDED
        }
    }, wizard, opponent, 1)

    assertTrue(opponent.elevation == Constants.ElevationState.GROUNDED, "batch should leave opponent grounded")
    assertTrue(#captured == 0, "deferred trap notification should not fire when final elevation is grounded")
end)

runTest("TRIGGER_TRAP resolves payload and cleans up slot", function()
    local realEventRunner = dofile("systems/EventRunner.lua")
    local removedId = nil
    local token = {
        requestReturnAnimation = function(self)
            self.returnRequested = true
        end
    }

    local gameState = {
        keywords = Keywords,
        rangeState = Constants.RangeState.NEAR,
        sustainedSpellManager = {
            removeSustainedSpell = function(id)
                removedId = id
                return true
            end
        }
    }

    local wizard = {
        name = "Trap Caster",
        x = 0,
        y = 0,
        elevation = Constants.ElevationState.GROUNDED,
        gameState = gameState,
        spellSlots = {
            [1] = {
                active = true,
                sustainedId = "trap-1",
                spell = {
                    name = "Icarus Trap",
                    affinity = Constants.TokenType.MOON,
                    attackType = Constants.AttackType.UTILITY,
                    visualShape = Constants.VisualShape.WARP
                },
                tokens = {
                    {
                        token = token,
                        index = 1
                    }
                }
            }
        },
        resetSpellSlot = function(self, slotIndex)
            local slot = self.spellSlots[slotIndex]
            if slot.sustainedId and self.gameState and self.gameState.sustainedSpellManager then
                self.gameState.sustainedSpellManager.removeSustainedSpell(slot.sustainedId)
                slot.sustainedId = nil
            end
            slot.active = false
            slot.spell = nil
            slot.tokens = {}
        end
    }

    local opponent = {
        name = "Opponent",
        x = 10,
        y = 0,
        health = 20,
        elevation = Constants.ElevationState.GROUNDED,
        statusEffects = {},
        gameState = gameState,
        spellSlots = {}
    }

    gameState.wizards = { wizard, opponent }

    local results = realEventRunner.processEvents({
        {
            type = "TRIGGER_TRAP",
            source = "caster",
            target = Constants.TargetType.ENEMY,
            slotIndex = 1,
            trapEffect = {
                damage = {
                    amount = 3,
                    type = Constants.DamageType.MOON,
                    target = Constants.TargetType.ENEMY
                }
            },
            trapSpell = wizard.spellSlots[1].spell,
            cleanupReason = "trap_triggered"
        }
    }, wizard, opponent, 1)

    assertTrue(results.trapsTriggered == 1, "TRIGGER_TRAP should report one triggered trap")
    assertTrue(results.damageDealt == 3, "TRIGGER_TRAP should apply trap damage")
    assertTrue(results.slotsCleaned == 1, "TRIGGER_TRAP should clean up the sustaining slot")
    assertTrue(opponent.health == 17, "TRIGGER_TRAP did not damage the target wizard")
    assertTrue(token.returnRequested == true, "TRIGGER_TRAP did not return sustaining tokens")
    assertTrue(removedId == "trap-1", "TRIGGER_TRAP did not remove the sustained entry during cleanup")
    assertTrue(wizard.spellSlots[1].active == false, "TRIGGER_TRAP did not reset the caster slot")
end)

io.write(string.format("\nSummary: %d passed, %d failed\n", passed, failed))
if failed > 0 then
    os.exit(1)
end
