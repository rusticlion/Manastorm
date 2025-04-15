# Manastorm Codebase Dump
Generated: Tue Apr 15 10:28:37 CDT 2025

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

-- Game state
local game = {
    wizards = {},
    manaPool = nil,
    font = nil
}

function love.load()
    -- Set up window
    love.window.setTitle("Manastorm - Wizard Duel")
    love.window.setMode(800, 600)
    
    -- Load font
    game.font = love.graphics.newFont("assets/fonts/Lionscript-Regular.ttf", 16)
    love.graphics.setFont(game.font)
    
    -- Create mana pool
    game.manaPool = ManaPool.new(400, 200)
    
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

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    -- Player 1 (Ashgar) controls - Q, W, E keys for different spells
    if key == "q" then
        game.wizards[1]:queueSpell(1)  -- Firebolt
    elseif key == "w" then
        game.wizards[1]:queueSpell(2)  -- Meteor Dive
    elseif key == "e" then
        game.wizards[1]:queueSpell(3)  -- Combust Lock
    end
    
    -- Player 2 (Selene) controls - I, O, P keys for different spells
    if key == "i" then
        game.wizards[2]:queueSpell(1)  -- Mist Veil
    elseif key == "o" then
        game.wizards[2]:queueSpell(2)  -- Gravity Pin
    elseif key == "p" then
        game.wizards[2]:queueSpell(3)  -- Eclipse Echo
    end
    
    -- Debug: Add more tokens with T key
    if key == "t" then
        game.manaPool:addToken("fire", "assets/sprites/fire-token.png")
        game.manaPool:addToken("moon", "assets/sprites/moon-token.png")
        game.manaPool:addToken("force", "assets/sprites/force-token.png")
        print("Added more tokens to the mana pool")
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
    self.radius = 110  -- Area where tokens float
    self.innerRadius = 40  -- Inner radius where tokens can't go
    self.rotationSpeed = 0.3  -- Base rotation speed
    self.spiralTightness = 0.2  -- How tight the spiral is
    
    return self
end

