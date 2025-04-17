-- Spells.lua
-- Contains data for all spells in the game

local Spells = {}

-- Schema for spell object:
-- id: Unique identifier for the spell (string)
-- name: Display name of the spell (string)
-- description: Text description of what the spell does (string)
-- attackType: How the spell is delivered - "projectile", "remote", "zone", "utility" (string)
--   * projectile: Physical projectile attacks - can be blocked by barriers and wards
--   * remote:     Magical attacks at a distance - can only be blocked by wards
--   * zone:       Area effect attacks - can be blocked by barriers and fields
--   * utility:    Non-offensive spells that affect the caster - cannot be blocked
-- castTime: Duration in seconds to cast the spell (number)
-- cost: Array of token types required (simple array of strings like {"fire", "fire", "moon"})
-- keywords: Table of effect keywords and their parameters (table)
--   - Available keywords: conjure, dissipate, damage, lock, delay, accelerate, dispel, disjoint, 
--     stagger, elevate, ground, rangeShift, forcePull, reflect, block, echo, zoneAnchor,
--     zoneMulti, manaLeak, tokenShift, overcharge, rebound
-- vfx: Visual effect identifier (string, optional)
-- sfx: Sound effect identifier (string, optional)
-- blockableBy: Array of shield types that can block this spell (array, optional)
--
-- Shield Types and Blocking Rules:
-- * barrier: Physical shield that blocks projectiles and zones
-- * ward:    Magical shield that blocks projectiles and remotes
-- * field:   Energy field that blocks remotes and zones
-- 
-- When a shield blocks a spell:
-- 1. The spell's effect is completely negated
-- 2. If the shield is mana-linked, one token used to cast it is released to the pool
-- 3. The shield's strength is reduced by 1
-- 4. When a shield's strength reaches 0, it is destroyed
-- 5. If the shield has the reflect property, damage spells are reflected back at the caster

-- Define a logging function for keyword resolution
local function logKeywordResolution(spellId, keyword, params, results)
    local paramString = ""
    for k, v in pairs(params) do
        if type(v) == "function" then
            paramString = paramString .. k .. "=<function>, "
        else
            paramString = paramString .. k .. "=" .. tostring(v) .. ", "
        end
    end
    
    local resultString = ""
    for k, v in pairs(results) do
        if k ~= "damage" or results.damage ~= 0 then  -- Skip damage=0 to reduce noise
            resultString = resultString .. k .. "=" .. tostring(v) .. ", "
        end
    end
    
    print(string.format("[KEYWORD] %s: %s(%s) -> %s", 
                         spellId or "unknown", 
                         keyword, 
                         paramString:sub(1, -3),  -- Remove trailing comma
                         resultString:sub(1, -3)))  -- Remove trailing comma
end

-- Keyword resolution framework
local KeywordSystem = {}

-- Define keyword categories for organization
KeywordSystem.categories = {
    RESOURCE = "Resource Manipulation",
    DAMAGE = "Damage Effects",
    DOT = "Damage Over Time",
    TOKEN = "Token Manipulation",
    TIMING = "Spell Timing",
    MOVEMENT = "Movement & Position",
    DEFENSE = "Defense Mechanisms",
    SPECIAL = "Special Effects",
    ZONE = "Zone Mechanics"
}

-- Define targeting modes for keywords and spells
KeywordSystem.targetTypes = {
    SELF = "self",           -- The caster
    ENEMY = "enemy",         -- The opponent
    POOL_SELF = "pool_self", -- Caster's mana pool
    POOL_ENEMY = "pool_enemy", -- Opponent's mana pool
    SLOT_SELF = "slot_self", -- Caster's spell slots
    SLOT_ENEMY = "slot_enemy", -- Opponent's spell slots
    GLOBAL = "global",       -- Affects the entire game state
    NONE = "none"            -- No specific target (utility spells)
}

-- Map keywords to their default target type
KeywordSystem.keywordTargets = {
    -- Resource manipulation (mostly affect mana pools)
    tokenShift = "POOL_SELF",  -- Default affects own pool
    conjure = "POOL_SELF",
    dissipate = "POOL_ENEMY",  -- Default removes opponent's tokens
    
    -- Damage (always targets enemy)
    damage = "ENEMY",
    
    -- Damage over time effects
    burn = "ENEMY",
    
    -- Token manipulation
    lock = "POOL_ENEMY",
    
    -- Spell timing effects
    delay = "SLOT_ENEMY",
    accelerate = "SLOT_SELF",
    dispel = "SLOT_ENEMY", 
    disjoint = "SLOT_ENEMY",
    stagger = "SLOT_ENEMY",
    freeze = "SLOT_ENEMY", 
    
    -- Movement and position effects
    elevate = "SELF",
    ground = "ENEMY",
    rangeShift = "SELF", 
    forcePull = "ENEMY",
    
    -- Defense mechanisms
    reflect = "SELF",
    block = "SELF",
    
    -- Special effects
    echo = "SLOT_SELF",
    
    -- Zone mechanics
    zoneAnchor = "SELF",
    zoneMulti = "SELF"
}

-- Map keywords to their categories
KeywordSystem.keywordCategories = {
    -- Resource Manipulation
    tokenShift = "RESOURCE",
    conjure = "RESOURCE",
    dissipate = "RESOURCE",
    
    -- Damage Effects
    damage = "DAMAGE",
    
    -- Damage Over Time Effects
    burn = "DOT",
    
    -- Token Manipulation
    lock = "TOKEN",
    
    -- Spell Timing
    delay = "TIMING",
    accelerate = "TIMING",
    dispel = "TIMING",
    disjoint = "TIMING",
    stagger = "TIMING",
    freeze = "TIMING",
    
    -- Movement & Position
    elevate = "MOVEMENT",
    ground = "MOVEMENT",
    rangeShift = "MOVEMENT",
    forcePull = "MOVEMENT",
    
    -- Defense Mechanisms
    reflect = "DEFENSE",
    block = "DEFENSE",
    
    -- Special Effects
    echo = "SPECIAL",
    
    -- Zone Mechanics
    zoneAnchor = "ZONE",
    zoneMulti = "ZONE"
}

