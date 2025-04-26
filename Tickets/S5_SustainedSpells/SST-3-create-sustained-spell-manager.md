# Ticket #SST-3: Create Sustained Spell Manager System

## Description
Implement the basic structure for a new system (SustainedSpellManager) that will track all active sustained spells (Shields and Traps).

## Tasks

### Create File (systems/SustainedSpellManager.lua)
- Create the module SustainedSpellManager
- Initialize `SustainedSpellManager.activeSpells = {}`. Use a structure that allows easy lookup and removal, perhaps keyed by a unique ID or a composite key like wizard_name .. "_" .. slotIndex. Example entry structure: `{ id = uniqueId, wizard = wizardRef, slotIndex = slotIndex, spell = compiledSpellRef, windowData = ..., triggerData = ..., effectData = ..., expiryTimer = ... }`
- Implement `SustainedSpellManager.addSustainedSpell(wizard, slotIndex, spellData)`:
  - Generate a unique ID
  - Extract relevant info from spellData (the results table from executeAll, containing isSustained, trapTrigger, trapWindow, trapEffect, shieldParams etc.)
  - Store the entry in activeSpells. Initialize expiry timers if spellData.trapWindow.duration exists
  - Log the addition: `print("[SustainedManager] Added spell '"..spellData.spell.name.."' for "..wizard.name.." slot "..slotIndex)`
- Implement `SustainedSpellManager.removeSustainedSpell(id)`: Finds and removes the entry from activeSpells. Log the removal
- Implement `SustainedSpellManager.update(dt)`:
  - Iterate through activeSpells
  - For spells with a duration in their windowData, decrement `expiryTimer = expiryTimer - dt`
  - (Placeholder) Log the current count of active sustained spells

### Initialize in main.lua
- `local SustainedSpellManager = require("systems.SustainedSpellManager")`
- Add `game.sustainedSpellManager = SustainedSpellManager` in love.load

## Acceptance Criteria
- SustainedSpellManager.lua exists with the specified functions and internal structure
- addSustainedSpell correctly stores data
- removeSustainedSpell removes the entry
- update iterates and logs basic info or decrements timers

## Design Notes
Storing a reference to the wizard and the slotIndex is critical for later cleanup.