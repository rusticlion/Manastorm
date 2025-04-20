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
    if not slot or not slot.active or not slot.isShield then
        print(string.format("WARNING: handleShieldBlock called on invalid or non-shield slot %d for %s", slotIndex, wizard.name))
        return false
    end

    -- Determine how many tokens to remove based on incoming spell's shieldBreaker property
    local shieldBreakPower = (incomingSpell and incomingSpell.shieldBreaker) or 1
    local tokensToConsume = math.min(shieldBreakPower, #slot.tokens)

    print(string.format("[SHIELD BLOCK] %s's %s shield (slot %d) hit by %s (%d break power). Consuming %d token(s).", 
        wizard.name, slot.defenseType, slotIndex, incomingSpell.name, shieldBreakPower, tokensToConsume))

    -- Consume the tokens
    for i = 1, tokensToConsume do
        if #slot.tokens > 0 then
            -- Remove token data from the end (doesn't matter which one for shields)
            local removedTokenData = table.remove(slot.tokens)
            local removedTokenObject = removedTokenData.token
            
            print(string.format("[TOKEN LIFECYCLE] Shield Token (%s) consumed by block -> DESTROYED", 
                tostring(removedTokenObject.type)))
                
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
    
    -- Trigger shield hit VFX
    if wizard.gameState and wizard.gameState.vfx then
        wizard.gameState.vfx.createEffect("impact", wizard.x, wizard.y, nil, nil, {
            duration = 0.5,
            color = {0.8, 0.8, 0.2, 0.7},
            particleCount = 8,
            radius = 30
        })
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
    if not caster.gameState or not caster.gameState.vfx then
        return
    end
    
    -- Shield color based on type
    local shieldColor = ShieldSystem.getShieldColor(blockInfo.blockType)
    -- Add alpha for VFX
    shieldColor[4] = 0.7
    
    -- Create visual effect on the target to show the block
    caster.gameState.vfx.createEffect("shield", target.x, target.y, nil, nil, {
        duration = 0.5,
        color = shieldColor,
        shieldType = blockInfo.blockType
    })
    
    -- Create spell impact effect on the caster
    caster.gameState.vfx.createEffect("impact", caster.x, caster.y, nil, nil, {
        duration = 0.3,
        color = {0.8, 0.2, 0.2, 0.5},
        particleCount = 5,
        radius = 15
    })
end

return ShieldSystem