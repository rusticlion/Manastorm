# Ticket PROG-19: Refactor Wizard:castSpell for Shield Activation

## Goal
Handle the transition from a casting spell to an active shield state cleanly after keyword execution.

## Tasks

1. Modify Wizard:castSpell after the `effect = spellToUse.executeAll(...)` call.
   - Check if `effect.shieldParams` exists and `effect.shieldParams.createShield == true`.

2. If true:
   - Call the existing createShield function (or integrate its logic here), passing self (the wizard), spellSlot, and effect.shieldParams. This function will handle:
     - Setting `slot.isShield = true`.
     - Setting `slot.defenseType`, `slot.blocksAttackTypes`, `slot.reflect`.
     - Setting token states to SHIELDING.
     - Setting `slot.progress = slot.castTime` (shield is now fully "cast" and active).
     - Triggering the "Shield Activated" VFX.
   - Crucially: Do not reset the slot or return tokens for shield spells here. The slot remains active with the shield.

3. If not a shield spell (no effect.shieldParams), proceed with the existing logic for returning tokens and resetting the slot.

4. Remove the old `if slot.willBecomeShield...` logic from Wizard:update and the premature `slot.isShield = true` setting from Wizard:queueSpell. The state change happens definitively in castSpell now.

## Acceptance Criteria
Shield spells correctly transition to an active shield state managed by the slot. Tokens remain and are marked SHIELDING. Non-shield spells resolve normally. The createShield function is now properly triggered by the keyword result.