-- Wizard class

local Wizard = {}
Wizard.__index = Wizard

-- Load spells module with the new keyword system
local SpellsModule = require("spells")
local Spells = SpellsModule.spells  -- For backwards compatibility

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
    
    -- Status effects
    self.statusEffects = {
        burn = {
            active = false,
            duration = 0,
            tickDamage = 0,
            tickInterval = 1.0,
            elapsed = 0,         -- Time since last tick
            totalTime = 0        -- Total time effect has been active
        }
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
            ["12"] = Spells.eruption,      -- Zone spell with range anchoring 
            ["13"] = Spells.combust, -- Mana denial spell
            ["23"] = Spells.emberlift,     -- Movement spell
            ["123"] = Spells.meteor  -- Zone dependent nuke
        }
    elseif name == "Selene" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjuremoonlight,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.mist,
            
            -- Multi-key combinations
            ["12"] = Spells.tidalforce,     -- Chip damage Remote spell that forces out of AERIAL
            ["13"] = Spells.eclipse,
            ["23"] = Spells.lunardisjunction, -- 
            ["123"] = Spells.fullmoonbeam -- Full Moon Beam spell
        }
    end
    
    -- Verify that all spells in the spellbook are properly defined
    for key, spell in pairs(self.spellbook) do
        if not spell then
            print("WARNING: Spell for key combo '" .. key .. "' is nil for " .. name)
        elseif not spell.cost then
            print("WARNING: Spell '" .. (spell.name or "unnamed") .. "' for key combo '" .. key .. "' has no cost defined")
        else
            -- Ensure spell has an ID
            if not spell.id and spell.name then
                spell.id = spell.name:lower():gsub(" ", "")
                print("DEBUG: Added missing ID for spell: " .. spell.name .. " -> " .. spell.id)
            end
            
            -- Detailed debug output for detecting reference issues
            print("DEBUG: Spell reference check for key combo '" .. key .. "':")
            print("DEBUG: - Name: " .. (spell.name or "unnamed"))
            print("DEBUG: - ID: " .. (spell.id or "no id"))
            print("DEBUG: - Cost: " .. (type(spell.cost) == "table" and "table of length " .. #spell.cost or tostring(spell.cost)))
        end
    end
    
    -- Spell slots (3 max)
    self.spellSlots = {}
    for i = 1, 3 do
        self.spellSlots[i] = {
            active = false,
            progress = 0,
            spellType = nil,
            castTime = 0,
            tokens = {},  -- Will hold channeled mana tokens
            
            -- Shield-specific properties
            isShield = false,
            defenseType = nil,  -- "barrier", "ward", or "field"
            shieldStrength = 0, -- How many hits the shield can take
            blocksAttackTypes = nil  -- Table of attack types this shield blocks
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
    
    -- Update burn status effect
    if self.statusEffects.burn.active then
        -- Update total time
        self.statusEffects.burn.totalTime = self.statusEffects.burn.totalTime + dt
        
        -- Update elapsed time since last tick
        self.statusEffects.burn.elapsed = self.statusEffects.burn.elapsed + dt
        
        -- Check if it's time for damage tick
        if self.statusEffects.burn.elapsed >= self.statusEffects.burn.tickInterval then
            -- Apply burn damage
            local damage = self.statusEffects.burn.tickDamage
            self.health = math.max(0, self.health - damage)
            
            -- Reset elapsed time
            self.statusEffects.burn.elapsed = 0
            
            -- Log damage
            print(string.format("[BURN] %s takes %d burn damage! (health: %d)", 
                self.name, damage, self.health))
            
            -- Create burn effect using VFX system
            if self.gameState and self.gameState.vfx then
                -- Random position around the wizard for the burn effect
                local angle = math.random() * math.pi * 2
                local distance = math.random(10, 30)
                local effectX = self.x + math.cos(angle) * distance
                local effectY = self.y + math.sin(angle) * distance
                
                self.gameState.vfx.createEffect("impact", effectX, effectY, nil, nil, {
                    duration = 0.3,
                    color = {1.0, 0.4, 0.1, 0.6},
                    particleCount = 3,
                    radius = 10
                })
            end
        end
        
        -- Check if the effect has expired
        if self.statusEffects.burn.totalTime >= self.statusEffects.burn.duration then
            -- Deactivate the effect
            self.statusEffects.burn.active = false
            print(string.format("[STATUS] %s is no longer burning", self.name))
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
            -- If the slot is an active shield, just keep it active, and add
            -- shield pulsing effects if needed
            if slot.isShield and slot.progress >= slot.castTime then
                -- For active shields, make tokens orbit their slots
                -- Calculate positions for all tokens in this shield
                local slotYOffsets = {30, 0, -30}
                -- Apply AERIAL offset to shield tokens
                local yOffset = self.currentYOffset or 0
                local slotY = self.y + slotYOffsets[i] + yOffset
                -- Define orbit radii for each slot (same values used in drawSpellSlots)
                local horizontalRadii = {80, 70, 60}  -- Wider at the bottom, narrower at the top  
                local verticalRadii = {20, 25, 30}    -- Flatter at the bottom, rounder at the top
                local radiusX = horizontalRadii[i]
                local radiusY = verticalRadii[i]
                
                -- Move all tokens in a slow orbit
                if #slot.tokens > 0 then
                    -- Make tokens orbit slowly
                    local baseAngle = love.timer.getTime() * 0.3  -- Slow steady rotation
                    local tokenCount = #slot.tokens
                    
                    for j, tokenData in ipairs(slot.tokens) do
                        local token = tokenData.token
                        -- Position tokens evenly around the orbit
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = baseAngle + anglePerToken * (j - 1)
                        
                        -- Calculate 3D position with elliptical projection
                        -- Apply NEAR/FAR positioning offset for tokens as well
                        local xOffset = 0
                        local isNear = self.gameState and self.gameState.rangeState == "NEAR"
                        
                        -- Push wizards closer to center in NEAR mode, further in FAR mode
                        if self.name == "Ashgar" then -- Player 1 (left side)
                            xOffset = isNear and 60 or 0 -- Move right when NEAR
                        else -- Player 2 (right side)
                            xOffset = isNear and -60 or 0 -- Move left when NEAR
                        end
                        
                        token.x = self.x + xOffset + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Update token rotation angle too (spin on its axis)
                        token.rotAngle = token.rotAngle + 0.01  -- Slow spin
                    end
                end
                
                -- Occasionally add subtle visual effects
                if math.random() < 0.01 and self.gameState and self.gameState.vfx then
                    local angle = math.random() * math.pi * 2
                    local radius = math.random(30, 40)
                    
                    -- Apply NEAR/FAR offset to sparkle effects as well
                    local xOffset = 0
                    local isNear = self.gameState and self.gameState.rangeState == "NEAR"
                    
                    -- Push wizards closer to center in NEAR mode, further in FAR mode
                    if self.name == "Ashgar" then -- Player 1 (left side)
                        xOffset = isNear and 60 or 0 -- Move right when NEAR
                    else -- Player 2 (right side)
                        xOffset = isNear and -60 or 0 -- Move left when NEAR
                    end
                    
                    local sparkleX = self.x + xOffset + math.cos(angle) * radius
                    local sparkleY = slotY + math.sin(angle) * radius
                    
                    -- Color based on shield type
                    local effectColor = {0.7, 0.7, 0.7, 0.5}  -- Default gray
                    if slot.defenseType == "barrier" then
                        effectColor = {1.0, 1.0, 0.3, 0.5}  -- Yellow for barriers
                    elseif slot.defenseType == "ward" then
                        effectColor = {0.3, 0.3, 1.0, 0.5}  -- Blue for wards
                    elseif slot.defenseType == "field" then
                        effectColor = {0.3, 1.0, 0.3, 0.5}  -- Green for fields
                    end
                    
                    self.gameState.vfx.createEffect("impact", sparkleX, sparkleY, nil, nil, {
                        duration = 0.3,
                        color = effectColor,
                        particleCount = 2,
                        radius = 5
                    })
                end
                
                -- Continue to next spell slot
                goto continue_next_slot
            end
            
            -- Check if the spell is frozen (by Eclipse Echo)
            if slot.frozen then
                -- Update freeze timer
                slot.freezeTimer = slot.freezeTimer - dt
                
                -- Check if the freeze duration has elapsed
                if slot.freezeTimer <= 0 then
                    -- Unfreeze the spell
                    slot.frozen = false
                    print(self.name .. "'s spell in slot " .. i .. " is no longer frozen")
                    
                    -- Add a visual "unfreeze" effect
                    if self.gameState and self.gameState.vfx then
                        local slotYOffsets = {30, 0, -30}
                        local slotY = self.y + slotYOffsets[i]
                        
                        self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                            duration = 0.5,
                            color = {0.7, 0.7, 1.0, 0.6},
                            particleCount = 10,
                            radius = 35
                        })
                    end
                else
                    -- Spell is still frozen, don't increment progress
                    -- Visual progress arc will appear frozen in place
                    
                    -- Add a subtle frozen visual effect if we have VFX
                    if math.random() < 0.03 and self.gameState and self.gameState.vfx then -- Occasional sparkle
                        local slotYOffsets = {30, 0, -30}
                        local slotY = self.y + slotYOffsets[i]
                        local angle = math.random() * math.pi * 2
                        local radius = math.random(30, 40)
                        local sparkleX = self.x + math.cos(angle) * radius
                        local sparkleY = slotY + math.sin(angle) * radius
                        
                        self.gameState.vfx.createEffect("impact", sparkleX, sparkleY, nil, nil, {
                            duration = 0.3,
                            color = {0.6, 0.6, 1.0, 0.5},
                            particleCount = 3,
                            radius = 5
                        })
                    end
                end
            else
                -- Normal progress update for unfrozen spells
                slot.progress = slot.progress + dt
            end
            
            -- If spell finished casting
            if slot.progress >= slot.castTime then
                -- Cast the spell
                self:castSpell(i)
                
                -- For non-shield spells, we return tokens and reset the slot
                -- For shield spells, castSpell will handle setting up the shield 
                -- and we won't get here because we'll have the isShield check above
                if not slot.isShield then
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
            
            ::continue_next_slot::
        end
    end
end

function Wizard:draw()
    -- Calculate position adjustments based on elevation and range state
    local yOffset = 0
    local xOffset = 0
    
    -- Vertical adjustment for AERIAL state - increased for more dramatic effect
    if self.elevation == "AERIAL" then
        yOffset = -50  -- Lift the wizard up more significantly when AERIAL
    end
    
    -- Horizontal adjustment for NEAR/FAR state
    local isNear = self.gameState and self.gameState.rangeState == "NEAR"
    local centerX = love.graphics.getWidth() / 2
    
    -- Push wizards closer to center in NEAR mode, further in FAR mode
    if self.name == "Ashgar" then -- Player 1 (left side)
        xOffset = isNear and 60 or 0 -- Move right when NEAR
    else -- Player 2 (right side)
        xOffset = isNear and -60 or 0 -- Move left when NEAR
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
        -- Draw ground indicator below wizard, applying the x offset
        love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        love.graphics.ellipse("fill", self.x + xOffset, self.y + 30, 40, 10)  -- Simple shadow/ground indicator
    end
    
    -- Store current offsets for other functions to use
    self.currentXOffset = xOffset
    self.currentYOffset = yOffset
    
    -- Draw the wizard with appropriate elevation and position
    love.graphics.setColor(1, 1, 1)
    
    -- Flip Selene's sprite horizontally if she's player 2
    local scaleX = self.scale
    if self.name == "Selene" then
        -- Mirror the sprite by using negative scale for the second player
        scaleX = -self.scale
    end
    
    love.graphics.draw(
        self.sprite, 
        self.x + xOffset, self.y + yOffset,  -- Apply both offsets
        0,  -- Rotation
        scaleX, self.scale,  -- Scale x, Scale y (negative x scale for Selene)
        self.sprite:getWidth()/2, self.sprite:getHeight()/2  -- Origin at center
    )
    
    -- Draw aerial effect if applicable
    if self.elevation == "AERIAL" then
        -- Draw aerial effect (clouds, wind lines, etc.)
        love.graphics.setColor(0.8, 0.8, 1, 0.3)
        
        -- Draw cloud-like puffs, applying the xOffset
        for i = 1, 3 do
            local cloudXOffset = math.sin(love.timer.getTime() * 1.5 + i) * 8
            local cloudY = self.y + yOffset + 40 + math.sin(love.timer.getTime() + i) * 3
            love.graphics.circle("fill", self.x + xOffset - 15 + cloudXOffset, cloudY, 8)
            love.graphics.circle("fill", self.x + xOffset + cloudXOffset, cloudY, 10)
            love.graphics.circle("fill", self.x + xOffset + 15 + cloudXOffset, cloudY, 8)
        end
        
        -- No visual timer display here - moved to drawStatusEffects function
    end
    
    -- No longer drawing text elevation indicator - using visual representation only
    
    -- Draw subtle shield aura for projectile blocker (visual only, no timer)
    if self.blockers.projectile > 0 then
        local shieldRadius = 60
        local pulseAmount = 5 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.5, 0.5, 1, 0.15)
        love.graphics.circle("fill", self.x + xOffset, self.y, shieldRadius + pulseAmount)
        love.graphics.setColor(0.7, 0.7, 1, 0.2)
        love.graphics.circle("line", self.x + xOffset, self.y, shieldRadius + pulseAmount)
    end
    
    -- Draw status effects with durations using the new horizontal bar system
    self:drawStatusEffects()
    
    -- Draw block effect when projectile is blocked
    if self.blockVFX.active then
        -- Draw block flash animation
        local progress = self.blockVFX.timer / 0.5  -- Normalize to 0-1
        local size = 80 * (1 - progress)
        love.graphics.setColor(0.7, 0.7, 1, progress * 0.8)
        love.graphics.circle("fill", self.x + xOffset, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.circle("line", self.x + xOffset, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.print("BLOCKED!", self.x + xOffset - 30, self.y + 70)
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
        local notifYOffset = 10 * (1 - alpha)  -- Rise up as it fades
        love.graphics.print(self.spellCastNotification.text, 
                           self.spellCastNotification.x + xOffset - 60, 
                           self.spellCastNotification.y - notifYOffset, 
                           0, -- rotation
                           1.5, 1.5) -- scale
    end
    
    -- We'll remove the key indicators from here as they'll be drawn in the UI's spellbook component
    
    -- Save current xOffset and yOffset for other drawing functions
    self.currentXOffset = xOffset
    self.currentYOffset = yOffset
    
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
    
    -- Get position offsets from draw function
    local xOffset = self.currentXOffset or 0
    local yOffset = self.currentYOffset or 0
    
    -- Properties for status effect bars
    local barWidth = 130
    local barHeight = 12
    local barSpacing = 18
    local barPadding = 15  -- Additional padding between effect bars
    
    -- Position status bars above the spellbook area
    local baseY = screenHeight - 150  -- Higher up from the spellbook
    local effectCount = 0
    
    -- Determine x position based on which wizard this is, plus the NEAR/FAR offset
    local x = (self.name == "Ashgar") and (150 + xOffset) or (screenWidth - 150 + xOffset)
    
    -- Define colors for different effect types
    local effectColors = {
        aerial = {0.7, 0.7, 1.0, 0.8},
        stun = {1.0, 1.0, 0.1, 0.8},
        shield = {0.5, 0.7, 1.0, 0.8},
        burn = {1.0, 0.4, 0.1, 0.8}
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
    
    -- Draw BURN duration if active
    if self.statusEffects.burn.active then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress
        local maxDuration = self.statusEffects.burn.duration
        local progress = 1.0 - (self.statusEffects.burn.totalTime / maxDuration)
        progress = math.max(0.0, progress)  -- Ensure non-negative
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label with pulsing effect
        love.graphics.setColor(effectColors.burn[1], effectColors.burn[2], effectColors.burn[3], 
                              effectColors.burn[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 7)))
        love.graphics.print("BURNING", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.burn)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.burn[1], effectColors.burn[2], effectColors.burn[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time remaining and damage info
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs (%d/tick)", 
                           maxDuration - self.statusEffects.burn.totalTime,
                           self.statusEffects.burn.tickDamage), 
                           x - 20, y)
        
        -- Draw fire particles on the wizard to show the burning effect
        if math.random() < 0.2 and self.gameState and self.gameState.vfx then
            local angle = math.random() * math.pi * 2
            local distance = math.random(10, 30)
            local effectX = self.x + xOffset + math.cos(angle) * distance
            local effectY = self.y + yOffset + math.sin(angle) * distance
            
            self.gameState.vfx.createEffect("impact", effectX, effectY, nil, nil, {
                duration = 0.2,
                color = {1.0, 0.3, 0.1, 0.4},
                particleCount = 2,
                radius = 5
            })
        end
    end
end

function Wizard:drawSpellSlots()
    -- Draw 3 orbiting spell slots as elliptical paths at different vertical positions
    -- Position the slots at legs, midsection, and head levels
    -- Get position offsets from draw function to apply the same offsets as the wizard
    local xOffset = self.currentXOffset or 0
    local yOffset = self.currentYOffset or 0
    local slotYOffsets = {30, 0, -30}  -- From bottom to top
    
    -- Horizontal and vertical radii for each elliptical path
    local horizontalRadii = {80, 70, 60}   -- Wider at the bottom, narrower at the top
    local verticalRadii = {20, 25, 30}     -- Flatter at the bottom, rounder at the top
    
    for i, slot in ipairs(self.spellSlots) do
        -- Position parameters for each slot, applying both offsets
        local slotY = self.y + slotYOffsets[i] + yOffset
        local slotX = self.x + xOffset
        local radiusX = horizontalRadii[i]
        local radiusY = verticalRadii[i]
        
        -- Draw tokens that should appear "behind" the character first
        -- Skip drawing here for shields as those are handled in update
        if slot.active and #slot.tokens > 0 and not slot.isShield then
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
                        token.x = slotX + math.cos(tokenAngle) * radiusX
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
            
            -- Check if it's a shield spell (fully cast)
            if slot.isShield then
                -- Draw a full shield arc with color based on defense type
                local shieldColor
                local shieldName = ""
                
                if slot.defenseType == "barrier" then
                    shieldColor = {1.0, 1.0, 0.3}  -- Yellow for barriers
                    shieldName = "Barrier"
                elseif slot.defenseType == "ward" then 
                    shieldColor = {0.3, 0.3, 1.0}  -- Blue for wards
                    shieldName = "Ward"
                elseif slot.defenseType == "field" then
                    shieldColor = {0.3, 1.0, 0.3}  -- Green for fields
                    shieldName = "Field"
                else
                    shieldColor = {0.8, 0.8, 0.8}  -- Grey fallback
                    shieldName = "Shield"
                end
                
                -- Add pulsing effect for active shields
                local pulseSize = 2 + math.sin(love.timer.getTime() * 3) * 2
                
                -- Draw a slightly larger pulse effect around the orbit
                for j = 1, 3 do
                    local extraSize = j * 2
                    love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.2 - j*0.05)
                    self:drawEllipse(slotX, slotY, radiusX + pulseSize + extraSize, 
                                    radiusY + pulseSize + extraSize, "line")
                end
                
                -- Draw the back half of the shield (reduced alpha)
                love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.4)
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, math.pi * 2, 16)
                
                -- Draw the front half of the shield (full alpha)
                love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.7)
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.pi, 16)
                
                -- Draw shield name (without numeric indicator) above the highest slot
                if i == 3 then
                    love.graphics.setColor(1, 1, 1, 0.8)
                    love.graphics.print(shieldName, slotX - 25, slotY - radiusY - 15)
                end
            
            -- Check if the spell is frozen by Eclipse Echo
            elseif slot.frozen then
                -- Draw frozen indicator - a "stopped" pulse effect around the orbit
                for j = 1, 3 do
                    local pulseSize = 2 + j*1.5
                    love.graphics.setColor(0.5, 0.5, 1.0, 0.2 - j*0.05)
                    
                    -- Draw a slightly larger ellipse to indicate frozen state
                    self:drawEllipse(slotX, slotY, radiusX + pulseSize + math.sin(love.timer.getTime() * 3) * 2, 
                                    radiusY + pulseSize + math.sin(love.timer.getTime() * 3) * 2, "line")
                end
                
                -- Draw the progress arc with a blue/icy color for frozen spells
                -- First the back half of the progress arc (if it extends that far)
                if progressAngle > math.pi then
                    love.graphics.setColor(0.5, 0.5, 1.0, 0.3)  -- Light blue for frozen
                    self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, progressAngle, 16)
                end
                
                -- Then the front half of the progress arc
                love.graphics.setColor(0.5, 0.5, 1.0, 0.7)  -- Light blue for frozen
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.min(progressAngle, math.pi), 16)
            else
                -- Normal progress arc for unfrozen spells
                -- First the back half of the progress arc (if it extends that far)
                if progressAngle > math.pi then
                    love.graphics.setColor(0.8, 0.8, 0.2, 0.3)  -- Lower alpha for back
                    self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, progressAngle, 16)
                end
                
                -- Then the front half of the progress arc
                love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Higher alpha for front
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.min(progressAngle, math.pi), 16)
            end
            
            -- Draw spell name above the highest slot (only for non-shield spells)
            if i == 3 and not slot.isShield then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(slot.spellType, slotX - 20, slotY - radiusY - 15)
            end
            
            -- Draw tokens that should appear "in front" of the character
            -- Skip drawing here for shields as those are handled in update
            if #slot.tokens > 0 and not slot.isShield then
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
                            token.x = slotX + math.cos(tokenAngle) * radiusX
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
            -- Skip drawing inactive tokens for shield slots - we shouldn't have this case anyway
            if #slot.tokens > 0 and not slot.isShield then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        -- Position tokens on their appropriate paths even when slot is inactive
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = anglePerToken * (j - 1)
                        
                        -- Calculate position based on angle
                        token.x = slotX + math.cos(tokenAngle) * radiusX
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
            
            -- Debug: verify spell definition is complete
            if not self.currentKeyedSpell.cost then
                print("WARNING: Spell '" .. self.currentKeyedSpell.name .. "' has no cost defined!")
            end
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
    
    -- Debug output to identify issues with specific spells
    print("DEBUG: " .. self.name .. " attempting to cast: " .. self.currentKeyedSpell.name)
    print("DEBUG: Spell cost: " .. self:formatCost(self.currentKeyedSpell.cost))
    
    -- Enhanced debugging for ALL spells to identify differences
    print("\nDEBUG: FULL SPELL ANALYSIS:")
    print("  - Name: " .. (self.currentKeyedSpell.name or "nil"))
    print("  - ID: " .. (self.currentKeyedSpell.id or "nil"))
    print("  - Cost type: " .. type(self.currentKeyedSpell.cost))
    print("  - Attack Type: " .. (self.currentKeyedSpell.attackType or "nil"))
    print("  - Has isShield: " .. tostring(self.currentKeyedSpell.isShield ~= nil))
    if self.currentKeyedSpell.isShield ~= nil then
        print("  - isShield value: " .. tostring(self.currentKeyedSpell.isShield))
    end
    print("  - Has effect func: " .. tostring(type(self.currentKeyedSpell.effect) == "function"))
    print("  - Has keywords: " .. tostring(self.currentKeyedSpell.keywords ~= nil))
    if self.currentKeyedSpell.keywords and self.currentKeyedSpell.keywords.block then
        print("  - Has block keyword")
        print("  - Block type: " .. (self.currentKeyedSpell.keywords.block.type or "nil"))
    else
        print("  - No block keyword")
    end
    
    -- Queue the keyed spell with detailed error handling
    print("DEBUG: Calling queueSpell...")
    local success, result = pcall(function() 
        return self:queueSpell(self.currentKeyedSpell)
    end)
    
    -- Debug the result of queueSpell
    if not success then
        print("ERROR: Exception in queueSpell: " .. tostring(result))
        print("ERROR TRACE: " .. debug.traceback())
        return false
    elseif not result then
        print("DEBUG: Failed to queue " .. self.currentKeyedSpell.name .. " - check if manaCost check failed")
    else
        print("DEBUG: Successfully queued " .. self.currentKeyedSpell.name)
    end
    
    return result
