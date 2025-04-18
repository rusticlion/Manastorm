# Manastorm Codebase Dump
Generated: Fri Apr 18 09:46:27 CDT 2025

# Source Code

## ./conf.lua
```lua
-- Configuration
function love.conf(t)
    t.title = "Manastorm - Wizard Duel"  -- The title of the window
    t.version = "11.4"                    -- The LÖVE version this game was made for
    
    -- Base design resolution
    t.window.width = 800
    t.window.height = 600
    
    -- Allow high DPI mode on supported displays (macOS, etc)
    t.window.highdpi = true
    
    -- Make window resizable
    t.window.resizable = true
    
    -- Graphics settings
    t.window.vsync = 1                    -- Vertical sync (1 = enabled)
    t.window.msaa = 0                     -- Disable anti-aliasing to keep pixel art crisp
    
    -- For debugging
    t.console = true
    
    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = false
end```

## ./docs/keywords.lua
```lua
-- Keywords Documentation Generator
-- This file helps maintain up-to-date documentation for the keyword system

local Spells = require("spells")

local DocGenerator = {}

-- Function to get the default target type description for a keyword
local function getTargetTypeDescription(keyword)
    local targetType = Spells.keywordSystem.keywordTargets[keyword]
    local descriptions = {
        self = "Affects the caster",
        enemy = "Affects the opponent",
        pool_self = "Affects the caster's mana pool",
        pool_enemy = "Affects the opponent's mana pool",
        slot_self = "Affects the caster's spell slots",
        slot_enemy = "Affects the opponent's spell slots",
        global = "Affects the game state",
        none = "No specific target"
    }
    
    return descriptions[targetType] or "Unknown target type"
end

-- Generate markdown documentation for all available keywords
function DocGenerator.generateMarkdown()
    local output = "# Manastorm Spell Keyword Reference\n\n"
    output = output .. "This document provides a reference for all available keywords in the Manastorm spell system.\n\n"
    
    -- Get keyword info organized by category
    local keywordsByCategory = Spells.keywordSystem.getKeywordHelp("byCategory")
    
    -- Table of contents
    output = output .. "## Contents\n\n"
    for categoryKey, category in pairs(keywordsByCategory) do
        output = output .. "- [" .. category.name .. "](#" .. string.lower(category.name:gsub("%s+", "-")) .. ")\n"
    end
    output = output .. "\n\n"
    
    -- Generate sections for each category
    for categoryKey, category in pairs(keywordsByCategory) do
        output = output .. "## " .. category.name .. "\n\n"
        
        for _, keyword in ipairs(category.keywords) do
            output = output .. "### " .. keyword.name .. "\n\n"
            output = output .. keyword.description .. "\n\n"
            output = output .. "**Default targeting:** " .. getTargetTypeDescription(keyword.name) .. "\n\n"
            output = output .. "**Example usage:**\n\n"
            output = output .. "```lua\n" .. keyword.example .. "\n```\n\n"
            
            -- Add targeting example if appropriate
            if Spells.keywordSystem.keywordTargets[keyword.name] then
                output = output .. "**Custom targeting example:**\n\n"
                output = output .. "```lua\n" .. keyword.name .. " = {\n"
                output = output .. "    -- Parameters as above\n"
                output = output .. "    target = \"" .. Spells.keywordSystem.keywordTargets[keyword.name] .. "\"  -- Default target\n"
                output = output .. "    -- You can override with any of: \"self\", \"enemy\", \"pool_self\", \"pool_enemy\", \"slot_self\", \"slot_enemy\", \"global\", \"none\"\n"
                output = output .. "}\n```\n\n"
            end
        end
    end
    
    -- Add a section with sample spells
    output = output .. "## Sample Spells\n\n"
    output = output .. "These examples show how to combine multiple keywords to create complex spell effects.\n\n"
    
    -- Targeting section
    output = output .. "### About Targeting\n\n"
    output = output .. "Each keyword has a default target (shown in the keyword documentation). You can override this by specifying a `target` parameter in the keyword configuration.\n\n"
    output = output .. "Available target types:\n\n"
    output = output .. "| Target Type | Description |\n"
    output = output .. "|------------|-------------|\n"
    output = output .. "| `self` | Affects the caster |\n"
    output = output .. "| `enemy` | Affects the opponent |\n"
    output = output .. "| `pool_self` | Affects the caster's mana pool |\n"
    output = output .. "| `pool_enemy` | Affects the opponent's mana pool |\n"
    output = output .. "| `slot_self` | Affects the caster's spell slots |\n"
    output = output .. "| `slot_enemy` | Affects the opponent's spell slots |\n"
    output = output .. "| `global` | Affects the game state |\n"
    output = output .. "| `none` | No specific target |\n\n"
    
    -- Multi-target spell example
    output = output .. "### Arcane Reversal (Multi-Target Example)\n\n"
    output = output .. "```lua\nSpells.arcaneReversal = {\n"
    output = output .. "    id = \"arcanereversal\",\n"
    output = output .. "    name = \"Arcane Reversal\",\n"
    output = output .. "    description = \"A complex spell that manipulates mana, movement, and timing simultaneously\",\n"
    output = output .. "    attackType = \"remote\",\n"
    output = output .. "    castTime = 6.0,\n"
    output = output .. "    cost = {\"moon\", \"star\", \"force\", \"force\"},\n"
    output = output .. "    keywords = {\n"
    output = output .. "        -- Apply damage to enemy\n"
    output = output .. "        damage = {\n"
    output = output .. "            amount = function(caster, target)\n"
    output = output .. "                -- More damage if enemy has active shields\n"
    output = output .. "                local shieldCount = 0\n"
    output = output .. "                for _, slot in ipairs(target.spellSlots) do\n"
    output = output .. "                    if slot.active and slot.isShield then\n"
    output = output .. "                        shieldCount = shieldCount + 1\n"
    output = output .. "                    end\n"
    output = output .. "                end\n"
    output = output .. "                return 8 + (shieldCount * 4)  -- 8 base + 4 per shield\n"
    output = output .. "            end,\n"
    output = output .. "            type = \"star\",\n"
    output = output .. "            target = \"ENEMY\"  -- Explicit targeting\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Move self to opposite range\n"
    output = output .. "        rangeShift = {\n"
    output = output .. "            position = function(caster, target)\n"
    output = output .. "                return caster.gameState.rangeState == \"NEAR\" and \"FAR\" or \"NEAR\"\n"
    output = output .. "            end,\n"
    output = output .. "            target = \"SELF\"  -- Different target from damage\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Lock opponent's mana tokens\n"
    output = output .. "        lock = {\n"
    output = output .. "            duration = 4.0,\n"
    output = output .. "            target = \"POOL_ENEMY\"  -- Target opponent's pool\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Add tokens to own pool\n"
    output = output .. "        conjure = {\n"
    output = output .. "            token = \"force\",\n"
    output = output .. "            amount = 1,\n"
    output = output .. "            target = \"POOL_SELF\"  -- Target own pool\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Accelerate own next spell\n"
    output = output .. "        accelerate = {\n"
    output = output .. "            amount = 2.0,\n"
    output = output .. "            slot = 1,  -- First slot\n"
    output = output .. "            target = \"SLOT_SELF\"  -- Target own slot\n"
    output = output .. "        }\n"
    output = output .. "    },\n"
    output = output .. "    vfx = \"arcane_reversal\",\n"
    output = output .. "    blockableBy = {\"ward\", \"field\"}\n"
    output = output .. "}\n```\n\n"
    
    -- Fireball example
    output = output .. "### Fireball\n\n"
    output = output .. "```lua\nSpells.fireball = {\n"
    output = output .. "    id = \"fireball\",\n"
    output = output .. "    name = \"Fireball\",\n"
    output = output .. "    description = \"Launches a ball of fire that deals heavy damage\",\n"
    output = output .. "    attackType = \"projectile\",\n"
    output = output .. "    castTime = 4.0,\n"
    output = output .. "    cost = {\"fire\", \"fire\", \"force\"},\n"
    output = output .. "    keywords = {\n"
    output = output .. "        damage = {\n"
    output = output .. "            amount = function(caster, target)\n"
    output = output .. "                -- More damage at FAR range\n"
    output = output .. "                return caster.gameState.rangeState == \"FAR\" and 18 or 12\n"
    output = output .. "            end,\n"
    output = output .. "            type = \"fire\"\n"
    output = output .. "            -- No target specified, uses default: ENEMY\n"
    output = output .. "        },\n"
    output = output .. "        -- Add AOE effect if cast from AERIAL\n"
    output = output .. "        zoneMulti = function(caster, target)\n"
    output = output .. "            return caster.elevation == \"AERIAL\"\n"
    output = output .. "        end\n"
    output = output .. "    },\n"
    output = output .. "    vfx = \"fireball\",\n"
    output = output .. "    sfx = \"explosion\",\n"
    output = output .. "    blockableBy = {\"barrier\"}\n"
    output = output .. "}\n```\n\n"
    
    return output
end

-- Generate a documentation file
function DocGenerator.writeDocumentation(outputPath)
    outputPath = outputPath or "/Users/russell/Manastorm/docs/KEYWORDS.md"
    
    local markdown = DocGenerator.generateMarkdown()
    
    local file = io.open(outputPath, "w")
    if file then
        file:write(markdown)
        file:close()
        print("Keyword documentation written to: " .. outputPath)
        return true
    else
        print("Error: Could not open file for writing: " .. outputPath)
        return false
    end
end

-- Execute documentation generation if this file is run directly
if not ... then
    DocGenerator.writeDocumentation()
end

return DocGenerator```

## ./keywords.lua
```lua
-- keywords.lua
-- Defines all keywords and their behaviors for the spell system

local Keywords = {}

-- Keyword categories for organization
Keywords.categories = {
    DAMAGE = "Damage Effects",
    DOT = "Damage Over Time",
    TIMING = "Spell Timing",
    MOVEMENT = "Movement & Position",
    RESOURCE = "Resource Manipulation",
    TOKEN = "Token Manipulation",
    DEFENSE = "Defense Mechanisms",
    SPECIAL = "Special Effects",
    ZONE = "Zone Mechanics"
}

-- Target types for keywords
Keywords.targetTypes = {
    SELF = "self",               -- The caster
    ENEMY = "enemy",             -- The opponent
    SLOT_SELF = "slot_self",     -- Caster's spell slots
    SLOT_ENEMY = "slot_enemy",   -- Opponent's spell slots
    POOL_SELF = "pool_self",     -- Shared mana pool (from caster's perspective)
    POOL_ENEMY = "pool_enemy"    -- Shared mana pool (from opponent's perspective)
}

-- ===== Core Combat Keywords =====

-- damage: Deals direct damage to a target
Keywords.damage = {
    -- Behavior definition
    behavior = {
        dealsDamage = true,
        targetType = "ENEMY",
        category = "DAMAGE",
        
        -- Default parameters
        defaultAmount = 0,
        defaultType = "generic"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
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
            end
        else
            -- Static damage value
            results.damage = damageAmount
        end
        
        results.damageType = params.type
        return results
    end
}

-- burn: Applies damage over time effect
Keywords.burn = {
    -- Behavior definition
    behavior = {
        appliesStatusEffect = true,
        statusType = "burn",
        dealsDamageOverTime = true,
        targetType = "ENEMY",
        category = "DOT",
        
        -- Default parameters
        defaultDuration = 3.0,
        defaultTickDamage = 2,
        defaultTickInterval = 1.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.burnApplied = true
        results.burnDuration = params.duration or 3.0
        results.burnTickDamage = params.tickDamage or 2
        results.burnTickInterval = params.tickInterval or 1.0  -- Default to 1 second between ticks
        return results
    end
}

-- stagger: Interrupts a spell and prevents recasting for a duration
Keywords.stagger = {
    -- Behavior definition
    behavior = {
        interruptsSpell = true,
        preventsRecasting = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING",
        
        -- Default parameters
        defaultDuration = 3.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.stagger = true
        results.targetSlot = params.slot or 0
        results.staggerDuration = params.duration or 3.0
        return results
    end
}

-- ===== Movement & Positioning Keywords =====

-- elevate: Sets a wizard to AERIAL state
Keywords.elevate = {
    -- Behavior definition
    behavior = {
        setsElevationState = "AERIAL",
        hasDefaultDuration = true,
        targetType = "SELF",
        category = "MOVEMENT",
        
        -- Default parameters
        defaultDuration = 5.0,
        defaultVfx = "emberlift"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.setElevation = "AERIAL"
        results.elevationDuration = params.duration or 5.0
        -- Store the target that should receive this effect
        results.elevationTarget = params.target or "SELF" -- Default to SELF
        -- Store the visual effect to use
        results.elevationVfx = params.vfx or "emberlift"
        return results
    end
}

-- ground: Forces a wizard to GROUNDED state
Keywords.ground = {
    -- Behavior definition
    behavior = {
        setsElevationState = "GROUNDED",
        canBeConditional = true,
        targetType = "ENEMY",
        category = "MOVEMENT"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        -- Check if there's a conditional function
        if params.conditional and type(params.conditional) == "function" then
            -- Only apply grounding if the condition is met
            if params.conditional(caster, target) then
                results.setElevation = "GROUNDED"
                -- Store the target that should receive this effect
                results.elevationTarget = params.target or "ENEMY" -- Default to ENEMY
            end
        else
            -- No condition, apply grounding unconditionally
            results.setElevation = "GROUNDED"
            results.elevationTarget = params.target or "ENEMY" -- Default to ENEMY
        end
        
        return results
    end
}

-- rangeShift: Changes the range state (NEAR/FAR)
Keywords.rangeShift = {
    -- Behavior definition
    behavior = {
        setsRangeState = true,
        targetType = "SELF",
        category = "MOVEMENT",
        
        -- Default parameters
        defaultPosition = "NEAR" 
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.setPosition = params.position or "NEAR"
        return results
    end
}

-- forcePull: Forces opponent to move to caster's range
Keywords.forcePull = {
    -- Behavior definition
    behavior = {
        forcesOpponentPosition = true,
        targetType = "ENEMY",
        category = "MOVEMENT"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        -- Force opponent to move to caster's range
        results.forcePosition = true
        return results
    end
}

-- ===== Resource & Token Keywords =====

-- conjure: Creates new tokens in the shared mana pool
Keywords.conjure = {
    -- Behavior definition
    behavior = {
        addsTokensToSharedPool = true,
        targetType = "POOL_SELF", -- Indicates who gets credit for the conjuring, not a separate pool
        category = "RESOURCE",
        
        -- Default parameters
        defaultTokenType = "fire",
        defaultAmount = 1
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        local tokenType = params.token or "fire"
        local amount = params.amount or 1
        
        for i = 1, amount do
            local assetPath = "assets/sprites/" .. tokenType .. "-token.png"
            caster.manaPool:addToken(tokenType, assetPath)
        end
        
        return results
    end
}

-- dissipate: Removes tokens from the shared mana pool
Keywords.dissipate = {
    -- Behavior definition
    behavior = {
        removesTokensFromSharedPool = true,
        targetType = "POOL_ENEMY", -- Indicates which player is causing the removal, not separate pools
        category = "RESOURCE",
        
        -- Default parameters
        defaultTokenType = "any",
        defaultAmount = 1
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
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
                
                -- Stop once we've marked enough tokens
                if tokensFound >= amount then
                    break
                end
            end
        end
        
        results.tokensDestroyed = tokensFound
        
        return results
    end
}

-- tokenShift: Changes token types in the shared mana pool
Keywords.tokenShift = {
    -- Behavior definition
    behavior = {
        transformsTokensInSharedPool = true,
        targetType = "POOL_SELF", -- Indicates who initiates the transformation, not separate pools
        category = "RESOURCE",
        
        -- Default parameters
        defaultTokenType = "fire",
        defaultAmount = 1,
        supportedTypes = {"fire", "force", "moon", "nature", "star", "random"}
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
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
    end
}

-- lock: Locks tokens in the shared mana pool, preventing their use for a duration
Keywords.lock = {
    -- Behavior definition
    behavior = {
        locksTokensInSharedPool = true,
        hasDefaultDuration = true,
        targetType = "POOL_ENEMY", -- Indicates which tokens to target, not separate pools
        category = "TOKEN",
        
        -- Default parameters
        defaultDuration = 5.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.lockToken = true
        results.lockDuration = params.duration or 5.0
        return results
    end
}

-- ===== Cast Time Keywords =====

-- delay: Adds time to opponent's spell cast
Keywords.delay = {
    -- Behavior definition
    behavior = {
        increasesSpellCastTime = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING",
        
        -- Default parameters
        defaultDuration = 1.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.delayApplied = true
        results.targetSlot = params.slot or 0  -- 0 means random or auto-select
        results.delayAmount = params.duration or 1.0
        return results
    end
}

-- accelerate: Reduces cast time of a spell
Keywords.accelerate = {
    -- Behavior definition
    behavior = {
        reducesSpellCastTime = true,
        targetType = "SLOT_SELF",
        category = "TIMING",
        
        -- Default parameters
        defaultAmount = 1.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.accelerate = true
        results.targetSlot = params.slot or 0  -- 0 means self or current slot
        results.accelerateAmount = params.amount or 1.0
        return results
    end
}

-- dispel: Cancels a spell and returns mana to the pool
Keywords.dispel = {
    -- Behavior definition
    behavior = {
        cancelsSpell = true,
        returnsManaToPool = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.dispel = true
        results.targetSlot = params.slot or 0  -- 0 means random active slot
        return results
    end
}

-- disjoint: Cancels a spell and destroys its mana
Keywords.disjoint = {
    -- Behavior definition
    behavior = {
        cancelsSpell = true,
        destroysMana = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.disjoint = true
        results.targetSlot = params.slot or 0
        return results
    end
}

-- freeze: Pauses a spell's progress for a duration
Keywords.freeze = {
    -- Behavior definition
    behavior = {
        pausesSpellProgress = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING",
        
        -- Default parameters
        defaultSlot = 2,  -- Default to middle slot
        defaultDuration = 2.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.freezeApplied = true
        results.targetSlot = params.slot or 2  -- Default to middle slot
        results.freezeDuration = params.duration or 2.0
        return results
    end
}

-- ===== Defense Keywords =====

-- block: Creates a shield to block specific attack types
Keywords.block = {
    -- Behavior definition
    behavior = {
        createsShield = true,
        targetType = "SELF",
        category = "DEFENSE",
        
        -- Shield properties
        shieldTypes = {"barrier", "ward", "field"},
        attackTypes = {"projectile", "remote", "zone"}
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        -- Create a structured shieldParams table within the results
        results.shieldParams = {
            createShield = true,
            defenseType = params.type or "barrier",
            blocksAttackTypes = params.blocks or {"projectile"},
            reflect = params.reflect or false
            -- Mana-linking is now the default, no need for a flag
        }
        
        return results
    end
}

-- reflect: Reflects incoming spells
Keywords.reflect = {
    -- Behavior definition
    behavior = {
        reflectsSpells = true,
        targetType = "SELF",
        category = "DEFENSE",
        
        -- Default parameters
        defaultDuration = 3.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.reflect = true
        results.reflectDuration = params.duration or 3.0
        return results
    end
}

-- ===== Special Effect Keywords =====

-- echo: Recasts the spell after a delay
Keywords.echo = {
    -- Behavior definition
    behavior = {
        recastsSpell = true,
        targetType = "SLOT_SELF",
        category = "SPECIAL",
        
        -- Default parameters
        defaultDelay = 2.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.echo = true
        results.echoDelay = params.delay or 2.0
        return results
    end
}

-- ===== Zone Keywords =====

-- zoneAnchor: Locks spell to cast-time range; fails if range changes
Keywords.zoneAnchor = {
    -- Behavior definition
    behavior = {
        anchorsSpellToConditions = true,
        targetType = "SELF",
        category = "ZONE",
        
        -- Parameters
        conditionTypes = {"range", "elevation"}
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
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
    end
}

-- zoneMulti: Makes zone affect both NEAR and FAR ranges
Keywords.zoneMulti = {
    -- Behavior definition
    behavior = {
        affectsBothRanges = true,
        targetType = "SELF",
        category = "ZONE"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.zoneMulti = true
        return results
    end
}

return Keywords```

## ./main.lua
```lua
-- Manastorm - Wizard Duel Game
-- Main game file

-- Load dependencies
local Wizard = require("wizard")
local ManaPool = require("manapool")
local UI = require("ui")
local VFX = require("vfx")
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local SpellsModule = require("spells")

-- Resolution settings
local baseWidth = 800    -- Base design resolution width
local baseHeight = 600   -- Base design resolution height
local scale = 1          -- Current scaling factor
local offsetX = 0        -- Horizontal offset for pillarboxing
local offsetY = 0        -- Vertical offset for letterboxing

-- Game state (globally accessible)
game = {
    wizards = {},
    manaPool = nil,
    font = nil,
    rangeState = "FAR",  -- Initial range state (NEAR or FAR)
    gameOver = false,
    winner = nil,
    winScreenTimer = 0,
    winScreenDuration = 5,  -- How long to show the win screen before auto-reset
    keywords = Keywords,
    spellCompiler = SpellCompiler,
    -- Resolution properties
    baseWidth = baseWidth,
    baseHeight = baseHeight,
    scale = scale,
    offsetX = offsetX,
    offsetY = offsetY
}

-- Define token types and images (globally available for consistency)
game.tokenTypes = {"fire", "force", "moon", "nature", "star"}
game.tokenImages = {
    fire = "assets/sprites/fire-token.png",
    force = "assets/sprites/force-token.png",
    moon = "assets/sprites/moon-token.png",
    nature = "assets/sprites/nature-token.png",
    star = "assets/sprites/star-token.png"
}

-- Helper function to add a random token to the mana pool
function game.addRandomToken()
    local randomType = game.tokenTypes[math.random(#game.tokenTypes)]
    game.manaPool:addToken(randomType, game.tokenImages[randomType])
    return randomType
end

-- Calculate the appropriate scaling for the current window size
function calculateScaling()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Calculate possible scales (use integer scaling for pixel art crispness)
    local scaleX = math.floor(windowWidth / baseWidth)
    local scaleY = math.floor(windowHeight / baseHeight)
    
    -- Use the smaller scale to fit the screen
    scale = math.max(1, math.min(scaleX, scaleY))
    
    -- Calculate offsets for centering (letterbox/pillarbox)
    offsetX = math.floor((windowWidth - baseWidth * scale) / 2)
    offsetY = math.floor((windowHeight - baseHeight * scale) / 2)
    
    -- Update global references
    game.scale = scale
    game.offsetX = offsetX
    game.offsetY = offsetY
    
    print("Window resized: " .. windowWidth .. "x" .. windowHeight .. " (scale: " .. scale .. ")")
end

-- Handle window resize events
function love.resize(width, height)
    calculateScaling()
end

-- Set up pixel art-friendly scaling
function configurePixelArtRendering()
    -- Disable texture filtering for crisp pixel art
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    
    -- Use integer scaling when possible
    love.graphics.setLineStyle("rough")
end

function love.load()
    -- Set up window
    love.window.setTitle("Manastorm - Wizard Duel")
    
    -- Configure pixel art rendering
    configurePixelArtRendering()
    
    -- Calculate initial scaling
    calculateScaling()
    
    -- Use system font for now
    game.font = love.graphics.newFont(16)  -- Default system font
    
    -- Set default font for normal rendering
    love.graphics.setFont(game.font)
    
    -- Create mana pool positioned above the battlefield, but below health bars
    game.manaPool = ManaPool.new(baseWidth/2, 120)  -- Positioned between health bars and wizards
    
    -- Create wizards - moved lower on screen to allow more room for aerial movement
    game.wizards[1] = Wizard.new("Ashgar", 200, 370, {255, 100, 100})
    game.wizards[2] = Wizard.new("Selene", 600, 370, {100, 100, 255})
    
    -- Set up references
    for _, wizard in ipairs(game.wizards) do
        wizard.manaPool = game.manaPool
        wizard.gameState = game
    end
    
    -- Initialize VFX system
    game.vfx = VFX.init()
    
    -- Precompile all spells for better performance
    print("Precompiling all spells...")
    
    -- Create a compiledSpells table and do the compilation ourselves
    game.compiledSpells = {}
    
    -- Get all spells from the SpellsModule
    local allSpells = SpellsModule.spells
    
    -- Compile each spell
    for id, spell in pairs(allSpells) do
        game.compiledSpells[id] = game.spellCompiler.compileSpell(spell, game.keywords)
        print("Compiled spell: " .. spell.name)
    end
    
    -- Count compiled spells
    local count = 0
    for _ in pairs(game.compiledSpells) do
        count = count + 1
    end
    
    print("Precompiled " .. count .. " spells")
    
    -- Create custom shield spells just for hotkeys
    -- These are complete, independent spell definitions
    game.customSpells = {}
    
    -- Define Moon Ward with minimal dependencies
    game.customSpells.moonWard = {
        id = "customMoonWard",
        name = "Moon Ward",
        description = "A mystical ward that blocks projectiles and remotes",
        attackType = "utility",
        castTime = 4.5,
        cost = {"moon", "moon"},
        keywords = {
            block = {
                type = "ward",
                blocks = {"projectile", "remote"},
                manaLinked = true
            }
        },
        vfx = "moon_ward",
        sfx = "shield_up",
        blockableBy = {}
    }
    
    -- Define Mirror Shield with minimal dependencies
    game.customSpells.mirrorShield = {
        id = "customMirrorShield",
        name = "Mirror Shield",
        description = "A reflective barrier that returns damage to attackers",
        attackType = "utility",
        castTime = 5.0,
        cost = {"moon", "moon", "star"},
        keywords = {
            block = {
                type = "barrier",
                blocks = {"projectile", "zone"},
                manaLinked = false,
                reflect = true,
                hitPoints = 3
            }
        },
        vfx = "mirror_shield",
        sfx = "crystal_ring",
        blockableBy = {}
    }
    
    -- Compile custom spells too
    for id, spell in pairs(game.customSpells) do
        game.compiledSpells[id] = game.spellCompiler.compileSpell(spell, game.keywords)
        print("Compiled custom spell: " .. spell.name)
    end
    
    -- Initialize mana pool with a single random token to start
    local tokenType = game.addRandomToken()
    
    -- Log which token was added
    print("Starting the game with a single " .. tokenType .. " token")
end

-- Reset the game
function resetGame()
    -- Reset game state
    game.gameOver = false
    game.winner = nil
    game.winScreenTimer = 0
    
    -- Reset wizards
    for _, wizard in ipairs(game.wizards) do
        wizard.health = 100
        wizard.elevation = "GROUNDED"
        wizard.elevationTimer = 0
        wizard.stunTimer = 0
        
        -- Reset spell slots
        for i = 1, 3 do
            wizard.spellSlots[i] = {
                active = false,
                progress = 0,
                spellType = nil,
                castTime = 0,
                tokens = {},
                isShield = false,
                defenseType = nil,
                shieldStrength = 0,
                blocksAttackTypes = nil
            }
        end
        
        -- Reset status effects
        wizard.statusEffects.burn.active = false
        wizard.statusEffects.burn.duration = 0
        wizard.statusEffects.burn.tickDamage = 0
        wizard.statusEffects.burn.tickInterval = 1.0
        wizard.statusEffects.burn.elapsed = 0
        wizard.statusEffects.burn.totalTime = 0
        
        -- Reset blockers
        for blockType in pairs(wizard.blockers) do
            wizard.blockers[blockType] = 0
        end
        
        -- Reset spell keying
        wizard.activeKeys = {[1] = false, [2] = false, [3] = false}
        wizard.currentKeyedSpell = nil
    end
    
    -- Reset range state
    game.rangeState = "FAR"
    
    -- Clear mana pool and add a single token to start
    game.manaPool:clear()
    local tokenType = game.addRandomToken()
    
    -- Reset health display animation state
    for i = 1, 2 do
        local display = UI.healthDisplay["player" .. i]
        display.currentHealth = 100
        display.targetHealth = 100
        display.pendingDamage = 0
        display.lastDamageTime = 0
    end
    
    print("Game reset! Starting with a single " .. tokenType .. " token")
end

-- Handle keybindings for window size adjustments
function love.keypressed(key, scancode, isrepeat)
    -- Scale adjustments
    if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
        if key == "1" then
            love.window.setMode(baseWidth, baseHeight)
            calculateScaling()
        elseif key == "2" then
            love.window.setMode(baseWidth * 2, baseHeight * 2)
            calculateScaling()
        elseif key == "3" then
            love.window.setMode(baseWidth * 3, baseHeight * 3)
            calculateScaling()
        elseif key == "f" then
            love.window.setFullscreen(not love.window.getFullscreen())
            calculateScaling()
        end
    end
end

function love.update(dt)
    -- Check for win condition before updates
    if game.gameOver then
        -- Update win screen timer
        game.winScreenTimer = game.winScreenTimer + dt
        
        -- Auto-reset after duration
        if game.winScreenTimer >= game.winScreenDuration then
            resetGame()
        end
        
        -- Still update VFX system for visual effects
        game.vfx.update(dt)
        return
    end
    
    -- Check if any wizard's health has reached zero
    for i, wizard in ipairs(game.wizards) do
        if wizard.health <= 0 then
            game.gameOver = true
            game.winner = 3 - i  -- Winner is the other wizard (3-1=2, 3-2=1)
            game.winScreenTimer = 0
            
            -- Create victory VFX around the winner
            local winner = game.wizards[game.winner]
            for j = 1, 15 do
                local angle = math.random() * math.pi * 2
                local distance = math.random(40, 100)
                local x = winner.x + math.cos(angle) * distance
                local y = winner.y + math.sin(angle) * distance
                
                -- Determine winner's color for effects
                local color
                if game.winner == 1 then -- Ashgar
                    color = {1.0, 0.5, 0.2, 0.9} -- Fire-like
                else -- Selene
                    color = {0.3, 0.3, 1.0, 0.9} -- Moon-like
                end
                
                -- Create sparkle effect with delay
                game.vfx.createEffect("impact", x, y, nil, nil, {
                    duration = 0.8 + math.random() * 0.5,
                    color = color,
                    particleCount = 5,
                    radius = 15,
                    delay = j * 0.1
                })
            end
            
            print(winner.name .. " wins!")
            break
        end
    end
    
    -- Update wizards
    for _, wizard in ipairs(game.wizards) do
        wizard:update(dt)
    end
    
    -- Update mana pool
    game.manaPool:update(dt)
    
    -- Update VFX system
    game.vfx.update(dt)
    
    -- Update animated health displays
    UI.updateHealthDisplays(dt, game.wizards)
end

function love.draw()
    -- Clear entire screen to black first (for letterboxing/pillarboxing)
    love.graphics.clear(0, 0, 0, 1)
    
    -- Setup scaling transform
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)
    
    -- Clear game area with game background color
    love.graphics.setColor(20/255, 20/255, 40/255, 1)
    love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    
    -- Draw range state indicator (NEAR/FAR)
    drawRangeIndicator()
    
    -- Draw mana pool
    game.manaPool:draw()
    
    -- Draw wizards
    for _, wizard in ipairs(game.wizards) do
        wizard:draw()
    end
    
    -- Draw visual effects layer (between wizards and UI)
    game.vfx.draw()
    
    -- Draw UI (health bars and wizard names are handled in UI.drawSpellInfo)
    love.graphics.setColor(1, 1, 1)
    
    -- Always draw spellbook components
    UI.drawSpellbookButtons()
    
    -- Draw spell info (health bars, etc.)
    UI.drawSpellInfo(game.wizards)
    
    -- Draw win screen if game is over
    if game.gameOver and game.winner then
        drawWinScreen()
    end
    
    -- Debug info only when debug key is pressed
    if love.keyboard.isDown("`") then
        UI.drawHelpText(game.font)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        
        -- Show scaling info in debug mode
        love.graphics.print("Scale: " .. scale .. "x (" .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight() .. ")", 10, 30)
    else
        -- Always show a small hint about the debug key
        love.graphics.setColor(0.6, 0.6, 0.6, 0.4)
        love.graphics.print("Press ` for debug controls", 10, baseHeight - 20)
    end
    
    -- End scaling transform
    love.graphics.pop()
    
    -- Draw letterbox/pillarbox borders if needed
    if offsetX > 0 or offsetY > 0 then
        love.graphics.setColor(0, 0, 0)
        -- Top letterbox
        if offsetY > 0 then
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), offsetY)
            love.graphics.rectangle("fill", 0, love.graphics.getHeight() - offsetY, love.graphics.getWidth(), offsetY)
        end
        -- Left/right pillarbox
        if offsetX > 0 then
            love.graphics.rectangle("fill", 0, 0, offsetX, love.graphics.getHeight())
            love.graphics.rectangle("fill", love.graphics.getWidth() - offsetX, 0, offsetX, love.graphics.getHeight())
        end
    end
end

-- Helper function to convert real screen coordinates to virtual (scaled) coordinates
function screenToGameCoords(x, y)
    if not x or not y then return nil, nil end
    
    -- Adjust for offset and scale
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    
    -- Check if the point is outside the game area
    if virtualX < 0 or virtualX > baseWidth or virtualY < 0 or virtualY > baseHeight then
        return nil, nil  -- Out of bounds
    end
    
    return virtualX, virtualY
end

-- Override love.mouse.getPosition for seamless integration
local original_getPosition = love.mouse.getPosition
love.mouse.getPosition = function()
    local rx, ry = original_getPosition()
    local vx, vy = screenToGameCoords(rx, ry)
    return vx or 0, vy or 0
end

-- Draw the win screen
function drawWinScreen()
    local screenWidth = baseWidth
    local screenHeight = baseHeight
    local winner = game.wizards[game.winner]
    
    -- Fade in effect
    local fadeProgress = math.min(game.winScreenTimer / 0.5, 1.0)
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7 * fadeProgress)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Determine winner's color scheme
    local winnerColor
    if game.winner == 1 then -- Ashgar
        winnerColor = {1.0, 0.4, 0.2} -- Fire-like
    else -- Selene
        winnerColor = {0.4, 0.4, 1.0} -- Moon-like
    end
    
    -- Calculate animation progress for text
    local textProgress = math.min(math.max(game.winScreenTimer - 0.5, 0) / 0.5, 1.0)
    local textScale = 1 + (1 - textProgress) * 3 -- Text starts larger and shrinks to normal size
    local textY = screenHeight / 2 - 100
    
    -- Draw winner text with animated scale
    love.graphics.setColor(winnerColor[1], winnerColor[2], winnerColor[3], textProgress)
    
    -- Main victory text
    local victoryText = winner.name .. " WINS!"
    local victoryTextWidth = game.font:getWidth(victoryText) * textScale * 3
    love.graphics.print(
        victoryText, 
        screenWidth / 2 - victoryTextWidth / 2, 
        textY,
        0, -- rotation
        textScale * 3, -- scale X
        textScale * 3  -- scale Y
    )
    
    -- Only show restart instructions after initial animation
    if game.winScreenTimer > 1.0 then
        -- Calculate pulse effect
        local pulse = 0.7 + 0.3 * math.sin(game.winScreenTimer * 4)
        
        -- Draw restart instruction with pulse effect
        local restartText = "Press [SPACE] to play again"
        local restartTextWidth = game.font:getWidth(restartText) * 1.5
        
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.print(
            restartText,
            screenWidth / 2 - restartTextWidth / 2,
            textY + 150,
            0, -- rotation
            1.5, -- scale X
            1.5  -- scale Y
        )
        
        -- Show auto-restart countdown
        local remainingTime = math.ceil(game.winScreenDuration - game.winScreenTimer)
        local countdownText = "Auto-restart in " .. remainingTime .. "..."
        local countdownTextWidth = game.font:getWidth(countdownText)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
        love.graphics.print(
            countdownText,
            screenWidth / 2 - countdownTextWidth / 2,
            textY + 200
        )
    end
    
    -- Draw some victory effect particles
    for i = 1, 3 do
        if math.random() < 0.3 then
            local x = math.random(screenWidth)
            local y = math.random(screenHeight)
            local size = math.random(10, 30)
            
            love.graphics.setColor(
                winnerColor[1], 
                winnerColor[2], 
                winnerColor[3], 
                math.random() * 0.3
            )
            love.graphics.circle("fill", x, y, size)
        end
    end
end

-- Function to draw the range indicator for NEAR/FAR states
function drawRangeIndicator()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX = screenWidth / 2
    
    -- Only draw a subtle central line, without the text indicators
    -- The wizard positions themselves will communicate NEAR/FAR state
    
    -- Different visual style based on range state
    if game.rangeState == "NEAR" then
        -- For NEAR state, draw a more vibrant, energetic line
        love.graphics.setColor(0.5, 0.5, 0.9, 0.4)
        
        -- Draw main line
        love.graphics.setLineWidth(1.5)
        love.graphics.line(centerX, 200, centerX, screenHeight - 100)
        
        -- Add a subtle energetic glow/pulse
        for i = 1, 5 do
            local pulseWidth = 3 + math.sin(love.timer.getTime() * 2.5) * 2
            local alpha = 0.12 - (i * 0.02)
            love.graphics.setColor(0.5, 0.5, 0.9, alpha)
            love.graphics.setLineWidth(pulseWidth * i)
            love.graphics.line(centerX, 200, centerX, screenHeight - 100)
        end
        love.graphics.setLineWidth(1)
    else
        -- For FAR state, draw a more distant, faded line
        love.graphics.setColor(0.3, 0.3, 0.7, 0.3)
        
        -- Draw main line with slight wave effect
        local segments = 12
        local segmentHeight = (screenHeight - 300) / segments
        local points = {}
        
        for i = 0, segments do
            local y = 200 + i * segmentHeight
            local wobble = math.sin(love.timer.getTime() + i * 0.3) * 1.5
            table.insert(points, centerX + wobble)
            table.insert(points, y)
        end
        
        love.graphics.setLineWidth(1)
        love.graphics.line(points)
        
        -- Add very subtle horizontal distortion lines
        for i = 1, 5 do
            local y = 200 + (i * (screenHeight - 300) / 6)
            local width = 15 + math.sin(love.timer.getTime() * 0.7 + i) * 5
            local alpha = 0.05
            love.graphics.setColor(0.3, 0.3, 0.7, alpha)
            love.graphics.setLineWidth(0.5)
            love.graphics.line(centerX - width, y, centerX + width, y)
        end
    end
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

function love.keypressed(key)
    -- Debug all key presses to isolate input issues
    print("DEBUG: Key pressed: '" .. key .. "'")
    
    -- Check for game over state first
    if game.gameOver then
        -- Reset game on space bar press during game over
        if key == "space" then
            resetGame()
        end
        return
    end
    
    if key == "escape" then
        love.event.quit()
    end
    
    -- Player 1 (Ashgar) key handling for spell combinations
    if key == "q" then
        game.wizards[1]:keySpell(1, true)
    elseif key == "w" then
        game.wizards[1]:keySpell(2, true)
    elseif key == "e" then
        game.wizards[1]:keySpell(3, true)
    elseif key == "f" then
        -- Cast key for Player 1
        game.wizards[1]:castKeyedSpell()
    elseif key == "g" then
        -- Free key for Player 1
        game.wizards[1]:freeAllSpells()
    elseif key == "b" then
        -- Toggle spellbook for Player 1
        UI.toggleSpellbook(1)
    end
    
    -- Player 2 (Selene) key handling for spell combinations
    if key == "i" then
        game.wizards[2]:keySpell(1, true)
    elseif key == "o" then
        game.wizards[2]:keySpell(2, true)
    elseif key == "p" then
        game.wizards[2]:keySpell(3, true)
    elseif key == "j" then
        -- Cast key for Player 2
        game.wizards[2]:castKeyedSpell()
    elseif key == "h" then
        -- Free key for Player 2
        game.wizards[2]:freeAllSpells()
    elseif key == "m" then
        -- Toggle spellbook for Player 2
        UI.toggleSpellbook(2)
    end
    
    -- Debug: Add a single random token with T key
    if key == "t" then
        local tokenType = game.addRandomToken()
        print("Added a " .. tokenType .. " token to the mana pool")
    end
    
    -- Debug: Add specific tokens for testing shield spells
    if key == "z" then
        local tokenType = "moon"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    elseif key == "x" then
        local tokenType = "star"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    elseif key == "c" then
        local tokenType = "force"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    end
    
    -- Direct keys for casting shield spells, bypassing keying and issue in cast key "l"
    if key == "1" then
        -- Force cast Moon Ward for Selene
        print("DEBUG: Directly casting Moon Ward for Selene")
        local result = game.wizards[2]:queueSpell(game.customSpells.moonWard)
        print("DEBUG: Moon Ward cast result: " .. tostring(result))
    elseif key == "2" then
        -- Force cast Mirror Shield for Selene
        print("DEBUG: Directly casting Mirror Shield for Selene")
        local result = game.wizards[2]:queueSpell(game.customSpells.mirrorShield)
        print("DEBUG: Mirror Shield cast result: " .. tostring(result))
    end
    
    -- Debug: Position/elevation test controls
    -- Toggle range state with R key
    if key == "r" then
        if game.rangeState == "NEAR" then
            game.rangeState = "FAR"
        else
            game.rangeState = "NEAR"
        end
        print("Range state toggled to: " .. game.rangeState)
    end
    
    -- Toggle Ashgar's elevation with A key
    if key == "a" then
        if game.wizards[1].elevation == "GROUNDED" then
            game.wizards[1].elevation = "AERIAL"
        else
            game.wizards[1].elevation = "GROUNDED"
        end
        print("Ashgar elevation toggled to: " .. game.wizards[1].elevation)
    end
    
    -- Toggle Selene's elevation with S key
    if key == "s" then
        if game.wizards[2].elevation == "GROUNDED" then
            game.wizards[2].elevation = "AERIAL"
        else
            game.wizards[2].elevation = "GROUNDED"
        end
        print("Selene elevation toggled to: " .. game.wizards[2].elevation)
    end
    
    -- Debug: Test VFX effects with number keys
    if key == "1" then
        -- Test firebolt effect
        game.vfx.createEffect("firebolt", game.wizards[1].x, game.wizards[1].y, game.wizards[2].x, game.wizards[2].y)
        print("Testing firebolt VFX")
    elseif key == "2" then
        -- Test meteor effect 
        game.vfx.createEffect("meteor", game.wizards[2].x, game.wizards[2].y - 100, game.wizards[2].x, game.wizards[2].y)
        print("Testing meteor VFX")
    elseif key == "3" then
        -- Test mist veil effect
        game.vfx.createEffect("mistveil", game.wizards[1].x, game.wizards[1].y)
        print("Testing mist veil VFX")
    elseif key == "4" then
        -- Test emberlift effect
        game.vfx.createEffect("emberlift", game.wizards[2].x, game.wizards[2].y)
        print("Testing emberlift VFX") 
    elseif key == "5" then
        -- Test full moon beam effect
        game.vfx.createEffect("fullmoonbeam", game.wizards[2].x, game.wizards[2].y, game.wizards[1].x, game.wizards[1].y)
        print("Testing full moon beam VFX")
    elseif key == "6" then
        -- Test conjure fire effect
        game.vfx.createEffect("conjurefire", game.wizards[1].x, game.wizards[1].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing conjure fire VFX")
    elseif key == "7" then
        -- Test conjure moonlight effect
        game.vfx.createEffect("conjuremoonlight", game.wizards[2].x, game.wizards[2].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing conjure moonlight VFX")
    elseif key == "8" then
        -- Test volatile conjuring effect
        game.vfx.createEffect("volatileconjuring", game.wizards[1].x, game.wizards[1].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing volatile conjuring VFX")
    end
end

-- Add key release handling to clear key combinations
function love.keyreleased(key)
    -- Player 1 key releases
    if key == "q" then
        game.wizards[1]:keySpell(1, false)
    elseif key == "w" then
        game.wizards[1]:keySpell(2, false)
    elseif key == "e" then
        game.wizards[1]:keySpell(3, false)
    end
    
    -- Player 2 key releases
    if key == "i" then
        game.wizards[2]:keySpell(1, false)
    elseif key == "o" then
        game.wizards[2]:keySpell(2, false)
    elseif key == "p" then
        game.wizards[2]:keySpell(3, false)
    end
end```

## ./manapool.lua
```lua
-- ManaPool class
-- Represents the shared pool of mana tokens in the center

local ManaPool = {}
ManaPool.__index = ManaPool

function ManaPool.new(x, y)
    local self = setmetatable({}, ManaPool)
    
    self.x = x
    self.y = y
    self.tokens = {}  -- List of mana tokens
    
    -- Make elliptical shape even flatter and wider
    self.radiusX = 280  -- Wider horizontal radius
    self.radiusY = 60   -- Flatter vertical radius
    
    -- Define orbital rings (valences) for tokens to follow
    self.valences = {
        {radiusX = 180, radiusY = 25, baseSpeed = 0.35},  -- Inner valence
        {radiusX = 230, radiusY = 40, baseSpeed = 0.25},  -- Middle valence
        {radiusX = 280, radiusY = 55, baseSpeed = 0.18}   -- Outer valence
    }
    
    -- Chance for a token to switch valences
    self.valenceJumpChance = 0.002  -- Per frame chance of switching
    
    -- Load lock overlay image
    self.lockOverlay = love.graphics.newImage("assets/sprites/token-lock.png")
    
    return self
end

-- Clear all tokens from the mana pool
function ManaPool:clear()
    self.tokens = {}
    self.reservedTokens = {}
end

function ManaPool:addToken(tokenType, imagePath)
    -- Pick a random valence for the token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    
    -- Calculate a random angle along the valence
    local angle = math.random() * math.pi * 2
    
    -- Calculate position based on elliptical path
    local x = self.x + math.cos(angle) * valence.radiusX
    local y = self.y + math.sin(angle) * valence.radiusY
    
    -- Generate slight positional variation to avoid tokens stacking perfectly
    local variationX = math.random(-5, 5)
    local variationY = math.random(-3, 3)
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Create a new token with valence-based properties
    local token = {
        type = tokenType,
        image = love.graphics.newImage(imagePath),
        x = x + variationX,
        y = y + variationY,
        state = "FREE",  -- FREE, CHANNELED, SHIELDING, LOCKED, DESTROYED
        lockDuration = 0, -- Duration for how long a token remains locked
        
        -- Valence-based orbit properties
        valenceIndex = valenceIndex,
        orbitAngle = angle,
        -- Speed varies by token but influenced by valence's base speed
        orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction,
        
        -- Visual effects
        pulsePhase = math.random() * math.pi * 2,
        pulseSpeed = 2 + math.random() * 3,
        rotAngle = math.random() * math.pi * 2,
        rotSpeed = math.random(-2, 2) * 0.5, -- Varying rotation speeds
        
        -- Valence jump timer (occasional orbit changes)
        valenceJumpTimer = 2 + math.random() * 8, -- Random time until possible valence change
        
        -- Valence transition properties (for smooth valence changes)
        inValenceTransition = false,
        valenceTransitionTime = 0,
        valenceTransitionDuration = 0.8,
        sourceValenceIndex = valenceIndex,
        targetValenceIndex = valenceIndex,
        sourceRadiusX = valence.radiusX,
        sourceRadiusY = valence.radiusY,
        targetRadiusX = valence.radiusX,
        targetRadiusY = valence.radiusY,
        currentRadiusX = valence.radiusX,
        currentRadiusY = valence.radiusY,
        
        -- Visual effect for locked state
        lockPulse = 0, -- For pulsing animation when locked
        
        -- Size variation for visual interest
        scale = 0.85 + math.random() * 0.3, -- Slight size variation
        
        -- Depth/z-order variation
        zOrder = math.random(),  -- Used for layering tokens
        
        -- We've intentionally removed token repulsion to return to clean orbital motion
    }
    
    token.originalSpeed = token.orbitSpeed
    
    table.insert(self.tokens, token)
end

-- Removed token repulsion system, reverting to pure orbital motion

function ManaPool:update(dt)
    -- Check for destroyed tokens and remove them from the list
    for i = #self.tokens, 1, -1 do
        local token = self.tokens[i]
        if token.state == "DESTROYED" then
            -- Create an explosion/dissolution visual effect if we haven't already
            if not token.dissolving then
                token.dissolving = true
                token.dissolveTime = 0
                token.dissolveMaxTime = 0.8  -- Dissolution animation duration
                token.dissolveScale = token.scale or 1.0
                token.initialX = token.x
                token.initialY = token.y
                
                -- Create visual particle effects at the token's position
                if token.exploding ~= true then  -- Prevent duplicate explosion effects
                    token.exploding = true
                    
                    -- Get token color based on its type
                    local color = {1, 0.6, 0.2, 0.8}  -- Default orange
                    if token.type == "fire" then
                        color = {1, 0.3, 0.1, 0.8}
                    elseif token.type == "force" then
                        color = {1, 0.9, 0.3, 0.8}
                    elseif token.type == "moon" then
                        color = {0.8, 0.6, 1.0, 0.8}  -- Purple for lunar disjunction
                    elseif token.type == "nature" then
                        color = {0.2, 0.9, 0.1, 0.8}
                    elseif token.type == "star" then
                        color = {1, 0.8, 0.2, 0.8}
                    end
                    
                    -- Create destruction visual effect
                    if token.gameState and token.gameState.vfx then
                        -- Use game state VFX system if available
                        token.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                            duration = 0.7,
                            color = color,
                            particleCount = 15,
                            radius = 30
                        })
                    end
                end
            else
                -- Update dissolution animation
                token.dissolveTime = token.dissolveTime + dt
                
                -- When dissolution is complete, remove the token
                if token.dissolveTime >= token.dissolveMaxTime then
                    table.remove(self.tokens, i)
                end
            end
        end
    end
    
    -- Update token positions and states
    for _, token in ipairs(self.tokens) do
        -- Update token position based on state
        if token.state == "FREE" then
            -- Handle the transition period for newly returned tokens
            if token.inTransition then
                token.transitionTime = token.transitionTime + dt
                local transProgress = math.min(1, token.transitionTime / token.transitionDuration)
                
                -- Ease transition using a smooth curve
                transProgress = transProgress < 0.5 and 4 * transProgress * transProgress * transProgress 
                            or 1 - math.pow(-2 * transProgress + 2, 3) / 2
                
                -- During transition, gradually start orbital motion
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt * transProgress
                
                -- Check if transition is complete
                if token.transitionTime >= token.transitionDuration then
                    token.inTransition = false
                end
            else
                -- Normal FREE token behavior after transition
                -- Update orbit angle with variable speed
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt
                
                -- Update valence jump timer
                token.valenceJumpTimer = token.valenceJumpTimer - dt
                
                -- Chance to change valence when timer expires
                if token.valenceJumpTimer <= 0 then
                    token.valenceJumpTimer = 2 + math.random() * 8  -- Reset timer
                    
                    -- Random chance to jump to a different valence
                    if math.random() < self.valenceJumpChance * 100 then
                        -- Store current valence for interpolation
                        local oldValenceIndex = token.valenceIndex
                        local oldValence = self.valences[oldValenceIndex]
                        local newValenceIndex = oldValenceIndex
                        
                        -- Ensure we pick a different valence if more than one exists
                        if #self.valences > 1 then
                            while newValenceIndex == oldValenceIndex do
                                newValenceIndex = math.random(1, #self.valences)
                            end
                        end
                        
                        -- Start valence transition
                        local newValence = self.valences[newValenceIndex]
                        local direction = token.orbitSpeed > 0 and 1 or -1
                        
                        -- Set up transition parameters
                        token.inValenceTransition = true
                        token.valenceTransitionTime = 0
                        token.valenceTransitionDuration = 0.8  -- Time to transition between valences
                        token.sourceValenceIndex = oldValenceIndex
                        token.targetValenceIndex = newValenceIndex
                        token.sourceRadiusX = oldValence.radiusX
                        token.sourceRadiusY = oldValence.radiusY
                        token.targetRadiusX = newValence.radiusX
                        token.targetRadiusY = newValence.radiusY
                        
                        -- Update speed for new valence but maintain direction
                        token.orbitSpeed = newValence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                        token.originalSpeed = token.orbitSpeed
                    end
                end
                
                -- Handle valence transition if active
                if token.inValenceTransition then
                    token.valenceTransitionTime = token.valenceTransitionTime + dt
                    local progress = math.min(1, token.valenceTransitionTime / token.valenceTransitionDuration)
                    
                    -- Use easing function for smooth transition
                    progress = progress < 0.5 and 4 * progress * progress * progress 
                              or 1 - math.pow(-2 * progress + 2, 3) / 2
                    
                    -- Interpolate between source and target radiuses
                    token.currentRadiusX = token.sourceRadiusX + (token.targetRadiusX - token.sourceRadiusX) * progress
                    token.currentRadiusY = token.sourceRadiusY + (token.targetRadiusY - token.sourceRadiusY) * progress
                    
                    -- Check if transition is complete
                    if token.valenceTransitionTime >= token.valenceTransitionDuration then
                        token.inValenceTransition = false
                        token.valenceIndex = token.targetValenceIndex
                    end
                end
                
                -- Occasionally vary the speed slightly
                if math.random() < 0.01 then
                    local direction = token.orbitSpeed > 0 and 1 or -1
                    local valence = self.valences[token.valenceIndex]
                    local variation = 0.9 + math.random() * 0.2  -- Subtle variation
                    token.orbitSpeed = valence.baseSpeed * variation * direction
                end
            end
            
            -- Common behavior for all FREE tokens
            -- Update pulse phase
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            
            -- Calculate new position based on elliptical orbit - maintain perfect elliptical path
            if token.inValenceTransition then
                -- Use interpolated radii during transition
                token.x = self.x + math.cos(token.orbitAngle) * token.currentRadiusX
                token.y = self.y + math.sin(token.orbitAngle) * token.currentRadiusY
            else
                -- Use valence radii when not transitioning
                local valence = self.valences[token.valenceIndex]
                token.x = self.x + math.cos(token.orbitAngle) * valence.radiusX
                token.y = self.y + math.sin(token.orbitAngle) * valence.radiusY
            end
            
            -- Minimal wobble to maintain clean orbits but add slight visual interest
            local wobbleX = math.sin(token.pulsePhase * 0.7) * 2
            local wobbleY = math.cos(token.pulsePhase * 0.5) * 1
            token.x = token.x + wobbleX
            token.y = token.y + wobbleY
            
            -- Rotate token itself for visual interest, occasionally reversing direction
            token.rotAngle = token.rotAngle + token.rotSpeed * dt
            if math.random() < 0.002 then  -- Small chance to reverse rotation
                token.rotSpeed = -token.rotSpeed
            end
        elseif token.state == "CHANNELED" or token.state == "SHIELDING" then
            -- For channeled or shielding tokens, animate movement to/from their spell slot
            
            if token.animTime < token.animDuration then
                -- Token is still being animated to the spell slot
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                -- Start point
                local x0 = token.startX
                local y0 = token.startY
                
                -- End point (in the spell slot)
                local wizard = token.wizardOwner
                if wizard then
                    -- Calculate position in the 3D elliptical spell slot orbit
                    -- These values must match those in wizard.lua drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}  -- From bottom to top
                    local verticalRadii = {20, 25, 30}    -- From bottom to top
                    
                    local slotY = wizard.y + slotYOffsets[token.slotIndex]
                    local radiusX = horizontalRadii[token.slotIndex]
                    local radiusY = verticalRadii[token.slotIndex]
                    
                    local tokenCount = #wizard.spellSlots[token.slotIndex].tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = wizard.spellSlots[token.slotIndex].progress / 
                                       wizard.spellSlots[token.slotIndex].castTime * math.pi * 2 +
                                       anglePerToken * (token.tokenIndex - 1)
                    
                    -- Calculate position using elliptical projection
                    -- Apply the NEAR/FAR offset to the target position
                    local xOffset = 0
                    local isNear = wizard.gameState and wizard.gameState.rangeState == "NEAR"
                    
                    -- Apply the same NEAR/FAR offset logic as in the wizard's draw function
                    if wizard.name == "Ashgar" then -- Player 1 (left side)
                        xOffset = isNear and 60 or 0 -- Move right when NEAR
                    else -- Player 2 (right side)
                        xOffset = isNear and -60 or 0 -- Move left when NEAR
                    end
                    
                    local x3 = wizard.x + xOffset + math.cos(tokenAngle) * radiusX
                    local y3 = slotY + math.sin(tokenAngle) * radiusY
                    
                    -- Control points for bezier (creating an arc)
                    local midX = (x0 + x3) / 2
                    local midY = (y0 + y3) / 2 - 80  -- Arc height
                    
                    -- Quadratic bezier calculation
                    local t = progress
                    local u = 1 - t
                    token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                    token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                    
                    -- Update token rotation during flight
                    token.rotAngle = token.rotAngle + dt * 5  -- Spin faster during flight
                    
                    -- Store target position for the drawing function
                    token.targetX = x3
                    token.targetY = y3
                end
            else
                -- Animation complete - token is now in the spell orbit
                -- Token position will be updated by the wizard's drawSpellSlots function
                token.rotAngle = token.rotAngle + dt * 2  -- Continue spinning in orbit
            end
            
            -- Check if token is returning to the pool
            if token.returning then
                -- Token is being animated back to the mana pool
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                local x0 = token.startX
                local y0 = token.startY
                local x3 = self.x  -- Center of mana pool
                local y3 = self.y
                
                -- Control points for bezier (creating an arc)
                local midX = (x0 + x3) / 2
                local midY = (y0 + y3) / 2 - 50  -- Arc height
                
                -- Quadratic bezier calculation
                local t = progress
                local u = 1 - t
                token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                
                -- Update token rotation during flight - spin faster
                token.rotAngle = token.rotAngle + dt * 8
                
                -- Check if animation is complete
                if token.animTime >= token.animDuration then
                    -- Token has reached the pool - finalize its return and perform state transition
                    print(string.format("[MANAPOOL] Token return animation completed, finalizing state"))
                    self:finalizeTokenReturn(token)
                end
            end
            
            -- Update common pulse
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
        elseif token.state == "LOCKED" then
            -- For locked tokens, update the lock duration
            if token.lockDuration > 0 then
                token.lockDuration = token.lockDuration - dt
                
                -- Update lock pulse for animation
                token.lockPulse = (token.lockPulse + dt * 3) % (math.pi * 2)
                
                -- When lock duration expires, return to FREE state
                if token.lockDuration <= 0 then
                    token.state = "FREE"
                    print("A " .. token.type .. " token has been unlocked and returned to the mana pool")
                    
                    -- Reset position to center with some random velocity
                    token.x = self.x
                    token.y = self.y
                    -- Pick a random valence for the formerly locked token
                    token.valenceIndex = math.random(1, #self.valences)
                    token.orbitAngle = math.random() * math.pi * 2
                    -- Set direction and speed based on the valence
                    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
                    local valence = self.valences[token.valenceIndex]
                    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                    token.originalSpeed = token.orbitSpeed
                    -- No repulsion forces needed (system removed)
                end
            end
            
            -- Even locked tokens should move a bit, but more constrained
            token.x = token.x + math.sin(token.lockPulse) * 0.3
            token.y = token.y + math.cos(token.lockPulse) * 0.3
            
            -- Slight rotation
            token.rotAngle = token.rotAngle + token.rotSpeed * dt * 0.2
        end
        
        -- Update common properties for all tokens
        token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
    end
end

function ManaPool:draw()
    -- No longer drawing the pool background or valence rings
    -- The pool is now completely invisible, defined only by the positions of the tokens
    
    -- Sort tokens by z-order for better layering
    local sortedTokens = {}
    for i, token in ipairs(self.tokens) do
        table.insert(sortedTokens, {token = token, index = i})
    end
    
    table.sort(sortedTokens, function(a, b)
        return a.token.zOrder > b.token.zOrder
    end)
    
    -- Draw tokens in sorted order
    for _, tokenData in ipairs(sortedTokens) do
        local token = tokenData.token
        
        -- Draw a larger, more vibrant glow around the token based on its type
        local glowSize = 15 -- Larger glow radius
        local glowIntensity = 0.6  -- Stronger glow intensity
        
        -- Multiple glow layers for more visual interest
        for layer = 1, 2 do
            local layerSize = glowSize * (1.2 - layer * 0.3)
            local layerIntensity = glowIntensity * (layer == 1 and 0.4 or 0.8)
            
            -- Increase glow for tokens in transition (newly returned to pool)
            if token.state == "FREE" and token.inTransition then
                -- Stronger glow that fades over the transition period
                local transitionBoost = 0.6 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
                layerSize = layerSize * (1 + transitionBoost * 0.5)
                layerIntensity = layerIntensity + transitionBoost * 0.5
            end
            
            -- Set glow color based on token type with improved contrast and vibrancy
            if token.type == "fire" then
                love.graphics.setColor(1, 0.3, 0.1, layerIntensity)
            elseif token.type == "force" then
                love.graphics.setColor(1, 0.9, 0.3, layerIntensity)
            elseif token.type == "moon" then
                love.graphics.setColor(0.4, 0.4, 1, layerIntensity)
            elseif token.type == "nature" then
                love.graphics.setColor(0.2, 0.9, 0.1, layerIntensity)
            elseif token.type == "star" then
                love.graphics.setColor(1, 0.8, 0.2, layerIntensity)
            end
            
            -- Draw glow with pulsation
            local pulseAmount = 0.7 + 0.3 * math.sin(token.pulsePhase * 0.5)
            
            -- Enhanced pulsation for transitioning tokens
            if token.state == "FREE" and token.inTransition then
                pulseAmount = pulseAmount + 0.3 * math.sin(token.transitionTime * 10)
            end
            
            love.graphics.circle("fill", token.x, token.y, layerSize * pulseAmount * token.scale)
        end
        
        -- Draw a small outer ring for better definition
        if token.state == "FREE" then
            local ringAlpha = 0.4 + 0.2 * math.sin(token.pulsePhase * 0.8)
            
            -- Set ring color based on token type
            if token.type == "fire" then
                love.graphics.setColor(1, 0.5, 0.2, ringAlpha)
            elseif token.type == "force" then
                love.graphics.setColor(1, 1, 0.4, ringAlpha)
            elseif token.type == "moon" then
                love.graphics.setColor(0.6, 0.6, 1, ringAlpha)
            elseif token.type == "nature" then
                love.graphics.setColor(0.3, 1, 0.2, ringAlpha)
            elseif token.type == "star" then
                love.graphics.setColor(1, 0.9, 0.3, ringAlpha)
            end
            
            love.graphics.circle("line", token.x, token.y, (glowSize + 3) * token.scale)
        end
        
        -- Draw token image based on state
        if token.state == "FREE" then
            -- Free tokens are fully visible
            -- If token is in transition (just returned to pool), add a subtle glow effect
            if token.inTransition then
                local transitionGlow = 0.2 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
                love.graphics.setColor(1, 1, 1 + transitionGlow * 0.5, 1)  -- Slightly blue-white glow during transition
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
        elseif token.state == "CHANNELED" then
            -- Channeled tokens are fully visible
            love.graphics.setColor(1, 1, 1, 1)
        elseif token.state == "SHIELDING" then
            -- Shielding tokens have a slight colored tint based on their type
            if token.type == "force" then
                love.graphics.setColor(1, 1, 0.7, 1)  -- Yellow tint for force (barrier)
            elseif token.type == "moon" or token.type == "star" then
                love.graphics.setColor(0.8, 0.8, 1, 1)  -- Blue tint for moon/star (ward)
            elseif token.type == "nature" then
                love.graphics.setColor(0.8, 1, 0.8, 1)  -- Green tint for nature (field)
            else
                love.graphics.setColor(1, 1, 1, 1)  -- Default
            end
        elseif token.state == "LOCKED" then
            -- Locked tokens have a red tint
            love.graphics.setColor(1, 0.5, 0.5, 0.7)
        elseif token.state == "DESTROYED" then
            -- Dissolving tokens fade out
            if token.dissolving then
                -- Calculate progress of the dissolve animation
                local progress = token.dissolveTime / token.dissolveMaxTime
                
                -- Fade out by decreasing alpha
                local alpha = (1 - progress) * 0.8
                
                -- Get token color based on its type for the fade effect
                if token.type == "fire" then
                    love.graphics.setColor(1, 0.3, 0.1, alpha)
                elseif token.type == "force" then
                    love.graphics.setColor(1, 0.9, 0.3, alpha)
                elseif token.type == "moon" then
                    love.graphics.setColor(0.8, 0.6, 1.0, alpha)  -- Purple for lunar disjunction
                elseif token.type == "nature" then
                    love.graphics.setColor(0.2, 0.9, 0.1, alpha)
                elseif token.type == "star" then
                    love.graphics.setColor(1, 0.8, 0.2, alpha)
                else
                    love.graphics.setColor(1, 1, 1, alpha)
                end
            else
                -- Skip drawing if not dissolving
                goto continue
            end
        end
        
        -- Draw the token with dynamic scaling
        if token.state == "DESTROYED" and token.dissolving then
            -- For dissolving tokens, add special effects
            local progress = token.dissolveTime / token.dissolveMaxTime
            
            -- Expand and fade out
            local scaleFactor = token.dissolveScale * (1 + progress * 0.5)
            local rotationSpeed = token.rotSpeed or 1.0
            
            -- Speed up rotation as it dissolves
            token.rotAngle = token.rotAngle + rotationSpeed * 5 * progress
            
            -- Draw at original position with expanding effect
            love.graphics.draw(
                token.image, 
                token.initialX, 
                token.initialY, 
                token.rotAngle,
                scaleFactor * (1 - progress * 0.7), scaleFactor * (1 - progress * 0.7),
                token.image:getWidth()/2, token.image:getHeight()/2
            )
        else
            -- Normal tokens
            love.graphics.draw(
                token.image, 
                token.x, 
                token.y, 
                token.rotAngle,  -- Use the rotation angle
                token.scale, token.scale,  -- Use token-specific scale
                token.image:getWidth()/2, token.image:getHeight()/2  -- Origin at center
            )
        end
        
        ::continue::
        
        -- Draw shield effect for shielding tokens
        if token.state == "SHIELDING" then
            -- Get token color based on its mana type
            local tokenColor = {1, 1, 1, 0.3}  -- Default white
            
            -- Match color to the token type
            if token.type == "fire" then
                tokenColor = {1.0, 0.3, 0.1, 0.3}  -- Red-orange for fire
            elseif token.type == "force" then
                tokenColor = {1.0, 1.0, 0.3, 0.3}  -- Yellow for force
            elseif token.type == "moon" then
                tokenColor = {0.5, 0.5, 1.0, 0.3}  -- Blue for moon
            elseif token.type == "star" then
                tokenColor = {1.0, 0.8, 0.2, 0.3}  -- Gold for star
            elseif token.type == "nature" then
                tokenColor = {0.3, 0.9, 0.1, 0.3}  -- Green for nature
            end
            
            -- Draw a subtle shield aura with slight pulsation
            local pulseScale = 0.9 + math.sin(love.timer.getTime() * 2) * 0.1
            love.graphics.setColor(tokenColor)
            love.graphics.circle("fill", token.x, token.y, 15 * pulseScale * token.scale)
            
            -- Draw shield border
            love.graphics.setColor(tokenColor[1], tokenColor[2], tokenColor[3], 0.5)
            love.graphics.circle("line", token.x, token.y, 15 * pulseScale * token.scale)
            
            -- Add a small defensive shield symbol inside the circle
            -- Determine symbol shape by defense type if available
            if token.wizardOwner and token.spellSlot then
                local slot = token.wizardOwner.spellSlots[token.spellSlot]
                if slot and slot.defenseType then
                    love.graphics.setColor(1, 1, 1, 0.7)
                    if slot.defenseType == "barrier" then
                        -- Draw a small hexagon (shield shape) for barriers
                        local shieldSize = 6 * token.scale
                        local points = {}
                        for i = 1, 6 do
                            local angle = (i - 1) * math.pi / 3
                            table.insert(points, token.x + math.cos(angle) * shieldSize)
                            table.insert(points, token.y + math.sin(angle) * shieldSize)
                        end
                        love.graphics.polygon("line", points)
                    elseif slot.defenseType == "ward" then
                        -- Draw a small circle (ward shape)
                        love.graphics.circle("line", token.x, token.y, 6 * token.scale)
                    elseif slot.defenseType == "field" then
                        -- Draw a small diamond (field shape)
                        local fieldSize = 7 * token.scale
                        love.graphics.polygon("line", 
                            token.x, token.y - fieldSize,
                            token.x + fieldSize, token.y,
                            token.x, token.y + fieldSize,
                            token.x - fieldSize, token.y
                        )
                    end
                end
            end
        end
        
        -- Draw lock overlay for locked tokens
        if token.state == "LOCKED" then
            -- Draw the lock overlay
            local pulseScale = 0.9 + math.sin(token.lockPulse) * 0.2  -- Pulsing effect
            local overlayScale = 1.2 * pulseScale * token.scale  -- Scale for the lock overlay
            
            -- Pulsing red glow behind the lock
            love.graphics.setColor(1, 0, 0, 0.3 + 0.2 * math.sin(token.lockPulse))
            love.graphics.circle("fill", token.x, token.y, 12 * pulseScale * token.scale)
            
            -- Lock icon
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                self.lockOverlay,
                token.x,
                token.y,
                0,  -- No rotation for lock
                overlayScale, overlayScale,
                self.lockOverlay:getWidth()/2, self.lockOverlay:getHeight()/2
            )
            
            -- Display remaining lock time if more than 1 second
            if token.lockDuration > 1 then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(
                    string.format("%.0f", token.lockDuration),
                    token.x - 5,
                    token.y - 25
                )
            end
        end
    end
    
    -- No border - the pool is now completely invisible
end

-- Helper function to draw an ellipse
function ManaPool:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 64
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

function ManaPool:findFreeToken(tokenType)
    -- Find a free token of the specified type without changing its state
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            return token, i  -- Return token and its index without changing state
        end
    end
    return nil  -- No token available
end

function ManaPool:getToken(tokenType)
    -- Find a free token of the specified type that's not in transition
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" and
           not token.returning and not token.inTransition then
            -- Mark as being used
            token.state = "CHANNELED"  
            print(string.format("[MANAPOOL] Token %d (%s) reserved for channeling", i, token.type))
            return token, i  -- Return token and its index
        end
    end
    
    -- Second pass - try with less strict requirements if nothing was found
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            if token.returning then
                print("[MANAPOOL] WARNING: Using token in return animation - visual glitches may occur")
            elseif token.inTransition then
                print("[MANAPOOL] WARNING: Using token in transition state - visual glitches may occur")
            end
            token.state = "CHANNELED"
            print(string.format("[MANAPOOL] Token %d (%s) reserved for channeling (fallback)", i, token.type))
            -- Cancel any return animation
            token.returning = false
            token.inTransition = false
            return token, i
        end
    end
    
    return nil  -- No token available
end

function ManaPool:returnToken(tokenIndex)
    -- Return a token to the pool
    if self.tokens[tokenIndex] then
        local token = self.tokens[tokenIndex]
        
        -- Validate the token state and ownership before return
        if token.returning then
            print("[MANAPOOL] WARNING: Token " .. tokenIndex .. " is already being returned - ignoring duplicate return")
            return
        end
        
        -- Clear any wizard ownership immediately to prevent double-tracking
        token.wizardOwner = nil
        token.spellSlot = nil
        
        -- Ensure token is in a valid state - convert any state to valid transition state
        local originalState = token.state
        if token.state == "SHIELDING" or token.state == "CHANNELED" then
            print("[MANAPOOL] Token " .. tokenIndex .. " transitioning from " .. 
                 (token.state or "nil") .. " to return animation")
            
            -- We don't set state = FREE here yet - we let the animation complete first
            -- This prevents tokens from being reused in the middle of an animation
        elseif token.state ~= "FREE" then
            print("[MANAPOOL] WARNING: Returning token " .. tokenIndex .. " from unexpected state: " .. 
                 (token.state or "nil"))
        end
        
        -- Store current position as start position for return animation
        token.startX = token.x
        token.startY = token.y
        
        -- Pick a random valence for the token to return to
        local valenceIndex = math.random(1, #self.valences)
        
        -- Initialize needed valence transition fields
        local valence = self.valences[valenceIndex]
        token.valenceIndex = valenceIndex
        token.sourceValenceIndex = valenceIndex  -- Will be properly set in finalizeTokenReturn
        token.targetValenceIndex = valenceIndex
        token.sourceRadiusX = valence.radiusX
        token.sourceRadiusY = valence.radiusY
        token.targetRadiusX = valence.radiusX
        token.targetRadiusY = valence.radiusY
        token.currentRadiusX = valence.radiusX
        token.currentRadiusY = valence.radiusY
        
        -- Set up return animation parameters
        token.targetX = self.x  -- Center of mana pool
        token.targetY = self.y
        token.animTime = 0
        token.animDuration = 0.5 -- Half second return animation
        token.returning = true   -- Flag that this token is returning to the pool
        token.originalState = originalState  -- Remember what state it was in before return
        
        -- Set direction and speed based on the valence for when it becomes FREE
        local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
        token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
        token.originalSpeed = token.orbitSpeed
        
        -- Reset timers with some randomness
        token.valenceJumpTimer = 2 + math.random() * 4
        
        -- Initialize transition state for smooth blending
        token.inValenceTransition = false
        token.valenceTransitionTime = 0
        token.valenceTransitionDuration = 0.8
        
        print("[MANAPOOL] Token " .. tokenIndex .. " (" .. token.type .. ") returning animation started")
    else
        print("[MANAPOOL] WARNING: Attempted to return invalid token index: " .. tokenIndex)
    end
end

-- Called by update method when a token finishes its return animation
function ManaPool:finalizeTokenReturn(token)
    -- Clear all references to the spell it was used in
    token.wizardOwner = nil
    token.spellSlot = nil
    token.tokenIndex = nil
    
    -- Record the original state for debugging
    local originalState = token.state
    
    -- ALWAYS set to FREE state when a token returns to the pool
    token.state = "FREE"
    
    -- Log state change with details
    if originalState ~= "FREE" then
        print(string.format("[MANAPOOL] Token state changed: %s -> FREE (was %s before return animation)", 
              originalState or "nil", token.originalState or "unknown"))
    end
    token.originalState = nil -- Clean up
    
    -- Use the final position from the animation as the starting point
    local currentX = token.x
    local currentY = token.y
    
    -- Calculate angle from center
    local dx = currentX - self.x
    local dy = currentY - self.y
    local angle = math.atan2(dy, dx)
    
    -- Assign a random valence for the returned token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    token.valenceIndex = valenceIndex
    
    -- Calculate position based on current angle but using valence's elliptical dimensions
    token.orbitAngle = angle
    
    -- Calculate initial x,y based on selected valence
    local newX = self.x + math.cos(angle) * valence.radiusX
    local newY = self.y + math.sin(angle) * valence.radiusY
    
    -- Apply minimal variation to maintain clean orbits
    local variationX = math.random(-2, 2)
    local variationY = math.random(-1, 1)
    token.x = newX + variationX
    token.y = newY + variationY
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Set orbital speed based on the valence
    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    token.originalSpeed = token.orbitSpeed
    
    -- Add transition for smooth blending
    token.transitionTime = 0
    token.transitionDuration = 1.0  -- 1 second to blend into normal motion
    token.inTransition = true  -- Mark token as transitioning to normal motion
    
    -- Add valence jump timer
    token.valenceJumpTimer = 2 + math.random() * 8
    
    -- Initialize valence transition properties
    token.inValenceTransition = false
    token.valenceTransitionTime = 0
    token.valenceTransitionDuration = 0.8
    token.sourceValenceIndex = valenceIndex
    token.targetValenceIndex = valenceIndex
    token.sourceRadiusX = valence.radiusX
    token.sourceRadiusY = valence.radiusY
    token.targetRadiusX = valence.radiusX
    token.targetRadiusY = valence.radiusY
    token.currentRadiusX = valence.radiusX
    token.currentRadiusY = valence.radiusY
    
    -- Size and z-order variation
    token.scale = 0.85 + math.random() * 0.3
    token.zOrder = math.random()
    
    -- Clear animation flags and any spell-related ownership
    token.returning = false
    
    print("[MANAPOOL] Token (" .. token.type .. ") has fully returned to the pool and is FREE")
end

return ManaPool```

## ./spellCompiler.lua
```lua
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

return SpellCompiler```

## ./spells.lua
```lua
-- Spells.lua
-- Contains data for all spells in the game

-- Import the keyword system
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")

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
--   - Available keywords: damage, burn, stagger, elevate, ground, rangeShift, forcePull, 
--     tokenShift, conjure, dissipate, lock, delay, accelerate, dispel, disjoint, freeze,
--     block, reflect, echo, zoneAnchor, zoneMulti
-- vfx: Visual effect identifier (string, optional)
-- sfx: Sound effect identifier (string, optional)
-- blockableBy: Array of shield types that can block this spell (array, optional)
--
-- Shield Types and Blocking Rules:
-- * barrier: Physical shield that blocks projectiles and zones
-- * ward:    Magical shield that blocks projectiles and remotes
-- * field:   Energy field that blocks remotes and zones

-- Function to validate spell schema - Basic schema validation
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
                if not Keywords[keyword] then
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
                if target and target.elevation then
                    return target.elevation == "GROUNDED" and 20 or 0
                end
                return 0 -- Default damage if target is nil
            end,
            type = "fire"
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
            type = "fire"
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
            -- All shields are mana-linked now (consume tokens when blocking)
            -- Token count is the source of truth for shield strength
        },
        elevate = {
            duration = 4.0
        }
    },
    vfx = "mist_veil",
    sfx = "mist_shimmer",
    blockableBy = {},  -- Utility spell, can't be blocked
    
    -- Mark this as a shield (important for shield mechanics)
    -- isShield = true
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
                -- Make sure slot is a number
                local slotNum = tonumber(slot) or 0
                -- Validate the slot is in a valid range
                if slotNum > 0 and slotNum <= 3 then
                    return slotNum
                else
                    return 0  -- 0 means find the first active slot
                end
            end,
            target = "SLOT_ENEMY"  -- Explicitly target enemy's spell slot
        }
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
            type = "moon"
        },
        ground = {
            conditional = function(caster, target)
                return target and target.elevation == "AERIAL"
            end,
            target = "ENEMY",
            vfx = "gravity_pin_ground"
        },
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
            type = "moon"
        }
    },
    vfx = "moon_beam",
    sfx = "beam_charge",
    blockableBy = {"barrier", "ward"}
}

-- Shield spells
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
            blocks = {"projectile", "zone"}
            -- All shields are mana-linked now (consume tokens when blocking)
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
    cost = {"moon", "moon"},
    keywords = {
        block = {
            type = "ward",
            blocks = {"projectile", "remote"}
            -- All shields are mana-linked now (consume tokens when blocking)
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
            blocks = {"remote", "zone"}
            -- All shields are mana-linked now (consume tokens when blocking)
        }
    },
    vfx = "nature_field",
    sfx = "nature_grow",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Advanced reflective shield
Spells.mirrorshield = {
    id = "mirrorshield",
    name = "Mirror Shield",
    description = "A reflective barrier that returns damage to attackers",
    attackType = "utility",
    castTime = 5.0,
    cost = {"moon", "moon", "star"},
    keywords = {
        block = {
            type = "barrier",  -- Barrier type blocks projectiles and zones
            blocks = {"projectile", "zone"},
            reflect = true      -- Reflects damage back to attacker
            -- All shields are mana-linked now (consume tokens when blocking)
            -- Token count is the source of truth for shield strength
        }
    },
    vfx = "mirror_shield",
    sfx = "crystal_ring",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Shield-breaking spell
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
        }
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

-- Zone spell with range anchoring
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
        
        -- Return special response for handling the miss
        return {
            missBackfire = true,
            backfireDamage = 4,
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

-- Force blast spell that launches opponents into the air
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

-- Prepare the return table with all spells and utility functions
local SpellsModule = {
    spells = Spells,
    validateSpell = validateSpell,
    
    -- Public method to compile all spells
    compileAll = function()
        local compiled = {}
        for id, spell in pairs(Spells) do
            validateSpell(spell, id)
            -- References to SpellCompiler and Keywords need to be passed from game object
            -- This function will be called with the correct context from main.lua
            print("Waiting for SpellCompiler to compile: " .. spell.name)
        end
        return compiled
    end,
    
    -- Public method to get a compiled spell by ID
    getCompiledSpell = function(spellId, spellCompiler, keywords)
        if not Spells[spellId] then
            print("ERROR: Spell not found: " .. spellId)
            return nil
        end
        
        -- Make sure we have the required objects
        if not spellCompiler or not keywords then
            print("ERROR: Missing SpellCompiler or Keywords for compiling spell: " .. spellId)
            return nil
        end
        
        return spellCompiler.compileSpell(Spells[spellId], keywords)
    end
}

-- Validate all spells at module load time to catch errors early
for spellId, spell in pairs(Spells) do
    validateSpell(spell, spellId)
end

return SpellsModule```

## ./tools/generate_docs.lua
```lua
#!/usr/bin/env lua
-- Script to generate keyword documentation

-- Add manastorm root directory to lua path
package.path = package.path .. ";../?.lua"

-- Import the documentation generator
local DocGenerator = require("docs.keywords")

-- Generate the documentation
DocGenerator.writeDocumentation("../docs/KEYWORDS.md")

print("Documentation generation complete!")```

## ./tools/test_keywords.lua
```lua
#!/usr/bin/env lua
-- Script to test and debug keyword resolution

-- Add manastorm root directory to lua path
package.path = package.path .. ";../?.lua"

-- Import the spells module
local Spells = require("spells")

-- Mock wizard class for testing
local MockWizard = {}
MockWizard.__index = MockWizard

function MockWizard.new(name, position)
    local self = setmetatable({}, MockWizard)
    self.name = name
    self.x = position or 0
    self.y = 370
    self.elevation = "GROUNDED"
    self.spellSlots = {{}, {}, {}}
    self.manaPool = {
        tokens = {},
        addToken = function() print("Added token") end
    }
    self.gameState = {
        rangeState = "FAR",
        wizards = {}
    }
    return self
end

-- Create mock wizards for testing
local caster = MockWizard.new("TestWizard", 200)
local opponent = MockWizard.new("Opponent", 600)

-- Set up test state
caster.gameState.wizards = {caster, opponent}

-- Test a keyword in isolation
local function testKeyword(keyword, params)
    print("\n====== Testing keyword: " .. keyword .. " ======")
    
    -- Create starting results
    local results = {damage = 0, spellType = "test"}
    
    -- Process the keyword
    local newResults = Spells.keywordSystem.resolveKeyword(
        "test_spell", 
        keyword, 
        params, 
        caster, 
        opponent, 
        1, -- spell slot
        results
    )
    
    -- Show detailed results
    print("\nKeyword results:")
    for k, v in pairs(newResults) do
        if k ~= "damage" or v ~= 0 then
            print("  " .. k .. ": " .. tostring(v))
        end
    end
    
    return newResults
end

-- Test a full spell
local function testSpell(spell)
    print("\n====== Testing spell: " .. spell.name .. " ======")
    
    -- Process the spell using the new targeting-aware system
    local results = Spells.keywordSystem.castSpell(
        spell, 
        caster, 
        {
            opponent = opponent,
            spellSlot = 1,
            debug = true
        }
    )
    
    -- Show detailed results
    print("\nSpell results:")
    for k, v in pairs(results) do
        if k ~= "damage" or v ~= 0 then
            if k ~= "targetingInfo" then  -- Handle targeting info separately
                print("  " .. k .. ": " .. tostring(v))
            end
        end
    end
    
    -- Display targeting info
    if results.targetingInfo then
        print("\nTargeting information:")
        for keyword, info in pairs(results.targetingInfo) do
            print(string.format("  %s -> %s (%s)", 
                keyword, info.targetType, info.target))
        end
    end
    
    return results
end

-- Run tests based on command-line arguments
local function runTests()
    local arg = {...}
    
    if #arg == 0 then
        -- Default tests if no arguments provided
        print("Running default tests...")
        
        -- Test individual keywords
        testKeyword("damage", {amount = 10, type = "fire"})
        testKeyword("elevate", {duration = 3.0})
        testKeyword("rangeShift", {position = "NEAR"})
        
        -- Test a dynamic function parameter
        testKeyword("damage", {
            amount = function(caster, target)
                return caster.gameState.rangeState == "FAR" and 15 or 10
            end,
            type = "fire"
        })
        
        -- Test a complex spell
        local testSpell = {
            id = "testspell",
            name = "Test Compound Spell",
            description = "A spell combining multiple effects for testing",
            attackType = "projectile",
            castTime = 5.0,
            cost = {"fire", "force"},
            keywords = {
                damage = {
                    amount = function(caster, target)
                        return target.elevation == "AERIAL" and 15 or 10
                    end,
                    type = "fire"
                },
                elevate = {
                    duration = 3.0
                },
                rangeShift = {
                    position = "NEAR"
                }
            }
        }
        testSpell(testSpell)
        
    elseif arg[1] == "list" then
        -- List all available keywords
        print("Available keywords:")
        local keywordInfo = Spells.keywordSystem.getKeywordHelp()
        for keyword, info in pairs(keywordInfo) do
            print("- " .. keyword .. ": " .. info.description)
        end
        
    elseif arg[1] == "keyword" and arg[2] then
        -- Test a specific keyword
        local keyword = arg[2]
        
        -- Check if this keyword exists
        if not Spells.keywordSystem.handlers[keyword] then
            print("Error: Unknown keyword '" .. keyword .. "'")
            return
        end
        
        -- Create some basic params for testing
        local params = {}
        if keyword == "damage" then
            params = {amount = 10, type = "fire"}
        elseif keyword == "elevate" or keyword == "freeze" then
            params = {duration = 3.0}
        elseif keyword == "rangeShift" then
            params = {position = "NEAR"}
        elseif keyword == "block" then
            params = {type = "barrier", blocks = {"projectile"}}
        elseif keyword == "conjure" then
            params = {token = "fire", amount = 1}
        elseif keyword == "dissipate" then
            params = {token = "fire", amount = 1}
        elseif keyword == "tokenShift" then
            params = {type = "random", amount = 2}
        end
        
        testKeyword(keyword, params)
        
    elseif arg[1] == "spell" and arg[2] then
        -- Test a specific spell
        local spellId = arg[2]
        
        -- Check if this spell exists
        if not Spells.spells[spellId] then
            print("Error: Unknown spell '" .. spellId .. "'")
            return
        end
        
        testSpell(Spells.spells[spellId])
        
    else
        -- Show usage
        print("Usage:")
        print("  lua test_keywords.lua                  Run default tests")
        print("  lua test_keywords.lua list             List all available keywords")
        print("  lua test_keywords.lua keyword <name>   Test a specific keyword")
        print("  lua test_keywords.lua spell <id>       Test a specific spell")
    end
end

-- Run the tests
runTests(...)```

## ./tools/test_spellCompiler.lua
```lua
-- test_spellCompiler.lua
-- Tests for the Spell Compiler implementation

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local Spells = require("spells").spells

-- Define a fake game environment for testing
local gameEnv = {
    wizards = {
        { name = "TestWizard1", health = 100, elevation = "GROUNDED" },
        { name = "TestWizard2", health = 100, elevation = "AERIAL" }
    },
    rangeState = "FAR"
}

-- Add game state to wizards
gameEnv.wizards[1].gameState = gameEnv
gameEnv.wizards[2].gameState = gameEnv

-- Print test header
print("\n===== SPELL COMPILER TESTS =====\n")

-- Test 1: Basic spell compilation
print("TEST 1: Basic spell compilation")
local firebolt = Spells.firebolt
local compiledFirebolt = SpellCompiler.compileSpell(firebolt, Keywords)

-- Verify structure
print("Compiled spell structure check: " .. 
      (compiledFirebolt.behavior.damage ~= nil and "PASSED" or "FAILED"))
print("Original properties preserved: " .. 
      (compiledFirebolt.id == firebolt.id and 
       compiledFirebolt.name == firebolt.name and 
       compiledFirebolt.attackType == firebolt.attackType and "PASSED" or "FAILED"))

-- Test 2: Boolean keyword handling
print("\nTEST 2: Boolean keyword handling")
local groundKeywordSpell = {
    id = "testGround",
    name = "Test Ground",
    description = "Test for boolean keywords",
    attackType = "utility",
    castTime = 2.0,
    cost = {"any"},
    keywords = {
        ground = true
    }
}

local compiledGroundSpell = SpellCompiler.compileSpell(groundKeywordSpell, Keywords)
print("Boolean keyword handling: " .. 
      (compiledGroundSpell.behavior.ground.enabled == true and "PASSED" or "FAILED"))

-- Test 3: Complex spell with multiple keywords
print("\nTEST 3: Complex spell with multiple keywords")
local compiledMeteor = SpellCompiler.compileSpell(Spells.meteor, Keywords)
print("Multiple keywords compiled: " .. 
      (compiledMeteor.behavior.damage ~= nil and 
       compiledMeteor.behavior.rangeShift ~= nil and "PASSED" or "FAILED"))

-- Test 4: Execution of compiled behaviors
print("\nTEST 4: Execution of compiled behaviors")
local results = {}
results = compiledFirebolt.executeAll(gameEnv.wizards[1], gameEnv.wizards[2], results)

print("Behavior execution results:")
print("Damage applied: " .. tostring(results.damage))
print("Damage type: " .. tostring(results.damageType))

-- Test 5: Complex behavior parameter handling
print("\nTEST 5: Complex behavior parameter handling")
local arcaneReversal = Spells.arcaneReversal
local compiledArcaneReversal = SpellCompiler.compileSpell(arcaneReversal, Keywords)

print("Complex parameters preserved for multiple keywords: " .. 
      (compiledArcaneReversal.behavior.damage ~= nil and
       compiledArcaneReversal.behavior.rangeShift ~= nil and
       compiledArcaneReversal.behavior.lock ~= nil and
       compiledArcaneReversal.behavior.conjure ~= nil and
       compiledArcaneReversal.behavior.accelerate ~= nil and "PASSED" or "FAILED"))

-- Debug complete structure of a complex spell
print("\nDetailed structure of compiled arcaneReversal spell:")
SpellCompiler.debugCompiled(compiledArcaneReversal)

print("\n===== SPELL COMPILER TESTS COMPLETED =====\n")```

## ./tools/test_spellCompiler_standalone.lua
```lua
-- test_spellCompiler_standalone.lua
-- Standalone test for the Spell Compiler implementation

-- Mocking love.graphics.newImage to allow running outside LÖVE
_G.love = {
    graphics = {
        newImage = function(path) return { path = path } end
    }
}

package.path = package.path .. ";/Users/russell/Manastorm/?.lua"
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")

-- Define a sample spell for testing
local sampleSpell = {
    id = "fireball",
    name = "Fireball",
    description = "A ball of fire that deals damage",
    attackType = "projectile",
    castTime = 5.0,
    cost = {"fire", "fire"},
    keywords = {
        damage = {
            amount = 10,
            type = "fire"
        },
        burn = {
            duration = 3.0,
            tickDamage = 2
        }
    },
    vfx = "fireball_vfx",
    blockableBy = {"barrier", "ward"}
}

-- Print test header
print("\n===== SPELL COMPILER STANDALONE TEST =====\n")

-- Test basic spell compilation
print("Testing basic spell compilation...")
local compiledSpell = SpellCompiler.compileSpell(sampleSpell, Keywords)

-- Check that compilation worked
print("Compiled spell has behavior: " .. (compiledSpell.behavior ~= nil and "YES" or "NO"))
print("Compiled spell has damage behavior: " .. (compiledSpell.behavior.damage ~= nil and "YES" or "NO"))
print("Compiled spell has burn behavior: " .. (compiledSpell.behavior.burn ~= nil and "YES" or "NO"))

-- Test a boolean keyword
local spellWithBoolKeyword = {
    id = "groundSpell",
    name = "Ground Spell",
    description = "Forces enemy to ground",
    attackType = "utility",
    castTime = 3.0,
    cost = {"any"},
    keywords = {
        ground = true
    }
}

print("\nTesting boolean keyword handling...")
local compiledBoolSpell = SpellCompiler.compileSpell(spellWithBoolKeyword, Keywords)
print("Boolean keyword compiled: " .. (compiledBoolSpell.behavior.ground ~= nil and "YES" or "NO"))
print("Boolean keyword enabled: " .. (compiledBoolSpell.behavior.ground.enabled == true and "YES" or "NO"))

-- Define mock game objects for execution testing
local caster = {
    name = "TestWizard",
    elevation = "GROUNDED",
    manaPool = { 
        tokens = {},
        addToken = function() end
    },
    gameState = { rangeState = "FAR" }
}

local target = {
    name = "EnemyWizard",
    elevation = "AERIAL",
    health = 100
}

-- Test executing the compiled behaviors
print("\nTesting behavior execution...")
local results = compiledSpell.executeAll(caster, target, {})
print("Damage result: " .. tostring(results.damage))
print("Damage type: " .. tostring(results.damageType))
print("Burn applied: " .. tostring(results.burnApplied))
print("Burn duration: " .. tostring(results.burnDuration))
print("Burn tick damage: " .. tostring(results.burnTickDamage))

-- Debug the full compiled spell structure
print("\nDetailed structure of compiled spell:")
SpellCompiler.debugCompiled(compiledSpell)

print("\n===== SPELL COMPILER STANDALONE TEST COMPLETED =====\n")```

## ./ui.lua
```lua
-- UI helper module

local UI = {}

-- Spellbook visibility state
UI.spellbookVisible = {
    player1 = false,
    player2 = false
}

-- Delayed health damage display state
UI.healthDisplay = {
    player1 = {
        currentHealth = 100,        -- Current display health (smoothly animated)
        targetHealth = 100,         -- Actual health to animate towards
        pendingDamage = 0,          -- Damage that's pending animation (yellow bar)
        lastDamageTime = 0,         -- Time when last damage was taken
        pendingDrainDelay = 0.5,    -- Delay before yellow bar starts draining
        drainRate = 30              -- How fast the yellow bar drains (health points per second)
    },
    player2 = {
        currentHealth = 100,
        targetHealth = 100,
        pendingDamage = 0,
        lastDamageTime = 0,
        pendingDrainDelay = 0.5,
        drainRate = 30
    }
}

function UI.drawHelpText(font)
    -- Set font and color
    love.graphics.setFont(font)
    
    -- Draw a semi-transparent background for the debug panel
    love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
    local panelWidth = 600
    local y = love.graphics.getHeight() - 130
    love.graphics.rectangle("fill", 5, y + 30, panelWidth, 95, 5, 5)
    
    -- Draw a border
    love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
    love.graphics.rectangle("line", 5, y + 30, panelWidth, 95, 5, 5)
    
    -- Draw header
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.print("DEBUG MODE", 15, y + 35)
    
    -- Show debug controls with brighter text
    love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
    love.graphics.print("Debug Controls: T (Add tokens), R (Toggle range), A/S (Toggle elevations), ESC (Quit)", 15, y + 55)
    love.graphics.print("VFX Test Keys: 1 (Firebolt), 2 (Meteor), 3 (Mist Veil), 4 (Emberlift), 5 (Full Moon Beam)", 15, y + 75)
    love.graphics.print("Conjure Test Keys: 6 (Fire), 7 (Moonlight), 8 (Volatile)", 15, y + 95)
    
    -- No longer calling UI.drawSpellbookButtons() here as it's now handled in the main loop
end

-- Toggle spellbook visibility for a player
function UI.toggleSpellbook(player)
    if player == 1 then
        UI.spellbookVisible.player1 = not UI.spellbookVisible.player1
        UI.spellbookVisible.player2 = false -- Close other spellbook
    elseif player == 2 then
        UI.spellbookVisible.player2 = not UI.spellbookVisible.player2
        UI.spellbookVisible.player1 = false -- Close other spellbook
    end
end

-- Draw skeuomorphic spellbook components for both players
function UI.drawSpellbookButtons()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw Player 1's spellbook (Ashgar - pinned to left side)
    UI.drawPlayerSpellbook(1, 0, screenHeight - 70)
    
    -- Draw Player 2's spellbook (Selene - pinned to right side)
    UI.drawPlayerSpellbook(2, screenWidth - 250, screenHeight - 70)
end

-- Draw an individual player's spellbook component
function UI.drawPlayerSpellbook(playerNum, x, y)
    local screenWidth = love.graphics.getWidth()
    local width = 250  -- Balanced width
    local height = 50
    local player = (playerNum == 1) and "Ashgar" or "Selene"
    local keyLabel = (playerNum == 1) and "B" or "M"
    local keyPrefix = (playerNum == 1) and {"Q", "W", "E"} or {"I", "O", "P"}
    local wizard = _G.game.wizards[playerNum]
    local color = {wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255}
    
    -- Draw book background with slight gradient
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.25, 0.25, 0.35, 0.9)
    love.graphics.rectangle("fill", x, y, width, height/2)
    
    -- Draw book binding/spine effect
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("fill", x, y, 6, height)
    
    -- Draw book edge
    love.graphics.setColor(0.8, 0.8, 0.8, 0.3)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw dividers between sections
    love.graphics.setColor(0.4, 0.4, 0.5, 0.4)
    love.graphics.line(x + 120, y + 5, x + 120, y + height - 5)
    
    -- Center everything vertically in pane
    local centerY = y + height/2
    local runeSize = 14
    local groupSpacing = 35  -- Original spacing between keys
    
    -- GROUP 1: SPELL INPUT KEYS
    -- Add a subtle background for the key group
    love.graphics.setColor(0.2, 0.2, 0.3, 0.3)
    love.graphics.rectangle("fill", x + 15, centerY - 20, 95, 40, 5, 5)  -- Maintain original padding for keys
    
    -- Calculate positions for centered spell input keys
    local inputStartX = x + 30  -- Original position for better centering
    local inputY = centerY
    
    for i = 1, 3 do
        -- Draw rune background
        love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
        love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, runeSize)
        
        if wizard.activeKeys[i] then
            -- Active rune with glow effect
            -- Multiple layers for glow
            for j = 3, 1, -1 do
                local alpha = 0.3 * (4-j) / 3
                local size = runeSize + j * 2
                love.graphics.setColor(1, 1, 0.3, alpha)
                love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, size)
            end
            
            -- Bright center
            love.graphics.setColor(1, 1, 0.7, 0.9)
            love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, runeSize * 0.7)
            
            -- Properly centered rune symbol
            local keyText = keyPrefix[i]
            local keyTextWidth = love.graphics.getFont():getWidth(keyText)
            local keyTextHeight = love.graphics.getFont():getHeight()
            love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
            love.graphics.print(keyText, 
                inputStartX + (i-1)*groupSpacing - keyTextWidth/2, 
                inputY - keyTextHeight/2)
        else
            -- Inactive rune
            love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
            love.graphics.circle("line", inputStartX + (i-1)*groupSpacing, inputY, runeSize)
            
            -- Properly centered inactive symbol
            local keyText = keyPrefix[i]
            local keyTextWidth = love.graphics.getFont():getWidth(keyText)
            local keyTextHeight = love.graphics.getFont():getHeight()
            love.graphics.setColor(0.6, 0.6, 0.7, 0.6)
            love.graphics.print(keyText, 
                inputStartX + (i-1)*groupSpacing - keyTextWidth/2, 
                inputY - keyTextHeight/2)
        end
    end
    
    -- Removed "Input Keys" label for cleaner UI
    
    -- GROUP 2: CAST BUTTON & FREE BUTTON
    -- Create a shared container/background for both action buttons - more compact
    local actionSectionWidth = 90
    local actionX = x + 125
    
    -- Draw a shared background container for both action buttons
    love.graphics.setColor(0.18, 0.18, 0.25, 0.5)
    love.graphics.rectangle("fill", actionX, centerY - 18, actionSectionWidth, 36, 5, 5)  -- More compact
    
    -- Calculate positions for both buttons with tighter spacing
    local castX = actionX + actionSectionWidth/3 - 5
    local freeX = actionX + actionSectionWidth*2/3 + 5
    local castKey = (playerNum == 1) and "F" or "J"
    local freeKey = (playerNum == 1) and "G" or "H"
    
    -- CAST BUTTON
    -- Subtle highlighting background
    love.graphics.setColor(0.3, 0.2, 0.1, 0.3)
    love.graphics.rectangle("fill", castX - 17, centerY - 16, 34, 32, 5, 5)  -- More compact
    
    -- Draw cast button background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
    love.graphics.circle("fill", castX, inputY, runeSize)
    
    -- Cast button border
    love.graphics.setColor(0.8, 0.4, 0.1, 0.8)  -- Orange-ish for cast button
    love.graphics.circle("line", castX, inputY, runeSize)
    
    -- Cast button symbol
    local castTextWidth = love.graphics.getFont():getWidth(castKey)
    local castTextHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(1, 0.8, 0.3, 0.9)
    love.graphics.print(castKey, 
        castX - castTextWidth/2, 
        inputY - castTextHeight/2)
    
    -- Removed "Cast" label for cleaner UI
    
    -- FREE BUTTON
    -- Subtle highlighting background
    love.graphics.setColor(0.1, 0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", freeX - 17, centerY - 16, 34, 32, 5, 5)  -- More compact
    
    -- Draw free button background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
    love.graphics.circle("fill", freeX, inputY, runeSize)
    
    -- Free button border
    love.graphics.setColor(0.2, 0.6, 0.8, 0.8)  -- Blue-ish for free button
    love.graphics.circle("line", freeX, inputY, runeSize)
    
    -- Free button symbol
    local freeTextWidth = love.graphics.getFont():getWidth(freeKey)
    local freeTextHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(0.5, 0.8, 1.0, 0.9)
    love.graphics.print(freeKey, 
        freeX - freeTextWidth/2, 
        inputY - freeTextHeight/2)
    
    -- Removed "Free" label for cleaner UI
    
    -- GROUP 3: KEYED SPELL POPUP (appears above the spellbook when a spell is keyed)
    if wizard.currentKeyedSpell then
        -- Make the popup exactly match the width of the spellbook
        local popupWidth = width
        local popupHeight = 30
        local popupX = x  -- Align with spellbook
        local popupY = y - popupHeight - 10  -- Position above the spellbook with slightly larger gap
        
        -- Get spell name and calculate its width for centering
        local spellName = wizard.currentKeyedSpell.name
        local spellNameWidth = love.graphics.getFont():getWidth(spellName)
        
        -- Draw popup background with a slight "connected" look
        -- Use the same color as the spellbook for visual cohesion
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        
        -- Main popup body (rounded rectangle)
        love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 5, 5)
        
        -- Connection piece (small triangle pointing down)
        love.graphics.polygon("fill", 
            x + width/2 - 8, popupY + popupHeight,  -- Left point
            x + width/2 + 8, popupY + popupHeight,  -- Right point
            x + width/2, popupY + popupHeight + 8   -- Bottom point
        )
        
        -- Add a subtle border with the wizard's color
        love.graphics.setColor(color[1], color[2], color[3], 0.5)
        love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight, 5, 5)
        
        -- Subtle gradient for the background (matches the spellbook aesthetic)
        love.graphics.setColor(0.25, 0.25, 0.35, 0.7)
        love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight/2, 5, 5)
        
        -- Simple glow effect for the text
        for i = 3, 1, -1 do
            local alpha = 0.1 * (4-i) / 3
            local size = i * 2
            love.graphics.setColor(1, 1, 0.5, alpha)
            love.graphics.rectangle("fill", 
                x + width/2 - spellNameWidth/2 - size, 
                popupY + popupHeight/2 - 7 - size/2, 
                spellNameWidth + size*2, 
                14 + size,
                5, 5
            )
        end
        
        -- Spell name centered in the popup
        love.graphics.setColor(1, 1, 0.5, 0.9)
        love.graphics.print(spellName, 
            x + width/2 - spellNameWidth/2, 
            popupY + popupHeight/2 - 7
        )
    end
    
    -- GROUP 4: SPELLBOOK HELP (bottom-right corner) - more compact design
    local helpX = x + width - 15
    local helpY = y + height - 10
    
    -- Draw key hint - make it slightly bigger
    local helpSize = 8  -- Increased size
    love.graphics.setColor(0.4, 0.4, 0.6, 0.5)
    love.graphics.circle("fill", helpX, helpY, helpSize)
    
    -- Properly centered key symbol - BIGGER
    local smallFont = love.graphics.getFont()
    local keyTextWidth = smallFont:getWidth(keyLabel)
    local keyTextHeight = smallFont:getHeight()
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(keyLabel, 
        helpX - keyTextWidth/3, 
        helpY - keyTextHeight/3,
        0, 0.7, 0.7)  -- Significantly larger
    
    -- LARGER "?" indicator placed HIGHER above the button
    love.graphics.setColor(0.7, 0.7, 0.8, 0.8)  -- Brighter
    local helpLabel = "?"
    local helpLabelWidth = smallFont:getWidth(helpLabel)
    -- Position the ? significantly higher up
    love.graphics.print(helpLabel, 
        helpX - helpLabelWidth/3, 
        helpY - helpSize - smallFont:getHeight() - 2,  -- Position much higher above the button
        0, 0.7, 0.7)  -- Make it larger
    
    -- Highlight when active
    if (playerNum == 1 and UI.spellbookVisible.player1) or 
       (playerNum == 2 and UI.spellbookVisible.player2) then
        love.graphics.setColor(color[1], color[2], color[3], 0.4)
        love.graphics.rectangle("fill", x, y, width, height)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", x - 2, y - 2, width + 4, height + 4)
    end
end

function UI.drawSpellInfo(wizards)
    -- Function to format mana cost for display
    local function formatCost(cost)
        if not cost or #cost == 0 then
            return "Free"
        end
        
        -- Handle both old and new cost formats
        local costText = ""
        local tokenCounts = {}  -- For new array-style format
        
        -- Check if this is the new array-style format (simple array of strings)
        local isNewFormat = type(cost[1]) == "string"
        
        if isNewFormat then
            -- Count each token type
            for _, tokenType in ipairs(cost) do
                tokenCounts[tokenType] = (tokenCounts[tokenType] or 0) + 1
            end
            
            -- Format the counts
            for tokenType, count in pairs(tokenCounts) do
                costText = costText .. count .. " " .. tokenType .. ", "
            end
        else
            -- Old format with type and count properties
            for _, component in ipairs(cost) do
                local typeText = component.type
                if type(typeText) == "table" then
                    typeText = table.concat(typeText, "/")
                end
                costText = costText .. component.count .. " " .. typeText .. ", "
            end
        end
        
        return costText:sub(1, -3)  -- Remove trailing comma and space
    end
    
    -- Draw the fighting game style health bars
    UI.drawHealthBars(wizards)
    
    -- Draw spellbook popups if visible
    if UI.spellbookVisible.player1 then
        UI.drawSpellbookModal(wizards[1], 1, formatCost)
    end
    
    if UI.spellbookVisible.player2 then
        UI.drawSpellbookModal(wizards[2], 2, formatCost)
    end
    
    -- Spell notification is now handled by the wizard's castSpell function
    -- No longer drawing active spells list - relying on visual representation
end

-- Draw dramatic fighting game style health bars
function UI.drawHealthBars(wizards)
    local screenWidth = love.graphics.getWidth()
    local barHeight = 40
    local centerGap = 60 -- Space between bars in the center
    local barWidth = (screenWidth - centerGap) / 2
    local padding = 0 -- No padding from screen edges
    local y = 5
    
    -- Player 1 (Ashgar) health bar (left side, right-to-left depletion)
    local p1 = wizards[1]
    local display1 = UI.healthDisplay.player1
    
    -- Get the animated health percentage (from the delayed damage system)
    local p1HealthPercent = display1.currentHealth / 100
    local p1PendingDamagePercent = display1.pendingDamage / 100
    
    -- Background and border
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", padding, y, barWidth, barHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", padding, y, barWidth, barHeight)
    
    -- Health fill with gradient
    local ashgarGradient = {
        {0.8, 0.2, 0.2},  -- Red base color
        {1.0, 0.3, 0.1}   -- Brighter highlight
    }
    
    -- Calculate the total visible health (current + pending)
    local totalVisibleHealth = p1HealthPercent
    
    -- Draw gradient health bar for current health (excluding pending damage part)
    for i = 0, barWidth * p1HealthPercent, 1 do
        local gradientPos = i / (barWidth * p1HealthPercent)
        local r = ashgarGradient[1][1] + (ashgarGradient[2][1] - ashgarGradient[1][1]) * gradientPos
        local g = ashgarGradient[1][2] + (ashgarGradient[2][2] - ashgarGradient[1][2]) * gradientPos
        local b = ashgarGradient[1][3] + (ashgarGradient[2][3] - ashgarGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(padding + i, y + 2, padding + i, y + barHeight - 2)
    end
    
    -- Add a single halfway marker at 50% health, anchored to the bottom
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    local halfwayX = padding + (barWidth / 2)
    local markerHeight = barHeight / 2  -- The marker extends halfway up the bar
    love.graphics.line(halfwayX, y + barHeight - markerHeight, halfwayX, y + barHeight)
    
    -- Get actual health from the wizard for comparison
    local p1ActualHealthPercent = p1.health / 100
    
    -- Health lost "after damage" effect (fading darker region)
    -- This is displayed UNDER everything else, so draw it first
    local permanentDamageAmount = 1.0 - p1ActualHealthPercent
    if permanentDamageAmount > 0 then
        love.graphics.setColor(0.5, 0.1, 0.1, 0.3)
        love.graphics.rectangle("fill", 
            padding + barWidth * p1ActualHealthPercent, 
            y, 
            barWidth * permanentDamageAmount, 
            barHeight)
    end
    
    -- Pending damage effect (yellow bar segment)
    -- This shows the section of health that will drain away
    if p1PendingDamagePercent > 0 then
        -- Calculate where the pending damage begins and ends
        local pendingStart = p1HealthPercent  -- Where current health ends
        local pendingEnd = math.min(p1HealthPercent + p1PendingDamagePercent, p1ActualHealthPercent)
        local pendingWidth = pendingEnd - pendingStart
        
        -- Only draw if there's actual width to display
        if pendingWidth > 0 then
            -- Draw yellow segment for pending damage (as it's actually depleting)
            love.graphics.setColor(1.0, 0.9, 0.2, 0.8)
            
            -- Draw the pending section as yellow bars to match the health bar style
            for i = 0, barWidth * pendingWidth, 1 do
                local x = padding + barWidth * pendingStart + i
                love.graphics.line(x, y + 2, x, y + barHeight - 2)
            end
            
            -- Add some shading effects to the pending damage zone
            love.graphics.setColor(1.0, 1.0, 0.5, 0.2)
            love.graphics.rectangle("fill", 
                padding + barWidth * pendingStart, 
                y, 
                barWidth * pendingWidth, 
                barHeight/3)
        end
    end
    
    -- Gleaming highlight
    local time = love.timer.getTime()
    local hilight = math.abs(math.sin(time))
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", padding, y, barWidth * p1HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p1.name, padding + 20, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage only in debug mode
    if love.keyboard.isDown("`") then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(math.floor(p1HealthPercent * 100) .. "%", padding + barWidth - 40, y + 7)
    end
    
    
    -- Player 2 (Selene) health bar (right side, left-to-right depletion)
    local p2 = wizards[2]
    local display2 = UI.healthDisplay.player2
    
    -- Get the animated health percentage (from the delayed damage system)
    local p2HealthPercent = display2.currentHealth / 100
    local p2PendingDamagePercent = display2.pendingDamage / 100
    local p2X = screenWidth - barWidth
    
    -- Background and border
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", p2X, y, barWidth, barHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", p2X, y, barWidth, barHeight)
    
    -- Health fill with gradient
    local seleneGradient = {
        {0.1, 0.3, 0.8},  -- Blue base color
        {0.2, 0.5, 1.0}   -- Brighter highlight
    }
    
    -- Calculate the total visible health
    local totalVisibleHealth = p2HealthPercent
    
    -- Draw gradient health bar (left-to-right depletion)
    for i = 0, barWidth * p2HealthPercent, 1 do
        local gradientPos = i / (barWidth * p2HealthPercent)
        local r = seleneGradient[1][1] + (seleneGradient[2][1] - seleneGradient[1][1]) * gradientPos
        local g = seleneGradient[1][2] + (seleneGradient[2][2] - seleneGradient[1][2]) * gradientPos
        local b = seleneGradient[1][3] + (seleneGradient[2][3] - seleneGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(p2X + barWidth - i, y + 2, p2X + barWidth - i, y + barHeight - 2)
    end
    
    -- Add a single halfway marker at 50% health, anchored to the bottom
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    local halfwayX = p2X + (barWidth / 2)
    local markerHeight = barHeight / 2  -- The marker extends halfway up the bar
    love.graphics.line(halfwayX, y + barHeight - markerHeight, halfwayX, y + barHeight)
    
    -- Get actual health from the wizard for comparison
    local p2ActualHealthPercent = p2.health / 100
    
    -- Health lost "after damage" effect (fading darker region)
    -- This is displayed UNDER everything else, so draw it first
    local permanentDamageAmount = 1.0 - p2ActualHealthPercent
    if permanentDamageAmount > 0 then
        love.graphics.setColor(0.1, 0.1, 0.5, 0.3)
        love.graphics.rectangle("fill", p2X, y, barWidth * permanentDamageAmount, barHeight)
    end
    
    -- Pending damage effect (yellow bar segment)
    if p2PendingDamagePercent > 0 then
        -- Calculate where the pending damage begins and ends
        -- For player 2, the bar fills from right to left
        local pendingStart = 1.0 - p2HealthPercent  -- Where current health ends (from left)
        local pendingEnd = math.min(pendingStart + p2PendingDamagePercent, 1.0 - p2ActualHealthPercent)
        local pendingWidth = pendingEnd - pendingStart
        
        -- Only draw if there's actual width to display
        if pendingWidth > 0 then
            -- Draw yellow segment for pending damage (as it's actually depleting)
            love.graphics.setColor(1.0, 0.9, 0.2, 0.8)
            
            -- Draw the pending section as yellow bars to match the health bar style
            for i = 0, barWidth * pendingWidth, 1 do
                local x = p2X + barWidth * pendingStart + i
                love.graphics.line(x, y + 2, x, y + barHeight - 2)
            end
            
            -- Add some shading effects to the pending damage zone
            love.graphics.setColor(1.0, 1.0, 0.5, 0.2)
            love.graphics.rectangle("fill", 
                p2X + barWidth * pendingStart, 
                y, 
                barWidth * pendingWidth, 
                barHeight/3)
        end
    end
    
    -- Gleaming highlight
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", p2X + barWidth * (1 - p2HealthPercent), y, barWidth * p2HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p2.name, p2X + barWidth - 80, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage only in debug mode
    if love.keyboard.isDown("`") then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(math.floor(p2HealthPercent * 100) .. "%", p2X + 10, y + 7)
    end
end

-- [Removed drawActiveSpells function - now using visual representation instead]

-- Draw a full spellbook modal for a player
-- Update the health display animation
function UI.updateHealthDisplays(dt, wizards)
    local currentTime = love.timer.getTime()
    
    for i, wizard in ipairs(wizards) do
        local display = UI.healthDisplay["player" .. i]
        local actualHealth = wizard.health
        
        -- If actual health is different from our target, register new damage
        if actualHealth < display.targetHealth then
            -- Calculate how much new damage was taken
            local newDamage = display.targetHealth - actualHealth
            
            -- Add to pending damage
            display.pendingDamage = display.pendingDamage + newDamage
            
            -- Update target health to match actual health
            display.targetHealth = actualHealth
            
            -- Reset the damage timer to restart the delay
            display.lastDamageTime = currentTime
        end
        
        -- Check if we should start draining the pending damage
        if display.pendingDamage > 0 and (currentTime - display.lastDamageTime) > display.pendingDrainDelay then
            -- Calculate how much to drain based on time passed
            local drainAmount = display.drainRate * dt
            
            -- Don't drain more than what's pending
            drainAmount = math.min(drainAmount, display.pendingDamage)
            
            -- Reduce pending damage and update current health
            display.pendingDamage = display.pendingDamage - drainAmount
            display.currentHealth = display.currentHealth - drainAmount
            
            -- Ensure we don't go below target health
            if display.currentHealth < display.targetHealth then
                display.currentHealth = display.targetHealth
                display.pendingDamage = 0
            end
            
            -- Debug output to help track the animation
            -- print(string.format("Player %d: Health %.1f, Pending %.1f, Target %.1f", 
            --     i, display.currentHealth, display.pendingDamage, display.targetHealth))
        end
    end
end

function UI.drawSpellbookModal(wizard, playerNum, formatCost)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Determine position based on player number
    local modalX, modalTitle, keyPrefix
    if playerNum == 1 then
        modalX = 0  -- Pinned to left edge
        modalTitle = "Ashgar's Spellbook"
        keyPrefix = {"Q", "W", "E", "Q+W", "Q+E", "W+E", "Q+W+E"}
    else
        modalX = screenWidth - 400  -- Pinned to right edge
        modalTitle = "Selene's Spellbook"
        keyPrefix = {"I", "O", "P", "I+O", "I+P", "O+P", "I+O+P"}
    end
    
    -- Modal background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 450)
    love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
    love.graphics.rectangle("line", modalX, 50, 400, 450)
    
    -- Modal title
    love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(modalTitle, modalX + 150, 60)
    
    -- Close button
    love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", modalX + 370, 50, 30, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("X", modalX + 380, 60)
    
    -- Controls help section at the top of the modal
    love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
    love.graphics.rectangle("fill", modalX + 10, 90, 380, 100)
    love.graphics.setColor(1, 1, 1, 0.9)
    
    if playerNum == 1 then
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("Q/W/E: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("F: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("G: Free all active spells and return mana", modalX + 30, 155)
        love.graphics.print("B: Toggle spellbook visibility", modalX + 30, 175)
    else
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("I/O/P: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("J: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("H: Free all active spells and return mana", modalX + 30, 155)
        love.graphics.print("M: Toggle spellbook visibility", modalX + 30, 175)
    end
    
    -- Spells section
    local y = 200
    
    -- Single key spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Single Key Spells", modalX + 150, y + 5)
    y = y + 30
    
    -- Display single key spells
    for i = 1, 3 do
        local keyName = tostring(i)
        local spell = wizard.spellbook[keyName]
        if spell then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            love.graphics.print(keyPrefix[i] .. ": " .. spell.name, modalX + 20, y + 5)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. spell.castTime .. "s", modalX + 30, y + 25)
            y = y + 45
        end
    end
    
    -- Multi-key spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Multi-Key Spells", modalX + 150, y + 5)
    y = y + 30
    
    -- Display multi-key spells
    for i = 4, 7 do  -- 4=combo "12", 5=combo "13", 6=combo "23", 7=combo "123"
        local keyName
        if i == 4 then keyName = "12"
        elseif i == 5 then keyName = "13"
        elseif i == 6 then keyName = "23"
        else keyName = "123" end
        
        local spell = wizard.spellbook[keyName]
        if spell then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            love.graphics.print(keyPrefix[i] .. ": " .. spell.name, modalX + 20, y + 5)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. spell.castTime .. "s", modalX + 30, y + 25)
            y = y + 45
        end
    end
end


return UI```

## ./validate_spellCompiler.lua
```lua
-- validate_spellCompiler.lua
-- A simple script to validate the spellCompiler implementation
-- Writes validation results to a file for inspection

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")

-- Define a sample spell for testing
local sampleSpell = {
    id = "fireball",
    name = "Fireball",
    description = "A ball of fire that deals damage",
    attackType = "projectile",
    castTime = 5.0,
    cost = {"fire", "fire"},
    keywords = {
        damage = {
            amount = 10,
            type = "fire"
        },
        burn = {
            duration = 3.0,
            tickDamage = 2
        }
    },
    vfx = "fireball_vfx",
    blockableBy = {"barrier", "ward"}
}

-- Open a file for writing results
local outFile = io.open("spellCompiler_validation.txt", "w")

-- Write test header
outFile:write("===== SPELL COMPILER VALIDATION =====\n\n")

-- Test basic spell compilation
outFile:write("Testing basic spell compilation...\n")
local compiledSpell = SpellCompiler.compileSpell(sampleSpell, Keywords)

-- Check that compilation worked
outFile:write("Compiled spell has behavior: " .. (compiledSpell.behavior ~= nil and "YES" or "NO") .. "\n")
outFile:write("Compiled spell has damage behavior: " .. (compiledSpell.behavior.damage ~= nil and "YES" or "NO") .. "\n")
outFile:write("Compiled spell has burn behavior: " .. (compiledSpell.behavior.burn ~= nil and "YES" or "NO") .. "\n")

-- Test a boolean keyword
local spellWithBoolKeyword = {
    id = "groundSpell",
    name = "Ground Spell",
    description = "Forces enemy to ground",
    attackType = "utility",
    castTime = 3.0,
    cost = {"any"},
    keywords = {
        ground = true
    }
}

outFile:write("\nTesting boolean keyword handling...\n")
local compiledBoolSpell = SpellCompiler.compileSpell(spellWithBoolKeyword, Keywords)
outFile:write("Boolean keyword compiled: " .. (compiledBoolSpell.behavior.ground ~= nil and "YES" or "NO") .. "\n")
outFile:write("Boolean keyword enabled: " .. (compiledBoolSpell.behavior.ground.enabled == true and "YES" or "NO") .. "\n")

-- Define mock game objects for execution testing
local caster = {
    name = "TestWizard",
    elevation = "GROUNDED",
    manaPool = { 
        tokens = {},
        addToken = function() end
    },
    gameState = { rangeState = "FAR" }
}

local target = {
    name = "EnemyWizard",
    elevation = "AERIAL",
    health = 100
}

-- Test executing the compiled behaviors
outFile:write("\nTesting behavior execution...\n")

-- Create table to capture print output
local originalPrint = print
local printOutput = {}
print = function(...)
    local args = {...}
    local output = ""
    for i, v in ipairs(args) do
        output = output .. tostring(v) .. (i < #args and "\t" or "")
    end
    table.insert(printOutput, output)
end

-- Run debug output to capture to our printOutput table
SpellCompiler.debugCompiled(compiledSpell)

-- Write captured output to file
for _, line in ipairs(printOutput) do
    outFile:write(line .. "\n")
end

-- Restore original print function
print = originalPrint

outFile:write("\nVALIDATION SUMMARY\n")
outFile:write("- Basic spell compilation: " .. (compiledSpell.behavior ~= nil and "PASSED" or "FAILED") .. "\n")
outFile:write("- Boolean keyword handling: " .. (compiledBoolSpell.behavior.ground ~= nil and "PASSED" or "FAILED") .. "\n")
outFile:write("- Execution structure: " .. (type(compiledSpell.executeAll) == "function" and "PASSED" or "FAILED") .. "\n")

outFile:write("\n===== SPELL COMPILER VALIDATION COMPLETED =====\n")
outFile:close()

-- Print confirmation message
print("Validation completed. Results written to spellCompiler_validation.txt")```

## ./vfx.lua
```lua
-- VFX.lua
-- Visual effects module for spell animations and combat effects

local VFX = {}
VFX.__index = VFX

-- Table to store active effects
VFX.activeEffects = {}

-- Initialize the VFX system
function VFX.init()
    -- Load any necessary assets for effects
    VFX.assets = {
        -- Fire effects
        fireParticle = love.graphics.newImage("assets/sprites/fire-particle.png"),
        fireGlow = love.graphics.newImage("assets/sprites/fire-glow.png"),
        
        -- Force effects
        forceWave = love.graphics.newImage("assets/sprites/force-wave.png"),
        
        -- Moon effects
        moonGlow = love.graphics.newImage("assets/sprites/moon-glow.png"),
        
        -- Generic effects
        sparkle = love.graphics.newImage("assets/sprites/sparkle.png"),
        impactRing = love.graphics.newImage("assets/sprites/impact-ring.png"),
    }
    
    -- Effect definitions keyed by effect name
    VFX.effects = {
        -- General impact effect (used for many spell interactions)
        impact = {
            type = "impact",
            duration = 0.5,  -- Half second by default
            particleCount = 15,
            startScale = 0.8,
            endScale = 0.2,
            color = {1, 1, 1, 0.8},  -- Default white, will be overridden by options
            radius = 30,
            sound = nil  -- No default sound
        },
        
        -- Tidal Force Ground effect - for forcing opponents down from AERIAL to GROUNDED
        tidal_force_ground = {
            type = "impact",
            duration = 0.8,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = {0.4, 0.6, 1.0, 0.9},  -- Blue-ish for water/tidal theme
            radius = 80,
            sound = "tidal_wave"
        },
        
        -- Gravity Pin Ground effect - for forcing opponents down from AERIAL to GROUNDED
        gravity_pin_ground = {
            type = "impact",
            duration = 0.8,
            particleCount = 20,
            startScale = 0.6,
            endScale = 1.0,
            color = {0.7, 0.3, 0.9, 0.9},  -- Purple for gravity theme
            radius = 70,
            sound = "gravity_slam"
        },
        
        force_blast = {
            type = "impact",
            duration = 1.0,
            particleCount = 30,
            startScale = 0.4,
            endScale = 1.5,
            color = {0.4, 0.7, 1.0, 0.8},  -- Blue-ish for force theme
            radius = 90,
            sound = "force_wind"
        },
        
        -- Free Mana - special effect when freeing all spells
        free_mana = {
            type = "aura",
            duration = 1.2,
            particleCount = 40,
            startScale = 0.4,
            endScale = 0.8,
            color = {0.2, 0.6, 0.9, 0.9},  -- Bright blue for freeing mana
            radius = 100,
            pulseRate = 4,
            sound = "release"
        },

        -- Firebolt effect
        firebolt = {
            type = "projectile",
            duration = 1.0,  -- 1 second total duration
            particleCount = 20,
            startScale = 0.5,
            endScale = 1.0,
            color = {1, 0.5, 0.2, 1},
            trailLength = 12,
            impactSize = 1.4,
            sound = "firebolt"
        },
        
        -- Meteor effect
        meteor = {
            type = "impact",
            duration = 1.5,
            particleCount = 40,
            startScale = 2.0,
            endScale = 0.5,
            color = {1, 0.4, 0.1, 1},
            radius = 120,
            sound = "meteor"
        },
        
        -- Mist Veil effect
        mistveil = {
            type = "aura",
            duration = 3.0,
            particleCount = 30,
            startScale = 0.2,
            endScale = 0.8,
            color = {0.7, 0.7, 1.0, 0.7},
            radius = 80,
            pulseRate = 2,
            sound = "mist"
        },
        
        -- Emberlift effect
        emberlift = {
            type = "vertical",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.1,
            color = {1, 0.6, 0.2, 0.8},
            height = 100,
            sound = "whoosh"
        },
        
        -- Force Blast Up effect (for forcing opponents up to AERIAL)
        force_blast_up = {
            type = "vertical",
            duration = 1.5,
            particleCount = 35,
            startScale = 0.4,
            endScale = 0.2,
            color = {0.3, 0.5, 1.0, 0.8},  -- Blue-ish for force
            height = 120,
            sound = "force_wind"
        },
        
        -- Full Moon Beam effect
        fullmoonbeam = {
            type = "beam",
            duration = 1.8,
            particleCount = 30,
            beamWidth = 40,
            startScale = 0.2,
            endScale = 1.0,
            color = {0.8, 0.8, 1.0, 0.9},
            pulseRate = 3,
            sound = "moonbeam"
        },
        
        -- Tidal Force effect
        tidal_force = {
            type = "projectile",
            duration = 1.2,
            particleCount = 30,
            startScale = 0.4,
            endScale = 0.8,
            color = {0.3, 0.5, 1.0, 0.8},  -- Blue-ish for water theme
            trailLength = 15,
            impactSize = 1.6,
            sound = "tidal_wave"
        },
        
        -- Lunar Disjunction effect
        lunardisjunction = {
            type = "projectile",
            duration = 1.0,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.6,
            color = {0.8, 0.6, 1.0, 0.9},  -- Purple-blue for moon/cosmic theme
            trailLength = 10,
            impactSize = 1.8,  -- Bigger impact
            sound = "lunar_disrupt"
        },
        
        -- Disjoint effect (for cancelling opponent's spell)
        disjoint_cancel = {
            type = "impact",
            duration = 1.2,
            particleCount = 35,
            startScale = 0.6,
            endScale = 1.0,
            color = {0.9, 0.5, 1.0, 0.9},  -- Brighter purple for disruption
            radius = 70,
            sound = "lunar_disrupt"
        },
        
        -- Conjure Fire effect
        conjurefire = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = {1.0, 0.5, 0.2, 0.9},
            height = 140,  -- Height to rise toward mana pool
            spreadRadius = 40, -- Initial spread around the caster
            sound = "conjure"
        },
        
        -- Conjure Moonlight effect
        conjuremoonlight = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = {0.7, 0.7, 1.0, 0.9},
            height = 140,
            spreadRadius = 40,
            sound = "conjure"
        },
        
        -- Volatile Conjuring effect (random mana)
        volatileconjuring = {
            type = "conjure",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.2,
            endScale = 0.6,
            color = {1.0, 1.0, 0.5, 0.9},  -- Yellow base color, will be randomized
            height = 140,
            spreadRadius = 55,  -- Wider spread for volatile
            sound = "conjure"
        },
        
        -- Shield effect (used for barrier, ward, and field shield activation)
        shield = {
            type = "aura",
            duration = 1.0,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = {0.8, 0.8, 1.0, 0.8},  -- Default blue-ish, will be overridden by options
            radius = 60,
            pulseRate = 3,
            sound = "shield"
        }
    }
    
    -- Initialize sound effects (placeholders)
    VFX.sounds = {
        firebolt = nil, -- Will load actual sound files when available
        meteor = nil,
        mist = nil,
        whoosh = nil,
        moonbeam = nil,
        conjure = nil,
        shield = nil
    }
    
    return VFX
end

-- Create a new effect instance
function VFX.createEffect(effectName, sourceX, sourceY, targetX, targetY, options)
    -- Get effect template
    local template = VFX.effects[effectName:lower()]
    if not template then
        print("Warning: Effect not found: " .. effectName)
        return nil
    end
    
    -- Create a new effect instance
    local effect = {
        name = effectName,
        type = template.type,
        sourceX = sourceX,
        sourceY = sourceY,
        targetX = targetX or sourceX,
        targetY = targetY or sourceY,
        
        -- Timing
        duration = template.duration,
        timer = 0,
        progress = 0,
        isComplete = false,
        
        -- Visual properties (copied from template)
        particleCount = template.particleCount,
        startScale = template.startScale,
        endScale = template.endScale,
        color = {template.color[1], template.color[2], template.color[3], template.color[4]},
        
        -- Effect specific properties
        particles = {},
        trailPoints = {},
        
        -- Sound
        sound = template.sound,
        
        -- Additional properties based on effect type
        radius = template.radius,
        beamWidth = template.beamWidth,
        height = template.height,
        pulseRate = template.pulseRate,
        trailLength = template.trailLength,
        impactSize = template.impactSize,
        spreadRadius = template.spreadRadius,
        
        -- Optional overrides
        options = options or {}
    }
    
    -- Initialize particles based on effect type
    VFX.initializeParticles(effect)
    
    -- Play sound effect if available
    if effect.sound and VFX.sounds[effect.sound] then
        -- Will play sound when implemented
    end
    
    -- Add to active effects list
    table.insert(VFX.activeEffects, effect)
    
    return effect
end

-- Initialize particles based on effect type
function VFX.initializeParticles(effect)
    -- Different initialization based on effect type
    if effect.type == "projectile" then
        -- For projectiles, create a trail of particles
        for i = 1, effect.particleCount do
            local particle = {
                x = effect.sourceX,
                y = effect.sourceY,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = 0,
                delay = i / effect.particleCount * 0.3, -- Stagger particle start
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "impact" then
        -- For impact effects, create a radial explosion
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(10, effect.radius)
            local speed = math.random(50, 200)
            local particle = {
                x = effect.targetX,
                y = effect.targetY,
                targetX = effect.targetX + math.cos(angle) * distance,
                targetY = effect.targetY + math.sin(angle) * distance,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = angle,
                delay = math.random() * 0.2, -- Slight random delay
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "aura" then
        -- For aura effects, create particles that orbit the character
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(effect.radius * 0.6, effect.radius)
            local orbitalSpeed = math.random(0.5, 2.0)
            local particle = {
                angle = angle,
                distance = distance,
                orbitalSpeed = orbitalSpeed,
                scale = effect.startScale,
                alpha = 0, -- Start invisible and fade in
                rotation = 0,
                delay = i / effect.particleCount * 0.5,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "vertical" then
        -- For vertical effects like emberlift, particles rise upward
        for i = 1, effect.particleCount do
            local offsetX = math.random(-30, 30)
            local startY = math.random(0, 40)
            local speed = math.random(70, 150)
            local particle = {
                x = effect.sourceX + offsetX,
                y = effect.sourceY + startY,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = math.random() * math.pi * 2,
                delay = i / effect.particleCount * 0.8,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "beam" then
        -- For beam effects like fullmoonbeam, create a beam with particles
        -- First create the main beam shape
        effect.beamProgress = 0
        effect.beamLength = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
        effect.beamAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)
        
        -- Then add particles along the beam
        for i = 1, effect.particleCount do
            local position = math.random()
            local offset = math.random(-10, 10)
            local particle = {
                position = position, -- 0 to 1 along beam
                offset = offset, -- Perpendicular to beam
                scale = effect.startScale * math.random(0.7, 1.3),
                alpha = 0.8,
                rotation = math.random() * math.pi * 2,
                delay = math.random() * 0.3,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "conjure" then
        -- For conjuration spells, create particles that rise from caster toward mana pool
        -- Set the mana pool position (typically at top center)
        effect.manaPoolX = effect.options and effect.options.manaPoolX or 400 -- Screen center X
        effect.manaPoolY = effect.options and effect.options.manaPoolY or 120 -- Near top of screen
        
        -- Ensure spreadRadius has a default value
        effect.spreadRadius = effect.spreadRadius or 40
        
        -- Calculate direction vector toward mana pool
        local dirX = effect.manaPoolX - effect.sourceX
        local dirY = effect.manaPoolY - effect.sourceY
        local len = math.sqrt(dirX * dirX + dirY * dirY)
        dirX = dirX / len
        dirY = dirY / len
        
        for i = 1, effect.particleCount do
            -- Create a spread of particles around the caster
            local spreadAngle = math.random() * math.pi * 2
            local spreadDist = math.random() * effect.spreadRadius
            local startX = effect.sourceX + math.cos(spreadAngle) * spreadDist
            local startY = effect.sourceY + math.sin(spreadAngle) * spreadDist
            
            -- Randomize particle properties
            local speed = math.random(80, 180)
            local delay = i / effect.particleCount * 0.7
            
            -- Add some variance to path
            local pathVariance = math.random(-20, 20)
            local pathDirX = dirX + pathVariance / 100
            local pathDirY = dirY + pathVariance / 100
            
            local particle = {
                x = startX,
                y = startY,
                speedX = pathDirX * speed,
                speedY = pathDirY * speed,
                scale = effect.startScale,
                alpha = 0, -- Start transparent and fade in
                rotation = math.random() * math.pi * 2,
                rotSpeed = math.random(-3, 3),
                delay = delay,
                active = false,
                finalPulse = false,
                finalPulseTime = 0
            }
            table.insert(effect.particles, particle)
        end
    end
end

-- Update all active effects
function VFX.update(dt)
    local i = 1
    while i <= #VFX.activeEffects do
        local effect = VFX.activeEffects[i]
        
        -- Update effect timer
        effect.timer = effect.timer + dt
        effect.progress = math.min(effect.timer / effect.duration, 1.0)
        
        -- Update effect based on type
        if effect.type == "projectile" then
            VFX.updateProjectile(effect, dt)
        elseif effect.type == "impact" then
            VFX.updateImpact(effect, dt)
        elseif effect.type == "aura" then
            VFX.updateAura(effect, dt)
        elseif effect.type == "vertical" then
            VFX.updateVertical(effect, dt)
        elseif effect.type == "beam" then
            VFX.updateBeam(effect, dt)
        elseif effect.type == "conjure" then
            VFX.updateConjure(effect, dt)
        end
        
        -- Remove effect if complete
        if effect.progress >= 1.0 then
            table.remove(VFX.activeEffects, i)
        else
            i = i + 1
        end
    end
end

-- Update function for projectile effects
function VFX.updateProjectile(effect, dt)
    -- Update trail points
    if #effect.trailPoints == 0 then
        -- Initialize trail with source position
        for i = 1, effect.trailLength do
            table.insert(effect.trailPoints, {x = effect.sourceX, y = effect.sourceY})
        end
    end
    
    -- Calculate projectile position based on progress
    local posX = effect.sourceX + (effect.targetX - effect.sourceX) * effect.progress
    local posY = effect.sourceY + (effect.targetY - effect.sourceY) * effect.progress
    
    -- Add curved trajectory based on height
    local midpointProgress = effect.progress - 0.5
    local verticalOffset = -60 * (1 - (midpointProgress * 2)^2)
    posY = posY + verticalOffset
    
    -- Update trail
    table.remove(effect.trailPoints)
    table.insert(effect.trailPoints, 1, {x = posX, y = posY})
    
    -- Update particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Distribute particles along the trail
            local trailIndex = math.floor((i / #effect.particles) * #effect.trailPoints) + 1
            if trailIndex > #effect.trailPoints then trailIndex = #effect.trailPoints end
            
            local trailPoint = effect.trailPoints[trailIndex]
            
            -- Add some randomness to particle positions
            local spreadFactor = 8 * (1 - particleProgress)
            particle.x = trailPoint.x + math.random(-spreadFactor, spreadFactor)
            particle.y = trailPoint.y + math.random(-spreadFactor, spreadFactor)
            
            -- Update visual properties
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            particle.alpha = math.min(2.0 - particleProgress * 2, 1.0) -- Fade out in last half
            particle.rotation = particle.rotation + dt * 2
        end
    end
    
    -- Create impact effect when reaching the target
    if effect.progress > 0.95 and not effect.impactCreated then
        effect.impactCreated = true
        -- Would create a separate impact effect here in a full implementation
    end
end

-- Update function for impact effects
function VFX.updateImpact(effect, dt)
    -- Create impact wave that expands outward
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle outward from center
            local dirX = particle.targetX - effect.targetX
            local dirY = particle.targetY - effect.targetY
            local length = math.sqrt(dirX^2 + dirY^2)
            if length > 0 then
                dirX = dirX / length
                dirY = dirY / length
            end
            
            particle.x = effect.targetX + dirX * length * particleProgress
            particle.y = effect.targetY + dirY * length * particleProgress
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            particle.alpha = 1.0 - particleProgress^2 -- Quadratic fade out
            particle.rotation = particle.rotation + dt * 3
        end
    end
end

-- Update function for aura effects
function VFX.updateAura(effect, dt)
    -- Update orbital particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update angle for orbital motion
            particle.angle = particle.angle + dt * particle.orbitalSpeed
            
            -- Calculate position based on orbit
            particle.x = effect.sourceX + math.cos(particle.angle) * particle.distance
            particle.y = effect.sourceY + math.sin(particle.angle) * particle.distance
            
            -- Pulse effect
            local pulseOffset = math.sin(effect.timer * effect.pulseRate) * 0.2
            
            -- Update visual properties with fade in/out
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress + pulseOffset
            
            -- Fade in for first 20%, stay visible for 60%, fade out for last 20%
            if particleProgress < 0.2 then
                particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
            elseif particleProgress > 0.8 then
                particle.alpha = (1 - particleProgress) * 5 -- 1 to 0 over last 20% time
            else
                particle.alpha = 1.0
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for vertical effects
function VFX.updateVertical(effect, dt)
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle upward
            particle.y = particle.y - particle.speed * dt
            
            -- Add some horizontal drift
            local driftSpeed = 10 * math.sin(particle.y * 0.05 + i)
            particle.x = particle.x + driftSpeed * dt
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            
            -- Fade in briefly, then fade out over time
            if particleProgress < 0.1 then
                particle.alpha = particleProgress * 10 -- Quick fade in
            else
                particle.alpha = 1.0 - ((particleProgress - 0.1) / 0.9) -- Slower fade out
            end
            
            particle.rotation = particle.rotation + dt * 2
        end
    end
end

-- Update function for beam effects
function VFX.updateBeam(effect, dt)
    -- Update beam progress
    effect.beamProgress = math.min(effect.progress * 2, 1.0) -- Beam reaches full extension halfway through
    
    -- Update beam particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Only show particles along the visible length of the beam
            if particle.position <= effect.beamProgress then
                -- Calculate position along beam
                local beamX = effect.sourceX + (effect.targetX - effect.sourceX) * particle.position
                local beamY = effect.sourceY + (effect.targetY - effect.sourceY) * particle.position
                
                -- Add perpendicular offset
                local perpX = -math.sin(effect.beamAngle) * particle.offset
                local perpY = math.cos(effect.beamAngle) * particle.offset
                
                particle.x = beamX + perpX
                particle.y = beamY + perpY
                
                -- Add pulsing effect
                local pulseOffset = math.sin(effect.timer * effect.pulseRate + particle.position * 10) * 0.3
                
                -- Update visual properties
                particle.scale = (effect.startScale + (effect.endScale - effect.startScale) * particleProgress) * (1 + pulseOffset)
                
                -- Fade based on beam extension and overall effect progress
                if effect.progress < 0.5 then
                    -- Beam extending - particles at tip are brighter
                    local distFromTip = math.abs(particle.position - effect.beamProgress)
                    particle.alpha = math.max(0, 1.0 - distFromTip * 3)
                else
                    -- Beam fully extended, starting to fade out
                    local fadeProgress = (effect.progress - 0.5) * 2 -- 0 to 1 in second half
                    particle.alpha = 1.0 - fadeProgress
                end
            else
                particle.alpha = 0 -- Particle not yet reached by beam extension
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for conjure effects
function VFX.updateConjure(effect, dt)
    -- Update particles rising toward mana pool
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update position based on speed
            if not particle.finalPulse then
                particle.x = particle.x + particle.speedX * dt
                particle.y = particle.y + particle.speedY * dt
                
                -- Calculate distance to mana pool
                local distX = effect.manaPoolX - particle.x
                local distY = effect.manaPoolY - particle.y
                local dist = math.sqrt(distX * distX + distY * distY)
                
                -- If close to mana pool, trigger final pulse effect
                if dist < 30 or particleProgress > 0.85 then
                    particle.finalPulse = true
                    particle.finalPulseTime = 0
                    
                    -- Center at mana pool
                    particle.x = effect.manaPoolX + math.random(-15, 15)
                    particle.y = effect.manaPoolY + math.random(-15, 15)
                end
            else
                -- Handle final pulse animation
                particle.finalPulseTime = particle.finalPulseTime + dt
                
                -- Expand and fade out for final pulse
                local pulseProgress = math.min(particle.finalPulseTime / 0.3, 1.0) -- 0.3s pulse duration
                particle.scale = effect.endScale * (1 + pulseProgress * 2) -- Expand to 3x size
                particle.alpha = 1.0 - pulseProgress -- Fade out
            end
            
            -- Handle fade in and rotation regardless of state
            if not particle.finalPulse then
                -- Fade in over first 20% of travel
                if particleProgress < 0.2 then
                    particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
                else
                    particle.alpha = 1.0
                end
                
                -- Update scale
                particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            end
            
            -- Update rotation
            particle.rotation = particle.rotation + particle.rotSpeed * dt
        end
    end
    
    -- Add a special effect at source and destination
    if effect.progress < 0.3 then
        -- Glow at source during initial phase
        effect.sourceGlow = 1.0 - (effect.progress / 0.3)
    else
        effect.sourceGlow = 0
    end
    
    -- Glow at mana pool during later phase
    if effect.progress > 0.5 then
        effect.poolGlow = (effect.progress - 0.5) * 2
        if effect.poolGlow > 1.0 then effect.poolGlow = 2 - effect.poolGlow end -- Peak at 0.75 progress
    else
        effect.poolGlow = 0
    end
end

-- Draw all active effects
function VFX.draw()
    for _, effect in ipairs(VFX.activeEffects) do
        if effect.type == "projectile" then
            VFX.drawProjectile(effect)
        elseif effect.type == "impact" then
            VFX.drawImpact(effect)
        elseif effect.type == "aura" then
            VFX.drawAura(effect)
        elseif effect.type == "vertical" then
            VFX.drawVertical(effect)
        elseif effect.type == "beam" then
            VFX.drawBeam(effect)
        elseif effect.type == "conjure" then
            VFX.drawConjure(effect)
        end
    end
end

-- Draw function for projectile effects
function VFX.drawProjectile(effect)
    local particleImage = VFX.assets.fireParticle
    local glowImage = VFX.assets.fireGlow
    
    -- Draw trail
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    if #effect.trailPoints >= 3 then
        local points = {}
        for i, point in ipairs(effect.trailPoints) do
            table.insert(points, point.x)
            table.insert(points, point.y)
        end
        love.graphics.setLineWidth(effect.startScale * 10)
        love.graphics.line(points)
        love.graphics.setLineWidth(1)
    end
    
    -- Draw glow at head of projectile
    if #effect.trailPoints > 0 then
        local head = effect.trailPoints[1]
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
        local glowScale = effect.startScale * 3
        love.graphics.draw(
            glowImage,
            head.x, head.y,
            0,
            glowScale, glowScale,
            glowImage:getWidth()/2, glowImage:getHeight()/2
        )
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw impact flash when projectile reaches target
    if effect.progress > 0.95 then
        local flashIntensity = (1 - (effect.progress - 0.95) * 20) -- Flash quickly fades
        if flashIntensity > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], flashIntensity)
            love.graphics.circle("fill", effect.targetX, effect.targetY, effect.impactSize * 30 * (1 - flashIntensity))
        end
    end
end

-- Draw function for impact effects
function VFX.drawImpact(effect)
    local particleImage = VFX.assets.fireParticle
    local impactImage = VFX.assets.impactRing
    
    -- Draw expanding ring
    local ringProgress = math.min(effect.progress * 1.5, 1.0) -- Ring expands faster than full effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - ringProgress) * effect.color[4])
    local ringScale = effect.radius * 0.02 * ringProgress
    love.graphics.draw(
        impactImage,
        effect.targetX, effect.targetY,
        0,
        ringScale, ringScale,
        impactImage:getWidth()/2, impactImage:getHeight()/2
    )
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw central flash
    if effect.progress < 0.3 then
        local flashIntensity = 1.0 - (effect.progress / 0.3)
        love.graphics.setColor(1, 1, 1, flashIntensity * 0.7)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 30 * flashIntensity)
    end
end

-- Draw function for aura effects
function VFX.drawAura(effect)
    local particleImage = VFX.assets.sparkle
    
    -- Draw base aura circle
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.2
    local baseAlpha = 0.3 * (1 - (math.abs(effect.progress - 0.5) * 2)^2) -- Peak at middle of effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], baseAlpha)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, baseAlpha * 1.5)
    love.graphics.circle("line", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
end

-- Draw function for vertical effects
function VFX.drawVertical(effect)
    local particleImage = VFX.assets.fireParticle
    
    -- Draw base effect at source
    local baseProgress = math.min(effect.progress * 3, 1.0) -- Quick initial flash
    if baseProgress < 1.0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - baseProgress) * 0.7)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 40 * baseProgress)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw guiding lines (subtle vertical paths)
    if effect.progress < 0.7 then
        local lineAlpha = 0.3 * (1.0 - effect.progress / 0.7)
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], lineAlpha)
        for i = 1, 5 do
            local xOffset = (i - 3) * 10
            local startY = effect.sourceY
            local endY = effect.sourceY - effect.height * math.min(effect.progress * 2, 1.0)
            love.graphics.line(effect.sourceX + xOffset, startY, effect.sourceX + xOffset * 1.5, endY)
        end
    end
end

-- Draw function for beam effects
function VFX.drawBeam(effect)
    local particleImage = VFX.assets.sparkle
    local beamLength = effect.beamLength * effect.beamProgress
    
    -- Draw base beam
    local beamEndX = effect.sourceX + math.cos(effect.beamAngle) * beamLength
    local beamEndY = effect.sourceY + math.sin(effect.beamAngle) * beamLength
    
    -- Calculate beam width with pulse
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.3
    local beamWidth = effect.beamWidth * (1 + pulseAmount) * (1 - (effect.progress > 0.5 and (effect.progress - 0.5) * 2 or 0))
    
    -- Draw outer beam glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    love.graphics.setLineWidth(beamWidth * 1.5)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw inner beam core
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, effect.color[4] * 0.7)
    love.graphics.setLineWidth(beamWidth * 0.7)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw brightest beam center
    love.graphics.setColor(1, 1, 1, effect.color[4] * 0.9)
    love.graphics.setLineWidth(beamWidth * 0.3)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw source glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, 20 * (1 + pulseAmount))
    
    -- Draw impact glow at target if beam is fully extended
    if effect.beamProgress >= 0.99 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.8 * (1 - (effect.progress - 0.5) * 2))
        love.graphics.circle("fill", beamEndX, beamEndY, 25 * (1 + pulseAmount))
    end
end

-- Draw function for conjure effects
function VFX.drawConjure(effect)
    local particleImage = VFX.assets.sparkle
    local glowImage = VFX.assets.fireGlow  -- We'll use this for all conjure types
    
    -- Draw source glow if active
    if effect.sourceGlow and effect.sourceGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.sourceGlow * 0.6)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 50 * effect.sourceGlow)
        
        -- Draw expanding rings from source (hint at conjuration happening)
        local ringCount = 3
        for i = 1, ringCount do
            local ringProgress = ((effect.timer * 1.5) % 1.0) + (i-1) / ringCount
            if ringProgress < 1.0 then
                local ringSize = 60 * ringProgress
                local ringAlpha = 0.5 * (1.0 - ringProgress) * effect.sourceGlow
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], ringAlpha)
                love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
            end
        end
    end
    
    -- Draw mana pool glow if active
    if effect.poolGlow and effect.poolGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.poolGlow * 0.7)
        love.graphics.circle("fill", effect.manaPoolX, effect.manaPoolY, 40 * effect.poolGlow)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            -- Choose the right glow image based on final pulse state
            local imgToDraw = particleImage
            
            -- Adjust color based on state
            if particle.finalPulse then
                -- Brighter for final pulse
                love.graphics.setColor(
                    effect.color[1] * 1.3, 
                    effect.color[2] * 1.3, 
                    effect.color[3] * 1.3, 
                    effect.color[4] * particle.alpha
                )
                imgToDraw = glowImage
            else
                love.graphics.setColor(
                    effect.color[1], 
                    effect.color[2], 
                    effect.color[3], 
                    effect.color[4] * particle.alpha
                )
            end
            
            -- Draw the particle
            love.graphics.draw(
                imgToDraw,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                imgToDraw:getWidth()/2, imgToDraw:getHeight()/2
            )
            
            -- For volatile conjuring, add random color sparks
            if effect.name:lower() == "volatileconjuring" and not particle.finalPulse and math.random() < 0.3 then
                -- Random rainbow hue for volatile conjuring
                local hue = (effect.timer * 0.5 + particle.x * 0.01) % 1.0
                local r, g, b = HSVtoRGB(hue, 0.8, 1.0)
                
                love.graphics.setColor(r, g, b, particle.alpha * 0.7)
                love.graphics.draw(
                    particleImage,
                    particle.x + math.random(-5, 5), 
                    particle.y + math.random(-5, 5),
                    particle.rotation + math.random() * math.pi,
                    particle.scale * 0.5, particle.scale * 0.5,
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
            end
        end
    end
    
    -- Draw connection lines between particles (ethereal threads)
    if effect.progress < 0.7 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.2)
        
        local maxConnectDist = 50  -- Maximum distance for particles to connect
        for i = 1, #effect.particles do
            local p1 = effect.particles[i]
            if p1.active and p1.alpha > 0.2 and not p1.finalPulse then
                for j = i+1, #effect.particles do
                    local p2 = effect.particles[j]
                    if p2.active and p2.alpha > 0.2 and not p2.finalPulse then
                        local dx = p1.x - p2.x
                        local dy = p1.y - p2.y
                        local dist = math.sqrt(dx*dx + dy*dy)
                        
                        if dist < maxConnectDist then
                            -- Fade based on distance
                            local alpha = (1 - dist/maxConnectDist) * 0.3 * p1.alpha * p2.alpha
                            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
                            love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                        end
                    end
                end
            end
        end
    end
end

-- Helper function for HSV to RGB conversion (for volatile conjuring rainbow effect)
function HSVtoRGB(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r, g, b
end

-- Helper function to create the appropriate effect for a spell
function VFX.createSpellEffect(spell, caster, target)
    -- Get mana pool position for conjuration spells
    local manaPoolX = caster.manaPool and caster.manaPool.x or 400
    local manaPoolY = caster.manaPool and caster.manaPool.y or 120
    
    -- Determine source and target positions
    local sourceX, sourceY = caster.x, caster.y
    local targetX, targetY = target.x, target.y
    
    -- Handle different spell types
    local spellName = spell.name:lower():gsub("%s+", "") -- Convert to lowercase and remove spaces
    
    -- Handle conjuration spells first
    if spellName == "conjurefire" then
        return VFX.createEffect("conjurefire", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "conjuremoonlight" then
        return VFX.createEffect("conjuremoonlight", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "volatileconjuring" then
        return VFX.createEffect("volatileconjuring", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    
    -- Special handling for other specific spells
    elseif spellName == "firebolt" then
        return VFX.createEffect("firebolt", sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "meteor" then
        return VFX.createEffect("meteor", targetX, targetY - 100, targetX, targetY)
    elseif spellName == "mistveil" then
        return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
    elseif spellName == "emberlift" then
        return VFX.createEffect("emberlift", sourceX, sourceY, nil, nil)
    elseif spellName == "fullmoonbeam" then
        return VFX.createEffect("fullmoonbeam", sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "tidalforce" then
        return VFX.createEffect("tidal_force", sourceX, sourceY - 15, targetX, targetY - 15)
    elseif spellName == "lunardisjunction" then
        return VFX.createEffect("lunardisjunction", sourceX, sourceY - 15, targetX, targetY - 15)
    elseif spellName == "forceblast" then
        return VFX.createEffect("force_blast", sourceX, sourceY - 15, targetX, targetY - 15)
    else
        -- Create a generic effect based on spell type or mana cost
        if spell.spellType == "projectile" then
            return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
        else
            -- Look at spell cost to determine effect type
            local hasFireMana = false
            local hasMoonMana = false
            
            for _, cost in ipairs(spell.cost or {}) do
                if cost.type == "fire" then hasFireMana = true end
                if cost.type == "moon" then hasMoonMana = true end
            end
            
            if hasFireMana then
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            elseif hasMoonMana then
                return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
            else
                -- Default generic effect
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            end
        end
    end
end

return VFX```

## ./wizard.lua
```lua
-- Wizard class

local Wizard = {}
Wizard.__index = Wizard

-- Load spells module with the new keyword system
local SpellsModule = require("spells")
local Spells = SpellsModule.spells  -- For backwards compatibility

-- We'll use game.compiledSpells instead of a local compiled spells table

-- Create a shield function to replace the one from SpellsModule.keywordSystem
local function createShield(wizard, spellSlot, blockParams)
    -- Check that the slot is valid
    if not wizard.spellSlots[spellSlot] then
        print("[SHIELD ERROR] Invalid spell slot for shield creation: " .. tostring(spellSlot))
        return { shieldCreated = false }
    end
    
    local slot = wizard.spellSlots[spellSlot]
    
    -- Set shield parameters - simplified to use token count as the only source of truth
    slot.isShield = true
    slot.defenseType = blockParams.type or "barrier"
    
    -- Store the original spell completion
    slot.active = true
    slot.progress = slot.castTime -- Mark as fully cast
    
    -- Set which attack types this shield blocks
    slot.blocksAttackTypes = {}
    local blockTypes = blockParams.blocks or {"projectile"}
    for _, attackType in ipairs(blockTypes) do
        slot.blocksAttackTypes[attackType] = true
    end
    
    -- Also store as array for compatibility
    slot.blockTypes = blockTypes
    
    -- ALL shields are mana-linked (consume tokens when hit) - simplified model
    
    -- Set reflection capability
    slot.reflect = blockParams.reflect or false
    
    -- No longer tracking shield strength separately - token count is the source of truth
    
    -- Slow down token orbiting speed for shield tokens if they exist
    for _, tokenData in ipairs(slot.tokens) do
        local token = tokenData.token
        if token then
            -- Set token to "SHIELDING" state
            token.state = "SHIELDING"
            -- Add specific shield type info to the token for visual effects
            token.shieldType = slot.defenseType
            -- Slow down the rotation speed for shield tokens
            if token.orbitSpeed then
                token.orbitSpeed = token.orbitSpeed * 0.5  -- 50% slower
            end
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
    
    -- Print debug info - simplified to only show token count
    print(string.format("[SHIELD] %s created a %s shield in slot %d with %d tokens",
        wizard.name or "Unknown wizard",
        slot.defenseType,
        spellSlot,
        #slot.tokens))
    
    -- Return result for further processing - simplified for token-based shields only
    return {
        shieldCreated = true,
        defenseType = slot.defenseType,
        blockTypes = blockParams.blocks
    }
end

-- Function to check if a spell can be blocked by a shield
local function checkShieldBlock(spell, attackType, defender, attacker)
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
    if not defender or not spell or not attackType then
        print("[SHIELD DEBUG] checkShieldBlock early exit - missing parameter")
        return result
    end
    
    -- Utility spells can't be blocked
    if attackType == "utility" then
        print("[SHIELD DEBUG] checkShieldBlock early exit - utility spell can't be blocked")
        return result
    end
    
    print("[SHIELD DEBUG] Checking if " .. attackType .. " spell can be blocked by " .. defender.name .. "'s shields")
    
    -- Check each of the defender's spell slots for active shields
    for i, slot in ipairs(defender.spellSlots) do
        -- Skip inactive slots or non-shield slots
        if not slot.active or not slot.isShield then
            goto continue
        end
        
        -- Check if this shield has tokens remaining (token count is the source of truth for shield strength)
        if #slot.tokens <= 0 then
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
            -- All shields are mana-linked by default
            result.manaLinked = true
            
            -- Handle mana consumption for the block
            if #slot.tokens > 0 then
                result.processBlockEffect = true
                
                -- Get amount of hits based on the spell's shield breaker power (if any)
                local shieldBreakPower = spell.shieldBreaker or 1
                
                -- Determine how many tokens to consume (up to shield breaker power or tokens available)
                local tokensToConsume = math.min(shieldBreakPower, #slot.tokens)
                result.tokensToConsume = tokensToConsume
                
                -- No need to track shield strength separately anymore
                -- Token consumption is handled by removing tokens directly
                
                -- Check if this will destroy the shield (when all tokens are consumed)
                if tokensToConsume >= #slot.tokens then
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

-- Get a compiled spell by ID, compile on demand if not already compiled
local function getCompiledSpell(spellId, wizard)
    -- Make sure we have a game reference
    if not wizard or not wizard.gameState then
        print("Error: No wizard or gameState to get compiled spell")
        return nil
    end
    
    local gameState = wizard.gameState
    
    -- Try to get from game's compiled spells
    if gameState.compiledSpells and gameState.compiledSpells[spellId] then
        return gameState.compiledSpells[spellId]
    end
    
    -- If not found, try to compile on demand
    if Spells[spellId] and gameState.spellCompiler and gameState.keywords then
        -- Make sure compiledSpells exists
        if not gameState.compiledSpells then
            gameState.compiledSpells = {}
        end
        
        -- Compile the spell and store it
        gameState.compiledSpells[spellId] = gameState.spellCompiler.compileSpell(
            Spells[spellId], 
            gameState.keywords
        )
        print("Compiled spell on demand: " .. spellId)
        return gameState.compiledSpells[spellId]
    else
        print("Error: Could not compile spell with ID: " .. spellId)
        return nil
    end
end

function Wizard.new(name, x, y, color)
    local self = setmetatable({}, Wizard)
    
    self.name = name
    self.x = x
    self.y = y
    self.color = color  -- RGB table
    
    -- Wizard state
    self.health = 100
    self.elevation = "GROUNDED"  -- GROUNDED or AERIAL
    self.elevationTimer = 0      -- Timer for temporary elevation changes
    self.stunTimer = 0           -- Stun timer in seconds
    
    -- Status effects
    self.statusEffects = {
        burn = {
            active = false,
            duration = 0,
            tickDamage = 0,
            tickInterval = 1.0,
            elapsed = 0,         -- Time since last tick
            totalTime = 0        -- Total time effect has been active
        }
    }
    
    -- Visual effects
    self.blockVFX = {
        active = false,
        timer = 0,
        x = 0,
        y = 0
    }
    
    -- Spell cast notification (temporary until proper VFX)
    self.spellCastNotification = nil
    
    -- Spell keying system
    self.activeKeys = {
        [1] = false,
        [2] = false,
        [3] = false
    }
    self.currentKeyedSpell = nil
    
    -- Spell loadout based on wizard name
    if name == "Ashgar" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjurefire,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.firebolt,
            
            -- Multi-key combinations
            ["12"] = Spells.eruption,      -- Zone spell with range anchoring 
            ["13"] = Spells.combust, -- Mana denial spell
            ["23"] = Spells.emberlift,     -- Movement spell
            ["123"] = Spells.meteor  -- Zone dependent nuke
        }
    elseif name == "Selene" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjuremoonlight,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.mist,
            
            -- Multi-key combinations
            ["12"] = Spells.tidalforce,     -- Chip damage Remote spell that forces out of AERIAL
            ["13"] = Spells.eclipse,
            ["23"] = Spells.lunardisjunction, -- 
            ["123"] = Spells.fullmoonbeam -- Full Moon Beam spell
        }
    end
    
    -- Verify that all spells in the spellbook are properly defined
    for key, spell in pairs(self.spellbook) do
        if not spell then
            print("WARNING: Spell for key combo '" .. key .. "' is nil for " .. name)
        elseif not spell.cost then
            print("WARNING: Spell '" .. (spell.name or "unnamed") .. "' for key combo '" .. key .. "' has no cost defined")
        else
            -- Ensure spell has an ID
            if not spell.id and spell.name then
                spell.id = spell.name:lower():gsub(" ", "")
                print("DEBUG: Added missing ID for spell: " .. spell.name .. " -> " .. spell.id)
            end
            
            -- Detailed debug output for detecting reference issues
            print("DEBUG: Spell reference check for key combo '" .. key .. "':")
            print("DEBUG: - Name: " .. (spell.name or "unnamed"))
            print("DEBUG: - ID: " .. (spell.id or "no id"))
            print("DEBUG: - Cost: " .. (type(spell.cost) == "table" and "table of length " .. #spell.cost or tostring(spell.cost)))
        end
    end
    
    -- Spell slots (3 max)
    self.spellSlots = {}
    for i = 1, 3 do
        self.spellSlots[i] = {
            active = false,
            progress = 0,
            spellType = nil,
            castTime = 0,
            tokens = {},  -- Will hold channeled mana tokens
            
            -- Shield-specific properties
            isShield = false,
            defenseType = nil,  -- "barrier", "ward", or "field"
            shieldStrength = 0, -- How many hits the shield can take
            blocksAttackTypes = nil  -- Table of attack types this shield blocks
        }
    end
    
    -- Load wizard sprite
    self.sprite = love.graphics.newImage("assets/sprites/wizard.png")
    self.scale = 2.0  -- Scale factor for the sprite
    
    return self
end

function Wizard:update(dt)
    -- Update stun timer
    if self.stunTimer > 0 then
        self.stunTimer = math.max(0, self.stunTimer - dt)
        if self.stunTimer == 0 then
            print(self.name .. " is no longer stunned")
        end
    end
    
    -- Update elevation timer
    if self.elevationTimer > 0 and self.elevation == "AERIAL" then
        self.elevationTimer = math.max(0, self.elevationTimer - dt)
        if self.elevationTimer == 0 then
            self.elevation = "GROUNDED"
            print(self.name .. " returned to GROUNDED elevation")
            
            -- Create landing effect using VFX system
            if self.gameState and self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", self.x, self.y + 30, nil, nil, {
                    duration = 0.5,
                    color = {0.7, 0.7, 0.7, 0.8},
                    particleCount = 8,
                    radius = 20
                })
            end
        end
    end
    
    -- Update burn status effect
    if self.statusEffects.burn.active then
        -- Update total time
        self.statusEffects.burn.totalTime = self.statusEffects.burn.totalTime + dt
        
        -- Update elapsed time since last tick
        self.statusEffects.burn.elapsed = self.statusEffects.burn.elapsed + dt
        
        -- Check if it's time for damage tick
        if self.statusEffects.burn.elapsed >= self.statusEffects.burn.tickInterval then
            -- Apply burn damage
            local damage = self.statusEffects.burn.tickDamage
            self.health = math.max(0, self.health - damage)
            
            -- Reset elapsed time
            self.statusEffects.burn.elapsed = 0
            
            -- Log damage
            print(string.format("[BURN] %s takes %d burn damage! (health: %d)", 
                self.name, damage, self.health))
            
            -- Create burn effect using VFX system
            if self.gameState and self.gameState.vfx then
                -- Random position around the wizard for the burn effect
                local angle = math.random() * math.pi * 2
                local distance = math.random(10, 30)
                local effectX = self.x + math.cos(angle) * distance
                local effectY = self.y + math.sin(angle) * distance
                
                self.gameState.vfx.createEffect("impact", effectX, effectY, nil, nil, {
                    duration = 0.3,
                    color = {1.0, 0.4, 0.1, 0.6},
                    particleCount = 3,
                    radius = 10
                })
            end
        end
        
        -- Check if the effect has expired
        if self.statusEffects.burn.totalTime >= self.statusEffects.burn.duration then
            -- Deactivate the effect
            self.statusEffects.burn.active = false
            print(string.format("[STATUS] %s is no longer burning", self.name))
        end
    end
    
    -- Update block VFX
    if self.blockVFX.active then
        self.blockVFX.timer = self.blockVFX.timer - dt
        if self.blockVFX.timer <= 0 then
            self.blockVFX.active = false
        end
    end
    
    -- Update spell cast notification
    if self.spellCastNotification then
        self.spellCastNotification.timer = self.spellCastNotification.timer - dt
        if self.spellCastNotification.timer <= 0 then
            self.spellCastNotification = nil
        end
    end
    
    -- Update spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            -- If the slot is an active shield, just keep it active, and add
            -- shield pulsing effects if needed
            if slot.isShield and slot.progress >= slot.castTime then
                -- For active shields, make tokens orbit their slots
                -- Calculate positions for all tokens in this shield
                local slotYOffsets = {30, 0, -30}
                -- Apply AERIAL offset to shield tokens
                local yOffset = self.currentYOffset or 0
                local slotY = self.y + slotYOffsets[i] + yOffset
                -- Define orbit radii for each slot (same values used in drawSpellSlots)
                local horizontalRadii = {80, 70, 60}  -- Wider at the bottom, narrower at the top  
                local verticalRadii = {20, 25, 30}    -- Flatter at the bottom, rounder at the top
                local radiusX = horizontalRadii[i]
                local radiusY = verticalRadii[i]
                
                -- Move all tokens in a slow orbit
                if #slot.tokens > 0 then
                    -- Make tokens orbit slowly
                    local baseAngle = love.timer.getTime() * 0.3  -- Slow steady rotation
                    local tokenCount = #slot.tokens
                    
                    for j, tokenData in ipairs(slot.tokens) do
                        local token = tokenData.token
                        -- Position tokens evenly around the orbit
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = baseAngle + anglePerToken * (j - 1)
                        
                        -- Calculate 3D position with elliptical projection
                        -- Apply NEAR/FAR positioning offset for tokens as well
                        local xOffset = 0
                        local isNear = self.gameState and self.gameState.rangeState == "NEAR"
                        
                        -- Push wizards closer to center in NEAR mode, further in FAR mode
                        if self.name == "Ashgar" then -- Player 1 (left side)
                            xOffset = isNear and 60 or 0 -- Move right when NEAR
                        else -- Player 2 (right side)
                            xOffset = isNear and -60 or 0 -- Move left when NEAR
                        end
                        
                        token.x = self.x + xOffset + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Update token rotation angle too (spin on its axis)
                        token.rotAngle = token.rotAngle + 0.01  -- Slow spin
                    end
                end
                
                -- Occasionally add subtle visual effects
                if math.random() < 0.01 and self.gameState and self.gameState.vfx then
                    local angle = math.random() * math.pi * 2
                    local radius = math.random(30, 40)
                    
                    -- Apply NEAR/FAR offset to sparkle effects as well
                    local xOffset = 0
                    local isNear = self.gameState and self.gameState.rangeState == "NEAR"
                    
                    -- Push wizards closer to center in NEAR mode, further in FAR mode
                    if self.name == "Ashgar" then -- Player 1 (left side)
                        xOffset = isNear and 60 or 0 -- Move right when NEAR
                    else -- Player 2 (right side)
                        xOffset = isNear and -60 or 0 -- Move left when NEAR
                    end
                    
                    local sparkleX = self.x + xOffset + math.cos(angle) * radius
                    local sparkleY = slotY + math.sin(angle) * radius
                    
                    -- Color based on shield type
                    local effectColor = {0.7, 0.7, 0.7, 0.5}  -- Default gray
                    if slot.defenseType == "barrier" then
                        effectColor = {1.0, 1.0, 0.3, 0.5}  -- Yellow for barriers
                    elseif slot.defenseType == "ward" then
                        effectColor = {0.3, 0.3, 1.0, 0.5}  -- Blue for wards
                    elseif slot.defenseType == "field" then
                        effectColor = {0.3, 1.0, 0.3, 0.5}  -- Green for fields
                    end
                    
                    self.gameState.vfx.createEffect("impact", sparkleX, sparkleY, nil, nil, {
                        duration = 0.3,
                        color = effectColor,
                        particleCount = 2,
                        radius = 5
                    })
                end
                
                -- Continue to next spell slot
                goto continue_next_slot
            end
            
            -- Check if the spell is frozen (by Eclipse Echo)
            if slot.frozen then
                -- Update freeze timer
                slot.freezeTimer = slot.freezeTimer - dt
                
                -- Check if the freeze duration has elapsed
                if slot.freezeTimer <= 0 then
                    -- Unfreeze the spell
                    slot.frozen = false
                    print(self.name .. "'s spell in slot " .. i .. " is no longer frozen")
                    
                    -- Add a visual "unfreeze" effect
                    if self.gameState and self.gameState.vfx then
                        local slotYOffsets = {30, 0, -30}
                        local slotY = self.y + slotYOffsets[i]
                        
                        self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                            duration = 0.5,
                            color = {0.7, 0.7, 1.0, 0.6},
                            particleCount = 10,
                            radius = 35
                        })
                    end
                else
                    -- Spell is still frozen, don't increment progress
                    -- Visual progress arc will appear frozen in place
                    
                    -- Add a subtle frozen visual effect if we have VFX
                    if math.random() < 0.03 and self.gameState and self.gameState.vfx then -- Occasional sparkle
                        local slotYOffsets = {30, 0, -30}
                        local slotY = self.y + slotYOffsets[i]
                        local angle = math.random() * math.pi * 2
                        local radius = math.random(30, 40)
                        local sparkleX = self.x + math.cos(angle) * radius
                        local sparkleY = slotY + math.sin(angle) * radius
                        
                        self.gameState.vfx.createEffect("impact", sparkleX, sparkleY, nil, nil, {
                            duration = 0.3,
                            color = {0.6, 0.6, 1.0, 0.5},
                            particleCount = 3,
                            radius = 5
                        })
                    end
                end
            else
                -- Normal progress update for unfrozen spells
                slot.progress = slot.progress + dt
                
                -- Shield state is now managed directly in the castSpell function
                -- and tokens remain as CHANNELED until the shield is activated
            end
            
            -- If spell finished casting
            if slot.progress >= slot.castTime then
                -- Shield state is now handled in the castSpell function via the 
                -- block keyword's shieldParams and the createShield function
                
                -- Cast the spell
                self:castSpell(i)
                
                -- For non-shield spells, we return tokens and reset the slot
                -- For shield spells, castSpell will handle setting up the shield 
                -- and we won't get here because we'll have the isShield check above
                if not slot.isShield then
                    -- Start return animation for tokens
                    if #slot.tokens > 0 then
                        for _, tokenData in ipairs(slot.tokens) do
                            -- Trigger animation to return token to the mana pool
                            self.manaPool:returnToken(tokenData.index)
                        end
                        
                        -- Clear token list (tokens still exist in the mana pool)
                        slot.tokens = {}
                    end
                    
                    -- Reset slot
                    slot.active = false
                    slot.progress = 0
                    slot.spellType = nil
                    slot.castTime = 0
                end
            end
            
            ::continue_next_slot::
        end
    end
end

function Wizard:draw()
    -- Calculate position adjustments based on elevation and range state
    local yOffset = 0
    local xOffset = 0
    
    -- Vertical adjustment for AERIAL state - increased for more dramatic effect
    if self.elevation == "AERIAL" then
        yOffset = -50  -- Lift the wizard up more significantly when AERIAL
    end
    
    -- Horizontal adjustment for NEAR/FAR state
    local isNear = self.gameState and self.gameState.rangeState == "NEAR"
    local centerX = love.graphics.getWidth() / 2
    
    -- Push wizards closer to center in NEAR mode, further in FAR mode
    if self.name == "Ashgar" then -- Player 1 (left side)
        xOffset = isNear and 60 or 0 -- Move right when NEAR
    else -- Player 2 (right side)
        xOffset = isNear and -60 or 0 -- Move left when NEAR
    end
    
    -- Set color and draw wizard
    if self.stunTimer > 0 then
        -- Apply a yellow/white flash for stunned wizards
        local flashIntensity = 0.5 + math.sin(love.timer.getTime() * 10) * 0.5
        love.graphics.setColor(1, 1, flashIntensity)
    else
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw elevation effect (GROUNDED or AERIAL)
    if self.elevation == "GROUNDED" then
        -- Draw ground indicator below wizard, applying the x offset
        love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        love.graphics.ellipse("fill", self.x + xOffset, self.y + 30, 40, 10)  -- Simple shadow/ground indicator
    end
    
    -- Store current offsets for other functions to use
    self.currentXOffset = xOffset
    self.currentYOffset = yOffset
    
    -- Draw the wizard with appropriate elevation and position
    love.graphics.setColor(1, 1, 1)
    
    -- Flip Selene's sprite horizontally if she's player 2
    local scaleX = self.scale
    if self.name == "Selene" then
        -- Mirror the sprite by using negative scale for the second player
        scaleX = -self.scale
    end
    
    love.graphics.draw(
        self.sprite, 
        self.x + xOffset, self.y + yOffset,  -- Apply both offsets
        0,  -- Rotation
        scaleX, self.scale,  -- Scale x, Scale y (negative x scale for Selene)
        self.sprite:getWidth()/2, self.sprite:getHeight()/2  -- Origin at center
    )
    
    -- Draw aerial effect if applicable
    if self.elevation == "AERIAL" then
        -- Draw aerial effect (clouds, wind lines, etc.)
        love.graphics.setColor(0.8, 0.8, 1, 0.3)
        
        -- Draw cloud-like puffs, applying the xOffset
        for i = 1, 3 do
            local cloudXOffset = math.sin(love.timer.getTime() * 1.5 + i) * 8
            local cloudY = self.y + yOffset + 40 + math.sin(love.timer.getTime() + i) * 3
            love.graphics.circle("fill", self.x + xOffset - 15 + cloudXOffset, cloudY, 8)
            love.graphics.circle("fill", self.x + xOffset + cloudXOffset, cloudY, 10)
            love.graphics.circle("fill", self.x + xOffset + 15 + cloudXOffset, cloudY, 8)
        end
        
        -- No visual timer display here - moved to drawStatusEffects function
    end
    
    -- No longer drawing text elevation indicator - using visual representation only
    
    -- Draw status effects with durations using the new horizontal bar system
    self:drawStatusEffects()
    
    -- Draw block effect when projectile is blocked
    if self.blockVFX.active then
        -- Draw block flash animation
        local progress = self.blockVFX.timer / 0.5  -- Normalize to 0-1
        local size = 80 * (1 - progress)
        love.graphics.setColor(0.7, 0.7, 1, progress * 0.8)
        love.graphics.circle("fill", self.x + xOffset, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.circle("line", self.x + xOffset, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.print("BLOCKED!", self.x + xOffset - 30, self.y + 70)
    end
    
    -- Health bars will now be drawn in the UI system for a more dramatic fighting game style
    
    -- Keyed spell display has been moved to the UI spellbook component
    
    -- Handle shield block and token consumption
function Wizard:handleShieldBlock(slotIndex, blockedSpell)
    -- Get the shield slot
    local slot = self.spellSlots[slotIndex]
    
    -- Check if slot exists and is a valid shield
    if not slot or not slot.isShield then
        print("[SHIELD ERROR] Invalid shield slot: " .. tostring(slotIndex))
        return false
    end
    
    -- Check if shield has tokens
    if #slot.tokens <= 0 then
        print("[SHIELD ERROR] Shield has no tokens to consume")
        return false
    end
    
    -- Determine how many tokens to consume
    local tokensToConsume = 1 -- Default: consume 1 token per hit
    
    -- Shield breaker spells can consume more tokens
    if blockedSpell.shieldBreaker and blockedSpell.shieldBreaker > 1 then
        tokensToConsume = math.min(blockedSpell.shieldBreaker, #slot.tokens)
        print(string.format("[SHIELD BREAKER] Shield breaker consuming up to %d tokens", tokensToConsume))
    end
    
    -- Debug output to track token removal
    print(string.format("[SHIELD DEBUG] Before token removal: Shield has %d tokens", #slot.tokens))
    print(string.format("[SHIELD DEBUG] Will remove %d token(s)", tokensToConsume))
    
    -- Only consume tokens up to the number we have
    tokensToConsume = math.min(tokensToConsume, #slot.tokens)
    
    -- Return tokens back to the mana pool - ONE AT A TIME
    for i = 1, tokensToConsume do
        if #slot.tokens > 0 then
            -- Get the last token
            local lastTokenIndex = #slot.tokens
            local tokenData = slot.tokens[lastTokenIndex]
            
            print(string.format("[SHIELD DEBUG] Consuming token %d from shield (token %d of %d)", 
                tokenData.index, i, tokensToConsume))
            
            -- Important: We DO NOT directly set the token state here
            -- Instead, let the manaPool:returnToken method handle the state transition properly
            
            -- First check token state for debugging
            if tokenData.token then
                print(string.format("[SHIELD DEBUG] Token %d current state: %s", 
                    tokenData.index, tokenData.token.state or "unknown"))
            else
                print("[SHIELD WARNING] Token has no token data object")
            end
            
            -- Trigger animation to return this token to the mana pool
            -- The manaPool:returnToken handles all state changes properly
            if self.manaPool then
                print(string.format("[SHIELD DEBUG] Returning token %d to mana pool", tokenData.index))
                self.manaPool:returnToken(tokenData.index)
            else
                print("[SHIELD ERROR] Could not return token - mana pool not found")
            end
            
            -- Remove this token from the slot's token list
            table.remove(slot.tokens, lastTokenIndex)
            print(string.format("[SHIELD DEBUG] Token %d removed from shield token list (%d tokens remaining)", 
                tokenData.index, #slot.tokens))
        else
            print("[SHIELD ERROR] Tried to consume token but shield has no more tokens!")
            break -- Stop trying to consume tokens if there are none left
        end
    end
    
    print("[SHIELD DEBUG] After token removal: Shield has " .. #slot.tokens .. " tokens left")
    
    -- Create token release VFX
    if self.gameState and self.gameState.vfx then
        self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
            duration = 0.5,
            color = {0.8, 0.8, 0.2, 0.7},
            particleCount = 8,
            radius = 30
        })
    end
    
    -- Check if the shield is depleted (no tokens left)
    if #slot.tokens <= 0 then
        print(string.format("[SHIELD BREAK] %s's %s shield has been broken!", 
            self.name, slot.defenseType))
        
        -- Reset slot completely to avoid half-broken shield state
        print("[SHIELD DEBUG] Resetting slot " .. slotIndex .. " to empty state")
        slot.active = false
        slot.isShield = false
        slot.defenseType = nil
        slot.blocksAttackTypes = nil
        slot.blockTypes = nil  -- Clear block types array too
        slot.progress = 0
        slot.spellType = nil
        slot.spell = nil  -- Clear spell reference too
        slot.castTime = 0
        slot.tokens = {}  -- Ensure it's empty
        
        -- Create shield break effect
        if self.gameState and self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.7,
                color = {1.0, 0.5, 0.5, 0.8},
                particleCount = 15,
                radius = 50
            })
        end
    end
    
    return true
end

-- Draw spell cast notification (temporary until proper VFX)
    if self.spellCastNotification then
        -- Fade out towards the end
        local alpha = math.min(1.0, self.spellCastNotification.timer)
        local color = self.spellCastNotification.color
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        
        -- Draw with a subtle rise effect
        local notifYOffset = 10 * (1 - alpha)  -- Rise up as it fades
        love.graphics.print(self.spellCastNotification.text, 
                           self.spellCastNotification.x + xOffset - 60, 
                           self.spellCastNotification.y - notifYOffset, 
                           0, -- rotation
                           1.5, 1.5) -- scale
    end
    
    -- We'll remove the key indicators from here as they'll be drawn in the UI's spellbook component
    
    -- Save current xOffset and yOffset for other drawing functions
    self.currentXOffset = xOffset
    self.currentYOffset = yOffset
    
    -- Draw spell slots (orbits)
    self:drawSpellSlots()
end

-- Helper function to draw an ellipse
function Wizard:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 32
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

-- Helper function to draw an elliptical arc
function Wizard:drawEllipticalArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
    segments = segments or 16
    
    -- Calculate the angle increment
    local angleRange = endAngle - startAngle
    local angleIncrement = angleRange / segments
    
    -- Create points for the arc
    local points = {}
    
    for i = 0, segments do
        local angle = startAngle + angleIncrement * i
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(points, px)
        table.insert(points, py)
    end
    
    -- Draw the arc as a line
    love.graphics.line(points)
end

-- Draw status effects with durations using horizontal bars
function Wizard:drawStatusEffects()
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Get position offsets from draw function
    local xOffset = self.currentXOffset or 0
    local yOffset = self.currentYOffset or 0
    
    -- Properties for status effect bars
    local barWidth = 130
    local barHeight = 12
    local barSpacing = 18
    local barPadding = 15  -- Additional padding between effect bars
    
    -- Position status bars above the spellbook area
    local baseY = screenHeight - 150  -- Higher up from the spellbook
    local effectCount = 0
    
    -- Determine x position based on which wizard this is, plus the NEAR/FAR offset
    local x = (self.name == "Ashgar") and (150 + xOffset) or (screenWidth - 150 + xOffset)
    
    -- Define colors for different effect types
    local effectColors = {
        aerial = {0.7, 0.7, 1.0, 0.8},
        stun = {1.0, 1.0, 0.1, 0.8},
        shield = {0.5, 0.7, 1.0, 0.8},
        burn = {1.0, 0.4, 0.1, 0.8}
    }
    
    -- Draw AERIAL duration if active
    if self.elevation == "AERIAL" and self.elevationTimer > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress (1.0 to 0.0 as time depletes)
        local maxDuration = 5.0  -- Assuming 5 seconds is max aerial duration
        local progress = self.elevationTimer / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label
        love.graphics.setColor(effectColors.aerial[1], effectColors.aerial[2], effectColors.aerial[3], 
                              effectColors.aerial[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 4)))
        love.graphics.print("AERIAL", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.aerial)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.aerial[1], effectColors.aerial[2], effectColors.aerial[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time text
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs", self.elevationTimer), 
                           x + barWidth/2 - 30, y)
    end
    
    -- Draw STUN duration if active
    if self.stunTimer > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress
        local maxDuration = 2.0  -- Assuming 2 seconds is max stun duration
        local progress = self.stunTimer / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label
        love.graphics.setColor(effectColors.stun[1], effectColors.stun[2], effectColors.stun[3], 
                              effectColors.stun[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 5)))
        love.graphics.print("STUNNED", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.stun)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.stun[1], effectColors.stun[2], effectColors.stun[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time text
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs", self.stunTimer), 
                           x + barWidth/2 - 30, y)
    end
    
    -- Shield display is now handled by the new shield system via shield slots
    
    -- Draw BURN duration if active
    if self.statusEffects.burn.active then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress
        local maxDuration = self.statusEffects.burn.duration
        local progress = 1.0 - (self.statusEffects.burn.totalTime / maxDuration)
        progress = math.max(0.0, progress)  -- Ensure non-negative
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label with pulsing effect
        love.graphics.setColor(effectColors.burn[1], effectColors.burn[2], effectColors.burn[3], 
                              effectColors.burn[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 7)))
        love.graphics.print("BURNING", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.burn)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.burn[1], effectColors.burn[2], effectColors.burn[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time remaining and damage info
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs (%d/tick)", 
                           maxDuration - self.statusEffects.burn.totalTime,
                           self.statusEffects.burn.tickDamage), 
                           x - 20, y)
        
        -- Draw fire particles on the wizard to show the burning effect
        if math.random() < 0.2 and self.gameState and self.gameState.vfx then
            local angle = math.random() * math.pi * 2
            local distance = math.random(10, 30)
            local effectX = self.x + xOffset + math.cos(angle) * distance
            local effectY = self.y + yOffset + math.sin(angle) * distance
            
            self.gameState.vfx.createEffect("impact", effectX, effectY, nil, nil, {
                duration = 0.2,
                color = {1.0, 0.3, 0.1, 0.4},
                particleCount = 2,
                radius = 5
            })
        end
    end
end

function Wizard:drawSpellSlots()
    -- Draw 3 orbiting spell slots as elliptical paths at different vertical positions
    -- Position the slots at legs, midsection, and head levels
    -- Get position offsets from draw function to apply the same offsets as the wizard
    local xOffset = self.currentXOffset or 0
    local yOffset = self.currentYOffset or 0
    local slotYOffsets = {30, 0, -30}  -- From bottom to top
    
    -- Horizontal and vertical radii for each elliptical path
    local horizontalRadii = {80, 70, 60}   -- Wider at the bottom, narrower at the top
    local verticalRadii = {20, 25, 30}     -- Flatter at the bottom, rounder at the top
    
    for i, slot in ipairs(self.spellSlots) do
        -- Position parameters for each slot, applying both offsets
        local slotY = self.y + slotYOffsets[i] + yOffset
        local slotX = self.x + xOffset
        local radiusX = horizontalRadii[i]
        local radiusY = verticalRadii[i]
        
        -- Draw tokens that should appear "behind" the character first
        -- Skip drawing here for shields as those are handled in update
        if slot.active and #slot.tokens > 0 and not slot.isShield then
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            for j, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                if token.animTime >= token.animDuration and not token.returning then
                    local tokenCount = #slot.tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = progressAngle + anglePerToken * (j - 1)
                    
                    -- Only draw tokens that are in the back half (π to 2π)
                    local normalizedAngle = tokenAngle % (math.pi * 2)
                    if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                        -- Calculate 3D position with elliptical projection
                        token.x = slotX + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        token.zOrder = 0  -- Behind the wizard
                        
                        -- Draw token with reduced alpha for "behind" effect
                        love.graphics.setColor(1, 1, 1, 0.5)
                        love.graphics.draw(
                            token.image,
                            token.x, token.y,
                            token.rotAngle,
                            token.scale * 0.8, token.scale * 0.8,  -- Slightly smaller for perspective
                            token.image:getWidth()/2, token.image:getHeight()/2
                        )
                    end
                end
            end
        end
        
        -- Draw the character sprite (handled by the main draw function)
        
        -- If slot is active, draw progress arc and spell name
        if slot.active then
            -- Calculate progress angle (0 to 2*pi)
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            -- Check if it's a shield spell (fully cast)
            if slot.isShield then
                -- Draw a full shield arc with color based on defense type
                local shieldColor
                local shieldName = ""
                
                if slot.defenseType == "barrier" then
                    shieldColor = {1.0, 1.0, 0.3}  -- Yellow for barriers
                    shieldName = "Barrier"
                elseif slot.defenseType == "ward" then 
                    shieldColor = {0.3, 0.3, 1.0}  -- Blue for wards
                    shieldName = "Ward"
                elseif slot.defenseType == "field" then
                    shieldColor = {0.3, 1.0, 0.3}  -- Green for fields
                    shieldName = "Field"
                else
                    shieldColor = {0.8, 0.8, 0.8}  -- Grey fallback
                    shieldName = "Shield"
                end
                
                -- Add pulsing effect for active shields
                local pulseSize = 2 + math.sin(love.timer.getTime() * 3) * 2
                
                -- Draw a slightly larger pulse effect around the orbit
                for j = 1, 3 do
                    local extraSize = j * 2
                    love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.2 - j*0.05)
                    self:drawEllipse(slotX, slotY, radiusX + pulseSize + extraSize, 
                                    radiusY + pulseSize + extraSize, "line")
                end
                
                -- Draw the back half of the shield (reduced alpha)
                love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.4)
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, math.pi * 2, 16)
                
                -- Draw the front half of the shield (full alpha)
                love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.7)
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.pi, 16)
                
                -- Draw shield name (without numeric indicator) above the highest slot
                if i == 3 then
                    love.graphics.setColor(1, 1, 1, 0.8)
                    love.graphics.print(shieldName, slotX - 25, slotY - radiusY - 15)
                end
            
            -- Check if the spell is frozen by Eclipse Echo
            elseif slot.frozen then
                -- Draw frozen indicator - a "stopped" pulse effect around the orbit
                for j = 1, 3 do
                    local pulseSize = 2 + j*1.5
                    love.graphics.setColor(0.5, 0.5, 1.0, 0.2 - j*0.05)
                    
                    -- Draw a slightly larger ellipse to indicate frozen state
                    self:drawEllipse(slotX, slotY, radiusX + pulseSize + math.sin(love.timer.getTime() * 3) * 2, 
                                    radiusY + pulseSize + math.sin(love.timer.getTime() * 3) * 2, "line")
                end
                
                -- Draw the progress arc with a blue/icy color for frozen spells
                -- First the back half of the progress arc (if it extends that far)
                if progressAngle > math.pi then
                    love.graphics.setColor(0.5, 0.5, 1.0, 0.3)  -- Light blue for frozen
                    self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, progressAngle, 16)
                end
                
                -- Then the front half of the progress arc
                love.graphics.setColor(0.5, 0.5, 1.0, 0.7)  -- Light blue for frozen
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.min(progressAngle, math.pi), 16)
            else
                -- Normal progress arc for unfrozen spells
                -- First the back half of the progress arc (if it extends that far)
                if progressAngle > math.pi then
                    love.graphics.setColor(0.8, 0.8, 0.2, 0.3)  -- Lower alpha for back
                    self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, progressAngle, 16)
                end
                
                -- Then the front half of the progress arc
                love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Higher alpha for front
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.min(progressAngle, math.pi), 16)
            end
            
            -- Draw spell name above the highest slot (only for non-shield spells)
            if i == 3 and not slot.isShield then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(slot.spellType, slotX - 20, slotY - radiusY - 15)
            end
            
            -- Draw tokens that should appear "in front" of the character
            -- Skip drawing here for shields as those are handled in update
            if #slot.tokens > 0 and not slot.isShield then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = progressAngle + anglePerToken * (j - 1)
                        
                        -- Only draw tokens that are in the front half (0 to π)
                        local normalizedAngle = tokenAngle % (math.pi * 2)
                        if normalizedAngle >= 0 and normalizedAngle <= math.pi then
                            -- Calculate 3D position with elliptical projection
                            token.x = slotX + math.cos(tokenAngle) * radiusX
                            token.y = slotY + math.sin(tokenAngle) * radiusY
                            token.zOrder = 1  -- In front of the wizard
                            
                            -- Draw token with full alpha for "front" effect
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale, token.scale,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        end
                    end
                end
            end
        else
            -- For inactive slots, only update token positions without drawing orbits
            -- Skip drawing inactive tokens for shield slots - we shouldn't have this case anyway
            if #slot.tokens > 0 and not slot.isShield then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        -- Position tokens on their appropriate paths even when slot is inactive
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = anglePerToken * (j - 1)
                        
                        -- Calculate position based on angle
                        token.x = slotX + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Set z-order based on position
                        local normalizedAngle = tokenAngle % (math.pi * 2)
                        if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                            token.zOrder = 0  -- Behind
                            -- Draw with reduced alpha for "behind" effect
                            love.graphics.setColor(1, 1, 1, 0.5)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale * 0.8, token.scale * 0.8,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        else
                            token.zOrder = 1  -- In front
                            -- Draw with full alpha
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale, token.scale,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        end
                    end
                end
            end
        end
    end
end

-- Handle key press and update currently keyed spell
function Wizard:keySpell(keyIndex, isPressed)
    -- Check if wizard is stunned
    if self.stunTimer > 0 and isPressed then
        print(self.name .. " tried to key a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Update key state
    self.activeKeys[keyIndex] = isPressed
    
    -- Determine current key combination
    local keyCombo = ""
    for i = 1, 3 do
        if self.activeKeys[i] then
            keyCombo = keyCombo .. i
        end
    end
    
    -- Update currently keyed spell based on combination
    if keyCombo == "" then
        self.currentKeyedSpell = nil
    else
        self.currentKeyedSpell = self.spellbook[keyCombo]
        
        -- Log the currently keyed spell
        if self.currentKeyedSpell then
            print(self.name .. " keyed " .. self.currentKeyedSpell.name .. " (" .. keyCombo .. ")")
            
            -- Debug: verify spell definition is complete
            if not self.currentKeyedSpell.cost then
                print("WARNING: Spell '" .. self.currentKeyedSpell.name .. "' has no cost defined!")
            end
        else
            print(self.name .. " has no spell for key combination: " .. keyCombo)
        end
    end
    
    return true
end

-- Cast the currently keyed spell
function Wizard:castKeyedSpell()
    -- Check if wizard is stunned
    if self.stunTimer > 0 then
        print(self.name .. " tried to cast a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Check if a spell is keyed
    if not self.currentKeyedSpell then
        print(self.name .. " tried to cast, but no spell is keyed")
        return false
    end
    
    -- Debug output to identify issues with specific spells
    print("DEBUG: " .. self.name .. " attempting to cast: " .. self.currentKeyedSpell.name)
    print("DEBUG: Spell cost: " .. self:formatCost(self.currentKeyedSpell.cost))
    
    -- Enhanced debugging for ALL spells to identify differences
    print("\nDEBUG: FULL SPELL ANALYSIS:")
    print("  - Name: " .. (self.currentKeyedSpell.name or "nil"))
    print("  - ID: " .. (self.currentKeyedSpell.id or "nil"))
    print("  - Cost type: " .. type(self.currentKeyedSpell.cost))
    print("  - Attack Type: " .. (self.currentKeyedSpell.attackType or "nil"))
    print("  - Has isShield: " .. tostring(self.currentKeyedSpell.isShield ~= nil))
    if self.currentKeyedSpell.isShield ~= nil then
        print("  - isShield value: " .. tostring(self.currentKeyedSpell.isShield))
    end
    print("  - Has effect func: " .. tostring(type(self.currentKeyedSpell.effect) == "function"))
    print("  - Has keywords: " .. tostring(self.currentKeyedSpell.keywords ~= nil))
    if self.currentKeyedSpell.keywords and self.currentKeyedSpell.keywords.block then
        print("  - Has block keyword")
        print("  - Block type: " .. (self.currentKeyedSpell.keywords.block.type or "nil"))
    else
        print("  - No block keyword")
    end
    
    -- Queue the keyed spell with detailed error handling
    print("DEBUG: Calling queueSpell...")
    local success, result = pcall(function() 
        return self:queueSpell(self.currentKeyedSpell)
    end)
    
    -- Debug the result of queueSpell
    if not success then
        print("ERROR: Exception in queueSpell: " .. tostring(result))
        print("ERROR TRACE: " .. debug.traceback())
        return false
    elseif not result then
        print("DEBUG: Failed to queue " .. self.currentKeyedSpell.name .. " - check if manaCost check failed")
    else
        print("DEBUG: Successfully queued " .. self.currentKeyedSpell.name)
    end
    
    return result
end

-- Helper to format spell cost for debug output
function Wizard:formatCost(cost)
    local costText = ""
    for i, costComponent in ipairs(cost) do
        if type(costComponent) == "string" then
            -- New format
            costText = costText .. costComponent
        else
            -- Old format
            costText = costText .. costComponent.type .. " x" .. costComponent.count
        end
        
        if i < #cost then
            costText = costText .. ", "
        end
    end
    
    if costText == "" then
        return "Free"
    else
        return costText
    end
end

function Wizard:queueSpell(spell)
    print("DEBUG: " .. self.name .. " queueSpell called for " .. (spell and spell.name or "nil spell"))
    
    -- Check if wizard is stunned
    if self.stunTimer > 0 then
        print(self.name .. " tried to queue a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Validate the spell
    if not spell then
        print("No spell provided to queue")
        return false
    end
    
    -- Get the compiled spell if available
    local spellToUse = spell
    if spell.id and not spell.executeAll then
        -- This is an original spell definition, not a compiled one - get the compiled version
        local compiledSpell = getCompiledSpell(spell.id, self)
        if compiledSpell then
            spellToUse = compiledSpell
            print("Using compiled spell for queue: " .. spellToUse.id)
        else
            print("Warning: Using original spell definition - could not get compiled version of " .. spell.id)
        end
    end
    
    -- Find the innermost available spell slot
    print("DEBUG: Checking for available spell slots...")
    for i = 1, #self.spellSlots do
        print("DEBUG: Checking slot " .. i .. ": " .. (self.spellSlots[i].active and "ACTIVE" or "AVAILABLE"))
        if not self.spellSlots[i].active then
            print("DEBUG: Found available slot " .. i .. ", checking mana cost...")
            -- Check if we can pay the mana cost from the pool
            local tokenReservations = self:canPayManaCost(spell.cost)
            
            -- Debug info for mana cost checks
            if not tokenReservations then
                print("DEBUG: Cannot pay mana cost for " .. spell.name)
                if type(spell.cost) == "table" then
                    for j, component in ipairs(spell.cost) do
                        print("DEBUG: - Cost component " .. j .. ": " .. tostring(component))
                    end
                else
                    print("DEBUG: Cost is not a table: " .. tostring(spell.cost))
                end
            end
            
            if tokenReservations then
                -- Collect the actual tokens to animate them to the spell slot
                local tokens = {}
                
                -- Move each token from mana pool to spell slot with animation
                for _, reservation in ipairs(tokenReservations) do
                    local token = self.manaPool.tokens[reservation.index]
                    
                    -- Mark the token as being channeled
                    token.state = "CHANNELED"
                    
                    -- Store original position for animation
                    token.startX = token.x
                    token.startY = token.y
                    
                    -- Calculate target position in the spell slot based on 3D positioning
                    -- These must match values in drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}
                    local verticalRadii = {20, 25, 30}
                    
                    local targetX = self.x
                    local targetY = self.y + slotYOffsets[i]  -- Vertical offset based on slot
                    
                    -- Animation data
                    token.targetX = targetX
                    token.targetY = targetY
                    token.animTime = 0
                    token.animDuration = 0.5 -- Half second animation
                    token.slotIndex = i
                    token.tokenIndex = #tokens + 1 -- Position in the slot
                    token.spellSlot = i
                    token.wizardOwner = self
                    
                    -- 3D perspective data
                    token.radiusX = horizontalRadii[i]
                    token.radiusY = verticalRadii[i]
                    
                    table.insert(tokens, {token = token, index = reservation.index})
                end
                
                -- Successfully paid the cost, queue the spell
                self.spellSlots[i].active = true
                self.spellSlots[i].progress = 0
                self.spellSlots[i].spellType = spellToUse.name
                
                -- Use dynamic cast time if available, otherwise use static cast time
                if spellToUse.getCastTime and type(spellToUse.getCastTime) == "function" then
                    self.spellSlots[i].castTime = spellToUse.getCastTime(self)
                    print(self.name .. " is using dynamic cast time: " .. self.spellSlots[i].castTime .. "s")
                else
                    self.spellSlots[i].castTime = spellToUse.castTime
                end
                
                self.spellSlots[i].spell = spellToUse
                self.spellSlots[i].tokens = tokens
                
                -- Check if this is a shield spell and mark it accordingly
                if spellToUse.isShield or (spellToUse.keywords and spellToUse.keywords.block) then
                    print("SHIELD SPELL DETECTED during queue: " .. spellToUse.name)
                    -- Flag that this will become a shield when cast
                    self.spellSlots[i].willBecomeShield = true
                    
                    -- DO NOT mark tokens as SHIELDING yet - let them orbit normally during casting
                    -- Only mark them as SHIELDING after the spell is fully cast
                    
                    -- Mark this in the compiled spell if not already marked
                    if not spellToUse.isShield then
                        spellToUse.isShield = true
                    end
                end
                
                -- Set attackType if present in the new schema
                if spellToUse.attackType then
                    self.spellSlots[i].attackType = spellToUse.attackType
                end
                
                print(self.name .. " queued " .. spellToUse.name .. " in slot " .. i .. " (cast time: " .. spellToUse.castTime .. "s)")
                return true
            else
                -- Couldn't pay the cost
                print(self.name .. " tried to queue " .. spellToUse.name .. " but couldn't pay the mana cost")
                return false
            end
        end
    end
    
    -- No available slots
    print(self.name .. " tried to queue " .. spellToUse.name .. " but all slots are full")
    return false
end

-- Helper function to create a shield from spell params
local function createShield(wizard, spellSlot, shieldParams)
    local slot = wizard.spellSlots[spellSlot]
    
    -- Set basic shield properties
    slot.isShield = true
    slot.defenseType = shieldParams.defenseType or "barrier"
    
    -- Set up blocksAttackTypes if not already set
    slot.blockTypes = shieldParams.blocksAttackTypes or {"projectile"}
    slot.blocksAttackTypes = {}
    for _, attackType in ipairs(slot.blockTypes) do
        slot.blocksAttackTypes[attackType] = true
    end
    
    -- Handle reflect property
    slot.reflect = shieldParams.reflect or false
    
    -- Mark tokens as SHIELDING
    for _, tokenData in ipairs(slot.tokens) do
        if tokenData.token then
            tokenData.token.state = "SHIELDING"
            -- Add specific shield type info to the token for visual effects
            tokenData.token.shieldType = slot.defenseType
        end
    end
    
    -- Mark the shield as fully cast
    slot.progress = slot.castTime
    
    -- Create shield activated visual effect
    if wizard.gameState and wizard.gameState.vfx then
        local shieldColor
        if slot.defenseType == "barrier" then
            shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Yellow for barriers
        elseif slot.defenseType == "ward" then
            shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
        elseif slot.defenseType == "field" then
            shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
        else
            shieldColor = {0.8, 0.8, 0.8, 0.7}  -- Default gray
        end
        
        wizard.gameState.vfx.createEffect("shield", wizard.x, wizard.y, nil, nil, {
            duration = 0.7,
            color = shieldColor,
            shieldType = slot.defenseType
        })
    end
    
    print(string.format("[SHIELD] %s activated a %s shield with %d tokens", 
        wizard.name, slot.defenseType, #slot.tokens))
end

-- Free all active spells and return their mana to the pool
function Wizard:freeAllSpells()
    print(self.name .. " is freeing all active spells")
    
    -- Iterate through all spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            -- Return tokens to the mana pool
            if #slot.tokens > 0 then
                for _, tokenData in ipairs(slot.tokens) do
                    -- Trigger animation to return token to the mana pool
                    self.manaPool:returnToken(tokenData.index)
                end
                
                -- Clear token list (tokens still exist in the mana pool)
                slot.tokens = {}
            end
            
            -- Reset slot properties
            slot.active = false
            slot.progress = 0
            slot.spellType = nil
            slot.castTime = 0
            slot.spell = nil
            
            -- Reset shield-specific properties if applicable
            if slot.isShield then
                slot.isShield = false
                slot.defenseType = nil
                slot.blocksAttackTypes = nil
                slot.shieldStrength = 0
            end
            
            -- Reset any frozen state
            if slot.frozen then
                slot.frozen = false
                slot.freezeTimer = 0
            end
            
            print("Freed spell in slot " .. i)
        end
    end
    
    -- Create visual effect for all spells being canceled
    if self.gameState and self.gameState.vfx then
        self.gameState.vfx.createEffect("free_mana", self.x, self.y, nil, nil)
    end
    
    -- Reset active key inputs
    for i = 1, 3 do
        self.activeKeys[i] = false
    end
    
    -- Clear keyed spell
    self.currentKeyedSpell = nil
    
    return true
end

-- Helper function to check if mana cost can be paid without actually taking the tokens
function Wizard:canPayManaCost(cost)
    local tokenReservations = {}
    local reservedIndices = {} -- Track which token indices are already reserved
    
    -- Debug output for cost checking
    print("DEBUG: Checking mana cost payment for " .. (self.currentKeyedSpell and self.currentKeyedSpell.name or "unknown spell"))
    
    -- Handle cost being nil or not a table
    if not cost then
        print("DEBUG: Cost is nil")
        return {}
    end
    
    -- Check if cost is a valid table we can iterate through
    if type(cost) ~= "table" then
        print("DEBUG: Cost is not a table, it's a " .. type(cost))
        return nil
    end
    
    -- Early exit if cost is empty
    if #cost == 0 then 
        print("DEBUG: Cost is an empty table")
        return {} 
    end
    
    -- Dump the exact cost structure to understand what's being passed
    print("DEBUG: Cost structure details:")
    print("DEBUG: - Type: " .. type(cost))
    print("DEBUG: - Length: " .. #cost)
    for i, component in ipairs(cost) do
        print("DEBUG: - Component " .. i .. " type: " .. type(component))
        print("DEBUG: - Component " .. i .. " value: " .. tostring(component))
    end
    
    -- Print existing tokens in mana pool for debugging
    print("DEBUG: Mana pool contains " .. #self.manaPool.tokens .. " tokens:")
    local tokenCounts = {}
    for _, token in ipairs(self.manaPool.tokens) do
        if token.state == "FREE" then
            tokenCounts[token.type] = (tokenCounts[token.type] or 0) + 1
        end
    end
    for tokenType, count in pairs(tokenCounts) do
        print("DEBUG: - " .. tokenType .. ": " .. count .. " free tokens")
    end
    
    -- This function mirrors payManaCost but just returns the indices of tokens that would be used
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType, costCount
        
        -- Handle both old and new cost formats
        if type(costComponent) == "string" then
            -- New format: simple string token type
            costType = costComponent
            costCount = 1
        else
            -- Old format: table with type and count
            costType = costComponent.type
            costCount = costComponent.count
        end
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Try to get tokens of this type (that aren't already reserved)
                local availableTokens = {}
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.type == modalType and token.state == "FREE" and not reservedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                if #availableTokens >= costCount then
                    -- We have enough tokens to pay this cost
                    for i = 1, costCount do
                        local tokenData = availableTokens[i]
                        table.insert(tokenReservations, tokenData)
                        reservedIndices[tokenData.index] = true -- Mark as reserved
                    end
                    paid = true
                    break
                end
            end
            
            if not paid then
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available token types that aren't already reserved
                local availableTokens = {}
                
                -- Check each token and gather available ones that haven't been reserved yet
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.state == "FREE" and not reservedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTokens > 0 then
                    -- Shuffle the available tokens for true randomness
                    for i = #availableTokens, 2, -1 do
                        local j = math.random(i)
                        availableTokens[i], availableTokens[j] = availableTokens[j], availableTokens[i]
                    end
                    
                    -- Use the first token after shuffling
                    local tokenData = availableTokens[1]
                    table.insert(tokenReservations, tokenData)
                    reservedIndices[tokenData.index] = true -- Mark as reserved
                else
                    return nil
                end
            end
        else
            -- Specific type cost
            -- Get all the free tokens of this type first
            local availableTokens = {}
            for i, token in ipairs(self.manaPool.tokens) do
                if token.type == costType and token.state == "FREE" and not reservedIndices[i] then
                    table.insert(availableTokens, {token = token, index = i})
                end
            end
            
            -- Check if we have enough tokens
            if #availableTokens < costCount then
                return nil  -- Not enough tokens of this type
            end
            
            -- Add the required number of tokens to our reservations
            for i = 1, costCount do
                local tokenData = availableTokens[i]
                table.insert(tokenReservations, tokenData)
                reservedIndices[tokenData.index] = true -- Mark as reserved
            end
        end
    end
    
    return tokenReservations
end

-- Helper function to check and pay mana costs
function Wizard:payManaCost(cost)
    local tokens = {}
    local usedIndices = {} -- Track which token indices are already used
    
    -- Early exit if cost is empty
    if not cost or #cost == 0 then 
        print("DEBUG: Cost is nil or empty")
        return {} 
    end
    
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType, costCount
        
        -- Handle both old and new cost formats
        if type(costComponent) == "string" then
            -- New format: simple string token type
            costType = costComponent
            costCount = 1
        else
            -- Old format: table with type and count
            costType = costComponent.type
            costCount = costComponent.count
        end
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Collect all available tokens of this type that haven't been used yet
                local availableTokens = {}
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.type == modalType and token.state == "FREE" and not usedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                if #availableTokens >= costCount then
                    -- We have enough tokens to pay this cost
                    for i = 1, costCount do
                        local tokenData = availableTokens[i]
                        local token = self.manaPool.tokens[tokenData.index]
                        token.state = "CHANNELED" -- Mark as being used
                        table.insert(tokens, {token = token, index = tokenData.index})
                        usedIndices[tokenData.index] = true -- Mark as used
                    end
                    paid = true
                    break
                end
            end
            
            if not paid then
                -- Failed to pay modal cost, return tokens to pool
                for _, tokenData in ipairs(tokens) do
                    self.manaPool:returnToken(tokenData.index)
                end
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available tokens that haven't been used yet
                local availableTokens = {}
                
                -- Check each token and gather available ones
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.state == "FREE" and not usedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTokens > 0 then
                    -- Shuffle the available tokens for true randomness
                    for i = #availableTokens, 2, -1 do
                        local j = math.random(i)
                        availableTokens[i], availableTokens[j] = availableTokens[j], availableTokens[i]
                    end
                    
                    -- Use the first token after shuffling
                    local tokenData = availableTokens[1]
                    local token = self.manaPool.tokens[tokenData.index]
                    token.state = "CHANNELED" -- Mark as being used
                    table.insert(tokens, {token = token, index = tokenData.index})
                    usedIndices[tokenData.index] = true -- Mark as used
                else
                    -- No available tokens, return already collected tokens
                    for _, tokenData in ipairs(tokens) do
                        self.manaPool:returnToken(tokenData.index)
                    end
                    return nil
                end
            end
        else
            -- Specific type cost
            -- First gather all available tokens of this type
            local availableTokens = {}
            for i, token in ipairs(self.manaPool.tokens) do
                if token.type == costType and token.state == "FREE" and not usedIndices[i] then
                    table.insert(availableTokens, {token = token, index = i})
                end
            end
            
            -- Check if we have enough tokens
            if #availableTokens < costCount then
                -- Failed to find enough tokens, return any collected tokens to pool
                for _, tokenData in ipairs(tokens) do
                    self.manaPool:returnToken(tokenData.index)
                end
                return nil
            end
            
            -- Get the required number of tokens and mark them as CHANNELED
            for i = 1, costCount do
                local tokenData = availableTokens[i]
                local token = self.manaPool.tokens[tokenData.index]
                token.state = "CHANNELED"  -- Mark as being used
                table.insert(tokens, {token = token, index = tokenData.index})
                usedIndices[tokenData.index] = true -- Mark as used
            end
        end
    end
    
    -- Successfully paid all costs
    return tokens
end

function Wizard:castSpell(spellSlot)
    local slot = self.spellSlots[spellSlot]
    if not slot or not slot.active or not slot.spell then return end
    
    print(self.name .. " cast " .. slot.spellType .. " from slot " .. spellSlot)
    
    -- Create a temporary visual notification for spell casting
    self.spellCastNotification = {
        text = self.name .. " cast " .. slot.spellType,
        timer = 2.0,  -- Show for 2 seconds
        x = self.x,
        y = self.y + 70, -- Moved below the wizard instead of above
        color = {self.color[1]/255, self.color[2]/255, self.color[3]/255, 1.0}
    }
    
    -- Get target (the other wizard)
    local target = nil
    for _, wizard in ipairs(self.gameState.wizards) do
        if wizard ~= self then
            target = wizard
            break
        end
    end
    
    if not target then return end
    
    -- Get the spell (either compiled or original)
    local spellToUse = slot.spell
    
    -- Convert to compiled spell if needed
    if spellToUse.id and not spellToUse.executeAll then
        -- This is an original spell, not a compiled one - get the compiled version
        local compiledSpell = getCompiledSpell(spellToUse.id, self)
        if compiledSpell then
            spellToUse = compiledSpell
            -- Store the compiled spell back in the slot for future use
            slot.spell = compiledSpell
            print("Using compiled spell: " .. spellToUse.id)
        else
            print("Warning: Falling back to original spell - could not get compiled version of " .. spellToUse.id)
        end
    end
    
    -- Get attack type for shield checking
    local attackType = spellToUse.attackType or "projectile"
    
    -- Check if the spell can be blocked by any of the target's shields
    -- This now happens BEFORE spell execution per ticket PROG-20
    local blockInfo = checkShieldBlock(spellToUse, attackType, target, self)
    
    -- If blockable, handle block effects and exit early
    if blockInfo.blockable then
        print(string.format("[SHIELD] %s's %s was blocked by %s's %s shield!", 
            self.name, spellToUse.name, target.name, blockInfo.blockType or "unknown"))
        
        local effect = {
            blocked = true,
            blockType = blockInfo.blockType
        }
        
        -- Add VFX for shield block
        -- Create spell impact effect on the caster to show the spell being blocked
        if self.gameState.vfx then
            -- Shield color based on type
            local shieldColor = {0.8, 0.8, 0.8, 0.7}  -- Default gray
            if blockInfo.blockType == "barrier" then
                shieldColor = {1.0, 1.0, 0.3, 0.7}    -- Yellow for barriers
            elseif blockInfo.blockType == "ward" then
                shieldColor = {0.3, 0.3, 1.0, 0.7}    -- Blue for wards
            elseif blockInfo.blockType == "field" then 
                shieldColor = {0.3, 1.0, 0.3, 0.7}    -- Green for fields
            end
            
            -- Create visual effect on the target to show the block
            self.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
                duration = 0.5,
                color = shieldColor,
                shieldType = blockInfo.blockType
            })
            
            -- Create spell impact effect on the caster
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.3,
                color = {0.8, 0.2, 0.2, 0.5},
                particleCount = 5,
                radius = 15
            })
        end
        
        -- Use the new centralized handleShieldBlock method to handle token consumption
        target:handleShieldBlock(blockInfo.blockingSlot, spellToUse)
        
        -- Return tokens from our spell slot
        if #slot.tokens > 0 then
            for _, tokenData in ipairs(slot.tokens) do
                -- Trigger animation to return token to the mana pool
                self.manaPool:returnToken(tokenData.index)
            end
            -- Clear token list
            slot.tokens = {}
        end
        
        -- Reset our slot
        slot.active = false
        slot.progress = 0
        slot.spellType = nil
        slot.castTime = 0
        
        -- Skip further execution and return the effect
        return effect
    end
    
    -- Execute spell behavior using the compiled spell if available
    local effect = {}
    if spellToUse.executeAll then
        -- Use the compiled spell's executeAll method
        effect = spellToUse.executeAll(self, target, {}, spellSlot)
        print("Executed compiled spell: " .. spellToUse.name)
    else
        -- Fall back to the legacy keyword system for compatibility
        effect = SpellsModule.keywordSystem.castSpell(
            slot.spell,
            self,
            {
                opponent = target,
                spellSlot = spellSlot,
                debug = false  -- Set to true for detailed logging
            }
        )
        print("Executed spell via legacy system: " .. spellToUse.name)
    end
    
    -- Check if this is a shield spell with shieldParams from the block keyword
    if effect.shieldParams and effect.shieldParams.createShield then
        print("[SHIELD] Creating shield from shieldParams")
        
        -- Call createShield function with the parameters
        createShield(self, spellSlot, effect.shieldParams)
        
        -- Return early - don't reset the slot or return tokens
        return
    end
    
    -- Handle block effects from the block keyword within the spell execution
    -- This covers cases where the block is performed within the spell execution
    -- rather than by our shield detection system above
    if effect.blocked then
        -- Our preemptive shield check should have caught this, but
        -- handle it gracefully anyway for backward compatibility
        
        print("Note: Spell was blocked during execution (legacy block logic)")
        
        local shieldBreakPower = effect.shieldBreakPower or 1
        local shieldDestroyed = effect.shieldDestroyed or false
        
        if shieldDestroyed then
            print(string.format("[BLOCKED] %s's %s was blocked by %s's %s which has been DESTROYED!", 
                self.name, slot.spellType, target.name, effect.blockType or "shield"))
                
            -- Create shield break visual effect on the target
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                    duration = 0.7,
                    color = {1.0, 0.5, 0.5, 0.8},
                    particleCount = 15,
                    radius = 50
                })
            end
        else
            if shieldBreakPower > 1 then
                print(string.format("[BLOCKED] %s's %s was blocked by %s's %s! (shield took %d hits)", 
                    self.name, slot.spellType, target.name, effect.blockType or "shield", shieldBreakPower))
            else
                print(string.format("[BLOCKED] %s's %s was blocked by %s's %s", 
                    self.name, slot.spellType, target.name, effect.blockType or "shield"))
            end
            
            -- Create blocked visual effect at the shield
            if self.gameState.vfx then
                -- Shield color based on type
                local shieldColor = {0.8, 0.8, 0.8, 0.7}  -- Default gray
                if effect.blockType == "barrier" then
                    shieldColor = {1.0, 1.0, 0.3, 0.7}    -- Yellow for barriers
                elseif effect.blockType == "ward" then
                    shieldColor = {0.3, 0.3, 1.0, 0.7}    -- Blue for wards
                elseif effect.blockType == "field" then 
                    shieldColor = {0.3, 1.0, 0.3, 0.7}    -- Green for fields
                end
                
                -- Create visual effect on the target to show the block
                self.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
                    duration = 0.5,
                    color = shieldColor,
                    shieldType = effect.blockType
                })
            end
        end
        
        -- Create spell impact effect on the caster to show the spell being blocked
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.3,
                color = {0.8, 0.2, 0.2, 0.5},
                particleCount = 5,
                radius = 15
            })
        end
        
        -- Skip further processing - tokens have already been returned by the blocking logic
        return
    end
    
    -- Check if the spell missed (for zone spells with zoneAnchor)
    if effect.missed then
        print(string.format("[MISSED] %s's %s missed due to range/elevation mismatch", 
            self.name, slot.spellType))
        
        -- Create whiff visual effect
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.3,
                color = {0.5, 0.5, 0.5, 0.3},
                particleCount = 3,
                radius = 10
            })
        end
    end
    
    -- Handle token dissipation from the dissipate keyword
    if effect.dissipate then
        local tokenType = effect.dissipateType or "any"
        local amount = effect.dissipateAmount or 1
        local tokensDestroyed = effect.tokensDestroyed or 0
        
        if tokensDestroyed > 0 then
            print("Destroyed " .. tokensDestroyed .. " " .. tokenType .. " tokens")
        else
            print("No matching " .. tokenType .. " tokens found to destroy")
        end
    end
    
    -- Handle burn effects from the burn keyword
    if effect.burnApplied then
        -- Apply burn status effect to target
        target.statusEffects.burn.active = true
        target.statusEffects.burn.duration = effect.burnDuration or 3.0
        target.statusEffects.burn.tickDamage = effect.burnTickDamage or 2
        target.statusEffects.burn.tickInterval = effect.burnTickInterval or 1.0
        target.statusEffects.burn.elapsed = 0
        target.statusEffects.burn.totalTime = 0
        
        print(string.format("[STATUS] %s is burning! (%d damage per %.1f sec for %.1f sec)",
            target.name, 
            target.statusEffects.burn.tickDamage,
            target.statusEffects.burn.tickInterval,
            target.statusEffects.burn.duration))
        
        -- Create initial burn effect
        if self.gameState and self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.6,
                color = {1.0, 0.3, 0.1, 0.8},
                particleCount = 12,
                radius = 35
            })
        end
    end
    
    -- Handle spell freeze effect from the freeze keyword
    if effect.freezeApplied then
        local targetSlot = effect.targetSlot or 2  -- Default to middle slot
        local freezeDuration = effect.freezeDuration or 2.0
        
        -- Check if the target slot exists and is active
        if self.spellSlots[targetSlot] and self.spellSlots[targetSlot].active then
            local slot = self.spellSlots[targetSlot]
            
            -- Add the frozen flag and timer
            slot.frozen = true
            slot.freezeTimer = freezeDuration
            
            print(slot.spellType .. " in slot " .. targetSlot .. " frozen for " .. freezeDuration .. " seconds")
            
            -- Add visual effect for the frozen spell
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlot]
                
                -- Create a clear visual effect to show freeze
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 1.2,
                    color = {0.3, 0.3, 0.8, 0.7},
                    particleCount = 20,
                    radius = 50
                })
            end
        else
            print("No active spell found in slot " .. targetSlot .. " to freeze")
        end
    end
    
    -- Handle disjoint effect (spell cancellation with mana destruction)
    if effect.disjoint then
        local targetSlot = effect.targetSlot or 0
        
        -- Handle the case where targetSlot is a function (from the compiled spell)
        if type(targetSlot) == "function" then
            -- Call the function with proper parameters
            local slot_func_result = targetSlot(self, target, spellSlot)
            -- Convert the result to a number (in case it returns a string)
            targetSlot = tonumber(slot_func_result) or 0
            print("Disjoint slot function returned: " .. targetSlot)
        end
        
        -- If targetSlot is 0 or invalid, find the first active slot
        if targetSlot == 0 or type(targetSlot) ~= "number" then
            for i, slot in ipairs(target.spellSlots) do
                if slot.active then
                    targetSlot = i
                    break
                end
            end
        end
        
        -- Ensure targetSlot is a valid number before comparison
        targetSlot = tonumber(targetSlot) or 0
        
        -- Check if the target slot exists and is active
        if targetSlot > 0 and targetSlot <= #target.spellSlots and target.spellSlots[targetSlot].active then
            local slot = target.spellSlots[targetSlot]
            
            -- Store data for feedback
            local spellName = slot.spellType or "spell"
            local tokenCount = #slot.tokens
            
            -- Destroy the mana tokens instead of returning them to the pool
            for _, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                if token then
                    -- Mark the token as destroyed
                    token.state = "DESTROYED"
                    token.gameState = self.gameState  -- Give the token access to gameState for VFX
                    
                    -- Create immediate destruction VFX
                    if self.gameState.vfx then
                        self.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                            duration = 0.5,
                            color = {0.8, 0.6, 1.0, 0.7},  -- Purple for lunar theme
                            particleCount = 10,
                            radius = 20
                        })
                    end
                end
            end
            
            -- Cancel the spell, emptying the slot
            slot.active = false
            slot.progress = 0
            slot.tokens = {}
            
            -- Create visual effect at the spell slot position
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = target.y + slotYOffsets[targetSlot]
                
                -- Create a visual effect for the disjunction
                self.gameState.vfx.createEffect("disjoint_cancel", target.x, slotY, nil, nil)
            end
            
            print(self.name .. " disjointed " .. target.name .. "'s " .. spellName .. 
                  " in slot " .. targetSlot .. ", destroying " .. tokenCount .. " mana tokens")
        else
            print("No active spell found in slot " .. targetSlot .. " to disjoint")
        end
    end
    
    -- Create visual effect based on spell type
    if self.gameState.vfx then
        self.gameState.vfx.createSpellEffect(slot.spell, self, target)
    end
    
    -- Check if it's a shield spell that should persist in the spell slot
    if slot.spell.isShield or effect.isShield or isShieldSpell then
        -- Mark this as a shield spell (for the end of the function)
        isShieldSpell = true
        
        -- Mark the progress as completed
        slot.progress = slot.castTime  -- Mark as fully cast
        
        -- Debug shield creation process
        print("DEBUG: Creating shield from spell: " .. slot.spellType)
        
        -- Check if we have shieldCreated flag which means the shield was already
        -- created by the block keyword handler
        if not effect.shieldCreated then
            -- Extract shield params from effect or keywords
            local defenseType = "barrier"
            local blocks = {"projectile"}
            local manaLinked = true
            local reflect = false
            local hitPoints = nil
            
            -- Get shield parameters from effect or spell
            if effect.defenseType then
                defenseType = effect.defenseType
            elseif slot.spell.defenseType then
                defenseType = slot.spell.defenseType
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.type then
                defenseType = slot.spell.keywords.block.type
            end
            
            -- Get blocks from effect or spell
            if effect.blockTypes then
                blocks = effect.blockTypes
            elseif slot.spell.blockableBy then
                blocks = slot.spell.blockableBy
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.blocks then
                blocks = slot.spell.keywords.block.blocks
            end
            
            -- Get manaLinked from effect or spell
            if effect.manaLinked ~= nil then
                manaLinked = effect.manaLinked
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.manaLinked ~= nil then
                manaLinked = slot.spell.keywords.block.manaLinked
            end
            
            -- Get reflect from effect or spell
            if effect.reflect ~= nil then
                reflect = effect.reflect
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.reflect ~= nil then
                reflect = slot.spell.keywords.block.reflect
            end
            
            -- Get hitPoints from effect or spell
            if effect.shieldStrength then
                hitPoints = effect.shieldStrength
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.hitPoints then
                hitPoints = slot.spell.keywords.block.hitPoints
            end
            
            -- Use our central shield creation function to set up the shield
            local blockParams = {
                type = defenseType,
                blocks = blocks,
                reflect = reflect
                -- manaLinked and hitPoints no longer needed - token count is source of truth
            }
            
            print("DEBUG: Shield parameters:")
            print("DEBUG: - Type: " .. defenseType)
            print("DEBUG: - Reflect: " .. tostring(reflect))
            print("DEBUG: - Tokens: " .. #slot.tokens .. " (token count is shield strength)")
            
            -- Call the shield creation function - this centralizes all shield setup logic
            createShield(self, spellSlot, blockParams)
        end
        
        -- Force the isShield flag to be true for any shield spells
        -- This ensures tokens stay attached to the shield
        slot.isShield = true
        
        -- Apply elevation change if the shield spell includes that effect
        -- This handles both explicit elevation effects and those from the elevate keyword
        -- For Mist Veil, ensure elevate keyword is properly recognized
        if effect.setElevation or (effect.elevate and effect.elevate.active) or (slot.spell.keywords and slot.spell.keywords.elevate) then
            -- Determine the target for elevation changes based on keyword settings
            local elevationTarget
            
            -- Explicit targeting from keyword resolution
            if effect.elevationTarget then
                if effect.elevationTarget == "SELF" then
                    elevationTarget = self
                elseif effect.elevationTarget == "ENEMY" then
                    elevationTarget = target
                else
                    -- Default to self if target specification is invalid
                    elevationTarget = self
                    print("Warning: Unknown elevation target type: " .. tostring(effect.elevationTarget))
                end
            else
                -- Legacy behavior if no explicit target (for backward compatibility)
                elevationTarget = effect.setElevation == "GROUNDED" and target or self
            end
            
            -- Record if this is changing from AERIAL (for VFX)
            local wasAerial = elevationTarget.elevation == "AERIAL"
            
            -- Apply the elevation change
            local newElevation
            if effect.setElevation then
                newElevation = effect.setElevation
            elseif effect.elevate and effect.elevate.active then
                newElevation = "AERIAL"
            else
                newElevation = "AERIAL" -- Default to AERIAL if we got here without a specific elevation
            end
            
            elevationTarget.elevation = newElevation
            
            -- Set duration for elevation change if provided
            local elevationDuration
            if effect.elevationDuration then
                elevationDuration = effect.elevationDuration
            elseif effect.elevate and effect.elevate.duration then
                elevationDuration = effect.elevate.duration
            elseif slot.spell.keywords and slot.spell.keywords.elevate and slot.spell.keywords.elevate.duration then
                elevationDuration = slot.spell.keywords.elevate.duration
            end
            
            if elevationDuration and elevationTarget.elevation == "AERIAL" then
                elevationTarget.elevationTimer = elevationDuration
                print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation for " .. elevationDuration .. " seconds")
            else
                -- No duration specified, treat as permanent until changed by another spell
                elevationTarget.elevationTimer = 0
                print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation")
            end
            
            -- Create appropriate visual effect for elevation change
            if self.gameState.vfx then
                if effect.setElevation == "AERIAL" then
                    -- Effect for rising into the air (use specified VFX or default)
                    local vfxName = effect.elevationVfx or "emberlift"
                    self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
                elseif effect.setElevation == "GROUNDED" and wasAerial then
                    -- Effect for forcing down to the ground (use specified VFX or default)
                    local vfxName = effect.elevationVfx or "tidal_force_ground"
                    self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
                end
            end
        end
        
        -- Do not reset the slot - the shield will remain active
        return
    end
    
    -- Check for shield blocking based on attack type
    local attackBlocked = false
    local blockingShieldSlot = nil
    
    -- Only check for blocking if this is an offensive spell
    if slot.spell.attackType or slot.attackType then
        -- The attack type of the current spell (check both old and new schema)
        local attackType = slot.spell.attackType or slot.attackType
        print("Checking if " .. attackType .. " attack can be blocked by " .. target.name .. "'s shields")
        
        -- Add detailed shield debugging
        print("[SHIELD DEBUG] Shield check details:")
        print("[SHIELD DEBUG] - Spell: " .. (slot.spellType or "Unknown") .. " (Type: " .. attackType .. ")")
        print("[SHIELD DEBUG] - Target: " .. target.name)
        
        -- Count total shields
        local shieldCount = 0
        for i, targetSlot in ipairs(target.spellSlots) do
            if targetSlot.active and targetSlot.isShield then
                shieldCount = shieldCount + 1
            end
        end
        print("[SHIELD DEBUG] - Found " .. shieldCount .. " active shields")
        
        -- Check each of the target's spell slots for active shields
        for i, targetSlot in ipairs(target.spellSlots) do
            -- Debug print to check shield state
            if targetSlot.active and targetSlot.isShield then
                -- Use token count as the source of truth for shield strength
                local defenseType = targetSlot.defenseType or "unknown"
                
                print("Found shield in slot " .. i .. " of type " .. defenseType .. 
                      " with " .. #targetSlot.tokens .. " tokens")
                
                -- Check if the shield blocks appropriate attack types
                if targetSlot.blocksAttackTypes then
                    for blockType, _ in pairs(targetSlot.blocksAttackTypes) do
                        print("Shield blocks: " .. blockType)
                    end
                else
                    print("Shield does not have blocksAttackTypes defined!")
                end
            end
            
            -- Check if this shield can block this attack type
            local canBlock = false
            
            print("[SHIELD DEBUG] Checking if shield in slot " .. i .. " can block " .. attackType)
            
            -- Only process active shields with tokens
            if targetSlot.active and targetSlot.isShield and #targetSlot.tokens > 0 then
                -- Continue with detailed shield checks
                
                if targetSlot.blocksAttackTypes then
                    -- Old format - table with attackType as keys
                    canBlock = targetSlot.blocksAttackTypes[attackType]
                    print("[SHIELD DEBUG] - blocksAttackTypes check: " .. (canBlock and "YES" or "NO"))
                    
                    -- Additional debugging for blocksAttackTypes
                    print("[SHIELD DEBUG] - blocksAttackTypes contents:")
                    for blockType, value in pairs(targetSlot.blocksAttackTypes) do
                        print("[SHIELD DEBUG]   * " .. blockType .. ": " .. tostring(value))
                    end
                elseif targetSlot.blockTypes then
                    -- New format - array of attack types
                    print("[SHIELD DEBUG] - Checking blockTypes array")
                    for _, blockType in ipairs(targetSlot.blockTypes) do
                        print("[SHIELD DEBUG]   * " .. blockType)
                        if blockType == attackType then
                            canBlock = true
                            break
                        end
                    end
                    print("[SHIELD DEBUG] - blockTypes check: " .. (canBlock and "YES" or "NO"))
                else
                    print("[SHIELD DEBUG] - No block types defined!")
                end
            
            -- Complete debugging about the shield state
            print("[SHIELD DEBUG] Final check for slot " .. i .. ":")
            print("[SHIELD DEBUG] - Active: " .. (targetSlot.active and "YES" or "NO"))
            print("[SHIELD DEBUG] - Is Shield: " .. (targetSlot.isShield and "YES" or "NO"))
            print("[SHIELD DEBUG] - Tokens: " .. #targetSlot.tokens)
            print("[SHIELD DEBUG] - Can Block: " .. (canBlock and "YES" or "NO"))
            
            if targetSlot.active and targetSlot.isShield and
               #targetSlot.tokens > 0 and canBlock then
                
                -- This shield can block this attack type
                attackBlocked = true
                blockingShieldSlot = i
                
                print("[SHIELD DEBUG] ATTACK BLOCKED by shield in slot " .. i)
                
                -- Create visual effect for the block
                target.blockVFX = {
                    active = true,
                    timer = 0.5,  -- Duration of the block visual effect
                    x = target.x,
                    y = target.y
                }
                
                -- Create block effect using VFX system
                if self.gameState.vfx then
                    local shieldColor
                    if targetSlot.defenseType == "barrier" then
                        shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Yellow for barriers
                    elseif targetSlot.defenseType == "ward" then
                        shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
                    elseif targetSlot.defenseType == "field" then
                        shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
                    end
                    
                    self.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
                        duration = 0.5, -- Short block flash
                        color = shieldColor,
                        shieldType = targetSlot.defenseType
                    })
                end
                
                -- Determine how many hits to apply to the shield
                -- Check if this is a shield-breaker spell
                local shieldBreakPower = 1  -- Default: reduce shield by 1
                if slot.spell.shieldBreaker then
                    shieldBreakPower = slot.spell.shieldBreaker
                    print(string.format("[SHIELD BREAKER] %s's %s is a shield-breaker spell that deals %d hits to shields!",
                        self.name, slot.spellType, shieldBreakPower))
                end
                
                -- All shields consume ONE token when blocking (always just 1 token per hit)
                -- Never consume more than one token per hit for regular attacks
                local tokensToConsume = 1
                
                -- Shield breaker spells can consume more tokens
                if slot.spell.shieldBreaker and slot.spell.shieldBreaker > 1 then
                    tokensToConsume = math.min(slot.spell.shieldBreaker, #targetSlot.tokens)
                    print(string.format("[SHIELD BREAKER] Shield breaker consuming up to %d tokens", tokensToConsume))
                end
                
                -- Debug output to track token removal
                print(string.format("[SHIELD DEBUG] Before token removal: Shield has %d tokens", #targetSlot.tokens))
                print(string.format("[SHIELD DEBUG] Will remove %d token(s)", tokensToConsume))
                
                -- Only consume tokens up to the number we have
                tokensToConsume = math.min(tokensToConsume, #targetSlot.tokens)
                
                -- Return tokens back to the mana pool - ONE AT A TIME
                for i = 1, tokensToConsume do
                    if #targetSlot.tokens > 0 then
                        -- Get the last token
                        local lastTokenIndex = #targetSlot.tokens
                        local tokenData = targetSlot.tokens[lastTokenIndex]
                        
                        print(string.format("[SHIELD DEBUG] Consuming token %d from shield (token %d of %d)", 
                            tokenData.index, i, tokensToConsume))
                        
                        -- First make sure token state is updated
                        if tokenData.token then
                            print(string.format("[SHIELD DEBUG] Setting token %d state to FREE from %s", 
                                tokenData.index, tokenData.token.state or "unknown"))
                            tokenData.token.state = "FREE"
                        else
                            print("[SHIELD WARNING] Token has no token data object")
                        end
                        
                        -- Trigger animation to return this token to the mana pool
                        if target and target.manaPool then
                            print(string.format("[SHIELD DEBUG] Returning token %d to mana pool", tokenData.index))
                            target.manaPool:returnToken(tokenData.index)
                        else
                            print("[SHIELD ERROR] Could not return token - mana pool not found")
                        end
                        
                        -- Remove this token from the slot's token list
                        table.remove(targetSlot.tokens, lastTokenIndex)
                        print(string.format("[SHIELD DEBUG] Token %d removed from shield token list (%d tokens remaining)", 
                            tokenData.index, #targetSlot.tokens))
                    else
                        print("[SHIELD ERROR] Tried to consume token but shield has no more tokens!")
                        break -- Stop trying to consume tokens if there are none left
                    end
                end
                
                print("[SHIELD DEBUG] After token removal: Shield has " .. #targetSlot.tokens .. " tokens left")
                
                -- Print the blocked attack message with token info
                if tokensToConsume > 1 then
                    print(string.format("[BLOCK] %s's %s shield blocked %s's %s attack and leaked %d tokens! (%d tokens remaining)",
                        target.name, targetSlot.defenseType, self.name, attackType, tokensToConsume, #targetSlot.tokens))
                else
                    print(string.format("[BLOCK] %s's %s shield blocked %s's %s attack and leaked one token! (%d tokens remaining)",
                        target.name, targetSlot.defenseType, self.name, attackType, #targetSlot.tokens))
                end
                
                -- If the shield is depleted (no tokens left)
                local shieldDepleted = false
                
                -- Simple check based on actual token count (token count is the source of truth)
                -- All shields are mana-linked and use tokens for strength
                shieldDepleted = (#targetSlot.tokens <= 0)
                print("[SHIELD DEBUG] Is shield depleted? " .. (shieldDepleted and "YES" or "NO") .. " (" .. #targetSlot.tokens .. " tokens left)")
                
                -- Double-check token state to ensure shield is properly detected as depleted
                -- A shield is ONLY depleted when ALL tokens have been removed
                if #targetSlot.tokens == 0 then
                    -- Shield is now completely depleted (no tokens left)
                    print("[SHIELD DEBUG] Shield is now depleted - all tokens consumed")
                    shieldDepleted = true
                end
                
                if shieldDepleted then
                    print(string.format("[BLOCK] %s's %s shield has been broken!", target.name, targetSlot.defenseType))
                    print("[SHIELD DEBUG] Destroying shield in slot " .. i)
                    
                    -- Return any remaining tokens (for partially consumed shields)
                    print("[SHIELD DEBUG] Shield has " .. #targetSlot.tokens .. " remaining tokens to return")
                    
                    -- Important: Create a copy of the tokens table, as we'll be modifying it while iterating
                    local tokensToReturn = {}
                    for i, tokenData in ipairs(targetSlot.tokens) do
                        tokensToReturn[i] = tokenData
                    end
                    
                    -- Process each token
                    for _, tokenData in ipairs(tokensToReturn) do
                        print(string.format("[SHIELD DEBUG] Returning token %d to pool during shield destruction", tokenData.index))
                        
                        -- Make sure token state is FREE
                        if tokenData.token then
                            print(string.format("[SHIELD DEBUG] Setting token %d state to FREE from %s", 
                                tokenData.index, tokenData.token.state or "unknown"))
                            tokenData.token.state = "FREE"
                        end
                        
                        -- Return to mana pool
                        if target and target.manaPool then
                            target.manaPool:returnToken(tokenData.index)
                        else
                            print("[SHIELD ERROR] Could not return token - mana pool not found")
                        end
                    end
                    
                    -- Explicitly clear the tokens array
                    targetSlot.tokens = {}
                    
                    -- Reset slot completely to avoid half-broken shield state
                    print("[SHIELD DEBUG] Resetting slot " .. i .. " to empty state")
                    targetSlot.active = false
                    targetSlot.isShield = false
                    targetSlot.defenseType = nil
                    targetSlot.blocksAttackTypes = nil
                    targetSlot.blockTypes = nil  -- Clear block types array too
                    targetSlot.progress = 0
                    targetSlot.spellType = nil
                    targetSlot.spell = nil  -- Clear spell reference too
                    targetSlot.castTime = 0
                    targetSlot.tokens = {}  -- Already cleared above, but ensure it's empty
                    
                    -- Create shield break effect
                    if self.gameState.vfx then
                        self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                            duration = 0.7,
                            color = {1.0, 0.5, 0.5, 0.8},
                            particleCount = 15,
                            radius = 50
                        })
                    end
                end
                
                -- Check for reflection if this shield has that property
                if targetSlot.reflect then
                    print(string.format("[REFLECT] %s's shield reflected %s's attack back at them!",
                        target.name, self.name))
                    
                    -- Implement spell reflection (simplified version)
                    -- For now, just deal partial damage back to the caster
                    if effect.damage and effect.damage > 0 then
                        local reflectDamage = math.floor(effect.damage * 0.5) -- 50% reflection
                        self.health = self.health - reflectDamage
                        if self.health < 0 then self.health = 0 end
                        
                        print(string.format("[REFLECT] %s took %d reflected damage! (health: %d)", 
                            self.name, reflectDamage, self.health))
                            
                        -- Create reflected damage visual effect
                        if self.gameState.vfx then
                            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                                duration = 0.5,
                                color = {0.8, 0.2, 0.8, 0.7}, -- Purple for reflection
                                particleCount = 10,
                                radius = 30
                            })
                        end
                    end
                end
                
                    -- We found a shield that blocked this attack, so stop checking other shields
                    break
                end -- End of if targetSlot.active and canBlock check
            end -- End of if targetSlot.active check
        end
    end
    
    -- If the attack was blocked, don't apply any effects
    if attackBlocked then
        -- Start return animation for tokens
        if #slot.tokens > 0 then
            for _, tokenData in ipairs(slot.tokens) do
                -- Trigger animation to return token to the mana pool
                self.manaPool:returnToken(tokenData.index)
            end
            
            -- Clear token list (tokens still exist in the mana pool)
            slot.tokens = {}
        end
        
        -- Reset slot
        slot.active = false
        slot.progress = 0
        slot.spellType = nil
        slot.castTime = 0
        
        return  -- Skip applying any effects
    end
    
    -- The old blocker system has been completely removed
    -- Shield functionality is now handled through the shield keyword system
    
    -- Apply damage
    if effect.damage and effect.damage > 0 then
        target.health = target.health - effect.damage
        if target.health < 0 then target.health = 0 end
        
        -- Special feedback for time-scaled damage from Full Moon Beam
        if effect.scaledDamage then
            print(target.name .. " took " .. effect.damage .. " damage from " .. slot.spellType .. 
                  " (scaled by cast time) (health: " .. target.health .. ")")
            
            -- Create a more dramatic visual effect for scaled damage
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                    duration = 0.8,
                    color = {0.5, 0.5, 1.0, 0.8},
                    particleCount = 20,
                    radius = 45
                })
            end
        else
            -- Regular damage feedback
            print(target.name .. " took " .. effect.damage .. " damage (health: " .. target.health .. ")")
            
            -- Create hit effect if not already created by the spell VFX
            if self.gameState.vfx and not effect.spellType then
                -- Default impact effect for non-specific damage
                self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                    duration = 0.5,
                    color = {1.0, 0.3, 0.3, 0.8}
                })
            end
        end
    end
    
    -- Apply position changes to the shared game state
    if effect.setPosition then
        -- Update the shared game rangeState
        if effect.setPosition == "NEAR" or effect.setPosition == "FAR" then
            self.gameState.rangeState = effect.setPosition
            print(self.name .. " changed the range state to " .. self.gameState.rangeState)
        end
    end
    
    if effect.setElevation then
        -- Determine the target for elevation changes based on keyword settings
        local elevationTarget
        
        -- Explicit targeting from keyword resolution
        if effect.elevationTarget then
            if effect.elevationTarget == "SELF" then
                elevationTarget = self
            elseif effect.elevationTarget == "ENEMY" then
                elevationTarget = target
            else
                -- Default to self if target specification is invalid
                elevationTarget = self
                print("Warning: Unknown elevation target type: " .. tostring(effect.elevationTarget))
            end
        else
            -- Legacy behavior if no explicit target (for backward compatibility)
            elevationTarget = effect.setElevation == "GROUNDED" and target or self
        end
        
        -- Record if this is changing from AERIAL (for VFX)
        local wasAerial = elevationTarget.elevation == "AERIAL"
        
        -- Apply the elevation change
        elevationTarget.elevation = effect.setElevation
        
        -- Set duration for elevation change if provided
        if effect.elevationDuration and effect.setElevation == "AERIAL" then
            elevationTarget.elevationTimer = effect.elevationDuration
            print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation for " .. effect.elevationDuration .. " seconds")
        else
            -- No duration specified, treat as permanent until changed by another spell
            elevationTarget.elevationTimer = 0
            print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation")
        end
        
        -- Create appropriate visual effect for elevation change
        if self.gameState.vfx then
            if effect.setElevation == "AERIAL" then
                -- Effect for rising into the air (use specified VFX or default)
                local vfxName = effect.elevationVfx or "emberlift"
                self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
            elseif effect.setElevation == "GROUNDED" and wasAerial then
                -- Effect for forcing down to the ground (use specified VFX or default)
                local vfxName = effect.elevationVfx or "tidal_force_ground"
                self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
            end
        end
    end
    
    -- Apply stun
    if effect.stun and effect.stun > 0 then
        target.stunTimer = effect.stun
        print(target.name .. " is stunned for " .. effect.stun .. " seconds")
        
        -- Create stun effect
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.8,
                color = {1.0, 1.0, 0.2, 0.8}
            })
        end
    end
    
    -- Apply token lock
    if effect.lockToken and #target.manaPool.tokens > 0 then
        -- Get lock duration from effect or use default
        local lockDuration = effect.lockDuration or 5.0  -- Default to 5 seconds if not specified
        
        -- Find a random free token to lock
        local freeTokens = {}
        for i, token in ipairs(target.manaPool.tokens) do
            if token.state == "FREE" then
                table.insert(freeTokens, i)
            end
        end
        
        if #freeTokens > 0 then
            local tokenIndex = freeTokens[math.random(#freeTokens)]
            local token = target.manaPool.tokens[tokenIndex]
            
            -- Set token to locked state
            token.state = "LOCKED"
            token.lockDuration = lockDuration
            token.lockPulse = 0  -- Reset lock pulse animation
            
            -- Record the token type for better feedback
            local tokenType = token.type
            print("Locked a " .. tokenType .. " token in " .. target.name .. "'s mana pool for " .. lockDuration .. " seconds")
            
            -- Create lock effect at token position
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                    duration = 0.5,
                    color = {0.8, 0.2, 0.2, 0.7},
                    particleCount = 10,
                    radius = 30
                })
            end
        end
    end
    
    -- Apply spell delay (to target's spell)
    if effect.delaySpell and target.spellSlots[effect.delaySpell] and target.spellSlots[effect.delaySpell].active then
        -- Get the target spell slot
        local slot = target.spellSlots[effect.delaySpell]
        
        -- Calculate how much progress has been made (as a percentage)
        local progressPercent = slot.progress / slot.castTime
        
        -- Add additional time to the spell
        local delayTime = effect.delayAmount or 2.0  -- Use specified delay amount or default to 2.0 seconds
        local newCastTime = slot.castTime + delayTime
        
        -- Update the castTime and adjust the progress proportionally
        -- This effectively "pushes back" the progress bar
        slot.castTime = newCastTime
        slot.progress = progressPercent * slot.castTime
        
        print("Delayed " .. target.name .. "'s spell in slot " .. effect.delaySpell .. " by " .. delayTime .. " seconds")
        
        -- Create delay effect near the targeted spell slot
        if self.gameState.vfx then
            -- Calculate position of the targeted spell slot
            local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
            local slotY = target.y + slotYOffsets[effect.delaySpell]
            
            -- Create a more distinctive delay visual effect
            self.gameState.vfx.createEffect("impact", target.x, slotY, nil, nil, {
                duration = 0.9,
                color = {0.3, 0.3, 0.8, 0.7},
                particleCount = 15,
                radius = 40
            })
        end
    end
    
    -- Apply spell delay (to caster's own spell)
    if effect.delaySelfSpell then
        print("DEBUG - Eclipse Echo effect triggered with delaySelfSpell = " .. effect.delaySelfSpell)
        print("DEBUG - Caster: " .. self.name)
        print("DEBUG - Spell slots status:")
        for i, slot in ipairs(self.spellSlots) do
            print("DEBUG - Slot " .. i .. ": " .. (slot.active and "ACTIVE - " .. (slot.spellType or "unknown") or "INACTIVE"))
            if slot.active then
                print("DEBUG - Progress: " .. slot.progress .. " / " .. slot.castTime)
            end
        end
        
        -- When Eclipse Echo resolves, we need to target the middle spell slot
        -- Which in Lua is index 2 (1-based indexing)
        local targetSlotIndex = effect.delaySelfSpell  -- Should be 2 for the middle slot
        print("DEBUG - Targeting slot index: " .. targetSlotIndex)
        local targetSlot = self.spellSlots[targetSlotIndex]
        
        if targetSlot and targetSlot.active then
            -- Get the caster's spell slot
            local slot = targetSlot
            print("DEBUG - Found active spell in target slot: " .. (slot.spellType or "unknown"))
            
            -- Calculate how much progress has been made (as a percentage)
            local progressPercent = slot.progress / slot.castTime
            
            -- Add additional time to the spell
            local delayTime = effect.delayAmount or 2.0  -- Use specified delay amount or default to 2.0 seconds
            local newCastTime = slot.castTime + delayTime
            
            -- Update the castTime and adjust the progress proportionally
            -- This effectively "pushes back" the progress bar
            slot.castTime = newCastTime
            slot.progress = progressPercent * slot.castTime
            
            print(self.name .. " delayed their own spell in slot " .. targetSlotIndex .. " by " .. delayTime .. " seconds")
            
            -- Create delay effect near the caster's spell slot
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlotIndex]
                
                -- Create a more distinctive delay visual effect
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 0.9,
                    color = {0.3, 0.3, 0.8, 0.7},
                    particleCount = 15,
                    radius = 40
                })
            end
        else
            -- If there's no spell in the target slot, show a "fizzle" effect
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlotIndex]
                
                -- Create a small fizzle effect to show the spell had no effect
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 0.3,
                    color = {0.3, 0.3, 0.4, 0.4},
                    particleCount = 5,
                    radius = 20
                })
                
                print("Eclipse Echo fizzled - no spell in " .. self.name .. "'s middle slot")
            end
        end
    end
    
    -- Only reset the spell slot and return tokens for non-shield spells
    -- For shield spells, keep tokens in the slot for mana-linking
    
    -- CRITICAL CHECK: For Mist Veil spell, it must be treated as a shield
    if slot.spellType == "Mist Veil" or slot.spell.id == "mist" then
        -- Force shield behavior for Mist Veil
        slot.isShield = true
        isShieldSpell = true
        effect.isShield = true
        
        -- Force tokens to SHIELDING state
        for _, tokenData in ipairs(slot.tokens) do
            if tokenData.token then
                tokenData.token.state = "SHIELDING"
            end
        end
        print("DEBUG: SPECIAL CASE - Enforcing Mist Veil shield behavior")
    end
    
    if not isShieldSpell and not slot.isShield and not effect.isShield then
        print("DEBUG: Returning tokens to mana pool - not a shield spell")
        -- Start return animation for tokens
        if #slot.tokens > 0 then
            -- Check one more time that no tokens are marked as SHIELDING
            local hasShieldingTokens = false
            for _, tokenData in ipairs(slot.tokens) do
                if tokenData.token and tokenData.token.state == "SHIELDING" then
                    hasShieldingTokens = true
                    break
                end
            end
            
            if not hasShieldingTokens then
                -- Safe to return tokens
                for _, tokenData in ipairs(slot.tokens) do
                    -- Trigger animation to return token to the mana pool
                    self.manaPool:returnToken(tokenData.index)
                end
                
                -- Clear token list (tokens still exist in the mana pool)
                slot.tokens = {}
            else
                print("DEBUG: Found SHIELDING tokens, preventing token return")
            end
        end
        
        -- Reset slot only if it's not a shield
        slot.active = false
        slot.progress = 0
        slot.spellType = nil
        slot.castTime = 0
    else
        print("DEBUG: Shield spell - keeping tokens in slot for mana-linking")
        -- For shield spells, the slot remains active and tokens remain in orbit
        -- Make sure slot is marked as a shield
        slot.isShield = true
        -- Mark tokens as SHIELDING again just to be sure
        for _, tokenData in ipairs(slot.tokens) do
            if tokenData.token then
                tokenData.token.state = "SHIELDING"
            end
        end
    end
end

return Wizard```

# Documentation

## docs/shield_system.md
# Manastorm Shield System

This document describes the shield system in Manastorm, including its design, implementation, and intended interactions with other game systems.

## Overview

Shields are a special type of spell that persist after casting, keeping their mana tokens in orbit until the shield is depleted by blocking attacks or manually freed by the caster. Shields can block specific types of attacks depending on their defense type.

## Shield Types

There are three types of shields, each blocking different attack types:

| Shield Type | Blocks                  | Visual Color |
|-------------|-------------------------|--------------|
| Barrier     | Projectiles, Zones      | Yellow       |
| Ward        | Projectiles, Remotes    | Blue         |
| Field       | Remotes, Zones          | Green        |

## Attack Types

Spells can have the following attack types:

| Attack Type | Description                                       | Blocked By             |
|-------------|---------------------------------------------------|------------------------|
| Projectile  | Physical projectile attacks                       | Barriers, Wards        |
| Remote      | Magical attacks at a distance                     | Wards, Fields          |
| Zone        | Area effect attacks                              | Barriers, Fields       |
| Utility     | Non-offensive spells that affect the caster       | Cannot be blocked      |

## Shield Lifecycle

1. **Casting Phase**: 
   - During casting, shield spells behave like normal spells
   - Mana tokens orbit normally in the spell slot
   - The slot is marked with `willBecomeShield = true` flag

2. **Completion Phase**:
   - When casting completes, tokens are marked as "SHIELDING"
   - The spell slot is marked with `isShield = true`
   - A shield visual effect is created
   - Shield strength is represented by the number of tokens used

3. **Active Phase**:
   - The shield remains active indefinitely until destroyed
   - Tokens continue to orbit slowly in the spell slot
   - The slot cannot be used for other spells while the shield is active

4. **Blocking Phase**:
   - When an attack is directed at the wizard, shield checks occur
   - If a shield can block the attack type, the attack is blocked
   - A token is consumed and returned to the pool
   - Shield strength decreases as tokens are consumed

5. **Destruction Phase**:
   - When a shield's last token is consumed, it is destroyed
   - The spell slot is reset and becomes available for new spells

## Implementation Details

### Shield Properties

Shields have the following properties:

- `isShield`: Flag that marks a spell slot as containing a shield
- `defenseType`: The type of shield ("barrier", "ward", or "field")
- `tokens`: Array of tokens powering the shield (token count = shield strength)
- `blocksAttackTypes`: Table specifying which attack types this shield blocks
- `blockTypes`: Array form of blocksAttackTypes for compatibility
- `reflect`: Whether the shield reflects damage back to the attacker (default: false)

### Block Keyword

The `block` keyword is used to create shields:

```lua
block = {
    type = "ward",            -- Shield type (barrier, ward, field)
    blocks = {"projectile", "remote"}, -- Attack types to block
    reflect = false           -- Whether to reflect damage back
}
```

### Shield Creation

Shields are created through the `createShield` function in wizard.lua:

```lua
createShield(wizard, spellSlot, blockParams)
```

This function:
1. Marks the slot as a shield
2. Sets the defense type and blocking properties
3. Marks tokens as "SHIELDING"
4. Uses token count as the source of truth for shield strength
5. Slows down token orbiting for shield tokens
6. Creates shield visual effects

### Shield Blocking Logic

When a spell is cast, shield checking occurs in the `castSpell` function:

1. The attack type of the spell is determined
2. Each of the target's spell slots is checked for active shields
3. If a shield can block the attack type and has tokens remaining, the attack is blocked
4. A token is consumed and returned to the mana pool
5. If all tokens are consumed, the shield is destroyed

## Future Extensions

Possible future extensions to the shield system:

1. **Passive Shield Effects**: Shields that provide ongoing effects while active
2. **Shield Combinations**: Special effects when multiple shield types are active
3. **Shield Enhancements**: Items or spells that improve shield properties
4. **Shield Regeneration**: Shields that recover strength over time
5. **Shield Reflection**: More elaborate reflection mechanics
6. **Shield Overloading**: Effects that trigger when a shield is destroyed

## Debugging

Common issues with shields and their solutions:

1. **Tokens not showing in shield**: Check that tokens are marked as "SHIELDING" and not returned to the pool
2. **Shield not blocking attacks**: Verify shield has tokens remaining and that it blocks the attack type
3. **Shield persisting after depletion**: Check the shield destruction logic in wizard.lua

Shield debugging can be enabled in wizard.lua with detailed output to trace shield behavior.

## Cross-Module Interactions

The shield system interacts with several other game systems:

- **Mana Pool**: Tokens from shields are returned here when consumed or destroyed
- **Spell Compiler**: Handles compiled shield spells with block keywords
- **VFX System**: Creates visual effects for shields, blocks, and breaks
- **Elevation System**: Some shields also change elevation (e.g., Mist Veil)

## Example Shield Spells

1. **Mist Veil** (Ward): Blocks projectiles and remotes, elevates caster
2. **Stone Wall** (Barrier): Blocks projectiles and zones, grounds caster
3. **Energy Field** (Field): Blocks remotes and zones, mana-intensive

## Known Issues and Limitations

- Shields cannot currently be stacked in the same slot
- Attack types are fixed and cannot be dynamically modified
- Shield strength is EXACTLY equal to token count

## Best Practices

When implementing new shield-related functionality:

1. Always mark tokens as "SHIELDING" after the spell completes, not during casting
2. Use the `createShield` function to ensure consistent shield initialization
3. Check for null/nil values in shield properties to prevent runtime errors
4. Remember that token count is the source of truth for shield strength
5. When checking if a shield is depleted, check if no tokens remain

## ./ComprehensiveDesignDocument.md
Game Title: Manastorm (working title)

Genre: Tactical Wizard Dueling / Real-Time Strategic Battler

Target Platforms: PC (initial), with possible future expansion to consoles

Core Pitch:

A high-stakes, low-input real-time dueling game where two spellcasters 
clash in arcane combat by channeling mana from a shared pool to queue 
spells into orbiting "spell slots." Strategy emerges from a shared 
resource economy, strict limitations on casting tempo, and deep 
interactions between positional states and spell types. Think Street 
Fighter meets Magic: The Gathering, filtered through an occult operating 
system.

Core Gameplay Loop:

Spell Selection Phase (Pre-battle)

Each player drafts a small set of spells from a shared pool.

These spells define their available actions for the match.

Combat Phase (Real-Time)

Players queue spells from their loadout (max 3 at a time).

Each spell channels mana from a shared pool and takes time to resolve.

Spells resolve in real-time after a fixed cast duration.

Cast spells release mana back into the shared pool, ramping intensity.

Positioning states (NEAR/FAR, GROUNDED/AERIAL) alter spell legality and 
effects.

Players win by reducing the opponent’s health to zero.

Key Systems & Concepts:

1. Spell Queue & Spell Slots

Each player has 3 spell slots.

Spells are queued into slots using hotkeys (Q/W/E or similar).

Each slot is visually represented as an orbit ring around the player 
character.

Channeled mana tokens orbit in these rings.

2. Mana Pool System

A shared pool of mana tokens floats in the center of the screen.

Tokens are temporarily removed when used to queue a spell.

Upon spell resolution, tokens return to the pool.

Tokens have types (e.g. FIRE, VOID, WATER), which interact with spell 
costs and effects.

The mana pool escalates tension by becoming more dynamic and volatile as 
spells resolve.

3. Token States

FREE: Available in the pool.

CHANNELED: Orbiting a caster while a spell is charging.

LOCKED: Temporarily unavailable due to enemy effects.

DESTROYED: Rare, removed from match entirely.

4. Positional States

Each player exists in binary positioning states:

Range: NEAR / FAR

Elevation: GROUNDED / AERIAL

Many spells can only be cast or take effect under certain conditions.

Players can be moved between states via spell effects.

5. Cast Feedback (Diegetic UI)

Each spell slot shows its cast time progression via a glowing arc rotating 
around the orbit.

Players can visually read how close a spell is to resolving.

No abstract bars; all feedback is embedded in the arena.

6. Spellbook System

Players have access to a limited loadout of spells during combat.

A separate spellbook UI (toggleable) shows full names, descriptions, and 
mechanics.

Core battlefield UI remains minimal to prioritize visual clarity and 
strategic deduction.

Visual & Presentation Goals

Combat is side-view, 2D.

Wizards are expressive but minimal sprites.

Mana tokens are vibrant, animated symbols.

All key mechanics are visible in-world (tokens, cast arcs, positioning 
shifts).

No HUD overload; world itself communicates state.

Design Pillars

Tactical Clarity: All decisions have observable consequences.

Strategic Literacy: Experienced players gain advantage by reading visual 
patterns.

Diegetic Information: The battlefield tells the story; minimal overlays.

Shared Economy, Shared Risk: Players operate in a closed loop that fuels 
both offense and defense.

Example Spells (Shortlist)

Ashgar the Emberfist:

Firebolt: Quick ranged hit, more damage at FAR.

Meteor Dive: Aerial finisher, hits GROUNDED enemies.

Combust Lock: Locks opponent mana token, punishes overqueueing.

Selene of the Veil:

Mist Veil: Projectile block, grants AERIAL.

Gravity Pin: Traps AERIAL enemies.

Eclipse Echo: Delays central queued spell.

Target Experience

Matches last 2–5 minutes.

Constant mental engagement without twitchy inputs.

Read-your-opponent mind games and counterplay at the forefront.

Replayable duels with high skill ceiling and unique matchups.

This document will evolve, but this version represents the intended 
holistic vision of the gameplay experience, tone, and structure of 
Manastorm.

## ./ModularSpellsRefactor.md
~Manastorm Spell System Refactor: Game Plan
1. The Vision: "Keyword Totality Doctrine"

Problem: Currently, spell behaviors (rules), visual effects (VFX), sound 
effects (SFX), and potentially UI descriptions are likely defined 
separately or hardcoded within each spell's logic in spells.lua and 
vfx.lua. This makes adding new spells complex, leads to inconsistencies, 
and doesn't enforce a unified visual language based on the game's rules 
(like Projectile vs. Remote, Fire vs. Ice).
Goal: We want a system where defining a spell is as simple as listing its 
core keywords (like "Fire", "Projectile", "Damage", "Knockdown"). These 
keywords become the single source of truth, dictating everything about 
that aspect of the spell:
How it behaves in the simulation (combat.lua).
How it looks (vfx.lua).
How it sounds.
How it's described in the UI (like a spellbook).
Why?:
Consistency: Spells with the "Projectile" keyword will always share core 
visual motion characteristics. Fire spells will always have a certain 
color palette and feel.
Maintainability: Change the "Fire" keyword's VFX once, and all fire spells 
update instantly.
Scalability: Adding new spells becomes much faster – just combine existing 
keywords or define a new keyword with its associated data. Designers can 
mix and match keywords easily.
Readability: Players learn the visual language tied to keywords, allowing 
them to understand spells diegetically, without needing explicit text 
popups during intense duels.
2. The Technical Approach: Refactor & Compilation

We will refactor the existing codebase by introducing two key new 
components and modifying existing ones:

keywords.lua (New File): This file will become a dictionary or library of 
all possible spell keywords. Each keyword entry will be pure data, 
defining the deltas or pieces it contributes:
behavior: How it modifies game state (e.g., { damageAmount = 10, 
damageType = "fire" }).
vfx: Visual parameters (e.g., { form = "orb", trail = "flare", color = {1, 
0.4, 0.2} }).
sfx: Sound cues (e.g., { cast = "fire_launch", impact = "explosion_soft" 
}).
description: A text fragment for UI tooltips (e.g., "Travels in a straight 
line...").
flags: Tags for categorization or synergies (e.g., { "ranged", "offensive" 
}).
spellCompiler.lua (New File): This file will contain a function, let's 
call it compileSpell(spellDefinition, keywordData).
It takes a basic spell definition (like { name = "Fireball", keywords = 
{"Fire", "Projectile", "Damage"}, cost = 1 } from the refactored 
spells.lua).
It looks up each keyword in keywords.lua.
It merges all the behavior, vfx, sfx, description, and flags data from 
those keywords into a single, complete "compiled spell" object. This 
object contains all the information needed to execute, render, and 
describe the spell.
spells.lua (Refactored): This file will be simplified dramatically. It 
will only contain the basic definitions: spell name, cost, cooldown, and 
the list of keywords it uses. All specific logic and VFX/SFX details will 
be removed.
combat.lua / Simulation Logic (Updated): Instead of reading logic directly 
from spells.lua, the simulation will now use the compiledSpell.behavior 
object generated by the compiler.
vfx.lua / Rendering Logic (Updated): Instead of having hardcoded effects 
per spell name, the VFX engine will read parameters from the 
compiledSpell.vfx object to dynamically create the correct visuals based 
on form, affinity, function, etc.
Sound Engine (Updated): Similarly, sound cues will be triggered based on 
the compiledSpell.sfx data.
UI (Future): Any spellbook or tooltip UI will read from 
compiledSpell.description and compiledSpell.flags.
3. The Process:

We'll tackle this iteratively:

Setup: Create the new files and basic structures.
Migrate Keywords: Define keywords in keywords.lua based on existing spell 
logic, starting with behavior.
Build Compiler: Implement the compileSpell function to merge keyword data.
Refactor spells.lua: Strip out old logic, use only keyword lists.
Integrate: Make the simulation use the compiled spells.
VFX/SFX Data: Add visual and audio data to keywords.
Render Integration: Update VFX/SFX systems to use compiled data.
UI Data: Add description/flags and prepare for UI integration.
This approach allows us to gradually shift functionality to the new system 
while ensuring the game remains functional (or close to it) throughout the 
process.~

## ./README.md
# Manastorm

A tactical wizard dueling game built with LÖVE (Love2D).

## Description

Manastorm is a real-time strategic battler where two spellcasters clash in arcane combat by channeling mana from a shared pool to queue spells into orbiting "spell slots." Strategy emerges from a shared resource economy, strict limitations on casting tempo, and deep interactions between positional states and spell types.

## Requirements

- [LÖVE](https://love2d.org/) 11.4 or later

## How to Run

1. Install LÖVE from [love2d.org](https://love2d.org/)
2. Clone this repository
3. Run the game:
   - On Windows: Drag the folder onto love.exe, or run `"C:\Program Files\LOVE\love.exe" path\to\Manastorm`
   - On macOS: Run `open -n -a love.app --args $(pwd)` from the Manastorm directory
   - On Linux: Run `love .` from the Manastorm directory

## Controls

### Player 1 (Ashgar)
- Q, W, E: Queue spells in spell slots 1, 2, and 3

### Player 2 (Selene)
- I, O, P: Queue spells in spell slots 1, 2, and 3

### General
- ESC: Quit the game

## Development Status

This is an early prototype with basic functionality:
- Two opposing wizards with health bars
- Shared mana pool with floating tokens
- Three spell slots per wizard with visual feedback
- Basic state representation (NEAR/FAR, GROUNDED/AERIAL)

## Next Steps

- Connect mana tokens to spell queueing
- Implement actual spell effects
- Add position changes
- Create proper spell descriptions
- Add collision detection
- Add visual effects

## ./SupportShieldsInModularSystem.md
~This is a classic case where a highly stateful, persistent effect (like 
an active shield) clashes a bit with a system designed for resolving 
discrete, immediate keyword effects.

Based on the codebase and the design goals, here's the breakdown and a 
plan to get shields working elegantly within the keyword framework:

Diagnosis of the Problem:

Keyword Execution vs. Persistent State: The core issue is that the block 
keyword's execute function (in keywords.lua) runs when the shield spell 
resolves, setting flags in the results table. However, the actual blocking 
needs to happen later, whenever an enemy spell hits. Furthermore, the 
shield needs to persist in the slot after its initial cast resolves, 
retaining its mana. The current keyword execution model is primarily 
designed for immediate effects, not setting up long-term states on a slot.

State Management Split: Because the keyword isn't fully setting up the 
persistent state, wizard.lua is still doing a lot of heavy lifting outside 
the keyword system:

The createShield helper function seems to contain logic that should 
ideally be driven by the keyword result.

The checkShieldBlock function runs during castSpell to detect if an 
incoming spell should be blocked, separate from the keyword resolution.

The Wizard:update function has logic to update orbiting shield tokens 
(which is good, but shows the state isn't fully managed just by spell 
resolution).

The Wizard:castSpell function has complex conditional logic around 
slot.isShield to prevent tokens from returning, which shouldn't be needed 
if the state is handled correctly.

Mist Veil's Custom executeAll: This is a symptom. Because the standard 
keyword compilation + execution wasn't sufficient to handle the specific 
combination of block and elevate along with the persistent shield state, a 
custom override was needed. This breaks the modularity goal.

Token State Timing: The spellCompiler's executeAll function marks tokens 
as SHIELDING during compilation. This is too early. Tokens should remain 
CHANNELED during the shield's cast time and only become SHIELDING when the 
shield activates.

Solution: Refined Shield Implementation Plan

Let's restructure how shields are handled to align better with the keyword 
system while respecting their persistent nature.

Phase 1: Redefine Keyword Responsibilities & State Setup

Ticket PROG-18: Refactor block Keyword Execution

Goal: Make the block keyword only responsible for setting up the intent to 
create a shield when its spell resolves.

Tasks:

In keywords.lua, modify the block.execute function. Instead of just 
setting simple flags, have it return a structured shieldParams table 
within the results. Example:

execute = function(params, caster, target, results)
    results.shieldParams = {
        createShield = true,
        defenseType = params.type or "barrier",
        blocksAttackTypes = params.blocks or {"projectile"},
        reflect = params.reflect or false
        -- Mana-linking is now the default, no need for a flag
    }
    return results
end
Use code with caution.
Lua
Remove the direct setting of results.isShield, results.defenseType, etc., 
from the keyword's execute.

AC: The block keyword's execute function returns a shieldParams table in 
the results.

Ticket PROG-19: Refactor Wizard:castSpell for Shield Activation

Goal: Handle the transition from a casting spell to an active shield state 
cleanly after keyword execution.

Tasks:

Modify Wizard:castSpell after the effect = spellToUse.executeAll(...) 
call.

Check if effect.shieldParams exists and effect.shieldParams.createShield 
== true.

If true:

Call the existing createShield function (or integrate its logic here), 
passing self (the wizard), spellSlot, and effect.shieldParams. This 
function will handle:

Setting slot.isShield = true.

Setting slot.defenseType, slot.blocksAttackTypes, slot.reflect.

Setting token states to SHIELDING.

Setting slot.progress = slot.castTime (shield is now fully "cast" and 
active).

Triggering the "Shield Activated" VFX.

Crucially: Do not reset the slot or return tokens for shield spells here. 
The slot remains active with the shield.

If not a shield spell (no effect.shieldParams), proceed with the existing 
logic for returning tokens and resetting the slot.

Remove the old if slot.willBecomeShield... logic from Wizard:update and 
the premature slot.isShield = true setting from Wizard:queueSpell. The 
state change happens definitively in castSpell now.

AC: Shield spells correctly transition to an active shield state managed 
by the slot. Tokens remain and are marked SHIELDING. Non-shield spells 
resolve normally. The createShield function is now properly triggered by 
the keyword result.

Phase 2: Integrate Blocking Check

Ticket PROG-20: Integrate checkShieldBlock into castSpell

Goal: Move the shield blocking check into the appropriate place in the 
spell resolution flow.

Tasks:

In Wizard:castSpell, before calling effect = spellToUse.executeAll(...) 
and before checking for the caster's own blockers (like the old Mist Veil 
logic, which should be removed per PROG-16), call the existing 
checkShieldBlock(spellToUse, attackType, target, self).

If blockInfo.blockable is true:

Trigger block VFX.

Call target:handleShieldBlock(blockInfo.blockingSlot, spellToUse) (from 
PROG-14 - assuming it exists or implement it now).

Crucially: Return early from castSpell. Do not execute the spell's 
keywords or apply any other effects.

Remove the separate checkShieldBlock call that happens later in the 
current castSpell.

AC: Incoming offensive spells are correctly checked against active shields 
before their effects are calculated or applied. Successful blocks prevent 
the spell and trigger shield mana consumption.

Ticket PROG-14: Implement Wizard:handleShieldBlock (If not already done, 
or refine it)

Goal: Centralize the logic for consuming mana from a shield when it 
blocks.

Tasks: (As defined previously)

Create Wizard:handleShieldBlock(slotIndex, blockedSpell).

Get the shieldSlot.

Check token count > 0.

Determine tokensToConsume based on blockedSpell.shieldBreaker (default 1).

Remove the correct number of tokens from shieldSlot.tokens.

Call self.manaPool:returnToken() for each consumed token index.

Trigger "token release" VFX.

If #shieldSlot.tokens == 0: Deactivate the slot, trigger "shield break" 
VFX, clear shield properties (isShield, etc.).

AC: Shield correctly consumes mana tokens upon blocking. Shield breaks 
when mana is depleted. Slot becomes available again.

Phase 3: Cleanup and Refinement

Ticket PROG-21: Refactor Mist Veil

Goal: Remove the custom executeAll from Spells.mist and define it purely 
using keywords.

Tasks:

In spells.lua, remove the executeAll function from Spells.mist.

Ensure its keywords table correctly defines both the block keyword 
parameters and the elevate keyword parameters.

keywords = {
    block = { type = "ward", blocks = {"projectile", "remote"} },
    elevate = { duration = 4.0 }
}
Use code with caution.
Lua
AC: Mist Veil works correctly using the standard keyword compilation and 
resolution process.

Ticket PROG-16: Remove Old Blocker System (As defined previously – remove 
wizard.blockers, related timers, and drawing code).

Ticket PROG-15: Visual Distinction for Shield Slots (As defined previously 
– update drawSpellSlots to show active shields differently).

Key Principle:

Keyword Sets Intent: The block keyword's execution signals intent to 
create a shield.

castSpell Establishes State: The castSpell function, upon seeing the 
shield intent in the results, performs the actions to make the shield 
state persistent on the slot (using createShield logic).

castSpell Checks Blocks: The castSpell function also checks the target for 
existing active shields before processing the incoming spell's effects.

handleShieldBlock Manages Breakdown: A dedicated function handles the 
consequences of a successful block (mana leak, shield break).

This approach keeps the keyword system focused on defining effects while 
acknowledging that shields require specific state management within the 
wizard/slot structure and interaction checks during spell resolution. It 
centralizes the shield creation logic previously duplicated or bypassed.~

## ./manastorm_codebase_dump.md
# Manastorm Codebase Dump
Generated: Fri Apr 18 09:46:27 CDT 2025

# Source Code

## ./conf.lua
```lua
-- Configuration
function love.conf(t)
    t.title = "Manastorm - Wizard Duel"  -- The title of the window
    t.version = "11.4"                    -- The LÖVE version this game was made for
    
    -- Base design resolution
    t.window.width = 800
    t.window.height = 600
    
    -- Allow high DPI mode on supported displays (macOS, etc)
    t.window.highdpi = true
    
    -- Make window resizable
    t.window.resizable = true
    
    -- Graphics settings
    t.window.vsync = 1                    -- Vertical sync (1 = enabled)
    t.window.msaa = 0                     -- Disable anti-aliasing to keep pixel art crisp
    
    -- For debugging
    t.console = true
    
    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = false
end```

## ./docs/keywords.lua
```lua
-- Keywords Documentation Generator
-- This file helps maintain up-to-date documentation for the keyword system

local Spells = require("spells")

local DocGenerator = {}

-- Function to get the default target type description for a keyword
local function getTargetTypeDescription(keyword)
    local targetType = Spells.keywordSystem.keywordTargets[keyword]
    local descriptions = {
        self = "Affects the caster",
        enemy = "Affects the opponent",
        pool_self = "Affects the caster's mana pool",
        pool_enemy = "Affects the opponent's mana pool",
        slot_self = "Affects the caster's spell slots",
        slot_enemy = "Affects the opponent's spell slots",
        global = "Affects the game state",
        none = "No specific target"
    }
    
    return descriptions[targetType] or "Unknown target type"
end

-- Generate markdown documentation for all available keywords
function DocGenerator.generateMarkdown()
    local output = "# Manastorm Spell Keyword Reference\n\n"
    output = output .. "This document provides a reference for all available keywords in the Manastorm spell system.\n\n"
    
    -- Get keyword info organized by category
    local keywordsByCategory = Spells.keywordSystem.getKeywordHelp("byCategory")
    
    -- Table of contents
    output = output .. "## Contents\n\n"
    for categoryKey, category in pairs(keywordsByCategory) do
        output = output .. "- [" .. category.name .. "](#" .. string.lower(category.name:gsub("%s+", "-")) .. ")\n"
    end
    output = output .. "\n\n"
    
    -- Generate sections for each category
    for categoryKey, category in pairs(keywordsByCategory) do
        output = output .. "## " .. category.name .. "\n\n"
        
        for _, keyword in ipairs(category.keywords) do
            output = output .. "### " .. keyword.name .. "\n\n"
            output = output .. keyword.description .. "\n\n"
            output = output .. "**Default targeting:** " .. getTargetTypeDescription(keyword.name) .. "\n\n"
            output = output .. "**Example usage:**\n\n"
            output = output .. "```lua\n" .. keyword.example .. "\n```\n\n"
            
            -- Add targeting example if appropriate
            if Spells.keywordSystem.keywordTargets[keyword.name] then
                output = output .. "**Custom targeting example:**\n\n"
                output = output .. "```lua\n" .. keyword.name .. " = {\n"
                output = output .. "    -- Parameters as above\n"
                output = output .. "    target = \"" .. Spells.keywordSystem.keywordTargets[keyword.name] .. "\"  -- Default target\n"
                output = output .. "    -- You can override with any of: \"self\", \"enemy\", \"pool_self\", \"pool_enemy\", \"slot_self\", \"slot_enemy\", \"global\", \"none\"\n"
                output = output .. "}\n```\n\n"
            end
        end
    end
    
    -- Add a section with sample spells
    output = output .. "## Sample Spells\n\n"
    output = output .. "These examples show how to combine multiple keywords to create complex spell effects.\n\n"
    
    -- Targeting section
    output = output .. "### About Targeting\n\n"
    output = output .. "Each keyword has a default target (shown in the keyword documentation). You can override this by specifying a `target` parameter in the keyword configuration.\n\n"
    output = output .. "Available target types:\n\n"
    output = output .. "| Target Type | Description |\n"
    output = output .. "|------------|-------------|\n"
    output = output .. "| `self` | Affects the caster |\n"
    output = output .. "| `enemy` | Affects the opponent |\n"
    output = output .. "| `pool_self` | Affects the caster's mana pool |\n"
    output = output .. "| `pool_enemy` | Affects the opponent's mana pool |\n"
    output = output .. "| `slot_self` | Affects the caster's spell slots |\n"
    output = output .. "| `slot_enemy` | Affects the opponent's spell slots |\n"
    output = output .. "| `global` | Affects the game state |\n"
    output = output .. "| `none` | No specific target |\n\n"
    
    -- Multi-target spell example
    output = output .. "### Arcane Reversal (Multi-Target Example)\n\n"
    output = output .. "```lua\nSpells.arcaneReversal = {\n"
    output = output .. "    id = \"arcanereversal\",\n"
    output = output .. "    name = \"Arcane Reversal\",\n"
    output = output .. "    description = \"A complex spell that manipulates mana, movement, and timing simultaneously\",\n"
    output = output .. "    attackType = \"remote\",\n"
    output = output .. "    castTime = 6.0,\n"
    output = output .. "    cost = {\"moon\", \"star\", \"force\", \"force\"},\n"
    output = output .. "    keywords = {\n"
    output = output .. "        -- Apply damage to enemy\n"
    output = output .. "        damage = {\n"
    output = output .. "            amount = function(caster, target)\n"
    output = output .. "                -- More damage if enemy has active shields\n"
    output = output .. "                local shieldCount = 0\n"
    output = output .. "                for _, slot in ipairs(target.spellSlots) do\n"
    output = output .. "                    if slot.active and slot.isShield then\n"
    output = output .. "                        shieldCount = shieldCount + 1\n"
    output = output .. "                    end\n"
    output = output .. "                end\n"
    output = output .. "                return 8 + (shieldCount * 4)  -- 8 base + 4 per shield\n"
    output = output .. "            end,\n"
    output = output .. "            type = \"star\",\n"
    output = output .. "            target = \"ENEMY\"  -- Explicit targeting\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Move self to opposite range\n"
    output = output .. "        rangeShift = {\n"
    output = output .. "            position = function(caster, target)\n"
    output = output .. "                return caster.gameState.rangeState == \"NEAR\" and \"FAR\" or \"NEAR\"\n"
    output = output .. "            end,\n"
    output = output .. "            target = \"SELF\"  -- Different target from damage\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Lock opponent's mana tokens\n"
    output = output .. "        lock = {\n"
    output = output .. "            duration = 4.0,\n"
    output = output .. "            target = \"POOL_ENEMY\"  -- Target opponent's pool\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Add tokens to own pool\n"
    output = output .. "        conjure = {\n"
    output = output .. "            token = \"force\",\n"
    output = output .. "            amount = 1,\n"
    output = output .. "            target = \"POOL_SELF\"  -- Target own pool\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Accelerate own next spell\n"
    output = output .. "        accelerate = {\n"
    output = output .. "            amount = 2.0,\n"
    output = output .. "            slot = 1,  -- First slot\n"
    output = output .. "            target = \"SLOT_SELF\"  -- Target own slot\n"
    output = output .. "        }\n"
    output = output .. "    },\n"
    output = output .. "    vfx = \"arcane_reversal\",\n"
    output = output .. "    blockableBy = {\"ward\", \"field\"}\n"
    output = output .. "}\n```\n\n"
    
    -- Fireball example
    output = output .. "### Fireball\n\n"
    output = output .. "```lua\nSpells.fireball = {\n"
    output = output .. "    id = \"fireball\",\n"
    output = output .. "    name = \"Fireball\",\n"
    output = output .. "    description = \"Launches a ball of fire that deals heavy damage\",\n"
    output = output .. "    attackType = \"projectile\",\n"
    output = output .. "    castTime = 4.0,\n"
    output = output .. "    cost = {\"fire\", \"fire\", \"force\"},\n"
    output = output .. "    keywords = {\n"
    output = output .. "        damage = {\n"
    output = output .. "            amount = function(caster, target)\n"
    output = output .. "                -- More damage at FAR range\n"
    output = output .. "                return caster.gameState.rangeState == \"FAR\" and 18 or 12\n"
    output = output .. "            end,\n"
    output = output .. "            type = \"fire\"\n"
    output = output .. "            -- No target specified, uses default: ENEMY\n"
    output = output .. "        },\n"
    output = output .. "        -- Add AOE effect if cast from AERIAL\n"
    output = output .. "        zoneMulti = function(caster, target)\n"
    output = output .. "            return caster.elevation == \"AERIAL\"\n"
    output = output .. "        end\n"
    output = output .. "    },\n"
    output = output .. "    vfx = \"fireball\",\n"
    output = output .. "    sfx = \"explosion\",\n"
    output = output .. "    blockableBy = {\"barrier\"}\n"
    output = output .. "}\n```\n\n"
    
    return output
end

-- Generate a documentation file
function DocGenerator.writeDocumentation(outputPath)
    outputPath = outputPath or "/Users/russell/Manastorm/docs/KEYWORDS.md"
    
    local markdown = DocGenerator.generateMarkdown()
    
    local file = io.open(outputPath, "w")
    if file then
        file:write(markdown)
        file:close()
        print("Keyword documentation written to: " .. outputPath)
        return true
    else
        print("Error: Could not open file for writing: " .. outputPath)
        return false
    end
end

-- Execute documentation generation if this file is run directly
if not ... then
    DocGenerator.writeDocumentation()
end

return DocGenerator```

## ./keywords.lua
```lua
-- keywords.lua
-- Defines all keywords and their behaviors for the spell system

local Keywords = {}

-- Keyword categories for organization
Keywords.categories = {
    DAMAGE = "Damage Effects",
    DOT = "Damage Over Time",
    TIMING = "Spell Timing",
    MOVEMENT = "Movement & Position",
    RESOURCE = "Resource Manipulation",
    TOKEN = "Token Manipulation",
    DEFENSE = "Defense Mechanisms",
    SPECIAL = "Special Effects",
    ZONE = "Zone Mechanics"
}

-- Target types for keywords
Keywords.targetTypes = {
    SELF = "self",               -- The caster
    ENEMY = "enemy",             -- The opponent
    SLOT_SELF = "slot_self",     -- Caster's spell slots
    SLOT_ENEMY = "slot_enemy",   -- Opponent's spell slots
    POOL_SELF = "pool_self",     -- Shared mana pool (from caster's perspective)
    POOL_ENEMY = "pool_enemy"    -- Shared mana pool (from opponent's perspective)
}

-- ===== Core Combat Keywords =====

-- damage: Deals direct damage to a target
Keywords.damage = {
    -- Behavior definition
    behavior = {
        dealsDamage = true,
        targetType = "ENEMY",
        category = "DAMAGE",
        
        -- Default parameters
        defaultAmount = 0,
        defaultType = "generic"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
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
            end
        else
            -- Static damage value
            results.damage = damageAmount
        end
        
        results.damageType = params.type
        return results
    end
}

-- burn: Applies damage over time effect
Keywords.burn = {
    -- Behavior definition
    behavior = {
        appliesStatusEffect = true,
        statusType = "burn",
        dealsDamageOverTime = true,
        targetType = "ENEMY",
        category = "DOT",
        
        -- Default parameters
        defaultDuration = 3.0,
        defaultTickDamage = 2,
        defaultTickInterval = 1.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.burnApplied = true
        results.burnDuration = params.duration or 3.0
        results.burnTickDamage = params.tickDamage or 2
        results.burnTickInterval = params.tickInterval or 1.0  -- Default to 1 second between ticks
        return results
    end
}

-- stagger: Interrupts a spell and prevents recasting for a duration
Keywords.stagger = {
    -- Behavior definition
    behavior = {
        interruptsSpell = true,
        preventsRecasting = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING",
        
        -- Default parameters
        defaultDuration = 3.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.stagger = true
        results.targetSlot = params.slot or 0
        results.staggerDuration = params.duration or 3.0
        return results
    end
}

-- ===== Movement & Positioning Keywords =====

-- elevate: Sets a wizard to AERIAL state
Keywords.elevate = {
    -- Behavior definition
    behavior = {
        setsElevationState = "AERIAL",
        hasDefaultDuration = true,
        targetType = "SELF",
        category = "MOVEMENT",
        
        -- Default parameters
        defaultDuration = 5.0,
        defaultVfx = "emberlift"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.setElevation = "AERIAL"
        results.elevationDuration = params.duration or 5.0
        -- Store the target that should receive this effect
        results.elevationTarget = params.target or "SELF" -- Default to SELF
        -- Store the visual effect to use
        results.elevationVfx = params.vfx or "emberlift"
        return results
    end
}

-- ground: Forces a wizard to GROUNDED state
Keywords.ground = {
    -- Behavior definition
    behavior = {
        setsElevationState = "GROUNDED",
        canBeConditional = true,
        targetType = "ENEMY",
        category = "MOVEMENT"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        -- Check if there's a conditional function
        if params.conditional and type(params.conditional) == "function" then
            -- Only apply grounding if the condition is met
            if params.conditional(caster, target) then
                results.setElevation = "GROUNDED"
                -- Store the target that should receive this effect
                results.elevationTarget = params.target or "ENEMY" -- Default to ENEMY
            end
        else
            -- No condition, apply grounding unconditionally
            results.setElevation = "GROUNDED"
            results.elevationTarget = params.target or "ENEMY" -- Default to ENEMY
        end
        
        return results
    end
}

-- rangeShift: Changes the range state (NEAR/FAR)
Keywords.rangeShift = {
    -- Behavior definition
    behavior = {
        setsRangeState = true,
        targetType = "SELF",
        category = "MOVEMENT",
        
        -- Default parameters
        defaultPosition = "NEAR" 
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.setPosition = params.position or "NEAR"
        return results
    end
}

-- forcePull: Forces opponent to move to caster's range
Keywords.forcePull = {
    -- Behavior definition
    behavior = {
        forcesOpponentPosition = true,
        targetType = "ENEMY",
        category = "MOVEMENT"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        -- Force opponent to move to caster's range
        results.forcePosition = true
        return results
    end
}

-- ===== Resource & Token Keywords =====

-- conjure: Creates new tokens in the shared mana pool
Keywords.conjure = {
    -- Behavior definition
    behavior = {
        addsTokensToSharedPool = true,
        targetType = "POOL_SELF", -- Indicates who gets credit for the conjuring, not a separate pool
        category = "RESOURCE",
        
        -- Default parameters
        defaultTokenType = "fire",
        defaultAmount = 1
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        local tokenType = params.token or "fire"
        local amount = params.amount or 1
        
        for i = 1, amount do
            local assetPath = "assets/sprites/" .. tokenType .. "-token.png"
            caster.manaPool:addToken(tokenType, assetPath)
        end
        
        return results
    end
}

-- dissipate: Removes tokens from the shared mana pool
Keywords.dissipate = {
    -- Behavior definition
    behavior = {
        removesTokensFromSharedPool = true,
        targetType = "POOL_ENEMY", -- Indicates which player is causing the removal, not separate pools
        category = "RESOURCE",
        
        -- Default parameters
        defaultTokenType = "any",
        defaultAmount = 1
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
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
                
                -- Stop once we've marked enough tokens
                if tokensFound >= amount then
                    break
                end
            end
        end
        
        results.tokensDestroyed = tokensFound
        
        return results
    end
}

-- tokenShift: Changes token types in the shared mana pool
Keywords.tokenShift = {
    -- Behavior definition
    behavior = {
        transformsTokensInSharedPool = true,
        targetType = "POOL_SELF", -- Indicates who initiates the transformation, not separate pools
        category = "RESOURCE",
        
        -- Default parameters
        defaultTokenType = "fire",
        defaultAmount = 1,
        supportedTypes = {"fire", "force", "moon", "nature", "star", "random"}
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
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
    end
}

-- lock: Locks tokens in the shared mana pool, preventing their use for a duration
Keywords.lock = {
    -- Behavior definition
    behavior = {
        locksTokensInSharedPool = true,
        hasDefaultDuration = true,
        targetType = "POOL_ENEMY", -- Indicates which tokens to target, not separate pools
        category = "TOKEN",
        
        -- Default parameters
        defaultDuration = 5.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.lockToken = true
        results.lockDuration = params.duration or 5.0
        return results
    end
}

-- ===== Cast Time Keywords =====

-- delay: Adds time to opponent's spell cast
Keywords.delay = {
    -- Behavior definition
    behavior = {
        increasesSpellCastTime = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING",
        
        -- Default parameters
        defaultDuration = 1.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.delayApplied = true
        results.targetSlot = params.slot or 0  -- 0 means random or auto-select
        results.delayAmount = params.duration or 1.0
        return results
    end
}

-- accelerate: Reduces cast time of a spell
Keywords.accelerate = {
    -- Behavior definition
    behavior = {
        reducesSpellCastTime = true,
        targetType = "SLOT_SELF",
        category = "TIMING",
        
        -- Default parameters
        defaultAmount = 1.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.accelerate = true
        results.targetSlot = params.slot or 0  -- 0 means self or current slot
        results.accelerateAmount = params.amount or 1.0
        return results
    end
}

-- dispel: Cancels a spell and returns mana to the pool
Keywords.dispel = {
    -- Behavior definition
    behavior = {
        cancelsSpell = true,
        returnsManaToPool = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.dispel = true
        results.targetSlot = params.slot or 0  -- 0 means random active slot
        return results
    end
}

-- disjoint: Cancels a spell and destroys its mana
Keywords.disjoint = {
    -- Behavior definition
    behavior = {
        cancelsSpell = true,
        destroysMana = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.disjoint = true
        results.targetSlot = params.slot or 0
        return results
    end
}

-- freeze: Pauses a spell's progress for a duration
Keywords.freeze = {
    -- Behavior definition
    behavior = {
        pausesSpellProgress = true,
        targetType = "SLOT_ENEMY",
        category = "TIMING",
        
        -- Default parameters
        defaultSlot = 2,  -- Default to middle slot
        defaultDuration = 2.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.freezeApplied = true
        results.targetSlot = params.slot or 2  -- Default to middle slot
        results.freezeDuration = params.duration or 2.0
        return results
    end
}

-- ===== Defense Keywords =====

-- block: Creates a shield to block specific attack types
Keywords.block = {
    -- Behavior definition
    behavior = {
        createsShield = true,
        targetType = "SELF",
        category = "DEFENSE",
        
        -- Shield properties
        shieldTypes = {"barrier", "ward", "field"},
        attackTypes = {"projectile", "remote", "zone"}
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        -- Create a structured shieldParams table within the results
        results.shieldParams = {
            createShield = true,
            defenseType = params.type or "barrier",
            blocksAttackTypes = params.blocks or {"projectile"},
            reflect = params.reflect or false
            -- Mana-linking is now the default, no need for a flag
        }
        
        return results
    end
}

-- reflect: Reflects incoming spells
Keywords.reflect = {
    -- Behavior definition
    behavior = {
        reflectsSpells = true,
        targetType = "SELF",
        category = "DEFENSE",
        
        -- Default parameters
        defaultDuration = 3.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.reflect = true
        results.reflectDuration = params.duration or 3.0
        return results
    end
}

-- ===== Special Effect Keywords =====

-- echo: Recasts the spell after a delay
Keywords.echo = {
    -- Behavior definition
    behavior = {
        recastsSpell = true,
        targetType = "SLOT_SELF",
        category = "SPECIAL",
        
        -- Default parameters
        defaultDelay = 2.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.echo = true
        results.echoDelay = params.delay or 2.0
        return results
    end
}

-- ===== Zone Keywords =====

-- zoneAnchor: Locks spell to cast-time range; fails if range changes
Keywords.zoneAnchor = {
    -- Behavior definition
    behavior = {
        anchorsSpellToConditions = true,
        targetType = "SELF",
        category = "ZONE",
        
        -- Parameters
        conditionTypes = {"range", "elevation"}
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
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
    end
}

-- zoneMulti: Makes zone affect both NEAR and FAR ranges
Keywords.zoneMulti = {
    -- Behavior definition
    behavior = {
        affectsBothRanges = true,
        targetType = "SELF",
        category = "ZONE"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.zoneMulti = true
        return results
    end
}

return Keywords```

## ./main.lua
```lua
-- Manastorm - Wizard Duel Game
-- Main game file

-- Load dependencies
local Wizard = require("wizard")
local ManaPool = require("manapool")
local UI = require("ui")
local VFX = require("vfx")
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local SpellsModule = require("spells")

-- Resolution settings
local baseWidth = 800    -- Base design resolution width
local baseHeight = 600   -- Base design resolution height
local scale = 1          -- Current scaling factor
local offsetX = 0        -- Horizontal offset for pillarboxing
local offsetY = 0        -- Vertical offset for letterboxing

-- Game state (globally accessible)
game = {
    wizards = {},
    manaPool = nil,
    font = nil,
    rangeState = "FAR",  -- Initial range state (NEAR or FAR)
    gameOver = false,
    winner = nil,
    winScreenTimer = 0,
    winScreenDuration = 5,  -- How long to show the win screen before auto-reset
    keywords = Keywords,
    spellCompiler = SpellCompiler,
    -- Resolution properties
    baseWidth = baseWidth,
    baseHeight = baseHeight,
    scale = scale,
    offsetX = offsetX,
    offsetY = offsetY
}

-- Define token types and images (globally available for consistency)
game.tokenTypes = {"fire", "force", "moon", "nature", "star"}
game.tokenImages = {
    fire = "assets/sprites/fire-token.png",
    force = "assets/sprites/force-token.png",
    moon = "assets/sprites/moon-token.png",
    nature = "assets/sprites/nature-token.png",
    star = "assets/sprites/star-token.png"
}

-- Helper function to add a random token to the mana pool
function game.addRandomToken()
    local randomType = game.tokenTypes[math.random(#game.tokenTypes)]
    game.manaPool:addToken(randomType, game.tokenImages[randomType])
    return randomType
end

-- Calculate the appropriate scaling for the current window size
function calculateScaling()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Calculate possible scales (use integer scaling for pixel art crispness)
    local scaleX = math.floor(windowWidth / baseWidth)
    local scaleY = math.floor(windowHeight / baseHeight)
    
    -- Use the smaller scale to fit the screen
    scale = math.max(1, math.min(scaleX, scaleY))
    
    -- Calculate offsets for centering (letterbox/pillarbox)
    offsetX = math.floor((windowWidth - baseWidth * scale) / 2)
    offsetY = math.floor((windowHeight - baseHeight * scale) / 2)
    
    -- Update global references
    game.scale = scale
    game.offsetX = offsetX
    game.offsetY = offsetY
    
    print("Window resized: " .. windowWidth .. "x" .. windowHeight .. " (scale: " .. scale .. ")")
end

-- Handle window resize events
function love.resize(width, height)
    calculateScaling()
end

-- Set up pixel art-friendly scaling
function configurePixelArtRendering()
    -- Disable texture filtering for crisp pixel art
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    
    -- Use integer scaling when possible
    love.graphics.setLineStyle("rough")
end

function love.load()
    -- Set up window
    love.window.setTitle("Manastorm - Wizard Duel")
    
    -- Configure pixel art rendering
    configurePixelArtRendering()
    
    -- Calculate initial scaling
    calculateScaling()
    
    -- Use system font for now
    game.font = love.graphics.newFont(16)  -- Default system font
    
    -- Set default font for normal rendering
    love.graphics.setFont(game.font)
    
    -- Create mana pool positioned above the battlefield, but below health bars
    game.manaPool = ManaPool.new(baseWidth/2, 120)  -- Positioned between health bars and wizards
    
    -- Create wizards - moved lower on screen to allow more room for aerial movement
    game.wizards[1] = Wizard.new("Ashgar", 200, 370, {255, 100, 100})
    game.wizards[2] = Wizard.new("Selene", 600, 370, {100, 100, 255})
    
    -- Set up references
    for _, wizard in ipairs(game.wizards) do
        wizard.manaPool = game.manaPool
        wizard.gameState = game
    end
    
    -- Initialize VFX system
    game.vfx = VFX.init()
    
    -- Precompile all spells for better performance
    print("Precompiling all spells...")
    
    -- Create a compiledSpells table and do the compilation ourselves
    game.compiledSpells = {}
    
    -- Get all spells from the SpellsModule
    local allSpells = SpellsModule.spells
    
    -- Compile each spell
    for id, spell in pairs(allSpells) do
        game.compiledSpells[id] = game.spellCompiler.compileSpell(spell, game.keywords)
        print("Compiled spell: " .. spell.name)
    end
    
    -- Count compiled spells
    local count = 0
    for _ in pairs(game.compiledSpells) do
        count = count + 1
    end
    
    print("Precompiled " .. count .. " spells")
    
    -- Create custom shield spells just for hotkeys
    -- These are complete, independent spell definitions
    game.customSpells = {}
    
    -- Define Moon Ward with minimal dependencies
    game.customSpells.moonWard = {
        id = "customMoonWard",
        name = "Moon Ward",
        description = "A mystical ward that blocks projectiles and remotes",
        attackType = "utility",
        castTime = 4.5,
        cost = {"moon", "moon"},
        keywords = {
            block = {
                type = "ward",
                blocks = {"projectile", "remote"},
                manaLinked = true
            }
        },
        vfx = "moon_ward",
        sfx = "shield_up",
        blockableBy = {}
    }
    
    -- Define Mirror Shield with minimal dependencies
    game.customSpells.mirrorShield = {
        id = "customMirrorShield",
        name = "Mirror Shield",
        description = "A reflective barrier that returns damage to attackers",
        attackType = "utility",
        castTime = 5.0,
        cost = {"moon", "moon", "star"},
        keywords = {
            block = {
                type = "barrier",
                blocks = {"projectile", "zone"},
                manaLinked = false,
                reflect = true,
                hitPoints = 3
            }
        },
        vfx = "mirror_shield",
        sfx = "crystal_ring",
        blockableBy = {}
    }
    
    -- Compile custom spells too
    for id, spell in pairs(game.customSpells) do
        game.compiledSpells[id] = game.spellCompiler.compileSpell(spell, game.keywords)
        print("Compiled custom spell: " .. spell.name)
    end
    
    -- Initialize mana pool with a single random token to start
    local tokenType = game.addRandomToken()
    
    -- Log which token was added
    print("Starting the game with a single " .. tokenType .. " token")
end

-- Reset the game
function resetGame()
    -- Reset game state
    game.gameOver = false
    game.winner = nil
    game.winScreenTimer = 0
    
    -- Reset wizards
    for _, wizard in ipairs(game.wizards) do
        wizard.health = 100
        wizard.elevation = "GROUNDED"
        wizard.elevationTimer = 0
        wizard.stunTimer = 0
        
        -- Reset spell slots
        for i = 1, 3 do
            wizard.spellSlots[i] = {
                active = false,
                progress = 0,
                spellType = nil,
                castTime = 0,
                tokens = {},
                isShield = false,
                defenseType = nil,
                shieldStrength = 0,
                blocksAttackTypes = nil
            }
        end
        
        -- Reset status effects
        wizard.statusEffects.burn.active = false
        wizard.statusEffects.burn.duration = 0
        wizard.statusEffects.burn.tickDamage = 0
        wizard.statusEffects.burn.tickInterval = 1.0
        wizard.statusEffects.burn.elapsed = 0
        wizard.statusEffects.burn.totalTime = 0
        
        -- Reset blockers
        for blockType in pairs(wizard.blockers) do
            wizard.blockers[blockType] = 0
        end
        
        -- Reset spell keying
        wizard.activeKeys = {[1] = false, [2] = false, [3] = false}
        wizard.currentKeyedSpell = nil
    end
    
    -- Reset range state
    game.rangeState = "FAR"
    
    -- Clear mana pool and add a single token to start
    game.manaPool:clear()
    local tokenType = game.addRandomToken()
    
    -- Reset health display animation state
    for i = 1, 2 do
        local display = UI.healthDisplay["player" .. i]
        display.currentHealth = 100
        display.targetHealth = 100
        display.pendingDamage = 0
        display.lastDamageTime = 0
    end
    
    print("Game reset! Starting with a single " .. tokenType .. " token")
end

-- Handle keybindings for window size adjustments
function love.keypressed(key, scancode, isrepeat)
    -- Scale adjustments
    if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
        if key == "1" then
            love.window.setMode(baseWidth, baseHeight)
            calculateScaling()
        elseif key == "2" then
            love.window.setMode(baseWidth * 2, baseHeight * 2)
            calculateScaling()
        elseif key == "3" then
            love.window.setMode(baseWidth * 3, baseHeight * 3)
            calculateScaling()
        elseif key == "f" then
            love.window.setFullscreen(not love.window.getFullscreen())
            calculateScaling()
        end
    end
end

function love.update(dt)
    -- Check for win condition before updates
    if game.gameOver then
        -- Update win screen timer
        game.winScreenTimer = game.winScreenTimer + dt
        
        -- Auto-reset after duration
        if game.winScreenTimer >= game.winScreenDuration then
            resetGame()
        end
        
        -- Still update VFX system for visual effects
        game.vfx.update(dt)
        return
    end
    
    -- Check if any wizard's health has reached zero
    for i, wizard in ipairs(game.wizards) do
        if wizard.health <= 0 then
            game.gameOver = true
            game.winner = 3 - i  -- Winner is the other wizard (3-1=2, 3-2=1)
            game.winScreenTimer = 0
            
            -- Create victory VFX around the winner
            local winner = game.wizards[game.winner]
            for j = 1, 15 do
                local angle = math.random() * math.pi * 2
                local distance = math.random(40, 100)
                local x = winner.x + math.cos(angle) * distance
                local y = winner.y + math.sin(angle) * distance
                
                -- Determine winner's color for effects
                local color
                if game.winner == 1 then -- Ashgar
                    color = {1.0, 0.5, 0.2, 0.9} -- Fire-like
                else -- Selene
                    color = {0.3, 0.3, 1.0, 0.9} -- Moon-like
                end
                
                -- Create sparkle effect with delay
                game.vfx.createEffect("impact", x, y, nil, nil, {
                    duration = 0.8 + math.random() * 0.5,
                    color = color,
                    particleCount = 5,
                    radius = 15,
                    delay = j * 0.1
                })
            end
            
            print(winner.name .. " wins!")
            break
        end
    end
    
    -- Update wizards
    for _, wizard in ipairs(game.wizards) do
        wizard:update(dt)
    end
    
    -- Update mana pool
    game.manaPool:update(dt)
    
    -- Update VFX system
    game.vfx.update(dt)
    
    -- Update animated health displays
    UI.updateHealthDisplays(dt, game.wizards)
end

function love.draw()
    -- Clear entire screen to black first (for letterboxing/pillarboxing)
    love.graphics.clear(0, 0, 0, 1)
    
    -- Setup scaling transform
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)
    
    -- Clear game area with game background color
    love.graphics.setColor(20/255, 20/255, 40/255, 1)
    love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    
    -- Draw range state indicator (NEAR/FAR)
    drawRangeIndicator()
    
    -- Draw mana pool
    game.manaPool:draw()
    
    -- Draw wizards
    for _, wizard in ipairs(game.wizards) do
        wizard:draw()
    end
    
    -- Draw visual effects layer (between wizards and UI)
    game.vfx.draw()
    
    -- Draw UI (health bars and wizard names are handled in UI.drawSpellInfo)
    love.graphics.setColor(1, 1, 1)
    
    -- Always draw spellbook components
    UI.drawSpellbookButtons()
    
    -- Draw spell info (health bars, etc.)
    UI.drawSpellInfo(game.wizards)
    
    -- Draw win screen if game is over
    if game.gameOver and game.winner then
        drawWinScreen()
    end
    
    -- Debug info only when debug key is pressed
    if love.keyboard.isDown("`") then
        UI.drawHelpText(game.font)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        
        -- Show scaling info in debug mode
        love.graphics.print("Scale: " .. scale .. "x (" .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight() .. ")", 10, 30)
    else
        -- Always show a small hint about the debug key
        love.graphics.setColor(0.6, 0.6, 0.6, 0.4)
        love.graphics.print("Press ` for debug controls", 10, baseHeight - 20)
    end
    
    -- End scaling transform
    love.graphics.pop()
    
    -- Draw letterbox/pillarbox borders if needed
    if offsetX > 0 or offsetY > 0 then
        love.graphics.setColor(0, 0, 0)
        -- Top letterbox
        if offsetY > 0 then
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), offsetY)
            love.graphics.rectangle("fill", 0, love.graphics.getHeight() - offsetY, love.graphics.getWidth(), offsetY)
        end
        -- Left/right pillarbox
        if offsetX > 0 then
            love.graphics.rectangle("fill", 0, 0, offsetX, love.graphics.getHeight())
            love.graphics.rectangle("fill", love.graphics.getWidth() - offsetX, 0, offsetX, love.graphics.getHeight())
        end
    end
end

-- Helper function to convert real screen coordinates to virtual (scaled) coordinates
function screenToGameCoords(x, y)
    if not x or not y then return nil, nil end
    
    -- Adjust for offset and scale
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    
    -- Check if the point is outside the game area
    if virtualX < 0 or virtualX > baseWidth or virtualY < 0 or virtualY > baseHeight then
        return nil, nil  -- Out of bounds
    end
    
    return virtualX, virtualY
end

-- Override love.mouse.getPosition for seamless integration
local original_getPosition = love.mouse.getPosition
love.mouse.getPosition = function()
    local rx, ry = original_getPosition()
    local vx, vy = screenToGameCoords(rx, ry)
    return vx or 0, vy or 0
end

-- Draw the win screen
function drawWinScreen()
    local screenWidth = baseWidth
    local screenHeight = baseHeight
    local winner = game.wizards[game.winner]
    
    -- Fade in effect
    local fadeProgress = math.min(game.winScreenTimer / 0.5, 1.0)
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7 * fadeProgress)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Determine winner's color scheme
    local winnerColor
    if game.winner == 1 then -- Ashgar
        winnerColor = {1.0, 0.4, 0.2} -- Fire-like
    else -- Selene
        winnerColor = {0.4, 0.4, 1.0} -- Moon-like
    end
    
    -- Calculate animation progress for text
    local textProgress = math.min(math.max(game.winScreenTimer - 0.5, 0) / 0.5, 1.0)
    local textScale = 1 + (1 - textProgress) * 3 -- Text starts larger and shrinks to normal size
    local textY = screenHeight / 2 - 100
    
    -- Draw winner text with animated scale
    love.graphics.setColor(winnerColor[1], winnerColor[2], winnerColor[3], textProgress)
    
    -- Main victory text
    local victoryText = winner.name .. " WINS!"
    local victoryTextWidth = game.font:getWidth(victoryText) * textScale * 3
    love.graphics.print(
        victoryText, 
        screenWidth / 2 - victoryTextWidth / 2, 
        textY,
        0, -- rotation
        textScale * 3, -- scale X
        textScale * 3  -- scale Y
    )
    
    -- Only show restart instructions after initial animation
    if game.winScreenTimer > 1.0 then
        -- Calculate pulse effect
        local pulse = 0.7 + 0.3 * math.sin(game.winScreenTimer * 4)
        
        -- Draw restart instruction with pulse effect
        local restartText = "Press [SPACE] to play again"
        local restartTextWidth = game.font:getWidth(restartText) * 1.5
        
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.print(
            restartText,
            screenWidth / 2 - restartTextWidth / 2,
            textY + 150,
            0, -- rotation
            1.5, -- scale X
            1.5  -- scale Y
        )
        
        -- Show auto-restart countdown
        local remainingTime = math.ceil(game.winScreenDuration - game.winScreenTimer)
        local countdownText = "Auto-restart in " .. remainingTime .. "..."
        local countdownTextWidth = game.font:getWidth(countdownText)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
        love.graphics.print(
            countdownText,
            screenWidth / 2 - countdownTextWidth / 2,
            textY + 200
        )
    end
    
    -- Draw some victory effect particles
    for i = 1, 3 do
        if math.random() < 0.3 then
            local x = math.random(screenWidth)
            local y = math.random(screenHeight)
            local size = math.random(10, 30)
            
            love.graphics.setColor(
                winnerColor[1], 
                winnerColor[2], 
                winnerColor[3], 
                math.random() * 0.3
            )
            love.graphics.circle("fill", x, y, size)
        end
    end
end

-- Function to draw the range indicator for NEAR/FAR states
function drawRangeIndicator()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX = screenWidth / 2
    
    -- Only draw a subtle central line, without the text indicators
    -- The wizard positions themselves will communicate NEAR/FAR state
    
    -- Different visual style based on range state
    if game.rangeState == "NEAR" then
        -- For NEAR state, draw a more vibrant, energetic line
        love.graphics.setColor(0.5, 0.5, 0.9, 0.4)
        
        -- Draw main line
        love.graphics.setLineWidth(1.5)
        love.graphics.line(centerX, 200, centerX, screenHeight - 100)
        
        -- Add a subtle energetic glow/pulse
        for i = 1, 5 do
            local pulseWidth = 3 + math.sin(love.timer.getTime() * 2.5) * 2
            local alpha = 0.12 - (i * 0.02)
            love.graphics.setColor(0.5, 0.5, 0.9, alpha)
            love.graphics.setLineWidth(pulseWidth * i)
            love.graphics.line(centerX, 200, centerX, screenHeight - 100)
        end
        love.graphics.setLineWidth(1)
    else
        -- For FAR state, draw a more distant, faded line
        love.graphics.setColor(0.3, 0.3, 0.7, 0.3)
        
        -- Draw main line with slight wave effect
        local segments = 12
        local segmentHeight = (screenHeight - 300) / segments
        local points = {}
        
        for i = 0, segments do
            local y = 200 + i * segmentHeight
            local wobble = math.sin(love.timer.getTime() + i * 0.3) * 1.5
            table.insert(points, centerX + wobble)
            table.insert(points, y)
        end
        
        love.graphics.setLineWidth(1)
        love.graphics.line(points)
        
        -- Add very subtle horizontal distortion lines
        for i = 1, 5 do
            local y = 200 + (i * (screenHeight - 300) / 6)
            local width = 15 + math.sin(love.timer.getTime() * 0.7 + i) * 5
            local alpha = 0.05
            love.graphics.setColor(0.3, 0.3, 0.7, alpha)
            love.graphics.setLineWidth(0.5)
            love.graphics.line(centerX - width, y, centerX + width, y)
        end
    end
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

function love.keypressed(key)
    -- Debug all key presses to isolate input issues
    print("DEBUG: Key pressed: '" .. key .. "'")
    
    -- Check for game over state first
    if game.gameOver then
        -- Reset game on space bar press during game over
        if key == "space" then
            resetGame()
        end
        return
    end
    
    if key == "escape" then
        love.event.quit()
    end
    
    -- Player 1 (Ashgar) key handling for spell combinations
    if key == "q" then
        game.wizards[1]:keySpell(1, true)
    elseif key == "w" then
        game.wizards[1]:keySpell(2, true)
    elseif key == "e" then
        game.wizards[1]:keySpell(3, true)
    elseif key == "f" then
        -- Cast key for Player 1
        game.wizards[1]:castKeyedSpell()
    elseif key == "g" then
        -- Free key for Player 1
        game.wizards[1]:freeAllSpells()
    elseif key == "b" then
        -- Toggle spellbook for Player 1
        UI.toggleSpellbook(1)
    end
    
    -- Player 2 (Selene) key handling for spell combinations
    if key == "i" then
        game.wizards[2]:keySpell(1, true)
    elseif key == "o" then
        game.wizards[2]:keySpell(2, true)
    elseif key == "p" then
        game.wizards[2]:keySpell(3, true)
    elseif key == "j" then
        -- Cast key for Player 2
        game.wizards[2]:castKeyedSpell()
    elseif key == "h" then
        -- Free key for Player 2
        game.wizards[2]:freeAllSpells()
    elseif key == "m" then
        -- Toggle spellbook for Player 2
        UI.toggleSpellbook(2)
    end
    
    -- Debug: Add a single random token with T key
    if key == "t" then
        local tokenType = game.addRandomToken()
        print("Added a " .. tokenType .. " token to the mana pool")
    end
    
    -- Debug: Add specific tokens for testing shield spells
    if key == "z" then
        local tokenType = "moon"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    elseif key == "x" then
        local tokenType = "star"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    elseif key == "c" then
        local tokenType = "force"
        game.manaPool:addToken(tokenType, game.tokenImages[tokenType])
        print("Added a " .. tokenType .. " token to the mana pool")
    end
    
    -- Direct keys for casting shield spells, bypassing keying and issue in cast key "l"
    if key == "1" then
        -- Force cast Moon Ward for Selene
        print("DEBUG: Directly casting Moon Ward for Selene")
        local result = game.wizards[2]:queueSpell(game.customSpells.moonWard)
        print("DEBUG: Moon Ward cast result: " .. tostring(result))
    elseif key == "2" then
        -- Force cast Mirror Shield for Selene
        print("DEBUG: Directly casting Mirror Shield for Selene")
        local result = game.wizards[2]:queueSpell(game.customSpells.mirrorShield)
        print("DEBUG: Mirror Shield cast result: " .. tostring(result))
    end
    
    -- Debug: Position/elevation test controls
    -- Toggle range state with R key
    if key == "r" then
        if game.rangeState == "NEAR" then
            game.rangeState = "FAR"
        else
            game.rangeState = "NEAR"
        end
        print("Range state toggled to: " .. game.rangeState)
    end
    
    -- Toggle Ashgar's elevation with A key
    if key == "a" then
        if game.wizards[1].elevation == "GROUNDED" then
            game.wizards[1].elevation = "AERIAL"
        else
            game.wizards[1].elevation = "GROUNDED"
        end
        print("Ashgar elevation toggled to: " .. game.wizards[1].elevation)
    end
    
    -- Toggle Selene's elevation with S key
    if key == "s" then
        if game.wizards[2].elevation == "GROUNDED" then
            game.wizards[2].elevation = "AERIAL"
        else
            game.wizards[2].elevation = "GROUNDED"
        end
        print("Selene elevation toggled to: " .. game.wizards[2].elevation)
    end
    
    -- Debug: Test VFX effects with number keys
    if key == "1" then
        -- Test firebolt effect
        game.vfx.createEffect("firebolt", game.wizards[1].x, game.wizards[1].y, game.wizards[2].x, game.wizards[2].y)
        print("Testing firebolt VFX")
    elseif key == "2" then
        -- Test meteor effect 
        game.vfx.createEffect("meteor", game.wizards[2].x, game.wizards[2].y - 100, game.wizards[2].x, game.wizards[2].y)
        print("Testing meteor VFX")
    elseif key == "3" then
        -- Test mist veil effect
        game.vfx.createEffect("mistveil", game.wizards[1].x, game.wizards[1].y)
        print("Testing mist veil VFX")
    elseif key == "4" then
        -- Test emberlift effect
        game.vfx.createEffect("emberlift", game.wizards[2].x, game.wizards[2].y)
        print("Testing emberlift VFX") 
    elseif key == "5" then
        -- Test full moon beam effect
        game.vfx.createEffect("fullmoonbeam", game.wizards[2].x, game.wizards[2].y, game.wizards[1].x, game.wizards[1].y)
        print("Testing full moon beam VFX")
    elseif key == "6" then
        -- Test conjure fire effect
        game.vfx.createEffect("conjurefire", game.wizards[1].x, game.wizards[1].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing conjure fire VFX")
    elseif key == "7" then
        -- Test conjure moonlight effect
        game.vfx.createEffect("conjuremoonlight", game.wizards[2].x, game.wizards[2].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing conjure moonlight VFX")
    elseif key == "8" then
        -- Test volatile conjuring effect
        game.vfx.createEffect("volatileconjuring", game.wizards[1].x, game.wizards[1].y, nil, nil, {
            manaPoolX = game.manaPool.x,
            manaPoolY = game.manaPool.y
        })
        print("Testing volatile conjuring VFX")
    end
end

-- Add key release handling to clear key combinations
function love.keyreleased(key)
    -- Player 1 key releases
    if key == "q" then
        game.wizards[1]:keySpell(1, false)
    elseif key == "w" then
        game.wizards[1]:keySpell(2, false)
    elseif key == "e" then
        game.wizards[1]:keySpell(3, false)
    end
    
    -- Player 2 key releases
    if key == "i" then
        game.wizards[2]:keySpell(1, false)
    elseif key == "o" then
        game.wizards[2]:keySpell(2, false)
    elseif key == "p" then
        game.wizards[2]:keySpell(3, false)
    end
end```

## ./manapool.lua
```lua
-- ManaPool class
-- Represents the shared pool of mana tokens in the center

local ManaPool = {}
ManaPool.__index = ManaPool

function ManaPool.new(x, y)
    local self = setmetatable({}, ManaPool)
    
    self.x = x
    self.y = y
    self.tokens = {}  -- List of mana tokens
    
    -- Make elliptical shape even flatter and wider
    self.radiusX = 280  -- Wider horizontal radius
    self.radiusY = 60   -- Flatter vertical radius
    
    -- Define orbital rings (valences) for tokens to follow
    self.valences = {
        {radiusX = 180, radiusY = 25, baseSpeed = 0.35},  -- Inner valence
        {radiusX = 230, radiusY = 40, baseSpeed = 0.25},  -- Middle valence
        {radiusX = 280, radiusY = 55, baseSpeed = 0.18}   -- Outer valence
    }
    
    -- Chance for a token to switch valences
    self.valenceJumpChance = 0.002  -- Per frame chance of switching
    
    -- Load lock overlay image
    self.lockOverlay = love.graphics.newImage("assets/sprites/token-lock.png")
    
    return self
end

-- Clear all tokens from the mana pool
function ManaPool:clear()
    self.tokens = {}
    self.reservedTokens = {}
end

function ManaPool:addToken(tokenType, imagePath)
    -- Pick a random valence for the token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    
    -- Calculate a random angle along the valence
    local angle = math.random() * math.pi * 2
    
    -- Calculate position based on elliptical path
    local x = self.x + math.cos(angle) * valence.radiusX
    local y = self.y + math.sin(angle) * valence.radiusY
    
    -- Generate slight positional variation to avoid tokens stacking perfectly
    local variationX = math.random(-5, 5)
    local variationY = math.random(-3, 3)
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Create a new token with valence-based properties
    local token = {
        type = tokenType,
        image = love.graphics.newImage(imagePath),
        x = x + variationX,
        y = y + variationY,
        state = "FREE",  -- FREE, CHANNELED, SHIELDING, LOCKED, DESTROYED
        lockDuration = 0, -- Duration for how long a token remains locked
        
        -- Valence-based orbit properties
        valenceIndex = valenceIndex,
        orbitAngle = angle,
        -- Speed varies by token but influenced by valence's base speed
        orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction,
        
        -- Visual effects
        pulsePhase = math.random() * math.pi * 2,
        pulseSpeed = 2 + math.random() * 3,
        rotAngle = math.random() * math.pi * 2,
        rotSpeed = math.random(-2, 2) * 0.5, -- Varying rotation speeds
        
        -- Valence jump timer (occasional orbit changes)
        valenceJumpTimer = 2 + math.random() * 8, -- Random time until possible valence change
        
        -- Valence transition properties (for smooth valence changes)
        inValenceTransition = false,
        valenceTransitionTime = 0,
        valenceTransitionDuration = 0.8,
        sourceValenceIndex = valenceIndex,
        targetValenceIndex = valenceIndex,
        sourceRadiusX = valence.radiusX,
        sourceRadiusY = valence.radiusY,
        targetRadiusX = valence.radiusX,
        targetRadiusY = valence.radiusY,
        currentRadiusX = valence.radiusX,
        currentRadiusY = valence.radiusY,
        
        -- Visual effect for locked state
        lockPulse = 0, -- For pulsing animation when locked
        
        -- Size variation for visual interest
        scale = 0.85 + math.random() * 0.3, -- Slight size variation
        
        -- Depth/z-order variation
        zOrder = math.random(),  -- Used for layering tokens
        
        -- We've intentionally removed token repulsion to return to clean orbital motion
    }
    
    token.originalSpeed = token.orbitSpeed
    
    table.insert(self.tokens, token)
end

-- Removed token repulsion system, reverting to pure orbital motion

function ManaPool:update(dt)
    -- Check for destroyed tokens and remove them from the list
    for i = #self.tokens, 1, -1 do
        local token = self.tokens[i]
        if token.state == "DESTROYED" then
            -- Create an explosion/dissolution visual effect if we haven't already
            if not token.dissolving then
                token.dissolving = true
                token.dissolveTime = 0
                token.dissolveMaxTime = 0.8  -- Dissolution animation duration
                token.dissolveScale = token.scale or 1.0
                token.initialX = token.x
                token.initialY = token.y
                
                -- Create visual particle effects at the token's position
                if token.exploding ~= true then  -- Prevent duplicate explosion effects
                    token.exploding = true
                    
                    -- Get token color based on its type
                    local color = {1, 0.6, 0.2, 0.8}  -- Default orange
                    if token.type == "fire" then
                        color = {1, 0.3, 0.1, 0.8}
                    elseif token.type == "force" then
                        color = {1, 0.9, 0.3, 0.8}
                    elseif token.type == "moon" then
                        color = {0.8, 0.6, 1.0, 0.8}  -- Purple for lunar disjunction
                    elseif token.type == "nature" then
                        color = {0.2, 0.9, 0.1, 0.8}
                    elseif token.type == "star" then
                        color = {1, 0.8, 0.2, 0.8}
                    end
                    
                    -- Create destruction visual effect
                    if token.gameState and token.gameState.vfx then
                        -- Use game state VFX system if available
                        token.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                            duration = 0.7,
                            color = color,
                            particleCount = 15,
                            radius = 30
                        })
                    end
                end
            else
                -- Update dissolution animation
                token.dissolveTime = token.dissolveTime + dt
                
                -- When dissolution is complete, remove the token
                if token.dissolveTime >= token.dissolveMaxTime then
                    table.remove(self.tokens, i)
                end
            end
        end
    end
    
    -- Update token positions and states
    for _, token in ipairs(self.tokens) do
        -- Update token position based on state
        if token.state == "FREE" then
            -- Handle the transition period for newly returned tokens
            if token.inTransition then
                token.transitionTime = token.transitionTime + dt
                local transProgress = math.min(1, token.transitionTime / token.transitionDuration)
                
                -- Ease transition using a smooth curve
                transProgress = transProgress < 0.5 and 4 * transProgress * transProgress * transProgress 
                            or 1 - math.pow(-2 * transProgress + 2, 3) / 2
                
                -- During transition, gradually start orbital motion
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt * transProgress
                
                -- Check if transition is complete
                if token.transitionTime >= token.transitionDuration then
                    token.inTransition = false
                end
            else
                -- Normal FREE token behavior after transition
                -- Update orbit angle with variable speed
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt
                
                -- Update valence jump timer
                token.valenceJumpTimer = token.valenceJumpTimer - dt
                
                -- Chance to change valence when timer expires
                if token.valenceJumpTimer <= 0 then
                    token.valenceJumpTimer = 2 + math.random() * 8  -- Reset timer
                    
                    -- Random chance to jump to a different valence
                    if math.random() < self.valenceJumpChance * 100 then
                        -- Store current valence for interpolation
                        local oldValenceIndex = token.valenceIndex
                        local oldValence = self.valences[oldValenceIndex]
                        local newValenceIndex = oldValenceIndex
                        
                        -- Ensure we pick a different valence if more than one exists
                        if #self.valences > 1 then
                            while newValenceIndex == oldValenceIndex do
                                newValenceIndex = math.random(1, #self.valences)
                            end
                        end
                        
                        -- Start valence transition
                        local newValence = self.valences[newValenceIndex]
                        local direction = token.orbitSpeed > 0 and 1 or -1
                        
                        -- Set up transition parameters
                        token.inValenceTransition = true
                        token.valenceTransitionTime = 0
                        token.valenceTransitionDuration = 0.8  -- Time to transition between valences
                        token.sourceValenceIndex = oldValenceIndex
                        token.targetValenceIndex = newValenceIndex
                        token.sourceRadiusX = oldValence.radiusX
                        token.sourceRadiusY = oldValence.radiusY
                        token.targetRadiusX = newValence.radiusX
                        token.targetRadiusY = newValence.radiusY
                        
                        -- Update speed for new valence but maintain direction
                        token.orbitSpeed = newValence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                        token.originalSpeed = token.orbitSpeed
                    end
                end
                
                -- Handle valence transition if active
                if token.inValenceTransition then
                    token.valenceTransitionTime = token.valenceTransitionTime + dt
                    local progress = math.min(1, token.valenceTransitionTime / token.valenceTransitionDuration)
                    
                    -- Use easing function for smooth transition
                    progress = progress < 0.5 and 4 * progress * progress * progress 
                              or 1 - math.pow(-2 * progress + 2, 3) / 2
                    
                    -- Interpolate between source and target radiuses
                    token.currentRadiusX = token.sourceRadiusX + (token.targetRadiusX - token.sourceRadiusX) * progress
                    token.currentRadiusY = token.sourceRadiusY + (token.targetRadiusY - token.sourceRadiusY) * progress
                    
                    -- Check if transition is complete
                    if token.valenceTransitionTime >= token.valenceTransitionDuration then
                        token.inValenceTransition = false
                        token.valenceIndex = token.targetValenceIndex
                    end
                end
                
                -- Occasionally vary the speed slightly
                if math.random() < 0.01 then
                    local direction = token.orbitSpeed > 0 and 1 or -1
                    local valence = self.valences[token.valenceIndex]
                    local variation = 0.9 + math.random() * 0.2  -- Subtle variation
                    token.orbitSpeed = valence.baseSpeed * variation * direction
                end
            end
            
            -- Common behavior for all FREE tokens
            -- Update pulse phase
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            
            -- Calculate new position based on elliptical orbit - maintain perfect elliptical path
            if token.inValenceTransition then
                -- Use interpolated radii during transition
                token.x = self.x + math.cos(token.orbitAngle) * token.currentRadiusX
                token.y = self.y + math.sin(token.orbitAngle) * token.currentRadiusY
            else
                -- Use valence radii when not transitioning
                local valence = self.valences[token.valenceIndex]
                token.x = self.x + math.cos(token.orbitAngle) * valence.radiusX
                token.y = self.y + math.sin(token.orbitAngle) * valence.radiusY
            end
            
            -- Minimal wobble to maintain clean orbits but add slight visual interest
            local wobbleX = math.sin(token.pulsePhase * 0.7) * 2
            local wobbleY = math.cos(token.pulsePhase * 0.5) * 1
            token.x = token.x + wobbleX
            token.y = token.y + wobbleY
            
            -- Rotate token itself for visual interest, occasionally reversing direction
            token.rotAngle = token.rotAngle + token.rotSpeed * dt
            if math.random() < 0.002 then  -- Small chance to reverse rotation
                token.rotSpeed = -token.rotSpeed
            end
        elseif token.state == "CHANNELED" or token.state == "SHIELDING" then
            -- For channeled or shielding tokens, animate movement to/from their spell slot
            
            if token.animTime < token.animDuration then
                -- Token is still being animated to the spell slot
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                -- Start point
                local x0 = token.startX
                local y0 = token.startY
                
                -- End point (in the spell slot)
                local wizard = token.wizardOwner
                if wizard then
                    -- Calculate position in the 3D elliptical spell slot orbit
                    -- These values must match those in wizard.lua drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}  -- From bottom to top
                    local verticalRadii = {20, 25, 30}    -- From bottom to top
                    
                    local slotY = wizard.y + slotYOffsets[token.slotIndex]
                    local radiusX = horizontalRadii[token.slotIndex]
                    local radiusY = verticalRadii[token.slotIndex]
                    
                    local tokenCount = #wizard.spellSlots[token.slotIndex].tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = wizard.spellSlots[token.slotIndex].progress / 
                                       wizard.spellSlots[token.slotIndex].castTime * math.pi * 2 +
                                       anglePerToken * (token.tokenIndex - 1)
                    
                    -- Calculate position using elliptical projection
                    -- Apply the NEAR/FAR offset to the target position
                    local xOffset = 0
                    local isNear = wizard.gameState and wizard.gameState.rangeState == "NEAR"
                    
                    -- Apply the same NEAR/FAR offset logic as in the wizard's draw function
                    if wizard.name == "Ashgar" then -- Player 1 (left side)
                        xOffset = isNear and 60 or 0 -- Move right when NEAR
                    else -- Player 2 (right side)
                        xOffset = isNear and -60 or 0 -- Move left when NEAR
                    end
                    
                    local x3 = wizard.x + xOffset + math.cos(tokenAngle) * radiusX
                    local y3 = slotY + math.sin(tokenAngle) * radiusY
                    
                    -- Control points for bezier (creating an arc)
                    local midX = (x0 + x3) / 2
                    local midY = (y0 + y3) / 2 - 80  -- Arc height
                    
                    -- Quadratic bezier calculation
                    local t = progress
                    local u = 1 - t
                    token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                    token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                    
                    -- Update token rotation during flight
                    token.rotAngle = token.rotAngle + dt * 5  -- Spin faster during flight
                    
                    -- Store target position for the drawing function
                    token.targetX = x3
                    token.targetY = y3
                end
            else
                -- Animation complete - token is now in the spell orbit
                -- Token position will be updated by the wizard's drawSpellSlots function
                token.rotAngle = token.rotAngle + dt * 2  -- Continue spinning in orbit
            end
            
            -- Check if token is returning to the pool
            if token.returning then
                -- Token is being animated back to the mana pool
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                local x0 = token.startX
                local y0 = token.startY
                local x3 = self.x  -- Center of mana pool
                local y3 = self.y
                
                -- Control points for bezier (creating an arc)
                local midX = (x0 + x3) / 2
                local midY = (y0 + y3) / 2 - 50  -- Arc height
                
                -- Quadratic bezier calculation
                local t = progress
                local u = 1 - t
                token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                
                -- Update token rotation during flight - spin faster
                token.rotAngle = token.rotAngle + dt * 8
                
                -- Check if animation is complete
                if token.animTime >= token.animDuration then
                    -- Token has reached the pool - finalize its return and perform state transition
                    print(string.format("[MANAPOOL] Token return animation completed, finalizing state"))
                    self:finalizeTokenReturn(token)
                end
            end
            
            -- Update common pulse
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
        elseif token.state == "LOCKED" then
            -- For locked tokens, update the lock duration
            if token.lockDuration > 0 then
                token.lockDuration = token.lockDuration - dt
                
                -- Update lock pulse for animation
                token.lockPulse = (token.lockPulse + dt * 3) % (math.pi * 2)
                
                -- When lock duration expires, return to FREE state
                if token.lockDuration <= 0 then
                    token.state = "FREE"
                    print("A " .. token.type .. " token has been unlocked and returned to the mana pool")
                    
                    -- Reset position to center with some random velocity
                    token.x = self.x
                    token.y = self.y
                    -- Pick a random valence for the formerly locked token
                    token.valenceIndex = math.random(1, #self.valences)
                    token.orbitAngle = math.random() * math.pi * 2
                    -- Set direction and speed based on the valence
                    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
                    local valence = self.valences[token.valenceIndex]
                    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                    token.originalSpeed = token.orbitSpeed
                    -- No repulsion forces needed (system removed)
                end
            end
            
            -- Even locked tokens should move a bit, but more constrained
            token.x = token.x + math.sin(token.lockPulse) * 0.3
            token.y = token.y + math.cos(token.lockPulse) * 0.3
            
            -- Slight rotation
            token.rotAngle = token.rotAngle + token.rotSpeed * dt * 0.2
        end
        
        -- Update common properties for all tokens
        token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
    end
end

function ManaPool:draw()
    -- No longer drawing the pool background or valence rings
    -- The pool is now completely invisible, defined only by the positions of the tokens
    
    -- Sort tokens by z-order for better layering
    local sortedTokens = {}
    for i, token in ipairs(self.tokens) do
        table.insert(sortedTokens, {token = token, index = i})
    end
    
    table.sort(sortedTokens, function(a, b)
        return a.token.zOrder > b.token.zOrder
    end)
    
    -- Draw tokens in sorted order
    for _, tokenData in ipairs(sortedTokens) do
        local token = tokenData.token
        
        -- Draw a larger, more vibrant glow around the token based on its type
        local glowSize = 15 -- Larger glow radius
        local glowIntensity = 0.6  -- Stronger glow intensity
        
        -- Multiple glow layers for more visual interest
        for layer = 1, 2 do
            local layerSize = glowSize * (1.2 - layer * 0.3)
            local layerIntensity = glowIntensity * (layer == 1 and 0.4 or 0.8)
            
            -- Increase glow for tokens in transition (newly returned to pool)
            if token.state == "FREE" and token.inTransition then
                -- Stronger glow that fades over the transition period
                local transitionBoost = 0.6 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
                layerSize = layerSize * (1 + transitionBoost * 0.5)
                layerIntensity = layerIntensity + transitionBoost * 0.5
            end
            
            -- Set glow color based on token type with improved contrast and vibrancy
            if token.type == "fire" then
                love.graphics.setColor(1, 0.3, 0.1, layerIntensity)
            elseif token.type == "force" then
                love.graphics.setColor(1, 0.9, 0.3, layerIntensity)
            elseif token.type == "moon" then
                love.graphics.setColor(0.4, 0.4, 1, layerIntensity)
            elseif token.type == "nature" then
                love.graphics.setColor(0.2, 0.9, 0.1, layerIntensity)
            elseif token.type == "star" then
                love.graphics.setColor(1, 0.8, 0.2, layerIntensity)
            end
            
            -- Draw glow with pulsation
            local pulseAmount = 0.7 + 0.3 * math.sin(token.pulsePhase * 0.5)
            
            -- Enhanced pulsation for transitioning tokens
            if token.state == "FREE" and token.inTransition then
                pulseAmount = pulseAmount + 0.3 * math.sin(token.transitionTime * 10)
            end
            
            love.graphics.circle("fill", token.x, token.y, layerSize * pulseAmount * token.scale)
        end
        
        -- Draw a small outer ring for better definition
        if token.state == "FREE" then
            local ringAlpha = 0.4 + 0.2 * math.sin(token.pulsePhase * 0.8)
            
            -- Set ring color based on token type
            if token.type == "fire" then
                love.graphics.setColor(1, 0.5, 0.2, ringAlpha)
            elseif token.type == "force" then
                love.graphics.setColor(1, 1, 0.4, ringAlpha)
            elseif token.type == "moon" then
                love.graphics.setColor(0.6, 0.6, 1, ringAlpha)
            elseif token.type == "nature" then
                love.graphics.setColor(0.3, 1, 0.2, ringAlpha)
            elseif token.type == "star" then
                love.graphics.setColor(1, 0.9, 0.3, ringAlpha)
            end
            
            love.graphics.circle("line", token.x, token.y, (glowSize + 3) * token.scale)
        end
        
        -- Draw token image based on state
        if token.state == "FREE" then
            -- Free tokens are fully visible
            -- If token is in transition (just returned to pool), add a subtle glow effect
            if token.inTransition then
                local transitionGlow = 0.2 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
                love.graphics.setColor(1, 1, 1 + transitionGlow * 0.5, 1)  -- Slightly blue-white glow during transition
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
        elseif token.state == "CHANNELED" then
            -- Channeled tokens are fully visible
            love.graphics.setColor(1, 1, 1, 1)
        elseif token.state == "SHIELDING" then
            -- Shielding tokens have a slight colored tint based on their type
            if token.type == "force" then
                love.graphics.setColor(1, 1, 0.7, 1)  -- Yellow tint for force (barrier)
            elseif token.type == "moon" or token.type == "star" then
                love.graphics.setColor(0.8, 0.8, 1, 1)  -- Blue tint for moon/star (ward)
            elseif token.type == "nature" then
                love.graphics.setColor(0.8, 1, 0.8, 1)  -- Green tint for nature (field)
            else
                love.graphics.setColor(1, 1, 1, 1)  -- Default
            end
        elseif token.state == "LOCKED" then
            -- Locked tokens have a red tint
            love.graphics.setColor(1, 0.5, 0.5, 0.7)
        elseif token.state == "DESTROYED" then
            -- Dissolving tokens fade out
            if token.dissolving then
                -- Calculate progress of the dissolve animation
                local progress = token.dissolveTime / token.dissolveMaxTime
                
                -- Fade out by decreasing alpha
                local alpha = (1 - progress) * 0.8
                
                -- Get token color based on its type for the fade effect
                if token.type == "fire" then
                    love.graphics.setColor(1, 0.3, 0.1, alpha)
                elseif token.type == "force" then
                    love.graphics.setColor(1, 0.9, 0.3, alpha)
                elseif token.type == "moon" then
                    love.graphics.setColor(0.8, 0.6, 1.0, alpha)  -- Purple for lunar disjunction
                elseif token.type == "nature" then
                    love.graphics.setColor(0.2, 0.9, 0.1, alpha)
                elseif token.type == "star" then
                    love.graphics.setColor(1, 0.8, 0.2, alpha)
                else
                    love.graphics.setColor(1, 1, 1, alpha)
                end
            else
                -- Skip drawing if not dissolving
                goto continue
            end
        end
        
        -- Draw the token with dynamic scaling
        if token.state == "DESTROYED" and token.dissolving then
            -- For dissolving tokens, add special effects
            local progress = token.dissolveTime / token.dissolveMaxTime
            
            -- Expand and fade out
            local scaleFactor = token.dissolveScale * (1 + progress * 0.5)
            local rotationSpeed = token.rotSpeed or 1.0
            
            -- Speed up rotation as it dissolves
            token.rotAngle = token.rotAngle + rotationSpeed * 5 * progress
            
            -- Draw at original position with expanding effect
            love.graphics.draw(
                token.image, 
                token.initialX, 
                token.initialY, 
                token.rotAngle,
                scaleFactor * (1 - progress * 0.7), scaleFactor * (1 - progress * 0.7),
                token.image:getWidth()/2, token.image:getHeight()/2
            )
        else
            -- Normal tokens
            love.graphics.draw(
                token.image, 
                token.x, 
                token.y, 
                token.rotAngle,  -- Use the rotation angle
                token.scale, token.scale,  -- Use token-specific scale
                token.image:getWidth()/2, token.image:getHeight()/2  -- Origin at center
            )
        end
        
        ::continue::
        
        -- Draw shield effect for shielding tokens
        if token.state == "SHIELDING" then
            -- Get token color based on its mana type
            local tokenColor = {1, 1, 1, 0.3}  -- Default white
            
            -- Match color to the token type
            if token.type == "fire" then
                tokenColor = {1.0, 0.3, 0.1, 0.3}  -- Red-orange for fire
            elseif token.type == "force" then
                tokenColor = {1.0, 1.0, 0.3, 0.3}  -- Yellow for force
            elseif token.type == "moon" then
                tokenColor = {0.5, 0.5, 1.0, 0.3}  -- Blue for moon
            elseif token.type == "star" then
                tokenColor = {1.0, 0.8, 0.2, 0.3}  -- Gold for star
            elseif token.type == "nature" then
                tokenColor = {0.3, 0.9, 0.1, 0.3}  -- Green for nature
            end
            
            -- Draw a subtle shield aura with slight pulsation
            local pulseScale = 0.9 + math.sin(love.timer.getTime() * 2) * 0.1
            love.graphics.setColor(tokenColor)
            love.graphics.circle("fill", token.x, token.y, 15 * pulseScale * token.scale)
            
            -- Draw shield border
            love.graphics.setColor(tokenColor[1], tokenColor[2], tokenColor[3], 0.5)
            love.graphics.circle("line", token.x, token.y, 15 * pulseScale * token.scale)
            
            -- Add a small defensive shield symbol inside the circle
            -- Determine symbol shape by defense type if available
            if token.wizardOwner and token.spellSlot then
                local slot = token.wizardOwner.spellSlots[token.spellSlot]
                if slot and slot.defenseType then
                    love.graphics.setColor(1, 1, 1, 0.7)
                    if slot.defenseType == "barrier" then
                        -- Draw a small hexagon (shield shape) for barriers
                        local shieldSize = 6 * token.scale
                        local points = {}
                        for i = 1, 6 do
                            local angle = (i - 1) * math.pi / 3
                            table.insert(points, token.x + math.cos(angle) * shieldSize)
                            table.insert(points, token.y + math.sin(angle) * shieldSize)
                        end
                        love.graphics.polygon("line", points)
                    elseif slot.defenseType == "ward" then
                        -- Draw a small circle (ward shape)
                        love.graphics.circle("line", token.x, token.y, 6 * token.scale)
                    elseif slot.defenseType == "field" then
                        -- Draw a small diamond (field shape)
                        local fieldSize = 7 * token.scale
                        love.graphics.polygon("line", 
                            token.x, token.y - fieldSize,
                            token.x + fieldSize, token.y,
                            token.x, token.y + fieldSize,
                            token.x - fieldSize, token.y
                        )
                    end
                end
            end
        end
        
        -- Draw lock overlay for locked tokens
        if token.state == "LOCKED" then
            -- Draw the lock overlay
            local pulseScale = 0.9 + math.sin(token.lockPulse) * 0.2  -- Pulsing effect
            local overlayScale = 1.2 * pulseScale * token.scale  -- Scale for the lock overlay
            
            -- Pulsing red glow behind the lock
            love.graphics.setColor(1, 0, 0, 0.3 + 0.2 * math.sin(token.lockPulse))
            love.graphics.circle("fill", token.x, token.y, 12 * pulseScale * token.scale)
            
            -- Lock icon
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                self.lockOverlay,
                token.x,
                token.y,
                0,  -- No rotation for lock
                overlayScale, overlayScale,
                self.lockOverlay:getWidth()/2, self.lockOverlay:getHeight()/2
            )
            
            -- Display remaining lock time if more than 1 second
            if token.lockDuration > 1 then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(
                    string.format("%.0f", token.lockDuration),
                    token.x - 5,
                    token.y - 25
                )
            end
        end
    end
    
    -- No border - the pool is now completely invisible
end

-- Helper function to draw an ellipse
function ManaPool:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 64
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

function ManaPool:findFreeToken(tokenType)
    -- Find a free token of the specified type without changing its state
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            return token, i  -- Return token and its index without changing state
        end
    end
    return nil  -- No token available
end

function ManaPool:getToken(tokenType)
    -- Find a free token of the specified type that's not in transition
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" and
           not token.returning and not token.inTransition then
            -- Mark as being used
            token.state = "CHANNELED"  
            print(string.format("[MANAPOOL] Token %d (%s) reserved for channeling", i, token.type))
            return token, i  -- Return token and its index
        end
    end
    
    -- Second pass - try with less strict requirements if nothing was found
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            if token.returning then
                print("[MANAPOOL] WARNING: Using token in return animation - visual glitches may occur")
            elseif token.inTransition then
                print("[MANAPOOL] WARNING: Using token in transition state - visual glitches may occur")
            end
            token.state = "CHANNELED"
            print(string.format("[MANAPOOL] Token %d (%s) reserved for channeling (fallback)", i, token.type))
            -- Cancel any return animation
            token.returning = false
            token.inTransition = false
            return token, i
        end
    end
    
    return nil  -- No token available
end

function ManaPool:returnToken(tokenIndex)
    -- Return a token to the pool
    if self.tokens[tokenIndex] then
        local token = self.tokens[tokenIndex]
        
        -- Validate the token state and ownership before return
        if token.returning then
            print("[MANAPOOL] WARNING: Token " .. tokenIndex .. " is already being returned - ignoring duplicate return")
            return
        end
        
        -- Clear any wizard ownership immediately to prevent double-tracking
        token.wizardOwner = nil
        token.spellSlot = nil
        
        -- Ensure token is in a valid state - convert any state to valid transition state
        local originalState = token.state
        if token.state == "SHIELDING" or token.state == "CHANNELED" then
            print("[MANAPOOL] Token " .. tokenIndex .. " transitioning from " .. 
                 (token.state or "nil") .. " to return animation")
            
            -- We don't set state = FREE here yet - we let the animation complete first
            -- This prevents tokens from being reused in the middle of an animation
        elseif token.state ~= "FREE" then
            print("[MANAPOOL] WARNING: Returning token " .. tokenIndex .. " from unexpected state: " .. 
                 (token.state or "nil"))
        end
        
        -- Store current position as start position for return animation
        token.startX = token.x
        token.startY = token.y
        
        -- Pick a random valence for the token to return to
        local valenceIndex = math.random(1, #self.valences)
        
        -- Initialize needed valence transition fields
        local valence = self.valences[valenceIndex]
        token.valenceIndex = valenceIndex
        token.sourceValenceIndex = valenceIndex  -- Will be properly set in finalizeTokenReturn
        token.targetValenceIndex = valenceIndex
        token.sourceRadiusX = valence.radiusX
        token.sourceRadiusY = valence.radiusY
        token.targetRadiusX = valence.radiusX
        token.targetRadiusY = valence.radiusY
        token.currentRadiusX = valence.radiusX
        token.currentRadiusY = valence.radiusY
        
        -- Set up return animation parameters
        token.targetX = self.x  -- Center of mana pool
        token.targetY = self.y
        token.animTime = 0
        token.animDuration = 0.5 -- Half second return animation
        token.returning = true   -- Flag that this token is returning to the pool
        token.originalState = originalState  -- Remember what state it was in before return
        
        -- Set direction and speed based on the valence for when it becomes FREE
        local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
        token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
        token.originalSpeed = token.orbitSpeed
        
        -- Reset timers with some randomness
        token.valenceJumpTimer = 2 + math.random() * 4
        
        -- Initialize transition state for smooth blending
        token.inValenceTransition = false
        token.valenceTransitionTime = 0
        token.valenceTransitionDuration = 0.8
        
        print("[MANAPOOL] Token " .. tokenIndex .. " (" .. token.type .. ") returning animation started")
    else
        print("[MANAPOOL] WARNING: Attempted to return invalid token index: " .. tokenIndex)
    end
end

-- Called by update method when a token finishes its return animation
function ManaPool:finalizeTokenReturn(token)
    -- Clear all references to the spell it was used in
    token.wizardOwner = nil
    token.spellSlot = nil
    token.tokenIndex = nil
    
    -- Record the original state for debugging
    local originalState = token.state
    
    -- ALWAYS set to FREE state when a token returns to the pool
    token.state = "FREE"
    
    -- Log state change with details
    if originalState ~= "FREE" then
        print(string.format("[MANAPOOL] Token state changed: %s -> FREE (was %s before return animation)", 
              originalState or "nil", token.originalState or "unknown"))
    end
    token.originalState = nil -- Clean up
    
    -- Use the final position from the animation as the starting point
    local currentX = token.x
    local currentY = token.y
    
    -- Calculate angle from center
    local dx = currentX - self.x
    local dy = currentY - self.y
    local angle = math.atan2(dy, dx)
    
    -- Assign a random valence for the returned token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    token.valenceIndex = valenceIndex
    
    -- Calculate position based on current angle but using valence's elliptical dimensions
    token.orbitAngle = angle
    
    -- Calculate initial x,y based on selected valence
    local newX = self.x + math.cos(angle) * valence.radiusX
    local newY = self.y + math.sin(angle) * valence.radiusY
    
    -- Apply minimal variation to maintain clean orbits
    local variationX = math.random(-2, 2)
    local variationY = math.random(-1, 1)
    token.x = newX + variationX
    token.y = newY + variationY
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Set orbital speed based on the valence
    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    token.originalSpeed = token.orbitSpeed
    
    -- Add transition for smooth blending
    token.transitionTime = 0
    token.transitionDuration = 1.0  -- 1 second to blend into normal motion
    token.inTransition = true  -- Mark token as transitioning to normal motion
    
    -- Add valence jump timer
    token.valenceJumpTimer = 2 + math.random() * 8
    
    -- Initialize valence transition properties
    token.inValenceTransition = false
    token.valenceTransitionTime = 0
    token.valenceTransitionDuration = 0.8
    token.sourceValenceIndex = valenceIndex
    token.targetValenceIndex = valenceIndex
    token.sourceRadiusX = valence.radiusX
    token.sourceRadiusY = valence.radiusY
    token.targetRadiusX = valence.radiusX
    token.targetRadiusY = valence.radiusY
    token.currentRadiusX = valence.radiusX
    token.currentRadiusY = valence.radiusY
    
    -- Size and z-order variation
    token.scale = 0.85 + math.random() * 0.3
    token.zOrder = math.random()
    
    -- Clear animation flags and any spell-related ownership
    token.returning = false
    
    print("[MANAPOOL] Token (" .. token.type .. ") has fully returned to the pool and is FREE")
end

return ManaPool```

## ./spellCompiler.lua
```lua
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

return SpellCompiler```

## ./spells.lua
```lua
-- Spells.lua
-- Contains data for all spells in the game

-- Import the keyword system
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")

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
--   - Available keywords: damage, burn, stagger, elevate, ground, rangeShift, forcePull, 
--     tokenShift, conjure, dissipate, lock, delay, accelerate, dispel, disjoint, freeze,
--     block, reflect, echo, zoneAnchor, zoneMulti
-- vfx: Visual effect identifier (string, optional)
-- sfx: Sound effect identifier (string, optional)
-- blockableBy: Array of shield types that can block this spell (array, optional)
--
-- Shield Types and Blocking Rules:
-- * barrier: Physical shield that blocks projectiles and zones
-- * ward:    Magical shield that blocks projectiles and remotes
-- * field:   Energy field that blocks remotes and zones

-- Function to validate spell schema - Basic schema validation
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
                if not Keywords[keyword] then
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
                if target and target.elevation then
                    return target.elevation == "GROUNDED" and 20 or 0
                end
                return 0 -- Default damage if target is nil
            end,
            type = "fire"
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
            type = "fire"
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
            -- All shields are mana-linked now (consume tokens when blocking)
            -- Token count is the source of truth for shield strength
        },
        elevate = {
            duration = 4.0
        }
    },
    vfx = "mist_veil",
    sfx = "mist_shimmer",
    blockableBy = {},  -- Utility spell, can't be blocked
    
    -- Mark this as a shield (important for shield mechanics)
    -- isShield = true
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
                -- Make sure slot is a number
                local slotNum = tonumber(slot) or 0
                -- Validate the slot is in a valid range
                if slotNum > 0 and slotNum <= 3 then
                    return slotNum
                else
                    return 0  -- 0 means find the first active slot
                end
            end,
            target = "SLOT_ENEMY"  -- Explicitly target enemy's spell slot
        }
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
            type = "moon"
        },
        ground = {
            conditional = function(caster, target)
                return target and target.elevation == "AERIAL"
            end,
            target = "ENEMY",
            vfx = "gravity_pin_ground"
        },
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
            type = "moon"
        }
    },
    vfx = "moon_beam",
    sfx = "beam_charge",
    blockableBy = {"barrier", "ward"}
}

-- Shield spells
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
            blocks = {"projectile", "zone"}
            -- All shields are mana-linked now (consume tokens when blocking)
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
    cost = {"moon", "moon"},
    keywords = {
        block = {
            type = "ward",
            blocks = {"projectile", "remote"}
            -- All shields are mana-linked now (consume tokens when blocking)
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
            blocks = {"remote", "zone"}
            -- All shields are mana-linked now (consume tokens when blocking)
        }
    },
    vfx = "nature_field",
    sfx = "nature_grow",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Advanced reflective shield
Spells.mirrorshield = {
    id = "mirrorshield",
    name = "Mirror Shield",
    description = "A reflective barrier that returns damage to attackers",
    attackType = "utility",
    castTime = 5.0,
    cost = {"moon", "moon", "star"},
    keywords = {
        block = {
            type = "barrier",  -- Barrier type blocks projectiles and zones
            blocks = {"projectile", "zone"},
            reflect = true      -- Reflects damage back to attacker
            -- All shields are mana-linked now (consume tokens when blocking)
            -- Token count is the source of truth for shield strength
        }
    },
    vfx = "mirror_shield",
    sfx = "crystal_ring",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Shield-breaking spell
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
        }
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

-- Zone spell with range anchoring
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
        
        -- Return special response for handling the miss
        return {
            missBackfire = true,
            backfireDamage = 4,
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

-- Force blast spell that launches opponents into the air
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

-- Prepare the return table with all spells and utility functions
local SpellsModule = {
    spells = Spells,
    validateSpell = validateSpell,
    
    -- Public method to compile all spells
    compileAll = function()
        local compiled = {}
        for id, spell in pairs(Spells) do
            validateSpell(spell, id)
            -- References to SpellCompiler and Keywords need to be passed from game object
            -- This function will be called with the correct context from main.lua
            print("Waiting for SpellCompiler to compile: " .. spell.name)
        end
        return compiled
    end,
    
    -- Public method to get a compiled spell by ID
    getCompiledSpell = function(spellId, spellCompiler, keywords)
        if not Spells[spellId] then
            print("ERROR: Spell not found: " .. spellId)
            return nil
        end
        
        -- Make sure we have the required objects
        if not spellCompiler or not keywords then
            print("ERROR: Missing SpellCompiler or Keywords for compiling spell: " .. spellId)
            return nil
        end
        
        return spellCompiler.compileSpell(Spells[spellId], keywords)
    end
}

-- Validate all spells at module load time to catch errors early
for spellId, spell in pairs(Spells) do
    validateSpell(spell, spellId)
end

return SpellsModule```

## ./tools/generate_docs.lua
```lua
#!/usr/bin/env lua
-- Script to generate keyword documentation

-- Add manastorm root directory to lua path
package.path = package.path .. ";../?.lua"

-- Import the documentation generator
local DocGenerator = require("docs.keywords")

-- Generate the documentation
DocGenerator.writeDocumentation("../docs/KEYWORDS.md")

print("Documentation generation complete!")```

## ./tools/test_keywords.lua
```lua
#!/usr/bin/env lua
-- Script to test and debug keyword resolution

-- Add manastorm root directory to lua path
package.path = package.path .. ";../?.lua"

-- Import the spells module
local Spells = require("spells")

-- Mock wizard class for testing
local MockWizard = {}
MockWizard.__index = MockWizard

function MockWizard.new(name, position)
    local self = setmetatable({}, MockWizard)
    self.name = name
    self.x = position or 0
    self.y = 370
    self.elevation = "GROUNDED"
    self.spellSlots = {{}, {}, {}}
    self.manaPool = {
        tokens = {},
        addToken = function() print("Added token") end
    }
    self.gameState = {
        rangeState = "FAR",
        wizards = {}
    }
    return self
end

-- Create mock wizards for testing
local caster = MockWizard.new("TestWizard", 200)
local opponent = MockWizard.new("Opponent", 600)

-- Set up test state
caster.gameState.wizards = {caster, opponent}

-- Test a keyword in isolation
local function testKeyword(keyword, params)
    print("\n====== Testing keyword: " .. keyword .. " ======")
    
    -- Create starting results
    local results = {damage = 0, spellType = "test"}
    
    -- Process the keyword
    local newResults = Spells.keywordSystem.resolveKeyword(
        "test_spell", 
        keyword, 
        params, 
        caster, 
        opponent, 
        1, -- spell slot
        results
    )
    
    -- Show detailed results
    print("\nKeyword results:")
    for k, v in pairs(newResults) do
        if k ~= "damage" or v ~= 0 then
            print("  " .. k .. ": " .. tostring(v))
        end
    end
    
    return newResults
end

-- Test a full spell
local function testSpell(spell)
    print("\n====== Testing spell: " .. spell.name .. " ======")
    
    -- Process the spell using the new targeting-aware system
    local results = Spells.keywordSystem.castSpell(
        spell, 
        caster, 
        {
            opponent = opponent,
            spellSlot = 1,
            debug = true
        }
    )
    
    -- Show detailed results
    print("\nSpell results:")
    for k, v in pairs(results) do
        if k ~= "damage" or v ~= 0 then
            if k ~= "targetingInfo" then  -- Handle targeting info separately
                print("  " .. k .. ": " .. tostring(v))
            end
        end
    end
    
    -- Display targeting info
    if results.targetingInfo then
        print("\nTargeting information:")
        for keyword, info in pairs(results.targetingInfo) do
            print(string.format("  %s -> %s (%s)", 
                keyword, info.targetType, info.target))
        end
    end
    
    return results
end

-- Run tests based on command-line arguments
local function runTests()
    local arg = {...}
    
    if #arg == 0 then
        -- Default tests if no arguments provided
        print("Running default tests...")
        
        -- Test individual keywords
        testKeyword("damage", {amount = 10, type = "fire"})
        testKeyword("elevate", {duration = 3.0})
        testKeyword("rangeShift", {position = "NEAR"})
        
        -- Test a dynamic function parameter
        testKeyword("damage", {
            amount = function(caster, target)
                return caster.gameState.rangeState == "FAR" and 15 or 10
            end,
            type = "fire"
        })
        
        -- Test a complex spell
        local testSpell = {
            id = "testspell",
            name = "Test Compound Spell",
            description = "A spell combining multiple effects for testing",
            attackType = "projectile",
            castTime = 5.0,
            cost = {"fire", "force"},
            keywords = {
                damage = {
                    amount = function(caster, target)
                        return target.elevation == "AERIAL" and 15 or 10
                    end,
                    type = "fire"
                },
                elevate = {
                    duration = 3.0
                },
                rangeShift = {
                    position = "NEAR"
                }
            }
        }
        testSpell(testSpell)
        
    elseif arg[1] == "list" then
        -- List all available keywords
        print("Available keywords:")
        local keywordInfo = Spells.keywordSystem.getKeywordHelp()
        for keyword, info in pairs(keywordInfo) do
            print("- " .. keyword .. ": " .. info.description)
        end
        
    elseif arg[1] == "keyword" and arg[2] then
        -- Test a specific keyword
        local keyword = arg[2]
        
        -- Check if this keyword exists
        if not Spells.keywordSystem.handlers[keyword] then
            print("Error: Unknown keyword '" .. keyword .. "'")
            return
        end
        
        -- Create some basic params for testing
        local params = {}
        if keyword == "damage" then
            params = {amount = 10, type = "fire"}
        elseif keyword == "elevate" or keyword == "freeze" then
            params = {duration = 3.0}
        elseif keyword == "rangeShift" then
            params = {position = "NEAR"}
        elseif keyword == "block" then
            params = {type = "barrier", blocks = {"projectile"}}
        elseif keyword == "conjure" then
            params = {token = "fire", amount = 1}
        elseif keyword == "dissipate" then
            params = {token = "fire", amount = 1}
        elseif keyword == "tokenShift" then
            params = {type = "random", amount = 2}
        end
        
        testKeyword(keyword, params)
        
    elseif arg[1] == "spell" and arg[2] then
        -- Test a specific spell
        local spellId = arg[2]
        
        -- Check if this spell exists
        if not Spells.spells[spellId] then
            print("Error: Unknown spell '" .. spellId .. "'")
            return
        end
        
        testSpell(Spells.spells[spellId])
        
    else
        -- Show usage
        print("Usage:")
        print("  lua test_keywords.lua                  Run default tests")
        print("  lua test_keywords.lua list             List all available keywords")
        print("  lua test_keywords.lua keyword <name>   Test a specific keyword")
        print("  lua test_keywords.lua spell <id>       Test a specific spell")
    end
end

-- Run the tests
runTests(...)```

## ./tools/test_spellCompiler.lua
```lua
-- test_spellCompiler.lua
-- Tests for the Spell Compiler implementation

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local Spells = require("spells").spells

-- Define a fake game environment for testing
local gameEnv = {
    wizards = {
        { name = "TestWizard1", health = 100, elevation = "GROUNDED" },
        { name = "TestWizard2", health = 100, elevation = "AERIAL" }
    },
    rangeState = "FAR"
}

-- Add game state to wizards
gameEnv.wizards[1].gameState = gameEnv
gameEnv.wizards[2].gameState = gameEnv

-- Print test header
print("\n===== SPELL COMPILER TESTS =====\n")

-- Test 1: Basic spell compilation
print("TEST 1: Basic spell compilation")
local firebolt = Spells.firebolt
local compiledFirebolt = SpellCompiler.compileSpell(firebolt, Keywords)

-- Verify structure
print("Compiled spell structure check: " .. 
      (compiledFirebolt.behavior.damage ~= nil and "PASSED" or "FAILED"))
print("Original properties preserved: " .. 
      (compiledFirebolt.id == firebolt.id and 
       compiledFirebolt.name == firebolt.name and 
       compiledFirebolt.attackType == firebolt.attackType and "PASSED" or "FAILED"))

-- Test 2: Boolean keyword handling
print("\nTEST 2: Boolean keyword handling")
local groundKeywordSpell = {
    id = "testGround",
    name = "Test Ground",
    description = "Test for boolean keywords",
    attackType = "utility",
    castTime = 2.0,
    cost = {"any"},
    keywords = {
        ground = true
    }
}

local compiledGroundSpell = SpellCompiler.compileSpell(groundKeywordSpell, Keywords)
print("Boolean keyword handling: " .. 
      (compiledGroundSpell.behavior.ground.enabled == true and "PASSED" or "FAILED"))

-- Test 3: Complex spell with multiple keywords
print("\nTEST 3: Complex spell with multiple keywords")
local compiledMeteor = SpellCompiler.compileSpell(Spells.meteor, Keywords)
print("Multiple keywords compiled: " .. 
      (compiledMeteor.behavior.damage ~= nil and 
       compiledMeteor.behavior.rangeShift ~= nil and "PASSED" or "FAILED"))

-- Test 4: Execution of compiled behaviors
print("\nTEST 4: Execution of compiled behaviors")
local results = {}
results = compiledFirebolt.executeAll(gameEnv.wizards[1], gameEnv.wizards[2], results)

print("Behavior execution results:")
print("Damage applied: " .. tostring(results.damage))
print("Damage type: " .. tostring(results.damageType))

-- Test 5: Complex behavior parameter handling
print("\nTEST 5: Complex behavior parameter handling")
local arcaneReversal = Spells.arcaneReversal
local compiledArcaneReversal = SpellCompiler.compileSpell(arcaneReversal, Keywords)

print("Complex parameters preserved for multiple keywords: " .. 
      (compiledArcaneReversal.behavior.damage ~= nil and
       compiledArcaneReversal.behavior.rangeShift ~= nil and
       compiledArcaneReversal.behavior.lock ~= nil and
       compiledArcaneReversal.behavior.conjure ~= nil and
       compiledArcaneReversal.behavior.accelerate ~= nil and "PASSED" or "FAILED"))

-- Debug complete structure of a complex spell
print("\nDetailed structure of compiled arcaneReversal spell:")
SpellCompiler.debugCompiled(compiledArcaneReversal)

print("\n===== SPELL COMPILER TESTS COMPLETED =====\n")```

## ./tools/test_spellCompiler_standalone.lua
```lua
-- test_spellCompiler_standalone.lua
-- Standalone test for the Spell Compiler implementation

-- Mocking love.graphics.newImage to allow running outside LÖVE
_G.love = {
    graphics = {
        newImage = function(path) return { path = path } end
    }
}

package.path = package.path .. ";/Users/russell/Manastorm/?.lua"
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")

-- Define a sample spell for testing
local sampleSpell = {
    id = "fireball",
    name = "Fireball",
    description = "A ball of fire that deals damage",
    attackType = "projectile",
    castTime = 5.0,
    cost = {"fire", "fire"},
    keywords = {
        damage = {
            amount = 10,
            type = "fire"
        },
        burn = {
            duration = 3.0,
            tickDamage = 2
        }
    },
    vfx = "fireball_vfx",
    blockableBy = {"barrier", "ward"}
}

-- Print test header
print("\n===== SPELL COMPILER STANDALONE TEST =====\n")

-- Test basic spell compilation
print("Testing basic spell compilation...")
local compiledSpell = SpellCompiler.compileSpell(sampleSpell, Keywords)

-- Check that compilation worked
print("Compiled spell has behavior: " .. (compiledSpell.behavior ~= nil and "YES" or "NO"))
print("Compiled spell has damage behavior: " .. (compiledSpell.behavior.damage ~= nil and "YES" or "NO"))
print("Compiled spell has burn behavior: " .. (compiledSpell.behavior.burn ~= nil and "YES" or "NO"))

-- Test a boolean keyword
local spellWithBoolKeyword = {
    id = "groundSpell",
    name = "Ground Spell",
    description = "Forces enemy to ground",
    attackType = "utility",
    castTime = 3.0,
    cost = {"any"},
    keywords = {
        ground = true
    }
}

print("\nTesting boolean keyword handling...")
local compiledBoolSpell = SpellCompiler.compileSpell(spellWithBoolKeyword, Keywords)
print("Boolean keyword compiled: " .. (compiledBoolSpell.behavior.ground ~= nil and "YES" or "NO"))
print("Boolean keyword enabled: " .. (compiledBoolSpell.behavior.ground.enabled == true and "YES" or "NO"))

-- Define mock game objects for execution testing
local caster = {
    name = "TestWizard",
    elevation = "GROUNDED",
    manaPool = { 
        tokens = {},
        addToken = function() end
    },
    gameState = { rangeState = "FAR" }
}

local target = {
    name = "EnemyWizard",
    elevation = "AERIAL",
    health = 100
}

-- Test executing the compiled behaviors
print("\nTesting behavior execution...")
local results = compiledSpell.executeAll(caster, target, {})
print("Damage result: " .. tostring(results.damage))
print("Damage type: " .. tostring(results.damageType))
print("Burn applied: " .. tostring(results.burnApplied))
print("Burn duration: " .. tostring(results.burnDuration))
print("Burn tick damage: " .. tostring(results.burnTickDamage))

-- Debug the full compiled spell structure
print("\nDetailed structure of compiled spell:")
SpellCompiler.debugCompiled(compiledSpell)

print("\n===== SPELL COMPILER STANDALONE TEST COMPLETED =====\n")```

## ./ui.lua
```lua
-- UI helper module

local UI = {}

-- Spellbook visibility state
UI.spellbookVisible = {
    player1 = false,
    player2 = false
}

-- Delayed health damage display state
UI.healthDisplay = {
    player1 = {
        currentHealth = 100,        -- Current display health (smoothly animated)
        targetHealth = 100,         -- Actual health to animate towards
        pendingDamage = 0,          -- Damage that's pending animation (yellow bar)
        lastDamageTime = 0,         -- Time when last damage was taken
        pendingDrainDelay = 0.5,    -- Delay before yellow bar starts draining
        drainRate = 30              -- How fast the yellow bar drains (health points per second)
    },
    player2 = {
        currentHealth = 100,
        targetHealth = 100,
        pendingDamage = 0,
        lastDamageTime = 0,
        pendingDrainDelay = 0.5,
        drainRate = 30
    }
}

function UI.drawHelpText(font)
    -- Set font and color
    love.graphics.setFont(font)
    
    -- Draw a semi-transparent background for the debug panel
    love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
    local panelWidth = 600
    local y = love.graphics.getHeight() - 130
    love.graphics.rectangle("fill", 5, y + 30, panelWidth, 95, 5, 5)
    
    -- Draw a border
    love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
    love.graphics.rectangle("line", 5, y + 30, panelWidth, 95, 5, 5)
    
    -- Draw header
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.print("DEBUG MODE", 15, y + 35)
    
    -- Show debug controls with brighter text
    love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
    love.graphics.print("Debug Controls: T (Add tokens), R (Toggle range), A/S (Toggle elevations), ESC (Quit)", 15, y + 55)
    love.graphics.print("VFX Test Keys: 1 (Firebolt), 2 (Meteor), 3 (Mist Veil), 4 (Emberlift), 5 (Full Moon Beam)", 15, y + 75)
    love.graphics.print("Conjure Test Keys: 6 (Fire), 7 (Moonlight), 8 (Volatile)", 15, y + 95)
    
    -- No longer calling UI.drawSpellbookButtons() here as it's now handled in the main loop
end

-- Toggle spellbook visibility for a player
function UI.toggleSpellbook(player)
    if player == 1 then
        UI.spellbookVisible.player1 = not UI.spellbookVisible.player1
        UI.spellbookVisible.player2 = false -- Close other spellbook
    elseif player == 2 then
        UI.spellbookVisible.player2 = not UI.spellbookVisible.player2
        UI.spellbookVisible.player1 = false -- Close other spellbook
    end
end

-- Draw skeuomorphic spellbook components for both players
function UI.drawSpellbookButtons()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw Player 1's spellbook (Ashgar - pinned to left side)
    UI.drawPlayerSpellbook(1, 0, screenHeight - 70)
    
    -- Draw Player 2's spellbook (Selene - pinned to right side)
    UI.drawPlayerSpellbook(2, screenWidth - 250, screenHeight - 70)
end

-- Draw an individual player's spellbook component
function UI.drawPlayerSpellbook(playerNum, x, y)
    local screenWidth = love.graphics.getWidth()
    local width = 250  -- Balanced width
    local height = 50
    local player = (playerNum == 1) and "Ashgar" or "Selene"
    local keyLabel = (playerNum == 1) and "B" or "M"
    local keyPrefix = (playerNum == 1) and {"Q", "W", "E"} or {"I", "O", "P"}
    local wizard = _G.game.wizards[playerNum]
    local color = {wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255}
    
    -- Draw book background with slight gradient
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.25, 0.25, 0.35, 0.9)
    love.graphics.rectangle("fill", x, y, width, height/2)
    
    -- Draw book binding/spine effect
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("fill", x, y, 6, height)
    
    -- Draw book edge
    love.graphics.setColor(0.8, 0.8, 0.8, 0.3)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw dividers between sections
    love.graphics.setColor(0.4, 0.4, 0.5, 0.4)
    love.graphics.line(x + 120, y + 5, x + 120, y + height - 5)
    
    -- Center everything vertically in pane
    local centerY = y + height/2
    local runeSize = 14
    local groupSpacing = 35  -- Original spacing between keys
    
    -- GROUP 1: SPELL INPUT KEYS
    -- Add a subtle background for the key group
    love.graphics.setColor(0.2, 0.2, 0.3, 0.3)
    love.graphics.rectangle("fill", x + 15, centerY - 20, 95, 40, 5, 5)  -- Maintain original padding for keys
    
    -- Calculate positions for centered spell input keys
    local inputStartX = x + 30  -- Original position for better centering
    local inputY = centerY
    
    for i = 1, 3 do
        -- Draw rune background
        love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
        love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, runeSize)
        
        if wizard.activeKeys[i] then
            -- Active rune with glow effect
            -- Multiple layers for glow
            for j = 3, 1, -1 do
                local alpha = 0.3 * (4-j) / 3
                local size = runeSize + j * 2
                love.graphics.setColor(1, 1, 0.3, alpha)
                love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, size)
            end
            
            -- Bright center
            love.graphics.setColor(1, 1, 0.7, 0.9)
            love.graphics.circle("fill", inputStartX + (i-1)*groupSpacing, inputY, runeSize * 0.7)
            
            -- Properly centered rune symbol
            local keyText = keyPrefix[i]
            local keyTextWidth = love.graphics.getFont():getWidth(keyText)
            local keyTextHeight = love.graphics.getFont():getHeight()
            love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
            love.graphics.print(keyText, 
                inputStartX + (i-1)*groupSpacing - keyTextWidth/2, 
                inputY - keyTextHeight/2)
        else
            -- Inactive rune
            love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
            love.graphics.circle("line", inputStartX + (i-1)*groupSpacing, inputY, runeSize)
            
            -- Properly centered inactive symbol
            local keyText = keyPrefix[i]
            local keyTextWidth = love.graphics.getFont():getWidth(keyText)
            local keyTextHeight = love.graphics.getFont():getHeight()
            love.graphics.setColor(0.6, 0.6, 0.7, 0.6)
            love.graphics.print(keyText, 
                inputStartX + (i-1)*groupSpacing - keyTextWidth/2, 
                inputY - keyTextHeight/2)
        end
    end
    
    -- Removed "Input Keys" label for cleaner UI
    
    -- GROUP 2: CAST BUTTON & FREE BUTTON
    -- Create a shared container/background for both action buttons - more compact
    local actionSectionWidth = 90
    local actionX = x + 125
    
    -- Draw a shared background container for both action buttons
    love.graphics.setColor(0.18, 0.18, 0.25, 0.5)
    love.graphics.rectangle("fill", actionX, centerY - 18, actionSectionWidth, 36, 5, 5)  -- More compact
    
    -- Calculate positions for both buttons with tighter spacing
    local castX = actionX + actionSectionWidth/3 - 5
    local freeX = actionX + actionSectionWidth*2/3 + 5
    local castKey = (playerNum == 1) and "F" or "J"
    local freeKey = (playerNum == 1) and "G" or "H"
    
    -- CAST BUTTON
    -- Subtle highlighting background
    love.graphics.setColor(0.3, 0.2, 0.1, 0.3)
    love.graphics.rectangle("fill", castX - 17, centerY - 16, 34, 32, 5, 5)  -- More compact
    
    -- Draw cast button background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
    love.graphics.circle("fill", castX, inputY, runeSize)
    
    -- Cast button border
    love.graphics.setColor(0.8, 0.4, 0.1, 0.8)  -- Orange-ish for cast button
    love.graphics.circle("line", castX, inputY, runeSize)
    
    -- Cast button symbol
    local castTextWidth = love.graphics.getFont():getWidth(castKey)
    local castTextHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(1, 0.8, 0.3, 0.9)
    love.graphics.print(castKey, 
        castX - castTextWidth/2, 
        inputY - castTextHeight/2)
    
    -- Removed "Cast" label for cleaner UI
    
    -- FREE BUTTON
    -- Subtle highlighting background
    love.graphics.setColor(0.1, 0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", freeX - 17, centerY - 16, 34, 32, 5, 5)  -- More compact
    
    -- Draw free button background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
    love.graphics.circle("fill", freeX, inputY, runeSize)
    
    -- Free button border
    love.graphics.setColor(0.2, 0.6, 0.8, 0.8)  -- Blue-ish for free button
    love.graphics.circle("line", freeX, inputY, runeSize)
    
    -- Free button symbol
    local freeTextWidth = love.graphics.getFont():getWidth(freeKey)
    local freeTextHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(0.5, 0.8, 1.0, 0.9)
    love.graphics.print(freeKey, 
        freeX - freeTextWidth/2, 
        inputY - freeTextHeight/2)
    
    -- Removed "Free" label for cleaner UI
    
    -- GROUP 3: KEYED SPELL POPUP (appears above the spellbook when a spell is keyed)
    if wizard.currentKeyedSpell then
        -- Make the popup exactly match the width of the spellbook
        local popupWidth = width
        local popupHeight = 30
        local popupX = x  -- Align with spellbook
        local popupY = y - popupHeight - 10  -- Position above the spellbook with slightly larger gap
        
        -- Get spell name and calculate its width for centering
        local spellName = wizard.currentKeyedSpell.name
        local spellNameWidth = love.graphics.getFont():getWidth(spellName)
        
        -- Draw popup background with a slight "connected" look
        -- Use the same color as the spellbook for visual cohesion
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        
        -- Main popup body (rounded rectangle)
        love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 5, 5)
        
        -- Connection piece (small triangle pointing down)
        love.graphics.polygon("fill", 
            x + width/2 - 8, popupY + popupHeight,  -- Left point
            x + width/2 + 8, popupY + popupHeight,  -- Right point
            x + width/2, popupY + popupHeight + 8   -- Bottom point
        )
        
        -- Add a subtle border with the wizard's color
        love.graphics.setColor(color[1], color[2], color[3], 0.5)
        love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight, 5, 5)
        
        -- Subtle gradient for the background (matches the spellbook aesthetic)
        love.graphics.setColor(0.25, 0.25, 0.35, 0.7)
        love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight/2, 5, 5)
        
        -- Simple glow effect for the text
        for i = 3, 1, -1 do
            local alpha = 0.1 * (4-i) / 3
            local size = i * 2
            love.graphics.setColor(1, 1, 0.5, alpha)
            love.graphics.rectangle("fill", 
                x + width/2 - spellNameWidth/2 - size, 
                popupY + popupHeight/2 - 7 - size/2, 
                spellNameWidth + size*2, 
                14 + size,
                5, 5
            )
        end
        
        -- Spell name centered in the popup
        love.graphics.setColor(1, 1, 0.5, 0.9)
        love.graphics.print(spellName, 
            x + width/2 - spellNameWidth/2, 
            popupY + popupHeight/2 - 7
        )
    end
    
    -- GROUP 4: SPELLBOOK HELP (bottom-right corner) - more compact design
    local helpX = x + width - 15
    local helpY = y + height - 10
    
    -- Draw key hint - make it slightly bigger
    local helpSize = 8  -- Increased size
    love.graphics.setColor(0.4, 0.4, 0.6, 0.5)
    love.graphics.circle("fill", helpX, helpY, helpSize)
    
    -- Properly centered key symbol - BIGGER
    local smallFont = love.graphics.getFont()
    local keyTextWidth = smallFont:getWidth(keyLabel)
    local keyTextHeight = smallFont:getHeight()
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(keyLabel, 
        helpX - keyTextWidth/3, 
        helpY - keyTextHeight/3,
        0, 0.7, 0.7)  -- Significantly larger
    
    -- LARGER "?" indicator placed HIGHER above the button
    love.graphics.setColor(0.7, 0.7, 0.8, 0.8)  -- Brighter
    local helpLabel = "?"
    local helpLabelWidth = smallFont:getWidth(helpLabel)
    -- Position the ? significantly higher up
    love.graphics.print(helpLabel, 
        helpX - helpLabelWidth/3, 
        helpY - helpSize - smallFont:getHeight() - 2,  -- Position much higher above the button
        0, 0.7, 0.7)  -- Make it larger
    
    -- Highlight when active
    if (playerNum == 1 and UI.spellbookVisible.player1) or 
       (playerNum == 2 and UI.spellbookVisible.player2) then
        love.graphics.setColor(color[1], color[2], color[3], 0.4)
        love.graphics.rectangle("fill", x, y, width, height)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", x - 2, y - 2, width + 4, height + 4)
    end
end

function UI.drawSpellInfo(wizards)
    -- Function to format mana cost for display
    local function formatCost(cost)
        if not cost or #cost == 0 then
            return "Free"
        end
        
        -- Handle both old and new cost formats
        local costText = ""
        local tokenCounts = {}  -- For new array-style format
        
        -- Check if this is the new array-style format (simple array of strings)
        local isNewFormat = type(cost[1]) == "string"
        
        if isNewFormat then
            -- Count each token type
            for _, tokenType in ipairs(cost) do
                tokenCounts[tokenType] = (tokenCounts[tokenType] or 0) + 1
            end
            
            -- Format the counts
            for tokenType, count in pairs(tokenCounts) do
                costText = costText .. count .. " " .. tokenType .. ", "
            end
        else
            -- Old format with type and count properties
            for _, component in ipairs(cost) do
                local typeText = component.type
                if type(typeText) == "table" then
                    typeText = table.concat(typeText, "/")
                end
                costText = costText .. component.count .. " " .. typeText .. ", "
            end
        end
        
        return costText:sub(1, -3)  -- Remove trailing comma and space
    end
    
    -- Draw the fighting game style health bars
    UI.drawHealthBars(wizards)
    
    -- Draw spellbook popups if visible
    if UI.spellbookVisible.player1 then
        UI.drawSpellbookModal(wizards[1], 1, formatCost)
    end
    
    if UI.spellbookVisible.player2 then
        UI.drawSpellbookModal(wizards[2], 2, formatCost)
    end
    
    -- Spell notification is now handled by the wizard's castSpell function
    -- No longer drawing active spells list - relying on visual representation
end

-- Draw dramatic fighting game style health bars
function UI.drawHealthBars(wizards)
    local screenWidth = love.graphics.getWidth()
    local barHeight = 40
    local centerGap = 60 -- Space between bars in the center
    local barWidth = (screenWidth - centerGap) / 2
    local padding = 0 -- No padding from screen edges
    local y = 5
    
    -- Player 1 (Ashgar) health bar (left side, right-to-left depletion)
    local p1 = wizards[1]
    local display1 = UI.healthDisplay.player1
    
    -- Get the animated health percentage (from the delayed damage system)
    local p1HealthPercent = display1.currentHealth / 100
    local p1PendingDamagePercent = display1.pendingDamage / 100
    
    -- Background and border
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", padding, y, barWidth, barHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", padding, y, barWidth, barHeight)
    
    -- Health fill with gradient
    local ashgarGradient = {
        {0.8, 0.2, 0.2},  -- Red base color
        {1.0, 0.3, 0.1}   -- Brighter highlight
    }
    
    -- Calculate the total visible health (current + pending)
    local totalVisibleHealth = p1HealthPercent
    
    -- Draw gradient health bar for current health (excluding pending damage part)
    for i = 0, barWidth * p1HealthPercent, 1 do
        local gradientPos = i / (barWidth * p1HealthPercent)
        local r = ashgarGradient[1][1] + (ashgarGradient[2][1] - ashgarGradient[1][1]) * gradientPos
        local g = ashgarGradient[1][2] + (ashgarGradient[2][2] - ashgarGradient[1][2]) * gradientPos
        local b = ashgarGradient[1][3] + (ashgarGradient[2][3] - ashgarGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(padding + i, y + 2, padding + i, y + barHeight - 2)
    end
    
    -- Add a single halfway marker at 50% health, anchored to the bottom
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    local halfwayX = padding + (barWidth / 2)
    local markerHeight = barHeight / 2  -- The marker extends halfway up the bar
    love.graphics.line(halfwayX, y + barHeight - markerHeight, halfwayX, y + barHeight)
    
    -- Get actual health from the wizard for comparison
    local p1ActualHealthPercent = p1.health / 100
    
    -- Health lost "after damage" effect (fading darker region)
    -- This is displayed UNDER everything else, so draw it first
    local permanentDamageAmount = 1.0 - p1ActualHealthPercent
    if permanentDamageAmount > 0 then
        love.graphics.setColor(0.5, 0.1, 0.1, 0.3)
        love.graphics.rectangle("fill", 
            padding + barWidth * p1ActualHealthPercent, 
            y, 
            barWidth * permanentDamageAmount, 
            barHeight)
    end
    
    -- Pending damage effect (yellow bar segment)
    -- This shows the section of health that will drain away
    if p1PendingDamagePercent > 0 then
        -- Calculate where the pending damage begins and ends
        local pendingStart = p1HealthPercent  -- Where current health ends
        local pendingEnd = math.min(p1HealthPercent + p1PendingDamagePercent, p1ActualHealthPercent)
        local pendingWidth = pendingEnd - pendingStart
        
        -- Only draw if there's actual width to display
        if pendingWidth > 0 then
            -- Draw yellow segment for pending damage (as it's actually depleting)
            love.graphics.setColor(1.0, 0.9, 0.2, 0.8)
            
            -- Draw the pending section as yellow bars to match the health bar style
            for i = 0, barWidth * pendingWidth, 1 do
                local x = padding + barWidth * pendingStart + i
                love.graphics.line(x, y + 2, x, y + barHeight - 2)
            end
            
            -- Add some shading effects to the pending damage zone
            love.graphics.setColor(1.0, 1.0, 0.5, 0.2)
            love.graphics.rectangle("fill", 
                padding + barWidth * pendingStart, 
                y, 
                barWidth * pendingWidth, 
                barHeight/3)
        end
    end
    
    -- Gleaming highlight
    local time = love.timer.getTime()
    local hilight = math.abs(math.sin(time))
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", padding, y, barWidth * p1HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p1.name, padding + 20, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage only in debug mode
    if love.keyboard.isDown("`") then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(math.floor(p1HealthPercent * 100) .. "%", padding + barWidth - 40, y + 7)
    end
    
    
    -- Player 2 (Selene) health bar (right side, left-to-right depletion)
    local p2 = wizards[2]
    local display2 = UI.healthDisplay.player2
    
    -- Get the animated health percentage (from the delayed damage system)
    local p2HealthPercent = display2.currentHealth / 100
    local p2PendingDamagePercent = display2.pendingDamage / 100
    local p2X = screenWidth - barWidth
    
    -- Background and border
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", p2X, y, barWidth, barHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", p2X, y, barWidth, barHeight)
    
    -- Health fill with gradient
    local seleneGradient = {
        {0.1, 0.3, 0.8},  -- Blue base color
        {0.2, 0.5, 1.0}   -- Brighter highlight
    }
    
    -- Calculate the total visible health
    local totalVisibleHealth = p2HealthPercent
    
    -- Draw gradient health bar (left-to-right depletion)
    for i = 0, barWidth * p2HealthPercent, 1 do
        local gradientPos = i / (barWidth * p2HealthPercent)
        local r = seleneGradient[1][1] + (seleneGradient[2][1] - seleneGradient[1][1]) * gradientPos
        local g = seleneGradient[1][2] + (seleneGradient[2][2] - seleneGradient[1][2]) * gradientPos
        local b = seleneGradient[1][3] + (seleneGradient[2][3] - seleneGradient[1][3]) * gradientPos
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(p2X + barWidth - i, y + 2, p2X + barWidth - i, y + barHeight - 2)
    end
    
    -- Add a single halfway marker at 50% health, anchored to the bottom
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    local halfwayX = p2X + (barWidth / 2)
    local markerHeight = barHeight / 2  -- The marker extends halfway up the bar
    love.graphics.line(halfwayX, y + barHeight - markerHeight, halfwayX, y + barHeight)
    
    -- Get actual health from the wizard for comparison
    local p2ActualHealthPercent = p2.health / 100
    
    -- Health lost "after damage" effect (fading darker region)
    -- This is displayed UNDER everything else, so draw it first
    local permanentDamageAmount = 1.0 - p2ActualHealthPercent
    if permanentDamageAmount > 0 then
        love.graphics.setColor(0.1, 0.1, 0.5, 0.3)
        love.graphics.rectangle("fill", p2X, y, barWidth * permanentDamageAmount, barHeight)
    end
    
    -- Pending damage effect (yellow bar segment)
    if p2PendingDamagePercent > 0 then
        -- Calculate where the pending damage begins and ends
        -- For player 2, the bar fills from right to left
        local pendingStart = 1.0 - p2HealthPercent  -- Where current health ends (from left)
        local pendingEnd = math.min(pendingStart + p2PendingDamagePercent, 1.0 - p2ActualHealthPercent)
        local pendingWidth = pendingEnd - pendingStart
        
        -- Only draw if there's actual width to display
        if pendingWidth > 0 then
            -- Draw yellow segment for pending damage (as it's actually depleting)
            love.graphics.setColor(1.0, 0.9, 0.2, 0.8)
            
            -- Draw the pending section as yellow bars to match the health bar style
            for i = 0, barWidth * pendingWidth, 1 do
                local x = p2X + barWidth * pendingStart + i
                love.graphics.line(x, y + 2, x, y + barHeight - 2)
            end
            
            -- Add some shading effects to the pending damage zone
            love.graphics.setColor(1.0, 1.0, 0.5, 0.2)
            love.graphics.rectangle("fill", 
                p2X + barWidth * pendingStart, 
                y, 
                barWidth * pendingWidth, 
                barHeight/3)
        end
    end
    
    -- Gleaming highlight
    love.graphics.setColor(1, 1, 1, 0.2 * hilight)
    love.graphics.rectangle("fill", p2X + barWidth * (1 - p2HealthPercent), y, barWidth * p2HealthPercent, barHeight/3)
    
    -- Name printed directly on the health bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(p2.name, p2X + barWidth - 80, y + barHeight/2 - 8, 0, 1.2, 1.2)
    
    -- Health percentage only in debug mode
    if love.keyboard.isDown("`") then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(math.floor(p2HealthPercent * 100) .. "%", p2X + 10, y + 7)
    end
end

-- [Removed drawActiveSpells function - now using visual representation instead]

-- Draw a full spellbook modal for a player
-- Update the health display animation
function UI.updateHealthDisplays(dt, wizards)
    local currentTime = love.timer.getTime()
    
    for i, wizard in ipairs(wizards) do
        local display = UI.healthDisplay["player" .. i]
        local actualHealth = wizard.health
        
        -- If actual health is different from our target, register new damage
        if actualHealth < display.targetHealth then
            -- Calculate how much new damage was taken
            local newDamage = display.targetHealth - actualHealth
            
            -- Add to pending damage
            display.pendingDamage = display.pendingDamage + newDamage
            
            -- Update target health to match actual health
            display.targetHealth = actualHealth
            
            -- Reset the damage timer to restart the delay
            display.lastDamageTime = currentTime
        end
        
        -- Check if we should start draining the pending damage
        if display.pendingDamage > 0 and (currentTime - display.lastDamageTime) > display.pendingDrainDelay then
            -- Calculate how much to drain based on time passed
            local drainAmount = display.drainRate * dt
            
            -- Don't drain more than what's pending
            drainAmount = math.min(drainAmount, display.pendingDamage)
            
            -- Reduce pending damage and update current health
            display.pendingDamage = display.pendingDamage - drainAmount
            display.currentHealth = display.currentHealth - drainAmount
            
            -- Ensure we don't go below target health
            if display.currentHealth < display.targetHealth then
                display.currentHealth = display.targetHealth
                display.pendingDamage = 0
            end
            
            -- Debug output to help track the animation
            -- print(string.format("Player %d: Health %.1f, Pending %.1f, Target %.1f", 
            --     i, display.currentHealth, display.pendingDamage, display.targetHealth))
        end
    end
end

function UI.drawSpellbookModal(wizard, playerNum, formatCost)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Determine position based on player number
    local modalX, modalTitle, keyPrefix
    if playerNum == 1 then
        modalX = 0  -- Pinned to left edge
        modalTitle = "Ashgar's Spellbook"
        keyPrefix = {"Q", "W", "E", "Q+W", "Q+E", "W+E", "Q+W+E"}
    else
        modalX = screenWidth - 400  -- Pinned to right edge
        modalTitle = "Selene's Spellbook"
        keyPrefix = {"I", "O", "P", "I+O", "I+P", "O+P", "I+O+P"}
    end
    
    -- Modal background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 450)
    love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
    love.graphics.rectangle("line", modalX, 50, 400, 450)
    
    -- Modal title
    love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
    love.graphics.rectangle("fill", modalX, 50, 400, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(modalTitle, modalX + 150, 60)
    
    -- Close button
    love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", modalX + 370, 50, 30, 30)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("X", modalX + 380, 60)
    
    -- Controls help section at the top of the modal
    love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
    love.graphics.rectangle("fill", modalX + 10, 90, 380, 100)
    love.graphics.setColor(1, 1, 1, 0.9)
    
    if playerNum == 1 then
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("Q/W/E: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("F: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("G: Free all active spells and return mana", modalX + 30, 155)
        love.graphics.print("B: Toggle spellbook visibility", modalX + 30, 175)
    else
        love.graphics.print("Controls:", modalX + 20, 95)
        love.graphics.print("I/O/P: Key different spell inputs", modalX + 30, 115)
        love.graphics.print("J: Cast the currently keyed spell", modalX + 30, 135)
        love.graphics.print("H: Free all active spells and return mana", modalX + 30, 155)
        love.graphics.print("M: Toggle spellbook visibility", modalX + 30, 175)
    end
    
    -- Spells section
    local y = 200
    
    -- Single key spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Single Key Spells", modalX + 150, y + 5)
    y = y + 30
    
    -- Display single key spells
    for i = 1, 3 do
        local keyName = tostring(i)
        local spell = wizard.spellbook[keyName]
        if spell then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            love.graphics.print(keyPrefix[i] .. ": " .. spell.name, modalX + 20, y + 5)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. spell.castTime .. "s", modalX + 30, y + 25)
            y = y + 45
        end
    end
    
    -- Multi-key spells heading
    love.graphics.setColor(1, 1, 0.7, 0.9)
    love.graphics.rectangle("fill", modalX + 10, y, 380, 25)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.print("Multi-Key Spells", modalX + 150, y + 5)
    y = y + 30
    
    -- Display multi-key spells
    for i = 4, 7 do  -- 4=combo "12", 5=combo "13", 6=combo "23", 7=combo "123"
        local keyName
        if i == 4 then keyName = "12"
        elseif i == 5 then keyName = "13"
        elseif i == 6 then keyName = "23"
        else keyName = "123" end
        
        local spell = wizard.spellbook[keyName]
        if spell then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            love.graphics.rectangle("fill", modalX + 10, y, 380, 40)
            love.graphics.setColor(wizard.color[1]/255, wizard.color[2]/255, wizard.color[3]/255, 0.9)
            love.graphics.print(keyPrefix[i] .. ": " .. spell.name, modalX + 20, y + 5)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print("Cost: " .. formatCost(spell.cost) .. "   Cast Time: " .. spell.castTime .. "s", modalX + 30, y + 25)
            y = y + 45
        end
    end
end


return UI```

## ./validate_spellCompiler.lua
```lua
-- validate_spellCompiler.lua
-- A simple script to validate the spellCompiler implementation
-- Writes validation results to a file for inspection

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")

-- Define a sample spell for testing
local sampleSpell = {
    id = "fireball",
    name = "Fireball",
    description = "A ball of fire that deals damage",
    attackType = "projectile",
    castTime = 5.0,
    cost = {"fire", "fire"},
    keywords = {
        damage = {
            amount = 10,
            type = "fire"
        },
        burn = {
            duration = 3.0,
            tickDamage = 2
        }
    },
    vfx = "fireball_vfx",
    blockableBy = {"barrier", "ward"}
}

-- Open a file for writing results
local outFile = io.open("spellCompiler_validation.txt", "w")

-- Write test header
outFile:write("===== SPELL COMPILER VALIDATION =====\n\n")

-- Test basic spell compilation
outFile:write("Testing basic spell compilation...\n")
local compiledSpell = SpellCompiler.compileSpell(sampleSpell, Keywords)

-- Check that compilation worked
outFile:write("Compiled spell has behavior: " .. (compiledSpell.behavior ~= nil and "YES" or "NO") .. "\n")
outFile:write("Compiled spell has damage behavior: " .. (compiledSpell.behavior.damage ~= nil and "YES" or "NO") .. "\n")
outFile:write("Compiled spell has burn behavior: " .. (compiledSpell.behavior.burn ~= nil and "YES" or "NO") .. "\n")

-- Test a boolean keyword
local spellWithBoolKeyword = {
    id = "groundSpell",
    name = "Ground Spell",
    description = "Forces enemy to ground",
    attackType = "utility",
    castTime = 3.0,
    cost = {"any"},
    keywords = {
        ground = true
    }
}

outFile:write("\nTesting boolean keyword handling...\n")
local compiledBoolSpell = SpellCompiler.compileSpell(spellWithBoolKeyword, Keywords)
outFile:write("Boolean keyword compiled: " .. (compiledBoolSpell.behavior.ground ~= nil and "YES" or "NO") .. "\n")
outFile:write("Boolean keyword enabled: " .. (compiledBoolSpell.behavior.ground.enabled == true and "YES" or "NO") .. "\n")

-- Define mock game objects for execution testing
local caster = {
    name = "TestWizard",
    elevation = "GROUNDED",
    manaPool = { 
        tokens = {},
        addToken = function() end
    },
    gameState = { rangeState = "FAR" }
}

local target = {
    name = "EnemyWizard",
    elevation = "AERIAL",
    health = 100
}

-- Test executing the compiled behaviors
outFile:write("\nTesting behavior execution...\n")

-- Create table to capture print output
local originalPrint = print
local printOutput = {}
print = function(...)
    local args = {...}
    local output = ""
    for i, v in ipairs(args) do
        output = output .. tostring(v) .. (i < #args and "\t" or "")
    end
    table.insert(printOutput, output)
end

-- Run debug output to capture to our printOutput table
SpellCompiler.debugCompiled(compiledSpell)

-- Write captured output to file
for _, line in ipairs(printOutput) do
    outFile:write(line .. "\n")
end

-- Restore original print function
print = originalPrint

outFile:write("\nVALIDATION SUMMARY\n")
outFile:write("- Basic spell compilation: " .. (compiledSpell.behavior ~= nil and "PASSED" or "FAILED") .. "\n")
outFile:write("- Boolean keyword handling: " .. (compiledBoolSpell.behavior.ground ~= nil and "PASSED" or "FAILED") .. "\n")
outFile:write("- Execution structure: " .. (type(compiledSpell.executeAll) == "function" and "PASSED" or "FAILED") .. "\n")

outFile:write("\n===== SPELL COMPILER VALIDATION COMPLETED =====\n")
outFile:close()

-- Print confirmation message
print("Validation completed. Results written to spellCompiler_validation.txt")```

## ./vfx.lua
```lua
-- VFX.lua
-- Visual effects module for spell animations and combat effects

local VFX = {}
VFX.__index = VFX

-- Table to store active effects
VFX.activeEffects = {}

-- Initialize the VFX system
function VFX.init()
    -- Load any necessary assets for effects
    VFX.assets = {
        -- Fire effects
        fireParticle = love.graphics.newImage("assets/sprites/fire-particle.png"),
        fireGlow = love.graphics.newImage("assets/sprites/fire-glow.png"),
        
        -- Force effects
        forceWave = love.graphics.newImage("assets/sprites/force-wave.png"),
        
        -- Moon effects
        moonGlow = love.graphics.newImage("assets/sprites/moon-glow.png"),
        
        -- Generic effects
        sparkle = love.graphics.newImage("assets/sprites/sparkle.png"),
        impactRing = love.graphics.newImage("assets/sprites/impact-ring.png"),
    }
    
    -- Effect definitions keyed by effect name
    VFX.effects = {
        -- General impact effect (used for many spell interactions)
        impact = {
            type = "impact",
            duration = 0.5,  -- Half second by default
            particleCount = 15,
            startScale = 0.8,
            endScale = 0.2,
            color = {1, 1, 1, 0.8},  -- Default white, will be overridden by options
            radius = 30,
            sound = nil  -- No default sound
        },
        
        -- Tidal Force Ground effect - for forcing opponents down from AERIAL to GROUNDED
        tidal_force_ground = {
            type = "impact",
            duration = 0.8,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = {0.4, 0.6, 1.0, 0.9},  -- Blue-ish for water/tidal theme
            radius = 80,
            sound = "tidal_wave"
        },
        
        -- Gravity Pin Ground effect - for forcing opponents down from AERIAL to GROUNDED
        gravity_pin_ground = {
            type = "impact",
            duration = 0.8,
            particleCount = 20,
            startScale = 0.6,
            endScale = 1.0,
            color = {0.7, 0.3, 0.9, 0.9},  -- Purple for gravity theme
            radius = 70,
            sound = "gravity_slam"
        },
        
        force_blast = {
            type = "impact",
            duration = 1.0,
            particleCount = 30,
            startScale = 0.4,
            endScale = 1.5,
            color = {0.4, 0.7, 1.0, 0.8},  -- Blue-ish for force theme
            radius = 90,
            sound = "force_wind"
        },
        
        -- Free Mana - special effect when freeing all spells
        free_mana = {
            type = "aura",
            duration = 1.2,
            particleCount = 40,
            startScale = 0.4,
            endScale = 0.8,
            color = {0.2, 0.6, 0.9, 0.9},  -- Bright blue for freeing mana
            radius = 100,
            pulseRate = 4,
            sound = "release"
        },

        -- Firebolt effect
        firebolt = {
            type = "projectile",
            duration = 1.0,  -- 1 second total duration
            particleCount = 20,
            startScale = 0.5,
            endScale = 1.0,
            color = {1, 0.5, 0.2, 1},
            trailLength = 12,
            impactSize = 1.4,
            sound = "firebolt"
        },
        
        -- Meteor effect
        meteor = {
            type = "impact",
            duration = 1.5,
            particleCount = 40,
            startScale = 2.0,
            endScale = 0.5,
            color = {1, 0.4, 0.1, 1},
            radius = 120,
            sound = "meteor"
        },
        
        -- Mist Veil effect
        mistveil = {
            type = "aura",
            duration = 3.0,
            particleCount = 30,
            startScale = 0.2,
            endScale = 0.8,
            color = {0.7, 0.7, 1.0, 0.7},
            radius = 80,
            pulseRate = 2,
            sound = "mist"
        },
        
        -- Emberlift effect
        emberlift = {
            type = "vertical",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.1,
            color = {1, 0.6, 0.2, 0.8},
            height = 100,
            sound = "whoosh"
        },
        
        -- Force Blast Up effect (for forcing opponents up to AERIAL)
        force_blast_up = {
            type = "vertical",
            duration = 1.5,
            particleCount = 35,
            startScale = 0.4,
            endScale = 0.2,
            color = {0.3, 0.5, 1.0, 0.8},  -- Blue-ish for force
            height = 120,
            sound = "force_wind"
        },
        
        -- Full Moon Beam effect
        fullmoonbeam = {
            type = "beam",
            duration = 1.8,
            particleCount = 30,
            beamWidth = 40,
            startScale = 0.2,
            endScale = 1.0,
            color = {0.8, 0.8, 1.0, 0.9},
            pulseRate = 3,
            sound = "moonbeam"
        },
        
        -- Tidal Force effect
        tidal_force = {
            type = "projectile",
            duration = 1.2,
            particleCount = 30,
            startScale = 0.4,
            endScale = 0.8,
            color = {0.3, 0.5, 1.0, 0.8},  -- Blue-ish for water theme
            trailLength = 15,
            impactSize = 1.6,
            sound = "tidal_wave"
        },
        
        -- Lunar Disjunction effect
        lunardisjunction = {
            type = "projectile",
            duration = 1.0,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.6,
            color = {0.8, 0.6, 1.0, 0.9},  -- Purple-blue for moon/cosmic theme
            trailLength = 10,
            impactSize = 1.8,  -- Bigger impact
            sound = "lunar_disrupt"
        },
        
        -- Disjoint effect (for cancelling opponent's spell)
        disjoint_cancel = {
            type = "impact",
            duration = 1.2,
            particleCount = 35,
            startScale = 0.6,
            endScale = 1.0,
            color = {0.9, 0.5, 1.0, 0.9},  -- Brighter purple for disruption
            radius = 70,
            sound = "lunar_disrupt"
        },
        
        -- Conjure Fire effect
        conjurefire = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = {1.0, 0.5, 0.2, 0.9},
            height = 140,  -- Height to rise toward mana pool
            spreadRadius = 40, -- Initial spread around the caster
            sound = "conjure"
        },
        
        -- Conjure Moonlight effect
        conjuremoonlight = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = {0.7, 0.7, 1.0, 0.9},
            height = 140,
            spreadRadius = 40,
            sound = "conjure"
        },
        
        -- Volatile Conjuring effect (random mana)
        volatileconjuring = {
            type = "conjure",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.2,
            endScale = 0.6,
            color = {1.0, 1.0, 0.5, 0.9},  -- Yellow base color, will be randomized
            height = 140,
            spreadRadius = 55,  -- Wider spread for volatile
            sound = "conjure"
        },
        
        -- Shield effect (used for barrier, ward, and field shield activation)
        shield = {
            type = "aura",
            duration = 1.0,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = {0.8, 0.8, 1.0, 0.8},  -- Default blue-ish, will be overridden by options
            radius = 60,
            pulseRate = 3,
            sound = "shield"
        }
    }
    
    -- Initialize sound effects (placeholders)
    VFX.sounds = {
        firebolt = nil, -- Will load actual sound files when available
        meteor = nil,
        mist = nil,
        whoosh = nil,
        moonbeam = nil,
        conjure = nil,
        shield = nil
    }
    
    return VFX
end

-- Create a new effect instance
function VFX.createEffect(effectName, sourceX, sourceY, targetX, targetY, options)
    -- Get effect template
    local template = VFX.effects[effectName:lower()]
    if not template then
        print("Warning: Effect not found: " .. effectName)
        return nil
    end
    
    -- Create a new effect instance
    local effect = {
        name = effectName,
        type = template.type,
        sourceX = sourceX,
        sourceY = sourceY,
        targetX = targetX or sourceX,
        targetY = targetY or sourceY,
        
        -- Timing
        duration = template.duration,
        timer = 0,
        progress = 0,
        isComplete = false,
        
        -- Visual properties (copied from template)
        particleCount = template.particleCount,
        startScale = template.startScale,
        endScale = template.endScale,
        color = {template.color[1], template.color[2], template.color[3], template.color[4]},
        
        -- Effect specific properties
        particles = {},
        trailPoints = {},
        
        -- Sound
        sound = template.sound,
        
        -- Additional properties based on effect type
        radius = template.radius,
        beamWidth = template.beamWidth,
        height = template.height,
        pulseRate = template.pulseRate,
        trailLength = template.trailLength,
        impactSize = template.impactSize,
        spreadRadius = template.spreadRadius,
        
        -- Optional overrides
        options = options or {}
    }
    
    -- Initialize particles based on effect type
    VFX.initializeParticles(effect)
    
    -- Play sound effect if available
    if effect.sound and VFX.sounds[effect.sound] then
        -- Will play sound when implemented
    end
    
    -- Add to active effects list
    table.insert(VFX.activeEffects, effect)
    
    return effect
end

-- Initialize particles based on effect type
function VFX.initializeParticles(effect)
    -- Different initialization based on effect type
    if effect.type == "projectile" then
        -- For projectiles, create a trail of particles
        for i = 1, effect.particleCount do
            local particle = {
                x = effect.sourceX,
                y = effect.sourceY,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = 0,
                delay = i / effect.particleCount * 0.3, -- Stagger particle start
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "impact" then
        -- For impact effects, create a radial explosion
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(10, effect.radius)
            local speed = math.random(50, 200)
            local particle = {
                x = effect.targetX,
                y = effect.targetY,
                targetX = effect.targetX + math.cos(angle) * distance,
                targetY = effect.targetY + math.sin(angle) * distance,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = angle,
                delay = math.random() * 0.2, -- Slight random delay
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "aura" then
        -- For aura effects, create particles that orbit the character
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(effect.radius * 0.6, effect.radius)
            local orbitalSpeed = math.random(0.5, 2.0)
            local particle = {
                angle = angle,
                distance = distance,
                orbitalSpeed = orbitalSpeed,
                scale = effect.startScale,
                alpha = 0, -- Start invisible and fade in
                rotation = 0,
                delay = i / effect.particleCount * 0.5,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "vertical" then
        -- For vertical effects like emberlift, particles rise upward
        for i = 1, effect.particleCount do
            local offsetX = math.random(-30, 30)
            local startY = math.random(0, 40)
            local speed = math.random(70, 150)
            local particle = {
                x = effect.sourceX + offsetX,
                y = effect.sourceY + startY,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = math.random() * math.pi * 2,
                delay = i / effect.particleCount * 0.8,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "beam" then
        -- For beam effects like fullmoonbeam, create a beam with particles
        -- First create the main beam shape
        effect.beamProgress = 0
        effect.beamLength = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
        effect.beamAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)
        
        -- Then add particles along the beam
        for i = 1, effect.particleCount do
            local position = math.random()
            local offset = math.random(-10, 10)
            local particle = {
                position = position, -- 0 to 1 along beam
                offset = offset, -- Perpendicular to beam
                scale = effect.startScale * math.random(0.7, 1.3),
                alpha = 0.8,
                rotation = math.random() * math.pi * 2,
                delay = math.random() * 0.3,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "conjure" then
        -- For conjuration spells, create particles that rise from caster toward mana pool
        -- Set the mana pool position (typically at top center)
        effect.manaPoolX = effect.options and effect.options.manaPoolX or 400 -- Screen center X
        effect.manaPoolY = effect.options and effect.options.manaPoolY or 120 -- Near top of screen
        
        -- Ensure spreadRadius has a default value
        effect.spreadRadius = effect.spreadRadius or 40
        
        -- Calculate direction vector toward mana pool
        local dirX = effect.manaPoolX - effect.sourceX
        local dirY = effect.manaPoolY - effect.sourceY
        local len = math.sqrt(dirX * dirX + dirY * dirY)
        dirX = dirX / len
        dirY = dirY / len
        
        for i = 1, effect.particleCount do
            -- Create a spread of particles around the caster
            local spreadAngle = math.random() * math.pi * 2
            local spreadDist = math.random() * effect.spreadRadius
            local startX = effect.sourceX + math.cos(spreadAngle) * spreadDist
            local startY = effect.sourceY + math.sin(spreadAngle) * spreadDist
            
            -- Randomize particle properties
            local speed = math.random(80, 180)
            local delay = i / effect.particleCount * 0.7
            
            -- Add some variance to path
            local pathVariance = math.random(-20, 20)
            local pathDirX = dirX + pathVariance / 100
            local pathDirY = dirY + pathVariance / 100
            
            local particle = {
                x = startX,
                y = startY,
                speedX = pathDirX * speed,
                speedY = pathDirY * speed,
                scale = effect.startScale,
                alpha = 0, -- Start transparent and fade in
                rotation = math.random() * math.pi * 2,
                rotSpeed = math.random(-3, 3),
                delay = delay,
                active = false,
                finalPulse = false,
                finalPulseTime = 0
            }
            table.insert(effect.particles, particle)
        end
    end
end

-- Update all active effects
function VFX.update(dt)
    local i = 1
    while i <= #VFX.activeEffects do
        local effect = VFX.activeEffects[i]
        
        -- Update effect timer
        effect.timer = effect.timer + dt
        effect.progress = math.min(effect.timer / effect.duration, 1.0)
        
        -- Update effect based on type
        if effect.type == "projectile" then
            VFX.updateProjectile(effect, dt)
        elseif effect.type == "impact" then
            VFX.updateImpact(effect, dt)
        elseif effect.type == "aura" then
            VFX.updateAura(effect, dt)
        elseif effect.type == "vertical" then
            VFX.updateVertical(effect, dt)
        elseif effect.type == "beam" then
            VFX.updateBeam(effect, dt)
        elseif effect.type == "conjure" then
            VFX.updateConjure(effect, dt)
        end
        
        -- Remove effect if complete
        if effect.progress >= 1.0 then
            table.remove(VFX.activeEffects, i)
        else
            i = i + 1
        end
    end
end

-- Update function for projectile effects
function VFX.updateProjectile(effect, dt)
    -- Update trail points
    if #effect.trailPoints == 0 then
        -- Initialize trail with source position
        for i = 1, effect.trailLength do
            table.insert(effect.trailPoints, {x = effect.sourceX, y = effect.sourceY})
        end
    end
    
    -- Calculate projectile position based on progress
    local posX = effect.sourceX + (effect.targetX - effect.sourceX) * effect.progress
    local posY = effect.sourceY + (effect.targetY - effect.sourceY) * effect.progress
    
    -- Add curved trajectory based on height
    local midpointProgress = effect.progress - 0.5
    local verticalOffset = -60 * (1 - (midpointProgress * 2)^2)
    posY = posY + verticalOffset
    
    -- Update trail
    table.remove(effect.trailPoints)
    table.insert(effect.trailPoints, 1, {x = posX, y = posY})
    
    -- Update particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Distribute particles along the trail
            local trailIndex = math.floor((i / #effect.particles) * #effect.trailPoints) + 1
            if trailIndex > #effect.trailPoints then trailIndex = #effect.trailPoints end
            
            local trailPoint = effect.trailPoints[trailIndex]
            
            -- Add some randomness to particle positions
            local spreadFactor = 8 * (1 - particleProgress)
            particle.x = trailPoint.x + math.random(-spreadFactor, spreadFactor)
            particle.y = trailPoint.y + math.random(-spreadFactor, spreadFactor)
            
            -- Update visual properties
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            particle.alpha = math.min(2.0 - particleProgress * 2, 1.0) -- Fade out in last half
            particle.rotation = particle.rotation + dt * 2
        end
    end
    
    -- Create impact effect when reaching the target
    if effect.progress > 0.95 and not effect.impactCreated then
        effect.impactCreated = true
        -- Would create a separate impact effect here in a full implementation
    end
end

-- Update function for impact effects
function VFX.updateImpact(effect, dt)
    -- Create impact wave that expands outward
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle outward from center
            local dirX = particle.targetX - effect.targetX
            local dirY = particle.targetY - effect.targetY
            local length = math.sqrt(dirX^2 + dirY^2)
            if length > 0 then
                dirX = dirX / length
                dirY = dirY / length
            end
            
            particle.x = effect.targetX + dirX * length * particleProgress
            particle.y = effect.targetY + dirY * length * particleProgress
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            particle.alpha = 1.0 - particleProgress^2 -- Quadratic fade out
            particle.rotation = particle.rotation + dt * 3
        end
    end
end

-- Update function for aura effects
function VFX.updateAura(effect, dt)
    -- Update orbital particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update angle for orbital motion
            particle.angle = particle.angle + dt * particle.orbitalSpeed
            
            -- Calculate position based on orbit
            particle.x = effect.sourceX + math.cos(particle.angle) * particle.distance
            particle.y = effect.sourceY + math.sin(particle.angle) * particle.distance
            
            -- Pulse effect
            local pulseOffset = math.sin(effect.timer * effect.pulseRate) * 0.2
            
            -- Update visual properties with fade in/out
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress + pulseOffset
            
            -- Fade in for first 20%, stay visible for 60%, fade out for last 20%
            if particleProgress < 0.2 then
                particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
            elseif particleProgress > 0.8 then
                particle.alpha = (1 - particleProgress) * 5 -- 1 to 0 over last 20% time
            else
                particle.alpha = 1.0
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for vertical effects
function VFX.updateVertical(effect, dt)
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle upward
            particle.y = particle.y - particle.speed * dt
            
            -- Add some horizontal drift
            local driftSpeed = 10 * math.sin(particle.y * 0.05 + i)
            particle.x = particle.x + driftSpeed * dt
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            
            -- Fade in briefly, then fade out over time
            if particleProgress < 0.1 then
                particle.alpha = particleProgress * 10 -- Quick fade in
            else
                particle.alpha = 1.0 - ((particleProgress - 0.1) / 0.9) -- Slower fade out
            end
            
            particle.rotation = particle.rotation + dt * 2
        end
    end
end

-- Update function for beam effects
function VFX.updateBeam(effect, dt)
    -- Update beam progress
    effect.beamProgress = math.min(effect.progress * 2, 1.0) -- Beam reaches full extension halfway through
    
    -- Update beam particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Only show particles along the visible length of the beam
            if particle.position <= effect.beamProgress then
                -- Calculate position along beam
                local beamX = effect.sourceX + (effect.targetX - effect.sourceX) * particle.position
                local beamY = effect.sourceY + (effect.targetY - effect.sourceY) * particle.position
                
                -- Add perpendicular offset
                local perpX = -math.sin(effect.beamAngle) * particle.offset
                local perpY = math.cos(effect.beamAngle) * particle.offset
                
                particle.x = beamX + perpX
                particle.y = beamY + perpY
                
                -- Add pulsing effect
                local pulseOffset = math.sin(effect.timer * effect.pulseRate + particle.position * 10) * 0.3
                
                -- Update visual properties
                particle.scale = (effect.startScale + (effect.endScale - effect.startScale) * particleProgress) * (1 + pulseOffset)
                
                -- Fade based on beam extension and overall effect progress
                if effect.progress < 0.5 then
                    -- Beam extending - particles at tip are brighter
                    local distFromTip = math.abs(particle.position - effect.beamProgress)
                    particle.alpha = math.max(0, 1.0 - distFromTip * 3)
                else
                    -- Beam fully extended, starting to fade out
                    local fadeProgress = (effect.progress - 0.5) * 2 -- 0 to 1 in second half
                    particle.alpha = 1.0 - fadeProgress
                end
            else
                particle.alpha = 0 -- Particle not yet reached by beam extension
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for conjure effects
function VFX.updateConjure(effect, dt)
    -- Update particles rising toward mana pool
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update position based on speed
            if not particle.finalPulse then
                particle.x = particle.x + particle.speedX * dt
                particle.y = particle.y + particle.speedY * dt
                
                -- Calculate distance to mana pool
                local distX = effect.manaPoolX - particle.x
                local distY = effect.manaPoolY - particle.y
                local dist = math.sqrt(distX * distX + distY * distY)
                
                -- If close to mana pool, trigger final pulse effect
                if dist < 30 or particleProgress > 0.85 then
                    particle.finalPulse = true
                    particle.finalPulseTime = 0
                    
                    -- Center at mana pool
                    particle.x = effect.manaPoolX + math.random(-15, 15)
                    particle.y = effect.manaPoolY + math.random(-15, 15)
                end
            else
                -- Handle final pulse animation
                particle.finalPulseTime = particle.finalPulseTime + dt
                
                -- Expand and fade out for final pulse
                local pulseProgress = math.min(particle.finalPulseTime / 0.3, 1.0) -- 0.3s pulse duration
                particle.scale = effect.endScale * (1 + pulseProgress * 2) -- Expand to 3x size
                particle.alpha = 1.0 - pulseProgress -- Fade out
            end
            
            -- Handle fade in and rotation regardless of state
            if not particle.finalPulse then
                -- Fade in over first 20% of travel
                if particleProgress < 0.2 then
                    particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
                else
                    particle.alpha = 1.0
                end
                
                -- Update scale
                particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            end
            
            -- Update rotation
            particle.rotation = particle.rotation + particle.rotSpeed * dt
        end
    end
    
    -- Add a special effect at source and destination
    if effect.progress < 0.3 then
        -- Glow at source during initial phase
        effect.sourceGlow = 1.0 - (effect.progress / 0.3)
    else
        effect.sourceGlow = 0
    end
    
    -- Glow at mana pool during later phase
    if effect.progress > 0.5 then
        effect.poolGlow = (effect.progress - 0.5) * 2
        if effect.poolGlow > 1.0 then effect.poolGlow = 2 - effect.poolGlow end -- Peak at 0.75 progress
    else
        effect.poolGlow = 0
    end
end

-- Draw all active effects
function VFX.draw()
    for _, effect in ipairs(VFX.activeEffects) do
        if effect.type == "projectile" then
            VFX.drawProjectile(effect)
        elseif effect.type == "impact" then
            VFX.drawImpact(effect)
        elseif effect.type == "aura" then
            VFX.drawAura(effect)
        elseif effect.type == "vertical" then
            VFX.drawVertical(effect)
        elseif effect.type == "beam" then
            VFX.drawBeam(effect)
        elseif effect.type == "conjure" then
            VFX.drawConjure(effect)
        end
    end
end

-- Draw function for projectile effects
function VFX.drawProjectile(effect)
    local particleImage = VFX.assets.fireParticle
    local glowImage = VFX.assets.fireGlow
    
    -- Draw trail
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    if #effect.trailPoints >= 3 then
        local points = {}
        for i, point in ipairs(effect.trailPoints) do
            table.insert(points, point.x)
            table.insert(points, point.y)
        end
        love.graphics.setLineWidth(effect.startScale * 10)
        love.graphics.line(points)
        love.graphics.setLineWidth(1)
    end
    
    -- Draw glow at head of projectile
    if #effect.trailPoints > 0 then
        local head = effect.trailPoints[1]
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
        local glowScale = effect.startScale * 3
        love.graphics.draw(
            glowImage,
            head.x, head.y,
            0,
            glowScale, glowScale,
            glowImage:getWidth()/2, glowImage:getHeight()/2
        )
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw impact flash when projectile reaches target
    if effect.progress > 0.95 then
        local flashIntensity = (1 - (effect.progress - 0.95) * 20) -- Flash quickly fades
        if flashIntensity > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], flashIntensity)
            love.graphics.circle("fill", effect.targetX, effect.targetY, effect.impactSize * 30 * (1 - flashIntensity))
        end
    end
end

-- Draw function for impact effects
function VFX.drawImpact(effect)
    local particleImage = VFX.assets.fireParticle
    local impactImage = VFX.assets.impactRing
    
    -- Draw expanding ring
    local ringProgress = math.min(effect.progress * 1.5, 1.0) -- Ring expands faster than full effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - ringProgress) * effect.color[4])
    local ringScale = effect.radius * 0.02 * ringProgress
    love.graphics.draw(
        impactImage,
        effect.targetX, effect.targetY,
        0,
        ringScale, ringScale,
        impactImage:getWidth()/2, impactImage:getHeight()/2
    )
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw central flash
    if effect.progress < 0.3 then
        local flashIntensity = 1.0 - (effect.progress / 0.3)
        love.graphics.setColor(1, 1, 1, flashIntensity * 0.7)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 30 * flashIntensity)
    end
end

-- Draw function for aura effects
function VFX.drawAura(effect)
    local particleImage = VFX.assets.sparkle
    
    -- Draw base aura circle
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.2
    local baseAlpha = 0.3 * (1 - (math.abs(effect.progress - 0.5) * 2)^2) -- Peak at middle of effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], baseAlpha)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, baseAlpha * 1.5)
    love.graphics.circle("line", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
end

-- Draw function for vertical effects
function VFX.drawVertical(effect)
    local particleImage = VFX.assets.fireParticle
    
    -- Draw base effect at source
    local baseProgress = math.min(effect.progress * 3, 1.0) -- Quick initial flash
    if baseProgress < 1.0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - baseProgress) * 0.7)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 40 * baseProgress)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw guiding lines (subtle vertical paths)
    if effect.progress < 0.7 then
        local lineAlpha = 0.3 * (1.0 - effect.progress / 0.7)
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], lineAlpha)
        for i = 1, 5 do
            local xOffset = (i - 3) * 10
            local startY = effect.sourceY
            local endY = effect.sourceY - effect.height * math.min(effect.progress * 2, 1.0)
            love.graphics.line(effect.sourceX + xOffset, startY, effect.sourceX + xOffset * 1.5, endY)
        end
    end
end

-- Draw function for beam effects
function VFX.drawBeam(effect)
    local particleImage = VFX.assets.sparkle
    local beamLength = effect.beamLength * effect.beamProgress
    
    -- Draw base beam
    local beamEndX = effect.sourceX + math.cos(effect.beamAngle) * beamLength
    local beamEndY = effect.sourceY + math.sin(effect.beamAngle) * beamLength
    
    -- Calculate beam width with pulse
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.3
    local beamWidth = effect.beamWidth * (1 + pulseAmount) * (1 - (effect.progress > 0.5 and (effect.progress - 0.5) * 2 or 0))
    
    -- Draw outer beam glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    love.graphics.setLineWidth(beamWidth * 1.5)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw inner beam core
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, effect.color[4] * 0.7)
    love.graphics.setLineWidth(beamWidth * 0.7)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw brightest beam center
    love.graphics.setColor(1, 1, 1, effect.color[4] * 0.9)
    love.graphics.setLineWidth(beamWidth * 0.3)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw source glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, 20 * (1 + pulseAmount))
    
    -- Draw impact glow at target if beam is fully extended
    if effect.beamProgress >= 0.99 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.8 * (1 - (effect.progress - 0.5) * 2))
        love.graphics.circle("fill", beamEndX, beamEndY, 25 * (1 + pulseAmount))
    end
end

-- Draw function for conjure effects
function VFX.drawConjure(effect)
    local particleImage = VFX.assets.sparkle
    local glowImage = VFX.assets.fireGlow  -- We'll use this for all conjure types
    
    -- Draw source glow if active
    if effect.sourceGlow and effect.sourceGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.sourceGlow * 0.6)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 50 * effect.sourceGlow)
        
        -- Draw expanding rings from source (hint at conjuration happening)
        local ringCount = 3
        for i = 1, ringCount do
            local ringProgress = ((effect.timer * 1.5) % 1.0) + (i-1) / ringCount
            if ringProgress < 1.0 then
                local ringSize = 60 * ringProgress
                local ringAlpha = 0.5 * (1.0 - ringProgress) * effect.sourceGlow
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], ringAlpha)
                love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
            end
        end
    end
    
    -- Draw mana pool glow if active
    if effect.poolGlow and effect.poolGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.poolGlow * 0.7)
        love.graphics.circle("fill", effect.manaPoolX, effect.manaPoolY, 40 * effect.poolGlow)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            -- Choose the right glow image based on final pulse state
            local imgToDraw = particleImage
            
            -- Adjust color based on state
            if particle.finalPulse then
                -- Brighter for final pulse
                love.graphics.setColor(
                    effect.color[1] * 1.3, 
                    effect.color[2] * 1.3, 
                    effect.color[3] * 1.3, 
                    effect.color[4] * particle.alpha
                )
                imgToDraw = glowImage
            else
                love.graphics.setColor(
                    effect.color[1], 
                    effect.color[2], 
                    effect.color[3], 
                    effect.color[4] * particle.alpha
                )
            end
            
            -- Draw the particle
            love.graphics.draw(
                imgToDraw,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                imgToDraw:getWidth()/2, imgToDraw:getHeight()/2
            )
            
            -- For volatile conjuring, add random color sparks
            if effect.name:lower() == "volatileconjuring" and not particle.finalPulse and math.random() < 0.3 then
                -- Random rainbow hue for volatile conjuring
                local hue = (effect.timer * 0.5 + particle.x * 0.01) % 1.0
                local r, g, b = HSVtoRGB(hue, 0.8, 1.0)
                
                love.graphics.setColor(r, g, b, particle.alpha * 0.7)
                love.graphics.draw(
                    particleImage,
                    particle.x + math.random(-5, 5), 
                    particle.y + math.random(-5, 5),
                    particle.rotation + math.random() * math.pi,
                    particle.scale * 0.5, particle.scale * 0.5,
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
            end
        end
    end
    
    -- Draw connection lines between particles (ethereal threads)
    if effect.progress < 0.7 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.2)
        
        local maxConnectDist = 50  -- Maximum distance for particles to connect
        for i = 1, #effect.particles do
            local p1 = effect.particles[i]
            if p1.active and p1.alpha > 0.2 and not p1.finalPulse then
                for j = i+1, #effect.particles do
                    local p2 = effect.particles[j]
                    if p2.active and p2.alpha > 0.2 and not p2.finalPulse then
                        local dx = p1.x - p2.x
                        local dy = p1.y - p2.y
                        local dist = math.sqrt(dx*dx + dy*dy)
                        
                        if dist < maxConnectDist then
                            -- Fade based on distance
                            local alpha = (1 - dist/maxConnectDist) * 0.3 * p1.alpha * p2.alpha
                            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
                            love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                        end
                    end
                end
            end
        end
    end
end

-- Helper function for HSV to RGB conversion (for volatile conjuring rainbow effect)
function HSVtoRGB(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r, g, b
end

-- Helper function to create the appropriate effect for a spell
function VFX.createSpellEffect(spell, caster, target)
    -- Get mana pool position for conjuration spells
    local manaPoolX = caster.manaPool and caster.manaPool.x or 400
    local manaPoolY = caster.manaPool and caster.manaPool.y or 120
    
    -- Determine source and target positions
    local sourceX, sourceY = caster.x, caster.y
    local targetX, targetY = target.x, target.y
    
    -- Handle different spell types
    local spellName = spell.name:lower():gsub("%s+", "") -- Convert to lowercase and remove spaces
    
    -- Handle conjuration spells first
    if spellName == "conjurefire" then
        return VFX.createEffect("conjurefire", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "conjuremoonlight" then
        return VFX.createEffect("conjuremoonlight", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "volatileconjuring" then
        return VFX.createEffect("volatileconjuring", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    
    -- Special handling for other specific spells
    elseif spellName == "firebolt" then
        return VFX.createEffect("firebolt", sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "meteor" then
        return VFX.createEffect("meteor", targetX, targetY - 100, targetX, targetY)
    elseif spellName == "mistveil" then
        return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
    elseif spellName == "emberlift" then
        return VFX.createEffect("emberlift", sourceX, sourceY, nil, nil)
    elseif spellName == "fullmoonbeam" then
        return VFX.createEffect("fullmoonbeam", sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "tidalforce" then
        return VFX.createEffect("tidal_force", sourceX, sourceY - 15, targetX, targetY - 15)
    elseif spellName == "lunardisjunction" then
        return VFX.createEffect("lunardisjunction", sourceX, sourceY - 15, targetX, targetY - 15)
    elseif spellName == "forceblast" then
        return VFX.createEffect("force_blast", sourceX, sourceY - 15, targetX, targetY - 15)
    else
        -- Create a generic effect based on spell type or mana cost
        if spell.spellType == "projectile" then
            return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
        else
            -- Look at spell cost to determine effect type
            local hasFireMana = false
            local hasMoonMana = false
            
            for _, cost in ipairs(spell.cost or {}) do
                if cost.type == "fire" then hasFireMana = true end
                if cost.type == "moon" then hasMoonMana = true end
            end
            
            if hasFireMana then
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            elseif hasMoonMana then
                return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
            else
                -- Default generic effect
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            end
        end
    end
end

return VFX```

## ./wizard.lua
```lua
-- Wizard class

local Wizard = {}
Wizard.__index = Wizard

-- Load spells module with the new keyword system
local SpellsModule = require("spells")
local Spells = SpellsModule.spells  -- For backwards compatibility

-- We'll use game.compiledSpells instead of a local compiled spells table

-- Create a shield function to replace the one from SpellsModule.keywordSystem
local function createShield(wizard, spellSlot, blockParams)
    -- Check that the slot is valid
    if not wizard.spellSlots[spellSlot] then
        print("[SHIELD ERROR] Invalid spell slot for shield creation: " .. tostring(spellSlot))
        return { shieldCreated = false }
    end
    
    local slot = wizard.spellSlots[spellSlot]
    
    -- Set shield parameters - simplified to use token count as the only source of truth
    slot.isShield = true
    slot.defenseType = blockParams.type or "barrier"
    
    -- Store the original spell completion
    slot.active = true
    slot.progress = slot.castTime -- Mark as fully cast
    
    -- Set which attack types this shield blocks
    slot.blocksAttackTypes = {}
    local blockTypes = blockParams.blocks or {"projectile"}
    for _, attackType in ipairs(blockTypes) do
        slot.blocksAttackTypes[attackType] = true
    end
    
    -- Also store as array for compatibility
    slot.blockTypes = blockTypes
    
    -- ALL shields are mana-linked (consume tokens when hit) - simplified model
    
    -- Set reflection capability
    slot.reflect = blockParams.reflect or false
    
    -- No longer tracking shield strength separately - token count is the source of truth
    
    -- Slow down token orbiting speed for shield tokens if they exist
    for _, tokenData in ipairs(slot.tokens) do
        local token = tokenData.token
        if token then
            -- Set token to "SHIELDING" state
            token.state = "SHIELDING"
            -- Add specific shield type info to the token for visual effects
            token.shieldType = slot.defenseType
            -- Slow down the rotation speed for shield tokens
            if token.orbitSpeed then
                token.orbitSpeed = token.orbitSpeed * 0.5  -- 50% slower
            end
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
    
    -- Print debug info - simplified to only show token count
    print(string.format("[SHIELD] %s created a %s shield in slot %d with %d tokens",
        wizard.name or "Unknown wizard",
        slot.defenseType,
        spellSlot,
        #slot.tokens))
    
    -- Return result for further processing - simplified for token-based shields only
    return {
        shieldCreated = true,
        defenseType = slot.defenseType,
        blockTypes = blockParams.blocks
    }
end

-- Function to check if a spell can be blocked by a shield
local function checkShieldBlock(spell, attackType, defender, attacker)
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
    if not defender or not spell or not attackType then
        print("[SHIELD DEBUG] checkShieldBlock early exit - missing parameter")
        return result
    end
    
    -- Utility spells can't be blocked
    if attackType == "utility" then
        print("[SHIELD DEBUG] checkShieldBlock early exit - utility spell can't be blocked")
        return result
    end
    
    print("[SHIELD DEBUG] Checking if " .. attackType .. " spell can be blocked by " .. defender.name .. "'s shields")
    
    -- Check each of the defender's spell slots for active shields
    for i, slot in ipairs(defender.spellSlots) do
        -- Skip inactive slots or non-shield slots
        if not slot.active or not slot.isShield then
            goto continue
        end
        
        -- Check if this shield has tokens remaining (token count is the source of truth for shield strength)
        if #slot.tokens <= 0 then
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
            -- All shields are mana-linked by default
            result.manaLinked = true
            
            -- Handle mana consumption for the block
            if #slot.tokens > 0 then
                result.processBlockEffect = true
                
                -- Get amount of hits based on the spell's shield breaker power (if any)
                local shieldBreakPower = spell.shieldBreaker or 1
                
                -- Determine how many tokens to consume (up to shield breaker power or tokens available)
                local tokensToConsume = math.min(shieldBreakPower, #slot.tokens)
                result.tokensToConsume = tokensToConsume
                
                -- No need to track shield strength separately anymore
                -- Token consumption is handled by removing tokens directly
                
                -- Check if this will destroy the shield (when all tokens are consumed)
                if tokensToConsume >= #slot.tokens then
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

-- Get a compiled spell by ID, compile on demand if not already compiled
local function getCompiledSpell(spellId, wizard)
    -- Make sure we have a game reference
    if not wizard or not wizard.gameState then
        print("Error: No wizard or gameState to get compiled spell")
        return nil
    end
    
    local gameState = wizard.gameState
    
    -- Try to get from game's compiled spells
    if gameState.compiledSpells and gameState.compiledSpells[spellId] then
        return gameState.compiledSpells[spellId]
    end
    
    -- If not found, try to compile on demand
    if Spells[spellId] and gameState.spellCompiler and gameState.keywords then
        -- Make sure compiledSpells exists
        if not gameState.compiledSpells then
            gameState.compiledSpells = {}
        end
        
        -- Compile the spell and store it
        gameState.compiledSpells[spellId] = gameState.spellCompiler.compileSpell(
            Spells[spellId], 
            gameState.keywords
        )
        print("Compiled spell on demand: " .. spellId)
        return gameState.compiledSpells[spellId]
    else
        print("Error: Could not compile spell with ID: " .. spellId)
        return nil
    end
end

function Wizard.new(name, x, y, color)
    local self = setmetatable({}, Wizard)
    
    self.name = name
    self.x = x
    self.y = y
    self.color = color  -- RGB table
    
    -- Wizard state
    self.health = 100
    self.elevation = "GROUNDED"  -- GROUNDED or AERIAL
    self.elevationTimer = 0      -- Timer for temporary elevation changes
    self.stunTimer = 0           -- Stun timer in seconds
    
    -- Status effects
    self.statusEffects = {
        burn = {
            active = false,
            duration = 0,
            tickDamage = 0,
            tickInterval = 1.0,
            elapsed = 0,         -- Time since last tick
            totalTime = 0        -- Total time effect has been active
        }
    }
    
    -- Visual effects
    self.blockVFX = {
        active = false,
        timer = 0,
        x = 0,
        y = 0
    }
    
    -- Spell cast notification (temporary until proper VFX)
    self.spellCastNotification = nil
    
    -- Spell keying system
    self.activeKeys = {
        [1] = false,
        [2] = false,
        [3] = false
    }
    self.currentKeyedSpell = nil
    
    -- Spell loadout based on wizard name
    if name == "Ashgar" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjurefire,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.firebolt,
            
            -- Multi-key combinations
            ["12"] = Spells.eruption,      -- Zone spell with range anchoring 
            ["13"] = Spells.combust, -- Mana denial spell
            ["23"] = Spells.emberlift,     -- Movement spell
            ["123"] = Spells.meteor  -- Zone dependent nuke
        }
    elseif name == "Selene" then
        self.spellbook = {
            -- Single key spells
            ["1"] = Spells.conjuremoonlight,
            ["2"] = Spells.volatileconjuring,
            ["3"] = Spells.mist,
            
            -- Multi-key combinations
            ["12"] = Spells.tidalforce,     -- Chip damage Remote spell that forces out of AERIAL
            ["13"] = Spells.eclipse,
            ["23"] = Spells.lunardisjunction, -- 
            ["123"] = Spells.fullmoonbeam -- Full Moon Beam spell
        }
    end
    
    -- Verify that all spells in the spellbook are properly defined
    for key, spell in pairs(self.spellbook) do
        if not spell then
            print("WARNING: Spell for key combo '" .. key .. "' is nil for " .. name)
        elseif not spell.cost then
            print("WARNING: Spell '" .. (spell.name or "unnamed") .. "' for key combo '" .. key .. "' has no cost defined")
        else
            -- Ensure spell has an ID
            if not spell.id and spell.name then
                spell.id = spell.name:lower():gsub(" ", "")
                print("DEBUG: Added missing ID for spell: " .. spell.name .. " -> " .. spell.id)
            end
            
            -- Detailed debug output for detecting reference issues
            print("DEBUG: Spell reference check for key combo '" .. key .. "':")
            print("DEBUG: - Name: " .. (spell.name or "unnamed"))
            print("DEBUG: - ID: " .. (spell.id or "no id"))
            print("DEBUG: - Cost: " .. (type(spell.cost) == "table" and "table of length " .. #spell.cost or tostring(spell.cost)))
        end
    end
    
    -- Spell slots (3 max)
    self.spellSlots = {}
    for i = 1, 3 do
        self.spellSlots[i] = {
            active = false,
            progress = 0,
            spellType = nil,
            castTime = 0,
            tokens = {},  -- Will hold channeled mana tokens
            
            -- Shield-specific properties
            isShield = false,
            defenseType = nil,  -- "barrier", "ward", or "field"
            shieldStrength = 0, -- How many hits the shield can take
            blocksAttackTypes = nil  -- Table of attack types this shield blocks
        }
    end
    
    -- Load wizard sprite
    self.sprite = love.graphics.newImage("assets/sprites/wizard.png")
    self.scale = 2.0  -- Scale factor for the sprite
    
    return self
end

function Wizard:update(dt)
    -- Update stun timer
    if self.stunTimer > 0 then
        self.stunTimer = math.max(0, self.stunTimer - dt)
        if self.stunTimer == 0 then
            print(self.name .. " is no longer stunned")
        end
    end
    
    -- Update elevation timer
    if self.elevationTimer > 0 and self.elevation == "AERIAL" then
        self.elevationTimer = math.max(0, self.elevationTimer - dt)
        if self.elevationTimer == 0 then
            self.elevation = "GROUNDED"
            print(self.name .. " returned to GROUNDED elevation")
            
            -- Create landing effect using VFX system
            if self.gameState and self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", self.x, self.y + 30, nil, nil, {
                    duration = 0.5,
                    color = {0.7, 0.7, 0.7, 0.8},
                    particleCount = 8,
                    radius = 20
                })
            end
        end
    end
    
    -- Update burn status effect
    if self.statusEffects.burn.active then
        -- Update total time
        self.statusEffects.burn.totalTime = self.statusEffects.burn.totalTime + dt
        
        -- Update elapsed time since last tick
        self.statusEffects.burn.elapsed = self.statusEffects.burn.elapsed + dt
        
        -- Check if it's time for damage tick
        if self.statusEffects.burn.elapsed >= self.statusEffects.burn.tickInterval then
            -- Apply burn damage
            local damage = self.statusEffects.burn.tickDamage
            self.health = math.max(0, self.health - damage)
            
            -- Reset elapsed time
            self.statusEffects.burn.elapsed = 0
            
            -- Log damage
            print(string.format("[BURN] %s takes %d burn damage! (health: %d)", 
                self.name, damage, self.health))
            
            -- Create burn effect using VFX system
            if self.gameState and self.gameState.vfx then
                -- Random position around the wizard for the burn effect
                local angle = math.random() * math.pi * 2
                local distance = math.random(10, 30)
                local effectX = self.x + math.cos(angle) * distance
                local effectY = self.y + math.sin(angle) * distance
                
                self.gameState.vfx.createEffect("impact", effectX, effectY, nil, nil, {
                    duration = 0.3,
                    color = {1.0, 0.4, 0.1, 0.6},
                    particleCount = 3,
                    radius = 10
                })
            end
        end
        
        -- Check if the effect has expired
        if self.statusEffects.burn.totalTime >= self.statusEffects.burn.duration then
            -- Deactivate the effect
            self.statusEffects.burn.active = false
            print(string.format("[STATUS] %s is no longer burning", self.name))
        end
    end
    
    -- Update block VFX
    if self.blockVFX.active then
        self.blockVFX.timer = self.blockVFX.timer - dt
        if self.blockVFX.timer <= 0 then
            self.blockVFX.active = false
        end
    end
    
    -- Update spell cast notification
    if self.spellCastNotification then
        self.spellCastNotification.timer = self.spellCastNotification.timer - dt
        if self.spellCastNotification.timer <= 0 then
            self.spellCastNotification = nil
        end
    end
    
    -- Update spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            -- If the slot is an active shield, just keep it active, and add
            -- shield pulsing effects if needed
            if slot.isShield and slot.progress >= slot.castTime then
                -- For active shields, make tokens orbit their slots
                -- Calculate positions for all tokens in this shield
                local slotYOffsets = {30, 0, -30}
                -- Apply AERIAL offset to shield tokens
                local yOffset = self.currentYOffset or 0
                local slotY = self.y + slotYOffsets[i] + yOffset
                -- Define orbit radii for each slot (same values used in drawSpellSlots)
                local horizontalRadii = {80, 70, 60}  -- Wider at the bottom, narrower at the top  
                local verticalRadii = {20, 25, 30}    -- Flatter at the bottom, rounder at the top
                local radiusX = horizontalRadii[i]
                local radiusY = verticalRadii[i]
                
                -- Move all tokens in a slow orbit
                if #slot.tokens > 0 then
                    -- Make tokens orbit slowly
                    local baseAngle = love.timer.getTime() * 0.3  -- Slow steady rotation
                    local tokenCount = #slot.tokens
                    
                    for j, tokenData in ipairs(slot.tokens) do
                        local token = tokenData.token
                        -- Position tokens evenly around the orbit
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = baseAngle + anglePerToken * (j - 1)
                        
                        -- Calculate 3D position with elliptical projection
                        -- Apply NEAR/FAR positioning offset for tokens as well
                        local xOffset = 0
                        local isNear = self.gameState and self.gameState.rangeState == "NEAR"
                        
                        -- Push wizards closer to center in NEAR mode, further in FAR mode
                        if self.name == "Ashgar" then -- Player 1 (left side)
                            xOffset = isNear and 60 or 0 -- Move right when NEAR
                        else -- Player 2 (right side)
                            xOffset = isNear and -60 or 0 -- Move left when NEAR
                        end
                        
                        token.x = self.x + xOffset + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Update token rotation angle too (spin on its axis)
                        token.rotAngle = token.rotAngle + 0.01  -- Slow spin
                    end
                end
                
                -- Occasionally add subtle visual effects
                if math.random() < 0.01 and self.gameState and self.gameState.vfx then
                    local angle = math.random() * math.pi * 2
                    local radius = math.random(30, 40)
                    
                    -- Apply NEAR/FAR offset to sparkle effects as well
                    local xOffset = 0
                    local isNear = self.gameState and self.gameState.rangeState == "NEAR"
                    
                    -- Push wizards closer to center in NEAR mode, further in FAR mode
                    if self.name == "Ashgar" then -- Player 1 (left side)
                        xOffset = isNear and 60 or 0 -- Move right when NEAR
                    else -- Player 2 (right side)
                        xOffset = isNear and -60 or 0 -- Move left when NEAR
                    end
                    
                    local sparkleX = self.x + xOffset + math.cos(angle) * radius
                    local sparkleY = slotY + math.sin(angle) * radius
                    
                    -- Color based on shield type
                    local effectColor = {0.7, 0.7, 0.7, 0.5}  -- Default gray
                    if slot.defenseType == "barrier" then
                        effectColor = {1.0, 1.0, 0.3, 0.5}  -- Yellow for barriers
                    elseif slot.defenseType == "ward" then
                        effectColor = {0.3, 0.3, 1.0, 0.5}  -- Blue for wards
                    elseif slot.defenseType == "field" then
                        effectColor = {0.3, 1.0, 0.3, 0.5}  -- Green for fields
                    end
                    
                    self.gameState.vfx.createEffect("impact", sparkleX, sparkleY, nil, nil, {
                        duration = 0.3,
                        color = effectColor,
                        particleCount = 2,
                        radius = 5
                    })
                end
                
                -- Continue to next spell slot
                goto continue_next_slot
            end
            
            -- Check if the spell is frozen (by Eclipse Echo)
            if slot.frozen then
                -- Update freeze timer
                slot.freezeTimer = slot.freezeTimer - dt
                
                -- Check if the freeze duration has elapsed
                if slot.freezeTimer <= 0 then
                    -- Unfreeze the spell
                    slot.frozen = false
                    print(self.name .. "'s spell in slot " .. i .. " is no longer frozen")
                    
                    -- Add a visual "unfreeze" effect
                    if self.gameState and self.gameState.vfx then
                        local slotYOffsets = {30, 0, -30}
                        local slotY = self.y + slotYOffsets[i]
                        
                        self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                            duration = 0.5,
                            color = {0.7, 0.7, 1.0, 0.6},
                            particleCount = 10,
                            radius = 35
                        })
                    end
                else
                    -- Spell is still frozen, don't increment progress
                    -- Visual progress arc will appear frozen in place
                    
                    -- Add a subtle frozen visual effect if we have VFX
                    if math.random() < 0.03 and self.gameState and self.gameState.vfx then -- Occasional sparkle
                        local slotYOffsets = {30, 0, -30}
                        local slotY = self.y + slotYOffsets[i]
                        local angle = math.random() * math.pi * 2
                        local radius = math.random(30, 40)
                        local sparkleX = self.x + math.cos(angle) * radius
                        local sparkleY = slotY + math.sin(angle) * radius
                        
                        self.gameState.vfx.createEffect("impact", sparkleX, sparkleY, nil, nil, {
                            duration = 0.3,
                            color = {0.6, 0.6, 1.0, 0.5},
                            particleCount = 3,
                            radius = 5
                        })
                    end
                end
            else
                -- Normal progress update for unfrozen spells
                slot.progress = slot.progress + dt
                
                -- Shield state is now managed directly in the castSpell function
                -- and tokens remain as CHANNELED until the shield is activated
            end
            
            -- If spell finished casting
            if slot.progress >= slot.castTime then
                -- Shield state is now handled in the castSpell function via the 
                -- block keyword's shieldParams and the createShield function
                
                -- Cast the spell
                self:castSpell(i)
                
                -- For non-shield spells, we return tokens and reset the slot
                -- For shield spells, castSpell will handle setting up the shield 
                -- and we won't get here because we'll have the isShield check above
                if not slot.isShield then
                    -- Start return animation for tokens
                    if #slot.tokens > 0 then
                        for _, tokenData in ipairs(slot.tokens) do
                            -- Trigger animation to return token to the mana pool
                            self.manaPool:returnToken(tokenData.index)
                        end
                        
                        -- Clear token list (tokens still exist in the mana pool)
                        slot.tokens = {}
                    end
                    
                    -- Reset slot
                    slot.active = false
                    slot.progress = 0
                    slot.spellType = nil
                    slot.castTime = 0
                end
            end
            
            ::continue_next_slot::
        end
    end
end

function Wizard:draw()
    -- Calculate position adjustments based on elevation and range state
    local yOffset = 0
    local xOffset = 0
    
    -- Vertical adjustment for AERIAL state - increased for more dramatic effect
    if self.elevation == "AERIAL" then
        yOffset = -50  -- Lift the wizard up more significantly when AERIAL
    end
    
    -- Horizontal adjustment for NEAR/FAR state
    local isNear = self.gameState and self.gameState.rangeState == "NEAR"
    local centerX = love.graphics.getWidth() / 2
    
    -- Push wizards closer to center in NEAR mode, further in FAR mode
    if self.name == "Ashgar" then -- Player 1 (left side)
        xOffset = isNear and 60 or 0 -- Move right when NEAR
    else -- Player 2 (right side)
        xOffset = isNear and -60 or 0 -- Move left when NEAR
    end
    
    -- Set color and draw wizard
    if self.stunTimer > 0 then
        -- Apply a yellow/white flash for stunned wizards
        local flashIntensity = 0.5 + math.sin(love.timer.getTime() * 10) * 0.5
        love.graphics.setColor(1, 1, flashIntensity)
    else
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw elevation effect (GROUNDED or AERIAL)
    if self.elevation == "GROUNDED" then
        -- Draw ground indicator below wizard, applying the x offset
        love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        love.graphics.ellipse("fill", self.x + xOffset, self.y + 30, 40, 10)  -- Simple shadow/ground indicator
    end
    
    -- Store current offsets for other functions to use
    self.currentXOffset = xOffset
    self.currentYOffset = yOffset
    
    -- Draw the wizard with appropriate elevation and position
    love.graphics.setColor(1, 1, 1)
    
    -- Flip Selene's sprite horizontally if she's player 2
    local scaleX = self.scale
    if self.name == "Selene" then
        -- Mirror the sprite by using negative scale for the second player
        scaleX = -self.scale
    end
    
    love.graphics.draw(
        self.sprite, 
        self.x + xOffset, self.y + yOffset,  -- Apply both offsets
        0,  -- Rotation
        scaleX, self.scale,  -- Scale x, Scale y (negative x scale for Selene)
        self.sprite:getWidth()/2, self.sprite:getHeight()/2  -- Origin at center
    )
    
    -- Draw aerial effect if applicable
    if self.elevation == "AERIAL" then
        -- Draw aerial effect (clouds, wind lines, etc.)
        love.graphics.setColor(0.8, 0.8, 1, 0.3)
        
        -- Draw cloud-like puffs, applying the xOffset
        for i = 1, 3 do
            local cloudXOffset = math.sin(love.timer.getTime() * 1.5 + i) * 8
            local cloudY = self.y + yOffset + 40 + math.sin(love.timer.getTime() + i) * 3
            love.graphics.circle("fill", self.x + xOffset - 15 + cloudXOffset, cloudY, 8)
            love.graphics.circle("fill", self.x + xOffset + cloudXOffset, cloudY, 10)
            love.graphics.circle("fill", self.x + xOffset + 15 + cloudXOffset, cloudY, 8)
        end
        
        -- No visual timer display here - moved to drawStatusEffects function
    end
    
    -- No longer drawing text elevation indicator - using visual representation only
    
    -- Draw status effects with durations using the new horizontal bar system
    self:drawStatusEffects()
    
    -- Draw block effect when projectile is blocked
    if self.blockVFX.active then
        -- Draw block flash animation
        local progress = self.blockVFX.timer / 0.5  -- Normalize to 0-1
        local size = 80 * (1 - progress)
        love.graphics.setColor(0.7, 0.7, 1, progress * 0.8)
        love.graphics.circle("fill", self.x + xOffset, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.circle("line", self.x + xOffset, self.y, size)
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.print("BLOCKED!", self.x + xOffset - 30, self.y + 70)
    end
    
    -- Health bars will now be drawn in the UI system for a more dramatic fighting game style
    
    -- Keyed spell display has been moved to the UI spellbook component
    
    -- Handle shield block and token consumption
function Wizard:handleShieldBlock(slotIndex, blockedSpell)
    -- Get the shield slot
    local slot = self.spellSlots[slotIndex]
    
    -- Check if slot exists and is a valid shield
    if not slot or not slot.isShield then
        print("[SHIELD ERROR] Invalid shield slot: " .. tostring(slotIndex))
        return false
    end
    
    -- Check if shield has tokens
    if #slot.tokens <= 0 then
        print("[SHIELD ERROR] Shield has no tokens to consume")
        return false
    end
    
    -- Determine how many tokens to consume
    local tokensToConsume = 1 -- Default: consume 1 token per hit
    
    -- Shield breaker spells can consume more tokens
    if blockedSpell.shieldBreaker and blockedSpell.shieldBreaker > 1 then
        tokensToConsume = math.min(blockedSpell.shieldBreaker, #slot.tokens)
        print(string.format("[SHIELD BREAKER] Shield breaker consuming up to %d tokens", tokensToConsume))
    end
    
    -- Debug output to track token removal
    print(string.format("[SHIELD DEBUG] Before token removal: Shield has %d tokens", #slot.tokens))
    print(string.format("[SHIELD DEBUG] Will remove %d token(s)", tokensToConsume))
    
    -- Only consume tokens up to the number we have
    tokensToConsume = math.min(tokensToConsume, #slot.tokens)
    
    -- Return tokens back to the mana pool - ONE AT A TIME
    for i = 1, tokensToConsume do
        if #slot.tokens > 0 then
            -- Get the last token
            local lastTokenIndex = #slot.tokens
            local tokenData = slot.tokens[lastTokenIndex]
            
            print(string.format("[SHIELD DEBUG] Consuming token %d from shield (token %d of %d)", 
                tokenData.index, i, tokensToConsume))
            
            -- Important: We DO NOT directly set the token state here
            -- Instead, let the manaPool:returnToken method handle the state transition properly
            
            -- First check token state for debugging
            if tokenData.token then
                print(string.format("[SHIELD DEBUG] Token %d current state: %s", 
                    tokenData.index, tokenData.token.state or "unknown"))
            else
                print("[SHIELD WARNING] Token has no token data object")
            end
            
            -- Trigger animation to return this token to the mana pool
            -- The manaPool:returnToken handles all state changes properly
            if self.manaPool then
                print(string.format("[SHIELD DEBUG] Returning token %d to mana pool", tokenData.index))
                self.manaPool:returnToken(tokenData.index)
            else
                print("[SHIELD ERROR] Could not return token - mana pool not found")
            end
            
            -- Remove this token from the slot's token list
            table.remove(slot.tokens, lastTokenIndex)
            print(string.format("[SHIELD DEBUG] Token %d removed from shield token list (%d tokens remaining)", 
                tokenData.index, #slot.tokens))
        else
            print("[SHIELD ERROR] Tried to consume token but shield has no more tokens!")
            break -- Stop trying to consume tokens if there are none left
        end
    end
    
    print("[SHIELD DEBUG] After token removal: Shield has " .. #slot.tokens .. " tokens left")
    
    -- Create token release VFX
    if self.gameState and self.gameState.vfx then
        self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
            duration = 0.5,
            color = {0.8, 0.8, 0.2, 0.7},
            particleCount = 8,
            radius = 30
        })
    end
    
    -- Check if the shield is depleted (no tokens left)
    if #slot.tokens <= 0 then
        print(string.format("[SHIELD BREAK] %s's %s shield has been broken!", 
            self.name, slot.defenseType))
        
        -- Reset slot completely to avoid half-broken shield state
        print("[SHIELD DEBUG] Resetting slot " .. slotIndex .. " to empty state")
        slot.active = false
        slot.isShield = false
        slot.defenseType = nil
        slot.blocksAttackTypes = nil
        slot.blockTypes = nil  -- Clear block types array too
        slot.progress = 0
        slot.spellType = nil
        slot.spell = nil  -- Clear spell reference too
        slot.castTime = 0
        slot.tokens = {}  -- Ensure it's empty
        
        -- Create shield break effect
        if self.gameState and self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.7,
                color = {1.0, 0.5, 0.5, 0.8},
                particleCount = 15,
                radius = 50
            })
        end
    end
    
    return true
end

-- Draw spell cast notification (temporary until proper VFX)
    if self.spellCastNotification then
        -- Fade out towards the end
        local alpha = math.min(1.0, self.spellCastNotification.timer)
        local color = self.spellCastNotification.color
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        
        -- Draw with a subtle rise effect
        local notifYOffset = 10 * (1 - alpha)  -- Rise up as it fades
        love.graphics.print(self.spellCastNotification.text, 
                           self.spellCastNotification.x + xOffset - 60, 
                           self.spellCastNotification.y - notifYOffset, 
                           0, -- rotation
                           1.5, 1.5) -- scale
    end
    
    -- We'll remove the key indicators from here as they'll be drawn in the UI's spellbook component
    
    -- Save current xOffset and yOffset for other drawing functions
    self.currentXOffset = xOffset
    self.currentYOffset = yOffset
    
    -- Draw spell slots (orbits)
    self:drawSpellSlots()
end

-- Helper function to draw an ellipse
function Wizard:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 32
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

-- Helper function to draw an elliptical arc
function Wizard:drawEllipticalArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
    segments = segments or 16
    
    -- Calculate the angle increment
    local angleRange = endAngle - startAngle
    local angleIncrement = angleRange / segments
    
    -- Create points for the arc
    local points = {}
    
    for i = 0, segments do
        local angle = startAngle + angleIncrement * i
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(points, px)
        table.insert(points, py)
    end
    
    -- Draw the arc as a line
    love.graphics.line(points)
end

-- Draw status effects with durations using horizontal bars
function Wizard:drawStatusEffects()
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Get position offsets from draw function
    local xOffset = self.currentXOffset or 0
    local yOffset = self.currentYOffset or 0
    
    -- Properties for status effect bars
    local barWidth = 130
    local barHeight = 12
    local barSpacing = 18
    local barPadding = 15  -- Additional padding between effect bars
    
    -- Position status bars above the spellbook area
    local baseY = screenHeight - 150  -- Higher up from the spellbook
    local effectCount = 0
    
    -- Determine x position based on which wizard this is, plus the NEAR/FAR offset
    local x = (self.name == "Ashgar") and (150 + xOffset) or (screenWidth - 150 + xOffset)
    
    -- Define colors for different effect types
    local effectColors = {
        aerial = {0.7, 0.7, 1.0, 0.8},
        stun = {1.0, 1.0, 0.1, 0.8},
        shield = {0.5, 0.7, 1.0, 0.8},
        burn = {1.0, 0.4, 0.1, 0.8}
    }
    
    -- Draw AERIAL duration if active
    if self.elevation == "AERIAL" and self.elevationTimer > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress (1.0 to 0.0 as time depletes)
        local maxDuration = 5.0  -- Assuming 5 seconds is max aerial duration
        local progress = self.elevationTimer / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label
        love.graphics.setColor(effectColors.aerial[1], effectColors.aerial[2], effectColors.aerial[3], 
                              effectColors.aerial[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 4)))
        love.graphics.print("AERIAL", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.aerial)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.aerial[1], effectColors.aerial[2], effectColors.aerial[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time text
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs", self.elevationTimer), 
                           x + barWidth/2 - 30, y)
    end
    
    -- Draw STUN duration if active
    if self.stunTimer > 0 then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress
        local maxDuration = 2.0  -- Assuming 2 seconds is max stun duration
        local progress = self.stunTimer / maxDuration
        progress = math.min(1.0, progress)  -- Cap at 1.0
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label
        love.graphics.setColor(effectColors.stun[1], effectColors.stun[2], effectColors.stun[3], 
                              effectColors.stun[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 5)))
        love.graphics.print("STUNNED", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.stun)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.stun[1], effectColors.stun[2], effectColors.stun[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time text
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs", self.stunTimer), 
                           x + barWidth/2 - 30, y)
    end
    
    -- Shield display is now handled by the new shield system via shield slots
    
    -- Draw BURN duration if active
    if self.statusEffects.burn.active then
        effectCount = effectCount + 1
        local y = baseY - (effectCount * (barHeight + barPadding))
        
        -- Calculate progress
        local maxDuration = self.statusEffects.burn.duration
        local progress = 1.0 - (self.statusEffects.burn.totalTime / maxDuration)
        progress = math.max(0.0, progress)  -- Ensure non-negative
        
        -- Background frame for the entire effect
        love.graphics.setColor(0.2, 0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", x - barWidth/2 - 5, y - barHeight - 10, barWidth + 10, barHeight + 20, 5, 5)
        
        -- Draw label with pulsing effect
        love.graphics.setColor(effectColors.burn[1], effectColors.burn[2], effectColors.burn[3], 
                              effectColors.burn[4] * (0.7 + 0.3 * math.sin(love.timer.getTime() * 7)))
        love.graphics.print("BURNING", x - barWidth/2, y - barHeight - 5)
        
        -- Draw background bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw progress bar
        love.graphics.setColor(effectColors.burn)
        love.graphics.rectangle("fill", x - barWidth/2, y, barWidth * progress, barHeight, 3, 3)
        
        -- Draw border
        love.graphics.setColor(effectColors.burn[1], effectColors.burn[2], effectColors.burn[3], 0.5)
        love.graphics.rectangle("line", x - barWidth/2, y, barWidth, barHeight, 3, 3)
        
        -- Draw time remaining and damage info
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(string.format("%.1fs (%d/tick)", 
                           maxDuration - self.statusEffects.burn.totalTime,
                           self.statusEffects.burn.tickDamage), 
                           x - 20, y)
        
        -- Draw fire particles on the wizard to show the burning effect
        if math.random() < 0.2 and self.gameState and self.gameState.vfx then
            local angle = math.random() * math.pi * 2
            local distance = math.random(10, 30)
            local effectX = self.x + xOffset + math.cos(angle) * distance
            local effectY = self.y + yOffset + math.sin(angle) * distance
            
            self.gameState.vfx.createEffect("impact", effectX, effectY, nil, nil, {
                duration = 0.2,
                color = {1.0, 0.3, 0.1, 0.4},
                particleCount = 2,
                radius = 5
            })
        end
    end
end

function Wizard:drawSpellSlots()
    -- Draw 3 orbiting spell slots as elliptical paths at different vertical positions
    -- Position the slots at legs, midsection, and head levels
    -- Get position offsets from draw function to apply the same offsets as the wizard
    local xOffset = self.currentXOffset or 0
    local yOffset = self.currentYOffset or 0
    local slotYOffsets = {30, 0, -30}  -- From bottom to top
    
    -- Horizontal and vertical radii for each elliptical path
    local horizontalRadii = {80, 70, 60}   -- Wider at the bottom, narrower at the top
    local verticalRadii = {20, 25, 30}     -- Flatter at the bottom, rounder at the top
    
    for i, slot in ipairs(self.spellSlots) do
        -- Position parameters for each slot, applying both offsets
        local slotY = self.y + slotYOffsets[i] + yOffset
        local slotX = self.x + xOffset
        local radiusX = horizontalRadii[i]
        local radiusY = verticalRadii[i]
        
        -- Draw tokens that should appear "behind" the character first
        -- Skip drawing here for shields as those are handled in update
        if slot.active and #slot.tokens > 0 and not slot.isShield then
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            for j, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                if token.animTime >= token.animDuration and not token.returning then
                    local tokenCount = #slot.tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = progressAngle + anglePerToken * (j - 1)
                    
                    -- Only draw tokens that are in the back half (π to 2π)
                    local normalizedAngle = tokenAngle % (math.pi * 2)
                    if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                        -- Calculate 3D position with elliptical projection
                        token.x = slotX + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        token.zOrder = 0  -- Behind the wizard
                        
                        -- Draw token with reduced alpha for "behind" effect
                        love.graphics.setColor(1, 1, 1, 0.5)
                        love.graphics.draw(
                            token.image,
                            token.x, token.y,
                            token.rotAngle,
                            token.scale * 0.8, token.scale * 0.8,  -- Slightly smaller for perspective
                            token.image:getWidth()/2, token.image:getHeight()/2
                        )
                    end
                end
            end
        end
        
        -- Draw the character sprite (handled by the main draw function)
        
        -- If slot is active, draw progress arc and spell name
        if slot.active then
            -- Calculate progress angle (0 to 2*pi)
            local progressAngle = slot.progress / slot.castTime * math.pi * 2
            
            -- Check if it's a shield spell (fully cast)
            if slot.isShield then
                -- Draw a full shield arc with color based on defense type
                local shieldColor
                local shieldName = ""
                
                if slot.defenseType == "barrier" then
                    shieldColor = {1.0, 1.0, 0.3}  -- Yellow for barriers
                    shieldName = "Barrier"
                elseif slot.defenseType == "ward" then 
                    shieldColor = {0.3, 0.3, 1.0}  -- Blue for wards
                    shieldName = "Ward"
                elseif slot.defenseType == "field" then
                    shieldColor = {0.3, 1.0, 0.3}  -- Green for fields
                    shieldName = "Field"
                else
                    shieldColor = {0.8, 0.8, 0.8}  -- Grey fallback
                    shieldName = "Shield"
                end
                
                -- Add pulsing effect for active shields
                local pulseSize = 2 + math.sin(love.timer.getTime() * 3) * 2
                
                -- Draw a slightly larger pulse effect around the orbit
                for j = 1, 3 do
                    local extraSize = j * 2
                    love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.2 - j*0.05)
                    self:drawEllipse(slotX, slotY, radiusX + pulseSize + extraSize, 
                                    radiusY + pulseSize + extraSize, "line")
                end
                
                -- Draw the back half of the shield (reduced alpha)
                love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.4)
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, math.pi * 2, 16)
                
                -- Draw the front half of the shield (full alpha)
                love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.7)
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.pi, 16)
                
                -- Draw shield name (without numeric indicator) above the highest slot
                if i == 3 then
                    love.graphics.setColor(1, 1, 1, 0.8)
                    love.graphics.print(shieldName, slotX - 25, slotY - radiusY - 15)
                end
            
            -- Check if the spell is frozen by Eclipse Echo
            elseif slot.frozen then
                -- Draw frozen indicator - a "stopped" pulse effect around the orbit
                for j = 1, 3 do
                    local pulseSize = 2 + j*1.5
                    love.graphics.setColor(0.5, 0.5, 1.0, 0.2 - j*0.05)
                    
                    -- Draw a slightly larger ellipse to indicate frozen state
                    self:drawEllipse(slotX, slotY, radiusX + pulseSize + math.sin(love.timer.getTime() * 3) * 2, 
                                    radiusY + pulseSize + math.sin(love.timer.getTime() * 3) * 2, "line")
                end
                
                -- Draw the progress arc with a blue/icy color for frozen spells
                -- First the back half of the progress arc (if it extends that far)
                if progressAngle > math.pi then
                    love.graphics.setColor(0.5, 0.5, 1.0, 0.3)  -- Light blue for frozen
                    self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, progressAngle, 16)
                end
                
                -- Then the front half of the progress arc
                love.graphics.setColor(0.5, 0.5, 1.0, 0.7)  -- Light blue for frozen
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.min(progressAngle, math.pi), 16)
            else
                -- Normal progress arc for unfrozen spells
                -- First the back half of the progress arc (if it extends that far)
                if progressAngle > math.pi then
                    love.graphics.setColor(0.8, 0.8, 0.2, 0.3)  -- Lower alpha for back
                    self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, math.pi, progressAngle, 16)
                end
                
                -- Then the front half of the progress arc
                love.graphics.setColor(0.8, 0.8, 0.2, 0.7)  -- Higher alpha for front
                self:drawEllipticalArc(slotX, slotY, radiusX, radiusY, 0, math.min(progressAngle, math.pi), 16)
            end
            
            -- Draw spell name above the highest slot (only for non-shield spells)
            if i == 3 and not slot.isShield then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(slot.spellType, slotX - 20, slotY - radiusY - 15)
            end
            
            -- Draw tokens that should appear "in front" of the character
            -- Skip drawing here for shields as those are handled in update
            if #slot.tokens > 0 and not slot.isShield then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = progressAngle + anglePerToken * (j - 1)
                        
                        -- Only draw tokens that are in the front half (0 to π)
                        local normalizedAngle = tokenAngle % (math.pi * 2)
                        if normalizedAngle >= 0 and normalizedAngle <= math.pi then
                            -- Calculate 3D position with elliptical projection
                            token.x = slotX + math.cos(tokenAngle) * radiusX
                            token.y = slotY + math.sin(tokenAngle) * radiusY
                            token.zOrder = 1  -- In front of the wizard
                            
                            -- Draw token with full alpha for "front" effect
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale, token.scale,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        end
                    end
                end
            end
        else
            -- For inactive slots, only update token positions without drawing orbits
            -- Skip drawing inactive tokens for shield slots - we shouldn't have this case anyway
            if #slot.tokens > 0 and not slot.isShield then
                for j, tokenData in ipairs(slot.tokens) do
                    local token = tokenData.token
                    if token.animTime >= token.animDuration and not token.returning then
                        -- Position tokens on their appropriate paths even when slot is inactive
                        local tokenCount = #slot.tokens
                        local anglePerToken = math.pi * 2 / tokenCount
                        local tokenAngle = anglePerToken * (j - 1)
                        
                        -- Calculate position based on angle
                        token.x = slotX + math.cos(tokenAngle) * radiusX
                        token.y = slotY + math.sin(tokenAngle) * radiusY
                        
                        -- Set z-order based on position
                        local normalizedAngle = tokenAngle % (math.pi * 2)
                        if normalizedAngle > math.pi and normalizedAngle < math.pi * 2 then
                            token.zOrder = 0  -- Behind
                            -- Draw with reduced alpha for "behind" effect
                            love.graphics.setColor(1, 1, 1, 0.5)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale * 0.8, token.scale * 0.8,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        else
                            token.zOrder = 1  -- In front
                            -- Draw with full alpha
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                token.image,
                                token.x, token.y,
                                token.rotAngle,
                                token.scale, token.scale,
                                token.image:getWidth()/2, token.image:getHeight()/2
                            )
                        end
                    end
                end
            end
        end
    end
end

-- Handle key press and update currently keyed spell
function Wizard:keySpell(keyIndex, isPressed)
    -- Check if wizard is stunned
    if self.stunTimer > 0 and isPressed then
        print(self.name .. " tried to key a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Update key state
    self.activeKeys[keyIndex] = isPressed
    
    -- Determine current key combination
    local keyCombo = ""
    for i = 1, 3 do
        if self.activeKeys[i] then
            keyCombo = keyCombo .. i
        end
    end
    
    -- Update currently keyed spell based on combination
    if keyCombo == "" then
        self.currentKeyedSpell = nil
    else
        self.currentKeyedSpell = self.spellbook[keyCombo]
        
        -- Log the currently keyed spell
        if self.currentKeyedSpell then
            print(self.name .. " keyed " .. self.currentKeyedSpell.name .. " (" .. keyCombo .. ")")
            
            -- Debug: verify spell definition is complete
            if not self.currentKeyedSpell.cost then
                print("WARNING: Spell '" .. self.currentKeyedSpell.name .. "' has no cost defined!")
            end
        else
            print(self.name .. " has no spell for key combination: " .. keyCombo)
        end
    end
    
    return true
end

-- Cast the currently keyed spell
function Wizard:castKeyedSpell()
    -- Check if wizard is stunned
    if self.stunTimer > 0 then
        print(self.name .. " tried to cast a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Check if a spell is keyed
    if not self.currentKeyedSpell then
        print(self.name .. " tried to cast, but no spell is keyed")
        return false
    end
    
    -- Debug output to identify issues with specific spells
    print("DEBUG: " .. self.name .. " attempting to cast: " .. self.currentKeyedSpell.name)
    print("DEBUG: Spell cost: " .. self:formatCost(self.currentKeyedSpell.cost))
    
    -- Enhanced debugging for ALL spells to identify differences
    print("\nDEBUG: FULL SPELL ANALYSIS:")
    print("  - Name: " .. (self.currentKeyedSpell.name or "nil"))
    print("  - ID: " .. (self.currentKeyedSpell.id or "nil"))
    print("  - Cost type: " .. type(self.currentKeyedSpell.cost))
    print("  - Attack Type: " .. (self.currentKeyedSpell.attackType or "nil"))
    print("  - Has isShield: " .. tostring(self.currentKeyedSpell.isShield ~= nil))
    if self.currentKeyedSpell.isShield ~= nil then
        print("  - isShield value: " .. tostring(self.currentKeyedSpell.isShield))
    end
    print("  - Has effect func: " .. tostring(type(self.currentKeyedSpell.effect) == "function"))
    print("  - Has keywords: " .. tostring(self.currentKeyedSpell.keywords ~= nil))
    if self.currentKeyedSpell.keywords and self.currentKeyedSpell.keywords.block then
        print("  - Has block keyword")
        print("  - Block type: " .. (self.currentKeyedSpell.keywords.block.type or "nil"))
    else
        print("  - No block keyword")
    end
    
    -- Queue the keyed spell with detailed error handling
    print("DEBUG: Calling queueSpell...")
    local success, result = pcall(function() 
        return self:queueSpell(self.currentKeyedSpell)
    end)
    
    -- Debug the result of queueSpell
    if not success then
        print("ERROR: Exception in queueSpell: " .. tostring(result))
        print("ERROR TRACE: " .. debug.traceback())
        return false
    elseif not result then
        print("DEBUG: Failed to queue " .. self.currentKeyedSpell.name .. " - check if manaCost check failed")
    else
        print("DEBUG: Successfully queued " .. self.currentKeyedSpell.name)
    end
    
    return result
end

-- Helper to format spell cost for debug output
function Wizard:formatCost(cost)
    local costText = ""
    for i, costComponent in ipairs(cost) do
        if type(costComponent) == "string" then
            -- New format
            costText = costText .. costComponent
        else
            -- Old format
            costText = costText .. costComponent.type .. " x" .. costComponent.count
        end
        
        if i < #cost then
            costText = costText .. ", "
        end
    end
    
    if costText == "" then
        return "Free"
    else
        return costText
    end
end

function Wizard:queueSpell(spell)
    print("DEBUG: " .. self.name .. " queueSpell called for " .. (spell and spell.name or "nil spell"))
    
    -- Check if wizard is stunned
    if self.stunTimer > 0 then
        print(self.name .. " tried to queue a spell but is stunned for " .. string.format("%.1f", self.stunTimer) .. " more seconds")
        return false
    end
    
    -- Validate the spell
    if not spell then
        print("No spell provided to queue")
        return false
    end
    
    -- Get the compiled spell if available
    local spellToUse = spell
    if spell.id and not spell.executeAll then
        -- This is an original spell definition, not a compiled one - get the compiled version
        local compiledSpell = getCompiledSpell(spell.id, self)
        if compiledSpell then
            spellToUse = compiledSpell
            print("Using compiled spell for queue: " .. spellToUse.id)
        else
            print("Warning: Using original spell definition - could not get compiled version of " .. spell.id)
        end
    end
    
    -- Find the innermost available spell slot
    print("DEBUG: Checking for available spell slots...")
    for i = 1, #self.spellSlots do
        print("DEBUG: Checking slot " .. i .. ": " .. (self.spellSlots[i].active and "ACTIVE" or "AVAILABLE"))
        if not self.spellSlots[i].active then
            print("DEBUG: Found available slot " .. i .. ", checking mana cost...")
            -- Check if we can pay the mana cost from the pool
            local tokenReservations = self:canPayManaCost(spell.cost)
            
            -- Debug info for mana cost checks
            if not tokenReservations then
                print("DEBUG: Cannot pay mana cost for " .. spell.name)
                if type(spell.cost) == "table" then
                    for j, component in ipairs(spell.cost) do
                        print("DEBUG: - Cost component " .. j .. ": " .. tostring(component))
                    end
                else
                    print("DEBUG: Cost is not a table: " .. tostring(spell.cost))
                end
            end
            
            if tokenReservations then
                -- Collect the actual tokens to animate them to the spell slot
                local tokens = {}
                
                -- Move each token from mana pool to spell slot with animation
                for _, reservation in ipairs(tokenReservations) do
                    local token = self.manaPool.tokens[reservation.index]
                    
                    -- Mark the token as being channeled
                    token.state = "CHANNELED"
                    
                    -- Store original position for animation
                    token.startX = token.x
                    token.startY = token.y
                    
                    -- Calculate target position in the spell slot based on 3D positioning
                    -- These must match values in drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}
                    local verticalRadii = {20, 25, 30}
                    
                    local targetX = self.x
                    local targetY = self.y + slotYOffsets[i]  -- Vertical offset based on slot
                    
                    -- Animation data
                    token.targetX = targetX
                    token.targetY = targetY
                    token.animTime = 0
                    token.animDuration = 0.5 -- Half second animation
                    token.slotIndex = i
                    token.tokenIndex = #tokens + 1 -- Position in the slot
                    token.spellSlot = i
                    token.wizardOwner = self
                    
                    -- 3D perspective data
                    token.radiusX = horizontalRadii[i]
                    token.radiusY = verticalRadii[i]
                    
                    table.insert(tokens, {token = token, index = reservation.index})
                end
                
                -- Successfully paid the cost, queue the spell
                self.spellSlots[i].active = true
                self.spellSlots[i].progress = 0
                self.spellSlots[i].spellType = spellToUse.name
                
                -- Use dynamic cast time if available, otherwise use static cast time
                if spellToUse.getCastTime and type(spellToUse.getCastTime) == "function" then
                    self.spellSlots[i].castTime = spellToUse.getCastTime(self)
                    print(self.name .. " is using dynamic cast time: " .. self.spellSlots[i].castTime .. "s")
                else
                    self.spellSlots[i].castTime = spellToUse.castTime
                end
                
                self.spellSlots[i].spell = spellToUse
                self.spellSlots[i].tokens = tokens
                
                -- Check if this is a shield spell and mark it accordingly
                if spellToUse.isShield or (spellToUse.keywords and spellToUse.keywords.block) then
                    print("SHIELD SPELL DETECTED during queue: " .. spellToUse.name)
                    -- Flag that this will become a shield when cast
                    self.spellSlots[i].willBecomeShield = true
                    
                    -- DO NOT mark tokens as SHIELDING yet - let them orbit normally during casting
                    -- Only mark them as SHIELDING after the spell is fully cast
                    
                    -- Mark this in the compiled spell if not already marked
                    if not spellToUse.isShield then
                        spellToUse.isShield = true
                    end
                end
                
                -- Set attackType if present in the new schema
                if spellToUse.attackType then
                    self.spellSlots[i].attackType = spellToUse.attackType
                end
                
                print(self.name .. " queued " .. spellToUse.name .. " in slot " .. i .. " (cast time: " .. spellToUse.castTime .. "s)")
                return true
            else
                -- Couldn't pay the cost
                print(self.name .. " tried to queue " .. spellToUse.name .. " but couldn't pay the mana cost")
                return false
            end
        end
    end
    
    -- No available slots
    print(self.name .. " tried to queue " .. spellToUse.name .. " but all slots are full")
    return false
end

-- Helper function to create a shield from spell params
local function createShield(wizard, spellSlot, shieldParams)
    local slot = wizard.spellSlots[spellSlot]
    
    -- Set basic shield properties
    slot.isShield = true
    slot.defenseType = shieldParams.defenseType or "barrier"
    
    -- Set up blocksAttackTypes if not already set
    slot.blockTypes = shieldParams.blocksAttackTypes or {"projectile"}
    slot.blocksAttackTypes = {}
    for _, attackType in ipairs(slot.blockTypes) do
        slot.blocksAttackTypes[attackType] = true
    end
    
    -- Handle reflect property
    slot.reflect = shieldParams.reflect or false
    
    -- Mark tokens as SHIELDING
    for _, tokenData in ipairs(slot.tokens) do
        if tokenData.token then
            tokenData.token.state = "SHIELDING"
            -- Add specific shield type info to the token for visual effects
            tokenData.token.shieldType = slot.defenseType
        end
    end
    
    -- Mark the shield as fully cast
    slot.progress = slot.castTime
    
    -- Create shield activated visual effect
    if wizard.gameState and wizard.gameState.vfx then
        local shieldColor
        if slot.defenseType == "barrier" then
            shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Yellow for barriers
        elseif slot.defenseType == "ward" then
            shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
        elseif slot.defenseType == "field" then
            shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
        else
            shieldColor = {0.8, 0.8, 0.8, 0.7}  -- Default gray
        end
        
        wizard.gameState.vfx.createEffect("shield", wizard.x, wizard.y, nil, nil, {
            duration = 0.7,
            color = shieldColor,
            shieldType = slot.defenseType
        })
    end
    
    print(string.format("[SHIELD] %s activated a %s shield with %d tokens", 
        wizard.name, slot.defenseType, #slot.tokens))
end

-- Free all active spells and return their mana to the pool
function Wizard:freeAllSpells()
    print(self.name .. " is freeing all active spells")
    
    -- Iterate through all spell slots
    for i, slot in ipairs(self.spellSlots) do
        if slot.active then
            -- Return tokens to the mana pool
            if #slot.tokens > 0 then
                for _, tokenData in ipairs(slot.tokens) do
                    -- Trigger animation to return token to the mana pool
                    self.manaPool:returnToken(tokenData.index)
                end
                
                -- Clear token list (tokens still exist in the mana pool)
                slot.tokens = {}
            end
            
            -- Reset slot properties
            slot.active = false
            slot.progress = 0
            slot.spellType = nil
            slot.castTime = 0
            slot.spell = nil
            
            -- Reset shield-specific properties if applicable
            if slot.isShield then
                slot.isShield = false
                slot.defenseType = nil
                slot.blocksAttackTypes = nil
                slot.shieldStrength = 0
            end
            
            -- Reset any frozen state
            if slot.frozen then
                slot.frozen = false
                slot.freezeTimer = 0
            end
            
            print("Freed spell in slot " .. i)
        end
    end
    
    -- Create visual effect for all spells being canceled
    if self.gameState and self.gameState.vfx then
        self.gameState.vfx.createEffect("free_mana", self.x, self.y, nil, nil)
    end
    
    -- Reset active key inputs
    for i = 1, 3 do
        self.activeKeys[i] = false
    end
    
    -- Clear keyed spell
    self.currentKeyedSpell = nil
    
    return true
end

-- Helper function to check if mana cost can be paid without actually taking the tokens
function Wizard:canPayManaCost(cost)
    local tokenReservations = {}
    local reservedIndices = {} -- Track which token indices are already reserved
    
    -- Debug output for cost checking
    print("DEBUG: Checking mana cost payment for " .. (self.currentKeyedSpell and self.currentKeyedSpell.name or "unknown spell"))
    
    -- Handle cost being nil or not a table
    if not cost then
        print("DEBUG: Cost is nil")
        return {}
    end
    
    -- Check if cost is a valid table we can iterate through
    if type(cost) ~= "table" then
        print("DEBUG: Cost is not a table, it's a " .. type(cost))
        return nil
    end
    
    -- Early exit if cost is empty
    if #cost == 0 then 
        print("DEBUG: Cost is an empty table")
        return {} 
    end
    
    -- Dump the exact cost structure to understand what's being passed
    print("DEBUG: Cost structure details:")
    print("DEBUG: - Type: " .. type(cost))
    print("DEBUG: - Length: " .. #cost)
    for i, component in ipairs(cost) do
        print("DEBUG: - Component " .. i .. " type: " .. type(component))
        print("DEBUG: - Component " .. i .. " value: " .. tostring(component))
    end
    
    -- Print existing tokens in mana pool for debugging
    print("DEBUG: Mana pool contains " .. #self.manaPool.tokens .. " tokens:")
    local tokenCounts = {}
    for _, token in ipairs(self.manaPool.tokens) do
        if token.state == "FREE" then
            tokenCounts[token.type] = (tokenCounts[token.type] or 0) + 1
        end
    end
    for tokenType, count in pairs(tokenCounts) do
        print("DEBUG: - " .. tokenType .. ": " .. count .. " free tokens")
    end
    
    -- This function mirrors payManaCost but just returns the indices of tokens that would be used
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType, costCount
        
        -- Handle both old and new cost formats
        if type(costComponent) == "string" then
            -- New format: simple string token type
            costType = costComponent
            costCount = 1
        else
            -- Old format: table with type and count
            costType = costComponent.type
            costCount = costComponent.count
        end
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Try to get tokens of this type (that aren't already reserved)
                local availableTokens = {}
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.type == modalType and token.state == "FREE" and not reservedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                if #availableTokens >= costCount then
                    -- We have enough tokens to pay this cost
                    for i = 1, costCount do
                        local tokenData = availableTokens[i]
                        table.insert(tokenReservations, tokenData)
                        reservedIndices[tokenData.index] = true -- Mark as reserved
                    end
                    paid = true
                    break
                end
            end
            
            if not paid then
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available token types that aren't already reserved
                local availableTokens = {}
                
                -- Check each token and gather available ones that haven't been reserved yet
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.state == "FREE" and not reservedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTokens > 0 then
                    -- Shuffle the available tokens for true randomness
                    for i = #availableTokens, 2, -1 do
                        local j = math.random(i)
                        availableTokens[i], availableTokens[j] = availableTokens[j], availableTokens[i]
                    end
                    
                    -- Use the first token after shuffling
                    local tokenData = availableTokens[1]
                    table.insert(tokenReservations, tokenData)
                    reservedIndices[tokenData.index] = true -- Mark as reserved
                else
                    return nil
                end
            end
        else
            -- Specific type cost
            -- Get all the free tokens of this type first
            local availableTokens = {}
            for i, token in ipairs(self.manaPool.tokens) do
                if token.type == costType and token.state == "FREE" and not reservedIndices[i] then
                    table.insert(availableTokens, {token = token, index = i})
                end
            end
            
            -- Check if we have enough tokens
            if #availableTokens < costCount then
                return nil  -- Not enough tokens of this type
            end
            
            -- Add the required number of tokens to our reservations
            for i = 1, costCount do
                local tokenData = availableTokens[i]
                table.insert(tokenReservations, tokenData)
                reservedIndices[tokenData.index] = true -- Mark as reserved
            end
        end
    end
    
    return tokenReservations
end

-- Helper function to check and pay mana costs
function Wizard:payManaCost(cost)
    local tokens = {}
    local usedIndices = {} -- Track which token indices are already used
    
    -- Early exit if cost is empty
    if not cost or #cost == 0 then 
        print("DEBUG: Cost is nil or empty")
        return {} 
    end
    
    -- Try to pay each component of the cost
    for _, costComponent in ipairs(cost) do
        local costType, costCount
        
        -- Handle both old and new cost formats
        if type(costComponent) == "string" then
            -- New format: simple string token type
            costType = costComponent
            costCount = 1
        else
            -- Old format: table with type and count
            costType = costComponent.type
            costCount = costComponent.count
        end
        
        -- Handle different types of costs
        if type(costType) == "table" then
            -- Modal cost (can be paid with any of the listed types)
            local paid = false
            for _, modalType in ipairs(costType) do
                -- Collect all available tokens of this type that haven't been used yet
                local availableTokens = {}
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.type == modalType and token.state == "FREE" and not usedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                if #availableTokens >= costCount then
                    -- We have enough tokens to pay this cost
                    for i = 1, costCount do
                        local tokenData = availableTokens[i]
                        local token = self.manaPool.tokens[tokenData.index]
                        token.state = "CHANNELED" -- Mark as being used
                        table.insert(tokens, {token = token, index = tokenData.index})
                        usedIndices[tokenData.index] = true -- Mark as used
                    end
                    paid = true
                    break
                end
            end
            
            if not paid then
                -- Failed to pay modal cost, return tokens to pool
                for _, tokenData in ipairs(tokens) do
                    self.manaPool:returnToken(tokenData.index)
                end
                return nil
            end
        elseif costType == "any" then
            -- Generic cost (can be paid with any type)
            for _ = 1, costCount do
                -- Collect all available tokens that haven't been used yet
                local availableTokens = {}
                
                -- Check each token and gather available ones
                for i, token in ipairs(self.manaPool.tokens) do
                    if token.state == "FREE" and not usedIndices[i] then
                        table.insert(availableTokens, {token = token, index = i})
                    end
                end
                
                -- If there are available tokens, pick one randomly
                if #availableTokens > 0 then
                    -- Shuffle the available tokens for true randomness
                    for i = #availableTokens, 2, -1 do
                        local j = math.random(i)
                        availableTokens[i], availableTokens[j] = availableTokens[j], availableTokens[i]
                    end
                    
                    -- Use the first token after shuffling
                    local tokenData = availableTokens[1]
                    local token = self.manaPool.tokens[tokenData.index]
                    token.state = "CHANNELED" -- Mark as being used
                    table.insert(tokens, {token = token, index = tokenData.index})
                    usedIndices[tokenData.index] = true -- Mark as used
                else
                    -- No available tokens, return already collected tokens
                    for _, tokenData in ipairs(tokens) do
                        self.manaPool:returnToken(tokenData.index)
                    end
                    return nil
                end
            end
        else
            -- Specific type cost
            -- First gather all available tokens of this type
            local availableTokens = {}
            for i, token in ipairs(self.manaPool.tokens) do
                if token.type == costType and token.state == "FREE" and not usedIndices[i] then
                    table.insert(availableTokens, {token = token, index = i})
                end
            end
            
            -- Check if we have enough tokens
            if #availableTokens < costCount then
                -- Failed to find enough tokens, return any collected tokens to pool
                for _, tokenData in ipairs(tokens) do
                    self.manaPool:returnToken(tokenData.index)
                end
                return nil
            end
            
            -- Get the required number of tokens and mark them as CHANNELED
            for i = 1, costCount do
                local tokenData = availableTokens[i]
                local token = self.manaPool.tokens[tokenData.index]
                token.state = "CHANNELED"  -- Mark as being used
                table.insert(tokens, {token = token, index = tokenData.index})
                usedIndices[tokenData.index] = true -- Mark as used
            end
        end
    end
    
    -- Successfully paid all costs
    return tokens
end

function Wizard:castSpell(spellSlot)
    local slot = self.spellSlots[spellSlot]
    if not slot or not slot.active or not slot.spell then return end
    
    print(self.name .. " cast " .. slot.spellType .. " from slot " .. spellSlot)
    
    -- Create a temporary visual notification for spell casting
    self.spellCastNotification = {
        text = self.name .. " cast " .. slot.spellType,
        timer = 2.0,  -- Show for 2 seconds
        x = self.x,
        y = self.y + 70, -- Moved below the wizard instead of above
        color = {self.color[1]/255, self.color[2]/255, self.color[3]/255, 1.0}
    }
    
    -- Get target (the other wizard)
    local target = nil
    for _, wizard in ipairs(self.gameState.wizards) do
        if wizard ~= self then
            target = wizard
            break
        end
    end
    
    if not target then return end
    
    -- Get the spell (either compiled or original)
    local spellToUse = slot.spell
    
    -- Convert to compiled spell if needed
    if spellToUse.id and not spellToUse.executeAll then
        -- This is an original spell, not a compiled one - get the compiled version
        local compiledSpell = getCompiledSpell(spellToUse.id, self)
        if compiledSpell then
            spellToUse = compiledSpell
            -- Store the compiled spell back in the slot for future use
            slot.spell = compiledSpell
            print("Using compiled spell: " .. spellToUse.id)
        else
            print("Warning: Falling back to original spell - could not get compiled version of " .. spellToUse.id)
        end
    end
    
    -- Get attack type for shield checking
    local attackType = spellToUse.attackType or "projectile"
    
    -- Check if the spell can be blocked by any of the target's shields
    -- This now happens BEFORE spell execution per ticket PROG-20
    local blockInfo = checkShieldBlock(spellToUse, attackType, target, self)
    
    -- If blockable, handle block effects and exit early
    if blockInfo.blockable then
        print(string.format("[SHIELD] %s's %s was blocked by %s's %s shield!", 
            self.name, spellToUse.name, target.name, blockInfo.blockType or "unknown"))
        
        local effect = {
            blocked = true,
            blockType = blockInfo.blockType
        }
        
        -- Add VFX for shield block
        -- Create spell impact effect on the caster to show the spell being blocked
        if self.gameState.vfx then
            -- Shield color based on type
            local shieldColor = {0.8, 0.8, 0.8, 0.7}  -- Default gray
            if blockInfo.blockType == "barrier" then
                shieldColor = {1.0, 1.0, 0.3, 0.7}    -- Yellow for barriers
            elseif blockInfo.blockType == "ward" then
                shieldColor = {0.3, 0.3, 1.0, 0.7}    -- Blue for wards
            elseif blockInfo.blockType == "field" then 
                shieldColor = {0.3, 1.0, 0.3, 0.7}    -- Green for fields
            end
            
            -- Create visual effect on the target to show the block
            self.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
                duration = 0.5,
                color = shieldColor,
                shieldType = blockInfo.blockType
            })
            
            -- Create spell impact effect on the caster
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.3,
                color = {0.8, 0.2, 0.2, 0.5},
                particleCount = 5,
                radius = 15
            })
        end
        
        -- Use the new centralized handleShieldBlock method to handle token consumption
        target:handleShieldBlock(blockInfo.blockingSlot, spellToUse)
        
        -- Return tokens from our spell slot
        if #slot.tokens > 0 then
            for _, tokenData in ipairs(slot.tokens) do
                -- Trigger animation to return token to the mana pool
                self.manaPool:returnToken(tokenData.index)
            end
            -- Clear token list
            slot.tokens = {}
        end
        
        -- Reset our slot
        slot.active = false
        slot.progress = 0
        slot.spellType = nil
        slot.castTime = 0
        
        -- Skip further execution and return the effect
        return effect
    end
    
    -- Execute spell behavior using the compiled spell if available
    local effect = {}
    if spellToUse.executeAll then
        -- Use the compiled spell's executeAll method
        effect = spellToUse.executeAll(self, target, {}, spellSlot)
        print("Executed compiled spell: " .. spellToUse.name)
    else
        -- Fall back to the legacy keyword system for compatibility
        effect = SpellsModule.keywordSystem.castSpell(
            slot.spell,
            self,
            {
                opponent = target,
                spellSlot = spellSlot,
                debug = false  -- Set to true for detailed logging
            }
        )
        print("Executed spell via legacy system: " .. spellToUse.name)
    end
    
    -- Check if this is a shield spell with shieldParams from the block keyword
    if effect.shieldParams and effect.shieldParams.createShield then
        print("[SHIELD] Creating shield from shieldParams")
        
        -- Call createShield function with the parameters
        createShield(self, spellSlot, effect.shieldParams)
        
        -- Return early - don't reset the slot or return tokens
        return
    end
    
    -- Handle block effects from the block keyword within the spell execution
    -- This covers cases where the block is performed within the spell execution
    -- rather than by our shield detection system above
    if effect.blocked then
        -- Our preemptive shield check should have caught this, but
        -- handle it gracefully anyway for backward compatibility
        
        print("Note: Spell was blocked during execution (legacy block logic)")
        
        local shieldBreakPower = effect.shieldBreakPower or 1
        local shieldDestroyed = effect.shieldDestroyed or false
        
        if shieldDestroyed then
            print(string.format("[BLOCKED] %s's %s was blocked by %s's %s which has been DESTROYED!", 
                self.name, slot.spellType, target.name, effect.blockType or "shield"))
                
            -- Create shield break visual effect on the target
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                    duration = 0.7,
                    color = {1.0, 0.5, 0.5, 0.8},
                    particleCount = 15,
                    radius = 50
                })
            end
        else
            if shieldBreakPower > 1 then
                print(string.format("[BLOCKED] %s's %s was blocked by %s's %s! (shield took %d hits)", 
                    self.name, slot.spellType, target.name, effect.blockType or "shield", shieldBreakPower))
            else
                print(string.format("[BLOCKED] %s's %s was blocked by %s's %s", 
                    self.name, slot.spellType, target.name, effect.blockType or "shield"))
            end
            
            -- Create blocked visual effect at the shield
            if self.gameState.vfx then
                -- Shield color based on type
                local shieldColor = {0.8, 0.8, 0.8, 0.7}  -- Default gray
                if effect.blockType == "barrier" then
                    shieldColor = {1.0, 1.0, 0.3, 0.7}    -- Yellow for barriers
                elseif effect.blockType == "ward" then
                    shieldColor = {0.3, 0.3, 1.0, 0.7}    -- Blue for wards
                elseif effect.blockType == "field" then 
                    shieldColor = {0.3, 1.0, 0.3, 0.7}    -- Green for fields
                end
                
                -- Create visual effect on the target to show the block
                self.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
                    duration = 0.5,
                    color = shieldColor,
                    shieldType = effect.blockType
                })
            end
        end
        
        -- Create spell impact effect on the caster to show the spell being blocked
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.3,
                color = {0.8, 0.2, 0.2, 0.5},
                particleCount = 5,
                radius = 15
            })
        end
        
        -- Skip further processing - tokens have already been returned by the blocking logic
        return
    end
    
    -- Check if the spell missed (for zone spells with zoneAnchor)
    if effect.missed then
        print(string.format("[MISSED] %s's %s missed due to range/elevation mismatch", 
            self.name, slot.spellType))
        
        -- Create whiff visual effect
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                duration = 0.3,
                color = {0.5, 0.5, 0.5, 0.3},
                particleCount = 3,
                radius = 10
            })
        end
    end
    
    -- Handle token dissipation from the dissipate keyword
    if effect.dissipate then
        local tokenType = effect.dissipateType or "any"
        local amount = effect.dissipateAmount or 1
        local tokensDestroyed = effect.tokensDestroyed or 0
        
        if tokensDestroyed > 0 then
            print("Destroyed " .. tokensDestroyed .. " " .. tokenType .. " tokens")
        else
            print("No matching " .. tokenType .. " tokens found to destroy")
        end
    end
    
    -- Handle burn effects from the burn keyword
    if effect.burnApplied then
        -- Apply burn status effect to target
        target.statusEffects.burn.active = true
        target.statusEffects.burn.duration = effect.burnDuration or 3.0
        target.statusEffects.burn.tickDamage = effect.burnTickDamage or 2
        target.statusEffects.burn.tickInterval = effect.burnTickInterval or 1.0
        target.statusEffects.burn.elapsed = 0
        target.statusEffects.burn.totalTime = 0
        
        print(string.format("[STATUS] %s is burning! (%d damage per %.1f sec for %.1f sec)",
            target.name, 
            target.statusEffects.burn.tickDamage,
            target.statusEffects.burn.tickInterval,
            target.statusEffects.burn.duration))
        
        -- Create initial burn effect
        if self.gameState and self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.6,
                color = {1.0, 0.3, 0.1, 0.8},
                particleCount = 12,
                radius = 35
            })
        end
    end
    
    -- Handle spell freeze effect from the freeze keyword
    if effect.freezeApplied then
        local targetSlot = effect.targetSlot or 2  -- Default to middle slot
        local freezeDuration = effect.freezeDuration or 2.0
        
        -- Check if the target slot exists and is active
        if self.spellSlots[targetSlot] and self.spellSlots[targetSlot].active then
            local slot = self.spellSlots[targetSlot]
            
            -- Add the frozen flag and timer
            slot.frozen = true
            slot.freezeTimer = freezeDuration
            
            print(slot.spellType .. " in slot " .. targetSlot .. " frozen for " .. freezeDuration .. " seconds")
            
            -- Add visual effect for the frozen spell
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlot]
                
                -- Create a clear visual effect to show freeze
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 1.2,
                    color = {0.3, 0.3, 0.8, 0.7},
                    particleCount = 20,
                    radius = 50
                })
            end
        else
            print("No active spell found in slot " .. targetSlot .. " to freeze")
        end
    end
    
    -- Handle disjoint effect (spell cancellation with mana destruction)
    if effect.disjoint then
        local targetSlot = effect.targetSlot or 0
        
        -- Handle the case where targetSlot is a function (from the compiled spell)
        if type(targetSlot) == "function" then
            -- Call the function with proper parameters
            local slot_func_result = targetSlot(self, target, spellSlot)
            -- Convert the result to a number (in case it returns a string)
            targetSlot = tonumber(slot_func_result) or 0
            print("Disjoint slot function returned: " .. targetSlot)
        end
        
        -- If targetSlot is 0 or invalid, find the first active slot
        if targetSlot == 0 or type(targetSlot) ~= "number" then
            for i, slot in ipairs(target.spellSlots) do
                if slot.active then
                    targetSlot = i
                    break
                end
            end
        end
        
        -- Ensure targetSlot is a valid number before comparison
        targetSlot = tonumber(targetSlot) or 0
        
        -- Check if the target slot exists and is active
        if targetSlot > 0 and targetSlot <= #target.spellSlots and target.spellSlots[targetSlot].active then
            local slot = target.spellSlots[targetSlot]
            
            -- Store data for feedback
            local spellName = slot.spellType or "spell"
            local tokenCount = #slot.tokens
            
            -- Destroy the mana tokens instead of returning them to the pool
            for _, tokenData in ipairs(slot.tokens) do
                local token = tokenData.token
                if token then
                    -- Mark the token as destroyed
                    token.state = "DESTROYED"
                    token.gameState = self.gameState  -- Give the token access to gameState for VFX
                    
                    -- Create immediate destruction VFX
                    if self.gameState.vfx then
                        self.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                            duration = 0.5,
                            color = {0.8, 0.6, 1.0, 0.7},  -- Purple for lunar theme
                            particleCount = 10,
                            radius = 20
                        })
                    end
                end
            end
            
            -- Cancel the spell, emptying the slot
            slot.active = false
            slot.progress = 0
            slot.tokens = {}
            
            -- Create visual effect at the spell slot position
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = target.y + slotYOffsets[targetSlot]
                
                -- Create a visual effect for the disjunction
                self.gameState.vfx.createEffect("disjoint_cancel", target.x, slotY, nil, nil)
            end
            
            print(self.name .. " disjointed " .. target.name .. "'s " .. spellName .. 
                  " in slot " .. targetSlot .. ", destroying " .. tokenCount .. " mana tokens")
        else
            print("No active spell found in slot " .. targetSlot .. " to disjoint")
        end
    end
    
    -- Create visual effect based on spell type
    if self.gameState.vfx then
        self.gameState.vfx.createSpellEffect(slot.spell, self, target)
    end
    
    -- Check if it's a shield spell that should persist in the spell slot
    if slot.spell.isShield or effect.isShield or isShieldSpell then
        -- Mark this as a shield spell (for the end of the function)
        isShieldSpell = true
        
        -- Mark the progress as completed
        slot.progress = slot.castTime  -- Mark as fully cast
        
        -- Debug shield creation process
        print("DEBUG: Creating shield from spell: " .. slot.spellType)
        
        -- Check if we have shieldCreated flag which means the shield was already
        -- created by the block keyword handler
        if not effect.shieldCreated then
            -- Extract shield params from effect or keywords
            local defenseType = "barrier"
            local blocks = {"projectile"}
            local manaLinked = true
            local reflect = false
            local hitPoints = nil
            
            -- Get shield parameters from effect or spell
            if effect.defenseType then
                defenseType = effect.defenseType
            elseif slot.spell.defenseType then
                defenseType = slot.spell.defenseType
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.type then
                defenseType = slot.spell.keywords.block.type
            end
            
            -- Get blocks from effect or spell
            if effect.blockTypes then
                blocks = effect.blockTypes
            elseif slot.spell.blockableBy then
                blocks = slot.spell.blockableBy
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.blocks then
                blocks = slot.spell.keywords.block.blocks
            end
            
            -- Get manaLinked from effect or spell
            if effect.manaLinked ~= nil then
                manaLinked = effect.manaLinked
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.manaLinked ~= nil then
                manaLinked = slot.spell.keywords.block.manaLinked
            end
            
            -- Get reflect from effect or spell
            if effect.reflect ~= nil then
                reflect = effect.reflect
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.reflect ~= nil then
                reflect = slot.spell.keywords.block.reflect
            end
            
            -- Get hitPoints from effect or spell
            if effect.shieldStrength then
                hitPoints = effect.shieldStrength
            elseif slot.spell.keywords and slot.spell.keywords.block and slot.spell.keywords.block.hitPoints then
                hitPoints = slot.spell.keywords.block.hitPoints
            end
            
            -- Use our central shield creation function to set up the shield
            local blockParams = {
                type = defenseType,
                blocks = blocks,
                reflect = reflect
                -- manaLinked and hitPoints no longer needed - token count is source of truth
            }
            
            print("DEBUG: Shield parameters:")
            print("DEBUG: - Type: " .. defenseType)
            print("DEBUG: - Reflect: " .. tostring(reflect))
            print("DEBUG: - Tokens: " .. #slot.tokens .. " (token count is shield strength)")
            
            -- Call the shield creation function - this centralizes all shield setup logic
            createShield(self, spellSlot, blockParams)
        end
        
        -- Force the isShield flag to be true for any shield spells
        -- This ensures tokens stay attached to the shield
        slot.isShield = true
        
        -- Apply elevation change if the shield spell includes that effect
        -- This handles both explicit elevation effects and those from the elevate keyword
        -- For Mist Veil, ensure elevate keyword is properly recognized
        if effect.setElevation or (effect.elevate and effect.elevate.active) or (slot.spell.keywords and slot.spell.keywords.elevate) then
            -- Determine the target for elevation changes based on keyword settings
            local elevationTarget
            
            -- Explicit targeting from keyword resolution
            if effect.elevationTarget then
                if effect.elevationTarget == "SELF" then
                    elevationTarget = self
                elseif effect.elevationTarget == "ENEMY" then
                    elevationTarget = target
                else
                    -- Default to self if target specification is invalid
                    elevationTarget = self
                    print("Warning: Unknown elevation target type: " .. tostring(effect.elevationTarget))
                end
            else
                -- Legacy behavior if no explicit target (for backward compatibility)
                elevationTarget = effect.setElevation == "GROUNDED" and target or self
            end
            
            -- Record if this is changing from AERIAL (for VFX)
            local wasAerial = elevationTarget.elevation == "AERIAL"
            
            -- Apply the elevation change
            local newElevation
            if effect.setElevation then
                newElevation = effect.setElevation
            elseif effect.elevate and effect.elevate.active then
                newElevation = "AERIAL"
            else
                newElevation = "AERIAL" -- Default to AERIAL if we got here without a specific elevation
            end
            
            elevationTarget.elevation = newElevation
            
            -- Set duration for elevation change if provided
            local elevationDuration
            if effect.elevationDuration then
                elevationDuration = effect.elevationDuration
            elseif effect.elevate and effect.elevate.duration then
                elevationDuration = effect.elevate.duration
            elseif slot.spell.keywords and slot.spell.keywords.elevate and slot.spell.keywords.elevate.duration then
                elevationDuration = slot.spell.keywords.elevate.duration
            end
            
            if elevationDuration and elevationTarget.elevation == "AERIAL" then
                elevationTarget.elevationTimer = elevationDuration
                print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation for " .. elevationDuration .. " seconds")
            else
                -- No duration specified, treat as permanent until changed by another spell
                elevationTarget.elevationTimer = 0
                print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation")
            end
            
            -- Create appropriate visual effect for elevation change
            if self.gameState.vfx then
                if effect.setElevation == "AERIAL" then
                    -- Effect for rising into the air (use specified VFX or default)
                    local vfxName = effect.elevationVfx or "emberlift"
                    self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
                elseif effect.setElevation == "GROUNDED" and wasAerial then
                    -- Effect for forcing down to the ground (use specified VFX or default)
                    local vfxName = effect.elevationVfx or "tidal_force_ground"
                    self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
                end
            end
        end
        
        -- Do not reset the slot - the shield will remain active
        return
    end
    
    -- Check for shield blocking based on attack type
    local attackBlocked = false
    local blockingShieldSlot = nil
    
    -- Only check for blocking if this is an offensive spell
    if slot.spell.attackType or slot.attackType then
        -- The attack type of the current spell (check both old and new schema)
        local attackType = slot.spell.attackType or slot.attackType
        print("Checking if " .. attackType .. " attack can be blocked by " .. target.name .. "'s shields")
        
        -- Add detailed shield debugging
        print("[SHIELD DEBUG] Shield check details:")
        print("[SHIELD DEBUG] - Spell: " .. (slot.spellType or "Unknown") .. " (Type: " .. attackType .. ")")
        print("[SHIELD DEBUG] - Target: " .. target.name)
        
        -- Count total shields
        local shieldCount = 0
        for i, targetSlot in ipairs(target.spellSlots) do
            if targetSlot.active and targetSlot.isShield then
                shieldCount = shieldCount + 1
            end
        end
        print("[SHIELD DEBUG] - Found " .. shieldCount .. " active shields")
        
        -- Check each of the target's spell slots for active shields
        for i, targetSlot in ipairs(target.spellSlots) do
            -- Debug print to check shield state
            if targetSlot.active and targetSlot.isShield then
                -- Use token count as the source of truth for shield strength
                local defenseType = targetSlot.defenseType or "unknown"
                
                print("Found shield in slot " .. i .. " of type " .. defenseType .. 
                      " with " .. #targetSlot.tokens .. " tokens")
                
                -- Check if the shield blocks appropriate attack types
                if targetSlot.blocksAttackTypes then
                    for blockType, _ in pairs(targetSlot.blocksAttackTypes) do
                        print("Shield blocks: " .. blockType)
                    end
                else
                    print("Shield does not have blocksAttackTypes defined!")
                end
            end
            
            -- Check if this shield can block this attack type
            local canBlock = false
            
            print("[SHIELD DEBUG] Checking if shield in slot " .. i .. " can block " .. attackType)
            
            -- Only process active shields with tokens
            if targetSlot.active and targetSlot.isShield and #targetSlot.tokens > 0 then
                -- Continue with detailed shield checks
                
                if targetSlot.blocksAttackTypes then
                    -- Old format - table with attackType as keys
                    canBlock = targetSlot.blocksAttackTypes[attackType]
                    print("[SHIELD DEBUG] - blocksAttackTypes check: " .. (canBlock and "YES" or "NO"))
                    
                    -- Additional debugging for blocksAttackTypes
                    print("[SHIELD DEBUG] - blocksAttackTypes contents:")
                    for blockType, value in pairs(targetSlot.blocksAttackTypes) do
                        print("[SHIELD DEBUG]   * " .. blockType .. ": " .. tostring(value))
                    end
                elseif targetSlot.blockTypes then
                    -- New format - array of attack types
                    print("[SHIELD DEBUG] - Checking blockTypes array")
                    for _, blockType in ipairs(targetSlot.blockTypes) do
                        print("[SHIELD DEBUG]   * " .. blockType)
                        if blockType == attackType then
                            canBlock = true
                            break
                        end
                    end
                    print("[SHIELD DEBUG] - blockTypes check: " .. (canBlock and "YES" or "NO"))
                else
                    print("[SHIELD DEBUG] - No block types defined!")
                end
            
            -- Complete debugging about the shield state
            print("[SHIELD DEBUG] Final check for slot " .. i .. ":")
            print("[SHIELD DEBUG] - Active: " .. (targetSlot.active and "YES" or "NO"))
            print("[SHIELD DEBUG] - Is Shield: " .. (targetSlot.isShield and "YES" or "NO"))
            print("[SHIELD DEBUG] - Tokens: " .. #targetSlot.tokens)
            print("[SHIELD DEBUG] - Can Block: " .. (canBlock and "YES" or "NO"))
            
            if targetSlot.active and targetSlot.isShield and
               #targetSlot.tokens > 0 and canBlock then
                
                -- This shield can block this attack type
                attackBlocked = true
                blockingShieldSlot = i
                
                print("[SHIELD DEBUG] ATTACK BLOCKED by shield in slot " .. i)
                
                -- Create visual effect for the block
                target.blockVFX = {
                    active = true,
                    timer = 0.5,  -- Duration of the block visual effect
                    x = target.x,
                    y = target.y
                }
                
                -- Create block effect using VFX system
                if self.gameState.vfx then
                    local shieldColor
                    if targetSlot.defenseType == "barrier" then
                        shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Yellow for barriers
                    elseif targetSlot.defenseType == "ward" then
                        shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
                    elseif targetSlot.defenseType == "field" then
                        shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
                    end
                    
                    self.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
                        duration = 0.5, -- Short block flash
                        color = shieldColor,
                        shieldType = targetSlot.defenseType
                    })
                end
                
                -- Determine how many hits to apply to the shield
                -- Check if this is a shield-breaker spell
                local shieldBreakPower = 1  -- Default: reduce shield by 1
                if slot.spell.shieldBreaker then
                    shieldBreakPower = slot.spell.shieldBreaker
                    print(string.format("[SHIELD BREAKER] %s's %s is a shield-breaker spell that deals %d hits to shields!",
                        self.name, slot.spellType, shieldBreakPower))
                end
                
                -- All shields consume ONE token when blocking (always just 1 token per hit)
                -- Never consume more than one token per hit for regular attacks
                local tokensToConsume = 1
                
                -- Shield breaker spells can consume more tokens
                if slot.spell.shieldBreaker and slot.spell.shieldBreaker > 1 then
                    tokensToConsume = math.min(slot.spell.shieldBreaker, #targetSlot.tokens)
                    print(string.format("[SHIELD BREAKER] Shield breaker consuming up to %d tokens", tokensToConsume))
                end
                
                -- Debug output to track token removal
                print(string.format("[SHIELD DEBUG] Before token removal: Shield has %d tokens", #targetSlot.tokens))
                print(string.format("[SHIELD DEBUG] Will remove %d token(s)", tokensToConsume))
                
                -- Only consume tokens up to the number we have
                tokensToConsume = math.min(tokensToConsume, #targetSlot.tokens)
                
                -- Return tokens back to the mana pool - ONE AT A TIME
                for i = 1, tokensToConsume do
                    if #targetSlot.tokens > 0 then
                        -- Get the last token
                        local lastTokenIndex = #targetSlot.tokens
                        local tokenData = targetSlot.tokens[lastTokenIndex]
                        
                        print(string.format("[SHIELD DEBUG] Consuming token %d from shield (token %d of %d)", 
                            tokenData.index, i, tokensToConsume))
                        
                        -- First make sure token state is updated
                        if tokenData.token then
                            print(string.format("[SHIELD DEBUG] Setting token %d state to FREE from %s", 
                                tokenData.index, tokenData.token.state or "unknown"))
                            tokenData.token.state = "FREE"
                        else
                            print("[SHIELD WARNING] Token has no token data object")
                        end
                        
                        -- Trigger animation to return this token to the mana pool
                        if target and target.manaPool then
                            print(string.format("[SHIELD DEBUG] Returning token %d to mana pool", tokenData.index))
                            target.manaPool:returnToken(tokenData.index)
                        else
                            print("[SHIELD ERROR] Could not return token - mana pool not found")
                        end
                        
                        -- Remove this token from the slot's token list
                        table.remove(targetSlot.tokens, lastTokenIndex)
                        print(string.format("[SHIELD DEBUG] Token %d removed from shield token list (%d tokens remaining)", 
                            tokenData.index, #targetSlot.tokens))
                    else
                        print("[SHIELD ERROR] Tried to consume token but shield has no more tokens!")
                        break -- Stop trying to consume tokens if there are none left
                    end
                end
                
                print("[SHIELD DEBUG] After token removal: Shield has " .. #targetSlot.tokens .. " tokens left")
                
                -- Print the blocked attack message with token info
                if tokensToConsume > 1 then
                    print(string.format("[BLOCK] %s's %s shield blocked %s's %s attack and leaked %d tokens! (%d tokens remaining)",
                        target.name, targetSlot.defenseType, self.name, attackType, tokensToConsume, #targetSlot.tokens))
                else
                    print(string.format("[BLOCK] %s's %s shield blocked %s's %s attack and leaked one token! (%d tokens remaining)",
                        target.name, targetSlot.defenseType, self.name, attackType, #targetSlot.tokens))
                end
                
                -- If the shield is depleted (no tokens left)
                local shieldDepleted = false
                
                -- Simple check based on actual token count (token count is the source of truth)
                -- All shields are mana-linked and use tokens for strength
                shieldDepleted = (#targetSlot.tokens <= 0)
                print("[SHIELD DEBUG] Is shield depleted? " .. (shieldDepleted and "YES" or "NO") .. " (" .. #targetSlot.tokens .. " tokens left)")
                
                -- Double-check token state to ensure shield is properly detected as depleted
                -- A shield is ONLY depleted when ALL tokens have been removed
                if #targetSlot.tokens == 0 then
                    -- Shield is now completely depleted (no tokens left)
                    print("[SHIELD DEBUG] Shield is now depleted - all tokens consumed")
                    shieldDepleted = true
                end
                
                if shieldDepleted then
                    print(string.format("[BLOCK] %s's %s shield has been broken!", target.name, targetSlot.defenseType))
                    print("[SHIELD DEBUG] Destroying shield in slot " .. i)
                    
                    -- Return any remaining tokens (for partially consumed shields)
                    print("[SHIELD DEBUG] Shield has " .. #targetSlot.tokens .. " remaining tokens to return")
                    
                    -- Important: Create a copy of the tokens table, as we'll be modifying it while iterating
                    local tokensToReturn = {}
                    for i, tokenData in ipairs(targetSlot.tokens) do
                        tokensToReturn[i] = tokenData
                    end
                    
                    -- Process each token
                    for _, tokenData in ipairs(tokensToReturn) do
                        print(string.format("[SHIELD DEBUG] Returning token %d to pool during shield destruction", tokenData.index))
                        
                        -- Make sure token state is FREE
                        if tokenData.token then
                            print(string.format("[SHIELD DEBUG] Setting token %d state to FREE from %s", 
                                tokenData.index, tokenData.token.state or "unknown"))
                            tokenData.token.state = "FREE"
                        end
                        
                        -- Return to mana pool
                        if target and target.manaPool then
                            target.manaPool:returnToken(tokenData.index)
                        else
                            print("[SHIELD ERROR] Could not return token - mana pool not found")
                        end
                    end
                    
                    -- Explicitly clear the tokens array
                    targetSlot.tokens = {}
                    
                    -- Reset slot completely to avoid half-broken shield state
                    print("[SHIELD DEBUG] Resetting slot " .. i .. " to empty state")
                    targetSlot.active = false
                    targetSlot.isShield = false
                    targetSlot.defenseType = nil
                    targetSlot.blocksAttackTypes = nil
                    targetSlot.blockTypes = nil  -- Clear block types array too
                    targetSlot.progress = 0
                    targetSlot.spellType = nil
                    targetSlot.spell = nil  -- Clear spell reference too
                    targetSlot.castTime = 0
                    targetSlot.tokens = {}  -- Already cleared above, but ensure it's empty
                    
                    -- Create shield break effect
                    if self.gameState.vfx then
                        self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                            duration = 0.7,
                            color = {1.0, 0.5, 0.5, 0.8},
                            particleCount = 15,
                            radius = 50
                        })
                    end
                end
                
                -- Check for reflection if this shield has that property
                if targetSlot.reflect then
                    print(string.format("[REFLECT] %s's shield reflected %s's attack back at them!",
                        target.name, self.name))
                    
                    -- Implement spell reflection (simplified version)
                    -- For now, just deal partial damage back to the caster
                    if effect.damage and effect.damage > 0 then
                        local reflectDamage = math.floor(effect.damage * 0.5) -- 50% reflection
                        self.health = self.health - reflectDamage
                        if self.health < 0 then self.health = 0 end
                        
                        print(string.format("[REFLECT] %s took %d reflected damage! (health: %d)", 
                            self.name, reflectDamage, self.health))
                            
                        -- Create reflected damage visual effect
                        if self.gameState.vfx then
                            self.gameState.vfx.createEffect("impact", self.x, self.y, nil, nil, {
                                duration = 0.5,
                                color = {0.8, 0.2, 0.8, 0.7}, -- Purple for reflection
                                particleCount = 10,
                                radius = 30
                            })
                        end
                    end
                end
                
                    -- We found a shield that blocked this attack, so stop checking other shields
                    break
                end -- End of if targetSlot.active and canBlock check
            end -- End of if targetSlot.active check
        end
    end
    
    -- If the attack was blocked, don't apply any effects
    if attackBlocked then
        -- Start return animation for tokens
        if #slot.tokens > 0 then
            for _, tokenData in ipairs(slot.tokens) do
                -- Trigger animation to return token to the mana pool
                self.manaPool:returnToken(tokenData.index)
            end
            
            -- Clear token list (tokens still exist in the mana pool)
            slot.tokens = {}
        end
        
        -- Reset slot
        slot.active = false
        slot.progress = 0
        slot.spellType = nil
        slot.castTime = 0
        
        return  -- Skip applying any effects
    end
    
    -- The old blocker system has been completely removed
    -- Shield functionality is now handled through the shield keyword system
    
    -- Apply damage
    if effect.damage and effect.damage > 0 then
        target.health = target.health - effect.damage
        if target.health < 0 then target.health = 0 end
        
        -- Special feedback for time-scaled damage from Full Moon Beam
        if effect.scaledDamage then
            print(target.name .. " took " .. effect.damage .. " damage from " .. slot.spellType .. 
                  " (scaled by cast time) (health: " .. target.health .. ")")
            
            -- Create a more dramatic visual effect for scaled damage
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                    duration = 0.8,
                    color = {0.5, 0.5, 1.0, 0.8},
                    particleCount = 20,
                    radius = 45
                })
            end
        else
            -- Regular damage feedback
            print(target.name .. " took " .. effect.damage .. " damage (health: " .. target.health .. ")")
            
            -- Create hit effect if not already created by the spell VFX
            if self.gameState.vfx and not effect.spellType then
                -- Default impact effect for non-specific damage
                self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                    duration = 0.5,
                    color = {1.0, 0.3, 0.3, 0.8}
                })
            end
        end
    end
    
    -- Apply position changes to the shared game state
    if effect.setPosition then
        -- Update the shared game rangeState
        if effect.setPosition == "NEAR" or effect.setPosition == "FAR" then
            self.gameState.rangeState = effect.setPosition
            print(self.name .. " changed the range state to " .. self.gameState.rangeState)
        end
    end
    
    if effect.setElevation then
        -- Determine the target for elevation changes based on keyword settings
        local elevationTarget
        
        -- Explicit targeting from keyword resolution
        if effect.elevationTarget then
            if effect.elevationTarget == "SELF" then
                elevationTarget = self
            elseif effect.elevationTarget == "ENEMY" then
                elevationTarget = target
            else
                -- Default to self if target specification is invalid
                elevationTarget = self
                print("Warning: Unknown elevation target type: " .. tostring(effect.elevationTarget))
            end
        else
            -- Legacy behavior if no explicit target (for backward compatibility)
            elevationTarget = effect.setElevation == "GROUNDED" and target or self
        end
        
        -- Record if this is changing from AERIAL (for VFX)
        local wasAerial = elevationTarget.elevation == "AERIAL"
        
        -- Apply the elevation change
        elevationTarget.elevation = effect.setElevation
        
        -- Set duration for elevation change if provided
        if effect.elevationDuration and effect.setElevation == "AERIAL" then
            elevationTarget.elevationTimer = effect.elevationDuration
            print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation for " .. effect.elevationDuration .. " seconds")
        else
            -- No duration specified, treat as permanent until changed by another spell
            elevationTarget.elevationTimer = 0
            print(elevationTarget.name .. " moved to " .. elevationTarget.elevation .. " elevation")
        end
        
        -- Create appropriate visual effect for elevation change
        if self.gameState.vfx then
            if effect.setElevation == "AERIAL" then
                -- Effect for rising into the air (use specified VFX or default)
                local vfxName = effect.elevationVfx or "emberlift"
                self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
            elseif effect.setElevation == "GROUNDED" and wasAerial then
                -- Effect for forcing down to the ground (use specified VFX or default)
                local vfxName = effect.elevationVfx or "tidal_force_ground"
                self.gameState.vfx.createEffect(vfxName, elevationTarget.x, elevationTarget.y, nil, nil)
            end
        end
    end
    
    -- Apply stun
    if effect.stun and effect.stun > 0 then
        target.stunTimer = effect.stun
        print(target.name .. " is stunned for " .. effect.stun .. " seconds")
        
        -- Create stun effect
        if self.gameState.vfx then
            self.gameState.vfx.createEffect("impact", target.x, target.y, nil, nil, {
                duration = 0.8,
                color = {1.0, 1.0, 0.2, 0.8}
            })
        end
    end
    
    -- Apply token lock
    if effect.lockToken and #target.manaPool.tokens > 0 then
        -- Get lock duration from effect or use default
        local lockDuration = effect.lockDuration or 5.0  -- Default to 5 seconds if not specified
        
        -- Find a random free token to lock
        local freeTokens = {}
        for i, token in ipairs(target.manaPool.tokens) do
            if token.state == "FREE" then
                table.insert(freeTokens, i)
            end
        end
        
        if #freeTokens > 0 then
            local tokenIndex = freeTokens[math.random(#freeTokens)]
            local token = target.manaPool.tokens[tokenIndex]
            
            -- Set token to locked state
            token.state = "LOCKED"
            token.lockDuration = lockDuration
            token.lockPulse = 0  -- Reset lock pulse animation
            
            -- Record the token type for better feedback
            local tokenType = token.type
            print("Locked a " .. tokenType .. " token in " .. target.name .. "'s mana pool for " .. lockDuration .. " seconds")
            
            -- Create lock effect at token position
            if self.gameState.vfx then
                self.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                    duration = 0.5,
                    color = {0.8, 0.2, 0.2, 0.7},
                    particleCount = 10,
                    radius = 30
                })
            end
        end
    end
    
    -- Apply spell delay (to target's spell)
    if effect.delaySpell and target.spellSlots[effect.delaySpell] and target.spellSlots[effect.delaySpell].active then
        -- Get the target spell slot
        local slot = target.spellSlots[effect.delaySpell]
        
        -- Calculate how much progress has been made (as a percentage)
        local progressPercent = slot.progress / slot.castTime
        
        -- Add additional time to the spell
        local delayTime = effect.delayAmount or 2.0  -- Use specified delay amount or default to 2.0 seconds
        local newCastTime = slot.castTime + delayTime
        
        -- Update the castTime and adjust the progress proportionally
        -- This effectively "pushes back" the progress bar
        slot.castTime = newCastTime
        slot.progress = progressPercent * slot.castTime
        
        print("Delayed " .. target.name .. "'s spell in slot " .. effect.delaySpell .. " by " .. delayTime .. " seconds")
        
        -- Create delay effect near the targeted spell slot
        if self.gameState.vfx then
            -- Calculate position of the targeted spell slot
            local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
            local slotY = target.y + slotYOffsets[effect.delaySpell]
            
            -- Create a more distinctive delay visual effect
            self.gameState.vfx.createEffect("impact", target.x, slotY, nil, nil, {
                duration = 0.9,
                color = {0.3, 0.3, 0.8, 0.7},
                particleCount = 15,
                radius = 40
            })
        end
    end
    
    -- Apply spell delay (to caster's own spell)
    if effect.delaySelfSpell then
        print("DEBUG - Eclipse Echo effect triggered with delaySelfSpell = " .. effect.delaySelfSpell)
        print("DEBUG - Caster: " .. self.name)
        print("DEBUG - Spell slots status:")
        for i, slot in ipairs(self.spellSlots) do
            print("DEBUG - Slot " .. i .. ": " .. (slot.active and "ACTIVE - " .. (slot.spellType or "unknown") or "INACTIVE"))
            if slot.active then
                print("DEBUG - Progress: " .. slot.progress .. " / " .. slot.castTime)
            end
        end
        
        -- When Eclipse Echo resolves, we need to target the middle spell slot
        -- Which in Lua is index 2 (1-based indexing)
        local targetSlotIndex = effect.delaySelfSpell  -- Should be 2 for the middle slot
        print("DEBUG - Targeting slot index: " .. targetSlotIndex)
        local targetSlot = self.spellSlots[targetSlotIndex]
        
        if targetSlot and targetSlot.active then
            -- Get the caster's spell slot
            local slot = targetSlot
            print("DEBUG - Found active spell in target slot: " .. (slot.spellType or "unknown"))
            
            -- Calculate how much progress has been made (as a percentage)
            local progressPercent = slot.progress / slot.castTime
            
            -- Add additional time to the spell
            local delayTime = effect.delayAmount or 2.0  -- Use specified delay amount or default to 2.0 seconds
            local newCastTime = slot.castTime + delayTime
            
            -- Update the castTime and adjust the progress proportionally
            -- This effectively "pushes back" the progress bar
            slot.castTime = newCastTime
            slot.progress = progressPercent * slot.castTime
            
            print(self.name .. " delayed their own spell in slot " .. targetSlotIndex .. " by " .. delayTime .. " seconds")
            
            -- Create delay effect near the caster's spell slot
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlotIndex]
                
                -- Create a more distinctive delay visual effect
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 0.9,
                    color = {0.3, 0.3, 0.8, 0.7},
                    particleCount = 15,
                    radius = 40
                })
            end
        else
            -- If there's no spell in the target slot, show a "fizzle" effect
            if self.gameState.vfx then
                -- Calculate position of the targeted spell slot
                local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                local slotY = self.y + slotYOffsets[targetSlotIndex]
                
                -- Create a small fizzle effect to show the spell had no effect
                self.gameState.vfx.createEffect("impact", self.x, slotY, nil, nil, {
                    duration = 0.3,
                    color = {0.3, 0.3, 0.4, 0.4},
                    particleCount = 5,
                    radius = 20
                })
                
                print("Eclipse Echo fizzled - no spell in " .. self.name .. "'s middle slot")
            end
        end
    end
    
    -- Only reset the spell slot and return tokens for non-shield spells
    -- For shield spells, keep tokens in the slot for mana-linking
    
    -- CRITICAL CHECK: For Mist Veil spell, it must be treated as a shield
    if slot.spellType == "Mist Veil" or slot.spell.id == "mist" then
        -- Force shield behavior for Mist Veil
        slot.isShield = true
        isShieldSpell = true
        effect.isShield = true
        
        -- Force tokens to SHIELDING state
        for _, tokenData in ipairs(slot.tokens) do
            if tokenData.token then
                tokenData.token.state = "SHIELDING"
            end
        end
        print("DEBUG: SPECIAL CASE - Enforcing Mist Veil shield behavior")
    end
    
    if not isShieldSpell and not slot.isShield and not effect.isShield then
        print("DEBUG: Returning tokens to mana pool - not a shield spell")
        -- Start return animation for tokens
        if #slot.tokens > 0 then
            -- Check one more time that no tokens are marked as SHIELDING
            local hasShieldingTokens = false
            for _, tokenData in ipairs(slot.tokens) do
                if tokenData.token and tokenData.token.state == "SHIELDING" then
                    hasShieldingTokens = true
                    break
                end
            end
            
            if not hasShieldingTokens then
                -- Safe to return tokens
                for _, tokenData in ipairs(slot.tokens) do
                    -- Trigger animation to return token to the mana pool
                    self.manaPool:returnToken(tokenData.index)
                end
                
                -- Clear token list (tokens still exist in the mana pool)
                slot.tokens = {}
            else
                print("DEBUG: Found SHIELDING tokens, preventing token return")
            end
        end
        
        -- Reset slot only if it's not a shield
        slot.active = false
        slot.progress = 0
        slot.spellType = nil
        slot.castTime = 0
    else
        print("DEBUG: Shield spell - keeping tokens in slot for mana-linking")
        -- For shield spells, the slot remains active and tokens remain in orbit
        -- Make sure slot is marked as a shield
        slot.isShield = true
        -- Mark tokens as SHIELDING again just to be sure
        for _, tokenData in ipairs(slot.tokens) do
            if tokenData.token then
                tokenData.token.state = "SHIELDING"
            end
        end
    end
end

return Wizard```

# Documentation

## docs/shield_system.md
# Manastorm Shield System

This document describes the shield system in Manastorm, including its design, implementation, and intended interactions with other game systems.

## Overview

Shields are a special type of spell that persist after casting, keeping their mana tokens in orbit until the shield is depleted by blocking attacks or manually freed by the caster. Shields can block specific types of attacks depending on their defense type.

## Shield Types

There are three types of shields, each blocking different attack types:

| Shield Type | Blocks                  | Visual Color |
|-------------|-------------------------|--------------|
| Barrier     | Projectiles, Zones      | Yellow       |
| Ward        | Projectiles, Remotes    | Blue         |
| Field       | Remotes, Zones          | Green        |

## Attack Types

Spells can have the following attack types:

| Attack Type | Description                                       | Blocked By             |
|-------------|---------------------------------------------------|------------------------|
| Projectile  | Physical projectile attacks                       | Barriers, Wards        |
| Remote      | Magical attacks at a distance                     | Wards, Fields          |
| Zone        | Area effect attacks                              | Barriers, Fields       |
| Utility     | Non-offensive spells that affect the caster       | Cannot be blocked      |

## Shield Lifecycle

1. **Casting Phase**: 
   - During casting, shield spells behave like normal spells
   - Mana tokens orbit normally in the spell slot
   - The slot is marked with `willBecomeShield = true` flag

2. **Completion Phase**:
   - When casting completes, tokens are marked as "SHIELDING"
   - The spell slot is marked with `isShield = true`
   - A shield visual effect is created
   - Shield strength is represented by the number of tokens used

3. **Active Phase**:
   - The shield remains active indefinitely until destroyed
   - Tokens continue to orbit slowly in the spell slot
   - The slot cannot be used for other spells while the shield is active

4. **Blocking Phase**:
   - When an attack is directed at the wizard, shield checks occur
   - If a shield can block the attack type, the attack is blocked
   - A token is consumed and returned to the pool
   - Shield strength decreases as tokens are consumed

5. **Destruction Phase**:
   - When a shield's last token is consumed, it is destroyed
   - The spell slot is reset and becomes available for new spells

## Implementation Details

### Shield Properties

Shields have the following properties:

- `isShield`: Flag that marks a spell slot as containing a shield
- `defenseType`: The type of shield ("barrier", "ward", or "field")
- `tokens`: Array of tokens powering the shield (token count = shield strength)
- `blocksAttackTypes`: Table specifying which attack types this shield blocks
- `blockTypes`: Array form of blocksAttackTypes for compatibility
- `reflect`: Whether the shield reflects damage back to the attacker (default: false)

### Block Keyword

The `block` keyword is used to create shields:

```lua
block = {
    type = "ward",            -- Shield type (barrier, ward, field)
    blocks = {"projectile", "remote"}, -- Attack types to block
    reflect = false           -- Whether to reflect damage back
}
```

### Shield Creation

Shields are created through the `createShield` function in wizard.lua:

```lua
createShield(wizard, spellSlot, blockParams)
```

This function:
1. Marks the slot as a shield
2. Sets the defense type and blocking properties
3. Marks tokens as "SHIELDING"
4. Uses token count as the source of truth for shield strength
5. Slows down token orbiting for shield tokens
6. Creates shield visual effects

### Shield Blocking Logic

When a spell is cast, shield checking occurs in the `castSpell` function:

1. The attack type of the spell is determined
2. Each of the target's spell slots is checked for active shields
3. If a shield can block the attack type and has tokens remaining, the attack is blocked
4. A token is consumed and returned to the mana pool
5. If all tokens are consumed, the shield is destroyed

## Future Extensions

Possible future extensions to the shield system:

1. **Passive Shield Effects**: Shields that provide ongoing effects while active
2. **Shield Combinations**: Special effects when multiple shield types are active
3. **Shield Enhancements**: Items or spells that improve shield properties
4. **Shield Regeneration**: Shields that recover strength over time
5. **Shield Reflection**: More elaborate reflection mechanics
6. **Shield Overloading**: Effects that trigger when a shield is destroyed

## Debugging

Common issues with shields and their solutions:

1. **Tokens not showing in shield**: Check that tokens are marked as "SHIELDING" and not returned to the pool
2. **Shield not blocking attacks**: Verify shield has tokens remaining and that it blocks the attack type
3. **Shield persisting after depletion**: Check the shield destruction logic in wizard.lua

Shield debugging can be enabled in wizard.lua with detailed output to trace shield behavior.

## Cross-Module Interactions

The shield system interacts with several other game systems:

- **Mana Pool**: Tokens from shields are returned here when consumed or destroyed
- **Spell Compiler**: Handles compiled shield spells with block keywords
- **VFX System**: Creates visual effects for shields, blocks, and breaks
- **Elevation System**: Some shields also change elevation (e.g., Mist Veil)

## Example Shield Spells

1. **Mist Veil** (Ward): Blocks projectiles and remotes, elevates caster
2. **Stone Wall** (Barrier): Blocks projectiles and zones, grounds caster
3. **Energy Field** (Field): Blocks remotes and zones, mana-intensive

## Known Issues and Limitations

- Shields cannot currently be stacked in the same slot
- Attack types are fixed and cannot be dynamically modified
- Shield strength is EXACTLY equal to token count

## Best Practices

When implementing new shield-related functionality:

1. Always mark tokens as "SHIELDING" after the spell completes, not during casting
2. Use the `createShield` function to ensure consistent shield initialization
3. Check for null/nil values in shield properties to prevent runtime errors
4. Remember that token count is the source of truth for shield strength
5. When checking if a shield is depleted, check if no tokens remain

## ./ComprehensiveDesignDocument.md
Game Title: Manastorm (working title)

Genre: Tactical Wizard Dueling / Real-Time Strategic Battler

Target Platforms: PC (initial), with possible future expansion to consoles

Core Pitch:

A high-stakes, low-input real-time dueling game where two spellcasters 
clash in arcane combat by channeling mana from a shared pool to queue 
spells into orbiting "spell slots." Strategy emerges from a shared 
resource economy, strict limitations on casting tempo, and deep 
interactions between positional states and spell types. Think Street 
Fighter meets Magic: The Gathering, filtered through an occult operating 
system.

Core Gameplay Loop:

Spell Selection Phase (Pre-battle)

Each player drafts a small set of spells from a shared pool.

These spells define their available actions for the match.

Combat Phase (Real-Time)

Players queue spells from their loadout (max 3 at a time).

Each spell channels mana from a shared pool and takes time to resolve.

Spells resolve in real-time after a fixed cast duration.

Cast spells release mana back into the shared pool, ramping intensity.

Positioning states (NEAR/FAR, GROUNDED/AERIAL) alter spell legality and 
effects.

Players win by reducing the opponent’s health to zero.

Key Systems & Concepts:

1. Spell Queue & Spell Slots

Each player has 3 spell slots.

Spells are queued into slots using hotkeys (Q/W/E or similar).

Each slot is visually represented as an orbit ring around the player 
character.

Channeled mana tokens orbit in these rings.

2. Mana Pool System

A shared pool of mana tokens floats in the center of the screen.

Tokens are temporarily removed when used to queue a spell.

Upon spell resolution, tokens return to the pool.

Tokens have types (e.g. FIRE, VOID, WATER), which interact with spell 
costs and effects.

The mana pool escalates tension by becoming more dynamic and volatile as 
spells resolve.

3. Token States

FREE: Available in the pool.

CHANNELED: Orbiting a caster while a spell is charging.

LOCKED: Temporarily unavailable due to enemy effects.

DESTROYED: Rare, removed from match entirely.

4. Positional States

Each player exists in binary positioning states:

Range: NEAR / FAR

Elevation: GROUNDED / AERIAL

Many spells can only be cast or take effect under certain conditions.

Players can be moved between states via spell effects.

5. Cast Feedback (Diegetic UI)

Each spell slot shows its cast time progression via a glowing arc rotating 
around the orbit.

Players can visually read how close a spell is to resolving.

No abstract bars; all feedback is embedded in the arena.

6. Spellbook System

Players have access to a limited loadout of spells during combat.

A separate spellbook UI (toggleable) shows full names, descriptions, and 
mechanics.

Core battlefield UI remains minimal to prioritize visual clarity and 
strategic deduction.

Visual & Presentation Goals

Combat is side-view, 2D.

Wizards are expressive but minimal sprites.

Mana tokens are vibrant, animated symbols.

All key mechanics are visible in-world (tokens, cast arcs, positioning 
shifts).

No HUD overload; world itself communicates state.

Design Pillars

Tactical Clarity: All decisions have observable consequences.

Strategic Literacy: Experienced players gain advantage by reading visual 
patterns.

Diegetic Information: The battlefield tells the story; minimal overlays.

Shared Economy, Shared Risk: Players operate in a closed loop that fuels 
both offense and defense.

Example Spells (Shortlist)

Ashgar the Emberfist:

Firebolt: Quick ranged hit, more damage at FAR.

Meteor Dive: Aerial finisher, hits GROUNDED enemies.

Combust Lock: Locks opponent mana token, punishes overqueueing.

Selene of the Veil:

Mist Veil: Projectile block, grants AERIAL.

Gravity Pin: Traps AERIAL enemies.

Eclipse Echo: Delays central queued spell.

Target Experience

Matches last 2–5 minutes.

Constant mental engagement without twitchy inputs.

Read-your-opponent mind games and counterplay at the forefront.

Replayable duels with high skill ceiling and unique matchups.

This document will evolve, but this version represents the intended 
holistic vision of the gameplay experience, tone, and structure of 
Manastorm.

## ./ModularSpellsRefactor.md
~Manastorm Spell System Refactor: Game Plan
1. The Vision: "Keyword Totality Doctrine"

Problem: Currently, spell behaviors (rules), visual effects (VFX), sound 
effects (SFX), and potentially UI descriptions are likely defined 
separately or hardcoded within each spell's logic in spells.lua and 
vfx.lua. This makes adding new spells complex, leads to inconsistencies, 
and doesn't enforce a unified visual language based on the game's rules 
(like Projectile vs. Remote, Fire vs. Ice).
Goal: We want a system where defining a spell is as simple as listing its 
core keywords (like "Fire", "Projectile", "Damage", "Knockdown"). These 
keywords become the single source of truth, dictating everything about 
that aspect of the spell:
How it behaves in the simulation (combat.lua).
How it looks (vfx.lua).
How it sounds.
How it's described in the UI (like a spellbook).
Why?:
Consistency: Spells with the "Projectile" keyword will always share core 
visual motion characteristics. Fire spells will always have a certain 
color palette and feel.
Maintainability: Change the "Fire" keyword's VFX once, and all fire spells 
update instantly.
Scalability: Adding new spells becomes much faster – just combine existing 
keywords or define a new keyword with its associated data. Designers can 
mix and match keywords easily.
Readability: Players learn the visual language tied to keywords, allowing 
them to understand spells diegetically, without needing explicit text 
popups during intense duels.
2. The Technical Approach: Refactor & Compilation

We will refactor the existing codebase by introducing two key new 
components and modifying existing ones:

keywords.lua (New File): This file will become a dictionary or library of 
all possible spell keywords. Each keyword entry will be pure data, 
defining the deltas or pieces it contributes:
behavior: How it modifies game state (e.g., { damageAmount = 10, 
damageType = "fire" }).
vfx: Visual parameters (e.g., { form = "orb", trail = "flare", color = {1, 
0.4, 0.2} }).
sfx: Sound cues (e.g., { cast = "fire_launch", impact = "explosion_soft" 
}).
description: A text fragment for UI tooltips (e.g., "Travels in a straight 
line...").
flags: Tags for categorization or synergies (e.g., { "ranged", "offensive" 
}).
spellCompiler.lua (New File): This file will contain a function, let's 
call it compileSpell(spellDefinition, keywordData).
It takes a basic spell definition (like { name = "Fireball", keywords = 
{"Fire", "Projectile", "Damage"}, cost = 1 } from the refactored 
spells.lua).
It looks up each keyword in keywords.lua.
It merges all the behavior, vfx, sfx, description, and flags data from 
those keywords into a single, complete "compiled spell" object. This 
object contains all the information needed to execute, render, and 
describe the spell.
spells.lua (Refactored): This file will be simplified dramatically. It 
will only contain the basic definitions: spell name, cost, cooldown, and 
the list of keywords it uses. All specific logic and VFX/SFX details will 
be removed.
combat.lua / Simulation Logic (Updated): Instead of reading logic directly 
from spells.lua, the simulation will now use the compiledSpell.behavior 
object generated by the compiler.
vfx.lua / Rendering Logic (Updated): Instead of having hardcoded effects 
per spell name, the VFX engine will read parameters from the 
compiledSpell.vfx object to dynamically create the correct visuals based 
on form, affinity, function, etc.
Sound Engine (Updated): Similarly, sound cues will be triggered based on 
the compiledSpell.sfx data.
UI (Future): Any spellbook or tooltip UI will read from 
compiledSpell.description and compiledSpell.flags.
3. The Process:

We'll tackle this iteratively:

Setup: Create the new files and basic structures.
Migrate Keywords: Define keywords in keywords.lua based on existing spell 
logic, starting with behavior.
Build Compiler: Implement the compileSpell function to merge keyword data.
Refactor spells.lua: Strip out old logic, use only keyword lists.
Integrate: Make the simulation use the compiled spells.
VFX/SFX Data: Add visual and audio data to keywords.
Render Integration: Update VFX/SFX systems to use compiled data.
UI Data: Add description/flags and prepare for UI integration.
This approach allows us to gradually shift functionality to the new system 
while ensuring the game remains functional (or close to it) throughout the 
process.~

## ./README.md
# Manastorm

A tactical wizard dueling game built with LÖVE (Love2D).

## Description

Manastorm is a real-time strategic battler where two spellcasters clash in arcane combat by channeling mana from a shared pool to queue spells into orbiting "spell slots." Strategy emerges from a shared resource economy, strict limitations on casting tempo, and deep interactions between positional states and spell types.

## Requirements

- [LÖVE](https://love2d.org/) 11.4 or later

## How to Run

1. Install LÖVE from [love2d.org](https://love2d.org/)
2. Clone this repository
3. Run the game:
   - On Windows: Drag the folder onto love.exe, or run `"C:\Program Files\LOVE\love.exe" path\to\Manastorm`
   - On macOS: Run `open -n -a love.app --args $(pwd)` from the Manastorm directory
   - On Linux: Run `love .` from the Manastorm directory

## Controls

### Player 1 (Ashgar)
- Q, W, E: Queue spells in spell slots 1, 2, and 3

### Player 2 (Selene)
- I, O, P: Queue spells in spell slots 1, 2, and 3

### General
- ESC: Quit the game

## Development Status

This is an early prototype with basic functionality:
- Two opposing wizards with health bars
- Shared mana pool with floating tokens
- Three spell slots per wizard with visual feedback
- Basic state representation (NEAR/FAR, GROUNDED/AERIAL)

## Next Steps

- Connect mana tokens to spell queueing
- Implement actual spell effects
- Add position changes
- Create proper spell descriptions
- Add collision detection
- Add visual effects

## ./SupportShieldsInModularSystem.md
~This is a classic case where a highly stateful, persistent effect (like 
an active shield) clashes a bit with a system designed for resolving 
discrete, immediate keyword effects.

Based on the codebase and the design goals, here's the breakdown and a 
plan to get shields working elegantly within the keyword framework:

Diagnosis of the Problem:

Keyword Execution vs. Persistent State: The core issue is that the block 
keyword's execute function (in keywords.lua) runs when the shield spell 
resolves, setting flags in the results table. However, the actual blocking 
needs to happen later, whenever an enemy spell hits. Furthermore, the 
shield needs to persist in the slot after its initial cast resolves, 
retaining its mana. The current keyword execution model is primarily 
designed for immediate effects, not setting up long-term states on a slot.

State Management Split: Because the keyword isn't fully setting up the 
persistent state, wizard.lua is still doing a lot of heavy lifting outside 
the keyword system:

The createShield helper function seems to contain logic that should 
ideally be driven by the keyword result.

The checkShieldBlock function runs during castSpell to detect if an 
incoming spell should be blocked, separate from the keyword resolution.

The Wizard:update function has logic to update orbiting shield tokens 
(which is good, but shows the state isn't fully managed just by spell 
resolution).

The Wizard:castSpell function has complex conditional logic around 
slot.isShield to prevent tokens from returning, which shouldn't be needed 
if the state is handled correctly.

Mist Veil's Custom executeAll: This is a symptom. Because the standard 
keyword compilation + execution wasn't sufficient to handle the specific 
combination of block and elevate along with the persistent shield state, a 
custom override was needed. This breaks the modularity goal.

Token State Timing: The spellCompiler's executeAll function marks tokens 
as SHIELDING during compilation. This is too early. Tokens should remain 
CHANNELED during the shield's cast time and only become SHIELDING when the 
shield activates.

Solution: Refined Shield Implementation Plan

Let's restructure how shields are handled to align better with the keyword 
system while respecting their persistent nature.

Phase 1: Redefine Keyword Responsibilities & State Setup

Ticket PROG-18: Refactor block Keyword Execution

Goal: Make the block keyword only responsible for setting up the intent to 
create a shield when its spell resolves.

Tasks:

In keywords.lua, modify the block.execute function. Instead of just 
setting simple flags, have it return a structured shieldParams table 
within the results. Example:

execute = function(params, caster, target, results)
    results.shieldParams = {
        createShield = true,
        defenseType = params.type or "barrier",
        blocksAttackTypes = params.blocks or {"projectile"},
        reflect = params.reflect or false
        -- Mana-linking is now the default, no need for a flag
    }
    return results
end
Use code with caution.
Lua
Remove the direct setting of results.isShield, results.defenseType, etc., 
from the keyword's execute.

AC: The block keyword's execute function returns a shieldParams table in 
the results.

Ticket PROG-19: Refactor Wizard:castSpell for Shield Activation

Goal: Handle the transition from a casting spell to an active shield state 
cleanly after keyword execution.

Tasks:

Modify Wizard:castSpell after the effect = spellToUse.executeAll(...) 
call.

Check if effect.shieldParams exists and effect.shieldParams.createShield 
== true.

If true:

Call the existing createShield function (or integrate its logic here), 
passing self (the wizard), spellSlot, and effect.shieldParams. This 
function will handle:

Setting slot.isShield = true.

Setting slot.defenseType, slot.blocksAttackTypes, slot.reflect.

Setting token states to SHIELDING.

Setting slot.progress = slot.castTime (shield is now fully "cast" and 
active).

Triggering the "Shield Activated" VFX.

Crucially: Do not reset the slot or return tokens for shield spells here. 
The slot remains active with the shield.

If not a shield spell (no effect.shieldParams), proceed with the existing 
logic for returning tokens and resetting the slot.

Remove the old if slot.willBecomeShield... logic from Wizard:update and 
the premature slot.isShield = true setting from Wizard:queueSpell. The 
state change happens definitively in castSpell now.

AC: Shield spells correctly transition to an active shield state managed 
by the slot. Tokens remain and are marked SHIELDING. Non-shield spells 
resolve normally. The createShield function is now properly triggered by 
the keyword result.

Phase 2: Integrate Blocking Check

Ticket PROG-20: Integrate checkShieldBlock into castSpell

Goal: Move the shield blocking check into the appropriate place in the 
spell resolution flow.

Tasks:

In Wizard:castSpell, before calling effect = spellToUse.executeAll(...) 
and before checking for the caster's own blockers (like the old Mist Veil 
logic, which should be removed per PROG-16), call the existing 
checkShieldBlock(spellToUse, attackType, target, self).

If blockInfo.blockable is true:

Trigger block VFX.

Call target:handleShieldBlock(blockInfo.blockingSlot, spellToUse) (from 
PROG-14 - assuming it exists or implement it now).

Crucially: Return early from castSpell. Do not execute the spell's 
keywords or apply any other effects.

Remove the separate checkShieldBlock call that happens later in the 
current castSpell.

AC: Incoming offensive spells are correctly checked against active shields 
before their effects are calculated or applied. Successful blocks prevent 
the spell and trigger shield mana consumption.

Ticket PROG-14: Implement Wizard:handleShieldBlock (If not already done, 
or refine it)

Goal: Centralize the logic for consuming mana from a shield when it 
blocks.

Tasks: (As defined previously)

Create Wizard:handleShieldBlock(slotIndex, blockedSpell).

Get the shieldSlot.

Check token count > 0.

Determine tokensToConsume based on blockedSpell.shieldBreaker (default 1).

Remove the correct number of tokens from shieldSlot.tokens.

Call self.manaPool:returnToken() for each consumed token index.

Trigger "token release" VFX.

If #shieldSlot.tokens == 0: Deactivate the slot, trigger "shield break" 
VFX, clear shield properties (isShield, etc.).

AC: Shield correctly consumes mana tokens upon blocking. Shield breaks 
when mana is depleted. Slot becomes available again.

Phase 3: Cleanup and Refinement

Ticket PROG-21: Refactor Mist Veil

Goal: Remove the custom executeAll from Spells.mist and define it purely 
using keywords.

Tasks:

In spells.lua, remove the executeAll function from Spells.mist.

Ensure its keywords table correctly defines both the block keyword 
parameters and the elevate keyword parameters.

keywords = {
    block = { type = "ward", blocks = {"projectile", "remote"} },
    elevate = { duration = 4.0 }
}
Use code with caution.
Lua
AC: Mist Veil works correctly using the standard keyword compilation and 
resolution process.

Ticket PROG-16: Remove Old Blocker System (As defined previously – remove 
wizard.blockers, related timers, and drawing code).

Ticket PROG-15: Visual Distinction for Shield Slots (As defined previously 
– update drawSpellSlots to show active shields differently).

Key Principle:

Keyword Sets Intent: The block keyword's execution signals intent to 
create a shield.

castSpell Establishes State: The castSpell function, upon seeing the 
shield intent in the results, performs the actions to make the shield 
state persistent on the slot (using createShield logic).

castSpell Checks Blocks: The castSpell function also checks the target for 
existing active shields before processing the incoming spell's effects.

handleShieldBlock Manages Breakdown: A dedicated function handles the 
consequences of a successful block (mana leak, shield break).

This approach keeps the keyword system focused on defining effects while 
acknowledging that shields require specific state management within the 
wizard/slot structure and interaction checks during spell resolution. It 
centralizes the shield creation logic previously duplicated or bypassed.~

## ./manastorm_codebase_dump.md

## Tickets/1-1-setup-new-files.md
Ticket #1: Setup Keyword & Compiler Files

Goal: Create the basic file structure for the new system.
Tasks:
Create a new file: keywords.lua. Initialize it with an empty Lua table 
Keywords = {}.
Create a new file: spellCompiler.lua. Define an empty function 
compileSpell(spellDef, keywordData) that currently just returns the input 
spellDef. Require this file where needed (e.g., main.lua or combat.lua).
Ensure both files are correctly loaded by the LÖVE project.
Deliverable: The two new Lua files exist and are integrated into the 
project structure without errors.

## Tickets/1-2-define-and-migrate-core-combat-keywords-behavior.md
~Define & Migrate Core Combat Keywords (Behavior Only)

Goal: Populate keywords.lua with initial keywords based on existing core 
combat mechanics found in spells.lua and combat.lua, focusing only on the 
behavior aspect.
Tasks:
Identify core combat actions currently hardcoded (e.g., dealing damage, 
applying stagger).
Define keyword entries in keywords.lua for: damage, stagger, burn (if 
exists).
Populate the behavior table for each. Example for damage: behavior = { 
dealsDamage = true, baseAmount = 10 } (adjust based on actual 
implementation).
Do not add VFX/SFX/description/flags yet.
Deliverable: keywords.lua contains definitions for damage, stagger, burn 
with populated behavior tables reflecting current game logic.~

## Tickets/1-3-define-and-migrate-movement-and-positioning-keywords-behavior.md
~Define & Migrate Movement/Positioning Keywords (Behavior Only)

Goal: Define keywords related to player/opponent movement and positioning.
Tasks:
Identify positioning logic (NEAR/FAR, GROUNDED/AERIAL).
Define keyword entries in keywords.lua for: elevate, ground, rangeShift, 
forcePull.
Populate the behavior table for each (e.g., behavior = { setsCasterState = 
"AERIAL" }, behavior = { togglesRange = true }).
Deliverable: keywords.lua includes definitions for movement/positioning 
keywords with populated behavior tables.~

## Tickets/1-4-define-and-migrate-resource-and-token-keywords-behavior.md
~Define & Migrate Resource/Token Keywords (Behavior Only)

Goal: Define keywords related to mana token manipulation.
Tasks:
Identify token logic (conjure, dissipate, shift, lock).
Define keyword entries in keywords.lua for: conjure, dissipate, 
tokenShift, lock.
Populate the behavior table for each (e.g., behavior = { addsTokens = 1, 
tokenType = "moon" }, behavior = { locksEnemyPool = true }).
Deliverable: keywords.lua includes definitions for resource/token keywords 
with populated behavior tables.~

## Tickets/1-5-define-and-migrate-casttime-defense-zone-keywords.md
~Define & Migrate Cast Time/Defense/Zone Keywords (Behavior Only)

Goal: Define keywords for remaining mechanics: cast time, defense, zone 
effects.
Tasks:
Identify logic for delay, accelerate, dispel, disjoint, freeze, echo, 
block, reflect, zoneAnchor, zoneMulti.
Define corresponding keyword entries in keywords.lua.
Populate the behavior table for each.
Deliverable: keywords.lua includes definitions for these remaining 
keywords with populated behavior tables.~

## Tickets/1-6-implement-spell-compiler-for-behavior.md
~ Implement Spell Compiler (Behavior Merging)

Goal: Make compileSpell function correctly merge behavior data from 
multiple keywords.
Tasks:
Implement the logic inside compileSpell(spellDef, keywordData) in 
spellCompiler.lua.
Loop through spellDef.keywords.
For each keyword, fetch its definition from keywordData.
Merge the behavior table from the keyword into a compiledSpell.behavior 
table. Define a clear merge strategy (e.g., simple table merge, last 
keyword wins for conflicting keys, or additive for things like damage 
bonuses).
The function should return a compiledSpell object containing name, cost, 
cooldown (from spellDef) and the merged behavior table.
Deliverable: compileSpell function correctly processes a sample spellDef 
and merges behavior tables from the specified keywords. Add unit tests if 
possible.~

## Tickets/1-7-refactor-spells-file.md
~ Refactor spells.lua

Goal: Convert all spell definitions in spells.lua to use the new 
keyword-only format.
Tasks:
Go through each spell definition in spells.lua.
Remove all hardcoded behavior logic, VFX calls, SFX triggers etc.
Replace them with a keywords = { ... } list, using the keywords defined in 
keywords.lua.
Keep name, cost, cooldown fields.
Deliverable: spells.lua contains only keyword-based definitions. All 
previous spell logic is now represented by keyword lists.~

## Tickets/1-8-integrate-compiled-spells.md
~Integrate Compiled Spells into Simulation

Goal: Modify the game simulation (combat.lua or relevant files) to use the 
compiled spell objects instead of the old spells.lua definitions.
Tasks:
Identify where spells are loaded/accessed for casting (e.g., main.lua on 
load, or combat.lua when casting starts).
Call compileSpell for each spell defined in spells.lua at game 
initialization. Store these compiled spell objects (e.g., in a 
CompiledSpells table).
Update functions like castSpell, applyEffect, etc., to read data from 
compiledSpell.behavior (e.g., if compiledSpell.behavior.dealsDamage then 
...) instead of checking spell names or reading directly from the old 
Spells table structure.
Deliverable: The game runs, spells can be cast, and their behavioral 
effects (damage, state changes, token manipulation) work correctly based 
on the data merged by the spellCompiler. Visuals and sounds might be 
broken or missing at this stage. Thorough testing is crucial here.~

## Tickets/2-1-refactor-block-keyword-execution.md
# Ticket PROG-18: Refactor block Keyword Execution

## Goal
Make the block keyword only responsible for setting up the intent to create a shield when its spell resolves.

## Tasks

1. In keywords.lua, modify the block.execute function. Instead of just setting simple flags, have it return a structured shieldParams table within the results. Example:

```lua
execute = function(params, caster, target, results)
    results.shieldParams = {
        createShield = true,
        defenseType = params.type or "barrier",
        blocksAttackTypes = params.blocks or {"projectile"},
        reflect = params.reflect or false
        -- Mana-linking is now the default, no need for a flag
    }
    return results
end
```

2. Remove the direct setting of results.isShield, results.defenseType, etc., from the keyword's execute.

## Acceptance Criteria
The block keyword's execute function returns a shieldParams table in the results.

## Tickets/2-2-refactor-wizard-castspell-for-shield-activation.md
# Ticket PROG-19: Refactor Wizard:castSpell for Shield Activation

## Goal
Handle the transition from a casting spell to an active shield state cleanly after keyword execution.

## Tasks

1. Modify Wizard:castSpell after the `effect = spellToUse.executeAll(...)` call.
   - Check if `effect.shieldParams` exists and `effect.shieldParams.createShield == true`.

2. If true:
   - Call the existing createShield function (or integrate its logic here), passing self (the wizard), spellSlot, and effect.shieldParams. This function will handle:
     - Setting `slot.isShield = true`.
     - Setting `slot.defenseType`, `slot.blocksAttackTypes`, `slot.reflect`.
     - Setting token states to SHIELDING.
     - Setting `slot.progress = slot.castTime` (shield is now fully "cast" and active).
     - Triggering the "Shield Activated" VFX.
   - Crucially: Do not reset the slot or return tokens for shield spells here. The slot remains active with the shield.

3. If not a shield spell (no effect.shieldParams), proceed with the existing logic for returning tokens and resetting the slot.

4. Remove the old `if slot.willBecomeShield...` logic from Wizard:update and the premature `slot.isShield = true` setting from Wizard:queueSpell. The state change happens definitively in castSpell now.

## Acceptance Criteria
Shield spells correctly transition to an active shield state managed by the slot. Tokens remain and are marked SHIELDING. Non-shield spells resolve normally. The createShield function is now properly triggered by the keyword result.

## Tickets/2-3-integrate-checkshieldblock-into-castspell.md
# Ticket PROG-20: Integrate checkShieldBlock into castSpell

## Goal
Move the shield blocking check into the appropriate place in the spell resolution flow.

## Tasks

1. In Wizard:castSpell, before calling `effect = spellToUse.executeAll(...)` and before checking for the caster's own blockers (like the old Mist Veil logic, which should be removed per PROG-16), call the existing `checkShieldBlock(spellToUse, attackType, target, self)`.

2. If `blockInfo.blockable` is true:
   - Trigger block VFX.
   - Call `target:handleShieldBlock(blockInfo.blockingSlot, spellToUse)` (from PROG-14 - assuming it exists or implement it now).
   - Crucially: Return early from castSpell. Do not execute the spell's keywords or apply any other effects.

3. Remove the separate checkShieldBlock call that happens later in the current castSpell.

## Acceptance Criteria
Incoming offensive spells are correctly checked against active shields before their effects are calculated or applied. Successful blocks prevent the spell and trigger shield mana consumption.

## Tickets/2-4-implement-wizard-handleshieldblock.md
# Ticket PROG-14: Implement Wizard:handleShieldBlock

## Goal
Centralize the logic for consuming mana from a shield when it blocks.

## Tasks

1. Create `Wizard:handleShieldBlock(slotIndex, blockedSpell)`.

2. Get the shieldSlot.

3. Check token count > 0.

4. Determine tokensToConsume based on blockedSpell.shieldBreaker (default 1).

5. Remove the correct number of tokens from shieldSlot.tokens.

6. Call `self.manaPool:returnToken()` for each consumed token index.

7. Trigger "token release" VFX.

8. If `#shieldSlot.tokens == 0`: Deactivate the slot, trigger "shield break" VFX, clear shield properties (isShield, etc.).

## Acceptance Criteria
Shield correctly consumes mana tokens upon blocking. Shield breaks when mana is depleted. Slot becomes available again.

## Tickets/2-5-refactor-mist-veil.md
# Ticket PROG-21: Refactor Mist Veil

## Goal
Remove the custom executeAll from Spells.mist and define it purely using keywords.

## Tasks

1. In spells.lua, remove the executeAll function from Spells.mist.

2. Ensure its keywords table correctly defines both the block keyword parameters and the elevate keyword parameters:

```lua
keywords = {
    block = { type = "ward", blocks = {"projectile", "remote"} },
    elevate = { duration = 4.0 }
}
```

## Acceptance Criteria
Mist Veil works correctly using the standard keyword compilation and resolution process.

## Tickets/2-6-remove-old-blocker-system.md
# Ticket PROG-16: Remove Old Blocker System

## Goal
Clean up the codebase by removing the deprecated blocker system that's now replaced by the shield keyword system.

## Tasks

1. Remove wizard.blockers property and related initialization.

2. Remove all logic that manages blocker timers.

3. Remove any drawing code related to the old blocker system.

4. Ensure all references to the old blocker system are removed or migrated to the new shield system.

## Acceptance Criteria
The old blocker system is completely removed from the codebase, and all shield functionality works through the new shield system without errors.

## Tickets/2-7-visual-distinction-for-shield-slots.md
# Ticket PROG-15: Visual Distinction for Shield Slots

## Goal
Improve UI clarity by visually distinguishing active shield slots from regular spell slots.

## Tasks

1. Update drawSpellSlots to show active shields differently.

2. Implement visual indicators for active shield slots, such as:
   - Different border color or glow
   - Shield icon or overlay
   - Distinct background color or pattern

3. Ensure the visual distinction scales appropriately with the UI and is visible at different game resolutions.

## Acceptance Criteria
Active shield slots are visually distinct from regular spell slots in a way that clearly communicates their status to the player.

