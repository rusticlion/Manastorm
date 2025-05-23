# INPUT-5: Standardize Menu Navigation with Abstract Actions

**Goal:** Unify menu navigation across all game menus to use the new abstract control actions, supporting keyboard arrows, gamepad D-pad/analog stick, and game action keys (Cast/Free).

## Tasks

### 1. Refactor Menu Input Logic (main.lua)
- Modify existing menu-specific input functions (`settingsMove`, `compendiumMove`, `characterSelectMove`, `campaignMenuMove`, and their "select/confirm/back" counterparts)
- These functions should now be callable with a generic direction (e.g., -1 for up/left, 1 for down/right) or an actionType (e.g., CONFIRM, CANCEL)
- The core `Input.triggerUIAction(action, params)` function will call these refactored menu logic functions based on `gameState.currentState` and the action type (`MENU_UP`, `MENU_CONFIRM`, etc.)

### 2. Update Input.setupRoutes() (core/Input.lua)
- Map keyboard arrow keys (e.g., "up", "down", "left", "right") to `Constants.ControlAction.MENU_UP`, `MENU_DOWN`, `MENU_LEFT`, `MENU_RIGHT`
- Map "return" (Enter) and "space" to `MENU_CONFIRM`
- Map "escape" to `MENU_CANCEL_BACK`

### 3. Enhance Input.triggerAction()
If `gameState.currentState` indicates a menu is active:
- If action is `P1_CAST` or `P2_CAST`, also call `Input.triggerUIAction(Constants.ControlAction.MENU_CONFIRM)`
- If action is `P1_FREE` or `P2_FREE`, also call `Input.triggerUIAction(Constants.ControlAction.MENU_CANCEL_BACK)`

## Acceptance Criteria
- All game menus (Main, Settings, Rebind, Character Select, Compendium, Campaign) are navigable using keyboard arrow keys
- All game menus are navigable using gamepad D-pad and/or left analog stick (with deadzone and repeat)
- The primary "Cast" game action (default F/gamepad A) functions as "Confirm" in menus
- The primary "Free" game action (default G/gamepad B) functions as "Cancel/Back" in menus
- Escape key consistently functions as "Cancel/Back" in menus or "Quit" from the main menu