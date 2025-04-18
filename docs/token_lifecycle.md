# Mana Token Lifecycle State Machine

## Overview
This document describes the token lifecycle system in Manastorm, which handles the transition of mana tokens between various states, from creation to destruction.

## Implementation Status

The token lifecycle system is implemented in the following files:
- `core/Constants.lua` - Defines the TokenStatus enum
- `manapool.lua` - Implements the token methods and updates the mana pool update loop to drive animations
- Future tickets will update all token acquisition and return points to use the new methods

## States

```
+-------+    channeling    +------------+    shield creation    +-----------+
| FREE  |----------------->| CHANNELED  |-------------------->  | SHIELDING |
+-------+                  +------------+                       +-----------+
   ^                           |    |                               |
   |                           |    |                               |
   |                           |    v                               |
   |      animation            |  +------------+                    |
   |<-----------------+--------+  | DISSOLVING |                    |
   |      complete    |           +------------+                    |
   |                  |                 |                           |
   |                  |                 v                           |
   |                  |          +------------+                     |
   |                  +----------| RETURNING  |<--------------------+
   |                             +------------+
   |                                    |
   |                                    v
   |                             +------------+
   +-----------------------------+   POOLED   |
                                 +------------+
```

### State Descriptions

- **FREE**: Token is available in the mana pool for use
- **CHANNELED**: Token is being used for an active spell or ability
- **SHIELDING**: Token is specifically being used as part of a shield
- **RETURNING**: Token is animating back to the mana pool (temporary transition state)
- **DISSOLVING**: Token is being destroyed and will be released back to object pool (temporary transition state)
- **POOLED**: Token is fully released to the object pool and no longer exists in game

## Token Methods

Each token has the following state machine methods:

### setState(newStatus)
- Validates and changes the token's state
- Logs the state transition for debugging
- Maintains backward compatibility with legacy token.state

### requestReturnAnimation()
- Initiates the process of returning a token to the pool
- Validates that token is in CHANNELED or SHIELDING state
- Sets animation parameters and schedules the finalizeReturn callback

### requestDestructionAnimation()
- Initiates the process of dissolving/destroying a token
- Sets animation parameters and schedules the finalizeDestruction callback
- Creates visual effects for the dissolution

### finalizeReturn()
- Called when return animation completes
- Positions the token appropriately in the mana pool
- Resets token properties for its FREE state

### finalizeDestruction()
- Called when dissolve animation completes
- Removes token from the tokens list
- Releases token to the object pool (POOLED state)

## Usage

### Acquiring a Token
```lua
local token, index = manaPool:getToken(tokenType)
-- token.status is now CHANNELED
```

### Returning a Token to Pool
```lua
token:requestReturnAnimation()
-- Animation will play, then token.status will become FREE
```

### Destroying a Token
```lua
token:requestDestructionAnimation()
-- Animation will play, then token will be released to pool
```

## Benefits

1. Encapsulation: Token manages its own lifecycle
2. Clear states: Each token's state is well-defined
3. Animation/Logic Separation: Animation logic is clearly separated from state transition logic
4. Safety: Invalid state transitions are prevented and logged
5. Unified approach: All token handling follows the same pattern

## Animation System

The ManaPool:update method now drives token animations based on their status:

- For tokens with status == RETURNING:
  - Updates their return animation progress (moving towards pool center)
  - When animation completes, calls token.animationCallback() which triggers finalizeReturn()

- For tokens with status == DISSOLVING:
  - Updates their dissolve animation progress (scaling/fading)
  - When animation completes, calls token.animationCallback() which triggers finalizeDestruction()

- For each status (FREE, CHANNELED, SHIELDING, LOCKED):
  - Updates positions based on appropriate behavior (orbiting, spell slot, wobbling, etc.)

This separation of concerns ensures that:
1. Animations are consistent and predictable
2. Token state transitions only happen at well-defined points
3. The ManaPool update method is more maintainable, focusing on animation driving rather than state management