-- Keyword handlers table - each entry is a function that processes one keyword type
KeywordSystem.handlers = {
    -- Damage over time effects
    burn = function(params, caster, target, results)
        results.burnApplied = true
        results.burnDuration = params.duration or 3.0
        results.burnTickDamage = params.tickDamage or 2
        results.burnTickInterval = params.tickInterval or 1.0  -- Default to 1 second between ticks
        return results
    end,
    -- Resource manipulation
    tokenShift = function(params, caster, target, results)
        local tokenType = params.type or "fire"
        local amount = params.amount or 1
        
        if tokenType == "random" then
            -- Implement random token shifting
            results.tokenShift = true
            results.tokenShiftType = "random"
            results.tokenShiftAmount = amount
        else
            -- Implement specific token shifting
            results.tokenShift = true
            results.tokenShiftType = tokenType
            results.tokenShiftAmount = amount
        end
        
        return results
    end,
    conjure = function(params, caster, target, results)
        local tokenType = params.token or "fire"
        local amount = params.amount or 1
        
        for i = 1, amount do
            local assetPath = "assets/sprites/" .. tokenType .. "-token.png"
            caster.manaPool:addToken(tokenType, assetPath)
        end
        
        return results
    end,
    
    dissipate = function(params, caster, target, results)
        local tokenType = params.token or "any"
        local amount = params.amount or 1
        local targetWizard = params.target == "caster" and caster or target
        
        -- Find and remove tokens from the target's mana pool
        results.dissipate = true
        results.dissipateType = tokenType
        results.dissipateAmount = amount
        results.dissipateTarget = targetWizard
        
        -- Keep track of how many tokens were successfully found to remove
        local tokensFound = 0
        
        -- Logic to find and mark tokens for removal
        for i, token in ipairs(targetWizard.manaPool.tokens) do
            if token.state == "FREE" and (tokenType == "any" or token.type == tokenType) then
                -- Mark token for destruction
                token.state = "DESTROYED"
                tokensFound = tokensFound + 1
                
                -- Add a destruction effect
                if targetWizard.gameState.vfx then
                    targetWizard.gameState.vfx.createEffect("token_destroy", token.x, token.y, nil, nil, {
                        duration = 0.5,
                        color = {0.8, 0.3, 0.3, 0.7},
                        particleCount = 5,
                        radius = 15
                    })
                end
                
                -- Stop once we've marked enough tokens
                if tokensFound >= amount then
                    break
                end
            end
        end
        
        results.tokensDestroyed = tokensFound
        
        return results
    end,
    
    -- Damage effects
    damage = function(params, caster, target, results)
        -- Handle damage amount that could be a function or a value
        local damageAmount = params.amount or 0
        
        -- If damage is a function, evaluate it with nil checks
        if type(damageAmount) == "function" then
            if target ~= nil then
                -- Normal case, we have a target
                results.damage = damageAmount(caster, target)
            else
                -- No target, use 0 damage as default
                results.damage = 0
                print("[WARNING] Damage calculation called with nil target")
            end
        else
            -- Static damage value
            results.damage = damageAmount
        end
        
        results.damageType = params.type
        return results
    end,
    
    -- Token manipulation
    lock = function(params, caster, target, results)
        results.lockToken = true
        results.lockDuration = params.duration or 5.0
        return results
    end,
    
    -- Spell timing effects
    delay = function(params, caster, target, results)
        results.delayApplied = true
        results.targetSlot = params.slot or 0  -- 0 means random or auto-select
        results.delayAmount = params.duration or 1.0
        return results
    end,
    
    accelerate = function(params, caster, target, results)
        -- This would need implementation in wizard.lua to accelerate spell progress
        results.accelerate = true
        results.targetSlot = params.slot or 0  -- 0 means self or current slot
        results.accelerateAmount = params.amount or 1.0
        return results
    end,
    
    -- Spell cancellation effects
    dispel = function(params, caster, target, results)
        results.dispel = true
        results.targetSlot = params.slot or 0  -- 0 means random active slot
        return results
    end,
    
    disjoint = function(params, caster, target, results)
        results.disjoint = true
        results.targetSlot = params.slot or 0
        return results
    end,
    
    stagger = function(params, caster, target, results)
        results.stagger = true
        results.targetSlot = params.slot or 0
        results.staggerDuration = params.duration or 3.0
        return results
    end,
    
    -- Movement and position effects
    elevate = function(params, caster, target, results)
        results.setElevation = "AERIAL"
        results.elevationDuration = params.duration or 5.0
        -- Store the target that should receive this effect
        results.elevationTarget = params.target or "SELF" -- Default to SELF
        -- Store the visual effect to use
        results.elevationVfx = params.vfx or "emberlift"
        return results
    end,
    
    ground = function(params, caster, target, results)
        -- Check if there's a conditional function
        if params.conditional and type(params.conditional) == "function" then
            -- Only apply grounding if the condition is met
            if params.conditional(caster, target) then
                results.setElevation = "GROUNDED"
                -- Store the target that should receive this effect
                results.elevationTarget = params.target or "ENEMY" -- Default to ENEMY
                
                -- Add visual effect if specified in params
                if params.vfx and target and caster.gameState and caster.gameState.vfx then
                    caster.gameState.vfx.createEffect(params.vfx, target.x, target.y, nil, nil)
                end
                
                -- Print debug message indicating grounding
                if target and target.name and caster and caster.name then
                    print(target.name .. " was forced to GROUNDED by " .. caster.name .. "'s spell")
                end
            end
        else
            -- No condition, apply grounding unconditionally
            results.setElevation = "GROUNDED"
            results.elevationTarget = params.target or "ENEMY" -- Default to ENEMY
        end
        
        return results
    end,
    
    rangeShift = function(params, caster, target, results)
        results.setPosition = params.position or "NEAR"
        return results
    end,
    
    forcePull = function(params, caster, target, results)
        -- Force opponent to move to caster's range
        results.forcePosition = true
        return results
    end,
    
    -- Defense mechanisms
    reflect = function(params, caster, target, results)
        results.reflect = true
        results.reflectDuration = params.duration or 3.0
        return results
    end,
    
    block = function(params, caster, target, results)
        local spellSlot = params.slot or nil
        
        -- Check if we should create a shield directly
        if caster and spellSlot then
            -- Call the shield creation function
            local shieldResults = KeywordSystem.createShield(caster, spellSlot, params)
            
            -- Merge the shield results with our existing results
            for k, v in pairs(shieldResults) do
                results[k] = v
            end
        else
            -- Set shield parameters on the results object for later processing
            results.isShield = true
            results.defenseType = params.type or "barrier"
            results.blockTypes = params.blocks or {"projectile"}
            results.manaLinked = params.manaLinked or true  -- Default to true for mana linking
            results.reflect = params.reflect or false
            results.hitPoints = params.hitPoints  -- Optional override for shield strength
        end
        
        return results
    end,
    
    -- Special effects
    echo = function(params, caster, target, results)
        results.echo = true
        results.echoDelay = params.delay or 2.0
        return results
    end,
    
    -- Zone mechanics
    zoneAnchor = function(params, caster, target, results)
        results.zoneAnchor = true
        
        -- Store the anchor parameters
        if params.range then
            -- Range can be "NEAR", "FAR", or "ANY"
            results.anchorRange = params.range
        elseif caster and caster.gameState then
            -- If not explicitly set, anchor to current range state
            results.anchorRange = caster.gameState.rangeState
        end
        
        if params.elevation then
            -- Elevation can be "AERIAL", "GROUNDED", or "ANY"
            results.anchorElevation = params.elevation
        elseif target then
            -- If not explicitly set, anchor to current target elevation
            results.anchorElevation = target.elevation
        end
        
        -- Store requirement for matching all conditions or just one
        results.anchorRequireAll = params.requireAll
        if results.anchorRequireAll == nil then
            results.anchorRequireAll = true  -- Default to requiring all conditions
        end
        
        return results
    end,
    
    zoneMulti = function(params, caster, target, results)
        results.zoneMulti = true
        return results
    end,
    
    -- Special slot effects
    freeze = function(params, caster, target, results)
        -- Freeze a spell in place (pause its progress)
        results.freezeApplied = true
        results.targetSlot = params.slot or 2  -- Default to middle slot
        results.freezeDuration = params.duration or 2.0
        return results
    end
}

