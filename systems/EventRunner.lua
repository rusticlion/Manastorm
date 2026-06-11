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

local Constants = require("core.Constants")
local Log = require("core.Log")
local DamageHandlers = require("systems.event_handlers.DamageHandlers")
local DefenseHandlers = require("systems.event_handlers.DefenseHandlers")
local PositionHandlers = require("systems.event_handlers.PositionHandlers")
local RangeHandlers = require("systems.event_handlers.RangeHandlers")
local SpecialHandlers = require("systems.event_handlers.SpecialHandlers")
local SpellTimelineHandlers = require("systems.event_handlers.SpellTimelineHandlers")
local StatusHandlers = require("systems.event_handlers.StatusHandlers")
local SustainedTrapHandlers = require("systems.event_handlers.SustainedTrapHandlers")
local TokenHandlers = require("systems.event_handlers.TokenHandlers")
local VisualEffectHandlers = require("systems.event_handlers.VisualEffectHandlers")
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
    CAST_COMPLETE = 240,
    
    -- Defense events (fourth)
    CREATE_SHIELD = 300,
    SHIELD_BLOCK = 305,
    REFLECT = 310,
    REGISTER_SUSTAINED = 320,
    TRIGGER_TRAP = 330,
    
    -- Status effects (fifth)
    APPLY_STATUS = 400,
    REMOVE_STATUS = 410,
    
    -- Damage events (sixth)
    DAMAGE = 500,
    BLOCKED_DAMAGE = 501, -- Same priority as DAMAGE but won't apply health changes
    
    -- Visual effects (before special effects)
    EFFECT = 550,
    
    -- Special effects (last)
    ECHO = 600,
    ZONE_MULTI = 610,
    NOTIFY_TRAP_TRIGGER = 620,
    CLEANUP_SLOT = 700
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

local mergeProcessResults
local queueDeferredEventBatch
local emitEffectEvent

