-- EventRunner.lua
-- Processes spell events and applies them to game state
--
-- IMPORTANT: Visual Effects Pattern
-- =================================
-- This module now uses the VisualResolver for determining which VFX to trigger.
-- The pattern for creating visuals is:
--
-- 1. For typical gameplay events (damage, status, etc.):
--    - Keywords in keywords.lua should include visual metadata in their events
--    - The EFFECT handler in this module will use VisualResolver.pick() to determine visuals
--
-- 2. For specialized effects in other handlers:
--    - Generate an EFFECT event with proper metadata and dispatch it
--    - This ensures consistent visual handling through the VisualResolver
--
-- 3. Legacy direct VFX calls:
--    - Some handlers still use safeCreateVFX() directly (marked with TODO comments)
--    - These will be gradually migrated to use the VisualResolver pattern

local Constants = require("core.Constants")
local VisualResolver = require("systems.VisualResolver")
local EventRunner = {}

-- Constants for event processing order
local PROCESSING_PRIORITY = {
    -- State setting events (first)
    SET_ELEVATION = 10,
    SET_RANGE = 20,
    FORCE_POSITION = 30,
    ZONE_ANCHOR = 40,
    
    -- Resource events (second)
    CONJURE_TOKEN = 100,
    DISSIPATE_TOKEN = 110,
    SHIFT_TOKEN = 120,
    LOCK_TOKEN = 130,
    CONSUME_TOKENS = 140,
    
    -- Spell timeline events (third)
    ACCELERATE_SPELL = 210,
    CANCEL_SPELL = 220,
    FREEZE_SPELL = 230,
    
    -- Defense events (fourth)
    CREATE_SHIELD = 300,
    REFLECT = 310,
    
    -- Status effects (fifth)
    APPLY_STATUS = 400,
    
    -- Damage events (sixth)
    DAMAGE = 500,
    
    -- Visual effects (before special effects)
    EFFECT = 550,
    
    -- Special effects (last)
    ECHO = 600,
    ZONE_MULTI = 610
}

-- Sort events by their processing priority
local function sortEventsByPriority(events)
    table.sort(events, function(a, b)
        local priorityA = PROCESSING_PRIORITY[a.type] or 999
        local priorityB = PROCESSING_PRIORITY[b.type] or 999
        return priorityA < priorityB
    end)
    return events
end

-- Safe VFX creation helper function
local function safeCreateVFX(vfx, methodName, fallbackType, x, y, params)
    if not vfx then 
        print("DEBUG: VFX system is nil")
        return false 
    end
    
    -- Make sure x and y are valid numbers
    if not x or not y or type(x) ~= "number" or type(y) ~= "number" then
        x = 0
        y = 0
        print("DEBUG: Invalid coordinates for VFX, using (0,0)")
    end
    
    -- Debug the parameters
    print(string.format("[safeCreateVFX] Method: %s, EffectType: '%s', Coords: (%d, %d)", 
        methodName, tostring(fallbackType), x or 0, y or 0))
        
    -- Try to call the specific method
    if type(vfx[methodName]) == "function" then
        -- Method needs to be called as vfx:methodName() for self to be passed properly
        local success, err = pcall(function() 
            if methodName == "createEffect" then
                -- Print the type of vfx and fallbackType for debugging
                print("[safeCreateVFX] vfx is type: " .. type(vfx) .. ", fallbackType is type: " .. type(fallbackType))
                
                -- IMPORTANT: Need to use dot notation and pass VFX module as first arg for module functions
                -- DO NOT use colon notation (vfx:createEffect) as it passes vfx as self which makes effectName a table
                print("[safeCreateVFX] Calling vfx.createEffect with effectName: " .. tostring(fallbackType))
                vfx.createEffect(fallbackType, x, y, nil, nil, params)
            else
                -- For other methods
                print("[safeCreateVFX] Calling vfx." .. methodName)
                vfx[methodName](vfx, x, y, params) 
            end
        end)
        
        if not success then
            print("DEBUG: Error calling " .. methodName .. ": " .. tostring(err))
            -- Try fallback on error
            if methodName ~= "createEffect" and type(vfx.createEffect) == "function" then
                pcall(function() vfx.createEffect(fallbackType, x, y, nil, nil, params) end)
            end
        end
        return true
    -- Fall back to generic createEffect if available
    elseif type(vfx.createEffect) == "function" then
        local success, err = pcall(function() 
            vfx.createEffect(fallbackType, x, y, nil, nil, params) 
        end)
        
        if not success then
            print("DEBUG: Error calling createEffect: " .. tostring(err))
        end
        return true
    else
        -- Debug output if no VFX methods are available
        print("DEBUG: VFX system lacks both " .. methodName .. " and createEffect methods")
        return false
    end
end

-- Process all events and apply them to game state
function EventRunner.processEvents(events, caster, target, spellSlot)
    -- Double check we actually have valid input
    if not events or type(events) ~= "table" then
        print("WARNING: Nil or invalid events list passed to processEvents")
        return {
            eventsProcessed = 0,
            damageDealt = 0,
            statusEffectsApplied = {},
            shieldCreated = false,
            tokensAffected = 0,
            error = "Invalid events list"
        }
    end
    
    -- Verify caster and target are valid
    if not caster then
        print("WARNING: Nil caster passed to processEvents")
        return {
            eventsProcessed = 0,
            error = "Invalid caster"
        }
    end
    
    -- Create a results table to track effects 
    local results = {
        eventsProcessed = 0,
        damageDealt = 0,
        statusEffectsApplied = {},
        shieldCreated = false,
        tokensAffected = 0
    }
    
    -- Sort events by processing priority
    local success, sortedEvents = pcall(function() 
        return sortEventsByPriority(events)
    end)
    
    if not success then
        print("WARNING: Error sorting events: " .. tostring(sortedEvents))
        sortedEvents = events -- Use unsorted events as fallback
    end
    
    -- Process each event
    for _, event in ipairs(sortedEvents) do
        -- Skip invalid events
        if not event or not event.type then
            print("WARNING: Skipping invalid event")
            goto continue
        end
        
        -- Wrap event handling in pcall to prevent crashes
        local success, handled = pcall(function()
            return EventRunner.handleEvent(event, caster, target, spellSlot, results)
        end)
        
        if success and handled then
            results.eventsProcessed = results.eventsProcessed + 1
        elseif not success then
            -- Log error but continue processing other events
            print("ERROR processing event type " .. (event.type or "unknown") .. ": " .. tostring(handled))
        end
        
        ::continue::
    end
    
    return results
