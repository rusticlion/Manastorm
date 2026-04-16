-- SustainedSpellManager.lua
-- Centralized management system for sustained spells (shields, traps, etc.)

local Constants = require("core.Constants")
local Log = require("core.Log")
local SustainedSpellManager = {}

-- Track all active sustained spells
-- Each entry contains: {
--   id = unique identifier,
--   wizard = reference to wizard who cast the spell,
--   slotIndex = index of the spell slot,
--   spell = reference to the spell,
--   triggerData = trigger conditions (for traps),
--   effectData = effect to apply when triggered (for traps),
--   type = "shield" or "trap" or "generic"
-- }
SustainedSpellManager.activeSpells = {}

-- Generate a unique ID for a sustained spell
local function generateUniqueId(wizard, slotIndex)
    return wizard.name .. "_" .. slotIndex .. "_" .. os.time() .. "_" .. math.random(1000)
end

local function getOpponentWizard(gameState, wizard)
    if not gameState or not gameState.wizards then
        return nil
    end

    for _, candidate in ipairs(gameState.wizards) do
        if candidate ~= wizard then
            return candidate
        end
    end

    return nil
end

local function matchesTrapSignal(entry, triggerCondition, targetWizard)
    local casterWizard = entry and entry.wizard or nil
    local condition = entry and entry.triggerData and entry.triggerData.condition or nil
    if not casterWizard or not targetWizard or not condition or condition ~= triggerCondition then
        return false
    end

    local opponent = getOpponentWizard(casterWizard.gameState, casterWizard)
    if opponent ~= targetWizard then
        return false
    end

    if condition == "on_opponent_elevate"
        and targetWizard.elevation == Constants.ElevationState.AERIAL then
        print(string.format(
            "[SustainedManager] Trap triggered by opponent elevation: %s",
            targetWizard.elevation
        ))
        return true
    end

    if condition == "on_opponent_far"
        and casterWizard.gameState
        and casterWizard.gameState.rangeState == Constants.RangeState.FAR then
        print("[SustainedManager] Trap triggered by opponent being far")
        return true
    end

    if condition == "on_opponent_cast" then
        print("[SustainedManager] Trap triggered by opponent casting spell")
        return true
    end

    return false
end

local function dispatchTrapTrigger(entry, targetWizard)
    local casterWizard = entry and entry.wizard or nil
    local gameState = casterWizard and casterWizard.gameState or nil
    local runner = gameState and gameState.eventRunner or nil
    if not runner or type(runner.processEvents) ~= "function" then
        print("[SustainedManager] WARNING: Cannot trigger trap without game.eventRunner")
        return nil
    end

    return runner.processEvents({
        {
            type = "TRIGGER_TRAP",
            source = "caster",
            target = Constants.TargetType.ENEMY,
            slotIndex = entry.slotIndex,
            trapId = entry.id,
            trapEffect = entry.effectData,
            trapSpell = entry.spell,
            cleanupReason = "trap_triggered"
        }
    }, casterWizard, targetWizard, entry.slotIndex)
end

function SustainedSpellManager.notifyTrapTrigger(triggerCondition, targetWizard, context)
    if not triggerCondition or not targetWizard then
        return 0
    end

    local matchingIds = {}
    for id, entry in pairs(SustainedSpellManager.activeSpells) do
        if entry.type == "trap"
            and not entry.triggered
            and not entry.processed
            and matchesTrapSignal(entry, triggerCondition, targetWizard) then
            table.insert(matchingIds, id)
        end
    end

    local triggeredCount = 0
    for _, id in ipairs(matchingIds) do
        local entry = SustainedSpellManager.activeSpells[id]
        if entry then
            entry.triggered = true
            entry.processed = true

            print(string.format(
                "[SustainedManager] Trap triggered for %s slot %d via %s",
                entry.wizard.name,
                entry.slotIndex,
                triggerCondition
            ))

            local result = dispatchTrapTrigger(entry, targetWizard)
            if result and (result.eventsProcessed or 0) > 0 then
                triggeredCount = triggeredCount + 1
            else
                print("[SustainedManager] ERROR: Failed to dispatch trap trigger")
                if SustainedSpellManager.activeSpells[id] then
                    SustainedSpellManager.removeSustainedSpell(id)
                end
            end
        end
    end

    return triggeredCount
end

-- Apply field status effect to both wizards
local function applyFieldStatus(entry)
    if not entry or not entry.fieldStatus then return end

    local gameState = entry.wizard and entry.wizard.gameState
    if not gameState or not gameState.wizards then return end

    local runner = gameState.eventRunner
    if not runner or not runner.processEvents then
        print("[SustainedManager] WARNING: Cannot apply field status without game.eventRunner")
        return
    end

    local opponent = getOpponentWizard(gameState, entry.wizard)
    local spell = entry.spell or {}
    local slot = entry.wizard and entry.wizard.spellSlots and entry.wizard.spellSlots[entry.slotIndex]
    local manaCost = slot and slot.tokens and #slot.tokens or 0

    runner.processEvents({
        {
            type = "APPLY_STATUS",
            source = "caster",
            target = Constants.TargetType.SELF,
            statusType = entry.fieldStatus.statusType,
            duration = entry.fieldStatus.duration or 0,
            tickDamage = entry.fieldStatus.tickDamage,
            tickInterval = entry.fieldStatus.tickInterval,
            magnitude = entry.fieldStatus.magnitude,
            targetSlot = entry.fieldStatus.targetSlot,
            affinity = spell.affinity,
            attackType = spell.attackType or Constants.AttackType.UTILITY,
            visualShape = spell.visualShape,
            manaCost = manaCost,
            tags = { FIELD = true }
        },
        {
            type = "APPLY_STATUS",
            source = "caster",
            target = Constants.TargetType.ENEMY,
            statusType = entry.fieldStatus.statusType,
            duration = entry.fieldStatus.duration or 0,
            tickDamage = entry.fieldStatus.tickDamage,
            tickInterval = entry.fieldStatus.tickInterval,
            magnitude = entry.fieldStatus.magnitude,
            targetSlot = entry.fieldStatus.targetSlot,
            affinity = spell.affinity,
            attackType = spell.attackType or Constants.AttackType.UTILITY,
            visualShape = spell.visualShape,
            manaCost = manaCost,
            tags = { FIELD = true }
        }
    }, entry.wizard, opponent, entry.slotIndex)
