-- Wizard class

local Wizard = {}
Wizard.__index = Wizard

-- Load required modules
local Constants = require("core.Constants")
local SpellsModule = require("spells")
local Spells = SpellsModule.spells
local ShieldSystem = require("systems.ShieldSystem")
local WizardVisuals = require("systems.WizardVisuals")
local TokenManager = require("systems.TokenManager")
local UnlockSystem = require("systems.UnlockSystem")
local BlockedCastLifecycle = require("systems.wizard.BlockedCastLifecycle")
local CastExecution = require("systems.wizard.CastExecution")

-- Fallback cleanup time in case a blocked spell's VFX callback is missed.
local BLOCKED_IMPACT_FALLBACK_SECONDS = 2.0

-- We'll use game.compiledSpells instead of a local compiled spells table

-- Get a compiled spell by ID, compile on demand if not already compiled
local function getCompiledSpell(spellId, wizard)
    -- Make sure we have a game reference
    if not wizard or not wizard.gameState then
        print("Error: No wizard or gameState to get compiled spell")
        return nil
    end
    
    local gameState = wizard.gameState
    
    -- Try to get from game's compiled spells
    if gameState.compiledSpells and gameState.compiledSpells[spellId] then
        return gameState.compiledSpells[spellId]
    end
    
    -- If not found, try to compile on demand
    if Spells[spellId] and gameState.spellCompiler and gameState.keywords then
        -- Make sure compiledSpells exists
        if not gameState.compiledSpells then
            gameState.compiledSpells = {}
        end
        
        -- Compile the spell and store it
        gameState.compiledSpells[spellId] = gameState.spellCompiler.compileSpell(
            Spells[spellId], 
            gameState.keywords
        )
        print("Compiled spell on demand: " .. spellId)
        return gameState.compiledSpells[spellId]
    else
        print("Error: Could not compile spell with ID: " .. spellId)
        return nil
    end
end

