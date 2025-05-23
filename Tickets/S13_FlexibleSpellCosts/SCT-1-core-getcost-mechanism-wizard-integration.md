# SCT-1: Core getCost Mechanism & Wizard Integration

**Goal:** Establish the foundational mechanism for dynamic costs and integrate it into the wizard's spellcasting logic.

## Tasks

### 1. Modify spells/schema.lua
- Update the `validateSpell` function to acknowledge an optional `getCost` function in spell definitions
- If `getCost` is present, the static cost table can still exist (perhaps as a "base" or "UI display" cost) or be optional
- For now, assume if `getCost` exists, it's the source of truth at runtime

### 2. Modify wizard.lua - Wizard:canPayManaCost(costOrGetCostFn)
- This function currently takes a cost table
- Update to accept either a cost table OR the spell.getCost function
- If `costOrGetCostFn` is a function, call it: `local actualCost = costOrGetCostFn(self, target, nil)`
  - Note: `canPayManaCost` is often called without a specific target context (e.g., by AI checking general affordability)
  - The `getCost` function signature should account for this: `getCost(caster, [potentialTarget])`
- The rest of `canPayManaCost` (token reservation logic) will then use `actualCost`

### 3. Modify wizard.lua - Wizard:queueSpell(spell)
- When checking affordability, pass `spellToUse.getCost` or `spellToUse.cost` to `self:canPayManaCost()`
- When acquiring tokens with `TokenManager.acquireTokensForSpell`, if `spellToUse.getCost` exists, call it to get the `actualCost` table to pass to TokenManager. Otherwise, pass `spellToUse.cost`
- The `spellToUse.cost` in the `spellSlots[i]` entry should ideally store the actual cost paid if it was dynamic, for potential future use (e.g., Dispel keyword). For now, storing the original reference is fine

### 4. Modify TokenManager.acquireTokensForSpell (if needed)
- Ensure it robustly handles the `manaCost` table passed to it, which will now always be a resolved table of token types/counts
- No major changes likely needed here if wizard.lua does the resolution

## Acceptance Criteria
- A spell can be defined with a `getCost` function
- `Wizard:canPayManaCost` correctly evaluates affordability using the dynamic cost if `getCost` is present
- `Wizard:queueSpell` correctly acquires tokens based on the dynamically calculated cost
- Spells with static costs continue to work as before

## Design Notes/Pitfalls
- The `getCost` function must return a table in the same format as the static cost property (e.g., `{Constants.TokenType.FIRE, Constants.TokenType.WATER}` or `{ [Constants.TokenType.FIRE] = 2 }`)
- Ensure the caster (and potentially target if relevant for a specific spell's dynamic cost) context is correctly passed to `getCost`