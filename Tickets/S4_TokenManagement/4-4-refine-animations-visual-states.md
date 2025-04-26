# Ticket #TLC-4: Refine Animations & Visual States

## Goal
Ensure the visual representation of tokens accurately reflects their new lifecycle states and animations.

## Description
Update the drawing logic in ManaPool:draw and potentially Wizard:drawSpellSlots to correctly display tokens based on their status (FREE, CHANNELED, SHIELDING, RETURNING, DISSOLVING) and potentially isAnimating flag. Implement the actual animations for returning and dissolving.

## Tasks

1. ManaPool:draw:
   - Modify the main drawing loop to switch based on token.status
   - Implement distinct visual styles or effects for RETURNING (e.g., streaking towards center, brighter glow) and DISSOLVING (e.g., shrinking, fading, particle burst)
   - Ensure POOLED tokens are not drawn
   - Ensure FREE, CHANNELED, SHIELDING, LOCKED states are still drawn correctly

2. Animation Implementation:
   - In ManaPool:update, add the actual position/scale/alpha modification logic for the RETURNING state (e.g., lerping position towards self.x, self.y). Define token.animDuration for return
   - In ManaPool:update, add the actual position/scale/alpha modification logic for the DISSOLVING state. Define token.dissolveMaxTime (or similar) for destruction animation

3. (Optional) Wizard:drawSpellSlots:
   - Review if any changes are needed here. Currently, it seems to handle drawing orbiting tokens correctly based on slot.tokens
   - Ensure it doesn't draw tokens that might be in RETURNING or DISSOLVING states if they somehow haven't been removed from slot.tokens yet (though TLC-3 should prevent this)

## Acceptance Criteria
- Tokens visually animate correctly when returning to the pool
- Tokens visually animate correctly when being destroyed
- Tokens in different states (FREE, CHANNELED, SHIELDING, LOCKED) are visually distinct and correctly represented
- Tokens disappear completely from the game view once they are POOLED (released)

## Design Notes
The dissolve animation logic previously within the DESTROYED state check in ManaPool:update can be adapted for the DISSOLVING state. The return animation needs bezier curve or lerp logic.