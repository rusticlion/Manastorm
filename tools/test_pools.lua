-- test_pools.lua
-- Tests for object pool implementation

local Pool = require("core.Pool")

-- Counters to track object allocations
local objectsCreated = 0
local objectsDestroyed = 0

-- Create a factory function that allows us to track creation
local function createTestObject()
    objectsCreated = objectsCreated + 1
    return { id = objectsCreated, value = "Test object #" .. objectsCreated }
end

-- Reset function that allows tracking release
local function resetTestObject(obj)
    for k, v in pairs(obj) do
        if k ~= "id" then -- Keep the ID for tracking
            obj[k] = nil
        end
    end
    return obj
end

-- Test basic pool functionality
local function testBasicPoolOperations()
    print("\n=== Testing Basic Pool Operations ===")
    
    -- Create a new pool
    Pool.create("test", 5, createTestObject, resetTestObject)
    local stats = Pool.getStats()
    local poolSize = Pool.size("test")
    
    print("Initial pool size: " .. poolSize)
    assert(poolSize == 5, "Initial pool size should be 5")
    
    -- Acquire some objects
    local obj1 = Pool.acquire("test")
    local obj2 = Pool.acquire("test")
    local obj3 = Pool.acquire("test")
    
    print("Acquired 3 objects, available: " .. Pool.available("test"))
    assert(Pool.available("test") == 2, "Should have 2 objects available")
    assert(Pool.activeCount("test") == 3, "Should have 3 active objects")
    
    -- Check that objects have proper IDs
    print("Object IDs: " .. obj1.id .. ", " .. obj2.id .. ", " .. obj3.id)
    assert(obj1.id ~= obj2.id and obj2.id ~= obj3.id, "Objects should have unique IDs")
    
    -- Release an object
    Pool.release("test", obj2)
    print("Released 1 object, available: " .. Pool.available("test"))
    assert(Pool.available("test") == 3, "Should have 3 objects available")
    assert(Pool.activeCount("test") == 2, "Should have 2 active objects")
    
    -- Re-acquire and verify we get the released object first
    local obj4 = Pool.acquire("test")
    print("Re-acquired object, ID: " .. obj4.id)
    assert(obj4.id == obj2.id, "Should reuse the released object")
    
    -- Clean up
    Pool.clear("test")
    print("Cleared test pool")
    return true
end

-- Test pool growth and reuse
local function testPoolGrowth()
    print("\n=== Testing Pool Growth and Reuse ===")
    
    -- Create a small pool
    Pool.create("growTest", 2, createTestObject, resetTestObject)
    print("Initial pool size: " .. Pool.size("growTest"))
    
    -- Acquire more objects than initial size
    local objects = {}
    for i = 1, 5 do
        objects[i] = Pool.acquire("growTest")
        print("Acquired object #" .. i .. ", ID: " .. objects[i].id)
    end
    
    local stats = Pool.getStats()
    local poolStats = nil
    for _, stat in ipairs(stats.pools) do
        if stat.id == "growTest" then
            poolStats = stat
            break
        end
    end
    
    print("Pool size after growth: " .. Pool.size("growTest"))
    assert(Pool.size("growTest") == 5, "Pool should grow to 5 objects")
    assert(poolStats.creates == 5, "Should have created 5 objects")
    
    -- Release all objects
    for i = 1, 5 do
        Pool.release("growTest", objects[i])
    end
    
    -- Acquire objects again to test reuse
    local newObjects = {}
    for i = 1, 5 do
        newObjects[i] = Pool.acquire("growTest")
    end
    
    stats = Pool.getStats()
    for _, stat in ipairs(stats.pools) do
        if stat.id == "growTest" then
            poolStats = stat
            break
        end
    end
    
    print("Objects created: " .. poolStats.creates)
    print("Objects acquired: " .. poolStats.acquires)
    print("Reuse percentage: " .. ((poolStats.acquires - poolStats.creates) / poolStats.acquires * 100) .. "%")
    
    assert(poolStats.creates == 5, "Should still have created only 5 objects")
    assert(poolStats.acquires == 10, "Should have 10 acquisitions total")
    
    -- Clean up
    Pool.clear("growTest")
    print("Cleared growth test pool")
    return true
end

