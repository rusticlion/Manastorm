-- ShieldSystem.lua
-- Centralized shield management system for Manastorm

local ShieldSystem = {}

-- Get appropriate shield color based on defense type
function ShieldSystem.getShieldColor(defenseType)
    local shieldColor = {0.8, 0.8, 0.8}  -- Default gray
    
    if defenseType == "barrier" then
        shieldColor = {1.0, 1.0, 0.3}    -- Yellow for barriers
    elseif defenseType == "ward" then
        shieldColor = {0.3, 0.3, 1.0}    -- Blue for wards
    elseif defenseType == "field" then
        shieldColor = {0.3, 1.0, 0.3}    -- Green for fields
    end
    
    return shieldColor
end

-- Create a shield in the specified slot
function ShieldSystem.createShield(wizard, spellSlot, blockParams)
    -- Check that the slot is valid
    if not wizard.spellSlots[spellSlot] then
        print("[SHIELD ERROR] Invalid spell slot for shield creation: " .. tostring(spellSlot))
        return { shieldCreated = false }
    end
    
    local slot = wizard.spellSlots[spellSlot]
    
    -- Set shield parameters - simplified to use token count as the only source of truth
    slot.isShield = true
    
    -- Look for shield type in both parameters for compatibility
    slot.defenseType = blockParams.defenseType or blockParams.type or "barrier"
    
    -- Store the original spell completion
    slot.active = true
    slot.progress = slot.castTime -- Mark as fully cast
    
    -- Store the onBlock handler if provided
    slot.onBlock = blockParams.onBlock
    
    -- Debug log for onBlock handler
    if blockParams.onBlock then
        print("[SHIELD DEBUG] Shield creation: onBlock handler saved to slot")
    else
        print("[SHIELD DEBUG] Shield creation: No onBlock handler provided")
    end
    
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
    
    -- Set onBlock callback
    slot.onBlock = blockParams.onBlock or nil
    
    -- Get TokenManager module
    local TokenManager = require("systems.TokenManager")
    
    -- Mark tokens as shielding using TokenManager
    TokenManager.markTokensAsShielding(slot.tokens)
    
    -- Add additional shield-specific properties to tokens
    for _, tokenData in ipairs(slot.tokens) do
        local token = tokenData.token
        if token then
            -- Add specific shield type info to the token for visual effects
            token.shieldType = slot.defenseType
            -- Slow down the rotation speed for shield tokens
            if token.orbitSpeed then
                token.orbitSpeed = token.orbitSpeed * 0.5  -- 50% slower
            end
        end
    end
    
    -- Get shield color based on type
    local shieldColor = ShieldSystem.getShieldColor(slot.defenseType)
    
    -- Create shield effect using event system
    if wizard.gameState and wizard.gameState.eventRunner then
        local shieldEvent = {
            type = "EFFECT",
            source = "shield",
            target = "SELF",
            effectType = Constants.VFXType.SHIELD,
            duration = 1.0,
            vfxParams = {
                x = wizard.x,
                y = wizard.y,
                color = {shieldColor[1], shieldColor[2], shieldColor[3], 0.7},
                shieldType = slot.defenseType
            }
        }
        
        -- Process the event immediately
        wizard.gameState.eventRunner.processEvents({shieldEvent}, wizard, nil)
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

-- Check if a spell can be blocked by a shield
function ShieldSystem.checkShieldBlock(spell, attackType, defender, attacker)
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