-- Function to validate spell schema - Made more robust to handle malformed spells
local function validateSpell(spell, spellId)
    -- Add a missing ID based on spell name if needed
    if not spell.id and spell.name then
        spell.id = spell.name:lower():gsub(" ", "")
        print("INFO: Added missing ID for spell: " .. spell.name .. " -> " .. spell.id)
    end
    
    -- Check essential properties with better error handling
    if not spell.id then
        print("WARNING: Spell " .. spellId .. " missing required property: id, creating a default")
        spell.id = "spell_" .. spellId
    end
    
    if not spell.name then
        print("WARNING: Spell " .. spellId .. " missing required property: name, creating a default")
        spell.name = "Unnamed Spell " .. spellId
    end
    
    if not spell.description then
        print("WARNING: Spell " .. spellId .. " missing required property: description, creating a default")
        spell.description = "No description available for " .. spell.name
    end
    
    if not spell.castTime then
        print("WARNING: Spell " .. spellId .. " missing required property: castTime, setting default")
        spell.castTime = 5.0 -- Default cast time
    end
    
    if type(spell.castTime) ~= "number" then
        print("WARNING: Spell " .. spellId .. " castTime must be a number, fixing")
        spell.castTime = tonumber(spell.castTime) or 5.0
    end
    
    -- Ensure cost is a table, if empty then create empty table
    if not spell.cost then
        print("WARNING: Spell " .. spellId .. " missing required property: cost, creating empty cost")
        spell.cost = {}
    elseif type(spell.cost) ~= "table" then
        print("WARNING: Spell " .. spellId .. " cost must be a table, fixing")
        -- Try to convert to a table if possible
        local originalCost = spell.cost
        spell.cost = {}
        if originalCost then
            print("INFO: Converting non-table cost to table for: " .. spell.name)
            table.insert(spell.cost, tostring(originalCost))
        end
    end
    
    -- Check attackType is valid
    if spell.attackType then
        local validTypes = {
            projectile = true,
            remote = true,
            zone = true,
            utility = true
        }
        
        if not validTypes[spell.attackType] then
            print("WARNING: Spell " .. spellId .. " has invalid attackType: " .. spell.attackType .. ", fixing to utility")
            spell.attackType = "utility" -- Default to utility
        end
    else
        -- Default to utility if not specified
        print("WARNING: Spell " .. spellId .. " missing attackType, setting to utility")
        spell.attackType = "utility"
    end
    
    -- Check keywords are valid (if present)
    if spell.keywords then
        if type(spell.keywords) ~= "table" then
            print("WARNING: Spell " .. spellId .. " keywords must be a table, fixing")
            spell.keywords = {}
        else
            for keyword, _ in pairs(spell.keywords) do
                if not KeywordSystem.handlers[keyword] then
                    print("WARNING: Spell " .. spellId .. " has unimplemented keyword: " .. keyword .. ", removing")
                    spell.keywords[keyword] = nil
                end
            end
        end
    else
        -- Create empty keywords table if missing
        spell.keywords = {}
    end
    
    -- Check blockableBy (if present)
    if spell.blockableBy then
        if type(spell.blockableBy) ~= "table" then
            print("WARNING: Spell " .. spellId .. " blockableBy must be a table, fixing")
            spell.blockableBy = {}
        end
    else
        -- Create empty blockableBy table
        spell.blockableBy = {}
    end
    
    return true
end

-- Debug helper to show all available keywords and their descriptions
KeywordSystem.getKeywordHelp = function(format)
    -- Define descriptions for each keyword
    local descriptions = {
        -- Resource manipulation
        tokenShift = "Changes token types in the mana pool",
        conjure = "Creates new tokens in the mana pool",
        dissipate = "Removes tokens from the mana pool",
        
        -- Damage effects
        damage = "Deals damage to the opponent",
        
        -- Token manipulation
        lock = "Locks tokens, preventing their use for a duration",
        
        -- Spell timing effects
        delay = "Adds time to opponent's spell cast",
        accelerate = "Reduces cast time of a spell",
        dispel = "Cancels a spell and returns mana to the pool",
        disjoint = "Cancels a spell and destroys its mana",
        stagger = "Cancels a spell and prevents recasting",
        
        -- Movement and position effects
        elevate = "Sets caster to AERIAL state",
        ground = "Forces target to GROUNDED state",
        rangeShift = "Changes range state (NEAR/FAR)",
        forcePull = "Forces opponent to caster's range",
        
        -- Defense mechanisms
        reflect = "Reflects incoming spells",
        block = "Creates a shield to block specific attack types",
        
        -- Special effects
        echo = "Recasts the spell after a delay",
        freeze = "Freezes a spell's progress for a duration",
        
        -- Zone mechanics
        zoneAnchor = "Locks spell to cast-time range; fails if range changes",
        zoneMulti = "Makes zone affect both NEAR/FAR"
    }
    
    if format == "byCategory" then
        -- Organize keywords by category
        local categorizedInfo = {}
        
        -- Initialize categories
        for categoryKey, categoryName in pairs(KeywordSystem.categories) do
            categorizedInfo[categoryKey] = {
                name = categoryName,
                keywords = {}
            }
        end
        
        -- Sort keywords into categories
        for keyword in pairs(KeywordSystem.handlers) do
            local category = KeywordSystem.keywordCategories[keyword] or "SPECIAL"
            
            table.insert(categorizedInfo[category].keywords, {
                name = keyword,
                description = descriptions[keyword] or "No description available",
                example = KeywordSystem.getExampleUsage(keyword)
            })
        end
        
        return categorizedInfo
    else
        -- Default flat format
        local keywordInfo = {}
        
        -- Build a table of keyword info with usage examples
        for keyword in pairs(KeywordSystem.handlers) do
            keywordInfo[keyword] = {
                description = descriptions[keyword] or "No description available",
                example = KeywordSystem.getExampleUsage(keyword),
                category = KeywordSystem.keywordCategories[keyword] or "SPECIAL"
            }
        end
        
        return keywordInfo
    end
end

-- Generate example usage for keywords
KeywordSystem.getExampleUsage = function(keyword)
    local examples = {
        tokenShift = [[
            tokenShift = {
                type = "random",  -- or specific type like "fire"
                amount = 3
            }
        ]],
        
        conjure = [[
            conjure = {
                token = "fire",  -- or "moon", "force", etc.
                amount = 1
            }
        ]],
        
        damage = [[
            damage = {
                amount = 10,  -- or function(caster, target) return value end
                type = "fire"
            }
        ]],
        
        lock = [[
            lock = {
                duration = 5.0
            }
        ]],
        
        elevate = [[
            elevate = {
                duration = 4.0
            }
        ]],
        
        ground = [[
            ground = true
        ]],
        
        block = [[
            block = {
                type = "barrier",  -- Shield type: "barrier", "ward", or "field"
                blocks = {"projectile", "zone"},  -- Attack types to block
                manaLinked = true,  -- Whether shield consumes tokens on block (default: true)
                reflect = false,    -- Whether attacks are reflected back (default: false)
                hitPoints = 3       -- Optional: Fixed number of hits shield can take (default: token count)
            }
        ]]
    }
    
    return examples[keyword] or "No example available"
end

-- Centralized keyword resolution function
KeywordSystem.resolveKeyword = function(spellId, keyword, params, caster, target, slot, results)
    -- Check if this keyword has a handler
    if not KeywordSystem.handlers[keyword] then
        print(string.format("[KEYWORD ERROR] %s: Unknown keyword '%s'", spellId, keyword))
        return results
    end
    
    -- Process the parameters - handle both table and boolean cases
    local processedParams = {}
    
    if type(params) == "table" then
        -- For table parameters, process each one
        for paramKey, paramValue in pairs(params) do
            if type(paramValue) == "function" then
                processedParams[paramKey] = paramValue(caster, target, slot)
            else
                processedParams[paramKey] = paramValue
            end
        end
    else
        -- For boolean or other simple params, use directly
        processedParams = params
    end
    
    -- Store the original results for logging
    local resultsBefore = {}
    for k, v in pairs(results) do
        resultsBefore[k] = v
    end
    
    -- Process this keyword and get updated results
    local updatedResults = KeywordSystem.handlers[keyword](processedParams, caster, target, results)
    
    -- Log the keyword resolution
    if type(processedParams) == "table" then
        logKeywordResolution(spellId, keyword, processedParams, updatedResults)
    else
        -- For boolean params, create a simple parameter table for logging
        local simpleParams = {value = processedParams}
        logKeywordResolution(spellId, keyword, simpleParams, updatedResults)
    end
    
    return updatedResults
end

-- Function to get the appropriate target based on target type
KeywordSystem.resolveTarget = function(targetType, caster, opponent, spellSlot)
    local targetMap = {
        [KeywordSystem.targetTypes.SELF] = caster,
        [KeywordSystem.targetTypes.ENEMY] = opponent,
        [KeywordSystem.targetTypes.POOL_SELF] = caster.manaPool,
        [KeywordSystem.targetTypes.POOL_ENEMY] = opponent.manaPool,
        [KeywordSystem.targetTypes.SLOT_SELF] = caster.spellSlots[spellSlot] or caster.spellSlots,
        [KeywordSystem.targetTypes.SLOT_ENEMY] = opponent.spellSlots,
        [KeywordSystem.targetTypes.GLOBAL] = caster.gameState,
        [KeywordSystem.targetTypes.NONE] = nil
    }
    
    return targetMap[targetType]
end

