-- systems/event_handlers/PositionHandlers.lua
-- Position and elevation event handlers for EventRunner.

local PositionHandlers = {}

function PositionHandlers.build(deps)
    local Constants = deps.Constants
    local emitEffectEvent = deps.emitEffectEvent
    local queueDeferredEventBatch = deps.queueDeferredEventBatch
    local resolveTarget = deps.resolveTarget

    return {
        SET_ELEVATION = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                print("ERROR: SET_ELEVATION handler could not resolve target wizard")
                return false
            end
            local targetWizard = targetInfo.wizard

            targetWizard.elevation = event.elevation

            if event.duration then
                targetWizard.elevationEffects = targetWizard.elevationEffects or {}
                targetWizard.elevationEffects[event.elevation] = {
                    duration = event.duration,
                    revertElevation = event.revertElevation or Constants.ElevationState.GROUNDED,
                    affinity = event.affinity,
                    manaCost = event.manaCost,
                    visualShape = event.visualShape
                }
            end

            if caster.gameState and caster.gameState.vfx then
                emitEffectEvent({
                    type = "EFFECT",
                    source = "caster",
                    target = event.target,
                    effectOverride = (event.vfx and type(event.vfx) == "string") and event.vfx or nil,
                    affinity = event.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = event.manaCost or 1,
                    tags = { MOVEMENT = true, [event.elevation == Constants.ElevationState.AERIAL and "ELEVATE" or "GROUND"] = true },
                    rangeBand = caster.gameState.rangeState,
                    elevation = event.elevation,
                    visualShape = event.visualShape,
                    duration = 1.0
                }, caster, target, spellSlot, results)
            end

            if event.elevation == Constants.ElevationState.AERIAL then
                queueDeferredEventBatch(results, {
                    {
                        type = "NOTIFY_TRAP_TRIGGER",
                        source = event.source or "caster",
                        target = event.target,
                        triggerCondition = "on_opponent_elevate"
                    }
                }, caster, target, spellSlot)
            end

            return true
        end
    }
end

return PositionHandlers
