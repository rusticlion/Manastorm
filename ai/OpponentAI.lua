-- ai/OpponentAI.lua
-- Basic AI opponent for Manastorm
-- Phase 2: Modular AI Architecture with Personality System

local Constants = require("core.Constants")
local ManaHelpers = require("systems.ManaHelpers")
local PersonalityBase = require("ai.PersonalityBase")

-- Define the OpponentAI module
local OpponentAI = {}

-- AI States - Define as constants for clarity
OpponentAI.STATE = {
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
-- @param personalityModule - The personality module to use for decision making
function OpponentAI.new(wizard, gameState, personalityModule)
    -- Create default personality if none provided
    personalityModule = personalityModule or PersonalityBase.new("Default")
    
    -- Create a new instance
    local ai = {
        -- Store references to game objects
        wizard = wizard,
        gameState = gameState,
        
        -- Store personality
        personality = personalityModule,
        
        -- Track the opposing wizard (player's wizard)
        playerWizard = nil,
        
        -- Track last perception time for throttling
        lastPerceptionTime = 0,
        perceptionInterval = 2, -- Update perception every 2 seconds
        
        -- Track last action time for throttling
        lastActionTime = 0,
        actionInterval = 1.0, -- Consider actions every 1.0 seconds
        
        -- Simple finite state machine
        currentState = OpponentAI.STATE.IDLE, -- Initial state
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
    print(string.format("PERSONALITY: %s", self.personality.name))
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
    
    -- Check if personality wants to override state selection
    local suggestedState = self.personality:suggestState(self, p)
    if suggestedState then
        self.currentState = suggestedState
    else
        -- Basic state transition logic based on health and threat
        
        -- Critical health - go into escape mode
        if p.selfCriticalHealth then
            self.currentState = OpponentAI.STATE.ESCAPE
        
        -- Low health - prioritize defense
        elseif p.selfLowHealth and not p.hasActiveShield then
            self.currentState = OpponentAI.STATE.DEFEND
        
        -- Opponent has very low health - press the advantage
        elseif p.opponentLowHealth then
            self.currentState = OpponentAI.STATE.ATTACK
        
        -- Opponent is casting something - consider countering
        elseif p.opponentHasDangerousSpell and p.totalFreeTokens >= 2 then
            self.currentState = OpponentAI.STATE.COUNTER
        
        -- If health advantage is significant and we're not in low health, attack
        elseif p.healthAdvantage > 15 and not p.selfLowHealth then
            self.currentState = OpponentAI.STATE.ATTACK
        
        -- If we're at a health disadvantage, consider defense
        elseif p.healthAdvantage < -15 and not p.hasActiveShield then
            self.currentState = OpponentAI.STATE.DEFEND
        
        -- If no tokens or very few tokens are available, focus on gaining resources
        elseif p.totalFreeTokens <= 1 then
            self.currentState = OpponentAI.STATE.IDLE
        
        -- Default state when no specific criteria are met - slight aggression bias
        else
            -- Slightly biased toward attacking when nothing else is going on
            local randomChoice = math.random(1, 10)
            
            if randomChoice <= 6 then -- 60% chance of attack
                self.currentState = OpponentAI.STATE.ATTACK
            elseif randomChoice <= 9 then -- 30% chance of defense
                self.currentState = OpponentAI.STATE.DEFEND
            else -- 10% chance of resource gathering
                self.currentState = OpponentAI.STATE.IDLE
            end
        end
    end
    
    -- State->Action mapping
    local spell = nil
    local actionType = nil
    local reason = nil
    
    -- Based on the current state, decide what specific spell to cast
    if self.currentState == OpponentAI.STATE.ATTACK then
        -- Ask personality module for attack spell
        spell = self.personality:getAttackSpell(self, p, spellbook)
        reason = "Attack"
        actionType = "ATTACK_ACTION"
    
    elseif self.currentState == OpponentAI.STATE.DEFEND then
        -- Ask personality module for defense spell
        spell = self.personality:getDefenseSpell(self, p, spellbook)
        reason = "Defense"
        actionType = "DEFEND_ACTION"
    
    elseif self.currentState == OpponentAI.STATE.COUNTER then
        -- Ask personality module for counter spell
        spell = self.personality:getCounterSpell(self, p, spellbook)
        reason = "Counter"
        actionType = "COUNTER_ACTION"
    
    elseif self.currentState == OpponentAI.STATE.ESCAPE then
        -- Emergency defense: shield, escape, or free all (last resort)
        if p.activeSlots > 0 and p.totalFreeTokens < 1 then
            -- No resources, free all spell slots
            return {
                type = "FREE_ALL",
                reason = "Critical health - free resources"
            }
        end
        
        -- Ask personality module for escape spell
        spell = self.personality:getEscapeSpell(self, p, spellbook)
        reason = "Escape"
        actionType = "ESCAPE_ACTION"
    
    elseif self.currentState == OpponentAI.STATE.POSITION then
        -- Ask personality module for positioning spell
        spell = self.personality:getPositioningSpell(self, p, spellbook)
        reason = "Positioning"
        actionType = "POSITION_ACTION"
    
    elseif self.currentState == OpponentAI.STATE.IDLE then
        -- Ask personality module for conjure/resource spell
        spell = self.personality:getConjureSpell(self, p, spellbook)
        reason = "Generate resources"
        actionType = "CONJURE_ACTION"
    end
    
    -- If we found a specific spell and have a slot for it, cast it
    if spell and self:hasAvailableSpellSlot() and self.wizard:canPayManaCost(spell.cost) then
        return {
            type = "CAST_SPELL",
            spell = spell,
            reason = reason
        }
    end
    
    -- Return the general action if no specific spell was found or affordable
    return {
        type = actionType,
        reason = reason .. " (no specific spell found or affordable)"
    }
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
        
    elseif decision.type == "CAST_SPELL" and decision.spell then
        -- Direct spell casting (specified by higher-level logic)
        print("[AI] Casting specific spell: " .. decision.spell.name)
        local success = wizard:queueSpell(decision.spell)
        if not success then
            print("[AI] Failed to cast " .. decision.spell.name)
        end
    
    -- Generic action types - try to get a spell from personality as fallback
    elseif decision.type == "ATTACK_ACTION" then
        local spell = self.personality:getBestSpellForIntent(OpponentAI.STATE.ATTACK, self, self.perception, self.wizard.spellbook)
        if spell and self:hasAvailableSpellSlot() and self.wizard:canPayManaCost(spell.cost) then
            print("[AI] Fallback casting attack spell: " .. spell.name)
            self.wizard:queueSpell(spell)
        else
            print("[AI] No suitable attack spell found")
        end
        
    elseif decision.type == "DEFEND_ACTION" then
        local spell = self.personality:getBestSpellForIntent(OpponentAI.STATE.DEFEND, self, self.perception, self.wizard.spellbook)
        if spell and self:hasAvailableSpellSlot() and self.wizard:canPayManaCost(spell.cost) then
            print("[AI] Fallback casting defense spell: " .. spell.name)
            self.wizard:queueSpell(spell)
        else
            print("[AI] No suitable defense spell found")
        end
        
    elseif decision.type == "COUNTER_ACTION" then
        local spell = self.personality:getBestSpellForIntent(OpponentAI.STATE.COUNTER, self, self.perception, self.wizard.spellbook)
        if spell and self:hasAvailableSpellSlot() and self.wizard:canPayManaCost(spell.cost) then
            print("[AI] Fallback casting counter spell: " .. spell.name)
            self.wizard:queueSpell(spell)
        else
            print("[AI] No suitable counter spell found")
        end
        
    elseif decision.type == "ESCAPE_ACTION" then
        local spell = self.personality:getBestSpellForIntent(OpponentAI.STATE.ESCAPE, self, self.perception, self.wizard.spellbook)
        if spell and self:hasAvailableSpellSlot() and self.wizard:canPayManaCost(spell.cost) then
            print("[AI] Fallback casting escape spell: " .. spell.name)
            self.wizard:queueSpell(spell)
        else
            print("[AI] No suitable escape spell found")
        end
        
    elseif decision.type == "POSITION_ACTION" then
        local spell = self.personality:getBestSpellForIntent(OpponentAI.STATE.POSITION, self, self.perception, self.wizard.spellbook)
        if spell and self:hasAvailableSpellSlot() and self.wizard:canPayManaCost(spell.cost) then
            print("[AI] Fallback casting positioning spell: " .. spell.name)
            self.wizard:queueSpell(spell)
        else
            print("[AI] No suitable positioning spell found")
        end
        
    elseif decision.type == "CONJURE_ACTION" then
        local spell = self.personality:getBestSpellForIntent(OpponentAI.STATE.IDLE, self, self.perception, self.wizard.spellbook)
        if spell and self:hasAvailableSpellSlot() and self.wizard:canPayManaCost(spell.cost) then
            print("[AI] Fallback casting conjure spell: " .. spell.name)
            self.wizard:queueSpell(spell)
        else
            print("[AI] No suitable conjure spell found")
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

return OpponentAI