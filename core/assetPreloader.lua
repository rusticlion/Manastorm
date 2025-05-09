-- assetPreloader.lua
-- Centralized preloader for game assets

local AssetCache = require("core.AssetCache")

local AssetPreloader = {}

-- Preload all game assets to avoid hitches during gameplay
function AssetPreloader.preloadAllAssets()
    local startTime = love.timer.getTime()
    
    -- Manifest of all assets to preload
    local assetManifest = {
        images = {
            -- Token & UI assets
            "assets/sprites/token-lock.png",
            
            -- Elemental tokens
            "assets/sprites/v2Tokens/fire-token.png", 
            "assets/sprites/v2Tokens/water-token.png",
            "assets/sprites/v2Tokens/salt-token.png",
            "assets/sprites/v2Tokens/sun-token.png",
            "assets/sprites/v2Tokens/moon-token.png",
            "assets/sprites/v2Tokens/star-token.png",
            "assets/sprites/v2Tokens/life-token.png",
            "assets/sprites/v2Tokens/mind-token.png",
            "assets/sprites/v2Tokens/void-token.png",
            
            -- VFX assets
            "assets/sprites/fire-particle.png",
            "assets/sprites/fire-glow.png",
            "assets/sprites/force-wave.png", 
            "assets/sprites/moon-glow.png",
            "assets/sprites/sparkle.png",
            "assets/sprites/impact-ring.png",
            
            -- Game entity assets
            "assets/sprites/wizard.png",
            "assets/sprites/ashgar.png",
            "assets/sprites/ashgar-cast.png",
            "assets/sprites/selene.png",
            "assets/sprites/selene-cast.png",

            "assets/sprites/grounded-circle.png"
        },
        
        sounds = {
            -- These are placeholders until actual sound assets are created
            -- Format: {path, type} where type is "static" or "stream"
            -- {"assets/sounds/firebolt.wav", "static"},
            -- {"assets/sounds/meteor.wav", "static"},
            -- {"assets/sounds/mist.wav", "static"}
        }
    }
    
    -- Check assets directory structure
    local assetsExist = love.filesystem.getInfo("assets/sprites")
    if not assetsExist then
        print("WARNING: assets/sprites directory not found. Asset loading may fail.")
    end
    
    -- Filter manifest to only include existing paths
    local filteredManifest = {
        images = {},
        sounds = {}
    }
    
    for _, path in ipairs(assetManifest.images) do
        if love.filesystem.getInfo(path) then
            table.insert(filteredManifest.images, path)
        else
            print("Asset not found, will skip: " .. path)
        end
    end
    
    for _, soundData in ipairs(assetManifest.sounds) do
        if love.filesystem.getInfo(soundData[1]) then
            table.insert(filteredManifest.sounds, soundData)
        else
            print("Sound asset not found, will skip: " .. soundData[1])
        end
    end
    
    -- Preload all assets in the filtered manifest
    local loaded = AssetCache.preload(filteredManifest)
    
    -- Report preload time
    local loadTime = love.timer.getTime() - startTime
    print(string.format("AssetPreloader: Loaded %d images and %d sounds in %.2f seconds", 
                        loaded.images, loaded.sounds, loadTime))
                        
    -- Return statistics for verification
    return {
        imageCount = loaded.images,
        soundCount = loaded.sounds,
        loadTime = loadTime
    }
end

-- Helper to reload all assets (useful for development hot-reload)
function AssetPreloader.reloadAllAssets()
    AssetCache.flush()
    return AssetPreloader.preloadAllAssets()
end

-- Get asset cache statistics
function AssetPreloader.getStats()
    return AssetCache.dumpStats()
end

return AssetPreloader