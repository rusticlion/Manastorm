-- WizardVisuals.lua
-- Centralized visualization system for Wizard entities in Manastorm

local WizardVisuals = {}
local Constants = require("core.Constants")
local ShieldSystem = require("systems.ShieldSystem")

-- Get appropriate status effect color
function WizardVisuals.getStatusEffectColor(effectType)
    local effectColors = {
        aerial = {0.7, 0.7, 1.0, 0.8},
        stun = {1.0, 1.0, 0.1, 0.8},
        shield = {0.5, 0.7, 1.0, 0.8},
        burn = {1.0, 0.4, 0.1, 0.8}
    }
    
    return effectColors[effectType] or {0.8, 0.8, 0.8, 0.8} -- Default to gray
end

-- Helper function to draw an ellipse
function WizardVisuals.drawEllipse(x, y, radiusX, radiusY, mode)
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
function WizardVisuals.drawEllipticalArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
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
function WizardVisuals.drawStatusEffects(wizard)
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Get position offsets
    local xOffset = wizard.currentXOffset or 0
    local yOffset = wizard.currentYOffset or 0
    
    -- Properties for status effect bars
    local barWidth = 130
    local barHeight = 12
    local barSpacing = 18
    local barPadding = 15  -- Additional padding between effect bars
    
    -- Position status bars above the spellbook area
    local baseY = screenHeight - 150  -- Higher up from the spellbook
    local effectCount = 0
    
    -- Determine x position based on which wizard this is, plus the NEAR/FAR offset
    local x = (wizard.name == "Ashgar") and (150 + xOffset) or (screenWidth - 150 + xOffset)
    
    -- Draw AERIAL duration if active
    if wizard.elevation == "AERIAL" and wizard.elevationTimer > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress (1.0 to 0.0 as time depletes)
        local maxDuration = 5.0  -- Assuming 5 seconds is max aerial duration
        local progress = wizard.elevationTimer / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Get color for aerial state
        local color = WizardVisuals.getStatusEffectColor("aerial")
        
        -- Draw background bar (darker)
        love.graphics.setColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, color[4] * 0.5)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 4, 4)
        
        -- Draw progress bar
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 4, 4)
        
        -- Draw label
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("AERIAL", x - 25, y - 2)
        
        -- Add some particle effects for AERIAL state
        if wizard.gameState and wizard.gameState.vfx and math.random() < 0.02 then
            local particleX = x + math.random(-barWidth/2, barWidth/2)
            local particleY = y + math.random(-10, 10)
            
            wizard.gameState.vfx.createEffect("impact", particleX, particleY, nil, nil, {
                duration = 0.3,
                color = {0.5, 0.5, 1.0, 0.7},
                particleCount = 3,
                radius = 5
            })
        end
    end
    
    -- Draw STUN duration if active
    if wizard.stunTimer > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress (1.0 to 0.0 as time depletes)
        local maxDuration = 3.0  -- Assuming 3 seconds is max stun duration
        local progress = wizard.stunTimer / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Get color for stun state
        local color = WizardVisuals.getStatusEffectColor("stun")
        
        -- Draw background bar (darker)
        love.graphics.setColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, color[4] * 0.5)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 4, 4)
        
        -- Draw progress bar
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 4, 4)
        
        -- Draw label
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("STUNNED", x - 30, y - 2)
        
        -- Add some particle effects for STUN state
        if wizard.gameState and wizard.gameState.vfx and math.random() < 0.05 then
            local particleX = x + math.random(-barWidth/2, barWidth/2)
            local particleY = y + math.random(-5, 5)
            
            wizard.gameState.vfx.createEffect("impact", particleX, particleY, nil, nil, {
                duration = 0.2,
                color = {1.0, 1.0, 0.0, 0.7},
                particleCount = 2,
                radius = 5
            })
        end
    end
    
    -- Draw BURN effect if active
    if wizard.statusEffects.burn and wizard.statusEffects.burn.active then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Get burn effect data
        local burnEffect = wizard.statusEffects.burn
        
        -- Calculate progress (1.0 to 0.0 as time depletes)
        local progress = 1.0
        if burnEffect.duration > 0 then
            progress = (burnEffect.duration - burnEffect.totalTime) / burnEffect.duration
            progress = math.max(0.0, math.min(1.0, progress))  -- Clamp between 0 and 1
        end
        
        -- Get tick progress for pulsing effect
        local tickProgress = burnEffect.elapsed / burnEffect.tickInterval
        local pulseEffect = math.sin(tickProgress * math.pi) * 0.2  -- Pulse effect strongest right before tick
        
        -- Get color for burn state
        local color = WizardVisuals.getStatusEffectColor("burn")
        
        -- Draw background bar (darker)
        love.graphics.setColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, color[4] * 0.5)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 4, 4)
        
        -- Draw progress bar with pulse effect
        love.graphics.setColor(
            color[1] * (1 + pulseEffect), 
            color[2] * (1 + pulseEffect), 
            color[3] * (1 + pulseEffect), 
            color[4]
        )
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 4, 4)
        
        -- Draw label with damage per tick
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("BURN "..burnEffect.tickDamage, x - 30, y - 2)
        
        -- Add some particle effects for BURN state
        if wizard.gameState and wizard.gameState.vfx and math.random() < 0.1 then
            local particleX = wizard.x + math.random(-20, 20)
            local particleY = wizard.y + math.random(-30, 10)
            
            wizard.gameState.vfx.createEffect("impact", particleX, particleY, nil, nil, {
                duration = 0.3,
                color = {1.0, 0.4, 0.1, 0.6},
                particleCount = 3,
                radius = 8
            })
        end
    end
