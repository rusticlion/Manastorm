# Ticket #SST-6: Implement Trap Effect Execution via EventRunner

## Description
When a trap is marked as triggered, execute its stored effect using the EventRunner and then clean up the trap.

## Tasks

### Modify SustainedSpellManager.update(dt)
- After checking triggers, check if `entry.triggered == true`
- If true:
  - Log: `print("[SustainedManager] Executing trap effect for "..entry.wizard.name.." slot "..entry.slotIndex)`
  - Get the effectData (e.g., `{ damage = { amount = 10 } }`)
  - Generate Events: Create an `events = {}` list. Iterate through effectData's keywords (like damage, ground). For each, call the corresponding `Keywords[keywordName].execute(params, caster, target, {}, events)` function to populate the events list. Crucially, determine the correct caster (likely entry.wizard) and target (based on the trap's definition, likely the opponent) to pass here
  - Process Events: `local EventRunner = require("systems.EventRunner"); EventRunner.processEvents(events, entry.wizard, targetWizard, nil)`
  - Cleanup:
    - Call `TokenManager.returnTokensToPool(entry.wizard.spellSlots[entry.slotIndex].tokens)` to start returning the mana
    - Call `entry.wizard:resetSpellSlot(entry.slotIndex)` to free the slot
    - Call `self.removeSustainedSpell(entry.id)` to remove it from the manager. Ensure iteration handles removal safely

## Acceptance Criteria
- Triggered trap effects (damage, grounding, etc.) are correctly applied via the EventRunner
- The trap is removed from the manager after triggering
- The spell slot used by the trap is reset
- The mana tokens used by the trap begin their return animation

## Pitfalls
Correctly identifying the caster and target for the trap_effect execution is vital. Safe removal from the activeSpells list during iteration is needed (e.g., iterate backwards or store IDs to remove after the loop). Ensure resetSpellSlot is called after returnTokensToPool is initiated.