# Constants Reference

This document provides a reference for the Constants module in Manastorm.

## Overview

The Constants module (`core/Constants.lua`) provides centralized string constants used throughout the game, replacing string literals with structured reference tables. This approach offers several benefits:

- **Reduced typos**: References are checked at compile time
- **Better IDE support**: Autocomplete suggestions for constants
- **Centralized documentation**: All constants defined in one place
- **Easier refactoring**: Change a value in one place instead of throughout the codebase

## Usage

```lua
-- Import the module
local Constants = require("core.Constants")

-- Use constants in code
if wizard.elevation == Constants.ElevationState.AERIAL then
    -- Do something with aerial wizards
end

-- Use in tables
local spell = {
    attackType = Constants.AttackType.PROJECTILE,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FORCE}
}
```

## Available Constants

### Token Types

```lua
Constants.TokenType.FIRE    -- "fire"
Constants.TokenType.FORCE   -- "force"
Constants.TokenType.MOON    -- "moon"
Constants.TokenType.NATURE  -- "nature"
Constants.TokenType.STAR    -- "star"
Constants.TokenType.RANDOM  -- "random" (special: used in spell costs)
Constants.TokenType.ANY     -- "any" (special: used in keywords)
```

### Token States

```lua
Constants.TokenState.FREE       -- "FREE"
Constants.TokenState.CHANNELED  -- "CHANNELED"
Constants.TokenState.SHIELDING  -- "SHIELDING"
Constants.TokenState.LOCKED     -- "LOCKED"
Constants.TokenState.DESTROYED  -- "DESTROYED"
```

### Range States

```lua
Constants.RangeState.NEAR  -- "NEAR"
Constants.RangeState.FAR   -- "FAR"
```

### Elevation States

```lua
Constants.ElevationState.GROUNDED  -- "GROUNDED"
Constants.ElevationState.AERIAL    -- "AERIAL"
```

### Shield Types

```lua
Constants.ShieldType.BARRIER  -- "barrier"
Constants.ShieldType.WARD     -- "ward"
Constants.ShieldType.FIELD    -- "field"
```

### Attack Types

```lua
Constants.AttackType.PROJECTILE  -- "projectile"
Constants.AttackType.REMOTE      -- "remote"
Constants.AttackType.ZONE        -- "zone"
Constants.AttackType.UTILITY     -- "utility"
```

### Target Types

```lua
Constants.TargetType.SELF        -- "SELF"
Constants.TargetType.ENEMY       -- "ENEMY"
Constants.TargetType.SLOT_SELF   -- "SLOT_SELF"
Constants.TargetType.SLOT_ENEMY  -- "SLOT_ENEMY"
Constants.TargetType.POOL_SELF   -- "POOL_SELF"
Constants.TargetType.POOL_ENEMY  -- "POOL_ENEMY"
Constants.TargetType.CASTER      -- "caster"
Constants.TargetType.TARGET      -- "target"
```

### Damage Types

```lua
Constants.DamageType.FIRE     -- "fire"
Constants.DamageType.FORCE    -- "force"
Constants.DamageType.MOON     -- "moon"
Constants.DamageType.NATURE   -- "nature"
Constants.DamageType.STAR     -- "star"
Constants.DamageType.GENERIC  -- "generic"
Constants.DamageType.MIXED    -- "mixed"
```

### Player Sides

```lua
Constants.PlayerSide.PLAYER    -- "PLAYER"
Constants.PlayerSide.OPPONENT  -- "OPPONENT"
Constants.PlayerSide.NEUTRAL   -- "NEUTRAL"
```

### Status Types

```lua
Constants.StatusType.BURN    -- "burn"
Constants.StatusType.SLOW    -- "slow"
Constants.StatusType.STUN    -- "stun"
Constants.StatusType.REFLECT -- "reflect"
```

## Helper Functions

The Constants module also provides helper functions:

### `Constants.poolSide(side)`

Converts a side (SELF/ENEMY) to its POOL_ equivalent.

```lua
Constants.poolSide(Constants.TargetType.SELF)  -- Returns Constants.TargetType.POOL_SELF
```

### `Constants.slotSide(side)`

Converts a side (SELF/ENEMY) to its SLOT_ equivalent.

```lua
Constants.slotSide(Constants.TargetType.ENEMY)  -- Returns Constants.TargetType.SLOT_ENEMY
```

### Collection Functions

- `Constants.getAllTokenTypes()` - Returns a table with all token types
- `Constants.getAllShieldTypes()` - Returns a table with all shield types
- `Constants.getAllAttackTypes()` - Returns a table with all attack types

## CI Checking

We've implemented a CI check to prevent new string literals from being added. Run the check script:

```
lua tools/check_magic_strings.lua
```

This will scan the codebase for string literals that should be using Constants instead.