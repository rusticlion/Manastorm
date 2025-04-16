# Manastorm Codebase Dump
Generated: Wed Apr 16 08:35:18 CDT 2025

# Source Code

## ./conf.lua
```lua
-- Configuration
function love.conf(t)
    t.title = "Manastorm - Wizard Duel"  -- The title of the window
    t.version = "11.4"                    -- The LÖVE version this game was made for
    t.window.width = 800
    t.window.height = 600
    
    t.window.vsync = 1                    -- Vertical sync (1 = enabled)
    t.window.msaa = 2                     -- Anti-aliasing (smoothing)
    
    -- For debugging
    t.console = true
    
    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = false
end```

## ./main.lua
```lua
-- Manastorm - Wizard Duel Game
-- Main game file

-- Load dependencies
local Wizard = require("wizard")
local ManaPool = require("manapool")
local UI = require("ui")
local VFX = require("vfx")

-- Game state (globally accessible)
game = {
    wizards = {},
    manaPool = nil,
    font = nil,
    rangeState = "FAR"  -- Initial range state (NEAR or FAR)
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
    
    -- Create wizards
    game.wizards[1] = Wizard.new("Ashgar", 200, 300, {255, 100, 100})
    game.wizards[2] = Wizard.new("Selene", 600, 300, {100, 100, 255})
    
    -- Set up references
    for _, wizard in ipairs(game.wizards) do
        wizard.manaPool = game.manaPool
        wizard.gameState = game
    end
    
    -- Initialize VFX system
    game.vfx = VFX.init()
    
    -- Initialize mana pool with a single random token to start
    local tokenType = game.addRandomToken()
    
    -- Log which token was added
    print("Starting the game with a single " .. tokenType .. " token")
end

function love.update(dt)
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
    
    -- Debug: Add a single random token with T key
    if key == "t" then
        local tokenType = game.addRandomToken()
        print("Added a " .. tokenType .. " token to the mana pool")
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
end```

## ./manapool.lua
```lua
-- ManaPool class
-- Represents the shared pool of mana tokens in the center

local ManaPool = {}
ManaPool.__index = ManaPool

function ManaPool.new(x, y)
    local self = setmetatable({}, ManaPool)
    
    self.x = x
    self.y = y
    self.tokens = {}  -- List of mana tokens
    
    -- Make elliptical shape even flatter and wider
    self.radiusX = 280  -- Wider horizontal radius
    self.radiusY = 60   -- Flatter vertical radius
    
    -- Define orbital rings (valences) for tokens to follow
    self.valences = {
        {radiusX = 180, radiusY = 25, baseSpeed = 0.35},  -- Inner valence
        {radiusX = 230, radiusY = 40, baseSpeed = 0.25},  -- Middle valence
        {radiusX = 280, radiusY = 55, baseSpeed = 0.18}   -- Outer valence
    }
    
    -- Chance for a token to switch valences
    self.valenceJumpChance = 0.002  -- Per frame chance of switching
    
    -- Load lock overlay image
    self.lockOverlay = love.graphics.newImage("assets/sprites/token-lock.png")
    
    return self
end

function ManaPool:addToken(tokenType, imagePath)
    -- Pick a random valence for the token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    
    -- Calculate a random angle along the valence
    local angle = math.random() * math.pi * 2
    
    -- Calculate position based on elliptical path
    local x = self.x + math.cos(angle) * valence.radiusX
    local y = self.y + math.sin(angle) * valence.radiusY
    
    -- Generate slight positional variation to avoid tokens stacking perfectly
    local variationX = math.random(-5, 5)
    local variationY = math.random(-3, 3)
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Create a new token with valence-based properties
    local token = {
        type = tokenType,
        image = love.graphics.newImage(imagePath),
        x = x + variationX,
        y = y + variationY,
        state = "FREE",  -- FREE, CHANNELED, LOCKED, DESTROYED
        lockDuration = 0, -- Duration for how long a token remains locked
        
        -- Valence-based orbit properties
        valenceIndex = valenceIndex,
        orbitAngle = angle,
        -- Speed varies by token but influenced by valence's base speed
        orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction,
        
        -- Visual effects
        pulsePhase = math.random() * math.pi * 2,
        pulseSpeed = 2 + math.random() * 3,
        rotAngle = math.random() * math.pi * 2,
        rotSpeed = math.random(-2, 2) * 0.5, -- Varying rotation speeds
        
        -- Valence jump timer (occasional orbit changes)
        valenceJumpTimer = 2 + math.random() * 8, -- Random time until possible valence change
        
        -- Valence transition properties (for smooth valence changes)
        inValenceTransition = false,
        valenceTransitionTime = 0,
        valenceTransitionDuration = 0.8,
        sourceValenceIndex = valenceIndex,
        targetValenceIndex = valenceIndex,
        sourceRadiusX = valence.radiusX,
        sourceRadiusY = valence.radiusY,
        targetRadiusX = valence.radiusX,
        targetRadiusY = valence.radiusY,
        currentRadiusX = valence.radiusX,
        currentRadiusY = valence.radiusY,
        
        -- Visual effect for locked state
        lockPulse = 0, -- For pulsing animation when locked
        
        -- Size variation for visual interest
        scale = 0.85 + math.random() * 0.3, -- Slight size variation
        
        -- Depth/z-order variation
        zOrder = math.random(),  -- Used for layering tokens
    }
    
    token.originalSpeed = token.orbitSpeed
    
    table.insert(self.tokens, token)
end

function ManaPool:update(dt)
    -- Update token positions and states
    for _, token in ipairs(self.tokens) do
        -- Update token position based on state
        if token.state == "FREE" then
            -- Handle the transition period for newly returned tokens
            if token.inTransition then
                token.transitionTime = token.transitionTime + dt
                local transProgress = math.min(1, token.transitionTime / token.transitionDuration)
                
                -- Ease transition using a smooth curve
                transProgress = transProgress < 0.5 and 4 * transProgress * transProgress * transProgress 
                            or 1 - math.pow(-2 * transProgress + 2, 3) / 2
                
                -- During transition, gradually start orbital motion
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt * transProgress
                
                -- Check if transition is complete
                if token.transitionTime >= token.transitionDuration then
                    token.inTransition = false
                end
            else
                -- Normal FREE token behavior after transition
                -- Update orbit angle with variable speed
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt
                
                -- Update valence jump timer
                token.valenceJumpTimer = token.valenceJumpTimer - dt
                
                -- Chance to change valence when timer expires
                if token.valenceJumpTimer <= 0 then
                    token.valenceJumpTimer = 2 + math.random() * 8  -- Reset timer
                    
                    -- Random chance to jump to a different valence
                    if math.random() < self.valenceJumpChance * 100 then
                        -- Store current valence for interpolation
                        local oldValenceIndex = token.valenceIndex
                        local oldValence = self.valences[oldValenceIndex]
                        local newValenceIndex = oldValenceIndex
                        
                        -- Ensure we pick a different valence if more than one exists
                        if #self.valences > 1 then
                            while newValenceIndex == oldValenceIndex do
                                newValenceIndex = math.random(1, #self.valences)
                            end
                        end
                        
                        -- Start valence transition
                        local newValence = self.valences[newValenceIndex]
                        local direction = token.orbitSpeed > 0 and 1 or -1
                        
                        -- Set up transition parameters
                        token.inValenceTransition = true
                        token.valenceTransitionTime = 0
                        token.valenceTransitionDuration = 0.8  -- Time to transition between valences
                        token.sourceValenceIndex = oldValenceIndex
                        token.targetValenceIndex = newValenceIndex
                        token.sourceRadiusX = oldValence.radiusX
                        token.sourceRadiusY = oldValence.radiusY
                        token.targetRadiusX = newValence.radiusX
                        token.targetRadiusY = newValence.radiusY
                        
                        -- Update speed for new valence but maintain direction
                        token.orbitSpeed = newValence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                        token.originalSpeed = token.orbitSpeed
                    end
                end
                
                -- Handle valence transition if active
                if token.inValenceTransition then
                    token.valenceTransitionTime = token.valenceTransitionTime + dt
                    local progress = math.min(1, token.valenceTransitionTime / token.valenceTransitionDuration)
                    
                    -- Use easing function for smooth transition
                    progress = progress < 0.5 and 4 * progress * progress * progress 
                              or 1 - math.pow(-2 * progress + 2, 3) / 2
                    
                    -- Interpolate between source and target radiuses
                    token.currentRadiusX = token.sourceRadiusX + (token.targetRadiusX - token.sourceRadiusX) * progress
                    token.currentRadiusY = token.sourceRadiusY + (token.targetRadiusY - token.sourceRadiusY) * progress
                    
                    -- Check if transition is complete
                    if token.valenceTransitionTime >= token.valenceTransitionDuration then
                        token.inValenceTransition = false
                        token.valenceIndex = token.targetValenceIndex
                    end
                end
                
                -- Occasionally vary the speed slightly
                if math.random() < 0.01 then
                    local direction = token.orbitSpeed > 0 and 1 or -1
                    local valence = self.valences[token.valenceIndex]
                    local variation = 0.9 + math.random() * 0.2  -- Subtle variation
                    token.orbitSpeed = valence.baseSpeed * variation * direction
                end
            end
            
            -- Common behavior for all FREE tokens
            -- Update pulse phase
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            
            -- Calculate new position based on elliptical orbit - maintain perfect elliptical path
            if token.inValenceTransition then
                -- Use interpolated radii during transition
                token.x = self.x + math.cos(token.orbitAngle) * token.currentRadiusX
                token.y = self.y + math.sin(token.orbitAngle) * token.currentRadiusY
            else
                -- Use valence radii when not transitioning
                local valence = self.valences[token.valenceIndex]
                token.x = self.x + math.cos(token.orbitAngle) * valence.radiusX
                token.y = self.y + math.sin(token.orbitAngle) * valence.radiusY
            end
            
            -- Minimal wobble to maintain clean orbits but add slight visual interest
            local wobbleX = math.sin(token.pulsePhase * 0.7) * 2
            local wobbleY = math.cos(token.pulsePhase * 0.5) * 1
            token.x = token.x + wobbleX
            token.y = token.y + wobbleY
            
            -- Rotate token itself for visual interest, occasionally reversing direction
            token.rotAngle = token.rotAngle + token.rotSpeed * dt
            if math.random() < 0.002 then  -- Small chance to reverse rotation
                token.rotSpeed = -token.rotSpeed
            end
        elseif token.state == "CHANNELED" then
            -- For channeled tokens, animate movement to/from their spell slot
            
            if token.animTime < token.animDuration then
                -- Token is still being animated to the spell slot
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                -- Start point
                local x0 = token.startX
                local y0 = token.startY
                
                -- End point (in the spell slot)
                local wizard = token.wizardOwner
                if wizard then
                    -- Calculate position in the 3D elliptical spell slot orbit
                    -- These values must match those in wizard.lua drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}  -- From bottom to top
                    local verticalRadii = {20, 25, 30}    -- From bottom to top
                    
                    local slotY = wizard.y + slotYOffsets[token.slotIndex]
                    local radiusX = horizontalRadii[token.slotIndex]
                    local radiusY = verticalRadii[token.slotIndex]
                    
                    local tokenCount = #wizard.spellSlots[token.slotIndex].tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = wizard.spellSlots[token.slotIndex].progress / 
                                       wizard.spellSlots[token.slotIndex].castTime * math.pi * 2 +
                                       anglePerToken * (token.tokenIndex - 1)
                    
                    -- Calculate position using elliptical projection
                    local x3 = wizard.x + math.cos(tokenAngle) * radiusX
                    local y3 = slotY + math.sin(tokenAngle) * radiusY
                    
                    -- Control points for bezier (creating an arc)
                    local midX = (x0 + x3) / 2
                    local midY = (y0 + y3) / 2 - 80  -- Arc height
                    
                    -- Quadratic bezier calculation
                    local t = progress
                    local u = 1 - t
                    token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                    token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                    
                    -- Update token rotation during flight
                    token.rotAngle = token.rotAngle + dt * 5  -- Spin faster during flight
                    
                    -- Store target position for the drawing function
                    token.targetX = x3
                    token.targetY = y3
                end
            else
                -- Animation complete - token is now in the spell orbit
                -- Token position will be updated by the wizard's drawSpellSlots function
                token.rotAngle = token.rotAngle + dt * 2  -- Continue spinning in orbit
            end
            
            -- Check if token is returning to the pool
            if token.returning then
                -- Token is being animated back to the mana pool
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                local x0 = token.startX
                local y0 = token.startY
                local x3 = self.x  -- Center of mana pool
                local y3 = self.y
                
                -- Control points for bezier (creating an arc)
                local midX = (x0 + x3) / 2
                local midY = (y0 + y3) / 2 - 50  -- Arc height
                
                -- Quadratic bezier calculation
                local t = progress
                local u = 1 - t
                token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                
                -- Update token rotation during flight - spin faster
                token.rotAngle = token.rotAngle + dt * 8
                
                -- Check if animation is complete
                if token.animTime >= token.animDuration then
                    -- Finalize the return
                    self:finalizeTokenReturn(token)
                end
            end
            
            -- Update common pulse
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
        elseif token.state == "LOCKED" then
            -- For locked tokens, update the lock duration
            if token.lockDuration > 0 then
                token.lockDuration = token.lockDuration - dt
                
                -- Update lock pulse for animation
                token.lockPulse = (token.lockPulse + dt * 3) % (math.pi * 2)
                
                -- When lock duration expires, return to FREE state
                if token.lockDuration <= 0 then
                    token.state = "FREE"
                    print("A " .. token.type .. " token has been unlocked and returned to the mana pool")
                    
                    -- Reset position to center with some random velocity
                    token.x = self.x
                    token.y = self.y
                    -- Pick a random valence for the formerly locked token
                    token.valenceIndex = math.random(1, #self.valences)
                    token.orbitAngle = math.random() * math.pi * 2
                    -- Set direction and speed based on the valence
                    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
                    local valence = self.valences[token.valenceIndex]
                    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                    token.originalSpeed = token.orbitSpeed
                end
            end
            
            -- Even locked tokens should move a bit, but more constrained
            token.x = token.x + math.sin(token.lockPulse) * 0.3
            token.y = token.y + math.cos(token.lockPulse) * 0.3
            
            -- Slight rotation
            token.rotAngle = token.rotAngle + token.rotSpeed * dt * 0.2
        end
        
        -- Update common properties for all tokens
        token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
    end
end

function ManaPool:draw()
    -- Draw pool background with a subtle gradient effect for elliptical shape
    love.graphics.setColor(0.15, 0.15, 0.25, 0.2)
    
    -- Draw the elliptical mana pool area with a glow effect
    self:drawEllipse(self.x, self.y, self.radiusX, self.radiusY, "fill")
    
    -- Draw valence rings subtly
    for _, valence in ipairs(self.valences) do
        local alpha = 0.07  -- Very subtle
        love.graphics.setColor(0.5, 0.5, 0.7, alpha)
        
        -- Draw elliptical valence path
        self:drawEllipse(self.x, self.y, valence.radiusX, valence.radiusY, "line")
    end
    
    -- Sort tokens by z-order for better layering
    local sortedTokens = {}
    for i, token in ipairs(self.tokens) do
        table.insert(sortedTokens, {token = token, index = i})
    end
    
    table.sort(sortedTokens, function(a, b)
        return a.token.zOrder > b.token.zOrder
    end)
    
    -- Draw tokens in sorted order
    for _, tokenData in ipairs(sortedTokens) do
        local token = tokenData.token
        
        -- Draw a glow around the token based on its type
        local glowSize = 10
        local glowIntensity = 0.4  -- Slightly stronger glow
        
        -- Increase glow for tokens in transition (newly returned to pool)
        if token.state == "FREE" and token.inTransition then
            -- Stronger glow that fades over the transition period
            local transitionBoost = 0.4 + 0.6 * (1 - token.transitionTime / token.transitionDuration)
            glowSize = glowSize * (1 + transitionBoost * 0.5)
            glowIntensity = glowIntensity + transitionBoost * 0.4
        end
        
        -- Set glow color based on token type with improved contrast
        if token.type == "fire" then
            love.graphics.setColor(1, 0.3, 0.1, glowIntensity)
        elseif token.type == "force" then
            love.graphics.setColor(1, 1, 0.5, glowIntensity)
        elseif token.type == "moon" then
            love.graphics.setColor(0.5, 0.5, 1, glowIntensity)
        elseif token.type == "nature" then
            love.graphics.setColor(0.3, 0.9, 0.1, glowIntensity)
        elseif token.type == "star" then
            love.graphics.setColor(1, 1, 0.2, glowIntensity)
        end
        
        -- Draw glow with pulsation
        local pulseAmount = 0.7 + 0.3 * math.sin(token.pulsePhase * 0.5)
        
        -- Enhanced pulsation for transitioning tokens
        if token.state == "FREE" and token.inTransition then
            pulseAmount = pulseAmount + 0.3 * math.sin(token.transitionTime * 10)
        end
        
        love.graphics.circle("fill", token.x, token.y, glowSize * pulseAmount * token.scale)
        
        -- Draw token image based on state
        if token.state == "FREE" then
            -- Free tokens are fully visible
            -- If token is in transition (just returned to pool), add a subtle glow effect
            if token.inTransition then
                local transitionGlow = 0.2 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
                love.graphics.setColor(1, 1, 1 + transitionGlow * 0.5, 1)  -- Slightly blue-white glow during transition
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
        elseif token.state == "CHANNELED" then
            -- Channeled tokens are fully visible
            love.graphics.setColor(1, 1, 1, 1)
        elseif token.state == "LOCKED" then
            -- Locked tokens have a red tint
            love.graphics.setColor(1, 0.5, 0.5, 0.7)
        end
        
        -- Draw the token with dynamic scaling
        love.graphics.draw(
            token.image, 
            token.x, 
            token.y, 
            token.rotAngle,  -- Use the rotation angle
            token.scale, token.scale,  -- Use token-specific scale
            token.image:getWidth()/2, token.image:getHeight()/2  -- Origin at center
        )
        
        -- Draw lock overlay for locked tokens
        if token.state == "LOCKED" then
            -- Draw the lock overlay
            local pulseScale = 0.9 + math.sin(token.lockPulse) * 0.2  -- Pulsing effect
            local overlayScale = 1.2 * pulseScale * token.scale  -- Scale for the lock overlay
            
            -- Pulsing red glow behind the lock
            love.graphics.setColor(1, 0, 0, 0.3 + 0.2 * math.sin(token.lockPulse))
            love.graphics.circle("fill", token.x, token.y, 12 * pulseScale * token.scale)
            
            -- Lock icon
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                self.lockOverlay,
                token.x,
                token.y,
                0,  -- No rotation for lock
                overlayScale, overlayScale,
                self.lockOverlay:getWidth()/2, self.lockOverlay:getHeight()/2
            )
            
            -- Display remaining lock time if more than 1 second
            if token.lockDuration > 1 then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(
                    string.format("%.0f", token.lockDuration),
                    token.x - 5,
                    token.y - 25
                )
            end
        end
    end
    
    -- Outer border with subtle glow
    love.graphics.setColor(0.5, 0.5, 0.8, 0.2 + 0.1 * math.sin(love.timer.getTime() * 0.5))
    self:drawEllipse(self.x, self.y, self.radiusX + 2, self.radiusY + 2, "line")
end

-- Helper function to draw an ellipse
function ManaPool:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 64
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

function ManaPool:findFreeToken(tokenType)
    -- Find a free token of the specified type without changing its state
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            return token, i  -- Return token and its index without changing state
        end
    end
    return nil  -- No token available
end

function ManaPool:getToken(tokenType)
    -- Find a free token of the specified type
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            token.state = "CHANNELED"  -- Mark as being used
            return token, i  -- Return token and its index
        end
    end
    return nil  -- No token available
end

function ManaPool:returnToken(tokenIndex)
    -- Return a token to the pool
    if self.tokens[tokenIndex] then
        local token = self.tokens[tokenIndex]
        
        -- Store current position as start position for return animation
        token.startX = token.x
        token.startY = token.y
        
        -- Pick a random valence for the token to return to
        local valenceIndex = math.random(1, #self.valences)
        
        -- Initialize needed valence transition fields
        local valence = self.valences[valenceIndex]
        token.valenceIndex = valenceIndex
        token.sourceValenceIndex = valenceIndex  -- Will be properly set in finalizeTokenReturn
        token.targetValenceIndex = valenceIndex
        token.sourceRadiusX = valence.radiusX
        token.sourceRadiusY = valence.radiusY
        token.targetRadiusX = valence.radiusX
        token.targetRadiusY = valence.radiusY
        token.currentRadiusX = valence.radiusX
        token.currentRadiusY = valence.radiusY
        
        -- Set up return animation parameters
        token.targetX = self.x  -- Center of mana pool
        token.targetY = self.y
        token.animTime = 0
        token.animDuration = 0.5 -- Half second return animation
        token.returning = true   -- Flag that this token is returning to the pool
        
        -- When token finishes return animation, it will become FREE in update method
        
        -- Set direction and speed based on the valence
        local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
        token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
        token.originalSpeed = token.orbitSpeed
        
        -- Reset timers with some randomness
        token.valenceJumpTimer = 2 + math.random() * 4
        
        -- Initialize transition state for smooth blending
        token.inValenceTransition = false
        token.valenceTransitionTime = 0
        token.valenceTransitionDuration = 0.8
    end
end

-- Called by update method when a token finishes its return animation
function ManaPool:finalizeTokenReturn(token)
    -- Set token state to FREE
    token.state = "FREE"
    
    -- Use the final position from the animation as the starting point
    local currentX = token.x
    local currentY = token.y
    
    -- Calculate angle from center
    local dx = currentX - self.x
    local dy = currentY - self.y
    local angle = math.atan2(dy, dx)
    
    -- Assign a random valence for the returned token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    token.valenceIndex = valenceIndex
    
    -- Calculate position based on current angle but using valence's elliptical dimensions
    token.orbitAngle = angle
    
    -- Calculate initial x,y based on selected valence
    local newX = self.x + math.cos(angle) * valence.radiusX
    local newY = self.y + math.sin(angle) * valence.radiusY
    
    -- Apply minimal variation to maintain clean orbits
    local variationX = math.random(-2, 2)
    local variationY = math.random(-1, 1)
    token.x = newX + variationX
    token.y = newY + variationY
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Set orbital speed based on the valence
    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    token.originalSpeed = token.orbitSpeed
    
    -- Add transition for smooth blending
    token.transitionTime = 0
    token.transitionDuration = 1.0  -- 1 second to blend into normal motion
    token.inTransition = true  -- Mark token as transitioning to normal motion
    
    -- Add valence jump timer
    token.valenceJumpTimer = 2 + math.random() * 8
    
    -- Initialize valence transition properties
    token.inValenceTransition = false
    token.valenceTransitionTime = 0
    token.valenceTransitionDuration = 0.8
    token.sourceValenceIndex = valenceIndex
    token.targetValenceIndex = valenceIndex
    token.sourceRadiusX = valence.radiusX
    token.sourceRadiusY = valence.radiusY
    token.targetRadiusX = valence.radiusX
    token.targetRadiusY = valence.radiusY
    token.currentRadiusX = valence.radiusX
    token.currentRadiusY = valence.radiusY
    
    -- Size and z-order variation
    token.scale = 0.85 + math.random() * 0.3
    token.zOrder = math.random()
    
    -- Clear animation flags
    token.returning = false
    token.wizardOwner = nil
    
    print("A " .. token.type .. " token has returned to the mana pool")
end

return ManaPool```

## ./spells.lua
```lua
-- Spells.lua
-- Contains data for all spells in the game

local Spells = {}

-- Spell costs are defined as tables with mana type and count
-- For generic/any mana, use "any" as the type
-- For modal costs (can be paid with subset of types), use a table of types

-- Ashgar's Spells (Fire-focused)
Spells.conjurefire = {
    name = "Conjure Fire",
    description = "Creates a new Fire mana token",
    castTime = 2.0,  -- Fast cast time
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Create a fire token in the mana pool
        caster.manaPool:addToken("fire", "assets/sprites/fire-token.png")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.firebolt = {
    name = "Firebolt",
    description = "Quick ranged hit, more damage at FAR range",
    castTime = 5.0,  -- seconds
    spellType = "projectile",  -- Mark as a projectile spell
    cost = {
        {type = "fire", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        -- Access shared range state from game state reference
        local damage = 10
        if caster.gameState.rangeState == "FAR" then damage = 15 end
        return {
            damage = damage,
            damageType = "fire",  -- Type of damage
            spellType = "projectile"  -- Include in effect for blocking check
        }
    end
}

Spells.meteor = {
    name = "Meteor Dive",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = 8.0,
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1},
        {type = "star", count = 1}
    },
    effect = function(caster, target)
        if target.elevation ~= "GROUNDED" then return {damage = 0} end
        
        return {
            damage = 20,
            type = "fire",
            setPosition = "NEAR"  -- Moves caster to NEAR
        }
    end
}

Spells.combust = {
    name = "Combust Lock",
    description = "Locks opponent mana token, punishes overqueueing",
    castTime = 6.0,
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        -- Count active spell slots
        local activeSlots = 0
        for _, slot in ipairs(target.spellSlots) do
            if slot.active then
                activeSlots = activeSlots + 1
            end
        end
        
        return {
            lockToken = true,
            lockDuration = 10.0,  -- Lock mana token for 10 seconds
            damage = activeSlots * 3  -- More damage if target has many active spells
        }
    end
}

Spells.emberlift = {
    name = "Emberlift",
    description = "Launches caster into the air and increases range",
    castTime = 2.5,  -- Short cast time
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            elevationDuration = 5.0,  -- Sets AERIAL for 5 seconds
            setPosition = "FAR",      -- Sets range to FAR
            damage = 0
        }
    end
}

-- Selene's Spells (Moon-focused)
Spells.conjuremoonlight = {
    name = "Conjure Moonlight",
    description = "Creates a new Moon mana token",
    castTime = 2.0,  -- Fast cast time
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Create a moon token in the mana pool
        caster.manaPool:addToken("moon", "assets/sprites/moon-token.png")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.volatileconjuring = {
    name = "Volatile Conjuring",
    description = "Creates a random mana token",
    castTime = 1.4,  -- Shorter cast time than the dedicated conjuring spells
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Available token types and their image paths
        local tokenTypes = {
            {type = "fire", path = "assets/sprites/fire-token.png"},
            {type = "force", path = "assets/sprites/force-token.png"},
            {type = "moon", path = "assets/sprites/moon-token.png"},
            {type = "nature", path = "assets/sprites/nature-token.png"},
            {type = "star", path = "assets/sprites/star-token.png"}
        }
        
        -- Select a random token type
        local randomIndex = math.random(#tokenTypes)
        local selectedToken = tokenTypes[randomIndex]
        
        -- Create the token in the mana pool
        caster.manaPool:addToken(selectedToken.type, selectedToken.path)
        
        -- Display a message about which token was created (optional)
        print(caster.name .. " conjured a random " .. selectedToken.type .. " token")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.mist = {
    name = "Mist Veil",
    description = "Projectile block, grants AERIAL",
    castTime = 5.0,
    cost = {
        {type = "moon", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            block = "projectile",
            blockDuration = 5.0  -- Block projectiles for 5 seconds
        }
    end
}

Spells.gravity = {
    name = "Gravity Pin",
    description = "Traps AERIAL enemies",
    castTime = 7.0,
    cost = {
        {type = "moon", count = 1},
        {type = "nature", count = 1}
    },
    effect = function(caster, target)
        if target.elevation ~= "AERIAL" then return {damage = 0} end
        
        return {
            damage = 15,
            setElevation = "GROUNDED",
            stun = 2.0  -- Stun for 2 seconds
        }
    end
}

Spells.eclipse = {
    name = "Eclipse Echo",
    description = "Delays central queued spell",
    castTime = 6.0,
    cost = {
        {type = "moon", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        return {
            delaySpell = 2  -- Targets spell slot 2 (middle)
        }
    end
}

Spells.fullmoonbeam = {
    name = "Full Moon Beam",
    description = "Channels moonlight into a powerful beam",
    castTime = 7.0,    -- Long cast time
    cost = {
        {type = "moon", count = 5}  -- Costs 5 moon mana
    },
    effect = function(caster, target)
        return {
            damage = 25,     -- Deals 25 damage
            damageType = "moon"
        }
    end
}

return Spells```

