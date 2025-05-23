# INPUT-3: Implement Gamepad Input Processing

**Goal:** Enable the game to receive and process input from gamepads, initially for Player 1.

## Tasks

### 1. Add Gamepad Event Handlers (main.lua)
Implement:
- `love.gamepadpressed(joystick, button)`
- `love.gamepadreleased(joystick, button)`  
- `love.axismoved(joystick, axis, value)` (note: `love.axispressed` is not a LÖVE callback, `love.joystickmoved` handles axes for gamepads too)

Inside these:
- Get `joystick:getID()`
- Initially, assume the first active joystick (`joystick:getID() == 1` or the first one that sends an event) controls Player 1
- Call new functions in Input.lua:
  - `Input.handleGamepadButton(joystickID, buttonName, true/false)`
  - `Input.handleGamepadAxis(joystickID, axisName, value)`

### 2. Modify Input.lua for Gamepad

#### Input.handleGamepadButton(joystickID, buttonName, isPressed)
- Determine `playerIndex` (e.g., if `joystickID == game.p1GamepadID`, then `playerIndex = 1`)
- Load `controls.gamepadP1` (or `gamepadP2`)
- Iterate through this mapping to find which `ControlAction` corresponds to `buttonName`
- Call `Input.triggerAction(action, playerIndex, {pressed = isPressed})`
- Handle button release for spell slot keys by triggering `_RELEASE` variants of actions

#### Input.handleGamepadAxis(joystickID, axisName, value)
- Determine `playerIndex`
- Load `controls.gamepadP1` (or `gamepadP2`)
- Map axis movements (e.g., "leftx", "lefty", "dpup", "dpdown" - LÖVE uses "dpup" etc. for D-pad buttons) to `MENU_UP/DOWN/LEFT/RIGHT` actions
- Implement a deadzone for analog stick axes
- Implement a repeat timer for sustained axis input for menu navigation
- Call `Input.triggerUIAction(action, {value = value})`

### 3. Gamepad ID Management (main.lua or Input.lua)
- Add `game.p1GamepadID = nil`, `game.p2GamepadID = nil`
- In `love.joystickadded(joystick)`:
  - If `game.p1GamepadID` is nil, assign `joystick:getID()` to it
  - Or, if P2 needs a controller, assign it to `game.p2GamepadID`
- In `love.joystickremoved(joystick)`:
  - If `joystick:getID()` matches a stored ID, set it back to nil

## Acceptance Criteria
- A connected gamepad can control Player 1's wizard actions using the default gamepad bindings
- Gamepad D-pad and/or left analog stick can navigate menus that currently support keyboard arrow navigation  
- Gamepad connect/disconnect is handled gracefully