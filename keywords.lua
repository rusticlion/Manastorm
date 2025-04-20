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
        local applyDamage = true
        -- Check for conditional function
        if params.condition and type(params.condition) == "function" then
            applyDamage = params.condition(caster, target, results.currentSlot)
        end

        -- Only generate event if condition passed (or no condition)
        if applyDamage then
            local damageAmountFuncOrValue = params.amount or 0
            local calculatedDamage = 0
            local damageType = params.type or Constants.DamageType.GENERIC

            if type(damageAmountFuncOrValue) == "function" then
                -- It's a function, call it
                local currentSlotIndex = results.currentSlot -- Assign to local variable

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
        end

        -- Keep legacy results for now (might still be used elsewhere)
        -- results.damage = calculatedDamage 
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
    
    -- Implementation function - Generates APPLY_STATUS event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "APPLY_STATUS",
            source = "caster",
            target = "enemy",
            statusType = "burn",
            duration = params.duration or 3.0,
            tickDamage = params.tickDamage or 2,
            tickInterval = params.tickInterval or 1.0
        })
        return results
    end
}

-- stagger: Interrupts a spell and prevents recasting for a duration
Keywords.stagger = {
    -- Behavior definition
    behavior = {
        appliesStatusEffect = true, -- Assuming stagger applies a stun/daze status
        statusType = "stun",      -- Using "stun" status for simplicity
        interruptsSpell = true,    -- Stagger implies interruption
        targetType = "ENEMY",     -- Typically targets enemy
        category = "TIMING",
        
        -- Default parameters
        defaultDuration = 3.0
    },
    
    -- Implementation function - Generates APPLY_STATUS event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "APPLY_STATUS",
            source = "caster",
            target = "enemy",
            statusType = "stun", -- Using "stun" as the status effect
            duration = params.duration or 3.0
        })
        
        -- Optionally, could also add a CANCEL_SPELL event if stagger should interrupt
        -- table.insert(events or {}, { type = "CANCEL_SPELL", target = "enemy_slot", ... })
        
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
    
    -- Implementation function - Generates SET_ELEVATION event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "SET_ELEVATION",
            source = "caster",
            target = params.target or "self", -- Use specified target or default to self
            elevation = Constants.ElevationState.AERIAL,
            duration = params.duration or 5.0,
            vfx = params.vfx or "emberlift"
        })
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
        category = "MOVEMENT",
        defaultVfx = "tidal_force_ground" -- Add default VFX for ground
    },
    
    -- Implementation function - Generates SET_ELEVATION event
    execute = function(params, caster, target, results, events)
        local applyGrounding = true
        -- Check if there's a conditional function
        if params.conditional and type(params.conditional) == "function" then
            applyGrounding = params.conditional(caster, target)
        end
        
        if applyGrounding then
            table.insert(events or {}, {
                type = "SET_ELEVATION",
                source = "caster",
                target = params.target or "enemy", -- Use specified target or default to enemy
                elevation = Constants.ElevationState.GROUNDED,
                vfx = params.vfx or "tidal_force_ground"
            })
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
    
    -- Implementation function - Generates SET_RANGE event
    execute = function(params, caster, target, results, events)
        local targetPosition = params.position or Constants.RangeState.NEAR
        -- If position is a function, resolve it
        if type(targetPosition) == "function" then
             targetPosition = targetPosition(caster, target)
        end
        
        table.insert(events or {}, {
            type = "SET_RANGE",
            source = "caster",
            target = params.target or "self", -- Usually affects both, but can be targeted
            position = targetPosition
        })
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
    
    -- Implementation function - Generates FORCE_POSITION event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "FORCE_POSITION",
            source = "caster",
            target = "enemy" -- Force position applies to the enemy relative to caster
        })
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
    execute = function(params, caster, target, results, events)
        local tokenTypeParam = params.token or Constants.TokenType.FIRE -- Default if nil
        local amount = params.amount or 1
        local targetPool = params.target or "POOL_SELF" -- Default target pool

        events = events or {} -- Ensure events table exists

        if type(tokenTypeParam) == "table" then
            -- Handle array of token types
            for _, specificTokenType in ipairs(tokenTypeParam) do
                for i = 1, amount do -- Assuming amount applies per token type
                    table.insert(events, {
                        type = "CONJURE_TOKEN",
                        source = "caster",
                        target = targetPool,
                        tokenType = specificTokenType,
                        amount = 1 -- Conjure one of this specific type
                    })
                end
            end
        elseif type(tokenTypeParam) == "string" then
             -- Handle single token type string (original behavior)
             for i = 1, amount do
                 table.insert(events, {
                     type = "CONJURE_TOKEN",
                     source = "caster",
                     target = targetPool,
                     tokenType = tokenTypeParam,
                     amount = 1 -- Conjure one of this specific type
                 })
             end
        else
            print("WARN: Conjure keyword received unexpected token type: " .. type(tokenTypeParam))
        end
        
        -- Event-based system, no direct modification or legacy results needed
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
    
    -- Implementation function - Generates DISSIPATE_TOKEN event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "DISSIPATE_TOKEN",
            source = "caster",
            target = "pool", -- Target the shared pool
            tokenType = params.token or "any",
            amount = params.amount or 1,
            dissipateTarget = params.target or "enemy" -- Specify whose tokens to target within the pool
        })
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
    
    -- Implementation function - Generates SHIFT_TOKEN event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "SHIFT_TOKEN",
            source = "caster",
            target = "pool",
            tokenType = params.type or "fire",
            amount = params.amount or 1,
            shiftTarget = params.target or "self" -- Whose tokens to target within the pool
        })
        return results
    end
}

