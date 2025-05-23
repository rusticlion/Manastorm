-- Input.lua
-- Unified input routing system for Manastorm

local Input = {}
local Constants = require("core.Constants")

-- Store a reference to the game state for routing
local gameState = nil
Input.controls = nil

-- States considered to have a menu active
local MENU_STATES = {
    MENU = true,
    SETTINGS = true,
    CHARACTER_SELECT = true,
    COMPENDIUM = true,
    CAMPAIGN_MENU = true,
    CAMPAIGN_VICTORY = true,
    CAMPAIGN_DEFEAT = true
}

-- Set up input routes by category
Input.Routes = {
    -- System-level controls (scaling, fullscreen, quit)
    system = {},

    -- Player 1 keyboard controls
    p1_kb = {},

    -- Player 2 keyboard controls
    p2_kb = {},

    -- Gamepad routes will be added later
    gp1 = {},
    gp2 = {},

    -- Debug controls (only available outside gameOver state)
    debug = {},

    -- Test controls (only available outside gameOver state)
    test = {},

    -- UI controls (available in any state)
    ui = {},

    -- Game over state controls
    gameOver = {}
}

-- Initialize with game state reference
function Input.init(game)
    gameState = game
    Input.controls = gameState.settings.get("controls")
    Input.setupRoutes()
end

-- Central dispatch for abstract control actions
function Input.triggerAction(action, playerIndex, params)
    local gs = gameState
    if not gs then return false end

    -- Player 1 actions
    if action == Constants.ControlAction.P1_SLOT1 and playerIndex == 1 then
        gs.wizards[1]:keySpell(1, true)
    elseif action == Constants.ControlAction.P1_SLOT2 and playerIndex == 1 then
        gs.wizards[1]:keySpell(2, true)
    elseif action == Constants.ControlAction.P1_SLOT3 and playerIndex == 1 then
        gs.wizards[1]:keySpell(3, true)
    elseif action == Constants.ControlAction.P1_CAST and playerIndex == 1 then
        if MENU_STATES[gs.currentState] then
            Input.triggerUIAction(Constants.ControlAction.MENU_CONFIRM, params)
        end
        gs.wizards[1]:castKeyedSpell()
    elseif action == Constants.ControlAction.P1_FREE and playerIndex == 1 then
        if MENU_STATES[gs.currentState] then
            Input.triggerUIAction(Constants.ControlAction.MENU_CANCEL_BACK, params)
        end
        gs.wizards[1]:freeAllSpells()
    elseif action == Constants.ControlAction.P1_BOOK and playerIndex == 1 then
        require("ui").toggleSpellbook(1)
    elseif action == Constants.ControlAction.P1_SLOT1_RELEASE and playerIndex == 1 then
        gs.wizards[1]:keySpell(1, false)
    elseif action == Constants.ControlAction.P1_SLOT2_RELEASE and playerIndex == 1 then
        gs.wizards[1]:keySpell(2, false)
    elseif action == Constants.ControlAction.P1_SLOT3_RELEASE and playerIndex == 1 then
        gs.wizards[1]:keySpell(3, false)

    -- Player 2 actions
    elseif action == Constants.ControlAction.P2_SLOT1 and playerIndex == 2 then
        gs.wizards[2]:keySpell(1, true)
    elseif action == Constants.ControlAction.P2_SLOT2 and playerIndex == 2 then
        gs.wizards[2]:keySpell(2, true)
    elseif action == Constants.ControlAction.P2_SLOT3 and playerIndex == 2 then
        gs.wizards[2]:keySpell(3, true)
    elseif action == Constants.ControlAction.P2_CAST and playerIndex == 2 then
        if MENU_STATES[gs.currentState] then
            Input.triggerUIAction(Constants.ControlAction.MENU_CONFIRM, params)
        end
        gs.wizards[2]:castKeyedSpell()
    elseif action == Constants.ControlAction.P2_FREE and playerIndex == 2 then
        if MENU_STATES[gs.currentState] then
            Input.triggerUIAction(Constants.ControlAction.MENU_CANCEL_BACK, params)
        end
        gs.wizards[2]:freeAllSpells()
    elseif action == Constants.ControlAction.P2_BOOK and playerIndex == 2 then
        require("ui").toggleSpellbook(2)
    elseif action == Constants.ControlAction.P2_SLOT1_RELEASE and playerIndex == 2 then
        gs.wizards[2]:keySpell(1, false)
    elseif action == Constants.ControlAction.P2_SLOT2_RELEASE and playerIndex == 2 then
        gs.wizards[2]:keySpell(2, false)
    elseif action == Constants.ControlAction.P2_SLOT3_RELEASE and playerIndex == 2 then
        gs.wizards[2]:keySpell(3, false)

    -- Menu/UI actions
    elseif action == Constants.ControlAction.MENU_UP
        or action == Constants.ControlAction.MENU_DOWN
        or action == Constants.ControlAction.MENU_LEFT
        or action == Constants.ControlAction.MENU_RIGHT
        or action == Constants.ControlAction.MENU_CONFIRM
        or action == Constants.ControlAction.MENU_CANCEL_BACK then
        return Input.triggerUIAction(action, params)
    else
        return false
    end
    return true
