-- test_particle_manager.lua
-- A script to test ParticleManager integration with vfx.lua

local Pool = require("core.Pool")
local ParticleManager = require("vfx.ParticleManager")
local VFX = require("vfx")

-- Initialize the VFX system
VFX.init()

-- Count the total particles created and returned to pool
local function testParticlePooling()
    print("\n=== TESTING PARTICLE POOLING ===")
    
    -- Get initial stats
    local initialStats = ParticleManager.getStats()
    print(string.format("Initial pool: %d total (%d active, %d available)", 
        initialStats.poolSize, initialStats.active, initialStats.available))
    
    -- Create effects with different types
    local effects = {}
    
    print("\nCreating test effects...")
    
    -- Test a projectile effect
    local projectile = VFX.createEffect("proj_base", 100, 100, 500, 300, {
        color = {1, 0, 0, 1}, -- Red
    })
    table.insert(effects, projectile)
    print("Created projectile effect with " .. #projectile.particles .. " particles")
    
    -- Test an impact effect
    local impact = VFX.createEffect("impact_base", 300, 300, 300, 300, {
        color = {0, 1, 0, 1}, -- Green
    })
    table.insert(effects, impact)
    print("Created impact effect with " .. #impact.particles .. " particles")
    
    -- Test a cone effect
    local cone = VFX.createEffect("blast_base", 200, 400, 500, 200, {
        color = {0, 0, 1, 1}, -- Blue
    })
    table.insert(effects, cone)
    print("Created cone effect with " .. #cone.particles .. " particles")
    
    -- Test a beam effect
    local beam = VFX.createEffect("beam_base", 100, 400, 600, 400, {
        color = {1, 1, 0, 1}, -- Yellow
    })
    table.insert(effects, beam)
    print("Created beam effect with " .. #beam.particles .. " particles")
    
    -- Test an aura effect
    local aura = VFX.createEffect("zone_base", 400, 300, 400, 300, {
        color = {1, 0, 1, 1}, -- Purple
    })
    table.insert(effects, aura)
    print("Created aura effect with " .. #aura.particles .. " particles")
    
    -- Test a remote effect
    local remote = VFX.createEffect("remote_base", 300, 100, 300, 100, {
        color = {0, 1, 1, 1}, -- Cyan
    })
    table.insert(effects, remote)
    print("Created remote effect with " .. #remote.particles .. " particles")
    
    -- Test a surge effect
    local surge = VFX.createEffect("surge_base", 500, 500, 500, 500, {
        color = {1, 0.5, 0, 1}, -- Orange
    })
    table.insert(effects, surge)
    print("Created surge effect with " .. #surge.particles .. " particles")
    
    -- Test a conjure effect
    local conjure = VFX.createEffect("conjure_base", 200, 500, 200, 500, {
        color = {0.5, 0.5, 1, 1}, -- Light blue
    })
    table.insert(effects, conjure)
    print("Created conjure effect with " .. #conjure.particles .. " particles")
    
    -- Get stats after creating effects
    local afterCreateStats = ParticleManager.getStats()
    print(string.format("\nAfter creating effects: %d total (%d active, %d available)", 
        afterCreateStats.poolSize, afterCreateStats.active, afterCreateStats.available))
    
    -- Count total particles created
    local totalParticles = 0
    for _, effect in ipairs(effects) do
        totalParticles = totalParticles + #effect.particles
    end
    print("Total particles created: " .. totalParticles)
    
    -- Release all effects and their particles
    print("\nReleasing all effects and particles...")
    for i, effect in ipairs(effects) do
        print("Releasing effect " .. i .. " with " .. #effect.particles .. " particles")
        -- First release all particles
        for _, particle in ipairs(effect.particles) do
            ParticleManager.releaseParticle(particle)
        end
        -- Then release the effect
        Pool.release("vfx_effect", effect)
    end
    
    -- Get final stats
    local finalStats = ParticleManager.getStats()
    print(string.format("\nFinal pool: %d total (%d active, %d available)", 
        finalStats.poolSize, finalStats.active, finalStats.available))
    
    -- Verify all particles were returned to the pool
    if finalStats.active == 0 and finalStats.available == finalStats.poolSize then
        print("\n✓ SUCCESS: All particles were returned to the pool!")
    else
        print("\n✗ FAILURE: Not all particles were returned to the pool.")
        print("  Expected active=0, got " .. finalStats.active)
        print("  Expected available=" .. finalStats.poolSize .. ", got " .. finalStats.available)
    end
end

-- Run the test
testParticlePooling()

return {
    testParticlePooling = testParticlePooling
}