local function getSlotVisualContext(wizard, slotIndex)
    local slot = wizard and wizard.spellSlots and slotIndex and wizard.spellSlots[slotIndex] or nil
    local spell = slot and slot.spell or nil

    return {
        slot = slot,
        spell = spell,
        affinity = spell and spell.affinity or nil,
        attackType = spell and spell.attackType or nil,
        visualShape = spell and spell.visualShape or nil,
        manaCost = slot and slot.tokens and #slot.tokens or nil
    }
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
            shieldBlocksResolved = 0,
            sustainedRegistered = false,
            trapsTriggered = 0,
            slotsCleaned = 0,
            tokensAffected = 0,
            error = "Invalid events list"
        }
    end
    
    -- Verify caster and target are valid
    if not caster then
        print("WARNING: Nil caster passed to processEvents")
        return {
            eventsProcessed = 0,
            sustainedRegistered = false,
            trapsTriggered = 0,
            slotsCleaned = 0,
            error = "Invalid caster"
        }
    end
    
    -- Create a results table to track effects 
    local results = {
        eventsProcessed = 0,
        damageDealt = 0,
        statusEffectsApplied = {},
        statusEffectsRemoved = {},
        shieldCreated = false,
        shieldBlocksResolved = 0,
        sustainedRegistered = false,
        sustainedId = nil,
        trapsTriggered = 0,
        slotsCleaned = 0,
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

    local deferredBatches = results._deferredEventBatches
    results._deferredEventBatches = nil
    if deferredBatches then
        for _, batch in ipairs(deferredBatches) do
            local nestedResults = EventRunner.processEvents(
                batch.events,
                batch.caster or caster,
                batch.target or target,
                batch.spellSlot
            )
            mergeProcessResults(results, nestedResults)
        end
    end
    
    return results
end

local function getOpponentWizard(gameState, wizard)
    if not gameState or not gameState.wizards then
        return nil
    end

    for _, candidate in ipairs(gameState.wizards) do
        if candidate ~= wizard then
            return candidate
        end
    end

    return nil
end

mergeProcessResults = function(results, nestedResults)
    if not results or not nestedResults then
        return
    end

    results.damageDealt = (results.damageDealt or 0) + (nestedResults.damageDealt or 0)
    results.tokensAffected = (results.tokensAffected or 0) + (nestedResults.tokensAffected or 0)
    results.shieldBlocksResolved = (results.shieldBlocksResolved or 0) + (nestedResults.shieldBlocksResolved or 0)
    results.slotsCleaned = (results.slotsCleaned or 0) + (nestedResults.slotsCleaned or 0)
    results.trapsTriggered = (results.trapsTriggered or 0) + (nestedResults.trapsTriggered or 0)
    results.shieldCreated = results.shieldCreated or nestedResults.shieldCreated or false
    results.sustainedRegistered = results.sustainedRegistered or nestedResults.sustainedRegistered or false
    if not results.sustainedId and nestedResults.sustainedId then
        results.sustainedId = nestedResults.sustainedId
    end

    if nestedResults.statusEffectsApplied then
        results.statusEffectsApplied = results.statusEffectsApplied or {}
        for _, statusType in ipairs(nestedResults.statusEffectsApplied) do
            table.insert(results.statusEffectsApplied, statusType)
        end
    end

    if nestedResults.statusEffectsRemoved then
        results.statusEffectsRemoved = results.statusEffectsRemoved or {}
        for _, statusType in ipairs(nestedResults.statusEffectsRemoved) do
            table.insert(results.statusEffectsRemoved, statusType)
        end
    end
end

queueDeferredEventBatch = function(results, events, caster, target, spellSlot)
    if not results or type(events) ~= "table" or #events == 0 then
        return
    end

    results._deferredEventBatches = results._deferredEventBatches or {}
    table.insert(results._deferredEventBatches, {
        events = events,
        caster = caster,
        target = target,
        spellSlot = spellSlot
    })
end

local function clearBlockedImpactState(slot)
    if not slot then
        return
    end

    slot.blockedPendingImpact = false
    slot.blockImpactTimer = 0
    slot.blockImpactTimeout = nil
end

local function getKeywordRegistry(caster)
    local gameState = caster and caster.gameState or nil
    if gameState and gameState.keywords then
        return gameState.keywords
    end

    local ok, keywords = pcall(require, "keywords")
    if ok then
        return keywords
    end

    return nil
end

local function buildKeywordPayloadEvents(payload, caster, target, slotIndex, spell)
    if type(payload) ~= "table" then
        return nil, "invalid keyword payload"
    end

    local keywords = getKeywordRegistry(caster)
    if not keywords then
        return nil, "cannot access Keywords module"
    end

    local events = {}
    local keywordResults = {
        currentSlot = slotIndex
    }

    for keyword, params in pairs(payload) do
        local keywordDef = keywords[keyword]
        if keywordDef and type(keywordDef.execute) == "function" then
            local updatedResults = keywordDef.execute(
                params,
                caster,
                target,
                keywordResults,
                events,
                spell
            )

            if type(updatedResults) == "table" and updatedResults ~= keywordResults then
                for k, v in pairs(updatedResults) do
                    keywordResults[k] = v
                end
            end

            keywordResults.currentSlot = slotIndex
        else
            print(string.format(
                "[EVENT RUNNER] WARNING: Keyword '%s' not found or not executable",
                tostring(keyword)
            ))
        end
    end

    return events, keywordResults
end

emitEffectEvent = function(effectEvent, caster, target, spellSlot, results)
    if not caster or not caster.gameState or not caster.gameState.vfx then
        return false
    end

    return EventRunner.handleEvent(effectEvent, caster, target, spellSlot, results)
end

function EventRunner.updateTimedEffects(gameState, dt)
    if not gameState or not gameState.wizards or not dt then
        return
    end

    local pending = {}
    local expiredElevationEffects = {}

    for _, wizard in ipairs(gameState.wizards) do
        local opponent = getOpponentWizard(gameState, wizard)

        if wizard.statusEffects then
            for statusType, effectData in pairs(wizard.statusEffects) do
                if effectData and effectData.active then
                    effectData.elapsed = (effectData.elapsed or 0) + dt
                    effectData.totalTime = (effectData.totalTime or 0) + dt

                    local duration = effectData.duration or 0
                    local expired = duration > 0 and effectData.totalTime >= duration

                    if expired then
                        table.insert(pending, {
                            caster = wizard,
                            target = opponent,
                            events = {
                                {
                                    type = "REMOVE_STATUS",
                                    source = "caster",
                                    target = Constants.TargetType.SELF,
                                    statusType = statusType
                                }
                            }
                        })
                    elseif statusType == Constants.StatusType.BURN then
                        local tickInterval = effectData.tickInterval or 1.0
                        if tickInterval <= 0 then
                            tickInterval = 1.0
                        end
                        local tickDamage = effectData.tickDamage or 0

                        while tickDamage > 0 and effectData.elapsed >= tickInterval do
                            effectData.elapsed = effectData.elapsed - tickInterval

                            table.insert(pending, {
                                caster = wizard,
                                target = opponent,
                                events = {
                                    {
                                        type = "DAMAGE",
                                        source = "caster",
                                        target = Constants.TargetType.SELF,
                                        amount = tickDamage,
                                        damageType = effectData.damageType or effectData.affinity or Constants.DamageType.GENERIC,
                                        affinity = effectData.affinity,
                                        attackType = effectData.attackType or Constants.AttackType.UTILITY,
                                        visualShape = effectData.visualShape,
                                        manaCost = effectData.manaCost or 0,
                                        tags = effectData.tags or { BURN = true, DOT = true },
                                        rangeBand = wizard.gameState and wizard.gameState.rangeState or nil,
                                        elevation = wizard.elevation,
                                        delayDamage = false
                                    }
                                }
                            })
                        end
                    end
                end
            end
        end

        if wizard.elevationEffects then
            for elevationType, effectData in pairs(wizard.elevationEffects) do
                if effectData and effectData.duration then
                    effectData.duration = effectData.duration - dt

                    if effectData.duration <= 0 then
                        table.insert(pending, {
                            caster = wizard,
                            target = opponent,
                            events = {
                                {
                                    type = "SET_ELEVATION",
                                    source = "caster",
                                    target = Constants.TargetType.SELF,
                                    elevation = effectData.revertElevation or Constants.ElevationState.GROUNDED,
                                    affinity = effectData.affinity,
                                    manaCost = effectData.manaCost,
                                    visualShape = effectData.visualShape
                                }
                            }
                        })

                        table.insert(expiredElevationEffects, {
                            wizard = wizard,
                            elevationType = elevationType
                        })
                    end
                end
            end
        end
    end

    for _, item in ipairs(pending) do
        EventRunner.processEvents(item.events, item.caster, item.target, nil)
    end

    for _, expired in ipairs(expiredElevationEffects) do
        if expired.wizard.elevationEffects then
            expired.wizard.elevationEffects[expired.elevationType] = nil
        end
    end
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

local rangeHandlers = RangeHandlers.build({
    Constants = Constants,
    emitEffectEvent = emitEffectEvent,
    queueDeferredEventBatch = queueDeferredEventBatch,
})

local statusHandlers = StatusHandlers.build({
    Constants = Constants,
    Log = Log,
    emitEffectEvent = emitEffectEvent,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

local tokenHandlers = TokenHandlers.build({
    Constants = Constants,
    Log = Log,
    emitEffectEvent = emitEffectEvent,
    getSlotVisualContext = getSlotVisualContext,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

local spellTimelineHandlers = SpellTimelineHandlers.build({
    Constants = Constants,
    clearBlockedImpactState = clearBlockedImpactState,
    emitEffectEvent = emitEffectEvent,
    getSlotVisualContext = getSlotVisualContext,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

local defenseHandlers = DefenseHandlers.build({
    Constants = Constants,
    Log = Log,
    handleEvent = function(event, caster, target, spellSlot, results)
        return EventRunner.handleEvent(event, caster, target, spellSlot, results)
    end,
    mergeProcessResults = mergeProcessResults,
    processEvents = function(events, caster, target, spellSlot)
        return EventRunner.processEvents(events, caster, target, spellSlot)
    end,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

local sustainedTrapHandlers = SustainedTrapHandlers.build({
    Constants = Constants,
    Log = Log,
    buildKeywordPayloadEvents = buildKeywordPayloadEvents,
    handleEvent = function(event, caster, target, spellSlot, results)
        return EventRunner.handleEvent(event, caster, target, spellSlot, results)
    end,
    mergeProcessResults = mergeProcessResults,
    processEvents = function(events, caster, target, spellSlot)
        return EventRunner.processEvents(events, caster, target, spellSlot)
    end,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

local damageHandlers = DamageHandlers.build({
    Log = Log,
    handleEvent = function(event, caster, target, spellSlot, results)
        return EventRunner.handleEvent(event, caster, target, spellSlot, results)
    end,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

local positionHandlers = PositionHandlers.build({
    Constants = Constants,
    emitEffectEvent = emitEffectEvent,
    queueDeferredEventBatch = queueDeferredEventBatch,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

local specialHandlers = SpecialHandlers.build({
    Constants = Constants,
    emitEffectEvent = emitEffectEvent,
    getSlotVisualContext = getSlotVisualContext,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

local visualEffectHandlers = VisualEffectHandlers.build({
    Constants = Constants,
    Log = Log,
    processEvents = function(events, caster, target, spellSlot)
        return EventRunner.processEvents(events, caster, target, spellSlot)
    end,
    resolveTarget = function(event, caster, target)
        return EventRunner.resolveTarget(event, caster, target)
    end
})

-- Event handler functions
EventRunner.EVENT_HANDLERS = {
    -- ===== Damage Events =====

    DAMAGE = damageHandlers.DAMAGE,

    BLOCKED_DAMAGE = damageHandlers.BLOCKED_DAMAGE,
    
    -- ===== Status Effect Events =====

    APPLY_STATUS = statusHandlers.APPLY_STATUS,

    REMOVE_STATUS = statusHandlers.REMOVE_STATUS,
    
    -- ===== Elevation Events =====

    SET_ELEVATION = positionHandlers.SET_ELEVATION,
    
    -- ===== Range Events =====
    
    SET_RANGE = rangeHandlers.SET_RANGE,
    
    FORCE_POSITION = rangeHandlers.FORCE_POSITION,
    
    -- ===== Resource & Token Events =====

    CONJURE_TOKEN = tokenHandlers.CONJURE_TOKEN,

    DISSIPATE_TOKEN = tokenHandlers.DISSIPATE_TOKEN,

    SHIFT_TOKEN = tokenHandlers.SHIFT_TOKEN,

    LOCK_TOKEN = tokenHandlers.LOCK_TOKEN,
    
    -- ===== Spell Timing Events =====
    
    ACCELERATE_SPELL = spellTimelineHandlers.ACCELERATE_SPELL,

    CANCEL_SPELL = spellTimelineHandlers.CANCEL_SPELL,

    FREEZE_SPELL = spellTimelineHandlers.FREEZE_SPELL,

    CLEANUP_SLOT = spellTimelineHandlers.CLEANUP_SLOT,
    
    -- NEW HANDLER: Disrupts channeling, shifts token type, returns it to pool
    DISRUPT_AND_SHIFT = tokenHandlers.DISRUPT_AND_SHIFT,
    
    -- CONSUME_TOKENS: Permanently removes the tokens channeled to cast a spell
    CONSUME_TOKENS = tokenHandlers.CONSUME_TOKENS,
    
    -- ===== Defense Events =====
    
    CREATE_SHIELD = defenseHandlers.CREATE_SHIELD,

    SHIELD_BLOCK = defenseHandlers.SHIELD_BLOCK,

    REGISTER_SUSTAINED = sustainedTrapHandlers.REGISTER_SUSTAINED,

    CAST_COMPLETE = sustainedTrapHandlers.CAST_COMPLETE,

    NOTIFY_TRAP_TRIGGER = sustainedTrapHandlers.NOTIFY_TRAP_TRIGGER,

    TRIGGER_TRAP = sustainedTrapHandlers.TRIGGER_TRAP,
    
    REFLECT = defenseHandlers.REFLECT,
    
    -- ===== Special Events =====

    ECHO = specialHandlers.ECHO,

    ZONE_ANCHOR = specialHandlers.ZONE_ANCHOR,

    ZONE_MULTI = specialHandlers.ZONE_MULTI,
    
    -- Add a new EFFECT event handler for pure visual effects
    EFFECT = visualEffectHandlers.EFFECT
}

-- Debug function to print all events
function EventRunner.debugPrintEvents(events)
    Log.debug("===== DEBUG: Event List =====")
    for i, event in ipairs(events) do
        Log.debug(string.format("[%d] %s - Source: %s, Target: %s",
            i, event.type, event.source, event.target))
        
        -- Print additional event-specific fields
        for k, v in pairs(event) do
            if k ~= "type" and k ~= "source" and k ~= "target" then
                Log.debug(string.format("  %s: %s", k, tostring(v)))
            end
        end
    end
    Log.debug("=============================")
end

return EventRunner
