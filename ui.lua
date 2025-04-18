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
-- Each player can now independently toggle their spellbook without affecting the other
function UI.toggleSpellbook(player)
    if player == 1 then
        UI.spellbookVisible.player1 = not UI.spellbookVisible.player1
    elseif player == 2 then
        UI.spellbookVisible.player2 = not UI.spellbookVisible.player2
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
    
    -- Highlight when active - just color tint, no white outline
    if (playerNum == 1 and UI.spellbookVisible.player1) or 
       (playerNum == 2 and UI.spellbookVisible.player2) then
        love.graphics.setColor(color[1], color[2], color[3], 0.4)
        love.graphics.rectangle("fill", x, y, width, height)
        -- Removed white outline rectangle
    end
end

function UI.drawSpellInfo(wizards)
    -- Function to format mana cost for display
    local function formatCost(cost)
        if not cost or #cost == 0 then
            return "Free"
        end
        
        -- Handle both old and new cost formats
        local regularTokens = {}
        local anyTokens = {}
        
        -- Check if this is the new array-style format (simple array of strings)
        local isNewFormat = type(cost[1]) == "string"
        
        if isNewFormat then
            -- Collect each token individually, separating "any" tokens
            for _, tokenType in ipairs(cost) do
                if tokenType:lower() == "any" then
                    table.insert(anyTokens, tokenType)
                else
                    table.insert(regularTokens, tokenType)
                end
            end
        else
            -- Old format with type and count properties
            for _, component in ipairs(cost) do
                local typeText = component.type
                local isAnyToken = false
                
                if type(typeText) == "table" then
                    typeText = table.concat(typeText, "/")
                end
                
                if typeText:lower() == "any" then
                    isAnyToken = true
                end
                
                -- Add the token the appropriate number of times
                for i = 1, component.count do
                    if isAnyToken then
                        table.insert(anyTokens, typeText)
                    else
                        table.insert(regularTokens, typeText)
                    end
                end
            end
        end
        
        -- Combine regular tokens and any tokens (any tokens always last)
        local allTokens = {}
        for _, token in ipairs(regularTokens) do
            table.insert(allTokens, token)
        end
        for _, token in ipairs(anyTokens) do
            table.insert(allTokens, token)
        end
        
        -- Build the final cost text
        if #allTokens == 0 then
            return "Free"
        else
            return table.concat(allTokens, ", ")
        end
    end
    
    -- Draw the fighting game style health bars
    UI.drawHealthBars(wizards)
    
    -- Note: spellbook modals are now drawn separately to ensure proper z-ordering
    -- Spell notification is now handled by the wizard's castSpell function
end

