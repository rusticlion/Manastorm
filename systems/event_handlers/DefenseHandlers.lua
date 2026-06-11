-- systems/event_handlers/DefenseHandlers.lua
-- Shield and defense event handlers for EventRunner.

local DefenseHandlers = {}

function DefenseHandlers.build(deps)
    local Constants = deps.Constants
    local Log = deps.Log
    local handleEvent = deps.handleEvent
    local mergeProcessResults = deps.mergeProcessResults
    local processEvents = deps.processEvents
    local resolveTarget = deps.resolveTarget

    return {
        CREATE_SHIELD = function(event, caster, target, spellSlot, results)
            local wizard = nil
            local slotIndex = nil

            if event.target == "self_slot" then
                wizard = caster
                slotIndex = event.slotIndex or spellSlot
            elseif event.target == Constants.TargetType.SELF or event.target == "self" then
                wizard = caster
                slotIndex = spellSlot
            else
                local targetInfo = resolveTarget(event, caster, target)
                if targetInfo and targetInfo.wizard then
                    wizard = targetInfo.wizard
                    slotIndex = targetInfo.slotIndex or spellSlot
                end
            end

            if not wizard or not slotIndex then
                print("ERROR: Invalid wizard or slot for shield creation")
                return false
            end

            local slot = wizard.spellSlots[slotIndex]
            if not slot or not slot.tokens or #slot.tokens == 0 then
                print("ERROR: Slot " .. slotIndex .. " invalid or has no tokens for shield")
                return false
            end

            local shieldParams = {
                createShield = true,
                defenseType = event.defenseType or Constants.ShieldType.BARRIER,
                type = event.defenseType or Constants.ShieldType.BARRIER,
                blocksAttackTypes = event.blocksAttackTypes or {Constants.AttackType.PROJECTILE},
                reflect = event.reflect or false,
                onBlock = event.onBlock or nil
            }

            if event.onBlock then
                Log.debug("[EVENT DEBUG] CREATE_SHIELD event contains onBlock handler")
                Log.debug("[EVENT DEBUG] Type of onBlock: " .. type(event.onBlock))

                if type(event.onBlock) == "function" then
                    Log.debug("[EVENT DEBUG] onBlock is a valid function")
                else
                    Log.debug("[EVENT DEBUG] WARNING: onBlock is not a function!")
                end
            else
                Log.debug("[EVENT DEBUG] CREATE_SHIELD event has no onBlock handler")
            end

            local shieldCreated = false

            if type(wizard.createShield) ~= "function" then
                print("ERROR: Wizard " .. wizard.name .. " does not have createShield method")

                Log.debug("Using fallback shield creation")
                slot.isShield = true
                slot.defenseType = shieldParams.defenseType
                slot.blocksAttackTypes = shieldParams.blocksAttackTypes
                slot.reflect = shieldParams.reflect
                slot.onBlock = shieldParams.onBlock

                for _, tokenData in ipairs(slot.tokens) do
                    if tokenData.token then
                        tokenData.token:setState(Constants.TokenStatus.SHIELDING)
                        Log.debug("DEBUG: Marked token as SHIELDING to prevent return to pool")
                    end
                end
                shieldCreated = true
            else
                local shieldResult = wizard:createShield(slotIndex, shieldParams)
                shieldCreated = shieldResult and shieldResult.shieldCreated == true or false
            end

            results.shieldCreated = shieldCreated

            if shieldCreated
                and wizard.gameState
                and wizard.gameState.sustainedSpellManager
                and not slot.sustainedId then
                local sustainedId = wizard.gameState.sustainedSpellManager.addSustainedSpell(
                    wizard,
                    slotIndex,
                    {
                        isShield = true,
                        isSustained = true,
                        shieldParams = shieldParams
                    }
                )

                slot.sustainedId = sustainedId
            end

            return shieldCreated
        end,

        SHIELD_BLOCK = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: SHIELD_BLOCK handler could not resolve target wizard")
                return false
            end

            local wizard = targetInfo.wizard
            local slotIndex = targetInfo.slotIndex or event.slotIndex or spellSlot
            local slot = wizard.spellSlots and wizard.spellSlots[slotIndex] or nil
            if not slot or not slot.active then
                print(string.format("WARNING: SHIELD_BLOCK received invalid or inactive slot %s for %s", tostring(slotIndex), wizard.name or "wizard"))
                return false
            end

            if not slot.isShield then
                print(string.format("WARNING: SHIELD_BLOCK received non-shield slot %s for %s", tostring(slotIndex), wizard.name or "wizard"))
                return false
            end

            local incomingSpell = event.incomingSpell
            if not incomingSpell then
                print("WARNING: SHIELD_BLOCK called without incomingSpell")
                return false
            end

            local defenseType = slot.defenseType or Constants.ShieldType.BARRIER
            local shieldBreakPower = event.shieldBreakPower or incomingSpell.shieldBreaker or 1
            local tokensToConsume = math.min(event.tokensToConsume or shieldBreakPower, #(slot.tokens or {}))
            local onBlock = slot.onBlock
            local attackerWizard = event.attackerWizard or target

            Log.debug(string.format(
                "[SHIELD BLOCK] %s's %s shield (slot %d) hit by %s (%d break power). Consuming %d token(s).",
                wizard.name or "Unknown wizard",
                defenseType,
                slotIndex,
                incomingSpell.name or "unknown spell",
                shieldBreakPower,
                tokensToConsume
            ))

            local TokenManager = require("systems.TokenManager")
            local consumedTokens = {}

            for _ = 1, tokensToConsume do
                if #slot.tokens == 0 then
                    break
                end

                local removedTokenData = table.remove(slot.tokens)
                local removedTokenObject = removedTokenData and removedTokenData.token or nil

                if removedTokenObject and removedTokenObject.type then
                    Log.debug(string.format(
                        "[TOKEN LIFECYCLE] Shield Token (%s) freed by block -> FREE",
                        tostring(removedTokenObject.type)
                    ))
                    table.insert(consumedTokens, {
                        token = removedTokenObject,
                        index = removedTokenData.index or 1
                    })
                else
                    Log.debug("[TOKEN LIFECYCLE] Shield Token (unknown type) freed by block -> FREE")
                end
            end

            if #consumedTokens > 0 then
                TokenManager.returnTokensToPool(consumedTokens)
                results.tokensAffected = (results.tokensAffected or 0) + #consumedTokens
            end

            local effectEvent = {
                type = "EFFECT",
                source = Constants.TargetType.TARGET,
                target = Constants.TargetType.TARGET,
                effectType = "shield_hit",
                affinity = defenseType,
                tags = { SHIELD_HIT = true },
                shieldType = defenseType,
                vfxParams = {
                    x = wizard.x,
                    y = wizard.y,
                },
                rangeBand = wizard.gameState and wizard.gameState.rangeState or nil,
                elevation = wizard.elevation,
            }
            handleEvent(effectEvent, wizard, attackerWizard, slotIndex, results)

            if onBlock then
                local ok, blockEvents = pcall(onBlock, wizard, attackerWizard, slotIndex, {
                    blockType = defenseType,
                    shieldBreakPower = shieldBreakPower,
                    tokensConsumed = tokensToConsume
                })

                if ok and type(blockEvents) == "table" and #blockEvents > 0 then
                    local nestedResults = processEvents(blockEvents, wizard, attackerWizard, slotIndex)
                    mergeProcessResults(results, nestedResults)
                elseif not ok then
                    print("[SHIELD ERROR] Error executing onBlock handler: " .. tostring(blockEvents))
                end
            end

            if #slot.tokens == 0 then
                Log.debug("[TOKEN MANAGER] Spell in slot " .. slotIndex .. " fizzled - no tokens left")
                wizard:resetSpellSlot(slotIndex)
            end

            results.shieldBlocksResolved = (results.shieldBlocksResolved or 0) + 1

            return true
        end,

        REFLECT = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: REFLECT handler could not resolve target wizard")
                return false
            end
            local targetWizard = targetInfo.wizard

            targetWizard.reflectActive = true
            targetWizard.reflectDuration = event.duration

            if caster.gameState and caster.gameState.vfx then
                local effectEvent = {
                    type = "EFFECT",
                    source = "caster",
                    target = event.target,
                    effectOverride = Constants.VFXType.REFLECT,
                    affinity = event.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = event.manaCost or 2,
                    tags = { DEFENSE = true, SHIELD = true },
                    rangeBand = caster.gameState.rangeState,
                    elevation = targetWizard.elevation,
                    duration = event.duration or 3.0
                }

                handleEvent(effectEvent, caster, target, spellSlot, results)
            end

            return true
        end
    }
end

return DefenseHandlers
