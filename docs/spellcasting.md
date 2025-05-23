# Manastorm Spell System

## Overview

The spell system in Manastorm is designed to be modular and data-driven, allowing for complex spell effects to be defined by combining simpler, reusable components. It revolves around four key files, which can be thought of using a kitchen metaphor:

1.  **`keywords.lua`**: The **Ingredients** - Defines atomic game actions.
2.  **`spells.lua`**: The **Recipes** - Combines ingredients (keywords) into specific spells.
3.  **`spellCompiler.lua`**: The **Chef** - Prepares the recipes for execution.
4.  **`systems/EventRunner.lua`**: The **Waiter** - Delivers the effects of the prepared spell to the game state.

This system is transitioning towards a pure event-based architecture, where spell effects generate descriptive events that are then processed centrally, ensuring consistent application order and state management.

## Core Components

### 1. `keywords.lua` - The Ingredients

*   **Purpose:** Defines the fundamental "verbs" or atomic actions that spells can perform. Each keyword represents a specific game mechanic (e.g., dealing damage, applying a status effect, changing position, manipulating tokens).
*   **Structure:** A large Lua table (`Keywords`) where each key is a keyword name (e.g., `damage`, `elevate`, `conjure`, `block`). The value is a table containing:
    *   `behavior`: A sub-table describing the keyword's effect conceptually (e.g., `dealsDamage = true`, `targetType = Constants.TargetType.ENEMY`, `category = "DAMAGE"`). This acts as metadata and helps define default parameters.
    *   `execute`: A function implementing the keyword's logic. **Crucially, this function should ideally generate events rather than directly modify game state.** It takes `caster`, `target`, `params`, `results` (for legacy compatibility), and an `events` table as arguments. It should add event tables (e.g., `{ type = "DAMAGE", ... }`) to the `events` list.
*   **Event-Based Shift:** Comments emphasize that new keywords should generate events processed by the `EventRunner`. Older keywords might still directly modify the `results` table for backward compatibility.

### 2. `spells.lua` - The Recipes

*   **Purpose:** Defines the concrete spells available by combining keywords (`ingredients`) with specific parameters. Acts as a database of spell definitions.
*   **Structure:** A large Lua table (`Spells`) where each key is a unique spell ID (e.g., `firebolt`). The value is a table adhering to a schema:
    *   **Basic Info:** `id`, `name`, `description`.
    *   **Mechanics:** `attackType` (`projectile`, `remote`, `zone`, `utility`), `castTime`, `cost` (array of token types like `Constants.TokenType.FIRE`). If a `getCost` function is provided it will be used at runtime instead of the static table.
    *   **`keywords`:** **The core.** A table mapping keyword names (from `keywords.lua`) to parameter tables (e.g., `damage = { amount = 10 }`, `elevate = { duration = 5.0 }`). Parameters can be static values or functions.

    The optional `getCost(caster, target)` function allows a spell's mana cost to change based on game state. It should return a table of token types just like the static `cost` field. `getCost` is evaluated each time the spell is queued or affordability is checked.

    **Example:** A spell that gets cheaper as the caster's health drops might be implemented as:

    ```lua
    getCost = function(caster)
        local fireCost = 3
        if caster.health < 75 then fireCost = 2 end
        if caster.health < 40 then fireCost = 1 end
        if caster.health < 20 then fireCost = 0 end
        local t = {}
        for i = 1, fireCost do
            t[i] = Constants.TokenType.FIRE
        end
        return t
    end
    ```
*   **Optional:** `vfx`, `sfx`, `getCastTime` (dynamic cast time function), `getCost` (dynamic mana cost), `onBlock`/`onMiss`/`onSuccess` (legacy callbacks).
*   **Validation:** Includes a `validateSpell` function called at load time to ensure schema adherence and add defaults, printing warnings for issues.

### 3. `spellCompiler.lua` - The Chef