end

-- Helper to format spell cost for debug output
function Wizard:formatCost(cost)
    local costText = ""
    for i, costComponent in ipairs(cost) do
        if type(costComponent) == "string" then
            -- New format
            costText = costText .. costComponent
        else
            -- Old format
            costText = costText .. costComponent.type .. " x" .. costComponent.count
        end
        
        if i < #cost then
            costText = costText .. ", "
        end
    end
    
    if costText == "" then
        return "Free"
    else
        return costText
    end
end

function Wizard:queueSpell(spell)
    print("DEBUG: " .. self.name .. " queueSpell called for " .. (spell and spell.name or "nil spell"))
    
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
    print("DEBUG: Checking for available spell slots...")
    for i = 1, #self.spellSlots do
        print("DEBUG: Checking slot " .. i .. ": " .. (self.spellSlots[i].active and "ACTIVE" or "AVAILABLE"))
        if not self.spellSlots[i].active then
            print("DEBUG: Found available slot " .. i .. ", checking mana cost...")
            -- Check if we can pay the mana cost from the pool
            local tokenReservations = self:canPayManaCost(spell.cost)
            
            -- Debug info for mana cost checks
            if not tokenReservations then
                print("DEBUG: Cannot pay mana cost for " .. spell.name)
                if type(spell.cost) == "table" then
                    for j, component in ipairs(spell.cost) do
                        print("DEBUG: - Cost component " .. j .. ": " .. tostring(component))
                    end
                else
                    print("DEBUG: Cost is not a table: " .. tostring(spell.cost))
                end
            end
            
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
                
                -- Use dynamic cast time if available, otherwise use static cast time
                if spell.getCastTime and type(spell.getCastTime) == "function" then
                    self.spellSlots[i].castTime = spell.getCastTime(self)
                    print(self.name .. " is using dynamic cast time: " .. self.spellSlots[i].castTime .. "s")
                else
                    self.spellSlots[i].castTime = spell.castTime
                end
                
                self.spellSlots[i].spell = spell
                self.spellSlots[i].tokens = tokens
                
                -- Set attackType if present in the new schema
                if spell.attackType then
                    self.spellSlots[i].attackType = spell.attackType
                end
                
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