end

-- Handle UI related actions based on current state
function Input.triggerUIAction(action, params)
    local gs = gameState
    if not gs then return false end

    if action == Constants.ControlAction.MENU_CANCEL_BACK then
        if gs.currentState == "MENU" then
            love.event.quit()
        elseif gs.currentState == "BATTLE" then
            gs.currentState = "MENU"
        elseif gs.currentState == "GAME_OVER" then
            gs.currentState = "MENU"
            gs.resetGame()
        elseif gs.currentState == "CHARACTER_SELECT" then
            gs.characterSelectBack(true)
        elseif gs.currentState == "CAMPAIGN_MENU" then
            gs.currentState = "MENU"
            gs.campaignMenu = nil
        elseif gs.currentState == "CAMPAIGN_VICTORY" then
            gs.currentState = "MENU"
            gs.campaignProgress = nil
        elseif gs.currentState == "CAMPAIGN_DEFEAT" then
            gs.currentState = "MENU"
            gs.campaignProgress = nil
        elseif gs.currentState == "SETTINGS" then
            if gs.settingsBack then
                gs.settingsBack()
            else
                gs.currentState = "MENU"
            end
        elseif gs.currentState == "COMPENDIUM" then
            gs.currentState = "MENU"
        end
        return true
    elseif action == Constants.ControlAction.MENU_CONFIRM then
        if gs.currentState == "MENU" then
            gs.startCharacterSelect()
        elseif gs.currentState == "SETTINGS" then
            gs.settingsSelect()
        elseif gs.currentState == "CAMPAIGN_MENU" then
            gs.campaignMenuConfirm()
        elseif gs.currentState == "CHARACTER_SELECT" then
            gs.characterSelectConfirm()
        elseif gs.currentState == "CAMPAIGN_DEFEAT" then
            gs.retryCampaignBattle()
        elseif gs.currentState == "CAMPAIGN_VICTORY" then
            gs.currentState = "MENU"
            gs.campaignProgress = nil
        end
        return true
    elseif action == Constants.ControlAction.MENU_UP then
        if gs.currentState == "SETTINGS" then
            gs.settingsMove(-1)
        elseif gs.currentState == "COMPENDIUM" then
            gs.compendiumMove(-1)
        elseif gs.currentState == "CAMPAIGN_MENU" then
            gs.campaignMenuMove(-1)
        end
        return true
    elseif action == Constants.ControlAction.MENU_DOWN then
        if gs.currentState == "SETTINGS" then
            gs.settingsMove(1)
        elseif gs.currentState == "COMPENDIUM" then
            gs.compendiumMove(1)
        elseif gs.currentState == "CAMPAIGN_MENU" then
            gs.campaignMenuMove(1)
        end
        return true
    elseif action == Constants.ControlAction.MENU_LEFT then
        if gs.currentState == "SETTINGS" then
            gs.settingsAdjust(-1)
        elseif gs.currentState == "COMPENDIUM" then
            gs.compendiumChangePage(-1)
        end
        return true
    elseif action == Constants.ControlAction.MENU_RIGHT then
        if gs.currentState == "SETTINGS" then
            gs.settingsAdjust(1)
        elseif gs.currentState == "COMPENDIUM" then
            gs.compendiumChangePage(1)
        end
        return true
    end

    return false
end