-- Enhanced spell resolution function with targeting support and attack type resolution
KeywordSystem.resolveSpell = function(spell, caster, opponent, spellSlot, options)
    options = options or {}
    local debug = options.debug or false
    
    -- Validate spell before attempting to resolve
    validateSpell(spell, spell.id or "unknown")
    
    local results = {
        damage = 0,
        spellType = spell.attackType,
        targetingInfo = {},  -- Store targeting information for post-processing
        blocked = false,     -- Indicates if the spell was blocked by a shield
        missed = false       -- Indicates if a zone spell missed due to range/elevation mismatch
    }
    
    if debug then
        print(string.format("[SPELL] Resolving spell: %s (cast by %s)", 
                         spell.name, caster.name))
    end
    
    -- Check if this spell can be blocked by opponent's shields before we process keywords
    if spell.attackType and spell.attackType ~= "utility" then
        local blockInfo = KeywordSystem.checkBlockable(spell, caster, opponent)
        
        -- If the spell would be blocked, execute onBlock handler and process shield effects
        if blockInfo.blockable then
            if debug then
                print(string.format("[BLOCK CHECK] %s by %s would be blocked by opponent's %s",
                    spell.name, caster.name, blockInfo.blockType))
            end
            
            -- Set blocked flag in results
            results.blocked = true
            results.blockType = blockInfo.blockType
            results.blockingShield = blockInfo.blockingShield
            results.blockingSlot = blockInfo.blockingSlot
            results.shieldBreakPower = spell.shieldBreaker or 1
            
            -- Process shield block effects if needed
            if blockInfo.processBlockEffect then
                -- Get the shield
                local shield = blockInfo.blockingShield
                local shieldSlot = blockInfo.blockingSlot
                
                -- Decrease shield strength
                shield.shieldStrength = shield.shieldStrength - blockInfo.strengthReduction
                
                if debug then
                    print(string.format("[SHIELD] %s's shield strength reduced by %d (now %d)",
                        opponent.name, blockInfo.strengthReduction, shield.shieldStrength))
                end
                
                -- If mana linked, consume tokens
                if blockInfo.manaLinked and blockInfo.tokensToConsume > 0 then
                    -- Return tokens to the pool
                    for i = 1, blockInfo.tokensToConsume do
                        if #shield.tokens > 0 then
                            -- Get the last token
                            local lastTokenIndex = #shield.tokens
                            local tokenData = shield.tokens[lastTokenIndex]
                            
                            -- Trigger animation to return this token to the mana pool
                            opponent.manaPool:returnToken(tokenData.index)
                            
                            -- Remove this token from the slot's token list
                            table.remove(shield.tokens, lastTokenIndex)
                            
                            if debug then
                                print(string.format("[SHIELD] Token returned to %s's mana pool from shield",
                                    opponent.name))
                            end
                        end
                    end
                end
                
                -- If the shield is depleted, destroy it
                if shield.shieldStrength <= 0 or blockInfo.destroyShield then
                    if debug then
                        print(string.format("[SHIELD] %s's shield in slot %d has been broken!",
                            opponent.name, shieldSlot))
                    end
                    
                    -- Return any remaining tokens to the pool
                    for _, tokenData in ipairs(shield.tokens) do
                        opponent.manaPool:returnToken(tokenData.index)
                    end
                    
                    -- Reset the shield slot
                    shield.active = false
                    shield.isShield = false
                    shield.defenseType = nil
                    shield.blocksAttackTypes = nil
                    shield.shieldStrength = 0
                    shield.progress = 0
                    shield.spellType = nil
                    shield.castTime = 0
                    shield.tokens = {}
                    
                    -- Set a specific flag in results to indicate shield was destroyed
                    results.shieldDestroyed = true
                end
                
                -- Add visual effects for the block
                -- These will be handled by the wizard's castSpell function
            end
            
            -- Call onBlock handler if defined in the spell
            if spell.onBlock then
                local blockResults = spell.onBlock(caster, opponent, spellSlot, blockInfo)
                
                -- Merge onBlock results with main results
                if blockResults then
                    for k, v in pairs(blockResults) do
                        results[k] = v
                    end
                end
                
                -- Special case: if onBlock handler sets 'continueExecution', don't stop processing
                if not results.continueExecution then
                    -- If we're blocked and there's no override, return early
                    return results
                end
            else
                -- If blocked with no handler, return early
                return results
            end
        end
    end
    
    -- For zone spells, check if the spell would miss due to range mismatch when zoneAnchor is used
    if spell.attackType == "zone" then
        local doesMiss = false
        
        -- Check for zoneAnchor keyword
        if spell.keywords and spell.keywords.zoneAnchor then
            -- For zone anchored spells, check if the target's position matches the anchor
            -- Get cast-time range and elevation state
            local anchorRange = spell.keywords.zoneAnchor.range
            local anchorElevation = spell.keywords.zoneAnchor.elevation
            
            -- Check current range state
            if anchorRange and caster.gameState then
                if anchorRange ~= caster.gameState.rangeState then
                    doesMiss = true
                end
            end
            
            -- Check current elevation state
            if anchorElevation and opponent then
                if anchorElevation ~= opponent.elevation then
                    doesMiss = true
                end
            end
        end
        
        -- If the spell would miss, execute onMiss handler if present
        if doesMiss then
            if debug then
                print(string.format("[ZONE MISS] %s by %s misses due to range/elevation mismatch",
                    spell.name, caster.name))
            end
            
            -- Set missed flag in results
            results.missed = true
            
            -- Call onMiss handler if defined in the spell
            if spell.onMiss then
                local missResults = spell.onMiss(caster, opponent, spellSlot)
                
                -- Merge onMiss results with main results
                if missResults then
                    for k, v in pairs(missResults) do
                        results[k] = v
                    end
                end
                
                -- Special case: if onMiss handler sets 'continueExecution', don't stop processing
                if not results.continueExecution then
                    -- If we missed with no override, return early
                    return results
                end
            else
                -- If missed with no handler, return early but with a basic whiff effect
                results.whiffEffect = true
                return results
            end
        end
    end
    
    -- Process each keyword in the spell
    if spell.keywords then
        for keyword, params in pairs(spell.keywords) do
            -- Get the target type based on whether params is a table or a boolean
            local targetType
            if type(params) == "table" then
                targetType = params.target or KeywordSystem.keywordTargets[keyword]
            else
                -- For boolean params (like ground = true), use the default target
                targetType = KeywordSystem.keywordTargets[keyword]
            end
            
            local target = KeywordSystem.resolveTarget(targetType, caster, opponent, spellSlot)
            
            -- Store targeting info for debugging and post-processing
            results.targetingInfo[keyword] = {
                targetType = targetType,
                target = target and target.name or "unknown"
            }
            
            -- Add targeting info to the log if in debug mode
            if debug then
                print(string.format("[TARGETING] Keyword %s targeting %s", 
                                 keyword, targetType))
            end
            
            -- Process the keyword with the correct target
            results = KeywordSystem.resolveKeyword(spell.id, keyword, params, caster, target, spellSlot, results)
        end
    end
    
    -- For backward compatibility - delegate to effect function if present
    if spell.effect then
        if debug then
            print(string.format("[SPELL] %s: Using legacy effect function", spell.id))
        end
        
        local effectResults = spell.effect(caster, opponent, spellSlot)
        -- Merge effect results with keyword results
        for k, v in pairs(effectResults) do
            results[k] = v
        end
    end
    
    -- If we have an onSuccess handler and the spell wasn't blocked or missed, execute it
    if not results.blocked and not results.missed and spell.onSuccess then
        local successResults = spell.onSuccess(caster, opponent, spellSlot, results)
        
        -- Merge onSuccess results with main results
        if successResults then
            for k, v in pairs(successResults) do
                results[k] = v
            end
        end
    end
    
    -- Count number of effects in results (excluding utility fields)
    local effectCount = 0
    for k, _ in pairs(results) do
        -- Don't count utility fields or zero damage
        if k ~= "damage" or results.damage ~= 0 then
            if k ~= "spellType" and k ~= "targetingInfo" and k ~= "blocked" and k ~= "missed" then
                effectCount = effectCount + 1
            end
        end
    end
    
    if debug then
        print(string.format("[SPELL] %s complete: damage=%s, effects=%d, blocked=%s, missed=%s", 
                            spell.id, tostring(results.damage), effectCount, 
                            tostring(results.blocked), tostring(results.missed)))
    end
    
    return results