-- Handle the effects of a spell being blocked by a shield
function ShieldSystem.handleShieldBlock(wizard, slotIndex, incomingSpell)
    local slot = wizard.spellSlots[slotIndex]
    if not slot or not slot.active then
        print(string.format("WARNING: handleShieldBlock called on invalid or inactive slot %d for %s", slotIndex, wizard.name))
        return false
    end
    
    -- Additional safety check for shield status
    if not slot.isShield then
        print(string.format("WARNING: handleShieldBlock called on non-shield slot %d for %s", slotIndex, wizard.name))
        return false
    end

    -- Safety check for incomingSpell
    if not incomingSpell then
        print("WARNING: handleShieldBlock called with nil incomingSpell")
        return false
    end

    -- Get defense type with safety check
    local defenseType = slot.defenseType or "unknown"

    -- Determine how many tokens to remove based on incoming spell's shieldBreaker property
    local shieldBreakPower = (incomingSpell and incomingSpell.shieldBreaker) or 1
    local tokensToConsume = math.min(shieldBreakPower, #slot.tokens)

    -- Get spell name with safety check
    local spellName = incomingSpell.name or "unknown spell"

    print(string.format("[SHIELD BLOCK] %s's %s shield (slot %d) hit by %s (%d break power). Consuming %d token(s).", 
        wizard.name, defenseType, slotIndex, spellName, shieldBreakPower, tokensToConsume))

    -- Consume the tokens
    for i = 1, tokensToConsume do
        if #slot.tokens > 0 then
            -- Remove token data from the end (doesn't matter which one for shields)
            local removedTokenData = table.remove(slot.tokens)
            local removedTokenObject = removedTokenData and removedTokenData.token
            
            -- Safety check for removed token object
            if removedTokenObject and removedTokenObject.type then
                print(string.format("[TOKEN LIFECYCLE] Shield Token (%s) consumed by block -> DESTROYED", 
                    tostring(removedTokenObject.type)))
            else
                print("[TOKEN LIFECYCLE] Shield Token (unknown type) consumed by block -> DESTROYED")
            end
                
            -- Mark the consumed token for destruction using TokenManager
            if removedTokenObject then
                -- Get TokenManager
                local TokenManager = require("systems.TokenManager")
                
                -- Create a token array for TokenManager to handle
                local tokenToDestroy = {
                    {token = removedTokenObject, index = 1}
                }
                
                -- Use TokenManager to destroy the token
                TokenManager.destroyTokens(tokenToDestroy)
                
                -- Call the wizard's centralized check *after* removing the token
                wizard:checkFizzleOnTokenRemoval(slotIndex, removedTokenObject)
            else
                print("WARNING: Shield block consumed a token reference that had no token object.")
                -- Still need to check fizzle even if token object missing
                wizard:checkFizzleOnTokenRemoval(slotIndex, nil)
            end
        else
            -- Should not happen if tokensToConsume calculation is correct, but break just in case
            print("WARNING: Tried to consume more tokens than available in shield slot.")
            break 
        end
    end
    
    -- Emit shield hit event for visual feedback through VisualResolver
    if wizard.gameState and wizard.gameState.eventRunner then
        local Constants = require("core.Constants")
        local shieldHitEvent = {
            type = "EFFECT",
            source = Constants.TargetType.TARGET,  -- defender is both source & target visually
            target = Constants.TargetType.TARGET,
            effectType = "shield_hit", -- logical tag for VisualResolver
            affinity = defenseType, -- Use defense type as affinity for color mapping
            tags = { SHIELD_HIT = true },
            shieldType = defenseType,
            posX = wizard.x,
            posY = wizard.y,
        }
        
        -- Process the event immediately
        wizard.gameState.eventRunner.processEvents({shieldHitEvent}, wizard, nil)
    end
    
    -- Add support for on-block effects
    -- Add safety check for slot.defenseType
    local defenseType = slot.defenseType or "unknown"
    print("[SHIELD DEBUG] Checking onBlock handler for " .. wizard.name .. "'s " .. defenseType .. " shield")
    
    if slot.onBlock then
        print("[SHIELD DEBUG] onBlock handler found, executing")
        local EventRunner = require("systems.EventRunner")
        local ok, blockEvents = pcall(slot.onBlock,
                                      wizard,          -- defender (owner of the shield)
                                      incomingSpell and incomingSpell.caster, -- attacker (may be nil)
                                      slotIndex,
                                      { blockType = defenseType })
        if ok and type(blockEvents) == "table" and #blockEvents > 0 then
            print("[SHIELD DEBUG] onBlock returned " .. #blockEvents .. " events, processing")
            EventRunner.processEvents(blockEvents, wizard, incomingSpell and incomingSpell.caster, slotIndex)
        elseif not ok then
            print("[SHIELD ERROR] Error executing onBlock handler: " .. tostring(blockEvents))
        else
            print("[SHIELD DEBUG] onBlock successful but no events returned or invalid events format")
            print("[SHIELD DEBUG] Return value: " .. type(blockEvents))
            if type(blockEvents) == "table" then
                print("[SHIELD DEBUG] Table length: " .. #blockEvents)
            end
        end
    else
        print("[SHIELD DEBUG] No onBlock handler found for this shield")
    end
    
    -- The checkFizzleOnTokenRemoval method handles the actual shield breaking (slot reset)
    
    return true
end

-- Update shield visuals and animations
function ShieldSystem.updateShieldVisuals(wizard, dt)
    -- This function will be expanded to handle shield pulse effects
    -- Currently a placeholder for future shield visual updates
    
    -- For each spell slot that contains a shield
    for i, slot in ipairs(wizard.spellSlots) do
        if slot.active and slot.isShield then
            -- Here we could add shield-specific visual updates
            -- Such as pulsing effects, particle emissions, etc.
        end
    end
end

-- Create block VFX for spell being blocked by a shield
function ShieldSystem.createBlockVFX(caster, target, blockInfo)
    if not caster.gameState or not caster.gameState.eventRunner then
        return
    end
    
    local Constants = require("core.Constants")
    -- Create a batch of VFX events
    local events = {}
    
    -- Emit shield hit event at target position using VisualResolver
    table.insert(events, {
        type = "EFFECT",
        source = Constants.TargetType.TARGET,  -- defender is both source & target visually
        target = Constants.TargetType.TARGET,  -- defender is target
        effectType = "shield_hit", -- logical tag for VisualResolver
        affinity = blockInfo.blockType, -- Use defense type for color mapping
        tags = { SHIELD_HIT = true },
        shieldType = blockInfo.blockType,
        posX = target.x,
        posY = target.y,
    })
    
    -- Add impact feedback at caster position
    table.insert(events, {
        type = "EFFECT",
        source = Constants.TargetType.CASTER, -- caster is source
        target = Constants.TargetType.CASTER, -- and target for feedback
        effectType = Constants.VFXType.IMPACT_BASE,
        affinity = "fire",  -- Red feedback for blocked spell
        tags = { SHIELD_HIT = true },
        scale = 0.7,        -- Smaller feedback effect
        posX = caster.x,
        posY = caster.y,
    })
    
    -- Process all events at once
    caster.gameState.eventRunner.processEvents(events, caster, target)
end

return ShieldSystem