function Wizard.new(name, x, y, color, spellbook)
    local self = setmetatable({}, Wizard)
    
    self.name = name
    self.x = x
    self.y = y
    self.color = color  -- RGB table
    
    -- Wizard state
    self.health = 100
    self.elevation = Constants.ElevationState.GROUNDED  -- GROUNDED or AERIAL
    self.elevationTimer = 0      -- Timer for temporary elevation changes
    
    -- Position animation state
    self.positionAnimation = {
        active = false,
        startX = 0,
        startY = 0, 
        targetX = 0,
        targetY = 0,
        progress = 0,
        duration = 0.3 -- 300ms animation by default
    }
    
    -- Status effects
    self.statusEffects = {
        [Constants.StatusType.BURN] = {
            active = false,
            duration = 0,
            tickDamage = 0,
            tickInterval = 1.0,
            elapsed = 0,         -- Time since last tick
            totalTime = 0        -- Total time effect has been active
        },
        [Constants.StatusType.STUN] = {
            active = false,
            duration = 0,
            elapsed = 0,
            totalTime = 0
        }
    }
    
    -- Visual effects
    self.blockVFX = {
        active = false,
        timer = 0,
        x = 0,
        y = 0
    }
    
    -- Hit flash effect
    self.hitFlashTimer = 0

    -- Cast frame animation properties
    self.castFrameSprite = nil
    self.castFrameTimer = 0
    self.castFrameDuration = 0.25 -- Show cast frame for 0.25 seconds

    -- Idle animation properties
    self.idleAnimationFrames = {}
    self.currentIdleFrame = 1
    self.idleFrameTimer = 0
    self.idleFrameDuration = 0.15 -- seconds per frame
    -- Positional animation sets (per range/elevation combo)
    self.positionalAnimations = {}
    self.lastPositionalKey = nil

    -- Spell cast notification (temporary until proper VFX)
    self.spellCastNotification = nil
    
    -- Spell keying system
    self.activeKeys = {
        [1] = false,
        [2] = false,
        [3] = false
    }
    self.currentKeyedSpell = nil
    
    -- Spell loadout provided by character data
    self.spellbook = spellbook or {}
    
    -- Create 3 spell slots for this wizard
    self.spellSlots = {}
    for i = 1, 3 do
        self.spellSlots[i] = {
            active = false,
            progress = 0,
            castTime = 0,
            spell = nil,
            spellType = nil,
            tokens = {},
            isShield = false,
            defenseType = nil,
            blocksAttackTypes = nil,
            reflect = false,
            frozen = false,
            freezeTimer = 0,
            castTimeModifier = 0, -- Additional time from freeze effects
            willBecomeShield = false,
            wasAlreadyCast = false, -- Track if the spell has already been cast
            blockedPendingImpact = false,
            blockImpactTimer = 0,
            blockImpactTimeout = nil
        }
    end
    
    -- Load sprite with fallback
    local spritePath = "assets/sprites/" .. string.lower(name) .. ".png"
    local success, result = pcall(function()
        return love.graphics.newImage(spritePath)
    end)

    if success then
        self.sprite = result
        print("Loaded wizard sprite: " .. spritePath)
    else
        -- Fallback to default wizard sprite
        print("Warning: Could not load sprite " .. spritePath .. ". Using default wizard.png instead.")
        self.sprite = love.graphics.newImage("assets/sprites/wizard.png")
    end

    -- Load cast frame sprite with fallback
    local castFramePath = "assets/sprites/" .. string.lower(name) .. "-cast.png"
    local castSuccess, castResult = pcall(function()
        return love.graphics.newImage(castFramePath)
    end)

    if castSuccess then
        self.castFrameSprite = castResult
        print("Loaded wizard cast frame: " .. castFramePath)
    else
        -- No fallback for cast frame, just leave it nil
        print("Warning: Could not load cast frame " .. castFramePath .. ". Cast animation will be disabled.")
    end

    -- Load default idle animation frames (used as fallback for positional sets)
    if name == "Ashgar" then
        local AssetCache = require("core.AssetCache")
        for i = 1, 7 do
            local framePath = "assets/sprites/" .. string.lower(name) .. "-idle-" .. i .. ".png"
            local frameImg = AssetCache.getImage(framePath)
            if frameImg then
                table.insert(self.idleAnimationFrames, frameImg)
            else
                print("Warning: Could not load Ashgar idle frame: " .. framePath)
                table.insert(self.idleAnimationFrames, self.sprite)
            end
        end
        if #self.idleAnimationFrames == 0 then
            print("Warning: Ashgar has no idle animation frames loaded, using static sprite.")
            table.insert(self.idleAnimationFrames, self.sprite)
        end
    else
        table.insert(self.idleAnimationFrames, self.sprite)
    end

    -- Load positional animation sets (idle + cast for range/elevation combos)
    self:loadPositionalAnimations()

    self.scale = 1.0
    
    -- Keep references
    self.gameState = _G.game  -- Reference to global game state
    self.manaPool = self.gameState.manaPool
    
    -- Track UI offsets
    self.currentXOffset = 0
    self.currentYOffset = 0
    
    -- Flags for spell-side transient effects
    self.justConjuredMana = false
    
    return self
end

