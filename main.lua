-- Manastorm - Wizard Duel Game
-- Main game file

-- Load dependencies
local Wizard = require("wizard")
local ManaPool = require("manapool")
local UI = require("ui")

-- Game state (globally accessible)
game = {
    wizards = {},
    manaPool = nil,
    font = nil,
    rangeState = "FAR"  -- Initial range state (NEAR or FAR)
}

function love.load()
    -- Set up window
    love.window.setTitle("Manastorm - Wizard Duel")
    love.window.setMode(800, 600)
    
    -- Use default system font for now (custom font has issues with numbers)
    -- game.font = love.graphics.newFont("assets/fonts/Lionscript-Regular.ttf", 16)
    game.font = love.graphics.newFont(16)  -- Default system font
    love.graphics.setFont(game.font)
    
    -- Create mana pool positioned above the battlefield, but below health bars
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    game.manaPool = ManaPool.new(screenWidth/2, 120)  -- Positioned between health bars and wizards
    
    -- Create wizards
    game.wizards[1] = Wizard.new("Ashgar", 200, 300, {255, 100, 100})
    game.wizards[2] = Wizard.new("Selene", 600, 300, {100, 100, 255})
    
    -- Set up references
    for _, wizard in ipairs(game.wizards) do
        wizard.manaPool = game.manaPool
        wizard.gameState = game
    end
    
    -- Initialize mana pool with tokens (2 of each type for now)
    for i = 1, 2 do
        game.manaPool:addToken("fire", "assets/sprites/fire-token.png")
        game.manaPool:addToken("force", "assets/sprites/force-token.png")
        game.manaPool:addToken("moon", "assets/sprites/moon-token.png")
        game.manaPool:addToken("nature", "assets/sprites/nature-token.png")
        game.manaPool:addToken("star", "assets/sprites/star-token.png")
    end
end

function love.update(dt)
    -- Update wizards
    for _, wizard in ipairs(game.wizards) do
        wizard:update(dt)
    end
    
    -- Update mana pool
    game.manaPool:update(dt)
end

function love.draw()
    -- Clear screen
    love.graphics.clear(20/255, 20/255, 40/255)
    
    -- Draw range state indicator (NEAR/FAR)
    drawRangeIndicator()
    
    -- Draw mana pool
    game.manaPool:draw()
    
    -- Draw wizards
    for _, wizard in ipairs(game.wizards) do
        wizard:draw()
    end
    
    -- Draw UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Ashgar", 100, 50)
    love.graphics.print("Selene", 650, 50)
    
    -- Draw help text and spell info
    UI.drawHelpText(game.font)
    UI.drawSpellInfo(game.wizards)
    
    -- Debug info
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end

