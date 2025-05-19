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

function Wizard.new(name, x, y, color)
    local self = setmetatable({}, Wizard)
    
    self.name = name
    self.x = x
    self.y = y
    self.color = color  -- RGB table
    
    -- Wizard state
    self.health = 100
    self.elevation = Constants.ElevationState.GROUNDED  -- GROUNDED or AERIAL
    self.elevationTimer = 0      -- Timer for temporary elevation changes
    self.stunTimer = 0           -- Stun timer in seconds
    
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
            ["1"]  = Spells.burnTheSoul,
            ["2"]  = Spells.SpaceRipper,
            ["3"]  = Spells.StingingEyes,

            -- Two key combos
            ["12"] = Spells.battleshield,
            ["13"] = Spells.NuclearFurnace,
            ["23"] = Spells.firebolt,

            -- Three key combo
            ["123"] = Spells.CoreBolt
        }

    elseif name == "Silex" then   -- New salt-themed wizard
        self.spellbook = {
            -- Single key spells
            ["1"]  = Spells.conjuresalt,
            ["2"]  = Spells.glitterfang,
            ["3"]  = Spells.imprison,

            -- Two key combos
            ["12"] = Spells.saltcircle,
            ["13"] = Spells.stoneshield,
            ["23"] = Spells.shieldbreaker,

            -- Three key combo
            ["123"] = Spells.saltstorm
        }

    else -- Default to Selene
        self.spellbook = {
            -- Single key spells
            ["1"]  = Spells.conjuremoonlight,
            ["2"]  = Spells.wrapinmoonlight,
            ["3"]  = Spells.moondance,
            
            -- Two key combos
            ["12"] = Spells.infiniteprocession,
            ["13"] = Spells.eclipse,
            ["23"] = Spells.gravityTrap,
            
            -- Three key combo
            ["123"] = Spells.fullmoonbeam
        }
    end
    
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
            wasAlreadyCast = false -- Track if the spell has already been cast
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

    -- Load idle animation frames specifically for Ashgar
    if name == "Ashgar" then
        local AssetCache = require("core.AssetCache")
        for i = 1, 7 do
            local framePath = "assets/sprites/" .. string.lower(name) .. "-idle-" .. i .. ".png"
            local frameImg = AssetCache.getImage(framePath)
            if frameImg then
                table.insert(self.idleAnimationFrames, frameImg)
            else
                print("Warning: Could not load Ashgar idle frame: " .. framePath)
                -- Fallback to using the main sprite if we can't load the idle frame
                table.insert(self.idleAnimationFrames, self.sprite)
            end
        end
        -- If no idle frames loaded, use the main sprite as a single-frame animation
        if #self.idleAnimationFrames == 0 then
            print("Warning: Ashgar has no idle animation frames loaded, using static sprite.")
            table.insert(self.idleAnimationFrames, self.sprite)
        end
    else
        -- For other wizards, populate with their main sprite for now
        table.insert(self.idleAnimationFrames, self.sprite)
    end

    self.scale = 1.0
    
    -- Keep references
    self.gameState = _G.game  -- Reference to global game state
    self.manaPool = self.gameState.manaPool
    
    -- Track UI offsets
    self.currentXOffset = 0
    self.currentYOffset = 0
    
    -- Flags for trap triggering and spell expiry
    self.justCastSpellThisFrame = false
    self.justConjuredMana = false
    
    return self
end

