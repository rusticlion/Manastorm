# Ticket #5 – Event-List Execution Refactor

## Goal
Decouple combat logic from in-memory wizard structures by having compiledSpell.executeAll() return an event list ({type="Damage", amount=12, target="enemy"}) instead of mutating slots/tokens directly.

## Tasks
1. Define event schema in docs/combat_events.md.
2. Update SpellCompiler.executeAll to push events rather than side-effects (start with damage, block, conjure).
3. Add systems/EventRunner.lua that consumes events and applies them to game state.
4. Refactor wizard.lua & token logic to use EventRunner.
5. Backfill unit tests for a few spells to assert event → state changes.

## Deliverables
* Event schema doc.
* Spell compiler refactor.
* Event runner + tests.
* No gameplay regressions (manual test).

## Design notes
This is the big refactor—do it in a feature branch. Begin with a "dual‑path" flag so you can compare old vs new at runtime.

## Pitfalls
Order‑of‑operations bugs (e.g., tokens conjured before damage vs after). Use deterministic test seeds.

## Senior Feedback
* **Complexity Assessment**: This is the most ambitious ticket and represents the core decoupling effort. Currently, SpellCompiler.executeAll directly calls keyword execute functions which often mutate caster, target, or results directly, or interact with caster.manaPool. Changing this to a descriptive event system is a significant architectural shift.
* **Event Schema Scope**: The event schema must be comprehensive, covering all effects produced by keywords:
  * Damage events (amount, type)
  * Status effects (burn, freeze, stagger - type, duration, parameters)
  * Elevation changes (target, state, duration)
  * Range changes (new state)
  * Mana pool changes (conjure type/amount, dissipate type/amount, lock duration)
  * Cast time changes (delay/accelerate amount, target slot)
  * Spell cancellation (dispel/disjoint target slot)
  * Shield creation (type, blocks, reflect)
  * Echo, zone effects, etc.
* **EventRunner Implementation**: EventRunner.lua will become the only place state is mutated based on spell effects. Consider whether it processes events sequentially or needs processing phases (e.g., apply all state changes first, then calculate/apply damage).
* **Extensive Refactoring Scope**: This touches spellCompiler.lua, keywords.lua (execute functions now return event descriptions), wizard.lua (state changes applied by the runner), manapool.lua (token changes applied by the runner), and requires the new EventRunner.lua.
* **Testing Strategy**: The "deterministic test seeds" suggestion is vital. Develop comprehensive unit tests comparing the before/after behavior of specific spells with controlled game states.