end

-- Handle a single event
function EventRunner.handleEvent(event, caster, target, spellSlot, results)
    -- Validate inputs
    if not event or not event.type then
        print("WARNING: Invalid event passed to handleEvent")
        return false
    end
    
    if not caster then
        print("WARNING: Nil caster in handleEvent for event type " .. event.type)
        return false
    end
    
    if not results then
        print("WARNING: Nil results in handleEvent for event type " .. event.type)
        results = {}
    end
    
    -- Get the event handler for this event type
    local handler = EventRunner.EVENT_HANDLERS[event.type]
    if not handler then
        print("WARNING: No handler for event type " .. event.type)
        return false
    end
    
    -- Call the handler with the event and context in protected mode
    local success, result = pcall(function()
        return handler(event, caster, target, spellSlot, results)
    end)
    
    if not success then
        print("ERROR in event handler for " .. event.type .. ": " .. tostring(result))
        return false
    end
    
    return result
end

-- Resolve the actual target entity for an event
-- This function handles both raw string target types (like "enemy_slot") 
-- and Constants.TargetType enum values (like Constants.TargetType.SLOT_ENEMY)
-- Always returns a table like { wizard, slotIndex } or nil
function EventRunner.resolveTarget(event, caster, target)
    -- Validate inputs
    if not event then
        print("WARNING: Nil event in resolveTarget")
        return {wizard = caster, slotIndex = nil} -- Default to caster as fallback
    end
    
    if not caster then
        print("WARNING: Nil caster in resolveTarget")
        return nil
    end
    
    local targetType = event.target
    local slotIndex = event.slotIndex -- Extract slotIndex from event
    
    -- Handle nil target type
    if targetType == nil then
        print("WARNING: Nil target type in event, defaulting to 'self'")
        return {wizard = caster, slotIndex = slotIndex}
    end
    
    -- Normalize target types to handle both string literals and Constants.TargetType values
    local normalizedTargetType = ""
    if type(targetType) == "string" then
        normalizedTargetType = string.lower(targetType)
    else
        print("WARNING: Non-string target type: " .. type(targetType) .. ", defaulting to 'self'")
        return {wizard = caster, slotIndex = slotIndex}
    end
    
    -- Handle Constants.TargetType values (mapping to strings)
    if targetType == Constants.TargetType.SLOT_ENEMY then
        normalizedTargetType = "enemy_slot"
    elseif targetType == Constants.TargetType.SLOT_SELF then
        normalizedTargetType = "self_slot"
    elseif targetType == Constants.TargetType.SELF then
        normalizedTargetType = "self"
    elseif targetType == Constants.TargetType.ENEMY then
        normalizedTargetType = "enemy"
    elseif targetType == Constants.TargetType.POOL_SELF or targetType == Constants.TargetType.POOL_ENEMY then
        -- Pool targets are handled differently, return nil for wizard/slot structure
        -- The handler must specifically check for pool targets
        return nil 
    end
    
    -- Process normalized target types
    if normalizedTargetType == "self" then
        return {wizard = caster, slotIndex = slotIndex}
    elseif normalizedTargetType == "enemy" then
        if not target then
            print("WARNING: Event targets 'enemy' but target is nil, cannot resolve")
            return nil
        end
        return {wizard = target, slotIndex = slotIndex}
    elseif normalizedTargetType == "self_slot" then
        return {wizard = caster, slotIndex = slotIndex}
    elseif normalizedTargetType == "enemy_slot" then
        if not target then
            print(string.format("WARNING: Event targets 'enemy_slot' but target is nil (event: %s)", event and event.type or "nil"))
            return nil
        end
        return {wizard = target, slotIndex = slotIndex}
    else
        -- Default case for unrecognized types
        print("WARNING: Unrecognized target type: " .. tostring(event.target) .. ", defaulting to 'self'")
        return {wizard = caster, slotIndex = slotIndex}
    end
end

