# Wizard Module (`wizard.lua`)

## Overview

The `wizard.lua` module defines the "class" for the player characters in Manastorm. It encapsulates the state, capabilities, and core logic for each wizard participating in the duel. This includes handling health, position, status effects, spellcasting (keying, channeling, casting, shielding), input interpretation (via delegation), updates, and drawing.

## Key Components

### 1. State Variables

Each `Wizard` instance maintains a comprehensive set of state variables:

*   **Identity & Position:** `name`, `x`, `y`, `color`.
*   **Combat:** `health`.
    * `statusEffects[Constants.StatusType.STUN]`: Tracks stun duration.
*   **Positioning:**
    *   `elevation`: String ("GROUNDED" or "AERIAL").
    *   `elevationTimer`: Duration for temporary AERIAL state.
    *   `currentXOffset`, `currentYOffset`: Calculated visual offsets based on game range state (`NEAR`/`FAR`) and elevation, used for drawing.
*   **Status Effects:** `statusEffects` table (e.g., `statusEffects.burn` tracks active state, duration, tick damage, timers).
*   **Spellcasting State:**
    *   `spellbook`: Table mapping key combinations ("1", "12", "123") to specific spell definitions from `SpellsModule`. Unique per wizard name ("Ashgar", "Selene").
    *   `activeKeys`: Table tracking pressed state of spell keys [1], [2], [3].
    *   `currentKeyedSpell`: Reference to the spell definition matching `activeKeys`.
    *   `spellSlots`: Array of 3 tables, each representing a casting/shield slot. Tracks:
        *   `active`: Boolean indicating if the slot is in use.
        *   `progress`: Current casting time elapsed.
        *   `castTime`: Total time required to cast the spell (can be dynamic).
        *   `spell`: Reference to the compiled spell object.
        *   `spellType`: Name of the spell.
        *   `tokens`: Array table holding references to mana tokens ({token=..., index=...}) currently channeled or part of a shield in this slot.
        *   `isShield`: Boolean indicating if the slot holds an active shield.
        *   `defenseType`: String ("barrier", "ward", "field") for shield type.
        *   `blocksAttackTypes`: Table mapping attack types this shield blocks.
        *   `reflect`: Boolean indicating if the shield reflects damage.
        *   `frozen`: Boolean indicating if the spell cast is paused (e.g., by Eclipse Echo).
        *   `freezeTimer`: Remaining duration for the frozen state.
*   **Visuals:** `sprite` (loaded image), `scale`, `blockVFX` (timer/state for block visuals).
*   **References:** `manaPool` (instance of ManaPool), `gameState` (reference to the global `game` table in `main.lua`).

### 2. Core Methods

*   **`Wizard.new(name, x, y, color)`:** Constructor. Initializes all state variables, loads sprite, sets up spellbook based on `name`.
*   **`Wizard:update(dt)`:** Per-frame update logic. Manages timers (stun, elevation, status effects), applies burn damage ticks, updates shield token orbits, increments spell casting `progress`. Calls `castSpell` upon completion.
*   **`Wizard:draw()`:** Main drawing function. Draws the wizard sprite (applying offsets/effects), elevation visuals, status bars (`drawStatusEffects`), and spell slots (`drawSpellSlots`).
*   **`Wizard:drawSpellSlots()`:** Visualizes casting/shields. Draws elliptical orbits, progress arcs (colored by state: casting, shield, frozen), shield type names, and orbiting mana tokens (with Z-ordering for depth).
*   **`Wizard:keySpell(keyIndex, isPressed)`:** Updates `activeKeys` and `currentKeyedSpell` based on player input.
*   **`Wizard:castKeyedSpell()`:** Entry point for casting. Checks stun state, validates `currentKeyedSpell`, and calls `queueSpell`.
*   **`Wizard:queueSpell(spell)`:** Initiates spell casting.
    *   Finds an available `spellSlot`.
    *   Checks mana availability using `canPayManaCost`.
    *   If affordable, acquires token references from `manaPool` via reservations.
    *   Sets token state to `CHANNELED`.
    *   Sets up animation parameters for tokens (Bezier curve towards wizard).
    *   Activates the `spellSlot`, storing spell info and cast time.
    *   Flags slot if it `willBecomeShield`.
*   **`Wizard:castSpell(spellSlot)`:** Executes the spell effect when casting completes.
    *   Performs preemptive shield check on the target (`checkShieldBlock`).
    *   If blocked: calls `target:handleShieldBlock`, returns caster's tokens, resets caster's slot (`resetSpellSlot`).
    *   If not blocked: Executes spell logic via `spell.executeAll` (compiled) or legacy system.
    *   Interprets returned `effect` table:
        *   Shield Spells: Calls local `createShield` helper, potentially applies elevation, leaves slot active with tokens (`isShield=true`).
        *   Normal Spells: Applies damage (`target.health`), status effects (burn, stun), position changes (range, elevation), mana manipulation (lock, delay) based on `effect` table. Returns caster's tokens (`requestReturnAnimation`/`manaPool:returnToken`), resets caster's slot (`resetSpellSlot`).
*   **`Wizard:handleShieldBlock(slotIndex, blockedSpell)`:** (Called on the target wizard). Consumes tokens from the specified shield slot based on `blockedSpell.shieldBreaker`, returns consumed tokens, and calls `resetSpellSlot` if the shield breaks (runs out of tokens).
*   **`Wizard:resetSpellSlot(slotIndex)`:** Utility function to reset all properties of a spell slot to default/inactive state and clear its token list. Used after normal casts, cancellations, or shield breaks.
*   **`Wizard:canPayManaCost(cost)`:** Checks if mana cost can be paid from `manaPool` *without* consuming tokens. Returns reservation details or `nil`.
*   **`Wizard:freeAllSpells()`:** Cancels all active spells/shields, returns their tokens, and resets the corresponding slots.

### 3. Token Interaction

The Wizard module interacts heavily with the `ManaPool` and individual token objects:

*   Uses `canPayManaCost` to check availability.
*   Reserves tokens during `queueSpell`.
*   Sets token state to `CHANNELED`.
*   Manages token position updates *while they are animating towards or orbiting the wizard*.
*   Initiates token return via `token:requestReturnAnimation()` (preferred) or `manaPool:returnToken()` (fallback).
*   Shields maintain references to their tokens; `handleShieldBlock` removes tokens from the target's shield slot and initiates their return.

### 4. Potential Cleanup Areas

*   Consider factoring to smaller modules.

## Dependencies

*   `core.Constants`
*   `core.AssetCache`
*   `spells` (SpellsModule)
*   `manapool` (via `self.manaPool` reference)
*   Global `game` state (via `self.gameState` reference) for accessing `vfx`, `wizards` list, `rangeState`.
*   Local `getCompiledSpell` helper (defined within `wizard.lua`)
*   Local `checkShieldBlock` helper (defined within `wizard.lua`)
*   Local `createShield` helper (defined within `wizard.lua`) 