end

-- Draw spell slots with token orbits
function WizardVisuals.drawSpellSlots(wizard)
    -- Draw 3 orbiting spell slots as elliptical paths at different vertical positions
    -- Position the slots at legs, midsection, and head levels
    -- Get position offsets to apply the same offsets as the wizard
    local xOffset = wizard.currentXOffset or 0
    local yOffset = wizard.currentYOffset or 0
    local slotYOffsets = {30, 0, -30}  -- From bottom to top
    
    -- Horizontal and vertical radii for each elliptical path
    local horizontalRadii = {80, 70, 60}   -- Wider at the bottom, narrower at the top
    local verticalRadii = {20, 25, 30}     -- Flatter at the bottom, rounder at the top
    
    for i, slot in ipairs(wizard.spellSlots) do
        -- Position parameters for each slot, applying both offsets
        local slotY = wizard.y + slotYOffsets[i] + yOffset
        local slotX = wizard.x + xOffset
        local radiusX = horizontalRadii[i]
        local radiusY = verticalRadii[i]
        
        -- Draw tokens that should appear "behind" the character first
        -- Skip drawing here for shields as those are handled in update
        if slot.active and #slot.tokens > 0 and not slot.isShield then
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            for j, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                -- Skip tokens that are returning or dissolving or in animation
                if token and 
                   (token.status == nil or (token.status ~= Constants.TokenStatus.RETURNING and token.status ~= Constants.TokenStatus.DISSOLVING)) and
                   (token.isAnimating ~= true) and
                   (token.animTime >= token.animDuration and not token.returning) then
                    local tokenCount = #slot.tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = progressAngle + anglePerToken * (j - 1)
                    
                    -- Only draw tokens that are in the back half (π to 2π)
                    local normalizedAngle = tokenAngle % (math.pi * 2)
                    if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                        -- Calculate 3D position with elliptical projection
                        token.x = slotX + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Draw the token at this position (handled by mana pool's draw)
                    end
                end
            end
        end
        
        -- Draw the elliptical orbit paths
        if wizard.activeKeys[i] then
            -- Highlight active spell slots
            love.graphics.setColor(0.8, 0.8, 0.2, 0.7) -- Yellow highlight for active keys
        elseif slot.active then
            if slot.isShield then
                -- Use shield color from ShieldSystem
                local shieldColor = ShieldSystem.getShieldColor(slot.defenseType)
                love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.7)
            elseif slot.frozen then
                -- Blue for frozen slots
                love.graphics.setColor(0.5, 0.5, 1.0, 0.7)
            else
                -- Active but not a shield - normal red/orange 
                love.graphics.setColor(0.9, 0.4, 0.2, 0.7) -- Reddish for active spell
            end
        else
            -- Inactive slot
            love.graphics.setColor(0.6, 0.6, 0.6, 0.3) -- Gray for inactive slot
        end
        
        -- Draw the orbit ellipse
        WizardVisuals.drawEllipse(slotX, slotY, radiusX, radiusY, "line")
        
        -- Draw progress arc for active slots
        if slot.active then
            local startAngle = 0
            local endAngle = (slot.progress / slot.castTime) * (math.pi * 2)
            
            if slot.isShield then
                -- Shield slots show a full arc (since they're fully cast)
                endAngle = math.pi * 2
                
                -- Draw shield type text
                love.graphics.setColor(1, 1, 1, 0.8)
                local shieldTypeText = slot.defenseType:upper()
                love.graphics.print(shieldTypeText, 
                    slotX - 20, -- Center text horizontally
                    slotY - verticalRadii[i] - 15) -- Position above the orbit
            elseif slot.frozen then
                -- Draw frozen indicator
                love.graphics.setColor(0.7, 0.7, 1.0, 0.8)
                love.graphics.print("FROZEN", 
                    slotX - 20, -- Center text
                    slotY - verticalRadii[i] - 15) -- Above the orbit
                
                -- Draw flickering ice effect
                if math.random() < 0.03 then
                    if wizard.gameState and wizard.gameState.vfx then
                        local angle = math.random() * math.pi * 2
                        local sparkleX = slotX + math.cos(angle) * radiusX * 0.7
                        local sparkleY = slotY + math.sin(angle) * radiusY * 0.7
                        
                        wizard.gameState.vfx.createEffect("impact", sparkleX, sparkleY, nil, nil, {
                            duration = 0.3,
                            color = {0.6, 0.6, 1.0, 0.5},
                            particleCount = 3,
                            radius = 5
                        })
                    end
                end
            end
            
            -- Draw the progress arc in a slightly different color
            if slot.isShield then
                -- Shields have a pulsing color to indicate active defense
                local pulseAmount = 0.2 + math.abs(math.sin(love.timer.getTime() * 2)) * 0.3
                local shieldColor = ShieldSystem.getShieldColor(slot.defenseType)
                love.graphics.setColor(
                    shieldColor[1] * (1 + pulseAmount),
                    shieldColor[2] * (1 + pulseAmount),
                    shieldColor[3] * (1 + pulseAmount),
                    0.8
                )
            elseif slot.frozen then
                -- Frozen spells have a blue, shimmering progress arc
                local flicker = 0.8 + math.random() * 0.2
                love.graphics.setColor(0.4 * flicker, 0.4 * flicker, 0.9 * flicker, 0.9)
            else
                -- Normal spell casting
                local brightness = 0.9 + math.sin(love.timer.getTime() * 5) * 0.1
                love.graphics.setColor(1.0 * brightness, 0.7 * brightness, 0.3 * brightness, 0.9)
            end
            
            -- Draw the actual progress arc
            WizardVisuals.drawEllipticalArc(
                slotX, slotY, 
                radiusX, radiusY, 
                startAngle, endAngle, 
                32 -- More segments for smoother arc
            )
            
            -- Draw spell name for active but non-shield slots
            if not slot.isShield then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(slot.spellType or "???", 
                    slotX - 20, -- Approximate centering
                    slotY - verticalRadii[i] - 15) -- Above the orbit
            end
        end
        
        -- Draw tokens that should appear "in front" of the character
        if slot.active and #slot.tokens > 0 then
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            for j, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                -- Skip tokens that are returning or dissolving or in animation
                if token and 
                   (token.status == nil or (token.status ~= Constants.TokenStatus.RETURNING and token.status ~= Constants.TokenStatus.DISSOLVING)) and
                   (token.isAnimating ~= true) and
                   (token.animTime >= token.animDuration and not token.returning) then
                    local tokenCount = #slot.tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    
                    -- Calculate angle differently for shields (fixed positions) vs casting (rotating)
                    local tokenAngle
                    if slot.isShield then
                        -- For shields, distribute evenly around the orbit (fixed)
                        tokenAngle = (j-1) * anglePerToken
                    else
                        -- For normal casting, tokens rotate around the orbit
                        tokenAngle = progressAngle + anglePerToken * (j - 1)
                    end
                    
                    -- Only draw tokens that are in the front half (0 to π)
                    local normalizedAngle = tokenAngle % (math.pi * 2)
                    if normalizedAngle >= 0 and normalizedAngle <= math.pi then
                        -- Calculate 3D position with elliptical projection
                        token.x = slotX + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Draw the token at this position (handled by mana pool's draw)
                    end
                end
            end
        end
    end
end

-- Main function to draw the wizard
function WizardVisuals.drawWizard(wizard)
    -- Calculate position adjustments based on elevation and range state
    local yOffset = 0
    local xOffset = 0
    
    -- Vertical adjustment for AERIAL state - increased for more dramatic effect
    if wizard.elevation == "AERIAL" then
        yOffset = -50  -- Lift the wizard up more significantly when AERIAL
    end
    
    -- Horizontal adjustment for NEAR/FAR state
    local isNear = wizard.gameState and wizard.gameState.rangeState == "NEAR"
    local centerX = love.graphics.getWidth() / 2
    
    -- Push wizards closer to center in NEAR mode, further in FAR mode
    if wizard.name == "Ashgar" then -- Player 1 (left side)
        xOffset = isNear and 60 or 0 -- Move right when NEAR
    else -- Player 2 (right side)
        xOffset = isNear and -60 or 0 -- Move left when NEAR
    end
    
    -- Set color and draw wizard
    if wizard.stunTimer > 0 then
        -- Apply a yellow/white flash for stunned wizards
        local flashIntensity = 0.5 + math.sin(love.timer.getTime() * 10) * 0.5
        love.graphics.setColor(1, 1, flashIntensity)
    else
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw elevation effect (GROUNDED or AERIAL)
    if wizard.elevation == "GROUNDED" then
        -- Draw ground indicator below wizard, applying the x offset
        love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        love.graphics.ellipse("fill", wizard.x + xOffset, wizard.y + 30, 40, 10)  -- Simple shadow/ground indicator
    end
    
    -- Store current offsets for other functions to use
    wizard.currentXOffset = xOffset
    wizard.currentYOffset = yOffset
    
    -- Draw the wizard sprite
    if wizard.sprite then
        local flipX = (wizard.name == "Selene") and -1 or 1  -- Flip Selene to face left
        local adjustedScale = wizard.scale * flipX  -- Apply flip for Selene
        
        -- Draw shadow first (when not AERIAL)
        if wizard.elevation == "GROUNDED" then
            love.graphics.setColor(0, 0, 0, 0.2)
            love.graphics.draw(
                wizard.sprite, 
                wizard.x + xOffset, 
                wizard.y + 30, -- Shadow on ground
                0, -- No rotation
                adjustedScale * 0.8, -- Slightly smaller shadow
                wizard.scale * 0.3, -- Flatter shadow
                wizard.sprite:getWidth() / 2, 
                wizard.sprite:getHeight() / 2
            )
        else
            -- AERIAL cloud effect
            love.graphics.setColor(0.8, 0.8, 1.0, 0.4)
            
            -- Draw animated cloud particles
            for i = 1, 3 do
                local cloudOffset = math.sin(love.timer.getTime() * 1.5 + i * 2) * 10
                love.graphics.ellipse(
                    "fill", 
                    wizard.x + xOffset + cloudOffset, 
                    wizard.y + 30, 
                    45 + i * 5, 
                    10
                )
            end
        end
        
        -- Draw the actual wizard
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            wizard.sprite, 
            wizard.x + xOffset, 
            wizard.y + yOffset, 
            0, -- No rotation
            adjustedScale, 
            wizard.scale, 
            wizard.sprite:getWidth() / 2, 
            wizard.sprite:getHeight() / 2
        )
    else
        -- Fallback if sprite not loaded - draw a colored circle
        love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255)
        love.graphics.circle("fill", wizard.x + xOffset, wizard.y + yOffset, 30)
    end
    
    -- Draw block visual effect if active
    if wizard.blockVFX and wizard.blockVFX.active then
        wizard.blockVFX.timer = wizard.blockVFX.timer - love.timer.getDelta()
        
        if wizard.blockVFX.timer <= 0 then
            wizard.blockVFX.active = false
        else
            -- Pulse effect for shield block
            local pulseSize = 50 * (1 - wizard.blockVFX.timer / 0.5)
            local alpha = wizard.blockVFX.timer / 0.5
            
            love.graphics.setColor(0.2, 0.8, 1.0, alpha)
            love.graphics.circle("line", wizard.blockVFX.x + xOffset, wizard.blockVFX.y + yOffset, pulseSize)
        end
    end
    
    -- Draw spell slots and their token orbits
    WizardVisuals.drawSpellSlots(wizard)
    
    -- Draw status effects
    WizardVisuals.drawStatusEffects(wizard)
    
    -- Draw casting notification if present
    if wizard.spellCastNotification then
        -- Update timer
        wizard.spellCastNotification.timer = wizard.spellCastNotification.timer - love.timer.getDelta()
        
        if wizard.spellCastNotification.timer <= 0 then
            wizard.spellCastNotification = nil
        else
            -- Draw the notification text
            love.graphics.setColor(
                wizard.spellCastNotification.color[1],
                wizard.spellCastNotification.color[2],
                wizard.spellCastNotification.color[3],
                wizard.spellCastNotification.timer / 2.0  -- Fade out
            )
            
            love.graphics.print(
                wizard.spellCastNotification.text,
                wizard.spellCastNotification.x - 40 + xOffset,  -- Center text approximately
                wizard.spellCastNotification.y + yOffset
            )
        end
    end
end

return WizardVisuals