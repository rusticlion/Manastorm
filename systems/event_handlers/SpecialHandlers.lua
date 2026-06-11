-- systems/event_handlers/SpecialHandlers.lua
-- Special echo and zone marker event handlers for EventRunner.

local SpecialHandlers = {}

function SpecialHandlers.build(deps)
    local Constants = deps.Constants
    local emitEffectEvent = deps.emitEffectEvent
    local getSlotVisualContext = deps.getSlotVisualContext
    local resolveTarget = deps.resolveTarget

    return {
        ECHO = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then
                return false
            end

            local wizard = targetInfo.wizard
            local slotIndex = targetInfo.slotIndex or spellSlot
            local slot = wizard.spellSlots[slotIndex]

            if slot and slot.spell then
                wizard.echoQueue = wizard.echoQueue or {}
                table.insert(wizard.echoQueue, {
                    spell = slot.spell,
                    delay = event.delay,
                    timer = event.delay
                })

                local visualContext = getSlotVisualContext(wizard, slotIndex)
                emitEffectEvent({
                    type = "EFFECT",
                    source = event.source or "caster",
                    target = event.target,
                    effectOverride = Constants.VFXType.WARP_BASE,
                    affinity = event.affinity or visualContext.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = visualContext.manaCost or 1,
                    rangeBand = wizard.gameState and wizard.gameState.rangeState or nil,
                    elevation = wizard.elevation,
                    visualShape = visualContext.visualShape,
                    duration = event.delay or 1.0,
                    delay = event.delay,
                    slotIndex = slotIndex,
                    spellName = slot.spell.name,
                    vfxParams = {
                        x = wizard.x,
                        y = wizard.y
                    }
                }, caster, wizard, slotIndex, results)

                return true
            end

            return false
        end,

        ZONE_ANCHOR = function(event, caster, target, spellSlot, results)
            local targetEntity = resolveTarget(event, caster, target)
            if not targetEntity then
                return false
            end

            if spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] then
                local slot = caster.spellSlots[spellSlot]
                slot.zoneAnchored = true
                slot.anchorRange = event.anchorRange
                slot.anchorElevation = event.anchorElevation
                slot.anchorRequireAll = event.requireAll

                return true
            end

            return false
        end,

        ZONE_MULTI = function(event, caster, target, spellSlot, results)
            local targetEntity = resolveTarget(event, caster, target)
            if not targetEntity then
                return false
            end

            if spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] then
                local slot = caster.spellSlots[spellSlot]
                slot.affectsBothRanges = true

                return true
            end

            return false
        end
    }
end

return SpecialHandlers
