-- validate_spellCompiler.lua
-- A simple script to validate the spellCompiler implementation
-- Writes validation results to a file for inspection

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")

-- Define a sample spell for testing
local sampleSpell = {
    id = "fireball",
    name = "Fireball",
    description = "A ball of fire that deals damage",
    attackType = "projectile",
    castTime = 5.0,
    cost = {"fire", "fire"},
    keywords = {
        damage = {
            amount = 10,
            type = "fire"
        },
        burn = {
            duration = 3.0,
            tickDamage = 2
        }
    },
    vfx = "fireball_vfx",
    blockableBy = {"barrier", "ward"}
}

-- Open a file for writing results
local outFile = io.open("spellCompiler_validation.txt", "w")

-- Write test header
outFile:write("===== SPELL COMPILER VALIDATION =====\n\n")

-- Test basic spell compilation
outFile:write("Testing basic spell compilation...\n")
local compiledSpell = SpellCompiler.compileSpell(sampleSpell, Keywords)

-- Check that compilation worked
outFile:write("Compiled spell has behavior: " .. (compiledSpell.behavior ~= nil and "YES" or "NO") .. "\n")
outFile:write("Compiled spell has damage behavior: " .. (compiledSpell.behavior.damage ~= nil and "YES" or "NO") .. "\n")
outFile:write("Compiled spell has burn behavior: " .. (compiledSpell.behavior.burn ~= nil and "YES" or "NO") .. "\n")

-- Test a boolean keyword
local spellWithBoolKeyword = {
    id = "groundSpell",
    name = "Ground Spell",
    description = "Forces enemy to ground",
    attackType = "utility",
    castTime = 3.0,
    cost = {"any"},
    keywords = {
        ground = true
    }
}

outFile:write("\nTesting boolean keyword handling...\n")
local compiledBoolSpell = SpellCompiler.compileSpell(spellWithBoolKeyword, Keywords)
outFile:write("Boolean keyword compiled: " .. (compiledBoolSpell.behavior.ground ~= nil and "YES" or "NO") .. "\n")
outFile:write("Boolean keyword enabled: " .. (compiledBoolSpell.behavior.ground.enabled == true and "YES" or "NO") .. "\n")

-- Define mock game objects for execution testing
local caster = {
    name = "TestWizard",
    elevation = "GROUNDED",
    manaPool = { 
        tokens = {},
        addToken = function() end
    },
    gameState = { rangeState = "FAR" }
}

local target = {
    name = "EnemyWizard",
    elevation = "AERIAL",
    health = 100
}

-- Test executing the compiled behaviors
outFile:write("\nTesting behavior execution...\n")

-- Create table to capture print output
local originalPrint = print
local printOutput = {}
print = function(...)
    local args = {...}
    local output = ""
    for i, v in ipairs(args) do
        output = output .. tostring(v) .. (i < #args and "\t" or "")
    end
    table.insert(printOutput, output)
end

-- Run debug output to capture to our printOutput table
SpellCompiler.debugCompiled(compiledSpell)

-- Write captured output to file
for _, line in ipairs(printOutput) do
    outFile:write(line .. "\n")
end

-- Restore original print function
print = originalPrint

outFile:write("\nVALIDATION SUMMARY\n")
outFile:write("- Basic spell compilation: " .. (compiledSpell.behavior ~= nil and "PASSED" or "FAILED") .. "\n")
outFile:write("- Boolean keyword handling: " .. (compiledBoolSpell.behavior.ground ~= nil and "PASSED" or "FAILED") .. "\n")
outFile:write("- Execution structure: " .. (type(compiledSpell.executeAll) == "function" and "PASSED" or "FAILED") .. "\n")

outFile:write("\n===== SPELL COMPILER VALIDATION COMPLETED =====\n")
outFile:close()

-- Print confirmation message
print("Validation completed. Results written to spellCompiler_validation.txt")