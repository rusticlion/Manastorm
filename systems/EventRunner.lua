-- EventRunner.lua
-- Processes spell events and applies them to game state

local Constants = require("core.Constants")
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
    
    -- Try to call the specific method if it exists
    if type(vfx[methodName]) == "function" then
        local success, err = pcall(function() 
            vfx[methodName](vfx, x, y, params) 
        end)
        
        if not success then
            print("DEBUG: Error calling " .. methodName .. ": " .. tostring(err))
            -- Try fallback on error
            if type(vfx.createEffect) == "function" then
                pcall(function() vfx.createEffect(vfx, fallbackType, x, y, nil, nil, params) end)
            end
        end
        return true
    -- Fall back to generic createEffect if available
    elseif type(vfx.createEffect) == "function" then
        local success, err = pcall(function() 
            vfx.createEffect(vfx, fallbackType, x, y, nil, nil, params) 
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
        
        -- Track damage for results
        results.damageDealt = results.damageDealt + event.amount
        
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
        
        -- Create elevation change VFX if available
        if caster.gameState and caster.gameState.vfx then
            local effectType = "elevation"
            if event.elevation == "AERIAL" then
                effectType = "elevation_up"
            else
                effectType = "elevation_down"
            end
            
            local params = {
                duration = 1.0,
                elevation = event.elevation,
                source = caster.name
            }
            
            -- Use our safe VFX creation helper, targeting the wizard's coords
            safeCreateVFX(
                caster.gameState.vfx, 
                "createElevationEffect", 
                effectType, 
                targetWizard.x, 
                targetWizard.y, 
                params
            )
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
            caster.gameState.rangeState = event.position
        end
        
        -- Create range change VFX if available
        if caster.gameState and caster.gameState.vfx then
            local params = {
                position = event.position,
                duration = 1.0
            }
            
            safeCreateVFX(
                caster.gameState.vfx,
                "createRangeChangeEffect",
                "range_change",
                caster.x,
                caster.y,
                params
            )
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
                local params = {
                    duration = 1.0,
                    source = caster.name,
                    target = target.name
                }
                
                safeCreateVFX(
                    caster.gameState.vfx,
                    "createPositionForceEffect",
                    "force_position",
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
        
        -- Add tokens to the mana pool
        for i = 1, event.amount do
            local assetPath = "assets/sprites/v2Tokens/" .. event.tokenType .. "-token.png"
            manaPool:addToken(event.tokenType, assetPath)
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
            local isFree = (token.status == Constants.TokenStatus.FREE) or (token.state == "FREE")
            local matchesType = (event.tokenType == "any" or token.type == event.tokenType)
            
            if isFree and matchesType then
                -- Request destruction animation using state machine if available
                if token.requestDestructionAnimation then
                    token:requestDestructionAnimation()
                else
                    -- Fallback to legacy direct state setting
                    token.state = "DESTROYED"
                end
                
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
                if token.state == "FREE" then
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
                if token.state == "FREE" and token.type ~= event.tokenType then
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
            if token.state == "FREE" and (event.tokenType == "any" or token.type == event.tokenType) then
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
            tokenToLock.state = "LOCKED"
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
                    "token_lock",
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
                    "spell_accelerate",
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
                        if tokenData.token.requestReturnAnimation then
                            tokenData.token:requestReturnAnimation()
                        else
                            -- Fallback to legacy direct state setting
                            tokenData.token.state = "FREE"
                        end
                    end
                end
            else
                -- Destroy tokens (disjoint)
                for _, tokenData in ipairs(slot.tokens) do
                    if tokenData.token then
                        if tokenData.token.requestDestructionAnimation then
                            tokenData.token:requestDestructionAnimation()
                        else
                            -- Fallback to legacy direct state setting
                            tokenData.token.state = "DESTROYED"
                        end
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
                    "spell_cancel",
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
        local slotIndexToFreeze = event.slotIndex or 2 -- Get slot from event, default to 2
        
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
                    "spell_freeze",
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
            if removedTokenObject.requestReturnAnimation then
                 removedTokenObject:requestReturnAnimation()
            else
                 removedTokenObject.state = "FREE" -- Fallback if no animation method
            end

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
                    "token_shift",
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
            blocksAttackTypes = event.blocksAttackTypes or {"projectile"},
            reflect = event.reflect or false
        }
        
        -- Check if the wizard has a createShield method
        if type(wizard.createShield) ~= "function" then
            print("ERROR: Wizard " .. wizard.name .. " does not have createShield method")
            
            -- Default implementation if the method is missing
            print("Using fallback shield creation")
            slot.isShield = true
            slot.defenseType = shieldParams.defenseType
            slot.blocksAttackTypes = shieldParams.blocksAttackTypes
            slot.reflect = shieldParams.reflect
            
            -- Mark tokens as shielding
            for _, tokenData in ipairs(slot.tokens) do
                if tokenData.token then
                    tokenData.token.state = "SHIELDING"
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
            local params = {
                duration = event.duration
            }
            
            safeCreateVFX(
                caster.gameState.vfx,
                "createReflectEffect",
                "reflect",
                targetWizard.x,
                targetWizard.y,
                params
            )
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
                    "spell_echo",
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