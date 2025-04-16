-- Spells.lua
-- Contains data for all spells in the game

local Spells = {}

-- Schema for spell object:
-- id: Unique identifier for the spell (string)
-- name: Display name of the spell (string)
-- description: Text description of what the spell does (string)
-- attackType: How the spell is delivered - "projectile", "remote", "zone", "utility" (string)
-- castTime: Duration in seconds to cast the spell (number)
-- cost: Array of token types required (simple array of strings like {"fire", "fire", "moon"})
-- keywords: Table of effect keywords and their parameters (table)
--   - Available keywords: conjure, dissipate, damage, lock, delay, accelerate, dispel, disjoint, 
--     stagger, elevate, ground, rangeShift, forcePull, reflect, block, echo, zoneAnchor,
--     zoneMulti, manaLeak, tokenShift, overcharge, rebound
-- vfx: Visual effect identifier (string, optional)
-- sfx: Sound effect identifier (string, optional)
-- blockableBy: Array of shield types that can block this spell (array, optional)

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
        results.damage = params.amount or 0
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
        return results
    end,
    
    ground = function(params, caster, target, results)
        results.setElevation = "GROUNDED"
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
        results.isShield = true
        results.defenseType = params.type or "barrier"
        results.blockTypes = params.blocks or {"projectile"}
        results.manaLinked = params.manaLinked or false
        results.reflect = params.reflect or false
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

-- Function to validate spell schema
local function validateSpell(spell, spellId)
    assert(spell.id, "Spell " .. spellId .. " missing required property: id")
    assert(spell.name, "Spell " .. spellId .. " missing required property: name")
    assert(spell.description, "Spell " .. spellId .. " missing required property: description")
    assert(spell.castTime, "Spell " .. spellId .. " missing required property: castTime")
    assert(type(spell.castTime) == "number", "Spell " .. spellId .. " castTime must be a number")
    
    -- Either cost must be a table or an array (empty cost is allowed)
    assert(type(spell.cost) == "table", "Spell " .. spellId .. " cost must be a table")
    
    -- Check attackType is valid
    if spell.attackType then
        local validTypes = {
            projectile = true,
            remote = true,
            zone = true,
            utility = true
        }
        assert(validTypes[spell.attackType], "Spell " .. spellId .. " has invalid attackType: " .. spell.attackType)
    end
    
    -- Check keywords are valid (if present)
    if spell.keywords then
        assert(type(spell.keywords) == "table", "Spell " .. spellId .. " keywords must be a table")
        for keyword, _ in pairs(spell.keywords) do
            assert(KeywordSystem.handlers[keyword], "Spell " .. spellId .. " has unimplemented keyword: " .. keyword)
        end
    end
    
    -- Check blockableBy (if present)
    if spell.blockableBy then
        assert(type(spell.blockableBy) == "table", "Spell " .. spellId .. " blockableBy must be a table")
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
                type = "barrier",  -- or "ward", "field"
                blocks = {"projectile", "zone"},
                manaLinked = true
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
    
    -- Process the parameters - evaluate dynamic functions
    local processedParams = {}
    for paramKey, paramValue in pairs(params) do
        if type(paramValue) == "function" then
            processedParams[paramKey] = paramValue(caster, target, slot)
        else
            processedParams[paramKey] = paramValue
        end
    end
    
    -- Store the original results for logging
    local resultsBefore = {}
    for k, v in pairs(results) do
        resultsBefore[k] = v
    end
    
    -- Process this keyword and get updated results
    local updatedResults = KeywordSystem.handlers[keyword](processedParams, caster, target, results)
    
    -- Log the keyword resolution
    logKeywordResolution(spellId, keyword, processedParams, updatedResults)
    
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

-- Enhanced spell resolution function with targeting support
KeywordSystem.resolveSpell = function(spell, caster, opponent, spellSlot, options)
    options = options or {}
    local debug = options.debug or false
    
    -- Validate spell before attempting to resolve
    validateSpell(spell, spell.id or "unknown")
    
    local results = {
        damage = 0,
        spellType = spell.attackType,
        targetingInfo = {}  -- Store targeting information for post-processing
    }
    
    if debug then
        print(string.format("[SPELL] Resolving spell: %s (cast by %s)", 
                         spell.name, caster.name))
    end
    
    -- Process each keyword in the spell
    if spell.keywords then
        for keyword, params in pairs(spell.keywords) do
            -- Determine targeting for this keyword
            local targetType = params.target or KeywordSystem.keywordTargets[keyword]
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
    
    -- Count number of effects in results (excluding utility fields)
    local effectCount = 0
    for k, _ in pairs(results) do
        -- Don't count utility fields or zero damage
        if k ~= "damage" or results.damage ~= 0 then
            if k ~= "spellType" and k ~= "targetingInfo" then
                effectCount = effectCount + 1
            end
        end
    end
    
    if debug then
        print(string.format("[SPELL] %s complete: damage=%s, effects=%d", 
                            spell.id, tostring(results.damage), effectCount))
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
    castTime = 2.0,
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = "fire",
            amount = 1
        }
    },
    vfx = "fire_conjure",
    blockableBy = {}  -- Unblockable
}

Spells.firebolt = {
    id = "firebolt",
    name = "Firebolt",
    description = "Quick ranged hit, more damage at FAR range",
    castTime = 5.0,
    attackType = "projectile",
    cost = {"fire", "any"},
    keywords = {
        damage = {
            amount = function(caster, target)
                -- Access shared range state from game state reference
                return caster.gameState.rangeState == "FAR" and 15 or 10
            end,
            type = "fire"
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
                return target.elevation == "GROUNDED" and 20 or 0
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
                for _, slot in ipairs(target.spellSlots) do
                    if slot.active then
                        activeSlots = activeSlots + 1
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
            duration = 5.0
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
    castTime = 2.0,
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = "moon",
            amount = 1
        }
    },
    vfx = "moon_conjure",
    blockableBy = {}  -- Unblockable
}

Spells.volatileconjuring = {
    id = "volatileconjuring",
    name = "Volatile Conjuring",
    description = "Creates a random mana token",
    attackType = "utility",
    castTime = 1.4,
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
                return target.elevation == "AERIAL" and 15 or 0
            end,
            type = "moon",
            conditional = "target.AERIAL"
        },
        ground = true,  -- Set target to GROUNDED
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
    cost = {"moon", "star"},
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
                for _, slot in ipairs(target.spellSlots) do
                    if slot.active and slot.isShield then
                        shieldCount = shieldCount + 1
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
                
                -- Count opponent's token types
                for _, token in ipairs(target.tokens or {}) do
                    if token.state == "FREE" then
                        tokenCounts[token.type] = (tokenCounts[token.type] or 0) + 1
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
                if target.elevation == "AERIAL" then
                    baseDamage = baseDamage + 4
                end
                
                -- If in NEAR range, deal more damage
                if caster.gameState.rangeState == "NEAR" then
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