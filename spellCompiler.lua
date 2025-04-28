-- spellCompiler.lua
-- Compiles spell definitions using keyword behaviors
--
-- IMPORTANT: This system now uses a pure event-based architecture.
-- All keyword behaviors should create events rather than directly modifying game state.
-- Events are processed by the EventRunner module after all behaviors have been executed.
-- The events should follow the schema defined in docs/combat_events.md.
--
-- Example event structure:
-- {
--   type = "DAMAGE",       -- Required: Type of the event
--   source = "caster",     -- Required: Source of the event (usually "caster")
--   target = "enemy",      -- Required: Target of the event (e.g., "self", "enemy", "both", etc.)
--   amount = 10,           -- Event-specific data
--   damageType = "fire"    -- Event-specific data
-- }

local SpellCompiler = {}

-- Add the EventRunner module for event-based execution
local EventRunner = nil -- Lazy-loaded to avoid circular dependencies

-- Helper function to merge tables
local function mergeTables(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            -- Recursively merge nested tables
            mergeTables(target[k], v)
        else
            -- For non-table values or if target key doesn't exist as table,
            -- simply overwrite/set the value
            target[k] = v
        end
    end
    return target
end

-- Main compilation function
-- Takes a spell definition and keyword data, returns a compiled spell
function SpellCompiler.compileSpell(spellDef, keywordData)
    -- Debug - check for onBlock in keywords.block
    if spellDef.keywords and spellDef.keywords.block and spellDef.keywords.block.onBlock then
        print("[COMPILER DEBUG] Spell " .. spellDef.id .. " has onBlock handler in keywords.block")
    end
    
    -- Create a new compiledSpell object
    local compiledSpell = {
        -- Copy base spell properties
        id = spellDef.id,
        name = spellDef.name,
        affinity = spellDef.affinity,
        description = spellDef.description,
        attackType = spellDef.attackType,
        castTime = spellDef.castTime,
        cost = spellDef.cost,
        keywords = spellDef.keywords,
        vfx = spellDef.vfx,
        sfx = spellDef.sfx,
        blockableBy = spellDef.blockableBy,
        -- Create empty behavior table to store merged behavior data
        behavior = {}
    }
    
    -- >>> ADDED: Also copy the getCastTime function if it exists
    if spellDef.getCastTime and type(spellDef.getCastTime) == "function" then
        compiledSpell.getCastTime = spellDef.getCastTime
    end
    
    -- Process keywords if they exist
    if spellDef.keywords then
        print("DEBUG: Processing keywords for spell " .. spellDef.id)
        for keyword, params in pairs(spellDef.keywords) do
            print("DEBUG:   Found keyword: " .. keyword)
            -- Check if the keyword exists in the keyword data
            if keywordData[keyword] and keywordData[keyword].behavior then
                -- Get the behavior definition for this keyword
                local keywordBehavior = keywordData[keyword].behavior
                
                -- Create behavior entry for this keyword with default behavior
                compiledSpell.behavior[keyword] = {}
                
                -- Copy the default behavior parameters
                mergeTables(compiledSpell.behavior[keyword], keywordBehavior)
                
                -- Apply specific parameters from the spell definition
                if type(params) == "table" then
                    -- For table parameters, process them first to capture any functions
                    compiledSpell.behavior[keyword].params = {}
                    
                    -- Copy params to behavior.params, preserving functions
                    for paramName, paramValue in pairs(params) do
                        compiledSpell.behavior[keyword].params[paramName] = paramValue
                    end
                elseif type(params) == "boolean" and params == true then
                    -- For boolean true parameters, just use default params
                    compiledSpell.behavior[keyword].enabled = true
                else
                    -- For any other type, store as a value parameter
                    compiledSpell.behavior[keyword].value = params
                end
                
                -- Bind the execute function from the keyword
                compiledSpell.behavior[keyword].execute = keywordData[keyword].execute
            else
                -- If keyword wasn't found in the keyword data, log an error
                print("Warning: Keyword '" .. keyword .. "' not found in keyword data for spell '" .. compiledSpell.name .. "'")
            end
        end
    end
    
    -- Handle top-level vfx field (convert to vfx keyword if not already present)
    if spellDef.vfx and not (spellDef.keywords and spellDef.keywords.vfx) and keywordData.vfx then
        print("DEBUG: Converting top-level vfx to keyword for spell " .. spellDef.id)
        
        -- Create behavior entry for vfx keyword
        compiledSpell.behavior.vfx = {}
        
        -- Copy the default behavior parameters from the keyword
        mergeTables(compiledSpell.behavior.vfx, keywordData.vfx.behavior)
        
        -- Create params based on vfx value
        compiledSpell.behavior.vfx.params = {
            effect = spellDef.vfx -- Use the vfx string as the effect name
        }
        
        -- Bind the execute function from the vfx keyword
        compiledSpell.behavior.vfx.execute = keywordData.vfx.execute
    end
    
        -- Method to get the event runner module (lazy loading)
    local function getEventRunner()
        if not EventRunner then
            EventRunner = require("systems.EventRunner")
        end
        return EventRunner
    end
    
    -- Add a method to execute all behaviors for this spell
    compiledSpell.executeAll = function(caster, target, results, spellSlot)
        -- LOGGING with safety checks
        if caster and caster.spellSlots and spellSlot and caster.spellSlots[spellSlot] then
            print(string.format("DEBUG_EXECUTE_ALL: Slot %d castTimeModifier=%.4f", 
                spellSlot, caster.spellSlots[spellSlot].castTimeModifier or 0))
        else
            -- Safe fallback logging
            print(string.format("DEBUG_EXECUTE_ALL: Slot %s (safety check failed, some values are nil)", 
                tostring(spellSlot)))
        end

        results = results or {}
        
        -- Check if this spell has shield behavior (block keyword)
        local hasShieldBehavior = compiledSpell.behavior.block ~= nil
        
        -- If this is a shield spell, tag the compiled spell
        if hasShieldBehavior or compiledSpell.isShield then
            compiledSpell.isShield = true
        end
        
        -- When using the event system, we collect events instead of directly mutating state
        local events = {}
        
        -- Execute each behavior
        for keyword, behavior in pairs(compiledSpell.behavior) do
            if behavior.execute then
                local params = behavior.params or {}
                
                -- Execute the behavior to get events
                local behaviorResults = {}
                local results = {currentSlot = spellSlot}  -- Base results with slot info
                
                -- The keyword's execute function is now solely responsible 
                -- for handling its params, including function evaluation.
                if behavior.enabled then
                    -- If it's a boolean-enabled keyword with no params
                    behaviorResults = behavior.execute({}, caster, target, results, events, compiledSpell) -- Pass empty params and the spell
                elseif behavior.value ~= nil then
                    -- If it's a simple value parameter
                    behaviorResults = behavior.execute({value = behavior.value}, caster, target, results, events, compiledSpell)
                else
                    -- Normal case with params table
                    behaviorResults = behavior.execute(params, caster, target, results, events, compiledSpell)
                end
                
                -- Debug output for events immediately after execute
                if keyword == "freeze" then
                    print(string.format("DEBUG: After executing %s keyword, events table has %d entries", 
                        keyword, events and #events or 0))
                end
                
                -- Merge the behavior results into the main results for backward compatibility
                for k, v in pairs(behaviorResults) do
                    results[k] = v
                end
                
                -- Special handling for vfx keyword's effectOverride
                -- This is part of the VFX-R5 refactoring to deprecate manual VFX specification
                if keyword == "vfx" and results.effectOverride then
                    -- Remember the override for when a damage event generates an EFFECT event
                    compiledSpell.effectOverride = results.effectOverride
                    compiledSpell.effectTarget = results.effectTarget
                    compiledSpell.effectDuration = results.effectDuration
                    compiledSpell.vfxParams = results.vfxParams
                end
                
                -- Special handling for shield behaviors
                if keyword == "block" then
                    -- Debug the block keyword behavior
                    print("[COMPILER DEBUG] Processing block keyword in executeAll")
                    
                    -- Check for onBlock in params
                    if params and params.onBlock then
                        print("[COMPILER DEBUG] Found onBlock handler in params")
                    else
                        print("[COMPILER DEBUG] No onBlock handler in params")
                    end
                    
                    -- Create a CREATE_SHIELD event
                    local shieldEvent = {
                        type = "CREATE_SHIELD",
                        source = "caster",
                        target = "self", -- Use "self" to be consistent with Keywords.block targetType
                        slotIndex = spellSlot,
                        defenseType = "barrier",
                        blocksAttackTypes = {"projectile"},
                        reflect = false,
                        onBlock = params.onBlock -- Include onBlock directly from params
                    }
                    
                    -- Debug the onBlock in the shield event
                    if shieldEvent.onBlock then
                        print("[COMPILER DEBUG] Added onBlock to CREATE_SHIELD event")
                    else
                        print("[COMPILER DEBUG] No onBlock added to CREATE_SHIELD event")
                    end
                    
                    -- Safely add shield parameters if available
                    if behaviorResults and behaviorResults.shieldParams then
                        shieldEvent.defenseType = behaviorResults.shieldParams.defenseType or "barrier"
                        shieldEvent.blocksAttackTypes = behaviorResults.shieldParams.blocksAttackTypes or {"projectile"}
                        shieldEvent.reflect = behaviorResults.shieldParams.reflect or false
                        
                        -- Also add onBlock from shieldParams if available and not already set
                        if behaviorResults.shieldParams.onBlock and not shieldEvent.onBlock then
                            shieldEvent.onBlock = behaviorResults.shieldParams.onBlock
                            print("[COMPILER DEBUG] Added onBlock from shieldParams to CREATE_SHIELD event")
                        end
                    end
                    
                    table.insert(events, shieldEvent)
                end
            end
        end
        
        -- If this is a shield spell, mark this in the results
        if hasShieldBehavior or compiledSpell.isShield then
            results.isShield = true
        end
        
        -- Check for sustain keyword or block keyword (which marks spells as sustained)
        if compiledSpell.behavior.sustain or 
           (compiledSpell.behavior.block and compiledSpell.behavior.block.marksSpellAsSustained) then
            -- This will be picked up by Wizard:castSpell to handle sustained spells
            results.isSustained = true
            print("DEBUG: Spell " .. compiledSpell.id .. " marked as sustained")
        else
            print("DEBUG: Spell " .. compiledSpell.id .. " not marked as sustained. Checking for sustain/shield keywords...")
            
            -- Debug: Print out the behavior table keys to see if sustain or block is there
            for behaviorKey, _ in pairs(compiledSpell.behavior) do
                print("  Behavior found: " .. behaviorKey)
                
                -- If it's the block keyword, check if it has marksSpellAsSustained
                if behaviorKey == "block" then
                    print("    Block keyword found. marksSpellAsSustained = " .. 
                        tostring(compiledSpell.behavior.block.marksSpellAsSustained))
                end
            end
        end
        
        -- Check for trap keywords and ensure they're in the results
        -- These trap-related fields will be used by the SustainedSpellManager later
        if compiledSpell.behavior.trap_trigger then
            -- Make sure trapTrigger data is in the results
            if not results.trapTrigger then
                results.trapTrigger = compiledSpell.behavior.trap_trigger.params or {}
                print("DEBUG: Adding trapTrigger data to results: " .. tostring(results.trapTrigger))
            end
        end
        
        if compiledSpell.behavior.trap_window then
            -- Make sure trapWindow data is in the results
            if not results.trapWindow then
                results.trapWindow = compiledSpell.behavior.trap_window.params or {}
                print("DEBUG: Adding trapWindow data to results: " .. tostring(results.trapWindow))
                
                -- Debug what's in the params
                for k, v in pairs(compiledSpell.behavior.trap_window.params or {}) do
                    print("DEBUG:   trapWindow param: " .. k .. " = " .. tostring(v))
                end
            end
        end
        
        if compiledSpell.behavior.trap_effect then
            -- Make sure trapEffect data is in the results
            if not results.trapEffect then
                results.trapEffect = compiledSpell.behavior.trap_effect.params or {}
                print("DEBUG: Adding trapEffect data to results: " .. tostring(results.trapEffect))
            end
        end
        
        -- Wrap event processing in pcall to avoid crashing the game
        local success, result = pcall(function()
            -- Debug output for events
            if _G.DEBUG_EVENTS then
                getEventRunner().debugPrintEvents(events)
            end
            
            -- Process the events to apply them to the game state
            local eventResults = {}
            if events and #events > 0 then
                print(string.format("DEBUG_EVENTS: Processing %d events for spell %s", 
                    #events, compiledSpell.id or "unknown"))
                
                -- Print type of first event as sanity check
                if events[1] and events[1].type then
                    print(string.format("DEBUG_EVENTS: First event type is %s", events[1].type))
                end
                
                eventResults = getEventRunner().processEvents(events, caster, target, spellSlot)
            else
                print("WARNING: No events generated for spell " .. (compiledSpell.id or "unknown"))
            end
            
            -- Add event processing results to the main results
            results.events = events
            results.eventsProcessed = eventResults.eventsProcessed
            
            return results
        end)
        
        if success then
            -- Return the combined results if everything went well
            return result
        else
            -- Log the error but still return the original results for fallback
            print("ERROR in event processing: " .. tostring(result))
            print("Falling back to direct results without event processing")
            return results
        end
    end
    
    -- Add method for direct event generation without execution
    -- Useful for testing and debugging
    compiledSpell.generateEvents = function(caster, target, spellSlot)
        local events = {}
        
        -- Execute each behavior to generate events
        for keyword, behavior in pairs(compiledSpell.behavior) do
            if behavior.execute then
                local params = behavior.params or {}
                local localResults = {}
                
                -- Execute the behavior to generate events directly
                -- No state modification occurs
                if behavior.enabled then
                    -- Call the keyword execute function with an empty results table
                    -- The events parameter allows keywords to add events directly via table.insert
                    behavior.execute(params, caster, target, {currentSlot = spellSlot}, events, compiledSpell)
                elseif behavior.value ~= nil then
                    behavior.execute({value = behavior.value}, caster, target, {currentSlot = spellSlot}, events, compiledSpell)
                else
                    behavior.execute(params, caster, target, {currentSlot = spellSlot}, events, compiledSpell)
                end
                
                -- Special handling for shield behaviors (block keyword)
                if keyword == "block" then
                    -- Debug the block keyword behavior
                    print("[COMPILER DEBUG] Processing block keyword in generateEvents")
                    
                    -- Create a CREATE_SHIELD event explicitly
                    local shieldParams = localResults.shieldParams or {}
                    
                    -- Check if onBlock is in the params
                    if params and params.onBlock then
                        print("[COMPILER DEBUG] Found onBlock handler in params")
                        -- Add onBlock to shieldParams if not already there
                        if not shieldParams.onBlock then
                            shieldParams.onBlock = params.onBlock
                        end
                    end
                    
                    -- Create event with onBlock included
                    local shieldEvent = {
                        type = "CREATE_SHIELD",
                        source = "caster",
                        target = "self",
                        slotIndex = spellSlot,
                        defenseType = shieldParams.defenseType or "barrier",
                        blocksAttackTypes = shieldParams.blocksAttackTypes or {"projectile"},
                        reflect = shieldParams.reflect or false,
                        onBlock = shieldParams.onBlock -- Include onBlock in the event
                    }
                    
                    -- Debug the onBlock in the shield event
                    if shieldEvent.onBlock then
                        print("[COMPILER DEBUG] Added onBlock to CREATE_SHIELD event")
                    else
                        print("[COMPILER DEBUG] No onBlock added to CREATE_SHIELD event")
                    end
                    
                    table.insert(events, shieldEvent)
                end
            end
        end
        
        return events
    end
    
    return compiledSpell
end

-- Function to test compile a spell and display its components
function SpellCompiler.debugCompiled(compiledSpell)
    print("=== Debug Compiled Spell: " .. compiledSpell.name .. " ===")
    print("ID: " .. compiledSpell.id)
    print("Attack Type: " .. compiledSpell.attackType)
    print("Cast Time: " .. compiledSpell.castTime)
    
    print("Cost: ")
    for _, token in ipairs(compiledSpell.cost) do
        print("  - " .. token)
    end
    
    print("Behaviors: ")
    for keyword, behavior in pairs(compiledSpell.behavior) do
        print("  - " .. keyword .. ":")
        if behavior.category then
            print("    Category: " .. behavior.category)
        end
        if behavior.targetType then
            print("    Target Type: " .. behavior.targetType)
        end
        if behavior.params then
            print("    Parameters:")
            for param, value in pairs(behavior.params) do
                if type(value) ~= "function" then
                    print("      " .. param .. ": " .. tostring(value))
                else
                    print("      " .. param .. ": <function>")
                end
            end
        end
    end
    
    print("=====================================================")
end

-- Function to enable/disable debug event output
function SpellCompiler.setDebugEvents(debugEvents)
    _G.DEBUG_EVENTS = debugEvents
    print("Event debugging " .. (debugEvents and "ENABLED" or "DISABLED"))
end

-- Initialize event debugging to disabled by default
_G.DEBUG_EVENTS = false

return SpellCompiler