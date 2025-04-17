-- UI helper module

local UI = {}

-- Spellbook visibility state
UI.spellbookVisible = {
    player1 = false,
    player2 = false
}

-- Delayed health damage display state
UI.healthDisplay = {
    player1 = {
        currentHealth = 100,        -- Current display health (smoothly animated)
        targetHealth = 100,         -- Actual health to animate towards
        pendingDamage = 0,          -- Damage that's pending animation (yellow bar)
        lastDamageTime = 0,         -- Time when last damage was taken
        pendingDrainDelay = 0.5,    -- Delay before yellow bar starts draining
        drainRate = 30              -- How fast the yellow bar drains (health points per second)
    },
    player2 = {
        currentHealth = 100,
        targetHealth = 100,
        pendingDamage = 0,
        lastDamageTime = 0,
        pendingDrainDelay = 0.5,
        drainRate = 30
    }
}

function UI.drawHelpText(font)
    -- Set font and color
    love.graphics.setFont(font)
    
    -- Draw a semi-transparent background for the debug panel
    love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
    local panelWidth = 600
    local y = love.graphics.getHeight() - 130
    love.graphics.rectangle("fill", 5, y + 30, panelWidth, 95, 5, 5)
    
    -- Draw a border
    love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
    love.graphics.rectangle("line", 5, y + 30, panelWidth, 95, 5, 5)
    
    -- Draw header
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.print("DEBUG MODE", 15, y + 35)
    
    -- Show debug controls with brighter text
    love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
    love.graphics.print("Debug Controls: T (Add tokens), R (Toggle range), A/S (Toggle elevations), ESC (Quit)", 15, y + 55)
    love.graphics.print("VFX Test Keys: 1 (Firebolt), 2 (Meteor), 3 (Mist Veil), 4 (Emberlift), 5 (Full Moon Beam)", 15, y + 75)
    love.graphics.print("Conjure Test Keys: 6 (Fire), 7 (Moonlight), 8 (Volatile)", 15, y + 95)
    
    -- No longer calling UI.drawSpellbookButtons() here as it's now handled in the main loop
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
    
    -- Draw Player 1's spellbook (Ashgar - pinned to left side)
    UI.drawPlayerSpellbook(1, 0, screenHeight - 70)
    
    -- Draw Player 2's spellbook (Selene - pinned to right side)
    UI.drawPlayerSpellbook(2, screenWidth - 250, screenHeight - 70)
end

