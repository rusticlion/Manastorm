-- WizardVisuals.lua
-- Centralized visualization system for Wizard entities in Manastorm

local WizardVisuals = {}
local Constants = require("core.Constants")
local ShieldSystem = require("systems.ShieldSystem")
local VFX = require("vfx") -- Added for accessing rune assets

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

-- Easing function for smoother animations
function WizardVisuals.easeOutCubic(t)
    return 1 - math.pow(1 - t, 3)
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
    
    local Constants = require("core.Constants")
    
    -- Draw AERIAL duration if active
    if wizard.elevation == Constants.ElevationState.AERIAL and wizard.elevationTimer > 0 then
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
        love.graphics.print(Constants.ElevationState.AERIAL, x - 25, y - 2)
        
        -- Add some particle effects for AERIAL state
        if wizard.gameState and wizard.gameState.vfx and math.random() < 0.02 then
            local particleX = x + math.random(-barWidth/2, barWidth/2)
            local particleY = y + math.random(-10, 10)
            
            wizard.gameState.vfx.createEffect(Constants.VFXType.IMPACT, particleX, particleY, nil, nil, {
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
            
            wizard.gameState.vfx.createEffect(Constants.VFXType.IMPACT, particleX, particleY, nil, nil, {
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
            
            wizard.gameState.vfx.createEffect(Constants.VFXType.IMPACT, particleX, particleY, nil, nil, {
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
            -- Clear stale casting arc data if this slot is not currently in an active casting phase
            if not slot.active or (slot.castTime or 0) == 0 or slot.progress >= (slot.castTime or 0) then
                slot._castArcActive = false
            end

            local shouldDrawOrbit = false
            local orbitColor = {0.5, 0.5, 0.5, 0.4} -- Default inactive/dim color
            local drawProgressArc = false
            local progressArcColor = {1.0, 1.0, 1.0, 0.9} -- Default progress color
            local stateText = nil -- Text like "FROZEN", "TRAP"
            local stateTextColor = {1, 1, 1, 0.8}

            -- First, check for keyed spell highlight on an inactive slot
            if wizard.currentKeyedSpell and not slot.active then
                local wouldUseThisSlot = true
                for j = 1, i-1 do
                    if not wizard.spellSlots[j].active then
                        wouldUseThisSlot = false
                        break
                    end
                end
                
                if wouldUseThisSlot then
                    local affinity = wizard.currentKeyedSpell.affinity
                    orbitColor = affinity and Constants.getColorForTokenType(affinity) or {0.8, 0.8, 0.2}
                    orbitColor[4] = 0.7 -- Set alpha
                    shouldDrawOrbit = true
                    -- Skip further checks for this slot if it's just a highlight
                    goto DrawOrbitAndArc -- Use goto to jump past active slot logic
                end
            end

            -- Handle active slots (casting or sustained/finished)
            if slot.active then
                -- Determine if the spell is currently in its casting phase
                local isActuallyCasting = (slot.castTime or 0) > 0 and slot.progress < slot.castTime

                if isActuallyCasting then
                    -- CASTING PHASE: Show affinity-colored progress arc only
                    drawProgressArc = true
                    shouldDrawOrbit = false -- Hide the full orbit during cast

                    local affinity = slot.spell and slot.spell.affinity
                    local baseArcColor = affinity and Constants.getColorForTokenType(affinity) or {1.0, 0.7, 0.3} -- Default yellowish
                    local brightness = 0.9 + math.sin(love.timer.getTime() * 5) * 0.1
                    progressArcColor = {
                        baseArcColor[1] * brightness, 
                        baseArcColor[2] * brightness, 
                        baseArcColor[3] * brightness, 
                        0.9
                    }

                    -- Store arc information so the complementary half can be rendered in the "front" pass
                    slot._castArcActive = true
                    slot._castArcColor = {progressArcColor[1], progressArcColor[2], progressArcColor[3], progressArcColor[4]}
                    slot._castArcProgress = (slot.castTime or 1) > 0 and (slot.progress / slot.castTime) or 0

                else
                    -- POST-CASTING PHASE (or instant spell): Show full orbit based on state
                    drawProgressArc = false
                    slot._castArcActive = false -- Clear cached arc
                    shouldDrawOrbit = true 

                    if slot.isShield then
                        -- New shield rendering logic based on type
                        local shieldColor = ShieldSystem.getShieldColor(slot.defenseType)
                        -- Use slot.defenseType directly instead of looking at the spell keywords, which are not always available
                        local shieldType = slot.defenseType
                        local pulseAmount = 0.2 + math.abs(math.sin(love.timer.getTime() * 2)) * 0.3
                        local alpha = 0.7 + pulseAmount * 0.3 -- Pulsing alpha

                        -- Compare against Constants instead of string literals
                        if shieldType == Constants.ShieldType.BARRIER then
                            -- Do NOT draw the horizontal orbit for Barrier; only vertical hedge lines
                            shouldDrawOrbit = false
                            -- Vertical cylinder lines are handled later in their dedicated block
                        
                        elseif shieldType == Constants.ShieldType.WARD then
                            shouldDrawOrbit = false -- Don't draw the standard orbit for Ward
                            local numRunes = 5
                            local runeYOffset = 0 -- Position runes above the orbit
                            local runeScale = 1.0

                            -- Get runes with more robust handling
                            local runeAssets
                            -- First try using the public getAsset function 
                            if VFX.getAsset then
                                runeAssets = VFX.getAsset("runes")
                            end
                            
                            -- Fall back to direct access if needed
                            if not runeAssets and VFX.assets then
                                runeAssets = VFX.assets.runes
                            end
                            
                            -- Last resort: create a dummy fallback for this frame
                            if not runeAssets or #runeAssets == 0 then
                                print("[WIZARD VISUALS] Warning: Unable to get rune assets, using fallback")
                                shouldDrawOrbit = true
                            end
                            
                            if runeAssets and #runeAssets > 0 then
                                local runeColor = {
                                    shieldColor[1] * (1 + pulseAmount * 0.7),
                                    shieldColor[2] * (1 + pulseAmount * 0.7),
                                    shieldColor[3] * (1 + pulseAmount * 0.7),
                                    alpha
                                }

                                for r = 1, numRunes do
                                    -- Deterministic seed so both passes pick the same rune image
                                    local seed = i * 10 + r + math.floor(love.timer.getTime())
                                    math.randomseed(seed)
                                    local runeIndex = math.random(1, #runeAssets)
                                    math.randomseed(os.time() + os.clock()*1000000)

                                    local runeImg = runeAssets[runeIndex]
                                    local angle = (r / numRunes) * math.pi * 2 + love.timer.getTime() * 0.7
                                    local runeX = slotX + math.cos(angle) * radiusX
                                    local runeY = slotY + math.sin(angle) * radiusY + runeYOffset

                                    -- Determine if rune is front or back half
                                    local normalizedAngle = (angle % (math.pi * 2))
                                    local runeLayer = (normalizedAngle >= 0 and normalizedAngle <= math.pi) and "front" or "back"

                                    if runeLayer == layer then
                                        -- Glow pass
                                        local prevBlendSrc, prevBlendDst = love.graphics.getBlendMode()
                                        love.graphics.setBlendMode("add")
                                        love.graphics.setColor(runeColor[1], runeColor[2], runeColor[3], runeColor[4] * 0.6)
                                        love.graphics.draw(
                                            runeImg,
                                            runeX, runeY,
                                            0,
                                            runeScale * 1.4, runeScale * 1.4,
                                            runeImg:getWidth() / 2, runeImg:getHeight() / 2
                                        )
                                        love.graphics.setBlendMode(prevBlendSrc, prevBlendDst)

                                        -- Main rune sprite
                                        love.graphics.setColor(runeColor[1], runeColor[2], runeColor[3], runeColor[4])
                                        love.graphics.draw(
                                            runeImg,
                                            runeX, runeY,
                                            0,
                                            runeScale, runeScale,
                                            runeImg:getWidth() / 2, runeImg:getHeight() / 2
                                        )
                                    end
                                end
                            else
                                -- Fallback: Draw the orbit if runes aren't loaded
                                shouldDrawOrbit = true
                                orbitColor = { shieldColor[1] * (1 + pulseAmount), shieldColor[2] * (1 + pulseAmount), shieldColor[3] * (1 + pulseAmount), alpha }
                            end

                        else
                            -- Fallback for unknown shield types or missing data: Draw original pulsating orbit
                            shouldDrawOrbit = true
                            orbitColor = { shieldColor[1] * (1 + pulseAmount), shieldColor[2] * (1 + pulseAmount), shieldColor[3] * (1 + pulseAmount), alpha }
                        end
                        
                        -- The old shield orbit drawing logic is now replaced by the type-specific drawing above
                        -- or handled by the fallback cases setting shouldDrawOrbit = true.

                    elseif slot.frozen then
                        orbitColor = {0.5, 0.5, 1.0, 0.7} -- Blue for frozen
                        stateText = "FROZEN"
                        stateTextColor = {0.7, 0.7, 1.0, 0.8}
                        -- Flickering ice effect
                        if math.random() < 0.03 then
                            if wizard.gameState and wizard.gameState.vfx then
                                local angle = math.random() * math.pi * 2
                                local sparkleX = slotX + math.cos(angle) * radiusX * 0.7
                                local sparkleY = slotY + math.sin(angle) * radiusY * 0.7
                                wizard.gameState.vfx.createEffect(Constants.VFXType.IMPACT, sparkleX, sparkleY, nil, nil, {
                                    duration = 0.3, color = {0.6, 0.6, 1.0, 0.5}, particleCount = 3, radius = 5
                                })
                            end
                        end

                    elseif slot.spell and slot.spell.behavior and slot.spell.behavior.trap_trigger then
                        orbitColor = {0.7, 0.3, 0.9, 0.7} -- Purple for traps
                        stateText = "TRAP"
                        stateTextColor = {0.7, 0.3, 0.9, 0.8}
                        -- Trap sigil effect
                        -- this is the "explosions" bit on the caster rn - replace with overhead rune
                        if math.random() < 0.05 then
                            if wizard.gameState and wizard.gameState.vfx then
                                local angle = math.random() * math.pi * 2
                                local sparkleX = slotX + math.cos(angle) * radiusX * 0.6
                                local sparkleY = slotY + math.sin(angle) * radiusY * 0.6
                                wizard.gameState.vfx.createEffect(Constants.VFXType.IMPACT, sparkleX, sparkleY, nil, nil, {
                                    duration = 0.3, color = {0.7, 0.2, 0.9, 0.5}, particleCount = 2, radius = 4
                                })
                            end
                        end

                    elseif slot.spell and slot.spell.behavior and slot.spell.behavior.sustain then
                        orbitColor = {0.9, 0.9, 0.9, 0.7} -- Light grey for sustained
                        stateText = "SUSTAIN"
                        stateTextColor = {0.9, 0.9, 0.9, 0.8}
                        -- Add potential sustain VFX here if desired

                    else 
                        -- Completed normal spell (not shield/frozen/trap/sustain)
                        -- Keep orbit briefly visible with affinity color (or maybe dim grey?)
                        local affinity = slot.spell and slot.spell.affinity
                        orbitColor = affinity and Constants.getColorForTokenType(affinity) or {0.9, 0.4, 0.2}
                        orbitColor[4] = 0.5 -- Make it slightly dimmer after completion
                    end
                end
            end -- End of active slot handling
            
            ::DrawOrbitAndArc::
            
            -- Draw the orbit ellipse if needed
            if shouldDrawOrbit then
                -- Store information so the corresponding bottom half can be drawn in the "front" pass
                slot._orbitShouldDraw = true
                slot._orbitColor = {orbitColor[1], orbitColor[2], orbitColor[3], orbitColor[4]}

                love.graphics.setColor(orbitColor[1], orbitColor[2], orbitColor[3], orbitColor[4])
                -- Draw ONLY the TOP half of the ellipse (π to 2π) during the "back" pass so it appears behind the wizard
                WizardVisuals.drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, math.pi * 2, 32)
            else
                -- Make sure we do not accidentally reuse stale data on the next frame
                slot._orbitShouldDraw = false
            end

            -- NEW: Draw Barrier vertical cylinder lines if applicable
            if slot.active and slot.isShield then
                 -- Use the slot's defenseType value directly rather than trying to check the spell
                 if slot.defenseType == Constants.ShieldType.BARRIER then
                    -- Recalculate color/alpha or retrieve if stored (recalculating is safer here)
                    local shieldColor = ShieldSystem.getShieldColor(slot.defenseType) 
                    local pulseAmount = 0.2 + math.abs(math.sin(love.timer.getTime() * 2)) * 0.3
                    local alpha = 0.7 + pulseAmount * 0.3 

                    local cylinderHeight = 20 -- Height of the barrier effect
                    local numLines = 72 -- Number of vertical lines to simulate the cylinder
                    local lineAlpha = alpha * 0.6 -- Make vertical lines slightly more transparent

                    love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], lineAlpha)
                    local prevWidth = love.graphics.getLineWidth()
                    love.graphics.setLineWidth(1.5) -- thicker

                    for k = 1, numLines do
                        local angle = (k / numLines) * math.pi * 2
                        local normalizedAngle = angle % (math.pi * 2)
                        -- Draw only BACK half lines in the back pass (π → 2π)
                        if normalizedAngle > math.pi then
                            local px = slotX + math.cos(angle) * radiusX
                            local py = slotY + math.sin(angle) * radiusY

                            -- Glow pass (thicker, additive blend)
                            local prevSrc, prevDst = love.graphics.getBlendMode()
                            love.graphics.setBlendMode("add")
                            love.graphics.setLineWidth(4)
                            love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], lineAlpha * 0.35)
                            love.graphics.line(px, py - cylinderHeight / 2, px, py + cylinderHeight / 2)
                            love.graphics.setBlendMode(prevSrc, prevDst)

                            -- Main line
                            love.graphics.setLineWidth(1.5)
                            love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], lineAlpha)
                            love.graphics.line(px, py - cylinderHeight / 2, px, py + cylinderHeight / 2)
                        end
                    end
                    love.graphics.setLineWidth(prevWidth) -- restore
                 end
            end
            
            -- Draw progress arc if needed (only during casting phase)
            if drawProgressArc then
                -- Compute end angle once
                local endAngle = ((slot.castTime or 1) > 0) and (slot.progress / slot.castTime) * (math.pi * 2) or 0

                -- Draw only the TOP half (π → 2π) of the arc for the back layer
                if endAngle > math.pi then
                    local segStart = math.max(math.pi, 0) -- will always be π
                    local segEnd = endAngle
                    love.graphics.setColor(progressArcColor[1], progressArcColor[2], progressArcColor[3], progressArcColor[4])
                    WizardVisuals.drawEllipticalArc(slotX, slotY, radiusX, radiusY, segStart, segEnd, 32)
                end
            end

            -- Draw state text (TRAP, FROZEN, SUSTAIN) above the orbit if applicable
            if stateText then
                love.graphics.setColor(stateTextColor[1], stateTextColor[2], stateTextColor[3], stateTextColor[4])
                local textWidth = love.graphics.getFont():getWidth(stateText)
                love.graphics.print(stateText, 
                    slotX - textWidth / 2, -- Center text
                    slotY - verticalRadii[i] - 15) -- Position above the orbit
            end

            -- Re-draw tokens so they sit on top of the just-drawn orbit / arc graphics (maintains depth vs wizard)
            if slot.active and #slot.tokens > 0 then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token and token.status ~= Constants.TokenStatus.RETURNING and token.status ~= Constants.TokenStatus.DISSOLVING then
                        -- token.orbitAngle was set earlier in the first pass through tokens
                        local normalizedAngle = (token.orbitAngle or 0) % (math.pi * 2)
                        local tokenLayer = (normalizedAngle >= 0 and normalizedAngle <= math.pi) and "front" or "back"

                        if tokenLayer == layer then
                            if token.status == Constants.TokenStatus.CHANNELED or token.status == Constants.TokenStatus.SHIELDING then
                                manaPool:drawToken(token)
                            end
                        end
                    end
                end
            end
        end -- End of drawing orbits only on 'back' pass

        -- NEW: Draw the BOTTOM half of the orbit ellipse during the "front" layer pass
        if layer == "front" then
            if slot._orbitShouldDraw and slot._orbitColor then
                local oc = slot._orbitColor
                love.graphics.setColor(oc[1], oc[2], oc[3], oc[4])
                WizardVisuals.drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.pi, 32)
            end

            -- Draw bottom half of casting progress arc if there is one
            if slot._castArcActive and slot._castArcColor then
                local endAngle = (slot._castArcProgress or 0) * (math.pi * 2)
                local segEnd = math.min(endAngle, math.pi)
                if segEnd > 0.01 then -- Avoid drawing if not progressed into bottom half yet
                    local cac = slot._castArcColor
                    love.graphics.setColor(cac[1], cac[2], cac[3], cac[4])
                    WizardVisuals.drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, segEnd, 32)
                end
            end

            -- Draw WARD runes that belong to the FRONT half
            if slot.active and slot.isShield and slot.defenseType == Constants.ShieldType.WARD then
                local shieldColor = ShieldSystem.getShieldColor(slot.defenseType)
                local pulseAmount = 0.2 + math.abs(math.sin(love.timer.getTime() * 2)) * 0.3
                local alpha = 0.7 + pulseAmount * 0.3

                local numRunes = 5
                local runeYOffset = 0
                local runeScale = 1.0

                local runeAssets
                if VFX.getAsset then
                    runeAssets = VFX.getAsset("runes")
                end
                if not runeAssets and VFX.assets then
                    runeAssets = VFX.assets.runes
                end

                if runeAssets and #runeAssets > 0 then
                    local runeColor = {
                        shieldColor[1] * (1 + pulseAmount * 0.7),
                        shieldColor[2] * (1 + pulseAmount * 0.7),
                        shieldColor[3] * (1 + pulseAmount * 0.7),
                        alpha
                    }

                    for r = 1, numRunes do
                        local seed = i * 10 + r + math.floor(love.timer.getTime())
                        math.randomseed(seed)
                        local runeIndex = math.random(1, #runeAssets)
                        math.randomseed(os.time() + os.clock()*1000000)

                        local runeImg = runeAssets[runeIndex]
                        local angle = (r / numRunes) * math.pi * 2 + love.timer.getTime() * 0.7
                        local runeX = slotX + math.cos(angle) * radiusX
                        local runeY = slotY + math.sin(angle) * radiusY + runeYOffset

                        local normalizedAngle = angle % (math.pi * 2)
                        if normalizedAngle >= 0 and normalizedAngle <= math.pi then -- Front half
                            -- Glow pass
                            local prevBlendSrc, prevBlendDst = love.graphics.getBlendMode()
                            love.graphics.setBlendMode("add")
                            love.graphics.setColor(runeColor[1], runeColor[2], runeColor[3], runeColor[4] * 0.6)
                            love.graphics.draw(runeImg, runeX, runeY, 0, runeScale * 1.4, runeScale * 1.4, runeImg:getWidth()/2, runeImg:getHeight()/2)
                            love.graphics.setBlendMode(prevBlendSrc, prevBlendDst)

                            -- Main rune
                            love.graphics.setColor(runeColor[1], runeColor[2], runeColor[3], runeColor[4])
                            love.graphics.draw(runeImg, runeX, runeY, 0, runeScale, runeScale, runeImg:getWidth()/2, runeImg:getHeight()/2)
                        end
                    end
                end
            end

            -- Draw Barrier vertical hedge lines for the FRONT half
            if slot.active and slot.isShield and slot.defenseType == Constants.ShieldType.BARRIER then
                local shieldColor = ShieldSystem.getShieldColor(slot.defenseType)
                local pulseAmount = 0.2 + math.abs(math.sin(love.timer.getTime() * 2)) * 0.3
                local alpha = 0.7 + pulseAmount * 0.3
                local cylinderHeight = 20
                local numLines = 72
                local lineAlpha = alpha * 0.6

                love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], lineAlpha)
                local prevWidthF = love.graphics.getLineWidth()
                love.graphics.setLineWidth(1.5)

                for k = 1, numLines do
                    local angle = (k / numLines) * math.pi * 2
                    local normalizedAngle = angle % (math.pi * 2)
                    -- FRONT half is 0 → π
                    if normalizedAngle <= math.pi then
                        local px = slotX + math.cos(angle) * radiusX
                        local py = slotY + math.sin(angle) * radiusY

                        -- Glow pass
                        local prevSrc, prevDst = love.graphics.getBlendMode()
                        love.graphics.setBlendMode("add")
                        love.graphics.setLineWidth(4)
                        love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], lineAlpha * 0.35)
                        love.graphics.line(px, py - cylinderHeight / 2, px, py + cylinderHeight / 2)
                        love.graphics.setBlendMode(prevSrc, prevDst)

                        -- Main line
                        love.graphics.setLineWidth(1.5)
                        love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], lineAlpha)
                        love.graphics.line(px, py - cylinderHeight / 2, px, py + cylinderHeight / 2)
                    end
                end
                love.graphics.setLineWidth(prevWidthF)
            end

            -- Re-draw tokens again in front layer to ensure they sit atop orbit/arc
            if slot.active and #slot.tokens > 0 then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token and token.status ~= Constants.TokenStatus.RETURNING and token.status ~= Constants.TokenStatus.DISSOLVING then
                        local normalizedAngle = (token.orbitAngle or 0) % (math.pi * 2)
                        local tokenLayer = (normalizedAngle >= 0 and normalizedAngle <= math.pi) and "front" or "back"
                        if tokenLayer == layer then
                            if token.status == Constants.TokenStatus.CHANNELED or token.status == Constants.TokenStatus.SHIELDING then
                                manaPool:drawToken(token)
                            end
                        end
                    end
                end
            end
        end
    end -- End of loop through spell slots