## ./ui.lua
```lua
-- UI helper module

local UI = {}

-- Spellbook visibility state
UI.spellbookVisible = {
    player1 = false,
    player2 = false
}

function UI.drawHelpText(font)
    -- Set font and color
    love.graphics.setFont(font)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    
    -- Only show minimal debug controls at the bottom
    local y = love.graphics.getHeight() - 110
    love.graphics.print("Debug Controls: T (Add tokens), R (Toggle range), A/S (Toggle elevations), ESC (Quit)", 10, y + 50)
    love.graphics.print("VFX Test Keys: 1 (Firebolt), 2 (Meteor), 3 (Mist Veil), 4 (Emberlift), 5 (Full Moon Beam)", 10, y + 70)
    love.graphics.print("Conjure Test Keys: 6 (Fire), 7 (Moonlight), 8 (Volatile)", 10, y + 90)
    
    -- Draw spellbook buttons for each player
    UI.drawSpellbookButtons()
end

-- Toggle spellbook visibility for a player
function UI.toggleSpellbook(player)
    if player == 1 then
        UI.spellbookVisible.player1 = not UI.spellbookVisible.player1
        UI.spellbookVisible.player2 = false -- Close other spellbook
    elseif player == 2 then
        UI.spellbookVisible.player2 = not UI.spellbookVisible.player2
        UI.spellbookVisible.player1 = false -- Close other spellbook
    end
end

-- Draw skeuomorphic spellbook components for both players
function UI.drawSpellbookButtons()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw Player 1's spellbook (Ashgar - left side)
    UI.drawPlayerSpellbook(1, 100, screenHeight - 70)
    
    -- Draw Player 2's spellbook (Selene - right side)
    UI.drawPlayerSpellbook(2, screenWidth - 300, screenHeight - 70)
end

-- Draw an individual player's spellbook component
function UI.drawPlayerSpellbook(playerNum, x, y)
    local screenWidth = love.graphics.getWidth()
    local width = 260  -- Further increased for better spacing
    local height = 50
    local player = (playerNum == 1) and "Ashgar" or "Selene"
    local keyLabel = (playerNum == 1) and "B" or "M"
    local keyPrefix = (playerNum == 1) and {"Q", "W", "E"} or {"I", "O", "P"}
    local wizard = _G.game.wizards[playerNum]
    local color = {wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255}
    
    -- Draw book background with slight gradient
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.25, 0.25, 0.35, 0.9)
    love.graphics.rectangle("fill", x, y, width, height/2)
    
    -- Draw book binding/spine effect
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("fill", x, y, 6, height)
    
    -- Draw book edge
    love.graphics.setColor(0.8, 0.8, 0.8, 0.3)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw dividers between sections
    love.graphics.setColor(0.4, 0.4, 0.5, 0.4)
    love.graphics.line(x + 120, y + 5, x + 120, y + height - 5)
    
    -- Center everything vertically in pane
    local centerY = y + height/2
    local runeSize = 14
    local groupSpacing = 35
    
    -- GROUP 1: SPELL INPUT KEYS
    -- Add a subtle background for the key group
    love.graphics.setColor(0.2, 0.2, 0.3, 0.3)
    love.graphics.rectangle("fill", x + 15, centerY - 20, 110, 40, 5, 5)  -- Rounded corners
    
    -- Calculate positions for centered spell input keys
    local inputStartX = x + 30
    local inputY = centerY
    
    for i = 1, 3 do
        -- Draw rune background
        love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
        love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, runeSize)
        
        if wizard.activeKeys[i] then
            -- Active rune with glow effect
            -- Multiple layers for glow
            for j = 3, 1, -1 do
                local alpha = 0.3 * (4-j) / 3
                local size = runeSize + j * 2
                love.graphics.setColor(1, 1, 0.3, alpha)
                love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, size)
            end
            
            -- Bright center
            love.graphics.setColor(1, 1, 0.7, 0.9)
            love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, runeSize * 0.7)
            
            -- Properly centered rune symbol
            local keyText = keyPrefix[i]
            local keyTextWidth = love.graphics.getFont():getWidth(keyText)
            local keyTextHeight = love.graphics.getFont():getHeight()
            love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
            love.graphics.print(keyText, 
                inputStartX + (i-1)*groupSpacing - keyTextWidth/2, 
                inputY - keyTextHeight/2)
        else
            -- Inactive rune
            love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
            love.graphics.circle("line", inputStartX + (i-1)*groupSpacing, inputY, runeSize)
            
            -- Properly centered inactive symbol
            local keyText = keyPrefix[i]
            local keyTextWidth = love.graphics.getFont():getWidth(keyText)
            local keyTextHeight = love.graphics.getFont():getHeight()
            love.graphics.setColor(0.6, 0.6, 0.7, 0.6)
            love.graphics.print(keyText, 
                inputStartX + (i-1)*groupSpacing - keyTextWidth/2, 
                inputY - keyTextHeight/2)
        end
    end
    
    -- Small "input" label beneath
    love.graphics.setColor(0.6, 0.6, 0.8, 0.7)
    local inputLabel = "Input Keys"
    local inputLabelWidth = love.graphics.getFont():getWidth(inputLabel)
    love.graphics.print(inputLabel, inputStartX + groupSpacing - inputLabelWidth/2, inputY + runeSize + 8)
    
    -- GROUP 2: CAST BUTTON
    -- Positioned farther to the right
    local castX = x + 150
    local castKey = (playerNum == 1) and "F" or "L"
    
    -- Subtle highlighting background
    love.graphics.setColor(0.3, 0.2, 0.1, 0.3)
    love.graphics.rectangle("fill", castX - 20, centerY - 20, 40, 40, 5, 5)  -- Rounded corners
    
    -- Draw cast button background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
    love.graphics.circle("fill", castX, inputY, runeSize)
    
    -- Cast button border
    love.graphics.setColor(0.8, 0.4, 0.1, 0.8)  -- Orange-ish for cast button
    love.graphics.circle("line", castX, inputY, runeSize)
    
    -- Cast button symbol
    local castTextWidth = love.graphics.getFont():getWidth(castKey)
    local castTextHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(1, 0.8, 0.3, 0.9)
    love.graphics.print(castKey, 
        castX - castTextWidth/2, 
        inputY - castTextHeight/2)
    
    -- Small "cast" label beneath
    love.graphics.setColor(0.8, 0.6, 0.3, 0.8)
    local castLabel = "Cast"
    local castLabelWidth = love.graphics.getFont():getWidth(castLabel)
    love.graphics.print(castLabel, castX - castLabelWidth/2, inputY + runeSize + 8)
    
    -- GROUP 3: KEYED SPELL POPUP (appears above the spellbook when a spell is keyed)
    if wizard.currentKeyedSpell then
        -- Make the popup exactly match the width of the spellbook
        local popupWidth = width
        local popupHeight = 30
        local popupX = x  -- Align with spellbook
        local popupY = y - popupHeight - 5  -- Position above the spellbook with small gap
        
        -- Get spell name and calculate its width for centering
        local spellName = wizard.currentKeyedSpell.name
        local spellNameWidth = love.graphics.getFont():getWidth(spellName)
        
        -- Draw popup background with a slight "connected" look
        -- Use the same color as the spellbook for visual cohesion
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        
        -- Main popup body (rounded rectangle)
        love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 5, 5)
        
        -- Connection piece (small triangle pointing down)
        love.graphics.polygon("fill", 
            x + width/2 - 8, popupY + popupHeight,  -- Left point
            x + width/2 + 8, popupY + popupHeight,  -- Right point
            x + width/2, popupY + popupHeight + 8   -- Bottom point
        )
        
        -- Add a subtle border with the wizard's color
        love.graphics.setColor(color[1], color[2], color[3], 0.5)
        love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight, 5, 5)
        
        -- Subtle gradient for the background (matches the spellbook aesthetic)
        love.graphics.setColor(0.25, 0.25, 0.35, 0.7)
        love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight/2, 5, 5)
        
        -- Simple glow effect for the text
        for i = 3, 1, -1 do
            local alpha = 0.1 * (4-i) / 3
            local size = i * 2
            love.graphics.setColor(1, 1, 0.5, alpha)
            love.graphics.rectangle("fill", 
                x + width/2 - spellNameWidth/2 - size, 
                popupY + popupHeight/2 - 7 - size/2, 
                spellNameWidth + size*2, 
                14 + size,
                5, 5
            )
        end
        
        -- Spell name centered in the popup
        love.graphics.setColor(1, 1, 0.5, 0.9)
        love.graphics.print(spellName, 
            x + width/2 - spellNameWidth/2, 
            popupY + popupHeight/2 - 7
        )
    end
    
    -- GROUP 4: SPELLBOOK HELP (bottom-right corner)
    local helpX = x + width - 20
    local helpY = y + height - 16
    
    -- Draw key hint - smaller
    local helpSize = 8
    love.graphics.setColor(0.4, 0.4, 0.6, 0.7)  -- More subdued color
    love.graphics.circle("fill", helpX, helpY, helpSize)
    
    -- Properly centered key symbol - smaller font
    local smallFont = love.graphics.getFont()  -- We'll use the same font but draw it smaller
    local keyTextWidth = smallFont:getWidth(keyLabel)
    local keyTextHeight = smallFont:getHeight()
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(keyLabel, 
        helpX - keyTextWidth/4, 
        helpY - keyTextHeight/4,
        0, 0.5, 0.5)  -- Scale to 50%
    
    -- Small "?" indicator
    love.graphics.setColor(0.6, 0.6, 0.7, 0.7)
    local helpLabel = "?"
    local helpLabelWidth = smallFont:getWidth(helpLabel)
    love.graphics.print(helpLabel, 
        helpX - 15 - helpLabelWidth/2, 
        helpY - smallFont:getHeight()/4,
        0, 0.7, 0.7)  -- Scale to 70%
    
    -- Highlight when active
    if (playerNum == 1 and UI.spellbookVisible.player1) or 
       (playerNum == 2 and UI.spellbookVisible.player2) then
        love.graphics.setColor(color[1], color[2], color[3], 0.4)
        love.graphics.rectangle("fill", x, y, width, height)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", x - 2, y - 2, width + 4, height + 4)
    end
end

function UI.drawSpellInfo(wizards)
    -- Function to format mana cost for display
    local function formatCost(cost)
        if not cost or #cost == 0 then
            return "Free"
        end
        
        local costText = ""
        for _, component in ipairs(cost) do
            local typeText = component.type
            if type(typeText) == "table" then
                typeText = table.concat(typeText, "/")
            end
            costText = costText .. component.count .. " " .. typeText .. ", "
        end
        return costText:sub(1, -3)  -- Remove trailing comma and space
    end
    
    -- Draw the fighting game style health bars
    UI.drawHealthBars(wizards)
    
    -- Draw spellbook popups if visible
    if UI.spellbookVisible.player1 then
        UI.drawSpellbookModal(wizards[1], 1, formatCost)
    end
    
    if UI.spellbookVisible.player2 then
        UI.drawSpellbookModal(wizards[2], 2, formatCost)
    end
    
    -- Spell notification is now handled by the wizard's castSpell function
    -- No longer drawing active spells list - relying on visual representation
end

-- Draw dramatic fighting game style health bars
function UI.drawHealthBars(wizards)
    local screenWidth = love.graphics.getWidth()
    local barHeight = 30
    local barWidth = 300
    local padding = 40
    local y = 20
    
    -- Player 1 (Ashgar) health bar (left side, right-to-left depletion)
    local p1 = wizards[1]
    local p1HealthPercent = p1.health / 100
    
    -- Background and border
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", padding, y, barWidth, barHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", padding, y, barWidth, barHeight)
    
    -- Health fill with gradient
    local ashgarGradient = {
        {0.8, 0.2, 0.2},  -- Red base color
        {1.0, 0.3, 0.1}   -- Brighter highlight
    }
    
    -- Draw gradient health bar 
    for i = 0, barWidth * p1HealthPercent, 1 do
        local gradientPos = i / (barWidth * p1HealthPercent)
        local r = ashgarGradient[1][1] + (ashgarGradient[2][1] - ashgarGradient[1][1]) * gradientPos
        local g = ashgarGradient[1][2] + (ashgarGradient[2][2] - ashgarGradient[1][2]) * gradientPos
        local b = ashgarGradient[1][3] + (ashgarGradient[2][3] - ashgarGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(padding + i, y + 5, padding + i, y + barHeight - 5)
    end
    
    -- Add segmented health bar sections
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    for i = 1, 9 do
        local x = padding + (barWidth / 10) * i
        love.graphics.line(x, y, x, y + barHeight)
    end
    
    -- Health lost "after damage" effect (fading darker region)
    local damageAmount = 1.0 - p1HealthPercent
    if damageAmount > 0 then
        love.graphics.setColor(0.5, 0.1, 0.1, 0.3)
        love.graphics.rectangle("fill", padding + barWidth * p1HealthPercent, y, barWidth * damageAmount, barHeight)
    end
    
    -- Gleaming highlight
    local time = love.timer.getTime()
    local hilight = math.abs(math.sin(time))
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", padding, y, barWidth * p1HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p1.name, padding + 20, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(math.floor(p1HealthPercent * 100) .. "%", padding + barWidth - 40, y + 7)
    
    
    -- Player 2 (Selene) health bar (right side, left-to-right depletion)
    local p2 = wizards[2]
    local p2HealthPercent = p2.health / 100
    local p2X = screenWidth - padding - barWidth
    
    -- Background and border
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", p2X, y, barWidth, barHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", p2X, y, barWidth, barHeight)
    
    -- Health fill with gradient
    local seleneGradient = {
        {0.1, 0.3, 0.8},  -- Blue base color
        {0.2, 0.5, 1.0}   -- Brighter highlight
    }
    
    -- Draw gradient health bar (left-to-right depletion)
    for i = 0, barWidth * p2HealthPercent, 1 do
        local gradientPos = i / (barWidth * p2HealthPercent)
        local r = seleneGradient[1][1] + (seleneGradient[2][1] - seleneGradient[1][1]) * gradientPos
        local g = seleneGradient[1][2] + (seleneGradient[2][2] - seleneGradient[1][2]) * gradientPos
        local b = seleneGradient[1][3] + (seleneGradient[2][3] - seleneGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(p2X + barWidth - i, y + 5, p2X + barWidth - i, y + barHeight - 5)
    end
    
    -- Add segmented health bar sections
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    for i = 1, 9 do
        local x = p2X + (barWidth / 10) * i
        love.graphics.line(x, y, x, y + barHeight)
    end
    
    -- Health lost "after damage" effect (fading darker region)
    local damageAmount = 1.0 - p2HealthPercent
    if damageAmount > 0 then
        love.graphics.setColor(0.1, 0.1, 0.5, 0.3)
        love.graphics.rectangle("fill", p2X, y, barWidth * damageAmount, barHeight)
    end
    
    -- Gleaming highlight
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", p2X + barWidth * (1 - p2HealthPercent), y, barWidth * p2HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p2.name, p2X + barWidth - 80, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(math.floor(p2HealthPercent * 100) .. "%", p2X + 10, y + 7)
end

-- [Removed drawActiveSpells function - now using visual representation instead]

-- Draw a full spellbook modal for a player
function UI.drawSpellbookModal(wizard, playerNum, formatCost)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Determine position based on player number
    local modalX, modalTitle, keyPrefix
    if playerNum == 1 then
        modalX = 50
        modalTitle = "Ashgar's Spellbook"
        keyPrefix = {"Q", "W", "E", "Q+W", "Q+E", "W+E", "Q+W+E"}
    else
        modalX = screenWidth - 450
        modalTitle = "Selene's Spellbook"
        keyPrefix = {"I", "O", "P", "I+O", "I+P", "O+P", "I+O+P"}
    end
    
    -- Modal background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 450)
    love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
    love.graphics.rectangle("line", modalX, 50, 400, 450)
    
    -- Modal title
    love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(modalTitle, modalX + 150, 60)
    
    -- Close button
    love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", modalX + 370, 50, 30, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("X", modalX + 380, 60)
    
    -- Controls help section at the top of the modal
    love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
    love.graphics.rectangle("fill", modalX + 10, 90, 380, 80)
    love.graphics.setColor(1, 1, 1, 0.9)
    
    if playerNum == 1 then
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("Q/W/E: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("F: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("B: Toggle spellbook visibility", modalX + 30, 155)
    else
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("I/O/P: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("L: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("M: Toggle spellbook visibility", modalX + 30, 155)
    end
    
    -- Spells section
    local y = 180
    
    -- Single key spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Single Key Spells", modalX + 150, y + 5)
    y = y + 30
    
    -- Display single key spells
    for i = 1, 3 do
        local keyName = tostring(i)
        local spell = wizard.spellbook[keyName]
        if spell then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            love.graphics.print(keyPrefix[i] .. ": " .. spell.name, modalX + 20, y + 5)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. spell.castTime .. "s", modalX + 30, y + 25)
            y = y + 45
        end
    end
    
    -- Multi-key spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Multi-Key Spells", modalX + 150, y + 5)
    y = y + 30
    
    -- Display multi-key spells
    for i = 4, 7 do  -- 4=combo "12", 5=combo "13", 6=combo "23", 7=combo "123"
        local keyName
        if i == 4 then keyName = "12"
        elseif i == 5 then keyName = "13"
        elseif i == 6 then keyName = "23"
        else keyName = "123" end
        
        local spell = wizard.spellbook[keyName]
        if spell then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            love.graphics.print(keyPrefix[i] .. ": " .. spell.name, modalX + 20, y + 5)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. spell.castTime .. "s", modalX + 30, y + 25)
            y = y + 45
        end
    end
end


return UI```

