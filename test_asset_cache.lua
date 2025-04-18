-- test_asset_cache.lua
-- A simple test script for AssetCache that can be run with LÖVE

local function testAssetCache()
    -- Mock love.graphics and love.audio for testing
    local originalNewImage = love.graphics.newImage
    local originalNewSource = love.audio.newSource
    local imageCount = 0
    local soundCount = 0
    
    -- Replace with mock functions for testing
    love.graphics.newImage = function(path)
        imageCount = imageCount + 1
        return { path = path, type = "image", id = imageCount }
    end
    
    love.audio.newSource = function(path, sourceType)
        soundCount = soundCount + 1
        return { path = path, type = "sound", sourceType = sourceType or "static", id = soundCount }
    end
    
    -- Load the AssetCache module
    package.loaded["core.AssetCache"] = nil  -- Force module reload
    local AssetCache = require("core.AssetCache")
    
    -- Store test results
    local tests = {
        passed = {},
        failed = {}
    }
    
    -- Test 1: Loading the same image twice returns the same object reference
    local function testImageCaching()
        local testPath = "assets/test.png"
        
        local img1 = AssetCache.getImage(testPath)
        local img2 = AssetCache.getImage(testPath)
        
        local result = (img1 == img2)
        local testName = "Image caching"
        
        if result then
            table.insert(tests.passed, testName)
        else
            table.insert(tests.failed, testName .. ": different references returned")
        end
        
        return result
    end
    
    -- Test 2: Loading the same sound twice returns the same object reference
    local function testSoundCaching()
        local testPath = "assets/test.wav"
        
        local snd1 = AssetCache.getSound(testPath)
        local snd2 = AssetCache.getSound(testPath)
        
        local result = (snd1 == snd2)
        local testName = "Sound caching"
        
        if result then
            table.insert(tests.passed, testName)
        else
            table.insert(tests.failed, testName .. ": different references returned")
        end
        
        return result
    end
    
    -- Test 3: Cache flush clears all cached assets
    local function testCacheFlush()
        local testPath = "assets/test2.png"
        
        local img1 = AssetCache.getImage(testPath)
        AssetCache.flush()
        local img2 = AssetCache.getImage(testPath)
        
        local result = (img1 ~= img2)
        local testName = "Cache flush"
        
        if result then
            table.insert(tests.passed, testName)
        else
            table.insert(tests.failed, testName .. ": same reference returned after flush")
        end
        
        return result
    end
    
    -- Test 4: Preload function correctly loads multiple assets
    local function testPreload()
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
        
        local imageCount = 0
        local soundCount = 0
        
        -- Count images loaded
        for _ in pairs(AssetCache.getImage("assets/test1.png")) do
            imageCount = imageCount + 1
        end
        
        -- Count sounds loaded
        for _ in pairs(AssetCache.getSound("assets/test1.wav")) do
            soundCount = soundCount + 1
        end
        
        local result = (imageCount > 0 and soundCount > 0 and stats.images.misses >= 2 and stats.sounds.misses >= 2)
        local testName = "Preload"
        
        if result then
            table.insert(tests.passed, testName)
        else
            table.insert(tests.failed, testName .. ": expected at least 2 images and 2 sounds loaded")
        end
        
        return result
    end
    
    -- Run all tests
    testImageCaching()
    testSoundCaching()
    testCacheFlush()
    testPreload()
    
    -- Restore original functions
    love.graphics.newImage = originalNewImage
    love.audio.newSource = originalNewSource
    
    -- Return test results
    return tests
end

local results

-- Allow this to be run both standalone with LÖVE and from another module
if love.filesystem then
    function love.load()
        results = testAssetCache()
        
        -- Print results
        print("AssetCache Tests Results:")
        print("\nPassed tests:")
        for _, test in ipairs(results.passed) do
            print("✓ " .. test)
        end
        
        if #results.failed > 0 then
            print("\nFailed tests:")
            for _, test in ipairs(results.failed) do
                print("✗ " .. test)
            end
        end
        
        print("\nTest summary: " .. 
              (#results.failed == 0 and "ALL TESTS PASSED" or "TESTS FAILED") ..
              " (" .. #results.passed .. " passed, " .. #results.failed .. " failed)")
    end
    
    function love.draw()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("AssetCache Tests Results:", 50, 50)
        
        -- Print passed tests in green
        love.graphics.setColor(0, 1, 0, 1)
        for i, test in ipairs(results.passed) do
            love.graphics.print("✓ " .. test, 50, 70 + i * 20)
        end
        
        -- Print failed tests in red
        love.graphics.setColor(1, 0, 0, 1)
        local offset = #results.passed
        for i, test in ipairs(results.failed) do
            love.graphics.print("✗ " .. test, 50, 70 + (offset + i) * 20)
        end
        
        -- Print summary
        love.graphics.setColor(1, 1, 1, 1)
        local summary = "Test summary: " .. 
                      (#results.failed == 0 and "ALL TESTS PASSED" or "TESTS FAILED") ..
                      " (" .. #results.passed .. " passed, " .. #results.failed .. " failed)"
        love.graphics.print(summary, 50, 70 + (offset + #results.failed + 2) * 20)
    end
    
    function love.keypressed(key)
        if key == "escape" then
            love.event.quit()
        end
    end
else
    return testAssetCache
end