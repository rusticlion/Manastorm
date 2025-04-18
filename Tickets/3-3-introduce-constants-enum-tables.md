# Ticket #3 – Introduce Constants / Enum Tables

## Goal
Replace string literals used as enums (token types, target types, range states, etc.) with a single canonical table (Constants). Improves auto‑complete, reduces typos.

## Tasks
1. Create core/Constants.lua.
2. Populate subtables: Tokens, Targets, RangeStates, ShieldTypes… (pull the raw strings from keywords.lua).
3. Refactor modules to reference Constants.Tokens.FIRE etc.; start with keywords.lua, spellCompiler.lua.
4. Add a luacheck rule or custom CI script to forbid new magic strings (grep -e '\"fire\"').

## Deliverables
* Constants module.
* Refactor PR (touches <10 files).
* CI lint rule update.

## Design notes
Use plain tables not metatables to avoid runtime cost; constants are just shared values.

## Pitfalls
Watch for concatenation like "POOL_" .. side—replace with a helper Constants.pooleSide(side).

## Senior Feedback
* **Additional Files to Check**: Also check wizard.lua (uses "GROUNDED"/"AERIAL", potentially shield types), manapool.lua (uses token states like "FREE", "CHANNELED", "LOCKED", "DESTROYED", "SHIELDING"), and main.lua (uses "NEAR"/"FAR"). Perform a comprehensive codebase search to verify the <10 files estimate.
* **Naming Conventions**: Ensure consistent naming conventions across all constant types (e.g., Constants.RangeState.NEAR, Constants.TokenType.FIRE).
* **Dynamic String Usage**: The concatenation pattern ("POOL_" .. side) wasn't immediately visible in the reviewed code, but look for similar patterns during refactoring. In keywords.lua under dissipate, pay attention to target selection (params.target == "caster" and caster or target).
* **CI Rule Complexity**: Implementing a luacheck rule to reliably forbid magic strings across the codebase will be tricky, especially distinguishing legitimate strings from enum candidates. Start with a simple rule that can be refined over time.