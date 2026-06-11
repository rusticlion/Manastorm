-- systems/event_handlers/SpellTimelineHandlers.lua
-- Spell timing and slot lifecycle event handlers for EventRunner.

local SpellTimelineHandlers = {}

function SpellTimelineHandlers.build(deps)
    local Constants = deps.Constants
    local clearBlockedImpactState = deps.clearBlockedImpactState
    local emitEffectEvent = deps.emitEffectEvent
    local getSlotVisualContext = deps.getSlotVisualContext
    local resolveTarget = deps.resolveTarget

    return {
        ACCELERATE_SPELL = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then return false end

            local wizard = targetInfo.wizard
            local slotIndex = targetInfo.slotIndex
            if not slotIndex or slotIndex == 0 then
                slotIndex = spellSlot
            end

            local slot = wizard.spellSlots[slotIndex]
            if slot and slot.active and not slot.isShield then
                slot.progress = slot.progress + event.amount

                local visualContext = getSlotVisualContext(wizard, slotIndex)
                emitEffectEvent({
                    type = "EFFECT",
                    source = event.source or "caster",
                    target = event.target,
                    effectOverride = Constants.VFXType.SURGE_BASE,
                    affinity = event.affinity or visualContext.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = visualContext.manaCost or 1,
                    rangeBand = wizard.gameState and wizard.gameState.rangeState or nil,
                    elevation = wizard.elevation,
                    duration = 1.0,
                    amount = event.amount,
                    slotIndex = slotIndex,
                    vfxParams = {
                        x = wizard.x,
                        y = wizard.y
                    }
                }, caster, wizard, slotIndex, results)

                return true
            end

            return false
        end,

        CANCEL_SPELL = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then return false end

            local wizard = targetInfo.wizard
            local slotIndex = targetInfo.slotIndex

            if not slotIndex or slotIndex == 0 then
                local activeSlots = {}
                for i, slot in ipairs(wizard.spellSlots) do
                    if slot.active and not slot.isShield then
                        table.insert(activeSlots, i)
                    end
                end

                if #activeSlots > 0 then
                    slotIndex = activeSlots[math.random(#activeSlots)]
                else
                    return false
                end
            end

            local slot = wizard.spellSlots[slotIndex]
            if slot and slot.active and not slot.isShield then
                local visualContext = getSlotVisualContext(wizard, slotIndex)

                if event.returnMana then
                    for _, tokenData in ipairs(slot.tokens) do
                        if tokenData.token then
                            tokenData.token:requestReturnAnimation()
                        end
                    end
                else
                    for _, tokenData in ipairs(slot.tokens) do
                        if tokenData.token then
                            tokenData.token:requestDestructionAnimation()
                        end
                    end
                end

                wizard:resetSpellSlot(slotIndex)

                emitEffectEvent({
                    type = "EFFECT",
                    source = event.source or "caster",
                    target = event.target,
                    effectOverride = event.returnMana and Constants.VFXType.FREE_MANA or Constants.VFXType.WARP_BASE,
                    affinity = event.affinity or visualContext.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = visualContext.manaCost or 1,
                    tags = event.returnMana and { RESOURCE = true } or nil,
                    rangeBand = wizard.gameState and wizard.gameState.rangeState or nil,
                    elevation = wizard.elevation,
                    visualShape = visualContext.visualShape,
                    duration = 1.0,
                    returnMana = event.returnMana,
                    slotIndex = slotIndex,
                    vfxParams = {
                        x = wizard.x,
                        y = wizard.y
                    }
                }, caster, wizard, slotIndex, results)

                return true
            end

            return false
        end,

        FREEZE_SPELL = function(event, caster, target, spellSlot, results)
            local resolvedTarget = resolveTarget(event, caster, target)
            local wizardToFreeze = nil
            local slotIndexToFreeze = event.slotIndex or 3

            if not resolvedTarget then
                print("ERROR: FREEZE_SPELL target resolution failed.")
                return false
            end

            if type(resolvedTarget) == "table" then
                if resolvedTarget.wizard then
                    wizardToFreeze = resolvedTarget.wizard
                    slotIndexToFreeze = resolvedTarget.slotIndex or slotIndexToFreeze
                elseif resolvedTarget.name then
                    wizardToFreeze = resolvedTarget
                else
                    print("ERROR: FREEZE_SPELL resolved target is an unexpected table type.")
                    return false
                end
            else
                print("ERROR: FREEZE_SPELL resolved target is not a table (wizard or slot table expected).")
                return false
            end

            if not wizardToFreeze then
                print("ERROR: FREEZE_SPELL could not determine target wizard.")
                return false
            end

            if not slotIndexToFreeze or slotIndexToFreeze == 0 then
                slotIndexToFreeze = 2

                if not wizardToFreeze.spellSlots[slotIndexToFreeze] or not wizardToFreeze.spellSlots[slotIndexToFreeze].active or wizardToFreeze.spellSlots[slotIndexToFreeze].isShield then
                    local activeSlots = {}
                    for i, slotData in ipairs(wizardToFreeze.spellSlots) do
                        if slotData.active and not slotData.isShield then
                            table.insert(activeSlots, i)
                        end
                    end

                    if #activeSlots > 0 then
                        slotIndexToFreeze = activeSlots[math.random(#activeSlots)]
                    else
                        return false
                    end
                end
            end

            local slot = wizardToFreeze.spellSlots[slotIndexToFreeze]
            if slot and slot.active and not slot.isShield then
                slot.frozen = true
                slot.freezeTimer = event.duration

                local visualContext = getSlotVisualContext(wizardToFreeze, slotIndexToFreeze)
                emitEffectEvent({
                    type = "EFFECT",
                    source = event.source or "caster",
                    target = event.target,
                    effectOverride = Constants.VFXType.WARP_BASE,
                    affinity = event.affinity or visualContext.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = visualContext.manaCost or 1,
                    rangeBand = wizardToFreeze.gameState and wizardToFreeze.gameState.rangeState or nil,
                    elevation = wizardToFreeze.elevation,
                    visualShape = visualContext.visualShape,
                    duration = event.duration,
                    slotIndex = slotIndexToFreeze,
                    vfxParams = {
                        x = wizardToFreeze.x,
                        y = wizardToFreeze.y
                    }
                }, caster, wizardToFreeze, slotIndexToFreeze, results)

                results.freezeApplied = true
                results.frozenSlot = slotIndexToFreeze
                results.freezeDuration = event.duration
                return true
            end

            return false
        end,

        CLEANUP_SLOT = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: CLEANUP_SLOT handler could not resolve target wizard")
                return false
            end

            local wizard = targetInfo.wizard
            local slotIndex = targetInfo.slotIndex or event.slotIndex or spellSlot
            local slot = wizard.spellSlots and wizard.spellSlots[slotIndex] or nil
            if not slot then
                print(string.format("WARNING: CLEANUP_SLOT received invalid slot %s for %s", tostring(slotIndex), wizard.name or "wizard"))
                return false
            end

            if event.requireBlockedPendingImpact and not slot.blockedPendingImpact then
                return false
            end

            local TokenManager = require("systems.TokenManager")
            local tokens = slot.tokens or {}
            local tokenCount = #tokens

            if event.returnTokens and tokenCount > 0 then
                TokenManager.returnTokensToPool(tokens)
                results.tokensAffected = (results.tokensAffected or 0) + tokenCount
            elseif event.destroyTokens and tokenCount > 0 then
                TokenManager.destroyTokens(tokens)
                results.tokensAffected = (results.tokensAffected or 0) + tokenCount
            end

            if event.clearBlockedPendingImpact then
                clearBlockedImpactState(slot)
            end

            if event.resetSlot then
                wizard:resetSpellSlot(slotIndex)
            elseif event.clearTokens then
                slot.tokens = {}
            end

            results.slotsCleaned = (results.slotsCleaned or 0) + 1

            return true
        end
    }
end

return SpellTimelineHandlers
