# Mana Token Lifecycle State Machine

## Context & Problem Statement
Our current mana token implementation has several issues that become more apparent when many tokens are in flux simultaneously:

1. Token state transitions aren't clearly defined or centralized
2. Token animations and state are managed in multiple places
3. Race conditions can occur when a token is in transition between states
4. Direct manipulation of token.state from multiple modules creates unpredictable behavior

## Proposed Solution
Implement a formal state machine for mana tokens with well-defined states and encapsulated transition methods, centralizing the management of token lifecycle.

## Token States

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

## State Descriptions

- **FREE**: Token is available in the mana pool for use
- **CHANNELED**: Token is being used for an active spell or ability
- **SHIELDING**: Token is specifically being used as part of a shield
- **RETURNING**: Token is animating back to the mana pool (temporary transition state)
- **DISSOLVING**: Token is being destroyed and will be released back to object pool (temporary transition state)
- **POOLED**: Token is fully released to the object pool and no longer exists in game

## Encapsulated Methods
The token object itself will manage state transitions through a set of well-defined methods:

- **token:setState(newState)**: Validate and change token state with logging
- **token:requestReturnAnimation()**: Start the process of returning to pool
- **token:requestDestructionAnimation()**: Start the process of dissolving/destroying
- **token:finalizeReturn()**: Called when return animation completes
- **token:finalizeDestruction()**: Called when dissolve animation completes

## Benefits

1. **Clarity**: Each token's state is well-defined and has a clear meaning
2. **Safety**: Invalid state transitions are prevented by the setState method
3. **Debuggability**: State changes are logged for troubleshooting
4. **Encapsulation**: Token manages its own lifecycle through proper methods
5. **Animation/Logic Separation**: Animation logic is clearly separated from state transition logic

## Implementation Plan
The implementation is broken down into 4 tickets:
1. Define token state machine and methods
2. Refactor ManaPool:update to drive animations based on the new states
3. Update all token acquisition and return points to use the new methods
4. Refine animations and visual states

This approach will ensure a smooth, incremental transition to the new architecture.