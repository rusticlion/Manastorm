# Status Effects

This document lists the built-in status effects available in the game and their expected behavior. All status types are defined in `core/Constants.lua` under `Constants.StatusType`.

## Available Statuses

| Status | Description |
|--------|-------------|
| `BURN` | Deals periodic damage over time. Damage ticks use `tickDamage` at intervals defined by `tickInterval` for the duration of the effect. |
| `SLOW` | Increases the cast time of the next spell by `magnitude` seconds. Can optionally target a specific slot. Consumed after affecting a cast or when the duration expires. |
| `STUN` | Prevents the affected wizard from keying or casting spells for the duration. |
| `REFLECT` | Causes the wizard to reflect incoming spells while active. |

## Usage

Status effects are applied through `APPLY_STATUS` events emitted by keywords or spell logic. Event handlers store the effect data on the target wizard in the `statusEffects` table.

```lua
-- Example APPLY_STATUS event
{
    type = "APPLY_STATUS",
    source = "caster",
    target = "enemy",
    statusType = Constants.StatusType.BURN,
    duration = 3.0,
    tickDamage = 2,
    tickInterval = 1.0
}
```

The `EventRunner` module processes these events and manages status state each frame.

