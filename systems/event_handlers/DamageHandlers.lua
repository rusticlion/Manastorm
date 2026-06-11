-- systems/event_handlers/DamageHandlers.lua
-- Damage and blocked-damage event handlers for EventRunner.

local DamageHandlers = {}

local function getEffectOverride(caster, spellSlot)
    local slot = spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] or nil
    local spell = slot and slot.spell or nil
    return spell and spell.effectOverride or nil
end

local function applyDamage(targetWizard, amount)
    targetWizard.health = targetWizard.health - amount

    if targetWizard.health < 0 then
        targetWizard.health = 0
    end

    if targetWizard.health <= 0 and targetWizard.gameState then
        targetWizard.gameState.gameOver = true

        if targetWizard.gameState.wizards then
            for index, wizard in ipairs(targetWizard.gameState.wizards) do
                if wizard == targetWizard then
                    targetWizard.gameState.winner = 3 - index
                    break
                end
            end
        end
    end
end

local function triggerDamageFeedback(Log, targetWizard, amount, tags)
    targetWizard.hitFlashTimer = 0.125

    if not targetWizard.gameState or not targetWizard.gameState.triggerShake then
        return
    end

    if amount >= 15 or (tags and tags.HIGH_IMPACT) then
        local intensity = math.min(10, 5 + (amount / 10))
        targetWizard.gameState.triggerShake(0.35, intensity)
        targetWizard.gameState.triggerHitstop(0.12)
        Log.debug(string.format("[DAMAGE EVENT] High impact hit! Triggering shake (%.2f, %.2f) and hitstop (%.2f)",
            0.35, intensity, 0.12))
    elseif amount >= 8 then
        targetWizard.gameState.triggerShake(0.25, 6)
        targetWizard.gameState.triggerHitstop(0.08)
        Log.debug(string.format("[DAMAGE EVENT] Medium impact hit! Triggering shake (%.2f, %.2f) and hitstop (%.2f)",
            0.25, 6, 0.08))
    elseif amount >= 3 then
        targetWizard.gameState.triggerShake(0.15, 4)
        Log.debug(string.format("[DAMAGE EVENT] Light impact hit! Triggering shake (%.2f, %.2f)",
            0.15, 4))
    end
end

local function logEventDetails(Log, prefix, event)
    Log.debug(prefix)
    for k, v in pairs(event) do
        if type(v) == "table" then
            Log.debug("  " .. k .. ": [table]")
        else
            Log.debug("  " .. k .. ": " .. tostring(v))
        end
    end
end

local function buildDamageEffectEvent(event, caster, spellSlot, targetWizard, delayDamage)
    local effectEvent = {
        type = "EFFECT",
        source = "caster",
        target = event.target,
        effectOverride = getEffectOverride(caster, spellSlot),

        affinity = event.affinity,
        attackType = event.attackType,
        damageType = event.damageType,
        manaCost = event.manaCost,
        tags = event.tags or { DAMAGE = true },
        rangeBand = event.rangeBand,
        elevation = event.elevation,
        visualShape = event.visualShape,

        delayedDamage = delayDamage and event.amount or nil,
        delayedDamageTarget = delayDamage and targetWizard or nil,

        blockInfo = event.blockInfo
    }

    if event.blockInfo and event.blockInfo.blockable then
        effectEvent.tags = effectEvent.tags or {}
        effectEvent.tags.SHIELD_BLOCKED = true
        effectEvent.blockPoint = event.blockInfo.blockPoint or 0.75
    end

    return effectEvent
end

local function buildBlockedDamageEffectEvent(event, caster, spellSlot)
    return {
        type = "EFFECT",
        source = "caster",
        target = event.target,
        effectOverride = getEffectOverride(caster, spellSlot),

        affinity = event.affinity,
        attackType = event.attackType or "projectile",
        damageType = event.damageType,
        manaCost = event.manaCost,
        tags = event.tags or { DAMAGE = true, SHIELD_BLOCKED = true },
        rangeBand = event.rangeBand,
        elevation = event.elevation,
        visualShape = event.visualShape or "bolt",

        blockInfo = event.blockInfo,
        blockPoint = event.blockPoint or 0.75,
        onComplete = (event.blockInfo and event.blockInfo.onBlockImpact) or event.onBlockImpact or nil,

        amount = event.amount or 10
    }