function Wizard:update(dt)
    -- Reset flags at the beginning of each frame
    self.justConjuredMana = false

    -- Update hit flash timer
    if self.hitFlashTimer > 0 then
        self.hitFlashTimer = math.max(0, self.hitFlashTimer - dt)
    end

    -- Update cast frame timer
    if self.castFrameTimer > 0 then
        self.castFrameTimer = math.max(0, self.castFrameTimer - dt)
    end

    -- Update idle animation timer and frame based on positional state
    local posKey = self:getPositionalKey()

    if posKey ~= self.lastPositionalKey then
        self.currentIdleFrame = 1
        self.idleFrameTimer = 0
        self.lastPositionalKey = posKey
    end

    local idleFrames = self:getIdleFramesForKey(posKey)

    if self.castFrameTimer <= 0 then
        self.idleFrameTimer = self.idleFrameTimer + dt
        if self.idleFrameTimer >= self.idleFrameDuration then
            self.idleFrameTimer = self.idleFrameTimer - self.idleFrameDuration
            self.currentIdleFrame = self.currentIdleFrame + 1
            if self.currentIdleFrame > #idleFrames then
                self.currentIdleFrame = 1
            end
        end
    else
        self.currentIdleFrame = 1
        self.idleFrameTimer = 0
    end
    
    -- Update position animation
    if self.positionAnimation.active then
        self.positionAnimation.progress = self.positionAnimation.progress + dt / self.positionAnimation.duration
        
        -- Check if animation is complete
        if self.positionAnimation.progress >= 1.0 then
            self.positionAnimation.active = false
            self.positionAnimation.progress = 1.0
            self.currentXOffset = self.positionAnimation.targetX
            self.currentYOffset = self.positionAnimation.targetY
        end
    end
    
    -- Update shield visuals using ShieldSystem
    ShieldSystem.updateShieldVisuals(self, dt)
    
    -- Update block effect
    if self.blockVFX.active then
        self.blockVFX.timer = self.blockVFX.timer - dt
        if self.blockVFX.timer <= 0 then
            self.blockVFX.active = false
        end
    end
    
    -- Update cast notification
    if self.spellCastNotification then
        self.spellCastNotification.timer = self.spellCastNotification.timer - dt
        if self.spellCastNotification.timer <= 0 then
            self.spellCastNotification = nil
        end
    end
    
    -- Update spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            if slot.isShield then
                -- Shields remain active and don't progress further
                -- But we still need to update token orbits, which happens below
            else
                if not BlockedCastLifecycle.updatePending(
                    self,
                    i,
                    slot,
                    dt,
                    BLOCKED_IMPACT_FALLBACK_SECONDS
                ) then
                    -- For frozen spells, don't increment progress but accumulate castTimeModifier
                    if slot.frozen then
                        -- Track the total freeze time as castTimeModifier
                        slot.castTimeModifier = (slot.castTimeModifier or 0) + dt
                        
                        -- Decrease freeze timer
                        slot.freezeTimer = slot.freezeTimer - dt
                        if slot.freezeTimer <= 0 then
                            slot.frozen = false
                            print(string.format("%s's spell in slot %d is no longer frozen after %.2f seconds (%.4f castTimeModifier)", 
                                self.name, i, slot.castTimeModifier, slot.castTimeModifier))
                        end
                    else
                        -- Normal progress update for unfrozen spells
                        slot.progress = slot.progress + dt
                        
                        -- ONLY check for spell completion when NOT frozen
                        if slot.progress >= slot.castTime and not slot.wasAlreadyCast then
                            -- Mark this slot as already cast to prevent repeated casting
                            slot.wasAlreadyCast = true
                            
                            -- CastExecution/castSpell now owns blocked-cast setup and slot cleanup.
                            self:castSpell(i)
                            
                            -- Debug message to confirm we're setting the flag
                            print(string.format("[DEBUG] Marked slot %d as already cast to prevent repetition", i))
                        end
                    end
                end
            end
        end
    end

    -- Update visual particles for spell slot arcs
    WizardVisuals.updateArcParticles(self, dt)
end

function Wizard:draw()
    -- Use WizardVisuals module for drawing
    WizardVisuals.drawWizard(self)
end

-- Helper function to draw an ellipse (delegated to WizardVisuals)
function Wizard:drawEllipse(x, y, radiusX, radiusY, mode)
    return WizardVisuals.drawEllipse(x, y, radiusX, radiusY, mode)
end

-- Helper function to draw an elliptical arc (delegated to WizardVisuals)
function Wizard:drawEllipticalArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
    return WizardVisuals.drawEllipticalArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
end

-- Draw status effects with durations using horizontal bars (delegated to WizardVisuals)
function Wizard:drawStatusEffects()
    return WizardVisuals.drawStatusEffects(self)
end

function Wizard:drawSpellSlots()
    -- Delegate to WizardVisuals module
    return WizardVisuals.drawSpellSlots(self)
end

