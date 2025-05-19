-- SustainedSpellManager.lua
-- Centralized management system for sustained spells (shields, traps, etc.)

local Constants = require("core.Constants")
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

-- Add a sustained spell to the manager
function SustainedSpellManager.addSustainedSpell(wizard, slotIndex, spellData)
    if not wizard or not slotIndex or not spellData then
        print("[SustainedManager] Error: Missing required parameters")
        return nil
    end
    
    print("[DEBUG] SustainedSpellManager.addSustainedSpell: Spell data:")
    print("[DEBUG]   isSustained: " .. tostring(spellData.isSustained))
    print("[DEBUG]   trapTrigger exists: " .. tostring(spellData.trapTrigger ~= nil))
    print("[DEBUG]   trapEffect exists: " .. tostring(spellData.trapEffect ~= nil))
    
    -- Generate a unique ID for this sustained spell
    local uniqueId = generateUniqueId(wizard, slotIndex)
    
    -- Determine the type of sustained spell
    local spellType = Constants.DamageType.GENERIC
    if spellData.isShield then
        spellType = "shield"
    elseif spellData.trapTrigger then
        spellType = "trap"
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
    
    -- Store the entry in the activeSpells table
    SustainedSpellManager.activeSpells[uniqueId] = entry
    
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
    
    -- Remove from the active spells table
    SustainedSpellManager.activeSpells[id] = nil
    
    return true
end