-- Main entry point for key handling
function Input.handleKey(key, scancode, isrepeat)
    -- Log key presses for debugging
    print("DEBUG: Key pressed: '" .. key .. "'")

    -- Handle settings key capture
    if gameState and gameState.currentState == "SETTINGS" and gameState.settingsMenu and gameState.settingsMenu.waitingForKey then
        local capture = gameState.settingsMenu.waitingForKey
        local controls = gameState.settings.get("controls")
        if controls[capture.playerType] then
            controls[capture.playerType][capture.action] = key
            gameState.settings.set("controls", controls)
            if gameState.settings.save then gameState.settings.save() end
            -- update list for UI
            if gameState.settingsMenu.rebindActionList then
                for _, entry in ipairs(gameState.settingsMenu.rebindActionList) do
                    if entry.action == capture.action then
                        entry.binding = key
                    end
                end
            end
        end
        gameState.settingsMenu.waitingForKey = nil
        Input.setupRoutes()
        return true
    end
    
    -- First check gameOver state - these have highest priority
    if gameState and gameState.gameOver then
        local handler = Input.Routes.gameOver[key]
        if handler then
            return handler(key, scancode, isrepeat)
        end
        return false -- Don't process other keys in gameOver state
    end
    
    -- Check system shortcuts (with modifiers) next
    if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
        local handler = Input.Routes.system[key]
        if handler then
            return handler(key, scancode, isrepeat)
        end
    end
    
    -- Check developer shortcuts
    if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        local handler = Input.Routes.system["ctrl_" .. key]
        if handler then
            return handler(key, scancode, isrepeat)
        end
    end
    
    -- Check UI controls (always active). Only stop processing if handled
    local uiHandler = Input.Routes.ui[key]
    if uiHandler then
        local handled = uiHandler(key, scancode, isrepeat)
        if handled then
            return true
        end
        -- fall through to player controls when not handled
    end

    -- Check player 1 keyboard controls
    local p1Handler = Input.Routes.p1_kb[key]
    if p1Handler then
        return p1Handler(key, scancode, isrepeat)
    end

    -- Check player 2 keyboard controls
    local p2Handler = Input.Routes.p2_kb[key]
    if p2Handler then
        return p2Handler(key, scancode, isrepeat)
    end
    
    -- Check debug controls
    local debugHandler = Input.Routes.debug[key]
    if debugHandler then
        return debugHandler(key, scancode, isrepeat)
    end
    
    -- Check test controls (lowest priority)
    local testHandler = Input.Routes.test[key]
    if testHandler then
        return testHandler(key, scancode, isrepeat)
    end
    
    -- No handler found
    return false
end

-- Handle key release events
function Input.handleKeyReleased(key, scancode)
    local controls = gameState.settings.get("controls")
    local kp1 = controls.keyboardP1 or (controls.p1 or {})
    local kp2 = controls.keyboardP2 or (controls.p2 or {})

    local p1s1 = kp1[Constants.ControlAction.P1_SLOT1] or kp1.slot1
    local p1s2 = kp1[Constants.ControlAction.P1_SLOT2] or kp1.slot2
    local p1s3 = kp1[Constants.ControlAction.P1_SLOT3] or kp1.slot3
    if key == p1s1 or key == p1s2 or key == p1s3 then
        local slotIndex = (key == p1s1) and 1 or (key == p1s2 and 2 or 3)
        if slotIndex == 1 then
            return Input.triggerAction(Constants.ControlAction.P1_SLOT1_RELEASE, 1)
        elseif slotIndex == 2 then
            return Input.triggerAction(Constants.ControlAction.P1_SLOT2_RELEASE, 1)
        else
            return Input.triggerAction(Constants.ControlAction.P1_SLOT3_RELEASE, 1)
        end
    end

    local p2s1 = kp2[Constants.ControlAction.P2_SLOT1] or kp2.slot1
    local p2s2 = kp2[Constants.ControlAction.P2_SLOT2] or kp2.slot2
    local p2s3 = kp2[Constants.ControlAction.P2_SLOT3] or kp2.slot3
    if key == p2s1 or key == p2s2 or key == p2s3 then
        local slotIndex = (key == p2s1) and 1 or (key == p2s2 and 2 or 3)
        if slotIndex == 1 then
            return Input.triggerAction(Constants.ControlAction.P2_SLOT1_RELEASE, 2)
        elseif slotIndex == 2 then
            return Input.triggerAction(Constants.ControlAction.P2_SLOT2_RELEASE, 2)
        else
            return Input.triggerAction(Constants.ControlAction.P2_SLOT3_RELEASE, 2)
        end
    end

    return false
end

