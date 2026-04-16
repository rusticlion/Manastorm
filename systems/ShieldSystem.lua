-- ShieldSystem.lua
-- Centralized shield management system for Manastorm

local Constants = require("core.Constants")
local ShieldSystem = {}

-- Get appropriate shield color based on defense type
function ShieldSystem.getShieldColor(defenseType)
    local shieldColor = {0.8, 0.8, 0.8}  -- Default gray
    
    if defenseType == Constants.ShieldType.BARRIER then
        shieldColor = {1.0, 1.0, 0.3}    -- Yellow for barriers
    elseif defenseType == Constants.ShieldType.WARD then
        shieldColor = {0.3, 0.3, 1.0}    -- Blue for wards
    elseif defenseType == Constants.ShieldType.FIELD then
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
    
    -- DEFENSIVE CHECK: Don't create shield if slot already has one
    if slot.isShield then
        print("[SHIELD ERROR] Slot " .. spellSlot .. " already has a shield! Preventing duplicate creation.")
        return { shieldCreated = false, reason = "duplicate" }
    end
    
    -- Set shield parameters - simplified to use token count as the only source of truth
    slot.isShield = true
    
    -- Look for shield type in both parameters for compatibility
    slot.defenseType = blockParams.defenseType or blockParams.type or Constants.ShieldType.BARRIER
    
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
    
    -- Remove duplicate onBlock assignment from line 67
    
    -- Set which attack types this shield blocks
    slot.blocksAttackTypes = {}
    -- Support both `blocks` and `blocksAttackTypes` for compatibility
    local blockTypes = blockParams.blocks or blockParams.blocksAttackTypes or {Constants.AttackType.PROJECTILE}
    for _, attackType in ipairs(blockTypes) do
        slot.blocksAttackTypes[attackType] = true
    end
    
    -- Also store as array for compatibility
    slot.blockTypes = blockTypes
    
    -- ALL shields are mana-linked (consume tokens when hit) - simplified model
    
    -- Set reflection capability
    slot.reflect = blockParams.reflect or false
    
    -- Note: onBlock is already set above (line 48)
    
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
            target = Constants.TargetType.SELF,
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
    if attackType == Constants.AttackType.UTILITY then
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
function ShieldSystem.handleShieldBlock(wizard, slotIndex, incomingSpell, attackerWizard)
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

    local eventRunner = wizard.gameState and wizard.gameState.eventRunner or require("systems.EventRunner")
    local results = eventRunner.processEvents({
        {
            type = "SHIELD_BLOCK",
            source = Constants.TargetType.SELF,
            target = Constants.TargetType.SLOT_SELF,
            slotIndex = slotIndex,
            incomingSpell = incomingSpell,
            attackerWizard = attackerWizard or incomingSpell.caster or nil,
        }
    }, wizard, attackerWizard or incomingSpell.caster or nil, slotIndex)

    return results and (results.shieldBlocksResolved or 0) > 0 or false
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
-- DEPRECATED: This function is no longer needed as the block effects are now handled
-- directly in the EFFECT event processing with blockInfo. It's kept for backward
-- compatibility but will be removed in a future version.
function ShieldSystem.createBlockVFX(caster, target, blockInfo, spellInfo)
    print("[SHIELD SYSTEM] WARNING: ShieldSystem.createBlockVFX is deprecated")
    print("[SHIELD SYSTEM] Shield block visuals are now handled by the VFX system")
    
    -- No-op function, kept for backward compatibility
    return 
end

return ShieldSystem