-- Update all active sustained spells
function SustainedSpellManager.update(dt)
    -- Count active spells by type
    local shieldCount = 0
    local trapCount = 0
    local genericCount = 0
    
    -- Spells to remove after iteration
    local spellsToRemove = {}
    
    -- Update each active spell
    for id, entry in pairs(SustainedSpellManager.activeSpells) do
        -- Debug: check what types of sustained spells we have
        if math.floor(os.time()) % 10 == 0 then -- Only log every 10 seconds to avoid spam
            print(string.format("[DEBUG] Sustained spell: id=%s, type=%s, spell=%s", 
                id, entry.type, entry.spell and entry.spell.name or "unknown"))
        end
        
        -- Count by type
        if entry.type == "shield" then
            shieldCount = shieldCount + 1
        elseif entry.type == "trap" then
            trapCount = trapCount + 1
        else
            genericCount = genericCount + 1
        end
        
        
        -- Process trap trigger conditions if this is a trap
        if entry.type == "trap" and entry.triggerData and not entry.triggered then
            local casterWizard = entry.wizard
            local targetWizard = nil
            
            -- Find target wizard (the other wizard)
            if casterWizard and casterWizard.gameState and casterWizard.gameState.wizards then
                for _, wizard in ipairs(casterWizard.gameState.wizards) do
                    if wizard ~= casterWizard then
                        targetWizard = wizard
                        break
                    end
                end
            end
            
            -- Evaluate trigger conditions
            if targetWizard and entry.triggerData.condition then
                local condition = entry.triggerData.condition
                local conditionMet = false
                
                -- Check elevation trigger condition
                if condition == "on_opponent_elevate" and targetWizard.elevation == Constants.ElevationState.AERIAL then
                    -- Enhancement idea: Track state changes rather than continuous state
                    -- For now, trigger continuously while the opponent is elevated
                    conditionMet = true
                    print(string.format("[SustainedManager] Trap triggered by opponent elevation: %s", targetWizard.elevation))
                end

                if condition == "on_opponent_far" and targetWizard.rangeState == Constants.RangeState.FAR then
                    conditionMet = true
                    print(string.format("[SustainedManager] Trap triggered by opponent being far"))
                end
                
                -- Check cast trigger condition
                if condition == "on_opponent_cast" and targetWizard.justCastSpellThisFrame then
                    conditionMet = true
                    print(string.format("[SustainedManager] Trap triggered by opponent casting spell"))
                end
                
                -- Check other trigger conditions as needed...
                -- Add more conditions here as the trap system expands
                
                -- If any condition is met, mark the trap as triggered
                if conditionMet then
                    entry.triggered = true
                    print(string.format("[SustainedManager] Trap triggered for %s slot %d", 
                        casterWizard.name, entry.slotIndex))
                end
            end
        end
        
        -- Process triggered traps
        if entry.type == "trap" and entry.triggered and not entry.processed then
            -- Mark as processed to avoid duplicate execution
            entry.processed = true
            
            local casterWizard = entry.wizard
            local targetWizard = nil
            
            -- Find target wizard (the other wizard)
            if casterWizard and casterWizard.gameState and casterWizard.gameState.wizards then
                for _, wizard in ipairs(casterWizard.gameState.wizards) do
                    if wizard ~= casterWizard then
                        targetWizard = wizard
                        break
                    end
                end
            end
            
            -- Execute trap effect via EventRunner
            if casterWizard and targetWizard and entry.effectData then
                print(string.format("[SustainedManager] Executing trap effect for %s slot %d", 
                    casterWizard.name, entry.slotIndex))
                
                -- Get Keywords module to execute the effect keywords
                local Keywords = nil
                if casterWizard.gameState and casterWizard.gameState.keywords then
                    Keywords = casterWizard.gameState.keywords
                else
                    print("[SustainedManager] ERROR: Cannot access Keywords module")
                    table.insert(spellsToRemove, id)
                    goto continue
                end
                
                -- Create events list to collect events from each keyword
                local events = {}
                
                -- Iterate through each keyword in the trap effect
                for keyword, params in pairs(entry.effectData) do
                    if Keywords[keyword] and type(Keywords[keyword].execute) == "function" then
                        local results = {}
                        
                        -- Call the keyword's execute function to generate events
                        -- Note: Different keywords expect different parameters, we pass consistent ones
                        -- and let each keyword pick what it needs
                        local updated_results = Keywords[keyword].execute(
                            params,          -- Parameters for the keyword
                            casterWizard,    -- Caster
                            targetWizard,    -- Target
                            results,         -- Results table (legacy)
                            events           -- Events list to populate
                        )
                        
                        -- Merge results for backward compatibility
                        if updated_results then
                            for k, v in pairs(updated_results) do
                                results[k] = v
                            end
                        end
                    else
                        print(string.format("[SustainedManager] WARNING: Keyword '%s' not found or not executable", 
                            tostring(keyword)))
                    end
                end
                
                -- Process generated events with EventRunner
                if #events > 0 then
                    -- Process events - Use pcall for safety
                    local result = { eventsProcessed = 0 }
                    local ok, err = pcall(function()
                        -- Get EventRunner at last possible moment
                        local EventRunner = require("systems.EventRunner")
                        result = EventRunner.processEvents(
                            events,         -- Events to process
                            casterWizard,   -- Caster
                            targetWizard,   -- Target
                            nil             -- No specific spell slot for effect execution
                        )
                    end)
                    
                    if not ok then
                        print("[SustainedManager] ERROR: Failed to process events: " .. tostring(err))
                    end
                    
                    print(string.format("[SustainedManager] Processed %d trap events", 
                        result and result.eventsProcessed or 0))
                else
                    print("[SustainedManager] WARNING: No events generated from trap effect")
                end
                
                -- Clean up the trap after execution
                local TokenManager = require("systems.TokenManager")
                
                -- Get the spell slot
                local slot = entry.wizard.spellSlots[entry.slotIndex]
                if slot then
                    -- Return tokens to the mana pool
                    if #slot.tokens > 0 then
                        TokenManager.returnTokensToPool(slot.tokens)
                        print(string.format("[SustainedManager] Returning %d tokens from triggered trap", 
                            #slot.tokens))
                    end
                    
                    -- Reset the spell slot
                    entry.wizard:resetSpellSlot(entry.slotIndex)
                end
                
                -- Mark for removal from manager
                table.insert(spellsToRemove, id)
            else
                print("[SustainedManager] ERROR: Missing wizard or effect data for trap execution")
                table.insert(spellsToRemove, id)
            end
        end

        ::continue::
    end
    
    -- Remove triggered spells after iteration
    for _, id in ipairs(spellsToRemove) do
        local entry = SustainedSpellManager.activeSpells[id]
        if entry then
            -- Remove the spell from the manager
            SustainedSpellManager.removeSustainedSpell(id)
        end
    end
    
    -- Log active spell counts (reduced frequency to avoid console spam)
    if math.floor(os.time()) % 5 == 0 then  -- Log every 5 seconds
        -- If we have at least one spell, log more details
        if shieldCount + trapCount + genericCount > 0 then
            for id, entry in pairs(SustainedSpellManager.activeSpells) do
                local wizardName = entry.wizard and entry.wizard.name or "unknown"
                local spellName = entry.spell and entry.spell.name or "unknown spell"
                print(string.format("  - %s: %s's %s in slot %d (id: %s)",
                    entry.type, wizardName, spellName, entry.slotIndex, id))
            end
        end
    end
end

return SustainedSpellManager