-- Function to draw spellbook modals (now separated to ensure proper z-ordering)
function UI.drawSpellbookModals(wizards)
    -- Local function to format costs for spellbook display
    local function formatCost(cost)
        if not cost or #cost == 0 then
            return "Free"
        end
        
        -- Handle both old and new cost formats
        local regularTokens = {}
        local anyTokens = {}
        
        -- Check if this is the new array-style format (simple array of strings)
        local isNewFormat = type(cost[1]) == "string"
        
        if isNewFormat then
            -- Collect each token individually, separating "any" tokens
            for _, tokenType in ipairs(cost) do
                if tokenType:lower() == "any" then
                    table.insert(anyTokens, tokenType)
                else
                    table.insert(regularTokens, tokenType)
                end
            end
        else
            -- Old format with type and count properties
            for _, component in ipairs(cost) do
                local typeText = component.type
                local isAnyToken = false
                
                if type(typeText) == "table" then
                    typeText = table.concat(typeText, "/")
                end
                
                if typeText:lower() == "any" then
                    isAnyToken = true
                end
                
                -- Add the token the appropriate number of times
                for i = 1, component.count do
                    if isAnyToken then
                        table.insert(anyTokens, typeText)
                    else
                        table.insert(regularTokens, typeText)
                    end
                end
            end
        end
        
        -- Combine regular tokens and any tokens (any tokens always last)
        local allTokens = {}
        for _, token in ipairs(regularTokens) do
            table.insert(allTokens, token)
        end
        for _, token in ipairs(anyTokens) do
            table.insert(allTokens, token)
        end
        
        -- Build the final cost text
        if #allTokens == 0 then
            return "Free"
        else
            return table.concat(allTokens, ", ")
        end
    end
    
    -- Draw spellbook popups if visible
    if UI.spellbookVisible.player1 then
        UI.drawSpellbookModal(wizards[1], 1, formatCost)
    end
    
    if UI.spellbookVisible.player2 then
        UI.drawSpellbookModal(wizards[2], 2, formatCost)
    end
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
    
    -- Determine position based on player number
    local modalX, keyPrefix
    if playerNum == 1 then
        modalX = 0  -- Pinned to left edge
        keyPrefix = {"Q", "W", "E", "QW", "QE", "WE", "QWE"}
    else
        modalX = screenWidth - 400  -- Pinned to right edge
        keyPrefix = {"I", "O", "P", "IO", "IP", "OP", "IOP"}
    end
    
    -- Define the key combinations and their corresponding keyNames
    local keyMappings = {
        {index = 1, keyName = "1"}, -- Q or I
        {index = 2, keyName = "2"}, -- W or O
        {index = 3, keyName = "3"}, -- E or P
        {index = 4, keyName = "12"}, -- QW or IO
        {index = 5, keyName = "13"}, -- QE or IP
        {index = 6, keyName = "23"}, -- WE or OP
        {index = 7, keyName = "123"} -- QWE or IOP
    }
    
    -- Count spells to calculate modal height dynamically
    local spellCount = 0
    for _, mapping in ipairs(keyMappings) do
        if wizard.spellbook[mapping.keyName] then
            spellCount = spellCount + 1
        end
    end
    
    -- Calculate modal height based on fixed components plus variable spell entries
    -- Components: title(30) + controls(120) + heading(25) + spellEntries(45 each) + no extra padding
    -- We end the component right after the last entry, letting the standard spacing between entries provide the visual margin
    local modalHeight = 175 + (spellCount * 45)
    
    -- Modal background - fully opaque to properly obscure what's behind it
    love.graphics.setColor(0.1, 0.1, 0.2, 1.0)  -- Fully opaque
    love.graphics.rectangle("fill", modalX, 50, 400, modalHeight)
    love.graphics.setColor(0.4, 0.4, 0.6, 1.0)  -- Fully opaque border
    love.graphics.rectangle("line", modalX, 50, 400, modalHeight)
    
    -- Modal title - simplified to just wizard name
    love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(wizard.name, modalX + 190, 60)
    
    -- Close button with appropriate hotkey instead of X
    local closeKey = (playerNum == 1) and "B" or "M"
    love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
    love.graphics.rectangle("fill", modalX + 370, 50, 30, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(closeKey, modalX + 380, 60)
    
    -- Controls help section at the top of the modal
    love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
    love.graphics.rectangle("fill", modalX + 10, 90, 380, 100)
    love.graphics.setColor(1, 1, 1, 0.9)
    
    if playerNum == 1 then
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("QWE: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("F: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("G: Free all active spells and return mana", modalX + 30, 155)
        love.graphics.print("B: Toggle spellbook visibility", modalX + 30, 175)
    else
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("IOP: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("J: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("H: Free all active spells and return mana", modalX + 30, 155)
        love.graphics.print("M: Toggle spellbook visibility", modalX + 30, 175)
    end
    
    -- Spells section
    local y = 200
    
    -- Spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Spellbook", modalX + 170, y + 5)
    y = y + 30
    
    -- Display all spells in a single unified list
    for _, mapping in ipairs(keyMappings) do
        local spell = wizard.spellbook[mapping.keyName]
        if spell then
            -- Check if this is the currently keyed spell
            local isCurrentSpell = wizard.currentKeyedSpell and wizard.currentKeyedSpell.name == spell.name
            
            -- Use a different background color to highlight the currently keyed spell
            if isCurrentSpell then
                -- Glowing highlight effect for the active spell
                -- Draw multiple layers with decreasing alpha for a glow effect
                for i = 3, 1, -1 do
                    local alpha = 0.15 * (4-i) / 3
                    local padding = i * 2
                    love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, alpha)
                    love.graphics.rectangle("fill", 
                        modalX + 10 - padding, 
                        y - padding, 
                        380 + padding*2, 
                        40 + padding*2, 
                        5, 5)
                end
                
                -- Brighter inner background for current spell
                love.graphics.setColor(0.25, 0.25, 0.35, 0.9)
            else
                -- Standard background for other spells
                love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            end
            
            -- Draw the spell entry background
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            
            -- Add a subtle border for the currently keyed spell
            if isCurrentSpell then
                love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.7)
                love.graphics.rectangle("line", modalX + 10, y, 380, 40)
            end
            
            -- Draw spell name with brighter color if it's the current spell
            if isCurrentSpell then
                love.graphics.setColor(1, 1, 0.8, 1.0)  -- Brighter color for active spell
            else
                love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            end
            love.graphics.print(keyPrefix[mapping.index] .. ": " .. spell.name, modalX + 20, y + 5)
            
            -- Draw spell details with appropriate color
            if isCurrentSpell then
                love.graphics.setColor(0.9, 0.9, 0.9, 1.0)  -- Brighter text for active spell
            else
                love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            end
            
            -- Convert cast time to "x" characters instead of numbers
            local castTimeVisual = string.rep("x", spell.castTime)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. castTimeVisual, modalX + 30, y + 25)
            y = y + 45  -- Restore original spacing between spell entries
        end
    end
end

return UI