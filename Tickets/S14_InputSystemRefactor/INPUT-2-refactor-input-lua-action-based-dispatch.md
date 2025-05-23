# INPUT-2: Refactor Input.lua for Action-Based Dispatch

**Goal:** Rework Input.lua to map physical inputs (keys/buttons) to abstract ControlActions, and have game logic respond to these actions.

## Tasks

### 1. Modify Input.setupRoutes() (core/Input.lua)
- `Input.Routes` (e.g., `Input.Routes.p1_kb`, `Input.Routes.p2_kb`, `Input.Routes.gp1`, `Input.Routes.system`) will now store anonymous functions
- Dynamically populate `Input.Routes` based on loaded settings:
  - Iterate through `controls.keyboardP1`. For each `actionConstant = keyName` pair, `Input.Routes.p1_kb[keyName] = function() Input.triggerAction(actionConstant, 1) end`
  - Similarly for `keyboardP2`
  - Gamepad routes will be handled differently in INPUT-3

### 2. Create Input.triggerAction(action, playerIndex, params) (core/Input.lua)
This new central function will contain the if/elseif logic previously in individual route handlers.

Takes the action (from `Constants.ControlAction`), an optional `playerIndex` (1 or 2), and optional `params`.

Example:
```lua
function Input.triggerAction(action, playerIndex, params)
    local gs = gameState -- Local reference for brevity
    if action == Constants.ControlAction.P1_SLOT1 and playerIndex == 1 then
        gs.wizards[1]:keySpell(1, true)
    elseif action == Constants.ControlAction.P1_CAST and playerIndex == 1 then
        gs.wizards[1]:castKeyedSpell()
    elseif action == Constants.ControlAction.P1_SLOT1_RELEASE and playerIndex == 1 then -- New action type
        gs.wizards[1]:keySpell(1, false)
    -- ... similar for P2 actions ...
    elseif action == Constants.ControlAction.MENU_UP then
        Input.triggerUIAction(action, params) -- Delegate UI actions
    -- ...
    end
end
```

### 3. Modify Input.handleKey(key, scancode, isrepeat)
- Its role is now to look up `key` in the appropriate `Input.Routes` (e.g., `Input.Routes.p1_kb[key]`) and call the routed function if found
- Distinguish between P1 and P2 keyboard routes

### 4. Modify Input.handleKeyReleased(key, scancode)
- Load current P1/P2 keyboard controls
- If key matches a P1 slot key, call `Input.triggerAction(Constants.ControlAction.P1_SLOT1_RELEASE, 1)` (or SLOT2/3)
- Similarly for P2

### 5. Create Input.triggerUIAction(action, params) (core/Input.lua or main.lua)
- This function will handle actions like `MENU_UP`, `MENU_CONFIRM`
- It will check `gameState.currentState` and call the appropriate game logic (e.g., `gameState.settingsMove(-1)`, `gameState.characterSelectConfirm()`)

## Acceptance Criteria
- Player 1 and Player 2 keyboard controls function as before, now dispatched via `Input.triggerAction`
- `Input.setupRoutes` dynamically builds routes from settings
- Input.lua internally uses `Constants.ControlAction`
- Menu-related system keys (like Escape for main menu back/quit) are routed to `Input.triggerUIAction`