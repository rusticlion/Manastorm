-- keywords.lua
-- Defines all keywords and their behaviors for the spell system
--
-- IMPORTANT: Keyword execute functions should create and return events rather than directly modifying game state.
-- The events are collected and processed by the EventRunner module.
--
-- When creating a new keyword, follow this pattern:
--
-- Keywords.newKeyword = {
--     behavior = {
--         -- Define behavior metadata here to document the effect
--         descriptiveProperty = true,
--         targetType = Constants.TargetType.ENEMY,
--         category = "CATEGORY"
--     },
--     
--     -- Implementation function should return events
--     execute = function(params, caster, target, results)
--         -- Create your event(s) here 
--         results.myEvent = {
--             type = "EVENT_TYPE", 
--             source = "caster",
--             target = "enemy",
--             property = params.property
--         }
--         
--         -- Return the results table containing events
--         return results
--     end
-- }
--
-- See docs/combat_events.md for the event schema and types.

local Constants = require("core.Constants")
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

-- Target types for keywords (legacy support - new code should use Constants.TargetType directly)
Keywords.targetTypes = Constants.TargetType

-- ===== Core Combat Keywords =====

-- damage: Deals direct damage to a target
Keywords.damage = {
    -- Behavior definition
    behavior = {
        dealsDamage = true,
        targetType = Constants.TargetType.ENEMY,
        category = "DAMAGE",
        
        -- Default parameters
        defaultAmount = 0,
        defaultType = Constants.DamageType.GENERIC
    },
    
    -- Implementation function
    execute = function(params, caster, target, results, events)
        print(string.format("DEBUG_DAMAGE_EXEC: Slot %d castTimeModifier=%.4f", results.currentSlot, caster.spellSlots[results.currentSlot].castTimeModifier))

        local damageAmountFuncOrValue = params.amount or 0
        local calculatedDamage = 0
        local damageType = params.type or Constants.DamageType.GENERIC

        if type(damageAmountFuncOrValue) == "function" then
            -- It's a function, call it
            local currentSlotIndex = results.currentSlot -- Assign to local variable
            print(string.format("DEBUG_DAMAGE_EXEC_PCALL: Calling function with slot=%s", tostring(currentSlotIndex))) -- Log before pcall

            local success, funcResult = pcall(function()
                -- Call the function stored in damageAmountFuncOrValue
                -- Pass caster, target, and the local slot index
                return damageAmountFuncOrValue(caster, target, currentSlotIndex)
            end)

            if success then
                calculatedDamage = funcResult
            else
                print("Error evaluating damage function: " .. tostring(funcResult))
                calculatedDamage = 0 -- Default on error
            end
        else
            -- It's a static value
            calculatedDamage = damageAmountFuncOrValue
        end

        -- Generate event
        table.insert(events or {}, {
            type = "DAMAGE", source = "caster", target = "enemy",
            amount = calculatedDamage, damageType = damageType,
            scaledDamage = (type(params.amount) == "function") -- Keep scaledDamage flag based on original param type
        })

        -- Keep legacy results for now
        -- results.damage = calculatedDamage -- Store final calculated damage
        -- results.damageType = damageType
        -- results.scaledDamage = (type(params.amount) == "function")
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
        targetType = Constants.TargetType.ENEMY,
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
        setsElevationState = Constants.ElevationState.AERIAL,
        hasDefaultDuration = true,
        targetType = Constants.TargetType.SELF,
        category = "MOVEMENT",
        
        -- Default parameters
        defaultDuration = 5.0,
        defaultVfx = "emberlift"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.setElevation = Constants.ElevationState.AERIAL
        results.elevationDuration = params.duration or 5.0
        -- Store the target that should receive this effect
        results.elevationTarget = params.target or Constants.TargetType.SELF -- Default to SELF
        -- Store the visual effect to use
        results.elevationVfx = params.vfx or "emberlift"
        return results
    end
}

