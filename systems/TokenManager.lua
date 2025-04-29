-- TokenManager.lua
-- Centralized management of token acquisition, positioning, and state transitions

local Constants = require("core.Constants")

local TokenManager = {}

-- Acquires tokens for a spell based on its mana cost
-- Returns success (boolean) and tokenData (list of tokens with positioning info)
function TokenManager.acquireTokensForSpell(wizard, slotIndex, manaCost)
    if not wizard or not wizard.manaPool then
        print("[TOKEN MANAGER] Error: Invalid wizard or missing manaPool reference")
        return false, {}
    end
    
    if not manaCost or type(manaCost) ~= "table" then
        print("[TOKEN MANAGER] Error: Invalid mana cost")
        return false, {}
    end
    
    -- Handle empty cost (free spells)
    if next(manaCost) == nil or #manaCost == 0 then
        print("[TOKEN MANAGER] Free spell (no mana cost)")
        return true, {} -- Success with no tokens
    end
    
    local manaPool = wizard.manaPool
    local requiredTokens = {}
    
    -- Check if mana cost is in array format (numbered indices) or key-value format
    local isArrayFormat = #manaCost > 0 or manaCost[1] ~= nil
    
    -- Handle array-style format (legacy format)
    if isArrayFormat then
        print("[TOKEN MANAGER] Processing array-style mana cost with " .. #manaCost .. " components")
        
        -- Process each component in the array
        for i, component in ipairs(manaCost) do
            if type(component) == "table" and component.type and component.amount then
                -- Handle {type="fire", amount=2} format
                local tokenType = component.type
                local count = component.amount
                
                for j = 1, count do
                    local token, tokenIndex = manaPool:findFreeToken(tokenType)
                    if token then
                        table.insert(requiredTokens, {
                            type = tokenType,
                            token = token,
                            index = tokenIndex
                        })
                    else
                        print("[TOKEN MANAGER] Error: Could not find free token of type " .. tokenType)
                        return false, {}
                    end
                end
            elseif type(component) == "string" then
                -- Handle "fire" format (single token) or "any" special case
                local tokenType = component
                
                if tokenType == "any" or tokenType == "ANY" then
                    -- Special case for "any" - try to find any token type
                    local foundAny = false
                    
                    -- Get all available token types
                    local availableTypes = Constants.getAllTokenTypes()
                    -- Shuffle the types to randomize selection
                    for i = #availableTypes, 2, -1 do
                        local j = math.random(i)
                        availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
                    end
                    
                    -- Try each token type in random order
                    for _, availableType in ipairs(availableTypes) do
                        local token, tokenIndex = manaPool:findFreeToken(availableType)
                        if token then
                            table.insert(requiredTokens, {
                                type = availableType,
                                token = token,
                                index = tokenIndex
                            })
                            foundAny = true
                            break
                        end
                    end
                    
                    if not foundAny then
                        print("[TOKEN MANAGER] Error: Could not find any free token for 'any' cost")
                        return false, {}
                    end
                else
                    -- Normal token type
                    local token, tokenIndex = manaPool:findFreeToken(tokenType)
                    
                    if token then
                        table.insert(requiredTokens, {
                            type = tokenType,
                            token = token,
                            index = tokenIndex
                        })
                    else
                        print("[TOKEN MANAGER] Error: Could not find free token of type " .. tokenType)
                        return false, {}
                    end
                end
            elseif type(component) == "number" then
                -- Handle numeric value (random tokens)
                local count = component
                for j = 1, count do
                    local foundRandom = false
                    
                    -- Get all available token types
                    local availableTypes = Constants.getAllTokenTypes()
                    -- Shuffle the types to randomize selection
                    for i = #availableTypes, 2, -1 do
                        local j = math.random(i)
                        availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
                    end
                    
                    -- Try each token type in random order
                    for _, tokenType in ipairs(availableTypes) do
                        local token, tokenIndex = manaPool:findFreeToken(tokenType)
                        if token then
                            table.insert(requiredTokens, {
                                type = tokenType,
                                token = token,
                                index = tokenIndex
                            })
                            foundRandom = true
                            break
                        end
                    end
                    
                    if not foundRandom then
                        print("[TOKEN MANAGER] Error: Could not find any free token for random cost")
                        return false, {}
                    end
                end
            else
                print("[TOKEN MANAGER] Warning: Unknown cost component type: " .. type(component))
            end
        end
    else
        -- Handle key-value format (new standardized format)
        print("[TOKEN MANAGER] Processing key-value style mana cost")
        
        -- Check if a specific mana cost can be paid from available tokens
        for tokenType, count in pairs(manaCost) do
            -- Skip special types like "description" or "zone"
            if tokenType ~= "description" and tokenType ~= "zone" and type(count) == "number" then
                for i = 1, count do
                    -- For "random" token type, pick any available token
                    if tokenType == "random" or tokenType == "any" then
                        local foundRandom = false
                        
                        -- Get all available token types
                        local availableTypes = Constants.getAllTokenTypes()
                        -- Shuffle the types to randomize selection
                        for i = #availableTypes, 2, -1 do
                            local j = math.random(i)
                            availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
                        end
                        
                        -- Try each token type in random order
                        for _, type in ipairs(availableTypes) do
                            local token, tokenIndex = manaPool:findFreeToken(type)
                            if token then
                                table.insert(requiredTokens, {
                                    type = type, 
                                    token = token, 
                                    index = tokenIndex
                                })
                                foundRandom = true
                                break
                            end
                        end
                        
                        if not foundRandom then
                            print("[TOKEN MANAGER] Error: Could not find any free token for 'random' cost")
                            return false, {}
                        end
                    else
                        -- Look for a specific token type
                        local token, tokenIndex = manaPool:findFreeToken(tokenType)
                        if token then
                            table.insert(requiredTokens, {
                                type = tokenType, 
                                token = token, 
                                index = tokenIndex
                            })
                        else
                            print("[TOKEN MANAGER] Error: Could not find free token of type " .. tokenType)
                            return false, {}
                        end
                    end
                end
            end
        end
    end
    
    -- Actually acquire the tokens (change their state)
    local acquiredTokens = {}
    
    for i, reservedToken in ipairs(requiredTokens) do
        -- Get the token and change its state
        local token = manaPool:getToken(reservedToken.type)
        if token then
            -- Set token references and ownership
            token.wizardOwner = wizard
            token.spellSlot = slotIndex
            token.tokenIndex = i
            
            -- Add token to the acquired list with positioning data
            table.insert(acquiredTokens, {
                token = token,
                index = i
            })
        else
            print("[TOKEN MANAGER] Error: Failed to acquire reserved token of type " .. reservedToken.type)
            -- Return all previously acquired tokens
            TokenManager.returnTokensToPool(acquiredTokens)
            return false, {}
        end
    end
    
    -- Position tokens in the spell slot
    TokenManager.positionTokensInSpellSlot(wizard, slotIndex, acquiredTokens)
    
    return true, acquiredTokens
end

-- Positions tokens in a spell slot with proper animation parameters
function TokenManager.positionTokensInSpellSlot(wizard, slotIndex, tokens)
    if not wizard or not slotIndex or not tokens then
        print("[TOKEN MANAGER] Error: Missing parameters for positionTokensInSpellSlot")
        return false
    end
    
    -- Initialize tokens with animation parameters
    local tokenCount = #tokens
    
    -- Calculate the visual parameters for the spell slot
    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
    local horizontalRadii = {80, 70, 60}
    local verticalRadii = {20, 25, 30}
    
    for i, tokenData in ipairs(tokens) do
        local token = tokenData.token
        
        -- Skip if token is invalid
        if not token then
            goto continue_token
        end
        
        -- Store token's current position as the starting point for animation
        token.startX = token.x
        token.startY = token.y
        
        -- Initialize animation parameters
        token.animTime = 0
        token.animDuration = 0.6  -- Animation duration in seconds
        token.isAnimating = true
        
        -- Set up references for the token
        token.wizardOwner = wizard
        token.spellSlot = slotIndex
        token.slotIndex = slotIndex
        token.tokenIndex = tokenData.index
        
        -- Calculate target position in the spell slot based on 3D positioning
        local targetY = wizard.y + slotYOffsets[slotIndex]
        local targetX = wizard.x
        
        -- Animation data
        token.targetX = targetX
        token.targetY = targetY
        
        -- 3D perspective data for rotation
        token.radiusX = horizontalRadii[slotIndex]
        token.radiusY = verticalRadii[slotIndex]
        
        -- Set proper token state
        if token.setState then
            token:setState(Constants.TokenStatus.CHANNELED)
        else
            -- Fallback for backward compatibility
            token.state = Constants.TokenState.CHANNELED
        end
        
        ::continue_token::
    end
    
    return true
end

-- Prepares tokens for use in a shield
function TokenManager.prepareTokensForShield(tokens)
    if not tokens then
        print("[TOKEN MANAGER] Error: No tokens provided to prepareTokensForShield")
        return false
    end
    
    for _, tokenData in ipairs(tokens) do
        local token = tokenData.token
        
        -- Skip if token is invalid
        if not token then
            goto continue_token
        end
        
        -- Set flag that this token will become a shield
        token.willBecomeShield = true
        
        ::continue_token::
    end
    
    return true
end

-- Marks tokens as being used in a shield (called after shield creation)
function TokenManager.markTokensAsShielding(tokens)
    if not tokens then
        print("[TOKEN MANAGER] Error: No tokens provided to markTokensAsShielding")
        return false
    end
    
    for _, tokenData in ipairs(tokens) do
        local token = tokenData.token
        
        -- Skip if token is invalid
        if not token then
            goto continue_token
        end
        
        -- Set proper token state using state machine if available
        if token.setState then
            token:setState(Constants.TokenStatus.SHIELDING)
        else
            -- Fallback for backward compatibility
            token.state = Constants.TokenState.SHIELDING
        end
        
        -- Clear the willBecomeShield flag since it's now a shield
        token.willBecomeShield = nil
        
        ::continue_token::
    end
    
    return true
end

-- Returns tokens to the mana pool
function TokenManager.returnTokensToPool(tokens)
    if not tokens then
        print("[TOKEN MANAGER] Error: No tokens provided to returnTokensToPool")
        return false
    end
    
    for _, tokenData in ipairs(tokens) do
        local token = tokenData.token
        
        -- Skip if token is invalid
        if not token then
            goto continue_token
        end
        
        -- Use token state machine if available
        if token.requestReturnAnimation then
            token:requestReturnAnimation()
        else
            -- Fallback for backward compatibility
            token.returning = true
            token.startX = token.x
            token.startY = token.y
            token.animTime = 0
            token.animDuration = 0.5
            
            -- Clear references
            token.wizardOwner = nil
            token.spellSlot = nil
        end
        
        ::continue_token::
    end
    
    return true
end

-- Destroys tokens (for disjunction effects)
function TokenManager.destroyTokens(tokens)
    if not tokens then
        print("[TOKEN MANAGER] Error: No tokens provided to destroyTokens")
        return false
    end
    
    for _, tokenData in ipairs(tokens) do
        local token = tokenData.token
        
        -- Skip if token is invalid
        if not token then
            goto continue_token
        end
        
        -- Use token state machine if available
        if token.requestDestructionAnimation then
            token:requestDestructionAnimation()
        else
            -- Fallback for backward compatibility
            token.state = Constants.TokenState.DESTROYED
        end
        
        ::continue_token::
    end
    
    return true
end

-- Checks if a spell should fizzle when a token is removed
function TokenManager.checkFizzleCondition(wizard, slotIndex, removedToken)
    if not wizard or not slotIndex then
        print("[TOKEN MANAGER] Error: Missing parameters for checkFizzleCondition")
        return false
    end
    
    local slot = wizard.spellSlots[slotIndex]
    if not slot or not slot.active then
        return false
    end
    
    -- If slot has no tokens left, reset it
    if not slot.tokens or #slot.tokens == 0 then
        print("[TOKEN MANAGER] Spell in slot " .. slotIndex .. " fizzled - no tokens left")
        wizard:resetSpellSlot(slotIndex)
        return true
    end
    
    -- Check if spell has lost a required token type (Law of Completion)
    if slot.spell and slot.spell.manaCost then
        local remainingTokensByType = {}
        
        -- Count remaining tokens by type
        for _, tokenData in ipairs(slot.tokens) do
            local tokenType = tokenData.token and tokenData.token.type or nil
            if tokenType then
                remainingTokensByType[tokenType] = (remainingTokensByType[tokenType] or 0) + 1
            end
        end
        
        -- Check against the required mana cost
        for tokenType, count in pairs(slot.spell.manaCost) do
            -- Skip special fields like "description"
            if tokenType ~= "description" and tokenType ~= "zone" then
                -- Handle random token type
                if tokenType == "random" then
                    local totalRemaining = 0
                    for _, typeCount in pairs(remainingTokensByType) do
                        totalRemaining = totalRemaining + typeCount
                    end
                    
                    if totalRemaining < count then
                        print("[TOKEN MANAGER] Spell in slot " .. slotIndex .. " fizzled - not enough tokens for 'random' cost")
                        wizard:resetSpellSlot(slotIndex)
                        return true
                    end
                else
                    -- Check specific token type
                    local remaining = remainingTokensByType[tokenType] or 0
                    if remaining < count then
                        print("[TOKEN MANAGER] Spell in slot " .. slotIndex .. " fizzled - not enough " .. tokenType .. " tokens")
                        wizard:resetSpellSlot(slotIndex)
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- Returns all tokens in a specific spell slot
function TokenManager.getTokensInSlot(wizard, slotIndex)
    if not wizard or not slotIndex or not wizard.spellSlots[slotIndex] then
        return {}
    end
    
    local slot = wizard.spellSlots[slotIndex]
    return slot.tokens or {}
end

-- Filters a list of tokens by type
function TokenManager.getTokensByType(tokens, tokenType)
    if not tokens or not tokenType then
        return {}
    end
    
    local filteredTokens = {}
    
    for _, tokenData in ipairs(tokens) do
        if tokenData.token and tokenData.token.type == tokenType then
            table.insert(filteredTokens, tokenData)
        end
    end
    
    return filteredTokens
end

-- Validates if a token is in the expected state
function TokenManager.validateTokenState(token, expectedState)
    if not token then
        return false, "Token is nil"
    end
    
    if not expectedState then
        return false, "Expected state is nil"
    end
    
    -- Check state using the status field
    return token.status == expectedState, 
           "Token state is " .. (token.status or "unknown") .. ", expected " .. expectedState
end

return TokenManager