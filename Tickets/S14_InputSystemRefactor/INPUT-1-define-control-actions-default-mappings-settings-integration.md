# INPUT-1: Define Control Actions, Default Mappings, and Settings Integration

**Goal:** Establish a canonical list of abstract game actions, define default keyboard/gamepad mappings for them, and update the settings system to store and manage these control configurations.

## Tasks

### 1. Define Action Constants (core/Constants.lua)
Create `Constants.ControlAction = { ... }` enum table.

Include actions for:
- **Player 1:** P1_SLOT1, P1_SLOT2, P1_SLOT3, P1_CAST, P1_FREE, P1_BOOK
- **Player 2:** P2_SLOT1, P2_SLOT2, P2_SLOT3, P2_CAST, P2_FREE, P2_BOOK
- **Menu Navigation:** MENU_UP, MENU_DOWN, MENU_LEFT, MENU_RIGHT
- **Menu Actions:** MENU_CONFIRM, MENU_CANCEL_BACK
- **System (Optional):** SYS_TOGGLE_DEBUG, SYS_QUIT_MENU_BACK (for unified Escape key)

### 2. Define Default Mappings & Update Settings (core/Settings.lua)
Modify `defaults.controls` to map `Constants.ControlAction` enums to default input strings (e.g., "q", "a" for gamepad button, "dpup" for D-pad up).

Structure:
```lua
defaults.controls = {
    keyboardP1 = { [Constants.ControlAction.P1_SLOT1] = "q", ... },
    keyboardP2 = { [Constants.ControlAction.P2_SLOT1] = "i", ... },
    gamepadP1  = { [Constants.ControlAction.P1_SLOT1] = "dpdown", [Constants.ControlAction.P1_CAST] = "a", ... },
    gamepadP2  = { [Constants.ControlAction.P2_SLOT1] = "dpdown", ... } -- Placeholder for P2 controller
}
```

- Ensure `Settings.load()` correctly merges new defaults if a settings.lua file already exists (handle adding new control sections)
- Ensure `Settings.save()` correctly serializes the new structure

### 3. Update Input.lua (Initial Settings Load)
- Modify `Input.init(game)` to load the new control structures from `gameState.settings.get("controls")`
- For now, `Input.setupRoutes()` might be partially non-functional until INPUT-2, but ensure no crashes occur due to the changed settings structure

## Acceptance Criteria
- `Constants.ControlAction` enum table is fully defined in core/Constants.lua
- core/Settings.lua contains default keyboard (P1 & P2) and generic gamepad (P1) mappings for all defined actions
- The game loads settings with the new control structure without errors and saves them correctly
- Game runs without crashing, input might be partially broken pending INPUT-2