-- Free all active spells and return their mana to the pool
function Wizard:freeAllSpells()
    print(self.name .. " is freeing all active spells")
    
    -- Iterate through all spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            -- Return tokens to the mana pool
            if #slot.tokens > 0 then
                for _, tokenData in ipairs(slot.tokens) do
                    -- Trigger animation to return token to the mana pool
                    self.manaPool:returnToken(tokenData.index)
                end
                
                -- Clear token list (tokens still exist in the mana pool)
                slot.tokens = {}
            end
            
            -- Reset slot properties
            slot.active = false
            slot.progress = 0
            slot.spellType = nil
            slot.castTime = 0
            slot.spell = nil
            
            -- Reset shield-specific properties if applicable
            if slot.isShield then
                slot.isShield = false
                slot.defenseType = nil
                slot.blocksAttackTypes = nil
                slot.shieldStrength = 0
            end
            
            -- Reset any frozen state
            if slot.frozen then
                slot.frozen = false
                slot.freezeTimer = 0
            end
            
            print("Freed spell in slot " .. i)
        end
    end
    
    -- Create visual effect for all spells being canceled
    if self.gameState and self.gameState.vfx then
        self.gameState.vfx.createEffect("free_mana", self.x, self.y, nil, nil)
    end
    
    -- Reset active key inputs
    for i = 1, 3 do
        self.activeKeys[i] = false
    end
    
    -- Clear keyed spell
    self.currentKeyedSpell = nil
    
    return true