end

-- Convenience function to resolve a spell against a specific target
KeywordSystem.castSpell = function(spell, caster, options)
    options = options or {}
    local gameState = caster.gameState
    local spellSlot = options.spellSlot or 1
    local debugMode = options.debug or false
    
    -- Find default opponent if not specified
    local opponent = options.opponent
    if not opponent and gameState and gameState.wizards then
        for _, wizard in ipairs(gameState.wizards) do
            if wizard ~= caster then
                opponent = wizard
                break
            end
        end
    end
    
    if not opponent then
        print("[ERROR] No opponent found for spell: " .. spell.name)
        return nil
    end
    
    -- Call the resolve function with appropriate targets
    return KeywordSystem.resolveSpell(spell, caster, opponent, spellSlot, { debug = debugMode })
end

-- Function to check if a spell can be blocked by opponent's shields
KeywordSystem.checkBlockable = function(spell, caster, opponent)
    -- Default response - not blockable
    local result = {
        blockable = false,
        blockType = nil,
        blockingShield = nil,
        blockingSlot = nil,
        manaLinked = nil,
        processBlockEffect = false
    }
    
    -- Early exit cases
    if not opponent or not spell or not spell.attackType then
        return result
    end
    
    -- Utility spells can't be blocked
    if spell.attackType == "utility" then
        return result
    end
    
    -- Get the attack type of the spell
    local attackType = spell.attackType  -- "projectile", "remote", or "zone"
    
    -- Check each of the opponent's spell slots for active shields
    for i, slot in ipairs(opponent.spellSlots) do
        -- Skip inactive slots or non-shield slots
        if not slot.active or not slot.isShield then
            goto continue
        end
        
        -- Check if this shield has strength remaining
        if slot.shieldStrength <= 0 then
            goto continue
        end
        
        -- Verify this shield can block this attack type
        local canBlock = false
        
        -- Check blocksAttackTypes or blockTypes properties
        if slot.blocksAttackTypes and slot.blocksAttackTypes[attackType] then
            canBlock = true
        elseif slot.blockTypes then
            -- Iterate through blockTypes array to find a match
            for _, blockType in ipairs(slot.blockTypes) do
                if blockType == attackType then
                    canBlock = true
                    break
                end
            end
        end
        
        -- If we found a shield that can block this attack
        if canBlock then
            result.blockable = true
            result.blockType = slot.defenseType
            result.blockingShield = slot
            result.blockingSlot = i
            result.manaLinked = slot.manaLinked
            
            -- Handle mana consumption for the block if mana linked
            if slot.manaLinked and #slot.tokens > 0 then
                result.processBlockEffect = true
                
                -- Get amount of hits based on the spell's shield breaker power (if any)
                local shieldBreakPower = spell.shieldBreaker or 1
                
                -- Determine how many tokens to consume (up to shield breaker power or tokens available)
                local tokensToConsume = math.min(shieldBreakPower, #slot.tokens)
                result.tokensToConsume = tokensToConsume
                
                -- Calculate how much to decrease the shield strength
                result.strengthReduction = shieldBreakPower
                
                -- Check if this will destroy the shield
                if slot.shieldStrength <= shieldBreakPower then
                    result.destroyShield = true
                end
            end
            
            -- Return after finding the first blocking shield
            return result
        end
        
        ::continue::
    end
    
    -- If we get here, no shield can block this spell
    return result
end

-- Shield creation function
KeywordSystem.createShield = function(wizard, spellSlot, blockParams)
    -- Default result table
    local results = {
        isShield = true,
        shieldCreated = true  -- Flag to indicate shield was created
    }
    
    -- Check that the slot is valid
    if not wizard.spellSlots[spellSlot] then
        print("[SHIELD ERROR] Invalid spell slot for shield creation: " .. tostring(spellSlot))
        return results
    end
    
    local slot = wizard.spellSlots[spellSlot]
    
    -- Set shield parameters
    slot.isShield = true
    slot.defenseType = blockParams.type or "barrier"
    
    -- Set which attack types this shield blocks
    slot.blocksAttackTypes = {}
    local blockTypes = blockParams.blocks or {"projectile"}
    for _, attackType in ipairs(blockTypes) do
        slot.blocksAttackTypes[attackType] = true
    end
    
    -- Set mana linking (default to true - shield consumes tokens when hit)
    slot.manaLinked = blockParams.manaLinked
    if slot.manaLinked == nil then  -- If not explicitly set
        slot.manaLinked = true
    end
    
    -- Set reflection capability
    slot.reflect = blockParams.reflect or false
    
    -- Set shield strength based on tokens or override value
    if blockParams.hitPoints then
        -- Use explicit hit point value if provided
        slot.shieldStrength = blockParams.hitPoints
    else
        -- Otherwise use token count
        slot.shieldStrength = #slot.tokens
    end
    
    -- Slow down token orbiting speed for shield tokens if they exist
    for _, tokenData in ipairs(slot.tokens) do
        local token = tokenData.token
        -- Set token to "SHIELDING" state
        token.state = "SHIELDING"
        -- Add specific shield type info to the token for visual effects
        token.shieldType = slot.defenseType
        -- Slow down the rotation speed for shield tokens
        if token.orbitSpeed then
            token.orbitSpeed = token.orbitSpeed * 0.5  -- 50% slower
        end
    end
    
    -- Shield visual effect color based on type
    local shieldColor = {0.8, 0.8, 0.8}  -- Default gray
    if slot.defenseType == "barrier" then
        shieldColor = {1.0, 1.0, 0.3}    -- Yellow for barriers
    elseif slot.defenseType == "ward" then
        shieldColor = {0.3, 0.3, 1.0}    -- Blue for wards
    elseif slot.defenseType == "field" then
        shieldColor = {0.3, 1.0, 0.3}    -- Green for fields
    end
    
    -- Create shield effect using VFX system if available
    if wizard.gameState and wizard.gameState.vfx then
        wizard.gameState.vfx.createEffect("shield", wizard.x, wizard.y, nil, nil, {
            duration = 1.0,
            color = {shieldColor[1], shieldColor[2], shieldColor[3], 0.7},
            shieldType = slot.defenseType
        })
    end
    
    -- Print debug info
    print(string.format("[SHIELD] %s created a %s shield in slot %d with %d strength (mana linked: %s)",
        wizard.name or "Unknown wizard",
        slot.defenseType,
        spellSlot,
        slot.shieldStrength,
        slot.manaLinked and "yes" or "no"))
    
    -- Include key parameters in result for later spell resolution
    results.defenseType = slot.defenseType
    results.blockTypes = blockParams.blocks
    results.shieldStrength = slot.shieldStrength
    results.manaLinked = slot.manaLinked
    
    return results
end

-- Function to register a new keyword handler
KeywordSystem.registerKeyword = function(keyword, handler, options)
    options = options or {}
    
    -- Check if this keyword already exists
    if KeywordSystem.handlers[keyword] then
        print(string.format("[WARNING] Overwriting existing keyword handler: %s", keyword))
    end
    
    -- Register the handler function
    KeywordSystem.handlers[keyword] = handler
    
    -- Register category
    local category = options.category or "SPECIAL"
    KeywordSystem.keywordCategories[keyword] = category
    
    -- Register default target type
    local targetType = options.targetType or KeywordSystem.targetTypes.SELF
    KeywordSystem.keywordTargets[keyword] = targetType
    
    print(string.format("[KEYWORD] Registered new keyword: %s (category: %s, target: %s)",
                      keyword, category, targetType))
    
    return true
end

-- Legacy resolution function name for backward compatibility
local function resolveSpellEffect(spell, caster, target, slot)
    return KeywordSystem.resolveSpell(spell, caster, target, slot)
end

-- Ashgar's Spells (Fire-focused)
Spells.conjurefire = {
    id = "conjurefire",
    name = "Conjure Fire",
    description = "Creates a new Fire mana token",
    attackType = "utility",
    castTime = 5.0,  -- Base cast time of 5 seconds
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = "fire",
            amount = 1
        }
    },
    vfx = "fire_conjure",
    blockableBy = {},  -- Unblockable
    
    -- Custom cast time calculation based on existing fire tokens
    getCastTime = function(caster)
        -- Base cast time
        local baseCastTime = 5.0
        
        -- Count fire tokens in the mana pool
        local fireCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == "fire" and token.state == "FREE" then
                    fireCount = fireCount + 1
                end
            end
        end
        
        -- Increase cast time by 5 seconds per existing fire token
        local adjustedCastTime = baseCastTime + (fireCount * 5.0)
        
        return adjustedCastTime
    end
}