-- Simulate token usage patterns
local function testTokenPoolSimulation()
    print("\n=== Testing Token Pool Simulation ===")
    
    -- Create a token pool
    Pool.create("tokenSim", 10, createTestObject, resetTestObject)
    
    -- Simulate a game with tokens being acquired and released
    local activeTokens = {}
    local totalOperations = 1000
    local acquisitions = 0
    local releases = 0
    
    -- Run the simulation
    print("Running simulation with " .. totalOperations .. " operations...")
    
    for i = 1, totalOperations do
        -- Randomly decide to acquire or release
        if #activeTokens < 20 and (math.random() < 0.7 or #activeTokens == 0) then
            -- Acquire a token
            local token = Pool.acquire("tokenSim")
            token.value = "Active token #" .. i
            token.createdAt = i
            table.insert(activeTokens, token)
            acquisitions = acquisitions + 1
        else
            -- Release a random token
            local index = math.random(#activeTokens)
            Pool.release("tokenSim", activeTokens[index])
            table.remove(activeTokens, index)
            releases = releases + 1
        end
        
        -- Every 100 operations, print some stats
        if i % 200 == 0 then
            local stats = Pool.getStats()
            local poolStats = nil
            for _, stat in ipairs(stats.pools) do
                if stat.id == "tokenSim" then
                    poolStats = stat
                    break
                end
            end
            
            print(string.format("Operation %d: Pool size %d (Active: %d, Available: %d)", 
                i, poolStats.size, poolStats.active, poolStats.available))
        end
    end
    
    -- Report final stats
    local stats = Pool.getStats()
    local poolStats = nil
    for _, stat in ipairs(stats.pools) do
        if stat.id == "tokenSim" then
            poolStats = stat
            break
        end
    end
    
    print("\nSimulation complete:")
    print("Total acquisitions: " .. acquisitions)
    print("Total releases: " .. releases)
    print("Objects created: " .. poolStats.creates)
    print("Final pool size: " .. poolStats.size)
    print("Reuse rate: " .. ((acquisitions - poolStats.creates) / acquisitions * 100) .. "%")
    
    -- Assert reasonable reuse
    assert(poolStats.creates < acquisitions, "Should have reused objects")
    assert(poolStats.creates <= 20 + 10, "Should not have created more than max active + initial")
    
    -- Clean up
    Pool.clear("tokenSim")
    print("Cleared token simulation pool")
    return true
end

-- VFX particle simulation
local function testVFXParticlePoolSimulation()
    print("\n=== Testing VFX Particle Pool Simulation ===")
    
    -- Set up particle pool
    Pool.create("particleSim", 50, createTestObject, resetTestObject)
    
    -- Statistics
    local effectsCreated = 0
    local particlesUsed = 0
    local maxParticles = 0
    
    -- Simulate effects being created and expiring
    local activeEffects = {}
    local totalFrames = 300  -- Simulate 5 seconds at 60fps
    
    print("Running " .. totalFrames .. " frame simulation...")
    
    for frame = 1, totalFrames do
        -- Randomly decide to create a new effect (about every 15 frames)
        if math.random() < 0.07 then
            effectsCreated = effectsCreated + 1
            
            -- Determine how long the effect will last
            local duration = math.random(30, 120)  -- 0.5 to 2.0 seconds
            
            -- Determine how many particles it needs
            local particleCount = math.random(10, 40)
            
            -- Create the effect
            local effect = {
                particles = {},
                remainingFrames = duration
            }
            
            -- Acquire particles for this effect
            for i = 1, particleCount do
                local particle = Pool.acquire("particleSim")
                particle.effect = effectsCreated
                particle.frame = frame
                table.insert(effect.particles, particle)
                particlesUsed = particlesUsed + 1
            end
            
            -- Add to active effects
            table.insert(activeEffects, effect)
        end
        
        -- Update active effects
        local i = 1
        while i <= #activeEffects do
            local effect = activeEffects[i]
            effect.remainingFrames = effect.remainingFrames - 1
            
            -- Check if effect is complete
            if effect.remainingFrames <= 0 then
                -- Release all particles back to the pool
                for _, particle in ipairs(effect.particles) do
                    Pool.release("particleSim", particle)
                end
                
                -- Remove the effect
                table.remove(activeEffects, i)
            else
                i = i + 1
            end
        end
        
        -- Every 60 frames, print some stats
        if frame % 60 == 0 then
            local activeParticles = 0
            for _, effect in ipairs(activeEffects) do
                activeParticles = activeParticles + #effect.particles
            end
            
            maxParticles = math.max(maxParticles, activeParticles)
            
            print(string.format("Frame %d: Active effects: %d, Active particles: %d", 
                frame, #activeEffects, activeParticles))
        end
    end
    
    -- Report final stats
    local stats = Pool.getStats()
    local poolStats = nil
    for _, stat in ipairs(stats.pools) do
        if stat.id == "particleSim" then
            poolStats = stat
            break
        end
    end
    
    print("\nSimulation complete:")
    print("Total effects created: " .. effectsCreated)
    print("Total particle usages: " .. particlesUsed)
    print("Peak particles at once: " .. maxParticles)
    print("Objects created: " .. poolStats.creates)
    print("Reuse rate: " .. ((particlesUsed - poolStats.creates) / particlesUsed * 100) .. "%")
    
    -- Clean up
    Pool.clear("particleSim")
    return true
end

-- Run all tests
local function runAllTests()
    print("===== OBJECT POOL SYSTEM TESTS =====")
    
    local testResults = {
        basicOps = testBasicPoolOperations(),
        growth = testPoolGrowth(),
        tokenSim = testTokenPoolSimulation(),
        vfxSim = testVFXParticlePoolSimulation()
    }
    
    -- Print summary
    print("\n===== TEST RESULTS =====")
    for test, result in pairs(testResults) do
        print(test .. ": " .. (result and "PASS" or "FAIL"))
    end
    
    -- Print global stats
    print("\nTotal objects created during testing: " .. objectsCreated)
    print("\nPool System Final Status:")
    Pool.printStats()
end

-- Run the tests
runAllTests()