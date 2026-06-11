-- systems/event_handlers/StatusHandlers.lua
-- Status application and removal handlers for EventRunner.

local StatusHandlers = {}

local function copyTags(tags)
    if type(tags) ~= "table" then
        return nil
    end

    local cloned = {}
    for key, value in pairs(tags) do
        cloned[key] = value
    end

    return cloned
end

local function buildStatusEffectVisualEvent(Constants, event, targetWizard)
    local tags = copyTags(event.tags) or {}
    local effectOverride = Constants.VFXType.UTIL_BASE

    if event.statusType == Constants.StatusType.BURN then
        effectOverride = Constants.VFXType.EMBER_OVERLAY
        tags.BURN = true
        if event.tickDamage or (event.duration or 0) > 0 then
            tags.DOT = true
        end
    elseif event.statusType == Constants.StatusType.REFLECT then
        effectOverride = Constants.VFXType.SHIELD_OVERLAY
        tags.SHIELD = true
    end

    if next(tags) == nil then
        tags = nil
    end

    return {
        type = "EFFECT",
        source = event.source or "caster",
        target = event.target,
        effectOverride = effectOverride,
        affinity = event.affinity,
        attackType = event.attackType or Constants.AttackType.UTILITY,
        manaCost = event.manaCost or 1,
        tags = tags,
        rangeBand = targetWizard and targetWizard.gameState and targetWizard.gameState.rangeState or nil,
        elevation = targetWizard and targetWizard.elevation or nil,
        visualShape = event.visualShape,
        duration = math.min(event.duration or 0.8, 1.0),
        statusType = event.statusType
    }
end

local function resetStatusEffect(effectData)
    if not effectData then
        return
    end

    effectData.active = false
    effectData.duration = 0
    effectData.elapsed = 0
    effectData.totalTime = 0
    effectData.tickDamage = nil
    effectData.tickInterval = nil
    effectData.magnitude = nil
    effectData.targetSlot = nil
end

function StatusHandlers.build(deps)
    local Constants = deps.Constants
    local Log = deps.Log
    local emitEffectEvent = deps.emitEffectEvent
    local resolveTarget = deps.resolveTarget

    return {
        APPLY_STATUS = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: APPLY_STATUS handler could not resolve target wizard")
                return false
            end
            local targetWizard = targetInfo.wizard

            targetWizard.statusEffects = targetWizard.statusEffects or {}

            local effectData = {
                active = true,
                duration = event.duration or 0,
                tickDamage = event.tickDamage,
                tickInterval = event.tickInterval,
                magnitude = event.magnitude,
                targetSlot = event.targetSlot,
                elapsed = 0,
                totalTime = 0,
                source = caster,
                affinity = event.affinity,
                attackType = event.attackType,
                visualShape = event.visualShape,
                manaCost = event.manaCost,
                tags = event.tags,
                damageType = event.damageType or event.affinity
            }

            if event.statusType == Constants.StatusType.STUN then
                targetWizard.statusEffects[Constants.StatusType.STUN] = effectData
            else
                targetWizard.statusEffects[event.statusType] = effectData
            end

            Log.debug(string.format("[STATUS] Applied %s to %s (Duration: %.1f, Magnitude: %s, Slot: %s)",
                event.statusType, targetWizard.name, event.duration or 0, tostring(event.magnitude), tostring(event.targetSlot)))

            results.statusEffectsApplied = results.statusEffectsApplied or {}
            table.insert(results.statusEffectsApplied, event.statusType)

            emitEffectEvent(
                buildStatusEffectVisualEvent(Constants, event, targetWizard),
                caster,
                target,
                spellSlot,
                results
            )

            return true
        end,

        REMOVE_STATUS = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: REMOVE_STATUS handler could not resolve target wizard")
                return false
            end

            local targetWizard = targetInfo.wizard
            if not targetWizard.statusEffects or not targetWizard.statusEffects[event.statusType] then
                return false
            end

            resetStatusEffect(targetWizard.statusEffects[event.statusType])
            results.statusEffectsRemoved = results.statusEffectsRemoved or {}
            table.insert(results.statusEffectsRemoved, event.statusType)

            Log.debug(string.format("[STATUS] Removed %s from %s", event.statusType, targetWizard.name))

            return true
        end
    }
end

return StatusHandlers