-- Process gamepad button events
function Input.handleGamepadButton(joystickID, buttonName, isPressed)
    local playerIndex
    if joystickID == gameState.p1GamepadID then
        playerIndex = 1
    elseif joystickID == gameState.p2GamepadID then
        playerIndex = 2
    end
    if not playerIndex then return false end

    if gameState and gameState.currentState == "SETTINGS" and gameState.settingsMenu and gameState.settingsMenu.waitingForKey then
        local capture = gameState.settingsMenu.waitingForKey
        if capture.playerType == "gamepadP1" and playerIndex == 1 or capture.playerType == "gamepadP2" and playerIndex == 2 then
            if isPressed then
                local controls = gameState.settings.get("controls")
                controls[capture.playerType][capture.action] = buttonName
                gameState.settings.set("controls", controls)
                if gameState.settings.save then gameState.settings.save() end
                if gameState.settingsMenu.rebindActionList then
                    for _, entry in ipairs(gameState.settingsMenu.rebindActionList) do
                        if entry.action == capture.action then
                            entry.binding = buttonName
                        end
                    end
                end
                gameState.settingsMenu.waitingForKey = nil
                Input.setupRoutes()
            end
            return true
        end
    end

    local controls = Input.controls or gameState.settings.get("controls")
    local map = (playerIndex == 1) and (controls.gamepadP1 or {}) or (controls.gamepadP2 or {})

    for action, button in pairs(map) do
        if button == buttonName then
            if not isPressed then
                -- Trigger release variants for spell slot buttons
                if action == Constants.ControlAction.P1_SLOT1 then
                    return Input.triggerAction(Constants.ControlAction.P1_SLOT1_RELEASE, playerIndex)
                elseif action == Constants.ControlAction.P1_SLOT2 then
                    return Input.triggerAction(Constants.ControlAction.P1_SLOT2_RELEASE, playerIndex)
                elseif action == Constants.ControlAction.P1_SLOT3 then
                    return Input.triggerAction(Constants.ControlAction.P1_SLOT3_RELEASE, playerIndex)
                elseif action == Constants.ControlAction.P2_SLOT1 then
                    return Input.triggerAction(Constants.ControlAction.P2_SLOT1_RELEASE, playerIndex)
                elseif action == Constants.ControlAction.P2_SLOT2 then
                    return Input.triggerAction(Constants.ControlAction.P2_SLOT2_RELEASE, playerIndex)
                elseif action == Constants.ControlAction.P2_SLOT3 then
                    return Input.triggerAction(Constants.ControlAction.P2_SLOT3_RELEASE, playerIndex)
                end
            end
            return Input.triggerAction(action, playerIndex, {pressed = isPressed})
        end
    end

    return false
end

-- Store previous axis values to implement deadzone and edge detection
Input._axisState = { [1] = {}, [2] = {} }
Input._axisRepeat = { [1] = {}, [2] = {} }
Input.AXIS_DEADZONE = 0.3
Input.AXIS_REPEAT_DELAY = 0.4
Input.AXIS_REPEAT_INTERVAL = 0.2

-- Process gamepad axis movements for menu navigation
function Input.handleGamepadAxis(joystickID, axisName, value)
    local playerIndex
    if joystickID == gameState.p1GamepadID then
        playerIndex = 1
    elseif joystickID == gameState.p2GamepadID then
        playerIndex = 2
    end
    if not playerIndex then return false end

    if gameState and gameState.currentState == "SETTINGS" and gameState.settingsMenu and gameState.settingsMenu.waitingForKey then
        local capture = gameState.settingsMenu.waitingForKey
        if (capture.playerType == "gamepadP1" and playerIndex == 1) or (capture.playerType == "gamepadP2" and playerIndex == 2) then
            if math.abs(value) > Input.AXIS_DEADZONE then
                local controls = gameState.settings.get("controls")
                controls[capture.playerType][capture.action] = axisName
                gameState.settings.set("controls", controls)
                if gameState.settings.save then gameState.settings.save() end
                if gameState.settingsMenu.rebindActionList then
                    for _, entry in ipairs(gameState.settingsMenu.rebindActionList) do
                        if entry.action == capture.action then
                            entry.binding = axisName
                        end
                    end
                end
                gameState.settingsMenu.waitingForKey = nil
                Input.setupRoutes()
            end
            return true
        end
    end

    local prev = Input._axisState[playerIndex][axisName] or 0
    Input._axisState[playerIndex][axisName] = value

    local action
    if axisName == "lefty" or axisName == "righty" then
        if value < -Input.AXIS_DEADZONE and prev >= -Input.AXIS_DEADZONE then
            action = Constants.ControlAction.MENU_UP
        elseif value > Input.AXIS_DEADZONE and prev <= Input.AXIS_DEADZONE then
            action = Constants.ControlAction.MENU_DOWN
        end
    elseif axisName == "leftx" or axisName == "rightx" then
        if value < -Input.AXIS_DEADZONE and prev >= -Input.AXIS_DEADZONE then
            action = Constants.ControlAction.MENU_LEFT
        elseif value > Input.AXIS_DEADZONE and prev <= Input.AXIS_DEADZONE then
            action = Constants.ControlAction.MENU_RIGHT
        end
    end

    if action then
        Input._axisRepeat[playerIndex][axisName] = {action = action, timer = Input.AXIS_REPEAT_DELAY}
        return Input.triggerUIAction(action, {value = value})
    elseif math.abs(value) < Input.AXIS_DEADZONE then
        Input._axisRepeat[playerIndex][axisName] = nil
    end

    return false
