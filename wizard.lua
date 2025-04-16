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
    self.elevationTimer = 0      -- Timer for temporary elevation changes
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
    
    -- Update elevation timer
    if self.elevationTimer > 0 and self.elevation == "AERIAL" then
        self.elevationTimer = math.max(0, self.elevationTimer - dt)
        if self.elevationTimer == 0 then
            self.elevation = "GROUNDED"
            print(self.name .. " returned to GROUNDED elevation")
            
            -- Create landing effect using VFX system
            if self.gameState and self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", self.x, self.y + 30, nil, nil, {
                    duration = 0.5,
                    color = {0.7, 0.7, 0.7, 0.8},
                    particleCount = 8,
                    radius = 20
                })
            end
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
        
        -- No visual timer display here - moved to drawStatusEffects function
    end
    
    -- No longer drawing text elevation indicator - using visual representation only
    
    -- Draw subtle shield aura for projectile blocker (visual only, no timer)
    if self.blockers.projectile > 0 then
        local shieldRadius = 60
        local pulseAmount = 5 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.5, 0.5, 1, 0.15)
        love.graphics.circle("fill", self.x, self.y, shieldRadius + pulseAmount)
        love.graphics.setColor(0.7, 0.7, 1, 0.2)
        love.graphics.circle("line", self.x, self.y, shieldRadius + pulseAmount)
    end
    
    -- Draw status effects with durations using the new horizontal bar system
    self:drawStatusEffects()
    
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

