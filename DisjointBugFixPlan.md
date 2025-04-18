~The core issue is indeed a clash between the old direct state 
manipulation and the new (partially implemented) animation-driven state 
machine, particularly around the disjoint mechanic.
Root Cause Analysis:
disjoint Keyword Not Updated: As suspected, the keywords.lua file in the 
latest dump still has the old disjoint.execute function. It sets 
results.disjoint = true but does not generate a CANCEL_SPELL event. This 
is the primary bug. The system isn't even trying to use the new state 
machine for disjointed tokens.
Legacy Wizard:castSpell Handling: Because the disjoint keyword doesn't 
generate an event, the legacy handling block within Wizard:castSpell kicks 
in:
-- Handle disjoint effect (spell cancellation with mana destruction)
    if effect.disjoint then
        -- ... finds targetSlot ...
        if targetSlot > 0 and targetSlot <= #target.spellSlots and 
target.spellSlots[targetSlot].active then
            local slot = target.spellSlots[targetSlot]
            -- ...
            -- Destroy the mana tokens instead of returning them to the 
pool
            for _, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                if token then
                    -- Mark the token as destroyed (LEGACY STATE)
                    token.state = "DESTROYED" -- << PROBLEM 1: Sets legacy 
state, not new status
                    token.gameState = self.gameState -- Give the token 
access to gameState for VFX
                    -- ... VFX ...
                end
            end
            -- Cancel the spell, emptying the slot
            slot.active = false
            slot.progress = 0
            slot.tokens = {} -- << PROBLEM 2: Clears slot's token list 
immediately
            -- ... VFX ...
            print(...)
        else
            print("No active spell found in slot " .. targetSlot .. " to 
disjoint")
        end
    end
Use code with caution.
Lua
State Mismatch & No Cleanup Trigger:
The tokens' legacy state is set to DESTROYED.
Their new status (from the state machine) likely remains CHANNELED because 
token:setState() was never called.
Crucially, token:requestDestructionAnimation() is never called.
The ManaPool:update loop now primarily checks token.status. It doesn't 
have specific logic to handle the legacy state == "DESTROYED" anymore 
(that was removed in favor of the DISSOLVING status check).
Because requestDestructionAnimation wasn't called, the DISSOLVING 
animation never starts, and finalizeDestruction (which releases the token 
to the pool) is never reached.
Visual Freezing:
The Wizard:castSpell function immediately clears the slot.tokens table for 
the disjointed slot.
Wizard:drawSpellSlots iterates slot.tokens to draw orbiting tokens. Since 
this list is now empty, the disjointed tokens are no longer drawn by the 
slot.
However, these tokens still exist in the main ManaPool.tokens list. They 
are likely drawn one last time by ManaPool:draw in their final calculated 
position (from their previous CHANNELED state orbit) before the slot was 
cleared, and then never updated or redrawn again, appearing frozen.
Solution: Fully Commit to the State Machine
We need to eliminate the legacy handling for disjoint and ensure it uses 
the new state machine correctly.
Update keywords.lua for disjoint: Modify keywords.disjoint.execute to 
generate the correct event instead of setting flags.
File: keywords.lua
Change: Replace the execute function for Keywords.disjoint with:
execute = function(params, caster, target, results, events) -- Add 
'events' parameter
    local targetSlotIndex = 0
    if params.slot and type(params.slot) == "function" then
        -- Evaluate the slot function if provided
        targetSlotIndex = params.slot(caster, target, results.currentSlot)
    elseif params.slot then
        targetSlotIndex = params.slot
    end
    targetSlotIndex = tonumber(targetSlotIndex) or 0 -- Ensure it's a 
number, default to 0

    -- Create a CANCEL_SPELL event with returnMana = false
    table.insert(events or {}, {
        type = "CANCEL_SPELL",
        source = "caster",
        target = Constants.TargetType.SLOT_ENEMY, -- Use constant
        slotIndex = targetSlotIndex, -- 0 means random active slot handled 
by EventRunner
        returnMana = false -- Key difference for disjoint
    })

    -- Remove legacy flag setting if present (results.disjoint, 
results.targetSlot)
    results.disjoint = nil
    results.targetSlot = nil

    return results -- Return results for backward compatibility if needed, 
though events are primary now
end,
Use code with caution.
Lua
Remove Legacy disjoint Handling in Wizard:castSpell: Delete the entire if 
effect.disjoint then ... end block from Wizard:castSpell. The EventRunner 
will now handle this via the CANCEL_SPELL event.
Modify Wizard:resetSpellSlot: Prevent it from interfering with token state 
transitions requested by the EventRunner.
File: wizard.lua
Change: Update the resetSpellSlot function:
resetSpellSlot = function(self, slotIndex)
    local slot = self.spellSlots[slotIndex]
    if not slot then return end

    --[[ REMOVE THIS BLOCK - Token state should be managed by token 
methods called by EventRunner
    if not slot.isShield then
        for _, tokenData in ipairs(slot.tokens) do
            if tokenData.token then
                tokenData.token.state = "FREE" -- DO NOT DO THIS HERE
            end
        end
    end
    ]]--

    -- Reset the slot properties
    slot.active = false
    slot.spell = nil
    slot.spellType = nil -- Added for completeness
    slot.castTime = 0 -- Added for completeness
    slot.castProgress = 0
    slot.tokens = {} -- Clear the reference list *after* animations have 
been requested
    slot.frozen = false
    slot.freezeTimer = 0
    slot.isShield = false
    slot.willBecomeShield = false
    -- Reset any other slot-specific flags if needed
end,
Use code with caution.
Lua
Verify EventRunner CANCEL_SPELL Handler: Double-check the CANCEL_SPELL 
handler in systems/EventRunner.lua ensures it correctly calls 
token:requestDestructionAnimation() when event.returnMana is false. (The 
current code looks correct, but verify).~
