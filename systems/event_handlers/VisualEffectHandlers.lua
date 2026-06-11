-- systems/event_handlers/VisualEffectHandlers.lua
-- Visual EFFECT event handler for EventRunner.

local VisualResolver = require("systems.VisualResolver")

local VisualEffectHandlers = {}

function VisualEffectHandlers.build(deps)
    local Constants = deps.Constants
    local Log = deps.Log
    local processEvents = deps.processEvents
    local resolveTarget = deps.resolveTarget

    return {
        EFFECT = function(event, caster, target, spellSlot, results)
            Log.debug("[EFFECT EVENT] Processing EFFECT event")

            Log.debug("[EFFECT EVENT] Full event details:")
            Log.debug(string.format("  effectOverride=%s", tostring(event.effectOverride)))
            Log.debug(string.format("  effectType=%s", tostring(event.effectType)))
            Log.debug(string.format("  affinity=%s, attackType=%s, damageType=%s",
                tostring(event.affinity),
                tostring(event.attackType),
                tostring(event.damageType)))
            Log.debug(string.format("  source=%s, target=%s",
                tostring(event.source),
                tostring(event.target)))

            if spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] and
               caster.spellSlots[spellSlot].spell then
                local spell = caster.spellSlots[spellSlot].spell
                Log.debug(string.format("[EFFECT EVENT] Associated spell: name=%s, effectOverride=%s",
                    tostring(spell.name), tostring(spell.effectOverride)))
            end

            local srcX, srcY, tgtX, tgtY = nil, nil, nil, nil

            if event.vfxParams and event.vfxParams.x and event.vfxParams.y then
                srcX = event.vfxParams.x
                srcY = event.vfxParams.y
                tgtX = event.vfxParams.targetX or srcX
                tgtY = event.vfxParams.targetY or srcY
                Log.debug(string.format("[EFFECT EVENT] Using direct coordinates from vfxParams: (%d, %d) -> (%d, %d)",
                    srcX, srcY, tgtX, tgtY))
            else
                srcX = caster and caster.x or 0
                srcY = caster and caster.y or 0

                local targetsAll = event.target == Constants.TargetType.ALL
                    or (type(event.target) == "string" and string.lower(event.target) == "both")

                if targetsAll and target and target.x and target.y then
                    tgtX = target.x
                    tgtY = target.y
                    Log.debug(string.format("[EFFECT EVENT] Using all-target coordinates: (%d, %d) -> (%d, %d)",
                        srcX, srcY, tgtX, tgtY))
                else
                    local targetInfo = resolveTarget(event, caster, target)
                    if targetInfo and targetInfo.wizard then
                        local targetWizard = targetInfo.wizard
                        tgtX = targetWizard.x
                        tgtY = targetWizard.y
                        Log.debug(string.format("[EFFECT EVENT] Using wizard coordinates: (%d, %d) -> (%d, %d)",
                            srcX, srcY, tgtX or srcX, tgtY or srcY))
                    else
                        tgtX = srcX
                        tgtY = srcY
                        Log.debug("[EFFECT EVENT] WARNING: Could not resolve target coordinates, using source as target")
                    end
                end
            end

            local overrideName = nil

            if event.effectOverride then
                overrideName = event.effectOverride
                Log.debug("[EFFECT EVENT] Using event effectOverride: " .. tostring(overrideName))
            elseif event.effectType then
                overrideName = event.effectType
                Log.debug("[EFFECT EVENT] Using event effectType: " .. tostring(overrideName))
            elseif spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] and
                   caster.spellSlots[spellSlot].spell and caster.spellSlots[spellSlot].spell.effectOverride then
                overrideName = caster.spellSlots[spellSlot].spell.effectOverride
                Log.debug("[EFFECT EVENT] Using spell effectOverride: " .. tostring(overrideName))
            end

            if caster.gameState and caster.gameState.vfx then
                local baseEffectName, vfxOpts

                Log.debug("[EFFECT EVENT] About to call VisualResolver.pick()")
                Log.debug("[EFFECT EVENT] Override strategy: " .. (overrideName and "Using override: " .. tostring(overrideName) or "Using metadata resolution"))

                if overrideName then
                    event.effectOverride = overrideName
                    Log.debug("[EFFECT EVENT] Set event.effectOverride = " .. tostring(overrideName))
                    baseEffectName, vfxOpts = VisualResolver.pick(event)
                else
                    baseEffectName, vfxOpts = VisualResolver.pick(event)
                end

                Log.debug(string.format("[EFFECT EVENT] VisualResolver.pick() returned: effectName=%s, options=%s",
                    tostring(baseEffectName),
                    vfxOpts and "present" or "nil"))

                if not baseEffectName then
                    Log.debug("[EFFECT EVENT] Warning: No valid effect name provided by VisualResolver")
                    return false
                end

                if not vfxOpts then vfxOpts = {} end

                if caster and caster.name then
                    vfxOpts.source = caster.name
                    vfxOpts.sourceEntity = caster

                    if spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] and
                       caster.spellSlots[spellSlot].spell and caster.spellSlots[spellSlot].spell.visualShape then
                        vfxOpts.visualShape = caster.spellSlots[spellSlot].spell.visualShape
                    end

                    vfxOpts.amount = event.amount or vfxOpts.amount or 10

                    Log.debug(string.format("[EFFECT EVENT] Setting sourceEntity = %s", tostring(caster)))
                end
                if target and target.name then
                    vfxOpts.target = target.name
                    vfxOpts.targetEntity = target
                    Log.debug(string.format("[EFFECT EVENT] Setting targetEntity = %s", tostring(target)))
                end

                if event.tags and event.tags.SHIELD_BLOCKED then
                    Log.debug("[EFFECT EVENT] This is a SHIELD_BLOCKED event")
                    vfxOpts.gameState = caster.gameState
                end

                if event.tags and event.tags.SHIELD_BLOCKED then
                    Log.debug("[EFFECT EVENT] Processing shield blocked effect")

                    if event.blockInfo then
                        vfxOpts.blockInfo = event.blockInfo
                        vfxOpts.blockPoint = event.blockPoint or 0.75

                        if event.blockInfo.blockType then
                            vfxOpts.shieldType = event.blockInfo.blockType
                        end

                        Log.debug("[EFFECT EVENT] Shield block visual at " .. tostring(vfxOpts.blockPoint))
                    else
                        Log.debug("[EFFECT EVENT] WARNING: SHIELD_BLOCKED tag but no blockInfo, creating default blockInfo")
                        vfxOpts.blockInfo = {
                            blockable = true,
                            blockType = event.shieldType or "ward",
                            blockPoint = event.blockPoint or 0.75
                        }
                        vfxOpts.blockPoint = event.blockPoint or 0.75
                        vfxOpts.shieldType = event.shieldType or "ward"

                        vfxOpts.tags = vfxOpts.tags or {}
                        vfxOpts.tags.SHIELD_BLOCKED = true

                        Log.debug("[EFFECT EVENT] Created fallback shield block visual at " .. tostring(vfxOpts.blockPoint))
                    end
                elseif event.blockInfo then
                    Log.debug("[EFFECT EVENT] Found blockInfo in event, passing to VFX system")
                    vfxOpts.blockInfo = event.blockInfo
                    vfxOpts.blockPoint = event.blockInfo.blockPoint or 0.75

                    if event.blockInfo.blockType then
                        vfxOpts.shieldType = event.blockInfo.blockType
                    end

                    vfxOpts.tags = vfxOpts.tags or {}
                    vfxOpts.tags.SHIELD_BLOCKED = true
                end

                if event.onComplete then
                    vfxOpts.onComplete = event.onComplete
                elseif event.blockInfo and event.blockInfo.onBlockImpact then
                    vfxOpts.onComplete = event.blockInfo.onBlockImpact
                end

                if not vfxOpts.duration then
                    vfxOpts.duration = event.duration or 0.5
                end

                if event.delayedDamage and event.delayedDamageTarget then
                    Log.debug(string.format("[EFFECT EVENT] Adding delayed damage %d to effect options", event.delayedDamage))
                    vfxOpts.delayedDamage = event.delayedDamage
                    vfxOpts.delayedDamageTarget = event.delayedDamageTarget
                    local priorOnComplete = vfxOpts.onComplete

                    vfxOpts.onComplete = function(effect)
                        if priorOnComplete then
                            local priorOk, priorErr = pcall(function()
                                priorOnComplete(effect)
                            end)
                            if not priorOk then
                                Log.debug("[EFFECT EVENT] WARNING: prior onComplete callback failed: " .. tostring(priorErr))
                            end
                        end

                        local damageTarget = vfxOpts.delayedDamageTarget
                        local amount = vfxOpts.delayedDamage

                        if damageTarget and amount then
                            local delayedDamageEvent = {
                                type = "DAMAGE",
                                source = event.source or "caster",
                                target = event.target or Constants.TargetType.ENEMY,
                                amount = amount,
                                damageType = event.damageType,
                                affinity = event.affinity,
                                attackType = event.attackType,
                                manaCost = event.manaCost,
                                tags = event.tags,
                                rangeBand = event.rangeBand,
                                elevation = event.elevation,
                                visualShape = event.visualShape,
                                delayDamage = false,
                                suppressVisual = true
                            }

                            processEvents({ delayedDamageEvent }, caster, damageTarget, spellSlot)

                            Log.debug(string.format("[DELAYED DAMAGE] Routed %d delayed damage back through EventRunner",
                                amount))
                        end
                    end
                end

                Log.debug(string.format("[EFFECT EVENT] Creating effect: '%s' at coords: (%d, %d) -> (%d, %d)",
                    tostring(baseEffectName), srcX or 0, srcY or 0, tgtX or srcX, tgtY or srcY))

                local vfxModule = caster.gameState.vfx
                if vfxModule and vfxModule.createEffect then
                    local success, err = pcall(function()
                        vfxModule.createEffect(baseEffectName, srcX, srcY, tgtX, tgtY, vfxOpts)
                    end)

                    if not success then
                        print("ERROR: Failed to create effect: " .. tostring(err))
                        return false
                    end
                else
                    Log.debug("[EFFECT EVENT] ERROR: VFX.createEffect not available")
                    return false
                end
            else
                Log.debug("[EFFECT EVENT] ERROR: VFX system not available")
                return false
            end

            return true
        end
    }
end

return VisualEffectHandlers