-- Draw status effects with durations using horizontal bars
function Wizard:drawStatusEffects()
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Properties for status effect bars
    local barWidth = 130
    local barHeight = 12
    local barSpacing = 18
    local barPadding = 15  -- Additional padding between effect bars
    
    -- Position status bars above the spellbook area
    local baseY = screenHeight - 150  -- Higher up from the spellbook
    local effectCount = 0
    
    -- Determine x position based on which wizard this is
    local x = (self.name == "Ashgar") and 150 or (screenWidth - 150)
    
    -- Define colors for different effect types
    local effectColors = {
        aerial = {0.7, 0.7, 1.0, 0.8},
        stun = {1.0, 1.0, 0.1, 0.8},
        shield = {0.5, 0.7, 1.0, 0.8}
    }
    
    -- Draw AERIAL duration if active
    if self.elevation == "AERIAL" and self.elevationTimer > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress (1.0 to 0.0 as time depletes)
        local maxDuration = 5.0  -- Assuming 5 seconds is max aerial duration
        local progress = self.elevationTimer / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label
        love.graphics.setColor(effectColors.aerial[1], effectColors.aerial[2], effectColors.aerial[3], 
                              effectColors.aerial[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 4)))
        love.graphics.print("AERIAL", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.aerial)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.aerial[1], effectColors.aerial[2], effectColors.aerial[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time text
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs", self.elevationTimer), 
                           x + barWidth/2 - 30, y)
    end
    
    -- Draw STUN duration if active
    if self.stunTimer > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress
        local maxDuration = 2.0  -- Assuming 2 seconds is max stun duration
        local progress = self.stunTimer / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label
        love.graphics.setColor(effectColors.stun[1], effectColors.stun[2], effectColors.stun[3], 
                              effectColors.stun[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 5)))
        love.graphics.print("STUNNED", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.stun)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.stun[1], effectColors.stun[2], effectColors.stun[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time text
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs", self.stunTimer), 
                           x + barWidth/2 - 30, y)
    end
    
    -- Draw SHIELD duration if active
    if self.blockers.projectile > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress
        local maxDuration = 5.0  -- Assuming 5 seconds is max shield duration
        local progress = self.blockers.projectile / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label
        love.graphics.setColor(effectColors.shield[1], effectColors.shield[2], effectColors.shield[3], 
                              effectColors.shield[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 3)))
        love.graphics.print("SHIELD", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.shield)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.shield[1], effectColors.shield[2], effectColors.shield[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time text
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs", self.blockers.projectile), 
                           x + barWidth/2 - 30, y)
    end
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
    local reservedIndices = {} -- Track which token indices are already reserved
    
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
                -- Try to get tokens of this type (that aren't already reserved)
                local availableTokens = {}
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.type == modalType and token.state == "FREE" and not reservedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                if #availableTokens >= costCount then
                    -- We have enough tokens to pay this cost
                    for i = 1, costCount do
                        local tokenData = availableTokens[i]
                        table.insert(tokenReservations, tokenData)
                        reservedIndices[tokenData.index] = true -- Mark as reserved
                    end
                    paid = true
                    break
                end
            end
            
            if not paid then
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available token types that aren't already reserved
                local availableTokens = {}
                
                -- Check each token and gather available ones that haven't been reserved yet
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.state == "FREE" and not reservedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTokens > 0 then
                    -- Shuffle the available tokens for true randomness
                    for i = #availableTokens, 2, -1 do
                        local j = math.random(i)
                        availableTokens[i], availableTokens[j] = availableTokens[j], availableTokens[i]
                    end
                    
                    -- Use the first token after shuffling
                    local tokenData = availableTokens[1]
                    table.insert(tokenReservations, tokenData)
                    reservedIndices[tokenData.index] = true -- Mark as reserved
                else
                    return nil
                end
            end
        else
            -- Specific type cost
            -- Get all the free tokens of this type first
            local availableTokens = {}
            for i, token in ipairs(self.manaPool.tokens) do
                if token.type == costType and token.state == "FREE" then
                    table.insert(availableTokens, {token = token, index = i})
                end
            end
            
            -- Check if we have enough tokens
            if #availableTokens < costCount then
                return nil  -- Not enough tokens of this type
            end
            
            -- Add the required number of tokens to our reservations
            for i = 1, costCount do
                table.insert(tokenReservations, availableTokens[i])
            end
        end
    end
    
    return tokenReservations
end

-- Helper function to check and pay mana costs
function Wizard:payManaCost(cost)
    local tokens = {}
    local usedIndices = {} -- Track which token indices are already used
    
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType = costComponent.type
        local costCount = costComponent.count
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Collect all available tokens of this type that haven't been used yet
                local availableTokens = {}
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.type == modalType and token.state == "FREE" and not usedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                if #availableTokens >= costCount then
                    -- We have enough tokens to pay this cost
                    for i = 1, costCount do
                        local tokenData = availableTokens[i]
                        local token = self.manaPool.tokens[tokenData.index]
                        token.state = "CHANNELED" -- Mark as being used
                        table.insert(tokens, {token = token, index = tokenData.index})
                        usedIndices[tokenData.index] = true -- Mark as used
                    end
                    paid = true
                    break
                end
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
                -- Collect all available tokens that haven't been used yet
                local availableTokens = {}
                
                -- Check each token and gather available ones
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.state == "FREE" and not usedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTokens > 0 then
                    -- Shuffle the available tokens for true randomness
                    for i = #availableTokens, 2, -1 do
                        local j = math.random(i)
                        availableTokens[i], availableTokens[j] = availableTokens[j], availableTokens[i]
                    end
                    
                    -- Use the first token after shuffling
                    local tokenData = availableTokens[1]
                    local token = self.manaPool.tokens[tokenData.index]
                    token.state = "CHANNELED" -- Mark as being used
                    table.insert(tokens, {token = token, index = tokenData.index})
                    usedIndices[tokenData.index] = true -- Mark as used
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
            -- First gather all available tokens of this type
            local availableTokens = {}
            for i, token in ipairs(self.manaPool.tokens) do
                if token.type == costType and token.state == "FREE" then
                    table.insert(availableTokens, {token = token, index = i})
                end
            end
            
            -- Check if we have enough tokens
            if #availableTokens < costCount then
                -- Failed to find enough tokens, return any collected tokens to pool
                for _, tokenData in ipairs(tokens) do
                    self.manaPool:returnToken(tokenData.index)
                end
                return nil
            end
            
            -- Get the required number of tokens and mark them as CHANNELED
            for i = 1, costCount do
                local tokenData = availableTokens[i]
                local token = self.manaPool.tokens[tokenData.index]
                token.state = "CHANNELED"  -- Mark as being used
                table.insert(tokens, {token = token, index = tokenData.index})
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
        
        -- Set duration for elevation change if provided
        if effect.elevationDuration and effect.setElevation == "AERIAL" then
            self.elevationTimer = effect.elevationDuration
            print(self.name .. " moved to " .. self.elevation .. " elevation for " .. effect.elevationDuration .. " seconds")
        else
            -- No duration specified, treat as permanent until changed by another spell
            self.elevationTimer = 0
            print(self.name .. " moved to " .. self.elevation .. " elevation")
        end
        
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

return Wizard