# Ticket #TLC-3.1: Ensure Disjoint Keyword Uses Event System

## Goal
Modify the disjoint keyword to generate a CANCEL_SPELL event instead of setting legacy flags.

## Description
The current disjoint keyword implementation bypasses the event system and the new token state machine. This needs to be updated to correctly trigger the DISSOLVING state via an event.

## Tasks

1. In keywords.lua, replace the execute function for Keywords.disjoint with the event-generating version:
   - Update the function to generate a CANCEL_SPELL event with returnMana = false
   - Remove direct token state manipulation
   - Ensure the event includes all necessary context (spellIndex, caster, etc.)

2. In wizard.lua, remove the legacy if effect.disjoint then ... end block from the castSpell function:
   - Identify and remove code blocks that directly handle disjoint effects
   - Ensure the spellCancellation logic in the event system properly handles the disjoint case

## Acceptance Criteria
- Casting a spell with the disjoint keyword generates a CANCEL_SPELL event with returnMana = false
- The legacy disjoint handling logic is removed from Wizard:castSpell
- Tokens affected by disjoint correctly transition to DISSOLVING state through the event system
- The full lifecycle from disjoint keyword → CANCEL_SPELL event → token:requestDestructionAnimation() → DISSOLVING → POOLED works correctly

## Related Tickets
- TLC-1: Define Token State Machine & Encapsulated Methods
- TLC-3: Refactor Token Acquisition & Return Points