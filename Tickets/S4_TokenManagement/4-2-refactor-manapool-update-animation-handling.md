# Ticket #TLC-2: Refactor ManaPool Update & Animation Handling

## Goal
Modify ManaPool:update to drive token animations based on the new states and execute callbacks upon completion.

## Description
The Mana Pool update loop should no longer directly manage timers like lockDuration or complex state transitions. It should focus on updating token positions based on their current state and checking if animations (RETURNING, DISSOLVING) are complete to trigger their finalization callbacks.

## Tasks

1. Modify the main loop within ManaPool:update(dt):
   - For tokens with status == TokenStatus.RETURNING:
     - Update their return animation progress (e.g., move towards pool center)
     - Check if the animation is complete (e.g., token.animTime >= token.animDuration)
     - If complete, call token.animationCallback() (which should trigger token:finalizeReturn)
   - For tokens with status == TokenStatus.DISSOLVING:
     - Update their dissolve animation progress (e.g., scale/fade)
     - Check if the animation is complete (e.g., token.dissolveTime >= token.dissolveMaxTime)
     - If complete, call token.animationCallback() (which should trigger token:finalizeDestruction and release the token to the pool)
   - For tokens with status == TokenStatus.FREE, CHANNELED, SHIELDING, LOCKED: Update their position/rotation/visuals based on the existing logic for those states (orbiting pool, orbiting wizard, locked wobble, etc.)

2. Remove the explicit DESTROYED state check and Pool.release call from ManaPool:update – this is now handled by the token:finalizeDestruction callback.

3. Remove the direct management of token.lockDuration from ManaPool:update. If locking needs a timer, it should be handled within the token's own update logic or via timed events if preferred (though simpler to keep it on the token for now). When the timer expires, the token should call self:setState(TokenStatus.FREE).

## Acceptance Criteria
- ManaPool:update correctly drives animations for RETURNING and DISSOLVING states
- Animation callbacks (finalizeReturn, finalizeDestruction) are called correctly upon animation completion
- Pool.release("token", ...) is no longer called directly from ManaPool:update
- Locked tokens correctly transition back to FREE after their duration (timer managed internally or via event)

## Design Notes
This separates animation driving (in ManaPool) from state finalization (in the token callback).