function Wizard:update(dt)
    -- Reset flags at the beginning of each frame
    self.justCastSpellThisFrame = false
    self.justConjuredMana = false

    -- Update hit flash timer
    if self.hitFlashTimer > 0 then
        self.hitFlashTimer = math.max(0, self.hitFlashTimer - dt)
    end

    -- Update cast frame timer
    if self.castFrameTimer > 0 then
        self.castFrameTimer = math.max(0, self.castFrameTimer - dt)
    end

    -- Update idle animation timer and frame
    -- Only animate idle if not casting or in another special visual state
    if self.castFrameTimer <= 0 then -- Play idle if not in cast animation
        self.idleFrameTimer = self.idleFrameTimer + dt
        if self.idleFrameTimer >= self.idleFrameDuration then
            self.idleFrameTimer = self.idleFrameTimer - self.idleFrameDuration -- Subtract to carry over excess time
            self.currentIdleFrame = self.currentIdleFrame + 1
            if self.currentIdleFrame > #self.idleAnimationFrames then
                self.currentIdleFrame = 1 -- Loop animation
            end
        end
    else
        -- If casting, reset idle animation to first frame to look clean when cast finishes
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
    
    -- Update stun timer
    if self.stunTimer > 0 then
        self.stunTimer = math.max(0, self.stunTimer - dt)
        if self.stunTimer == 0 then
            print(self.name .. " is no longer stunned")
        end
    end
    
    -- Update elevation effects (NEW LOGIC)
    if self.elevationEffects then
        for elevationType, effectData in pairs(self.elevationEffects) do
            effectData.duration = effectData.duration - dt
            
            if effectData.duration <= 0 then
                -- Execute the expiration action (e.g., set elevation back to GROUNDED)
                if effectData.expireAction then
                    effectData.expireAction()
                end
                
                -- Remove the effect from the table
                self.elevationEffects[elevationType] = nil
                
                -- Create landing VFX if we just returned to GROUNDED
                if self.elevation == Constants.ElevationState.GROUNDED then
                    if self.gameState and self.gameState.vfx then
                        local Constants = require("core.Constants")
                        self.gameState.vfx.createEffect(Constants.VFXType.IMPACT, self.x, self.y + 30, nil, nil, {
                            duration = 0.5,
                            color = {0.7, 0.7, 0.7, 0.8},
                            particleCount = 8,
                            radius = 20
                        })
                    end
                end
            end
        end
    end
    
    -- Update shield visuals using ShieldSystem
    ShieldSystem.updateShieldVisuals(self, dt)
    
    -- Update status effects generically
    if self.statusEffects then
        for effectType, effectData in pairs(self.statusEffects) do
            if effectData.active then
                -- Increment total time the effect has been active
                effectData.totalTime = effectData.totalTime + dt
                
                -- Check for expiration
                if effectData.duration > 0 then -- Only expire effects with explicit duration
                    if effectData.totalTime >= effectData.duration then
                        -- Reset the effect
                        effectData.active = false
                        effectData.elapsed = 0
                        effectData.totalTime = 0
                        print(string.format("%s's %s effect expired", self.name, effectType))
                    end
                end
                
                -- If this is a burn effect, handle damage ticks
                if effectType == "burn" and effectData.active then
                    effectData.elapsed = effectData.elapsed + dt
                    if effectData.elapsed >= effectData.tickInterval then
                        -- Apply burn damage
                        self.health = math.max(0, self.health - effectData.tickDamage)
                        
                        -- Set hit flash timer for DoT visual feedback
                        self.hitFlashTimer = 0.125 -- 125ms flash duration
                        
                        print(string.format("%s took %d burn damage (health: %d)", 
                            self.name, effectData.tickDamage, self.health))
                        
                        -- Create burn damage effect
                        if self.gameState and self.gameState.vfx then
                            self.gameState.vfx.createEffect(Constants.VFXType.IMPACT, self.x, self.y, nil, nil, {
                                duration = 0.3,
                                color = {1.0, 0.2, 0.0, 0.6},
                                particleCount = 10,
                                radius = 25
                            })
                        end
                        
                        -- Reset tick interval timer but keep total duration timer
                        effectData.elapsed = 0
                        
                        -- Check for defeat
                        if self.health <= 0 then
                            print(self.name .. " was defeated by burn damage!")
                            if self.gameState then
                                self.gameState.gameOver = true
                                self.gameState.winner = self.name == "Ashgar" and "Selene" or "Ashgar"
                                
                                -- Create defeat effect
                                if self.gameState.vfx then
                                    self.gameState.vfx.createEffect(Constants.VFXType.IMPACT, self.x, self.y, nil, nil, {
                                        duration = 1.0,
                                        color = {1.0, 0.0, 0.0, 0.8},
                                        particleCount = 30,
                                        radius = 80
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
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
                    
                    -- Shield state is now managed directly in the castSpell function
                    -- and tokens remain as CHANNELED until the shield is activated
                    
                    -- ONLY check for spell completion when NOT frozen
                    if slot.progress >= slot.castTime and not slot.wasAlreadyCast then
                        -- Mark this slot as already cast to prevent repeated casting
                        slot.wasAlreadyCast = true
                        
                        -- Cast the spell
                        self:castSpell(i)
                        
                        -- Debug message to confirm we're setting the flag
                        print(string.format("[DEBUG] Marked slot %d as already cast to prevent repetition", i))
                        
                        -- For non-shield spells, we return tokens and reset the slot
                        -- For shield spells, castSpell will handle setting up the shield 
                        -- UNLESS the spell is a sustained spell like a trap
                        
                        -- Check for both shield and sustained spells (traps, etc.)
                        if not slot.isShield and not slot.sustainedId then
                            -- Start return animation for tokens
                            if #slot.tokens > 0 then
                                for _, tokenData in ipairs(slot.tokens) do
                                    -- Request return animation directly on the token
                                    if tokenData.token and tokenData.token.requestReturnAnimation then
                                        tokenData.token:requestReturnAnimation()
                                    else
                                        -- Fallback to legacy method if token doesn't have the method
                                        self.manaPool:returnToken(tokenData.index)
                                    end
                                end
                                
                                -- Clear token list (tokens still exist in the mana pool)
                                slot.tokens = {}
                            end
                            
                            -- Reset slot using unified method only if it's not a sustained spell
                            self:resetSpellSlot(i)
                        end
                    end
                end
            end
        end
    end
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
    if self.stunTimer > 0 then
        print(self.name .. " tried to queue a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
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
            -- Check if we can pay the mana cost from the pool
            local tokenReservations = self:canPayManaCost(spell.cost)
            
            if tokenReservations then
                local tokens = {}
                
                -- Check if we need tokens (empty cost doesn't need tokens)
                if #tokenReservations == 0 then
                    -- Free spell - no tokens needed
                    print("[TOKEN MANAGER] Free spell (no mana cost)")
                else
                    -- Use TokenManager to acquire and position tokens for the spell
                    local success, acquiredTokens = TokenManager.acquireTokensForSpell(self, i, spell.cost)
                    
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
                
                -- Store the tokens in the spell slot
                self.spellSlots[i].tokens = tokens
                
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
                if self.statusEffects and self.statusEffects.slow and self.statusEffects.slow.active then
                    local slowEffect = self.statusEffects.slow
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
function Wizard:canPayManaCost(cost)
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
    
    -- Set the flag to indicate a spell was cast this frame (for trap triggers)
    self.justCastSpellThisFrame = true

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
    
    -- Get target (the other wizard)
    local target = nil
    for _, wizard in ipairs(self.gameState.wizards) do
        if wizard ~= self then
            target = wizard
            break
        end
    end
    
    if not target then return end
    
    -- Get the spell (either compiled or original)
    local spellToUse = slot.spell
    
    -- Convert to compiled spell if needed
    if spellToUse.id and not spellToUse.executeAll then
        -- This is an original spell, not a compiled one - get the compiled version
        local compiledSpell = getCompiledSpell(spellToUse.id, self)
        if compiledSpell then
            spellToUse = compiledSpell
            -- Store the compiled spell back in the slot for future use
            slot.spell = compiledSpell
            print("Using compiled spell: " .. spellToUse.id)
        else
            print("Warning: Falling back to original spell - could not get compiled version of " .. spellToUse.id)
        end
    end
    
    -- Get attack type for shield checking
    local attackType = spellToUse.attackType or Constants.AttackType.PROJECTILE
    
    -- Check if the spell can be blocked by any of the target's shields
    -- This now happens BEFORE spell execution per ticket PROG-20
    local blockInfo = ShieldSystem.checkShieldBlock(spellToUse, attackType, target, self)
    
    -- Handle shield block effects
    if blockInfo.blockable then
        print(string.format("[SHIELD BLOCK] %s's %s was blocked by %s's %s shield!", 
            self.name, spellToUse.name, target.name, blockInfo.blockType or "unknown"))
        
        -- Set a standard blockPoint for visual effect (75% of the way from caster to target)
        blockInfo.blockPoint = 0.75
        
        -- Use the ShieldSystem to handle token consumption for the shield
        ShieldSystem.handleShieldBlock(target, blockInfo.blockingSlot, spellToUse)
        
        -- Create a partial results table with initialResults
        local blockedResults = { blockInfo = blockInfo }
        
        -- Execute the spell, but convert the DAMAGE events to BLOCKED_DAMAGE
        -- This will show visuals but prevent actual damage application
        effect = spellToUse.executeAll(self, target, blockedResults, spellSlot)
        
        -- Set blocked flag in the effect results
        effect.blocked = true
        effect.blockType = blockInfo.blockType
        effect.blockingSlot = blockInfo.blockingSlot
        
        -- Return tokens from our spell slot
        if #slot.tokens > 0 then
            -- Use TokenManager to return tokens to pool
            TokenManager.returnTokensToPool(slot.tokens)
            -- Clear token list after requesting return animations
            slot.tokens = {}
        end
        
        -- Reset our slot using unified method
        self:resetSpellSlot(spellSlot)
        
        -- Return the effect
        return effect
    end
    
    -- Now execute the spell
    
    -- For tracking if the spell is a shield spell
    local isShieldSpell = false
    if slot.willBecomeShield or spellToUse.isShield then
        isShieldSpell = true
    end
    
    -- Handle spell execution based on type
    local effect = nil
    local shouldSustain = false  -- Initialize outside if-block so it's available throughout the function
    
    -- Execute the spell using compiled spell format
    print("Executing spell: " .. spellToUse.id)
    
    -- Execute the spell with blockInfo if the spell is blocked
    local initialResults = blockInfo.blockable and { blockInfo = blockInfo } or {}
    effect = spellToUse.executeAll(self, target, initialResults, spellSlot)
    
    -- After execution, check if the spell was blocked (results should have blocked=true)
    if effect.blocked then
        print(string.format("[SHIELD] %s's %s was fully blocked by shield!", 
            self.name, spellToUse.name))
    end
    
    -- Check if this is a sustained spell (from sustain keyword)
    shouldSustain = effect.isSustained or false
    print("DEBUG: effect.isSustained = " .. tostring(effect.isSustained) .. ", shouldSustain = " .. tostring(shouldSustain))
    
    -- If no valid effect was returned, create an empty one
    if not effect then
        print("WARNING: Spell " .. spellToUse.id .. " didn't return any effect")
        effect = {}
    end
    
    -- Shield spell creation - check if the effect has shield params
    if effect.isShield and not effect.blocked and not slot.isShield then
        if effect.shieldParams then
            -- Create a shield in this spell slot using ShieldSystem
            print("Creating shield in spell slot " .. spellSlot)
            
            -- Explicitly mark as sustained (shields are a type of sustained spell)
            effect.isSustained = true
            shouldSustain = true
            
            -- Mark this slot as already cast to prevent repeated casting
            slot.wasAlreadyCast = true
            
            local shieldResult = ShieldSystem.createShield(self, spellSlot, effect.shieldParams)
            
            -- Register shield with SustainedSpellManager (shields are a type of sustained spell)
            if shieldResult.shieldCreated and self.gameState and self.gameState.sustainedSpellManager then
                -- Mark the effect as sustained for shields too
                effect.isSustained = true
                shouldSustain = true  -- Make sure shouldSustain is set for shields as well
                
                -- Make sure the shield params are set in the proper field expected by SustainedSpellManager
                effect.shieldParams = effect.shieldParams or {}
                effect.isShield = true
                
                local sustainedId = self.gameState.sustainedSpellManager.addSustainedSpell(
                    self,        -- wizard who cast the spell
                    spellSlot,   -- slot index where the shield is
                    effect       -- effect table from executeAll with shield params
                )
                
                -- Store the sustained spell ID in the slot for reference
                slot.sustainedId = sustainedId
                
                print(string.format("[SUSTAINED] Registered shield in slot %d with ID: %s", 
                    spellSlot, tostring(sustainedId)))
            end
            
            -- Apply any elevation change specified by the shield
            if shieldResult.shieldCreated and effect.shieldParams.setElevation then
                self.elevation = effect.shieldParams.setElevation
                if effect.shieldParams.elevationDuration and effect.shieldParams.setElevation == Constants.ElevationState.AERIAL then
                    self.elevationTimer = effect.shieldParams.elevationDuration
                end
                print(self.name .. " moved to " .. self.elevation .. " elevation by shield spell")
            end
        else
            print("ERROR: Shield spell missing shieldParams")
        end
    end
    
    -- For shields, skip the rest of the processing (shields are a specific kind of sustained spell)
    if effect.isShield or slot.isShield then
        -- Debug log - make it clear to use sustain instead in new code, but shields keep working
        if effect.isSustained and effect.isShield then
            print("[SUSTAINED] Note: Spell " .. spellToUse.id .. " has both isShield and isSustained flags - shields are already sustained")
        end
        return effect
    end
    
    if not isShieldSpell and not slot.isShield and not effect.isShield then
        -- Only reset slot and return tokens if this isn't a sustained spell
        if not shouldSustain then
            -- Start return animation for tokens
            if #slot.tokens > 0 then
                -- Check if any tokens are marked as SHIELDING using TokenManager
                local hasShieldingTokens = false
                for _, tokenData in ipairs(slot.tokens) do
                    if tokenData.token and TokenManager.validateTokenState(tokenData.token, Constants.TokenStatus.SHIELDING) then
                        hasShieldingTokens = true
                        break
                    end
                end
                
                -- Handle blocked spells - should always return tokens
                if effect and effect.blocked then
                    print("Returning tokens for blocked spell")
                    TokenManager.returnTokensToPool(slot.tokens)
                    slot.tokens = {}
                elseif not hasShieldingTokens then
                    -- Normal case: Safe to return tokens if not shielding
                    TokenManager.returnTokensToPool(slot.tokens)
                    
                    -- Clear token list (tokens still exist in the mana pool)
                    slot.tokens = {}
                else
                    print("Found SHIELDING tokens, preventing token return")
                end
            end
            
            -- Reset slot only if it's not a shield
            self:resetSpellSlot(spellSlot)
        else
            -- This is a sustained spell - keep slot active and tokens in place
            print(string.format("[SUSTAINED] %s's spell in slot %d is being sustained", self.name, spellSlot))
            
            -- Keep the slot as active with full progress
            slot.active = true
            slot.progress = slot.castTime -- Mark as fully cast
            slot.wasAlreadyCast = true -- Keep the flag set to prevent repeated casting
            
            -- Register with the SustainedSpellManager
            if self.gameState and self.gameState.sustainedSpellManager then
                local sustainedId = self.gameState.sustainedSpellManager.addSustainedSpell(
                    self,        -- wizard who cast the spell
                    spellSlot,   -- slot index where the spell is
                    effect       -- effect table from executeAll (contains trapTrigger, trapWindow, trapEffect, etc.)
                )
                
                -- Store the sustained spell ID in the slot for reference
                slot.sustainedId = sustainedId
                
                print(string.format("[SUSTAINED] Registered spell in slot %d with ID: %s", 
                    spellSlot, tostring(sustainedId)))
            else
                print("[SUSTAINED ERROR] Could not register sustained spell - gameState or sustainedSpellManager missing")
            end
        end
    else
        -- For shield spells, the slot remains active and tokens remain in orbit
        -- Make sure slot is marked as a shield
        slot.isShield = true
        
        -- Use TokenManager to mark tokens as SHIELDING
        TokenManager.markTokensAsShielding(slot.tokens)
    end
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
    
    -- Reset shield-specific properties
    slot.isShield = false
    slot.willBecomeShield = false
    slot.defenseType = nil
    slot.blocksAttackTypes = nil
    slot.blockTypes = nil
    slot.reflect = nil
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
function Wizard:handleShieldBlock(slotIndex, incomingSpell)
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
    
    return ShieldSystem.handleShieldBlock(self, slotIndex, incomingSpell)
end

return Wizard