-- test_spellCompiler.lua
-- Tests for the Spell Compiler implementation

local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local Spells = require("spells").spells

-- Define a fake game environment for testing
local gameEnv = {
    wizards = {
        { name = "TestWizard1", health = 100, elevation = "GROUNDED" },
        { name = "TestWizard2", health = 100, elevation = "AERIAL" }
    },
    rangeState = "FAR"
}

-- Add game state to wizards
gameEnv.wizards[1].gameState = gameEnv
gameEnv.wizards[2].gameState = gameEnv

-- Print test header
print("\n===== SPELL COMPILER TESTS =====\n")

-- Test 1: Basic spell compilation
print("TEST 1: Basic spell compilation")
local firebolt = Spells.firebolt
local compiledFirebolt = SpellCompiler.compileSpell(firebolt, Keywords)

-- Verify structure
print("Compiled spell structure check: " .. 
      (compiledFirebolt.behavior.damage ~= nil and "PASSED" or "FAILED"))
print("Original properties preserved: " .. 
      (compiledFirebolt.id == firebolt.id and 
       compiledFirebolt.name == firebolt.name and 
       compiledFirebolt.attackType == firebolt.attackType and "PASSED" or "FAILED"))

-- Test 2: Boolean keyword handling
print("\nTEST 2: Boolean keyword handling")
local groundKeywordSpell = {
    id = "testGround",
    name = "Test Ground",
    description = "Test for boolean keywords",
    attackType = "utility",
    castTime = 2.0,
    cost = {"any"},
    keywords = {
        ground = true
    }
}

local compiledGroundSpell = SpellCompiler.compileSpell(groundKeywordSpell, Keywords)
print("Boolean keyword handling: " .. 
      (compiledGroundSpell.behavior.ground.enabled == true and "PASSED" or "FAILED"))

-- Test 3: Complex spell with multiple keywords
print("\nTEST 3: Complex spell with multiple keywords")
local compiledMeteor = SpellCompiler.compileSpell(Spells.meteor, Keywords)
print("Multiple keywords compiled: " .. 
      (compiledMeteor.behavior.damage ~= nil and 
       compiledMeteor.behavior.rangeShift ~= nil and "PASSED" or "FAILED"))

-- Test 4: Execution of compiled behaviors
print("\nTEST 4: Execution of compiled behaviors")
local results = {}
results = compiledFirebolt.executeAll(gameEnv.wizards[1], gameEnv.wizards[2], results)

print("Behavior execution results:")
print("Damage applied: " .. tostring(results.damage))
print("Damage type: " .. tostring(results.damageType))

-- Test 5: Complex behavior parameter handling
print("\nTEST 5: Complex behavior parameter handling")
local arcaneReversal = Spells.arcaneReversal
local compiledArcaneReversal = SpellCompiler.compileSpell(arcaneReversal, Keywords)

print("Complex parameters preserved for multiple keywords: " .. 
      (compiledArcaneReversal.behavior.damage ~= nil and
       compiledArcaneReversal.behavior.rangeShift ~= nil and
       compiledArcaneReversal.behavior.lock ~= nil and
       compiledArcaneReversal.behavior.conjure ~= nil and
       compiledArcaneReversal.behavior.accelerate ~= nil and "PASSED" or "FAILED"))

-- Debug complete structure of a complex spell
print("\nDetailed structure of compiled arcaneReversal spell:")
SpellCompiler.debugCompiled(compiledArcaneReversal)

print("\n===== SPELL COMPILER TESTS COMPLETED =====\n")