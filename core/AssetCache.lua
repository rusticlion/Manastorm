-- AssetCache.lua
-- Centralized cache for game assets to prevent duplicate loads
-- All image and sound loading should go through this module

local AssetCache = {}

-- Create weak tables for storing loaded assets
-- Using weak keys allows unused assets to be garbage collected
local imageCache = setmetatable({}, {__mode = "v"})
local soundCache = setmetatable({}, {__mode = "v"})

-- Cache hit counters for metrics
local stats = {
    imageHits = 0,
    imageMisses = 0,
    soundHits = 0,
    soundMisses = 0
}

-- Get an image, loading it only once
function AssetCache.getImage(path)
    if not path then
        print("ERROR: AssetCache.getImage called with nil path")
        return nil
    end
    
    if imageCache[path] then
        stats.imageHits = stats.imageHits + 1
        return imageCache[path]
    end
    
    stats.imageMisses = stats.imageMisses + 1
    
    local success, result = pcall(function()
        return love.graphics.newImage(path)
    end)
    
    if not success then
        print("ERROR: Failed to load image: " .. path .. " - " .. tostring(result))
        return nil
    end
    
    imageCache[path] = result
    return result
end

-- Get a sound, loading it only once
function AssetCache.getSound(path, soundType)
    if not path then
        print("ERROR: AssetCache.getSound called with nil path")
        return nil
    end
    
    soundType = soundType or "static" -- Default to static for effects
    
    if soundCache[path] then
        stats.soundHits = stats.soundHits + 1
        return soundCache[path]
    end
    
    stats.soundMisses = stats.soundMisses + 1
    
    local success, result = pcall(function()
        return love.audio.newSource(path, soundType)
    end)
    
    if not success then
        print("ERROR: Failed to load sound: " .. path .. " - " .. tostring(result))
        return nil
    end
    
    soundCache[path] = result
    return result
end

-- Check if a file exists
local function fileExists(path)
    local success = pcall(function()
        return love.filesystem.getInfo(path) ~= nil
    end)
    return success and love.filesystem.getInfo(path) ~= nil
end

-- Preload a collection of assets (useful at startup)
function AssetCache.preload(assets)
    local loaded = {images = 0, sounds = 0}
    local failed = {images = 0, sounds = 0}
    
    for type, paths in pairs(assets) do
        if type == "images" then
            for _, path in ipairs(paths) do
                if fileExists(path) then
                    local success, _ = pcall(function()
                        AssetCache.getImage(path)
                    end)
                    if success then
                        loaded.images = loaded.images + 1
                    else
                        failed.images = failed.images + 1
                        print("Failed to load image: " .. path)
                    end
                else
                    failed.images = failed.images + 1
                    print("Image file not found: " .. path)
                end
            end
        elseif type == "sounds" then
            for _, data in ipairs(paths) do
                local path, soundType = data[1], data[2]
                if fileExists(path) then
                    local success, _ = pcall(function()
                        AssetCache.getSound(path, soundType)
                    end)
                    if success then
                        loaded.sounds = loaded.sounds + 1
                    else
                        failed.sounds = failed.sounds + 1
                        print("Failed to load sound: " .. path)
                    end
                else
                    failed.sounds = failed.sounds + 1
                    print("Sound file not found: " .. path)
                end
            end
        end
    end
    
    if failed.images > 0 or failed.sounds > 0 then
        print(string.format("AssetCache: Loaded %d images, %d sounds. Failed: %d images, %d sounds", 
                           loaded.images, loaded.sounds, failed.images, failed.sounds))
    end
    
    return loaded
end

-- Flush the cache (useful for dev hot-reload)
function AssetCache.flush()
    for k in pairs(imageCache) do
        imageCache[k] = nil
    end
    for k in pairs(soundCache) do
        soundCache[k] = nil
    end
    
    -- Reset stats
    stats.imageHits = 0
    stats.imageMisses = 0
    stats.soundHits = 0
    stats.soundMisses = 0
end

-- Helper function to count table items (for weak tables)
local function countTableItems(t)
    local count = 0
    for _ in pairs(t) do 
        count = count + 1 
    end
    return count
end

-- Get cache statistics for debug overlay
function AssetCache.dumpStats()
    return {
        images = {
            loaded = countTableItems(imageCache),
            hits = stats.imageHits,
            misses = stats.imageMisses
        },
        sounds = {
            loaded = countTableItems(soundCache),
            hits = stats.soundHits,
            misses = stats.soundMisses
        }
    }
end

return AssetCache