-- Input.lua
-- Unified input routing system for Manastorm

local Input = {}

-- Store a reference to the game state for routing
local gameState = nil

-- Set up input routes by category
Input.Routes = {
    -- System-level controls (scaling, fullscreen, quit)
    system = {},
    
    -- Player 1 controls
    p1 = {},
    
    -- Player 2 controls
    p2 = {},
    
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
    Input.setupRoutes()
end

-- Main entry point for key handling
function Input.handleKey(key, scancode, isrepeat)
    -- Log key presses for debugging
    print("DEBUG: Key pressed: '" .. key .. "'")

    -- Handle settings key capture
    if gameState and gameState.currentState == "SETTINGS" and gameState.settingsMenu and gameState.settingsMenu.waitingForKey then
        local action = gameState.settingsMenu.waitingForKey
        local controls = gameState.settings.get("controls")
        controls[action.player][action.key] = key
        gameState.settings.set("controls", controls)
        gameState.settingsMenu.rebindIndex = gameState.settingsMenu.rebindIndex + 1
        if gameState.settingsMenu.rebindIndex <= #gameState.settingsMenu.bindOrder then
            local a = gameState.settingsMenu.bindOrder[gameState.settingsMenu.rebindIndex]
            gameState.settingsMenu.waitingForKey = {player=a[1], key=a[2], label=a[3]}
        else
            gameState.settingsMenu.waitingForKey = nil
            gameState.settingsMenu.mode = nil
        end
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
    
    -- Check player 1 controls
    local p1Handler = Input.Routes.p1[key]
    if p1Handler then
        return p1Handler(key, scancode, isrepeat)
    end
    
    -- Check player 2 controls
    local p2Handler = Input.Routes.p2[key]
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
    -- Handle player 1 key releases
    if key == controls.p1.slot1 or key == controls.p1.slot2 or key == controls.p1.slot3 then
        local slotIndex = (key == controls.p1.slot1) and 1 or (key == controls.p1.slot2 and 2 or 3)
        if gameState and gameState.wizards and gameState.wizards[1] then
            gameState.wizards[1]:keySpell(slotIndex, false)
            return true
        end
    end

    -- Handle player 2 key releases
    if key == controls.p2.slot1 or key == controls.p2.slot2 or key == controls.p2.slot3 then
        local slotIndex = (key == controls.p2.slot1) and 1 or (key == controls.p2.slot2 and 2 or 3)
        if gameState and gameState.wizards and gameState.wizards[2] then
            gameState.wizards[2]:keySpell(slotIndex, false)
            return true
        end
    end
    
    return false
end

-- Define all keyboard shortcuts and routes
function Input.setupRoutes()
    -- Reset route tables
    Input.Routes.system = {}
    Input.Routes.p1 = {}
    Input.Routes.p2 = {}
    Input.Routes.debug = {}
    Input.Routes.test = {}
    Input.Routes.ui = {}
    Input.Routes.gameOver = {}
    -- Exit / Quit the game or return to menu
    Input.Routes.ui["escape"] = function()
        -- If in MENU state, quit the game
        if gameState.currentState == "MENU" then
            love.event.quit()
            return true
        -- If in BATTLE state, return to menu
        elseif gameState.currentState == "BATTLE" then
            gameState.currentState = "MENU"
            print("Returning to main menu")
            return true
        -- If in GAME_OVER state, return to menu
        elseif gameState.currentState == "GAME_OVER" then
            gameState.currentState = "MENU"
            gameState.resetGame()
            print("Returning to main menu")
            return true
        -- If in CHARACTER_SELECT, go back to menu
        elseif gameState.currentState == "CHARACTER_SELECT" then
            gameState.characterSelectBack(true)
            return true
        elseif gameState.currentState == "CAMPAIGN_MENU" then
            gameState.currentState = "MENU"
            return true
        elseif gameState.currentState == "SETTINGS" then
            gameState.currentState = "MENU"
            return true
        elseif gameState.currentState == "COMPENDIUM" then
            gameState.currentState = "MENU"
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
            gameState.currentState = "CAMPAIGN_MENU"
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

    -- Legacy enter key starts Character Duel
    Input.Routes.ui["return"] = function()
        if gameState.currentState == "MENU" then
            gameState.startCharacterSelect()
            return true
        elseif gameState.currentState == "SETTINGS" then
            gameState.settingsSelect()
            return true
        end
        return false
    end

    -- SETTINGS AND COMPENDIUM CONTROLS
    Input.Routes.ui["up"] = function()
        if gameState.currentState == "SETTINGS" then
            gameState.settingsMove(-1)
            return true
        elseif gameState.currentState == "COMPENDIUM" then
            gameState.compendiumMove(-1)
            return true
        end
        return false
    end
    Input.Routes.ui["down"] = function()
        if gameState.currentState == "SETTINGS" then
            gameState.settingsMove(1)
            return true
        elseif gameState.currentState == "COMPENDIUM" then
            gameState.compendiumMove(1)
            return true
        end
        return false
    end
    Input.Routes.ui["left"] = function()
        if gameState.currentState == "SETTINGS" then
            gameState.settingsAdjust(-1)
            return true
        elseif gameState.currentState == "COMPENDIUM" then
            gameState.compendiumChangePage(-1)
            return true
        end
        return false
    end
    Input.Routes.ui["right"] = function()
        if gameState.currentState == "SETTINGS" then
            gameState.settingsAdjust(1)
            return true
        elseif gameState.currentState == "COMPENDIUM" then
            gameState.compendiumChangePage(1)
            return true
        end
        return false
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

    -- Confirm selection / Fight
    Input.Routes.ui["f"] = function()
        if gameState.currentState == "CHARACTER_SELECT" then
            gameState.characterSelectConfirm()
            return true
        end
        return false
    end

    -- Escape backs out of character select handled in global escape route
    
    -- GAME OVER STATE CONTROLS
    -- Reset game on space bar press during game over
    Input.Routes.gameOver["space"] = function()
        if gameState.currentState == "GAME_OVER" then
            gameState.resetGame()
            gameState.currentState = "MENU" -- Return to menu after game over
            return true
        end
        return false
    end
    
    -- PLAYER 1 CONTROLS (Ashgar)
    local c = gameState.settings.get("controls")
    local p1 = c.p1
    local p2 = c.p2

    -- Key spell slots
    Input.Routes.p1[p1.slot1] = function()
        gameState.wizards[1]:keySpell(1, true)
        return true
    end

    Input.Routes.p1[p1.slot2] = function()
        gameState.wizards[1]:keySpell(2, true)
        return true
    end

    Input.Routes.p1[p1.slot3] = function()
        gameState.wizards[1]:keySpell(3, true)
        return true
    end

    -- Cast keyed spell
    Input.Routes.p1[p1.cast] = function()
        gameState.wizards[1]:castKeyedSpell()
        return true
    end

    -- Free all spells
    Input.Routes.p1[p1.free] = function()
        gameState.wizards[1]:freeAllSpells()
        return true
    end

    -- Toggle spellbook
    Input.Routes.p1[p1.book] = function()
        local UI = require("ui")
        UI.toggleSpellbook(1)
        return true
    end

    -- PLAYER 2 CONTROLS (Selene)
    -- Key spell slots
    Input.Routes.p2[p2.slot1] = function()
        gameState.wizards[2]:keySpell(1, true)
        return true
    end

    Input.Routes.p2[p2.slot2] = function()
        gameState.wizards[2]:keySpell(2, true)
        return true
    end

    Input.Routes.p2[p2.slot3] = function()
        gameState.wizards[2]:keySpell(3, true)
        return true
    end

    -- Cast keyed spell
    Input.Routes.p2[p2.cast] = function()
        gameState.wizards[2]:castKeyedSpell()
        return true
    end

    -- Free all spells
    Input.Routes.p2[p2.free] = function()
        gameState.wizards[2]:freeAllSpells()
        return true
    end

    -- Toggle spellbook
    Input.Routes.p2[p2.book] = function()
        local UI = require("ui")
        UI.toggleSpellbook(2)
        return true
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

-- Document all currently used keys
Input.reservedKeys = {
    system = {
        "Alt+1", "Alt+2", "Alt+3", "Alt+f", -- Window scaling
        "Ctrl+R", -- Asset reload
    },
    
    menu = {
        "1", "2", "3", "4", "5", "6", -- Main menu options
        "Enter", -- Start character duel (shortcut)
        "Escape", -- Quit game from menu
    },
    
    battle = {
        "Escape", -- Return to menu from battle
    },

    characterSelect = {
        "Q", "E", -- Move cursor
        "F", -- Confirm
        "Escape" -- Back
    },
    
    gameOver = {
        "Space", -- Return to menu after game over
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