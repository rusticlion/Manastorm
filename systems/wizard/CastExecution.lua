-- systems/wizard/CastExecution.lua
-- Shared helpers for Wizard:castSpell orchestration.

local Constants = require("core.Constants")
local ShieldSystem = require("systems.ShieldSystem")
local TokenManager = require("systems.TokenManager")
local BlockedCastLifecycle = require("systems.wizard.BlockedCastLifecycle")
local Log = require("core.Log")

local CastExecution = {}

function CastExecution.findTargetWizard(caster)
    local gameState = caster and caster.gameState or nil
    if not gameState or not gameState.wizards then
        return nil
    end

    for _, wizard in ipairs(gameState.wizards) do
        if wizard ~= caster then
            return wizard
        end
    end

    return nil
end

function CastExecution.resolveSpellForCast(caster, slot, resolveCompiledSpell)
    if not slot or not slot.spell then
        return nil
    end

    local spellToUse = slot.spell

    if spellToUse.id and not spellToUse.executeAll then
        local compiledSpell = resolveCompiledSpell and resolveCompiledSpell(spellToUse.id, caster) or nil
        if compiledSpell then
            spellToUse = compiledSpell
            slot.spell = compiledSpell
            Log.debug("Using compiled spell: " .. spellToUse.id)
        else
            print("Warning: Falling back to original spell - could not get compiled version of " .. spellToUse.id)
        end
    end

    return spellToUse
end

function CastExecution.tryBlockedCast(caster, target, slot, spellSlot, spellToUse, fallbackSeconds)
    local attackType = spellToUse.attackType or Constants.AttackType.PROJECTILE
    local blockInfo = ShieldSystem.checkShieldBlock(spellToUse, attackType, target, caster)

    if not blockInfo.blockable then
        return nil, blockInfo
    end

    Log.debug(string.format("[SHIELD BLOCK] %s's %s was blocked by %s's %s shield!",
        caster.name, spellToUse.name, target.name, blockInfo.blockType or "unknown"))

    blockInfo.blockPoint = 0.75

    ShieldSystem.handleShieldBlock(target, blockInfo.blockingSlot, spellToUse, caster)

    local blockedResults = { blockInfo = blockInfo }
    BlockedCastLifecycle.begin(slot, fallbackSeconds)
    blockedResults.blockInfo.onBlockImpact = BlockedCastLifecycle.makeImpactCallback(
        caster,
        slot,
        spellSlot
    )

    local effect = spellToUse.executeAll(caster, target, blockedResults, spellSlot) or {}
    effect.blocked = true
    effect.blockType = blockInfo.blockType
    effect.blockingSlot = blockInfo.blockingSlot

    return effect, blockInfo
end

function CastExecution.dispatchCastComplete(caster, target, spellSlot, spellToUse, effect)
    local gameState = caster and caster.gameState or nil
    local eventRunner = gameState and gameState.eventRunner or nil
    if not eventRunner or type(eventRunner.processEvents) ~= "function" then
        return nil
    end

    effect = effect or {}

    return eventRunner.processEvents({
        {
            type = "CAST_COMPLETE",
            source = "caster",
            target = Constants.TargetType.SELF,
            slotIndex = spellSlot,
            spellId = spellToUse and spellToUse.id or nil,
            spell = spellToUse,
            blocked = effect.blocked or false,
            isShield = effect.isShield or false,
            isSustained = effect.isSustained or false
        }
    }, caster, target, spellSlot)
end

function CastExecution.finalizeCast(caster, slot, spellSlot, spellToUse, effect)
    effect = effect or {}

    if effect.blocked then
        Log.debug(string.format("[SHIELD] %s's %s was fully blocked by shield!",
            caster.name, spellToUse.name))
    end

    if effect.isShield or slot.isShield then
        if effect.isSustained and effect.isShield then
            Log.debug("[SUSTAINED] Note: Spell " .. spellToUse.id .. " has both isShield and isSustained flags - shields are already sustained")
        end
        return effect
    end

    if slot.sustainedId then
        Log.debug(string.format("[SUSTAINED] %s's spell in slot %d is active with ID: %s",
            caster.name,
            spellSlot,
            tostring(slot.sustainedId)))
        return effect
    end

    if effect.isSustained then
        print("[SUSTAINED ERROR] Sustained spell resolved without registration; falling back to normal slot cleanup")
    end

    if #slot.tokens > 0 then
        local hasShieldingTokens = false
        for _, tokenData in ipairs(slot.tokens) do
            if tokenData.token and TokenManager.validateTokenState(tokenData.token, Constants.TokenStatus.SHIELDING) then
                hasShieldingTokens = true
                break
            end
        end

        if effect.blocked then
            Log.debug("Returning tokens for blocked spell")
            TokenManager.returnTokensToPool(slot.tokens)
            slot.tokens = {}
        elseif not hasShieldingTokens then
            TokenManager.returnTokensToPool(slot.tokens)
            slot.tokens = {}
        else
            Log.debug("Found SHIELDING tokens, preventing token return")
        end
    end

    caster:resetSpellSlot(spellSlot)
    return effect
end

return CastExecution
