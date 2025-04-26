# Ticket #TLC-3.2: Decouple Wizard:resetSpellSlot from Token State

## Goal
Prevent resetSpellSlot from prematurely altering token states or interfering with state transitions managed by the token itself or the EventRunner.

## Description
resetSpellSlot currently sets token states to FREE which conflicts with the state machine's handling, especially for disjoint (which should lead to DISSOLVING -> POOLED). It should only reset the slot's properties.

## Tasks

1. In wizard.lua, modify resetSpellSlot to remove the loop that sets tokenData.token.state = "FREE":
   - Identify the current implementation that directly modifies token.state
   - Remove this direct manipulation while preserving other functionality
   - Add comments explaining that token state is now managed by the token object itself

2. Ensure resetSpellSlot still clears the slot.tokens = {} table:
   - The slot should no longer reference the tokens after cancellation
   - This is important because the tokens will either return to FREE state or be POOLED
   - Verify the slot's other properties are correctly reset

3. Review related methods that might be affected:
   - Check if freeAllSpells or other methods have similar direct state manipulation
   - Ensure they are refactored to use token:requestReturnAnimation() or token:requestDestructionAnimation()

## Acceptance Criteria
- resetSpellSlot no longer modifies token.state or token.status
- resetSpellSlot correctly clears the slot's tokens table
- Disjointed tokens correctly enter the DISSOLVING state via the EventRunner and are eventually pooled
- Tokens returning to the mana pool correctly enter the RETURNING state and eventually FREE

## Related Tickets
- TLC-1: Define Token State Machine & Encapsulated Methods
- TLC-3: Refactor Token Acquisition & Return Points
- TLC-3.1: Ensure Disjoint Keyword Uses Event System