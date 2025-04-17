# Manastorm Shield System

This document describes the shield system in Manastorm, including its design, implementation, and intended interactions with other game systems.

## Overview

Shields are a special type of spell that persist after casting, keeping their mana tokens in orbit until the shield is depleted by blocking attacks or manually freed by the caster. Shields can block specific types of attacks depending on their defense type.

## Shield Types

There are three types of shields, each blocking different attack types:

| Shield Type | Blocks                  | Visual Color |
|-------------|-------------------------|--------------|
| Barrier     | Projectiles, Zones      | Yellow       |
| Ward        | Projectiles, Remotes    | Blue         |
| Field       | Remotes, Zones          | Green        |

## Attack Types

Spells can have the following attack types:

| Attack Type | Description                                       | Blocked By             |
|-------------|---------------------------------------------------|------------------------|
| Projectile  | Physical projectile attacks                       | Barriers, Wards        |
| Remote      | Magical attacks at a distance                     | Wards, Fields          |
| Zone        | Area effect attacks                              | Barriers, Fields       |
| Utility     | Non-offensive spells that affect the caster       | Cannot be blocked      |

## Shield Lifecycle

1. **Casting Phase**: 
   - During casting, shield spells behave like normal spells
   - Mana tokens orbit normally in the spell slot
   - The slot is marked with `willBecomeShield = true` flag

2. **Completion Phase**:
   - When casting completes, tokens are marked as "SHIELDING"
   - The spell slot is marked with `isShield = true`
   - A shield visual effect is created
   - Shield strength is represented by the number of tokens used

3. **Active Phase**:
   - The shield remains active indefinitely until destroyed
   - Tokens continue to orbit slowly in the spell slot
   - The slot cannot be used for other spells while the shield is active

4. **Blocking Phase**:
   - When an attack is directed at the wizard, shield checks occur
   - If a shield can block the attack type, the attack is blocked
   - A token is consumed and returned to the pool
   - Shield strength decreases as tokens are consumed

5. **Destruction Phase**:
   - When a shield's last token is consumed, it is destroyed
   - The spell slot is reset and becomes available for new spells

## Implementation Details

### Shield Properties

Shields have the following properties:

- `isShield`: Flag that marks a spell slot as containing a shield
- `defenseType`: The type of shield ("barrier", "ward", or "field")
- `tokens`: Array of tokens powering the shield (token count = shield strength)
- `blocksAttackTypes`: Table specifying which attack types this shield blocks
- `blockTypes`: Array form of blocksAttackTypes for compatibility
- `reflect`: Whether the shield reflects damage back to the attacker (default: false)

### Block Keyword

The `block` keyword is used to create shields:

```lua
block = {
    type = "ward",            -- Shield type (barrier, ward, field)
    blocks = {"projectile", "remote"}, -- Attack types to block
    reflect = false           -- Whether to reflect damage back
}
```

### Shield Creation

Shields are created through the `createShield` function in wizard.lua:

```lua
createShield(wizard, spellSlot, blockParams)
```

This function:
1. Marks the slot as a shield
2. Sets the defense type and blocking properties
3. Marks tokens as "SHIELDING"
4. Uses token count as the source of truth for shield strength
5. Slows down token orbiting for shield tokens
6. Creates shield visual effects

### Shield Blocking Logic

When a spell is cast, shield checking occurs in the `castSpell` function:

1. The attack type of the spell is determined
2. Each of the target's spell slots is checked for active shields
3. If a shield can block the attack type and has tokens remaining, the attack is blocked
4. A token is consumed and returned to the mana pool
5. If all tokens are consumed, the shield is destroyed

## Future Extensions

Possible future extensions to the shield system:

1. **Passive Shield Effects**: Shields that provide ongoing effects while active
2. **Shield Combinations**: Special effects when multiple shield types are active
3. **Shield Enhancements**: Items or spells that improve shield properties
4. **Shield Regeneration**: Shields that recover strength over time
5. **Shield Reflection**: More elaborate reflection mechanics
6. **Shield Overloading**: Effects that trigger when a shield is destroyed

## Debugging

Common issues with shields and their solutions:

1. **Tokens not showing in shield**: Check that tokens are marked as "SHIELDING" and not returned to the pool
2. **Shield not blocking attacks**: Verify shield has tokens remaining and that it blocks the attack type
3. **Shield persisting after depletion**: Check the shield destruction logic in wizard.lua

Shield debugging can be enabled in wizard.lua with detailed output to trace shield behavior.

## Cross-Module Interactions

The shield system interacts with several other game systems:

- **Mana Pool**: Tokens from shields are returned here when consumed or destroyed
- **Spell Compiler**: Handles compiled shield spells with block keywords
- **VFX System**: Creates visual effects for shields, blocks, and breaks
- **Elevation System**: Some shields also change elevation (e.g., Mist Veil)

## Example Shield Spells

1. **Mist Veil** (Ward): Blocks projectiles and remotes, elevates caster
2. **Stone Wall** (Barrier): Blocks projectiles and zones, grounds caster
3. **Energy Field** (Field): Blocks remotes and zones, mana-intensive

## Known Issues and Limitations

- Shields cannot currently be stacked in the same slot
- Attack types are fixed and cannot be dynamically modified
- Shield strength is EXACTLY equal to token count

## Best Practices

When implementing new shield-related functionality:

1. Always mark tokens as "SHIELDING" after the spell completes, not during casting
2. Use the `createShield` function to ensure consistent shield initialization
3. Check for null/nil values in shield properties to prevent runtime errors
4. Remember that token count is the source of truth for shield strength
5. When checking if a shield is depleted, check if no tokens remain