-- Function to draw the range indicator for NEAR/FAR states
function drawRangeIndicator()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX = screenWidth / 2
    
    -- Start range indicator well below the mana pool
    local startY = 200
    
    -- Draw a line or barrier to indicate NEAR/FAR state
    if game.rangeState == "NEAR" then
        -- Draw a more prominent barrier for NEAR state
        love.graphics.setColor(0.6, 0.6, 0.8, 0.4)
        love.graphics.line(centerX, startY, centerX, screenHeight - 100)
        
        -- Add a more noticeable glow/pulse
        for i = 1, 7 do
            local alpha = 0.15 - (i * 0.018)
            local width = i * 5
            love.graphics.setColor(0.6, 0.6, 0.8, alpha)
            love.graphics.setLineWidth(width)
            love.graphics.line(centerX, startY, centerX, screenHeight - 100)
        end
        love.graphics.setLineWidth(1)
        
        -- Add "NEAR" text indicator below mana pool
        love.graphics.setColor(0.7, 0.7, 0.9, 0.8)
        love.graphics.print("NEAR", centerX - 20, startY - 20)
        
        -- Add a pulsing background for the text
        local pulseIntensity = 0.3 + 0.1 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.5, 0.5, 0.8, pulseIntensity)
        love.graphics.rectangle("fill", centerX - 25, startY - 23, 50, 20)
        love.graphics.setColor(0.9, 0.9, 1, 0.9)
        love.graphics.print("NEAR", centerX - 20, startY - 20)
    else
        -- For FAR state, draw a more substantial, distant barrier
        -- Distortion effect to simulate distance
        for i = 1, 12 do
            local wobble = math.sin(love.timer.getTime() * 2 + i * 0.3) * 3
            local y1 = startY + (i * 5) + wobble
            local y2 = screenHeight - 100 - (i * 5) + wobble
            local alpha = 0.15 - (i * 0.009)
            love.graphics.setColor(0.4, 0.4, 0.7, alpha)
            love.graphics.line(centerX + i * 3, y1, centerX + i * 3, y2)
            love.graphics.line(centerX - i * 3, y1, centerX - i * 3, y2)
        end
        
        -- Main line
        love.graphics.setColor(0.4, 0.4, 0.7, 0.5)
        love.graphics.line(centerX, startY, centerX, screenHeight - 100)
        
        -- Add "FAR" text indicator below mana pool
        love.graphics.setColor(0.5, 0.5, 0.8, 0.8)
        love.graphics.print("FAR", centerX - 15, startY - 20)
        
        -- Add a pulsing background for the text
        local pulseIntensity = 0.3 + 0.1 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.3, 0.3, 0.6, pulseIntensity)
        love.graphics.rectangle("fill", centerX - 20, startY - 23, 40, 20)
        love.graphics.setColor(0.7, 0.7, 0.9, 0.9)
        love.graphics.print("FAR", centerX - 15, startY - 20)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    -- Player 1 (Ashgar) key handling for spell combinations
    if key == "q" then
        game.wizards[1]:keySpell(1, true)
    elseif key == "w" then
        game.wizards[1]:keySpell(2, true)
    elseif key == "e" then
        game.wizards[1]:keySpell(3, true)
    elseif key == "f" then
        -- Cast key for Player 1
        game.wizards[1]:castKeyedSpell()
    elseif key == "b" then
        -- Toggle spellbook for Player 1
        UI.toggleSpellbook(1)
    end
    
    -- Player 2 (Selene) key handling for spell combinations
    if key == "i" then
        game.wizards[2]:keySpell(1, true)
    elseif key == "o" then
        game.wizards[2]:keySpell(2, true)
    elseif key == "p" then
        game.wizards[2]:keySpell(3, true)
    elseif key == "l" then
        -- Cast key for Player 2
        game.wizards[2]:castKeyedSpell()
    elseif key == "m" then
        -- Toggle spellbook for Player 2
        UI.toggleSpellbook(2)
    end
    
    -- Debug: Add more tokens with T key
    if key == "t" then
        game.manaPool:addToken("fire", "assets/sprites/fire-token.png")
        game.manaPool:addToken("moon", "assets/sprites/moon-token.png")
        game.manaPool:addToken("force", "assets/sprites/force-token.png")
        print("Added more tokens to the mana pool")
    end
    
    -- Debug: Position/elevation test controls
    -- Toggle range state with R key
    if key == "r" then
        if game.rangeState == "NEAR" then
            game.rangeState = "FAR"
        else
            game.rangeState = "NEAR"
        end
        print("Range state toggled to: " .. game.rangeState)
    end
    
    -- Toggle Ashgar's elevation with A key
    if key == "a" then
        if game.wizards[1].elevation == "GROUNDED" then
            game.wizards[1].elevation = "AERIAL"
        else
            game.wizards[1].elevation = "GROUNDED"
        end
        print("Ashgar elevation toggled to: " .. game.wizards[1].elevation)
    end
    
    -- Toggle Selene's elevation with S key
    if key == "s" then
        if game.wizards[2].elevation == "GROUNDED" then
            game.wizards[2].elevation = "AERIAL"
        else
            game.wizards[2].elevation = "GROUNDED"
        end
        print("Selene elevation toggled to: " .. game.wizards[2].elevation)
    end
end

-- Add key release handling to clear key combinations
function love.keyreleased(key)
    -- Player 1 key releases
    if key == "q" then
        game.wizards[1]:keySpell(1, false)
    elseif key == "w" then
        game.wizards[1]:keySpell(2, false)
    elseif key == "e" then
        game.wizards[1]:keySpell(3, false)
    end
    
    -- Player 2 key releases
    if key == "i" then
        game.wizards[2]:keySpell(1, false)
    elseif key == "o" then
        game.wizards[2]:keySpell(2, false)
    elseif key == "p" then
        game.wizards[2]:keySpell(3, false)
    end
end