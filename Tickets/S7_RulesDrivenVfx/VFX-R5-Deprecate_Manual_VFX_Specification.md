# Ticket #VFX-R5: Deprecate Manual VFX Specification

## Goal
Remove legacy spell-specific VFX declarations, relying primarily on the rule-driven `VisualResolver` with an override mechanic for special cases.

## Tasks
1. **Clean Up `spells.lua`:**
   * Remove most `vfx = { ... }` keyword entries and top-level `vfx = "effect"` properties.
   * Retain 1–2 showcase spells that intentionally set `effectOverride` (cinematic finishers).

2. **Adjust `Keywords.vfx` (`keywords.lua`):**
   * Change behavior: instead of creating an `EFFECT` event, simply set `results.effectOverride = params.effectOverride` (or `params.effect`) and return.

3. **Pass Override Through Compiler/Runner:**
   * Ensure `SpellCompiler.executeAll` or `EventRunner` copies `results.effectOverride` into the generated `EFFECT` event.
   * Alternatively, have `VisualResolver.pick` inspect `event.effectOverride` (preferred) – already planned in R2.

## Acceptance Criteria
* Majority of spells no longer specify VFX directly; visuals are resolved automatically.
* Override mechanism still works for designated spells.
* No runtime errors from missing VFX definitions.

## Design Notes / Pitfalls
* Double-check that removed manual VFX definitions are truly redundant.
* Keep at least one example spell using the override for regression testing. 