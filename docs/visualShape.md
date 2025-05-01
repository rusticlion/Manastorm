# visualShape Property in Spell Definitions

## Overview

The `visualShape` property is an optional field in spell definitions that allows overriding the default visual template selection based on attackType. This property gives greater control over the visual representation of spells without requiring custom VFX definitions for every spell variant.

## Purpose

In Manastorm's visual system:

1. By default, the `VisualResolver` selects a base visual template based on a spell's `attackType`:
   - `PROJECTILE` → `proj_base`
   - `REMOTE` → `remote_base`
   - `ZONE` → `zone_base`
   - `UTILITY` → `util_base`

2. The `visualShape` property allows overriding this default mapping to select a more appropriate template.

## Example Use Case

Consider a spell like `Full Moon Beam` which has `attackType = REMOTE` but should visually appear as a beam:

```lua
MoonSpells.fullmoonbeam = {
    id = "fullmoonbeam",
    name = "Full Moon Beam",
    affinity = Constants.TokenType.MOON,
    description = "Channels moonlight into a beam",
    attackType = Constants.AttackType.REMOTE,
    visualShape = "beam",  -- Override to use beam template instead of remote template
    -- other properties...
}
```

Without the `visualShape` property, this spell would use the `remote_base` template (which might be an explosion effect). By setting `visualShape = "beam"`, it will use the `beam_base` template instead.

## Supported Values

The `visualShape` property supports the following values:

- `"beam"` - A sustained beam effect (uses `beam_base` template)
- `"bolt"` or `"orb"` or `"zap"` - Projectile effects (use `proj_base` template)
- `"blast"` or `"groundBurst"` - Area effects (use `zone_base` template)
- `"warp"`, `"surge"`, or `"affectManaPool"` - Utility effects (use `util_base` template)
- `"wings"` or `"mirror"` - Shield/barrier effects (use `shield_overlay` template)
- `"eclipse"` - Special effect (uses a specialized template)

## Implementation Details

1. The spell definition includes a `visualShape` property.
2. This property is carried through to the compiled spell.
3. When the spell is cast, the VisualResolver checks for this property in the event.
4. If found, it overrides the template selection logic to use the specified template instead of the default based on attackType.

## Benefits

- Maintains the benefit of the rules-driven VFX system while allowing visual customization
- Allows spells with the same attackType to have different visual styles
- Reduces the need for custom VFX definitions for every spell
- Separates the gameplay behavior (attackType) from visual representation (visualShape)

## Relationship with Other VFX Properties

The `visualShape` property works alongside other VFX-related properties:

- `vfx`: Directly specifies a VFX template (highest priority, bypasses VisualResolver)
- `visualShape`: Overrides the base template selection in VisualResolver
- `attackType`: Default method for determining base template (lowest priority)

## Example Implementation Flow

1. Spell definition includes `visualShape = "beam"`
2. Spell is cast, generates a DAMAGE event
3. DAMAGE handler creates an EFFECT event with the same visualShape
4. VisualResolver receives the event with visualShape property
5. VisualResolver maps "beam" to beam_base template
6. VFX is rendered using the beam_base template with appropriate colors and modifiers based on spell affinity