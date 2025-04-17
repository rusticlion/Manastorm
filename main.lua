-- Manastorm - Wizard Duel Game
-- Main game file

-- Load dependencies
local Wizard = require("wizard")
local ManaPool = require("manapool")
local UI = require("ui")
local VFX = require("vfx")
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")

-- Game state (globally accessible)
game = {
    wizards = {},
    manaPool = nil,
    font = nil,
    rangeState = "FAR",  -- Initial range state (NEAR or FAR)
    gameOver = false,
    winner = nil,
    winScreenTimer = 0,
    winScreenDuration = 5,  -- How long to show the win screen before auto-reset
    keywords = Keywords,
    spellCompiler = SpellCompiler
}

-- Define token types and images (globally available for consistency)
game.tokenTypes = {"fire", "force", "moon", "nature", "star"}
game.tokenImages = {
    fire = "assets/sprites/fire-token.png",
    force = "assets/sprites/force-token.png",
    moon = "assets/sprites/moon-token.png",
    nature = "assets/sprites/nature-token.png",
    star = "assets/sprites/star-token.png"
}

-- Helper function to add a random token to the mana pool
function game.addRandomToken()
    local randomType = game.tokenTypes[math.random(#game.tokenTypes)]
    game.manaPool:addToken(randomType, game.tokenImages[randomType])
    return randomType
end

function love.load()
    -- Set up window
    love.window.setTitle("Manastorm - Wizard Duel")
    love.window.setMode(800, 600)
    
    -- Use system font for now
    game.font = love.graphics.newFont(16)  -- Default system font
    
    -- Set default font for normal rendering
    love.graphics.setFont(game.font)
    
    -- Create mana pool positioned above the battlefield, but below health bars
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    game.manaPool = ManaPool.new(screenWidth/2, 120)  -- Positioned between health bars and wizards
    
    -- Create wizards - moved lower on screen to allow more room for aerial movement
    game.wizards[1] = Wizard.new("Ashgar", 200, 370, {255, 100, 100})
    game.wizards[2] = Wizard.new("Selene", 600, 370, {100, 100, 255})
    
    -- Set up references
    for _, wizard in ipairs(game.wizards) do
        wizard.manaPool = game.manaPool
        wizard.gameState = game
    end
    
    -- Initialize VFX system
    game.vfx = VFX.init()
    
    -- Create custom shield spells just for hotkeys
    -- These are complete, independent spell definitions
    game.customSpells = {}
    
    -- Define Moon Ward with minimal dependencies
    game.customSpells.moonWard = {
        id = "customMoonWard",
        name = "Moon Ward",
        description = "A mystical ward that blocks projectiles and remotes",
        attackType = "utility",
        castTime = 4.5,
        cost = {"moon", "moon"},
        keywords = {
            block = {
                type = "ward",
                blocks = {"projectile", "remote"},
                manaLinked = true
            }
        },
        vfx = "moon_ward",
        sfx = "shield_up",
        blockableBy = {}
    }
    
    -- Define Mirror Shield with minimal dependencies
    game.customSpells.mirrorShield = {
        id = "customMirrorShield",
        name = "Mirror Shield",
        description = "A reflective barrier that returns damage to attackers",
        attackType = "utility",
        castTime = 5.0,
        cost = {"moon", "moon", "star"},
        keywords = {
            block = {
                type = "barrier",
                blocks = {"projectile", "zone"},
                manaLinked = false,
                reflect = true,
                hitPoints = 3
            }
        },
        vfx = "mirror_shield",
        sfx = "crystal_ring",
        blockableBy = {}
    }
    
    -- Initialize mana pool with a single random token to start
    local tokenType = game.addRandomToken()
    
    -- Log which token was added
    print("Starting the game with a single " .. tokenType .. " token")
end

-- Reset the game
function resetGame()
    -- Reset game state
    game.gameOver = false
    game.winner = nil
    game.winScreenTimer = 0
    
    -- Reset wizards
    for _, wizard in ipairs(game.wizards) do
        wizard.health = 100
        wizard.elevation = "GROUNDED"
        wizard.elevationTimer = 0
        wizard.stunTimer = 0
        
        -- Reset spell slots
        for i = 1, 3 do
            wizard.spellSlots[i] = {
                active = false,
                progress = 0,
                spellType = nil,
                castTime = 0,
                tokens = {},
                isShield = false,
                defenseType = nil,
                shieldStrength = 0,
                blocksAttackTypes = nil
            }
        end
        
        -- Reset status effects
        wizard.statusEffects.burn.active = false
        wizard.statusEffects.burn.duration = 0
        wizard.statusEffects.burn.tickDamage = 0
        wizard.statusEffects.burn.tickInterval = 1.0
        wizard.statusEffects.burn.elapsed = 0
        wizard.statusEffects.burn.totalTime = 0
        
        -- Reset blockers
        for blockType in pairs(wizard.blockers) do
            wizard.blockers[blockType] = 0
        end
        
        -- Reset spell keying
        wizard.activeKeys = {[1] = false, [2] = false, [3] = false}
        wizard.currentKeyedSpell = nil
    end
    
    -- Reset range state
    game.rangeState = "FAR"
    
    -- Clear mana pool and add a single token to start
    game.manaPool:clear()
    local tokenType = game.addRandomToken()
    print("Game reset! Starting with a single " .. tokenType .. " token")
end

function love.update(dt)
    -- Check for win condition before updates
    if game.gameOver then
        -- Update win screen timer
        game.winScreenTimer = game.winScreenTimer + dt
        
        -- Auto-reset after duration
        if game.winScreenTimer >= game.winScreenDuration then
            resetGame()
        end
        
        -- Still update VFX system for visual effects
        game.vfx.update(dt)
        return
    end
    
    -- Check if any wizard's health has reached zero
    for i, wizard in ipairs(game.wizards) do
        if wizard.health <= 0 then
            game.gameOver = true
            game.winner = 3 - i  -- Winner is the other wizard (3-1=2, 3-2=1)
            game.winScreenTimer = 0
            
            -- Create victory VFX around the winner
            local winner = game.wizards[game.winner]
            for j = 1, 15 do
                local angle = math.random() * math.pi * 2
                local distance = math.random(40, 100)
                local x = winner.x + math.cos(angle) * distance
                local y = winner.y + math.sin(angle) * distance
                
                -- Determine winner's color for effects
                local color
                if game.winner == 1 then -- Ashgar
                    color = {1.0, 0.5, 0.2, 0.9} -- Fire-like
                else -- Selene
                    color = {0.3, 0.3, 1.0, 0.9} -- Moon-like
                end
                
                -- Create sparkle effect with delay
                game.vfx.createEffect("impact", x, y, nil, nil, {
                    duration = 0.8 + math.random() * 0.5,
                    color = color,
                    particleCount = 5,
                    radius = 15,
                    delay = j * 0.1
                })
            end
            
            print(winner.name .. " wins!")
            break
        end
    end
    
    -- Update wizards
    for _, wizard in ipairs(game.wizards) do
        wizard:update(dt)
    end
    
    -- Update mana pool
    game.manaPool:update(dt)
    
    -- Update VFX system
    game.vfx.update(dt)
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
    
    -- Draw visual effects layer (between wizards and UI)
    game.vfx.draw()
    
    -- Draw UI (health bars and wizard names are handled in UI.drawSpellInfo)
    love.graphics.setColor(1, 1, 1)
    
    -- Always draw spellbook components
    UI.drawSpellbookButtons()
    
    -- Draw spell info (health bars, etc.)
    UI.drawSpellInfo(game.wizards)
    
    -- Draw win screen if game is over
    if game.gameOver and game.winner then
        drawWinScreen()
    end
    
    -- Debug info only when debug key is pressed
    if love.keyboard.isDown("`") then
        UI.drawHelpText(game.font)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    else
        -- Always show a small hint about the debug key
        love.graphics.setColor(0.6, 0.6, 0.6, 0.4)
        love.graphics.print("Press ` for debug controls", 10, love.graphics.getHeight() - 20)
    end
end

-- Draw the win screen
function drawWinScreen()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local winner = game.wizards[game.winner]
    
    -- Fade in effect
    local fadeProgress = math.min(game.winScreenTimer / 0.5, 1.0)
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7 * fadeProgress)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Determine winner's color scheme
    local winnerColor
    if game.winner == 1 then -- Ashgar
        winnerColor = {1.0, 0.4, 0.2} -- Fire-like
    else -- Selene
        winnerColor = {0.4, 0.4, 1.0} -- Moon-like
    end
    
    -- Calculate animation progress for text
    local textProgress = math.min(math.max(game.winScreenTimer - 0.5, 0) / 0.5, 1.0)
    local textScale = 1 + (1 - textProgress) * 3 -- Text starts larger and shrinks to normal size
    local textY = screenHeight / 2 - 100
    
    -- Draw winner text with animated scale
    love.graphics.setColor(winnerColor[1], winnerColor[2], winnerColor[3], textProgress)
    
    -- Main victory text
    local victoryText = winner.name .. " WINS!"
    local victoryTextWidth = game.font:getWidth(victoryText) * textScale * 3
    love.graphics.print(
        victoryText, 
        screenWidth / 2 - victoryTextWidth / 2, 
        textY,
        0, -- rotation
        textScale * 3, -- scale X
        textScale * 3  -- scale Y
    )
    
    -- Only show restart instructions after initial animation
    if game.winScreenTimer > 1.0 then
        -- Calculate pulse effect
        local pulse = 0.7 + 0.3 * math.sin(game.winScreenTimer * 4)
        
        -- Draw restart instruction with pulse effect
        local restartText = "Press [SPACE] to play again"
        local restartTextWidth = game.font:getWidth(restartText) * 1.5
        
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.print(
            restartText,
            screenWidth / 2 - restartTextWidth / 2,
            textY + 150,
            0, -- rotation
            1.5, -- scale X
            1.5  -- scale Y
        )
        
        -- Show auto-restart countdown
        local remainingTime = math.ceil(game.winScreenDuration - game.winScreenTimer)
        local countdownText = "Auto-restart in " .. remainingTime .. "..."
        local countdownTextWidth = game.font:getWidth(countdownText)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
        love.graphics.print(
            countdownText,
            screenWidth / 2 - countdownTextWidth / 2,
            textY + 200
        )
    end
    
    -- Draw some victory effect particles
    for i = 1, 3 do
        if math.random() < 0.3 then
            local x = math.random(screenWidth)
            local y = math.random(screenHeight)
            local size = math.random(10, 30)
            
            love.graphics.setColor(
                winnerColor[1], 
                winnerColor[2], 
                winnerColor[3], 
                math.random() * 0.3
            )
            love.graphics.circle("fill", x, y, size)
        end
    end
end

-- Function to draw the range indicator for NEAR/FAR states
function drawRangeIndicator()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX = screenWidth / 2
    
    -- Only draw a subtle central line, without the text indicators
    -- The wizard positions themselves will communicate NEAR/FAR state
    
    -- Different visual style based on range state
    if game.rangeState == "NEAR" then
        -- For NEAR state, draw a more vibrant, energetic line
        love.graphics.setColor(0.5, 0.5, 0.9, 0.4)
        
        -- Draw main line
        love.graphics.setLineWidth(1.5)
        love.graphics.line(centerX, 200, centerX, screenHeight - 100)
        
        -- Add a subtle energetic glow/pulse
        for i = 1, 5 do
            local pulseWidth = 3 + math.sin(love.timer.getTime() * 2.5) * 2
            local alpha = 0.12 - (i * 0.02)
            love.graphics.setColor(0.5, 0.5, 0.9, alpha)
            love.graphics.setLineWidth(pulseWidth * i)
            love.graphics.line(centerX, 200, centerX, screenHeight - 100)
        end
        love.graphics.setLineWidth(1)
    else
        -- For FAR state, draw a more distant, faded line
        love.graphics.setColor(0.3, 0.3, 0.7, 0.3)
        
        -- Draw main line with slight wave effect
        local segments = 12
        local segmentHeight = (screenHeight - 300) / segments
        local points = {}
        
        for i = 0, segments do
            local y = 200 + i * segmentHeight
            local wobble = math.sin(love.timer.getTime() + i * 0.3) * 1.5
            table.insert(points, centerX + wobble)
            table.insert(points, y)
        end
        
        love.graphics.setLineWidth(1)
        love.graphics.line(points)
        
        -- Add very subtle horizontal distortion lines
        for i = 1, 5 do
            local y = 200 + (i * (screenHeight - 300) / 6)
            local width = 15 + math.sin(love.timer.getTime() * 0.7 + i) * 5
            local alpha = 0.05
            love.graphics.setColor(0.3, 0.3, 0.7, alpha)
            love.graphics.setLineWidth(0.5)
            love.graphics.line(centerX - width, y, centerX + width, y)
        end
    end
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

function love.keypressed(key)
    -- Debug all key presses to isolate input issues
    print("DEBUG: Key pressed: '" .. key .. "'")
    
    -- Check for game over state first
    if game.gameOver then
        -- Reset game on space bar press during game over
        if key == "space" then
            resetGame()
        end
        return
    end
    
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
    elseif key == "g" then
        -- Free key for Player 1
        game.wizards[1]:freeAllSpells()
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
    elseif key == "j" then
        -- Cast key for Player 2
        game.wizards[2]:castKeyedSpell()
    elseif key == "h" then
        -- Free key for Player 2
        game.wizards[2]:freeAllSpells()
    elseif key == "m" then
        -- Toggle spellbook for Player 2
        UI.toggleSpellbook(2)
    end
    
    -- Debug: Add a single random token with T key
    if key == "t" then
        local tokenType = game.addRandomToken()
        print("Added a " .. tokenType .. " token to the mana pool")
    end
    
    -- Debug: Add specific tokens for testing shield spells
    if key == "z" then
        local tokenType = "moon"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    elseif key == "x" then
        local tokenType = "star"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    elseif key == "c" then
        local tokenType = "force"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    end
    
    -- Direct keys for casting shield spells, bypassing keying and issue in cast key "l"
    if key == "1" then
        -- Force cast Moon Ward for Selene
        print("DEBUG: Directly casting Moon Ward for Selene")
        local result = game.wizards[2]:queueSpell(game.customSpells.moonWard)
        print("DEBUG: Moon Ward cast result: " .. tostring(result))
    elseif key == "2" then
        -- Force cast Mirror Shield for Selene
        print("DEBUG: Directly casting Mirror Shield for Selene")
        local result = game.wizards[2]:queueSpell(game.customSpells.mirrorShield)
        print("DEBUG: Mirror Shield cast result: " .. tostring(result))
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
    
    -- Debug: Test VFX effects with number keys
    if key == "1" then
        -- Test firebolt effect
        game.vfx.createEffect("firebolt", game.wizards[1].x, game.wizards[1].y, game.wizards[2].x, game.wizards[2].y)
        print("Testing firebolt VFX")
    elseif key == "2" then
        -- Test meteor effect 
        game.vfx.createEffect("meteor", game.wizards[2].x, game.wizards[2].y - 100, game.wizards[2].x, game.wizards[2].y)
        print("Testing meteor VFX")
    elseif key == "3" then
        -- Test mist veil effect
        game.vfx.createEffect("mistveil", game.wizards[1].x, game.wizards[1].y)
        print("Testing mist veil VFX")
    elseif key == "4" then
        -- Test emberlift effect
        game.vfx.createEffect("emberlift", game.wizards[2].x, game.wizards[2].y)
        print("Testing emberlift VFX") 
    elseif key == "5" then
        -- Test full moon beam effect
        game.vfx.createEffect("fullmoonbeam", game.wizards[2].x, game.wizards[2].y, game.wizards[1].x, game.wizards[1].y)
        print("Testing full moon beam VFX")
    elseif key == "6" then
        -- Test conjure fire effect
        game.vfx.createEffect("conjurefire", game.wizards[1].x, game.wizards[1].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing conjure fire VFX")
    elseif key == "7" then
        -- Test conjure moonlight effect
        game.vfx.createEffect("conjuremoonlight", game.wizards[2].x, game.wizards[2].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing conjure moonlight VFX")
    elseif key == "8" then
        -- Test volatile conjuring effect
        game.vfx.createEffect("volatileconjuring", game.wizards[1].x, game.wizards[1].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing volatile conjuring VFX")
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