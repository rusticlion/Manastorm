# SCT-4: Example Spell Implementation

**Goal:** Implement 1-2 spells that utilize the new dynamic getCost feature to demonstrate and test its functionality.

## Tasks

### 1. Choose/Design Spells
- **Example 1:** A "Desperation Strike" spell whose cost in FIRE tokens decreases as the caster's health gets lower
- **Example 2:** A "Resource Drain" spell whose cost in MOON tokens increases based on the number of STAR tokens the opponent has in their active spell slots

### 2. Implement in spells/elements/*.lua

#### Example: Desperation Fire
```lua
-- Example: Desperation Fire
Spells.desperationFire = {
    id = "desperationfire",
    name = "Desperation Fire",
    affinity = Constants.TokenType.FIRE,
    description = "A fiery attack whose Fire cost decreases as your health lowers.",
    attackType = Constants.AttackType.PROJECTILE,
    castTime = Constants.CastSpeed.NORMAL,
    cost = { Constants.TokenType.FIRE, Constants.TokenType.FIRE, Constants.TokenType.FIRE }, -- Base/max cost for UI reference
    keywords = { damage = { amount = 15, type = Constants.DamageType.FIRE } },
    getCost = function(caster, target)
        local fireCost = 3
        if caster.health < 75 then fireCost = 2 end
        if caster.health < 40 then fireCost = 1 end
        if caster.health < 20 then fireCost = 0 end -- Free at critical health
        
        local finalCost = {}
        for i = 1, fireCost do
            table.insert(finalCost, Constants.TokenType.FIRE)
        end
        -- Add any other static costs if necessary
        -- table.insert(finalCost, Constants.TokenType.ANY) 
        return finalCost
    end
}
```

#### Example: Moon Drain
```lua
-- Example: Moon Drain (cost depends on opponent's channeled STAR tokens)
Spells.moonDrain = {
    id = "moondrain",
    name = "Moon Drain",
    affinity = Constants.TokenType.MOON,
    description = "Drains opponent. Costs more Moon tokens if opponent is channeling Star mana.",
    attackType = Constants.AttackType.REMOTE,
    castTime = Constants.CastSpeed.FAST,
    cost = { Constants.TokenType.MOON }, -- Base cost
    keywords = { damage = { amount = 8, type = Constants.DamageType.MOON } },
    getCost = function(caster, target)
        local moonTokens = 1
        if target then
            for _, slot in ipairs(target.spellSlots) do
                if slot.active and slot.tokens then
                    for _, tokenData in ipairs(slot.tokens) do
                        if tokenData.token.type == Constants.TokenType.STAR then
                            moonTokens = moonTokens + 1
                        end
                    end
                end
            end
        end
        local finalCost = {}
        for i = 1, math.min(moonTokens, 4) do -- Cap cost increase
            table.insert(finalCost, Constants.TokenType.MOON)
        end
        return finalCost
    end
}
```

### 3. Add to a Character's Spellbook (characterData.lua)
Make these spells available to test.

## Acceptance Criteria
- The example spells function correctly, with their costs changing based on the defined game state conditions
- These spells can be cast by both player and AI (if AI is configured to use them)

## Design Notes/Pitfalls
- `getCost` functions should be relatively lightweight
- Can reuse `expr.lua` helpers within `getCost` if the desired output is a token type string, though direct logic as shown above is also fine