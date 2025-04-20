# WizardVisuals Modularization Plan

This document outlines the extraction of visualization-related functionality from `wizard.lua` into a dedicated `WizardVisuals` module.

## Overview

The current visualization code in `wizard.lua` is tightly coupled with the Wizard class, making it difficult to modify visual elements without impacting game logic. This plan details how to extract this functionality into a dedicated module to improve code organization and maintainability.

## Module Structure

The new module will be located at `/systems/WizardVisuals.lua` and will expose the following interface:

```lua
local WizardVisuals = {
    drawWizard = nil,          -- Main drawing function for the wizard
    drawSpellSlots = nil,      -- Draw spell slots and tokens
    drawStatusEffects = nil,   -- Draw status effect indicators
    drawEllipse = nil,         -- Helper for drawing elliptical shapes
    drawEllipticalArc = nil,   -- Helper for drawing elliptical arcs
    getStatusEffectColor = nil -- Get color based on status effect type
}
```

## Implementation Steps

### 1. Create the Module File

Create `/systems/WizardVisuals.lua` with the initial module structure.

### 2. Extract Drawing-Related Functions

The following functions need to be extracted from `wizard.lua`:

#### 2.1 drawWizard function (Lines ~464-583)

This function:
- Calculates positioning based on wizard state
- Renders the wizard sprite with appropriate offsets
- Applies visual effects (stun, elevation indicators)
- Manages animation effects

#### 2.2 drawSpellSlots function (Lines ~794-1000+)

This function:
- Renders spell slot orbits and tokens
- Shows casting progress
- Manages shield and spell state visualization
- Handles 3D-like token positioning

#### 2.3 drawStatusEffects function (Lines ~633-792)

This function:
- Renders status effect UI bars
- Visualizes duration and remaining time
- Creates visual particles for active effects

#### 2.4 drawEllipse and drawEllipticalArc helper functions (Lines ~586-630)

These functions:
- Provide utilities for drawing elliptical shapes
- Support shield and spell slot visualizations

### 3. Create Helper Functions

#### 3.1 getStatusEffectColor function

Create a new function to determine colors based on status effect type.

### 4. Update Wizard.lua References

#### 4.1 Add the module import

```lua
local WizardVisuals = require("systems.WizardVisuals")
```

#### 4.2 Replace existing implementations

- Replace the original drawing methods with calls to the WizardVisuals module
- Update the main draw method to use WizardVisuals.drawWizard

## Integration with Existing VFX System

The WizardVisuals module will leverage the existing VFX system (`vfx.lua`) for particle effects and animations instead of duplicating functionality:

- For particle effects and animations, use `wizard.gameState.vfx.createEffect()`
- For spell effects, use the existing `VFX.createSpellEffect()` helper
- Shield visuals will use `ShieldSystem` for colors and coordinate with `VFX` for effects

This approach ensures proper separation of concerns:
- **WizardVisuals**: Handles wizard-specific rendering (sprite, spellslots, status effects)
- **VFX**: Manages particle effects, animations, and complex visual effects
- **ShieldSystem**: Handles shield-specific logic and visual properties

## Implementation Details

### WizardVisuals.lua

```lua
-- WizardVisuals.lua
-- Centralized visualization system for Wizard entities in Manastorm

local WizardVisuals = {}
local Constants = require("core.Constants")
local ShieldSystem = require("systems.ShieldSystem")

-- Draw the wizard with all visual elements
function WizardVisuals.drawWizard(wizard)
    -- Implementation extracted from wizard.lua Wizard:draw
    -- ...
end

-- Draw spell slots and tokens
function WizardVisuals.drawSpellSlots(wizard)
    -- Implementation extracted from wizard.lua Wizard:drawSpellSlots
    -- ...
end

-- Draw status effect indicators
function WizardVisuals.drawStatusEffects(wizard)
    -- Implementation extracted from wizard.lua Wizard:drawStatusEffects
    -- ...
end

-- Helper function to draw an ellipse
function WizardVisuals.drawEllipse(x, y, radiusX, radiusY, mode)
    -- Implementation extracted from wizard.lua Wizard:drawEllipse
    -- ...
end

-- Helper function to draw an elliptical arc
function WizardVisuals.drawEllipticalArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
    -- Implementation extracted from wizard.lua Wizard:drawEllipticalArc
    -- ...
end

-- Get appropriate status effect color
function WizardVisuals.getStatusEffectColor(effectType)
    -- New function to determine status effect colors
    -- ...
end

return WizardVisuals
```

### Wizard.lua Updates

```lua
-- Add WizardVisuals module import
local WizardVisuals = require("systems.WizardVisuals")

-- Replace draw method with wrapper
function Wizard:draw()
    WizardVisuals.drawWizard(self)
end

-- Remove original drawSpellSlots, drawStatusEffects, drawEllipse, drawEllipticalArc methods
-- They are now in the WizardVisuals module
```

## Dependencies

The WizardVisuals module will have the following dependencies:

1. **LÖVE Graphics**: For rendering (`love.graphics`)
2. **Constants**: For status and state values
3. **ShieldSystem**: For shield visuals and colors
4. **Wizard State**: For accessing wizard properties needed for visualization
5. **Asset Cache**: For sprite and visual assets
6. **VFX System**: For particle effects and animations

## Testing Strategy

1. Test each extracted function in isolation
2. Verify visual output matches the original
3. Test with various wizard states (aerial, grounded, stunned)
4. Validate spell slot and token visualization
5. Ensure status effects display correctly

## Future Enhancements

Once the initial extraction is complete, consider these enhancements:

1. Add support for visual themes or skins
2. Add animation transitions between states
3. Create specialized visualizations for different wizard types
4. Support for customizing colors and visual elements

## Backward Compatibility

To ensure backward compatibility during transition:
- Maintain the same visual appearance as before
- Keep wrapper methods in the Wizard class
- Verify all existing visualization functionality works correctly