-- spellCompiler.lua
-- Compiles spell definitions using keyword behaviors

local SpellCompiler = {}

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
    
    -- Add a method to execute all behaviors for this spell
    compiledSpell.executeAll = function(caster, target, results, spellSlot)
        results = results or {}
        
        -- Check if this spell has shield behavior (block keyword)
        local hasShieldBehavior = compiledSpell.behavior.block ~= nil
        
        -- If this is a shield spell, tag the compiled spell
        if hasShieldBehavior or compiledSpell.isShield then
            compiledSpell.isShield = true
        end
        
        -- Execute each behavior
        for keyword, behavior in pairs(compiledSpell.behavior) do
            if behavior.execute then
                local params = behavior.params or {}
                
                -- Special handling for shield behaviors
                if keyword == "block" then
                    -- Add debug information
                    print("DEBUG: Processing block keyword in compiled spell")
                    
                    -- When a shield behavior is found, mark the tokens to prevent them from returning to the pool
                    if caster and caster.spellSlots and spellSlot and caster.spellSlots[spellSlot] then
                        local slot = caster.spellSlots[spellSlot]
                        
                        -- Set shield status before executing behavior
                        for _, tokenData in ipairs(slot.tokens) do
                            if tokenData.token then
                                -- Mark as shielding to prevent token from returning to pool
                                tokenData.token.state = "SHIELDING"
                                print("DEBUG: Marked token as SHIELDING to prevent return to pool")
                            end
                        end
                    end
                end
                
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
                
                if behavior.enabled then
                    -- If it's a boolean-enabled keyword with no params
                    results = behavior.execute(params, caster, target, results)
                elseif behavior.value ~= nil then
                    -- If it's a simple value parameter
                    results = behavior.execute({value = behavior.value}, caster, target, results)
                else
                    -- Normal case with params table
                    results = behavior.execute(params, caster, target, results)
                end
            end
        end
        
        -- If this is a shield spell, mark this in the results
        if hasShieldBehavior or compiledSpell.isShield then
            results.isShield = true
        end
        
        return results
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

return SpellCompiler