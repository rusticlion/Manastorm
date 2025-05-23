# SCT-3: UI Display of Dynamic Costs

**Goal:** Update the UI (spellbook modal, keyed spell popup) to appropriately display costs for spells that might be dynamic.

## Tasks

### 1. Modify ui.lua - UI.drawSpellbookModal (and its internal formatCost)
- The `formatCost` helper and the spell display logic currently expect `spell.cost` to be a static table
- When displaying a spell's cost, check if `spell.getCost` exists
- If it does, call `local displayCost = spell.getCost(wizard, opponentWizard)` to get the current cost for display purposes
  - Need to ensure `opponentWizard` is available in this context, or `getCost` functions need to be robust to a nil target if not relevant
- Then, use `displayCost` with the `formatCost` helper
- Consider adding a visual indicator (e.g., an asterisk `*` or a different color) if a spell's cost is dynamic to inform the player

### 2. Modify ui.lua - UI.drawPlayerSpellbook (for keyed spell popup)
- Similar to the spellbook modal, if `wizard.currentKeyedSpell.getCost` exists, evaluate it in the current context to display its cost
- Note: This part of the UI doesn't currently show cost, but if it were to be added, it would need this logic
- The keyed spell popup `wizard.currentKeyedSpell.name` is drawn. Cost is not shown there, so no change needed for this specific part unless we decide to add cost display there

### 3. Modify characterData.lua or spell definitions (spells/elements/*.lua)
- If a spell uses `getCost`, its static cost field could represent a "base cost" or "typical cost" for display if evaluating the dynamic one is too complex or volatile for a quick UI glance
- The UI would then need to be aware of this convention
- For simplicity now, we'll assume UI always tries to evaluate `getCost`

## Acceptance Criteria
- Spellbook UI displays the dynamically calculated cost of spells if `getCost` is defined
- (Optional) UI indicates that a spell's cost is dynamic

## Design Notes/Pitfalls
- Displaying a constantly changing cost in the UI might be distracting
- A "base cost" with an indicator, or evaluating it only when the spellbook is opened, might be better UX long-term
- For now, live evaluation is simplest to implement
- The `formatCost` helper itself likely doesn't need changes, as it already expects a resolved cost table