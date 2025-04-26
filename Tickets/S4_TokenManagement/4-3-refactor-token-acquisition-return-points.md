# Ticket #TLC-3: Refactor Token Acquisition & Return Points

## Goal
Update all parts of the code that get, return, or destroy tokens to use the new token methods.

## Description
Replace direct state manipulation and calls to ManaPool:returnToken or Pool.release with calls to the new encapsulated token methods (requestReturnAnimation, requestDestructionAnimation).

## Tasks

1. Wizard Spell Completion:
   - In Wizard:castSpell, for non-shield spells, instead of calling self.manaPool:returnToken(tokenData.index), call tokenData.token:requestReturnAnimation()

2. Wizard Shield Blocking:
   - In Wizard:handleShieldBlock, instead of calling self.manaPool:returnToken(tokenData.index), call tokenData.token:requestReturnAnimation()

3. Wizard Free All:
   - In Wizard:freeAllSpells, instead of calling self.manaPool:returnToken(tokenData.index), call tokenData.token:requestReturnAnimation()

4. Keyword/Event - Disjoint/Dissipate:
   - Modify Keywords.dissipate.execute to find the target token(s) and call token:requestDestructionAnimation() instead of setting token.state = "DESTROYED". Remove the results.dissipate=true logic, as the effect is now handled by the token itself
   - Modify EventRunner handler for CANCEL_SPELL where returnMana == false (Disjoint) to find the target token(s) and call token:requestDestructionAnimation()

5. Mana Cost Payment:
   - In Wizard:queueSpell (where payManaCost logic resides), ensure tokens acquired from the pool are correctly set to TokenStatus.CHANNELED using token:setState()

6. Shield Creation:
   - In the createShield helper function (wizard.lua), ensure tokens are set to TokenStatus.SHIELDING using token:setState()

7. Remove Old ManaPool:returnToken:
   - Delete the old ManaPool:returnToken and ManaPool:finalizeTokenReturn functions as their logic is now encapsulated in the token methods and animation callbacks

## Acceptance Criteria
- All logical points where tokens are finished with (spell completion, shield block, free all, disjoint) now call token:requestReturnAnimation() or token:requestDestructionAnimation()
- Tokens correctly transition through RETURNING or DISSOLVING states driven by ManaPool:update
- Tokens correctly end up in FREE state (for returns) or are released to the pool (for destruction) after their animations complete
- Old ManaPool:returnToken and finalizeTokenReturn are removed

## Pitfalls
- Ensure the correct token object reference is being used when calling the new methods, not just an index