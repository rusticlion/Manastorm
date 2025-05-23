# INPUT-6: Player 2 & AI Controller Management

**Goal:** Provide clear mechanisms for enabling/disabling Player 2 human control versus AI, and manage controller assignments.

## Tasks

### 1. Player 2 Mode Selection (Character Select Screen)
- Modify `drawCharacterSelect()` and its associated logic in main.lua
- When Player 2's character is being selected (or after P1 selection if it's a global P2 setting), display an option "P2: Human / AI"
- Allow toggling this setting. This will set/unset `game.useAI`

### 2. Conditional AI Initialization (main.lua)
In `setupWizards()` or `resetGame()` or wherever AI is typically initialized for a battle:
- If `game.useAI` is true, initialize `game.opponentAI` for `game.wizards[2]`
- If `game.useAI` is false, ensure `game.opponentAI` is nil

### 3. Controller Assignment (Input.lua and main.lua)
Maintain `game.p1GamepadID` and `game.p2GamepadID`.

#### love.joystickadded(joystick):
- If `game.p1GamepadID` is nil, assign `joystick:getID()` to it
- Else if `game.p2GamepadID` is nil (and potentially `game.useAI` is false or we are in a state allowing P2 join), assign `joystick:getID()` to `game.p2GamepadID`

#### Input.handleGamepadButton/Axis: 
- Determine `playerIndex` based on `joystickID` matching `game.p1GamepadID` or `game.p2GamepadID`

**Stretch Goal:** If `game.useAI` is true and input is received from `game.p2GamepadID`, prompt "Player 2 Press Start?" or automatically switch `game.useAI` to false and activate P2.

### 4. Disable P2 Keyboard if Gamepad P2 Active
- If `game.p2GamepadID` is not nil and P2 is human, `Input.handleKey` should ignore P2 keyboard default routes to prevent conflicts
- This can be a simple flag `game.p2UsingGamepad = true`

## Acceptance Criteria
- Player can explicitly choose between a human Player 2 or an AI opponent during character selection
- If Human P2 is selected, keyboard controls (remappable) for P2 are active. If a second gamepad is connected and assigned, it controls P2
- If AI P2 is selected, `game.opponentAI` controls `wizards[2]`, and P2 human inputs are ignored
- Attract mode (AI vs AI) remains unaffected and uses its own AI instances