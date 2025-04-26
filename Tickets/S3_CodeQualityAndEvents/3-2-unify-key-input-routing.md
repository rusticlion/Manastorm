# Ticket #2 – Unify Key-Input Routing

## Goal
Replace the two clashing love.keypressed definitions with a single dispatcher that cleanly separates system shortcuts, player 1, player 2, and debug hooks.

## Tasks
1. Add core/Input.lua with Input.handleKey(key, scancode, isrepeat).
2. Move scaling keys, gameplay keys, debug keys into tables inside that file (Input.Routes.system, Routes.p1, …).
3. In main.lua, replace definitions with: function love.keypressed(...) Input.handleKey(...) end.
4. Update love.keyreleased similarly.
5. Write a quick doc block listing reserved keys.

## Deliverables
* Input module + updated main.lua.
* Manual QA: scaling shortcuts, spell casting, debug overlay still work.

## Pitfalls
Be careful not to double‑map "1"/"2" that are already used for both scaling and VFX tests— resolve or namespace via ALT modifier.

## Senior Feedback
* **Confirmed Key Conflicts**: The conflict with "1" and "2" keys is evident in the codebase. main.lua uses ALT + "1"/"2"/"3" for scaling and "1" through "8" for VFX tests. wizard.lua (via main.lua's love.keypressed) uses "1" and "2" for custom spells moonWard and mirrorShield.
* **Input Complexity Warning**: The current love.keypressed in main.lua handles multiple concerns: game state checks, player 1/2 inputs (q/w/e/f/g/b, i/o/p/j/h/m), debug keys (t, z, x, c, r, a, s), scaling (ALT+1/2/3/f), and VFX tests (1-8). This consolidation requires careful state management and clear separation of concerns.
* **Key Release Handling**: Ensure the love.keyreleased handler in main.lua (which updates wizard.activeKeys) is also correctly migrated to prevent sticky keys.
* **UI Input Planning**: Consider how UI interactions (like closing modal dialogs) will fit into this system if mouse input is added later, even if not immediately implemented.