-- ground: Forces a wizard to GROUNDED state
Keywords.ground = {
    -- Behavior definition
    behavior = {
        setsElevationState = Constants.ElevationState.GROUNDED,
        canBeConditional = true,
        targetType = Constants.TargetType.ENEMY,
        category = "MOVEMENT"
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        -- Check if there's a conditional function
        if params.conditional and type(params.conditional) == "function" then
            -- Only apply grounding if the condition is met
            if params.conditional(caster, target) then
                results.setElevation = Constants.ElevationState.GROUNDED
                -- Store the target that should receive this effect
                results.elevationTarget = params.target or Constants.TargetType.ENEMY -- Default to ENEMY
            end
        else
            -- No condition, apply grounding unconditionally
            results.setElevation = Constants.ElevationState.GROUNDED
            results.elevationTarget = params.target or Constants.TargetType.ENEMY -- Default to ENEMY
        end
        
        return results
    end
}

-- rangeShift: Changes the range state (NEAR/FAR)
Keywords.rangeShift = {
    -- Behavior definition
    behavior = {
        setsRangeState = true,
        targetType = Constants.TargetType.SELF,
        category = "MOVEMENT",
        
        -- Default parameters
        defaultPosition = Constants.RangeState.NEAR 
    },
    
    -- Implementation function
    execute = function(params, caster, target, results)
        results.setPosition = params.position or Constants.RangeState.NEAR
        return results
    end
}

-- forcePull: Forces opponent to move to caster's range
Keywords.forcePull = {
    -- Behavior definition
    behavior = {
        forcesOpponentPosition = true,
        targetType = Constants.TargetType.ENEMY,
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
            local isFree = (token.status == Constants.TokenStatus.FREE) or (token.state == "FREE")
            local matchesType = (tokenType == "any" or token.type == tokenType)
            
            if isFree and matchesType then
                -- Request destruction animation using state machine if available
                if token.requestDestructionAnimation then
                    token:requestDestructionAnimation()
                else
                    -- Fallback to legacy direct state setting
                    token.state = "DESTROYED"
                end
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
    execute = function(params, caster, target, results, events)
        -- Generate LOCK_TOKEN event instead of setting results
        table.insert(events or {}, {
            type = "LOCK_TOKEN",
            source = "caster",
            target = "POOL_ENEMY", -- Target opponent's pool
            duration = params.duration or 5.0,
            tokenType = "any", -- Default to locking any token type
            amount = 1 -- Default to locking 1 token
            -- Optional: Could add params.tokenType or params.amount if needed
        })
        
        -- Keep legacy results for compatibility during transition (optional)
        -- results.lockToken = true
        -- results.lockDuration = params.duration or 5.0
        
        return results -- Return legacy results for now
    end
}

-- ===== Cast Time Keywords =====

-- slow: Applies a status effect that increases the cast time of the opponent's next spell
Keywords.slow = {
    -- Behavior definition
    behavior = {
        appliesStatusEffect = true,
        statusType = "slow",
        targetType = Constants.TargetType.ENEMY, -- Applies status to enemy wizard
        category = "TIMING",
        
        -- Default parameters
        defaultMagnitude = 1.0, -- How much to increase cast time by
        defaultDuration = 10.0, -- How long the slow effect waits for a cast
        defaultSlot = nil -- nil or 0 means next cast in any slot, 1/2/3 targets specific slot
    },
    
    -- Implementation function - Generates an APPLY_STATUS event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "APPLY_STATUS",
            source = "caster",
            target = "enemy", -- Target the enemy wizard entity
            statusType = "slow",
            magnitude = params.magnitude or 1.0, -- How much time to add
            duration = params.duration or 10.0, -- How long effect persists waiting for cast
            targetSlot = params.slot or nil -- Which slot to affect (nil for any)
        })
        
        -- No legacy results needed for this new approach
        return results -- Return empty results or results potentially modified by other keywords
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
    execute = function(params, caster, target, results, events)
        local targetSlotIndex = 0
        if params.slot and type(params.slot) == "function" then
            -- Evaluate the slot function if provided
            targetSlotIndex = params.slot(caster, target, results.currentSlot)
        elseif params.slot then
            targetSlotIndex = params.slot
        end
        targetSlotIndex = tonumber(targetSlotIndex) or 0 -- Ensure it's a number, default to 0
        
        -- Create a CANCEL_SPELL event with returnMana = false
        table.insert(events or {}, {
            type = "CANCEL_SPELL",
            source = "caster",
            target = "enemy_slot", -- Use string that EventRunner.resolveTarget understands
            slotIndex = targetSlotIndex, -- 0 means random active slot handled by EventRunner
            returnMana = false -- Key difference for disjoint
        })
        
        -- Remove legacy flag setting (for backward compatibility in transition)
        results.disjoint = nil
        results.targetSlot = nil
        
        return results -- Return results for backward compatibility
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
    
    -- Implementation function - New event-based pattern
    execute = function(params, caster, target, results, events)
        -- Create an ECHO event directly
        table.insert(events or {}, {
            type = "ECHO",
            source = "caster",
            target = "self_slot",
            slotIndex = results.currentSlot, -- Use the current slot or specified one
            delay = params.delay or 2.0
        })
        
        -- For backward compatibility, still add to results
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

return Keywords