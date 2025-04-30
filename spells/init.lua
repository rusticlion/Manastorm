-- spells/init.lua
-- Main entry point for the spells module

local Constants = require("core.Constants")
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local expr = require("expr")
local ManaHelpers = require("systems.ManaHelpers")
local Schema = require("spells.schema")

-- Import all elemental spell collections
local FireSpells = require("spells.elements.fire")
local WaterSpells = require("spells.elements.water")
local SaltSpells = require("spells.elements.salt")
local SunSpells = require("spells.elements.sun")
local MoonSpells = require("spells.elements.moon")
local StarSpells = require("spells.elements.star")
local LifeSpells = require("spells.elements.life")
local MindSpells = require("spells.elements.mind")
local VoidSpells = require("spells.elements.void")

-- Combine all spells into a single table
local Spells = {}

-- Add spells from each collection
local function addSpells(spellCollection)
    for id, spell in pairs(spellCollection) do
        Spells[id] = spell
    end
end

-- Add all elemental spell collections
addSpells(FireSpells)
addSpells(WaterSpells)
addSpells(SaltSpells)
addSpells(SunSpells)
addSpells(MoonSpells)
addSpells(StarSpells)
addSpells(LifeSpells)
addSpells(MindSpells)
addSpells(VoidSpells)

-- Prepare the return table with all spells and utility functions
local SpellsModule = {
    spells = Spells,
    validateSpell = Schema.validateSpell,
    
    -- Public method to compile all spells
    compileAll = function()
        local compiled = {}
        for id, spell in pairs(Spells) do
            Schema.validateSpell(spell, id)
            -- References to SpellCompiler and Keywords need to be passed from game object
            -- This function will be called with the correct context from main.lua
            print("Waiting for SpellCompiler to compile: " .. spell.name)
        end
        return compiled
    end,
    
    -- Public method to get a compiled spell by ID
    getCompiledSpell = function(spellId, spellCompiler, keywords)
        if not Spells[spellId] then
            print("ERROR: Spell not found: " .. spellId)
            return nil
        end
        
        -- Make sure we have the required objects
        if not spellCompiler or not keywords then
            print("ERROR: Missing SpellCompiler or Keywords for compiling spell: " .. spellId)
            return nil
        end
        
        return spellCompiler.compileSpell(Spells[spellId], keywords)
    end
}

-- Validate all spells at module load time to catch errors early
for spellId, spell in pairs(Spells) do
    Schema.validateSpell(spell, spellId)
end

return SpellsModule