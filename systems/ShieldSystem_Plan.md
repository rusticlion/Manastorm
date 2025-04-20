# ShieldSystem Modularization Plan

This document outlines the extraction of shield-related functionality from `wizard.lua` into a dedicated `ShieldSystem` module.

## Overview

The current shield functionality in `wizard.lua` is tightly integrated with the Wizard class, making it difficult to maintain and extend. This plan details how to extract this functionality into a dedicated module to improve code organization and maintainability.

## Module Structure

The new module will be located at `/systems/ShieldSystem.lua` and will expose the following interface:

```lua
local ShieldSystem = {
    createShield = nil,          -- Create a shield for a wizard in a slot
    checkShieldBlock = nil,      -- Check if a spell can be blocked
    handleShieldBlock = nil,     -- Handle token consumption for blocks
    updateShieldVisuals = nil,   -- Update shield visual effects
    getShieldColor = nil         -- Get color based on shield type
}
```

## Implementation Steps

### 1. Create the Module File

Create `/systems/ShieldSystem.lua` with the initial module structure.

### 2. Extract Shield-Related Functions

The following functions need to be extracted from `wizard.lua`:

#### 2.1 createShield function (Lines ~14-95)

This function:
- Creates a shield in a specified spell slot
- Sets shield properties (defense type, blocks attack types, etc.)
- Updates token states for the shield
- Triggers shield creation VFX
- Returns information about the created shield

#### 2.2 checkShieldBlock function (Lines ~97-189)

This function:
- Determines if a spell can be blocked by any of the defender's shields
- Checks shield types against attack types
- Returns block information (blockable, blockType, blockingSlot, etc.)

#### 2.3 handleShieldBlock method (Lines ~2729-2788)

This method:
- Consumes shield tokens based on the incoming spell's power
- Handles token destruction
- Checks for shield collapse
- Triggers shield impact VFX

### 3. Create Helper Functions

#### 3.1 getShieldColor function

Create a new function to determine shield colors based on defense type.

#### 3.2 updateShieldVisuals function

Create a function to centralize shield visual updates.

### 4. Update Wizard.lua References

#### 4.1 Add the module import

```lua
local ShieldSystem = require("systems.ShieldSystem")
```

#### 4.2 Replace existing implementations

- Remove original `createShield` and `checkShieldBlock` functions
- Replace the `Wizard:handleShieldBlock` method with a wrapper calling `ShieldSystem.handleShieldBlock`
- Update `castSpell` method to use `ShieldSystem.checkShieldBlock`
- Add shield visual updates in the `update` method

## Implementation Details

### ShieldSystem.lua

```lua
-- ShieldSystem.lua
-- Centralized shield management system for Manastorm

local ShieldSystem = {}

-- Get appropriate shield color based on defense type
function ShieldSystem.getShieldColor(defenseType)
    local shieldColor = {0.8, 0.8, 0.8}  -- Default gray
    
    if defenseType == "barrier" then
        shieldColor = {1.0, 1.0, 0.3}    -- Yellow for barriers
    elseif defenseType == "ward" then
        shieldColor = {0.3, 0.3, 1.0}    -- Blue for wards
    elseif defenseType == "field" then
        shieldColor = {0.3, 1.0, 0.3}    -- Green for fields
    end
    
    return shieldColor
end

-- Create a shield in the specified slot
function ShieldSystem.createShield(wizard, spellSlot, blockParams)
    -- Implementation extracted from wizard.lua
    -- ...
end

-- Check if a spell can be blocked by a shield
function ShieldSystem.checkShieldBlock(spell, attackType, defender, attacker)
    -- Implementation extracted from wizard.lua
    -- ...
end

-- Handle the effects of a spell being blocked by a shield
function ShieldSystem.handleShieldBlock(wizard, slotIndex, incomingSpell)
    -- Implementation extracted from wizard.lua
    -- ...
end

-- Update shield visuals and animations
function ShieldSystem.updateShieldVisuals(wizard, dt)
    -- New function to centralize shield visual updates
    -- ...
end

return ShieldSystem
```

### Wizard.lua Updates

```lua
-- Add ShieldSystem module import
local ShieldSystem = require("systems.ShieldSystem")

-- Replace handleShieldBlock method with wrapper
function Wizard:handleShieldBlock(slotIndex, incomingSpell)
    return ShieldSystem.handleShieldBlock(self, slotIndex, incomingSpell)
end

-- Update castSpell to use ShieldSystem
function Wizard:castSpell(spellSlot)
    -- ...
    local blockInfo = ShieldSystem.checkShieldBlock(spellToUse, attackType, target, self)
    -- ...
end

-- Add shield visual updates to update method
function Wizard:update(dt)
    -- ...
    ShieldSystem.updateShieldVisuals(self, dt)
    -- ...
end
```

## Dependencies

The ShieldSystem module will have the following dependencies:

1. **Wizard Objects**: For accessing wizard properties (position, name)
2. **Spell Slots**: For managing shield slots and their tokens
3. **VFX System**: For shield visual effects
4. **TokenManager**: For token state management

## Testing Strategy

1. Test each extracted function in isolation
2. Verify shield creation with the new system
3. Test shield blocking against various attack types
4. Validate token consumption on shield blocks
5. Ensure shield visuals display correctly

## Future Enhancements

Once the initial extraction is complete, consider these enhancements:

1. Add more shield types with different visual effects
2. Implement shield strength variations
3. Add shield interaction modifiers
4. Create shield-specific sound effects

## Backward Compatibility

To ensure backward compatibility during transition:
- Maintain the same function signatures and return values
- Keep wrapper methods in the Wizard class
- Verify all existing shield functionality works correctly