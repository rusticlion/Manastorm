# Shield On-Block Hooks

This document describes the on-block hook system for shield spells, which allows custom effects to be triggered when a shield successfully blocks an incoming spell.

## Overview

Shields can now define an `onBlock` callback function that is invoked whenever the shield successfully blocks an attack. This callback can emit events that are processed by the EventRunner, allowing for a wide variety of dynamic effects.

## onBlock Callback Signature

The `onBlock` callback has the following signature:

```lua
function onBlock(defender, attacker, slotIndex, blockInfo)
    -- Return an array of events to process
    return events
end
```

### Parameters

- `defender`: The wizard who owns the shield (shield caster)
- `attacker`: The wizard who cast the spell being blocked (may be nil)
- `slotIndex`: The spell slot index where the shield is active
- `blockInfo`: A table with contextual information about the block:
  - `blockType`: The type of shield (barrier, ward, field)

### Return Value

The callback should return an array of events to be processed by the EventRunner. Each event should follow the standard event structure defined in the EventRunner system.

## Examples

### Simple Elevation on Block

```lua
onBlock = function(defender, attacker, slotIndex, blockInfo)
    return {{
        type = "SET_ELEVATION",
        source = "caster",
        target = "self",
        elevation = "AERIAL",
        duration = 4.0
    }}
end
```

### Counter Damage

```lua
onBlock = function(defender, attacker, slotIndex, blockInfo)
    if not attacker then return {} end
    
    return {{
        type = "DAMAGE",
        source = "caster",
        target = "enemy",
        amount = 10,
        damageType = "fire"
    }}
end
```

### Multiple Effects

```lua
onBlock = function(defender, attacker, slotIndex, blockInfo)
    local events = {}
    
    -- Deal counter damage
    table.insert(events, {
        type = "DAMAGE",
        source = "caster",
        target = "enemy",
        amount = 8,
        damageType = "fire"
    })
    
    -- Accelerate next spell
    table.insert(events, {
        type = "ACCELERATE_SPELL",
        source = "caster",
        target = "self_slot",
        slotIndex = 0,
        amount = 2.0
    })
    
    return events
end
```

## Creating Custom Shield Spells

To create a shield spell with an on-block hook:

1. Define a normal spell with the `block` keyword
2. Add an `onBlock` function to the block keyword parameters
3. Return an array of events from the `onBlock` function

The events will be processed through the EventRunner system, maintaining compatibility with all existing game systems.