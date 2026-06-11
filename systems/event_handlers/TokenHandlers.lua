-- systems/event_handlers/TokenHandlers.lua
-- Mana pool and token resource event handlers for EventRunner.

local TokenHandlers = {}

function TokenHandlers.build(deps)
    local Constants = deps.Constants
    local Log = deps.Log
    local emitEffectEvent = deps.emitEffectEvent
    local getSlotVisualContext = deps.getSlotVisualContext
    local resolveTarget = deps.resolveTarget

    return {
        CONJURE_TOKEN = function(event, caster, target, spellSlot, results)
            local manaPool = caster.manaPool
            if not manaPool then return false end

            if caster.gameState and caster.gameState.vfx then
                local effectEvent = {
                    type = "EFFECT",
                    source = "caster",
                    target = "caster",
                    effectOverride = nil,
                    affinity = event.tokenType,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = event.amount,
                    tags = { CONJURE = true, RESOURCE = true },
                    tokenType = event.tokenType,
                    amount = event.amount
                }

                local specificEffect = "conjure" .. event.tokenType
                if Constants.VFXType[specificEffect:upper()] then
                    effectEvent.effectOverride = Constants.VFXType[specificEffect:upper()]
                end

                emitEffectEvent(effectEvent, caster, caster, spellSlot, results)
            end

            for _ = 1, event.amount do
                local assetPath = "assets/sprites/v2Tokens/" .. event.tokenType .. "-token.png"
                manaPool:addTokenWithAnimation(event.tokenType, assetPath, caster)
                results.tokensAffected = results.tokensAffected + 1
            end

            return true
        end,

        DISSIPATE_TOKEN = function(event, caster, target, spellSlot, results)
            local manaPool = caster.manaPool
            if not manaPool then return false end

            local tokensRemoved = 0

            for _, token in ipairs(manaPool.tokens) do
                local isFree = (token.status == Constants.TokenStatus.FREE)
                local matchesType = (event.tokenType == Constants.TokenType.ANY or token.type == event.tokenType)

                if isFree and matchesType then
                    token:requestDestructionAnimation()

                    tokensRemoved = tokensRemoved + 1
                    results.tokensAffected = results.tokensAffected + 1

                    if tokensRemoved >= event.amount then
                        break
                    end
                end
            end

            return true
        end,

        SHIFT_TOKEN = function(event, caster, target, spellSlot, results)
            local manaPool = caster.manaPool
            if not manaPool then return false end

            local tokensShifted = 0

            if event.tokenType == Constants.TokenType.RANDOM then
                local tokenTypes = Constants.getAllTokenTypes()

                for _, token in ipairs(manaPool.tokens) do
                    if token.status == Constants.TokenStatus.FREE then
                        local randomType = tokenTypes[math.random(#tokenTypes)]
                        local oldType = token.type

                        if randomType ~= oldType then
                            token.type = randomType
                            token.image = love.graphics.newImage("assets/sprites/v2Tokens/" .. randomType .. "-token.png")
                            tokensShifted = tokensShifted + 1
                            results.tokensAffected = results.tokensAffected + 1
                        end

                        if tokensShifted >= event.amount then
                            break
                        end
                    end
                end
            else
                for _, token in ipairs(manaPool.tokens) do
                    if token.status == Constants.TokenStatus.FREE and token.type ~= event.tokenType then
                        token.type = event.tokenType
                        token.image = love.graphics.newImage("assets/sprites/v2Tokens/" .. event.tokenType .. "-token.png")
                        tokensShifted = tokensShifted + 1
                        results.tokensAffected = results.tokensAffected + 1

                        if tokensShifted >= event.amount then
                            break
                        end
                    end
                end
            end

            return true
        end,

        LOCK_TOKEN = function(event, caster, target, spellSlot, results)
            local manaPool = caster.gameState and caster.gameState.manaPool or nil
            if not manaPool then
                print("ERROR: LOCK_TOKEN handler could not find shared manaPool via caster.gameState")
                return false
            end

            local freeTokens = {}
            for _, token in ipairs(manaPool.tokens) do
                if token.status == Constants.TokenStatus.FREE and (event.tokenType == "any" or token.type == event.tokenType) then
                    table.insert(freeTokens, token)
                end
            end

            if #freeTokens == 0 then
                return false
            end

            local tokensLocked = 0
            local lockAmount = event.amount or 1

            while tokensLocked < lockAmount and #freeTokens > 0 do
                local randomIndex = math.random(#freeTokens)
                local tokenToLock = table.remove(freeTokens, randomIndex)

                if tokenToLock.setState then
                    tokenToLock:setState(Constants.TokenStatus.LOCKED)
                end
                tokenToLock.lockTimer = event.duration
                tokensLocked = tokensLocked + 1
                results.tokensAffected = results.tokensAffected + 1

                emitEffectEvent({
                    type = "EFFECT",
                    source = event.source or "caster",
                    target = Constants.TargetType.SELF,
                    effectOverride = Constants.VFXType.RESOURCE_OVERLAY,
                    affinity = tokenToLock.type,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = 1,
                    tags = { RESOURCE = true },
                    rangeBand = caster.gameState and caster.gameState.rangeState or nil,
                    elevation = caster.elevation,
                    duration = event.duration or 0.8,
                    tokenType = tokenToLock.type,
                    vfxParams = {
                        x = tokenToLock.x,
                        y = tokenToLock.y
                    }
                }, caster, caster, spellSlot, results)
            end

            return tokensLocked > 0
        end,

        DISRUPT_AND_SHIFT = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then return false end

            local wizard = targetInfo.wizard
            local slotIndex = targetInfo.slotIndex

            if not slotIndex or slotIndex == 0 then
                local activeSlots = {}
                for i, slot in ipairs(wizard.spellSlots) do
                    if slot.active then
                        table.insert(activeSlots, i)
                    end
                end

                if #activeSlots > 0 then
                    slotIndex = activeSlots[math.random(#activeSlots)]
                else
                    return false
                end
            end

            local slot = wizard.spellSlots[slotIndex]
            if not slot or not slot.active or not slot.tokens or #slot.tokens == 0 then
                return false
            end

            local tokenIndexToRemove = math.random(#slot.tokens)
            local tokenDataToRemove = slot.tokens[tokenIndexToRemove]
            local removedTokenObject = tokenDataToRemove.token

            table.remove(slot.tokens, tokenIndexToRemove)

            if removedTokenObject then
                local newType = event.newType or Constants.TokenType.FIRE
                local oldType = removedTokenObject.type
                removedTokenObject.type = newType
                removedTokenObject.image = love.graphics.newImage("assets/sprites/v2Tokens/" .. newType .. "-token.png")
                results.tokensAffected = (results.tokensAffected or 0) + 1

                removedTokenObject:requestReturnAnimation()

                emitEffectEvent({
                    type = "EFFECT",
                    source = event.source or "caster",
                    target = Constants.TargetType.SELF,
                    effectOverride = Constants.VFXType.CONJURE_BASE,
                    affinity = newType,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = 1,
                    tags = { RESOURCE = true },
                    rangeBand = caster.gameState and caster.gameState.rangeState or nil,
                    elevation = caster.elevation,
                    duration = 0.8,
                    oldType = oldType,
                    newType = newType,
                    vfxParams = {
                        x = removedTokenObject.x,
                        y = removedTokenObject.y
                    }
                }, caster, wizard, slotIndex, results)
            else
                print("WARNING: Could not find token object to shift after removal from slot.")
            end

            wizard:checkFizzleOnTokenRemoval(slotIndex, removedTokenObject)

            return true
        end,

        CONSUME_TOKENS = function(event, caster, target, spellSlot, results)
            local targetInfo = resolveTarget(event, caster, target)
            if not targetInfo or not targetInfo.wizard then return false end

            local wizard = targetInfo.wizard
            local slotIndex = event.slotIndex or spellSlot
            local slot = wizard.spellSlots[slotIndex]
            if not slot or not slot.active or not slot.tokens or #slot.tokens == 0 then
                return false
            end

            local tokensConsumed = 0

            for _, tokenData in ipairs(slot.tokens) do
                if tokenData.token then
                    local shouldConsume = true
                    if event.amount ~= "all" and tokensConsumed >= event.amount then
                        shouldConsume = false
                    end

                    if shouldConsume then
                        tokenData.token:requestDestructionAnimation()

                        tokensConsumed = tokensConsumed + 1
                        results.tokensAffected = (results.tokensAffected or 0) + 1
                    end
                end
            end

            if tokensConsumed > 0 then
                local visualContext = getSlotVisualContext(wizard, slotIndex)
                emitEffectEvent({
                    type = "EFFECT",
                    source = event.source or "caster",
                    target = event.target,
                    effectOverride = Constants.VFXType.RESOURCE_OVERLAY,
                    affinity = event.affinity or visualContext.affinity,
                    attackType = Constants.AttackType.UTILITY,
                    manaCost = tokensConsumed,
                    tags = { RESOURCE = true },
                    rangeBand = wizard.gameState and wizard.gameState.rangeState or nil,
                    elevation = wizard.elevation,
                    duration = 0.8,
                    slotIndex = slotIndex,
                    tokensConsumed = tokensConsumed,
                    vfxParams = {
                        x = wizard.x,
                        y = wizard.y
                    }
                }, caster, wizard, slotIndex, results)
            end

            Log.debug(string.format("[CONSUME] Consumed %d tokens from slot %d", tokensConsumed, slotIndex))

            return tokensConsumed > 0
        end
    }
end

return TokenHandlers