function ManaPool:addToken(tokenType, imagePath)
    -- Calculate a random position in the pool area, but not too close to center
    local angle = math.random() * math.pi * 2
    local dist = math.random(self.innerRadius, self.radius)
    
    -- Define token valence rings (orbital paths)
    local valences = {
        self.innerRadius + 10,
        self.innerRadius + (self.radius - self.innerRadius) * 0.4,
        self.innerRadius + (self.radius - self.innerRadius) * 0.7,
        self.radius - 10
    }
    
    -- Pick a starting valence
    local valenceIndex = math.random(1, #valences)
    
    -- Create a new token with more dynamic properties
    local token = {
        type = tokenType,
        image = love.graphics.newImage(imagePath),
        x = self.x + math.cos(angle) * dist,
        y = self.y + math.sin(angle) * dist,
        state = "FREE",  -- FREE, CHANNELED, LOCKED, DESTROYED
        orbitAngle = angle,
        orbitDist = dist,
        -- More varying speeds, some much faster than others
        orbitSpeed = (0.5 + math.random() * 1.5) * self.rotationSpeed * (1 - (dist / self.radius) * self.spiralTightness),
        pulsePhase = math.random() * math.pi * 2,
        pulseSpeed = 2 + math.random() * 3,
        rotAngle = math.random() * math.pi * 2,
        rotSpeed = math.random(-2, 2) * 0.5, -- More varying rotations
        
        -- Valence properties
        valenceIndex = valenceIndex,
        valenceTarget = valences[valenceIndex],
        valenceJumpTimer = 2 + math.random() * 6, -- Time until next valence jump
        valenceJumpChance = 0.3, -- Chance to jump valences
        
        -- Occasional speed changes
        speedVariationTimer = 1 + math.random() * 3,
        originalSpeed = 0, -- Will be set after initialization
    }
    
    token.originalSpeed = token.orbitSpeed
    
    table.insert(self.tokens, token)
end

function ManaPool:update(dt)
    -- Define token valence rings (orbital paths) - must match the ones in addToken
    local valences = {
        self.innerRadius + 10,
        self.innerRadius + (self.radius - self.innerRadius) * 0.4,
        self.innerRadius + (self.radius - self.innerRadius) * 0.7,
        self.radius - 10
    }
    
    -- Update token positions and states
    for _, token in ipairs(self.tokens) do
        if token.state == "FREE" then
            -- Update orbit angle with variable speed
            token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt
            
            -- Update valence jump timer
            token.valenceJumpTimer = token.valenceJumpTimer - dt
            if token.valenceJumpTimer <= 0 then
                -- Reset timer
                token.valenceJumpTimer = 2 + math.random() * 6
                
                -- Random chance to jump to a different valence
                if math.random() <= token.valenceJumpChance then
                    -- Pick a new valence that's different from the current one
                    local newValenceIndex = token.valenceIndex
                    while newValenceIndex == token.valenceIndex do
                        newValenceIndex = math.random(1, #valences)
                    end
                    
                    token.valenceIndex = newValenceIndex
                    token.valenceTarget = valences[newValenceIndex]
                    
                    -- Speed up temporarily during transition
                    token.orbitSpeed = token.originalSpeed * (1.5 + math.random())
                end
            end
            
            -- Smoothly move toward target valence
            local distDiff = token.valenceTarget - token.orbitDist
            token.orbitDist = token.orbitDist + distDiff * dt * 1.5
            
            -- Add some wobble to the orbit
            token.orbitDist = token.orbitDist + math.sin(token.pulsePhase) * 2 * dt
            
            -- Keep within absolute bounds
            if token.orbitDist < self.innerRadius then
                token.orbitDist = self.innerRadius
            elseif token.orbitDist > self.radius then
                token.orbitDist = self.radius
            end
            
            -- Update pulse phase
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            
            -- Update speed variation timer
            token.speedVariationTimer = token.speedVariationTimer - dt
            if token.speedVariationTimer <= 0 then
                -- Reset timer
                token.speedVariationTimer = 1 + math.random() * 3
                
                -- Occasionally change speed
                if math.random() < 0.7 then
                    local speedFactor = 0.5 + math.random() * 1.5
                    token.orbitSpeed = token.originalSpeed * speedFactor
                else
                    -- Sometimes revert to original speed
                    token.orbitSpeed = token.originalSpeed
                end
            end
            
            -- Calculate new position based on orbit
            token.x = self.x + math.cos(token.orbitAngle) * token.orbitDist
            token.y = self.y + math.sin(token.orbitAngle) * token.orbitDist
            
            -- Rotate token itself for visual interest, occasionally reversing direction
            token.rotAngle = token.rotAngle + token.rotSpeed * dt
            if math.random() < 0.002 then  -- Small chance to reverse rotation
                token.rotSpeed = -token.rotSpeed
            end
        end
    end
end

function ManaPool:draw()
    -- Draw pool background with a subtle gradient effect
    love.graphics.setColor(0.15, 0.15, 0.25, 0.2)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- Inner circle with slightly different color
    love.graphics.setColor(0.2, 0.2, 0.35, 0.3)
    love.graphics.circle("fill", self.x, self.y, self.innerRadius)
    
    -- Outer border (subtle)
    love.graphics.setColor(0.25, 0.25, 0.4, 0.3)
    love.graphics.circle("line", self.x, self.y, self.radius)
    
    -- Inner border (subtle)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
    love.graphics.circle("line", self.x, self.y, self.innerRadius)
    
    -- Draw tokens
    for _, token in ipairs(self.tokens) do
        -- Draw a subtle glow around the token based on its type
        local glowSize = 10
        local glowIntensity = 0.3
        
        -- Set glow color based on token type
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
        
        -- Draw glow
        love.graphics.circle("fill", token.x, token.y, glowSize * (0.7 + 0.3 * math.sin(token.pulsePhase * 0.5)))
        
        -- Draw token image
        if token.state == "FREE" then
            love.graphics.setColor(1, 1, 1, 1)  -- FREE tokens are fully visible
        elseif token.state == "LOCKED" then
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)  -- LOCKED tokens are faded
        end
        
        love.graphics.draw(
            token.image, 
            token.x, 
            token.y, 
            token.rotAngle,  -- Use the rotation angle
            1, 1,  -- Scale
            token.image:getWidth()/2, token.image:getHeight()/2  -- Origin at center
        )
    end
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
        token.state = "FREE"
        
        -- Define token valence rings (orbital paths) - must match the ones in addToken and update
        local valences = {
            self.innerRadius + 10,
            self.innerRadius + (self.radius - self.innerRadius) * 0.4,
            self.innerRadius + (self.radius - self.innerRadius) * 0.7,
            self.radius - 10
        }
        
        -- Pick a random valence
        local valenceIndex = math.random(1, #valences)
        token.valenceIndex = valenceIndex
        token.valenceTarget = valences[valenceIndex]
        
        -- Reset position to pool center
        token.x = self.x
        token.y = self.y
        
        -- Set a random orbit angle and distance
        token.orbitAngle = math.random() * math.pi * 2
        token.orbitDist = self.innerRadius + (self.radius - self.innerRadius) * 0.5
        
        -- Temporarily boost speed for dramatic return
        token.orbitSpeed = token.originalSpeed * 2
        token.speedVariationTimer = 1 + math.random() * 2
        
        -- Reset timers with some randomness
        token.valenceJumpTimer = 2 + math.random() * 4
    end
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
Spells.firebolt = {
    name = "Firebolt",
    description = "Quick ranged hit, more damage at FAR range",
    castTime = 2.5,  -- seconds
    cost = {
        {type = "fire", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        -- Will implement actual effects later
        local damage = 10
        if target.position == "FAR" then damage = 15 end
        return {
            damage = damage,
            type = "fire"
        }
    end
}

Spells.meteor = {
    name = "Meteor Dive",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = 4.0,
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
    castTime = 3.0,
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        return {
            lockToken = true,
            damage = target.spellSlotsActive * 3  -- More damage if target has many active spells
        }
    end
}

-- Selene's Spells (Moon-focused)
Spells.mist = {
    name = "Mist Veil",
    description = "Projectile block, grants AERIAL",
    castTime = 2.5,
    cost = {
        {type = "moon", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            block = "projectile"
        }
    end
}

Spells.gravity = {
    name = "Gravity Pin",
    description = "Traps AERIAL enemies",
    castTime = 3.5,
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
    castTime = 3.0,
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

return Spells```

## ./ui.lua
```lua
-- UI helper module

local UI = {}

function UI.drawHelpText(font)
    -- Set font and color
    love.graphics.setFont(font)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    
    -- Draw control help text
    local y = love.graphics.getHeight() - 120
    love.graphics.print("Controls:", 10, y)
    love.graphics.print("Player 1: Q/W/E to queue different spells", 20, y + 20)
    love.graphics.print("Player 2: I/O/P to queue different spells", 20, y + 40)
    love.graphics.print("Spells queue into the next available inner slot", 20, y + 60)
    love.graphics.print("T: Add more tokens to the mana pool (debug)", 20, y + 80)
    love.graphics.print("ESC: Quit", 20, y + 100)
end

function UI.drawSpellInfo(wizards)
    -- Function to format mana cost for display
    local function formatCost(cost)
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
    
    -- Function to display spell casting progress
    local function formatProgress(slot)
        return math.floor(slot.progress * 100 / slot.castTime) .. "%"
    end
    
    -- First wizard spells
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    
    -- Display Ashgar's spells with costs
    love.graphics.print("Q: " .. wizards[1].spellbook[1].name, 20, 80)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[1].spellbook[1].cost), 30, 95)
    
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    love.graphics.print("W: " .. wizards[1].spellbook[2].name, 20, 115)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[1].spellbook[2].cost), 30, 130)
    
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    love.graphics.print("E: " .. wizards[1].spellbook[3].name, 20, 150)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[1].spellbook[3].cost), 30, 165)
    
    -- Draw active spells in slots
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    love.graphics.print("Active spells:", 20, 190)
    for i, slot in ipairs(wizards[1].spellSlots) do
        if slot.active then
            love.graphics.print("Slot " .. i .. ": " .. slot.spellType .. " (" .. formatProgress(slot) .. ")", 30, 190 + i * 20)
        end
    end
    
    -- Second wizard spells
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    
    -- Display Selene's spells with costs
    local rightX = love.graphics.getWidth() - 230
    love.graphics.print("I: " .. wizards[2].spellbook[1].name, rightX, 80)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[2].spellbook[1].cost), rightX + 10, 95)
    
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    love.graphics.print("O: " .. wizards[2].spellbook[2].name, rightX, 115)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[2].spellbook[2].cost), rightX + 10, 130)
    
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    love.graphics.print("P: " .. wizards[2].spellbook[3].name, rightX, 150)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[2].spellbook[3].cost), rightX + 10, 165)
    
    -- Draw active spells in slots
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    love.graphics.print("Active spells:", rightX, 190)
    for i, slot in ipairs(wizards[2].spellSlots) do
        if slot.active then
            love.graphics.print("Slot " .. i .. ": " .. slot.spellType .. " (" .. formatProgress(slot) .. ")", rightX + 10, 190 + i * 20)
        end
    end
    
    -- Draw mana pool stats
    love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
    local poolX = love.graphics.getWidth() / 2 - 50
    love.graphics.print("Mana Pool:", poolX, 150)
    
    -- Count free tokens by type
    local counts = {fire = 0, force = 0, moon = 0, nature = 0, star = 0}
    for _, token in ipairs(wizards[1].manaPool.tokens) do
        if token.state == "FREE" then
            counts[token.type] = counts[token.type] + 1
        end
    end
    
    -- Display token counts
    love.graphics.print("Fire: " .. counts.fire, poolX, 170)
    love.graphics.print("Force: " .. counts.force, poolX, 185)
    love.graphics.print("Moon: " .. counts.moon, poolX, 200)
    love.graphics.print("Nature: " .. counts.nature, poolX, 215)
    love.graphics.print("Star: " .. counts.star, poolX, 230)
    
    -- Debug: Display total free/channeled tokens
    local free, channeled, locked = 0, 0, 0
    for _, token in ipairs(wizards[1].manaPool.tokens) do
        if token.state == "FREE" then free = free + 1
        elseif token.state == "CHANNELED" then channeled = channeled + 1
        elseif token.state == "LOCKED" then locked = locked + 1
        end
    end
    
    love.graphics.print("Free: " .. free .. ", Channeled: " .. channeled .. ", Locked: " .. locked, poolX - 30, 250)