Spells.firebolt = {
    id = "firebolt",
    name = "Firebolt",
    description = "Quick ranged hit, more damage against AERIAL opponents",
    castTime = 5.0,
    attackType = "projectile",
    cost = {"fire", "any"},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.elevation then
                    return target.elevation == "AERIAL" and 15 or 10
                end
                return 10
            end,
            type = "fire",
            conditional = "target.AERIAL"
        }
    },
    vfx = "fire_bolt",
    sfx = "fire_whoosh",
    blockableBy = {"barrier", "ward"}
}

Spells.meteor = {
    id = "meteor",
    name = "Meteor Dive",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = 8.0,
    attackType = "zone",
    cost = {"fire", "force", "star"},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.elevation then
                    return target.elevation == "GROUNDED" and 20 or 0
                end
                return 0 -- Default damage if target is nil
            end,
            type = "fire",
            conditional = "target.GROUNDED"
        },
        rangeShift = {
            position = "NEAR"
        }
    },
    vfx = "meteor_dive",
    sfx = "meteor_impact",
    blockableBy = {"barrier", "field"}
}

Spells.combust = {
    id = "combust",
    name = "Combust Lock",
    description = "Locks opponent mana token, punishes overqueueing",
    castTime = 6.0,
    attackType = "remote",
    cost = {"fire", "force"},
    keywords = {
        lock = {
            duration = 10.0
        },
        damage = {
            amount = function(caster, target)
                -- Count active spell slots
                local activeSlots = 0
                if target and target.spellSlots then
                    for _, slot in ipairs(target.spellSlots) do
                        if slot.active then
                            activeSlots = activeSlots + 1
                        end
                    end
                end
                return activeSlots * 3
            end,
            type = "fire",
            scalesWithOpponentSlots = true
        }
    },
    vfx = "combust_lock",
    blockableBy = {"ward", "field"}
}

Spells.emberlift = {
    id = "emberlift",
    name = "Emberlift",
    description = "Launches caster into the air and increases range",
    castTime = 2.5,
    attackType = "utility",
    cost = {"fire", "force"},
    keywords = {
        elevate = {
            duration = 5.0,
            target = "SELF",
            vfx = "emberlift"
        },
        rangeShift = {
            position = "FAR"
        }
    },
    vfx = "ember_lift",
    sfx = "whoosh_up",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Selene's Spells (Moon-focused)
Spells.conjuremoonlight = {
    id = "conjuremoonlight",
    name = "Conjure Moonlight",
    description = "Creates a new Moon mana token",
    attackType = "utility",
    castTime = 5.0,  -- Base cast time of 5 seconds
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = "moon",
            amount = 1
        }
    },
    vfx = "moon_conjure",
    blockableBy = {},  -- Unblockable
    
    -- Custom cast time calculation based on existing moon tokens
    getCastTime = function(caster)
        -- Base cast time
        local baseCastTime = 5.0
        
        -- Count moon tokens in the mana pool
        local moonCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == "moon" and token.state == "FREE" then
                    moonCount = moonCount + 1
                end
            end
        end
        
        -- Increase cast time by 5 seconds per existing moon token
        local adjustedCastTime = baseCastTime + (moonCount * 5.0)
        
        return adjustedCastTime
    end
}

Spells.volatileconjuring = {
    id = "volatileconjuring",
    name = "Volatile Conjuring",
    description = "Creates a random mana token",
    attackType = "utility",
    castTime = 5.0,  -- Fixed cast time of 5 seconds
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = function(caster, target)
                local tokenTypes = {"fire", "force", "moon", "nature", "star"}
                local randomIndex = math.random(#tokenTypes)
                local selectedToken = tokenTypes[randomIndex]
                print(caster.name .. " conjured a random " .. selectedToken .. " token")
                return selectedToken
            end,
            amount = 1
        }
    },
    vfx = "volatile_conjure",
    blockableBy = {}  -- Unblockable
    -- Removed dynamic cast time calculation to keep it fixed at 5 seconds
}

Spells.mist = {
    id = "mist",
    name = "Mist Veil",
    description = "A ward of mist that blocks projectiles and remotes",
    attackType = "utility",
    castTime = 5.0,
    cost = {"moon", "moon"},
    keywords = {
        block = {
            type = "ward",
            blocks = {"projectile", "remote"},
            manaLinked = true
        },
        elevate = {
            duration = 4.0
        }
    },
    vfx = "mist_veil",
    sfx = "mist_shimmer",
    blockableBy = {}  -- Utility spell, can't be blocked
}

Spells.tidalforce = {
    id = "tidalforce",
    name = "Tidal Force",
    description = "Chip damage, forces AERIAL enemies out of the air",
    attackType = "remote",
    castTime = 5.0,
    cost = {"moon", "any"},
    keywords = {
        damage = {
            amount = 5,
            type = "moon"
        },
        ground = {
            -- Only apply grounding if the target is AERIAL
            conditional = function(caster, target)
                return target and target.elevation == "AERIAL"
            end,
            target = "ENEMY", -- Explicitly specify the enemy as the target
            vfx = "tidal_force_ground" -- Specify the visual effect to use
        }
    },
    vfx = "tidal_force",
    sfx = "tidal_wave",
    blockableBy = {"ward", "field"}
}

Spells.lunardisjunction = {
    id = "lunardisjunction",
    name = "Lunar Disjunction",
    description = "Counterspell, cancels an opponent's spell and destroys its mana",
    attackType = "projectile",
    castTime = 5.0,
    cost = {"moon", "any"},
    keywords = {
        disjoint = {
            -- Target the opponent's slot corresponding to the slot this spell was cast from
            slot = function(caster, target, slot) 
                return slot 
            end,
            target = "SLOT_ENEMY"  -- Explicitly target enemy's spell slot
        }
        -- Note: Destroying the mana used to cast *this* spell (Lunar Disjunction)
        -- is not handled by standard keywords. 'disjoint' above handles destroying
        -- the mana of the *target* spell. Self-destruction might require a custom
        -- handler or engine-level support.
    },
    vfx = "lunardisjunction",
    sfx = "lunardisjunction_sound",
    blockableBy = {"barrier", "ward"} -- Disjunction is a projectile
}

Spells.gravity = {
    id = "gravity",
    name = "Gravity Pin",
    description = "Traps AERIAL enemies",
    attackType = "zone",
    castTime = 7.0,
    cost = {"moon", "nature"},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.elevation then
                    return target.elevation == "AERIAL" and 15 or 0
                end
                return 0 -- Default damage if target is nil
            end,
            type = "moon",
            conditional = "target.AERIAL"
        },
        ground = {
            conditional = function(caster, target)
                return target and target.elevation == "AERIAL"
            end,
            target = "ENEMY",
            vfx = "gravity_pin_ground"
        },  -- Set target to GROUNDED if AERIAL
        stagger = {
            duration = 2.0  -- Stun for 2 seconds
        }
    },
    vfx = "gravity_pin",
    sfx = "gravity_slam",
    blockableBy = {"barrier", "field"}
}

