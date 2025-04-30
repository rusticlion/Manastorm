-- ai/OpponentAI.lua
-- Basic AI opponent for Manastorm
-- Phase 1: Local Demo Implementation

local Constants = require("core.Constants")
local ManaHelpers = require("systems.ManaHelpers")

-- Define the OpponentAI module
local OpponentAI = {}

-- AI States - Define as constants for clarity
local STATE = {
    IDLE = "IDLE",             -- Default state, focus on building mana resources
    ATTACK = "ATTACK",         -- Aggressive offense, prioritize damage spells
    DEFEND = "DEFEND",         -- Defensive posture, prioritize shields and healing
    COUNTER = "COUNTER",       -- Counter opponent's active spells
    ESCAPE = "ESCAPE",         -- Desperate state when very low health, try to survive
    POSITION = "POSITION"      -- Adjust position (elevation/range) for advantage
}

-- Constructor for OpponentAI
-- @param wizard - The wizard object this AI will control (typically game.wizards[2])
-- @param gameState - Reference to the game state (the global 'game' object)
function OpponentAI.new(wizard, gameState)
    -- Create a new instance
    local ai = {
        -- Store references to game objects
        wizard = wizard,
        gameState = gameState,
        
        -- Track the opposing wizard (player's wizard)
        playerWizard = nil,
        
        -- Track last perception time for throttling
        lastPerceptionTime = 0,
        perceptionInterval = 0.5, -- Update perception every 0.5 seconds
        
        -- Track last action time for throttling
        lastActionTime = 0,
        actionInterval = 1.0, -- Consider actions every 1.0 seconds
        
        -- Simple finite state machine
        currentState = STATE.IDLE, -- Initial state
        lastState = nil,           -- Previous state for transition detection
        stateChangeTime = 0,       -- When the last state change occurred
        
        -- Current decision and action
        currentDecision = nil,
        
        -- Perceived game state (updated periodically)
        perception = {
            selfHealth = 0,
            opponentHealth = 0,
            rangeState = Constants.RangeState.FAR,
            ownElevation = Constants.ElevationState.GROUNDED,
            opponentElevation = Constants.ElevationState.GROUNDED,
            availableTokens = {}, -- Count of each token type
            activeSlots = 0, -- Number of spell slots currently in use
            spellSlots = {}, -- Detailed information about own spell slots
            opponentSpellSlots = {}, -- Information about opponent spell slots
        },
        
        -- Debug output options
        debug = {
            printPerception = true, -- Set to false to disable perception debug output
            perceptionPrintInterval = 2.0, -- How often to print perception details (seconds)
            lastPerceptionPrintTime = 0,
        }
    }
    
    -- Set the metatable to use the OpponentAI methods
    setmetatable(ai, {__index = OpponentAI})
    
    -- Find the opposing wizard (player's wizard)
    for i, w in ipairs(gameState.wizards) do
        if w ~= wizard then
            ai.playerWizard = w
            break
        end
    end
    
    return ai
end

-- Main update method - called from main.lua's love.update
-- @param dt - Delta time from the game loop
function OpponentAI:update(dt)
    -- Update perception (throttled)
    if love.timer.getTime() - self.lastPerceptionTime > self.perceptionInterval then
        self:perceive()
        self.lastPerceptionTime = love.timer.getTime()
        
        -- Debug output (throttled separately)
        if self.debug.printPerception and love.timer.getTime() - self.debug.lastPerceptionPrintTime > self.debug.perceptionPrintInterval then
            self:printPerceptionDebug()
            self.debug.lastPerceptionPrintTime = love.timer.getTime()
        end
    end
    
    -- Make decisions and act (throttled)
    if love.timer.getTime() - self.lastActionTime > self.actionInterval then
        -- Store previous state for transition detection
        self.lastState = self.currentState
        
        -- Make a decision based on current perception
        local decision = self:decide()
        self.currentDecision = decision
        
        -- If state changed, log it and record the time
        if self.currentState ~= self.lastState then
            print(string.format("[AI] State transition: %s -> %s", 
                self.lastState, self.currentState))
            self.stateChangeTime = love.timer.getTime()
            
            -- Print the decision that led to the state change
            if decision and decision.type then
                print(string.format("[AI] New Action: %s (reason: %s)", 
                    decision.type, decision.reason or "unknown"))
            end
        end
        
        -- Execute the decided action
        self:act(decision)
        
        self.lastActionTime = love.timer.getTime()
    end
end

-- Observe the current game state and update perception
function OpponentAI:perceive()
    local p = self.perception -- shorthand for readability
    
    -- Check if game state and wizards still exist (safety check)
    if not self.gameState or not self.wizard or not self.playerWizard then
        print("ERROR: AI missing critical game references")
        return
    end
    
    -- Basic game state perception
    p.rangeState = self.gameState.rangeState
    
    -- Self wizard perception
    p.selfHealth = self.wizard.health
    p.ownElevation = self.wizard.elevation
    
    -- Opponent wizard perception
    p.opponentHealth = self.playerWizard.health
    p.opponentElevation = self.playerWizard.elevation
    
    -- Mana pool token counts
    p.availableTokens = {}
    
    -- Track counts for all token types
    for _, tokenType in ipairs(Constants.getAllTokenTypes()) do
        p.availableTokens[tokenType] = ManaHelpers.count(tokenType, self.gameState.manaPool)
    end
    
    -- Count total free tokens
    p.totalFreeTokens = 0
    for _, count in pairs(p.availableTokens) do
        p.totalFreeTokens = p.totalFreeTokens + count
    end
    
    -- Spell slot perception (own)
    p.spellSlots = {}
    p.activeSlots = 0
    
    for i, slot in ipairs(self.wizard.spellSlots) do
        p.spellSlots[i] = {
            active = slot.active,
            progress = slot.progress,
            castTime = slot.castTime,
            isShield = slot.isShield or false,
            willBecomeShield = slot.willBecomeShield or false,
            spellType = slot.spellType,
            frozen = slot.frozen or false,
            attackType = slot.attackType,
            tokenCount = slot.tokens and #slot.tokens or 0
        }
        
        if slot.active then
            p.activeSlots = p.activeSlots + 1
        end
    end
    
    -- Spell slot perception (opponent)
    p.opponentSpellSlots = {}
    p.opponentActiveSlots = 0
    
    for i, slot in ipairs(self.playerWizard.spellSlots) do
        p.opponentSpellSlots[i] = {
            active = slot.active,
            progress = slot.progress,
            castTime = slot.castTime,
            isShield = slot.isShield or false,
            spellType = slot.spellType,
            tokenCount = slot.tokens and #slot.tokens or 0
        }
        
        if slot.active then
            p.opponentActiveSlots = p.opponentActiveSlots + 1
        end
    end
    
    -- Can pay for basic token costs? (for decision making)
    p.canPayForSingleToken = {}
    for _, tokenType in ipairs(Constants.getAllTokenTypes()) do
        local canPay = self.wizard:canPayManaCost({tokenType}) ~= nil
        p.canPayForSingleToken[tokenType] = canPay
    end
    
    -- Calculate key derived states for decision making
    p.opponentLowHealth = p.opponentHealth < 30
    p.selfLowHealth = p.selfHealth < 30
    p.selfCriticalHealth = p.selfHealth < 15
    
    -- Calculate health advantage (positive = AI has more health)
    p.healthAdvantage = p.selfHealth - p.opponentHealth
    
    -- Check if opponent has dangerous spell in progress
    p.opponentHasDangerousSpell = false
    for _, slot in ipairs(p.opponentSpellSlots) do
        if slot.active and not slot.isShield and slot.progress > 0 then
            -- Simple heuristic: consider any active spell with progress "dangerous"
            p.opponentHasDangerousSpell = true
            break
        end
    end
    
    -- Check if we have any shield active
    p.hasActiveShield = false
    for _, slot in ipairs(p.spellSlots) do
        if slot.active and slot.isShield then
            p.hasActiveShield = true
            break
        end
    end
    
    return p
end

-- Print debug information about current perception
function OpponentAI:printPerceptionDebug()
    local p = self.perception
    print("=== AI PERCEPTION ===")
    print(string.format("HEALTH: Self=%d, Opponent=%d", p.selfHealth, p.opponentHealth))
    print(string.format("RANGE: %s, ELEVATION: Self=%s, Opp=%s", 
        p.rangeState, p.ownElevation, p.opponentElevation))
    
    -- Token counts
    local tokenInfo = "TOKENS: "
    for tokenType, count in pairs(p.availableTokens) do
        if count > 0 then
            tokenInfo = tokenInfo .. tokenType .. "=" .. count .. " "
        end
    end
    print(tokenInfo)
    
    -- Spell slot info (self)
    print("SPELL SLOTS:")
    for i, slot in ipairs(p.spellSlots) do
        if slot.active then
            print(string.format("  [%d] %s - Progress: %.1f/%.1f %s%s", 
                i, slot.spellType or "Unknown", 
                slot.progress, slot.castTime,
                slot.isShield and "[SHIELD]" or "",
                slot.frozen and "[FROZEN]" or ""))
        end
    end
    
    -- Opponent spell slots
    print("OPPONENT SLOTS:")
    for i, slot in ipairs(p.opponentSpellSlots) do
        if slot.active then
            print(string.format("  [%d] %s - Progress: %.1f/%.1f %s", 
                i, slot.spellType or "Unknown", 
                slot.progress, slot.castTime,
                slot.isShield and "[SHIELD]" or ""))
        end
    end
    
    -- Current AI state
    print("AI STATE: " .. self.currentState)
    if self.currentDecision then
        print("CURRENT ACTION: " .. (self.currentDecision.type or "None"))
    end
    print("===================")
end

-- Decide what to do based on current perception
function OpponentAI:decide()
    local p = self.perception
    local spellbook = self.wizard.spellbook
    
    -- Basic state transition logic based on health and threat
    
    -- Critical health - go into escape mode
    if p.selfCriticalHealth then
        self.currentState = STATE.ESCAPE
        
        -- First try to find a shield spell if not already shielded
        if not p.hasActiveShield then
            local shieldSpell = spellbook["2"] -- wrapinmoonlight
            if shieldSpell and self.wizard:canPayManaCost(shieldSpell.cost) and self:hasAvailableSpellSlot() then
                return { 
                    type = "CAST_SPELL", 
                    spell = shieldSpell,
                    reason = "Critical health - need shield"
                }
            end
        end
        
        -- If shield not available, try mobility
        local escapeSpell = spellbook["3"] -- moondance
        if escapeSpell and self.wizard:canPayManaCost(escapeSpell.cost) and self:hasAvailableSpellSlot() then
            return { 
                type = "CAST_SPELL", 
                spell = escapeSpell,
                reason = "Critical health - escape"
            }
        end
        
        -- Last resort - free all spells
        if p.activeSlots > 0 then
            return { 
                type = "FREE_ALL", 
                reason = "Critical health - free resources"
            }
        end
        
        return { 
            type = "ESCAPE_ACTION", 
            reason = "Critical health (" .. p.selfHealth .. ")"
        }
    
    -- Low health - prioritize defense
    elseif p.selfLowHealth and not p.hasActiveShield then
        self.currentState = STATE.DEFEND
        
        -- Look for shield spell
        local shieldSpell = spellbook["2"] -- wrapinmoonlight
        if shieldSpell and self.wizard:canPayManaCost(shieldSpell.cost) and self:hasAvailableSpellSlot() then
            return { 
                type = "CAST_SPELL", 
                spell = shieldSpell,
                reason = "Low health defense"
            }
        end
        
        return { 
            type = "DEFEND_ACTION", 
            reason = "Low health, need shield"
        }
    
    -- Opponent has very low health - press the advantage
    elseif p.opponentLowHealth then
        self.currentState = STATE.ATTACK
        
        -- Use strongest attack spell available
        if self:hasAvailableSpellSlot() then
            local attackOptions = {
                spellbook["123"], -- fullmoonbeam (strongest)
                spellbook["13"], -- eclipse
                spellbook["3"]   -- moondance
            }
            
            for _, spell in ipairs(attackOptions) do
                if spell and self.wizard:canPayManaCost(spell.cost) then
                    return { 
                        type = "CAST_SPELL", 
                        spell = spell,
                        reason = "Offensive finish"
                    }
                end
            end
        end
        
        return { 
            type = "ATTACK_ACTION", 
            reason = "Opponent low health (" .. p.opponentHealth .. ")"
        }
    
    -- Opponent is casting something - consider countering
    elseif p.opponentHasDangerousSpell and p.totalFreeTokens >= 2 then
        self.currentState = STATE.COUNTER
        
        -- Try counter spells
        if self:hasAvailableSpellSlot() then
            local counterOptions = {
                spellbook["13"], -- eclipse (freezes crown slot)
                spellbook["3"]   -- moondance (changes range, can disrupt)
            }
            
            for _, spell in ipairs(counterOptions) do
                if spell and self.wizard:canPayManaCost(spell.cost) then
                    return { 
                        type = "CAST_SPELL", 
                        spell = spell, 
                        reason = "Counter opponent spell"
                    }
                end
            end
        end
        
        return { 
            type = "COUNTER_ACTION", 
            reason = "Opponent casting spell"
        }
    
    -- If health advantage is significant and we're not in low health, attack
    elseif p.healthAdvantage > 15 and not p.selfLowHealth then
        self.currentState = STATE.ATTACK
        
        -- Use offensive spell based on available mana
        if self:hasAvailableSpellSlot() then
            local attackOptions = {
                spellbook["123"], -- fullmoonbeam (strongest)
                spellbook["13"], -- eclipse
                spellbook["3"]   -- moondance
            }
            
            for _, spell in ipairs(attackOptions) do
                if spell and self.wizard:canPayManaCost(spell.cost) then
                    return { 
                        type = "CAST_SPELL", 
                        spell = spell,
                        reason = "Press advantage"
                    }
                end
            end
        end
        
        return { 
            type = "ATTACK_ACTION", 
            reason = "Health advantage (" .. p.healthAdvantage .. ")"
        }
    
    -- If we're at a health disadvantage, consider defense
    elseif p.healthAdvantage < -15 and not p.hasActiveShield then
        self.currentState = STATE.DEFEND
        
        -- Look for shield spell
        local shieldSpell = spellbook["2"] -- wrapinmoonlight
        if shieldSpell and self.wizard:canPayManaCost(shieldSpell.cost) and self:hasAvailableSpellSlot() then
            return { 
                type = "CAST_SPELL", 
                spell = shieldSpell,
                reason = "Health disadvantage defense"
            }
        end
        
        return { 
            type = "DEFEND_ACTION", 
            reason = "Health disadvantage (" .. p.healthAdvantage .. ")"
        }
    
    -- If no tokens or very few tokens are available, focus on gaining resources
    elseif p.totalFreeTokens <= 1 then
        self.currentState = STATE.IDLE
        
        -- Try conjuring spell
        local conjureSpell = spellbook["1"] -- conjuremoonlight
        if conjureSpell and self:hasAvailableSpellSlot() and 
           (p.totalFreeTokens == 0 or self.wizard:canPayManaCost(conjureSpell.cost)) then
            return { 
                type = "CAST_SPELL", 
                spell = conjureSpell,
                reason = "Generate resources"
            }
        end
        
        return { 
            type = "CONJURE_ACTION", 
            reason = "Need resources (tokens: " .. p.totalFreeTokens .. ")"
        }
    
    -- Default state when no specific criteria are met - slight aggression bias
    else
        -- Slightly biased toward attacking when nothing else is going on
        local randomChoice = math.random(1, 10)
        
        if randomChoice <= 6 then -- 60% chance of attack
            self.currentState = STATE.ATTACK
            
            -- Try an attack spell if possible
            if self:hasAvailableSpellSlot() then
                local attackOptions = {
                    spellbook["123"], -- fullmoonbeam
                    spellbook["13"], -- eclipse
                    spellbook["3"]   -- moondance
                }
                
                for _, spell in ipairs(attackOptions) do
                    if spell and self.wizard:canPayManaCost(spell.cost) then
                        return { 
                            type = "CAST_SPELL", 
                            spell = spell,
                            reason = "Default attack"
                        }
                    end
                end
            end
            
            return { 
                type = "ATTACK_ACTION", 
                reason = "Default aggression"
            }
            
        elseif randomChoice <= 9 then -- 30% chance of defense
            self.currentState = STATE.DEFEND
            
            -- Try defensive spell if possible
            local shieldSpell = spellbook["2"] -- wrapinmoonlight
            if shieldSpell and self.wizard:canPayManaCost(shieldSpell.cost) and self:hasAvailableSpellSlot() 
               and not p.hasActiveShield then
                return { 
                    type = "CAST_SPELL", 
                    spell = shieldSpell,
                    reason = "Default defense"
                }
            end
            
            return { 
                type = "DEFEND_ACTION", 
                reason = "Default caution"
            }
            
        else -- 10% chance of resource gathering
            self.currentState = STATE.IDLE
            
            -- Try conjuring spell if possible
            local conjureSpell = spellbook["1"] -- conjuremoonlight
            if conjureSpell and self.wizard:canPayManaCost(conjureSpell.cost) and self:hasAvailableSpellSlot() then
                return { 
                    type = "CAST_SPELL", 
                    spell = conjureSpell,
                    reason = "Default resource gathering"
                }
            end
            
            return { 
                type = "WAIT_ACTION", 
                reason = "Default patience"
            }
        end
    end
end

-- Execute the decided action
function OpponentAI:act(decision)
    -- Safety check
    if not decision or not decision.type then
        print("[AI] No valid decision to act on")
        return
    end
    
    -- Log the action
    print("[AI Action] " .. decision.type)
    
    -- For conciseness
    local wizard = self.wizard
    
    -- Execute based on action type
    if decision.type == "WAIT_ACTION" then
        -- Do nothing (idle)
        print("[AI] Waiting...")
        
    elseif decision.type == "FREE_ALL" then
        -- Cancel all active spells
        print("[AI] Freeing all spells")
        wizard:freeAllSpells()
        
    elseif decision.type == "ATTACK_ACTION" then
        -- Choose and cast an offensive spell based on available mana
        self:castOffensiveSpell()
        
    elseif decision.type == "DEFEND_ACTION" then
        -- Choose and cast a defensive spell based on available mana
        self:castDefensiveSpell()
        
    elseif decision.type == "CONJURE_ACTION" then
        -- Cast a mana conjuring spell
        self:castConjurationSpell()
        
    elseif decision.type == "COUNTER_ACTION" then
        -- Cast a counter spell against opponent's active spell
        self:castCounterSpell()
        
    elseif decision.type == "ESCAPE_ACTION" then
        -- Cast an escape spell for desperate situations
        self:castEscapeSpell()
        
    elseif decision.type == "POSITION_ACTION" then
        -- Cast positioning spell to change range or elevation
        self:castPositioningSpell()
        
    elseif decision.type == "CAST_SPELL" and decision.spell then
        -- Direct spell casting (specified by higher-level logic)
        print("[AI] Casting specific spell: " .. decision.spell.name)
        local success = wizard:queueSpell(decision.spell)
        if not success then
            print("[AI] Failed to cast " .. decision.spell.name)
        end
    else
        print("[AI] Unknown action type: " .. decision.type)
    end
end

-- Helper function to check if a spell slot is available
function OpponentAI:hasAvailableSpellSlot()
    for _, slot in ipairs(self.wizard.spellSlots) do
        if not slot.active then
            return true
        end
    end
    return false
end

-- Try to cast an offensive spell based on available mana
function OpponentAI:castOffensiveSpell()
    local p = self.perception
    local spellbook = self.wizard.spellbook
    local spellsToTry = {}
    
    -- If we have a lot of tokens, try the most powerful spell
    if p.totalFreeTokens >= 3 and self:hasAvailableSpellSlot() then
        -- Try full moon beam (3-key combo) if we have enough mana
        table.insert(spellsToTry, spellbook["123"]) -- fullmoonbeam
    end
    
    -- Try 2-key offensive combos
    if p.totalFreeTokens >= 2 and self:hasAvailableSpellSlot() then
        -- Add offensive 2-key spells
        if p.opponentElevation == Constants.ElevationState.AERIAL then
            -- Gravity trap good against aerial opponents
            table.insert(spellsToTry, spellbook["23"]) -- gravityTrap
        end
        
        -- Try to use positioning tricks
        table.insert(spellsToTry, spellbook["13"]) -- eclipse
    end
    
    -- Try simpler attacks if nothing else worked
    if p.totalFreeTokens >= 1 and self:hasAvailableSpellSlot() then
        -- Add single key offensive spells
        table.insert(spellsToTry, spellbook["3"]) -- moondance (position change)
    end
    
    -- Try each spell in order of preference
    for _, spell in ipairs(spellsToTry) do
        if spell then
            print("[AI] Attempting offensive spell: " .. spell.name)
            local success = self.wizard:queueSpell(spell)
            if success then
                print("[AI] Successfully cast " .. spell.name)
                return true
            end
        end
    end
    
    -- If we couldn't cast anything offensive, try to build resources
    if p.totalFreeTokens < 2 then
        return self:castConjurationSpell()
    end
    
    return false
end

-- Try to cast a defensive spell based on available mana
function OpponentAI:castDefensiveSpell()
    local p = self.perception
    local spellbook = self.wizard.spellbook
    local spellsToTry = {}
    
    -- Best defense is shield
    if p.totalFreeTokens >= 2 and self:hasAvailableSpellSlot() then
        -- Try shield spell (wrapinmoonlight)
        table.insert(spellsToTry, spellbook["2"]) -- wrapinmoonlight
    end
    
    -- If we don't have enough tokens for a shield
    if p.totalFreeTokens >= 1 and self:hasAvailableSpellSlot() then
        -- Try to gain tokens
        table.insert(spellsToTry, spellbook["1"]) -- conjuremoonlight
    end
    
    -- Try each spell in order of preference
    for _, spell in ipairs(spellsToTry) do
        if spell then
            print("[AI] Attempting defensive spell: " .. spell.name)
            local success = self.wizard:queueSpell(spell)
            if success then
                print("[AI] Successfully cast " .. spell.name)
                return true
            end
        end
    end
    
    -- If we couldn't cast any defensive spell, try to build resources
    return self:castConjurationSpell()
end

-- Try to cast a mana conjuring spell
function OpponentAI:castConjurationSpell()
    local spellbook = self.wizard.spellbook
    
    -- Try conjuration spell if a slot is available
    if self:hasAvailableSpellSlot() then
        local conjureSpell = spellbook["1"] -- conjuremoonlight
        
        if conjureSpell then
            print("[AI] Attempting conjuration: " .. conjureSpell.name)
            local success = self.wizard:queueSpell(conjureSpell)
            if success then
                print("[AI] Successfully cast " .. conjureSpell.name)
                return true
            end
        end
    end
    
    return false
end

-- Try to cast a counter spell against opponent's active spell
function OpponentAI:castCounterSpell()
    local p = self.perception
    local spellbook = self.wizard.spellbook
    
    -- Check if there's something to counter and we have enough resources
    if p.opponentHasDangerousSpell and p.totalFreeTokens >= 2 and self:hasAvailableSpellSlot() then
        -- For Selene, try using eclipse or moondance
        local counterSpells = {
            spellbook["13"], -- eclipse (freezes crown slot)
            spellbook["3"]   -- moondance (can disrupt by changing range)
        }
        
        -- Try each counter spell
        for _, spell in ipairs(counterSpells) do
            if spell then
                print("[AI] Attempting counter spell: " .. spell.name)
                local success = self.wizard:queueSpell(spell)
                if success then
                    print("[AI] Successfully cast counter " .. spell.name)
                    return true
                end
            end
        end
    end
    
    -- If countering failed, try attacking instead
    return self:castOffensiveSpell()
end

-- Try to cast an escape spell for desperate situations
function OpponentAI:castEscapeSpell()
    local p = self.perception
    local spellbook = self.wizard.spellbook
    
    -- When in critical health, try shield, range change, or free all slots
    
    -- First priority: shields if not already shielded
    if not p.hasActiveShield and p.totalFreeTokens >= 2 and self:hasAvailableSpellSlot() then
        local shieldSpell = spellbook["2"] -- wrapinmoonlight
        if shieldSpell then
            print("[AI] Attempting emergency shield: " .. shieldSpell.name)
            local success = self.wizard:queueSpell(shieldSpell)
            if success then 
                return true
            end
        end
    end
    
    -- Second priority: change range/position
    if p.totalFreeTokens >= 1 and self:hasAvailableSpellSlot() then
        local escapeSpell = spellbook["3"] -- moondance
        if escapeSpell then
            print("[AI] Attempting escape with: " .. escapeSpell.name)
            local success = self.wizard:queueSpell(escapeSpell)
            if success then 
                return true
            end
        end
    end
    
    -- Last resort: free all slots to get more resources
    if p.activeSlots > 0 then
        print("[AI] Emergency - freeing all spell slots")
        self.wizard:freeAllSpells()
        return true
    end
    
    return false
end

-- Try to cast a positioning spell to change range or elevation
function OpponentAI:castPositioningSpell()
    local p = self.perception
    local spellbook = self.wizard.spellbook
    
    -- Try to use moondance to change range
    if p.totalFreeTokens >= 1 and self:hasAvailableSpellSlot() then
        local posSpell = spellbook["3"] -- moondance
        if posSpell then
            print("[AI] Attempting position change with: " .. posSpell.name)
            local success = self.wizard:queueSpell(posSpell)
            if success then
                return true
            end
        end
    end
    
    return false
end

return OpponentAI