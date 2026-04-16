-- systems/event_handlers/RangeHandlers.lua
-- Range and forced-position event handlers for EventRunner.

local RangeHandlers = {}

function RangeHandlers.build(deps)
    local Constants = deps.Constants
    local emitEffectEvent = deps.emitEffectEvent
    local queueDeferredEventBatch = deps.queueDeferredEventBatch

    return {
        SET_RANGE = function(event, caster, target, spellSlot, results)
            -- Update game state with new range
            if caster.gameState then
                -- Store the new range state
                caster.gameState.rangeState = event.position

                -- No need to call any extra position animation functions - the wizards'
                -- positionAnimation state is automatically detected and updated in
                -- WizardVisuals.drawWizard when it sees the range state has changed
            end

            -- Create range change VFX if available
            if caster.gameState and caster.gameState.vfx then
                -- Generate an EFFECT event for consistent handling through VisualResolver
                local effectEvent = {
                    type = "EFFECT",
                    source = "caster",
                    target = Constants.TargetType.ALL, -- Range changes affect both wizards
                    effectOverride = Constants.VFXType.RANGE_CHANGE, -- Use explicit override for this special effect
                    -- Provide relevant metadata for the resolver
                    affinity = event.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = 1,
                    tags = { MOVEMENT = true },
                    rangeBand = event.position, -- The new range state
                    elevation = caster.elevation,
                    visualShape = event.visualShape, -- Preserve visualShape if specified
                    duration = 1.0,
                    -- Extra params specific to range changes
                    position = event.position
                }

                -- Process the effect event through the standard pipeline
                emitEffectEvent(effectEvent, caster, target, spellSlot, results)
            end

            if event.position == Constants.RangeState.FAR then
                queueDeferredEventBatch(results, {
                    {
                        type = "NOTIFY_TRAP_TRIGGER",
                        source = event.source or "caster",
                        target = Constants.TargetType.SELF,
                        triggerCondition = "on_opponent_far"
                    }
                }, caster, target, spellSlot)
            end

            return true
        end,

        FORCE_POSITION = function(event, caster, target, spellSlot, results)
            -- Force opponent to match caster's range
            -- Range is stored in game state, not on individual wizards
            if caster.gameState then
                -- Just a shortcut to quickly force range change - could be expanded if needed
                caster.gameState.rangeState = caster.gameState.rangeState

                emitEffectEvent({
                    type = "EFFECT",
                    source = event.source or "caster",
                    target = event.target,
                    effectOverride = Constants.VFXType.WARP_BASE,
                    affinity = event.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = event.manaCost or 1,
                    rangeBand = caster.gameState.rangeState,
                    elevation = caster.elevation,
                    duration = 1.0,
                    sourceName = caster.name,
                    targetName = target.name,
                    vfxParams = {
                        x = (caster.x + target.x) / 2,
                        y = (caster.y + target.y) / 2
                    }
                }, caster, target, spellSlot, results)
            end

            return true
        end
    }
end

return RangeHandlers