-- NEW KEYWORD: disruptAndShift
-- Removes a token from an opponent's channeling slot and changes its type
Keywords.disruptAndShift = {
    behavior = {
        disruptsChanneling = true,
        transformsTokens = true, -- Indicates it changes token type
        targetType = "SLOT_ENEMY", -- Targets an enemy spell slot
        category = "TOKEN",
        
        -- Default parameters
        defaultTargetType = "fire" -- Default type to shift to
    },
    
    -- Implementation function - Generates DISRUPT_AND_SHIFT event
    execute = function(params, caster, target, results, events)
        -- Determine target slot (using same logic as disjoint/cancel)
        local targetSlotIndex = 0
        if params.slot and type(params.slot) == "function" then
            targetSlotIndex = params.slot(caster, target, results.currentSlot)
        elseif params.slot then
            targetSlotIndex = params.slot
        end
        targetSlotIndex = tonumber(targetSlotIndex) or 0 -- 0 means random active

        -- Generate DISRUPT_AND_SHIFT event
        table.insert(events or {}, {
            type = "DISRUPT_AND_SHIFT",
            source = "caster",
            target = "enemy_slot", -- Target opponent's slot
            slotIndex = targetSlotIndex, -- 0 means random active slot handled by EventRunner
            newType = params.targetType or "fire" -- Type to shift the removed token to
        })
        
        return results
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
    
    -- Implementation function - Generates ACCELERATE_SPELL event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "ACCELERATE_SPELL",
            source = "caster",
            target = "self_slot", -- Target own spell slot
            slotIndex = params.slot or 0, -- 0 means current/last cast slot
            amount = params.amount or 1.0
        })
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
    
    -- Implementation function - Generates CANCEL_SPELL event
    execute = function(params, caster, target, results, events)
        local targetSlotIndex = 0
        if params.slot and type(params.slot) == "function" then
            targetSlotIndex = params.slot(caster, target, results.currentSlot)
        elseif params.slot then
            targetSlotIndex = params.slot
        end
        targetSlotIndex = tonumber(targetSlotIndex) or 0

        table.insert(events or {}, {
            type = "CANCEL_SPELL",
            source = "caster",
            target = "enemy_slot",
            slotIndex = targetSlotIndex,
            returnMana = true -- Key difference for dispel
        })
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
        return results
    end
}

-- freeze: Pauses a spell's progress for a duration
Keywords.freeze = {
    -- Behavior definition
    behavior = {
        pausesSpellProgress = true,
        targetType = "SLOT_ENEMY", -- Can be overridden by spell
        category = "TIMING",
        
        -- Default parameters
        defaultSlot = 2,  -- Default to middle slot
        defaultDuration = 2.0
    },
    
    -- Implementation function
    execute = function(params, caster, target, results, events)
        -- Get the slot to target (default to middle slot)
        local targetSlot = params.slot or 2  
        
        -- Determine the target entity (caster or enemy)
        local targetEntity = params.target or "enemy_slot" -- Default to enemy if not specified
        
        -- Make sure we have an events table
        events = events or {}
        
        -- Create a FREEZE_SPELL event directly, using the targetEntity
        table.insert(events, {
            type = "FREEZE_SPELL",
            source = "caster",
            target = targetEntity, -- Use the resolved target (e.g., "self" or "enemy_slot")
            slotIndex = targetSlot, -- Use specified slot or default 2
            duration = params.duration or 2.0
        })
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
    
    -- Implementation function - Generates CREATE_SHIELD event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "CREATE_SHIELD",
            source = "caster",
            target = "self_slot", -- Shields are created in the caster's slot
            slotIndex = results.currentSlot, -- Use the slot the spell was cast from
            defenseType = params.type or "barrier",
            blocksAttackTypes = params.blocks or {"projectile"},
            reflect = params.reflect or false
        })
        return results
    end
}

-- reflect: Reflects incoming spells
Keywords.reflect = {
    -- Behavior definition
    behavior = {
        appliesStatusEffect = true, -- Reflect handled as a status effect
        statusType = "reflect",
        targetType = "SELF",
        category = "DEFENSE",
        
        -- Default parameters
        defaultDuration = 3.0
    },
    
    -- Implementation function - Generates APPLY_STATUS event
    execute = function(params, caster, target, results, events)
         table.insert(events or {}, {
            type = "APPLY_STATUS",
            source = "caster",
            target = "self",
            statusType = "reflect",
            duration = params.duration or 3.0
        })
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
    
    -- Implementation function - Generates ZONE_ANCHOR event
    execute = function(params, caster, target, results, events)
        local anchorRange = "ANY"
        local anchorElevation = "ANY"
        
        if params.range then
            anchorRange = params.range
        elseif caster and caster.gameState then
            anchorRange = caster.gameState.rangeState
        end
        
        if params.elevation then
            anchorElevation = params.elevation
        elseif target then
            anchorElevation = target.elevation
        end
        
        local requireAll = params.requireAll
        if requireAll == nil then requireAll = true end
        
        table.insert(events or {}, {
            type = "ZONE_ANCHOR",
            source = "caster",
            target = "self_slot",
            slotIndex = results.currentSlot,
            anchorRange = anchorRange,
            anchorElevation = anchorElevation,
            requireAll = requireAll
        })
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
    
    -- Implementation function - Generates ZONE_MULTI event
    execute = function(params, caster, target, results, events)
        table.insert(events or {}, {
            type = "ZONE_MULTI",
            source = "caster",
            target = "self_slot",
            slotIndex = results.currentSlot
        })
        return results
    end
}

return Keywords