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
    local y = love.graphics.getHeight() - 70
    love.graphics.print("Debug Controls: T (Add tokens), R (Toggle range), A/S (Toggle elevations), ESC (Quit)", 10, y + 50)
    
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
    local width = 200
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
    
    -- Draw active key indicators as glowing runes on the book
    local runeX = x + 20
    local runeY = y + height/2 - 10
    local runeSize = 14
    local runeSpacing = 30
    
    for i = 1, 3 do
        -- Draw rune background
        love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
        love.graphics.circle("fill", runeX + (i-1)*runeSpacing, runeY, runeSize)
        
        if wizard.activeKeys[i] then
            -- Active rune with glow effect
            -- Multiple layers for glow
            for j = 3, 1, -1 do
                local alpha = 0.3 * (4-j) / 3
                local size = runeSize + j * 2
                love.graphics.setColor(1, 1, 0.3, alpha)
                love.graphics.circle("fill", runeX + (i-1)*runeSpacing, runeY, size)
            end
            
            -- Bright center
            love.graphics.setColor(1, 1, 0.7, 0.9)
            love.graphics.circle("fill", runeX + (i-1)*runeSpacing, runeY, runeSize * 0.7)
            
            -- Rune symbol
            love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
            love.graphics.print(keyPrefix[i], runeX + (i-1)*runeSpacing - 4, runeY - 7)
        else
            -- Inactive rune
            love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
            love.graphics.circle("line", runeX + (i-1)*runeSpacing, runeY, runeSize)
            
            -- Inactive symbol
            love.graphics.setColor(0.6, 0.6, 0.7, 0.6)
            love.graphics.print(keyPrefix[i], runeX + (i-1)*runeSpacing - 4, runeY - 7)
        end
    end
    
    -- Draw spellbook open control
    local openX = x + 135
    love.graphics.setColor(0.7, 0.7, 0.8, 0.8)
    love.graphics.print("Open", openX, y + 10)
    love.graphics.print("Spellbook", openX, y + 25)
    
    -- Draw key hint
    love.graphics.setColor(1, 1, 0.4, 0.9)
    love.graphics.circle("fill", openX + 40, y + 18, 10)
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.print(keyLabel, openX + 37, y + 13)
    
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
    
    -- Function to display spell casting progress
    local function formatProgress(slot)
        return math.floor(slot.progress * 100 / slot.castTime) .. "%"
    end
    
    -- Draw the fighting game style health bars
    UI.drawHealthBars(wizards)
    
    -- Always show active spells for both wizards (compact view)
    UI.drawActiveSpells(wizards, formatProgress)
    
    -- Draw spellbook popups if visible
    if UI.spellbookVisible.player1 then
        UI.drawSpellbookModal(wizards[1], 1, formatCost)
    end
    
    if UI.spellbookVisible.player2 then
        UI.drawSpellbookModal(wizards[2], 2, formatCost)
    end
    
    -- Draw mana pool stats (always visible)
    UI.drawManaPoolStats(wizards[1].manaPool)
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
    
    -- Name plate
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", padding, y - 20, 120, 20)
    love.graphics.setColor(1, 0.9, 0.3, 0.9)
    love.graphics.print(p1.name, padding + 10, y - 17)
    
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
    
    -- Name plate
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", p2X + barWidth - 120, y - 20, 120, 20)
    love.graphics.setColor(1, 0.9, 0.3, 0.9)
    love.graphics.print(p2.name, p2X + barWidth - 110, y - 17)
    
    -- Health percentage
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(math.floor(p2HealthPercent * 100) .. "%", p2X + 10, y + 7)
end

-- Draw active spells for both wizards (always visible)
function UI.drawActiveSpells(wizards, formatProgress)
    -- Position the active spells below each wizard's spell slots
    -- The largest orbit radius is 110 (from wizard.lua drawSpellSlots)
    -- Adding some padding to position below the slots
    
    -- Active spells for Player 1 (Ashgar)
    local screenHeight = love.graphics.getHeight()
    local player1Y = screenHeight - 150
    love.graphics.setColor(wizards[1].color[1]/255, wizards[1].color[2]/255, wizards[1].color[3]/255)
    love.graphics.print("Active Spells:", wizards[1].x - 50, player1Y)
    
    local activeCount = 0
    for i, slot in ipairs(wizards[1].spellSlots) do
        if slot.active then
            love.graphics.print("Slot " .. i .. ": " .. slot.spellType .. " (" .. formatProgress(slot) .. ")", wizards[1].x - 40, player1Y + (activeCount + 1) * 20)
            activeCount = activeCount + 1
        end
    end
    if activeCount == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.7)
        love.graphics.print("(None)", wizards[1].x - 40, player1Y + 20)
    end
    
    -- Show active effects for Player 1
    if wizards[1].blockers.projectile > 0 then
        love.graphics.setColor(0.6, 0.6, 1, 0.8)
        love.graphics.print("Projectile Block: " .. string.format("%.1fs", wizards[1].blockers.projectile), wizards[1].x - 50, player1Y + (activeCount + 1) * 20 + 10)
    end
    
    -- Active spells for Player 2 (Selene)
    local player2Y = screenHeight - 150
    love.graphics.setColor(wizards[2].color[1]/255, wizards[2].color[2]/255, wizards[2].color[3]/255)
    love.graphics.print("Active Spells:", wizards[2].x - 50, player2Y)
    
    activeCount = 0
    for i, slot in ipairs(wizards[2].spellSlots) do
        if slot.active then
            love.graphics.print("Slot " .. i .. ": " .. slot.spellType .. " (" .. formatProgress(slot) .. ")", wizards[2].x - 40, player2Y + (activeCount + 1) * 20)
            activeCount = activeCount + 1
        end
    end
    if activeCount == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.7)
        love.graphics.print("(None)", wizards[2].x - 40, player2Y + 20)
    end
    
    -- Show active effects for Player 2
    if wizards[2].blockers.projectile > 0 then
        love.graphics.setColor(0.6, 0.6, 1, 0.8)
        love.graphics.print("Projectile Block: " .. string.format("%.1fs", wizards[2].blockers.projectile), wizards[2].x - 50, player2Y + (activeCount + 1) * 20 + 10)
    end
end

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

-- Draw mana pool stats
function UI.drawManaPoolStats(manaPool)
    -- Draw mana pool stats
    love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
    local poolX = love.graphics.getWidth() / 2 - 50
    love.graphics.print("Mana Pool:", poolX, 150)
    
    -- Count free tokens by type
    local counts = {fire = 0, force = 0, moon = 0, nature = 0, star = 0}
    for _, token in ipairs(manaPool.tokens) do
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
    
    -- Count tokens by state
    local free, channeled, locked = 0, 0, 0
    for _, token in ipairs(manaPool.tokens) do
        if token.state == "FREE" then free = free + 1
        elseif token.state == "CHANNELED" then channeled = channeled + 1
        elseif token.state == "LOCKED" then locked = locked + 1
        end
    end
    
    -- Display token counts by state
    love.graphics.print("Free: " .. free .. ", Channeled: " .. channeled, poolX - 30, 250)
    
    -- Display locked tokens with a highlight if any are locked
    if locked > 0 then
        love.graphics.setColor(1, 0.5, 0.5, 0.8)
        love.graphics.print("Locked: " .. locked, poolX - 30, 270)
    else
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
        love.graphics.print("Locked: 0", poolX - 30, 270)
    end
end

return UI