Spells.eclipse = {
    id = "eclipse",
    name = "Eclipse Echo",
    description = "Freezes caster's central queued spell for 2 seconds",
    attackType = "remote",
    castTime = 6.0,
    cost = {"moon", "force"},
    keywords = {
        freeze = {
            slot = 2,  -- Middle spell slot
            duration = 2.0
        }
    },
    vfx = "eclipse_echo",
    sfx = "time_stop",
    blockableBy = {"ward", "field"}
}

Spells.fullmoonbeam = {
    id = "fullmoonbeam",
    name = "Full Moon Beam",
    description = "Channels moonlight into a beam that deals damage equal to its cast time",
    attackType = "projectile",
    castTime = 7.0,
    cost = {"moon", "moon", "moon", "moon", "moon"},  -- 5 moon mana
    keywords = {
        damage = {
            amount = function(caster, target, slot)
                -- Find the slot this spell was cast from to get its actual cast time
                local actualCastTime = 7.0  -- Default/base cast time
                
                -- If we know which slot this spell was cast from
                if slot and caster.spellSlots[slot] then
                    -- Use the actual cast time of the spell which may have been modified
                    actualCastTime = caster.spellSlots[slot].castTime
                end
                
                -- Calculate damage based on cast time (roughly 3.5 damage per second)
                local damage = math.floor(actualCastTime * 3.5)
                
                -- Log the damage calculation
                print("Full Moon Beam cast time: " .. actualCastTime .. "s, dealing " .. damage .. " damage")
                
                return damage
            end,
            type = "moon",
            scaledDamage = true
        }
    },
    vfx = "moon_beam",
    sfx = "beam_charge",
    blockableBy = {"barrier", "ward"}
}

-- New shield spells

Spells.forcebarrier = {
    id = "forcebarrier",
    name = "Force Barrier",
    description = "A protective barrier that blocks projectiles and zones",
    castTime = 4.0,
    attackType = "utility",
    cost = {"force", "force"},
    keywords = {
        block = {
            type = "barrier",
            blocks = {"projectile", "zone"},
            manaLinked = true
        }
    },
    vfx = "force_barrier",
    sfx = "shield_up",
    blockableBy = {}  -- Utility spell, can't be blocked
}

Spells.moonward = {
    id = "moonward",
    name = "Moon Ward",
    description = "A mystical ward that blocks projectiles and remotes",
    attackType = "utility",
    castTime = 4.5,
    cost = {"moon", "moon"},  -- Changed cost from moon+star to moon+moon
    keywords = {
        block = {
            type = "ward",
            blocks = {"projectile", "remote"},
            manaLinked = true
        }
    },
    vfx = "moon_ward",
    sfx = "shield_up",
    blockableBy = {}  -- Utility spell, can't be blocked
}

