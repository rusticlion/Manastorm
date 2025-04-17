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
    UI.drawPlayerSpellbook(2, screenWidth - 260, screenHeight - 70)
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
    
    -- GROUP 2: CAST BUTTON & FREE BUTTON
    -- Calculate positions for both buttons
    local castX = x + 140
    local freeX = x + 190
    local castKey = (playerNum == 1) and "F" or "J"
    local freeKey = (playerNum == 1) and "G" or "H"
    
    -- CAST BUTTON
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
    
    -- FREE BUTTON
    -- Subtle highlighting background
    love.graphics.setColor(0.1, 0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", freeX - 20, centerY - 20, 40, 40, 5, 5)  -- Rounded corners
    
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
    
    -- Small "free" label beneath
    love.graphics.setColor(0.5, 0.7, 0.9, 0.8)
    local freeLabel = "Free"
    local freeLabelWidth = love.graphics.getFont():getWidth(freeLabel)
    love.graphics.print(freeLabel, freeX - freeLabelWidth/2, inputY + runeSize + 8)
    
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