-- Event handler functions
EventRunner.EVENT_HANDLERS = {
    -- ===== Damage Events =====
    
    DAMAGE = function(event, caster, target, spellSlot, results)
        -- Resolve target, expecting { wizard, slotIndex } table or nil
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        
        -- Check if target resolution failed OR if the wizard object is missing
        if not targetInfo or not targetInfo.wizard then 
            print("ERROR: DAMAGE handler could not resolve target wizard")
            return false 
        end
        
        -- Get the actual wizard object
        local targetWizard = targetInfo.wizard
        
        -- Apply damage to the target wizard's health
        targetWizard.health = targetWizard.health - event.amount
        
        -- Ensure health doesn't go below zero
        if targetWizard.health < 0 then targetWizard.health = 0 end
        
        -- Debug log damage application
        print(string.format("[DAMAGE EVENT] Applied %d damage to %s. New health: %d", 
            event.amount, targetWizard.name, targetWizard.health))
            
        -- Debug log visual metadata
        print(string.format("[DAMAGE EVENT] Visual metadata: affinity=%s, attackType=%s, damageType=%s, manaCost=%s", 
            tostring(event.affinity),
            tostring(event.attackType),
            tostring(event.damageType),
            tostring(event.manaCost)))
        print(string.format("[DAMAGE EVENT] More metadata: tags=%s, rangeBand=%s, elevation=%s", 
            event.tags and "present" or "nil",
            tostring(event.rangeBand),
            tostring(event.elevation)))
        
        -- Track damage for results
        results.damageDealt = results.damageDealt + event.amount
        
        -- Generate an EFFECT event for the damage
        -- Check if we have a spell with effectOverride first
        local effectOverride = nil
        if spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] and 
           caster.spellSlots[spellSlot].spell and caster.spellSlots[spellSlot].spell.effectOverride then
            effectOverride = caster.spellSlots[spellSlot].spell.effectOverride
        end
        
        -- Create EFFECT event
        local effectEvent = {
            type = "EFFECT",
            source = "caster",
            target = event.target,
            effectOverride = effectOverride, -- Use override if we have one
            
            -- Copy visual metadata from the damage event
            affinity = event.affinity,
            attackType = event.attackType,
            damageType = event.damageType,
            manaCost = event.manaCost,
            tags = event.tags or { DAMAGE = true },
            rangeBand = event.rangeBand,
            elevation = event.elevation
        }
        
        -- Debug log the generated EFFECT event
        print(string.format("[DAMAGE->EFFECT] Generated EFFECT event with effectOverride=%s", 
            tostring(effectOverride)))
        print(string.format("[DAMAGE->EFFECT] Transferred metadata: affinity=%s, attackType=%s, damageType=%s", 
            tostring(effectEvent.affinity),
            tostring(effectEvent.attackType),
            tostring(effectEvent.damageType)))
        print(string.format("[DAMAGE->EFFECT] More metadata: tags=%s, rangeBand=%s, elevation=%s", 
            effectEvent.tags and "present" or "nil",
            tostring(effectEvent.rangeBand),
            tostring(effectEvent.elevation)))
        
        -- Process the effect event to create visuals
        EventRunner.handleEvent(effectEvent, caster, target, spellSlot, results)
        
        return true
    end,
    
    -- ===== Status Effect Events =====
    
    APPLY_STATUS = function(event, caster, target, spellSlot, results)
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        if not targetInfo or not targetInfo.wizard then 
            print("ERROR: APPLY_STATUS handler could not resolve target wizard")
            return false 
        end
        local targetWizard = targetInfo.wizard
        
        -- Initialize status effects table if it doesn't exist
        targetWizard.statusEffects = targetWizard.statusEffects or {}
        
        -- Add or update the status effect - Store relevant fields from the event
        targetWizard.statusEffects[event.statusType] = {
            active = true, -- Mark as active
            duration = event.duration or 0, -- How long the status lasts (or waits, for slow)
            tickDamage = event.tickDamage, -- For DoTs like burn
            tickInterval = event.tickInterval, -- For DoTs like burn
            magnitude = event.magnitude, -- For effects like slow (cast time increase)
            targetSlot = event.targetSlot, -- For effects like slow (specific slot)
            elapsed = 0, -- Timer for DoT ticks
            totalTime = 0, -- Timer for overall duration
            source = caster -- Who applied the status
        }
        
        -- Log the application
        print(string.format("[STATUS] Applied %s to %s (Duration: %.1f, Magnitude: %s, Slot: %s)", 
            event.statusType, targetWizard.name, event.duration or 0, tostring(event.magnitude), tostring(event.targetSlot)))

        -- Track applied status for results
        table.insert(results.statusEffectsApplied, event.statusType)
        
        -- Create status effect VFX if available
        if caster.gameState and caster.gameState.vfx then
            -- Assuming createStatusEffect takes the wizard object
            caster.gameState.vfx.createStatusEffect(targetWizard, event.statusType)
        end
        
        return true
    end,
    
    -- ===== Elevation Events =====
    
    SET_ELEVATION = function(event, caster, target, spellSlot, results)
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        if not targetInfo or not targetInfo.wizard then 
             print("ERROR: SET_ELEVATION handler could not resolve target wizard")
             return false
        end
        local targetWizard = targetInfo.wizard
        
        -- Set elevation state
        targetWizard.elevation = event.elevation
        
        -- Set duration if provided
        if event.duration then
            targetWizard.elevationEffects = targetWizard.elevationEffects or {}
            targetWizard.elevationEffects[event.elevation] = {
                duration = event.duration,
                expireAction = function()
                    -- When effect expires, return to default elevation (usually GROUNDED)
                    targetWizard.elevation = "GROUNDED"
                end
            }
        end
        
        -- No need to manually trigger position animation here -
        -- The wizard's positionAnimation is automatically detected and handled
        -- in WizardVisuals.drawWizard when elevation changes
        
        -- Create elevation change VFX if available
        if caster.gameState and caster.gameState.vfx then
            -- Interim Approach: Generate an EFFECT event to handle VFX consistently
            local effectEvent = {
                type = "EFFECT",
                source = "caster",
                target = event.target,
                -- If the event has a custom vfx specified, use it as an override
                effectOverride = (event.vfx and type(event.vfx) == "string") and event.vfx or nil,
                -- Provide elevation metadata for the resolver
                affinity = event.affinity, -- Use affinity from original event
                attackType = "utility",    -- Elevation is a utility spell type
                manaCost = event.manaCost or 1,
                tags = { MOVEMENT = true, [event.elevation == "AERIAL" and "ELEVATE" or "GROUND"] = true },
                rangeBand = caster.gameState.rangeState,
                elevation = event.elevation,
                duration = 1.0
            }
            
            -- Process the effect event, which will use the VisualResolver internally
            -- This ensures consistent visual handling for all effects
            EventRunner.handleEvent(effectEvent, caster, target, spellSlot, results)
            
            -- Note: The above approach is cleaner than calling VisualResolver directly
            -- as it ensures all event parameters are properly passed through
        end
        
        return true
    end,
    
    -- ===== Range Events =====
    
    SET_RANGE = function(event, caster, target, spellSlot, results)
        local targetEntities
        
        -- Range changes always affect both wizards
        if event.target == "both" then
            targetEntities = {caster, target}
        else
            targetEntities = {EventRunner.resolveTarget(event, caster, target)}
        end
        
        -- Update game state with new range
        if caster.gameState then
            -- Store the new range state
            caster.gameState.rangeState = event.position
            
            -- No need to call any extra position animation functions - the wizards'
            -- positionAnimation state is automatically detected and updated in 
            -- WizardVisuals.drawWizard when it sees the range state has changed
        end
        
        -- Create range change VFX if available
        if caster.gameState and caster.gameState.vfx then
            -- Generate an EFFECT event for consistent handling through VisualResolver
            local effectEvent = {
                type = "EFFECT",
                source = "caster",
                target = "both", -- Range changes affect both wizards
                effectOverride = Constants.VFXType.RANGE_CHANGE, -- Use explicit override for this special effect
                -- Provide relevant metadata for the resolver
                affinity = event.affinity,
                attackType = "utility",
                manaCost = 1,
                tags = { MOVEMENT = true },
                rangeBand = event.position, -- The new range state
                elevation = caster.elevation,
                duration = 1.0,
                -- Extra params specific to range changes
                position = event.position
            }
            
            -- Process the effect event through the standard pipeline
            EventRunner.handleEvent(effectEvent, caster, target, spellSlot, results)
        end
        
        return true
    end,
    
    FORCE_POSITION = function(event, caster, target, spellSlot, results)
        -- Force opponent to match caster's range
        -- Range is stored in game state, not on individual wizards
        if caster.gameState then
            -- Just a shortcut to quickly force range change - could be expanded if needed
            caster.gameState.rangeState = caster.gameState.rangeState
            
            -- Create position force VFX if available
            if caster.gameState.vfx then
                -- TODO: VFX-R5 - Update this to use VisualResolver pattern
                -- This handler should be refactored to generate an EFFECT event
                -- for consistency, but we'll leave it for now as it's a specialized effect
                local params = {
                    duration = 1.0,
                    source = caster.name,
                    target = target.name
                }
                
                safeCreateVFX(
                    caster.gameState.vfx,
                    "createPositionForceEffect",
                    Constants.VFXType.FORCE_POSITION,
                    (caster.x + target.x) / 2,  -- Midpoint
                    (caster.y + target.y) / 2,  -- Midpoint
                    params
                )
            end
        end
        
        return true
    end,
    
    -- ===== Resource & Token Events =====
    
    CONJURE_TOKEN = function(event, caster, target, spellSlot, results)
        local manaPool = caster.manaPool
        if not manaPool then return false end
        
        -- Create VFX for token conjuration if available
        if caster.gameState and caster.gameState.vfx then
            local params = {
                tokenType = event.tokenType,
                amount = event.amount
            }
            
            safeCreateVFX(
                caster.gameState.vfx,
                "createTokenConjureEffect",
                Constants.VFXType.CONJUREFIRE,  -- Use a VFX type that matches the conjuring action
                caster.x,
                caster.y,
                params
            )
        end
        
        -- Add tokens to the mana pool with animation
        for i = 1, event.amount do
            local assetPath = "assets/sprites/v2Tokens/" .. event.tokenType .. "-token.png"
            manaPool:addTokenWithAnimation(event.tokenType, assetPath, caster)
            results.tokensAffected = results.tokensAffected + 1
        end
        
        return true
    end,
    
    DISSIPATE_TOKEN = function(event, caster, target, spellSlot, results)
        local manaPool = caster.manaPool
        if not manaPool then return false end
        
        -- Find and remove tokens from the mana pool
        local tokensRemoved = 0
        
        -- Logic to find and mark tokens for removal
        for i, token in ipairs(manaPool.tokens) do
            local isFree = (token.status == Constants.TokenStatus.FREE)
            local matchesType = (event.tokenType == "any" or token.type == event.tokenType)
            
            if isFree and matchesType then
                -- Request destruction animation using state machine
                token:requestDestructionAnimation()
                
                tokensRemoved = tokensRemoved + 1
                results.tokensAffected = results.tokensAffected + 1
                
                -- Stop once we've marked enough tokens
                if tokensRemoved >= event.amount then
                    break
                end
            end
        end
        
        return true
    end,
    
    SHIFT_TOKEN = function(event, caster, target, spellSlot, results)
        local manaPool = caster.manaPool
        if not manaPool then return false end
        
        -- Count how many tokens we successfully shifted
        local tokensShifted = 0
        
        -- Handle random token shifting
        if event.tokenType == "random" then
            local tokenTypes = {"fire", "water", "salt", "sun", "moon", "star", "life", "mind", "void"}
            
            -- Find FREE tokens and shift them to random types
            for i, token in ipairs(manaPool.tokens) do
                if token.status == Constants.TokenStatus.FREE then
                    -- Pick a random token type
                    local randomType = tokenTypes[math.random(#tokenTypes)]
                    local oldType = token.type
                    
                    -- Only change if it's a different type
                    if randomType ~= oldType then
                        token.type = randomType
                        token.image = love.graphics.newImage("assets/sprites/v2Tokens/" .. randomType .. "-token.png")
                        tokensShifted = tokensShifted + 1
                        results.tokensAffected = results.tokensAffected + 1
                    end
                    
                    -- Stop once we've shifted enough tokens
                    if tokensShifted >= event.amount then
                        break
                    end
                end
            end
        else
            -- Find FREE tokens and shift them to the specified type
            for i, token in ipairs(manaPool.tokens) do
                if token.status == Constants.TokenStatus.FREE and token.type ~= event.tokenType then
                    token.type = event.tokenType
                    token.image = love.graphics.newImage("assets/sprites/v2Tokens/" .. event.tokenType .. "-token.png")
                    tokensShifted = tokensShifted + 1
                    results.tokensAffected = results.tokensAffected + 1
                    
                    -- Stop once we've shifted enough tokens
                    if tokensShifted >= event.amount then
                        break
                    end
                end
            end
        end
        
        return true
    end,
    
    LOCK_TOKEN = function(event, caster, target, spellSlot, results)
        -- Target the SHARED mana pool via gameState
        local manaPool = caster.gameState.manaPool 
        if not manaPool then 
            print("ERROR: LOCK_TOKEN handler could not find shared manaPool via caster.gameState")
            return false 
        end
        
        -- Find all FREE tokens matching the type (or 'any')
        local freeTokens = {}
        for i, token in ipairs(manaPool.tokens) do
            if token.status == Constants.TokenStatus.FREE and (event.tokenType == "any" or token.type == event.tokenType) then
                table.insert(freeTokens, token)
            end
        end
        
        -- If no free tokens found, do nothing
        if #freeTokens == 0 then
            return false -- Indicate event didn't successfully apply
        end
        
        -- Lock the specified amount (usually 1) of random free tokens
        local tokensLocked = 0
        local lockAmount = event.amount or 1
        
        while tokensLocked < lockAmount and #freeTokens > 0 do
            -- Select a random token from the list
            local randomIndex = math.random(#freeTokens)
            local tokenToLock = table.remove(freeTokens, randomIndex)
            
            -- Lock the selected token
            if tokenToLock.setState then
                tokenToLock:setState(Constants.TokenStatus.LOCKED)
            end
            tokenToLock.lockTimer = event.duration
            tokensLocked = tokensLocked + 1
            results.tokensAffected = results.tokensAffected + 1
            
            -- Create lock visual effect if VFX system available
            if caster.gameState and caster.gameState.vfx then
                local params = {
                    duration = event.duration,
                    tokenType = tokenToLock.type
                }
                
                safeCreateVFX(
                    caster.gameState.vfx,
                    "createTokenLockEffect",
                    Constants.VFXType.TOKEN_LOCK,
                    tokenToLock.x,
                    tokenToLock.y,
                    params
                )
            end
        end
        
        return tokensLocked > 0 -- Return true if at least one token was locked
    end,
    
    -- ===== Spell Timing Events =====
    
    ACCELERATE_SPELL = function(event, caster, target, spellSlot, results)
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        if not targetInfo or not targetInfo.wizard then return false end
        
        local wizard = targetInfo.wizard
        local slotIndex = targetInfo.slotIndex
        
        -- If slotIndex is not specified, use the current slot
        if not slotIndex or slotIndex == 0 then
            slotIndex = spellSlot
        end
        
        -- Apply acceleration to the slot
        local slot = wizard.spellSlots[slotIndex]
        if slot and slot.active and not slot.isShield then
            slot.progress = slot.progress + event.amount
            
            -- Create acceleration VFX if available
            if caster.gameState and caster.gameState.vfx then
                local params = {
                    duration = 1.0,
                    amount = event.amount,
                    slotIndex = slotIndex
                }
                
                safeCreateVFX(
                    caster.gameState.vfx,
                    "createSpellAccelerateEffect",
                    Constants.VFXType.SPELL_ACCELERATE,
                    wizard.x,
                    wizard.y,
                    params
                )
            end
            
            return true
        end
        
        return false
    end,
    
    CANCEL_SPELL = function(event, caster, target, spellSlot, results)
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        if not targetInfo or not targetInfo.wizard then return false end
        
        local wizard = targetInfo.wizard
        local slotIndex = targetInfo.slotIndex
        
        -- If slotIndex is not specified, pick a random active slot
        if not slotIndex or slotIndex == 0 then
            local activeSlots = {}
            for i, slot in ipairs(wizard.spellSlots) do
                if slot.active and not slot.isShield then
                    table.insert(activeSlots, i)
                end
            end
            
            if #activeSlots > 0 then
                slotIndex = activeSlots[math.random(#activeSlots)]
            else
                -- No active slots, nothing to cancel
                return false
            end
        end
        
        -- Apply cancel to the slot
        local slot = wizard.spellSlots[slotIndex]
        if slot and slot.active and not slot.isShield then
            -- Check if mana should be returned to the pool
            if event.returnMana then
                -- Return tokens to the pool (dispel)
                for _, tokenData in ipairs(slot.tokens) do
                    if tokenData.token then
                        tokenData.token:requestReturnAnimation()
                    end
                end
            else
                -- Destroy tokens (disjoint)
                for _, tokenData in ipairs(slot.tokens) do
                    if tokenData.token then
                        tokenData.token:requestDestructionAnimation()
                    end
                end
            end
            
            -- Reset the slot
            wizard:resetSpellSlot(slotIndex)
            
            -- Create cancel VFX if available
            if caster.gameState and caster.gameState.vfx then
                local params = {
                    duration = 1.0,
                    returnMana = event.returnMana,
                    slotIndex = slotIndex
                }
                
                safeCreateVFX(
                    caster.gameState.vfx,
                    "createSpellCancelEffect",
                    Constants.VFXType.SPELL_CANCEL,
                    wizard.x,
                    wizard.y,
                    params
                )
            end
            
            return true
        end
        
        return false
    end,
    
    FREEZE_SPELL = function(event, caster, target, spellSlot, results)
        local resolvedTarget = EventRunner.resolveTarget(event, caster, target)
        
        -- Determine the actual wizard and slot index
        local wizardToFreeze = nil
        local slotIndexToFreeze = event.slotIndex or 3 -- Get slot from event, default to 2
        
        if not resolvedTarget then
            print("ERROR: FREEZE_SPELL target resolution failed.")
            return false
        end
        
        -- Check the type of the resolved target
        if type(resolvedTarget) == "table" then
            if resolvedTarget.wizard then 
                -- It's a slot target table: {wizard, slotIndex}
                wizardToFreeze = resolvedTarget.wizard
                -- Use slot index from table if provided, otherwise stick to event/default
                slotIndexToFreeze = resolvedTarget.slotIndex or slotIndexToFreeze 
            elseif resolvedTarget.name then 
                -- It's likely a direct wizard object (check for 'name' as indicator)
                wizardToFreeze = resolvedTarget
            else
                -- It's some other table type (e.g., manaPool), which is invalid for FREEZE
                 print("ERROR: FREEZE_SPELL resolved target is an unexpected table type.")
                 return false
            end
        else
            -- Should not happen if resolveTarget is working, but handle unexpected types
            print("ERROR: FREEZE_SPELL resolved target is not a table (wizard or slot table expected).")
            return false
        end

        -- Final check for wizard object
        if not wizardToFreeze then
            print("ERROR: FREEZE_SPELL could not determine target wizard.")
            return false
        end

        -- Handle case where slot index is nil or 0 (needs default/random logic)
        if not slotIndexToFreeze or slotIndexToFreeze == 0 then
            slotIndexToFreeze = 2 -- Default to middle slot
            
            -- If default slot 2 is not active, find *any* active, non-shield slot
            if not wizardToFreeze.spellSlots[slotIndexToFreeze] or not wizardToFreeze.spellSlots[slotIndexToFreeze].active or wizardToFreeze.spellSlots[slotIndexToFreeze].isShield then
                local activeSlots = {}
                for i, slotData in ipairs(wizardToFreeze.spellSlots) do
                    if slotData.active and not slotData.isShield then
                        table.insert(activeSlots, i)
                    end
                end
                
                if #activeSlots > 0 then
                    slotIndexToFreeze = activeSlots[math.random(#activeSlots)]
                else
                    return false -- No valid target slot
                end
            end
        end
        
        -- Apply freeze to the determined wizard and slot index
        local slot = wizardToFreeze.spellSlots[slotIndexToFreeze]

        if slot and slot.active and not slot.isShield then
            slot.frozen = true
            slot.freezeTimer = event.duration
            
            -- Create freeze VFX if available
            if caster.gameState and caster.gameState.vfx then
                local params = {
                    duration = event.duration,
                    slotIndex = slotIndexToFreeze
                }
                
                safeCreateVFX(
                    caster.gameState.vfx,
                    "createSpellFreezeEffect",
                    Constants.VFXType.SPELL_FREEZE,
                    wizardToFreeze.x,
                    wizardToFreeze.y,
                    params
                )
            end
            
            -- Return true and results structure
            results.freezeApplied = true
            results.frozenSlot = slotIndexToFreeze
            results.freezeDuration = event.duration
            return true
        end
        
        return false
    end,
    
    -- NEW HANDLER: Disrupts channeling, shifts token type, returns it to pool
    DISRUPT_AND_SHIFT = function(event, caster, target, spellSlot, results)
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        if not targetInfo or not targetInfo.wizard then return false end
        
        local wizard = targetInfo.wizard
        local slotIndex = targetInfo.slotIndex
        
        -- If slotIndex is 0 or nil, pick a random active slot (including shields)
        if not slotIndex or slotIndex == 0 then
            local activeSlots = {}
            for i, slot in ipairs(wizard.spellSlots) do
                if slot.active then 
                    table.insert(activeSlots, i)
                end
            end
            
            if #activeSlots > 0 then
                slotIndex = activeSlots[math.random(#activeSlots)]
            else
                return false -- No valid target slot
            end
        end
        
        -- Get the target slot
        local slot = wizard.spellSlots[slotIndex]
        if not slot or not slot.active or not slot.tokens or #slot.tokens == 0 then
            return false -- Invalid target slot
        end
        
        -- Select 1 random token from the slot's tokens
        local tokenIndexToRemove = math.random(#slot.tokens)
        local tokenDataToRemove = slot.tokens[tokenIndexToRemove]
        local removedTokenObject = tokenDataToRemove.token
        local originalType = removedTokenObject and removedTokenObject.type or "unknown"

        -- Remove the token data reference from the slot
        table.remove(slot.tokens, tokenIndexToRemove)

        -- Shift the REMOVED token object's type and request return animation
        if removedTokenObject then
            local newType = event.newType or "fire"
            local oldType = removedTokenObject.type
            removedTokenObject.type = newType
            removedTokenObject.image = love.graphics.newImage("assets/sprites/v2Tokens/" .. newType .. "-token.png")
            results.tokensAffected = (results.tokensAffected or 0) + 1
            
            -- Request token return animation
            removedTokenObject:requestReturnAnimation()

            -- Trigger a VFX for the type shift
            if caster.gameState and caster.gameState.vfx then
                local params = {
                    duration = 0.8,
                    oldType = oldType,
                    newType = newType
                }
                safeCreateVFX(
                    caster.gameState.vfx,
                    "createTokenShiftEffect", -- Need to add this VFX method
                    Constants.VFXType.TOKEN_SHIFT,
                    removedTokenObject.x, 
                    removedTokenObject.y,
                    params
                )
            end
        else
            print("WARNING: Could not find token object to shift after removal from slot.")
        end

        -- Call the centralized Law of Completion check on the target wizard
        wizard:checkFizzleOnTokenRemoval(slotIndex, removedTokenObject)
        
        return true -- Event succeeded
    end,
    
    -- CONSUME_TOKENS: Permanently removes the tokens channeled to cast a spell
    CONSUME_TOKENS = function(event, caster, target, spellSlot, results)
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        if not targetInfo or not targetInfo.wizard then return false end
        
        local wizard = targetInfo.wizard
        local slotIndex = event.slotIndex or spellSlot
        
        -- Get the target slot
        local slot = wizard.spellSlots[slotIndex]
        if not slot or not slot.active or not slot.tokens or #slot.tokens == 0 then
            return false -- Invalid target slot
        end
        
        -- Track how many tokens we consume
        local tokensConsumed = 0
        
        -- Go through all tokens in the slot and mark them for destruction
        for _, tokenData in ipairs(slot.tokens) do
            if tokenData.token then
                -- Check if we should consume this token based on amount parameter
                local shouldConsume = true
                if event.amount ~= "all" and tokensConsumed >= event.amount then
                    shouldConsume = false
                end
                
                if shouldConsume then
                    -- Request destruction animation
                    tokenData.token:requestDestructionAnimation()
                    
                    tokensConsumed = tokensConsumed + 1
                    results.tokensAffected = (results.tokensAffected or 0) + 1
                end
            end
        end
        
        -- Create VFX for token consumption if available
        if tokensConsumed > 0 and caster.gameState and caster.gameState.vfx then
            local params = {
                slotIndex = slotIndex,
                tokensConsumed = tokensConsumed
            }
            
            safeCreateVFX(
                caster.gameState.vfx,
                "createTokenConsumeEffect",
                Constants.VFXType.TOKEN_CONSUME,
                wizard.x,
                wizard.y,
                params
            )
        end
        
        print(string.format("[CONSUME] Consumed %d tokens from slot %d", tokensConsumed, slotIndex))
        
        return tokensConsumed > 0 -- Success if at least one token was consumed
    end,
    
    -- ===== Defense Events =====
    
    CREATE_SHIELD = function(event, caster, target, spellSlot, results)
        -- For shields, we need to handle events differently because the wizard is always the caster
        -- and the target is always a spell slot on the caster
        local wizard = nil
        local slotIndex = nil
        
        -- Determine which wizard and slot to use
        if event.target == "self_slot" then
            wizard = caster
            slotIndex = event.slotIndex or spellSlot
        elseif event.target == "SELF" or event.target == "self" then
            -- Handle case when target is just "SELF" (shield spells often use this)
            wizard = caster
            slotIndex = spellSlot
        else
            -- Try the normal target resolution for other cases
            local targetInfo = EventRunner.resolveTarget(event, caster, target)
            if targetInfo and targetInfo.wizard then
                wizard = targetInfo.wizard
                slotIndex = targetInfo.slotIndex or spellSlot
            end
        end
        
        -- Verify we have a valid wizard and slot
        if not wizard or not slotIndex then
            print("ERROR: Invalid wizard or slot for shield creation")
            return false
        end
        
        -- Check that the slot exists and has tokens
        local slot = wizard.spellSlots[slotIndex]
        if not slot or not slot.tokens or #slot.tokens == 0 then 
            print("ERROR: Slot " .. slotIndex .. " invalid or has no tokens for shield")
            return false 
        end
        
        -- Create shield parameters from the event
        local shieldParams = {
            createShield = true,
            defenseType = event.defenseType or "barrier",
            type = event.defenseType or "barrier", -- Add type as well for compatibility
            blocksAttackTypes = event.blocksAttackTypes or {"projectile"},
            reflect = event.reflect or false,
            onBlock = event.onBlock or nil
        }
        
        -- Debug logging for onBlock
        if event.onBlock then
            print("[EVENT DEBUG] CREATE_SHIELD event contains onBlock handler")
            print("[EVENT DEBUG] Type of onBlock: " .. type(event.onBlock))
            
            -- Check if it's actually a function
            if type(event.onBlock) == "function" then
                print("[EVENT DEBUG] onBlock is a valid function")
            else
                print("[EVENT DEBUG] WARNING: onBlock is not a function!")
            end
        else
            print("[EVENT DEBUG] CREATE_SHIELD event has no onBlock handler")
        end
        
        -- Check if the wizard has a createShield method
        if type(wizard.createShield) ~= "function" then
            print("ERROR: Wizard " .. wizard.name .. " does not have createShield method")
            
            -- Default implementation if the method is missing
            print("Using fallback shield creation")
            slot.isShield = true
            slot.defenseType = shieldParams.defenseType
            slot.blocksAttackTypes = shieldParams.blocksAttackTypes
            slot.reflect = shieldParams.reflect
            slot.onBlock = shieldParams.onBlock
            
            -- Mark tokens as shielding
            for _, tokenData in ipairs(slot.tokens) do
                if tokenData.token then
                    tokenData.token:setState(Constants.TokenStatus.SHIELDING)
                    print("DEBUG: Marked token as SHIELDING to prevent return to pool")
                end
            end
        else
            -- Call the wizard's createShield method
            wizard:createShield(slotIndex, shieldParams)
        end
        
        -- Track shield creation in results
        results.shieldCreated = true
        
        return true
    end,
    
    REFLECT = function(event, caster, target, spellSlot, results)
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        if not targetInfo or not targetInfo.wizard then 
             print("ERROR: REFLECT handler could not resolve target wizard")
            return false
        end
        local targetWizard = targetInfo.wizard
        
        -- Set reflect property on the wizard
        targetWizard.reflectActive = true
        targetWizard.reflectDuration = event.duration
        
        -- Create reflect VFX if available
        if caster.gameState and caster.gameState.vfx then
            -- Generate an EFFECT event for consistent handling through VisualResolver
            local effectEvent = {
                type = "EFFECT",
                source = "caster",
                target = event.target,
                effectOverride = Constants.VFXType.REFLECT, -- Use explicit override for now
                -- Provide relevant metadata for the resolver
                affinity = event.affinity, 
                attackType = "utility",
                manaCost = event.manaCost or 2,
                tags = { DEFENSE = true, SHIELD = true },
                rangeBand = caster.gameState.rangeState,
                elevation = targetWizard.elevation,
                duration = event.duration or 3.0
            }
            
            -- Process the effect event through the standard pipeline
            EventRunner.handleEvent(effectEvent, caster, target, spellSlot, results)
        end
        
        return true
    end,
    
    -- ===== Special Events =====
    
    ECHO = function(event, caster, target, spellSlot, results)
        local targetInfo = EventRunner.resolveTarget(event, caster, target)
        if not targetInfo or not targetInfo.wizard then return false end
        
        local wizard = targetInfo.wizard
        local slotIndex = targetInfo.slotIndex or spellSlot
        
        -- Schedule an echo of the current spell
        local slot = wizard.spellSlots[slotIndex]
        if slot and slot.spell then
            -- Create an echo entry in the wizard's echo queue
            wizard.echoQueue = wizard.echoQueue or {}
            table.insert(wizard.echoQueue, {
                spell = slot.spell,
                delay = event.delay,
                timer = event.delay
            })
            
            -- Create echo VFX if available
            if caster.gameState and caster.gameState.vfx then
                local params = {
                    delay = event.delay,
                    slotIndex = slotIndex,
                    spellName = slot.spell.name
                }
                
                safeCreateVFX(
                    caster.gameState.vfx,
                    "createEchoEffect",
                    Constants.VFXType.SPELL_ECHO,
                    wizard.x,
                    wizard.y,
                    params
                )
            end
            
            return true
        end
        
        return false
    end,
    
    ZONE_ANCHOR = function(event, caster, target, spellSlot, results)
        local targetEntity = EventRunner.resolveTarget(event, caster, target)
        if not targetEntity then return false end
        
        -- Store zone anchor information on the spell itself 
        -- This will be checked during spell resolution
        if spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] then
            local slot = caster.spellSlots[spellSlot]
            slot.zoneAnchored = true
            slot.anchorRange = event.anchorRange
            slot.anchorElevation = event.anchorElevation
            slot.anchorRequireAll = event.requireAll
            
            return true
        end
        
        return false
    end,
    
    ZONE_MULTI = function(event, caster, target, spellSlot, results)
        local targetEntity = EventRunner.resolveTarget(event, caster, target)
        if not targetEntity then return false end
        
        -- Mark this spell as affecting both ranges
        if spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] then
            local slot = caster.spellSlots[spellSlot]
            slot.affectsBothRanges = true
            
            return true
        end
        
        return false
    end,
    
    -- Add a new EFFECT event handler for pure visual effects
    EFFECT = function(event, caster, target, spellSlot, results)
        print("[EFFECT EVENT] Processing EFFECT event")
        
        -- Detailed event inspection for debugging
        print("[EFFECT EVENT] Full event details:")
        print(string.format("  effectOverride=%s", tostring(event.effectOverride)))
        print(string.format("  effectType=%s", tostring(event.effectType)))
        print(string.format("  affinity=%s, attackType=%s, damageType=%s", 
            tostring(event.affinity), 
            tostring(event.attackType), 
            tostring(event.damageType)))
        print(string.format("  source=%s, target=%s", 
            tostring(event.source), 
            tostring(event.target)))
            
        -- Check if spell has override
        if spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] and 
           caster.spellSlots[spellSlot].spell then
            local spell = caster.spellSlots[spellSlot].spell
            print(string.format("[EFFECT EVENT] Associated spell: name=%s, effectOverride=%s", 
                tostring(spell.name), tostring(spell.effectOverride)))
        end
        
        -- Get source and target coordinates for the effect
        local srcX, srcY, tgtX, tgtY = nil, nil, nil, nil
        
        -- CASE 1: If vfxParams contains direct coordinates, use those
        if event.vfxParams and event.vfxParams.x and event.vfxParams.y then
            srcX = event.vfxParams.x
            srcY = event.vfxParams.y
            tgtX = event.vfxParams.targetX or srcX  -- Use target coords if provided, otherwise same as source
            tgtY = event.vfxParams.targetY or srcY
            print(string.format("[EFFECT EVENT] Using direct coordinates from vfxParams: (%d, %d) -> (%d, %d)", 
                srcX, srcY, tgtX, tgtY))
        
        -- CASE 2: Otherwise resolve based on source/target entities
        else
            -- Source coordinates (caster)
            srcX = caster and caster.x or 0
            srcY = caster and caster.y or 0
            
            -- Target coordinates 
            local targetInfo = EventRunner.resolveTarget(event, caster, target)
            if targetInfo and targetInfo.wizard then 
                local targetWizard = targetInfo.wizard
                tgtX = targetWizard.x
                tgtY = targetWizard.y
                print(string.format("[EFFECT EVENT] Using wizard coordinates: (%d, %d) -> (%d, %d)", 
                    srcX, srcY, tgtX or srcX, tgtY or srcY))
            else
                -- If target resolution fails, use same coordinates as source
                tgtX = srcX
                tgtY = srcY
                print("[EFFECT EVENT] WARNING: Could not resolve target coordinates, using source as target")
            end
        end
        
        -- Check if this spell slot contains a spell with an effectOverride
        local overrideName = nil
        
        -- Check in priority order for effect name
        if event.effectOverride then
            -- First check the event for an effectOverride (highest priority)
            overrideName = event.effectOverride
            print("[EFFECT EVENT] Using event effectOverride: " .. tostring(overrideName))
        elseif event.effectType then
            -- Then check if there's an effectType directly in the event (legacy VFX keyword)
            overrideName = event.effectType
            print("[EFFECT EVENT] Using event effectType: " .. tostring(overrideName))
        elseif spellSlot and caster.spellSlots and caster.spellSlots[spellSlot] and 
               caster.spellSlots[spellSlot].spell and caster.spellSlots[spellSlot].spell.effectOverride then
            -- Finally check the spell slot for effectOverride (set by vfx keyword)
            overrideName = caster.spellSlots[spellSlot].spell.effectOverride
            print("[EFFECT EVENT] Using spell effectOverride: " .. tostring(overrideName))
        end
        
        -- Create visual effect if VFX system is available
        if caster.gameState and caster.gameState.vfx then
            -- Use the override or let VisualResolver pick based on metadata
            local baseEffectName, vfxOpts
            
            -- Debug before VisualResolver.pick
            print("[EFFECT EVENT] About to call VisualResolver.pick()")
            print("[EFFECT EVENT] Override strategy: " .. (overrideName and "Using override: " .. tostring(overrideName) or "Using metadata resolution"))
            
            if overrideName then
                -- Manual override - use it directly but still get options from resolver
                event.effectOverride = overrideName -- Ensure the event has the override
                print("[EFFECT EVENT] Set event.effectOverride = " .. tostring(overrideName))
                baseEffectName, vfxOpts = VisualResolver.pick(event)
            else
                -- Standard resolver path using event metadata
                baseEffectName, vfxOpts = VisualResolver.pick(event)
            end
            
            -- Debug after VisualResolver.pick
            print(string.format("[EFFECT EVENT] VisualResolver.pick() returned: effectName=%s, options=%s", 
                tostring(baseEffectName), 
                vfxOpts and "present" or "nil"))
            
            -- Skip VFX if no valid base effect name
            if not baseEffectName then
                print("[EFFECT EVENT] Warning: No valid effect name provided by VisualResolver")
                return false
            end
            
            -- Merge additional parameters from event
            if not vfxOpts then vfxOpts = {} end
            
            -- Add source/target names
            if caster and caster.name then
                vfxOpts.source = caster.name
            end
            if target and target.name then
                vfxOpts.target = target.name
            end
            
            -- Set default duration if not provided
            if not vfxOpts.duration then
                vfxOpts.duration = event.duration or 0.5
            end
            
            -- Extra debug info
            print(string.format("[EFFECT EVENT] Creating effect: '%s' at coords: (%d, %d) -> (%d, %d)", 
                tostring(baseEffectName), srcX or 0, srcY or 0, tgtX or srcX, tgtY or srcY))
                
            -- Call VFX.createEffect directly instead of using safeCreateVFX
            -- This pattern matches how we want VFX module to be called in the future
            -- with directional information (source -> target)
            local vfxModule = caster.gameState.vfx
            if vfxModule and vfxModule.createEffect then
                local success, err = pcall(function()
                    vfxModule.createEffect(baseEffectName, srcX, srcY, tgtX, tgtY, vfxOpts)
                end)
                
                if not success then
                    print("ERROR: Failed to create effect: " .. tostring(err))
                    return false
                end
            else
                print("[EFFECT EVENT] ERROR: VFX.createEffect not available")
                return false
            end
        else
            print("[EFFECT EVENT] ERROR: VFX system not available")
            return false
        end
        
        return true
    end
}

-- Debug function to print all events
function EventRunner.debugPrintEvents(events)
    print("===== DEBUG: Event List =====")
    for i, event in ipairs(events) do
        print(string.format("[%d] %s - Source: %s, Target: %s", 
            i, event.type, event.source, event.target))
        
        -- Print additional event-specific fields
        for k, v in pairs(event) do
            if k ~= "type" and k ~= "source" and k ~= "target" then
                print(string.format("  %s: %s", k, tostring(v)))
            end
        end
    end
    print("=============================")
end

return EventRunner