# Ticket #VFX-2: Formalize VFX Event Contract & Validation

## Goal
Strengthen the connection between gameplay events and visual effects by using constants for effect names and adding validation within the EventRunner to prevent crashes from unknown effect types.

## Tasks

1.  **Define VFX Constants (`core/Constants.lua`):**
    *   Add a new sub-table `Constants.VFXType = {}`.
    *   Populate it with constants corresponding to the keys in the `VFX.effects` table registry found in `vfx.lua`. Examples:
        ```lua
        Constants.VFXType = {
            IMPACT = "impact",
            FIREBOLT = "firebolt",
            METEOR = "meteor",
            MISTVEIL = "mistveil",
            EMBERLIFT = "emberlift",
            -- ... add ALL effect names from vfx.lua ...
            CONJURE_FIRE = "conjurefire",
            CONJURE_MOONLIGHT = "conjuremoonlight",
            SHIELD = "shield",
            GRAVITY_TRAP_SET = "gravity_trap_set",
            -- etc.
        }
        ```

2.  **Update Keyword & Spells (`keywords.lua`, `spells.lua`):**
    *   Modify the `Keywords.vfx.execute` function to expect and use constants: `effectType = params.effect or Constants.VFXType.IMPACT`.
    *   Update the spell definitions modified in VFX-1 (e.g., `firebolt`) to use the constants: `keywords.vfx = { effect = Constants.VFXType.FIREBOLT }`.

3.  **Add Validation in EventRunner (`systems/EventRunner.lua`):**
    *   Locate the `EFFECT` handler function within `EventRunner.EVENT_HANDLERS`.
    *   Before calling `safeCreateVFX`, validate `event.effectType`:
        *   Check if `event.effectType` exists as a value within `Constants.VFXType` (or directly check against `VFX.effects` keys if simpler).
        *   If the `effectType` is invalid or nil, log a warning (`print("Warning: Unknown effectType '"..tostring(event.effectType).."' requested by event. Defaulting to impact.")`) and set `event.effectType = Constants.VFXType.IMPACT` before calling `safeCreateVFX`.

## Deliverables
-   Updated `core/Constants.lua` with the `Constants.VFXType` table.
-   Updated `keywords.lua` and `spells.lua` (for spells modified in VFX-1) to use `Constants.VFXType`.
-   Updated `systems/EventRunner.lua` with validation logic in the `EFFECT` handler.
-   Manual Test: Intentionally trigger an `EFFECT` event with an invalid `effectType` and verify that a warning is logged and the default "impact" VFX plays without crashing.

## Design Notes/Pitfalls
-   Using constants prevents typos in effect names.
-   Validation in the `EventRunner` makes the system more robust against data errors in spell definitions.
-   Ensure *all* effect names from `vfx.lua` are added to `Constants.VFXType`.