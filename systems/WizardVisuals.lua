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
function WizardVisuals.drawSpellSlots(wizard, layer)
    -- Draw 3 orbiting spell slots as elliptical paths at different vertical positions
    -- Position the slots at legs, midsection, and head levels
    -- Get position offsets to apply the same offsets as the wizard
    local xOffset = wizard.currentXOffset or 0
    local yOffset = wizard.currentYOffset or 0
    local slotYOffsets = {30, 0, -30}  -- From bottom to top
    
    -- Horizontal and vertical radii for each elliptical path
    local horizontalRadii = {80, 70, 60}   -- Wider at the bottom, narrower at the top
    local verticalRadii = {20, 25, 30}     -- Flatter at the bottom, rounder at the top
    
    -- Get the ManaPool instance (ensure gameState and manaPool exist)
    local manaPool = wizard.gameState and wizard.gameState.manaPool
    if not manaPool then
        print("ERROR: ManaPool instance not found in WizardVisuals.drawSpellSlots")
        return
    end

    for i, slot in ipairs(wizard.spellSlots) do
        -- Position parameters for each slot, applying both offsets
        local slotY = wizard.y + slotYOffsets[i] + yOffset
        local slotX = wizard.x + xOffset
        local radiusX = horizontalRadii[i]
        local radiusY = verticalRadii[i]
        
        -- Calculate base position and animation values for all tokens
        -- This is crucial for both normal and shield tokens to get consistent positions
        if slot.active and #slot.tokens > 0 then
            -- For normal spells, angle based on cast progress
            -- For shields, use time-based constant rotation
            local baseAngle
            if slot.isShield then
                -- Shield rotation is time-based and continuous
                baseAngle = love.timer.getTime() * 0.3  -- Slightly faster to make orbiting more visible
            else
                -- Normal spell rotation is based on cast progress
                baseAngle = slot.progress / slot.castTime * math.pi * 2
            end
            
            -- Pre-calculate token positions for ALL tokens in this slot
            -- This ensures consistent positioning regardless of front/back rendering order
            local tokenCount = #slot.tokens
            local anglePerToken = math.pi * 2 / tokenCount
            
            -- First pass: calculate positions and draw based on layer
            for j, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                
                -- Skip invalid or transitioning tokens
                if not token or 
                   token.status == Constants.TokenStatus.RETURNING or 
                   token.status == Constants.TokenStatus.DISSOLVING then
                    -- No goto needed here, just continue to next token
                else
                    -- Calculate angle for each token based on its index
                    local tokenAngle = baseAngle + anglePerToken * (j - 1)
                    
                    -- Store the token's orbit angle (for continuity)
                    token.orbitAngle = tokenAngle
                    
                    -- Calculate position - used for both rendering and token state
                    -- Note: If the token is animating towards the slot (CHANNELED state, animTime < animDuration),
                    -- its x, y might be updated by ManaPool:update. We should use the calculated orbit position
                    -- for layer determination, but let ManaPool:drawToken use the token's current x,y.
                    local orbitX = slotX + math.cos(tokenAngle) * radiusX
                    local orbitY = slotY + math.sin(tokenAngle) * radiusY
                    
                    -- If token isn't fully animated to the slot yet, keep its animating position
                    -- but use the calculated orbit position for determining front/back
                    if token.status == Constants.TokenStatus.CHANNELED and token.animTime < token.animDuration then
                        -- Position is being animated, use orbitAngle for layering check only
                    else
                        -- Token is in orbit, update its position directly
                        token.x = orbitX
                        token.y = orbitY
                    end
                    
                    -- Determine if token is in the front or back half based on its *intended* orbit angle
                    local normalizedAngle = token.orbitAngle % (math.pi * 2)
                    local tokenLayer = (normalizedAngle >= 0 and normalizedAngle <= math.pi) and "front" or "back"

                    -- Draw the token if its layer matches the requested layer
                    if tokenLayer == layer then
                         -- Check if the token is actually supposed to be drawn (not animating away)
                        if token.status == Constants.TokenStatus.CHANNELED or token.status == Constants.TokenStatus.SHIELDING then
                             manaPool:drawToken(token)
                        end
                    end
                end
            end
        end
        
        -- Draw the elliptical orbit paths (only need to do this once, e.g., during the 'back' pass)
        if layer == "back" then 
            if wizard.currentKeyedSpell and not slot.active then
                local shouldDraw = true
                -- Highlight slot that would be used for the current keyed spell
                -- This is always the first available slot, which we need to calculate
                local wouldUseThisSlot = true
                for j = 1, i-1 do
                    if not wizard.spellSlots[j].active then
                        wouldUseThisSlot = false
                        break
                    end
                end
                
                if wouldUseThisSlot then
                    -- Use affinity color for keyed spell highlight
                    local affinity = wizard.currentKeyedSpell and wizard.currentKeyedSpell.affinity
                    local baseColor = affinity and Constants.getColorForTokenType(affinity) or {0.8, 0.8, 0.2} -- Default yellow
                    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.7)
                else
                    -- Inactive slot
                    shouldDraw = false
                end
            elseif slot.active then
                if slot.isShield then
                    -- Use shield color from ShieldSystem
                    local shieldColor = ShieldSystem.getShieldColor(slot.defenseType)
                    love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.7)
                elseif slot.frozen then
                    -- Blue for frozen slots
                    love.graphics.setColor(0.5, 0.5, 1.0, 0.7)
                else
                    shouldDraw = false
                    -- Active but not a shield - use affinity color
                    local affinity = slot.spell and slot.spell.affinity -- Assuming slot.spell exists
                    local baseColor = affinity and Constants.getColorForTokenType(affinity) or {0.9, 0.4, 0.2} -- Default reddish
                    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.7)
                end
            else
                -- Inactive slot
                shouldDraw = false
            end
            
            -- Draw the orbit ellipse
            if shouldDraw then
                WizardVisuals.drawEllipse(slotX, slotY, radiusX, radiusY, "line")
            end
            
            -- Draw progress arc for active slots
            if slot.active then
                local startAngle = 0
                local endAngle = (slot.progress / slot.castTime) * (math.pi * 2)
                
                if slot.isShield then
                    -- Shield slots show a full arc (since they're fully cast)
                    endAngle = math.pi * 2
                    
                    -- Show some VFX effect conveying Barrier vs. Ward - "Wall of Light" for barriers, "Ring of Runes" for wards
                    -- Use slotX, slotY, radiusX, radiusY for the effect to align it with the spell slot
                    if slot.defenseType == "barrier" then
                        -- wizard.gameState.vfx.createEffect("barrier", slotX, slotY, radiusX, radiusY)
                    elseif slot.defenseType == "ward" then
                        -- wizard.gameState.vfx.createEffect("ward", slotX, slotY, radiusX, radiusY)
                    end
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
                    local affinity = slot.spell and slot.spell.affinity -- Assuming slot.spell exists
                    print("spell: " .. slot.spell.name)
                    local baseColor = affinity and Constants.getColorForTokenType(affinity) or {1.0, 0.7, 0.3} -- Default yellowish
                    love.graphics.setColor(baseColor[1] * brightness, baseColor[2] * brightness, baseColor[3] * brightness, 0.9)
                end
                
                -- Draw the actual progress arc
                WizardVisuals.drawEllipticalArc(
                    slotX, slotY, 
                    radiusX, radiusY, 
                    startAngle, endAngle, 
                    32 -- More segments for smoother arc
                )
            end
        end -- End of drawing orbits only on 'back' pass

    end -- End of loop through spell slots
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
    
    -- Draw elevation effect (GROUNDED only - AERIAL clouds moved after wizard)
    if wizard.elevation == "GROUNDED" then
        -- Draw ground indicator below wizard, applying the x offset
        love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        love.graphics.ellipse("fill", wizard.x + xOffset, wizard.y + 40, 40, 10)  -- Simple shadow/ground indicator
    end
    
    -- Store current offsets for other functions to use
    wizard.currentXOffset = xOffset
    wizard.currentYOffset = yOffset

    -- Draw spell slots and tokens behind the wizard
    WizardVisuals.drawSpellSlots(wizard, "back")
    
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
                wizard.y + 40, -- Shadow on ground
                0, -- No rotation
                adjustedScale * 0.8, -- Slightly smaller shadow
                wizard.scale * 0.3, -- Flatter shadow
                wizard.sprite:getWidth() / 2, 
                wizard.sprite:getHeight() / 2
            )
        end
        
        -- Draw the actual wizard
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            wizard.sprite, 
            wizard.x + xOffset, 
            wizard.y + yOffset, 
            0, -- No rotation
            adjustedScale * 2, -- Double scale
            wizard.scale * 2, -- Double scale
            wizard.sprite:getWidth() / 2, 
            wizard.sprite:getHeight() / 2
        )

        -- Draw AERIAL cloud effect after wizard for proper layering
        if wizard.elevation == "AERIAL" then
            love.graphics.setColor(0.8, 0.8, 1.0, 0.3)
            
            -- Draw more numerous, smaller animated cloud particles
            for i = 1, 8 do
                -- Calculate wobble in both x and y directions
                local time = love.timer.getTime()
                local angle = (i / 8) * math.pi * 2 + time
                local xWobble = math.sin(time * 2 + i * 1.5) * 15
                local yWobble = math.cos(time * 1.8 + i * 1.7) * 10
                
                -- Vary sizes for more natural look
                local width = 20 + math.sin(time + i) * 5
                local height = 6 + math.cos(time + i) * 2
                
                love.graphics.ellipse(
                    "fill",
                    wizard.x + xOffset + xWobble,
                    wizard.y + yOffset + 40 + yWobble,
                    width,
                    height
                )
            end
        end
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
    
    -- Draw spell slots and tokens in front of the wizard
    WizardVisuals.drawSpellSlots(wizard, "front")
    
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