end

-- Define all keyboard shortcuts and routes
function Input.setupRoutes()
    -- Reset route tables
    Input.Routes.system = {}
    Input.Routes.p1_kb = {}
    Input.Routes.p2_kb = {}
    Input.Routes.gp1 = {}
    Input.Routes.gp2 = {}
    Input.Routes.debug = {}
    Input.Routes.test = {}
    Input.Routes.ui = {}
    Input.Routes.gameOver = {}

    local c = gameState.settings.get("controls")
    Input.controls = c

    local function addRoute(tbl, key, actionDesc, fn)
        if not key or key == "" then
            print("[Input] Warning: action " .. actionDesc .. " has no binding")
            return
        end
        if tbl[key] then
            print("[Input] Warning: conflicting binding for key/button '" .. key .. "'")
        end
        tbl[key] = fn
    end

    -- Build player 1 keyboard routes
    local kp1 = c.keyboardP1 or {}
    for action, key in pairs(kp1) do
        addRoute(Input.Routes.p1_kb, key, action, function()
            return Input.triggerAction(action, 1)
        end)
    end

    -- Build player 2 keyboard routes
    local kp2 = c.keyboardP2 or {}
    for action, key in pairs(kp2) do
        addRoute(Input.Routes.p2_kb, key, action, function()
            return Input.triggerAction(action, 2)
        end)
    end

    -- Build player 1 gamepad routes (button to action lookup)
    local gp1 = c.gamepadP1 or {}
    for action, button in pairs(gp1) do
        addRoute(Input.Routes.gp1, button, action, function(pressed)
            return Input.handleGamepadButton(gameState.p1GamepadID, button, pressed)
        end)
    end

    -- Build player 2 gamepad routes
    local gp2 = c.gamepadP2 or {}
    for action, button in pairs(gp2) do
        addRoute(Input.Routes.gp2, button, action, function(pressed)
            return Input.handleGamepadButton(gameState.p2GamepadID, button, pressed)
        end)
    end

    -- SYSTEM CONTROLS (with ALT modifier)
    Input.Routes.system["1"] = function()
        love.window.setMode(gameState.baseWidth, gameState.baseHeight)
        Input.recalculateScaling()
        return true
    end

    Input.Routes.system["2"] = function()
        love.window.setMode(gameState.baseWidth * 2, gameState.baseHeight * 2)
        Input.recalculateScaling()
        return true
    end

    Input.Routes.system["3"] = function()
        love.window.setMode(gameState.baseWidth * 3, gameState.baseHeight * 3)
        Input.recalculateScaling()
        return true
    end

    Input.Routes.system["f"] = function()
        love.window.setFullscreen(not love.window.getFullscreen())
        Input.recalculateScaling()
        return true
    end

    -- Developer hot-reload with Ctrl+R
    Input.Routes.system["ctrl_r"] = function()
        print("Hot-reloading assets...")
        local AssetPreloader = require("core.assetPreloader")
        local reloadStats = AssetPreloader.reloadAllAssets()
        print(string.format("Asset reload complete: %d images, %d sounds in %.2f seconds",
                          reloadStats.imageCount,
                          reloadStats.soundCount,
                          reloadStats.loadTime))
        return true
    end

    -- GAME OVER STATE CONTROLS
    Input.Routes.gameOver["space"] = function()
        if gameState.currentState == "GAME_OVER" then
            gameState.winScreenTimer = gameState.winScreenDuration
            return true
        end
        return false
    end
    
    -- SYSTEM CONTROLS (with ALT modifier)
    -- Set window to 1x scale
    Input.Routes.system["1"] = function()
        love.window.setMode(gameState.baseWidth, gameState.baseHeight)
        Input.recalculateScaling()
        return true
    end
    
    -- Set window to 2x scale
    Input.Routes.system["2"] = function()
        love.window.setMode(gameState.baseWidth * 2, gameState.baseHeight * 2)
        Input.recalculateScaling()
        return true
    end
    
    -- Set window to 3x scale
    Input.Routes.system["3"] = function()
        love.window.setMode(gameState.baseWidth * 3, gameState.baseHeight * 3)
        Input.recalculateScaling()
        return true
    end
    
    -- Toggle fullscreen
    Input.Routes.system["f"] = function()
        love.window.setFullscreen(not love.window.getFullscreen())
        Input.recalculateScaling()
        return true
    end
    
    -- Developer hot-reload with Ctrl+R
    Input.Routes.system["ctrl_r"] = function()
        print("Hot-reloading assets...")
        local AssetPreloader = require("core.assetPreloader")
        local reloadStats = AssetPreloader.reloadAllAssets()
        print(string.format("Asset reload complete: %d images, %d sounds in %.2f seconds",
                          reloadStats.imageCount,
                          reloadStats.soundCount,
                          reloadStats.loadTime))
        return true
    end
    
    -- MENU CONTROLS
    Input.Routes.ui["1"] = function()
        if gameState.currentState == "MENU" then
            gameState.startCampaignMenu()
            return true
        end
        return false
    end

    -- Character Duel - goes to character select screen
    Input.Routes.ui["2"] = function()
        if gameState.currentState == "MENU" then
            gameState.startCharacterSelect()
            return true
        end
        return false
    end

    -- Research Duel stub
    Input.Routes.ui["3"] = function()
        if gameState.currentState == "MENU" then
            print("Research Duel not implemented yet")
            return true
        end
        return false
    end

    -- Open Compendium screen (with number key 4)
    Input.Routes.ui["4"] = function()
        if gameState.currentState == "MENU" then
            gameState.startCompendium()
            return true
        end
        return false
    end
    
    -- Open Compendium screen (with letter C for easier access)
    Input.Routes.ui["c"] = function()
        if gameState.currentState == "MENU" then
            gameState.startCompendium()
            return true
        end
        return false
    end

    -- Open settings menu
    Input.Routes.ui["5"] = function()
        if gameState.currentState == "MENU" then
            gameState.startSettings()
            return true
        end
        return false
    end

    -- Exit the game
    Input.Routes.ui["6"] = function()
        if gameState.currentState == "MENU" then
            love.event.quit()
            return true
        end
        return false
    end

    -- Generic menu navigation keys
    Input.Routes.ui["return"] = function()
        return Input.triggerUIAction(Constants.ControlAction.MENU_CONFIRM)
    end
    Input.Routes.ui["space"] = function()
        return Input.triggerUIAction(Constants.ControlAction.MENU_CONFIRM)
    end
    Input.Routes.ui["escape"] = function()
        return Input.triggerUIAction(Constants.ControlAction.MENU_CANCEL_BACK)
    end

    Input.Routes.ui["up"] = function()
        return Input.triggerUIAction(Constants.ControlAction.MENU_UP)
    end
    Input.Routes.ui["down"] = function()
        return Input.triggerUIAction(Constants.ControlAction.MENU_DOWN)
    end
    Input.Routes.ui["left"] = function()
        return Input.triggerUIAction(Constants.ControlAction.MENU_LEFT)
    end
    Input.Routes.ui["right"] = function()
        return Input.triggerUIAction(Constants.ControlAction.MENU_RIGHT)
    end

    -- Assign spells to slots when in Compendium
    for i=1,7 do
        local existing = Input.Routes.ui[tostring(i)]
        Input.Routes.ui[tostring(i)] = function()
            if gameState.currentState == "COMPENDIUM" then
                gameState.compendiumAssign(i)
                return true
            elseif existing then
                return existing()
            end
            return false
        end
    end

    -- CHARACTER SELECT CONTROLS
    -- Move cursor left
    Input.Routes.ui["q"] = function()
        if gameState.currentState == "CHARACTER_SELECT" then
            gameState.characterSelectMove(-1)
            return true
        end
        return false
    end

    -- Move cursor right
    Input.Routes.ui["e"] = function()
        if gameState.currentState == "CHARACTER_SELECT" then
            gameState.characterSelectMove(1)
            return true
        end
        return false
    end

    -- CHARACTER SELECT CONTROLS
    -- Move cursor left
    Input.Routes.ui["q"] = function()
        if gameState.currentState == "CHARACTER_SELECT" then
            gameState.characterSelectMove(-1)
            return true
        end
        return false
    end

    -- Move cursor right
    Input.Routes.ui["e"] = function()
        if gameState.currentState == "CHARACTER_SELECT" then
            gameState.characterSelectMove(1)
            return true
        end
        return false
    end

    -- Confirm selection / Fight (legacy key)
    Input.Routes.ui["f"] = function()
        return Input.triggerUIAction(Constants.ControlAction.MENU_CONFIRM)
    end

    Input.Routes.ui["r"] = function()
        if gameState.currentState == "CAMPAIGN_DEFEAT" or gameState.currentState == "CAMPAIGN_VICTORY" then
            gameState.restartCampaign()
            return true
        end
        return false
    end

    
    -- DEBUG CONTROLS
    -- Add 30 random tokens with T key
    Input.Routes.debug["t"] = function()
        local addedTokens = {}
        for i = 1, 30 do
            local tokenType = gameState.addRandomToken()
            addedTokens[tokenType] = (addedTokens[tokenType] or 0) + 1
        end
        
        -- Print summary of added tokens
        for tokenType, count in pairs(addedTokens) do
            print("Added " .. count .. " " .. tokenType .. " tokens to the mana pool")
        end
        return true
    end
    
    -- Add specific tokens for testing
    Input.Routes.debug["z"] = function()
        local tokenType = "moon"
        gameState.manaPool:addToken(tokenType, gameState.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
        return true
    end
    
    Input.Routes.debug["x"] = function()
        local tokenType = "star"
        gameState.manaPool:addToken(tokenType, gameState.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
        return true
    end
    
    Input.Routes.debug["c"] = function()
        local tokenType = "force"
        gameState.manaPool:addToken(tokenType, gameState.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
        return true
    end
    
    -- Position/elevation test controls
    -- Toggle range state with R key
    Input.Routes.debug["r"] = function()
        if gameState.rangeState == "NEAR" then
            gameState.rangeState = "FAR"
        else
            gameState.rangeState = "NEAR"
        end
        print("Range state toggled to: " .. gameState.rangeState)
        return true
    end
    
    -- Toggle Ashgar's elevation with A key
    Input.Routes.debug["a"] = function()
        if gameState.wizards[1].elevation == "GROUNDED" then
            gameState.wizards[1].elevation = "AERIAL"
        else
            gameState.wizards[1].elevation = "GROUNDED"
        end
        print("Ashgar elevation toggled to: " .. gameState.wizards[1].elevation)
        return true
    end
    
    -- Toggle Selene's elevation with S key
    Input.Routes.debug["s"] = function()
        if gameState.wizards[2].elevation == "GROUNDED" then
            gameState.wizards[2].elevation = "AERIAL"
        else
            gameState.wizards[2].elevation = "GROUNDED"
        end
        print("Selene elevation toggled to: " .. gameState.wizards[2].elevation)
        return true
    end
    
    -- TESTING / VFX CONTROLS
    -- Namespace these differently to avoid conflict with custom spell hotkeys
    -- Using a safeguard to check the context
    
    -- Test firebolt effect
    Input.Routes.test["1"] = function()
        if not hasActiveSpellInput() then
            gameState.vfx.createEffect("firebolt", gameState.wizards[1].x, gameState.wizards[1].y, gameState.wizards[2].x, gameState.wizards[2].y)
            print("Testing firebolt VFX")
            return true
        end
        return false
    end
    
    -- Test meteor effect
    Input.Routes.test["2"] = function()
        if not hasActiveSpellInput() then
            gameState.vfx.createEffect("meteor", gameState.wizards[2].x, gameState.wizards[2].y - 100, gameState.wizards[2].x, gameState.wizards[2].y)
            print("Testing meteor VFX")
            return true
        end
        return false
    end
    
    -- Test mist veil effect
    Input.Routes.test["3"] = function()
        gameState.vfx.createEffect("mistveil", gameState.wizards[1].x, gameState.wizards[1].y)
        print("Testing mist veil VFX")
        return true
    end
    
    -- Test emberlift effect
    Input.Routes.test["4"] = function()
        gameState.vfx.createEffect("emberlift", gameState.wizards[2].x, gameState.wizards[2].y)
        print("Testing emberlift VFX") 
        return true
    end
    
    -- Test full moon beam effect
    Input.Routes.test["5"] = function()
        gameState.vfx.createEffect("fullmoonbeam", gameState.wizards[2].x, gameState.wizards[2].y, gameState.wizards[1].x, gameState.wizards[1].y)
        print("Testing full moon beam VFX")
        return true
    end
    
    -- Test conjure fire effect
    Input.Routes.test["6"] = function()
        gameState.vfx.createEffect("conjurefire", gameState.wizards[1].x, gameState.wizards[1].y, nil, nil, {
            manaPoolX = gameState.manaPool.x,
            manaPoolY = gameState.manaPool.y
        })
        print("Testing conjure fire VFX")
        return true
    end
    
    -- Test conjure moonlight effect
    Input.Routes.test["7"] = function()
        gameState.vfx.createEffect("conjuremoonlight", gameState.wizards[2].x, gameState.wizards[2].y, nil, nil, {
            manaPoolX = gameState.manaPool.x,
            manaPoolY = gameState.manaPool.y
        })
        print("Testing conjure moonlight VFX")
        return true
    end
    
    -- Test volatile conjuring effect
    Input.Routes.test["8"] = function()
        gameState.vfx.createEffect("volatileconjuring", gameState.wizards[1].x, gameState.wizards[1].y, nil, nil, {
            manaPoolX = gameState.manaPool.x,
            manaPoolY = gameState.manaPool.y
        })
        print("Testing volatile conjuring VFX")
        return true
    end
    
    -- Add direct keys for casting shield spells
    -- This is a special case for spell debugging
    Input.Routes.debug["kp1"] = function() -- Using KeyPad 1 instead of regular 1
        -- Force cast Moon Ward for Selene
        print("DEBUG: Directly casting Moon Ward for Selene")
        local result = gameState.wizards[2]:queueSpell(gameState.customSpells.moonWard)
        print("DEBUG: Moon Ward cast result: " .. tostring(result))
        return true
    end
    
    Input.Routes.debug["kp2"] = function() -- Using KeyPad 2 instead of regular 2
        -- Force cast Mirror Shield for Selene
        print("DEBUG: Directly casting Mirror Shield for Selene")
        local result = gameState.wizards[2]:queueSpell(gameState.customSpells.mirrorShield)
        print("DEBUG: Mirror Shield cast result: " .. tostring(result))
        return true
    end
end

-- Helper to check if there's active spell input happening
-- Prevents VFX test keys from conflicting with spell casting
function hasActiveSpellInput()
    if not gameState or not gameState.wizards then
        return false
    end
    
    -- Check if any wizard has active key combinations
    for _, wizard in ipairs(gameState.wizards) do
        if wizard.activeKeys and (wizard.activeKeys[1] or wizard.activeKeys[2] or wizard.activeKeys[3]) then
            return true
        end
    end
    
    return false
end

-- Helper function to recalculate scaling
function Input.recalculateScaling()
    if gameState and gameState.calculateScaling then
        gameState.calculateScaling()
    end
end

-- Update repeat timers for held gamepad axes
function Input.update(dt)
    for playerIndex, axes in pairs(Input._axisRepeat) do
        for axis, state in pairs(axes) do
            state.timer = state.timer - dt
            if state.timer <= 0 then
                Input.triggerUIAction(state.action, {value = Input._axisState[playerIndex][axis]})
                state.timer = Input.AXIS_REPEAT_INTERVAL
            end
        end
    end
end

-- Document all currently used keys
Input.reservedKeys = {
    system = {
        "Alt+1", "Alt+2", "Alt+3", "Alt+f", -- Window scaling
        "Ctrl+R", -- Asset reload
    },
    
    menu = {
        "1", "2", "3", "4", "5", "6", -- Main menu options
        "Up", "Down", "Left", "Right", -- Navigation
        "Enter", "Space", -- Confirm
        "Escape", -- Quit/Back
    },
    
    battle = {
        "Escape", -- Return to menu from battle
    },

    campaignMenu = {
        "Up", "Down", "Left", "Right", "F", "Enter", "Space", "Escape"
    },

    characterSelect = {
        "Q", "E", -- Move cursor
        "F", "Enter", "Space", -- Confirm
        "Escape" -- Back
    },
    
    gameOver = {
        "Space", "Enter", -- Return to menu after game over
        "Escape", -- Return to menu immediately
    },
    
    player1 = {
        "Q", "W", "E", -- Spell slots
        "F", -- Cast keyed spell
        "G", -- Free all spells
        "B", -- Toggle spellbook
    },
    
    player2 = {
        "I", "O", "P", -- Spell slots
        "J", -- Cast keyed spell
        "H", -- Free all spells
        "M", -- Toggle spellbook
    },
    
    debug = {
        "T", -- Add random token
        "Z", "X", "C", -- Add specific tokens
        "R", -- Toggle range state
        "A", "S", -- Toggle elevations
        "P", -- Show object pool stats
        "Keypad 1", "Keypad 2", -- Direct shield spell casts
    },
    
    testing = {
        "1-8", -- VFX tests
    }
}

return Input