-- Handle key press and update currently keyed spell
function Wizard:keySpell(keyIndex, isPressed)
    -- Check if wizard is stunned
    local stun = self.statusEffects[Constants.StatusType.STUN]
    if stun and stun.active and isPressed then
        local remaining = stun.duration > 0 and (stun.duration - stun.totalTime) or 0
        print(self.name .. " tried to key a spell but is stunned for " .. string.format("%.1f", remaining) .. " more seconds")
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
    local stun = self.statusEffects[Constants.StatusType.STUN]
    if stun and stun.active then
        local remaining = stun.duration > 0 and (stun.duration - stun.totalTime) or 0
        print(self.name .. " tried to cast a spell but is stunned for " .. string.format("%.1f", remaining) .. " more seconds")
        return false
    end
    
    -- Check if a spell is keyed
    if not self.currentKeyedSpell then
        print(self.name .. " tried to cast, but no spell is keyed")
        return false
    end
    
    -- Queue the spell
    return self:queueSpell(self.currentKeyedSpell)
end

-- Format mana cost for display
function Wizard:formatCost(cost)
    if not cost then return "nil" end
    
    -- If cost is not a table, return as string
    if type(cost) ~= "table" then
        return tostring(cost)
    end
    
    -- Format cost components
    local costStrings = {}
    for _, component in ipairs(cost) do
        if type(component) == "table" and component.type then
            table.insert(costStrings, component.amount .. " " .. component.type)
        else
            table.insert(costStrings, tostring(component))
        end
    end
    
    return table.concat(costStrings, ", ")
end

