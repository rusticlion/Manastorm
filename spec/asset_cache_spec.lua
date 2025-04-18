-- asset_cache_spec.lua
-- Unit tests for the AssetCache module

-- Mock love.graphics and love.audio for testing
local originalLove = love
love = {
    graphics = {
        newImage = function(path)
            return { path = path, type = "image" }
        end
    },
    audio = {
        newSource = function(path, sourceType)
            return { path = path, type = "sound", sourceType = sourceType or "static" }
        end
    }
}

-- Load the AssetCache module
local AssetCache = require("core.AssetCache")

-- Restore original love after tests
local function tearDown()
    love = originalLove
end

local function runTests()
    local testsPassed = true
    local failedTests = {}
    
    -- Test 1: Loading the same image twice returns the same object reference
    local function testImageCaching()
        local result = true
        local testPath = "assets/test.png"
        
        local img1 = AssetCache.getImage(testPath)
        local img2 = AssetCache.getImage(testPath)
        
        if img1 ~= img2 then
            result = false
            table.insert(failedTests, "Image caching failed - different references returned")
        end
        
        return result
    end
    
    -- Test 2: Loading the same sound twice returns the same object reference
    local function testSoundCaching()
        local result = true
        local testPath = "assets/test.wav"
        
        local snd1 = AssetCache.getSound(testPath)
        local snd2 = AssetCache.getSound(testPath)
        
        if snd1 ~= snd2 then
            result = false
            table.insert(failedTests, "Sound caching failed - different references returned")
        end
        
        return result
    end
    
    -- Test 3: Cache flush clears all cached assets
    local function testCacheFlush()
        local result = true
        local testPath = "assets/test.png"
        
        local img1 = AssetCache.getImage(testPath)
        AssetCache.flush()
        local img2 = AssetCache.getImage(testPath)
        
        if img1 == img2 then
            result = false
            table.insert(failedTests, "Cache flush failed - same reference returned after flush")
        end
        
        return result
    end
    
    -- Test 4: Preload function correctly loads multiple assets
    local function testPreload()
        local result = true
        AssetCache.flush()
        
        local assets = {
            images = {
                "assets/test1.png",
                "assets/test2.png"
            },
            sounds = {
                {"assets/test1.wav", "static"},
                {"assets/test2.wav", "stream"}
            }
        }
        
        AssetCache.preload(assets)
        local stats = AssetCache.dumpStats()
        
        if stats.images.loaded ~= 2 or stats.sounds.loaded ~= 2 then
            result = false
            table.insert(failedTests, "Preload failed - expected 2 images and 2 sounds, got " .. 
                stats.images.loaded .. " images and " .. stats.sounds.loaded .. " sounds")
        end
        
        return result
    end
    
    -- Run all tests
    local tests = {
        { name = "Image Caching", func = testImageCaching },
        { name = "Sound Caching", func = testSoundCaching },
        { name = "Cache Flush", func = testCacheFlush },
        { name = "Preload", func = testPreload }
    }
    
    print("Running AssetCache tests...")
    for _, test in ipairs(tests) do
        local success = test.func()
        print(test.name .. ": " .. (success and "PASS" or "FAIL"))
        testsPassed = testsPassed and success
    end
    
    if #failedTests > 0 then
        print("\nFailed tests:")
        for _, failure in ipairs(failedTests) do
            print("- " .. failure)
        end
    end
    
    print("\nTest summary: " .. (testsPassed and "ALL TESTS PASSED" or "TESTS FAILED"))
    
    -- Clean up
    AssetCache.flush()
    return testsPassed
end

local success = runTests()
tearDown()
return success