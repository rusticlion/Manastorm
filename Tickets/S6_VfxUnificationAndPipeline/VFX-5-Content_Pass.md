# Ticket #VFX-5: VFX Content Pass & Validation

## Goal
Ensure all spells have appropriate visual effects triggered via the event system, establish a clear visual language reference, and add automated testing for VFX event generation.

## Tasks

1.  **Audit Spell VFX (`spells.lua`, Engineer):**
    *   Go through *every* spell definition in `spells.lua`.
    *   For each spell, ensure it either:
        *   Has an appropriate `keywords.vfx = { effect = Constants.VFXType.SOME_EFFECT }` entry.
        *   Or, if it uses multiple keywords that should *each* produce a visual (like `ground` and `damage` in `gravity`), ensure those keywords' `execute` functions are correctly generating `EFFECT` events (may require modifying `keywords.lua` for some keywords).
        *   Or, if it's a `UTILITY` spell with no intended visual, confirm this is intentional.
    *   Add missing `vfx` keywords or modify keyword `execute` functions as needed. Use existing VFX types or add new basic ones (`impact`, `aura`) if required.

2.  **Create Visual Language Reference (Docs/Spreadsheet, Artist/Designer + Engineer):**
    *   Create a document (e.g., `docs/Visual_Language.md` or a spreadsheet) mapping game concepts to visual elements.
    *   **Columns:** Element (Fire, Moon, etc.), Concept (Damage, Heal, Buff, Debuff, Conjure, Shield Break, etc.), Target (Self, Enemy, Pool), VFX Name (`Constants.VFXType`), Particle Sprite (`VFX.assetPaths`), Core Color (`Constants.Color`), Notes.
    *   Fill this out based on existing effects and desired look-and-feel. This helps ensure consistency and provides a reference for creating new VFX presets.

3.  **Implement VFX Event Test (`tools/test_vfx_events.lua`, Engineer):**
    *   Create a new test script.
    *   Load all spells from `spells.lua`.
    *   For each spell:
        *   Compile it using `SpellCompiler.compileSpell`.
        *   Call the `compiledSpell.generateEvents(dummyCaster, dummyTarget, dummySlot)` method (a simplified version of `executeAll` that *only* generates events without running `EventRunner`).
        *   Assert that the returned `events` table contains at least one event with `type == "EFFECT"`, unless the spell is `attackType == Constants.AttackType.UTILITY` and known to have no visual.
    *   This test ensures that compilation and keyword execution are correctly set up to produce visual effect events.

## Deliverables
-   Updated `spells.lua` (and potentially `keywords.lua`) ensuring all non-utility spells trigger at least one `EFFECT` event.
-   `docs/Visual_Language.md` (or spreadsheet) defining the mapping between game concepts and visual styles.
-   `tools/test_vfx_events.lua` script that automatically verifies basic VFX event generation for all spells.
-   Test script passes.

## Design Notes/Pitfalls
-   Some spells might logically have multiple visual components (e.g., a projectile *and* an impact). Ensure the system supports triggering multiple `EFFECT` events from a single spell cast if needed.
-   The visual language document is crucial for maintaining consistency as more effects are added.
-   The automated test won't verify *correctness* of the VFX, only that an `EFFECT` event *is generated*. Manual testing is still needed for visual quality.