end

-- Remove field status effect from both wizards
local function removeFieldStatus(entry)
    if not entry or not entry.fieldStatus then return end

    local gameState = entry.wizard and entry.wizard.gameState
    if not gameState or not gameState.wizards then return end

    local runner = gameState.eventRunner
    if not runner or not runner.processEvents then
        print("[SustainedManager] WARNING: Cannot remove field status without game.eventRunner")
        return
    end

    local opponent = getOpponentWizard(gameState, entry.wizard)

    runner.processEvents({
        {
            type = "REMOVE_STATUS",
            source = "caster",
            target = Constants.TargetType.SELF,
            statusType = entry.fieldStatus.statusType
        },
        {
            type = "REMOVE_STATUS",
            source = "caster",
            target = Constants.TargetType.ENEMY,
            statusType = entry.fieldStatus.statusType
        }
    }, entry.wizard, opponent, entry.slotIndex)
end

-- Add a sustained spell to the manager
function SustainedSpellManager.addSustainedSpell(wizard, slotIndex, spellData)
    if not wizard or not slotIndex or not spellData then
        print("[SustainedManager] Error: Missing required parameters")
        return nil
    end
    
    Log.debug("[DEBUG] SustainedSpellManager.addSustainedSpell: Spell data:")
    Log.debug("[DEBUG]   isSustained: " .. tostring(spellData.isSustained))
    Log.debug("[DEBUG]   trapTrigger exists: " .. tostring(spellData.trapTrigger ~= nil))
    Log.debug("[DEBUG]   trapWindow exists: " .. tostring(spellData.trapWindow ~= nil))
    Log.debug("[DEBUG]   trapEffect exists: " .. tostring(spellData.trapEffect ~= nil))
    Log.debug("[DEBUG]   fieldStatus exists: " .. tostring(spellData.fieldStatus ~= nil))
    
    -- Generate a unique ID for this sustained spell
    local uniqueId = generateUniqueId(wizard, slotIndex)
    
    -- Determine the type of sustained spell
    local spellType = Constants.DamageType.GENERIC
    if spellData.isShield then
        spellType = "shield"
    elseif spellData.trapTrigger then
        spellType = "trap"
    elseif spellData.fieldStatus then
        spellType = "field"
    end

    -- If a field already exists, remove it before adding the new one
    if spellType == "field" then
        for id, existing in pairs(SustainedSpellManager.activeSpells) do
            if existing.type == "field" then
                existing.wizard:resetSpellSlot(existing.slotIndex)
                break
            end
        end
    end
    
    -- Create the entry
    local entry = {
        id = uniqueId,
        wizard = wizard,
        slotIndex = slotIndex,
        spell = wizard.spellSlots[slotIndex].spell,
        type = spellType,
        creationTime = os.time()
    }
    
    -- Add trap-specific data if present
    if spellType == "trap" then
        entry.triggerData = spellData.trapTrigger or {}
        entry.effectData = spellData.trapEffect or {}
    end
    
    -- Add shield-specific data if present
    if spellType == "shield" then
        entry.shieldParams = spellData.shieldParams or {}
    end

    -- Add field-specific data if present
    if spellType == "field" then
        entry.fieldStatus = spellData.fieldStatus or {}
    end
    
    -- Store the entry in the activeSpells table
    SustainedSpellManager.activeSpells[uniqueId] = entry

    -- Apply field status immediately
    if spellType == "field" then
        applyFieldStatus(entry)
    end

    -- Log the addition
    print(string.format("[SustainedManager] Added %s '%s' for %s in slot %d",
        spellType, entry.spell.name or "unnamed spell", wizard.name, slotIndex))
    
    return uniqueId
end

-- Remove a sustained spell from the manager
function SustainedSpellManager.removeSustainedSpell(id)
    local entry = SustainedSpellManager.activeSpells[id]
    if not entry then
        print("[SustainedManager] Warning: Tried to remove non-existent sustained spell: " .. id)
        return false
    end
    
    -- Log removal
    print(string.format("[SustainedManager] Removed %s '%s' for %s in slot %d",
        entry.type, entry.spell.name or "unnamed spell", entry.wizard.name, entry.slotIndex))

    if entry.type == "field" then
        removeFieldStatus(entry)
    end

    -- Remove from the active spells table
    SustainedSpellManager.activeSpells[id] = nil
    
    return true
end

-- Update all active sustained spells
function SustainedSpellManager.update(dt)
    return
end

return SustainedSpellManager