*   **Purpose:** Takes a raw spell definition (`recipe`) from `spells.lua` and "compiles" it into an optimized, executable object, ready to be used in the game.
*   **Compilation (`compileSpell` function):**
    *   Creates a `compiledSpell` table, copying basic properties.
    *   Iterates through the `spellDef.keywords`.
    *   For each keyword, finds the corresponding definition in `keywords.lua`.
    *   Merges default keyword `behavior` with spell-specific `params` into `compiledSpell.behavior[keyword]`.
    *   Binds the `keywords.lua` `execute` function to `compiledSpell.behavior[keyword].execute`.
*   **Execution (`executeAll` method):**
    *   Adds an `executeAll` method to the `compiledSpell` object.
    *   Called by `Wizard:castSpell` when a spell finishes casting.
    *   Iterates through all behaviors defined in `compiledSpell.behavior`.
    *   Calls the bound `execute` function for each keyword, passing context (`caster`, `target`) and an **empty `events` table**.
    *   Keywords populate the `events` table.
    *   Calls `EventRunner.processEvents(events, ...)` to handle the generated events.
    *   Returns a `results` table (combining legacy results and the `EventRunner` summary).
*   **Configuration:** Includes toggles (`setUseEventSystem`, `setDebugEvents`) for debugging and controlling the execution path.

### 4. `systems/EventRunner.lua` - The Waiter

*   **Purpose:** Takes the list of raw events generated by `compiledSpell.executeAll` and applies their effects to the actual game state in a controlled, ordered manner.
*   **Structure:**
    *   `PROCESSING_PRIORITY`: Defines the order for processing different event types (e.g., state changes before damage).
    *   `EVENT_HANDLERS`: A table mapping event type strings (e.g., `"DAMAGE"`, `"APPLY_STATUS"`) to handler functions.
    *   `resolveTarget`: Helper to find the target game object(s) based on event data (e.g., `"self"`, `"enemy"`, `"enemy_slot"`).
*   **Processing Flow (`processEvents` function):**
    *   Receives the `events` list, `caster`, `target`, `spellSlot`.
    *   Sorts events based on `PROCESSING_PRIORITY`.
    *   Iterates through sorted events.
    *   Looks up the appropriate handler in `EVENT_HANDLERS` using `event.type`.
    *   Calls the handler function (`handleEvent`).
    *   **Handlers modify state:** The specific handler function (e.g., `EVENT_HANDLERS.DAMAGE`) uses `resolveTarget` and then directly modifies game state (e.g., `targetEntity.health -= event.amount`) or calls appropriate object methods (e.g., `wizard:resetSpellSlot`, `manaPool:addToken`). Handlers also trigger VFX.
    *   Returns a summary of processed events and effects.

## Interaction Flow Example (Firebolt)

1.  **Definition (`spells.lua`):** Defines `Spells.firebolt` using the `damage` keyword from `keywords.lua` with params `{ amount = 10, type = "fire" }`.
2.  **Compilation (`spellCompiler.lua`):** At game load, `compileSpell` processes `Spells.firebolt`, creating `compiledSpell` linking the `damage` keyword logic and params.
3.  **Casting (`wizard.lua`):** Player casts Firebolt; `Wizard:castSpell` calls `compiledSpell.executeAll`.
4.  **Execution & Event Generation (`spellCompiler.lua` -> `keywords.lua`):** `executeAll` calls the `damage` keyword's `execute` function, passing an `events` table. `damage.execute` adds `{ type="DAMAGE", target="enemy", amount=10, damageType="fire" }` to the `events` table.
5.  **Event Processing (`spellCompiler.lua` -> `EventRunner.lua`):** `executeAll` calls `EventRunner.processEvents` with the `events` list.
6.  **State Modification (`EventRunner.lua`):** `processEvents` sorts events, finds the `DAMAGE` handler, resolves the target to the enemy wizard, and executes `target.health = target.health - 10`. Triggers VFX.
7.  **Result:** Enemy health updated. `processEvents` returns summary. `executeAll` returns results to `castSpell`.

---

This modular system allows defining complex spell effects by combining simple, reusable keywords. The event-based execution ensures effects are applied consistently and in the correct order, making the system easier to manage and extend.