## ./vfx.lua
```lua
-- VFX.lua
-- Visual effects module for spell animations and combat effects

local VFX = {}
VFX.__index = VFX

-- Table to store active effects
VFX.activeEffects = {}

-- Initialize the VFX system
function VFX.init()
    -- Load any necessary assets for effects
    VFX.assets = {
        -- Fire effects
        fireParticle = love.graphics.newImage("assets/sprites/fire-particle.png"),
        fireGlow = love.graphics.newImage("assets/sprites/fire-glow.png"),
        
        -- Force effects
        forceWave = love.graphics.newImage("assets/sprites/force-wave.png"),
        
        -- Moon effects
        moonGlow = love.graphics.newImage("assets/sprites/moon-glow.png"),
        
        -- Generic effects
        sparkle = love.graphics.newImage("assets/sprites/sparkle.png"),
        impactRing = love.graphics.newImage("assets/sprites/impact-ring.png"),
    }
    
    -- Effect definitions keyed by effect name
    VFX.effects = {
        -- Firebolt effect
        firebolt = {
            type = "projectile",
            duration = 1.0,  -- 1 second total duration
            particleCount = 20,
            startScale = 0.5,
            endScale = 1.0,
            color = {1, 0.5, 0.2, 1},
            trailLength = 12,
            impactSize = 1.4,
            sound = "firebolt"
        },
        
        -- Meteor effect
        meteor = {
            type = "impact",
            duration = 1.5,
            particleCount = 40,
            startScale = 2.0,
            endScale = 0.5,
            color = {1, 0.4, 0.1, 1},
            radius = 120,
            sound = "meteor"
        },
        
        -- Mist Veil effect
        mistveil = {
            type = "aura",
            duration = 3.0,
            particleCount = 30,
            startScale = 0.2,
            endScale = 0.8,
            color = {0.7, 0.7, 1.0, 0.7},
            radius = 80,
            pulseRate = 2,
            sound = "mist"
        },
        
        -- Emberlift effect
        emberlift = {
            type = "vertical",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.1,
            color = {1, 0.6, 0.2, 0.8},
            height = 100,
            sound = "whoosh"
        },
        
        -- Full Moon Beam effect
        fullmoonbeam = {
            type = "beam",
            duration = 1.8,
            particleCount = 30,
            beamWidth = 40,
            startScale = 0.2,
            endScale = 1.0,
            color = {0.8, 0.8, 1.0, 0.9},
            pulseRate = 3,
            sound = "moonbeam"
        },
        
        -- Conjure Fire effect
        conjurefire = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = {1.0, 0.5, 0.2, 0.9},
            height = 140,  -- Height to rise toward mana pool
            spreadRadius = 40, -- Initial spread around the caster
            sound = "conjure"
        },
        
        -- Conjure Moonlight effect
        conjuremoonlight = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = {0.7, 0.7, 1.0, 0.9},
            height = 140,
            spreadRadius = 40,
            sound = "conjure"
        },
        
        -- Volatile Conjuring effect (random mana)
        volatileconjuring = {
            type = "conjure",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.2,
            endScale = 0.6,
            color = {1.0, 1.0, 0.5, 0.9},  -- Yellow base color, will be randomized
            height = 140,
            spreadRadius = 55,  -- Wider spread for volatile
            sound = "conjure"
        }
    }
    
    -- Initialize sound effects (placeholders)
    VFX.sounds = {
        firebolt = nil, -- Will load actual sound files when available
        meteor = nil,
        mist = nil,
        whoosh = nil,
        moonbeam = nil
    }
    
    return VFX
end

-- Create a new effect instance
function VFX.createEffect(effectName, sourceX, sourceY, targetX, targetY, options)
    -- Get effect template
    local template = VFX.effects[effectName:lower()]
    if not template then
        print("Warning: Effect not found: " .. effectName)
        return nil
    end
    
    -- Create a new effect instance
    local effect = {
        name = effectName,
        type = template.type,
        sourceX = sourceX,
        sourceY = sourceY,
        targetX = targetX or sourceX,
        targetY = targetY or sourceY,
        
        -- Timing
        duration = template.duration,
        timer = 0,
        progress = 0,
        isComplete = false,
        
        -- Visual properties (copied from template)
        particleCount = template.particleCount,
        startScale = template.startScale,
        endScale = template.endScale,
        color = {template.color[1], template.color[2], template.color[3], template.color[4]},
        
        -- Effect specific properties
        particles = {},
        trailPoints = {},
        
        -- Sound
        sound = template.sound,
        
        -- Additional properties based on effect type
        radius = template.radius,
        beamWidth = template.beamWidth,
        height = template.height,
        pulseRate = template.pulseRate,
        trailLength = template.trailLength,
        impactSize = template.impactSize,
        spreadRadius = template.spreadRadius,
        
        -- Optional overrides
        options = options or {}
    }
    
    -- Initialize particles based on effect type
    VFX.initializeParticles(effect)
    
    -- Play sound effect if available
    if effect.sound and VFX.sounds[effect.sound] then
        -- Will play sound when implemented
    end
    
    -- Add to active effects list
    table.insert(VFX.activeEffects, effect)
    
    return effect
end

-- Initialize particles based on effect type
function VFX.initializeParticles(effect)
    -- Different initialization based on effect type
    if effect.type == "projectile" then
        -- For projectiles, create a trail of particles
        for i = 1, effect.particleCount do
            local particle = {
                x = effect.sourceX,
                y = effect.sourceY,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = 0,
                delay = i / effect.particleCount * 0.3, -- Stagger particle start
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "impact" then
        -- For impact effects, create a radial explosion
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(10, effect.radius)
            local speed = math.random(50, 200)
            local particle = {
                x = effect.targetX,
                y = effect.targetY,
                targetX = effect.targetX + math.cos(angle) * distance,
                targetY = effect.targetY + math.sin(angle) * distance,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = angle,
                delay = math.random() * 0.2, -- Slight random delay
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "aura" then
        -- For aura effects, create particles that orbit the character
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(effect.radius * 0.6, effect.radius)
            local orbitalSpeed = math.random(0.5, 2.0)
            local particle = {
                angle = angle,
                distance = distance,
                orbitalSpeed = orbitalSpeed,
                scale = effect.startScale,
                alpha = 0, -- Start invisible and fade in
                rotation = 0,
                delay = i / effect.particleCount * 0.5,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "vertical" then
        -- For vertical effects like emberlift, particles rise upward
        for i = 1, effect.particleCount do
            local offsetX = math.random(-30, 30)
            local startY = math.random(0, 40)
            local speed = math.random(70, 150)
            local particle = {
                x = effect.sourceX + offsetX,
                y = effect.sourceY + startY,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = math.random() * math.pi * 2,
                delay = i / effect.particleCount * 0.8,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "beam" then
        -- For beam effects like fullmoonbeam, create a beam with particles
        -- First create the main beam shape
        effect.beamProgress = 0
        effect.beamLength = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
        effect.beamAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)
        
        -- Then add particles along the beam
        for i = 1, effect.particleCount do
            local position = math.random()
            local offset = math.random(-10, 10)
            local particle = {
                position = position, -- 0 to 1 along beam
                offset = offset, -- Perpendicular to beam
                scale = effect.startScale * math.random(0.7, 1.3),
                alpha = 0.8,
                rotation = math.random() * math.pi * 2,
                delay = math.random() * 0.3,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "conjure" then
        -- For conjuration spells, create particles that rise from caster toward mana pool
        -- Set the mana pool position (typically at top center)
        effect.manaPoolX = effect.options and effect.options.manaPoolX or 400 -- Screen center X
        effect.manaPoolY = effect.options and effect.options.manaPoolY or 120 -- Near top of screen
        
        -- Ensure spreadRadius has a default value
        effect.spreadRadius = effect.spreadRadius or 40
        
        -- Calculate direction vector toward mana pool
        local dirX = effect.manaPoolX - effect.sourceX
        local dirY = effect.manaPoolY - effect.sourceY
        local len = math.sqrt(dirX * dirX + dirY * dirY)
        dirX = dirX / len
        dirY = dirY / len
        
        for i = 1, effect.particleCount do
            -- Create a spread of particles around the caster
            local spreadAngle = math.random() * math.pi * 2
            local spreadDist = math.random() * effect.spreadRadius
            local startX = effect.sourceX + math.cos(spreadAngle) * spreadDist
            local startY = effect.sourceY + math.sin(spreadAngle) * spreadDist
            
            -- Randomize particle properties
            local speed = math.random(80, 180)
            local delay = i / effect.particleCount * 0.7
            
            -- Add some variance to path
            local pathVariance = math.random(-20, 20)
            local pathDirX = dirX + pathVariance / 100
            local pathDirY = dirY + pathVariance / 100
            
            local particle = {
                x = startX,
                y = startY,
                speedX = pathDirX * speed,
                speedY = pathDirY * speed,
                scale = effect.startScale,
                alpha = 0, -- Start transparent and fade in
                rotation = math.random() * math.pi * 2,
                rotSpeed = math.random(-3, 3),
                delay = delay,
                active = false,
                finalPulse = false,
                finalPulseTime = 0
            }
            table.insert(effect.particles, particle)
        end
    end
end

-- Update all active effects
function VFX.update(dt)
    local i = 1
    while i <= #VFX.activeEffects do
        local effect = VFX.activeEffects[i]
        
        -- Update effect timer
        effect.timer = effect.timer + dt
        effect.progress = math.min(effect.timer / effect.duration, 1.0)
        
        -- Update effect based on type
        if effect.type == "projectile" then
            VFX.updateProjectile(effect, dt)
        elseif effect.type == "impact" then
            VFX.updateImpact(effect, dt)
        elseif effect.type == "aura" then
            VFX.updateAura(effect, dt)
        elseif effect.type == "vertical" then
            VFX.updateVertical(effect, dt)
        elseif effect.type == "beam" then
            VFX.updateBeam(effect, dt)
        elseif effect.type == "conjure" then
            VFX.updateConjure(effect, dt)
        end
        
        -- Remove effect if complete
        if effect.progress >= 1.0 then
            table.remove(VFX.activeEffects, i)
        else
            i = i + 1
        end
    end
end

-- Update function for projectile effects
function VFX.updateProjectile(effect, dt)
    -- Update trail points
    if #effect.trailPoints == 0 then
        -- Initialize trail with source position
        for i = 1, effect.trailLength do
            table.insert(effect.trailPoints, {x = effect.sourceX, y = effect.sourceY})
        end
    end
    
    -- Calculate projectile position based on progress
    local posX = effect.sourceX + (effect.targetX - effect.sourceX) * effect.progress
    local posY = effect.sourceY + (effect.targetY - effect.sourceY) * effect.progress
    
    -- Add curved trajectory based on height
    local midpointProgress = effect.progress - 0.5
    local verticalOffset = -60 * (1 - (midpointProgress * 2)^2)
    posY = posY + verticalOffset
    
    -- Update trail
    table.remove(effect.trailPoints)
    table.insert(effect.trailPoints, 1, {x = posX, y = posY})
    
    -- Update particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Distribute particles along the trail
            local trailIndex = math.floor((i / #effect.particles) * #effect.trailPoints) + 1
            if trailIndex > #effect.trailPoints then trailIndex = #effect.trailPoints end
            
            local trailPoint = effect.trailPoints[trailIndex]
            
            -- Add some randomness to particle positions
            local spreadFactor = 8 * (1 - particleProgress)
            particle.x = trailPoint.x + math.random(-spreadFactor, spreadFactor)
            particle.y = trailPoint.y + math.random(-spreadFactor, spreadFactor)
            
            -- Update visual properties
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            particle.alpha = math.min(2.0 - particleProgress * 2, 1.0) -- Fade out in last half
            particle.rotation = particle.rotation + dt * 2
        end
    end
    
    -- Create impact effect when reaching the target
    if effect.progress > 0.95 and not effect.impactCreated then
        effect.impactCreated = true
        -- Would create a separate impact effect here in a full implementation
    end
end

-- Update function for impact effects
function VFX.updateImpact(effect, dt)
    -- Create impact wave that expands outward
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle outward from center
            local dirX = particle.targetX - effect.targetX
            local dirY = particle.targetY - effect.targetY
            local length = math.sqrt(dirX^2 + dirY^2)
            if length > 0 then
                dirX = dirX / length
                dirY = dirY / length
            end
            
            particle.x = effect.targetX + dirX * length * particleProgress
            particle.y = effect.targetY + dirY * length * particleProgress
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            particle.alpha = 1.0 - particleProgress^2 -- Quadratic fade out
            particle.rotation = particle.rotation + dt * 3
        end
    end
end

-- Update function for aura effects
function VFX.updateAura(effect, dt)
    -- Update orbital particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update angle for orbital motion
            particle.angle = particle.angle + dt * particle.orbitalSpeed
            
            -- Calculate position based on orbit
            particle.x = effect.sourceX + math.cos(particle.angle) * particle.distance
            particle.y = effect.sourceY + math.sin(particle.angle) * particle.distance
            
            -- Pulse effect
            local pulseOffset = math.sin(effect.timer * effect.pulseRate) * 0.2
            
            -- Update visual properties with fade in/out
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress + pulseOffset
            
            -- Fade in for first 20%, stay visible for 60%, fade out for last 20%
            if particleProgress < 0.2 then
                particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
            elseif particleProgress > 0.8 then
                particle.alpha = (1 - particleProgress) * 5 -- 1 to 0 over last 20% time
            else
                particle.alpha = 1.0
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for vertical effects
function VFX.updateVertical(effect, dt)
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle upward
            particle.y = particle.y - particle.speed * dt
            
            -- Add some horizontal drift
            local driftSpeed = 10 * math.sin(particle.y * 0.05 + i)
            particle.x = particle.x + driftSpeed * dt
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            
            -- Fade in briefly, then fade out over time
            if particleProgress < 0.1 then
                particle.alpha = particleProgress * 10 -- Quick fade in
            else
                particle.alpha = 1.0 - ((particleProgress - 0.1) / 0.9) -- Slower fade out
            end
            
            particle.rotation = particle.rotation + dt * 2
        end
    end
end

-- Update function for beam effects
function VFX.updateBeam(effect, dt)
    -- Update beam progress
    effect.beamProgress = math.min(effect.progress * 2, 1.0) -- Beam reaches full extension halfway through
    
    -- Update beam particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Only show particles along the visible length of the beam
            if particle.position <= effect.beamProgress then
                -- Calculate position along beam
                local beamX = effect.sourceX + (effect.targetX - effect.sourceX) * particle.position
                local beamY = effect.sourceY + (effect.targetY - effect.sourceY) * particle.position
                
                -- Add perpendicular offset
                local perpX = -math.sin(effect.beamAngle) * particle.offset
                local perpY = math.cos(effect.beamAngle) * particle.offset
                
                particle.x = beamX + perpX
                particle.y = beamY + perpY
                
                -- Add pulsing effect
                local pulseOffset = math.sin(effect.timer * effect.pulseRate + particle.position * 10) * 0.3
                
                -- Update visual properties
                particle.scale = (effect.startScale + (effect.endScale - effect.startScale) * particleProgress) * (1 + pulseOffset)
                
                -- Fade based on beam extension and overall effect progress
                if effect.progress < 0.5 then
                    -- Beam extending - particles at tip are brighter
                    local distFromTip = math.abs(particle.position - effect.beamProgress)
                    particle.alpha = math.max(0, 1.0 - distFromTip * 3)
                else
                    -- Beam fully extended, starting to fade out
                    local fadeProgress = (effect.progress - 0.5) * 2 -- 0 to 1 in second half
                    particle.alpha = 1.0 - fadeProgress
                end
            else
                particle.alpha = 0 -- Particle not yet reached by beam extension
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for conjure effects
function VFX.updateConjure(effect, dt)
    -- Update particles rising toward mana pool
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update position based on speed
            if not particle.finalPulse then
                particle.x = particle.x + particle.speedX * dt
                particle.y = particle.y + particle.speedY * dt
                
                -- Calculate distance to mana pool
                local distX = effect.manaPoolX - particle.x
                local distY = effect.manaPoolY - particle.y
                local dist = math.sqrt(distX * distX + distY * distY)
                
                -- If close to mana pool, trigger final pulse effect
                if dist < 30 or particleProgress > 0.85 then
                    particle.finalPulse = true
                    particle.finalPulseTime = 0
                    
                    -- Center at mana pool
                    particle.x = effect.manaPoolX + math.random(-15, 15)
                    particle.y = effect.manaPoolY + math.random(-15, 15)
                end
            else
                -- Handle final pulse animation
                particle.finalPulseTime = particle.finalPulseTime + dt
                
                -- Expand and fade out for final pulse
                local pulseProgress = math.min(particle.finalPulseTime / 0.3, 1.0) -- 0.3s pulse duration
                particle.scale = effect.endScale * (1 + pulseProgress * 2) -- Expand to 3x size
                particle.alpha = 1.0 - pulseProgress -- Fade out
            end
            
            -- Handle fade in and rotation regardless of state
            if not particle.finalPulse then
                -- Fade in over first 20% of travel
                if particleProgress < 0.2 then
                    particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
                else
                    particle.alpha = 1.0
                end
                
                -- Update scale
                particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            end
            
            -- Update rotation
            particle.rotation = particle.rotation + particle.rotSpeed * dt
        end
    end
    
    -- Add a special effect at source and destination
    if effect.progress < 0.3 then
        -- Glow at source during initial phase
        effect.sourceGlow = 1.0 - (effect.progress / 0.3)
    else
        effect.sourceGlow = 0
    end
    
    -- Glow at mana pool during later phase
    if effect.progress > 0.5 then
        effect.poolGlow = (effect.progress - 0.5) * 2
        if effect.poolGlow > 1.0 then effect.poolGlow = 2 - effect.poolGlow end -- Peak at 0.75 progress
    else
        effect.poolGlow = 0
    end
end

-- Draw all active effects
function VFX.draw()
    for _, effect in ipairs(VFX.activeEffects) do
        if effect.type == "projectile" then
            VFX.drawProjectile(effect)
        elseif effect.type == "impact" then
            VFX.drawImpact(effect)
        elseif effect.type == "aura" then
            VFX.drawAura(effect)
        elseif effect.type == "vertical" then
            VFX.drawVertical(effect)
        elseif effect.type == "beam" then
            VFX.drawBeam(effect)
        elseif effect.type == "conjure" then
            VFX.drawConjure(effect)
        end
    end
end

-- Draw function for projectile effects
function VFX.drawProjectile(effect)
    local particleImage = VFX.assets.fireParticle
    local glowImage = VFX.assets.fireGlow
    
    -- Draw trail
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    if #effect.trailPoints >= 3 then
        local points = {}
        for i, point in ipairs(effect.trailPoints) do
            table.insert(points, point.x)
            table.insert(points, point.y)
        end
        love.graphics.setLineWidth(effect.startScale * 10)
        love.graphics.line(points)
        love.graphics.setLineWidth(1)
    end
    
    -- Draw glow at head of projectile
    if #effect.trailPoints > 0 then
        local head = effect.trailPoints[1]
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
        local glowScale = effect.startScale * 3
        love.graphics.draw(
            glowImage,
            head.x, head.y,
            0,
            glowScale, glowScale,
            glowImage:getWidth()/2, glowImage:getHeight()/2
        )
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw impact flash when projectile reaches target
    if effect.progress > 0.95 then
        local flashIntensity = (1 - (effect.progress - 0.95) * 20) -- Flash quickly fades
        if flashIntensity > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], flashIntensity)
            love.graphics.circle("fill", effect.targetX, effect.targetY, effect.impactSize * 30 * (1 - flashIntensity))
        end
    end
end

-- Draw function for impact effects
function VFX.drawImpact(effect)
    local particleImage = VFX.assets.fireParticle
    local impactImage = VFX.assets.impactRing
    
    -- Draw expanding ring
    local ringProgress = math.min(effect.progress * 1.5, 1.0) -- Ring expands faster than full effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - ringProgress) * effect.color[4])
    local ringScale = effect.radius * 0.02 * ringProgress
    love.graphics.draw(
        impactImage,
        effect.targetX, effect.targetY,
        0,
        ringScale, ringScale,
        impactImage:getWidth()/2, impactImage:getHeight()/2
    )
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw central flash
    if effect.progress < 0.3 then
        local flashIntensity = 1.0 - (effect.progress / 0.3)
        love.graphics.setColor(1, 1, 1, flashIntensity * 0.7)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 30 * flashIntensity)
    end
end

-- Draw function for aura effects
function VFX.drawAura(effect)
    local particleImage = VFX.assets.sparkle
    
    -- Draw base aura circle
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.2
    local baseAlpha = 0.3 * (1 - (math.abs(effect.progress - 0.5) * 2)^2) -- Peak at middle of effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], baseAlpha)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, baseAlpha * 1.5)
    love.graphics.circle("line", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
end

-- Draw function for vertical effects
function VFX.drawVertical(effect)
    local particleImage = VFX.assets.fireParticle
    
    -- Draw base effect at source
    local baseProgress = math.min(effect.progress * 3, 1.0) -- Quick initial flash
    if baseProgress < 1.0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - baseProgress) * 0.7)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 40 * baseProgress)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw guiding lines (subtle vertical paths)
    if effect.progress < 0.7 then
        local lineAlpha = 0.3 * (1.0 - effect.progress / 0.7)
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], lineAlpha)
        for i = 1, 5 do
            local xOffset = (i - 3) * 10
            local startY = effect.sourceY
            local endY = effect.sourceY - effect.height * math.min(effect.progress * 2, 1.0)
            love.graphics.line(effect.sourceX + xOffset, startY, effect.sourceX + xOffset * 1.5, endY)
        end
    end
end

-- Draw function for beam effects
function VFX.drawBeam(effect)
    local particleImage = VFX.assets.sparkle
    local beamLength = effect.beamLength * effect.beamProgress
    
    -- Draw base beam
    local beamEndX = effect.sourceX + math.cos(effect.beamAngle) * beamLength
    local beamEndY = effect.sourceY + math.sin(effect.beamAngle) * beamLength
    
    -- Calculate beam width with pulse
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.3
    local beamWidth = effect.beamWidth * (1 + pulseAmount) * (1 - (effect.progress > 0.5 and (effect.progress - 0.5) * 2 or 0))
    
    -- Draw outer beam glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    love.graphics.setLineWidth(beamWidth * 1.5)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw inner beam core
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, effect.color[4] * 0.7)
    love.graphics.setLineWidth(beamWidth * 0.7)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw brightest beam center
    love.graphics.setColor(1, 1, 1, effect.color[4] * 0.9)
    love.graphics.setLineWidth(beamWidth * 0.3)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw source glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, 20 * (1 + pulseAmount))
    
    -- Draw impact glow at target if beam is fully extended
    if effect.beamProgress >= 0.99 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.8 * (1 - (effect.progress - 0.5) * 2))
        love.graphics.circle("fill", beamEndX, beamEndY, 25 * (1 + pulseAmount))
    end
end

-- Draw function for conjure effects
function VFX.drawConjure(effect)
    local particleImage = VFX.assets.sparkle
    local glowImage = VFX.assets.fireGlow  -- We'll use this for all conjure types
    
    -- Draw source glow if active
    if effect.sourceGlow and effect.sourceGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.sourceGlow * 0.6)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 50 * effect.sourceGlow)
        
        -- Draw expanding rings from source (hint at conjuration happening)
        local ringCount = 3
        for i = 1, ringCount do
            local ringProgress = ((effect.timer * 1.5) % 1.0) + (i-1) / ringCount
            if ringProgress < 1.0 then
                local ringSize = 60 * ringProgress
                local ringAlpha = 0.5 * (1.0 - ringProgress) * effect.sourceGlow
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], ringAlpha)
                love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
            end
        end
    end
    
    -- Draw mana pool glow if active
    if effect.poolGlow and effect.poolGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.poolGlow * 0.7)
        love.graphics.circle("fill", effect.manaPoolX, effect.manaPoolY, 40 * effect.poolGlow)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            -- Choose the right glow image based on final pulse state
            local imgToDraw = particleImage
            
            -- Adjust color based on state
            if particle.finalPulse then
                -- Brighter for final pulse
                love.graphics.setColor(
                    effect.color[1] * 1.3, 
                    effect.color[2] * 1.3, 
                    effect.color[3] * 1.3, 
                    effect.color[4] * particle.alpha
                )
                imgToDraw = glowImage
            else
                love.graphics.setColor(
                    effect.color[1], 
                    effect.color[2], 
                    effect.color[3], 
                    effect.color[4] * particle.alpha
                )
            end
            
            -- Draw the particle
            love.graphics.draw(
                imgToDraw,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                imgToDraw:getWidth()/2, imgToDraw:getHeight()/2
            )
            
            -- For volatile conjuring, add random color sparks
            if effect.name:lower() == "volatileconjuring" and not particle.finalPulse and math.random() < 0.3 then
                -- Random rainbow hue for volatile conjuring
                local hue = (effect.timer * 0.5 + particle.x * 0.01) % 1.0
                local r, g, b = HSVtoRGB(hue, 0.8, 1.0)
                
                love.graphics.setColor(r, g, b, particle.alpha * 0.7)
                love.graphics.draw(
                    particleImage,
                    particle.x + math.random(-5, 5), 
                    particle.y + math.random(-5, 5),
                    particle.rotation + math.random() * math.pi,
                    particle.scale * 0.5, particle.scale * 0.5,
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
            end
        end
    end
    
    -- Draw connection lines between particles (ethereal threads)
    if effect.progress < 0.7 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.2)
        
        local maxConnectDist = 50  -- Maximum distance for particles to connect
        for i = 1, #effect.particles do
            local p1 = effect.particles[i]
            if p1.active and p1.alpha > 0.2 and not p1.finalPulse then
                for j = i+1, #effect.particles do
                    local p2 = effect.particles[j]
                    if p2.active and p2.alpha > 0.2 and not p2.finalPulse then
                        local dx = p1.x - p2.x
                        local dy = p1.y - p2.y
                        local dist = math.sqrt(dx*dx + dy*dy)
                        
                        if dist < maxConnectDist then
                            -- Fade based on distance
                            local alpha = (1 - dist/maxConnectDist) * 0.3 * p1.alpha * p2.alpha
                            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
                            love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                        end
                    end
                end
            end
        end
    end
end

-- Helper function for HSV to RGB conversion (for volatile conjuring rainbow effect)
function HSVtoRGB(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r, g, b
end

-- Helper function to create the appropriate effect for a spell
function VFX.createSpellEffect(spell, caster, target)
    -- Get mana pool position for conjuration spells
    local manaPoolX = caster.manaPool and caster.manaPool.x or 400
    local manaPoolY = caster.manaPool and caster.manaPool.y or 120
    
    -- Determine source and target positions
    local sourceX, sourceY = caster.x, caster.y
    local targetX, targetY = target.x, target.y
    
    -- Handle different spell types
    local spellName = spell.name:lower():gsub("%s+", "") -- Convert to lowercase and remove spaces
    
    -- Handle conjuration spells first
    if spellName == "conjurefire" then
        return VFX.createEffect("conjurefire", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "conjuremoonlight" then
        return VFX.createEffect("conjuremoonlight", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "volatileconjuring" then
        return VFX.createEffect("volatileconjuring", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    
    -- Special handling for other specific spells
    elseif spellName == "firebolt" then
        return VFX.createEffect("firebolt", sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "meteor" then
        return VFX.createEffect("meteor", targetX, targetY - 100, targetX, targetY)
    elseif spellName == "mistveil" then
        return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
    elseif spellName == "emberlift" then
        return VFX.createEffect("emberlift", sourceX, sourceY, nil, nil)
    elseif spellName == "fullmoonbeam" then
        return VFX.createEffect("fullmoonbeam", sourceX, sourceY - 20, targetX, targetY - 20)
    else
        -- Create a generic effect based on spell type or mana cost
        if spell.spellType == "projectile" then
            return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
        else
            -- Look at spell cost to determine effect type
            local hasFireMana = false
            local hasMoonMana = false
            
            for _, cost in ipairs(spell.cost or {}) do
                if cost.type == "fire" then hasFireMana = true end
                if cost.type == "moon" then hasMoonMana = true end
            end
            
            if hasFireMana then
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            elseif hasMoonMana then
                return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
            else
                -- Default generic effect
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            end
        end
    end
end

return VFX```

