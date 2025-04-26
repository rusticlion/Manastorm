# VFX Integration Plan

**Version:** 1.0
**Date:** 2025-04-26

## 1. Purpose

This plan outlines the steps to refactor Manastorm's visual effects (VFX) system. The primary goal is to create a clean, consistent, and event-driven pipeline for triggering and managing all visual effects, decoupling VFX logic from core gameplay simulation.

**Benefits:**
*   **Decoupling:** Gameplay logic (keywords, wizard state) won't directly trigger visuals. Effects will be described by events.
*   **Consistency:** All VFX will flow through a single pipeline (`EventRunner` -> `VFX` module).
*   **Maintainability:** Easier to add, modify, or debug visual effects without touching core game rules.
*   **Testability:** VFX triggers can be tested by asserting event generation.
*   **Designer Workflow:** Lays groundwork for potentially allowing designers/artists to configure effects more easily in the future.

## 2. Current State & Problems

Currently, VFX are triggered in multiple ways:
1.  Directly from `wizard.lua`'s `castSpell` function via `game.vfx.createSpellEffect(...)`.
2.  Via the `EFFECT` event handler in `systems/EventRunner.lua`, which calls `VFX.createEffect(...)`.
3.  Directly from `manapool.lua` within `TokenMethods:requestDestructionAnimation`.

This creates duplicate paths, makes it hard to track where visuals originate, and prevents keywords from declaratively specifying their visual components alongside their gameplay effects.

## 3. Target Architecture

The desired flow for VFX triggering will be:

Spell Keywords (keywords.lua) -- Define gameplay and associated VFX needs
│
▼
Spell Compiler (spellCompiler.lua) -- Packages keywords into a compiled spell
│
▼
Spell Execution (wizard.lua -> compiledSpell.executeAll) -- Runs keywords, generates EVENTS
│ (including EFFECT events)
▼
Event Runner (systems/EventRunner.lua) -- Processes ALL events in order
│
├─ Gameplay Handlers (modify wizard health, tokens, etc.)
│
└─ EFFECT Handler ---> VFX Module (vfx.lua) -- Creates/manages actual visuals
Non-spell systems (like token destruction, shield creation) will also trigger VFX via `EventRunner` using specific `EFFECT` events.

## 4. Sprint Overview

The refactor will proceed in the following tickets:

1.  **Ticket 1 (VFX Keyword):** Introduce a `vfx` keyword helper and centralize spell VFX triggers through the event system. Remove the legacy direct call from `wizard.lua`.
2.  **Ticket 2 (Event Contract):** Formalize the `EFFECT` event using `Constants` and add validation in the `EventRunner`.
3.  **Ticket 3 (Lifecycle Hooks):** Standardize how non-spell game systems (token lifecycle, shields, elevation) trigger VFX via events.
4.  **Ticket 4 (VFX Ergonomics):** Improve the internal structure and usability of the `vfx.lua` module (registry, async, lazy loading).
5.  **Ticket 5 (Content & Testing):** Audit all spells to ensure they use the `vfx` keyword, create a visual language reference, and add automated tests.
6.  **Ticket 6 (Optional DSL):** Explore creating a designer-friendly text format for defining VFX presets.

## 5. Key Modules Involved

-   `keywords.lua`
-   `spells.lua`
-   `spellCompiler.lua`
-   `wizard.lua`
-   `systems/EventRunner.lua`
-   `vfx.lua`
-   `core/Constants.lua`
-   `manapool.lua`
-   `systems/ShieldSystem.lua`