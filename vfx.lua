-- VFX.lua
-- Visual effects module for spell animations and combat effects

local VFX = {
    -- Tables to hold effect type updaters and drawers
    updaters = {},
    drawers = {}
}
VFX.__index = VFX

-- Import dependencies
local Pool = require("core.Pool")
local Constants = require("core.Constants")
local AssetCache = require("core.AssetCache")
local ParticleManager = require("vfx.ParticleManager")
local initializeParticlesModule = require("vfx.initializeParticles")

-- Table to store active effects
VFX.activeEffects = {}

-- Helper function to lazily load assets on demand
local function getAssetInternal(assetId)
    -- Check if asset path exists
    local path = VFX.assetPaths[assetId]
    if not path then 
        print("[VFX] Warning: No path defined for asset: " .. tostring(assetId))
        return nil 
    end
    
    -- Initialize assets table if it doesn't exist
    VFX.assets = VFX.assets or {}
    
    -- Check if already loaded (simple cache within VFX module)
    if VFX.assets[assetId] then 
        return VFX.assets[assetId] 
    end
    
    -- Special handling for runes array
    if assetId == "runes" then
        -- Check if runes are already loaded
        if VFX.assets.runes and #VFX.assets.runes > 0 then
            return VFX.assets.runes
        end
        
        -- Initialize runes array if needed
        VFX.assets.runes = VFX.assets.runes or {}
        
        -- If array exists but is empty, load runes
        if #VFX.assets.runes == 0 then
            for i, runePath in ipairs(path) do
                print("[VFX] Loading rune asset on demand: rune" .. i)
                local runeImg = AssetCache.getImage(runePath)
                if runeImg then
                    table.insert(VFX.assets.runes, runeImg)
                else
                    print("[VFX] Warning: Failed to load rune asset: " .. runePath)
                end
            end
        end
        
        -- Log if runes were loaded successfully
        if #VFX.assets.runes > 0 then
            print("[VFX] Successfully loaded " .. #VFX.assets.runes .. " rune assets")
        else 
            print("[VFX] Warning: No rune assets were loaded!")
        end
        
        return VFX.assets.runes
    end
    
    -- Load on demand using AssetCache
    print("[VFX] Lazily loading asset: " .. assetId)
    VFX.assets[assetId] = AssetCache.getImage(path)
    return VFX.assets[assetId]
end

-- Initialize the VFX system
function VFX.init()
    -- Store a reference to the global game object for use in effects
    VFX.gameState = _G.game -- Access the global game variable
    
    -- Define asset paths (but don't load them yet - lazy loading)
    VFX.assetPaths = {
        -- Fire effects
        fireParticle = "assets/sprites/fire-particle.png",
        fireGlow = "assets/sprites/fire-glow.png",
        
        -- Force effects
        forceWave = "assets/sprites/force-wave.png",
        
        -- Moon effects
        moonGlow = "assets/sprites/moon-glow.png",
        
        -- Generic effects
        sparkle = "assets/sprites/sparkle.png",
        impactRing = "assets/sprites/impact-ring.png",
        
        -- Bolt effects
        boltFrames = {
            "assets/sprites/bolt/bolt1.png",
            "assets/sprites/bolt/bolt2.png",
            "assets/sprites/bolt/bolt3.png"
        },
        
        -- Warp effects
        warpFrames = {
            "assets/sprites/warp/warp1.png",
            "assets/sprites/warp/warp2.png",
            "assets/sprites/warp/warp3.png"
        },

        -- Pixel primitive
        pixel = "assets/sprites/1px.png",

        -- Twinkle assets
        twinkle1 = "assets/sprites/3px-twinkle1.png",
        twinkle2 = "assets/sprites/3px-twinkle2.png",
        -- Rune assets for Ward shields (paths only)
        runes = {}
    }
    
    -- Define rune paths
    for i = 1, 9 do
        table.insert(VFX.assetPaths.runes, string.format("assets/sprites/runes/rune%d.png", i))
    end
    
    -- Initialize empty assets table (will be filled on demand)
    VFX.assets = {}
    
    -- Public function to get assets - expose the internal getAsset function
    VFX.getAsset = getAssetInternal
    
    -- Initialize particle pools
    Pool.create("vfx_particle", 100, function() return {} end, VFX.resetParticle)
    
    -- Preload critical assets immediately
    -- This ensures essential effects like ward shields work even on first use
    print("[VFX] Eagerly preloading critical assets...")
    
    -- Preload rune assets for ward shields
    VFX.assets.runes = {}
    for i, runePath in ipairs(VFX.assetPaths.runes) do
        print("[VFX] Preloading essential asset: rune" .. i)
        local runeImg = AssetCache.getImage(runePath)
        if runeImg then
            table.insert(VFX.assets.runes, runeImg)
        else
            print("[VFX] Warning: Failed to preload rune asset: " .. runePath)
        end
    end
    
    -- Preload sparkle asset (used in many effects)
    print("[VFX] Preloading essential asset: sparkle")
    VFX.assets.sparkle = AssetCache.getImage(VFX.assetPaths.sparkle)
    
    -- Preload bolt frames for the bolt effects
    print("[VFX] Preloading bolt frame assets")
    VFX.assets.boltFrames = {}
    for i, boltPath in ipairs(VFX.assetPaths.boltFrames) do
        print("[VFX] Preloading bolt frame " .. i)
        local boltImg = AssetCache.getImage(boltPath)
        if boltImg then
            table.insert(VFX.assets.boltFrames, boltImg)
        else
            print("[VFX] Warning: Failed to preload bolt frame asset: " .. boltPath)
        end
    end
    
    -- Preload warp frames for the warp effects
    print("[VFX] Preloading warp frame assets")
    VFX.assets.warpFrames = {}
    for i, warpPath in ipairs(VFX.assetPaths.warpFrames) do
        print("[VFX] Preloading warp frame " .. i)
        local warpImg = AssetCache.getImage(warpPath)
        if warpImg then
            table.insert(VFX.assets.warpFrames, warpImg)
        else
            print("[VFX] Warning: Failed to preload warp frame asset: " .. warpPath)
        end
    end
    
    -- Effect definitions keyed by effect name
    VFX.effects = {
        -- Base templates for the rules-driven VFX system
        proj_base = {
            type = "proj_base",
            duration = 1.0,
            particleCount = 30,           -- Increased from 20 for richer visuals
            startScale = 0.5,
            endScale = 0.8,
            color = Constants.Color.GRAY,  -- Default color, will be overridden
            trailLength = 15,             -- Slightly longer trail
            impactSize = 1.2,
            sound = nil,                  -- No default sound
            coreDensity = 0.6,            -- Controls density of center particles (0-1)
            trailDensity = 0.4,           -- Controls density of trail particles (0-1)
            turbulence = 0.5,             -- Random motion factor (0-1)
            arcHeight = 60,               -- Base arc height for trajectories
            particleLifespan = 0.6,       -- How long individual particles last (as fraction of total duration)
            leadingIntensity = 1.5        -- Brightness multiplier for the leading edge
        },

        bolt_base = {
            type = "bolt_base",  -- Template name as type
            duration = 0.8,               -- Faster than standard projectile
            particleCount = 20,           -- Fewer particles since we're using sprites
            startScale = 0.4,
            endScale = 0.7,
            color = Constants.Color.GRAY,  -- Default color, will be overridden
            trailLength = 18,             -- Longer trail for lightning-like effect
            impactSize = 1.3,             -- Slightly larger impact
            sound = nil,                  -- No default sound
            coreDensity = 0.3,            -- Less dense core, since we're using sprites
            trailDensity = 0.4,           -- Less dense trail, since we're using sprites
            turbulence = 0.8,             -- More random motion for lightning effect
            arcHeight = 0,                -- Zero arc height for straight-line trajectory
            straightLine = true,          -- New: Flag for straight-line movement
            particleLifespan = 0.5,       -- Shorter particle lifespan for quick flashes
            leadingIntensity = 1.8,       -- Brighter leading edge
            flickerRate = 12,             -- Rate at which particles flicker (Hz)
            flickerIntensity = 0.3,       -- Intensity of the flicker effect (0-1)
            useSprites = true,            -- Flag to indicate this effect uses sprite frames
            spriteFrameRate = 15,         -- Frames per second for sprite animation
            spriteRotationOffset = 0.78,  -- Radians to rotate the sprite by default (≈45 degrees)
            spriteScale = 0.85,           -- Base scale factor for the sprite
            spriteTint = true,            -- Whether to apply color tinting to sprites
            useSourcePosition = true,     -- Track source (caster) position
            useTargetPosition = true,     -- Track target position
            criticalAssets = {"boltFrames"} -- Mark bolt frames as critical assets to preload
        },

        warp_base = {
            type = "warp_base",           -- Template name as type
            duration = 1.0,                -- Standard duration
            particleCount = 25,            -- Particles for additional effects
            startScale = 0.5,
            endScale = 1.0,
            color = Constants.Color.GRAY, -- Default color, will be overridden
            radius = 80,                   -- Radius for particle effects
            impactSize = 1.5,              -- Slightly larger impact
            sound = nil,                   -- No default sound
            pulseRate = 6.0,               -- Rate of pulsing effect
            useSprites = true,             -- Flag to indicate this effect uses sprite frames
            spriteFrameRate = 10,          -- Frames per second for sprite animation
            spriteScale = 1.0,             -- Base scale factor for the sprite
            spriteTint = true,             -- Whether to apply color tinting to sprites
            rotateSprite = true,           -- Whether to rotate the sprite
            rotationSpeed = 1.2,           -- Rotation speed in radians per second
            drawAtTarget = true,           -- Draw directly at target position
            usePulse = true,               -- Use pulsing effect
            pulseAmount = 0.2,             -- Amount of pulse (scale variation)
            glowIntensity = 0.7,           -- Intensity of the glow effect
            particleDensity = 0.6,         -- How dense the particles should be
            useTargetPosition = true,      -- Track the target's position
            criticalAssets = {"warpFrames"} -- Mark warp frames as critical assets to preload
        },

        beam_base = {
            type = "beam_base",           -- Template name as type
            duration = 1.2,
            particleCount = 25,
            beamWidth = 30,
            startScale = 0.3,
            endScale = 0.9,
            color = Constants.Color.GRAY,  -- Default color, will be overridden
            pulseRate = 3,
            sound = nil,
            useSourcePosition = true,     -- Track source (caster) position
            useTargetPosition = true      -- Track target position
        },

        blast_base = {
            type = "blast_base",          -- Template name as type
            duration = 1.3,               -- Even longer duration for more dramatic impact
            particleCount = 95,           -- More particles for density and impact
            startScale = 0.45,            -- Larger starting scale
            endScale = 1.35,              -- Larger end scale for dramatic growth
            color = Constants.Color.GRAY, -- Default color, will be overridden
            coneAngle = 45,               -- Narrower cone angle (45° instead of 70°)
            coneLength = 320,             -- Much longer range for dramatic reach
            waveCount = 5,                -- More waves for increased visual impact
            waveSpeed = 350,              -- Faster wave propagation
            nearRangeIntensity = 2.2,     -- Stronger intensity multiplier at NEAR range
            matchedElevationIntensity = 1.7, -- Stronger multiplier for matched elevation
            useSourcePosition = true,     -- Track source (caster) position
            motionStyle = Constants.MotionStyle.DIRECTIONAL, -- Directional movement for particles
            waveCrest = true,             -- Enable wave crest visual effect
            waveCrestSize = 2.2,          -- Even larger wave crests
            turbulence = 0.35,            -- Slightly reduced turbulence for more focused beam
            leadingEdgeGlow = true,       -- Add bright leading edge to waves
            particleSizeVariance = 0.6,   -- Greater size variance for particles
            wavePersistence = 0.9,        -- How long waves remain visible (new parameter)
            trailingGlowStrength = 0.8,   -- Strength of glow trail behind waves (new parameter)
            sound = nil,                  -- No default sound
            intensityFalloff = 0.65,      -- Control how quickly intensity drops with distance
            focusedCore = true            -- Concentrate particles in center of cone (new parameter)
        },

        zone_base = {
            type = "zone_base",           -- Template name as type
            duration = 1.0,
            particleCount = 30,
            startScale = 0.4,
            endScale = 1.0,
            color = Constants.Color.GRAY,  -- Default color, will be overridden
            radius = 80,
            pulseRate = 3,
            sound = nil
        },

        util_base = {
            type = "util_base",           -- Template name as type
            duration = 0.8,
            particleCount = 15,
            startScale = 0.3,
            endScale = 0.7,
            color = Constants.Color.GRAY,  -- Default color, will be overridden
            radius = 60,
            pulseRate = 4,
            sound = nil
        },

        surge_base = {
            type = "surge_base",          -- Template name as type
            duration = 1.5,                -- Longer duration for buff visual
            particleCount = 60,            -- More particles for richer effect
            startScale = 0.3,              -- Larger starting scale
            endScale = 0.08,               -- Smaller end scale for fade-out
            color = Constants.Color.YELLOW_HERO,   -- Default color, will be overridden
            height = 200,                  -- Higher fountain effect
            spread = 45,                   -- Narrower spread for more focused fountain
            riseFactor = 1.4,              -- How quickly particles rise (new parameter)
            gravity = 180,                 -- Gravity effect for natural arc (new parameter)
            centerGlow = true,             -- Create glowing core at caster (new parameter)
            centerGlowSize = 50,           -- Size of the center glow
            centerGlowIntensity = 1.3,     -- Intensity of center glow
            spiralMotion = true,           -- Add spiral motion to particles (new parameter)
            spiralTightness = 2.5,         -- How tight the spiral is (new parameter)
            particleSizeVariance = 0.6,    -- Varied particle sizes
            riseAcceleration = 1.2,        -- Particles accelerate as they rise (new parameter)
            bloomEffect = true,            -- Add bloom/glow to particles (new parameter)
            bloomIntensity = 0.8,          -- Intensity of bloom effect (new parameter)
            sparkleChance = 0.4,           -- Chance for sparkle effect on particles (new parameter)
            useSprites = true,             -- Use sprite images
            spriteFrameRate = 8,           -- Frame rate for sprite animation
            pulsateParticles = true,       -- Pulsate particle size (new parameter)
            sound = "surge",               -- Sound effect
            criticalAssets = {"sparkle"}   -- Required assets
        },

        conjure_base = {
            type = "conjure_base",        -- Template name as type
            duration = 0.8,
            particleCount = 35,
            startScale = 0.3,
            endScale = 0.9,
            color = Constants.Color.GRAY,  -- Default color, will be overridden by VisualResolver
            radius = 70,
            height = 120,
            pulseRate = 3,
            sound = nil,
            defaultParticleAsset = "sparkle"
        },

        impact_base = {
            type = "impact_base",         -- Template name as type
            duration = 0.5,
            particleCount = 20,
            startScale = 0.6,
            endScale = 0.3,
            color = Constants.Color.GRAY,  -- Default color, will be overridden
            radius = 40,
            sound = nil
        },

        remote_base = {
            type = "remote_base",         -- Template name as type
            duration = 0.7,
            particleCount = 35,
            startScale = 0.2,
            endScale = 1.0,              -- Larger ending scale for a flash effect
            color = Constants.Color.GRAY,  -- Default color, will be overridden
            radius = 60,                 -- Larger radius than impact
            pulseRate = 2,               -- Add pulse for dynamic flash effect
            intensityMultiplier = 1.8,   -- Brighter than normal effects
            useTargetPosition = true,    -- Always use target position, not source
            trackTargetOffsets = true,   -- Track target's current position including offsets
            sound = nil
        },

        shield_hit_base = {
            type = "shield_hit_base",     -- Template name as type
            duration = 0.8,  -- Slightly longer impact duration
            particleCount = 30, -- More particles
            startScale = 0.5,
            endScale = 1.3,  -- Larger end scale
            color = Constants.Color.GRAY,  -- Default color, will be overridden
            radius = 70,     -- Increased radius
            sound = "shield", -- Use shield sound
            criticalAssets = {"impactRing", "sparkle"} -- Assets needed for shield hit
        },
        
        -- Existing effects
        -- General impact effect (used for many spell interactions)
        impact = {
            type = "impact",              -- Effect name as type
            duration = 0.5,  -- Half second by default
            particleCount = 15,
            startScale = 0.8,
            endScale = 0.2,
            color = Constants.Color.GRAY,
            radius = 30,
            sound = nil  -- No default sound
        },

        meteor = {
            type = "meteor",              -- Effect name as type
            duration = 1.4,
            particleCount = 45,
            startScale = 0.6,
            endScale = 1.2,
            color = Constants.Color.RED_HERO,  -- Crimson red for meteor
            radius = 90,         -- Impact explosion radius
            height = 300,        -- Height from which meteor falls
            spread = 20,         -- Spread of the meteor cluster
            fireTrail = true,    -- Enable fire trail for particles
            impactExplosion = true, -- Create explosion effect on impact
            sound = "meteor_impact",
            defaultParticleAsset = "fireParticle"
        },

        force_blast = {
            type = "force_blast",         -- Effect name as type
            duration = 1.0,
            particleCount = 30,
            startScale = 0.4,
            endScale = 1.5,
            color = Constants.Color.YELLOW_HERO,
            radius = 90,
            sound = "force_wind"
        },

        free_mana = {
            type = "free_mana",           -- Effect name as type
            duration = 1.2,
            particleCount = 40,
            startScale = 0.4,
            endScale = 0.8,
            color = Constants.Color.WHITE,
            radius = 100,
            pulseRate = 4,
            sound = "release"
        },

        shield = {
            type = "shield",              -- Effect name as type
            duration = 1.0,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = Constants.Color.BLUE_HERO,
            radius = 60,
            pulseRate = 3,
            sound = "shield",
            criticalAssets = {"sparkle", "runes", "impactRing"}, -- Assets needed for shields
            shieldType = nil -- Will be set at runtime based on the spell
        },

        -- Emberlift spell effects
        emberlift = {
            type = "emberlift",           -- Effect name as type
            duration = 1.2,
            particleCount = 60,            -- More particles for richer effect
            startScale = 0.3,              -- Larger starting scale
            endScale = 0.08,               -- Smaller end scale for fade-out
            color = Constants.Color.RED_HERO,
            height = 160,                  -- Height for fountain effect
            spread = 45,                   -- Spread for the fountain
            riseFactor = 1.4,              -- How quickly particles rise
            gravity = 180,                 -- Gravity effect for natural arc
            centerGlow = true,             -- Create glowing core at caster
            centerGlowSize = 50,           -- Size of the center glow
            centerGlowIntensity = 1.3,     -- Intensity of center glow
            spiralMotion = true,           -- Add spiral motion to particles
            spiralTightness = 2.5,         -- How tight the spiral is
            particleSizeVariance = 0.6,    -- Varied particle sizes
            riseAcceleration = 1.2,        -- Particles accelerate as they rise
            bloomEffect = true,            -- Add bloom/glow to particles
            bloomIntensity = 0.8,          -- Intensity of bloom effect
            sparkleChance = 0.4,           -- Chance for sparkle effect on particles
            useSprites = true,             -- Use sprite images
            spriteFrameRate = 8,           -- Frame rate for sprite animation
            pulsateParticles = true,       -- Pulsate particle size
            sound = "surge",
            criticalAssets = {"sparkle", "fireParticle"}
        },

        range_change = {
            type = "range_change",         -- Effect name as type
            duration = 1.1,
            particleCount = 50,
            startScale = 0.3,
            endScale = 0.7,
            color = Constants.Color.YELLOW_HERO,
            height = 120,
            spread = 60,
            riseFactor = 1.2,
            gravity = 150,
            centerGlow = true,
            centerGlowSize = 40,
            spiralMotion = true,
            spiralTightness = 2.0,
            particleSizeVariance = 0.5,
            useSprites = true,
            spriteFrameRate = 8,
            sound = "range_shift"
        },

        -- Note: conjurefire will fall through to use the default conjure_base template
    }
    
    -- TODO: Initialize sound effects
    
    -- Create effect pool - each effect is a container object
    Pool.create("vfx_effect", 10, function() return { particles = {} } end, VFX.resetEffect)

    -- Run the diagnostic to ensure the particle pool is healthy
    VFX.runParticlePoolDiagnostic()

    -- Return the VFX table itself
    return VFX
end

-- Reset function for particle objects
function VFX.resetParticle(particle)
    -- Clear all fields
    for k, _ in pairs(particle) do
        particle[k] = nil
    end
    return particle
end

-- Update particle based on motion style
function VFX.updateParticle(particle, effect, dt, particleProgress)
    local Constants = require("core.Constants")
    
    -- If no motion style specified, use default behavior
    local motionStyle = particle.motion or Constants.MotionStyle.RADIAL
    
    -- Time since particle became active
    particle.startTime = (particle.startTime or 0) + dt
    local time = particle.startTime
    
    -- Get base position
    local baseX = particle.baseX or effect.sourceX
    local baseY = particle.baseY or effect.sourceY
    
    -- Apply motion based on style
    if motionStyle == Constants.MotionStyle.RADIAL then
        -- Standard radial outward motion (default)
        -- This behavior is already handled in most effect update functions
        -- Just update existing motion with time factor
        
    elseif motionStyle == Constants.MotionStyle.SWIRL then
        -- Tangential swirl using sine/cosine
        -- Start with the existing direction, then add rotational motion
        local angle = particle.angle or math.atan2(particle.targetY - baseY, particle.targetX - baseX)
        local baseDistance = math.sqrt((particle.targetX - baseX)^2 + (particle.targetY - baseY)^2)
        local distance = baseDistance * particleProgress
        local swirlFactor = 2.0 -- Controls the swirl tightness
        local rotationSpeed = 4.0 -- Controls how fast particles orbit
        
        -- Orbit around the path while moving outward
        local swirlAngle = angle + math.sin(time * rotationSpeed) * swirlFactor
        particle.x = baseX + math.cos(swirlAngle) * distance
        particle.y = baseY + math.sin(swirlAngle) * distance
        
    elseif motionStyle == Constants.MotionStyle.HEX then
        -- Approximated hex grid movement using snapped angles
        -- Move along hex angles (0, 60, 120, 180, 240, 300 degrees)
        local baseAngle = particle.angle or 0
        local hexAngle = math.floor(baseAngle / (math.pi/3)) * (math.pi/3)
        local jitterAmount = 0.2 * math.sin(time * 5) -- Small jitter
        local speed = particle.speed or 100 -- Default speed if not set
        local distance = speed * particleProgress
        
        particle.x = baseX + math.cos(hexAngle + jitterAmount) * distance
        particle.y = baseY + math.sin(hexAngle + jitterAmount) * distance
        
    elseif motionStyle == Constants.MotionStyle.STATIC then
        -- Minimal movement with subtle breathing effect
        local breatheFactor = 0.1 * math.sin(time * 3)
        
        -- Slight offset from original position
        local offsetX = (particle.targetX - baseX) * 0.2 * particleProgress
        local offsetY = (particle.targetY - baseY) * 0.2 * particleProgress
        
        -- Apply breathing effect
        particle.x = baseX + offsetX + math.cos(particle.angle or 0) * breatheFactor
        particle.y = baseY + offsetY + math.sin(particle.angle or 0) * breatheFactor
        
    elseif motionStyle == Constants.MotionStyle.RISE then
        -- Particles float upward
        local speed = particle.speed or 100 -- Default speed if not set
        local horizontalSpeed = speed * 0.3
        local verticalSpeed = speed
        
        particle.x = baseX + math.cos(particle.angle or 0) * horizontalSpeed * particleProgress
        particle.y = baseY - verticalSpeed * particleProgress -- Subtract to move up
        
    elseif motionStyle == Constants.MotionStyle.FALL then
        -- Particles fall downward
        local speed = particle.speed or 100 -- Default speed if not set
        local horizontalSpeed = speed * 0.3
        local verticalSpeed = speed
        local gravity = 100 -- Acceleration factor
        
        particle.x = baseX + math.cos(particle.angle or 0) * horizontalSpeed * particleProgress
        particle.y = baseY + (verticalSpeed * particleProgress + 0.5 * gravity * particleProgress * particleProgress)
        
    elseif motionStyle == Constants.MotionStyle.PULSE then
        -- Particles pulse outward and inward
        local pulseDistance = math.sin(time * 4) * 0.5 + 0.5 -- 0 to 1 pulsing
        local targetDistance = math.sqrt((particle.targetX - baseX)^2 + (particle.targetY - baseY)^2)
        local distance = targetDistance * pulseDistance * particleProgress
        
        particle.x = baseX + math.cos(particle.angle or 0) * distance
        particle.y = baseY + math.sin(particle.angle or 0) * distance
        
        -- Also pulse alpha
        particle.alpha = 0.4 + pulseDistance * 0.6
        
    elseif motionStyle == Constants.MotionStyle.RIPPLE then
        -- Wave-like ripple effect
        local angle = particle.angle or math.atan2(particle.targetY - baseY, particle.targetX - baseX)
        local baseDistance = math.sqrt((particle.targetX - baseX)^2 + (particle.targetY - baseY)^2)
        local distance = baseDistance * particleProgress
        
        -- Add wave effect perpendicular to the radial direction
        local waveAmplitude = 10 * math.sin(distance * 0.1 + time * 5)
        local perpX = -math.sin(angle) * waveAmplitude
        local perpY = math.cos(angle) * waveAmplitude
        
        particle.x = baseX + math.cos(angle) * distance + perpX
        particle.y = baseY + math.sin(angle) * distance + perpY
        
    elseif motionStyle == Constants.MotionStyle.DIRECTIONAL then
        -- Directional movement along a specific path
        -- This simply follows the default trajectory but with less randomness
        local dirX = (particle.targetX or baseX + 100) - baseX
        local dirY = (particle.targetY or baseY) - baseY
        local length = math.sqrt(dirX^2 + dirY^2)
        
        if length > 0 then
            dirX = dirX / length
            dirY = dirY / length
            
            -- Move with consistent speed
            local speed = particle.speed or 100 -- Default speed if not set
            particle.x = baseX + dirX * speed * particleProgress * time
            particle.y = baseY + dirY * speed * particleProgress * time
        end
    end
    
    -- Handle special visual effects for certain motion styles
    if motionStyle == Constants.MotionStyle.PULSE then
        -- Special scaling for pulse motion
        local pulseScale = 0.8 + 0.4 * math.sin(time * 4)
        particle.scale = (effect.startScale + (effect.endScale - effect.startScale) * particleProgress) * pulseScale
    end
end

-- Reset function for effect objects
function VFX.resetEffect(effect)
    -- Only release particles if effect has particles field
    if effect.particles then
        -- Use ParticleManager to safely release all particles
        ParticleManager.releaseAllParticles(effect.particles)
    end

    -- Clear all fields except particles
    effect.name = nil
    effect.type = nil
    effect.sourceX = nil
    effect.sourceY = nil
    effect.targetX = nil
    effect.targetY = nil
    effect.duration = nil
    effect.timer = nil
    effect.progress = nil
    effect.isComplete = nil
    effect.particleCount = nil
    effect.startScale = nil
    effect.endScale = nil
    effect.color = nil
    effect.trailPoints = nil
    effect.sound = nil
    effect.radius = nil
    effect.beamWidth = nil
    effect.height = nil
    effect.pulseRate = nil
    effect.trailLength = nil
    effect.impactSize = nil
    effect.spreadRadius = nil
    effect.options = nil
    effect.coreDensity = nil
    effect.trailDensity = nil
    effect.turbulence = nil
    effect.arcHeight = nil
    effect.particleLifespan = nil
    effect.leadingIntensity = nil
    effect.flickerRate = nil
    effect.flickerIntensity = nil
    effect.useSprites = nil
    effect.spriteFrameRate = nil
    effect.spriteRotationOffset = nil
    effect.spriteScale = nil
    effect.spriteTint = nil
    effect.straightLine = nil
    effect.rotateSprite = nil
    effect.rotationSpeed = nil
    effect.drawAtTarget = nil
    effect.usePulse = nil
    effect.pulseAmount = nil
    effect.glowIntensity = nil
    effect.particleDensity = nil
    effect.beamProgress = nil
    effect.beamLength = nil
    effect.beamAngle = nil
    effect.impactCreated = nil
    effect.manaPoolX = nil
    effect.manaPoolY = nil
    effect.sourceGlow = nil
    effect.poolGlow = nil
    effect.motion = nil
    effect.rangeBand = nil
    effect.elevation = nil
    effect.addons = nil
    effect.spread = nil
    effect.visualProgress = nil
    effect.blockTimerStarted = nil
    effect.blockTimer = nil
    effect.blockInfo = nil
    effect.blockLogged = nil
    effect.impactParticlesCreated = nil

    -- Reset particles array but don't delete it
    effect.particles = {}

    return effect
end

-- Helper function to ensure all effect parameters are valid
function VFX.sanitizeEffectParameters(effectName, sourceX, sourceY, targetX, targetY, options)
    -- Sanitize effect name
    if not effectName or effectName == "" then
        effectName = "impact_base" -- Safe default
        print("[VFX] Warning: Missing effect name, using impact_base as fallback")
    end
    
    -- Sanitize coordinates
    sourceX = sourceX or 0
    sourceY = sourceY or 0
    targetX = targetX or sourceX
    targetY = targetY or sourceY
    
    -- Sanitize options
    options = options or {}
    
    -- Ensure critical fields are present
    options.duration = options.duration or 0.5
    options.scale = options.scale or 1.0
    options.particleCount = options.particleCount or 10
    
    -- For blocked projectiles
    if options.blockInfo then
        options.blockPoint = options.blockPoint or 0.75
    end
    
    -- Always set default color if missing
    if not options.color then
        options.color = {1.0, 1.0, 1.0, 1.0} -- White fallback
    end
    
    -- Return sanitized values
    return effectName, sourceX, sourceY, targetX, targetY, options
end

-- Create a new effect instance
function VFX.createEffect(effectName, sourceX, sourceY, targetX, targetY, options)
    -- Sanitize all parameters to prevent nil errors
    effectName, sourceX, sourceY, targetX, targetY, options = 
        VFX.sanitizeEffectParameters(effectName, sourceX, sourceY, targetX, targetY, options)
    local Constants = require("core.Constants")
    
    -- Enhanced debugging for VFX-R5 implementation
    print("\n====== VFX CREATION CALL ======")
    print("[VFX] CALL STACK: " .. debug.traceback())
    print("[VFX] effectName: " .. tostring(effectName))
    print("[VFX] sourceX: " .. tostring(sourceX) .. " sourceY: " .. tostring(sourceY))
    if targetX and targetY then
        print("[VFX] targetX: " .. tostring(targetX) .. " targetY: " .. tostring(targetY))
    end
    if options then
        print("[VFX] Options:")
        for k, v in pairs(options) do
            if type(v) == "table" then
                print("  " .. k .. ": [table]")
            else
                print("  " .. k .. ": " .. tostring(v))
            end
        end
    end
    print("================================\n")
    
    -- Handle both string and Constants.VFXType format
    local effectNameStr
    
    -- Validate and normalize effectName 
    if type(effectName) ~= "string" then
        print("Error in VFX.createEffect: Effect name must be a string or Constants.VFXType value, got: " .. tostring(effectName))
        -- Fall back to a default effect
        effectNameStr = Constants.VFXType.IMPACT
    else
        effectNameStr = effectName
    end
    
    -- Regular debug output
    print("[VFX] Creating effect: " .. effectNameStr)
    print("[VFX] sourceX: " .. sourceX .. " sourceY: " .. sourceY)
    if targetX and targetY then
        print("[VFX] targetX: " .. targetX .. " targetY: " .. targetY)
    end
    
    -- Process options
    local opts = options or {}
    
    -- Process options.addons if provided (for future work)
    if opts.addons and #opts.addons > 0 then
        for _, addon in ipairs(opts.addons) do
            print("[VFX] TODO addon: " .. tostring(addon))
            -- In future work, we would create or modify effects based on addons
            -- Example: Apply a fire overlay to a projectile, add a sparkle effect, etc.
        end
    end
    
    -- Try to get the effect template first to check for critical assets
    local template = VFX.effects[effectNameStr:lower()]
    if template then
        -- Template exists, check for critical assets
        if template.criticalAssets then
            for _, assetId in ipairs(template.criticalAssets) do
                -- Try to get the asset, will trigger loading if not available
                local asset = VFX.getAsset(assetId)
                if not asset or (assetId == "runes" and #asset == 0) then
                    -- Asset failed to load, try emergency loading
                    print("[VFX] Critical asset missing: " .. assetId .. ", attempting emergency load")
                    
                    -- Emergency loading of critical asset
                    if assetId == "runes" and VFX.assetPaths and VFX.assetPaths.runes then
                        print("[VFX] Emergency loading of rune assets")
                        local AssetCache = require("core.AssetCache")
                        VFX.assets.runes = VFX.assets.runes or {}
                        for i, runePath in ipairs(VFX.assetPaths.runes) do
                            local runeImg = AssetCache.getImage(runePath)
                            if runeImg then
                                table.insert(VFX.assets.runes, runeImg)
                            end
                        end
                    elseif VFX.assetPaths and VFX.assetPaths[assetId] then
                        print("[VFX] Emergency loading of asset: " .. assetId)
                        local AssetCache = require("core.AssetCache")
                        VFX.assets[assetId] = AssetCache.getImage(VFX.assetPaths[assetId])
                    end
                end
            end
        end
    else
        -- Backward compatibility for effects without templates that may need runes
        -- (e.g., mistveil, effects with "ward" in the name)
        if effectNameStr:lower():find(Constants.ShieldType.WARD) or effectNameStr:lower() == "mistveil" then
            -- Ensure runes are loaded for ward-related effects
            local runeAssets = VFX.getAsset("runes")
            if not runeAssets or #runeAssets == 0 then
                print("[VFX] Warning: Ward effect requested but rune assets not available.")
                -- Force-load runes
                if VFX.assetPaths and VFX.assetPaths.runes then
                    local AssetCache = require("core.AssetCache")
                    VFX.assets.runes = {}
                    for i, runePath in ipairs(VFX.assetPaths.runes) do
                        print("[VFX] Emergency loading of rune asset: " .. i)
                        local runeImg = AssetCache.getImage(runePath)
                        if runeImg then
                            table.insert(VFX.assets.runes, runeImg)
                        end
                    end
                end
            end
        end
    end
    
    -- Get or reuse effect template - use :lower() safely now that we've verified it's a string
    if not template then -- Only if we didn't already get it above
        template = VFX.effects[effectNameStr:lower()]
        if not template then
            print("Warning: Effect not found: " .. effectNameStr)
            -- Fall back to impact effect if available
            template = VFX.effects[Constants.VFXType.IMPACT]
            if not template then
                return nil -- Give up if no fallback is available
            end
            print("[VFX] Falling back to '" .. Constants.VFXType.IMPACT .. "' effect")
        end
    end
    
    -- Create a new effect instance from pool
    local effect = Pool.acquire("vfx_effect")
    effect.name = effectName
    effect.type = template.type
    effect.sourceX = sourceX
    effect.sourceY = sourceY
    effect.targetX = targetX or sourceX
    effect.targetY = targetY or sourceY
    
    -- Store source and target entities for position tracking if provided in options
    if options and options.sourceEntity then
        effect.sourceEntity = options.sourceEntity
        
        -- Initialize with source position including offsets if available
        if effect.sourceEntity.currentXOffset and effect.sourceEntity.currentYOffset then
            effect.sourceX = effect.sourceEntity.x + effect.sourceEntity.currentXOffset
            effect.sourceY = effect.sourceEntity.y + effect.sourceEntity.currentYOffset
        end
    end
    
    if options and options.targetEntity then
        effect.targetEntity = options.targetEntity
        
        -- Initialize with target position including offsets if available
        if effect.targetEntity.currentXOffset and effect.targetEntity.currentYOffset then
            effect.targetX = effect.targetEntity.x + effect.targetEntity.currentXOffset
            effect.targetY = effect.targetEntity.y + effect.targetEntity.currentYOffset
        end
    end
    
    -- Flag for effects that should use target's actual position including offsets
    effect.trackTargetOffsets = (options and options.trackTargetOffsets) or (template and template.trackTargetOffsets) or false
    
    -- Flag for effects that should use source position tracking
    effect.useSourcePosition = (options and options.useSourcePosition) or (template and template.useSourcePosition) or false
    
    -- Flag for effects that should use target position tracking
    effect.useTargetPosition = (options and options.useTargetPosition) or (template and template.useTargetPosition) or false
    
    -- Timing
    -- Prioritize duration from options (EventRunner), then template, then fallback.
    if options and options.duration then
        effect.duration = options.duration
    elseif template.duration then
        effect.duration = template.duration
    else
        effect.duration = 0.5 -- Absolute fallback if no duration anywhere
        print("[VFX] Warning: Effect " .. effectNameStr .. " has no duration in options or template. Defaulting to 0.5s.")
    end
    effect.timer = 0
    effect.progress = 0
    effect.isComplete = false
    
    -- Visual properties (copied from template)
    effect.particleCount = template.particleCount
    effect.startScale = template.startScale
    effect.endScale = template.endScale
    effect.color = {template.color[1], template.color[2], template.color[3], template.color[4]}
    
    -- Store shield block information if provided (for projectile block visuals)
    if options and options.blockInfo then
        print("[VFX] Effect has blockInfo - will show shield block visuals")
        effect.blockInfo = options.blockInfo
        effect.options = effect.options or {}
        effect.options.blockPoint = options.blockPoint or 0.75 -- Default to 75% of the way
        effect.options.shieldType = options.blockInfo.blockType or (options.shieldType or "ward")
        
        -- Enhanced debugging for shield block effects
        print(string.format("[VFX] Created blocked effect '%s' with blockPoint=%.2f and shieldType=%s", 
            effectName, effect.options.blockPoint, effect.options.shieldType or "unknown"))
    elseif options and options.blockPoint then
        -- Fallback for cases where blockPoint is provided without blockInfo
        print("[VFX] Effect has blockPoint but no blockInfo - creating minimal blockInfo")
        effect.options = effect.options or {}
        effect.options.blockPoint = options.blockPoint
        effect.options.shieldType = options.shieldType or "ward"
        effect.blockInfo = {
            blockable = true,
            blockType = options.shieldType or "ward",
            blockPoint = options.blockPoint
        }
        
        -- Enhanced debugging for fallback shield block effects
        print(string.format("[VFX] Created fallback blocked effect '%s' with blockPoint=%.2f", 
            effectName, effect.options.blockPoint))
    elseif options and options.tags and options.tags.SHIELD_BLOCKED then
        -- Ultra fallback for SHIELD_BLOCKED tag without proper blockInfo
        print("[VFX] Effect has SHIELD_BLOCKED tag but no blockInfo or blockPoint - creating default blockInfo")
        effect.options = effect.options or {}
        effect.options.blockPoint = 0.75
        effect.options.shieldType = options.shieldType or "ward"
        effect.blockInfo = {
            blockable = true,
            blockType = options.shieldType or "ward",
            blockPoint = 0.75
        }
        
        -- Enhanced debugging for ultra fallback shield block effects
        print(string.format("[VFX] Created ultra fallback blocked effect '%s' with default blockPoint=0.75", 
            effectName))
    end
    
    -- Apply options modifiers
    if opts.color then
        -- Override color with the provided color
        effect.color = {opts.color[1], opts.color[2], opts.color[3], opts.color[4] or 1.0}
    end
    
    if opts.scale then
        -- Apply scale factor to particle counts, sizes, radii, etc.
        local scaleFactor = opts.scale
        effect.particleCount = math.floor(effect.particleCount * scaleFactor)
        effect.startScale = effect.startScale * scaleFactor
        effect.endScale = effect.endScale * scaleFactor
        if effect.radius then effect.radius = effect.radius * scaleFactor end
        if effect.beamWidth then effect.beamWidth = effect.beamWidth * scaleFactor end
        if effect.height then effect.height = effect.height * scaleFactor end
        if effect.spread then effect.spread = effect.spread * scaleFactor end
    end
    
    -- Store motion style and positional info
    effect.motion = opts.motion
    effect.rangeBand = opts.rangeBand
    effect.elevation = opts.elevation
    effect.addons = opts.addons
    
    -- Effect specific properties
    effect.particles = {}
    effect.trailPoints = {}
    
    -- Sound
    effect.sound = template.sound
    
    -- Additional properties based on effect type
    effect.radius = template.radius
    effect.beamWidth = template.beamWidth
    effect.height = template.height
    effect.pulseRate = template.pulseRate
    effect.trailLength = template.trailLength
    effect.impactSize = template.impactSize
    effect.spreadRadius = template.spreadRadius
    effect.spread = template.spread
    effect.coreDensity = template.coreDensity
    effect.trailDensity = template.trailDensity
    effect.turbulence = template.turbulence
    effect.arcHeight = template.arcHeight
    effect.particleLifespan = template.particleLifespan
    effect.leadingIntensity = template.leadingIntensity
    effect.flickerRate = template.flickerRate
    effect.flickerIntensity = template.flickerIntensity
    effect.useSprites = template.useSprites
    effect.spriteFrameRate = template.spriteFrameRate
    effect.spriteRotationOffset = template.spriteRotationOffset
    effect.spriteScale = template.spriteScale
    effect.spriteTint = template.spriteTint
    effect.straightLine = template.straightLine
    effect.rotateSprite = template.rotateSprite
    effect.rotationSpeed = template.rotationSpeed
    effect.drawAtTarget = template.drawAtTarget
    effect.usePulse = template.usePulse
    effect.pulseAmount = template.pulseAmount
    effect.glowIntensity = template.glowIntensity
    effect.particleDensity = template.particleDensity
    
    -- Optional overrides
    effect.options = options or {}
    
    -- Initialize particles based on effect type
    VFX.initializeParticles(effect)
    
    -- Play sound effect if available
    if effect.sound and VFX.sounds and VFX.sounds[effect.sound] then
        -- Will play sound when implemented
    end
    
    -- Add to active effects list
    table.insert(VFX.activeEffects, effect)
    
    return effect
end

-- Initialize particles based on effect type
-- Helper function to ensure particle has all required properties
function VFX.ensureParticleDefaults(particle)
    -- Safety defaults for mandatory properties
    particle.delay = particle.delay or 0
    particle.active = particle.active or false
    particle.startTime = particle.startTime or 0
    particle.scale = particle.scale or 1.0
    particle.alpha = particle.alpha or 1.0
    particle.rotation = particle.rotation or 0
    particle.isCore = particle.isCore or false
    return particle
end

function VFX.initializeParticles(effect)
    return initializeParticlesModule(effect)
end
-- Update all active effects
function VFX.update(dt)
    local i = 1
    
    -- Safety check
    if not VFX.activeEffects then 
        VFX.activeEffects = {}
        return
    end
    
    while i <= #VFX.activeEffects do
        local effect = VFX.activeEffects[i]
        
        -- Skip invalid effects
        if not effect then
            table.remove(VFX.activeEffects, i)
            goto next_effect
        end
        
        -- Update effect timer
        -- Make sure we have valid values
        effect.timer = effect.timer or 0
        effect.duration = effect.duration or 0.5
        
        -- Update timer
        effect.timer = effect.timer + dt
        
        -- Update positions based on tracked entities
        -- First check source position updates
        if effect.useSourcePosition and effect.sourceEntity then
            -- Check for wizard-specific position offsets
            if effect.sourceEntity.currentXOffset and effect.sourceEntity.currentYOffset then
                -- Update source position with offsets
                effect.sourceX = effect.sourceEntity.x + effect.sourceEntity.currentXOffset
                effect.sourceY = effect.sourceEntity.y + effect.sourceEntity.currentYOffset
            end
        end
        
        -- Then check target position updates
        if effect.useTargetPosition and effect.targetEntity then
            -- Check for wizard-specific position offsets
            if effect.targetEntity.currentXOffset and effect.targetEntity.currentYOffset then
                -- Update target position with offsets
                effect.targetX = effect.targetEntity.x + effect.targetEntity.currentXOffset
                effect.targetY = effect.targetEntity.y + effect.targetEntity.currentYOffset
            end
        end
        
        -- Only calculate progress if duration is valid
        if effect.duration > 0 then
            effect.progress = math.min(effect.timer / effect.duration, 1.0)
        else
            effect.progress = effect.timer -- Fallback when duration is 0
            print("[VFX] Warning: Effect has invalid duration: " .. tostring(effect.duration))
        end
        
        -- Handle shield block effects with improved safeguards
        local isBlocked = effect.options and effect.options.blockPoint

        -- Mark effect as blocked if necessary
        if isBlocked and not effect.isBlocked then
            effect.isBlocked = true
            print("[VFX] Setting effect.isBlocked = true for projectile")
        end

        -- Debug to verify blocked effect tracking
        if isBlocked and effect.timer == dt then  -- First update frame
            print(string.format("[VFX] Tracking blocked effect '%s' with blockPoint=%.2f",
                effect.name or "unknown", effect.options.blockPoint))
        end
        
        if isBlocked then
            -- Ensure these fields exist to prevent runtime errors
            if not effect.type then effect.type = effect.name or "projectile" end
            if not effect.options then effect.options = {} end
            if not effect.options.blockPoint then effect.options.blockPoint = 0.75 end
            
            -- NEW: Instead of immediately setting progress to blockPoint, use a visual progress tracker
            -- This allows the projectile to follow a natural trajectory
            if not effect.visualProgress then
                -- Initialize visualProgress at the beginning (first frame)
                effect.visualProgress = 0
                print("[VFX] Initializing blocked projectile trajectory")
            end
            
            -- Update visualProgress for smooth animation - speed up slightly for gameplay feel
            effect.visualProgress = effect.visualProgress + dt * (1/effect.duration) * 1.2
            
            -- Clamp visualProgress at the block point
            effect.visualProgress = math.min(effect.visualProgress, effect.options.blockPoint)
            
            -- Determine if effect should be blocked - check if visualProgress reached blockPoint
            local shouldStartBlock = not effect.blockTimerStarted and effect.visualProgress >= effect.options.blockPoint - 0.01
            
            -- Start the block effect when we reach the block point
            if shouldStartBlock then
                -- Mark the start of block timing
                effect.blockTimerStarted = true
                effect.blockTimer = 0
                
                -- Lock progress at block point to show projectile stopping
                effect.visualProgress = effect.options.blockPoint
                
                -- Enhanced debugging
                print(string.format("[VFX] Effect '%s' blocked at %.2f, starting shield impact sequence", 
                    effect.name or "unknown", effect.options.blockPoint))
                
                -- Create shield impact effect
                if not effect.impactParticlesCreated and effect.type == "projectile" then
                    effect.impactParticlesCreated = true
                    
                    -- Calculate impact position 
                    local progress = effect.options.blockPoint
                    local impactX = effect.sourceX + (effect.targetX - effect.sourceX) * progress
                    local impactY = effect.sourceY + (effect.targetY - effect.sourceY) * progress
                    
                    -- Create a separate shield hit effect
                    print(string.format("[VFX] Creating shield hit effect at (%.1f, %.1f)", impactX, impactY))
                    
                    -- Determine shield color based on shield type
                    local shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Default yellow
                    if effect.options.shieldType == "ward" then
                        shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards 
                    elseif effect.options.shieldType == "field" then
                        shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
                    end
                    
                    -- Make the impact more dramatically visible to the player
                    -- Use impact_base or a fallback effect
                    local impactEffect = "impact_base"
                    
                    -- Impact flash effect
                    local flashParams = {
                        duration = 0.3,
                        scale = (effect.startScale or 1.0) * 1.5,
                        color = {shieldColor[1], shieldColor[2], shieldColor[3], 0.9},
                        particleCount = 1
                    }
                    VFX.createEffect(impactEffect, impactX, impactY, impactX, impactY, flashParams)
                    
                    -- Particle burst effect 
                    local burstParams = {
                        duration = 0.8,
                        scale = (effect.startScale or 1.0) * 1.2,
                        color = shieldColor,
                        particleCount = 30
                    }
                    VFX.createEffect(impactEffect, impactX, impactY, impactX, impactY, burstParams)
                    
                    -- No need to add particles to current effect
                    print("[VFX] Created shield impact effects")
                    
                    -- Trigger screen shake at the exact moment of shield impact
                    print("[VFX] Attempting to trigger screen shake for shield block")
                    
                    -- Get the game state reference from the effect options if available
                    local gameState = nil
                    
                    -- First try to use the directly passed gameState if available
                    if effect.options and effect.options.gameState then
                        print("[VFX] Found gameState directly in options")
                        gameState = effect.options.gameState
                    -- Next try through sourceEntity
                    elseif effect.options and effect.options.sourceEntity and effect.options.sourceEntity.gameState then
                        print("[VFX] Found gameState through sourceEntity")
                        gameState = effect.options.sourceEntity.gameState
                    -- Next try through targetEntity
                    elseif effect.options and effect.options.targetEntity and effect.options.targetEntity.gameState then
                        print("[VFX] Found gameState through targetEntity")
                        gameState = effect.options.targetEntity.gameState
                    -- Finally try the global game object
                    else
                        -- Try to find it through the global game object
                        print("[VFX] No entity references found, looking for global game object")
                        if _G.game then
                            print("[VFX] Found global game object via _G.game")
                            gameState = _G.game
                        elseif game then -- Try directly referencing the global variable 
                            print("[VFX] Found global game object via direct access")
                            gameState = game
                        -- As a last resort, use the VFX module's stored reference
                        elseif VFX.gameState then
                            print("[VFX] Using VFX.gameState reference")
                            gameState = VFX.gameState
                        end
                    end
                    
                    -- Check if we have game state and trigger methods
                    if gameState then
                        print("[VFX] GameState found. Has triggerShake: " .. tostring(gameState.triggerShake ~= nil))
                    else
                        print("[VFX] No gameState found for triggering shake!")
                    end
                    
                    -- Determine impact amount for shake intensity (from effect or default)
                    local amount = effect.options.amount or 10
                    local intensity = math.min(4, 2 + (amount / 20))
                    local shakeDuration = 0.2
                    
                    -- Trigger shake if we have access to the game state
                    if gameState and gameState.triggerShake then
                        -- Trigger a light shake for shield blocks via gameState
                        print(string.format("[VFX] About to call gameState.triggerShake(%.2f, %.2f)", shakeDuration, intensity))
                        gameState.triggerShake(shakeDuration, intensity)
                        print(string.format("[VFX] Shield block impact! Triggered light shake (%.2f, %.2f) at blockPoint=%.2f", 
                            shakeDuration, intensity, effect.options.blockPoint or 0))
                    elseif VFX.triggerShake then
                        -- Use the VFX module's direct function reference
                        print(string.format("[VFX] About to call VFX.triggerShake(%.2f, %.2f)", shakeDuration, intensity))
                        VFX.triggerShake(shakeDuration, intensity)
                        print(string.format("[VFX] Shield block impact! Triggered light shake via VFX.triggerShake"))
                    else
                        -- Last resort: Try to use the global function directly
                        if _G.triggerShake then
                            print(string.format("[VFX] About to call global triggerShake(%.2f, %.2f)", shakeDuration, intensity))
                            _G.triggerShake(shakeDuration, intensity)
                            print("[VFX] Called global triggerShake function")
                        else
                            print("[VFX] Could not trigger shake - no valid triggerShake function found")
                        end
                    end
                end
            end
            
            -- Once block is triggered, increment a block timer
            if effect.blockTimerStarted then
                effect.blockTimer = effect.blockTimer + dt
                -- Keep the effect alive until the block timer elapses
                if effect.blockTimer > 1.2 then
                    -- After the hold period, mark the effect complete
                    effect.progress = 1.0
                    print(string.format("[VFX] Blocked effect '%s' cleanup - forcing completion", effect.name or "unknown"))
                else
                    -- Lock both visual and logical progress at the block point so the effect isn't removed early
                    effect.visualProgress = effect.options.blockPoint
                    effect.progress = math.min(effect.progress, effect.options.blockPoint)
                end
            end
        end
        
        -- Update target position if tracking offsets and we have a target entity
        if effect.trackTargetOffsets and effect.targetEntity then
            -- Include wizard offsets in target position
            local targetWizard = effect.targetEntity
            if targetWizard and targetWizard.x and targetWizard.y then
                local xOffset = targetWizard.currentXOffset or 0
                local yOffset = targetWizard.currentYOffset or 0
                
                -- Update the effect's target position to follow the wizard
                effect.targetX = targetWizard.x + xOffset
                effect.targetY = targetWizard.y + yOffset
            end
        end
        
        -- Update effect based on type using the dispatcher
        local effectType = effect.type
        local updater = VFX.updaters[effectType]
        if updater then
            -- Add safety pcall to prevent crashes
            local success, err = pcall(function()
                updater(effect, dt)
            end)

            if not success then
                print(string.format("[VFX] Error updating effect type '%s': %s", tostring(effectType), tostring(err)))
            end
        else
            -- Fallback or warning for unhandled types
            print("[VFX] Warning: No updater found for VFX type: " .. tostring(effectType))
        end
        
        -- Remove effect if complete
        if effect.progress >= 1.0 then
            -- Execute onComplete callback if it exists
            if effect.options and effect.options.onComplete then
                print("[VFX] Executing onComplete callback for effect: " .. (effect.name or "unnamed"))
                local success, err = pcall(function()
                    effect.options.onComplete(effect)
                end)
                
                if not success then
                    print("[VFX] Error in onComplete callback: " .. tostring(err))
                end
            end
            
            -- Release the effect and its particles back to their pools
            local removedEffect = table.remove(VFX.activeEffects, i)
            Pool.release("vfx_effect", removedEffect)
        else
            i = i + 1
        end
        
        ::next_effect::
        -- Continue label for the loop
    end
end

-- Draw all active effects
function VFX.draw()
    for _, effect in ipairs(VFX.activeEffects) do
        local effectType = effect.type
        local drawer = VFX.drawers[effectType]
        if drawer then
            -- Add safety pcall to prevent crashes
            local success, err = pcall(function()
                drawer(effect)
            end)

            if not success then
                print(string.format("[VFX] Error drawing effect type '%s': %s", tostring(effectType), tostring(err)))
            end
        else
            -- Fallback or warning for unhandled types
            print("[VFX] Warning: No drawer found for VFX type: " .. tostring(effectType))
        end
    end
end
-- Helper function for HSV to RGB conversion (for volatile conjuring rainbow effect)
function HSVtoRGB(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r, g, b
end

-- Show Pool stats in debug mode
function VFX.showPoolStats()
    print("\n=== VFX POOLS STATS ===")
    print(string.format("Active Effects: %d", #VFX.activeEffects))
    print(string.format("Particle Pool Size: %d (Available: %d, Active: %d)",
        Pool.size("vfx_particle"), Pool.available("vfx_particle"), Pool.activeCount("vfx_particle")))
    print(string.format("Effect Pool Size: %d (Available: %d, Active: %d)",
        Pool.size("vfx_effect"), Pool.available("vfx_effect"), Pool.activeCount("vfx_effect")))

    -- Check for potential issues
    local particlePoolActiveCount = Pool.activeCount("vfx_particle")
    local activeParticlesCount = 0

    -- Count actual particles in active effects
    for _, effect in ipairs(VFX.activeEffects) do
        if effect.particles then
            activeParticlesCount = activeParticlesCount + #effect.particles
        end
    end

    -- Report if there's a mismatch
    if particlePoolActiveCount > activeParticlesCount then
        print(string.format("WARNING: Pool reports %d active particles but only %d found in effects",
            particlePoolActiveCount, activeParticlesCount))
        print("This suggests particles are not being properly released back to the pool")
    elseif particlePoolActiveCount < activeParticlesCount then
        print(string.format("WARNING: Found %d particles in effects but pool only reports %d active",
            activeParticlesCount, particlePoolActiveCount))
        print("This suggests particles are being created without using Pool.acquire")
    end

    -- Check particle creation and usage rate
    local creates = Pool.stats.creates["vfx_particle"] or 0
    local acquires = Pool.stats.acquires["vfx_particle"] or 0

    if creates > 0 and acquires > 0 then
        local reuseRate = (acquires - creates) / acquires * 100
        print(string.format("Particle Reuse Rate: %.1f%% (Lower is worse)", reuseRate))

        if reuseRate < 50 then
            print("WARNING: Low particle reuse rate suggests pool is too small or particles aren't being released properly")
        end
    end
end

-- Create an effect with async callback support
-- Currently just a stub - in the future, this could use coroutines or callbacks for complex effects
function VFX.createEffectAsync(effectName, sourceX, sourceY, targetX, targetY, options)
    -- Create the effect normally
    local effect = VFX.createEffect(effectName, sourceX, sourceY, targetX, targetY, options)
    
    -- Return a "promise-like" table with callback support
    return {
        effect = effect,  -- Store a reference to the actual effect
        
        -- Method to register a callback for when the effect completes
        onComplete = function(callback)
            print("[VFX] Async VFX callback registered (stub)")
            -- In a full implementation, this would store the callback and call it 
            -- when the effect completes (tracked via effect.progress reaching 1.0)
            return effect
        end
    }
end

-- Diagnostic function to run on game startup to detect and fix particle pool issues
function VFX.runParticlePoolDiagnostic()
    print("\n=== VFX PARTICLE POOL DIAGNOSTIC ===")
    local stats = ParticleManager.getStats()
    print(string.format("Particle Pool: %d total (%d active, %d available)",
        stats.poolSize, stats.active, stats.available))

    -- Check for active particles that aren't in use
    if stats.active > 0 and #VFX.activeEffects == 0 then
        print("WARNING: Pool reports active particles but no active effects exist")
        print("This suggests particles weren't released properly in a previous session")

        -- Force reset the pool
        print("Resetting particle pool to fix the issue...")
        Pool.clear("vfx_particle")

        -- Recreate with initial size
        Pool.create("vfx_particle", 100, function() return {} end, VFX.resetParticle)

        print("Pool reset complete")
    end

    -- Test particle acquisition and release
    print("Testing particle acquisition and release...")
    local testParticle = ParticleManager.createParticle()
    if testParticle then
        print("Successfully acquired test particle from pool")
        if ParticleManager.releaseParticle(testParticle) then
            print("Successfully released test particle back to pool")
        else
            print("ERROR: Failed to release test particle")
        end
    else
        print("ERROR: Failed to acquire test particle from pool")
    end

    print("Diagnostic complete!")
end

-- Import effect modules
local ProjectileEffect = require("vfx.effects.projectile")
local ImpactEffect = require("vfx.effects.impact")
local BeamEffect = require("vfx.effects.beam")
local ConeEffect = require("vfx.effects.cone")
local AuraEffect = require("vfx.effects.aura")
local ConjureEffect = require("vfx.effects.conjure")
local SurgeEffect = require("vfx.effects.surge")
local RemoteEffect = require("vfx.effects.remote")
local MeteorEffect = require("vfx.effects.meteor")

-- Initialize the updaters table with update functions
-- Map each template name/type to the appropriate handler
VFX.updaters["proj_base"] = ProjectileEffect.update  -- Generic projectile template
VFX.updaters["bolt_base"] = ProjectileEffect.update  -- Bolt uses projectile logic
VFX.updaters["impact_base"] = ImpactEffect.update    -- Impact effect template
VFX.updaters["beam_base"] = BeamEffect.update        -- Beam effect template
VFX.updaters["blast_base"] = ConeEffect.update       -- Blast uses cone logic
VFX.updaters["zone_base"] = AuraEffect.update        -- Zone uses aura logic
VFX.updaters["util_base"] = AuraEffect.update        -- Utility uses aura logic
VFX.updaters["surge_base"] = SurgeEffect.update      -- Surge fountain template
VFX.updaters["conjure_base"] = ConjureEffect.update  -- Conjuration template
VFX.updaters["remote_base"] = RemoteEffect.update    -- Remote effect template
VFX.updaters["warp_base"] = RemoteEffect.update      -- Warp uses remote logic
VFX.updaters["shield_hit_base"] = ImpactEffect.update -- Shield hit template

-- Specific effect templates
VFX.updaters["meteor"] = MeteorEffect.update         -- Meteor effect
VFX.updaters["impact"] = ImpactEffect.update         -- Generic impact
VFX.updaters["force_blast"] = ImpactEffect.update    -- Force blast uses impact logic
VFX.updaters["free_mana"] = AuraEffect.update        -- Free mana uses aura logic
VFX.updaters["shield"] = AuraEffect.update           -- Shield uses aura logic
VFX.updaters["emberlift"] = SurgeEffect.update       -- Emberlift uses surge logic
VFX.updaters["range_change"] = SurgeEffect.update    -- Range change uses surge logic

-- Add backward compatibility for critical legacy code paths
-- These keys will be removed in a future update
VFX.updaters[Constants.AttackType.PROJECTILE] = ProjectileEffect.update

-- Initialize the drawers table with draw functions
VFX.drawers["proj_base"] = ProjectileEffect.draw    -- Generic projectile template
VFX.drawers["bolt_base"] = ProjectileEffect.draw    -- Bolt uses projectile logic
VFX.drawers["impact_base"] = ImpactEffect.draw      -- Impact effect template
VFX.drawers["beam_base"] = BeamEffect.draw          -- Beam effect template
VFX.drawers["blast_base"] = ConeEffect.draw         -- Blast uses cone logic
VFX.drawers["zone_base"] = AuraEffect.draw          -- Zone uses aura logic
VFX.drawers["util_base"] = AuraEffect.draw          -- Utility uses aura logic
VFX.drawers["surge_base"] = SurgeEffect.draw        -- Surge fountain template
VFX.drawers["conjure_base"] = ConjureEffect.draw    -- Conjuration template
VFX.drawers["remote_base"] = RemoteEffect.draw      -- Remote effect template
VFX.drawers["warp_base"] = RemoteEffect.draw        -- Warp uses remote logic
VFX.drawers["shield_hit_base"] = ImpactEffect.draw  -- Shield hit template

-- Specific effect templates
VFX.drawers["meteor"] = MeteorEffect.draw           -- Meteor effect
VFX.drawers["impact"] = ImpactEffect.draw           -- Generic impact
VFX.drawers["force_blast"] = ImpactEffect.draw      -- Force blast uses impact logic
VFX.drawers["free_mana"] = AuraEffect.draw          -- Free mana uses aura logic
VFX.drawers["shield"] = AuraEffect.draw             -- Shield uses aura logic
VFX.drawers["emberlift"] = SurgeEffect.draw         -- Emberlift uses surge logic
VFX.drawers["range_change"] = SurgeEffect.draw      -- Range change uses surge logic

-- Add backward compatibility for critical legacy code paths
-- These keys will be removed in a future update
VFX.drawers[Constants.AttackType.PROJECTILE] = ProjectileEffect.draw

return VFX