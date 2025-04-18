-- Manastorm - Wizard Duel Game
-- Main game file

-- Load dependencies
local AssetCache = require("core.AssetCache")
local AssetPreloader = require("core.assetPreloader")
local Constants = require("core.Constants")
local Input = require("core.Input")
local Pool = require("core.Pool")
local Wizard = require("wizard")
local ManaPool = require("manapool")
local UI = require("ui")
local VFX = require("vfx")
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local SpellsModule = require("spells")

-- Resolution settings
local baseWidth = 800    -- Base design resolution width
local baseHeight = 600   -- Base design resolution height
local scale = 1          -- Current scaling factor
local offsetX = 0        -- Horizontal offset for pillarboxing
local offsetY = 0        -- Vertical offset for letterboxing

-- Game state (globally accessible)
game = {
    wizards = {},
    manaPool = nil,
    font = nil,
    rangeState = Constants.RangeState.FAR,  -- Initial range state (NEAR or FAR)
    gameOver = false,
    winner = nil,
    winScreenTimer = 0,
    winScreenDuration = 5,  -- How long to show the win screen before auto-reset
    keywords = Keywords,
    spellCompiler = SpellCompiler,
    -- Resolution properties
    baseWidth = baseWidth,
    baseHeight = baseHeight,
    scale = scale,
    offsetX = offsetX,
    offsetY = offsetY
}

-- Define token types and images (globally available for consistency)
game.tokenTypes = {
    Constants.TokenType.FIRE, 
    Constants.TokenType.FORCE, 
    Constants.TokenType.MOON, 
    Constants.TokenType.NATURE, 
    Constants.TokenType.STAR
}
game.tokenImages = {
    [Constants.TokenType.FIRE] = "assets/sprites/fire-token.png",
    [Constants.TokenType.FORCE] = "assets/sprites/force-token.png",
    [Constants.TokenType.MOON] = "assets/sprites/moon-token.png",
    [Constants.TokenType.NATURE] = "assets/sprites/nature-token.png",
    [Constants.TokenType.STAR] = "assets/sprites/star-token.png"
}