end

function DamageHandlers.build(deps)
    local Log = deps.Log
    local handleEvent = deps.handleEvent
    local resolveTarget = deps.resolveTarget

    return {
        DAMAGE = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)

            if not targetInfo or not targetInfo.wizard then
                print("ERROR: DAMAGE handler could not resolve target wizard")
                return false
            end

            local targetWizard = targetInfo.wizard
            local delayDamage = event.delayDamage or false

            if not delayDamage then
                applyDamage(targetWizard, event.amount)
                triggerDamageFeedback(Log, targetWizard, event.amount, event.tags)

                Log.debug(string.format("[DAMAGE EVENT] Applied %d damage to %s. New health: %d",
                    event.amount, targetWizard.name, targetWizard.health))
            else
                Log.debug(string.format("[DAMAGE EVENT] Delaying %d damage to %s for visual sync",
                    event.amount, targetWizard.name))
            end

            Log.debug(string.format("[DAMAGE EVENT] Visual metadata: affinity=%s, attackType=%s, damageType=%s, manaCost=%s",
                tostring(event.affinity),
                tostring(event.attackType),
                tostring(event.damageType),
                tostring(event.manaCost)))
            Log.debug(string.format("[DAMAGE EVENT] More metadata: tags=%s, rangeBand=%s, elevation=%s",
                event.tags and "present" or "nil",
                tostring(event.rangeBand),
                tostring(event.elevation)))

            results.damageDealt = results.damageDealt + event.amount

            if not event.suppressVisual then
                local effectEvent = buildDamageEffectEvent(event, caster, spellSlot, targetWizard, delayDamage)

                if event.blockInfo and event.blockInfo.blockable then
                    Log.debug("[DAMAGE->EFFECT] Passing blockInfo to EFFECT event for shield block visuals")
                end

                Log.debug(string.format("[DAMAGE->EFFECT] Generated EFFECT event with effectOverride=%s",
                    tostring(effectEvent.effectOverride)))
                Log.debug(string.format("[DAMAGE->EFFECT] Transferred metadata: affinity=%s, attackType=%s, damageType=%s",
                    tostring(effectEvent.affinity),
                    tostring(effectEvent.attackType),
                    tostring(effectEvent.damageType)))
                Log.debug(string.format("[DAMAGE->EFFECT] More metadata: tags=%s, rangeBand=%s, elevation=%s",
                    effectEvent.tags and "present" or "nil",
                    tostring(effectEvent.rangeBand),
                    tostring(effectEvent.elevation)))

                handleEvent(effectEvent, caster, target, spellSlot, results)
            end

            return true
        end,

        BLOCKED_DAMAGE = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)

            if not targetInfo or not targetInfo.wizard then
                print("ERROR: BLOCKED_DAMAGE handler could not resolve target wizard")
                return false
            end

            local targetWizard = targetInfo.wizard

            Log.debug(string.format("[BLOCKED_DAMAGE] %s's spell blocked by shield! No damage applied to %s (would have been %d)",
                caster.name, targetWizard.name, event.amount or 0))

            results.damageBlocked = (results.damageBlocked or 0) + (event.amount or 0)

            logEventDetails(Log, "[BLOCKED_DAMAGE] Full event details:", event)

            if not event.blockInfo then
                print("[BLOCKED_DAMAGE] WARNING: Missing blockInfo in BLOCKED_DAMAGE event!")
                event.blockInfo = {
                    blockable = true,
                    blockType = event.shieldType or "ward",
                    blockPoint = event.blockPoint or 0.75
                }
            end

            local effectEvent = buildBlockedDamageEffectEvent(event, caster, spellSlot)

            Log.debug(string.format("[BLOCKED_DAMAGE->EFFECT] Generated EFFECT event with blockPoint=%.2f",
                effectEvent.blockPoint))
            logEventDetails(Log, "[BLOCKED_DAMAGE->EFFECT] Full effectEvent details:", effectEvent)

            local success, err = pcall(function()
                handleEvent(effectEvent, caster, target, spellSlot, results)
            end)

            if not success then
                print("[BLOCKED_DAMAGE->EFFECT] ERROR: Failed to process effect event: " .. tostring(err))
            end

            return true
        end
    }
end

return DamageHandlers