## ./wizard.lua
```lua
-- Wizard class

local Wizard = {}
Wizard.__index = Wizard

-- Load spells
local Spells = require("spells")

function Wizard.new(name, x, y, color)
    local self = setmetatable({}, Wizard)
    
    self.name = name
    self.x = x
    self.y = y
    self.color = color  -- RGB table
    
    -- Wizard state
    self.health = 100
    self.elevation = "GROUNDED"  -- GROUNDED or AERIAL
    self.stunTimer = 0           -- Stun timer in seconds
    self.blockers = {            -- Spell blocking effects
        projectile = 0           -- Projectile block duration
    }
    
    -- Visual effects
    self.blockVFX = {
        active = false,
        timer = 0,
        x = 0,
        y = 0
    }
    
    -- Spell cast notification (temporary until proper VFX)
    self.spellCastNotification = nil
    
    -- Spell keying system
    self.activeKeys = {
        [1] = false,
        [2] = false,
        [3] = false
    }
    self.currentKeyedSpell = nil
    
    -- Spell loadout based on wizard name
    if name == "Ashgar" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjurefire,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.firebolt,
            
            -- Multi-key combinations
            ["12"] = Spells.meteor,
            ["13"] = Spells.combust,
            ["23"] = Spells.emberlift, -- Added Emberlift spell
            ["123"] = Spells.meteor   -- Placeholder, could be a new spell
        }
    elseif name == "Selene" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjuremoonlight,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.mist,
            
            -- Multi-key combinations
            ["12"] = Spells.gravity,
            ["13"] = Spells.eclipse,
            ["23"] = Spells.fullmoonbeam, -- Added Full Moon Beam spell
            ["123"] = Spells.eclipse  -- Placeholder, could be a new spell
        }
    end
    
    -- Spell slots (3 max)
    self.spellSlots = {}
    for i = 1, 3 do
        self.spellSlots[i] = {
            active = false,
            progress = 0,
            spellType = nil,
            castTime = 0,
            tokens = {}  -- Will hold channeled mana tokens
        }
    end
    
    -- Load wizard sprite
    self.sprite = love.graphics.newImage("assets/sprites/wizard.png")
    self.scale = 2.0  -- Scale factor for the sprite
    
    return self
end

function Wizard:update(dt)
    -- Update stun timer
    if self.stunTimer > 0 then
        self.stunTimer = math.max(0, self.stunTimer - dt)
        if self.stunTimer == 0 then
            print(self.name .. " is no longer stunned")
        end
    end
    
    -- Update blocker timers
    for blockType, duration in pairs(self.blockers) do
        if duration > 0 then
            self.blockers[blockType] = math.max(0, duration - dt)
            if self.blockers[blockType] == 0 then
                print(self.name .. "'s " .. blockType .. " block has expired")
            end
        end
    end
    
    -- Update block VFX
    if self.blockVFX.active then
        self.blockVFX.timer = self.blockVFX.timer - dt
        if self.blockVFX.timer <= 0 then
            self.blockVFX.active = false
        end
    end
    
    -- Update spell cast notification
    if self.spellCastNotification then
        self.spellCastNotification.timer = self.spellCastNotification.timer - dt
        if self.spellCastNotification.timer <= 0 then
            self.spellCastNotification = nil
        end
    end
    
    -- Update spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            slot.progress = slot.progress + dt
            
            -- If spell finished casting
            if slot.progress >= slot.castTime then
                self:castSpell(i)
                
                -- Start return animation for tokens
                if #slot.tokens > 0 then
                    for _, tokenData in ipairs(slot.tokens) do
                        -- Trigger animation to return token to the mana pool
                        self.manaPool:returnToken(tokenData.index)
                    end
                    
                    -- Clear token list (tokens still exist in the mana pool)
                    slot.tokens = {}
                end
                
                -- Reset slot
                slot.active = false
                slot.progress = 0
                slot.spellType = nil
                slot.castTime = 0
            end
        end
    end
end

function Wizard:draw()
    -- Calculate position adjustments based on elevation
    local yOffset = 0
    if self.elevation == "AERIAL" then
        yOffset = -30  -- Lift the wizard up when AERIAL
    end
    
    -- Set color and draw wizard
    if self.stunTimer > 0 then
        -- Apply a yellow/white flash for stunned wizards
        local flashIntensity = 0.5 + math.sin(love.timer.getTime() * 10) * 0.5
        love.graphics.setColor(1, 1, flashIntensity)
    else
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw elevation effect (GROUNDED or AERIAL)
    if self.elevation == "GROUNDED" then
        -- Draw ground indicator below wizard
        love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        love.graphics.ellipse("fill", self.x, self.y + 30, 40, 10)  -- Simple shadow/ground indicator
    end
    
    -- Draw the wizard with appropriate elevation
    love.graphics.setColor(1, 1, 1)
    
    -- Flip Selene's sprite horizontally if she's player 2
    local scaleX = self.scale
    if self.name == "Selene" then
        -- Mirror the sprite by using negative scale for the second player
        scaleX = -self.scale
    end
    
    love.graphics.draw(
        self.sprite, 
        self.x, self.y + yOffset,  -- Apply elevation offset
        0,  -- Rotation
        scaleX, self.scale,  -- Scale x, Scale y (negative x scale for Selene)
        self.sprite:getWidth()/2, self.sprite:getHeight()/2  -- Origin at center
    )
    
    -- Draw aerial effect if applicable
    if self.elevation == "AERIAL" then
        -- Draw aerial effect (clouds, wind lines, etc.)
        love.graphics.setColor(0.8, 0.8, 1, 0.3)
        
        -- Draw cloud-like puffs
        for i = 1, 3 do
            local xOffset = math.sin(love.timer.getTime() * 1.5 + i) * 8
            local cloudY = self.y + yOffset + 25 + math.sin(love.timer.getTime() + i) * 3
            love.graphics.circle("fill", self.x - 15 + xOffset, cloudY, 8)
            love.graphics.circle("fill", self.x + xOffset, cloudY, 10)
            love.graphics.circle("fill", self.x + 15 + xOffset, cloudY, 8)
        end
    end
    
    -- No longer drawing text elevation indicator - using visual representation only
    
    -- Draw stun indicator if stunned
    if self.stunTimer > 0 then
        love.graphics.setColor(1, 1, 0, 0.7 + math.sin(love.timer.getTime() * 8) * 0.3)
        love.graphics.print("STUNNED", self.x - 30, self.y - 70)
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.print(string.format("%.1fs", self.stunTimer), self.x - 10, self.y - 55)
    end
    
    -- Draw blocker indicators
    if self.blockers.projectile > 0 then
        -- Mist veil (projectile block) active indicator
        love.graphics.setColor(0.6, 0.6, 1, 0.6 + math.sin(love.timer.getTime() * 4) * 0.3)
        love.graphics.print("MIST SHIELD", self.x - 40, self.y - 100)
        love.graphics.setColor(0.7, 0.7, 1, 0.4)
        love.graphics.print(string.format("%.1fs", self.blockers.projectile), self.x - 10, self.y - 85)
        
        -- Draw a subtle shield aura
        local shieldRadius = 60
        local pulseAmount = 5 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.5, 0.5, 1, 0.2)
        love.graphics.circle("fill", self.x, self.y, shieldRadius + pulseAmount)
        love.graphics.setColor(0.7, 0.7, 1, 0.3)
        love.graphics.circle("line", self.x, self.y, shieldRadius + pulseAmount)
    end
    
    -- Draw block effect when projectile is blocked
    if self.blockVFX.active then
        -- Draw block flash animation
        local progress = self.blockVFX.timer / 0.5  -- Normalize to 0-1
        local size = 80 * (1 - progress)
        love.graphics.setColor(0.7, 0.7, 1, progress * 0.8)
        love.graphics.circle("fill", self.x, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.circle("line", self.x, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.print("BLOCKED!", self.x - 30, self.y - 120)
    end
    
    -- Health bars will now be drawn in the UI system for a more dramatic fighting game style
    
    -- Keyed spell display has been moved to the UI spellbook component
    
    -- Draw spell cast notification (temporary until proper VFX)
    if self.spellCastNotification then
        -- Fade out towards the end
        local alpha = math.min(1.0, self.spellCastNotification.timer)
        local color = self.spellCastNotification.color
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        
        -- Draw with a subtle rise effect
        local yOffset = 10 * (1 - alpha)  -- Rise up as it fades
        love.graphics.print(self.spellCastNotification.text, 
                           self.spellCastNotification.x - 60, 
                           self.spellCastNotification.y - yOffset, 
                           0, -- rotation
                           1.5, 1.5) -- scale
    end
    
    -- We'll remove the key indicators from here as they'll be drawn in the UI's spellbook component
    
    -- Draw spell slots (orbits)
    self:drawSpellSlots()
end

-- Helper function to draw an ellipse
function Wizard:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 32
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

-- Helper function to draw an elliptical arc
function Wizard:drawEllipticalArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
    segments = segments or 16
    
    -- Calculate the angle increment
    local angleRange = endAngle - startAngle
    local angleIncrement = angleRange / segments
    
    -- Create points for the arc
    local points = {}
    
    for i = 0, segments do
        local angle = startAngle + angleIncrement * i
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(points, px)
        table.insert(points, py)
    end
    
    -- Draw the arc as a line
    love.graphics.line(points)
end

function Wizard:drawSpellSlots()
    -- Draw 3 orbiting spell slots as elliptical paths at different vertical positions
    -- Position the slots at legs, midsection, and head levels
    local slotYOffsets = {30, 0, -30}  -- From bottom to top
    
    -- Horizontal and vertical radii for each elliptical path
    local horizontalRadii = {80, 70, 60}   -- Wider at the bottom, narrower at the top
    local verticalRadii = {20, 25, 30}     -- Flatter at the bottom, rounder at the top
    
    for i, slot in ipairs(self.spellSlots) do
        -- Position parameters for each slot
        local slotY = self.y + slotYOffsets[i]
        local radiusX = horizontalRadii[i]
        local radiusY = verticalRadii[i]
        
        -- Draw tokens that should appear "behind" the character first
        if slot.active and #slot.tokens > 0 then
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            for j, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                if token.animTime >= token.animDuration and not token.returning then
                    local tokenCount = #slot.tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = progressAngle + anglePerToken * (j - 1)
                    
                    -- Only draw tokens that are in the back half (π to 2π)
                    local normalizedAngle = tokenAngle % (math.pi * 2)
                    if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                        -- Calculate 3D position with elliptical projection
                        token.x = self.x + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        token.zOrder = 0  -- Behind the wizard
                        
                        -- Draw token with reduced alpha for "behind" effect
                        love.graphics.setColor(1, 1, 1, 0.5)
                        love.graphics.draw(
                            token.image,
                            token.x, token.y,
                            token.rotAngle,
                            token.scale * 0.8, token.scale * 0.8,  -- Slightly smaller for perspective
                            token.image:getWidth()/2, token.image:getHeight()/2
                        )
                    end
                end
            end
        end
        
        -- Draw the character sprite (handled by the main draw function)
        
        -- If slot is active, draw progress arc and spell name
        if slot.active then
            -- Calculate progress angle (0 to 2*pi)
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            -- Draw progress arc as ellipse, respecting the front/back z-ordering
            -- First the back half of the progress arc (if it extends that far)
            if progressAngle > math.pi then
                love.graphics.setColor(0.8, 0.8, 0.2, 0.3)  -- Lower alpha for back
                self:drawEllipticalArc(self.x, slotY, radiusX, radiusY, math.pi, progressAngle, 16)
            end
            
            -- Then the front half of the progress arc
            love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Higher alpha for front
            self:drawEllipticalArc(self.x, slotY, radiusX, radiusY, 0, math.min(progressAngle, math.pi), 16)
            
            -- Draw spell name above the highest slot
            if i == 3 then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(slot.spellType, self.x - 20, slotY - radiusY - 15)
            end
            
            -- Draw tokens that should appear "in front" of the character
            if #slot.tokens > 0 then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = progressAngle + anglePerToken * (j - 1)
                        
                        -- Only draw tokens that are in the front half (0 to π)
                        local normalizedAngle = tokenAngle % (math.pi * 2)
                        if normalizedAngle >= 0 and normalizedAngle <= math.pi then
                            -- Calculate 3D position with elliptical projection
                            token.x = self.x + math.cos(tokenAngle) * radiusX
                            token.y = slotY + math.sin(tokenAngle) * radiusY
                            token.zOrder = 1  -- In front of the wizard
                            
                            -- Draw token with full alpha for "front" effect
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale, token.scale,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        end
                    end
                end
            end
        else
            -- For inactive slots, only update token positions without drawing orbits
            if #slot.tokens > 0 then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        -- Position tokens on their appropriate paths even when slot is inactive
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = anglePerToken * (j - 1)
                        
                        -- Calculate position based on angle
                        token.x = self.x + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Set z-order based on position
                        local normalizedAngle = tokenAngle % (math.pi * 2)
                        if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                            token.zOrder = 0  -- Behind
                            -- Draw with reduced alpha for "behind" effect
                            love.graphics.setColor(1, 1, 1, 0.5)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale * 0.8, token.scale * 0.8,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        else
                            token.zOrder = 1  -- In front
                            -- Draw with full alpha
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale, token.scale,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        end
                    end
                end
            end
        end
    end
end

-- Handle key press and update currently keyed spell
function Wizard:keySpell(keyIndex, isPressed)
    -- Check if wizard is stunned
    if self.stunTimer > 0 and isPressed then
        print(self.name .. " tried to key a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Update key state
    self.activeKeys[keyIndex] = isPressed
    
    -- Determine current key combination
    local keyCombo = ""
    for i = 1, 3 do
        if self.activeKeys[i] then
            keyCombo = keyCombo .. i
        end
    end
    
    -- Update currently keyed spell based on combination
    if keyCombo == "" then
        self.currentKeyedSpell = nil
    else
        self.currentKeyedSpell = self.spellbook[keyCombo]
        
        -- Log the currently keyed spell
        if self.currentKeyedSpell then
            print(self.name .. " keyed " .. self.currentKeyedSpell.name .. " (" .. keyCombo .. ")")
        else
            print(self.name .. " has no spell for key combination: " .. keyCombo)
        end
    end
    
    return true
end

-- Cast the currently keyed spell
function Wizard:castKeyedSpell()
    -- Check if wizard is stunned
    if self.stunTimer > 0 then
        print(self.name .. " tried to cast a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Check if a spell is keyed
    if not self.currentKeyedSpell then
        print(self.name .. " tried to cast, but no spell is keyed")
        return false
    end
    
    -- Queue the keyed spell and return the result
    return self:queueSpell(self.currentKeyedSpell)
end

function Wizard:queueSpell(spell)
    -- Check if wizard is stunned
    if self.stunTimer > 0 then
        print(self.name .. " tried to queue a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Validate the spell
    if not spell then
        print("No spell provided to queue")
        return false
    end
    
    -- Find the innermost available spell slot
    for i = 1, #self.spellSlots do
        if not self.spellSlots[i].active then
            -- Check if we can pay the mana cost from the pool
            local tokenReservations = self:canPayManaCost(spell.cost)
            
            if tokenReservations then
                -- Collect the actual tokens to animate them to the spell slot
                local tokens = {}
                
                -- Move each token from mana pool to spell slot with animation
                for _, reservation in ipairs(tokenReservations) do
                    local token = self.manaPool.tokens[reservation.index]
                    
                    -- Mark the token as being channeled
                    token.state = "CHANNELED"
                    
                    -- Store original position for animation
                    token.startX = token.x
                    token.startY = token.y
                    
                    -- Calculate target position in the spell slot based on 3D positioning
                    -- These must match values in drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}
                    local verticalRadii = {20, 25, 30}
                    
                    local targetX = self.x
                    local targetY = self.y + slotYOffsets[i]  -- Vertical offset based on slot
                    
                    -- Animation data
                    token.targetX = targetX
                    token.targetY = targetY
                    token.animTime = 0
                    token.animDuration = 0.5 -- Half second animation
                    token.slotIndex = i
                    token.tokenIndex = #tokens + 1 -- Position in the slot
                    token.spellSlot = i
                    token.wizardOwner = self
                    
                    -- 3D perspective data
                    token.radiusX = horizontalRadii[i]
                    token.radiusY = verticalRadii[i]
                    
                    table.insert(tokens, {token = token, index = reservation.index})
                end
                
                -- Successfully paid the cost, queue the spell
                self.spellSlots[i].active = true
                self.spellSlots[i].progress = 0
                self.spellSlots[i].spellType = spell.name
                self.spellSlots[i].castTime = spell.castTime
                self.spellSlots[i].spell = spell
                self.spellSlots[i].tokens = tokens
                
                print(self.name .. " queued " .. spell.name .. " in slot " .. i .. " (cast time: " .. spell.castTime .. "s)")
                return true
            else
                -- Couldn't pay the cost
                print(self.name .. " tried to queue " .. spell.name .. " but couldn't pay the mana cost")
                return false
            end
        end
    end
    
    -- No available slots
    print(self.name .. " tried to queue " .. spell.name .. " but all slots are full")
    return false
end

-- Helper function to check if mana cost can be paid without actually taking the tokens
function Wizard:canPayManaCost(cost)
    local tokenReservations = {}
    
    -- This function mirrors payManaCost but just returns the indices of tokens that would be used
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType = costComponent.type
        local costCount = costComponent.count
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Try to get tokens of this type
                for _ = 1, costCount do
                    local token, index = self.manaPool:findFreeToken(modalType)
                    if token then
                        table.insert(tokenReservations, {token = token, index = index})
                        paid = true
                        break
                    end
                end
                if paid then break end
            end
            
            if not paid then
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available token types
                local availableTypes = {}
                local availableIndices = {}
                
                -- Check each mana type and gather available ones
                for _, tokenType in ipairs({"fire", "force", "moon", "nature", "star"}) do
                    local token, index = self.manaPool:findFreeToken(tokenType)
                    if token then
                        table.insert(availableTypes, tokenType)
                        table.insert(availableIndices, index)
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTypes > 0 then
                    -- Shuffle the available types for true randomness
                    for i = #availableTypes, 2, -1 do
                        local j = math.random(i)
                        availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
                        availableIndices[i], availableIndices[j] = availableIndices[j], availableIndices[i]
                    end
                    
                    -- Use the first type after shuffling
                    local randomIndex = availableIndices[1]
                    local token = self.manaPool.tokens[randomIndex]
                    
                    table.insert(tokenReservations, {token = token, index = randomIndex})
                else
                    return nil
                end
            end
        else
            -- Specific type cost
            for _ = 1, costCount do
                local token, index = self.manaPool:findFreeToken(costType)
                if token then
                    table.insert(tokenReservations, {token = token, index = index})
                else
                    return nil
                end
            end
        end
    end
    
    return tokenReservations
end

-- Helper function to check and pay mana costs
function Wizard:payManaCost(cost)
    local tokens = {}
    
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType = costComponent.type
        local costCount = costComponent.count
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Try to get tokens of this type
                for _ = 1, costCount do
                    local token, index = self.manaPool:getToken(modalType)
                    if token then
                        table.insert(tokens, {token = token, index = index})
                        paid = true
                        break
                    end
                end
                if paid then break end
            end
            
            if not paid then
                -- Failed to pay modal cost, return tokens to pool
                for _, tokenData in ipairs(tokens) do
                    self.manaPool:returnToken(tokenData.index)
                end
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available token types
                local availableTypes = {}
                
                -- Check each mana type and gather available ones
                for _, tokenType in ipairs({"fire", "force", "moon", "nature", "star"}) do
                    local token, index = self.manaPool:getToken(tokenType)
                    if token then
                        -- Found a token, return it to the pool for now
                        self.manaPool:returnToken(index)
                        table.insert(availableTypes, tokenType)
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTypes > 0 then
                    -- Shuffle the available types for true randomness
                    for i = #availableTypes, 2, -1 do
                        local j = math.random(i)
                        availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
                    end
                    
                    -- Use the first type after shuffling
                    local token, index = self.manaPool:getToken(availableTypes[1])
                    
                    if token then
                        table.insert(tokens, {token = token, index = index})
                    else
                        -- Failed to find any token, return tokens to pool
                        for _, tokenData in ipairs(tokens) do
                            self.manaPool:returnToken(tokenData.index)
                        end
                        return nil
                    end
                else
                    -- No available tokens, return already collected tokens
                    for _, tokenData in ipairs(tokens) do
                        self.manaPool:returnToken(tokenData.index)
                    end
                    return nil
                end
            end
        else
            -- Specific type cost
            for _ = 1, costCount do
                local token, index = self.manaPool:getToken(costType)
                if token then
                    table.insert(tokens, {token = token, index = index})
                else
                    -- Failed to find required token, return tokens to pool
                    for _, tokenData in ipairs(tokens) do
                        self.manaPool:returnToken(tokenData.index)
                    end
                    return nil
                end
            end
        end
    end
    
    -- Successfully paid all costs
    return tokens
end

function Wizard:castSpell(spellSlot)
    local slot = self.spellSlots[spellSlot]
    if not slot or not slot.active or not slot.spell then return end
    
    print(self.name .. " cast " .. slot.spellType .. " from slot " .. spellSlot)
    
    -- Create a temporary visual notification for spell casting
    self.spellCastNotification = {
        text = self.name .. " cast " .. slot.spellType,
        timer = 2.0,  -- Show for 2 seconds
        x = self.x,
        y = self.y - 120,
        color = {self.color[1]/255, self.color[2]/255, self.color[3]/255, 1.0}
    }
    
    -- Get target (the other wizard)
    local target = nil
    for _, wizard in ipairs(self.gameState.wizards) do
        if wizard ~= self then
            target = wizard
            break
        end
    end
    
    if not target then return end
    
    -- Apply spell effect
    local effect = slot.spell.effect(self, target)
    
    -- Create visual effect based on spell type
    if self.gameState.vfx then
        self.gameState.vfx.createSpellEffect(slot.spell, self, target)
    end
    
    -- Check for projectile blocking
    if effect.spellType == "projectile" and target.blockers.projectile > 0 then
        -- Target has an active projectile block
        print(target.name .. " blocked " .. slot.spellType .. " with Mist Veil!")
        
        -- Create a visual effect for the block
        target.blockVFX = {
            active = true,
            timer = 0.5,  -- Duration of the block visual effect
            x = target.x,
            y = target.y
        }
        
        -- Create block effect using VFX system
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("mistveil", target.x, target.y, nil, nil, {
                duration = 0.5, -- Short block flash
                color = {0.7, 0.7, 1.0, 1.0}
            })
        end
        
        -- Don't consume the block, it remains active for its duration
        return  -- Skip applying any effects
    end
    
    -- Apply blocking effects (like Mist Veil)
    if effect.block then
        if effect.block == "projectile" then
            local duration = effect.blockDuration or 2.5  -- Default to 2.5s if not specified
            self.blockers.projectile = duration
            print(self.name .. " activated projectile blocking for " .. duration .. " seconds")
            
            -- Create aura effect using VFX system
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("mistveil", self.x, self.y, nil, nil)
            end
        end
    end
    
    -- Apply damage
    if effect.damage and effect.damage > 0 then
        target.health = target.health - effect.damage
        if target.health < 0 then target.health = 0 end
        print(target.name .. " took " .. effect.damage .. " damage (health: " .. target.health .. ")")
        
        -- Create hit effect if not already created by the spell VFX
        if self.gameState.vfx and not effect.spellType then
            -- Default impact effect for non-specific damage
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.5,
                color = {1.0, 0.3, 0.3, 0.8}
            })
        end
    end
    
    -- Apply position changes to the shared game state
    if effect.setPosition then
        -- Update the shared game rangeState
        if effect.setPosition == "NEAR" or effect.setPosition == "FAR" then
            self.gameState.rangeState = effect.setPosition
            print(self.name .. " changed the range state to " .. self.gameState.rangeState)
        end
    end
    
    if effect.setElevation then
        self.elevation = effect.setElevation
        print(self.name .. " moved to " .. self.elevation .. " elevation")
        
        -- Create elevation change effect
        if self.gameState.vfx and effect.setElevation == "AERIAL" then
            self.gameState.vfx.createEffect("emberlift", self.x, self.y, nil, nil)
        end
    end
    
    -- Apply stun
    if effect.stun and effect.stun > 0 then
        target.stunTimer = effect.stun
        print(target.name .. " is stunned for " .. effect.stun .. " seconds")
        
        -- Create stun effect
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.8,
                color = {1.0, 1.0, 0.2, 0.8}
            })
        end
    end
    
    -- Apply token lock
    if effect.lockToken and #target.manaPool.tokens > 0 then
        -- Get lock duration from effect or use default
        local lockDuration = effect.lockDuration or 5.0  -- Default to 5 seconds if not specified
        
        -- Find a random free token to lock
        local freeTokens = {}
        for i, token in ipairs(target.manaPool.tokens) do
            if token.state == "FREE" then
                table.insert(freeTokens, i)
            end
        end
        
        if #freeTokens > 0 then
            local tokenIndex = freeTokens[math.random(#freeTokens)]
            local token = target.manaPool.tokens[tokenIndex]
            
            -- Set token to locked state
            token.state = "LOCKED"
            token.lockDuration = lockDuration
            token.lockPulse = 0  -- Reset lock pulse animation
            
            -- Record the token type for better feedback
            local tokenType = token.type
            print("Locked a " .. tokenType .. " token in " .. target.name .. "'s mana pool for " .. lockDuration .. " seconds")
            
            -- Create lock effect at token position
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                    duration = 0.5,
                    color = {0.8, 0.2, 0.2, 0.7},
                    particleCount = 10,
                    radius = 30
                })
            end
        end
    end
    
    -- Apply spell delay
    if effect.delaySpell and target.spellSlots[effect.delaySpell] and target.spellSlots[effect.delaySpell].active then
        -- Add 50% more time to the spell
        local slot = target.spellSlots[effect.delaySpell]
        local delayTime = slot.castTime * 0.5
        slot.castTime = slot.castTime + delayTime
        print("Delayed " .. target.name .. "'s spell in slot " .. effect.delaySpell .. " by " .. delayTime .. " seconds")
        
        -- Create delay effect near the targeted spell slot
        if self.gameState.vfx then
            -- Calculate position of the targeted spell slot
            local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
            local slotY = target.y + slotYOffsets[effect.delaySpell]
            
            self.gameState.vfx.createEffect("impact", target.x, slotY, nil, nil, {
                duration = 0.7,
                color = {0.3, 0.3, 0.8, 0.7},
                particleCount = 15,
                radius = 40
            })
        end
    end
end

return Wizard```

# Documentation

## ./ComprehensiveDesignDocument.md
Game Title: Manastorm (working title)

Genre: Tactical Wizard Dueling / Real-Time Strategic Battler

Target Platforms: PC (initial), with possible future expansion to consoles

Core Pitch:

A high-stakes, low-input real-time dueling game where two spellcasters 
clash in arcane combat by channeling mana from a shared pool to queue 
spells into orbiting "spell slots." Strategy emerges from a shared 
resource economy, strict limitations on casting tempo, and deep 
interactions between positional states and spell types. Think Street 
Fighter meets Magic: The Gathering, filtered through an occult operating 
system.

Core Gameplay Loop:

Spell Selection Phase (Pre-battle)

Each player drafts a small set of spells from a shared pool.

These spells define their available actions for the match.

Combat Phase (Real-Time)

Players queue spells from their loadout (max 3 at a time).

Each spell channels mana from a shared pool and takes time to resolve.

Spells resolve in real-time after a fixed cast duration.

Cast spells release mana back into the shared pool, ramping intensity.

Positioning states (NEAR/FAR, GROUNDED/AERIAL) alter spell legality and 
effects.

Players win by reducing the opponent’s health to zero.

Key Systems & Concepts:

1. Spell Queue & Spell Slots

Each player has 3 spell slots.

Spells are queued into slots using hotkeys (Q/W/E or similar).

Each slot is visually represented as an orbit ring around the player 
character.

Channeled mana tokens orbit in these rings.

2. Mana Pool System

A shared pool of mana tokens floats in the center of the screen.

Tokens are temporarily removed when used to queue a spell.

Upon spell resolution, tokens return to the pool.

Tokens have types (e.g. FIRE, VOID, WATER), which interact with spell 
costs and effects.

The mana pool escalates tension by becoming more dynamic and volatile as 
spells resolve.

3. Token States

FREE: Available in the pool.

CHANNELED: Orbiting a caster while a spell is charging.

LOCKED: Temporarily unavailable due to enemy effects.

DESTROYED: Rare, removed from match entirely.

4. Positional States

Each player exists in binary positioning states:

Range: NEAR / FAR

Elevation: GROUNDED / AERIAL

Many spells can only be cast or take effect under certain conditions.

Players can be moved between states via spell effects.

5. Cast Feedback (Diegetic UI)

Each spell slot shows its cast time progression via a glowing arc rotating 
around the orbit.

Players can visually read how close a spell is to resolving.

No abstract bars; all feedback is embedded in the arena.

6. Spellbook System

Players have access to a limited loadout of spells during combat.

A separate spellbook UI (toggleable) shows full names, descriptions, and 
mechanics.

Core battlefield UI remains minimal to prioritize visual clarity and 
strategic deduction.

Visual & Presentation Goals

Combat is side-view, 2D.

Wizards are expressive but minimal sprites.

Mana tokens are vibrant, animated symbols.

All key mechanics are visible in-world (tokens, cast arcs, positioning 
shifts).

No HUD overload; world itself communicates state.

Design Pillars

Tactical Clarity: All decisions have observable consequences.

Strategic Literacy: Experienced players gain advantage by reading visual 
patterns.

Diegetic Information: The battlefield tells the story; minimal overlays.

Shared Economy, Shared Risk: Players operate in a closed loop that fuels 
both offense and defense.

Example Spells (Shortlist)

Ashgar the Emberfist:

Firebolt: Quick ranged hit, more damage at FAR.

Meteor Dive: Aerial finisher, hits GROUNDED enemies.

Combust Lock: Locks opponent mana token, punishes overqueueing.

Selene of the Veil:

Mist Veil: Projectile block, grants AERIAL.

Gravity Pin: Traps AERIAL enemies.

Eclipse Echo: Delays central queued spell.

Target Experience

Matches last 2–5 minutes.

Constant mental engagement without twitchy inputs.

Read-your-opponent mind games and counterplay at the forefront.

Replayable duels with high skill ceiling and unique matchups.

This document will evolve, but this version represents the intended 
holistic vision of the gameplay experience, tone, and structure of 
Manastorm.

## ./README.md
# Manastorm

A tactical wizard dueling game built with LÖVE (Love2D).

## Description

Manastorm is a real-time strategic battler where two spellcasters clash in arcane combat by channeling mana from a shared pool to queue spells into orbiting "spell slots." Strategy emerges from a shared resource economy, strict limitations on casting tempo, and deep interactions between positional states and spell types.

## Requirements

