# Ticket #SST-5: Implement Trap Trigger Condition Checking

## Description
Add logic to SustainedSpellManager.update to check if the trigger conditions for active Traps are met based on the current game state.

## Tasks

### Modify SustainedSpellManager.update(dt)
- In the loop iterating through activeSpells:
  - If the entry has triggerData (meaning it's a trap):
    - Get the casterWizard and targetWizard references (stored during addSustainedSpell). Access the global game state via casterWizard.gameState
    - Evaluate triggerData.condition:
      - If condition == "on_opponent_elevate": Check if `targetWizard.elevation == Constants.ElevationState.AERIAL`. Note: This triggers continuously while aerial. A refinement might be needed later to trigger only on the frame they enter AERIAL
      - If condition == "on_opponent_cast": Check a flag like `targetWizard.justCastSpellThisFrame` (this flag would need to be set in Wizard:castSpell and cleared at the start of Wizard:update)
      - Add checks for other potential trigger conditions defined in trap_trigger documentation
    - If the condition is met:
      - Log: `print("[SustainedManager] Trap triggered for "..casterWizard.name.." slot "..entry.slotIndex)`
      - Set a flag on the entry: `entry.triggered = true`

## Acceptance Criteria
- SustainedSpellManager.update evaluates trap trigger conditions based on game state
- When a condition is met, the corresponding log message appears, and the internal state of the tracked spell reflects `triggered = true`

## Design Notes
For simplicity, start with direct state polling (targetWizard.elevation). Event-based triggering is more complex. The justCastSpellThisFrame flag is a simple way to detect casting without event bus hooks.