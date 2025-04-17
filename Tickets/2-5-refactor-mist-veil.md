# Ticket PROG-21: Refactor Mist Veil

## Goal
Remove the custom executeAll from Spells.mist and define it purely using keywords.

## Tasks

1. In spells.lua, remove the executeAll function from Spells.mist.

2. Ensure its keywords table correctly defines both the block keyword parameters and the elevate keyword parameters:

```lua
keywords = {
    block = { type = "ward", blocks = {"projectile", "remote"} },
    elevate = { duration = 4.0 }
}
```

## Acceptance Criteria
Mist Veil works correctly using the standard keyword compilation and resolution process.