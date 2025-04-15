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
            ["23"] = Spells.firebolt, -- Placeholder, could be a new spell
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
            ["23"] = Spells.mist,     -- Placeholder, could be a new spell
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
    end
    
    -- Draw wizard elevation indicator
    love.graphics.setColor(self.color[1]/255, self.color[2]/255, self.color[3]/255)
    love.graphics.print(self.elevation, self.x - 20, self.y + 60)
    
    -- Draw stun indicator if stunned
    if self.stunTimer > 0 then
        love.graphics.setColor(1, 1, 0, 0.7 + math.sin(love.timer.getTime() * 8) * 0.3)
        love.graphics.print("STUNNED", self.x - 30, self.y - 70)
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.print(string.format("%.1fs", self.stunTimer), self.x - 10, self.y - 55)
    end
    
    -- Draw blocker indicators
    if self.blockers.projectile > 0 then
        -- Mist veil (projectile block) active indicator
        love.graphics.setColor(0.6, 0.6, 1, 0.6 + math.sin(love.timer.getTime() * 4) * 0.3)
        love.graphics.print("MIST SHIELD", self.x - 40, self.y - 100)
        love.graphics.setColor(0.7, 0.7, 1, 0.4)
        love.graphics.print(string.format("%.1fs", self.blockers.projectile), self.x - 10, self.y - 85)
        
        -- Draw a subtle shield aura
        local shieldRadius = 60
        local pulseAmount = 5 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.5, 0.5, 1, 0.2)
        love.graphics.circle("fill", self.x, self.y, shieldRadius + pulseAmount)
        love.graphics.setColor(0.7, 0.7, 1, 0.3)
        love.graphics.circle("line", self.x, self.y, shieldRadius + pulseAmount)
    end
    
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
    
    -- Draw currently keyed spell
    if self.currentKeyedSpell then
        love.graphics.setColor(1, 1, 0.5, 0.8)
        love.graphics.print("READY: " .. self.currentKeyedSpell.name, self.x - 40, self.y - 90)
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
        
        -- Z-ordering: draw the back half of the ellipse first (lower alpha)
        if slot.active then
            love.graphics.setColor(0.8, 0.8, 0.2, 0.3)  -- Active slot, back half
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.2)  -- Inactive slot, back half
        end
        
        -- Draw back half of the ellipse (π to 2π, right side going behind character)
        love.graphics.arc("line", "open", self.x, slotY, radiusX, math.pi, math.pi * 2, 16)
        
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
        
        -- Now draw the front half of the ellipse (0 to π, left side in front of character)
        if slot.active then
            love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Active slot, front half
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.4)  -- Inactive slot, front half
        end
        
        -- Draw front half of the ellipse
        love.graphics.arc("line", "open", self.x, slotY, radiusX, 0, math.pi, 16)
        
        -- If slot is active, draw progress arc and spell name
        if slot.active then
            -- Calculate progress angle (0 to 2*pi)
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            -- Draw progress arc, respecting the front/back z-ordering
            -- First the back half of the progress arc (if it extends that far)
            if progressAngle > math.pi then
                love.graphics.setColor(0.8, 0.8, 0.2, 0.3)  -- Lower alpha for back
                love.graphics.arc("line", "open", self.x, slotY, radiusX, math.pi, progressAngle, 16)
            end
            
            -- Then the front half of the progress arc
            love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Higher alpha for front
            love.graphics.arc("line", "open", self.x, slotY, radiusX, 0, math.min(progressAngle, math.pi), 16)
            
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
                -- Try to get tokens of this type
                for _ = 1, costCount do
                    local token, index = self.manaPool:findFreeToken(modalType)
                    if token then
                        table.insert(tokenReservations, {token = token, index = index})
                        paid = true
                        break
                    end
                end
                if paid then break end
            end
            
            if not paid then
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available token types
                local availableTypes = {}
                local availableIndices = {}
                
                -- Check each mana type and gather available ones
                for _, tokenType in ipairs({"fire", "force", "moon", "nature", "star"}) do
                    local token, index = self.manaPool:findFreeToken(tokenType)
                    if token then
                        table.insert(availableTypes, tokenType)
                        table.insert(availableIndices, index)
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTypes > 0 then
                    -- Shuffle the available types for true randomness
                    for i = #availableTypes, 2, -1 do
                        local j = math.random(i)
                        availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
                        availableIndices[i], availableIndices[j] = availableIndices[j], availableIndices[i]
                    end
                    
                    -- Use the first type after shuffling
                    local randomIndex = availableIndices[1]
                    local token = self.manaPool.tokens[randomIndex]
                    
                    table.insert(tokenReservations, {token = token, index = randomIndex})
                else
                    return nil
                end
            end
        else
            -- Specific type cost
            for _ = 1, costCount do
                local token, index = self.manaPool:findFreeToken(costType)
                if token then
                    table.insert(tokenReservations, {token = token, index = index})
                else
                    return nil
                end
            end
        end
    end
    
    return tokenReservations
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
    
    -- Check for projectile blocking
    if effect.spellType == "projectile" and target.blockers.projectile > 0 then
        -- Target has an active projectile block
        print(target.name .. " blocked " .. slot.spellType .. " with Mist Veil!")
        
        -- Create a visual effect for the block (will be enhanced later)
        target.blockVFX = {
            active = true,
            timer = 0.5,  -- Duration of the block visual effect
            x = target.x,
            y = target.y
        }
        
        -- Don't consume the block, it remains active for its duration
        return  -- Skip applying any effects
    end
    
    -- Apply blocking effects (like Mist Veil)
    if effect.block then
        if effect.block == "projectile" then
            local duration = effect.blockDuration or 2.5  -- Default to 2.5s if not specified
            self.blockers.projectile = duration
            print(self.name .. " activated projectile blocking for " .. duration .. " seconds")
        end
    end
    
    -- Apply damage
    if effect.damage and effect.damage > 0 then
        target.health = target.health - effect.damage
        if target.health < 0 then target.health = 0 end
        print(target.name .. " took " .. effect.damage .. " damage (health: " .. target.health .. ")")
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
        print(self.name .. " moved to " .. self.elevation .. " elevation")
    end
    
    -- Apply stun
    if effect.stun and effect.stun > 0 then
        target.stunTimer = effect.stun
        print(target.name .. " is stunned for " .. effect.stun .. " seconds")
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

return Wizard