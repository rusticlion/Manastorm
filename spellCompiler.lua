-- spellCompiler.lua
-- Compiles spell definitions using keyword behaviors

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
    -- Create a new compiledSpell object
    local compiledSpell = {
        -- Copy base spell properties
        id = spellDef.id,
        name = spellDef.name,
        description = spellDef.description,
        attackType = spellDef.attackType,
        castTime = spellDef.castTime,
        cost = spellDef.cost,
        vfx = spellDef.vfx,
        sfx = spellDef.sfx,
        blockableBy = spellDef.blockableBy,
        -- Create empty behavior table to store merged behavior data
        behavior = {}
    }
    
    -- Process keywords if they exist
    if spellDef.keywords then
        for keyword, params in pairs(spellDef.keywords) do
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
    
    -- Flag to determine which execution path to use (legacy or event-based)
    local useEventSystem = true
    
    -- Method to get the event runner module (lazy loading)
    local function getEventRunner()
        if not EventRunner then
            EventRunner = require("systems.EventRunner")
        end
        return EventRunner
    end
    
    -- Add a method to execute all behaviors for this spell
    compiledSpell.executeAll = function(caster, target, results, spellSlot)
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
                
                -- Process function parameters
                for paramName, paramValue in pairs(params) do
                    if type(paramValue) == "function" then
                        local success, result = pcall(function()
                            return paramValue(caster, target, spellSlot)
                        end)
                        
                        if success then
                            -- Copy the function result to results for easy access later
                            results[keyword .. "_" .. paramName] = result
                        else
                            print("Error executing function parameter " .. paramName .. " for keyword " .. keyword .. ": " .. tostring(result))
                        end
                    end
                end
                
                -- Execute the behavior to get the results
                local behaviorResults
                if behavior.enabled then
                    -- If it's a boolean-enabled keyword with no params
                    behaviorResults = behavior.execute(params, caster, target, {}, spellSlot)
                elseif behavior.value ~= nil then
                    -- If it's a simple value parameter
                    behaviorResults = behavior.execute({value = behavior.value}, caster, target, {}, spellSlot)
                else
                    -- Normal case with params table
                    behaviorResults = behavior.execute(params, caster, target, {}, spellSlot)
                end
                
                -- Merge the behavior results into the main results
                for k, v in pairs(behaviorResults) do
                    results[k] = v
                end
                
                -- Special handling for shield behaviors to maintain compatibility
                if keyword == "block" and useEventSystem then
                    -- Create a CREATE_SHIELD event
                    table.insert(events, {
                        type = "CREATE_SHIELD",
                        source = "caster",
                        target = "self", -- Use "self" to be consistent with Keywords.block targetType
                        slotIndex = spellSlot,
                        defenseType = behaviorResults.shieldParams and behaviorResults.shieldParams.defenseType or "barrier",
                        blocksAttackTypes = behaviorResults.shieldParams and behaviorResults.shieldParams.blocksAttackTypes or {"projectile"},
                        reflect = behaviorResults.shieldParams and behaviorResults.shieldParams.reflect or false
                    })
                end
            end
        end
        
        -- If this is a shield spell, mark this in the results
        if hasShieldBehavior or compiledSpell.isShield then
            results.isShield = true
        end
        
        if useEventSystem then
            -- Wrap event generation and processing in pcall to avoid crashing the game
            local success, result = pcall(function()
                -- Generate events from the results if using the event system
                local legacyEvents = getEventRunner().generateEventsFromResults(results, caster, target, spellSlot)
                
                -- Combine legacy events with any explicitly created events
                for _, event in ipairs(legacyEvents) do
                    table.insert(events, event)
                end
                
                -- Debug output for events
                if _G.DEBUG_EVENTS then
                    getEventRunner().debugPrintEvents(events)
                end
                
                -- Process the events to apply them to the game state
                local eventResults = getEventRunner().processEvents(events, caster, target, spellSlot)
                
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
        else
            -- Return the results directly if not using the event system
            return results
        end
    end
    
    -- Add method for direct event generation without execution
    -- Useful for testing and debugging
    compiledSpell.generateEvents = function(caster, target, spellSlot)
        local results = {}
        
        -- Execute each behavior to collect results
        for keyword, behavior in pairs(compiledSpell.behavior) do
            if behavior.execute then
                local params = behavior.params or {}
                
                -- Process function parameters
                for paramName, paramValue in pairs(params) do
                    if type(paramValue) == "function" then
                        local success, result = pcall(function()
                            return paramValue(caster, target, spellSlot)
                        end)
                        
                        if success then
                            results[keyword .. "_" .. paramName] = result
                        end
                    end
                end
                
                -- Execute the behavior without modifying state
                local behaviorResults
                if behavior.enabled then
                    behaviorResults = behavior.execute(params, caster, target, {}, spellSlot)
                elseif behavior.value ~= nil then
                    behaviorResults = behavior.execute({value = behavior.value}, caster, target, {}, spellSlot)
                else
                    behaviorResults = behavior.execute(params, caster, target, {}, spellSlot)
                end
                
                -- Merge the behavior results
                for k, v in pairs(behaviorResults) do
                    results[k] = v
                end
            end
        end
        
        -- Generate events from the results
        local events = getEventRunner().generateEventsFromResults(results, caster, target, spellSlot)
        
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

-- Function to toggle between legacy and event-based execution
function SpellCompiler.setUseEventSystem(useEvents)
    _G.USE_EVENT_SYSTEM = useEvents
    useEventSystem = useEvents
    print("Spell compiler execution mode set to " .. (useEvents and "EVENT-BASED" or "LEGACY"))
end

-- Function to enable/disable debug event output
function SpellCompiler.setDebugEvents(debugEvents)
    _G.DEBUG_EVENTS = debugEvents
    print("Event debugging " .. (debugEvents and "ENABLED" or "DISABLED"))
end

-- Initialize settings
SpellCompiler.setUseEventSystem(true)
SpellCompiler.setDebugEvents(false)

return SpellCompiler