end

return UI```

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
    self.position = "FAR"        -- FAR or NEAR
    self.elevation = "GROUNDED"  -- GROUNDED or AERIAL
    
    -- Spell loadout based on wizard name
    if name == "Ashgar" then
        self.spellbook = {
            [1] = Spells.firebolt, 
            [2] = Spells.meteor, 
            [3] = Spells.combust
        }
    elseif name == "Selene" then
        self.spellbook = {
            [1] = Spells.mist, 
            [2] = Spells.gravity, 
            [3] = Spells.eclipse
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
    -- Update spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            slot.progress = slot.progress + dt
            
            -- If spell finished casting
            if slot.progress >= slot.castTime then
                self:castSpell(i)
                
                -- Return tokens to pool
                if #slot.tokens > 0 then
                    for _, tokenData in ipairs(slot.tokens) do
                        self.manaPool:returnToken(tokenData.index)
                    end
                    
                    -- Clear token list
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
    -- Set color and draw wizard
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        self.sprite, 
        self.x, self.y, 
        0,  -- Rotation
        self.scale, self.scale,  -- Scale x, Scale y
        self.sprite:getWidth()/2, self.sprite:getHeight()/2  -- Origin at center
    )
    
    -- Draw wizard state indicators
    love.graphics.setColor(self.color[1]/255, self.color[2]/255, self.color[3]/255)
    love.graphics.print(self.position, self.x - 20, self.y + 40)
    love.graphics.print(self.elevation, self.x - 20, self.y + 60)
    
    -- Draw health bar
    local healthBarWidth = 50
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x - healthBarWidth/2, self.y - 50, healthBarWidth, 10)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", self.x - healthBarWidth/2, self.y - 50, healthBarWidth * (self.health/100), 10)
    
    -- Draw spell slots (orbits)
    self:drawSpellSlots()
end

function Wizard:drawSpellSlots()
    -- Draw 3 orbiting spell slots
    local orbitRadii = {70, 90, 110}  -- Different orbit distances
    
    for i, slot in ipairs(self.spellSlots) do
        -- Set orbit color based on active status
        if slot.active then
            love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Active slot
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.4)  -- Inactive slot
        end
        
        -- Draw orbit circle
        love.graphics.circle("line", self.x, self.y, orbitRadii[i])
        
        -- If slot is active, draw progress arc and spell name
        if slot.active then
            -- Calculate progress angle (0 to 2*pi)
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            -- Draw progress arc
            love.graphics.arc("line", "open", self.x, self.y, orbitRadii[i], 0, progressAngle)
            
            -- Draw spell name
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.print(slot.spellType, self.x - 20, self.y - orbitRadii[i] - 15)
            
            -- Draw channeled tokens orbiting in the spell slot
            if #slot.tokens > 0 then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    -- Calculate token position on the orbit
                    local tokenAngle = (j / #slot.tokens) * math.pi * 2 + progressAngle
                    local tokenX = self.x + math.cos(tokenAngle) * orbitRadii[i]
                    local tokenY = self.y + math.sin(tokenAngle) * orbitRadii[i]
                    
                    -- Draw token glow based on type
                    local glowSize = 8
                    local glowIntensity = 0.4
                    
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
                    
                    -- Draw token glow
                    love.graphics.circle("fill", tokenX, tokenY, glowSize)
                    
                    -- Draw token image
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(
                        token.image,
                        tokenX,
                        tokenY,
                        tokenAngle,  -- Rotate with orbit
                        0.8, 0.8,    -- Slightly smaller
                        token.image:getWidth()/2, token.image:getHeight()/2
                    )
                end
            end
        end
    end
end

function Wizard:queueSpell(spellKey)
    -- Get the spell from the spellbook
    local spell = self.spellbook[spellKey]
    if not spell then
        print("Spell not found in spellbook: " .. tostring(spellKey))
        return false
    end
    
    -- Find the innermost available spell slot
    for i = 1, #self.spellSlots do
        if not self.spellSlots[i].active then
            -- Check if we can pay the mana cost from the pool
            local tokens = self:payManaCost(spell.cost)
            
            if tokens then
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
    
    -- Apply damage
    if effect.damage and effect.damage > 0 then
        target.health = target.health - effect.damage
        if target.health < 0 then target.health = 0 end
        print(target.name .. " took " .. effect.damage .. " damage (health: " .. target.health .. ")")
    end
    
    -- Apply position/elevation changes
    if effect.setPosition then
        self.position = effect.setPosition
        print(self.name .. " moved to " .. self.position .. " position")
    end
    
    if effect.setElevation then
        self.elevation = effect.setElevation
        print(self.name .. " moved to " .. self.elevation .. " elevation")
    end
    
    -- Apply token lock
    if effect.lockToken and #target.manaPool.tokens > 0 then
        -- Find a random free token to lock
        local freeTokens = {}
        for i, token in ipairs(target.manaPool.tokens) do
            if token.state == "FREE" then
                table.insert(freeTokens, i)
            end
        end
        
        if #freeTokens > 0 then
            local tokenIndex = freeTokens[math.random(#freeTokens)]
            target.manaPool.tokens[tokenIndex].state = "LOCKED"
            print("Locked a token in " .. target.name .. "'s mana pool")
        end
    end
    
    -- Apply spell delay
    if effect.delaySpell and target.spellSlots[effect.delaySpell] and target.spellSlots[effect.delaySpell].active then
        -- Add 50% more time to the spell
        local slot = target.spellSlots[effect.delaySpell]
        local delayTime = slot.castTime * 0.5
        slot.castTime = slot.castTime + delayTime
        print("Delayed " .. target.name .. "'s spell in slot " .. effect.delaySpell .. " by " .. delayTime .. " seconds")
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
Generated: Tue Apr 15 10:28:37 CDT 2025

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

-- Game state
local game = {
    wizards = {},
    manaPool = nil,
    font = nil
}

function love.load()
    -- Set up window
    love.window.setTitle("Manastorm - Wizard Duel")
    love.window.setMode(800, 600)
    
    -- Load font
    game.font = love.graphics.newFont("assets/fonts/Lionscript-Regular.ttf", 16)
    love.graphics.setFont(game.font)
    
    -- Create mana pool
    game.manaPool = ManaPool.new(400, 200)
    
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

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    -- Player 1 (Ashgar) controls - Q, W, E keys for different spells
    if key == "q" then
        game.wizards[1]:queueSpell(1)  -- Firebolt
    elseif key == "w" then
        game.wizards[1]:queueSpell(2)  -- Meteor Dive
    elseif key == "e" then
        game.wizards[1]:queueSpell(3)  -- Combust Lock
    end
    
    -- Player 2 (Selene) controls - I, O, P keys for different spells
    if key == "i" then
        game.wizards[2]:queueSpell(1)  -- Mist Veil
    elseif key == "o" then
        game.wizards[2]:queueSpell(2)  -- Gravity Pin
    elseif key == "p" then
        game.wizards[2]:queueSpell(3)  -- Eclipse Echo
    end
    
    -- Debug: Add more tokens with T key
    if key == "t" then
        game.manaPool:addToken("fire", "assets/sprites/fire-token.png")
        game.manaPool:addToken("moon", "assets/sprites/moon-token.png")
        game.manaPool:addToken("force", "assets/sprites/force-token.png")
        print("Added more tokens to the mana pool")
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
    self.radius = 110  -- Area where tokens float
    self.innerRadius = 40  -- Inner radius where tokens can't go
    self.rotationSpeed = 0.3  -- Base rotation speed
    self.spiralTightness = 0.2  -- How tight the spiral is
    
    return self
end

function ManaPool:addToken(tokenType, imagePath)
    -- Calculate a random position in the pool area, but not too close to center
    local angle = math.random() * math.pi * 2
    local dist = math.random(self.innerRadius, self.radius)
    
    -- Define token valence rings (orbital paths)
    local valences = {
        self.innerRadius + 10,
        self.innerRadius + (self.radius - self.innerRadius) * 0.4,
        self.innerRadius + (self.radius - self.innerRadius) * 0.7,
        self.radius - 10
    }
    
    -- Pick a starting valence
    local valenceIndex = math.random(1, #valences)
    
    -- Create a new token with more dynamic properties
    local token = {
        type = tokenType,
        image = love.graphics.newImage(imagePath),
        x = self.x + math.cos(angle) * dist,
        y = self.y + math.sin(angle) * dist,
        state = "FREE",  -- FREE, CHANNELED, LOCKED, DESTROYED
        orbitAngle = angle,
        orbitDist = dist,
        -- More varying speeds, some much faster than others
        orbitSpeed = (0.5 + math.random() * 1.5) * self.rotationSpeed * (1 - (dist / self.radius) * self.spiralTightness),
        pulsePhase = math.random() * math.pi * 2,
        pulseSpeed = 2 + math.random() * 3,
        rotAngle = math.random() * math.pi * 2,
        rotSpeed = math.random(-2, 2) * 0.5, -- More varying rotations
        
        -- Valence properties
        valenceIndex = valenceIndex,
        valenceTarget = valences[valenceIndex],
        valenceJumpTimer = 2 + math.random() * 6, -- Time until next valence jump
        valenceJumpChance = 0.3, -- Chance to jump valences
        
        -- Occasional speed changes
        speedVariationTimer = 1 + math.random() * 3,
        originalSpeed = 0, -- Will be set after initialization
    }
    
    token.originalSpeed = token.orbitSpeed
    
    table.insert(self.tokens, token)
end

function ManaPool:update(dt)
    -- Define token valence rings (orbital paths) - must match the ones in addToken
    local valences = {
        self.innerRadius + 10,
        self.innerRadius + (self.radius - self.innerRadius) * 0.4,
        self.innerRadius + (self.radius - self.innerRadius) * 0.7,
        self.radius - 10
    }
    
    -- Update token positions and states
    for _, token in ipairs(self.tokens) do
        if token.state == "FREE" then
            -- Update orbit angle with variable speed
            token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt
            
            -- Update valence jump timer
            token.valenceJumpTimer = token.valenceJumpTimer - dt
            if token.valenceJumpTimer <= 0 then
                -- Reset timer
                token.valenceJumpTimer = 2 + math.random() * 6
                
                -- Random chance to jump to a different valence
                if math.random() <= token.valenceJumpChance then
                    -- Pick a new valence that's different from the current one
                    local newValenceIndex = token.valenceIndex
                    while newValenceIndex == token.valenceIndex do
                        newValenceIndex = math.random(1, #valences)
                    end
                    
                    token.valenceIndex = newValenceIndex
                    token.valenceTarget = valences[newValenceIndex]
                    
                    -- Speed up temporarily during transition
                    token.orbitSpeed = token.originalSpeed * (1.5 + math.random())
                end
            end
            
            -- Smoothly move toward target valence
            local distDiff = token.valenceTarget - token.orbitDist
            token.orbitDist = token.orbitDist + distDiff * dt * 1.5
            
            -- Add some wobble to the orbit
            token.orbitDist = token.orbitDist + math.sin(token.pulsePhase) * 2 * dt
            
            -- Keep within absolute bounds
            if token.orbitDist < self.innerRadius then
                token.orbitDist = self.innerRadius
            elseif token.orbitDist > self.radius then
                token.orbitDist = self.radius
            end
            
            -- Update pulse phase
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            
            -- Update speed variation timer
            token.speedVariationTimer = token.speedVariationTimer - dt
            if token.speedVariationTimer <= 0 then
                -- Reset timer
                token.speedVariationTimer = 1 + math.random() * 3
                
                -- Occasionally change speed
                if math.random() < 0.7 then
                    local speedFactor = 0.5 + math.random() * 1.5
                    token.orbitSpeed = token.originalSpeed * speedFactor
                else
                    -- Sometimes revert to original speed
                    token.orbitSpeed = token.originalSpeed
                end
            end
            
            -- Calculate new position based on orbit
            token.x = self.x + math.cos(token.orbitAngle) * token.orbitDist
            token.y = self.y + math.sin(token.orbitAngle) * token.orbitDist
            
            -- Rotate token itself for visual interest, occasionally reversing direction
            token.rotAngle = token.rotAngle + token.rotSpeed * dt
            if math.random() < 0.002 then  -- Small chance to reverse rotation
                token.rotSpeed = -token.rotSpeed
            end
        end
    end
end

function ManaPool:draw()
    -- Draw pool background with a subtle gradient effect
    love.graphics.setColor(0.15, 0.15, 0.25, 0.2)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- Inner circle with slightly different color
    love.graphics.setColor(0.2, 0.2, 0.35, 0.3)
    love.graphics.circle("fill", self.x, self.y, self.innerRadius)
    
    -- Outer border (subtle)
    love.graphics.setColor(0.25, 0.25, 0.4, 0.3)
    love.graphics.circle("line", self.x, self.y, self.radius)
    
    -- Inner border (subtle)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
    love.graphics.circle("line", self.x, self.y, self.innerRadius)
    
    -- Draw tokens
    for _, token in ipairs(self.tokens) do
        -- Draw a subtle glow around the token based on its type
        local glowSize = 10
        local glowIntensity = 0.3
        
        -- Set glow color based on token type
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
        
        -- Draw glow
        love.graphics.circle("fill", token.x, token.y, glowSize * (0.7 + 0.3 * math.sin(token.pulsePhase * 0.5)))
        
        -- Draw token image
        if token.state == "FREE" then
            love.graphics.setColor(1, 1, 1, 1)  -- FREE tokens are fully visible
        elseif token.state == "LOCKED" then
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)  -- LOCKED tokens are faded
        end
        
        love.graphics.draw(
            token.image, 
            token.x, 
            token.y, 
            token.rotAngle,  -- Use the rotation angle
            1, 1,  -- Scale
            token.image:getWidth()/2, token.image:getHeight()/2  -- Origin at center
        )
    end
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
        token.state = "FREE"
        
        -- Define token valence rings (orbital paths) - must match the ones in addToken and update
        local valences = {
            self.innerRadius + 10,
            self.innerRadius + (self.radius - self.innerRadius) * 0.4,
            self.innerRadius + (self.radius - self.innerRadius) * 0.7,
            self.radius - 10
        }
        
        -- Pick a random valence
        local valenceIndex = math.random(1, #valences)
        token.valenceIndex = valenceIndex
        token.valenceTarget = valences[valenceIndex]
        
        -- Reset position to pool center
        token.x = self.x
        token.y = self.y
        
        -- Set a random orbit angle and distance
        token.orbitAngle = math.random() * math.pi * 2
        token.orbitDist = self.innerRadius + (self.radius - self.innerRadius) * 0.5
        
        -- Temporarily boost speed for dramatic return
        token.orbitSpeed = token.originalSpeed * 2
        token.speedVariationTimer = 1 + math.random() * 2
        
        -- Reset timers with some randomness
        token.valenceJumpTimer = 2 + math.random() * 4
    end
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
Spells.firebolt = {
    name = "Firebolt",
    description = "Quick ranged hit, more damage at FAR range",
    castTime = 2.5,  -- seconds
    cost = {
        {type = "fire", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        -- Will implement actual effects later
        local damage = 10
        if target.position == "FAR" then damage = 15 end
        return {
            damage = damage,
            type = "fire"
        }
    end
}

Spells.meteor = {
    name = "Meteor Dive",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = 4.0,
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
    castTime = 3.0,
    cost = {
        {type = "fire", count = 1},
        {type = "force", count = 1}
    },
    effect = function(caster, target)
        return {
            lockToken = true,
            damage = target.spellSlotsActive * 3  -- More damage if target has many active spells
        }
    end
}

-- Selene's Spells (Moon-focused)
Spells.mist = {
    name = "Mist Veil",
    description = "Projectile block, grants AERIAL",
    castTime = 2.5,
    cost = {
        {type = "moon", count = 1},
        {type = "any", count = 1}
    },
    effect = function(caster, target)
        return {
            setElevation = "AERIAL",
            block = "projectile"
        }
    end
}

Spells.gravity = {
    name = "Gravity Pin",
    description = "Traps AERIAL enemies",
    castTime = 3.5,
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
    castTime = 3.0,
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

return Spells```

