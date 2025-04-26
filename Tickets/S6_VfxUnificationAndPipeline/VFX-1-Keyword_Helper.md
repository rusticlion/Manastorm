# Ticket #VFX-1: Implement VFX Keyword Helper & Centralize Triggering

## Goal
Introduce a dedicated `vfx` keyword to allow spells to declaratively specify their visual effects. Centralize all spell-related VFX triggering through the event system by removing the direct call from `Wizard:castSpell`.

## Tasks

1.  **Create `vfx` Keyword Helper (`keywords.lua`):**
    *   Add the following definition to the `Keywords` table:
        ```lua
        Keywords.vfx = {
            behavior = {
                triggersVisualEffect = true, -- Add descriptive behavior flag
                category = "SPECIAL"         -- Or maybe a new "VISUAL" category
            },
            execute = function(params, caster, target, results, events)
                -- Default target to ENEMY if not specified, matching most spell effects
                local eventTarget = params.target or Constants.TargetType.ENEMY 
                table.insert(events or {}, {
                    type       = "EFFECT", -- Use the existing EFFECT event type
                    source     = Constants.TargetType.CASTER, -- Effects originate from caster
                    target     = eventTarget, -- Target where the effect appears (can be overridden)
                    effectType = params.effect or "impact", -- The specific VFX template name (e.g., "firebolt")
                    duration   = params.duration, -- Optional duration override
                    -- Pass through any other params for the VFX system
                    vfxParams  = params -- Store original params for flexibility
                })
                return results -- Return unmodified results (only adds an event)
            end
        }
        ```
    *   Ensure the `EFFECT` event structure aligns with `docs/combat_events.md`.

2.  **Integrate `vfx` Keyword into Example Spells (`spells.lua`):**
    *   Find the `Spells.firebolt` definition.
    *   Add the `vfx` keyword to its `keywords` table:
        ```lua
        Spells.firebolt = {
            -- ... other properties ...
            keywords = {
                damage = { ... },
                vfx = { effect = "firebolt" } -- Add this line
            },
            -- Remove the top-level vfx = "fire_bolt" if it exists, or ensure compiler prioritizes keyword
            -- ... other properties ...
        }
        ```
    *   Do the same for 1-2 other spells (e.g., `meteor`, `conjurefire`) to test integration.

3.  **Update Spell Compiler (Optional but Recommended) (`spellCompiler.lua`):**
    *   Modify `compileSpell` to automatically convert a top-level `spellDef.vfx = "some_effect"` into the equivalent `keywords.vfx = { effect = "some_effect" }` if the keyword isn't already present. This provides backward compatibility and a simpler definition option. Prioritize the explicit keyword if both exist.

4.  **Remove Direct VFX Call (`wizard.lua`):**
    *   In the `Wizard:castSpell` function, locate and **delete** the line:
        ```lua
        -- if self.gameState and self.gameState.vfx then -- DELETE THIS BLOCK
        --     self.gameState.vfx.createSpellEffect(spellToUse, self, target)
        -- end
        ```
    *   Verify that VFX are now solely triggered via the `EFFECT` event processed by the `EventRunner`.

## Deliverables
-   Updated `keywords.lua` with the new `Keywords.vfx` definition.
-   Updated `spells.lua` with `vfx` keywords added to `firebolt` and 1-2 other spells.
-   (Optional) Updated `spellCompiler.lua` to handle top-level `vfx` field conversion.
-   Updated `wizard.lua` with the direct `createSpellEffect` call removed from `castSpell`.
-   Manual Test: Cast `firebolt` (and other modified spells) and verify their visual effects still trigger correctly via the event system.

## Design Notes/Pitfalls
-   The `EFFECT` event handler already exists in `EventRunner`, so this keyword leverages existing infrastructure.
-   Ensure the `effectType` string passed in the event (e.g., `"firebolt"`) exactly matches a key in the `VFX.effects` table in `vfx.lua`. Mismatches will likely default to a generic "impact" effect (see Sprint 2).
-   The `vfxParams` field in the event is added for potential future use where specific keyword parameters might need to influence the visual effect directly (e.g., damage amount affecting impact size).