# ManaPool Module (`manapool.lua`)

## Overview

The `manapool.lua` module manages the central shared pool of mana tokens that wizards use to cast spells. It handles the creation, storage, update (movement, state changes), and drawing of these tokens. It also defines the core state machine logic for individual tokens.

## Key Components

### 1. ManaPool Object

*   **Role:** Represents the central mana pool area.
*   **State:**
    *   `x`, `y`: Center position of the pool.
    *   `tokens`: Array table holding references to all active token objects currently managed by the pool (regardless of their state: FREE, CHANNELED, etc.).
    *   `valences`: Defines multiple elliptical orbital paths (rings) within the pool area for `FREE` tokens, each with different radii and base speeds.
    *   `valenceJumpChance`: Probability for `FREE` tokens to switch valences.
    *   `lockOverlay`: Loaded image for drawing on `LOCKED` tokens.
*   **Core Methods:**
    *   `ManaPool.new(x, y)`: Constructor. Initializes state, defines valences, loads assets, ensures the "token" object pool exists.
    *   `ManaPool:addToken(tokenType, imagePath)`: Creates a new token. Acquires a recycled object from the pool, adds `TokenMethods`, initializes state (`FREE`), sets orbital parameters, loads image, and adds it to `self.tokens`.
    *   `ManaPool:update(dt)`: Per-frame update loop. Iterates through `self.tokens` and updates each based on its `status`:
        *   `FREE`: Manages orbital motion, valence jumps, and smooth transitions.
        *   `CHANNELED`/`SHIELDING`: Updates animation towards the wizard along a Bezier path (position is handled by `Wizard` once animation completes).
        *   `RETURNING`: Updates animation back to the pool center along a Bezier path, triggers `animationCallback` (`finalizeReturn`) on completion.
        *   `DISSOLVING`: Updates animation timer, triggers `animationCallback` (`finalizeDestruction`) on completion.
        *   `LOCKED`: Updates timer, unlocks to `FREE` when timer expires, applies constrained movement.
    *   `ManaPool:draw()`: Draws all active tokens. Z-sorts for layering. Applies state-dependent visuals (glows, trails, color tints, overlays).
    *   `ManaPool:clear()`: Releases all tokens back to the object pool and clears `self.tokens`.
    *   `ManaPool:findFreeToken(tokenType)`: Helper to find a `FREE` token of a specific type *without* changing its state.
    *   `ManaPool:getToken(tokenType)`: Legacy/fallback (?) function to find a `FREE` token and set its state to `CHANNELED`.
    *   `ManaPool:returnToken(tokenIndex)`: Legacy/fallback function called if a token lacks `requestReturnAnimation`. Wraps the call if possible, otherwise handles return logic directly.
    *   `ManaPool.resetToken(token)`: Static function used by the object pool (`core.Pool`) to completely reset a token object's fields when it's released.

### 2. Token Objects & State Machine (`TokenMethods`)

*   **Object Pooling:** Tokens are managed using `core.Pool` for performance. Objects are acquired via `Pool.acquire("token")` and returned via `Pool.release("token", token)` (triggered by `finalizeDestruction` or `ManaPool:clear`).
*   **State (`token.status`):** Managed using `Constants.TokenStatus` values:
    *   `FREE`: Idle in the mana pool, orbiting.
    *   `CHANNELED`: Reserved/moving towards a wizard's spell slot.
    *   `SHIELDING`: Part of an active shield, orbiting the wizard (position managed by Wizard module).
    *   `LOCKED`: Unusable, timer counts down until returned to `FREE`.
    *   `RETURNING`: Animating back towards the mana pool center.
    *   `DISSOLVING`: Animating destruction.
    *   `POOLED`: Inactive, object released back to the pool.
*   **Core Methods (`TokenMethods` table, applied to token objects):**
    *   `token:setState(newStatus)`: Validates and applies state changes, maintains legacy `token.state` sync.
    *   `token:requestReturnAnimation()`: Preferred method to initiate return. Sets state to `RETURNING`, sets up animation parameters and `finalizeReturn` callback.
    *   `token:requestDestructionAnimation()`: Initiates destruction. Sets state to `DISSOLVING`, sets up animation parameters and `finalizeDestruction` callback, triggers VFX.
    *   `token:finalizeReturn()`: Callback after return animation. Sets state to `FREE`, clears wizard references, initializes orbital parameters within the pool.
    *   `token:finalizeDestruction()`: Callback after destruction animation. Sets state to `POOLED`, removes token from `manaPool.tokens`, releases object back to `core.Pool`.
*   **Other Token Properties:** `type`, `image`, `x`, `y`, `scale`, `rotAngle`, `orbitAngle`, `orbitSpeed`, animation timers/flags, references (`manaPool`, `gameState`, `wizardOwner`, `spellSlot`), etc.

### 3. Visuals

*   The pool itself is visually defined only by the orbiting `FREE` tokens.
*   Tokens have complex drawing logic based on state:
    *   Colored glows (type-specific).
    *   Pulsation.
    *   Z-ordering for depth.
    *   Color tints (`LOCKED`, `SHIELDING`).
    *   Shield type icons drawn inside `SHIELDING` tokens.
    *   Trails for `RETURNING` tokens.
    *   Fade-out/scale effects for `DISSOLVING` tokens.
    *   Lock overlay and timer for `LOCKED` tokens.

### 4. Potential Cleanup Areas

*   The `ManaPool:getToken` method seems less robust than the reservation system used in `Wizard` and might be a candidate for removal or refactoring.
*   The Bezier curve calculations used for animating tokens (`CHANNELED`/`SHIELDING`, `RETURNING`) are duplicated between the `update` function and the `draw` function (for trails). This could be consolidated into a helper function.

## Dependencies

*   `core.Constants`
*   `core.AssetCache`
*   `core.Pool`
*   Global `game` state (optional, via `self.gameState` reference, primarily for VFX access) 