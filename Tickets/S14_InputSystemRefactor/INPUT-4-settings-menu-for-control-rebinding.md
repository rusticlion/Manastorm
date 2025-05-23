# INPUT-4: Settings Menu for Control Rebinding

**Goal:** Allow players to rebind keyboard and gamepad controls for all actions via an enhanced Settings menu.

## Tasks

### 1. Extend Settings Menu UI (main.lua -> drawSettingsMenu, new drawRebindMenu)
- Add a "Rebind Controls" option to the main settings menu
- Selecting it sets `game.settingsMenu.mode = "rebind_select_player"` (or similar)

#### drawRebindMenu:
- If `mode == "rebind_select_player"`: Show options like "Player 1 Keyboard", "Player 2 Keyboard", "Player 1 Gamepad"
- If `mode == "rebind_action_list"`: Display a scrollable list of all `Constants.ControlAction` relevant to the selected player/input type. Show current binding next to each. Highlight selected action

### 2. Implement Rebinding Logic (main.lua & Input.lua)
When an action is selected for rebinding:
- Set `game.settingsMenu.waitingForKey = { playerType = "keyboardP1", action = Constants.ControlAction.P1_SLOT1, label = "P1 Slot 1" }` (similar to existing but use `playerType` to specify `keyboardP1`, `gamepadP1` etc.)

#### Input.handleKey():
- If `waitingForKey`, capture key, update `game.settings.controls[playerType][action] = newKeyString`

#### Input.handleGamepadButton():
- If `waitingForKey`, capture button, update `game.settings.controls[playerType][action] = newButtonString`

#### Input.handleGamepadAxis():
- If `waitingForKey` and axis is suitable for binding (e.g., D-pad as buttons), capture axis input
- (Analog stick full axis binding is more complex, might defer)

After capture:
- Call `game.settings.save()`
- Clear `waitingForKey`
- Call `Input.setupRoutes()` to apply changes immediately

### 3. Update Input.setupRoutes()
- Must now be robust enough to handle empty or conflicting bindings (e.g., log warnings, potentially revert to default for specific action if unbound)

## Acceptance Criteria
- Players can navigate to a detailed control rebinding screen
- Players can select any rebindable game action and assign a new keyboard key or gamepad button to it
- The UI updates to show the new binding
- New bindings are saved persistently and are active immediately and upon game restart
- The system handles attempts to bind already-used keys (e.g., prompt for overwrite or disallow)