- [LÖVE](https://love2d.org/) 11.4 or later

## How to Run

1. Install LÖVE from [love2d.org](https://love2d.org/)
2. Clone this repository
3. Run the game:
   - On Windows: Drag the folder onto love.exe, or run `"C:\Program Files\LOVE\love.exe" path\to\Manastorm`
   - On macOS: Run `open -n -a love.app --args $(pwd)` from the Manastorm directory
   - On Linux: Run `love .` from the Manastorm directory

## Controls

### Player 1 (Ashgar)
- Q, W, E: Queue spells in spell slots 1, 2, and 3

### Player 2 (Selene)
- I, O, P: Queue spells in spell slots 1, 2, and 3

### General
- ESC: Quit the game

## Development Status

This is an early prototype with basic functionality:
- Two opposing wizards with health bars
- Shared mana pool with floating tokens
- Three spell slots per wizard with visual feedback
- Basic state representation (NEAR/FAR, GROUNDED/AERIAL)

## Next Steps

- Connect mana tokens to spell queueing
- Implement actual spell effects
- Add position changes
- Create proper spell descriptions
- Add collision detection
- Add visual effects

## ./manastorm_codebase_dump.md
# Manastorm Codebase Dump
Generated: Wed Apr 16 08:35:18 CDT 2025

# Source Code

## ./conf.lua
```lua
-- Configuration
function love.conf(t)
    t.title = "Manastorm - Wizard Duel"  -- The title of the window
    t.version = "11.4"                    -- The LÖVE version this game was made for
    t.window.width = 800
    t.window.height = 600
    
    t.window.vsync = 1                    -- Vertical sync (1 = enabled)
    t.window.msaa = 2                     -- Anti-aliasing (smoothing)
    
    -- For debugging
    t.console = true
    
    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = false
end```

## ./main.lua
```lua
-- Manastorm - Wizard Duel Game
-- Main game file

-- Load dependencies
local Wizard = require("wizard")
local ManaPool = require("manapool")
local UI = require("ui")
local VFX = require("vfx")

-- Game state (globally accessible)
game = {
    wizards = {},
    manaPool = nil,
    font = nil,
    rangeState = "FAR"  -- Initial range state (NEAR or FAR)
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
    
    -- Create wizards
    game.wizards[1] = Wizard.new("Ashgar", 200, 300, {255, 100, 100})
    game.wizards[2] = Wizard.new("Selene", 600, 300, {100, 100, 255})
    
    -- Set up references
    for _, wizard in ipairs(game.wizards) do
        wizard.manaPool = game.manaPool
        wizard.gameState = game
    end
    
    -- Initialize VFX system
    game.vfx = VFX.init()
    
    -- Initialize mana pool with a single random token to start
    local tokenType = game.addRandomToken()
    
    -- Log which token was added
    print("Starting the game with a single " .. tokenType .. " token")
end

function love.update(dt)
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
    
    -- Debug: Add a single random token with T key
    if key == "t" then
        local tokenType = game.addRandomToken()
        print("Added a " .. tokenType .. " token to the mana pool")
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
end```

## ./manapool.lua
```lua
-- ManaPool class
-- Represents the shared pool of mana tokens in the center

local ManaPool = {}
ManaPool.__index = ManaPool

function ManaPool.new(x, y)
    local self = setmetatable({}, ManaPool)
    
    self.x = x
    self.y = y
    self.tokens = {}  -- List of mana tokens
    
    -- Make elliptical shape even flatter and wider
    self.radiusX = 280  -- Wider horizontal radius
    self.radiusY = 60   -- Flatter vertical radius
    
    -- Define orbital rings (valences) for tokens to follow
    self.valences = {
        {radiusX = 180, radiusY = 25, baseSpeed = 0.35},  -- Inner valence
        {radiusX = 230, radiusY = 40, baseSpeed = 0.25},  -- Middle valence
        {radiusX = 280, radiusY = 55, baseSpeed = 0.18}   -- Outer valence
    }
    
    -- Chance for a token to switch valences
    self.valenceJumpChance = 0.002  -- Per frame chance of switching
    
    -- Load lock overlay image
    self.lockOverlay = love.graphics.newImage("assets/sprites/token-lock.png")
    
    return self
end

function ManaPool:addToken(tokenType, imagePath)
    -- Pick a random valence for the token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    
    -- Calculate a random angle along the valence
    local angle = math.random() * math.pi * 2
    
    -- Calculate position based on elliptical path
    local x = self.x + math.cos(angle) * valence.radiusX
    local y = self.y + math.sin(angle) * valence.radiusY
    
    -- Generate slight positional variation to avoid tokens stacking perfectly
    local variationX = math.random(-5, 5)
    local variationY = math.random(-3, 3)
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Create a new token with valence-based properties
    local token = {
        type = tokenType,
        image = love.graphics.newImage(imagePath),
        x = x + variationX,
        y = y + variationY,
        state = "FREE",  -- FREE, CHANNELED, LOCKED, DESTROYED
        lockDuration = 0, -- Duration for how long a token remains locked
        
        -- Valence-based orbit properties
        valenceIndex = valenceIndex,
        orbitAngle = angle,
        -- Speed varies by token but influenced by valence's base speed
        orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction,
        
        -- Visual effects
        pulsePhase = math.random() * math.pi * 2,
        pulseSpeed = 2 + math.random() * 3,
        rotAngle = math.random() * math.pi * 2,
        rotSpeed = math.random(-2, 2) * 0.5, -- Varying rotation speeds
        
        -- Valence jump timer (occasional orbit changes)
        valenceJumpTimer = 2 + math.random() * 8, -- Random time until possible valence change
        
        -- Valence transition properties (for smooth valence changes)
        inValenceTransition = false,
        valenceTransitionTime = 0,
        valenceTransitionDuration = 0.8,
        sourceValenceIndex = valenceIndex,
        targetValenceIndex = valenceIndex,
        sourceRadiusX = valence.radiusX,
        sourceRadiusY = valence.radiusY,
        targetRadiusX = valence.radiusX,
        targetRadiusY = valence.radiusY,
        currentRadiusX = valence.radiusX,
        currentRadiusY = valence.radiusY,
        
        -- Visual effect for locked state
        lockPulse = 0, -- For pulsing animation when locked
        
        -- Size variation for visual interest
        scale = 0.85 + math.random() * 0.3, -- Slight size variation
        
        -- Depth/z-order variation
        zOrder = math.random(),  -- Used for layering tokens
    }
    
    token.originalSpeed = token.orbitSpeed
    
    table.insert(self.tokens, token)
end

function ManaPool:update(dt)
    -- Update token positions and states
    for _, token in ipairs(self.tokens) do
        -- Update token position based on state
        if token.state == "FREE" then
            -- Handle the transition period for newly returned tokens
            if token.inTransition then
                token.transitionTime = token.transitionTime + dt
                local transProgress = math.min(1, token.transitionTime / token.transitionDuration)
                
                -- Ease transition using a smooth curve
                transProgress = transProgress < 0.5 and 4 * transProgress * transProgress * transProgress 
                            or 1 - math.pow(-2 * transProgress + 2, 3) / 2
                
                -- During transition, gradually start orbital motion
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt * transProgress
                
                -- Check if transition is complete
                if token.transitionTime >= token.transitionDuration then
                    token.inTransition = false
                end
            else
                -- Normal FREE token behavior after transition
                -- Update orbit angle with variable speed
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt
                
                -- Update valence jump timer
                token.valenceJumpTimer = token.valenceJumpTimer - dt
                
                -- Chance to change valence when timer expires
                if token.valenceJumpTimer <= 0 then
                    token.valenceJumpTimer = 2 + math.random() * 8  -- Reset timer
                    
                    -- Random chance to jump to a different valence
                    if math.random() < self.valenceJumpChance * 100 then
                        -- Store current valence for interpolation
                        local oldValenceIndex = token.valenceIndex
                        local oldValence = self.valences[oldValenceIndex]
                        local newValenceIndex = oldValenceIndex
                        
                        -- Ensure we pick a different valence if more than one exists
                        if #self.valences > 1 then
                            while newValenceIndex == oldValenceIndex do
                                newValenceIndex = math.random(1, #self.valences)
                            end
                        end
                        
                        -- Start valence transition
                        local newValence = self.valences[newValenceIndex]
                        local direction = token.orbitSpeed > 0 and 1 or -1
                        
                        -- Set up transition parameters
                        token.inValenceTransition = true
                        token.valenceTransitionTime = 0
                        token.valenceTransitionDuration = 0.8  -- Time to transition between valences
                        token.sourceValenceIndex = oldValenceIndex
                        token.targetValenceIndex = newValenceIndex
                        token.sourceRadiusX = oldValence.radiusX
                        token.sourceRadiusY = oldValence.radiusY
                        token.targetRadiusX = newValence.radiusX
                        token.targetRadiusY = newValence.radiusY
                        
                        -- Update speed for new valence but maintain direction
                        token.orbitSpeed = newValence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                        token.originalSpeed = token.orbitSpeed
                    end
                end
                
                -- Handle valence transition if active
                if token.inValenceTransition then
                    token.valenceTransitionTime = token.valenceTransitionTime + dt
                    local progress = math.min(1, token.valenceTransitionTime / token.valenceTransitionDuration)
                    
                    -- Use easing function for smooth transition
                    progress = progress < 0.5 and 4 * progress * progress * progress 
                              or 1 - math.pow(-2 * progress + 2, 3) / 2
                    
                    -- Interpolate between source and target radiuses
                    token.currentRadiusX = token.sourceRadiusX + (token.targetRadiusX - token.sourceRadiusX) * progress
                    token.currentRadiusY = token.sourceRadiusY + (token.targetRadiusY - token.sourceRadiusY) * progress
                    
                    -- Check if transition is complete
                    if token.valenceTransitionTime >= token.valenceTransitionDuration then
                        token.inValenceTransition = false
                        token.valenceIndex = token.targetValenceIndex
                    end
                end
                
                -- Occasionally vary the speed slightly
                if math.random() < 0.01 then
                    local direction = token.orbitSpeed > 0 and 1 or -1
                    local valence = self.valences[token.valenceIndex]
                    local variation = 0.9 + math.random() * 0.2  -- Subtle variation
                    token.orbitSpeed = valence.baseSpeed * variation * direction
                end
            end
            
            -- Common behavior for all FREE tokens
            -- Update pulse phase
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            
            -- Calculate new position based on elliptical orbit - maintain perfect elliptical path
            if token.inValenceTransition then
                -- Use interpolated radii during transition
                token.x = self.x + math.cos(token.orbitAngle) * token.currentRadiusX
                token.y = self.y + math.sin(token.orbitAngle) * token.currentRadiusY
            else
                -- Use valence radii when not transitioning
                local valence = self.valences[token.valenceIndex]
                token.x = self.x + math.cos(token.orbitAngle) * valence.radiusX
                token.y = self.y + math.sin(token.orbitAngle) * valence.radiusY
            end
            
            -- Minimal wobble to maintain clean orbits but add slight visual interest
            local wobbleX = math.sin(token.pulsePhase * 0.7) * 2
            local wobbleY = math.cos(token.pulsePhase * 0.5) * 1
            token.x = token.x + wobbleX
            token.y = token.y + wobbleY
            
            -- Rotate token itself for visual interest, occasionally reversing direction
            token.rotAngle = token.rotAngle + token.rotSpeed * dt
            if math.random() < 0.002 then  -- Small chance to reverse rotation
                token.rotSpeed = -token.rotSpeed
            end
        elseif token.state == "CHANNELED" then
            -- For channeled tokens, animate movement to/from their spell slot
            
            if token.animTime < token.animDuration then
                -- Token is still being animated to the spell slot
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                -- Start point
                local x0 = token.startX
                local y0 = token.startY
                
                -- End point (in the spell slot)
                local wizard = token.wizardOwner
                if wizard then
                    -- Calculate position in the 3D elliptical spell slot orbit
                    -- These values must match those in wizard.lua drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}  -- From bottom to top
                    local verticalRadii = {20, 25, 30}    -- From bottom to top
                    
                    local slotY = wizard.y + slotYOffsets[token.slotIndex]
                    local radiusX = horizontalRadii[token.slotIndex]
                    local radiusY = verticalRadii[token.slotIndex]
                    
                    local tokenCount = #wizard.spellSlots[token.slotIndex].tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = wizard.spellSlots[token.slotIndex].progress / 
                                       wizard.spellSlots[token.slotIndex].castTime * math.pi * 2 +
                                       anglePerToken * (token.tokenIndex - 1)
                    
                    -- Calculate position using elliptical projection
                    local x3 = wizard.x + math.cos(tokenAngle) * radiusX
                    local y3 = slotY + math.sin(tokenAngle) * radiusY
                    
                    -- Control points for bezier (creating an arc)
                    local midX = (x0 + x3) / 2
                    local midY = (y0 + y3) / 2 - 80  -- Arc height
                    
                    -- Quadratic bezier calculation
                    local t = progress
                    local u = 1 - t
                    token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                    token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                    
                    -- Update token rotation during flight
                    token.rotAngle = token.rotAngle + dt * 5  -- Spin faster during flight
                    
                    -- Store target position for the drawing function
                    token.targetX = x3
                    token.targetY = y3
                end
            else
                -- Animation complete - token is now in the spell orbit
                -- Token position will be updated by the wizard's drawSpellSlots function
                token.rotAngle = token.rotAngle + dt * 2  -- Continue spinning in orbit
            end
            
            -- Check if token is returning to the pool
            if token.returning then
                -- Token is being animated back to the mana pool
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                local x0 = token.startX
                local y0 = token.startY
                local x3 = self.x  -- Center of mana pool
                local y3 = self.y
                
                -- Control points for bezier (creating an arc)
                local midX = (x0 + x3) / 2
                local midY = (y0 + y3) / 2 - 50  -- Arc height
                
                -- Quadratic bezier calculation
                local t = progress
                local u = 1 - t
                token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                
                -- Update token rotation during flight - spin faster
                token.rotAngle = token.rotAngle + dt * 8
                
                -- Check if animation is complete
                if token.animTime >= token.animDuration then
                    -- Finalize the return
                    self:finalizeTokenReturn(token)
                end
            end
            
            -- Update common pulse
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
        elseif token.state == "LOCKED" then
            -- For locked tokens, update the lock duration
            if token.lockDuration > 0 then
                token.lockDuration = token.lockDuration - dt
                
                -- Update lock pulse for animation
                token.lockPulse = (token.lockPulse + dt * 3) % (math.pi * 2)
                
                -- When lock duration expires, return to FREE state
                if token.lockDuration <= 0 then
                    token.state = "FREE"
                    print("A " .. token.type .. " token has been unlocked and returned to the mana pool")
                    
                    -- Reset position to center with some random velocity
                    token.x = self.x
                    token.y = self.y
                    -- Pick a random valence for the formerly locked token
                    token.valenceIndex = math.random(1, #self.valences)
                    token.orbitAngle = math.random() * math.pi * 2
                    -- Set direction and speed based on the valence
                    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
                    local valence = self.valences[token.valenceIndex]
                    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                    token.originalSpeed = token.orbitSpeed
                end
            end
            
            -- Even locked tokens should move a bit, but more constrained
            token.x = token.x + math.sin(token.lockPulse) * 0.3
            token.y = token.y + math.cos(token.lockPulse) * 0.3
            
            -- Slight rotation
            token.rotAngle = token.rotAngle + token.rotSpeed * dt * 0.2
        end
        
        -- Update common properties for all tokens
        token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
    end
end

function ManaPool:draw()
    -- Draw pool background with a subtle gradient effect for elliptical shape
    love.graphics.setColor(0.15, 0.15, 0.25, 0.2)
    
    -- Draw the elliptical mana pool area with a glow effect
    self:drawEllipse(self.x, self.y, self.radiusX, self.radiusY, "fill")
    
    -- Draw valence rings subtly
    for _, valence in ipairs(self.valences) do
        local alpha = 0.07  -- Very subtle
        love.graphics.setColor(0.5, 0.5, 0.7, alpha)
        
        -- Draw elliptical valence path
        self:drawEllipse(self.x, self.y, valence.radiusX, valence.radiusY, "line")
    end
    
    -- Sort tokens by z-order for better layering
    local sortedTokens = {}
    for i, token in ipairs(self.tokens) do
        table.insert(sortedTokens, {token = token, index = i})
    end
    
    table.sort(sortedTokens, function(a, b)
        return a.token.zOrder > b.token.zOrder
    end)
    
    -- Draw tokens in sorted order
    for _, tokenData in ipairs(sortedTokens) do
        local token = tokenData.token
        
        -- Draw a glow around the token based on its type
        local glowSize = 10
        local glowIntensity = 0.4  -- Slightly stronger glow
        
        -- Increase glow for tokens in transition (newly returned to pool)
        if token.state == "FREE" and token.inTransition then
            -- Stronger glow that fades over the transition period
            local transitionBoost = 0.4 + 0.6 * (1 - token.transitionTime / token.transitionDuration)
            glowSize = glowSize * (1 + transitionBoost * 0.5)
            glowIntensity = glowIntensity + transitionBoost * 0.4
        end
        
        -- Set glow color based on token type with improved contrast
        if token.type == "fire" then
            love.graphics.setColor(1, 0.3, 0.1, glowIntensity)
        elseif token.type == "force" then
            love.graphics.setColor(1, 1, 0.5, glowIntensity)
        elseif token.type == "moon" then
            love.graphics.setColor(0.5, 0.5, 1, glowIntensity)
        elseif token.type == "nature" then
            love.graphics.setColor(0.3, 0.9, 0.1, glowIntensity)
        elseif token.type == "star" then
            love.graphics.setColor(1, 1, 0.2, glowIntensity)
        end
        
        -- Draw glow with pulsation
        local pulseAmount = 0.7 + 0.3 * math.sin(token.pulsePhase * 0.5)
        
        -- Enhanced pulsation for transitioning tokens
        if token.state == "FREE" and token.inTransition then
            pulseAmount = pulseAmount + 0.3 * math.sin(token.transitionTime * 10)
        end
        
        love.graphics.circle("fill", token.x, token.y, glowSize * pulseAmount * token.scale)
        
        -- Draw token image based on state
        if token.state == "FREE" then
            -- Free tokens are fully visible
            -- If token is in transition (just returned to pool), add a subtle glow effect
            if token.inTransition then
                local transitionGlow = 0.2 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
                love.graphics.setColor(1, 1, 1 + transitionGlow * 0.5, 1)  -- Slightly blue-white glow during transition
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
        elseif token.state == "CHANNELED" then
            -- Channeled tokens are fully visible
            love.graphics.setColor(1, 1, 1, 1)
        elseif token.state == "LOCKED" then
            -- Locked tokens have a red tint
            love.graphics.setColor(1, 0.5, 0.5, 0.7)
        end
        
        -- Draw the token with dynamic scaling
        love.graphics.draw(
            token.image, 
            token.x, 
            token.y, 
            token.rotAngle,  -- Use the rotation angle
            token.scale, token.scale,  -- Use token-specific scale
            token.image:getWidth()/2, token.image:getHeight()/2  -- Origin at center
        )
        
        -- Draw lock overlay for locked tokens
        if token.state == "LOCKED" then
            -- Draw the lock overlay
            local pulseScale = 0.9 + math.sin(token.lockPulse) * 0.2  -- Pulsing effect
            local overlayScale = 1.2 * pulseScale * token.scale  -- Scale for the lock overlay
            
            -- Pulsing red glow behind the lock
            love.graphics.setColor(1, 0, 0, 0.3 + 0.2 * math.sin(token.lockPulse))
            love.graphics.circle("fill", token.x, token.y, 12 * pulseScale * token.scale)
            
            -- Lock icon
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                self.lockOverlay,
                token.x,
                token.y,
                0,  -- No rotation for lock
                overlayScale, overlayScale,
                self.lockOverlay:getWidth()/2, self.lockOverlay:getHeight()/2
            )
            
            -- Display remaining lock time if more than 1 second
            if token.lockDuration > 1 then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(
                    string.format("%.0f", token.lockDuration),
                    token.x - 5,
                    token.y - 25
                )
            end
        end
    end
    
    -- Outer border with subtle glow
    love.graphics.setColor(0.5, 0.5, 0.8, 0.2 + 0.1 * math.sin(love.timer.getTime() * 0.5))
    self:drawEllipse(self.x, self.y, self.radiusX + 2, self.radiusY + 2, "line")
end

-- Helper function to draw an ellipse
function ManaPool:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 64
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

function ManaPool:findFreeToken(tokenType)
    -- Find a free token of the specified type without changing its state
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            return token, i  -- Return token and its index without changing state
        end
    end
    return nil  -- No token available
end

function ManaPool:getToken(tokenType)
    -- Find a free token of the specified type
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            token.state = "CHANNELED"  -- Mark as being used
            return token, i  -- Return token and its index
        end
    end
    return nil  -- No token available
end

function ManaPool:returnToken(tokenIndex)
    -- Return a token to the pool
    if self.tokens[tokenIndex] then
        local token = self.tokens[tokenIndex]
        
        -- Store current position as start position for return animation
        token.startX = token.x
        token.startY = token.y
        
        -- Pick a random valence for the token to return to
        local valenceIndex = math.random(1, #self.valences)
        
        -- Initialize needed valence transition fields
        local valence = self.valences[valenceIndex]
        token.valenceIndex = valenceIndex
        token.sourceValenceIndex = valenceIndex  -- Will be properly set in finalizeTokenReturn
        token.targetValenceIndex = valenceIndex
        token.sourceRadiusX = valence.radiusX
        token.sourceRadiusY = valence.radiusY
        token.targetRadiusX = valence.radiusX
        token.targetRadiusY = valence.radiusY
        token.currentRadiusX = valence.radiusX
        token.currentRadiusY = valence.radiusY
        
        -- Set up return animation parameters
        token.targetX = self.x  -- Center of mana pool
        token.targetY = self.y
        token.animTime = 0
        token.animDuration = 0.5 -- Half second return animation
        token.returning = true   -- Flag that this token is returning to the pool
        
        -- When token finishes return animation, it will become FREE in update method
        
        -- Set direction and speed based on the valence
        local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
        token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
        token.originalSpeed = token.orbitSpeed
        
        -- Reset timers with some randomness
        token.valenceJumpTimer = 2 + math.random() * 4
        
        -- Initialize transition state for smooth blending
        token.inValenceTransition = false
        token.valenceTransitionTime = 0
        token.valenceTransitionDuration = 0.8
    end
end

-- Called by update method when a token finishes its return animation
function ManaPool:finalizeTokenReturn(token)
    -- Set token state to FREE
    token.state = "FREE"
    
    -- Use the final position from the animation as the starting point
    local currentX = token.x
    local currentY = token.y
    
    -- Calculate angle from center
    local dx = currentX - self.x
    local dy = currentY - self.y
    local angle = math.atan2(dy, dx)
    
    -- Assign a random valence for the returned token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    token.valenceIndex = valenceIndex
    
    -- Calculate position based on current angle but using valence's elliptical dimensions
    token.orbitAngle = angle
    
    -- Calculate initial x,y based on selected valence
    local newX = self.x + math.cos(angle) * valence.radiusX
    local newY = self.y + math.sin(angle) * valence.radiusY
    
    -- Apply minimal variation to maintain clean orbits
    local variationX = math.random(-2, 2)
    local variationY = math.random(-1, 1)
    token.x = newX + variationX
    token.y = newY + variationY
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Set orbital speed based on the valence
    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    token.originalSpeed = token.orbitSpeed
    
    -- Add transition for smooth blending
    token.transitionTime = 0
    token.transitionDuration = 1.0  -- 1 second to blend into normal motion
    token.inTransition = true  -- Mark token as transitioning to normal motion
    
    -- Add valence jump timer
    token.valenceJumpTimer = 2 + math.random() * 8
    
    -- Initialize valence transition properties
    token.inValenceTransition = false
    token.valenceTransitionTime = 0
    token.valenceTransitionDuration = 0.8
    token.sourceValenceIndex = valenceIndex
    token.targetValenceIndex = valenceIndex
    token.sourceRadiusX = valence.radiusX
    token.sourceRadiusY = valence.radiusY
    token.targetRadiusX = valence.radiusX
    token.targetRadiusY = valence.radiusY
    token.currentRadiusX = valence.radiusX
    token.currentRadiusY = valence.radiusY
    
    -- Size and z-order variation
    token.scale = 0.85 + math.random() * 0.3
    token.zOrder = math.random()
    
    -- Clear animation flags
    token.returning = false
    token.wizardOwner = nil
    
    print("A " .. token.type .. " token has returned to the mana pool")
end

return ManaPool```

## ./spells.lua
```lua
-- Spells.lua
-- Contains data for all spells in the game

local Spells = {}

-- Spell costs are defined as tables with mana type and count
-- For generic/any mana, use "any" as the type
-- For modal costs (can be paid with subset of types), use a table of types

-- Ashgar's Spells (Fire-focused)
Spells.conjurefire = {
    name = "Conjure Fire",
    description = "Creates a new Fire mana token",
    castTime = 2.0,  -- Fast cast time
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Create a fire token in the mana pool
        caster.manaPool:addToken("fire", "assets/sprites/fire-token.png")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.firebolt = {
    name = "Firebolt",
    description = "Quick ranged hit, more damage at FAR range",
    castTime = 5.0,  -- seconds
    spellType = "projectile",  -- Mark as a projectile spell
    cost = {
        {type = "fire", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        -- Access shared range state from game state reference
        local damage = 10
        if caster.gameState.rangeState == "FAR" then damage = 15 end
        return {
            damage = damage,
            damageType = "fire",  -- Type of damage
            spellType = "projectile"  -- Include in effect for blocking check
        }
    end
}

Spells.meteor = {
    name = "Meteor Dive",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = 8.0,
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1},
        {type = "star", count = 1}
    },
    effect = function(caster, target)
        if target.elevation ~= "GROUNDED" then return {damage = 0} end
        
        return {
            damage = 20,
            type = "fire",
            setPosition = "NEAR"  -- Moves caster to NEAR
        }
    end
}

Spells.combust = {
    name = "Combust Lock",
    description = "Locks opponent mana token, punishes overqueueing",
    castTime = 6.0,
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        -- Count active spell slots
        local activeSlots = 0
        for _, slot in ipairs(target.spellSlots) do
            if slot.active then
                activeSlots = activeSlots + 1
            end
        end
        
        return {
            lockToken = true,
            lockDuration = 10.0,  -- Lock mana token for 10 seconds
            damage = activeSlots * 3  -- More damage if target has many active spells
        }
    end
}

Spells.emberlift = {
    name = "Emberlift",
    description = "Launches caster into the air and increases range",
    castTime = 2.5,  -- Short cast time
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            elevationDuration = 5.0,  -- Sets AERIAL for 5 seconds
            setPosition = "FAR",      -- Sets range to FAR
            damage = 0
        }
    end
}

-- Selene's Spells (Moon-focused)
Spells.conjuremoonlight = {
    name = "Conjure Moonlight",
    description = "Creates a new Moon mana token",
    castTime = 2.0,  -- Fast cast time
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Create a moon token in the mana pool
        caster.manaPool:addToken("moon", "assets/sprites/moon-token.png")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.volatileconjuring = {
    name = "Volatile Conjuring",
    description = "Creates a random mana token",
    castTime = 1.4,  -- Shorter cast time than the dedicated conjuring spells
    cost = {},  -- No mana cost
    effect = function(caster, target)
        -- Available token types and their image paths
        local tokenTypes = {
            {type = "fire", path = "assets/sprites/fire-token.png"},
            {type = "force", path = "assets/sprites/force-token.png"},
            {type = "moon", path = "assets/sprites/moon-token.png"},
            {type = "nature", path = "assets/sprites/nature-token.png"},
            {type = "star", path = "assets/sprites/star-token.png"}
        }
        
        -- Select a random token type
        local randomIndex = math.random(#tokenTypes)
        local selectedToken = tokenTypes[randomIndex]
        
        -- Create the token in the mana pool
        caster.manaPool:addToken(selectedToken.type, selectedToken.path)
        
        -- Display a message about which token was created (optional)
        print(caster.name .. " conjured a random " .. selectedToken.type .. " token")
        
        return {
            -- No direct effects on target
            damage = 0
        }
    end
}

Spells.mist = {
    name = "Mist Veil",
    description = "Projectile block, grants AERIAL",
    castTime = 5.0,
    cost = {
        {type = "moon", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            block = "projectile",
            blockDuration = 5.0  -- Block projectiles for 5 seconds
        }
    end
}

Spells.gravity = {
    name = "Gravity Pin",
    description = "Traps AERIAL enemies",
    castTime = 7.0,
    cost = {
        {type = "moon", count = 1},
        {type = "nature", count = 1}
    },
    effect = function(caster, target)
        if target.elevation ~= "AERIAL" then return {damage = 0} end
        
        return {
            damage = 15,
            setElevation = "GROUNDED",
            stun = 2.0  -- Stun for 2 seconds
        }
    end
}

Spells.eclipse = {
    name = "Eclipse Echo",
    description = "Delays central queued spell",
    castTime = 6.0,
    cost = {
        {type = "moon", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        return {
            delaySpell = 2  -- Targets spell slot 2 (middle)
        }
    end
}

Spells.fullmoonbeam = {
    name = "Full Moon Beam",
    description = "Channels moonlight into a powerful beam",
    castTime = 7.0,    -- Long cast time
    cost = {
        {type = "moon", count = 5}  -- Costs 5 moon mana
    },
    effect = function(caster, target)
        return {
            damage = 25,     -- Deals 25 damage
            damageType = "moon"
        }
    end
}

return Spells```

## ./ui.lua
```lua
-- UI helper module

local UI = {}

-- Spellbook visibility state
UI.spellbookVisible = {
    player1 = false,
    player2 = false
}

function UI.drawHelpText(font)
    -- Set font and color
    love.graphics.setFont(font)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    
    -- Only show minimal debug controls at the bottom
    local y = love.graphics.getHeight() - 110
    love.graphics.print("Debug Controls: T (Add tokens), R (Toggle range), A/S (Toggle elevations), ESC (Quit)", 10, y + 50)
    love.graphics.print("VFX Test Keys: 1 (Firebolt), 2 (Meteor), 3 (Mist Veil), 4 (Emberlift), 5 (Full Moon Beam)", 10, y + 70)
    love.graphics.print("Conjure Test Keys: 6 (Fire), 7 (Moonlight), 8 (Volatile)", 10, y + 90)
    
    -- Draw spellbook buttons for each player
    UI.drawSpellbookButtons()
end

-- Toggle spellbook visibility for a player
function UI.toggleSpellbook(player)
    if player == 1 then
        UI.spellbookVisible.player1 = not UI.spellbookVisible.player1
        UI.spellbookVisible.player2 = false -- Close other spellbook
    elseif player == 2 then
        UI.spellbookVisible.player2 = not UI.spellbookVisible.player2
        UI.spellbookVisible.player1 = false -- Close other spellbook
    end
end

-- Draw skeuomorphic spellbook components for both players
function UI.drawSpellbookButtons()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw Player 1's spellbook (Ashgar - left side)
    UI.drawPlayerSpellbook(1, 100, screenHeight - 70)
    
    -- Draw Player 2's spellbook (Selene - right side)
    UI.drawPlayerSpellbook(2, screenWidth - 300, screenHeight - 70)
end

-- Draw an individual player's spellbook component
function UI.drawPlayerSpellbook(playerNum, x, y)
    local screenWidth = love.graphics.getWidth()
    local width = 260  -- Further increased for better spacing
    local height = 50
    local player = (playerNum == 1) and "Ashgar" or "Selene"
    local keyLabel = (playerNum == 1) and "B" or "M"
    local keyPrefix = (playerNum == 1) and {"Q", "W", "E"} or {"I", "O", "P"}
    local wizard = _G.game.wizards[playerNum]
    local color = {wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255}
    
    -- Draw book background with slight gradient
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.25, 0.25, 0.35, 0.9)
    love.graphics.rectangle("fill", x, y, width, height/2)
    
    -- Draw book binding/spine effect
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("fill", x, y, 6, height)
    
    -- Draw book edge
    love.graphics.setColor(0.8, 0.8, 0.8, 0.3)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw dividers between sections
    love.graphics.setColor(0.4, 0.4, 0.5, 0.4)
    love.graphics.line(x + 120, y + 5, x + 120, y + height - 5)
    
    -- Center everything vertically in pane
    local centerY = y + height/2
    local runeSize = 14
    local groupSpacing = 35
    
    -- GROUP 1: SPELL INPUT KEYS
    -- Add a subtle background for the key group
    love.graphics.setColor(0.2, 0.2, 0.3, 0.3)
    love.graphics.rectangle("fill", x + 15, centerY - 20, 110, 40, 5, 5)  -- Rounded corners
    
    -- Calculate positions for centered spell input keys
    local inputStartX = x + 30
    local inputY = centerY
    
    for i = 1, 3 do
        -- Draw rune background
        love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
        love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, runeSize)
        
        if wizard.activeKeys[i] then
            -- Active rune with glow effect
            -- Multiple layers for glow
            for j = 3, 1, -1 do
                local alpha = 0.3 * (4-j) / 3
                local size = runeSize + j * 2
                love.graphics.setColor(1, 1, 0.3, alpha)
                love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, size)
            end
            
            -- Bright center
            love.graphics.setColor(1, 1, 0.7, 0.9)
            love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, runeSize * 0.7)
            
            -- Properly centered rune symbol
            local keyText = keyPrefix[i]
            local keyTextWidth = love.graphics.getFont():getWidth(keyText)
            local keyTextHeight = love.graphics.getFont():getHeight()
            love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
            love.graphics.print(keyText, 
                inputStartX + (i-1)*groupSpacing - keyTextWidth/2, 
                inputY - keyTextHeight/2)
        else
            -- Inactive rune
            love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
            love.graphics.circle("line", inputStartX + (i-1)*groupSpacing, inputY, runeSize)
            
            -- Properly centered inactive symbol
            local keyText = keyPrefix[i]
            local keyTextWidth = love.graphics.getFont():getWidth(keyText)
            local keyTextHeight = love.graphics.getFont():getHeight()
            love.graphics.setColor(0.6, 0.6, 0.7, 0.6)
            love.graphics.print(keyText, 
                inputStartX + (i-1)*groupSpacing - keyTextWidth/2, 
                inputY - keyTextHeight/2)
        end
    end
    
    -- Small "input" label beneath
    love.graphics.setColor(0.6, 0.6, 0.8, 0.7)
    local inputLabel = "Input Keys"
    local inputLabelWidth = love.graphics.getFont():getWidth(inputLabel)
    love.graphics.print(inputLabel, inputStartX + groupSpacing - inputLabelWidth/2, inputY + runeSize + 8)
    
    -- GROUP 2: CAST BUTTON
    -- Positioned farther to the right
    local castX = x + 150
    local castKey = (playerNum == 1) and "F" or "L"
    
    -- Subtle highlighting background
    love.graphics.setColor(0.3, 0.2, 0.1, 0.3)
    love.graphics.rectangle("fill", castX - 20, centerY - 20, 40, 40, 5, 5)  -- Rounded corners
    
    -- Draw cast button background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
    love.graphics.circle("fill", castX, inputY, runeSize)
    
    -- Cast button border
    love.graphics.setColor(0.8, 0.4, 0.1, 0.8)  -- Orange-ish for cast button
    love.graphics.circle("line", castX, inputY, runeSize)
    
    -- Cast button symbol
    local castTextWidth = love.graphics.getFont():getWidth(castKey)
    local castTextHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(1, 0.8, 0.3, 0.9)
    love.graphics.print(castKey, 
        castX - castTextWidth/2, 
        inputY - castTextHeight/2)
    
    -- Small "cast" label beneath
    love.graphics.setColor(0.8, 0.6, 0.3, 0.8)
    local castLabel = "Cast"
    local castLabelWidth = love.graphics.getFont():getWidth(castLabel)
    love.graphics.print(castLabel, castX - castLabelWidth/2, inputY + runeSize + 8)
    
    -- GROUP 3: KEYED SPELL POPUP (appears above the spellbook when a spell is keyed)
    if wizard.currentKeyedSpell then
        -- Make the popup exactly match the width of the spellbook
        local popupWidth = width
        local popupHeight = 30
        local popupX = x  -- Align with spellbook
        local popupY = y - popupHeight - 5  -- Position above the spellbook with small gap
        
        -- Get spell name and calculate its width for centering
        local spellName = wizard.currentKeyedSpell.name
        local spellNameWidth = love.graphics.getFont():getWidth(spellName)
        
        -- Draw popup background with a slight "connected" look
        -- Use the same color as the spellbook for visual cohesion
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        
        -- Main popup body (rounded rectangle)
        love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 5, 5)
        
        -- Connection piece (small triangle pointing down)
        love.graphics.polygon("fill", 
            x + width/2 - 8, popupY + popupHeight,  -- Left point
            x + width/2 + 8, popupY + popupHeight,  -- Right point
            x + width/2, popupY + popupHeight + 8   -- Bottom point
        )
        
        -- Add a subtle border with the wizard's color
        love.graphics.setColor(color[1], color[2], color[3], 0.5)
        love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight, 5, 5)
        
        -- Subtle gradient for the background (matches the spellbook aesthetic)
        love.graphics.setColor(0.25, 0.25, 0.35, 0.7)
        love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight/2, 5, 5)
        
        -- Simple glow effect for the text
        for i = 3, 1, -1 do
            local alpha = 0.1 * (4-i) / 3
            local size = i * 2
            love.graphics.setColor(1, 1, 0.5, alpha)
            love.graphics.rectangle("fill", 
                x + width/2 - spellNameWidth/2 - size, 
                popupY + popupHeight/2 - 7 - size/2, 
                spellNameWidth + size*2, 
                14 + size,
                5, 5
            )
        end
        
        -- Spell name centered in the popup
        love.graphics.setColor(1, 1, 0.5, 0.9)
        love.graphics.print(spellName, 
            x + width/2 - spellNameWidth/2, 
            popupY + popupHeight/2 - 7
        )
    end
    
    -- GROUP 4: SPELLBOOK HELP (bottom-right corner)
    local helpX = x + width - 20
    local helpY = y + height - 16
    
    -- Draw key hint - smaller
    local helpSize = 8
    love.graphics.setColor(0.4, 0.4, 0.6, 0.7)  -- More subdued color
    love.graphics.circle("fill", helpX, helpY, helpSize)
    
    -- Properly centered key symbol - smaller font
    local smallFont = love.graphics.getFont()  -- We'll use the same font but draw it smaller
    local keyTextWidth = smallFont:getWidth(keyLabel)
    local keyTextHeight = smallFont:getHeight()
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(keyLabel, 
        helpX - keyTextWidth/4, 
        helpY - keyTextHeight/4,
        0, 0.5, 0.5)  -- Scale to 50%
    
    -- Small "?" indicator
    love.graphics.setColor(0.6, 0.6, 0.7, 0.7)
    local helpLabel = "?"
    local helpLabelWidth = smallFont:getWidth(helpLabel)
    love.graphics.print(helpLabel, 
        helpX - 15 - helpLabelWidth/2, 
        helpY - smallFont:getHeight()/4,
        0, 0.7, 0.7)  -- Scale to 70%
    
    -- Highlight when active
    if (playerNum == 1 and UI.spellbookVisible.player1) or 
       (playerNum == 2 and UI.spellbookVisible.player2) then
        love.graphics.setColor(color[1], color[2], color[3], 0.4)
        love.graphics.rectangle("fill", x, y, width, height)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", x - 2, y - 2, width + 4, height + 4)
    end
end

function UI.drawSpellInfo(wizards)
    -- Function to format mana cost for display
    local function formatCost(cost)
        if not cost or #cost == 0 then
            return "Free"
        end
        
        local costText = ""
        for _, component in ipairs(cost) do
            local typeText = component.type
            if type(typeText) == "table" then
                typeText = table.concat(typeText, "/")
            end
            costText = costText .. component.count .. " " .. typeText .. ", "
        end
        return costText:sub(1, -3)  -- Remove trailing comma and space
    end
    
    -- Draw the fighting game style health bars
    UI.drawHealthBars(wizards)
    
    -- Draw spellbook popups if visible
    if UI.spellbookVisible.player1 then
        UI.drawSpellbookModal(wizards[1], 1, formatCost)
    end
    
    if UI.spellbookVisible.player2 then
        UI.drawSpellbookModal(wizards[2], 2, formatCost)
    end
    
    -- Spell notification is now handled by the wizard's castSpell function
    -- No longer drawing active spells list - relying on visual representation
end

-- Draw dramatic fighting game style health bars
function UI.drawHealthBars(wizards)
    local screenWidth = love.graphics.getWidth()
    local barHeight = 30
    local barWidth = 300
    local padding = 40
    local y = 20
    
    -- Player 1 (Ashgar) health bar (left side, right-to-left depletion)
    local p1 = wizards[1]
    local p1HealthPercent = p1.health / 100
    
    -- Background and border
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", padding, y, barWidth, barHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", padding, y, barWidth, barHeight)
    
    -- Health fill with gradient
    local ashgarGradient = {
        {0.8, 0.2, 0.2},  -- Red base color
        {1.0, 0.3, 0.1}   -- Brighter highlight
    }
    
    -- Draw gradient health bar 
    for i = 0, barWidth * p1HealthPercent, 1 do
        local gradientPos = i / (barWidth * p1HealthPercent)
        local r = ashgarGradient[1][1] + (ashgarGradient[2][1] - ashgarGradient[1][1]) * gradientPos
        local g = ashgarGradient[1][2] + (ashgarGradient[2][2] - ashgarGradient[1][2]) * gradientPos
        local b = ashgarGradient[1][3] + (ashgarGradient[2][3] - ashgarGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(padding + i, y + 5, padding + i, y + barHeight - 5)
    end
    
    -- Add segmented health bar sections
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    for i = 1, 9 do
        local x = padding + (barWidth / 10) * i
        love.graphics.line(x, y, x, y + barHeight)
    end
    
    -- Health lost "after damage" effect (fading darker region)
    local damageAmount = 1.0 - p1HealthPercent
    if damageAmount > 0 then
        love.graphics.setColor(0.5, 0.1, 0.1, 0.3)
        love.graphics.rectangle("fill", padding + barWidth * p1HealthPercent, y, barWidth * damageAmount, barHeight)
    end
    
    -- Gleaming highlight
    local time = love.timer.getTime()
    local hilight = math.abs(math.sin(time))
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", padding, y, barWidth * p1HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p1.name, padding + 20, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(math.floor(p1HealthPercent * 100) .. "%", padding + barWidth - 40, y + 7)
    
    
    -- Player 2 (Selene) health bar (right side, left-to-right depletion)
    local p2 = wizards[2]
    local p2HealthPercent = p2.health / 100
    local p2X = screenWidth - padding - barWidth
    
    -- Background and border
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", p2X, y, barWidth, barHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", p2X, y, barWidth, barHeight)
    
    -- Health fill with gradient
    local seleneGradient = {
        {0.1, 0.3, 0.8},  -- Blue base color
        {0.2, 0.5, 1.0}   -- Brighter highlight
    }
    
    -- Draw gradient health bar (left-to-right depletion)
    for i = 0, barWidth * p2HealthPercent, 1 do
        local gradientPos = i / (barWidth * p2HealthPercent)
        local r = seleneGradient[1][1] + (seleneGradient[2][1] - seleneGradient[1][1]) * gradientPos
        local g = seleneGradient[1][2] + (seleneGradient[2][2] - seleneGradient[1][2]) * gradientPos
        local b = seleneGradient[1][3] + (seleneGradient[2][3] - seleneGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(p2X + barWidth - i, y + 5, p2X + barWidth - i, y + barHeight - 5)
    end
    
    -- Add segmented health bar sections
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    for i = 1, 9 do
        local x = p2X + (barWidth / 10) * i
        love.graphics.line(x, y, x, y + barHeight)
    end
    
    -- Health lost "after damage" effect (fading darker region)
    local damageAmount = 1.0 - p2HealthPercent
    if damageAmount > 0 then
        love.graphics.setColor(0.1, 0.1, 0.5, 0.3)
        love.graphics.rectangle("fill", p2X, y, barWidth * damageAmount, barHeight)
    end
    
    -- Gleaming highlight
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", p2X + barWidth * (1 - p2HealthPercent), y, barWidth * p2HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p2.name, p2X + barWidth - 80, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(math.floor(p2HealthPercent * 100) .. "%", p2X + 10, y + 7)
end

-- [Removed drawActiveSpells function - now using visual representation instead]

-- Draw a full spellbook modal for a player
function UI.drawSpellbookModal(wizard, playerNum, formatCost)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Determine position based on player number
    local modalX, modalTitle, keyPrefix
    if playerNum == 1 then
        modalX = 50
        modalTitle = "Ashgar's Spellbook"
        keyPrefix = {"Q", "W", "E", "Q+W", "Q+E", "W+E", "Q+W+E"}
    else
        modalX = screenWidth - 450
        modalTitle = "Selene's Spellbook"
        keyPrefix = {"I", "O", "P", "I+O", "I+P", "O+P", "I+O+P"}
    end
    
    -- Modal background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 450)
    love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
    love.graphics.rectangle("line", modalX, 50, 400, 450)
    
    -- Modal title
    love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(modalTitle, modalX + 150, 60)
    
    -- Close button
    love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", modalX + 370, 50, 30, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("X", modalX + 380, 60)
    
    -- Controls help section at the top of the modal
    love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
    love.graphics.rectangle("fill", modalX + 10, 90, 380, 80)
    love.graphics.setColor(1, 1, 1, 0.9)
    
    if playerNum == 1 then
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("Q/W/E: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("F: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("B: Toggle spellbook visibility", modalX + 30, 155)
    else
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("I/O/P: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("L: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("M: Toggle spellbook visibility", modalX + 30, 155)
    end
    
    -- Spells section
    local y = 180
    
    -- Single key spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Single Key Spells", modalX + 150, y + 5)
    y = y + 30
    
    -- Display single key spells
    for i = 1, 3 do
        local keyName = tostring(i)
        local spell = wizard.spellbook[keyName]
        if spell then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            love.graphics.print(keyPrefix[i] .. ": " .. spell.name, modalX + 20, y + 5)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. spell.castTime .. "s", modalX + 30, y + 25)
            y = y + 45
        end
    end
    
    -- Multi-key spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Multi-Key Spells", modalX + 150, y + 5)
    y = y + 30
    
    -- Display multi-key spells
    for i = 4, 7 do  -- 4=combo "12", 5=combo "13", 6=combo "23", 7=combo "123"
        local keyName
        if i == 4 then keyName = "12"
        elseif i == 5 then keyName = "13"
        elseif i == 6 then keyName = "23"
        else keyName = "123" end
        
        local spell = wizard.spellbook[keyName]
        if spell then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            love.graphics.print(keyPrefix[i] .. ": " .. spell.name, modalX + 20, y + 5)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. spell.castTime .. "s", modalX + 30, y + 25)
            y = y + 45
        end
    end
end


return UI```

## ./vfx.lua
```lua
-- VFX.lua
-- Visual effects module for spell animations and combat effects

local VFX = {}
VFX.__index = VFX

-- Table to store active effects
VFX.activeEffects = {}

-- Initialize the VFX system
function VFX.init()
    -- Load any necessary assets for effects
    VFX.assets = {
        -- Fire effects
        fireParticle = love.graphics.newImage("assets/sprites/fire-particle.png"),
        fireGlow = love.graphics.newImage("assets/sprites/fire-glow.png"),
        
        -- Force effects
        forceWave = love.graphics.newImage("assets/sprites/force-wave.png"),
        
        -- Moon effects
        moonGlow = love.graphics.newImage("assets/sprites/moon-glow.png"),
        
        -- Generic effects
        sparkle = love.graphics.newImage("assets/sprites/sparkle.png"),
        impactRing = love.graphics.newImage("assets/sprites/impact-ring.png"),
    }
    
    -- Effect definitions keyed by effect name
    VFX.effects = {
        -- Firebolt effect
        firebolt = {
            type = "projectile",
            duration = 1.0,  -- 1 second total duration
            particleCount = 20,
            startScale = 0.5,
            endScale = 1.0,
            color = {1, 0.5, 0.2, 1},
            trailLength = 12,
            impactSize = 1.4,
            sound = "firebolt"
        },
        
        -- Meteor effect
        meteor = {
            type = "impact",
            duration = 1.5,
            particleCount = 40,
            startScale = 2.0,
            endScale = 0.5,
            color = {1, 0.4, 0.1, 1},
            radius = 120,
            sound = "meteor"
        },
        
        -- Mist Veil effect
        mistveil = {
            type = "aura",
            duration = 3.0,
            particleCount = 30,
            startScale = 0.2,
            endScale = 0.8,
            color = {0.7, 0.7, 1.0, 0.7},
            radius = 80,
            pulseRate = 2,
            sound = "mist"
        },
        
        -- Emberlift effect
        emberlift = {
            type = "vertical",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.1,
            color = {1, 0.6, 0.2, 0.8},
            height = 100,
            sound = "whoosh"
        },
        
        -- Full Moon Beam effect
        fullmoonbeam = {
            type = "beam",
            duration = 1.8,
            particleCount = 30,
            beamWidth = 40,
            startScale = 0.2,
            endScale = 1.0,
            color = {0.8, 0.8, 1.0, 0.9},
            pulseRate = 3,
            sound = "moonbeam"
        },
        
        -- Conjure Fire effect
        conjurefire = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = {1.0, 0.5, 0.2, 0.9},
            height = 140,  -- Height to rise toward mana pool
            spreadRadius = 40, -- Initial spread around the caster
            sound = "conjure"
        },
        
        -- Conjure Moonlight effect
        conjuremoonlight = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = {0.7, 0.7, 1.0, 0.9},
            height = 140,
            spreadRadius = 40,
            sound = "conjure"
        },
        
        -- Volatile Conjuring effect (random mana)
        volatileconjuring = {
            type = "conjure",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.2,
            endScale = 0.6,
            color = {1.0, 1.0, 0.5, 0.9},  -- Yellow base color, will be randomized
            height = 140,
            spreadRadius = 55,  -- Wider spread for volatile
            sound = "conjure"
        }
    }
    
    -- Initialize sound effects (placeholders)
    VFX.sounds = {
        firebolt = nil, -- Will load actual sound files when available
        meteor = nil,
        mist = nil,
        whoosh = nil,
        moonbeam = nil
    }
    
    return VFX
end

-- Create a new effect instance
function VFX.createEffect(effectName, sourceX, sourceY, targetX, targetY, options)
    -- Get effect template
    local template = VFX.effects[effectName:lower()]
    if not template then
        print("Warning: Effect not found: " .. effectName)
        return nil
    end
    
    -- Create a new effect instance
    local effect = {
        name = effectName,
        type = template.type,
        sourceX = sourceX,
        sourceY = sourceY,
        targetX = targetX or sourceX,
        targetY = targetY or sourceY,
        
        -- Timing
        duration = template.duration,
        timer = 0,
        progress = 0,
        isComplete = false,
        
        -- Visual properties (copied from template)
        particleCount = template.particleCount,
        startScale = template.startScale,
        endScale = template.endScale,
        color = {template.color[1], template.color[2], template.color[3], template.color[4]},
        
        -- Effect specific properties
        particles = {},
        trailPoints = {},
        
        -- Sound
        sound = template.sound,
        
        -- Additional properties based on effect type
        radius = template.radius,
        beamWidth = template.beamWidth,
        height = template.height,
        pulseRate = template.pulseRate,
        trailLength = template.trailLength,
        impactSize = template.impactSize,
        spreadRadius = template.spreadRadius,
        
        -- Optional overrides
        options = options or {}
    }
    
    -- Initialize particles based on effect type
    VFX.initializeParticles(effect)
    
    -- Play sound effect if available
    if effect.sound and VFX.sounds[effect.sound] then
        -- Will play sound when implemented
    end
    
    -- Add to active effects list
    table.insert(VFX.activeEffects, effect)
    
    return effect
end

-- Initialize particles based on effect type
function VFX.initializeParticles(effect)
    -- Different initialization based on effect type
    if effect.type == "projectile" then
        -- For projectiles, create a trail of particles
        for i = 1, effect.particleCount do
            local particle = {
                x = effect.sourceX,
                y = effect.sourceY,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = 0,
                delay = i / effect.particleCount * 0.3, -- Stagger particle start
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "impact" then
        -- For impact effects, create a radial explosion
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(10, effect.radius)
            local speed = math.random(50, 200)
            local particle = {
                x = effect.targetX,
                y = effect.targetY,
                targetX = effect.targetX + math.cos(angle) * distance,
                targetY = effect.targetY + math.sin(angle) * distance,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = angle,
                delay = math.random() * 0.2, -- Slight random delay
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "aura" then
        -- For aura effects, create particles that orbit the character
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(effect.radius * 0.6, effect.radius)
            local orbitalSpeed = math.random(0.5, 2.0)
            local particle = {
                angle = angle,
                distance = distance,
                orbitalSpeed = orbitalSpeed,
                scale = effect.startScale,
                alpha = 0, -- Start invisible and fade in
                rotation = 0,
                delay = i / effect.particleCount * 0.5,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "vertical" then
        -- For vertical effects like emberlift, particles rise upward
        for i = 1, effect.particleCount do
            local offsetX = math.random(-30, 30)
            local startY = math.random(0, 40)
            local speed = math.random(70, 150)
            local particle = {
                x = effect.sourceX + offsetX,
                y = effect.sourceY + startY,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = math.random() * math.pi * 2,
                delay = i / effect.particleCount * 0.8,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "beam" then
        -- For beam effects like fullmoonbeam, create a beam with particles
        -- First create the main beam shape
        effect.beamProgress = 0
        effect.beamLength = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
        effect.beamAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)
        
        -- Then add particles along the beam
        for i = 1, effect.particleCount do
            local position = math.random()
            local offset = math.random(-10, 10)
            local particle = {
                position = position, -- 0 to 1 along beam
                offset = offset, -- Perpendicular to beam
                scale = effect.startScale * math.random(0.7, 1.3),
                alpha = 0.8,
                rotation = math.random() * math.pi * 2,
                delay = math.random() * 0.3,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "conjure" then
        -- For conjuration spells, create particles that rise from caster toward mana pool
        -- Set the mana pool position (typically at top center)
        effect.manaPoolX = effect.options and effect.options.manaPoolX or 400 -- Screen center X
        effect.manaPoolY = effect.options and effect.options.manaPoolY or 120 -- Near top of screen
        
        -- Ensure spreadRadius has a default value
        effect.spreadRadius = effect.spreadRadius or 40
        
        -- Calculate direction vector toward mana pool
        local dirX = effect.manaPoolX - effect.sourceX
        local dirY = effect.manaPoolY - effect.sourceY
        local len = math.sqrt(dirX * dirX + dirY * dirY)
        dirX = dirX / len
        dirY = dirY / len
        
        for i = 1, effect.particleCount do
            -- Create a spread of particles around the caster
            local spreadAngle = math.random() * math.pi * 2
            local spreadDist = math.random() * effect.spreadRadius
            local startX = effect.sourceX + math.cos(spreadAngle) * spreadDist
            local startY = effect.sourceY + math.sin(spreadAngle) * spreadDist
            
            -- Randomize particle properties
            local speed = math.random(80, 180)
            local delay = i / effect.particleCount * 0.7
            
            -- Add some variance to path
            local pathVariance = math.random(-20, 20)
            local pathDirX = dirX + pathVariance / 100
            local pathDirY = dirY + pathVariance / 100
            
            local particle = {
                x = startX,
                y = startY,
                speedX = pathDirX * speed,
                speedY = pathDirY * speed,
                scale = effect.startScale,
                alpha = 0, -- Start transparent and fade in
                rotation = math.random() * math.pi * 2,
                rotSpeed = math.random(-3, 3),
                delay = delay,
                active = false,
                finalPulse = false,
                finalPulseTime = 0
            }
            table.insert(effect.particles, particle)
        end
    end
end

-- Update all active effects
function VFX.update(dt)
    local i = 1
    while i <= #VFX.activeEffects do
        local effect = VFX.activeEffects[i]
        
        -- Update effect timer
        effect.timer = effect.timer + dt
        effect.progress = math.min(effect.timer / effect.duration, 1.0)
        
        -- Update effect based on type
        if effect.type == "projectile" then
            VFX.updateProjectile(effect, dt)
        elseif effect.type == "impact" then
            VFX.updateImpact(effect, dt)
        elseif effect.type == "aura" then
            VFX.updateAura(effect, dt)
        elseif effect.type == "vertical" then
            VFX.updateVertical(effect, dt)
        elseif effect.type == "beam" then
            VFX.updateBeam(effect, dt)
        elseif effect.type == "conjure" then
            VFX.updateConjure(effect, dt)
        end
        
        -- Remove effect if complete
        if effect.progress >= 1.0 then
            table.remove(VFX.activeEffects, i)
        else
            i = i + 1
        end
    end
end

-- Update function for projectile effects
function VFX.updateProjectile(effect, dt)
    -- Update trail points
    if #effect.trailPoints == 0 then
        -- Initialize trail with source position
        for i = 1, effect.trailLength do
            table.insert(effect.trailPoints, {x = effect.sourceX, y = effect.sourceY})
        end
    end
    
    -- Calculate projectile position based on progress
    local posX = effect.sourceX + (effect.targetX - effect.sourceX) * effect.progress
    local posY = effect.sourceY + (effect.targetY - effect.sourceY) * effect.progress
    
    -- Add curved trajectory based on height
    local midpointProgress = effect.progress - 0.5
    local verticalOffset = -60 * (1 - (midpointProgress * 2)^2)
    posY = posY + verticalOffset
    
    -- Update trail
    table.remove(effect.trailPoints)
    table.insert(effect.trailPoints, 1, {x = posX, y = posY})
    
    -- Update particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Distribute particles along the trail
            local trailIndex = math.floor((i / #effect.particles) * #effect.trailPoints) + 1
            if trailIndex > #effect.trailPoints then trailIndex = #effect.trailPoints end
            
            local trailPoint = effect.trailPoints[trailIndex]
            
            -- Add some randomness to particle positions
            local spreadFactor = 8 * (1 - particleProgress)
            particle.x = trailPoint.x + math.random(-spreadFactor, spreadFactor)
            particle.y = trailPoint.y + math.random(-spreadFactor, spreadFactor)
            
            -- Update visual properties
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            particle.alpha = math.min(2.0 - particleProgress * 2, 1.0) -- Fade out in last half
            particle.rotation = particle.rotation + dt * 2
        end
    end
    
    -- Create impact effect when reaching the target
    if effect.progress > 0.95 and not effect.impactCreated then
        effect.impactCreated = true
        -- Would create a separate impact effect here in a full implementation
    end
end

-- Update function for impact effects
function VFX.updateImpact(effect, dt)
    -- Create impact wave that expands outward
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle outward from center
            local dirX = particle.targetX - effect.targetX
            local dirY = particle.targetY - effect.targetY
            local length = math.sqrt(dirX^2 + dirY^2)
            if length > 0 then
                dirX = dirX / length
                dirY = dirY / length
            end
            
            particle.x = effect.targetX + dirX * length * particleProgress
            particle.y = effect.targetY + dirY * length * particleProgress
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            particle.alpha = 1.0 - particleProgress^2 -- Quadratic fade out
            particle.rotation = particle.rotation + dt * 3
        end
    end
end

-- Update function for aura effects
function VFX.updateAura(effect, dt)
    -- Update orbital particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update angle for orbital motion
            particle.angle = particle.angle + dt * particle.orbitalSpeed
            
            -- Calculate position based on orbit
            particle.x = effect.sourceX + math.cos(particle.angle) * particle.distance
            particle.y = effect.sourceY + math.sin(particle.angle) * particle.distance
            
            -- Pulse effect
            local pulseOffset = math.sin(effect.timer * effect.pulseRate) * 0.2
            
            -- Update visual properties with fade in/out
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress + pulseOffset
            
            -- Fade in for first 20%, stay visible for 60%, fade out for last 20%
            if particleProgress < 0.2 then
                particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
            elseif particleProgress > 0.8 then
                particle.alpha = (1 - particleProgress) * 5 -- 1 to 0 over last 20% time
            else
                particle.alpha = 1.0
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for vertical effects
function VFX.updateVertical(effect, dt)
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle upward
            particle.y = particle.y - particle.speed * dt
            
            -- Add some horizontal drift
            local driftSpeed = 10 * math.sin(particle.y * 0.05 + i)
            particle.x = particle.x + driftSpeed * dt
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            
            -- Fade in briefly, then fade out over time
            if particleProgress < 0.1 then
                particle.alpha = particleProgress * 10 -- Quick fade in
            else
                particle.alpha = 1.0 - ((particleProgress - 0.1) / 0.9) -- Slower fade out
            end
            
            particle.rotation = particle.rotation + dt * 2
        end
    end
end

-- Update function for beam effects
function VFX.updateBeam(effect, dt)
    -- Update beam progress
    effect.beamProgress = math.min(effect.progress * 2, 1.0) -- Beam reaches full extension halfway through
    
    -- Update beam particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Only show particles along the visible length of the beam
            if particle.position <= effect.beamProgress then
                -- Calculate position along beam
                local beamX = effect.sourceX + (effect.targetX - effect.sourceX) * particle.position
                local beamY = effect.sourceY + (effect.targetY - effect.sourceY) * particle.position
                
                -- Add perpendicular offset
                local perpX = -math.sin(effect.beamAngle) * particle.offset
                local perpY = math.cos(effect.beamAngle) * particle.offset
                
                particle.x = beamX + perpX
                particle.y = beamY + perpY
                
                -- Add pulsing effect
                local pulseOffset = math.sin(effect.timer * effect.pulseRate + particle.position * 10) * 0.3
                
                -- Update visual properties
                particle.scale = (effect.startScale + (effect.endScale - effect.startScale) * particleProgress) * (1 + pulseOffset)
                
                -- Fade based on beam extension and overall effect progress
                if effect.progress < 0.5 then
                    -- Beam extending - particles at tip are brighter
                    local distFromTip = math.abs(particle.position - effect.beamProgress)
                    particle.alpha = math.max(0, 1.0 - distFromTip * 3)
                else
                    -- Beam fully extended, starting to fade out
                    local fadeProgress = (effect.progress - 0.5) * 2 -- 0 to 1 in second half
                    particle.alpha = 1.0 - fadeProgress
                end
            else
                particle.alpha = 0 -- Particle not yet reached by beam extension
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for conjure effects
function VFX.updateConjure(effect, dt)
    -- Update particles rising toward mana pool
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update position based on speed
            if not particle.finalPulse then
                particle.x = particle.x + particle.speedX * dt
                particle.y = particle.y + particle.speedY * dt
                
                -- Calculate distance to mana pool
                local distX = effect.manaPoolX - particle.x
                local distY = effect.manaPoolY - particle.y
                local dist = math.sqrt(distX * distX + distY * distY)
                
                -- If close to mana pool, trigger final pulse effect
                if dist < 30 or particleProgress > 0.85 then
                    particle.finalPulse = true
                    particle.finalPulseTime = 0
                    
                    -- Center at mana pool
                    particle.x = effect.manaPoolX + math.random(-15, 15)
                    particle.y = effect.manaPoolY + math.random(-15, 15)
                end
            else
                -- Handle final pulse animation
                particle.finalPulseTime = particle.finalPulseTime + dt
                
                -- Expand and fade out for final pulse
                local pulseProgress = math.min(particle.finalPulseTime / 0.3, 1.0) -- 0.3s pulse duration
                particle.scale = effect.endScale * (1 + pulseProgress * 2) -- Expand to 3x size
                particle.alpha = 1.0 - pulseProgress -- Fade out
            end
            
            -- Handle fade in and rotation regardless of state
            if not particle.finalPulse then
                -- Fade in over first 20% of travel
                if particleProgress < 0.2 then
                    particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
                else
                    particle.alpha = 1.0
                end
                
                -- Update scale
                particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            end
            
            -- Update rotation
            particle.rotation = particle.rotation + particle.rotSpeed * dt
        end
    end
    
    -- Add a special effect at source and destination
    if effect.progress < 0.3 then
        -- Glow at source during initial phase
        effect.sourceGlow = 1.0 - (effect.progress / 0.3)
    else
        effect.sourceGlow = 0
    end
    
    -- Glow at mana pool during later phase
    if effect.progress > 0.5 then
        effect.poolGlow = (effect.progress - 0.5) * 2
        if effect.poolGlow > 1.0 then effect.poolGlow = 2 - effect.poolGlow end -- Peak at 0.75 progress
    else
        effect.poolGlow = 0
    end
end

-- Draw all active effects
function VFX.draw()
    for _, effect in ipairs(VFX.activeEffects) do
        if effect.type == "projectile" then
            VFX.drawProjectile(effect)
        elseif effect.type == "impact" then
            VFX.drawImpact(effect)
        elseif effect.type == "aura" then
            VFX.drawAura(effect)
        elseif effect.type == "vertical" then
            VFX.drawVertical(effect)
        elseif effect.type == "beam" then
            VFX.drawBeam(effect)
        elseif effect.type == "conjure" then
            VFX.drawConjure(effect)
        end
    end
end

-- Draw function for projectile effects
function VFX.drawProjectile(effect)
    local particleImage = VFX.assets.fireParticle
    local glowImage = VFX.assets.fireGlow
    
    -- Draw trail
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    if #effect.trailPoints >= 3 then
        local points = {}
        for i, point in ipairs(effect.trailPoints) do
            table.insert(points, point.x)
            table.insert(points, point.y)
        end
        love.graphics.setLineWidth(effect.startScale * 10)
        love.graphics.line(points)
        love.graphics.setLineWidth(1)
    end
    
    -- Draw glow at head of projectile
    if #effect.trailPoints > 0 then
        local head = effect.trailPoints[1]
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
        local glowScale = effect.startScale * 3
        love.graphics.draw(
            glowImage,
            head.x, head.y,
            0,
            glowScale, glowScale,
            glowImage:getWidth()/2, glowImage:getHeight()/2
        )
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw impact flash when projectile reaches target
    if effect.progress > 0.95 then
        local flashIntensity = (1 - (effect.progress - 0.95) * 20) -- Flash quickly fades
        if flashIntensity > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], flashIntensity)
            love.graphics.circle("fill", effect.targetX, effect.targetY, effect.impactSize * 30 * (1 - flashIntensity))
        end
    end
end

-- Draw function for impact effects
function VFX.drawImpact(effect)
    local particleImage = VFX.assets.fireParticle
    local impactImage = VFX.assets.impactRing
    
    -- Draw expanding ring
    local ringProgress = math.min(effect.progress * 1.5, 1.0) -- Ring expands faster than full effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - ringProgress) * effect.color[4])
    local ringScale = effect.radius * 0.02 * ringProgress
    love.graphics.draw(
        impactImage,
        effect.targetX, effect.targetY,
        0,
        ringScale, ringScale,
        impactImage:getWidth()/2, impactImage:getHeight()/2
    )
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw central flash
    if effect.progress < 0.3 then
        local flashIntensity = 1.0 - (effect.progress / 0.3)
        love.graphics.setColor(1, 1, 1, flashIntensity * 0.7)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 30 * flashIntensity)
    end
end

-- Draw function for aura effects
function VFX.drawAura(effect)
    local particleImage = VFX.assets.sparkle
    
    -- Draw base aura circle
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.2
    local baseAlpha = 0.3 * (1 - (math.abs(effect.progress - 0.5) * 2)^2) -- Peak at middle of effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], baseAlpha)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, baseAlpha * 1.5)
    love.graphics.circle("line", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
end

-- Draw function for vertical effects
function VFX.drawVertical(effect)
    local particleImage = VFX.assets.fireParticle
    
    -- Draw base effect at source
    local baseProgress = math.min(effect.progress * 3, 1.0) -- Quick initial flash
    if baseProgress < 1.0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - baseProgress) * 0.7)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 40 * baseProgress)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw guiding lines (subtle vertical paths)
    if effect.progress < 0.7 then
        local lineAlpha = 0.3 * (1.0 - effect.progress / 0.7)
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], lineAlpha)
        for i = 1, 5 do
            local xOffset = (i - 3) * 10
            local startY = effect.sourceY
            local endY = effect.sourceY - effect.height * math.min(effect.progress * 2, 1.0)
            love.graphics.line(effect.sourceX + xOffset, startY, effect.sourceX + xOffset * 1.5, endY)
        end
    end
end

-- Draw function for beam effects
function VFX.drawBeam(effect)
    local particleImage = VFX.assets.sparkle
    local beamLength = effect.beamLength * effect.beamProgress
    
    -- Draw base beam
    local beamEndX = effect.sourceX + math.cos(effect.beamAngle) * beamLength
    local beamEndY = effect.sourceY + math.sin(effect.beamAngle) * beamLength
    
    -- Calculate beam width with pulse
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.3
    local beamWidth = effect.beamWidth * (1 + pulseAmount) * (1 - (effect.progress > 0.5 and (effect.progress - 0.5) * 2 or 0))
    
    -- Draw outer beam glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    love.graphics.setLineWidth(beamWidth * 1.5)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw inner beam core
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, effect.color[4] * 0.7)
    love.graphics.setLineWidth(beamWidth * 0.7)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw brightest beam center
    love.graphics.setColor(1, 1, 1, effect.color[4] * 0.9)
    love.graphics.setLineWidth(beamWidth * 0.3)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw source glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, 20 * (1 + pulseAmount))
    
    -- Draw impact glow at target if beam is fully extended
    if effect.beamProgress >= 0.99 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.8 * (1 - (effect.progress - 0.5) * 2))
        love.graphics.circle("fill", beamEndX, beamEndY, 25 * (1 + pulseAmount))
    end
end

-- Draw function for conjure effects
function VFX.drawConjure(effect)
    local particleImage = VFX.assets.sparkle
    local glowImage = VFX.assets.fireGlow  -- We'll use this for all conjure types
    
    -- Draw source glow if active
    if effect.sourceGlow and effect.sourceGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.sourceGlow * 0.6)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 50 * effect.sourceGlow)
        
        -- Draw expanding rings from source (hint at conjuration happening)
        local ringCount = 3
        for i = 1, ringCount do
            local ringProgress = ((effect.timer * 1.5) % 1.0) + (i-1) / ringCount
            if ringProgress < 1.0 then
                local ringSize = 60 * ringProgress
                local ringAlpha = 0.5 * (1.0 - ringProgress) * effect.sourceGlow
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], ringAlpha)
                love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
            end
        end
    end
    
    -- Draw mana pool glow if active
    if effect.poolGlow and effect.poolGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.poolGlow * 0.7)
        love.graphics.circle("fill", effect.manaPoolX, effect.manaPoolY, 40 * effect.poolGlow)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            -- Choose the right glow image based on final pulse state
            local imgToDraw = particleImage
            
            -- Adjust color based on state
            if particle.finalPulse then
                -- Brighter for final pulse
                love.graphics.setColor(
                    effect.color[1] * 1.3, 
                    effect.color[2] * 1.3, 
                    effect.color[3] * 1.3, 
                    effect.color[4] * particle.alpha
                )
                imgToDraw = glowImage
            else
                love.graphics.setColor(
                    effect.color[1], 
                    effect.color[2], 
                    effect.color[3], 
                    effect.color[4] * particle.alpha
                )
            end
            
            -- Draw the particle
            love.graphics.draw(
                imgToDraw,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                imgToDraw:getWidth()/2, imgToDraw:getHeight()/2
            )
            
            -- For volatile conjuring, add random color sparks
            if effect.name:lower() == "volatileconjuring" and not particle.finalPulse and math.random() < 0.3 then
                -- Random rainbow hue for volatile conjuring
                local hue = (effect.timer * 0.5 + particle.x * 0.01) % 1.0
                local r, g, b = HSVtoRGB(hue, 0.8, 1.0)
                
                love.graphics.setColor(r, g, b, particle.alpha * 0.7)
                love.graphics.draw(
                    particleImage,
                    particle.x + math.random(-5, 5), 
                    particle.y + math.random(-5, 5),
                    particle.rotation + math.random() * math.pi,
                    particle.scale * 0.5, particle.scale * 0.5,
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
            end
        end
    end
    
    -- Draw connection lines between particles (ethereal threads)
    if effect.progress < 0.7 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.2)
        
        local maxConnectDist = 50  -- Maximum distance for particles to connect
        for i = 1, #effect.particles do
            local p1 = effect.particles[i]
            if p1.active and p1.alpha > 0.2 and not p1.finalPulse then
                for j = i+1, #effect.particles do
                    local p2 = effect.particles[j]
                    if p2.active and p2.alpha > 0.2 and not p2.finalPulse then
                        local dx = p1.x - p2.x
                        local dy = p1.y - p2.y
                        local dist = math.sqrt(dx*dx + dy*dy)
                        
                        if dist < maxConnectDist then
                            -- Fade based on distance
                            local alpha = (1 - dist/maxConnectDist) * 0.3 * p1.alpha * p2.alpha
                            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
                            love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                        end
                    end
                end
            end
        end
    end
end

-- Helper function for HSV to RGB conversion (for volatile conjuring rainbow effect)
function HSVtoRGB(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r, g, b
end

-- Helper function to create the appropriate effect for a spell
function VFX.createSpellEffect(spell, caster, target)
    -- Get mana pool position for conjuration spells
    local manaPoolX = caster.manaPool and caster.manaPool.x or 400
    local manaPoolY = caster.manaPool and caster.manaPool.y or 120
    
    -- Determine source and target positions
    local sourceX, sourceY = caster.x, caster.y
    local targetX, targetY = target.x, target.y
    
    -- Handle different spell types
    local spellName = spell.name:lower():gsub("%s+", "") -- Convert to lowercase and remove spaces
    
    -- Handle conjuration spells first
    if spellName == "conjurefire" then
        return VFX.createEffect("conjurefire", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "conjuremoonlight" then
        return VFX.createEffect("conjuremoonlight", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "volatileconjuring" then
        return VFX.createEffect("volatileconjuring", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    
    -- Special handling for other specific spells
    elseif spellName == "firebolt" then
        return VFX.createEffect("firebolt", sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "meteor" then
        return VFX.createEffect("meteor", targetX, targetY - 100, targetX, targetY)
    elseif spellName == "mistveil" then
        return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
    elseif spellName == "emberlift" then
        return VFX.createEffect("emberlift", sourceX, sourceY, nil, nil)
    elseif spellName == "fullmoonbeam" then
        return VFX.createEffect("fullmoonbeam", sourceX, sourceY - 20, targetX, targetY - 20)
    else
        -- Create a generic effect based on spell type or mana cost
        if spell.spellType == "projectile" then
            return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
        else
            -- Look at spell cost to determine effect type
            local hasFireMana = false
            local hasMoonMana = false
            
            for _, cost in ipairs(spell.cost or {}) do
                if cost.type == "fire" then hasFireMana = true end
                if cost.type == "moon" then hasMoonMana = true end
            end
            
            if hasFireMana then
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            elseif hasMoonMana then
                return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
            else
                -- Default generic effect
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            end
        end
    end
end

return VFX```

## ./wizard.lua
```lua
-- Wizard class

local Wizard = {}
Wizard.__index = Wizard

-- Load spells
local Spells = require("spells")

function Wizard.new(name, x, y, color)
    local self = setmetatable({}, Wizard)
    
    self.name = name
    self.x = x
    self.y = y
    self.color = color  -- RGB table
    
    -- Wizard state
    self.health = 100
    self.elevation = "GROUNDED"  -- GROUNDED or AERIAL
    self.stunTimer = 0           -- Stun timer in seconds
    self.blockers = {            -- Spell blocking effects
        projectile = 0           -- Projectile block duration
    }
    
    -- Visual effects
    self.blockVFX = {
        active = false,
        timer = 0,
        x = 0,
        y = 0
    }
    
    -- Spell cast notification (temporary until proper VFX)
    self.spellCastNotification = nil
    
    -- Spell keying system
    self.activeKeys = {
        [1] = false,
        [2] = false,
        [3] = false
    }
    self.currentKeyedSpell = nil
    
    -- Spell loadout based on wizard name
    if name == "Ashgar" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjurefire,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.firebolt,
            
            -- Multi-key combinations
            ["12"] = Spells.meteor,
            ["13"] = Spells.combust,
            ["23"] = Spells.emberlift, -- Added Emberlift spell
            ["123"] = Spells.meteor   -- Placeholder, could be a new spell
        }
    elseif name == "Selene" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjuremoonlight,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.mist,
            
            -- Multi-key combinations
            ["12"] = Spells.gravity,
            ["13"] = Spells.eclipse,
            ["23"] = Spells.fullmoonbeam, -- Added Full Moon Beam spell
            ["123"] = Spells.eclipse  -- Placeholder, could be a new spell
        }
    end
    
    -- Spell slots (3 max)
    self.spellSlots = {}
    for i = 1, 3 do
        self.spellSlots[i] = {
            active = false,
            progress = 0,
            spellType = nil,
            castTime = 0,
            tokens = {}  -- Will hold channeled mana tokens
        }
    end
    
    -- Load wizard sprite
    self.sprite = love.graphics.newImage("assets/sprites/wizard.png")
    self.scale = 2.0  -- Scale factor for the sprite
    
    return self
end

function Wizard:update(dt)
    -- Update stun timer
    if self.stunTimer > 0 then
        self.stunTimer = math.max(0, self.stunTimer - dt)
        if self.stunTimer == 0 then
            print(self.name .. " is no longer stunned")
        end
    end
    
    -- Update blocker timers
    for blockType, duration in pairs(self.blockers) do
        if duration > 0 then
            self.blockers[blockType] = math.max(0, duration - dt)
            if self.blockers[blockType] == 0 then
                print(self.name .. "'s " .. blockType .. " block has expired")
            end
        end
    end
    
    -- Update block VFX
    if self.blockVFX.active then
        self.blockVFX.timer = self.blockVFX.timer - dt
        if self.blockVFX.timer <= 0 then
            self.blockVFX.active = false
        end
    end
    
    -- Update spell cast notification
    if self.spellCastNotification then
        self.spellCastNotification.timer = self.spellCastNotification.timer - dt
        if self.spellCastNotification.timer <= 0 then
            self.spellCastNotification = nil
        end
    end
    
    -- Update spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            slot.progress = slot.progress + dt
            
            -- If spell finished casting
            if slot.progress >= slot.castTime then
                self:castSpell(i)
                
                -- Start return animation for tokens
                if #slot.tokens > 0 then
                    for _, tokenData in ipairs(slot.tokens) do
                        -- Trigger animation to return token to the mana pool
                        self.manaPool:returnToken(tokenData.index)
                    end
                    
                    -- Clear token list (tokens still exist in the mana pool)
                    slot.tokens = {}
                end
                
                -- Reset slot
                slot.active = false
                slot.progress = 0
                slot.spellType = nil
                slot.castTime = 0
            end
        end
    end
end

function Wizard:draw()
    -- Calculate position adjustments based on elevation
    local yOffset = 0
    if self.elevation == "AERIAL" then
        yOffset = -30  -- Lift the wizard up when AERIAL
    end
    
    -- Set color and draw wizard
    if self.stunTimer > 0 then
        -- Apply a yellow/white flash for stunned wizards
        local flashIntensity = 0.5 + math.sin(love.timer.getTime() * 10) * 0.5
        love.graphics.setColor(1, 1, flashIntensity)
    else
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw elevation effect (GROUNDED or AERIAL)
    if self.elevation == "GROUNDED" then
        -- Draw ground indicator below wizard
        love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        love.graphics.ellipse("fill", self.x, self.y + 30, 40, 10)  -- Simple shadow/ground indicator
    end
    
    -- Draw the wizard with appropriate elevation
    love.graphics.setColor(1, 1, 1)
    
    -- Flip Selene's sprite horizontally if she's player 2
    local scaleX = self.scale
    if self.name == "Selene" then
        -- Mirror the sprite by using negative scale for the second player
        scaleX = -self.scale
    end
    
    love.graphics.draw(
        self.sprite, 
        self.x, self.y + yOffset,  -- Apply elevation offset
        0,  -- Rotation
        scaleX, self.scale,  -- Scale x, Scale y (negative x scale for Selene)
        self.sprite:getWidth()/2, self.sprite:getHeight()/2  -- Origin at center
    )
    
    -- Draw aerial effect if applicable
    if self.elevation == "AERIAL" then
        -- Draw aerial effect (clouds, wind lines, etc.)
        love.graphics.setColor(0.8, 0.8, 1, 0.3)
        
        -- Draw cloud-like puffs
        for i = 1, 3 do
            local xOffset = math.sin(love.timer.getTime() * 1.5 + i) * 8
            local cloudY = self.y + yOffset + 25 + math.sin(love.timer.getTime() + i) * 3
            love.graphics.circle("fill", self.x - 15 + xOffset, cloudY, 8)
            love.graphics.circle("fill", self.x + xOffset, cloudY, 10)
            love.graphics.circle("fill", self.x + 15 + xOffset, cloudY, 8)
        end
    end
    
    -- No longer drawing text elevation indicator - using visual representation only
    
    -- Draw stun indicator if stunned
    if self.stunTimer > 0 then
        love.graphics.setColor(1, 1, 0, 0.7 + math.sin(love.timer.getTime() * 8) * 0.3)
        love.graphics.print("STUNNED", self.x - 30, self.y - 70)
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.print(string.format("%.1fs", self.stunTimer), self.x - 10, self.y - 55)
    end
    
    -- Draw blocker indicators
    if self.blockers.projectile > 0 then
        -- Mist veil (projectile block) active indicator
        love.graphics.setColor(0.6, 0.6, 1, 0.6 + math.sin(love.timer.getTime() * 4) * 0.3)
        love.graphics.print("MIST SHIELD", self.x - 40, self.y - 100)
        love.graphics.setColor(0.7, 0.7, 1, 0.4)
        love.graphics.print(string.format("%.1fs", self.blockers.projectile), self.x - 10, self.y - 85)
        
        -- Draw a subtle shield aura
        local shieldRadius = 60
        local pulseAmount = 5 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.5, 0.5, 1, 0.2)
        love.graphics.circle("fill", self.x, self.y, shieldRadius + pulseAmount)
        love.graphics.setColor(0.7, 0.7, 1, 0.3)
        love.graphics.circle("line", self.x, self.y, shieldRadius + pulseAmount)
    end
    
    -- Draw block effect when projectile is blocked
    if self.blockVFX.active then
        -- Draw block flash animation
        local progress = self.blockVFX.timer / 0.5  -- Normalize to 0-1
        local size = 80 * (1 - progress)
        love.graphics.setColor(0.7, 0.7, 1, progress * 0.8)
        love.graphics.circle("fill", self.x, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.circle("line", self.x, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.print("BLOCKED!", self.x - 30, self.y - 120)
    end
    
    -- Health bars will now be drawn in the UI system for a more dramatic fighting game style
    
    -- Keyed spell display has been moved to the UI spellbook component
    
    -- Draw spell cast notification (temporary until proper VFX)
    if self.spellCastNotification then
        -- Fade out towards the end
        local alpha = math.min(1.0, self.spellCastNotification.timer)
        local color = self.spellCastNotification.color
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        
        -- Draw with a subtle rise effect
        local yOffset = 10 * (1 - alpha)  -- Rise up as it fades
        love.graphics.print(self.spellCastNotification.text, 
                           self.spellCastNotification.x - 60, 
                           self.spellCastNotification.y - yOffset, 
                           0, -- rotation
                           1.5, 1.5) -- scale
    end
    
    -- We'll remove the key indicators from here as they'll be drawn in the UI's spellbook component
    
    -- Draw spell slots (orbits)
    self:drawSpellSlots()
end

-- Helper function to draw an ellipse
function Wizard:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 32
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

-- Helper function to draw an elliptical arc
function Wizard:drawEllipticalArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
    segments = segments or 16
    
    -- Calculate the angle increment
    local angleRange = endAngle - startAngle
    local angleIncrement = angleRange / segments
    
    -- Create points for the arc
    local points = {}
    
    for i = 0, segments do
        local angle = startAngle + angleIncrement * i
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(points, px)
        table.insert(points, py)
    end
    
    -- Draw the arc as a line
    love.graphics.line(points)
end

function Wizard:drawSpellSlots()
    -- Draw 3 orbiting spell slots as elliptical paths at different vertical positions
    -- Position the slots at legs, midsection, and head levels
    local slotYOffsets = {30, 0, -30}  -- From bottom to top
    
    -- Horizontal and vertical radii for each elliptical path
    local horizontalRadii = {80, 70, 60}   -- Wider at the bottom, narrower at the top
    local verticalRadii = {20, 25, 30}     -- Flatter at the bottom, rounder at the top
    
    for i, slot in ipairs(self.spellSlots) do
        -- Position parameters for each slot
        local slotY = self.y + slotYOffsets[i]
        local radiusX = horizontalRadii[i]
        local radiusY = verticalRadii[i]
        
        -- Draw tokens that should appear "behind" the character first
        if slot.active and #slot.tokens > 0 then
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            for j, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                if token.animTime >= token.animDuration and not token.returning then
                    local tokenCount = #slot.tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = progressAngle + anglePerToken * (j - 1)
                    
                    -- Only draw tokens that are in the back half (π to 2π)
                    local normalizedAngle = tokenAngle % (math.pi * 2)
                    if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                        -- Calculate 3D position with elliptical projection
                        token.x = self.x + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        token.zOrder = 0  -- Behind the wizard
                        
                        -- Draw token with reduced alpha for "behind" effect
                        love.graphics.setColor(1, 1, 1, 0.5)
                        love.graphics.draw(
                            token.image,
                            token.x, token.y,
                            token.rotAngle,
                            token.scale * 0.8, token.scale * 0.8,  -- Slightly smaller for perspective
                            token.image:getWidth()/2, token.image:getHeight()/2
                        )
                    end
                end
            end
        end
        
        -- Draw the character sprite (handled by the main draw function)
        
        -- If slot is active, draw progress arc and spell name
        if slot.active then
            -- Calculate progress angle (0 to 2*pi)
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            -- Draw progress arc as ellipse, respecting the front/back z-ordering
            -- First the back half of the progress arc (if it extends that far)
            if progressAngle > math.pi then
                love.graphics.setColor(0.8, 0.8, 0.2, 0.3)  -- Lower alpha for back
                self:drawEllipticalArc(self.x, slotY, radiusX, radiusY, math.pi, progressAngle, 16)
            end
            
            -- Then the front half of the progress arc
            love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Higher alpha for front
            self:drawEllipticalArc(self.x, slotY, radiusX, radiusY, 0, math.min(progressAngle, math.pi), 16)
            
            -- Draw spell name above the highest slot
            if i == 3 then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(slot.spellType, self.x - 20, slotY - radiusY - 15)
            end
            
            -- Draw tokens that should appear "in front" of the character
            if #slot.tokens > 0 then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = progressAngle + anglePerToken * (j - 1)
                        
                        -- Only draw tokens that are in the front half (0 to π)
                        local normalizedAngle = tokenAngle % (math.pi * 2)
                        if normalizedAngle >= 0 and normalizedAngle <= math.pi then
                            -- Calculate 3D position with elliptical projection
                            token.x = self.x + math.cos(tokenAngle) * radiusX
                            token.y = slotY + math.sin(tokenAngle) * radiusY
                            token.zOrder = 1  -- In front of the wizard
                            
                            -- Draw token with full alpha for "front" effect
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale, token.scale,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        end
                    end
                end
            end
        else
            -- For inactive slots, only update token positions without drawing orbits
            if #slot.tokens > 0 then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        -- Position tokens on their appropriate paths even when slot is inactive
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = anglePerToken * (j - 1)
                        
                        -- Calculate position based on angle
                        token.x = self.x + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Set z-order based on position
                        local normalizedAngle = tokenAngle % (math.pi * 2)
                        if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                            token.zOrder = 0  -- Behind
                            -- Draw with reduced alpha for "behind" effect
                            love.graphics.setColor(1, 1, 1, 0.5)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale * 0.8, token.scale * 0.8,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        else
                            token.zOrder = 1  -- In front
                            -- Draw with full alpha
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale, token.scale,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        end
                    end
                end
            end
        end
    end
end

-- Handle key press and update currently keyed spell
function Wizard:keySpell(keyIndex, isPressed)
    -- Check if wizard is stunned
    if self.stunTimer > 0 and isPressed then
        print(self.name .. " tried to key a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Update key state
    self.activeKeys[keyIndex] = isPressed
    
    -- Determine current key combination
    local keyCombo = ""
    for i = 1, 3 do
        if self.activeKeys[i] then
            keyCombo = keyCombo .. i
        end
    end
    
    -- Update currently keyed spell based on combination
    if keyCombo == "" then
        self.currentKeyedSpell = nil
    else
        self.currentKeyedSpell = self.spellbook[keyCombo]
        
        -- Log the currently keyed spell
        if self.currentKeyedSpell then
            print(self.name .. " keyed " .. self.currentKeyedSpell.name .. " (" .. keyCombo .. ")")
        else
            print(self.name .. " has no spell for key combination: " .. keyCombo)
        end
    end
    
    return true
end

-- Cast the currently keyed spell
function Wizard:castKeyedSpell()
    -- Check if wizard is stunned
    if self.stunTimer > 0 then
        print(self.name .. " tried to cast a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Check if a spell is keyed
    if not self.currentKeyedSpell then
        print(self.name .. " tried to cast, but no spell is keyed")
        return false
    end
    
    -- Queue the keyed spell and return the result
    return self:queueSpell(self.currentKeyedSpell)
end

function Wizard:queueSpell(spell)
    -- Check if wizard is stunned
    if self.stunTimer > 0 then
        print(self.name .. " tried to queue a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Validate the spell
    if not spell then
        print("No spell provided to queue")
        return false
    end
    
    -- Find the innermost available spell slot
    for i = 1, #self.spellSlots do
        if not self.spellSlots[i].active then
            -- Check if we can pay the mana cost from the pool
            local tokenReservations = self:canPayManaCost(spell.cost)
            
            if tokenReservations then
                -- Collect the actual tokens to animate them to the spell slot
                local tokens = {}
                
                -- Move each token from mana pool to spell slot with animation
                for _, reservation in ipairs(tokenReservations) do
                    local token = self.manaPool.tokens[reservation.index]
                    
                    -- Mark the token as being channeled
                    token.state = "CHANNELED"
                    
                    -- Store original position for animation
                    token.startX = token.x
                    token.startY = token.y
                    
                    -- Calculate target position in the spell slot based on 3D positioning
                    -- These must match values in drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}
                    local verticalRadii = {20, 25, 30}
                    
                    local targetX = self.x
                    local targetY = self.y + slotYOffsets[i]  -- Vertical offset based on slot
                    
                    -- Animation data
                    token.targetX = targetX
                    token.targetY = targetY
                    token.animTime = 0
                    token.animDuration = 0.5 -- Half second animation
                    token.slotIndex = i
                    token.tokenIndex = #tokens + 1 -- Position in the slot
                    token.spellSlot = i
                    token.wizardOwner = self
                    
                    -- 3D perspective data
                    token.radiusX = horizontalRadii[i]
                    token.radiusY = verticalRadii[i]
                    
                    table.insert(tokens, {token = token, index = reservation.index})
                end
                
                -- Successfully paid the cost, queue the spell
                self.spellSlots[i].active = true
                self.spellSlots[i].progress = 0
                self.spellSlots[i].spellType = spell.name
                self.spellSlots[i].castTime = spell.castTime
                self.spellSlots[i].spell = spell
                self.spellSlots[i].tokens = tokens
                
                print(self.name .. " queued " .. spell.name .. " in slot " .. i .. " (cast time: " .. spell.castTime .. "s)")
                return true
            else
                -- Couldn't pay the cost
                print(self.name .. " tried to queue " .. spell.name .. " but couldn't pay the mana cost")
                return false
            end
        end
    end
    
    -- No available slots
    print(self.name .. " tried to queue " .. spell.name .. " but all slots are full")
    return false
end

-- Helper function to check if mana cost can be paid without actually taking the tokens
function Wizard:canPayManaCost(cost)
    local tokenReservations = {}
    
    -- This function mirrors payManaCost but just returns the indices of tokens that would be used
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType = costComponent.type
        local costCount = costComponent.count
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Try to get tokens of this type
                for _ = 1, costCount do
                    local token, index = self.manaPool:findFreeToken(modalType)
                    if token then
                        table.insert(tokenReservations, {token = token, index = index})
                        paid = true
                        break
                    end
                end
                if paid then break end
            end
            
            if not paid then
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available token types
                local availableTypes = {}
                local availableIndices = {}
                
                -- Check each mana type and gather available ones
                for _, tokenType in ipairs({"fire", "force", "moon", "nature", "star"}) do
                    local token, index = self.manaPool:findFreeToken(tokenType)
                    if token then
                        table.insert(availableTypes, tokenType)
                        table.insert(availableIndices, index)
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTypes > 0 then
                    -- Shuffle the available types for true randomness
                    for i = #availableTypes, 2, -1 do
                        local j = math.random(i)
                        availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
                        availableIndices[i], availableIndices[j] = availableIndices[j], availableIndices[i]
                    end
                    
                    -- Use the first type after shuffling
                    local randomIndex = availableIndices[1]
                    local token = self.manaPool.tokens[randomIndex]
                    
                    table.insert(tokenReservations, {token = token, index = randomIndex})
                else
                    return nil
                end
            end
        else
            -- Specific type cost
            for _ = 1, costCount do
                local token, index = self.manaPool:findFreeToken(costType)
                if token then
                    table.insert(tokenReservations, {token = token, index = index})
                else
                    return nil
                end
            end
        end
    end
    
    return tokenReservations
end

-- Helper function to check and pay mana costs
function Wizard:payManaCost(cost)
    local tokens = {}
    
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType = costComponent.type
        local costCount = costComponent.count
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Try to get tokens of this type
                for _ = 1, costCount do
                    local token, index = self.manaPool:getToken(modalType)
                    if token then
                        table.insert(tokens, {token = token, index = index})
                        paid = true
                        break
                    end
                end
                if paid then break end
            end
            
            if not paid then
                -- Failed to pay modal cost, return tokens to pool
                for _, tokenData in ipairs(tokens) do
                    self.manaPool:returnToken(tokenData.index)
                end
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available token types
                local availableTypes = {}
                
                -- Check each mana type and gather available ones
                for _, tokenType in ipairs({"fire", "force", "moon", "nature", "star"}) do
                    local token, index = self.manaPool:getToken(tokenType)
                    if token then
                        -- Found a token, return it to the pool for now
                        self.manaPool:returnToken(index)
                        table.insert(availableTypes, tokenType)
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTypes > 0 then
                    -- Shuffle the available types for true randomness
                    for i = #availableTypes, 2, -1 do
                        local j = math.random(i)
                        availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
                    end
                    
                    -- Use the first type after shuffling
                    local token, index = self.manaPool:getToken(availableTypes[1])
                    
                    if token then
                        table.insert(tokens, {token = token, index = index})
                    else
                        -- Failed to find any token, return tokens to pool
                        for _, tokenData in ipairs(tokens) do
                            self.manaPool:returnToken(tokenData.index)
                        end
                        return nil
                    end
                else
                    -- No available tokens, return already collected tokens
                    for _, tokenData in ipairs(tokens) do
                        self.manaPool:returnToken(tokenData.index)
                    end
                    return nil
                end
            end
        else
            -- Specific type cost
            for _ = 1, costCount do
                local token, index = self.manaPool:getToken(costType)
                if token then
                    table.insert(tokens, {token = token, index = index})
                else
                    -- Failed to find required token, return tokens to pool
                    for _, tokenData in ipairs(tokens) do
                        self.manaPool:returnToken(tokenData.index)
                    end
                    return nil
                end
            end
        end
    end
    
    -- Successfully paid all costs
    return tokens
end

function Wizard:castSpell(spellSlot)
    local slot = self.spellSlots[spellSlot]
    if not slot or not slot.active or not slot.spell then return end
    
    print(self.name .. " cast " .. slot.spellType .. " from slot " .. spellSlot)
    
    -- Create a temporary visual notification for spell casting
    self.spellCastNotification = {
        text = self.name .. " cast " .. slot.spellType,
        timer = 2.0,  -- Show for 2 seconds
        x = self.x,
        y = self.y - 120,
        color = {self.color[1]/255, self.color[2]/255, self.color[3]/255, 1.0}
    }
    
    -- Get target (the other wizard)
    local target = nil
    for _, wizard in ipairs(self.gameState.wizards) do
        if wizard ~= self then
            target = wizard
            break
        end
    end
    
    if not target then return end
    
    -- Apply spell effect
    local effect = slot.spell.effect(self, target)
    
    -- Create visual effect based on spell type
    if self.gameState.vfx then
        self.gameState.vfx.createSpellEffect(slot.spell, self, target)
    end
    
    -- Check for projectile blocking
    if effect.spellType == "projectile" and target.blockers.projectile > 0 then
        -- Target has an active projectile block
        print(target.name .. " blocked " .. slot.spellType .. " with Mist Veil!")
        
        -- Create a visual effect for the block
        target.blockVFX = {
            active = true,
            timer = 0.5,  -- Duration of the block visual effect
            x = target.x,
            y = target.y
        }
        
        -- Create block effect using VFX system
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("mistveil", target.x, target.y, nil, nil, {
                duration = 0.5, -- Short block flash
                color = {0.7, 0.7, 1.0, 1.0}
            })
        end
        
        -- Don't consume the block, it remains active for its duration
        return  -- Skip applying any effects
    end
    
    -- Apply blocking effects (like Mist Veil)
    if effect.block then
        if effect.block == "projectile" then
            local duration = effect.blockDuration or 2.5  -- Default to 2.5s if not specified
            self.blockers.projectile = duration
            print(self.name .. " activated projectile blocking for " .. duration .. " seconds")
            
            -- Create aura effect using VFX system
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("mistveil", self.x, self.y, nil, nil)
            end
        end
    end
    
    -- Apply damage
    if effect.damage and effect.damage > 0 then
        target.health = target.health - effect.damage
        if target.health < 0 then target.health = 0 end
        print(target.name .. " took " .. effect.damage .. " damage (health: " .. target.health .. ")")
        
        -- Create hit effect if not already created by the spell VFX
        if self.gameState.vfx and not effect.spellType then
            -- Default impact effect for non-specific damage
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.5,
                color = {1.0, 0.3, 0.3, 0.8}
            })
        end
    end
    
    -- Apply position changes to the shared game state
    if effect.setPosition then
        -- Update the shared game rangeState
        if effect.setPosition == "NEAR" or effect.setPosition == "FAR" then
            self.gameState.rangeState = effect.setPosition
            print(self.name .. " changed the range state to " .. self.gameState.rangeState)
        end
    end
    
    if effect.setElevation then
        self.elevation = effect.setElevation
        print(self.name .. " moved to " .. self.elevation .. " elevation")
        
        -- Create elevation change effect
        if self.gameState.vfx and effect.setElevation == "AERIAL" then
            self.gameState.vfx.createEffect("emberlift", self.x, self.y, nil, nil)
        end
    end
    
    -- Apply stun
    if effect.stun and effect.stun > 0 then
        target.stunTimer = effect.stun
        print(target.name .. " is stunned for " .. effect.stun .. " seconds")
        
        -- Create stun effect
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.8,
                color = {1.0, 1.0, 0.2, 0.8}
            })
        end
    end
    
    -- Apply token lock
    if effect.lockToken and #target.manaPool.tokens > 0 then
        -- Get lock duration from effect or use default
        local lockDuration = effect.lockDuration or 5.0  -- Default to 5 seconds if not specified
        
        -- Find a random free token to lock
        local freeTokens = {}
        for i, token in ipairs(target.manaPool.tokens) do
            if token.state == "FREE" then
                table.insert(freeTokens, i)
            end
        end
        
        if #freeTokens > 0 then
            local tokenIndex = freeTokens[math.random(#freeTokens)]
            local token = target.manaPool.tokens[tokenIndex]
            
            -- Set token to locked state
            token.state = "LOCKED"
            token.lockDuration = lockDuration
            token.lockPulse = 0  -- Reset lock pulse animation
            
            -- Record the token type for better feedback
            local tokenType = token.type
            print("Locked a " .. tokenType .. " token in " .. target.name .. "'s mana pool for " .. lockDuration .. " seconds")
            
            -- Create lock effect at token position
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                    duration = 0.5,
                    color = {0.8, 0.2, 0.2, 0.7},
                    particleCount = 10,
                    radius = 30
                })
            end
        end
    end
    
    -- Apply spell delay
    if effect.delaySpell and target.spellSlots[effect.delaySpell] and target.spellSlots[effect.delaySpell].active then
        -- Add 50% more time to the spell
        local slot = target.spellSlots[effect.delaySpell]
        local delayTime = slot.castTime * 0.5
        slot.castTime = slot.castTime + delayTime
        print("Delayed " .. target.name .. "'s spell in slot " .. effect.delaySpell .. " by " .. delayTime .. " seconds")
        
        -- Create delay effect near the targeted spell slot
        if self.gameState.vfx then
            -- Calculate position of the targeted spell slot
            local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
            local slotY = target.y + slotYOffsets[effect.delaySpell]
            
            self.gameState.vfx.createEffect("impact", target.x, slotY, nil, nil, {
                duration = 0.7,
                color = {0.3, 0.3, 0.8, 0.7},
                particleCount = 15,
                radius = 40
            })
        end
    end
end

return Wizard```

# Documentation

## ./ComprehensiveDesignDocument.md
Game Title: Manastorm (working title)

Genre: Tactical Wizard Dueling / Real-Time Strategic Battler

Target Platforms: PC (initial), with possible future expansion to consoles

Core Pitch:

A high-stakes, low-input real-time dueling game where two spellcasters 
clash in arcane combat by channeling mana from a shared pool to queue 
spells into orbiting "spell slots." Strategy emerges from a shared 
resource economy, strict limitations on casting tempo, and deep 
interactions between positional states and spell types. Think Street 
Fighter meets Magic: The Gathering, filtered through an occult operating 
system.

Core Gameplay Loop:

Spell Selection Phase (Pre-battle)

Each player drafts a small set of spells from a shared pool.

These spells define their available actions for the match.

Combat Phase (Real-Time)

Players queue spells from their loadout (max 3 at a time).

Each spell channels mana from a shared pool and takes time to resolve.

Spells resolve in real-time after a fixed cast duration.

Cast spells release mana back into the shared pool, ramping intensity.

Positioning states (NEAR/FAR, GROUNDED/AERIAL) alter spell legality and 
effects.

Players win by reducing the opponent’s health to zero.

Key Systems & Concepts:

1. Spell Queue & Spell Slots

Each player has 3 spell slots.

Spells are queued into slots using hotkeys (Q/W/E or similar).

Each slot is visually represented as an orbit ring around the player 
character.

Channeled mana tokens orbit in these rings.

2. Mana Pool System

A shared pool of mana tokens floats in the center of the screen.

Tokens are temporarily removed when used to queue a spell.

Upon spell resolution, tokens return to the pool.

Tokens have types (e.g. FIRE, VOID, WATER), which interact with spell 
costs and effects.

The mana pool escalates tension by becoming more dynamic and volatile as 
spells resolve.

3. Token States

FREE: Available in the pool.

CHANNELED: Orbiting a caster while a spell is charging.

LOCKED: Temporarily unavailable due to enemy effects.

DESTROYED: Rare, removed from match entirely.

4. Positional States

Each player exists in binary positioning states:

Range: NEAR / FAR

Elevation: GROUNDED / AERIAL

Many spells can only be cast or take effect under certain conditions.

Players can be moved between states via spell effects.

5. Cast Feedback (Diegetic UI)

Each spell slot shows its cast time progression via a glowing arc rotating 
around the orbit.

Players can visually read how close a spell is to resolving.

No abstract bars; all feedback is embedded in the arena.

6. Spellbook System

Players have access to a limited loadout of spells during combat.

A separate spellbook UI (toggleable) shows full names, descriptions, and 
mechanics.

Core battlefield UI remains minimal to prioritize visual clarity and 
strategic deduction.

Visual & Presentation Goals

Combat is side-view, 2D.

Wizards are expressive but minimal sprites.

Mana tokens are vibrant, animated symbols.

All key mechanics are visible in-world (tokens, cast arcs, positioning 
shifts).

No HUD overload; world itself communicates state.

Design Pillars

Tactical Clarity: All decisions have observable consequences.

Strategic Literacy: Experienced players gain advantage by reading visual 
patterns.

Diegetic Information: The battlefield tells the story; minimal overlays.

Shared Economy, Shared Risk: Players operate in a closed loop that fuels 
both offense and defense.

Example Spells (Shortlist)

Ashgar the Emberfist:

Firebolt: Quick ranged hit, more damage at FAR.

Meteor Dive: Aerial finisher, hits GROUNDED enemies.

Combust Lock: Locks opponent mana token, punishes overqueueing.

Selene of the Veil:

Mist Veil: Projectile block, grants AERIAL.

Gravity Pin: Traps AERIAL enemies.

Eclipse Echo: Delays central queued spell.

Target Experience

Matches last 2–5 minutes.

Constant mental engagement without twitchy inputs.

Read-your-opponent mind games and counterplay at the forefront.

Replayable duels with high skill ceiling and unique matchups.

This document will evolve, but this version represents the intended 
holistic vision of the gameplay experience, tone, and structure of 
Manastorm.

## ./README.md
# Manastorm

A tactical wizard dueling game built with LÖVE (Love2D).

## Description

Manastorm is a real-time strategic battler where two spellcasters clash in arcane combat by channeling mana from a shared pool to queue spells into orbiting "spell slots." Strategy emerges from a shared resource economy, strict limitations on casting tempo, and deep interactions between positional states and spell types.

## Requirements

- [LÖVE](https://love2d.org/) 11.4 or later

## How to Run

1. Install LÖVE from [love2d.org](https://love2d.org/)
2. Clone this repository
3. Run the game:
   - On Windows: Drag the folder onto love.exe, or run `"C:\Program Files\LOVE\love.exe" path\to\Manastorm`
   - On macOS: Run `open -n -a love.app --args $(pwd)` from the Manastorm directory
   - On Linux: Run `love .` from the Manastorm directory

## Controls

### Player 1 (Ashgar)
- Q, W, E: Queue spells in spell slots 1, 2, and 3

### Player 2 (Selene)
- I, O, P: Queue spells in spell slots 1, 2, and 3

### General
- ESC: Quit the game

## Development Status

This is an early prototype with basic functionality:
- Two opposing wizards with health bars
- Shared mana pool with floating tokens
- Three spell slots per wizard with visual feedback
- Basic state representation (NEAR/FAR, GROUNDED/AERIAL)

## Next Steps

- Connect mana tokens to spell queueing
- Implement actual spell effects
- Add position changes
- Create proper spell descriptions
- Add collision detection
- Add visual effects

## ./manastorm_codebase_dump.md

