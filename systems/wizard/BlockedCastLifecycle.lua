-- systems/wizard/BlockedCastLifecycle.lua
-- Manages timing and cleanup for blocked casts waiting on impact VFX callbacks.

local Constants = require("core.Constants")
local BlockedCastLifecycle = {}

local function dispatchBlockedCleanup(wizard, slotIndex)
    local eventRunner = wizard and wizard.gameState and wizard.gameState.eventRunner or require("systems.EventRunner")
    if not eventRunner or type(eventRunner.processEvents) ~= "function" then
        print("[SHIELD BLOCK] WARNING: Cannot dispatch blocked cleanup without EventRunner")
        return false
    end

    local result = eventRunner.processEvents({
        {
            type = "CLEANUP_SLOT",
            source = "caster",
            target = Constants.TargetType.SLOT_SELF,
            slotIndex = slotIndex,
            returnTokens = true,
            resetSlot = true,
            clearBlockedPendingImpact = true,
            requireBlockedPendingImpact = true
        }
    }, wizard, nil, slotIndex)

    return result and (result.slotsCleaned or 0) > 0 or false
end

function BlockedCastLifecycle.begin(slot, fallbackSeconds)
    slot.blockedPendingImpact = true
    slot.blockImpactTimer = 0
    slot.blockImpactTimeout = fallbackSeconds
end

function BlockedCastLifecycle.makeImpactCallback(wizard, slot, slotIndex)
    return function()
        if not slot.blockedPendingImpact then
            return
        end

        dispatchBlockedCleanup(wizard, slotIndex)
    end
end

-- Returns true when blocked-pending state was handled and normal progress should be skipped.
function BlockedCastLifecycle.updatePending(wizard, slotIndex, slot, dt, defaultTimeout)
    if not slot.blockedPendingImpact then
        return false
    end

    slot.blockImpactTimer = (slot.blockImpactTimer or 0) + dt
    local timeout = slot.blockImpactTimeout or defaultTimeout
    if slot.blockImpactTimer < timeout then
        return true
    end

    print(string.format(
        "[SHIELD BLOCK] Fallback cleanup triggered for %s slot %d after %.2fs",
        wizard.name,
        slotIndex,
        slot.blockImpactTimer
    ))

    dispatchBlockedCleanup(wizard, slotIndex)
    return true
end

return BlockedCastLifecycle