## ./ui.lua
```lua
-- UI helper module

local UI = {}

function UI.drawHelpText(font)
    -- Set font and color
    love.graphics.setFont(font)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    
    -- Draw control help text
    local y = love.graphics.getHeight() - 120
    love.graphics.print("Controls:", 10, y)
    love.graphics.print("Player 1: Q/W/E to queue different spells", 20, y + 20)
    love.graphics.print("Player 2: I/O/P to queue different spells", 20, y + 40)
    love.graphics.print("Spells queue into the next available inner slot", 20, y + 60)
    love.graphics.print("T: Add more tokens to the mana pool (debug)", 20, y + 80)
    love.graphics.print("ESC: Quit", 20, y + 100)
end

function UI.drawSpellInfo(wizards)
    -- Function to format mana cost for display
    local function formatCost(cost)
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
    
    -- Function to display spell casting progress
    local function formatProgress(slot)
        return math.floor(slot.progress * 100 / slot.castTime) .. "%"
    end
    
    -- First wizard spells
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    
    -- Display Ashgar's spells with costs
    love.graphics.print("Q: " .. wizards[1].spellbook[1].name, 20, 80)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[1].spellbook[1].cost), 30, 95)
    
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    love.graphics.print("W: " .. wizards[1].spellbook[2].name, 20, 115)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[1].spellbook[2].cost), 30, 130)
    
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    love.graphics.print("E: " .. wizards[1].spellbook[3].name, 20, 150)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[1].spellbook[3].cost), 30, 165)
    
    -- Draw active spells in slots
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    love.graphics.print("Active spells:", 20, 190)
    for i, slot in ipairs(wizards[1].spellSlots) do
        if slot.active then
            love.graphics.print("Slot " .. i .. ": " .. slot.spellType .. " (" .. formatProgress(slot) .. ")", 30, 190 + i * 20)
        end
    end
    
    -- Second wizard spells
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    
    -- Display Selene's spells with costs
    local rightX = love.graphics.getWidth() - 230
    love.graphics.print("I: " .. wizards[2].spellbook[1].name, rightX, 80)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[2].spellbook[1].cost), rightX + 10, 95)
    
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    love.graphics.print("O: " .. wizards[2].spellbook[2].name, rightX, 115)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[2].spellbook[2].cost), rightX + 10, 130)
    
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    love.graphics.print("P: " .. wizards[2].spellbook[3].name, rightX, 150)
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("Cost: " .. formatCost(wizards[2].spellbook[3].cost), rightX + 10, 165)
    
    -- Draw active spells in slots
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    love.graphics.print("Active spells:", rightX, 190)
    for i, slot in ipairs(wizards[2].spellSlots) do
        if slot.active then
            love.graphics.print("Slot " .. i .. ": " .. slot.spellType .. " (" .. formatProgress(slot) .. ")", rightX + 10, 190 + i * 20)
        end
    end
    
    -- Draw mana pool stats
    love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
    local poolX = love.graphics.getWidth() / 2 - 50
    love.graphics.print("Mana Pool:", poolX, 150)
    
    -- Count free tokens by type
    local counts = {fire = 0, force = 0, moon = 0, nature = 0, star = 0}
    for _, token in ipairs(wizards[1].manaPool.tokens) do
        if token.state == "FREE" then
            counts[token.type] = counts[token.type] + 1
        end
    end
    
    -- Display token counts
    love.graphics.print("Fire: " .. counts.fire, poolX, 170)
    love.graphics.print("Force: " .. counts.force, poolX, 185)
    love.graphics.print("Moon: " .. counts.moon, poolX, 200)
    love.graphics.print("Nature: " .. counts.nature, poolX, 215)
    love.graphics.print("Star: " .. counts.star, poolX, 230)
    
    -- Debug: Display total free/channeled tokens
    local free, channeled, locked = 0, 0, 0
    for _, token in ipairs(wizards[1].manaPool.tokens) do
        if token.state == "FREE" then free = free + 1
        elseif token.state == "CHANNELED" then channeled = channeled + 1
        elseif token.state == "LOCKED" then locked = locked + 1
        end
    end
    
    love.graphics.print("Free: " .. free .. ", Channeled: " .. channeled .. ", Locked: " .. locked, poolX - 30, 250)
end

return UI```

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
    self.position = "FAR"        -- FAR or NEAR
    self.elevation = "GROUNDED"  -- GROUNDED or AERIAL
    
    -- Spell loadout based on wizard name
    if name == "Ashgar" then
        self.spellbook = {
            [1] = Spells.firebolt, 
            [2] = Spells.meteor, 
            [3] = Spells.combust
        }
    elseif name == "Selene" then
        self.spellbook = {
            [1] = Spells.mist, 
            [2] = Spells.gravity, 
            [3] = Spells.eclipse
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
    -- Update spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            slot.progress = slot.progress + dt
            
            -- If spell finished casting
            if slot.progress >= slot.castTime then
                self:castSpell(i)
                
                -- Return tokens to pool
                if #slot.tokens > 0 then
                    for _, tokenData in ipairs(slot.tokens) do
                        self.manaPool:returnToken(tokenData.index)
                    end
                    
                    -- Clear token list
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
    -- Set color and draw wizard
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        self.sprite, 
        self.x, self.y, 
        0,  -- Rotation
        self.scale, self.scale,  -- Scale x, Scale y
        self.sprite:getWidth()/2, self.sprite:getHeight()/2  -- Origin at center
    )
    
    -- Draw wizard state indicators
    love.graphics.setColor(self.color[1]/255, self.color[2]/255, self.color[3]/255)
    love.graphics.print(self.position, self.x - 20, self.y + 40)
    love.graphics.print(self.elevation, self.x - 20, self.y + 60)
    
    -- Draw health bar
    local healthBarWidth = 50
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x - healthBarWidth/2, self.y - 50, healthBarWidth, 10)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", self.x - healthBarWidth/2, self.y - 50, healthBarWidth * (self.health/100), 10)
    
    -- Draw spell slots (orbits)
    self:drawSpellSlots()
