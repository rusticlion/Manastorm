-- systems/event_handlers/SustainedTrapHandlers.lua
-- Sustained spell and trap event handlers for EventRunner.

local SustainedTrapHandlers = {}

function SustainedTrapHandlers.build(deps)
    local Constants = deps.Constants
    local Log = deps.Log
    local buildKeywordPayloadEvents = deps.buildKeywordPayloadEvents
    local handleEvent = deps.handleEvent
    local mergeProcessResults = deps.mergeProcessResults
    local processEvents = deps.processEvents
    local resolveTarget = deps.resolveTarget

    return {
        REGISTER_SUSTAINED = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: REGISTER_SUSTAINED handler could not resolve target wizard")
                return false
            end

            local wizard = targetInfo.wizard
            local slotIndex = targetInfo.slotIndex or event.slotIndex or spellSlot
            local slot = wizard.spellSlots and wizard.spellSlots[slotIndex] or nil
            if not slot or not slot.active then
                print(string.format("WARNING: REGISTER_SUSTAINED received invalid or inactive slot %s for %s", tostring(slotIndex), wizard.name or "wizard"))
                return false
            end

            if slot.isShield then
                return false
            end

            if slot.sustainedId then
                results.sustainedRegistered = true
                results.sustainedId = slot.sustainedId
                return true
            end

            local gameState = wizard.gameState
            local manager = gameState and gameState.sustainedSpellManager or nil
            if not manager or type(manager.addSustainedSpell) ~= "function" then
                print("[SUSTAINED ERROR] Cannot register sustained spell without sustainedSpellManager")
                return false
            end

            local sustainData = event.sustainData or {}
            local sustainedId = manager.addSustainedSpell(wizard, slotIndex, {
                isSustained = true,
                trapTrigger = sustainData.trapTrigger,
                trapEffect = sustainData.trapEffect,
                fieldStatus = sustainData.fieldStatus
            })

            if not sustainedId then
                return false
            end

            slot.sustainedId = sustainedId
            results.sustainedRegistered = true
            results.sustainedId = sustainedId

            return true
        end,

        CAST_COMPLETE = function(event, caster, target, spellSlot, results)
            return handleEvent({
                type = "NOTIFY_TRAP_TRIGGER",
                source = event.source or "caster",
                target = event.target or Constants.TargetType.SELF,
                triggerCondition = "on_opponent_cast",
                spellId = event.spellId,
                spell = event.spell,
                blocked = event.blocked,
                isShield = event.isShield,
                isSustained = event.isSustained
            }, caster, target, event.slotIndex or spellSlot, results)
        end,

        NOTIFY_TRAP_TRIGGER = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: NOTIFY_TRAP_TRIGGER handler could not resolve target wizard")
                return false
            end

            local subjectWizard = targetInfo.wizard
            local gameState = (caster and caster.gameState) or (subjectWizard and subjectWizard.gameState) or nil
            local manager = gameState and gameState.sustainedSpellManager or nil
            if not manager or type(manager.notifyTrapTrigger) ~= "function" then
                return false
            end

            manager.notifyTrapTrigger(event.triggerCondition, subjectWizard, event)
            return true
        end,

        TRIGGER_TRAP = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: TRIGGER_TRAP handler could not resolve target wizard")
                return false
            end

            local targetWizard = targetInfo.wizard
            local slotIndex = event.slotIndex or spellSlot
            if not slotIndex then
                print("ERROR: TRIGGER_TRAP missing slot context")
                return false
            end

            local trapSpell = event.trapSpell
            local trapName = trapSpell and trapSpell.name or "unnamed trap"
            Log.debug(string.format("[TRAP] Resolving %s for %s slot %d", trapName, caster.name or "caster", slotIndex))

            local trapEvents, err = buildKeywordPayloadEvents(
                event.trapEffect or {},
                caster,
                targetWizard,
                slotIndex,
                trapSpell
            )
            if not trapEvents then
                print("[TRAP] ERROR: Failed to build trap events: " .. tostring(err))
                return false
            end

            if event.cleanupSlot ~= false then
                table.insert(trapEvents, {
                    type = "CLEANUP_SLOT",
                    source = "caster",
                    target = Constants.TargetType.SLOT_SELF,
                    slotIndex = slotIndex,
                    returnTokens = true,
                    resetSlot = true,
                    cleanupReason = event.cleanupReason or "trap_triggered"
                })
            end

            if #trapEvents == 0 then
                print("[TRAP] WARNING: No events generated for trap payload")
            end

            local nestedResults = processEvents(trapEvents, caster, targetWizard, slotIndex)
            mergeProcessResults(results, nestedResults)
            results.trapsTriggered = (results.trapsTriggered or 0) + 1

            return true
        end
    }
end

return SustainedTrapHandlers
