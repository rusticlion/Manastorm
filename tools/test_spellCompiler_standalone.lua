-- test_spellCompiler_standalone.lua
-- Standalone test for the Spell Compiler implementation

-- Mocking love.graphics.newImage to allow running outside LÖVE
_G.love = {
    graphics = {
        newImage = function(path) return { path = path } end
    }
}

package.path = package.path .. ";/Users/russell/Manastorm/?.lua"
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

-- Print test header
print("\n===== SPELL COMPILER STANDALONE TEST =====\n")

-- Test basic spell compilation
print("Testing basic spell compilation...")
local compiledSpell = SpellCompiler.compileSpell(sampleSpell, Keywords)

-- Check that compilation worked
print("Compiled spell has behavior: " .. (compiledSpell.behavior ~= nil and "YES" or "NO"))
print("Compiled spell has damage behavior: " .. (compiledSpell.behavior.damage ~= nil and "YES" or "NO"))
print("Compiled spell has burn behavior: " .. (compiledSpell.behavior.burn ~= nil and "YES" or "NO"))

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

print("\nTesting boolean keyword handling...")
local compiledBoolSpell = SpellCompiler.compileSpell(spellWithBoolKeyword, Keywords)
print("Boolean keyword compiled: " .. (compiledBoolSpell.behavior.ground ~= nil and "YES" or "NO"))
print("Boolean keyword enabled: " .. (compiledBoolSpell.behavior.ground.enabled == true and "YES" or "NO"))

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
print("\nTesting behavior execution...")
local results = compiledSpell.executeAll(caster, target, {})
print("Damage result: " .. tostring(results.damage))
print("Damage type: " .. tostring(results.damageType))
print("Burn applied: " .. tostring(results.burnApplied))
print("Burn duration: " .. tostring(results.burnDuration))
print("Burn tick damage: " .. tostring(results.burnTickDamage))

-- Debug the full compiled spell structure
print("\nDetailed structure of compiled spell:")
SpellCompiler.debugCompiled(compiledSpell)

print("\n===== SPELL COMPILER STANDALONE TEST COMPLETED =====\n")