end

function Wizard:drawSpellSlots()
    -- Draw 3 orbiting spell slots
    local orbitRadii = {70, 90, 110}  -- Different orbit distances
    
    for i, slot in ipairs(self.spellSlots) do
        -- Set orbit color based on active status
        if slot.active then
            love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Active slot
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.4)  -- Inactive slot
        end
        
        -- Draw orbit circle
        love.graphics.circle("line", self.x, self.y, orbitRadii[i])
        
        -- If slot is active, draw progress arc and spell name
        if slot.active then
            -- Calculate progress angle (0 to 2*pi)
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            -- Draw progress arc
            love.graphics.arc("line", "open", self.x, self.y, orbitRadii[i], 0, progressAngle)
            
            -- Draw spell name
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.print(slot.spellType, self.x - 20, self.y - orbitRadii[i] - 15)
            
            -- Draw channeled tokens orbiting in the spell slot
            if #slot.tokens > 0 then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    -- Calculate token position on the orbit
                    local tokenAngle = (j / #slot.tokens) * math.pi * 2 + progressAngle
                    local tokenX = self.x + math.cos(tokenAngle) * orbitRadii[i]
                    local tokenY = self.y + math.sin(tokenAngle) * orbitRadii[i]
                    
                    -- Draw token glow based on type
                    local glowSize = 8
                    local glowIntensity = 0.4
                    
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
                    
                    -- Draw token glow
                    love.graphics.circle("fill", tokenX, tokenY, glowSize)
                    
                    -- Draw token image
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(
                        token.image,
                        tokenX,
                        tokenY,
                        tokenAngle,  -- Rotate with orbit
                        0.8, 0.8,    -- Slightly smaller
                        token.image:getWidth()/2, token.image:getHeight()/2
                    )
                end
            end
        end
    end
end

function Wizard:queueSpell(spellKey)
    -- Get the spell from the spellbook
    local spell = self.spellbook[spellKey]
    if not spell then
        print("Spell not found in spellbook: " .. tostring(spellKey))
        return false
    end
    
    -- Find the innermost available spell slot
    for i = 1, #self.spellSlots do
        if not self.spellSlots[i].active then
            -- Check if we can pay the mana cost from the pool
            local tokens = self:payManaCost(spell.cost)
            
            if tokens then
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
    
    -- Apply damage
    if effect.damage and effect.damage > 0 then
        target.health = target.health - effect.damage
        if target.health < 0 then target.health = 0 end
        print(target.name .. " took " .. effect.damage .. " damage (health: " .. target.health .. ")")
    end
    
    -- Apply position/elevation changes
    if effect.setPosition then
        self.position = effect.setPosition
        print(self.name .. " moved to " .. self.position .. " position")
    end
    
    if effect.setElevation then
        self.elevation = effect.setElevation
        print(self.name .. " moved to " .. self.elevation .. " elevation")
    end
    
    -- Apply token lock
    if effect.lockToken and #target.manaPool.tokens > 0 then
        -- Find a random free token to lock
        local freeTokens = {}
        for i, token in ipairs(target.manaPool.tokens) do
            if token.state == "FREE" then
                table.insert(freeTokens, i)
            end
        end
        
        if #freeTokens > 0 then
            local tokenIndex = freeTokens[math.random(#freeTokens)]
            target.manaPool.tokens[tokenIndex].state = "LOCKED"
            print("Locked a token in " .. target.name .. "'s mana pool")
        end
    end
    
    -- Apply spell delay
    if effect.delaySpell and target.spellSlots[effect.delaySpell] and target.spellSlots[effect.delaySpell].active then
        -- Add 50% more time to the spell
        local slot = target.spellSlots[effect.delaySpell]
        local delayTime = slot.castTime * 0.5
        slot.castTime = slot.castTime + delayTime
        print("Delayed " .. target.name .. "'s spell in slot " .. effect.delaySpell .. " by " .. delayTime .. " seconds")
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