-- Helper function to add a random token to the mana pool
function game.addRandomToken()
    local randomType = game.tokenTypes[math.random(#game.tokenTypes)]
    game.manaPool:addToken(randomType, game.tokenImages[randomType])
    return randomType
end

-- Calculate the appropriate scaling for the current window size
function calculateScaling()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Calculate possible scales (use integer scaling for pixel art crispness)
    local scaleX = math.floor(windowWidth / baseWidth)
    local scaleY = math.floor(windowHeight / baseHeight)
    
    -- Use the smaller scale to fit the screen
    scale = math.max(1, math.min(scaleX, scaleY))
    
    -- Calculate offsets for centering (letterbox/pillarbox)
    offsetX = math.floor((windowWidth - baseWidth * scale) / 2)
    offsetY = math.floor((windowHeight - baseHeight * scale) / 2)
    
    -- Update global references
    game.scale = scale
    game.offsetX = offsetX
    game.offsetY = offsetY
    
    print("Window resized: " .. windowWidth .. "x" .. windowHeight .. " (scale: " .. scale .. ")")
end

-- Handle window resize events
function love.resize(width, height)
    calculateScaling()
end

-- Set up pixel art-friendly scaling
function configurePixelArtRendering()
    -- Disable texture filtering for crisp pixel art
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    
    -- Use integer scaling when possible
    love.graphics.setLineStyle("rough")
end

function love.load()
    -- Set up window
    love.window.setTitle("Manastorm - Wizard Duel")
    
    -- Configure pixel art rendering
    configurePixelArtRendering()
    
    -- Calculate initial scaling
    calculateScaling()
    
    -- Preload all assets to prevent in-game loading hitches
    print("Preloading game assets...")
    local preloadStats = AssetPreloader.preloadAllAssets()
    print(string.format("Asset preloading complete: %d images, %d sounds in %.2f seconds",
                        preloadStats.imageCount,
                        preloadStats.soundCount,
                        preloadStats.loadTime))
    
    -- Set up game object to have calculateScaling function that can be called by Input
    game.calculateScaling = calculateScaling
    
    -- Load game font
    -- For now, fall back to system font if custom font isn't available
    local fontPath = "assets/fonts/Lionscript-Regular.ttf"
    local fontExists = love.filesystem.getInfo(fontPath)
    
    if fontExists then
        game.font = love.graphics.newFont(fontPath, 16)
        print("Using custom game font: " .. fontPath)
    else
        game.font = love.graphics.newFont(16)  -- Default system font
        print("Custom font not found, using system font")
    end
    
    -- Set default font for normal rendering
    love.graphics.setFont(game.font)
    
    -- Create mana pool positioned above the battlefield, but below health bars
    game.manaPool = ManaPool.new(baseWidth/2, 120)  -- Positioned between health bars and wizards
    
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
    
    -- Precompile all spells for better performance
    print("Precompiling all spells...")
    
    -- Create a compiledSpells table and do the compilation ourselves
    game.compiledSpells = {}
    
    -- Get all spells from the SpellsModule
    local allSpells = SpellsModule.spells
    
    -- Compile each spell
    for id, spell in pairs(allSpells) do
        game.compiledSpells[id] = game.spellCompiler.compileSpell(spell, game.keywords)
        print("Compiled spell: " .. spell.name)
    end
    
    -- Count compiled spells
    local count = 0
    for _ in pairs(game.compiledSpells) do
        count = count + 1
    end
    
    print("Precompiled " .. count .. " spells")
    
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
    
    -- Compile custom spells too
    for id, spell in pairs(game.customSpells) do
        game.compiledSpells[id] = game.spellCompiler.compileSpell(spell, game.keywords)
        print("Compiled custom spell: " .. spell.name)
    end
    
    -- Initialize mana pool with a single random token to start
    local tokenType = game.addRandomToken()
    
    -- Log which token was added
    print("Starting the game with a single " .. tokenType .. " token")
    
    -- Initialize input system with game state reference
    Input.init(game)
    print("Input system initialized")
end

-- Display hotkey help overlay
function drawHotkeyHelp()
    local x = baseWidth - 300
    local y = 50
    local lineHeight = 20
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x - 10, y - 10, 290, 500)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("HOTKEY REFERENCE", x, y)
    y = y + lineHeight * 2
    
    -- System keys
    love.graphics.setColor(0.8, 0.8, 1, 1)
    love.graphics.print("SYSTEM:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.system) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
    y = y + lineHeight/2
    
    -- Player 1 keys
    love.graphics.setColor(1, 0.5, 0.5, 1)
    love.graphics.print("PLAYER 1:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.player1) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
    y = y + lineHeight/2
    
    -- Player 2 keys
    love.graphics.setColor(0.5, 0.5, 1, 1)
    love.graphics.print("PLAYER 2:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.player2) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
    y = y + lineHeight/2
    
    -- Debug keys
    love.graphics.setColor(0.8, 1, 0.8, 1)
    love.graphics.print("DEBUG:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.debug) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
    
    -- Testing keys
    y = y + lineHeight/2
    love.graphics.setColor(1, 0.8, 0.5, 1)
    love.graphics.print("TESTING:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.testing) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
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
    game.rangeState = Constants.RangeState.FAR
    
    -- Clear mana pool and add a single token to start
    game.manaPool:clear()
    local tokenType = game.addRandomToken()
    
    -- Reset health display animation state
    for i = 1, 2 do
        local display = UI.healthDisplay["player" .. i]
        display.currentHealth = 100
        display.targetHealth = 100
        display.pendingDamage = 0
        display.lastDamageTime = 0
    end
    
    print("Game reset! Starting with a single " .. tokenType .. " token")
end

-- Add resetGame function to game state so Input system can call it
function game.resetGame()
    resetGame()
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
    
    -- Update animated health displays
    UI.updateHealthDisplays(dt, game.wizards)
end

function love.draw()
    -- Clear entire screen to black first (for letterboxing/pillarboxing)
    love.graphics.clear(0, 0, 0, 1)
    
    -- Setup scaling transform
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)
    
    -- Clear game area with game background color
    love.graphics.setColor(20/255, 20/255, 40/255, 1)
    love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    
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
    
    -- Draw UI elements in proper z-order
    love.graphics.setColor(1, 1, 1)
    
    -- First draw health bars and basic UI components
    UI.drawSpellInfo(game.wizards)
    
    -- Then draw spellbook buttons (the input feedback bar)
    UI.drawSpellbookButtons()
    
    -- Finally draw spellbook modals on top of everything else
    UI.drawSpellbookModals(game.wizards)
    
    -- Draw win screen if game is over
    if game.gameOver and game.winner then
        drawWinScreen()
    end
    
    -- Debug info only when debug key is pressed
    if love.keyboard.isDown("`") then
        UI.drawHelpText(game.font)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        
        -- Show scaling info in debug mode
        love.graphics.print("Scale: " .. scale .. "x (" .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight() .. ")", 10, 30)
        
        -- Show asset cache stats in debug mode
        local stats = AssetCache.dumpStats()
        love.graphics.print(string.format("Assets: %d images, %d sounds loaded", 
                            stats.images.loaded, stats.sounds.loaded), 10, 50)

        -- Show Pool stats in debug mode
        if love.keyboard.isDown("p") then
            -- Draw pool statistics overlay
            Pool.drawDebugOverlay()
            -- Also show VFX-specific stats
            game.vfx.showPoolStats()
        else
            love.graphics.print("Press P while in debug mode to see object pool stats", 10, 70)
        end
        
        -- Show hotkey summary when debug overlay is active
        if love.keyboard.isDown("tab") then
            drawHotkeyHelp()
        else
            love.graphics.print("Press TAB while in debug mode to see hotkeys", 10, 90)
        end
    else
        -- Always show a small hint about the debug key
        love.graphics.setColor(0.6, 0.6, 0.6, 0.4)
        love.graphics.print("Press ` for debug controls", 10, baseHeight - 20)
    end
    
    -- End scaling transform
    love.graphics.pop()
    
    -- Draw letterbox/pillarbox borders if needed
    if offsetX > 0 or offsetY > 0 then
        love.graphics.setColor(0, 0, 0)
        -- Top letterbox
        if offsetY > 0 then
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), offsetY)
            love.graphics.rectangle("fill", 0, love.graphics.getHeight() - offsetY, love.graphics.getWidth(), offsetY)
        end
        -- Left/right pillarbox
        if offsetX > 0 then
            love.graphics.rectangle("fill", 0, 0, offsetX, love.graphics.getHeight())
            love.graphics.rectangle("fill", love.graphics.getWidth() - offsetX, 0, offsetX, love.graphics.getHeight())
        end
    end
end

-- Helper function to convert real screen coordinates to virtual (scaled) coordinates
function screenToGameCoords(x, y)
    if not x or not y then return nil, nil end
    
    -- Adjust for offset and scale
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    
    -- Check if the point is outside the game area
    if virtualX < 0 or virtualX > baseWidth or virtualY < 0 or virtualY > baseHeight then
        return nil, nil  -- Out of bounds
    end
    
    return virtualX, virtualY
end

-- Override love.mouse.getPosition for seamless integration
local original_getPosition = love.mouse.getPosition
love.mouse.getPosition = function()
    local rx, ry = original_getPosition()
    local vx, vy = screenToGameCoords(rx, ry)
    return vx or 0, vy or 0
end

-- Draw the win screen
function drawWinScreen()
    local screenWidth = baseWidth
    local screenHeight = baseHeight
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

-- Unified key handler using the Input module
function love.keypressed(key, scancode, isrepeat)
    -- Forward all key presses to the Input module
    return Input.handleKey(key, scancode, isrepeat)
end

-- Unified key release handler
function love.keyreleased(key, scancode)
    -- Forward all key releases to the Input module
    return Input.handleKeyReleased(key, scancode)
end