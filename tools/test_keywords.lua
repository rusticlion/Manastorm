#!/usr/bin/env lua
-- Script to test and debug keyword resolution

-- Add manastorm root directory to lua path
package.path = package.path .. ";../?.lua"

-- Import the spells module
local Spells = require("spells")

-- Mock wizard class for testing
local MockWizard = {}
MockWizard.__index = MockWizard

function MockWizard.new(name, position)
    local self = setmetatable({}, MockWizard)
    self.name = name
    self.x = position or 0
    self.y = 370
    self.elevation = "GROUNDED"
    self.spellSlots = {{}, {}, {}}
    self.manaPool = {
        tokens = {},
        addToken = function() print("Added token") end
    }
    self.gameState = {
        rangeState = "FAR",
        wizards = {}
    }
    return self
end

-- Create mock wizards for testing
local caster = MockWizard.new("TestWizard", 200)
local opponent = MockWizard.new("Opponent", 600)

-- Set up test state
caster.gameState.wizards = {caster, opponent}

-- Test a keyword in isolation
local function testKeyword(keyword, params)
    print("\n====== Testing keyword: " .. keyword .. " ======")
    
    -- Create starting results
    local results = {damage = 0, spellType = "test"}
    
    -- Process the keyword
    local newResults = Spells.keywordSystem.resolveKeyword(
        "test_spell", 
        keyword, 
        params, 
        caster, 
        opponent, 
        1, -- spell slot
        results
    )
    
    -- Show detailed results
    print("\nKeyword results:")
    for k, v in pairs(newResults) do
        if k ~= "damage" or v ~= 0 then
            print("  " .. k .. ": " .. tostring(v))
        end
    end
    
    return newResults
end

-- Test a full spell
local function testSpell(spell)
    print("\n====== Testing spell: " .. spell.name .. " ======")
    
    -- Process the spell
    local results = Spells.resolveSpell(spell, caster, opponent, 1)
    
    -- Show detailed results
    print("\nSpell results:")
    for k, v in pairs(results) do
        if k ~= "damage" or v ~= 0 then
            print("  " .. k .. ": " .. tostring(v))
        end
    end
    
    return results
end

-- Run tests based on command-line arguments
local function runTests()
    local arg = {...}
    
    if #arg == 0 then
        -- Default tests if no arguments provided
        print("Running default tests...")
        
        -- Test individual keywords
        testKeyword("damage", {amount = 10, type = "fire"})
        testKeyword("elevate", {duration = 3.0})
        testKeyword("rangeShift", {position = "NEAR"})
        
        -- Test a dynamic function parameter
        testKeyword("damage", {
            amount = function(caster, target)
                return caster.gameState.rangeState == "FAR" and 15 or 10
            end,
            type = "fire"
        })
        
        -- Test a complex spell
        local testSpell = {
            id = "testspell",
            name = "Test Compound Spell",
            description = "A spell combining multiple effects for testing",
            attackType = "projectile",
            castTime = 5.0,
            cost = {"fire", "force"},
            keywords = {
                damage = {
                    amount = function(caster, target)
                        return target.elevation == "AERIAL" and 15 or 10
                    end,
                    type = "fire"
                },
                elevate = {
                    duration = 3.0
                },
                rangeShift = {
                    position = "NEAR"
                }
            }
        }
        testSpell(testSpell)
        
    elseif arg[1] == "list" then
        -- List all available keywords
        print("Available keywords:")
        local keywordInfo = Spells.keywordSystem.getKeywordHelp()
        for keyword, info in pairs(keywordInfo) do
            print("- " .. keyword .. ": " .. info.description)
        end
        
    elseif arg[1] == "keyword" and arg[2] then
        -- Test a specific keyword
        local keyword = arg[2]
        
        -- Check if this keyword exists
        if not Spells.keywordSystem.handlers[keyword] then
            print("Error: Unknown keyword '" .. keyword .. "'")
            return
        end
        
        -- Create some basic params for testing
        local params = {}
        if keyword == "damage" then
            params = {amount = 10, type = "fire"}
        elseif keyword == "elevate" or keyword == "freeze" then
            params = {duration = 3.0}
        elseif keyword == "rangeShift" then
            params = {position = "NEAR"}
        elseif keyword == "block" then
            params = {type = "barrier", blocks = {"projectile"}}
        elseif keyword == "conjure" then
            params = {token = "fire", amount = 1}
        elseif keyword == "dissipate" then
            params = {token = "fire", amount = 1}
        elseif keyword == "tokenShift" then
            params = {type = "random", amount = 2}
        end
        
        testKeyword(keyword, params)
        
    elseif arg[1] == "spell" and arg[2] then
        -- Test a specific spell
        local spellId = arg[2]
        
        -- Check if this spell exists
        if not Spells.spells[spellId] then
            print("Error: Unknown spell '" .. spellId .. "'")
            return
        end
        
        testSpell(Spells.spells[spellId])
        
    else
        -- Show usage
        print("Usage:")
        print("  lua test_keywords.lua                  Run default tests")
        print("  lua test_keywords.lua list             List all available keywords")
        print("  lua test_keywords.lua keyword <name>   Test a specific keyword")
        print("  lua test_keywords.lua spell <id>       Test a specific spell")
    end
end

-- Run the tests
runTests(...)