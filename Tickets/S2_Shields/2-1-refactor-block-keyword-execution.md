# Ticket PROG-18: Refactor block Keyword Execution

## Goal
Make the block keyword only responsible for setting up the intent to create a shield when its spell resolves.

## Tasks

1. In keywords.lua, modify the block.execute function. Instead of just setting simple flags, have it return a structured shieldParams table within the results. Example:

```lua
execute = function(params, caster, target, results)
    results.shieldParams = {
        createShield = true,
        defenseType = params.type or "barrier",
        blocksAttackTypes = params.blocks or {"projectile"},
        reflect = params.reflect or false
        -- Mana-linking is now the default, no need for a flag
    }
    return results
end
```

2. Remove the direct setting of results.isShield, results.defenseType, etc., from the keyword's execute.

## Acceptance Criteria
The block keyword's execute function returns a shieldParams table in the results.