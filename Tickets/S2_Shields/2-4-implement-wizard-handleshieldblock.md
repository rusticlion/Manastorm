# Ticket PROG-14: Implement Wizard:handleShieldBlock

## Goal
Centralize the logic for consuming mana from a shield when it blocks.

## Tasks

1. Create `Wizard:handleShieldBlock(slotIndex, blockedSpell)`.

2. Get the shieldSlot.

3. Check token count > 0.

4. Determine tokensToConsume based on blockedSpell.shieldBreaker (default 1).

5. Remove the correct number of tokens from shieldSlot.tokens.

6. Call `self.manaPool:returnToken()` for each consumed token index.

7. Trigger "token release" VFX.

8. If `#shieldSlot.tokens == 0`: Deactivate the slot, trigger "shield break" VFX, clear shield properties (isShield, etc.).

## Acceptance Criteria
Shield correctly consumes mana tokens upon blocking. Shield breaks when mana is depleted. Slot becomes available again.