~This is a classic case where a highly stateful, persistent effect (like 
an active shield) clashes a bit with a system designed for resolving 
discrete, immediate keyword effects.

Based on the codebase and the design goals, here's the breakdown and a 
plan to get shields working elegantly within the keyword framework:

Diagnosis of the Problem:

Keyword Execution vs. Persistent State: The core issue is that the block 
keyword's execute function (in keywords.lua) runs when the shield spell 
resolves, setting flags in the results table. However, the actual blocking 
needs to happen later, whenever an enemy spell hits. Furthermore, the 
shield needs to persist in the slot after its initial cast resolves, 
retaining its mana. The current keyword execution model is primarily 
designed for immediate effects, not setting up long-term states on a slot.

State Management Split: Because the keyword isn't fully setting up the 
persistent state, wizard.lua is still doing a lot of heavy lifting outside 
the keyword system:

The createShield helper function seems to contain logic that should 
ideally be driven by the keyword result.

The checkShieldBlock function runs during castSpell to detect if an 
incoming spell should be blocked, separate from the keyword resolution.

The Wizard:update function has logic to update orbiting shield tokens 
(which is good, but shows the state isn't fully managed just by spell 
resolution).

The Wizard:castSpell function has complex conditional logic around 
slot.isShield to prevent tokens from returning, which shouldn't be needed 
if the state is handled correctly.

Mist Veil's Custom executeAll: This is a symptom. Because the standard 
keyword compilation + execution wasn't sufficient to handle the specific 
combination of block and elevate along with the persistent shield state, a 
custom override was needed. This breaks the modularity goal.

Token State Timing: The spellCompiler's executeAll function marks tokens 
as SHIELDING during compilation. This is too early. Tokens should remain 
CHANNELED during the shield's cast time and only become SHIELDING when the 
shield activates.

Solution: Refined Shield Implementation Plan

Let's restructure how shields are handled to align better with the keyword 
system while respecting their persistent nature.

Phase 1: Redefine Keyword Responsibilities & State Setup

Ticket PROG-18: Refactor block Keyword Execution

Goal: Make the block keyword only responsible for setting up the intent to 
create a shield when its spell resolves.

Tasks:

In keywords.lua, modify the block.execute function. Instead of just 
setting simple flags, have it return a structured shieldParams table 
within the results. Example:

execute = function(params, caster, target, results)
    results.shieldParams = {
        createShield = true,
        defenseType = params.type or "barrier",
        blocksAttackTypes = params.blocks or {"projectile"},
        reflect = params.reflect or false
        -- Mana-linking is now the default, no need for a flag
    }
    return results
end
Use code with caution.
Lua
Remove the direct setting of results.isShield, results.defenseType, etc., 
from the keyword's execute.

AC: The block keyword's execute function returns a shieldParams table in 
the results.

Ticket PROG-19: Refactor Wizard:castSpell for Shield Activation

Goal: Handle the transition from a casting spell to an active shield state 
cleanly after keyword execution.

Tasks:

Modify Wizard:castSpell after the effect = spellToUse.executeAll(...) 
call.

Check if effect.shieldParams exists and effect.shieldParams.createShield 
== true.

If true:

Call the existing createShield function (or integrate its logic here), 
passing self (the wizard), spellSlot, and effect.shieldParams. This 
function will handle:

Setting slot.isShield = true.

Setting slot.defenseType, slot.blocksAttackTypes, slot.reflect.

Setting token states to SHIELDING.

Setting slot.progress = slot.castTime (shield is now fully "cast" and 
active).

Triggering the "Shield Activated" VFX.

Crucially: Do not reset the slot or return tokens for shield spells here. 
The slot remains active with the shield.

If not a shield spell (no effect.shieldParams), proceed with the existing 
logic for returning tokens and resetting the slot.

Remove the old if slot.willBecomeShield... logic from Wizard:update and 
the premature slot.isShield = true setting from Wizard:queueSpell. The 
state change happens definitively in castSpell now.

AC: Shield spells correctly transition to an active shield state managed 
by the slot. Tokens remain and are marked SHIELDING. Non-shield spells 
resolve normally. The createShield function is now properly triggered by 
the keyword result.

Phase 2: Integrate Blocking Check

Ticket PROG-20: Integrate checkShieldBlock into castSpell

Goal: Move the shield blocking check into the appropriate place in the 
spell resolution flow.

Tasks:

In Wizard:castSpell, before calling effect = spellToUse.executeAll(...) 
and before checking for the caster's own blockers (like the old Mist Veil 
logic, which should be removed per PROG-16), call the existing 
checkShieldBlock(spellToUse, attackType, target, self).

If blockInfo.blockable is true:

Trigger block VFX.

Call target:handleShieldBlock(blockInfo.blockingSlot, spellToUse) (from 
PROG-14 - assuming it exists or implement it now).

Crucially: Return early from castSpell. Do not execute the spell's 
keywords or apply any other effects.

Remove the separate checkShieldBlock call that happens later in the 
current castSpell.

AC: Incoming offensive spells are correctly checked against active shields 
before their effects are calculated or applied. Successful blocks prevent 
the spell and trigger shield mana consumption.

Ticket PROG-14: Implement Wizard:handleShieldBlock (If not already done, 
or refine it)

Goal: Centralize the logic for consuming mana from a shield when it 
blocks.

Tasks: (As defined previously)

Create Wizard:handleShieldBlock(slotIndex, blockedSpell).

Get the shieldSlot.

Check token count > 0.

Determine tokensToConsume based on blockedSpell.shieldBreaker (default 1).

Remove the correct number of tokens from shieldSlot.tokens.

Call self.manaPool:returnToken() for each consumed token index.

Trigger "token release" VFX.

If #shieldSlot.tokens == 0: Deactivate the slot, trigger "shield break" 
VFX, clear shield properties (isShield, etc.).

AC: Shield correctly consumes mana tokens upon blocking. Shield breaks 
when mana is depleted. Slot becomes available again.

Phase 3: Cleanup and Refinement

Ticket PROG-21: Refactor Mist Veil

Goal: Remove the custom executeAll from Spells.mist and define it purely 
using keywords.

Tasks:

In spells.lua, remove the executeAll function from Spells.mist.

Ensure its keywords table correctly defines both the block keyword 
parameters and the elevate keyword parameters.

keywords = {
    block = { type = "ward", blocks = {"projectile", "remote"} },
    elevate = { duration = 4.0 }
}
Use code with caution.
Lua
AC: Mist Veil works correctly using the standard keyword compilation and 
resolution process.

Ticket PROG-16: Remove Old Blocker System (As defined previously – remove 
wizard.blockers, related timers, and drawing code).

Ticket PROG-15: Visual Distinction for Shield Slots (As defined previously 
– update drawSpellSlots to show active shields differently).

Key Principle:

Keyword Sets Intent: The block keyword's execution signals intent to 
create a shield.

castSpell Establishes State: The castSpell function, upon seeing the 
shield intent in the results, performs the actions to make the shield 
state persistent on the slot (using createShield logic).

castSpell Checks Blocks: The castSpell function also checks the target for 
existing active shields before processing the incoming spell's effects.

handleShieldBlock Manages Breakdown: A dedicated function handles the 
consequences of a successful block (mana leak, shield break).

This approach keeps the keyword system focused on defining effects while 
acknowledging that shields require specific state management within the 
wizard/slot structure and interaction checks during spell resolution. It 
centralizes the shield creation logic previously duplicated or bypassed.~
