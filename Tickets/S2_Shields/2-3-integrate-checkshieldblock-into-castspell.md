# Ticket PROG-20: Integrate checkShieldBlock into castSpell

## Goal
Move the shield blocking check into the appropriate place in the spell resolution flow.

## Tasks

1. In Wizard:castSpell, before calling `effect = spellToUse.executeAll(...)` and before checking for the caster's own blockers (like the old Mist Veil logic, which should be removed per PROG-16), call the existing `checkShieldBlock(spellToUse, attackType, target, self)`.

2. If `blockInfo.blockable` is true:
   - Trigger block VFX.
   - Call `target:handleShieldBlock(blockInfo.blockingSlot, spellToUse)` (from PROG-14 - assuming it exists or implement it now).
   - Crucially: Return early from castSpell. Do not execute the spell's keywords or apply any other effects.

3. Remove the separate checkShieldBlock call that happens later in the current castSpell.

## Acceptance Criteria
Incoming offensive spells are correctly checked against active shields before their effects are calculated or applied. Successful blocks prevent the spell and trigger shield mana consumption.