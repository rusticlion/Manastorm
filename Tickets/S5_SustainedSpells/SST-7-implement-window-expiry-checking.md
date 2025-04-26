# Ticket #SST-7: Implement Window/Expiry Condition Checking

## Description
Add logic to the SustainedSpellManager to expire sustained spells based on duration or game state conditions.

## Tasks

### Modify SustainedSpellManager.update(dt)
- Inside the loop iterating through activeSpells (before trigger checks):
  - If the entry has windowData:
    - Duration Check: If windowData.duration exists and entry.expiryTimer exists:
      - If `entry.expiryTimer <= 0`, mark for removal: `entry.expired = true`. Log expiry
    - Condition Check: If windowData.condition exists:
      - Evaluate the condition (e.g., until_next_conjure, while_elevated). Get necessary state from entry.wizard.gameState or entry.wizard
      - If the expiry condition is met, mark for removal: `entry.expired = true`. Log expiry
- After checking triggers and expiry, add a block: `if entry.expired and not entry.triggered then ... end`
- Inside this block (spell expired without triggering):
  - Log: `print("[SustainedManager] Spell expired for "..entry.wizard.name.." slot "..entry.slotIndex)`
  - Call `TokenManager.returnTokensToPool(entry.wizard.spellSlots[entry.slotIndex].tokens)`
  - Call `entry.wizard:resetSpellSlot(entry.slotIndex)`
  - Call `self.removeSustainedSpell(entry.id)`. Ensure safe removal during iteration

## Acceptance Criteria
- Sustained spells with a duration expire and clean up correctly when their timer runs out
- Sustained spells with conditions (implement at least one, e.g., until_next_conjure or while_elevated) expire and clean up when the condition is met
- Expired spells do not trigger their trap_effect
- Slot and mana are correctly released upon expiry

## Design Notes
For state-based conditions like until_next_conjure, the originating system (e.g., the conjure keyword handler in EventRunner) needs to set a temporary flag on the wizard (e.g., wizard.justConjuredMana = true) that the manager checks and then clears each frame.