end

-- Main function to draw the wizard
function WizardVisuals.drawWizard(wizard)
    -- Calculate target position adjustments based on elevation and range state
    local targetYOffset = 0
    local targetXOffset = 0
    
    -- Vertical adjustment for AERIAL state - increased for more dramatic effect
    if wizard.elevation == Constants.ElevationState.AERIAL then
        targetYOffset = -50  -- Lift the wizard up more significantly when AERIAL
    end
    
    -- Horizontal adjustment for NEAR/FAR state
    local isNear = wizard.gameState and wizard.gameState.rangeState == Constants.RangeState.NEAR
    local centerX = love.graphics.getWidth() / 2
    
    -- Push wizards closer to center in NEAR mode, further in FAR mode
    if wizard.name == "Ashgar" then -- Player 1 (left side)
        targetXOffset = isNear and 60 or 0 -- Move right when NEAR
    else -- Player 2 (right side)
        targetXOffset = isNear and -60 or 0 -- Move left when NEAR
    end
    
    -- Check if position needs to change and start animation if needed
    if not wizard.positionAnimation.active and
       ((wizard.currentXOffset or 0) ~= targetXOffset or 
        (wizard.currentYOffset or 0) ~= targetYOffset) then
        -- Start animation
        wizard.positionAnimation.active = true
        wizard.positionAnimation.startX = wizard.currentXOffset or 0
        wizard.positionAnimation.startY = wizard.currentYOffset or 0
        wizard.positionAnimation.targetX = targetXOffset
        wizard.positionAnimation.targetY = targetYOffset
        wizard.positionAnimation.progress = 0
    end
    
    -- Calculate and apply current offsets (animated or target)
    local xOffset, yOffset
    if wizard.positionAnimation.active then
        -- Use interpolated position with easing
        local progress = WizardVisuals.easeOutCubic(wizard.positionAnimation.progress)
        xOffset = wizard.positionAnimation.startX + 
                 (wizard.positionAnimation.targetX - wizard.positionAnimation.startX) * progress
        yOffset = wizard.positionAnimation.startY + 
                 (wizard.positionAnimation.targetY - wizard.positionAnimation.startY) * progress
    else
        -- Use target position directly
        xOffset = targetXOffset
        yOffset = targetYOffset
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
    if wizard.elevation == Constants.ElevationState.GROUNDED then
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
        if wizard.elevation == Constants.ElevationState.GROUNDED then
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
        if wizard.elevation == Constants.ElevationState.AERIAL then
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