function Wizard:queueSpell(spell)
    -- Check if wizard is stunned
    local stun = self.statusEffects[Constants.StatusType.STUN]
    if stun and stun.active then
        local remaining = stun.duration > 0 and (stun.duration - stun.totalTime) or 0
        print(self.name .. " tried to queue a spell but is stunned for " .. string.format("%.1f", remaining) .. " more seconds")
        return false
    end
    
    -- Validate the spell
    if not spell then
        print("No spell provided to queue")
        return false
    end
    
    -- Get the compiled spell if available
    local spellToUse = spell
    if spell.id and not spell.executeAll then
        -- This is an original spell definition, not a compiled one - get the compiled version
        local compiledSpell = getCompiledSpell(spell.id, self)
        if compiledSpell then
            spellToUse = compiledSpell
            print("Using compiled spell for queue: " .. spellToUse.id)
        else
            print("Warning: Using original spell definition - could not get compiled version of " .. spell.id)
        end
    end
    
    -- Find the innermost available spell slot
    for i = 1, #self.spellSlots do
        if not self.spellSlots[i].active then
            -- Determine cost source (static table or dynamic function)
            local costSource = spellToUse.getCost or spellToUse.cost

            -- Check if we can pay the mana cost from the pool
            local tokenReservations = self:canPayManaCost(costSource)
            
            if tokenReservations then
                local tokens = {}
                
                -- Check if we need tokens (empty cost doesn't need tokens)
                if #tokenReservations == 0 then
                    -- Free spell - no tokens needed
                    print("[TOKEN MANAGER] Free spell (no mana cost)")
                else
                    -- Resolve actual cost table now if using dynamic cost
                    local actualCost = type(costSource) == "function" and costSource(self, nil) or costSource

                    -- Use TokenManager to acquire and position tokens for the spell
                    local success, acquiredTokens = TokenManager.acquireTokensForSpell(self, i, actualCost)
                    
                    -- If TokenManager succeeded, use those tokens
                    if success and acquiredTokens then
                        tokens = acquiredTokens
                    else
                        -- TokenManager failed, fallback to legacy method
                        print("[TokenManager] Failed to acquire tokens, using legacy method")
                        
                        -- Move each token from mana pool to spell slot with animation
                        for _, reservation in ipairs(tokenReservations) do
                            local token = self.manaPool.tokens[reservation.index]
                            
                            -- Mark the token as being channeled using state machine if available
                            if token.setState then
                                token:setState(Constants.TokenStatus.CHANNELED)
                            else
                                token.state = Constants.TokenState.CHANNELED
                            end
                            
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
                    end
                end
                
                -- Store the tokens and cost in the spell slot
                self.spellSlots[i].tokens = tokens
                self.spellSlots[i].cost = type(costSource) == "function" and costSource(self, nil) or costSource
                
                -- Successfully paid the cost, queue the spell
                self.spellSlots[i].active = true
                self.spellSlots[i].progress = 0
                self.spellSlots[i].spellType = spellToUse.name
                
                -- Calculate base cast time (handling dynamic function)
                local baseCastTime
                if spellToUse.getCastTime and type(spellToUse.getCastTime) == "function" then
                    baseCastTime = spellToUse.getCastTime(self)
                    print(self.name .. " is using dynamic base cast time: " .. baseCastTime .. "s")
                else
                    baseCastTime = spellToUse.castTime
                end

                -- Check for and apply Slow status effect
                local finalCastTime = baseCastTime
                if self.statusEffects and self.statusEffects[Constants.StatusType.SLOW] and self.statusEffects[Constants.StatusType.SLOW].active then
                    local slowEffect = self.statusEffects[Constants.StatusType.SLOW]
                    local targetSlot = slowEffect.targetSlot -- Slot the slow effect targets (nil for any)
                    local queueingSlot = i -- Slot we are currently queueing into

                    -- Check if the slow effect applies to this specific slot or any slot
                    if targetSlot == nil or targetSlot == 0 or targetSlot == queueingSlot then
                        local slowMagnitude = slowEffect.magnitude or 0
                        finalCastTime = baseCastTime + slowMagnitude
                        print(string.format("[STATUS] Slow effect applied! Base cast: %.1fs, Slowed cast: %.1fs (Slot %s)",
                            baseCastTime, finalCastTime, tostring(targetSlot or "Any")))
                        
                        -- Consume the slow effect
                        slowEffect.active = false
                        slowEffect.magnitude = nil
                        slowEffect.targetSlot = nil 
                        -- Keep duration timer running so it eventually clears from statusEffects table if update loop doesn't
                    end
                end
                
                -- Store the final cast time (potentially modified by slow)
                self.spellSlots[i].castTime = finalCastTime
                
                self.spellSlots[i].spell = spellToUse
                
                -- Check if this is a shield spell and mark it accordingly
                if spellToUse.isShield or (spellToUse.keywords and spellToUse.keywords.block) then
                    print("SHIELD SPELL DETECTED during queue: " .. spellToUse.name)
                    -- Flag that this will become a shield when cast
                    self.spellSlots[i].willBecomeShield = true
                    
                    -- Prepare tokens for shield status using TokenManager
                    TokenManager.prepareTokensForShield(tokens)
                    
                    -- DO NOT mark tokens as SHIELDING yet - let them orbit normally during casting
                    -- Only mark them as SHIELDING after the spell is fully cast
                    
                    -- Mark this in the compiled spell if not already marked
                    if not spellToUse.isShield then
                        spellToUse.isShield = true
                    end
                end
                
                -- Set attackType if present in the new schema
                if spellToUse.attackType then
                    self.spellSlots[i].attackType = spellToUse.attackType
                end
                
                print(self.name .. " queued " .. spellToUse.name .. " in slot " .. i .. " (cast time: " .. spellToUse.castTime .. "s)")
                return true
            else
                -- Couldn't pay the cost
                print(self.name .. " tried to queue " .. spellToUse.name .. " but couldn't pay the mana cost")
                return false
            end
        end
    end
    
    -- No available slots
    print(self.name .. " tried to queue " .. spellToUse.name .. " but all slots are full")
    return false
end

-- This is a stub that delegates to the ShieldSystem module
local function createShield(wizard, spellSlot, shieldParams)
    return ShieldSystem.createShield(wizard, spellSlot, shieldParams)
end

-- Add createShield method to Wizard for compatibility
function Wizard:createShield(spellSlot, shieldParams)
    return ShieldSystem.createShield(self, spellSlot, shieldParams)
end

-- Free all active spells and return their mana to the pool
function Wizard:freeAllSpells()
    print(self.name .. " is freeing all active spells")
    
    -- Iterate through all spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            -- Return tokens to the mana pool using TokenManager
            if #slot.tokens > 0 then
                -- Use TokenManager to return all tokens to pool
                TokenManager.returnTokensToPool(slot.tokens)
                
                -- Clear token list (tokens still exist in the mana pool)
                slot.tokens = {}
            end
            
            -- Reset all slot properties using unified method
            self:resetSpellSlot(i)
            
            print("Freed spell in slot " .. i)
        end
    end
    
    -- Create visual effect for all spells being canceled
    if self.gameState and self.gameState.vfx then
        self.gameState.vfx.createEffect(Constants.VFXType.FREE_MANA, self.x, self.y, nil, nil)
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
-- This is a wrapper around TokenManager functionality for backward compatibility
-- Helper function to check if mana cost can be paid without actually taking the tokens
-- Accepts either a cost table or a getCost function
function Wizard:canPayManaCost(costOrGetCostFn, target)
    local cost = costOrGetCostFn

    if type(costOrGetCostFn) == "function" then
        cost = costOrGetCostFn(self, target)
    end

    local tokenReservations = {}
    local reservedIndices = {} -- Track which token indices are already reserved
    
    -- Handle cost being nil or not a table
    if not cost then
        return {}
    end
    
    -- Check if cost is a valid table we can iterate through
    if type(cost) ~= "table" then
        print("Cost is not a table, it's a " .. type(cost))
        return nil
    end
    
    -- Early exit if cost is empty
    if #cost == 0 then 
        return {} 
    end
    
    -- Convert legacy cost format to standardized manaCost object
    local standardizedCost = {}
    
    -- Process each cost component
    for i, component in ipairs(cost) do
        if type(component) == "table" and component.type and component.amount then
            -- New schema: {type="fire", amount=2}
            local tokenType = component.type
            standardizedCost[tokenType] = (standardizedCost[tokenType] or 0) + component.amount
        elseif type(component) == "string" then
            -- Old schema: "fire", "water", "any", etc.
            standardizedCost[component] = (standardizedCost[component] or 0) + 1
        elseif type(component) == "number" then
            -- Old schema numeric: 1, 2, 3 means ANY token of that count
            -- Use "any" for consistency with string "any"
            standardizedCost[Constants.TokenType.ANY] = (standardizedCost[Constants.TokenType.ANY] or 0) + component
        else
            -- Unknown cost component format
            print("Unknown cost component format: " .. type(component))
            return nil
        end
    end
    
    -- Using our local function to maintain backward compatibility
    local function reserveToken(tokenType, amount)
        -- Find matching tokens in the mana pool
        
        local count = 0
        
        -- Special case for "any" token type
        if tokenType == Constants.TokenType.ANY or tokenType == "ANY" then
            -- Go through all tokens in the mana pool
            for i, token in ipairs(self.manaPool.tokens) do
                -- Skip already reserved tokens
                if not reservedIndices[i] and token.state == Constants.TokenState.FREE then
                    -- Any free token will work
                    count = count + 1
                    
                    -- Add to reservations
                    table.insert(tokenReservations, {index = i, token = token})
                    reservedIndices[i] = true
                    
                    -- Check if we've found enough
                    if count >= amount then
                        break
                    end
                end
            end
        else
            -- Normal token type or nil (for random)
            -- Go through all tokens in the mana pool
            for i, token in ipairs(self.manaPool.tokens) do
                -- Skip already reserved tokens
                if not reservedIndices[i] then
                    -- Match either by specific type or any type if no type specified
                    if (tokenType == nil and token.state == Constants.TokenState.FREE) or (token.type == tokenType and token.state == Constants.TokenState.FREE) then
                        -- This token matches our requirements
                        count = count + 1
                        
                        -- Add to reservations
                        table.insert(tokenReservations, {index = i, token = token})
                        reservedIndices[i] = true
                        
                        -- Check if we've found enough
                        if count >= amount then
                            break
                        end
                    end
                end
            end
        end
        
        -- Check if we found enough tokens
        return count >= amount
    end
    
    -- Check each token type in the standardized cost
    for tokenType, amount in pairs(standardizedCost) do
        if tokenType == Constants.TokenType.RANDOM or tokenType == Constants.TokenType.ANY or tokenType == "ANY" then
            -- Random/any token type (any token will do)
            local success = reserveToken(tokenType, amount)
            if not success then
                print("Cannot find " .. amount .. " tokens of any type")
                return nil
            end
        else
            -- Specific token type
            local success = reserveToken(tokenType, amount)
            if not success then
                print("Cannot find enough " .. tokenType .. " tokens (need " .. amount .. ")")
                return nil
            end
        end
    end
    
    -- If we get here, all components were successfully reserved
    return tokenReservations
end

function Wizard:castSpell(spellSlot)
    local slot = self.spellSlots[spellSlot]
    if not slot or not slot.active or not slot.spell then return end
    
    print(self.name .. " cast " .. slot.spellType .. " from slot " .. spellSlot)

    -- Activate cast frame animation if sprite is available
    if self.castFrameSprite then
        self.castFrameTimer = self.castFrameDuration
    end
    
    -- Create a temporary visual notification for spell casting
    self.spellCastNotification = {
        text = self.name .. " cast " .. slot.spellType,
        timer = 2.0,  -- Show for 2 seconds
        x = self.x,
        y = self.y + 70, -- Moved below the wizard instead of above
        color = {self.color[1]/255, self.color[2]/255, self.color[3]/255, 1.0}
    }
    
    local target = CastExecution.findTargetWizard(self)
    if not target then return end

    local spellToUse = CastExecution.resolveSpellForCast(self, slot, getCompiledSpell)
    if not spellToUse then return end

    -- Check for character unlocks based on this spell
    UnlockSystem.checkSpellUnlock(spellToUse, self)

    local blockedEffect = CastExecution.tryBlockedCast(
        self,
        target,
        slot,
        spellSlot,
        spellToUse,
        BLOCKED_IMPACT_FALLBACK_SECONDS
    )
    if blockedEffect then
        CastExecution.dispatchCastComplete(self, target, spellSlot, spellToUse, blockedEffect)
        return blockedEffect
    end

    print("Executing spell: " .. spellToUse.id)
    local effect = spellToUse.executeAll(self, target, {}, spellSlot)
    local finalizedEffect = CastExecution.finalizeCast(self, slot, spellSlot, spellToUse, effect)
    CastExecution.dispatchCastComplete(self, target, spellSlot, spellToUse, finalizedEffect)
    return finalizedEffect
end

-- Reset a spell slot to its default state
-- This function can be used to clear a slot when a spell is cast, canceled, or a shield is destroyed
function Wizard:resetSpellSlot(slotIndex)
    local slot = self.spellSlots[slotIndex]
    if not slot then return end
    
    -- Debug message when slot reset happens
    print(string.format("[DEBUG] resetSpellSlot called for %s slot %d", self.name, slotIndex))
    
    -- Remove from SustainedSpellManager if it's a sustained spell
    if slot.sustainedId and self.gameState and self.gameState.sustainedSpellManager then
        self.gameState.sustainedSpellManager.removeSustainedSpell(slot.sustainedId)
        print(string.format("[SUSTAINED] Removed spell in slot %d with ID: %s during slot reset", 
            slotIndex, tostring(slot.sustainedId)))
        slot.sustainedId = nil
    end

    -- Reset the basic slot properties
    slot.active = false
    slot.spell = nil
    slot.spellType = nil
    slot.castTime = 0
    slot.castProgress = 0
    slot.progress = 0 -- Used in many places instead of castProgress
    slot.wasAlreadyCast = false -- Reset the flag that tracks if the spell was already cast
    slot.blockedPendingImpact = false
    slot.blockImpactTimer = 0
    slot.blockImpactTimeout = nil
    
    -- Reset shield-specific properties
    slot.isShield = false
    slot.willBecomeShield = false
    slot.defenseType = nil
    slot.blocksAttackTypes = nil
    slot.blockTypes = nil
    slot.reflect = nil
    slot.onBlock = nil
    slot.shieldStrength = 0
    
    -- Reset spell status properties
    slot.frozen = false
    slot.freezeTimer = 0
    slot.castTimeModifier = 0 -- Renamed from frozenTimeAccrued
    
    -- Reset zone-specific properties
    slot.zoneAnchored = nil
    slot.anchorRange = nil
    slot.anchorElevation = nil
    slot.anchorRequireAll = nil
    slot.affectsBothRanges = nil
    
    -- Reset spell properties
    slot.attackType = nil
    
    -- Clear token references *after* animations have been requested
    slot.tokens = {}
end

-- Add method to check for spell fizzle/shield collapse when a token is removed
-- This is a wrapper around TokenManager.checkFizzleCondition
function Wizard:checkFizzleOnTokenRemoval(slotIndex, removedTokenObject)
    return TokenManager.checkFizzleCondition(self, slotIndex, removedTokenObject)
end

-- Handle the effects of a spell being blocked by a shield in a specific slot
-- This is now a wrapper method that delegates to ShieldSystem
function Wizard:handleShieldBlock(slotIndex, incomingSpell, attackerWizard)
    print("[WIZARD DEBUG] handleShieldBlock called for " .. self.name .. " slot " .. slotIndex)
    
    -- Debug the shield slot to check for onBlock
    if self.spellSlots and self.spellSlots[slotIndex] then
        local slot = self.spellSlots[slotIndex]
        if slot.onBlock then
            print("[WIZARD DEBUG] onBlock handler found in shield slot")
        else
            print("[WIZARD DEBUG] No onBlock handler found in shield slot")
        end
    else
        print("[WIZARD DEBUG] Invalid slot index: " .. tostring(slotIndex))
    end
    
    return ShieldSystem.handleShieldBlock(self, slotIndex, incomingSpell, attackerWizard)
end

-- Determine the current positional key string for animation lookup
function Wizard:getPositionalKey()
    local range = self.gameState and self.gameState.rangeState or Constants.RangeState.FAR
    local elevation = self.elevation or Constants.ElevationState.GROUNDED
    return string.lower(range .. "-" .. elevation)
end

-- Retrieve idle frames for a given positional key
function Wizard:getIdleFramesForKey(key)
    if self.positionalAnimations[key] and self.positionalAnimations[key].idle then
        return self.positionalAnimations[key].idle
    end
    return self.idleAnimationFrames
end

-- Retrieve cast frame for a given positional key
function Wizard:getCastFrameForKey(key)
    if self.positionalAnimations[key] then
        return self.positionalAnimations[key].cast or self.castFrameSprite
    end
    return self.castFrameSprite
end

-- Load positional animation assets for all range/elevation combinations
function Wizard:loadPositionalAnimations()
    local AssetCache = require("core.AssetCache")
    for _, range in pairs(Constants.RangeState) do
        for _, elevation in pairs(Constants.ElevationState) do
            local key = string.lower(range .. "-" .. elevation)
            local dir = string.format("assets/sprites/%s-%s-%s", string.lower(self.name), string.lower(range), string.lower(elevation))
            local anim = { idle = {}, cast = nil }

            if love.filesystem.getInfo(dir, "directory") then
                local files = love.filesystem.getDirectoryItems(dir)
                table.sort(files)
                for _, file in ipairs(files) do
                    if file:match("%.png$") then
                        local path = dir .. "/" .. file
                        if file:lower():find("cast") then
                            anim.cast = AssetCache.getImage(path)
                        else
                            local img = AssetCache.getImage(path)
                            if img then table.insert(anim.idle, img) end
                        end
                    end
                end
            end

            if #anim.idle == 0 then
                anim.idle = self.idleAnimationFrames
            end
            if not anim.cast then
                anim.cast = self.castFrameSprite
            end

            self.positionalAnimations[key] = anim
        end
    end
end

return Wizard