-- Draw an individual player's spellbook component
function UI.drawPlayerSpellbook(playerNum, x, y)
    local screenWidth = love.graphics.getWidth()
    local width = 250  -- Balanced width
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
    local groupSpacing = 35  -- Original spacing between keys
    
    -- GROUP 1: SPELL INPUT KEYS
    -- Add a subtle background for the key group
    love.graphics.setColor(0.2, 0.2, 0.3, 0.3)
    love.graphics.rectangle("fill", x + 15, centerY - 20, 95, 40, 5, 5)  -- Maintain original padding for keys
    
    -- Calculate positions for centered spell input keys
    local inputStartX = x + 30  -- Original position for better centering
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
    
    -- Removed "Input Keys" label for cleaner UI
    
    -- GROUP 2: CAST BUTTON & FREE BUTTON
    -- Create a shared container/background for both action buttons - more compact
    local actionSectionWidth = 90
    local actionX = x + 125
    
    -- Draw a shared background container for both action buttons
    love.graphics.setColor(0.18, 0.18, 0.25, 0.5)
    love.graphics.rectangle("fill", actionX, centerY - 18, actionSectionWidth, 36, 5, 5)  -- More compact
    
    -- Calculate positions for both buttons with tighter spacing
    local castX = actionX + actionSectionWidth/3 - 5
    local freeX = actionX + actionSectionWidth*2/3 + 5
    local castKey = (playerNum == 1) and "F" or "J"
    local freeKey = (playerNum == 1) and "G" or "H"
    
    -- CAST BUTTON
    -- Subtle highlighting background
    love.graphics.setColor(0.3, 0.2, 0.1, 0.3)
    love.graphics.rectangle("fill", castX - 17, centerY - 16, 34, 32, 5, 5)  -- More compact
    
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
    
    -- Removed "Cast" label for cleaner UI
    
    -- FREE BUTTON
    -- Subtle highlighting background
    love.graphics.setColor(0.1, 0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", freeX - 17, centerY - 16, 34, 32, 5, 5)  -- More compact
    
    -- Draw free button background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
    love.graphics.circle("fill", freeX, inputY, runeSize)
    
    -- Free button border
    love.graphics.setColor(0.2, 0.6, 0.8, 0.8)  -- Blue-ish for free button
    love.graphics.circle("line", freeX, inputY, runeSize)
    
    -- Free button symbol
    local freeTextWidth = love.graphics.getFont():getWidth(freeKey)
    local freeTextHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(0.5, 0.8, 1.0, 0.9)
    love.graphics.print(freeKey, 
        freeX - freeTextWidth/2, 
        inputY - freeTextHeight/2)
    
    -- Removed "Free" label for cleaner UI
    
    -- GROUP 3: KEYED SPELL POPUP (appears above the spellbook when a spell is keyed)
    if wizard.currentKeyedSpell then
        -- Make the popup exactly match the width of the spellbook
        local popupWidth = width
        local popupHeight = 30
        local popupX = x  -- Align with spellbook
        local popupY = y - popupHeight - 10  -- Position above the spellbook with slightly larger gap
        
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
    
    -- GROUP 4: SPELLBOOK HELP (bottom-right corner) - more compact design
    local helpX = x + width - 15
    local helpY = y + height - 10
    
    -- Draw key hint - make it slightly bigger
    local helpSize = 8  -- Increased size
    love.graphics.setColor(0.4, 0.4, 0.6, 0.5)
    love.graphics.circle("fill", helpX, helpY, helpSize)
    
    -- Properly centered key symbol - BIGGER
    local smallFont = love.graphics.getFont()
    local keyTextWidth = smallFont:getWidth(keyLabel)
    local keyTextHeight = smallFont:getHeight()
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(keyLabel, 
        helpX - keyTextWidth/3, 
        helpY - keyTextHeight/3,
        0, 0.7, 0.7)  -- Significantly larger
    
    -- LARGER "?" indicator placed HIGHER above the button
    love.graphics.setColor(0.7, 0.7, 0.8, 0.8)  -- Brighter
    local helpLabel = "?"
    local helpLabelWidth = smallFont:getWidth(helpLabel)
    -- Position the ? significantly higher up
    love.graphics.print(helpLabel, 
        helpX - helpLabelWidth/3, 
        helpY - helpSize - smallFont:getHeight() - 2,  -- Position much higher above the button
        0, 0.7, 0.7)  -- Make it larger
    
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
        
        -- Handle both old and new cost formats
        local costText = ""
        local tokenCounts = {}  -- For new array-style format
        
        -- Check if this is the new array-style format (simple array of strings)
        local isNewFormat = type(cost[1]) == "string"
        
        if isNewFormat then
            -- Count each token type
            for _, tokenType in ipairs(cost) do
                tokenCounts[tokenType] = (tokenCounts[tokenType] or 0) + 1
            end
            
            -- Format the counts
            for tokenType, count in pairs(tokenCounts) do
                costText = costText .. count .. " " .. tokenType .. ", "
            end
        else
            -- Old format with type and count properties
            for _, component in ipairs(cost) do
                local typeText = component.type
                if type(typeText) == "table" then
                    typeText = table.concat(typeText, "/")
                end
                costText = costText .. component.count .. " " .. typeText .. ", "
            end
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
    local barHeight = 40
    local centerGap = 60 -- Space between bars in the center
    local barWidth = (screenWidth - centerGap) / 2
    local padding = 0 -- No padding from screen edges
    local y = 5
    
    -- Player 1 (Ashgar) health bar (left side, right-to-left depletion)
    local p1 = wizards[1]
    local display1 = UI.healthDisplay.player1
    
    -- Get the animated health percentage (from the delayed damage system)
    local p1HealthPercent = display1.currentHealth / 100
    local p1PendingDamagePercent = display1.pendingDamage / 100
    
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
    
    -- Calculate the total visible health (current + pending)
    local totalVisibleHealth = p1HealthPercent
    
    -- Draw gradient health bar for current health (excluding pending damage part)
    for i = 0, barWidth * p1HealthPercent, 1 do
        local gradientPos = i / (barWidth * p1HealthPercent)
        local r = ashgarGradient[1][1] + (ashgarGradient[2][1] - ashgarGradient[1][1]) * gradientPos
        local g = ashgarGradient[1][2] + (ashgarGradient[2][2] - ashgarGradient[1][2]) * gradientPos
        local b = ashgarGradient[1][3] + (ashgarGradient[2][3] - ashgarGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(padding + i, y + 2, padding + i, y + barHeight - 2)
    end
    
    -- Add a single halfway marker at 50% health, anchored to the bottom
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    local halfwayX = padding + (barWidth / 2)
    local markerHeight = barHeight / 2  -- The marker extends halfway up the bar
    love.graphics.line(halfwayX, y + barHeight - markerHeight, halfwayX, y + barHeight)
    
    -- Get actual health from the wizard for comparison
    local p1ActualHealthPercent = p1.health / 100
    
    -- Health lost "after damage" effect (fading darker region)
    -- This is displayed UNDER everything else, so draw it first
    local permanentDamageAmount = 1.0 - p1ActualHealthPercent
    if permanentDamageAmount > 0 then
        love.graphics.setColor(0.5, 0.1, 0.1, 0.3)
        love.graphics.rectangle("fill", 
            padding + barWidth * p1ActualHealthPercent, 
            y, 
            barWidth * permanentDamageAmount, 
            barHeight)
    end
    
    -- Pending damage effect (yellow bar segment)
    -- This shows the section of health that will drain away
    if p1PendingDamagePercent > 0 then
        -- Calculate where the pending damage begins and ends
        local pendingStart = p1HealthPercent  -- Where current health ends
        local pendingEnd = math.min(p1HealthPercent + p1PendingDamagePercent, p1ActualHealthPercent)
        local pendingWidth = pendingEnd - pendingStart
        
        -- Only draw if there's actual width to display
        if pendingWidth > 0 then
            -- Draw yellow segment for pending damage (as it's actually depleting)
            love.graphics.setColor(1.0, 0.9, 0.2, 0.8)
            
            -- Draw the pending section as yellow bars to match the health bar style
            for i = 0, barWidth * pendingWidth, 1 do
                local x = padding + barWidth * pendingStart + i
                love.graphics.line(x, y + 2, x, y + barHeight - 2)
            end
            
            -- Add some shading effects to the pending damage zone
            love.graphics.setColor(1.0, 1.0, 0.5, 0.2)
            love.graphics.rectangle("fill", 
                padding + barWidth * pendingStart, 
                y, 
                barWidth * pendingWidth, 
                barHeight/3)
        end
    end
    
    -- Gleaming highlight
    local time = love.timer.getTime()
    local hilight = math.abs(math.sin(time))
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", padding, y, barWidth * p1HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p1.name, padding + 20, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage only in debug mode
    if love.keyboard.isDown("`") then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(math.floor(p1HealthPercent * 100) .. "%", padding + barWidth - 40, y + 7)
    end
    
    
    -- Player 2 (Selene) health bar (right side, left-to-right depletion)
    local p2 = wizards[2]
    local display2 = UI.healthDisplay.player2
    
    -- Get the animated health percentage (from the delayed damage system)
    local p2HealthPercent = display2.currentHealth / 100
    local p2PendingDamagePercent = display2.pendingDamage / 100
    local p2X = screenWidth - barWidth
    
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
    
    -- Calculate the total visible health
    local totalVisibleHealth = p2HealthPercent
    
    -- Draw gradient health bar (left-to-right depletion)
    for i = 0, barWidth * p2HealthPercent, 1 do
        local gradientPos = i / (barWidth * p2HealthPercent)
        local r = seleneGradient[1][1] + (seleneGradient[2][1] - seleneGradient[1][1]) * gradientPos
        local g = seleneGradient[1][2] + (seleneGradient[2][2] - seleneGradient[1][2]) * gradientPos
        local b = seleneGradient[1][3] + (seleneGradient[2][3] - seleneGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(p2X + barWidth - i, y + 2, p2X + barWidth - i, y + barHeight - 2)
    end
    
    -- Add a single halfway marker at 50% health, anchored to the bottom
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    local halfwayX = p2X + (barWidth / 2)
    local markerHeight = barHeight / 2  -- The marker extends halfway up the bar
    love.graphics.line(halfwayX, y + barHeight - markerHeight, halfwayX, y + barHeight)
    
    -- Get actual health from the wizard for comparison
    local p2ActualHealthPercent = p2.health / 100
    
    -- Health lost "after damage" effect (fading darker region)
    -- This is displayed UNDER everything else, so draw it first
    local permanentDamageAmount = 1.0 - p2ActualHealthPercent
    if permanentDamageAmount > 0 then
        love.graphics.setColor(0.1, 0.1, 0.5, 0.3)
        love.graphics.rectangle("fill", p2X, y, barWidth * permanentDamageAmount, barHeight)
    end
    
    -- Pending damage effect (yellow bar segment)
    if p2PendingDamagePercent > 0 then
        -- Calculate where the pending damage begins and ends
        -- For player 2, the bar fills from right to left
        local pendingStart = 1.0 - p2HealthPercent  -- Where current health ends (from left)
        local pendingEnd = math.min(pendingStart + p2PendingDamagePercent, 1.0 - p2ActualHealthPercent)
        local pendingWidth = pendingEnd - pendingStart
        
        -- Only draw if there's actual width to display
        if pendingWidth > 0 then
            -- Draw yellow segment for pending damage (as it's actually depleting)
            love.graphics.setColor(1.0, 0.9, 0.2, 0.8)
            
            -- Draw the pending section as yellow bars to match the health bar style
            for i = 0, barWidth * pendingWidth, 1 do
                local x = p2X + barWidth * pendingStart + i
                love.graphics.line(x, y + 2, x, y + barHeight - 2)
            end
            
            -- Add some shading effects to the pending damage zone
            love.graphics.setColor(1.0, 1.0, 0.5, 0.2)
            love.graphics.rectangle("fill", 
                p2X + barWidth * pendingStart, 
                y, 
                barWidth * pendingWidth, 
                barHeight/3)
        end
    end
    
    -- Gleaming highlight
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", p2X + barWidth * (1 - p2HealthPercent), y, barWidth * p2HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p2.name, p2X + barWidth - 80, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage only in debug mode
    if love.keyboard.isDown("`") then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(math.floor(p2HealthPercent * 100) .. "%", p2X + 10, y + 7)
    end
end

-- [Removed drawActiveSpells function - now using visual representation instead]

-- Draw a full spellbook modal for a player
-- Update the health display animation
function UI.updateHealthDisplays(dt, wizards)
    local currentTime = love.timer.getTime()
    
    for i, wizard in ipairs(wizards) do
        local display = UI.healthDisplay["player" .. i]
        local actualHealth = wizard.health
        
        -- If actual health is different from our target, register new damage
        if actualHealth < display.targetHealth then
            -- Calculate how much new damage was taken
            local newDamage = display.targetHealth - actualHealth
            
            -- Add to pending damage
            display.pendingDamage = display.pendingDamage + newDamage
            
            -- Update target health to match actual health
            display.targetHealth = actualHealth
            
            -- Reset the damage timer to restart the delay
            display.lastDamageTime = currentTime
        end
        
        -- Check if we should start draining the pending damage
        if display.pendingDamage > 0 and (currentTime - display.lastDamageTime) > display.pendingDrainDelay then
            -- Calculate how much to drain based on time passed
            local drainAmount = display.drainRate * dt
            
            -- Don't drain more than what's pending
            drainAmount = math.min(drainAmount, display.pendingDamage)
            
            -- Reduce pending damage and update current health
            display.pendingDamage = display.pendingDamage - drainAmount
            display.currentHealth = display.currentHealth - drainAmount
            
            -- Ensure we don't go below target health
            if display.currentHealth < display.targetHealth then
                display.currentHealth = display.targetHealth
                display.pendingDamage = 0
            end
            
            -- Debug output to help track the animation
            -- print(string.format("Player %d: Health %.1f, Pending %.1f, Target %.1f", 
            --     i, display.currentHealth, display.pendingDamage, display.targetHealth))
        end
    end
end

function UI.drawSpellbookModal(wizard, playerNum, formatCost)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Determine position based on player number
    local modalX, modalTitle, keyPrefix
    if playerNum == 1 then
        modalX = 0  -- Pinned to left edge
        modalTitle = "Ashgar's Spellbook"
        keyPrefix = {"Q", "W", "E", "Q+W", "Q+E", "W+E", "Q+W+E"}
    else
        modalX = screenWidth - 400  -- Pinned to right edge
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
    love.graphics.rectangle("fill", modalX + 10, 90, 380, 100)
    love.graphics.setColor(1, 1, 1, 0.9)
    
    if playerNum == 1 then
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("Q/W/E: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("F: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("G: Free all active spells and return mana", modalX + 30, 155)
        love.graphics.print("B: Toggle spellbook visibility", modalX + 30, 175)
    else
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("I/O/P: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("J: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("H: Free all active spells and return mana", modalX + 30, 155)
        love.graphics.print("M: Toggle spellbook visibility", modalX + 30, 175)
    end
    
    -- Spells section
    local y = 200
    
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


return UI