end

-- Helper function to check if mana cost can be paid without actually taking the tokens
function Wizard:canPayManaCost(cost)
    local tokenReservations = {}
    local reservedIndices = {} -- Track which token indices are already reserved
    
    -- Debug output for cost checking
    print("DEBUG: Checking mana cost payment for " .. (self.currentKeyedSpell and self.currentKeyedSpell.name or "unknown spell"))
    
    -- Handle cost being nil or not a table
    if not cost then
        print("DEBUG: Cost is nil")
        return {}
    end
    
    -- Check if cost is a valid table we can iterate through
    if type(cost) ~= "table" then
        print("DEBUG: Cost is not a table, it's a " .. type(cost))
        return nil
    end
    
    -- Early exit if cost is empty
    if #cost == 0 then 
        print("DEBUG: Cost is an empty table")
        return {} 
    end
    
    -- Dump the exact cost structure to understand what's being passed
    print("DEBUG: Cost structure details:")
    print("DEBUG: - Type: " .. type(cost))
    print("DEBUG: - Length: " .. #cost)
    for i, component in ipairs(cost) do
        print("DEBUG: - Component " .. i .. " type: " .. type(component))
        print("DEBUG: - Component " .. i .. " value: " .. tostring(component))
    end
    
    -- Print existing tokens in mana pool for debugging
    print("DEBUG: Mana pool contains " .. #self.manaPool.tokens .. " tokens:")
    local tokenCounts = {}
    for _, token in ipairs(self.manaPool.tokens) do
        if token.state == "FREE" then
            tokenCounts[token.type] = (tokenCounts[token.type] or 0) + 1
        end
    end
    for tokenType, count in pairs(tokenCounts) do
        print("DEBUG: - " .. tokenType .. ": " .. count .. " free tokens")
    end
    
    -- This function mirrors payManaCost but just returns the indices of tokens that would be used
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType, costCount
        
        -- Handle both old and new cost formats
        if type(costComponent) == "string" then
            -- New format: simple string token type
            costType = costComponent
            costCount = 1
        else
            -- Old format: table with type and count
            costType = costComponent.type
            costCount = costComponent.count
        end
        
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
                if token.type == costType and token.state == "FREE" and not reservedIndices[i] then
                    table.insert(availableTokens, {token = token, index = i})
                end
            end
            
            -- Check if we have enough tokens
            if #availableTokens < costCount then
                return nil  -- Not enough tokens of this type
            end
            
            -- Add the required number of tokens to our reservations
            for i = 1, costCount do
                local tokenData = availableTokens[i]
                table.insert(tokenReservations, tokenData)
                reservedIndices[tokenData.index] = true -- Mark as reserved
            end
        end
    end
    
    return tokenReservations
end

-- Helper function to check and pay mana costs
function Wizard:payManaCost(cost)
    local tokens = {}
    local usedIndices = {} -- Track which token indices are already used
    
    -- Early exit if cost is empty
    if not cost or #cost == 0 then 
        print("DEBUG: Cost is nil or empty")
        return {} 
    end
    
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType, costCount
        
        -- Handle both old and new cost formats
        if type(costComponent) == "string" then
            -- New format: simple string token type
            costType = costComponent
            costCount = 1
        else
            -- Old format: table with type and count
            costType = costComponent.type
            costCount = costComponent.count
        end
        
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
                if token.type == costType and token.state == "FREE" and not usedIndices[i] then
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
                usedIndices[tokenData.index] = true -- Mark as used
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
        y = self.y + 70, -- Moved below the wizard instead of above
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
    
    -- Apply spell effect using the enhanced keyword system with targeting
    local effect = SpellsModule.keywordSystem.castSpell(
        slot.spell,
        self,
        {
            opponent = target,
            spellSlot = spellSlot,
            debug = false  -- Set to true for detailed logging
        }
    )
    
    -- Early exit if the spell was blocked (handled by the resolution process)
    if effect.blocked then
        local shieldBreakPower = effect.shieldBreakPower or 1
        local shieldDestroyed = effect.shieldDestroyed or false
        
        if shieldDestroyed then
            print(string.format("[BLOCKED] %s's %s was blocked by %s's %s which has been DESTROYED!", 
                self.name, slot.spellType, target.name, effect.blockType or "shield"))
                
            -- Create shield break visual effect on the target
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                    duration = 0.7,
                    color = {1.0, 0.5, 0.5, 0.8},
                    particleCount = 15,
                    radius = 50
                })
            end
        else
            if shieldBreakPower > 1 then
                print(string.format("[BLOCKED] %s's %s was blocked by %s's %s! (shield took %d hits)", 
                    self.name, slot.spellType, target.name, effect.blockType or "shield", shieldBreakPower))
            else
                print(string.format("[BLOCKED] %s's %s was blocked by %s's %s", 
                    self.name, slot.spellType, target.name, effect.blockType or "shield"))
            end
            
            -- Create blocked visual effect at the shield
            if self.gameState.vfx then
                -- Shield color based on type
                local shieldColor = {0.8, 0.8, 0.8, 0.7}  -- Default gray
                if effect.blockType == "barrier" then
                    shieldColor = {1.0, 1.0, 0.3, 0.7}    -- Yellow for barriers
                elseif effect.blockType == "ward" then
                    shieldColor = {0.3, 0.3, 1.0, 0.7}    -- Blue for wards
                elseif effect.blockType == "field" then 
                    shieldColor = {0.3, 1.0, 0.3, 0.7}    -- Green for fields
                end
                
                -- Create visual effect on the target to show the block
                self.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
                    duration = 0.5,
                    color = shieldColor,
                    shieldType = effect.blockType
                })
            end
        end
        
        -- Create spell impact effect on the caster to show the spell being blocked
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.3,
                color = {0.8, 0.2, 0.2, 0.5},
                particleCount = 5,
                radius = 15
            })
        end
        
        -- Skip further processing - tokens have already been returned by the blocking logic
        return
    end
    
    -- Check if the spell missed (for zone spells with zoneAnchor)
    if effect.missed then
        print(string.format("[MISSED] %s's %s missed due to range/elevation mismatch", 
            self.name, slot.spellType))
        
        -- Create whiff visual effect
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.3,
                color = {0.5, 0.5, 0.5, 0.3},
                particleCount = 3,
                radius = 10
            })
        end
    end
    
    -- Handle token dissipation from the dissipate keyword
    if effect.dissipate then
        local tokenType = effect.dissipateType or "any"
        local amount = effect.dissipateAmount or 1
        local tokensDestroyed = effect.tokensDestroyed or 0
        
        if tokensDestroyed > 0 then
            print("Destroyed " .. tokensDestroyed .. " " .. tokenType .. " tokens")
        else
            print("No matching " .. tokenType .. " tokens found to destroy")
        end
    end
    
    -- Handle burn effects from the burn keyword
    if effect.burnApplied then
        -- Apply burn status effect to target
        target.statusEffects.burn.active = true
        target.statusEffects.burn.duration = effect.burnDuration or 3.0
        target.statusEffects.burn.tickDamage = effect.burnTickDamage or 2
        target.statusEffects.burn.tickInterval = effect.burnTickInterval or 1.0
        target.statusEffects.burn.elapsed = 0
        target.statusEffects.burn.totalTime = 0
        
        print(string.format("[STATUS] %s is burning! (%d damage per %.1f sec for %.1f sec)",
            target.name, 
            target.statusEffects.burn.tickDamage,
            target.statusEffects.burn.tickInterval,
            target.statusEffects.burn.duration))
        
        -- Create initial burn effect
        if self.gameState and self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.6,
                color = {1.0, 0.3, 0.1, 0.8},
                particleCount = 12,
                radius = 35
            })
        end
    end
    
    -- Handle spell freeze effect from the freeze keyword
    if effect.freezeApplied then
        local targetSlot = effect.targetSlot or 2  -- Default to middle slot
        local freezeDuration = effect.freezeDuration or 2.0
        
        -- Check if the target slot exists and is active
        if self.spellSlots[targetSlot] and self.spellSlots[targetSlot].active then
            local slot = self.spellSlots[targetSlot]
            
            -- Add the frozen flag and timer
            slot.frozen = true
            slot.freezeTimer = freezeDuration
            
            print(slot.spellType .. " in slot " .. targetSlot .. " frozen for " .. freezeDuration .. " seconds")
            
            -- Add visual effect for the frozen spell
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlot]
                
                -- Create a clear visual effect to show freeze
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 1.2,
                    color = {0.3, 0.3, 0.8, 0.7},
                    particleCount = 20,
                    radius = 50
                })
            end
        else
            print("No active spell found in slot " .. targetSlot .. " to freeze")
        end
    end
    
    -- Handle disjoint effect (spell cancellation with mana destruction)
    if effect.disjoint then
        local targetSlot = effect.targetSlot or 0
        
        -- If targetSlot is 0, find the first active slot
        if targetSlot == 0 then
            for i, slot in ipairs(target.spellSlots) do
                if slot.active then
                    targetSlot = i
                    break
                end
            end
        end
        
        -- Check if the target slot exists and is active
        if targetSlot > 0 and targetSlot <= #target.spellSlots and target.spellSlots[targetSlot].active then
            local slot = target.spellSlots[targetSlot]
            
            -- Store data for feedback
            local spellName = slot.spellType or "spell"
            local tokenCount = #slot.tokens
            
            -- Destroy the mana tokens instead of returning them to the pool
            for _, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                if token then
                    -- Mark the token as destroyed
                    token.state = "DESTROYED"
                    token.gameState = self.gameState  -- Give the token access to gameState for VFX
                    
                    -- Create immediate destruction VFX
                    if self.gameState.vfx then
                        self.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                            duration = 0.5,
                            color = {0.8, 0.6, 1.0, 0.7},  -- Purple for lunar theme
                            particleCount = 10,
                            radius = 20
                        })
                    end
                end
            end
            
            -- Cancel the spell, emptying the slot
            slot.active = false
            slot.progress = 0
            slot.tokens = {}
            
            -- Create visual effect at the spell slot position
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = target.y + slotYOffsets[targetSlot]
                
                -- Create a visual effect for the disjunction
                self.gameState.vfx.createEffect("disjoint_cancel", target.x, slotY, nil, nil)
            end
            
            print(self.name .. " disjointed " .. target.name .. "'s " .. spellName .. 
                  " in slot " .. targetSlot .. ", destroying " .. tokenCount .. " mana tokens")
        else
            print("No active spell found in slot " .. targetSlot .. " to disjoint")
        end
    end
    
    -- Create visual effect based on spell type
    if self.gameState.vfx then
        self.gameState.vfx.createSpellEffect(slot.spell, self, target)
    end
    
    -- Check if it's a shield spell that should persist in the spell slot
    if slot.spell.isShield or effect.isShield then
        -- Mark the progress as completed
        slot.progress = slot.castTime  -- Mark as fully cast
        
        -- Debug shield creation process
        print("DEBUG: Creating shield from spell: " .. slot.spellType)
        
        -- Check if we have shieldCreated flag which means the shield was already
        -- created by the block keyword handler
        if not effect.shieldCreated then
            -- Extract shield params from effect or keywords
            local defenseType = "barrier"
            local blocks = {"projectile"}
            local manaLinked = true
            local reflect = false
            local hitPoints = nil
            
            -- Get shield parameters from effect or spell
            if effect.defenseType then
                defenseType = effect.defenseType
            elseif slot.spell.defenseType then
                defenseType = slot.spell.defenseType
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.type then
                defenseType = slot.spell.keywords.block.type
            end
            
            -- Get blocks from effect or spell
            if effect.blockTypes then
                blocks = effect.blockTypes
            elseif slot.spell.blockableBy then
                blocks = slot.spell.blockableBy
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.blocks then
                blocks = slot.spell.keywords.block.blocks
            end
            
            -- Get manaLinked from effect or spell
            if effect.manaLinked ~= nil then
                manaLinked = effect.manaLinked
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.manaLinked ~= nil then
                manaLinked = slot.spell.keywords.block.manaLinked
            end
            
            -- Get reflect from effect or spell
            if effect.reflect ~= nil then
                reflect = effect.reflect
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.reflect ~= nil then
                reflect = slot.spell.keywords.block.reflect
            end
            
            -- Get hitPoints from effect or spell
            if effect.shieldStrength then
                hitPoints = effect.shieldStrength
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.hitPoints then
                hitPoints = slot.spell.keywords.block.hitPoints
            end
            
            -- Use our central shield creation function to set up the shield
            local blockParams = {
                type = defenseType,
                blocks = blocks,
                manaLinked = manaLinked,
                reflect = reflect,
                hitPoints = hitPoints -- Use existing shield strength if specified
            }
            
            print("DEBUG: Shield parameters:")
            print("DEBUG: - Type: " .. defenseType)
            print("DEBUG: - Mana linked: " .. tostring(manaLinked))
            print("DEBUG: - Reflect: " .. tostring(reflect))
            if hitPoints then
                print("DEBUG: - Hit points: " .. hitPoints)
            end
            
            -- Call the shield creation function - this centralizes all shield setup logic
            SpellsModule.keywordSystem.createShield(self, spellSlot, blockParams)
        end
        
        -- Apply elevation change if the shield spell includes that effect
        if effect.setElevation then
            -- Determine the target for elevation changes based on keyword settings
            local elevationTarget
            
            -- Explicit targeting from keyword resolution
            if effect.elevationTarget then
                if effect.elevationTarget == "SELF" then
                    elevationTarget = self
                elseif effect.elevationTarget == "ENEMY" then
                    elevationTarget = target
                else
                    -- Default to self if target specification is invalid
                    elevationTarget = self
                    print("Warning: Unknown elevation target type: " .. tostring(effect.elevationTarget))
                end
            else
                -- Legacy behavior if no explicit target (for backward compatibility)
                elevationTarget = effect.setElevation == "GROUNDED" and target or self
            end
            
            -- Record if this is changing from AERIAL (for VFX)
            local wasAerial = elevationTarget.elevation == "AERIAL"
            
            -- Apply the elevation change
            elevationTarget.elevation = effect.setElevation
            
            -- Set duration for elevation change if provided
            if effect.elevationDuration and effect.setElevation == "AERIAL" then
                elevationTarget.elevationTimer = effect.elevationDuration
                print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation for " .. effect.elevationDuration .. " seconds")
            else
                -- No duration specified, treat as permanent until changed by another spell
                elevationTarget.elevationTimer = 0
                print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation")
            end
            
            -- Create appropriate visual effect for elevation change
            if self.gameState.vfx then
                if effect.setElevation == "AERIAL" then
                    -- Effect for rising into the air (use specified VFX or default)
                    local vfxName = effect.elevationVfx or "emberlift"
                    self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
                elseif effect.setElevation == "GROUNDED" and wasAerial then
                    -- Effect for forcing down to the ground (use specified VFX or default)
                    local vfxName = effect.elevationVfx or "tidal_force_ground"
                    self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
                end
            end
        end
        
        -- Do not reset the slot - the shield will remain active
        return
    end
    
    -- Check for shield blocking based on attack type
    local attackBlocked = false
    local blockingShieldSlot = nil
    
    -- Only check for blocking if this is an offensive spell
    if slot.spell.attackType or slot.attackType then
        -- The attack type of the current spell (check both old and new schema)
        local attackType = slot.spell.attackType or slot.attackType
        print("Checking if " .. attackType .. " attack can be blocked by " .. target.name .. "'s shields")
        
        -- Check each of the target's spell slots for active shields
        for i, targetSlot in ipairs(target.spellSlots) do
            -- Debug print to check shield state
            if targetSlot.active and targetSlot.isShield then
                print("Found shield in slot " .. i .. " of type " .. targetSlot.defenseType .. 
                      " with strength " .. targetSlot.shieldStrength)
                
                -- Check if the shield blocks appropriate attack types
                if targetSlot.blocksAttackTypes then
                    for blockType, _ in pairs(targetSlot.blocksAttackTypes) do
                        print("Shield blocks: " .. blockType)
                    end
                else
                    print("Shield does not have blocksAttackTypes defined!")
                end
            end
            
            -- Check if this shield can block this attack type
            local canBlock = false
            if targetSlot.blocksAttackTypes then
                -- Old format - table with attackType as keys
                canBlock = targetSlot.blocksAttackTypes[attackType]
            elseif targetSlot.blockTypes then
                -- New format - array of attack types
                for _, blockType in ipairs(targetSlot.blockTypes) do
                    if blockType == attackType then
                        canBlock = true
                        break
                    end
                end
            end
            
            if targetSlot.active and targetSlot.isShield and 
               targetSlot.shieldStrength > 0 and canBlock then
                
                -- This shield can block this attack type
                attackBlocked = true
                blockingShieldSlot = i
                
                -- Create visual effect for the block
                target.blockVFX = {
                    active = true,
                    timer = 0.5,  -- Duration of the block visual effect
                    x = target.x,
                    y = target.y
                }
                
                -- Create block effect using VFX system
                if self.gameState.vfx then
                    local shieldColor
                    if targetSlot.defenseType == "barrier" then
                        shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Yellow for barriers
                    elseif targetSlot.defenseType == "ward" then
                        shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
                    elseif targetSlot.defenseType == "field" then
                        shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
                    end
                    
                    self.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
                        duration = 0.5, -- Short block flash
                        color = shieldColor,
                        shieldType = targetSlot.defenseType
                    })
                end
                
                -- Determine how many hits to apply to the shield
                -- Check if this is a shield-breaker spell
                local shieldBreakPower = 1  -- Default: reduce shield by 1
                if slot.spell.shieldBreaker then
                    shieldBreakPower = slot.spell.shieldBreaker
                    print(string.format("[SHIELD BREAKER] %s's %s is a shield-breaker spell that deals %d hits to shields!",
                        self.name, slot.spellType, shieldBreakPower))
                end
                
                -- Check if this is a mana-linked shield (consumes tokens when blocking)
                -- Default to true (backward compatibility)
                local manaLinked = targetSlot.manaLinked
                if manaLinked == nil then
                    manaLinked = true
                end
                
                if manaLinked then
                    -- Apply shield-break effect and leak tokens
                    local tokensToReturn = math.min(shieldBreakPower, #targetSlot.tokens)
                    
                    -- Return tokens back to the mana pool
                    for i = 1, tokensToReturn do
                        if #targetSlot.tokens > 0 then
                            -- Get the last token
                            local lastTokenIndex = #targetSlot.tokens
                            local tokenData = targetSlot.tokens[lastTokenIndex]
                            
                            -- Trigger animation to return this token to the mana pool
                            target.manaPool:returnToken(tokenData.index)
                            
                            -- Remove this token from the slot's token list
                            table.remove(targetSlot.tokens, lastTokenIndex)
                        end
                    end
                    
                    -- Update shield strength based on remaining tokens
                    targetSlot.shieldStrength = targetSlot.shieldStrength - shieldBreakPower
                    
                    -- Print the blocked attack message with mana leak info
                    if shieldBreakPower > 1 then
                        print(string.format("[BLOCK] %s's %s shield blocked %s's %s attack and leaked %d mana! (%d strength remaining)",
                            target.name, targetSlot.defenseType, self.name, attackType, tokensToReturn, targetSlot.shieldStrength))
                    else
                        print(string.format("[BLOCK] %s's %s shield blocked %s's %s attack and leaked one mana! (%d strength remaining)",
                            target.name, targetSlot.defenseType, self.name, attackType, targetSlot.shieldStrength))
                    end
                else
                    -- For non-mana linked shields, just decrease the shield strength
                    targetSlot.shieldStrength = targetSlot.shieldStrength - shieldBreakPower
                    
                    -- Print blocked message without mana leak info
                    if shieldBreakPower > 1 then
                        print(string.format("[BLOCK] %s's %s shield blocked %s's %s attack! (-%d strength, %d remaining)",
                            target.name, targetSlot.defenseType, self.name, attackType, shieldBreakPower, targetSlot.shieldStrength))
                    else
                        print(string.format("[BLOCK] %s's %s shield blocked %s's %s attack! (%d strength remaining)",
                            target.name, targetSlot.defenseType, self.name, attackType, targetSlot.shieldStrength))
                    end
                end
                
                -- If the shield is depleted (no strength left), destroy it
                if targetSlot.shieldStrength <= 0 then
                    print(string.format("[BLOCK] %s's %s shield has been broken!", target.name, targetSlot.defenseType))
                    
                    -- Return any remaining tokens (for partially consumed shields)
                    for _, tokenData in ipairs(targetSlot.tokens) do
                        target.manaPool:returnToken(tokenData.index)
                    end
                    
                    -- Reset slot
                    targetSlot.active = false
                    targetSlot.isShield = false
                    targetSlot.defenseType = nil
                    targetSlot.blocksAttackTypes = nil
                    targetSlot.shieldStrength = 0
                    targetSlot.progress = 0
                    targetSlot.spellType = nil
                    targetSlot.castTime = 0
                    
                    -- Create shield break effect
                    if self.gameState.vfx then
                        self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                            duration = 0.7,
                            color = {1.0, 0.5, 0.5, 0.8},
                            particleCount = 15,
                            radius = 50
                        })
                    end
                end
                
                -- Check for reflection if this shield has that property
                if targetSlot.reflect then
                    print(string.format("[REFLECT] %s's shield reflected %s's attack back at them!",
                        target.name, self.name))
                    
                    -- Implement spell reflection (simplified version)
                    -- For now, just deal partial damage back to the caster
                    if effect.damage and effect.damage > 0 then
                        local reflectDamage = math.floor(effect.damage * 0.5) -- 50% reflection
                        self.health = self.health - reflectDamage
                        if self.health < 0 then self.health = 0 end
                        
                        print(string.format("[REFLECT] %s took %d reflected damage! (health: %d)", 
                            self.name, reflectDamage, self.health))
                            
                        -- Create reflected damage visual effect
                        if self.gameState.vfx then
                            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                                duration = 0.5,
                                color = {0.8, 0.2, 0.8, 0.7}, -- Purple for reflection
                                particleCount = 10,
                                radius = 30
                            })
                        end
                    end
                end
                
                break  -- Stop checking other shields once one has blocked
            end
        end
    end
    
    -- If the attack was blocked, don't apply any effects
    if attackBlocked then
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
        
        return  -- Skip applying any effects
    end
    
    -- LEGACY CHECK FOR OLD BLOCKER SYSTEM - Disabled (Now using shield system instead)
    --[[
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
        
        return  -- Skip applying any effects
    }
    --]]
    
    -- LEGACY CODE - Apply blocking effects (like old Mist Veil) - Disabled
    --[[
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
    --]]
    
    -- Apply damage
    if effect.damage and effect.damage > 0 then
        target.health = target.health - effect.damage
        if target.health < 0 then target.health = 0 end
        
        -- Special feedback for time-scaled damage from Full Moon Beam
        if effect.scaledDamage then
            print(target.name .. " took " .. effect.damage .. " damage from " .. slot.spellType .. 
                  " (scaled by cast time) (health: " .. target.health .. ")")
            
            -- Create a more dramatic visual effect for scaled damage
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                    duration = 0.8,
                    color = {0.5, 0.5, 1.0, 0.8},
                    particleCount = 20,
                    radius = 45
                })
            end
        else
            -- Regular damage feedback
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
        -- Determine the target for elevation changes based on keyword settings
        local elevationTarget
        
        -- Explicit targeting from keyword resolution
        if effect.elevationTarget then
            if effect.elevationTarget == "SELF" then
                elevationTarget = self
            elseif effect.elevationTarget == "ENEMY" then
                elevationTarget = target
            else
                -- Default to self if target specification is invalid
                elevationTarget = self
                print("Warning: Unknown elevation target type: " .. tostring(effect.elevationTarget))
            end
        else
            -- Legacy behavior if no explicit target (for backward compatibility)
            elevationTarget = effect.setElevation == "GROUNDED" and target or self
        end
        
        -- Record if this is changing from AERIAL (for VFX)
        local wasAerial = elevationTarget.elevation == "AERIAL"
        
        -- Apply the elevation change
        elevationTarget.elevation = effect.setElevation
        
        -- Set duration for elevation change if provided
        if effect.elevationDuration and effect.setElevation == "AERIAL" then
            elevationTarget.elevationTimer = effect.elevationDuration
            print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation for " .. effect.elevationDuration .. " seconds")
        else
            -- No duration specified, treat as permanent until changed by another spell
            elevationTarget.elevationTimer = 0
            print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation")
        end
        
        -- Create appropriate visual effect for elevation change
        if self.gameState.vfx then
            if effect.setElevation == "AERIAL" then
                -- Effect for rising into the air (use specified VFX or default)
                local vfxName = effect.elevationVfx or "emberlift"
                self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
            elseif effect.setElevation == "GROUNDED" and wasAerial then
                -- Effect for forcing down to the ground (use specified VFX or default)
                local vfxName = effect.elevationVfx or "tidal_force_ground"
                self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
            end
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
    
    -- Apply spell delay (to target's spell)
    if effect.delaySpell and target.spellSlots[effect.delaySpell] and target.spellSlots[effect.delaySpell].active then
        -- Get the target spell slot
        local slot = target.spellSlots[effect.delaySpell]
        
        -- Calculate how much progress has been made (as a percentage)
        local progressPercent = slot.progress / slot.castTime
        
        -- Add additional time to the spell
        local delayTime = effect.delayAmount or 2.0  -- Use specified delay amount or default to 2.0 seconds
        local newCastTime = slot.castTime + delayTime
        
        -- Update the castTime and adjust the progress proportionally
        -- This effectively "pushes back" the progress bar
        slot.castTime = newCastTime
        slot.progress = progressPercent * slot.castTime
        
        print("Delayed " .. target.name .. "'s spell in slot " .. effect.delaySpell .. " by " .. delayTime .. " seconds")
        
        -- Create delay effect near the targeted spell slot
        if self.gameState.vfx then
            -- Calculate position of the targeted spell slot
            local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
            local slotY = target.y + slotYOffsets[effect.delaySpell]
            
            -- Create a more distinctive delay visual effect
            self.gameState.vfx.createEffect("impact", target.x, slotY, nil, nil, {
                duration = 0.9,
                color = {0.3, 0.3, 0.8, 0.7},
                particleCount = 15,
                radius = 40
            })
        end
    end
    
    -- Apply spell delay (to caster's own spell)
    if effect.delaySelfSpell then
        print("DEBUG - Eclipse Echo effect triggered with delaySelfSpell = " .. effect.delaySelfSpell)
        print("DEBUG - Caster: " .. self.name)
        print("DEBUG - Spell slots status:")
        for i, slot in ipairs(self.spellSlots) do
            print("DEBUG - Slot " .. i .. ": " .. (slot.active and "ACTIVE - " .. (slot.spellType or "unknown") or "INACTIVE"))
            if slot.active then
                print("DEBUG - Progress: " .. slot.progress .. " / " .. slot.castTime)
            end
        end
        
        -- When Eclipse Echo resolves, we need to target the middle spell slot
        -- Which in Lua is index 2 (1-based indexing)
        local targetSlotIndex = effect.delaySelfSpell  -- Should be 2 for the middle slot
        print("DEBUG - Targeting slot index: " .. targetSlotIndex)
        local targetSlot = self.spellSlots[targetSlotIndex]
        
        if targetSlot and targetSlot.active then
            -- Get the caster's spell slot
            local slot = targetSlot
            print("DEBUG - Found active spell in target slot: " .. (slot.spellType or "unknown"))
            
            -- Calculate how much progress has been made (as a percentage)
            local progressPercent = slot.progress / slot.castTime
            
            -- Add additional time to the spell
            local delayTime = effect.delayAmount or 2.0  -- Use specified delay amount or default to 2.0 seconds
            local newCastTime = slot.castTime + delayTime
            
            -- Update the castTime and adjust the progress proportionally
            -- This effectively "pushes back" the progress bar
            slot.castTime = newCastTime
            slot.progress = progressPercent * slot.castTime
            
            print(self.name .. " delayed their own spell in slot " .. targetSlotIndex .. " by " .. delayTime .. " seconds")
            
            -- Create delay effect near the caster's spell slot
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlotIndex]
                
                -- Create a more distinctive delay visual effect
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 0.9,
                    color = {0.3, 0.3, 0.8, 0.7},
                    particleCount = 15,
                    radius = 40
                })
            end
        else
            -- If there's no spell in the target slot, show a "fizzle" effect
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlotIndex]
                
                -- Create a small fizzle effect to show the spell had no effect
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 0.3,
                    color = {0.3, 0.3, 0.4, 0.4},
                    particleCount = 5,
                    radius = 20
                })
                
                print("Eclipse Echo fizzled - no spell in " .. self.name .. "'s middle slot")
            end
        end
    end
    
    -- Only reset the spell slot and return tokens for non-shield spells
    -- This is now handled at the beginning of the function for shield spells
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

return Wizard