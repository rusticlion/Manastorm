# Ticket #TLC-1: Define Token State Machine & Encapsulated Methods

## Goal
Establish a clear, robust state machine for mana tokens and centralize state transitions within the token object itself.

## Description
Refactor the token's state management. Instead of direct manipulation of token.state from various modules, create dedicated methods on the token object to request state changes and manage transitions, tied to a well-defined set of states.

## Tasks

1. In core/Constants.lua (or a new dedicated file if preferred), formally define the new TokenStatus enum:
   - FREE
   - CHANNELED
   - SHIELDING
   - RETURNING (animating back to pool)
   - DISSOLVING (animating destruction)
   - POOLED (ready for object pool release)

2. Modify the token structure (likely within the ManaPool.resetToken and ManaPool:addToken factory logic, or define a formal Token class if needed) to include:
   - status (using TokenStatus constants)
   - isAnimating (boolean flag)
   - animationCallback (function to call on animation completion)

3. Implement token:setState(newStatus):
   - Add checks to prevent invalid transitions (e.g., cannot transition from POOLED)
   - Include print("[TOKEN LIFECYCLE] Token "..self.id.." state: "..self.status.." -> "..newStatus) for debugging
   - Update self.status

4. Implement token:requestReturnAnimation():
   - Check if current status is CHANNELED or SHIELDING. If not, log a warning and return
   - Set self.isAnimating = true
   - Call self:setState(TokenStatus.RETURNING)
   - Trigger the "return to pool" animation (details TBD in later ticket, for now, maybe just set a timer)
   - Store a callback function: self.animationCallback = function() self:finalizeReturn() end

5. Implement token:requestDestructionAnimation():
   - Check if current status is already DISSOLVING or POOLED. If so, return
   - Set self.isAnimating = true
   - Call self:setState(TokenStatus.DISSOLVING)
   - Trigger the "dissolve/destroy" animation (details TBD)
   - Store a callback function: self.animationCallback = function() self:finalizeDestruction() end

6. Implement token:finalizeReturn():
   - Check if status is RETURNING
   - Set self.isAnimating = false
   - Call self:setState(TokenStatus.FREE)
   - Ensure the token is correctly positioned/configured for the mana pool idle state (may involve logic moved from ManaPool:finalizeTokenReturn)

7. Implement token:finalizeDestruction():
   - Check if status is DISSOLVING
   - Set self.isAnimating = false
   - Call self:setState(TokenStatus.POOLED)
   - Call Pool.release("token", self)

## Acceptance Criteria
- New TokenStatus constants exist
- Token objects have the new properties (status, isAnimating, animationCallback)
- State transition methods (setState, request..., finalize...) exist and perform basic state validation/logging
- Direct assignments to token.state outside these methods are removed (or flagged for removal in subsequent tickets)

## Pitfalls
- Ensure the token object passed around is the actual table instance from the pool, not a copy
- Initial state in addToken must be TokenStatus.FREE