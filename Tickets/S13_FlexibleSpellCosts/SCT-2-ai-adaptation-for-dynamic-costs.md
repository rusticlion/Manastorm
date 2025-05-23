# SCT-2: AI Adaptation for Dynamic Costs

**Goal:** Enable the AI to understand and correctly evaluate the affordability of spells with dynamic costs.

## Tasks

### 1. Modify ai/OpponentAI.lua - OpponentAI:decide()
When the AI considers casting a spell (e.g., `spell = self.personality:getAttackSpell(...)`), it currently checks `self.wizard:canPayManaCost(spell.cost)`.

This check needs to be updated to correctly use the dynamic cost function if available:

```lua
local costToEvaluate
if spell.getCost then
    -- AI needs to evaluate the cost in its current perceived context
    -- The OpponentAI's 'self.wizard' is the AI's wizard, 'self.playerWizard' is the opponent
    costToEvaluate = spell.getCost(self.wizard, self.playerWizard) 
else
    costToEvaluate = spell.cost
end
local canAfford = self.wizard:canPayManaCost(costToEvaluate)

if spell and self:hasAvailableSpellSlot() and canAfford then
    return { type = "CAST_SPELL", spell = spell, reason = reason }
end
```

### 2. Modify Personality Modules (e.g., ai/personalities/SelenePersonality.lua)
- No direct changes needed in how personalities return spells
- They should continue to return the spell object
- The core AI (`OpponentAI:decide()`) will handle the dynamic cost evaluation
- However, more advanced personality logic might internally call `wizard:canPayManaCost(spell.getCost and spell.getCost(...) or spell.cost)` if it needs to make finer-grained decisions about which spell to suggest based on fluctuating costs
- For now, this isn't strictly necessary

## Acceptance Criteria
- The AI correctly determines if it can afford a spell with a dynamic cost
- The AI attempts to cast dynamically-costed spells only when affordable based on the current game state

## Design Notes/Pitfalls
- The AI's perception of the game state (which `getCost` might depend on) might be slightly delayed due to `perceptionInterval`
- This is generally acceptable for AI behavior