Spells.naturefield = {
    id = "naturefield",
    name = "Nature Field",
    description = "A field of natural energy that blocks remotes and zones",
    attackType = "utility",
    castTime = 4.0,
    cost = {"nature", "nature"},
    keywords = {
        block = {
            type = "field",
            blocks = {"remote", "zone"},
            manaLinked = true
        }
    },
    vfx = "nature_field",
    sfx = "nature_grow",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Advanced reflective shield example
Spells.mirrorshield = {
    id = "mirrorshield",
    name = "Mirror Shield",
    description = "A reflective barrier that returns damage to attackers",
    attackType = "utility",
    castTime = 5.0,
    cost = {"moon", "moon", "star"},  -- Changed cost from force+moon+star to moon+moon+star
    keywords = {
        block = {
            type = "barrier",  -- Barrier type blocks projectiles and zones
            blocks = {"projectile", "zone"},
            manaLinked = false, -- Doesn't consume tokens when blocking
            reflect = true,     -- Reflects damage back to attacker
            hitPoints = 3       -- Can block 3 attacks regardless of token count
        }
    },
    vfx = "mirror_shield",
    sfx = "crystal_ring",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Shield-breaking spell example
Spells.shieldbreaker = {
    id = "shieldbreaker",
    name = "Shield Breaker",
    description = "A powerful force blast that shatters shields and barriers",
    attackType = "projectile", -- Projectile type (can be blocked by barriers and wards)
    castTime = 6.0,
    cost = {"force", "force", "star"},
    keywords = {
        -- Regular damage component
        damage = {
            amount = function(caster, target)
                -- Base damage
                local baseDamage = 8
                
                -- Check if target exists before checking shields
                local shieldBonus = 0
                if target and target.spellSlots then
                    -- Bonus damage if target has active shields
                    for _, slot in ipairs(target.spellSlots) do
                        if slot.active and slot.isShield then
                            shieldBonus = shieldBonus + 6
                            break -- Only count one shield for bonus
                        end
                    end
                end
                
                return baseDamage + shieldBonus
            end,
            type = "force"
        },
        
        -- Special effect: If it hits a shield, it deals 3 "hits" worth of damage
        -- This is implemented through the spell resolution pipeline that checks
        -- for shields blocking the projectile
        -- The effect is simulated by multiple shield strength reductions in a single hit
    },
    -- Add special property that indicates this is a shield-breaker spell
    -- This will be used in the shield-blocking logic
    shieldBreaker = 3, -- Deals 3 hits worth of damage to shields
    vfx = "force_blast",
    sfx = "shield_break",
    blockableBy = {"barrier", "ward"}, -- Can be blocked by barriers and wards
    
    -- Custom handler for when this spell is blocked
    onBlock = function(caster, target, slot, blockInfo)
        print(string.format("[SHIELD BREAKER] %s's Shield Breaker is testing the %s shield's strength!", 
            caster.name, blockInfo.blockType))
        
        -- Return a special response that overrides behavior
        return {
            specialBlockMessage = "Shield Breaker collides with active shield!",
            damageShield = true,  -- Signal that we want to damage the shield
            continueExecution = false  -- Don't continue processing the spell
        }
    end
}

-- Zone spell with range anchoring example
Spells.eruption = {
    id = "eruption",
    name = "Lava Eruption",
    description = "Creates a volcanic eruption under the opponent. Only works at NEAR range.",
    attackType = "zone", -- Zone attack - can be blocked by barriers, fields, or dodged
    castTime = 7.0,
    cost = {"fire", "fire", "nature"},
    keywords = {
        -- Anchor the spell to NEAR range - it can only work when cast at NEAR range
        zoneAnchor = {
            range = "NEAR", -- Only works at NEAR range
            elevation = "GROUNDED", -- Only hits GROUNDED targets
            requireAll = true -- Must match both conditions
        },
        
        -- Damage component
        damage = {
            amount = 16,
            type = "fire"
        },
        
        -- Secondary effect - ground the target if they're AERIAL
        ground = true,
        
        -- Add damage over time
        burn = {
            duration = 4.0,
            tickDamage = 3
        }
    },
    vfx = "lava_eruption",
    sfx = "volcano_rumble",
    blockableBy = {"barrier", "field"},
    
    -- Custom handler for when this spell misses
    onMiss = function(caster, target, slot)
        print(string.format("[MISS] %s's Lava Eruption misses because conditions aren't right!", caster.name))
        
        -- Create a small damage effect at caster's feet to simulate backfire
        if caster.gameState and caster.gameState.vfx then
            caster.gameState.vfx.createEffect("impact", caster.x, caster.y + 30, nil, nil, {
                duration = 0.5,
                color = {1.0, 0.3, 0.1, 0.6},
                particleCount = 5,
                radius = 15
            })
        end
        
        -- Caster takes a small amount of damage from their own spell backfiring
        local selfDamage = 4
        caster.health = caster.health - selfDamage
        if caster.health < 0 then caster.health = 0 end
        
        -- Return special response for handling the miss
        return {
            missBackfire = true,
            backfireDamage = selfDamage,
            backfireMessage = "Lava Eruption backfires when cast at wrong range!"
        }
    end,
    
    -- Custom handler for when this spell succeeds
    onSuccess = function(caster, target, slot, results)
        print(string.format("[SUCCESS] %s's Lava Eruption hits %s with full force!", caster.name, target.name))
        
        -- Return additional effects for when the spell hits successfully
        return {
            successMessage = "The ground trembles with volcanic fury!",
            extraEffect = "area_burn",
            burnDuration = 2.0
        }
    end
}

-- Prepare the return table with all spells and utility functions
local SpellsModule = {
    spells = Spells,
    resolveSpellEffect = resolveSpellEffect,  -- Legacy function 
    resolveSpell = KeywordSystem.resolveSpell,  -- New function
    castSpell = KeywordSystem.castSpell,       -- Convenient casting function
    validateSpell = validateSpell,
    keywords = KeywordSystem.handlers,         -- Keyword handlers
    registerKeyword = KeywordSystem.registerKeyword,  -- Register new keywords
    keywordTargets = KeywordSystem.targetTypes,  -- Targeting types
    keywordSystem = KeywordSystem               -- Full system access 
}

-- Validate all spells at module load time to catch errors early
for spellId, spell in pairs(Spells) do
    validateSpell(spell, spellId)
end

-- Add new spells using the keyword system

-- Utility spell that changes tokens
Spells.stormMeld = {
    id = "stormmeld",
    name = "Storm Meld",
    description = "An elemental fusion spell that changes tokens to random types",
    attackType = "utility",
    castTime = 3.0,
    cost = {"fire", "moon"},
    keywords = {
        tokenShift = {
            type = "random",
            amount = 3
        },
        damage = {
            amount = 5,
            type = "mixed"
        },
        echo = {
            delay = 3.0
        }
    },
    vfx = "storm_meld",
    sfx = "elemental_fusion",
    blockableBy = {}  -- Utility spells can't be blocked
}

-- Offensive spell with multiple effects
Spells.cosmicRift = {
    id = "cosmicrift",
    name = "Cosmic Rift",
    description = "Opens a rift that damages opponents and disrupts spellcasting",
    attackType = "zone",
    castTime = 5.5,
    cost = {"star", "star", "force"},
    keywords = {
        damage = {
            amount = 12,
            type = "star"
        },
        delay = {
            slot = 1,  -- Target opponent's first spell slot
            duration = 2.0
        },
        zoneMulti = true  -- Affects both NEAR and FAR
    },
    vfx = "cosmic_rift",
    sfx = "space_tear",
    blockableBy = {"barrier", "field"}
}

-- Create a new spell that launches opponents into the air
Spells.forceBlast = {
    id = "forceblast",
    name = "Force Blast",
    description = "Unleashes a blast of force that launches opponents into the air",
    attackType = "remote",
    castTime = 4.0,
    cost = {"force", "force"},
    keywords = {
        damage = {
            amount = 8,
            type = "force"
        },
        elevate = {
            duration = 3.0,         -- Lasts for 3 seconds
            target = "ENEMY",       -- Targets the opponent
            vfx = "force_blast_up"  -- Custom VFX for the effect
        }
    },
    vfx = "force_blast",
    sfx = "force_wind",
    blockableBy = {"ward", "field"}
}

-- Movement spell with multiple effects
Spells.blazingAscent = {
    id = "blazingascent",
    name = "Blazing Ascent",
    description = "Rockets upward in a burst of fire, dealing damage and becoming AERIAL",
    attackType = "projectile",
    castTime = 3.0,
    cost = {"fire", "fire", "force"},
    keywords = {
        damage = {
            amount = function(caster, target)
                -- More damage if already AERIAL (harder to cast while falling)
                return caster.elevation == "AERIAL" and 15 or 10
            end,
            type = "fire"
        },
        elevate = {
            duration = 6.0
        },
        dissipate = {
            token = "nature",
            amount = 1
        }
    },
    vfx = "blazing_ascent",
    sfx = "fire_whoosh",
    blockableBy = {"barrier", "ward"}
}

-- Complex multi-target spell using the new targeting system
Spells.arcaneReversal = {
    id = "arcanereversal",
    name = "Arcane Reversal",
    description = "A complex spell that manipulates mana, movement, and timing simultaneously",
    attackType = "remote",
    castTime = 6.0,
    cost = {"moon", "star", "force", "force"},
    keywords = {
        -- Apply damage to enemy
        damage = {
            amount = function(caster, target)
                -- More damage if enemy has active shields
                local shieldCount = 0
                if target and target.spellSlots then
                    for _, slot in ipairs(target.spellSlots) do
                        if slot.active and slot.isShield then
                            shieldCount = shieldCount + 1
                        end
                    end
                end
                return 8 + (shieldCount * 4)  -- 8 base + 4 per shield
            end,
            type = "star",
            target = "ENEMY"  -- Explicit targeting
        },
        
        -- Move self to opposite range
        rangeShift = {
            position = function(caster, target)
                return caster.gameState.rangeState == "NEAR" and "FAR" or "NEAR"
            end,
            target = "SELF"
        },
        
        -- Lock opponent's mana tokens
        lock = {
            duration = 4.0,
            target = "POOL_ENEMY" 
        },
        
        -- Add tokens to own pool
        conjure = {
            token = function(caster, target)
                -- Create a token of the type that's most common in opponent's pool
                local tokenCounts = {
                    fire = 0,
                    force = 0,
                    moon = 0,
                    nature = 0,
                    star = 0
                }
                
                -- Count opponent's token types in mana pool
                if target.manaPool then
                    for _, token in ipairs(target.manaPool.tokens or {}) do
                        if token.state == "FREE" then
                            tokenCounts[token.type] = (tokenCounts[token.type] or 0) + 1
                        end
                    end
                end
                
                -- Find the most common type
                local maxCount = 0
                local mostCommonType = "force"  -- Default
                
                for tokenType, count in pairs(tokenCounts) do
                    if count > maxCount then
                        maxCount = count
                        mostCommonType = tokenType
                    end
                end
                
                return mostCommonType
            end,
            amount = 1,
            target = "POOL_SELF"
        },
        
        -- Accelerate own next spell
        accelerate = {
            amount = 2.0,
            slot = 1,  -- First slot
            target = "SLOT_SELF"
        }
    },
    vfx = "arcane_reversal",
    sfx = "time_shift",
    blockableBy = {"ward", "field"}
}

-- Complex positional spell
Spells.lunarTides = {
    id = "lunartides",
    name = "Lunar Tides",
    description = "Manipulates the battle flow based on range and elevation",
    attackType = "zone",
    castTime = 7.0,
    cost = {"moon", "moon", "force", "star"},
    keywords = {
        damage = {
            amount = function(caster, target)
                -- Damage based on position
                local baseDamage = 8
                
                -- If opponent is AERIAL, deal more damage
                if target and target.elevation and target.elevation == "AERIAL" then
                    baseDamage = baseDamage + 4
                end
                
                -- If in NEAR range, deal more damage
                if caster and caster.gameState and caster.gameState.rangeState == "NEAR" then
                    baseDamage = baseDamage + 3
                end
                
                return baseDamage
            end,
            type = "moon",
            target = "ENEMY"  -- Explicit targeting
        },
        rangeShift = {
            -- Position changes based on current state
            position = function(caster, target)
                -- Toggle position
                return caster.gameState.rangeState == "NEAR" and "FAR" or "NEAR"
            end,
            target = "SELF"  -- Affects caster
        },
        lock = {
            -- Lock duration increases if target has multiple active spells
            duration = function(caster, target)
                local activeSlots = 0
                for _, slot in ipairs(target.spellSlots) do
                    if slot.active then
                        activeSlots = activeSlots + 1
                    end
                end
                return 3.0 + (activeSlots * 1.0)  -- Base 3 seconds + 1 per active slot
            end,
            target = "POOL_ENEMY"  -- Affects opponent's mana pool
        }
    },
    vfx = "lunar_tide",
    sfx = "tide_rush",
    blockableBy = {"field"}
}

return SpellsModule