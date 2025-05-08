-- VFX.lua
-- Visual effects module for spell animations and combat effects

local VFX = {}
VFX.__index = VFX

-- Import dependencies
local Pool = require("core.Pool")
local Constants = require("core.Constants")
local AssetCache = require("core.AssetCache")

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
            type = Constants.AttackType.PROJECTILE,
            duration = 1.0,
            particleCount = 30,           -- Increased from 20 for richer visuals
            startScale = 0.5,
            endScale = 0.8,
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
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
            type = Constants.AttackType.PROJECTILE,  -- Still uses projectile logic
            duration = 0.8,               -- Faster than standard projectile
            particleCount = 20,           -- Fewer particles since we're using sprites
            startScale = 0.4,
            endScale = 0.7,
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
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
            type = "remote",               -- Uses remote effect type (action at a distance)
            duration = 1.0,                -- Standard duration
            particleCount = 25,            -- Particles for additional effects
            startScale = 0.5,
            endScale = 1.0,
            color = Constants.Color.SMOKE, -- Default color, will be overridden
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
            type = "beam",
            duration = 1.2,
            particleCount = 25,
            beamWidth = 30,
            startScale = 0.3,
            endScale = 0.9,
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
            pulseRate = 3,
            sound = nil,
            useSourcePosition = true,     -- Track source (caster) position
            useTargetPosition = true      -- Track target position
        },
        
        blast_base = {
            type = "cone",                -- Cone-shaped blast effect
            duration = 1.3,               -- Even longer duration for more dramatic impact
            particleCount = 95,           -- More particles for density and impact
            startScale = 0.45,            -- Larger starting scale
            endScale = 1.35,              -- Larger end scale for dramatic growth
            color = Constants.Color.SMOKE, -- Default color, will be overridden
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
            type = "aura",
            duration = 1.0,
            particleCount = 30,
            startScale = 0.4,
            endScale = 1.0,
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
            radius = 80,
            pulseRate = 3,
            sound = nil
        },
        
        util_base = {
            type = "aura",
            duration = 0.8,
            particleCount = 15,
            startScale = 0.3,
            endScale = 0.7,
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
            radius = 60,
            pulseRate = 4,
            sound = nil
        },
        
        surge_base = {
            type = "surge",
            duration = 1.5,                -- Longer duration for buff visual
            particleCount = 60,            -- More particles for richer effect
            startScale = 0.3,              -- Larger starting scale
            endScale = 0.08,               -- Smaller end scale for fade-out
            color = Constants.Color.SKY,   -- Default color, will be overridden
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
            type = "conjure",
            duration = 0.8,
            particleCount = 35,
            startScale = 0.3,
            endScale = 0.9,
            color = Constants.Color.SMOKE,  -- Default color, will be overridden by VisualResolver
            radius = 70,
            height = 120,
            pulseRate = 3,
            sound = nil,
            defaultParticleAsset = "sparkle"
        },
        
        impact_base = {
            type = "impact",
            duration = 0.5,
            particleCount = 20,
            startScale = 0.6,
            endScale = 0.3,
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
            radius = 40,
            sound = nil
        },
        
        remote_base = {
            type = "impact",
            duration = 0.7,
            particleCount = 35,
            startScale = 0.2,
            endScale = 1.0,              -- Larger ending scale for a flash effect
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
            radius = 60,                 -- Larger radius than impact
            pulseRate = 2,               -- Add pulse for dynamic flash effect
            intensityMultiplier = 1.8,   -- Brighter than normal effects
            useTargetPosition = true,    -- Always use target position, not source
            trackTargetOffsets = true,   -- Track target's current position including offsets
            sound = nil
        },
        
        shield_hit_base = {
            type = "impact",
            duration = 0.8,  -- Slightly longer impact duration
            particleCount = 30, -- More particles
            startScale = 0.5,
            endScale = 1.3,  -- Larger end scale
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
            radius = 70,     -- Increased radius
            sound = "shield", -- Use shield sound
            criticalAssets = {"impactRing", "sparkle"} -- Assets needed for shield hit
        },
        
        -- Existing effects
        -- General impact effect (used for many spell interactions)
        impact = {
            type = "impact",
            duration = 0.5,  -- Half second by default
            particleCount = 15,
            startScale = 0.8,
            endScale = 0.2,
            color = Constants.Color.SMOKE,  -- Default white -> SMOKE
            radius = 30,
            sound = nil  -- No default sound
        },
        
        meteor = {
            type = "meteor",
            duration = 1.4,
            particleCount = 45,
            startScale = 0.6,
            endScale = 1.2,
            color = Constants.Color.CRIMSON,  -- Crimson red for meteor
            radius = 90,         -- Impact explosion radius
            height = 300,        -- Height from which meteor falls
            spread = 20,         -- Spread of the meteor cluster
            fireTrail = true,    -- Enable fire trail for particles
            impactExplosion = true, -- Create explosion effect on impact
            sound = "meteor_impact",
            defaultParticleAsset = "fireParticle"
        },
        
        force_blast = {
            type = "impact",
            duration = 1.0,
            particleCount = 30,
            startScale = 0.4,
            endScale = 1.5,
            color = Constants.Color.YELLOW,  -- Blue-ish for force theme -> YELLOW
            radius = 90,
            sound = "force_wind"
        },
        
        -- Free Mana - special effect when freeing all spells
        free_mana = {
            type = "aura",
            duration = 1.2,
            particleCount = 40,
            startScale = 0.4,
            endScale = 0.8,
            color = Constants.Color.BONE,  -- Bright blue for freeing mana -> SKY
            radius = 100,
            pulseRate = 4,
            sound = "release"
        },
        
        -- Shield effect (used for barrier or ward shield activation)
        shield = {
            type = "aura",
            duration = 1.0,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = Constants.Color.SKY,  -- Default blue-ish -> SKY
            radius = 60,
            pulseRate = 3,
            sound = "shield",
            criticalAssets = {"sparkle", "runes", "impactRing"}, -- Assets needed for shields
            shieldType = nil -- Will be set at runtime based on the spell
        },
    }
    
    -- TODO: Initialize sound effects
    
    -- Create effect pool - each effect is a container object
    Pool.create("vfx_effect", 10, function() return { particles = {} } end, VFX.resetEffect)
    
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
    -- Release all particles back to their pool
    for _, particle in ipairs(effect.particles) do
        Pool.release("vfx_particle", particle)
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
    effect.duration = template.duration
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
    
    -- Different initialization based on effect type
    if effect.type == Constants.AttackType.PROJECTILE then
        -- For projectiles, create core and trailing particles
        -- Calculate base trajectory properties
        local dirX = effect.targetX - effect.sourceX
        local dirY = effect.targetY - effect.sourceY
        local distance = math.sqrt(dirX*dirX + dirY*dirY)
        local baseAngle = math.atan2(dirY, dirX)
        
        -- Get turbulence factor or use default
        local turbulence = effect.turbulence or 0.5
        local coreDensity = effect.coreDensity or 0.6
        local trailDensity = effect.trailDensity or 0.4
        
        -- Core particles (at the leading edge of the projectile)
        local coreCount = math.floor(effect.particleCount * coreDensity)
        local trailCount = effect.particleCount - coreCount
        
        -- Create core/leading particles
        for i = 1, coreCount do
            local particle = VFX.ensureParticleDefaults(Pool.acquire("vfx_particle"))
            -- Random position near the projectile core (tighter cluster)
            local spreadFactor = 4 * turbulence
            local offsetX = math.random(-spreadFactor, spreadFactor)
            local offsetY = math.random(-spreadFactor, spreadFactor)
            
            -- Set initial state
            particle.x = effect.sourceX + offsetX
            particle.y = effect.sourceY + offsetY
            particle.scale = effect.startScale * math.random(0.9, 1.4) -- Slightly larger scales
            particle.alpha = 1.0
            particle.rotation = math.random() * math.pi * 2
            
            -- Create leading-edge cluster with even less delay for faster appearance
            particle.delay = math.random() * 0.05 -- Minimal delay
            particle.active = false
            particle.isCore = true -- Mark as core particle for special rendering
            particle.motion = effect.motion -- Store motion style
            
            -- Motion properties
            particle.startTime = 0
            particle.baseX = effect.sourceX
            particle.baseY = effect.sourceY
            particle.targetX = effect.targetX
            particle.targetY = effect.targetY
            
            -- Add less randomness to motion for more focused projectile
            local angleVar = (math.random() - 0.5) * 0.2 * turbulence
            particle.angle = baseAngle + angleVar
            particle.speed = math.random(200, 260) -- Significantly faster speeds
            
            -- Life cycle control
            particle.lifespan = (effect.particleLifespan or 0.6) * effect.duration
            particle.timeOffset = math.random() * 0.1
            particle.turbulence = turbulence
            
            -- Apply motion style variations 
            if effect.motion == Constants.MotionStyle.SWIRL then
                particle.swirlRadius = math.random(5, 15)
                particle.swirlSpeed = math.random(3, 8)
            elseif effect.motion == Constants.MotionStyle.PULSE then
                particle.pulseFreq = math.random(3, 7)
                particle.pulseAmplitude = 0.2 + math.random() * 0.3
            end
            
            table.insert(effect.particles, particle)
        end
        
        -- Create trail particles
        for i = 1, trailCount do
            local particle = VFX.ensureParticleDefaults(Pool.acquire("vfx_particle"))
            
            -- Trail particles start closer to the core
            local spreadRadius = 6 * trailDensity * turbulence -- Tighter spread
            local spreadAngle = math.random() * math.pi * 2
            local spreadDist = math.random() * spreadRadius
            
            -- Set initial state - more directional alignment
            particle.x = effect.sourceX + math.cos(spreadAngle) * spreadDist
            particle.y = effect.sourceY + math.sin(spreadAngle) * spreadDist
            particle.scale = effect.startScale * math.random(0.7, 0.9) -- Slightly smaller
            particle.alpha = 0.7 -- Lower alpha for less visibility
            particle.rotation = math.random() * math.pi * 2
            
            -- Much shorter staggered delay for trail particles
            particle.delay = (i / trailCount) * 0.15 -- Cut delay in half for faster response
            particle.active = false
            particle.isCore = false -- Mark as trail particle
            particle.motion = effect.motion
            
            -- Motion properties
            particle.startTime = 0
            particle.baseX = effect.sourceX
            particle.baseY = effect.sourceY
            particle.targetX = effect.targetX
            particle.targetY = effect.targetY
            
            -- Reduce trail spread angle for more directional appearance
            local angleVar = (math.random() - 0.5) * 0.3 * turbulence -- Half the angle variance
            particle.angle = baseAngle + angleVar
            particle.speed = math.random(150, 200) -- Faster than before, closer to core speed
            
            -- Trail particles have shorter lifespans for smoother fade
            particle.lifespan = (effect.particleLifespan or 0.6) * effect.duration * 0.8
            particle.timeOffset = math.random() * 0.2
            particle.turbulence = turbulence
            
            -- Which segment of the trail this particle belongs to
            particle.trailSegment = math.random()
            
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "impact" then
        -- For impact effects, create a radial explosion
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(10, effect.radius)
            local speed = math.random(50, 200)
            
            local particle = Pool.acquire("vfx_particle")
            particle.x = effect.targetX
            particle.y = effect.targetY
            particle.targetX = effect.targetX + math.cos(angle) * distance
            particle.targetY = effect.targetY + math.sin(angle) * distance
            particle.speed = speed
            particle.scale = effect.startScale
            particle.alpha = 1.0
            particle.rotation = angle
            particle.delay = math.random() * 0.2 -- Slight random delay
            particle.active = false
            particle.motion = effect.motion -- Store motion style on particle
            
            -- Additional properties for special motion
            particle.startTime = 0
            particle.baseX = effect.targetX
            particle.baseY = effect.targetY
            particle.angle = angle
            
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "cone" then
        -- For conical blast effects
        -- Calculate the base direction from source to target
        local dirX = effect.targetX - effect.sourceX
        local dirY = effect.targetY - effect.sourceY
        local baseAngle = math.atan2(dirY, dirX)
        
        -- Convert cone angle from degrees to radians
        local coneAngleRad = (effect.coneAngle or 60) * math.pi / 180
        local halfConeAngle = coneAngleRad / 2
        
        -- Set up wave parameters
        local waveCount = effect.waveCount or 3
        
        -- Calculate effect properties based on range and elevation
        local intensityMultiplier = 1.0
        if effect.rangeBand == Constants.RangeState.NEAR and effect.nearRangeIntensity then
            intensityMultiplier = intensityMultiplier * effect.nearRangeIntensity
        end
        
        -- Create particles for the cone blast
        for i = 1, effect.particleCount do
            local particle = Pool.acquire("vfx_particle")
            
            -- Determine if this particle is part of a wave or general cone fill
            local isWaveParticle = i <= math.floor(effect.particleCount * 0.45) -- 45% of particles for waves
            
            -- Random position within the cone but with focus toward center if focusedCore enabled
            local conePos = math.random()
            local angleOffset
            
            if effect.focusedCore then
                -- Apply quadratic distribution to concentrate particles near center
                -- Use squared random value to cluster toward cone center
                local angleRand = math.random()
                -- Apply bias toward center (squared distribution pushes values toward 0)
                angleRand = (angleRand * 2 - 1) * (angleRand * 2 - 1) * (angleRand > 0.5 and 1 or -1)
                angleOffset = angleRand * halfConeAngle
            else
                -- Standard uniform distribution across cone
                angleOffset = (math.random() * 2 - 1) * halfConeAngle
            end
            
            local angle = baseAngle + angleOffset
            
            -- Distance based on position in the cone (closer to edge or center)
            local maxDistance = effect.coneLength or 320
            
            -- For longer cone, we want more particles toward the end
            local distanceRand
            if math.random() < 0.6 then
                -- 60% chance for farther particles
                distanceRand = math.random() * 0.5 + 0.5 -- 0.5 to 1.0
            else
                -- 40% chance for closer particles
                distanceRand = math.random() * 0.5 -- 0.0 to 0.5
            end
            
            local distance = maxDistance * distanceRand
            
            -- Wave-specific properties
            if isWaveParticle and effect.waveCrest then
                -- Assign to a specific wave
                local waveIndex = math.floor(math.random() * waveCount) + 1
                particle.waveIndex = waveIndex
                particle.waveTime = waveIndex / waveCount -- Staggered wave timing
                particle.isWave = true
                
                -- Calculate wave speed and distance based on wave index (later waves move faster)
                local speedMultiplier = 1.0 + (waveIndex - 1) * 0.15 -- Each wave is faster than the previous
                particle.distance = maxDistance * 0.95 -- Waves extend almost to max distance
                particle.speed = (effect.waveSpeed or 350) * speedMultiplier
                particle.scale = effect.startScale * (1.5 + waveIndex * 0.1) -- Later waves slightly larger
                particle.alpha = 0.9
                
                -- Wave persistence for long-lasting waves (new property)
                if effect.wavePersistence then
                    particle.persistenceFactor = effect.wavePersistence
                end
                
                -- For trailing glow effect
                if effect.trailingGlowStrength then
                    particle.trailGlow = effect.trailingGlowStrength
                end
                
                -- Wave particles need a more consistent angle within the cone
                -- Distribute wave particles more densely in the center if focusedCore is enabled
                local waveAnglePos = math.random()
                if effect.focusedCore then
                    -- Apply curve to concentrate in center
                    waveAnglePos = (waveAnglePos * 2 - 1)
                    -- Cubic function to keep more particles in center
                    waveAnglePos = waveAnglePos * waveAnglePos * waveAnglePos
                    waveAnglePos = (waveAnglePos + 1) / 2 -- Remap to 0-1
                end
                angle = baseAngle + (waveAnglePos * 2 - 1) * halfConeAngle * 0.85
            else
                -- Regular fill particles
                particle.distance = distance
                -- Faster particles for longer cone
                particle.speed = math.random(100, 250)
                -- More varied scale based on particleSizeVariance
                local sizeVariance = effect.particleSizeVariance or 0.6
                particle.scale = effect.startScale * (0.7 + math.random() * sizeVariance)
                particle.alpha = 0.6 + math.random() * 0.4
                particle.isWave = false
                
                -- For focused cone, make particles in the center brighter and larger
                if effect.focusedCore then
                    -- Calculate distance from center angle
                    local angleDiff = math.abs(angle - baseAngle) / halfConeAngle -- 0 at center, 1 at edge
                    -- Particles closer to center get enhancements
                    if angleDiff < 0.4 then
                        local centerBoost = (1.0 - angleDiff/0.4) * 0.5
                        particle.scale = particle.scale * (1 + centerBoost)
                        particle.alpha = particle.alpha * (1 + centerBoost * 0.5)
                    end
                end
            end
            
            -- Common properties
            particle.angle = angle
            particle.rotation = angle -- Align rotation with direction
            particle.delay = math.random() * 0.3 -- Staggered start
            particle.active = false
            particle.motion = effect.motionStyle or Constants.MotionStyle.DIRECTIONAL
            particle.intensityMultiplier = intensityMultiplier
            
            -- Set position at source
            particle.x = effect.sourceX
            particle.y = effect.sourceY
            
            -- Additional properties for motion
            particle.startTime = 0
            particle.baseX = effect.sourceX
            particle.baseY = effect.sourceY
            
            -- Target destination for the particle
            particle.targetX = effect.sourceX + math.cos(angle) * particle.distance
            particle.targetY = effect.sourceY + math.sin(angle) * particle.distance
            
            table.insert(effect.particles, particle)
        end
        
        -- Flag to track which waves have started
        effect.waveStarted = {}
        for i = 1, waveCount do
            effect.waveStarted[i] = false
        end
        
    elseif effect.type == "aura" then
        -- For aura effects, create particles that orbit the character
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(effect.radius * 0.6, effect.radius)
            local orbitalSpeed = math.random(0.5, 2.0)
            
            local particle = Pool.acquire("vfx_particle")
            particle.angle = angle
            particle.distance = distance
            particle.orbitalSpeed = orbitalSpeed
            particle.scale = effect.startScale
            particle.alpha = 0 -- Start invisible and fade in
            particle.rotation = 0
            particle.delay = i / effect.particleCount * 0.5
            particle.active = false
            particle.motion = effect.motion -- Store motion style on particle
            
            -- Additional properties for special motion
            particle.startTime = 0
            particle.baseX = effect.sourceX
            particle.baseY = effect.sourceY
            particle.targetX = effect.sourceX + math.cos(angle) * distance
            particle.targetY = effect.sourceY + math.sin(angle) * distance
            particle.speed = orbitalSpeed * 30
            
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "vertical" then
        -- For vertical effects like emberlift, particles rise upward
        for i = 1, effect.particleCount do
            local offsetX = math.random(-30, 30)
            local startY = math.random(0, 40)
            local speed = math.random(70, 150)
            
            local particle = Pool.acquire("vfx_particle")
            particle.x = effect.sourceX + offsetX
            particle.y = effect.sourceY + startY
            particle.speed = speed
            particle.scale = effect.startScale
            particle.alpha = 1.0
            particle.rotation = math.random() * math.pi * 2
            particle.delay = i / effect.particleCount * 0.8
            particle.active = false
            
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "remote" then
        -- For remote effects like warp, create particles at the target location
        -- Use the target position as the center
        -- Set flags for position tracking
        effect.useTargetPosition = true  -- This tells the system to use the current target position
        
        -- Make sure to use the initial position with offsets if available
        local centerX = effect.targetX
        local centerY = effect.targetY
        
        -- Initialize with offset if the target entity has position offsets
        if effect.targetEntity and effect.targetEntity.currentXOffset and effect.targetEntity.currentYOffset then
            centerX = effect.targetEntity.x + effect.targetEntity.currentXOffset
            centerY = effect.targetEntity.y + effect.targetEntity.currentYOffset
            
            -- Update effect's target position to include offsets
            effect.targetX = centerX
            effect.targetY = centerY
            
            print(string.format("[VFX] Initializing warp at (%d, %d) with offsets (%d, %d)", 
                centerX, centerY, effect.targetEntity.currentXOffset, effect.targetEntity.currentYOffset))
        end
        
        local radius = effect.radius or 60
        
        -- Calculate how many particles to create based on density
        local particlesToCreate = effect.particleCount
        if effect.particleDensity then
            particlesToCreate = math.floor(effect.particleCount * effect.particleDensity)
        end
        
        for i = 1, particlesToCreate do
            -- Create particles in a circular pattern around the target
            local angle = (i / particlesToCreate) * math.pi * 2
            -- Random distance from center
            local distance = math.random(10, radius) 
            -- Random speed for movement
            local speed = math.random(10, 70) 
            
            local particle = Pool.acquire("vfx_particle")
            -- Start at the center
            particle.x = centerX
            particle.y = centerY 
            -- Target position (for radial movement)
            particle.targetX = centerX + math.cos(angle) * distance
            particle.targetY = centerY + math.sin(angle) * distance
            particle.speed = speed
            particle.scale = effect.startScale * (0.5 + math.random() * 0.5) -- Varied scales
            particle.alpha = 0.7 + math.random() * 0.3 -- Slightly varied alpha
            particle.rotation = angle
            -- Randomized delay for staggered appearance
            particle.delay = math.random() * 0.4
            particle.active = false
            -- Store motion style and other properties
            particle.motion = effect.motion
            particle.angle = angle
            particle.distance = distance
            -- Don't store fixed coordinates, just the angle and distance
            -- This way particles can be positioned relative to the current
            -- target position, which may change over time
            -- particle.baseX = centerX
            -- particle.baseY = centerY
            
            table.insert(effect.particles, particle)
        end
        
        -- Initialize sprite rotation angle if needed
        if effect.rotateSprite then
            effect.spriteAngle = 0
        end
    
    elseif effect.type == "beam" then
        -- For beam effects like fullmoonbeam, create a beam with particles
        -- First create the main beam shape
        effect.beamProgress = 0
        effect.beamLength = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
        effect.beamAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)
        
        -- Then add particles along the beam
        for i = 1, effect.particleCount do
            local position = math.random()
            local offset = math.random(-10, 10)
            
            local particle = Pool.acquire("vfx_particle")
            particle.position = position -- 0 to 1 along beam
            particle.offset = offset -- Perpendicular to beam
            particle.scale = effect.startScale * math.random(0.7, 1.3)
            particle.alpha = 0.8
            particle.rotation = math.random() * math.pi * 2
            particle.delay = math.random() * 0.3
            particle.active = false
            
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "conjure" then
        -- For conjuration spells, create particles that rise from caster toward mana pool
        -- Set the mana pool position (typically at top center)
        effect.manaPoolX = effect.options and effect.options.manaPoolX or 400 -- Screen center X
        effect.manaPoolY = effect.options and effect.options.manaPoolY or 120 -- Near top of screen
        
        -- Ensure spreadRadius has a default value
        effect.spreadRadius = effect.spreadRadius or 40
        
        -- Calculate direction vector toward mana pool
        local dirX = effect.manaPoolX - effect.sourceX
        local dirY = effect.manaPoolY - effect.sourceY
        local len = math.sqrt(dirX * dirX + dirY * dirY)
        dirX = dirX / len
        dirY = dirY / len
        
        for i = 1, effect.particleCount do
            -- Create a spread of particles around the caster
            local spreadAngle = math.random() * math.pi * 2
            local spreadDist = math.random() * effect.spreadRadius
            local startX = effect.sourceX + math.cos(spreadAngle) * spreadDist
            local startY = effect.sourceY + math.sin(spreadAngle) * spreadDist
            
            -- Randomize particle properties
            local speed = math.random(80, 180)
            local delay = i / effect.particleCount * 0.7
            
            -- Add some variance to path
            local pathVariance = math.random(-20, 20)
            local pathDirX = dirX + pathVariance / 100
            local pathDirY = dirY + pathVariance / 100
            
            local particle = Pool.acquire("vfx_particle")
            particle.x = startX
            particle.y = startY
            particle.speedX = pathDirX * speed
            particle.speedY = pathDirY * speed
            particle.scale = effect.startScale
            particle.alpha = 0 -- Start transparent and fade in
            particle.rotation = math.random() * math.pi * 2
            particle.rotSpeed = math.random(-3, 3)
            particle.delay = delay
            particle.active = false
            particle.finalPulse = false
            particle.finalPulseTime = 0
            
            table.insert(effect.particles, particle)
        end
    elseif effect.type == "surge" then
        -- Initialize particles for fountain surge effect centered on caster
        local spread = effect.spread or 45
        local riseFactor = effect.riseFactor or 1.4
        local gravity = effect.gravity or 180
        local particleSizeVariance = effect.particleSizeVariance or 0.6
        
        -- Determine if we're using sprites
        local useSprites = effect.useSprites
        local spriteFrameCount = 0
        if useSprites and effect.criticalAssets then
            -- Count how many sprite frames we have for animation
            for _, assetName in ipairs(effect.criticalAssets) do
                if assetName == "sparkle" then
                    -- Single sprite - no animation frames
                    spriteFrameCount = 1
                    break
                end
            end
        end
        
        -- Pre-load center particle
        effect.centerParticleTimer = 0
        
        -- Create particles with varied properties
        for i = 1, effect.particleCount do
            local particle = Pool.acquire("vfx_particle")

            -- Start at source position with slight random offset
            local startOffsetX = math.random(-10, 10)
            local startOffsetY = math.random(-10, 10)
            particle.x = effect.sourceX + startOffsetX
            particle.y = effect.sourceY + startOffsetY
            
            -- Store initial position for spiral motion calculations
            particle.initialX = particle.x
            particle.initialY = particle.y

            -- Create upward velocity with variety
            -- More focused in the center for a fountain effect
            local horizontalBias = math.pow(math.random(), 1.5) -- Bias toward lower values
            particle.speedX = (math.random() - 0.5) * spread * horizontalBias
            
            -- Vertical speed with some variance and acceleration
            local riseSpeed = math.random(220, 320) * riseFactor
            if effect.riseAcceleration then
                -- Some particles have extra acceleration
                particle.riseAcceleration = math.random() * effect.riseAcceleration
            end
            
            particle.speedY = -riseSpeed
            particle.gravity = gravity * (0.8 + math.random() * 0.4) -- Slight variance in gravity
            
            -- Visual properties with variance
            local sizeVariance = 1.0 + (math.random() * 2 - 1) * particleSizeVariance
            particle.scale = effect.startScale * sizeVariance
            particle.baseScale = particle.scale -- Store for pulsation
            
            particle.alpha = 0.9 + math.random() * 0.1
            particle.rotation = math.random() * math.pi * 2
            particle.rotationSpeed = math.random(-4, 4) -- Random rotation speed
            
            -- Staggered appearance
            particle.delay = math.random() * 0.4
            particle.active = false
            
            -- Add sprite animation if enabled
            if useSprites then
                particle.useSprite = true
                if spriteFrameCount > 1 then
                    particle.frameIndex = 1
                    particle.frameTimer = 0
                    particle.frameRate = effect.spriteFrameRate or 8
                end
            end
            
            -- Special properties based on effect template settings
            if effect.spiralMotion then
                particle.spiral = true
                particle.spiralFrequency = 5 + math.random() * 3
                particle.spiralAmplitude = 10 + math.random() * 20
                particle.spiralPhase = math.random() * math.pi * 2
                particle.spiralTightness = effect.spiralTightness or 2.5
            end
            
            if effect.pulsateParticles and math.random() < 0.7 then
                particle.pulsate = true
                particle.pulseRate = 3 + math.random() * 5
                particle.pulseAmount = 0.2 + math.random() * 0.3
            end
            
            -- Chance for special sparkle particles
            if effect.sparkleChance and math.random() < effect.sparkleChance then
                particle.sparkle = true
                particle.sparkleIntensity = 0.7 + math.random() * 0.3
            end
            
            -- Add bloom glow effect
            if effect.bloomEffect then
                particle.bloom = true
                particle.bloomIntensity = (effect.bloomIntensity or 0.8) * (0.7 + math.random() * 0.6)
            end

            table.insert(effect.particles, particle)
        end
    elseif effect.type == "meteor" then
        -- Initialize particles for meteor dive effect
        local height = effect.height or 300
        local spread = effect.spread or 20
        local particleAsset = effect.defaultParticleAsset or "fireParticle"
        
        -- Ensure we have the required asset
        local asset = VFX.getAsset(particleAsset)
        
        -- Create a cluster of meteors falling from above
        for i = 1, effect.particleCount do
            local particle = VFX.ensureParticleDefaults(Pool.acquire("vfx_particle"))
            
            -- Start above the target at random positions
            local offsetX = (math.random() - 0.5) * spread * 2
            local offsetY = -height + math.random() * height * 0.3
            
            -- Set starting position above target
            particle.x = effect.targetX + offsetX
            particle.y = effect.targetY + offsetY
            
            -- Downward velocity with slight inward pull toward target
            local angleToTarget = math.atan2(effect.targetY - particle.y, effect.targetX - particle.x)
            local fallSpeed = math.random(300, 450)
            local fallAngleVariance = (math.random() - 0.5) * 0.3
            particle.speedX = math.cos(angleToTarget + fallAngleVariance) * fallSpeed * 0.3
            particle.speedY = math.sin(angleToTarget + fallAngleVariance) * fallSpeed
            
            -- Set particle properties
            particle.scale = effect.startScale * math.random(0.8, 1.3)
            particle.alpha = 1.0
            particle.rotation = math.random() * math.pi * 2
            particle.rotSpeed = math.random(-5, 5)
            particle.delay = math.random() * 0.3
            particle.active = false
            
            -- Track if this particle has impacted
            particle.hasImpacted = false
            particle.impactTime = 0
            particle.fireTrail = effect.fireTrail
            
            -- Store additional properties
            particle.assetId = particleAsset
            
            table.insert(effect.particles, particle)
        end
        
        -- Create impact area particles (hidden until impact)
        if effect.impactExplosion then
            for i = 1, math.floor(effect.particleCount * 0.5) do
                local particle = VFX.ensureParticleDefaults(Pool.acquire("vfx_particle"))
                
                -- Start at target position
                particle.x = effect.targetX
                particle.y = effect.targetY
                
                -- Explosion trajectory
                local angle = math.random() * math.pi * 2
                local speed = math.random(100, 300)
                particle.speedX = math.cos(angle) * speed
                particle.speedY = math.sin(angle) * speed * 0.7 -- Flatten explosion
                
                -- Set particle properties
                particle.scale = effect.startScale * 0.6 * math.random(0.9, 1.4)
                particle.alpha = 0 -- Hidden until impact
                particle.rotation = math.random() * math.pi * 2
                particle.delay = 0.4 + math.random() * 0.2 -- Delay until impact
                particle.active = false
                particle.explosion = true
                
                -- Store additional properties
                particle.assetId = particleAsset
                
                table.insert(effect.particles, particle)
            end
        end
    end
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
                end
            end
            
            -- Once block is triggered, increment a block timer
            if effect.blockTimerStarted then
                effect.blockTimer = effect.blockTimer + dt
                -- Force effect completion after a longer time (1.2 seconds) to ensure player sees it
                if effect.blockTimer > 1.2 then
                    effect.progress = 1.0 -- Mark effect as complete
                    print(string.format("[VFX] Blocked effect '%s' cleanup - forcing completion", effect.name or "unknown"))
                else
                    -- Keep visual progress fixed at block point - this is crucial for seeing the projectile stop
                    effect.visualProgress = effect.options.blockPoint
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
        
        -- Update effect based on type
        if effect.type == Constants.AttackType.PROJECTILE then
            VFX.updateProjectile(effect, dt)
        elseif effect.type == "impact" then
            VFX.updateImpact(effect, dt)
        elseif effect.type == "cone" then
            VFX.updateCone(effect, dt)
        elseif effect.type == "remote" then
            VFX.updateRemote(effect, dt)
        elseif effect.type == "aura" then
            VFX.updateAura(effect, dt)
        elseif effect.type == "vertical" then
            VFX.updateVertical(effect, dt)
        elseif effect.type == "beam" then
            VFX.updateBeam(effect, dt)
        elseif effect.type == "conjure" then
            VFX.updateConjure(effect, dt)
        elseif effect.type == "surge" then
            VFX.updateSurge(effect, dt)
        elseif effect.type == "meteor" then
            VFX.updateMeteor(effect, dt)
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

-- Update function for projectile effects
function VFX.updateProjectile(effect, dt)
    local Constants = require("core.Constants")
    
    -- Initialize trail points if needed
    if #effect.trailPoints == 0 then
        -- Initialize trail with source position
        for i = 1, effect.trailLength do
            table.insert(effect.trailPoints, {
                x = effect.sourceX, 
                y = effect.sourceY,
                alpha = i == 1 and 1.0 or (1.0 - (i-1)/effect.trailLength)
            })
        end
    end
    
    -- Get effect parameters with defaults
    local arcHeight = effect.arcHeight or 60
    
    -- Use visualProgress for blocked effects, otherwise use normal progress
    local baseProgress 
    if effect.options and effect.options.blockPoint and effect.visualProgress then
        -- Use visualProgress for blocked effects to ensure smooth trajectory
        baseProgress = effect.visualProgress
    else
        -- Use normal progress for standard projectiles
        baseProgress = effect.progress
    end
    
    -- Calculate base projectile position
    -- Using current source and target positions (which may have been updated for tracking)
    local posX = effect.sourceX + (effect.targetX - effect.sourceX) * baseProgress
    local posY = effect.sourceY + (effect.targetY - effect.sourceY) * baseProgress
    
    -- For straight-line effects (like bolts), skip the arc calculation
    if not effect.straightLine then
        -- Calculate improved trajectory arc with natural physics
        -- Adjust trajectory based on rangeBand
        local rangeBandModifier = 1.0
        if effect.rangeBand == Constants.RangeState.FAR then
            rangeBandModifier = 1.6  -- Higher arc for far range
        elseif effect.rangeBand == Constants.RangeState.NEAR then
            rangeBandModifier = 0.5  -- Lower, flatter arc for near range
        end
        
        -- Adjust trajectory based on elevation with smoother transitions
        local elevationOffset = 0
        local arcModifier = 1.0
        
        if effect.elevation then
            if effect.elevation == Constants.ElevationState.AERIAL then
                -- When target is aerial, use more curved upward trajectory
                arcModifier = 0.7 -- Less pronounced arc
                elevationOffset = -50 * math.sin(baseProgress * math.pi) -- Smooth upward curve
            elseif effect.elevation == Constants.ElevationState.GROUNDED then
                -- When target is grounded, use more gravity-influenced downward arc
                arcModifier = 1.3 -- More pronounced arc
                elevationOffset = 40 * baseProgress^2 -- Accelerating downward
            end
        end
        
        -- Apply motion style variations to the arc
        if effect.motion == Constants.MotionStyle.RISE then
            -- Rising motion: mostly flat but with subtle upward momentum for fire
            local riseProgress = math.sin(baseProgress * math.pi * 0.4)
            elevationOffset = elevationOffset - 15 * (1 - baseProgress) * riseProgress
            arcModifier = arcModifier * 0.5 -- Reduce arc height further
        elseif effect.motion == Constants.MotionStyle.FALL then
            -- Falling motion: starts high, accelerates downward
            elevationOffset = elevationOffset + 20 * baseProgress^1.5
            arcModifier = arcModifier * 1.3
        elseif effect.motion == Constants.MotionStyle.SWIRL then
            -- Swirl adds a slight sine wave to the path
            local swirlFactor = math.sin(baseProgress * math.pi * 4) * 8 -- Faster swirl, smaller amplitude
            posX = posX + swirlFactor
            posY = posY + swirlFactor * 0.5
        elseif effect.motion == Constants.MotionStyle.PULSE then
            -- Pulse adds a throbbing effect to the arc height
            local pulseFactor = 0.3 * math.sin(baseProgress * math.pi * 5) -- Faster pulse
            arcModifier = arcModifier * (1 + pulseFactor)
        end
        
        -- Apply dynamic arc - smoother easing function
        local arcHeight = effect.arcHeight or 60
        local arcProgress = baseProgress * (1 - baseProgress) * 4 -- Quadratic ease in/out curve peaking at 0.5
        local verticalOffset = -arcHeight * rangeBandModifier * arcModifier * arcProgress
        
        -- Apply final position
        posY = posY + verticalOffset + elevationOffset * baseProgress
    else
        -- For straight-line effects like bolts, we can still add minor variations
        -- Add a slight zigzag effect for lightning bolts, if desired
        if effect.turbulence and effect.turbulence > 0 then
            local turbAmt = effect.turbulence * 4
            local zigzag = math.sin(baseProgress * 12) * turbAmt * baseProgress * (1 - baseProgress) * 2
            -- Apply zigzag perpendicularly to the direction of travel
            local dx = effect.targetX - effect.sourceX
            local dy = effect.targetY - effect.sourceY
            local len = math.sqrt(dx*dx + dy*dy)
            if len > 0 then
                -- Normalized perpendicular vector
                local perpX = -dy / len
                local perpY = dx / len
                posX = posX + perpX * zigzag
                posY = posY + perpY * zigzag
            end
        end
    end
    
    -- Check for special shield block point
    local blockPoint = effect.options and effect.options.blockPoint
    local isBlocked = blockPoint and baseProgress >= blockPoint
    
    if isBlocked and not effect.blockLogged then
        -- Log block point for debugging (only once)
        print(string.format("[VFX] Projectile blocked at blockPoint=%.2f", blockPoint))
        
        -- Debug information about effect.options to see what we have available
        print("[VFX] Effect options for blocked projectile:")
        if effect.options then
            for k, v in pairs(effect.options) do
                if type(v) ~= "table" and type(v) ~= "function" then
                    print(string.format("  options.%s = %s", tostring(k), tostring(v)))
                elseif type(v) == "table" then
                    print(string.format("  options.%s = [table]", tostring(k)))
                elseif type(v) == "function" then
                    print(string.format("  options.%s = [function]", tostring(k)))
                end
            end
        else
            print("  No options available!")
        end
        
        -- Debug entity references
        print(string.format("  sourceEntity available: %s", tostring(effect.options and effect.options.sourceEntity ~= nil)))
        print(string.format("  targetEntity available: %s", tostring(effect.options and effect.options.targetEntity ~= nil)))
        
        if effect.blockInfo then
            print(string.format("[VFX] BlockInfo: blockType=%s, blockingSlot=%s", 
                tostring(effect.blockInfo.blockType),
                tostring(effect.blockInfo.blockingSlot)))
        end
        effect.blockLogged = true
    end
    
    if isBlocked then
        -- We've reached the shield block point - calculate block position
        local blockX = effect.sourceX + (effect.targetX - effect.sourceX) * blockPoint
        local blockY = effect.sourceY + (effect.targetY - effect.sourceY) * blockPoint
        
        -- Apply adjustment for shield hit visuals
        local blockProgress = (baseProgress - blockPoint) / (1.0 - blockPoint) -- 0 to 1 after block
        
        -- Create shield block effect at blockPoint if not already created
        if not effect.blockEffectCreated and blockProgress > 0 then
            effect.blockEffectCreated = true
            
            -- Get shield color based on type
            local shieldColor = {1.0, 1.0, 0.3, 0.7}  -- Default yellow for barriers
            if effect.options.shieldType == Constants.ShieldType.WARD then
                shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
            elseif effect.options.shieldType == Constants.ShieldType.FIELD then
                shieldColor = {0.3, 1.0, 0.3, 0.7}  -- Green for fields
            elseif effect.options.shieldColor then
                shieldColor = effect.options.shieldColor
            end
            
            -- Create shield hit effect
            local shieldHitOpts = {
                duration = 0.5,
                color = shieldColor,
                particleCount = math.floor(effect.particleCount * 0.8),
                shieldType = effect.options.shieldType
            }
            
            -- Ensure we have valid coordinates
            local safeBlockX = blockX or effect.targetX
            local safeBlockY = blockY or effect.targetY
            
            -- Safety check for the shield effect options
            shieldHitOpts = shieldHitOpts or {}
            shieldHitOpts.duration = shieldHitOpts.duration or 0.5
            shieldHitOpts.particleCount = shieldHitOpts.particleCount or 10
            
            -- Trigger screen shake at the exact moment of shield impact
            -- Get the game state reference from the effect options if available
            local gameState = nil
            if effect.options and effect.options.sourceEntity and effect.options.sourceEntity.gameState then
                gameState = effect.options.sourceEntity.gameState
            elseif effect.options and effect.options.targetEntity and effect.options.targetEntity.gameState then
                gameState = effect.options.targetEntity.gameState
            end
            
            -- Trigger shake if we have access to the game state
            if gameState and gameState.triggerShake then
                -- Determine impact amount for shake intensity (from effect or default)
                local amount = effect.options.amount or 10
                local intensity = math.min(4, 2 + (amount / 20))
                -- Trigger a light shake for shield blocks
                gameState.triggerShake(0.2, intensity)
                print(string.format("[VFX] Shield block impact! Triggering light shake (%.2f, %.2f) at blockPoint=%.2f", 
                    0.2, intensity, blockPoint))
            end
            
            VFX.createEffect("shield_hit_base", safeBlockX, safeBlockY, nil, nil, shieldHitOpts)
            
            -- Gradually increase the timer to complete the effect lifecycle after block
            -- This ensures the effect is properly removed from the active effects list
            effect.timer = effect.timer + (effect.duration * 0.05)
        end
        
        -- Reset position to show scattering from block point
        if blockProgress < 0.2 then
            -- Initial impact phase - particles bunch up at block point
            -- Use normal position calculation up to block point
            -- Need to adjust posX, posY for impact visuals
            posX = blockX + math.cos(effect.timer * 10) * 3 * blockProgress
            posY = blockY + math.sin(effect.timer * 10) * 3 * blockProgress
        else
            -- No need to modify posX, posY here - individual particles 
            -- will handle scattering in their update logic
            
            -- Increment timer faster to complete the effect after showing impact
            -- This ensures the effect is removed from the active effects list
            effect.timer = math.min(effect.timer + (effect.duration * 0.1), effect.duration)
        end
    else
        -- Normal projectile flight with standard impact transition
        local impactTransition = math.max(0, (baseProgress - 0.9) / 0.1) -- 0-1 in last 10% of flight
        if impactTransition > 0 then
            -- Add slight slowdown and expansion as projectile approaches target
            local impactX = effect.targetX + math.cos(effect.timer * 5) * 2 * impactTransition
            local impactY = effect.targetY + math.sin(effect.timer * 5) * 2 * impactTransition
            
            -- Blend between normal trajectory and impact position
            posX = posX * (1 - impactTransition) + impactX * impactTransition
            posY = posY * (1 - impactTransition) + impactY * impactTransition
        end
    end
    
    -- Update trail points - add current position to front of trail
    table.remove(effect.trailPoints)
    table.insert(effect.trailPoints, 1, {
        x = posX, 
        y = posY,
        alpha = 1.0
    })
    
    -- Fade trail points based on position
    for i = 2, #effect.trailPoints do
        effect.trailPoints[i].alpha = 1.0 - (i-1)/#effect.trailPoints
    end
    
    -- Store leading point for particle updates
    effect.leadingPoint = {x = posX, y = posY}
    
    -- Initialize particles array if missing
    effect.particles = effect.particles or {}
    
    -- Update particles safely
    for i, particle in ipairs(effect.particles) do
        -- Skip invalid particles
        if not particle then
            print("[VFX] Warning: Invalid particle detected")
            -- Skip this particle without using goto
            goto next_particle
        end
        
        -- Initialize basic particle properties if missing
        particle.delay = particle.delay or 0
        particle.active = particle.active or false
        particle.startTime = particle.startTime or 0
        
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        -- Only process active particles
        if particle.active then
            -- Calculate particle lifecycle
            particle.startTime = particle.startTime + dt
            local totalLifespan = particle.lifespan or (effect.duration * 0.6)
            
            local particleLife = particle.startTime / totalLifespan
            
            -- If particle has exceeded its lifespan, reset it near the current position
            if particleLife >= 1.0 then
                -- Reset position to current projectile location with small offset
                local turbulence = particle.turbulence or 0.5
                local offset = particle.isCore and 5 or 15
                local randomOffsetX = math.random(-offset, offset) * turbulence
                local randomOffsetY = math.random(-offset, offset) * turbulence
                
                particle.x = posX + randomOffsetX
                particle.y = posY + randomOffsetY
                particle.startTime = 0
                
                -- Refresh motion properties but keep same general parameters
                particle.rotation = math.random() * math.pi * 2
                
                -- Core particles stay brighter
                if particle.isCore then
                    particle.alpha = 1.0
                else
                    particle.alpha = 0.7 + math.random() * 0.3
                end
            else
                -- Update particle based on motion style and position in the trail
                local particleProgress 
                
                if particle.isCore then
                    -- Core particles follow the leading edge closely
                    particleProgress = math.min(particle.startTime / (totalLifespan * 0.7), 1.0)
                    
                    -- Determine position based on turbulence and trail
                    local turbulence = particle.turbulence or 0.5
                    local spreadFactor = 4 * turbulence * (1 - particleProgress)
                    
                    -- Core particles cluster near the front of the projectile
                    local leadOffset = math.random(-spreadFactor, spreadFactor)
                    local leadX = effect.leadingPoint.x + math.cos(particle.angle) * leadOffset
                    local leadY = effect.leadingPoint.y + math.sin(particle.angle) * leadOffset
                    
                    -- Apply specific motion style modifications
                    if effect.motion == Constants.MotionStyle.SWIRL then
                        -- Swirling motion around leading point
                        local swirlAngle = particle.startTime * (particle.swirlSpeed or 5)
                        local swirlRadius = (particle.swirlRadius or 10) * (1 - 0.5 * particleProgress)
                        leadX = leadX + math.cos(swirlAngle) * swirlRadius
                        leadY = leadY + math.sin(swirlAngle) * swirlRadius
                    elseif effect.motion == Constants.MotionStyle.PULSE then
                        -- Pulsing size and position
                        local pulseFactor = math.sin(particle.startTime * (particle.pulseFreq or 5))
                        local pulseAmount = (particle.pulseAmplitude or 0.3) * pulseFactor
                        
                        -- Apply to scale and position
                        particle.scale = particle.scale * (1 + pulseAmount * 0.2)
                        leadX = leadX + math.cos(particle.angle) * pulseAmount * 5
                        leadY = leadY + math.sin(particle.angle) * pulseAmount * 5
                    elseif effect.motion == Constants.MotionStyle.RIPPLE then
                        -- Wave-like motion
                        local wavePhase = particle.startTime * 4 + i * 0.2
                        local waveAmplitude = 5 * turbulence * (1 - 0.5 * particleProgress)
                        
                        -- Perpendicular wave motion
                        local perpX = -math.sin(particle.angle) * math.sin(wavePhase) * waveAmplitude
                        local perpY = math.cos(particle.angle) * math.sin(wavePhase) * waveAmplitude
                        leadX = leadX + perpX
                        leadY = leadY + perpY
                    end
                    
                    -- Check for shield block behavior
                    local blockPoint = effect.options and effect.options.blockPoint
                    local isBlocked = blockPoint and effect.progress >= blockPoint
                    
                    if isBlocked then
                        -- Handle particles after shield block
                        local blockProgress = (effect.progress - blockPoint) / (1.0 - blockPoint) -- 0-1 after block
                        
                        -- Calculate block position
                        local blockX = effect.sourceX + (effect.targetX - effect.sourceX) * blockPoint
                        local blockY = effect.sourceY + (effect.targetY - effect.sourceY) * blockPoint
                        
                        if blockProgress < 0.2 then
                            -- Initial impact phase - particles bunch up at block point
                            local angle = math.random() * math.pi * 2
                            local scatter = 20 * (1.0 - blockProgress/0.2) -- Reduce scatter as we progress
                            
                            -- Move particles toward block point with some randomness
                            local targetX = blockX + math.cos(angle) * scatter * math.random()
                            local targetY = blockY + math.sin(angle) * scatter * math.random()
                            
                            -- Fade particles slightly during impact
                            particle.alpha = particle.alpha * 0.98
                            
                            -- Fast movement toward block point
                            local moveSpeed = 30 -- Faster movement during block
                            particle.x = particle.x + (targetX - particle.x) * moveSpeed * dt
                            particle.y = particle.y + (targetY - particle.y) * moveSpeed * dt
                        else
                            -- Deflection phase - particles scatter outward from block point
                            
                            -- Initialize deflection properties if not set
                            if not particle.deflectAngle then
                                -- Calculate deflection angle (mostly back toward source, with randomness)
                                local baseAngle = math.atan2(effect.sourceY - blockY, effect.sourceX - blockX)
                                particle.deflectAngle = baseAngle + (math.random() - 0.5) * math.pi * 0.6
                                
                                -- Random deflection speed to create spread
                                particle.deflectSpeed = 80 + math.random() * 120
                                particle.deflectDecay = 0.95  -- Speed decay factor
                                particle.scaleDecay = 0.98    -- Size decay factor
                                particle.deflectAge = 0       -- How long particle has been deflecting
                            end
                            
                            -- Update deflection age
                            particle.deflectAge = particle.deflectAge + dt
                            
                            -- Apply deflection movement with physics-based motion
                            local deflectDistance = particle.deflectSpeed * dt
                            particle.x = particle.x + math.cos(particle.deflectAngle) * deflectDistance
                            particle.y = particle.y + math.sin(particle.deflectAngle) * deflectDistance
                            
                            -- Apply decay factors
                            particle.deflectSpeed = particle.deflectSpeed * particle.deflectDecay
                            particle.scale = particle.scale * particle.scaleDecay
                            
                            -- Fade out as particles scatter - faster fade for a cleaner effect
                            particle.alpha = math.max(0, 1.0 - particle.deflectAge * 2.0) -- Fade out over ~0.5 seconds
                        end
                    else
                        -- Normal projectile behavior - smoothly move particle toward calculated position
                        local moveSpeed = 15 -- Adjust for smoother or more responsive motion
                        particle.x = particle.x + (leadX - particle.x) * moveSpeed * dt
                        particle.y = particle.y + (leadY - particle.y) * moveSpeed * dt
                    end
                    
                    -- Handle impact transition effects for core particles
                    local impactTransition = math.max(0, (effect.progress - 0.9) / 0.1) -- 0-1 in last 10% of flight
                    if impactTransition > 0 and not isBlocked then
                        -- Create spreading/expanding effect as projectile hits
                        local impactSpread = 30 * impactTransition
                        local spreadDirX = math.cos(particle.angle + particle.rotation)
                        local spreadDirY = math.sin(particle.angle + particle.rotation)
                        particle.x = particle.x + spreadDirX * impactSpread * dt * 10
                        particle.y = particle.y + spreadDirY * impactSpread * dt * 10
                        
                        -- Increase scale for impact
                        particle.scale = particle.scale * (1 + impactTransition * 0.5)
                    end
                else
                    -- Trail particles follow behind with more variance
                    particleProgress = math.min(particle.startTime / totalLifespan, 1.0)
                    
                    -- Trail particles distribute along trail points
                    local trailPos = math.min(math.floor(particle.trailSegment * #effect.trailPoints) + 1, #effect.trailPoints)
                    local trailPoint = effect.trailPoints[trailPos]
                    
                    -- Add some randomness to trail particle positions
                    local turbulence = particle.turbulence or 0.5
                    local spreadFactor = 12 * turbulence * (1 - 0.5 * particleProgress)
                    local spreadX = math.random(-spreadFactor, spreadFactor)
                    local spreadY = math.random(-spreadFactor, spreadFactor)
                    
                    -- Calculate target position on trail
                    local targetX = trailPoint.x + spreadX
                    local targetY = trailPoint.y + spreadY
                    
                    -- Move smoothly toward target position
                    local trailSpeed = 8 -- Slower than core particles
                    particle.x = particle.x + (targetX - particle.x) * trailSpeed * dt
                    particle.y = particle.y + (targetY - particle.y) * trailSpeed * dt
                    
                    -- Apply slight drift based on motion style
                    if effect.motion == Constants.MotionStyle.RISE then
                        particle.y = particle.y - (5 * particleProgress * dt)
                    elseif effect.motion == Constants.MotionStyle.FALL then
                        particle.y = particle.y + (8 * particleProgress * dt)
                    end
                    
                    -- Trail particles fade faster as they age
                    particle.alpha = particle.alpha * (1 - dt)
                end
                
                -- Update visual properties for all particles
                local baseScale = particle.isCore 
                    and (effect.startScale + (effect.endScale - effect.startScale) * particleProgress) * 1.2 
                    or (effect.startScale + (effect.endScale - effect.startScale) * particleProgress * 0.8)
                
                -- Apply scale
                particle.scale = baseScale * (particle.scale or 1.0)
                
                -- Apply rotation
                particle.rotation = particle.rotation + dt * (particle.isCore and 3 or 2)
                
                -- Handle particle fade out
                if particleProgress > 0.6 then
                    local fadeProgress = (particleProgress - 0.6) / 0.4 -- 0-1 in last 40% of life
                    particle.alpha = particle.alpha * (1 - fadeProgress)
                end
            end
        end
        
        ::next_particle::
    end
    
    -- Create impact effect when reaching the target
    if effect.progress > 0.9 and not effect.impactPrep then
        effect.impactPrep = true
        -- Begin impact preparation - particles start to expand
    end
    
    -- Actually trigger impact
    if effect.progress > 0.97 and not effect.impactCreated then
        effect.impactCreated = true
        -- In full implementation, would create impact effect here
    end
end

-- Update function for impact effects
function VFX.updateImpact(effect, dt)
    -- Create impact wave that expands outward
    -- For effects with useTargetPosition=true, ensure particles use target position
    local useTargetPosition = effect.useTargetPosition
    
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
            
            -- Update particle base position to current target position for effects that track target
            if useTargetPosition then
                particle.baseX = effect.targetX
                particle.baseY = effect.targetY
            end
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Check if we have a motion style to apply
            if effect.motion then
                -- Use the new updateParticle function with motion style
                VFX.updateParticle(particle, effect, dt, particleProgress)
            else
                -- Use the default behavior (radial expansion)
                local dirX = particle.targetX - effect.targetX
                local dirY = particle.targetY - effect.targetY
                local length = math.sqrt(dirX^2 + dirY^2)
                if length > 0 then
                    dirX = dirX / length
                    dirY = dirY / length
                end
                
                particle.x = effect.targetX + dirX * length * particleProgress
                particle.y = effect.targetY + dirY * length * particleProgress
            end
            
            -- Update visual properties if not already handled by the motion style
            if not (effect.motion == require("core.Constants").MotionStyle.PULSE) then
                particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
                particle.alpha = 1.0 - particleProgress^2 -- Quadratic fade out
            end
            
            -- Update rotation regardless of motion style
            particle.rotation = particle.rotation + dt * 3
        end
    end
end

-- Update function for aura effects
function VFX.updateAura(effect, dt)
    -- Update orbital particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Check if we have a motion style to apply
            if effect.motion and particle.motion then
                -- Use the new updateParticle function with motion style
                VFX.updateParticle(particle, effect, dt, particleProgress)
            else
                -- Use the default orbital motion behavior
                -- Update angle for orbital motion
                particle.angle = particle.angle + dt * particle.orbitalSpeed
                
                -- Calculate position based on orbit
                particle.x = effect.sourceX + math.cos(particle.angle) * particle.distance
                particle.y = effect.sourceY + math.sin(particle.angle) * particle.distance
            end
            
            -- Pulse effect
            local pulseOffset = math.sin(effect.timer * effect.pulseRate) * 0.2
            
            -- Update visual properties with fade in/out
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress + pulseOffset
            
            -- Fade in for first 20%, stay visible for 60%, fade out for last 20%
            if particleProgress < 0.2 then
                particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
            elseif particleProgress > 0.8 then
                particle.alpha = (1 - particleProgress) * 5 -- 1 to 0 over last 20% time
            else
                particle.alpha = 1.0
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for vertical effects
function VFX.updateVertical(effect, dt)
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Move particle upward
            particle.y = particle.y - particle.speed * dt
            
            -- Add some horizontal drift
            local driftSpeed = 10 * math.sin(particle.y * 0.05 + i)
            particle.x = particle.x + driftSpeed * dt
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            
            -- Fade in briefly, then fade out over time
            if particleProgress < 0.1 then
                particle.alpha = particleProgress * 10 -- Quick fade in
            else
                particle.alpha = 1.0 - ((particleProgress - 0.1) / 0.9) -- Slower fade out
            end
            
            particle.rotation = particle.rotation + dt * 2
        end
    end
end

-- Update function for beam effects
function VFX.updateBeam(effect, dt)
    -- Enhanced beam update with shield block handling
    local Constants = require("core.Constants")

    -- Update beam properties based on current source and target positions
    -- This ensures the beam adjusts if the wizards move due to range/elevation changes
    effect.beamLength = math.sqrt((effect.targetX - effect.sourceX)^2 + (effect.targetY - effect.sourceY)^2)
    effect.beamAngle = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)

    -- Determine which progress value to use (normal vs. visualProgress for blocked beams)
    local baseProgress
    if effect.options and effect.options.blockPoint and effect.visualProgress then
        baseProgress = effect.visualProgress -- Use smoothed visual progress when beam can be blocked
    else
        baseProgress = effect.progress
    end

    -- Determine how far the beam is allowed to extend (full length or up to the shield)
    local extensionTarget = (effect.options and effect.options.blockPoint) or 1.0

    -- Update beam progress – beam extends twice as fast, but never beyond its target length
    effect.beamProgress = math.min(baseProgress * 2, extensionTarget)

    -- If this beam was blocked, trigger shield-impact visuals once
    if extensionTarget < 1.0 and effect.blockTimerStarted and not effect.impactParticlesCreated then
        effect.impactParticlesCreated = true

        -- Calculate impact coordinates at the block point
        local impactX = effect.sourceX + (effect.targetX - effect.sourceX) * extensionTarget
        local impactY = effect.sourceY + (effect.targetY - effect.sourceY) * extensionTarget

        -- Resolve shield color based on shieldType / override
        local shieldColor = {1.0, 1.0, 0.3, 0.7} -- Default barrier yellow
        if effect.options and effect.options.shieldType == Constants.ShieldType.WARD then
            shieldColor = {0.3, 0.3, 1.0, 0.7}
        elseif effect.options and effect.options.shieldType == Constants.ShieldType.FIELD then
            shieldColor = {0.3, 1.0, 0.3, 0.7}
        elseif effect.options and effect.options.shieldColor then
            shieldColor = effect.options.shieldColor
        end

        -- Spawn the shield hit effect at the impact point
        local shieldHitOpts = {
            duration       = 0.5,
            color          = shieldColor,
            particleCount  = math.floor((effect.particleCount or 30) * 0.8),
            shieldType     = effect.options and effect.options.shieldType
        }
        VFX.createEffect("shield_hit_base", impactX, impactY, nil, nil, shieldHitOpts)
    end

    -- === Existing particle update logic ===
    -- Update beam particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Only show particles along the visible length of the beam
            if particle.position <= effect.beamProgress then
                -- Calculate position along beam
                local beamX = effect.sourceX + (effect.targetX - effect.sourceX) * particle.position
                local beamY = effect.sourceY + (effect.targetY - effect.sourceY) * particle.position
                
                -- Add perpendicular offset
                local perpX = -math.sin(effect.beamAngle) * particle.offset
                local perpY = math.cos(effect.beamAngle) * particle.offset
                
                particle.x = beamX + perpX
                particle.y = beamY + perpY
                
                -- Add pulsing effect
                local pulseOffset = math.sin(effect.timer * effect.pulseRate + particle.position * 10) * 0.3
                
                -- Update visual properties
                particle.scale = (effect.startScale + (effect.endScale - effect.startScale) * particleProgress) * (1 + pulseOffset)
                
                -- Fade based on beam extension and overall effect progress
                if effect.progress < 0.5 then
                    -- Beam extending - particles at tip are brighter
                    local distFromTip = math.abs(particle.position - effect.beamProgress)
                    particle.alpha = math.max(0, 1.0 - distFromTip * 3)
                else
                    -- Beam fully extended, starting to fade out
                    local fadeProgress = (effect.progress - 0.5) * 2 -- 0 to 1 in second half
                    particle.alpha = 1.0 - fadeProgress
                end
            else
                particle.alpha = 0 -- Particle not yet reached by beam extension
            end
            
            particle.rotation = particle.rotation + dt
        end
    end
end

-- Update function for conjure effects
function VFX.updateConjure(effect, dt)
    -- Update particles rising toward mana pool
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Update position based on speed
            if not particle.finalPulse then
                particle.x = particle.x + particle.speedX * dt
                particle.y = particle.y + particle.speedY * dt
                
                -- Calculate distance to mana pool
                local distX = effect.manaPoolX - particle.x
                local distY = effect.manaPoolY - particle.y
                local dist = math.sqrt(distX * distX + distY * distY)
                
                -- If close to mana pool, trigger final pulse effect
                if dist < 30 or particleProgress > 0.85 then
                    particle.finalPulse = true
                    particle.finalPulseTime = 0
                    
                    -- Center at mana pool
                    particle.x = effect.manaPoolX + math.random(-15, 15)
                    particle.y = effect.manaPoolY + math.random(-15, 15)
                end
            else
                -- Handle final pulse animation
                particle.finalPulseTime = particle.finalPulseTime + dt
                
                -- Expand and fade out for final pulse
                local pulseProgress = math.min(particle.finalPulseTime / 0.3, 1.0) -- 0.3s pulse duration
                particle.scale = effect.endScale * (1 + pulseProgress * 2) -- Expand to 3x size
                particle.alpha = 1.0 - pulseProgress -- Fade out
            end
            
            -- Handle fade in and rotation regardless of state
            if not particle.finalPulse then
                -- Fade in over first 20% of travel
                if particleProgress < 0.2 then
                    particle.alpha = particleProgress * 5 -- 0 to 1 over 20% time
                else
                    particle.alpha = 1.0
                end
                
                -- Update scale
                particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            end
            
            -- Update rotation
            particle.rotation = particle.rotation + particle.rotSpeed * dt
        end
    end
    
    -- Add a special effect at source and destination
    if effect.progress < 0.3 then
        -- Glow at source during initial phase
        effect.sourceGlow = 1.0 - (effect.progress / 0.3)
    else
        effect.sourceGlow = 0
    end
    
    -- Glow at mana pool during later phase
    if effect.progress > 0.5 then
        effect.poolGlow = (effect.progress - 0.5) * 2
        if effect.poolGlow > 1.0 then effect.poolGlow = 2 - effect.poolGlow end -- Peak at 0.75 progress
    else
        effect.poolGlow = 0
    end
end

-- Update function for surge effects
function VFX.updateSurge(effect, dt)
    -- Update center glow animation
    if effect.centerGlow then
        effect.centerParticleTimer = (effect.centerParticleTimer or 0) + dt
    end
    
    -- Fountain style upward burst with gravity pull and enhanced effects
    for _, particle in ipairs(effect.particles) do
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Apply acceleration if enabled
            if particle.riseAcceleration then
                -- Boost upward velocity over time
                local accelerationBoost = -particle.riseAcceleration * 60 * dt
                particle.speedY = particle.speedY + accelerationBoost
            end
            
            -- Base motion update
            particle.x = particle.x + particle.speedX * dt
            particle.y = particle.y + particle.speedY * dt
            particle.speedY = particle.speedY + particle.gravity * dt
            
            -- Handle sprite animation if enabled
            if particle.useSprite and particle.frameIndex and particle.frameRate then
                particle.frameTimer = (particle.frameTimer or 0) + dt
                if particle.frameTimer >= 1/particle.frameRate then
                    particle.frameIndex = particle.frameIndex + 1
                    if particle.frameIndex > spriteFrameCount then
                        particle.frameIndex = 1
                    end
                    particle.frameTimer = 0
                end
            end
            
            -- Apply spiral motion if enabled
            if particle.spiral then
                local spiralProgress = (effect.timer - particle.delay) * particle.spiralTightness
                local spiralAngle = spiralProgress * particle.spiralFrequency + particle.spiralPhase
                local spiralX = math.cos(spiralAngle) * particle.spiralAmplitude
                local spiralY = math.sin(spiralAngle) * particle.spiralAmplitude
                
                -- Apply spiral offset to position
                particle.x = particle.x + spiralX * dt * 5
                particle.y = particle.y + spiralY * dt * 5
            end
            
            -- Handle pulsation if enabled
            if particle.pulsate then
                local pulseOffset = math.sin(effect.timer * particle.pulseRate) * particle.pulseAmount
                particle.scale = particle.baseScale * (1 + pulseOffset)
            else
                -- Standard scale progression if not pulsating
                local scaleProgress = effect.progress
                particle.scale = effect.startScale + (effect.endScale - effect.startScale) * scaleProgress
            end
            
            -- Control sparkle flickering if enabled
            if particle.sparkle then
                -- Random flickering for sparkle particles
                local flicker = 0.7 + math.random() * 0.5
                particle.sparkleAlpha = flicker * particle.sparkleIntensity
            end
            
            -- Fade out toward end of effect, but with smoother transition
            if effect.progress > 0.6 then
                local fadeStart = 0.6
                local fadeDuration = 0.4
                local fadeProgress = (effect.progress - fadeStart) / fadeDuration
                -- Use smooth step function for nicer fade
                local fade = fadeProgress * fadeProgress * (3 - 2 * fadeProgress)
                particle.alpha = 1 - fade
            end
            
            -- Apply rotation 
            particle.rotation = particle.rotation + particle.rotationSpeed * dt
        end
    end
    
    -- Update center glow pulsing if enabled
    if effect.centerGlow then
        local pulseSpeed = 5
        effect.centerGlowPulse = 0.7 + 0.3 * math.sin(effect.centerParticleTimer * pulseSpeed)
    end
end

-- Draw all active effects
function VFX.draw()
    for _, effect in ipairs(VFX.activeEffects) do
        if effect.type == Constants.AttackType.PROJECTILE then
            VFX.drawProjectile(effect)
        elseif effect.type == "impact" then
            VFX.drawImpact(effect)
        elseif effect.type == "cone" then
            VFX.drawCone(effect)
        elseif effect.type == "remote" then
            VFX.drawRemote(effect)
        elseif effect.type == "aura" then
            VFX.drawAura(effect)
        elseif effect.type == "vertical" then
            VFX.drawVertical(effect)
        elseif effect.type == "beam" then
            VFX.drawBeam(effect)
        elseif effect.type == "conjure" then
            VFX.drawConjure(effect)
        elseif effect.type == "surge" then
            VFX.drawSurge(effect)
        elseif effect.type == "meteor" then
            VFX.drawMeteor(effect)
        end
    end
end

-- Draw function for projectile effects
function VFX.drawProjectile(effect)
    local particleImage = getAssetInternal("fireParticle")
    local glowImage = getAssetInternal("fireGlow")
    local impactImage = getAssetInternal("impactRing")
    
    -- Get bolt frames if needed
    local boltFrames = nil
    if effect.useSprites then
        boltFrames = getAssetInternal("boltFrames")
    end
    
    -- Calculate the actual trajectory angle for aimed shots
    -- This will be used for sprite rotation if it's a bolt
    local trajectoryAngle = nil
    if effect.useSourcePosition and effect.useTargetPosition then
        -- Calculate direction vector from current source to target
        local dirX = effect.targetX - effect.sourceX
        local dirY = effect.targetY - effect.sourceY
        
        -- Calculate the angle
        trajectoryAngle = math.atan2(dirY, dirX)
    end
    
    -- Calculate trail points but don't draw central line anymore
    -- We'll keep the trail points for particle positioning
    
    -- Draw head glow with motion blur effect
    if #effect.trailPoints > 0 then
        local head = effect.trailPoints[1]
        local leadingIntensity = effect.leadingIntensity or 1.5
        
        -- Apply flicker effect for bolt-type projectiles
        if effect.flickerRate and effect.flickerIntensity then
            -- Calculate flicker based on time and rate
            local flickerMod = math.sin(effect.timer * effect.flickerRate) * effect.flickerIntensity
            -- Apply intensity modification (make it brighter only, not dimmer)
            leadingIntensity = leadingIntensity * (1 + math.max(0, flickerMod))
        end
        
        -- Draw multiple layered glows for a more intense effect
        -- Outer glow
        love.graphics.setColor(
            effect.color[1], 
            effect.color[2], 
            effect.color[3], 
            0.3
        )
        local outerGlowScale = effect.startScale * 4.5
        love.graphics.draw(
            glowImage,
            head.x, head.y,
            0,
            outerGlowScale, outerGlowScale,
            glowImage:getWidth()/2, glowImage:getHeight()/2
        )
        
        -- Middle glow
        love.graphics.setColor(
            math.min(1.0, effect.color[1] * 1.2), 
            math.min(1.0, effect.color[2] * 1.2), 
            math.min(1.0, effect.color[3] * 1.2), 
            0.5
        )
        local middleGlowScale = effect.startScale * 3
        love.graphics.draw(
            glowImage,
            head.x, head.y,
            0,
            middleGlowScale, middleGlowScale,
            glowImage:getWidth()/2, glowImage:getHeight()/2
        )
        
        -- Inner glow (brightest)
        love.graphics.setColor(
            math.min(1.0, effect.color[1] * leadingIntensity), 
            math.min(1.0, effect.color[2] * leadingIntensity), 
            math.min(1.0, effect.color[3] * leadingIntensity), 
            0.7
        )
        local innerGlowScale = effect.startScale * 2
        love.graphics.draw(
            glowImage,
            head.x, head.y,
            0,
            innerGlowScale, innerGlowScale,
            glowImage:getWidth()/2, glowImage:getHeight()/2
        )
        
        -- Add enhanced directional motion blur based on trajectory
        if #effect.trailPoints >= 2 then
            local p1 = effect.trailPoints[1]
            local p2 = effect.trailPoints[2]
            
            -- Get direction vector
            local dirX = p1.x - p2.x
            local dirY = p1.y - p2.y
            local len = math.sqrt(dirX*dirX + dirY*dirY)
            
            if len > 0 then
                -- Normalize and create blur effect in the direction of motion
                dirX = dirX / len
                dirY = dirY / len
                
                -- Draw more motion blur particles for stronger speed effect
                for i = 1, 5 do
                    local distance = i * 8  -- Longer blur trail
                    local blurX = head.x - dirX * distance
                    local blurY = head.y - dirY * distance
                    local blurAlpha = 0.4 * (1 - i/5)  -- Slightly stronger alpha
                    
                    -- Elongated blur in direction of motion
                    local blurScaleX = effect.startScale * (2.2 - i * 0.3) * 1.3  -- Stretched in X
                    local blurScaleY = effect.startScale * (1.8 - i * 0.3) * 0.7  -- Compressed in Y
                    
                    -- Calculate angle for directional stretching
                    local angle = math.atan2(dirY, dirX)
                    
                    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], blurAlpha)
                    love.graphics.draw(
                        glowImage,
                        blurX, blurY,
                        angle,  -- Apply rotation to align with movement
                        blurScaleX, blurScaleY,
                        glowImage:getWidth()/2, glowImage:getHeight()/2
                    )
                    
                    -- Add small secondary particles for turbulence effect
                    if i < 3 and math.random() > 0.5 then
                        local offsetX = math.random(-5, 5)
                        local offsetY = math.random(-5, 5)
                        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], blurAlpha * 0.7)
                        love.graphics.draw(
                            particleImage,
                            blurX + offsetX, blurY + offsetY,
                            math.random() * math.pi * 2,
                            effect.startScale * 0.4, effect.startScale * 0.4,
                            particleImage:getWidth()/2, particleImage:getHeight()/2
                        )
                    end
                end
            end
        end
    end
    
    -- Draw particles with effect-specific rendering
    -- First draw trail particles (behind core)
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 and not particle.isCore then
            -- Use a slightly different color for trail particles
            local r = effect.color[1] * 0.9
            local g = effect.color[2] * 0.9
            local b = effect.color[3] * 0.9
            
            -- Apply flicker effect to trail particles for bolt-type projectiles
            local trailAlpha = particle.alpha * 0.8
            if effect.flickerRate and effect.flickerIntensity then
                -- Calculate unique flicker phase for each particle to create lightning-like effect
                local particlePhase = effect.timer * effect.flickerRate + particle.x * 0.05
                local flickerMod = math.sin(particlePhase) * effect.flickerIntensity
                -- Make particles brighter during flicker but not completely invisible
                trailAlpha = trailAlpha * (1 + math.max(-0.3, flickerMod))
            end
            
            love.graphics.setColor(r, g, b, trailAlpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Then draw core particles (on top, brighter)
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 and particle.isCore then
            -- Core particles are brighter
            local leadingIntensity = effect.leadingIntensity or 1.5
            
            -- Apply flicker effect to core particles for bolt-type projectiles
            if effect.flickerRate and effect.flickerIntensity then
                -- Calculate unique flicker phase for each particle to create lightning-like effect
                local particlePhase = effect.timer * effect.flickerRate + particle.x * 0.05
                local flickerMod = math.sin(particlePhase) * effect.flickerIntensity
                -- Apply intensity modification (make it brighter during flashes)
                leadingIntensity = leadingIntensity * (1 + math.max(0, flickerMod))
            end
            
            local r = math.min(1.0, effect.color[1] * leadingIntensity)
            local g = math.min(1.0, effect.color[2] * leadingIntensity)
            local b = math.min(1.0, effect.color[3] * leadingIntensity)
            
            love.graphics.setColor(r, g, b, particle.alpha)
            
            -- Draw with slight stretching in the direction of motion if we have trail points
            if #effect.trailPoints >= 2 then
                local p1 = effect.trailPoints[1]
                local p2 = effect.trailPoints[2]
                local angle = math.atan2(p1.y - p2.y, p1.x - p2.x)
                
                -- Draw with slight directional stretching
                love.graphics.draw(
                    particleImage,
                    particle.x, particle.y,
                    angle + particle.rotation,
                    particle.scale * 1.2, particle.scale * 0.9, -- Stretch in direction of motion
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
                
                -- Add small secondary glow for core particles
                love.graphics.setColor(r, g, b, particle.alpha * 0.4)
                love.graphics.draw(
                    glowImage,
                    particle.x, particle.y,
                    angle + particle.rotation,
                    particle.scale * 1.5, particle.scale * 1.5,
                    glowImage:getWidth()/2, glowImage:getHeight()/2
                )
            else
                -- Fallback if no trail points
                love.graphics.draw(
                    particleImage,
                    particle.x, particle.y,
                    particle.rotation,
                    particle.scale, particle.scale,
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
            end
        end
    end
    
    -- Draw impact transition effects
    local impactTransition = math.max(0, (effect.progress - 0.9) / 0.1)
    if impactTransition > 0 then
        -- Draw expanding ring
        love.graphics.setColor(
            effect.color[1], 
            effect.color[2], 
            effect.color[3], 
            impactTransition * (1 - impactTransition) * 4 -- Peak at 0.5 transition progress
        )
        
        -- Calculate ring size
        local ringScale = effect.impactSize * impactTransition * 1.5
        
        -- Draw impact ring
        love.graphics.draw(
            impactImage,
            effect.targetX, effect.targetY,
            0,
            ringScale, ringScale,
            impactImage:getWidth()/2, impactImage:getHeight()/2
        )
        
        -- Draw center flash/glow
        local flashIntensity = (1 - impactTransition) * impactTransition * 4
        if flashIntensity > 0 then
            -- Bright center flash
            love.graphics.setColor(
                math.min(1.0, effect.color[1] * 1.5), 
                math.min(1.0, effect.color[2] * 1.5), 
                math.min(1.0, effect.color[3] * 1.5), 
                flashIntensity
            )
            
            local flashSize = effect.impactSize * 25 * impactTransition
            love.graphics.draw(
                glowImage,
                effect.targetX, effect.targetY,
                0,
                flashSize / glowImage:getWidth(), flashSize / glowImage:getHeight(),
                glowImage:getWidth()/2, glowImage:getHeight()/2
            )
        end
    end
    
    -- Sprite-based rendering for bolt effects
    if effect.useSprites and boltFrames and #boltFrames > 0 then
        -- Calculate which frame to use based on animation time
        local frameRate = effect.spriteFrameRate or 15
        local totalFrames = #boltFrames
        local frameIndex = math.floor((effect.timer * frameRate) % totalFrames) + 1
        local currentFrame = boltFrames[frameIndex]
        
        if currentFrame then
            -- Calculate rotation angle for the sprite
            local rotationAngle = effect.spriteRotationOffset or 0
            
            -- If we have a trajectory angle from source to target (for aimed shots)
            -- use that instead of the trail points
            if trajectoryAngle then
                rotationAngle = trajectoryAngle + (effect.spriteRotationOffset or 0)
            elseif #effect.trailPoints >= 2 then
                -- Fallback to using trail points
                local p1 = effect.trailPoints[1]
                local p2 = effect.trailPoints[2]
                
                -- Get direction vector for trajectory
                local dirX = p1.x - p2.x
                local dirY = p1.y - p2.y
                local len = math.sqrt(dirX*dirX + dirY*dirY)
                
                if len > 0 then
                    -- Calculate rotation angle
                    rotationAngle = math.atan2(dirY, dirX) + (effect.spriteRotationOffset or 0)
                end
            end
            
            -- Draw the bolt sprite along the trail
            local trailSegmentCount = math.min(5, #effect.trailPoints)
            local segmentSpacing = 1
            
            for i = 1, trailSegmentCount, segmentSpacing do
                local point = effect.trailPoints[i]
                local alpha = 1.0
                
                -- Fade out at the back of the trail
                if i > 1 then
                    alpha = (trailSegmentCount - i + 1) / trailSegmentCount
                end
                
                -- Apply flicker effect to bolt sprite
                if effect.flickerRate and effect.flickerIntensity then
                    -- Calculate unique flicker phase for each segment
                    local segmentPhase = effect.timer * effect.flickerRate + i * 0.2
                    local flickerMod = math.sin(segmentPhase) * effect.flickerIntensity
                    -- Adjust alpha but keep it visible
                    alpha = alpha * (1 + math.max(-0.3, flickerMod))
                end
                
                -- Determine scaling based on position in the trail
                local scale = effect.spriteScale or 0.85
                if i == 1 then
                    -- Head of bolt is slightly larger
                    scale = scale * 1.2
                end
                
                -- Set color with tinting if enabled
                if effect.spriteTint then
                    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
                else
                    -- Pure white with alpha
                    love.graphics.setColor(1, 1, 1, alpha)
                end
                
                -- Draw sprite
                love.graphics.draw(
                    currentFrame,
                    point.x, point.y,
                    rotationAngle,
                    scale, scale,
                    currentFrame:getWidth()/2, currentFrame:getHeight()/2
                )
            end
        end
    end
    
    -- Add element-specific effects based on color/motion style
    if effect.motion == Constants.MotionStyle.RISE then
        -- Add rising embers for fire-like effects
        local emberCount = 3
        local emberProgress = math.min(effect.progress * 1.5, 1.0)
        
        for i = 1, emberCount do
            local pointIdx = math.min(math.floor(i / emberCount * #effect.trailPoints) + 1, #effect.trailPoints)
            local point = effect.trailPoints[pointIdx]
            local riseOffset = i * 5 * emberProgress
            
            -- Draw small embers rising from the trail
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.3 * (1 - i/emberCount))
            love.graphics.draw(
                particleImage,
                point.x + math.sin(effect.timer * 2 + i) * 3, 
                point.y - riseOffset,
                effect.timer * 2 + i,
                effect.startScale * 0.4, effect.startScale * 0.4,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    elseif effect.motion == Constants.MotionStyle.RIPPLE then
        -- Add ripple effect for water-like effects
        for i = 1, 2 do
            local idx = math.min(i * 3, #effect.trailPoints)
            if idx <= #effect.trailPoints then
                local point = effect.trailPoints[idx]
                local rippleSize = effect.startScale * (2 - i * 0.5) * math.sin(effect.timer * 3 + i * 0.7)
                
                if rippleSize > 0 then
                    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.2 * rippleSize)
                    love.graphics.circle("line", point.x, point.y, rippleSize * 10)
                end
            end
        end
    end
end

-- Draw function for impact effects
function VFX.drawImpact(effect)
    local particleImage = getAssetInternal("fireParticle")
    local impactImage = getAssetInternal("impactRing")
    
    -- Draw expanding ring
    local ringProgress = math.min(effect.progress * 1.5, 1.0) -- Ring expands faster than full effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - ringProgress)) -- Use base color, apply ring alpha
    local ringScale = effect.radius * 0.02 * ringProgress
    love.graphics.draw(
        impactImage,
        effect.targetX, effect.targetY,
        0,
        ringScale, ringScale,
        impactImage:getWidth()/2, impactImage:getHeight()/2
    )
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha) -- Use base color, apply particle alpha
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw central flash
    if effect.progress < 0.3 then
        local flashIntensity = 1.0 - (effect.progress / 0.3)
        love.graphics.setColor(1, 1, 1, flashIntensity * 0.7)
        love.graphics.circle("fill", effect.targetX, effect.targetY, 30 * flashIntensity)
    end
end

-- Draw function for aura effects
function VFX.drawAura(effect)
    local particleImage = getAssetInternal("sparkle")
    
    -- Draw base aura circle
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.2
    local baseAlpha = 0.3 * (1 - (math.abs(effect.progress - 0.5) * 2)^2) -- Peak at middle of effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], baseAlpha)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, baseAlpha * 1.5)
    love.graphics.circle("line", effect.sourceX, effect.sourceY, effect.radius * (1 + pulseAmount))
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha) -- Use base color, apply particle alpha
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
end

-- Draw function for vertical effects
function VFX.drawVertical(effect)
    local particleImage = getAssetInternal("fireParticle")
    
    -- Draw base effect at source
    local baseProgress = math.min(effect.progress * 3, 1.0) -- Quick initial flash
    if baseProgress < 1.0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - baseProgress) * 0.7)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 40 * baseProgress)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha) -- Use base color, apply particle alpha
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw guiding lines (subtle vertical paths)
    if effect.progress < 0.7 then
        local lineAlpha = 0.3 * (1.0 - effect.progress / 0.7)
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], lineAlpha)
        for i = 1, 5 do
            local xOffset = (i - 3) * 10
            local startY = effect.sourceY
            local endY = effect.sourceY - effect.height * math.min(effect.progress * 2, 1.0)
            love.graphics.line(effect.sourceX + xOffset, startY, effect.sourceX + xOffset * 1.5, endY)
        end
    end
end

-- Draw function for beam effects
function VFX.drawBeam(effect)
    local particleImage = getAssetInternal("sparkle")
    
    -- Use current beam properties (which have been updated in updateBeam)
    local beamLength = effect.beamLength * effect.beamProgress
    
    -- Draw base beam
    local beamEndX = effect.sourceX + math.cos(effect.beamAngle) * beamLength
    local beamEndY = effect.sourceY + math.sin(effect.beamAngle) * beamLength
    
    -- Calculate beam width with pulse
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.3
    local beamWidth = effect.beamWidth * (1 + pulseAmount) * (1 - (effect.progress > 0.5 and (effect.progress - 0.5) * 2 or 0))
    
    -- Draw outer beam glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.3) -- Use base color, apply fixed alpha
    love.graphics.setLineWidth(beamWidth * 1.5)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw inner beam core
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, 0.7) -- Use base color (brightened), apply fixed alpha
    love.graphics.setLineWidth(beamWidth * 0.7)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw brightest beam center
    love.graphics.setColor(1, 1, 1, 0.9) -- Keep white center for now
    love.graphics.setLineWidth(beamWidth * 0.3)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha) -- Use base color, apply particle alpha
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw source glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.7) -- Use base color, apply fixed alpha
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, 20 * (1 + pulseAmount))
    
    -- Draw impact glow at target if beam is fully extended
    if effect.beamProgress >= 0.99 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.8 * (1 - (effect.progress - 0.5) * 2)) -- Use base color, apply calculated alpha
        love.graphics.circle("fill", beamEndX, beamEndY, 25 * (1 + pulseAmount))
    end
end

-- Draw function for conjure effects
function VFX.drawConjure(effect)
    local particleImage = getAssetInternal("sparkle")
    local glowImage = getAssetInternal("fireGlow")  -- We'll use this for all conjure types
    
    -- Draw source glow if active
    if effect.sourceGlow and effect.sourceGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.sourceGlow * 0.6) -- Use base color, apply calculated alpha
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 50 * effect.sourceGlow)
        
        -- Draw expanding rings from source (hint at conjuration happening)
        local ringCount = 3
        for i = 1, ringCount do
            local ringProgress = ((effect.timer * 1.5) % 1.0) + (i-1) / ringCount
            if ringProgress < 1.0 then
                local ringSize = 60 * ringProgress
                local ringAlpha = 0.5 * (1.0 - ringProgress) * effect.sourceGlow
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], ringAlpha) -- Use base color, apply calculated alpha
                love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
            end
        end
    end
    
    -- Draw mana pool glow if active
    if effect.poolGlow and effect.poolGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.poolGlow * 0.7) -- Use base color, apply calculated alpha
        love.graphics.circle("fill", effect.manaPoolX, effect.manaPoolY, 40 * effect.poolGlow)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            -- Choose the right glow image based on final pulse state
            local imgToDraw = particleImage
            
            -- Adjust color based on state
            if particle.finalPulse then
                -- Brighter for final pulse
                love.graphics.setColor(
                    effect.color[1] * 1.3, 
                    effect.color[2] * 1.3, 
                    effect.color[3] * 1.3, 
                    particle.alpha -- Use base color (brightened), apply particle alpha
                )
                imgToDraw = glowImage
            else
                love.graphics.setColor(
                    effect.color[1], 
                    effect.color[2], 
                    effect.color[3], 
                    particle.alpha -- Use base color, apply particle alpha
                )
            end
            
            -- Draw the particle
            love.graphics.draw(
                imgToDraw,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                imgToDraw:getWidth()/2, imgToDraw:getHeight()/2
            )
            
            -- For volatile conjuring, add random color sparks
            if effect.name:lower() == "volatileconjuring" and not particle.finalPulse and math.random() < 0.3 then
                -- Random rainbow hue for volatile conjuring
                local hue = (effect.timer * 0.5 + particle.x * 0.01) % 1.0
                local r, g, b = HSVtoRGB(hue, 0.8, 1.0)
                
                love.graphics.setColor(r, g, b, particle.alpha * 0.7)
                love.graphics.draw(
                    particleImage,
                    particle.x + math.random(-5, 5), 
                    particle.y + math.random(-5, 5),
                    particle.rotation + math.random() * math.pi,
                    particle.scale * 0.5, particle.scale * 0.5,
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
            end
        end
    end
    
    -- Draw connection lines between particles (ethereal threads)
    if effect.progress < 0.7 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.2) -- Use base color, apply fixed alpha
        
        local maxConnectDist = 50  -- Maximum distance for particles to connect
        for i = 1, #effect.particles do
            local p1 = effect.particles[i]
            if p1.active and p1.alpha > 0.2 and not p1.finalPulse then
                for j = i+1, #effect.particles do
                    local p2 = effect.particles[j]
                    if p2.active and p2.alpha > 0.2 and not p2.finalPulse then
                        local dx = p1.x - p2.x
                        local dy = p1.y - p2.y
                        local dist = math.sqrt(dx*dx + dy*dy)
                        
                        if dist < maxConnectDist then
                            -- Fade based on distance
                            local alpha = (1 - dist/maxConnectDist) * 0.3 * p1.alpha * p2.alpha
                            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha) -- Use base color, apply calculated alpha
                            love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                        end
                    end
                end
            end
        end
    end
end

-- Draw function for surge effects
function VFX.drawSurge(effect)
    local particleImage = getAssetInternal("sparkle")
    
    -- Draw expanding ground effect ring at source
    if effect.progress < 0.7 then
        local ringProgress = effect.progress / 0.7
        local ringSize = 30 + ringProgress * 40 -- Grows from 30 to 70 pixels
        local ringAlpha = 0.5 * (1 - ringProgress)
        
        love.graphics.setColor(effect.color[1] * 0.8, effect.color[2] * 0.8, effect.color[3] * 0.8, ringAlpha)
        love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
        
        -- Add inner filled ring
        local innerRingSize = ringSize * 0.7
        love.graphics.setColor(effect.color[1] * 0.6, effect.color[2] * 0.6, effect.color[3] * 0.6, ringAlpha * 0.5)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, innerRingSize)
    end
    
    -- Draw enhanced center glow if enabled
    if effect.centerGlow then
        -- Get size and pulse parameters
        local centerGlowSize = effect.centerGlowSize or 50
        local glowIntensity = effect.centerGlowIntensity or 1.3
        local glowPulse = effect.centerGlowPulse or 1.0
        
        -- Calculate fade based on progress
        local glowAlpha
        if effect.progress < 0.6 then
            glowAlpha = 0.7  -- Full strength during main part
        else
            -- Fade out during last 40% of effect
            glowAlpha = 0.7 * (1 - (effect.progress - 0.6) / 0.4)
        end
        
        -- Draw outer glow layers
        love.graphics.setColor(effect.color[1] * 0.5, effect.color[2] * 0.5, effect.color[3] * 0.5, glowAlpha * 0.4)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 1.2 * glowPulse)
        
        -- Middle glow layer
        love.graphics.setColor(effect.color[1] * 0.8, effect.color[2] * 0.8, effect.color[3] * 0.8, glowAlpha * 0.6)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 0.8 * glowPulse)
        
        -- Bright core
        love.graphics.setColor(effect.color[1] * glowIntensity, effect.color[2] * glowIntensity, 
                              effect.color[3] * glowIntensity, glowAlpha * 0.8)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 0.5 * glowPulse)
        
        -- White inner core
        love.graphics.setColor(1, 1, 1, glowAlpha * 0.9 * glowPulse)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, centerGlowSize * 0.2 * glowPulse)
    else
        -- Simpler base glow at origin if centerGlow not enabled
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.3 * (1 - effect.progress))
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 35 * (1 - effect.progress))
    end
    
    -- Draw bloom halos first (rendered underneath particles)
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 and particle.bloom then
            local bloomIntensity = particle.bloomIntensity or 0.8
            local bloomAlpha = particle.alpha * 0.6 * bloomIntensity
            local bloomScale = particle.scale * 2.5
            
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], bloomAlpha)
            love.graphics.circle("fill", particle.x, particle.y, particleImage:getWidth()/2 * bloomScale)
        end
    end

    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            -- Base particle
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
            
            -- Add sparkle overlay for sparkle particles
            if particle.sparkle and particle.sparkleAlpha and particle.sparkleAlpha > 0 then
                -- Draw a bright white overlay
                love.graphics.setColor(1, 1, 1, particle.sparkleAlpha)
                love.graphics.draw(
                    particleImage,
                    particle.x, particle.y,
                    particle.rotation,
                    particle.scale * 0.6, particle.scale * 0.6,
                    particleImage:getWidth()/2, particleImage:getHeight()/2
                )
            end
        end
    end
    
    -- Draw additional radial lines emanating from center for dramatic effect
    if effect.progress < 0.3 then
        local lineProgress = effect.progress / 0.3
        local lineCount = 12
        local lineLength = 40 * (1 - lineProgress) -- Lines shrink as they dissipate
        local lineAlpha = 0.4 * (1 - lineProgress)
        
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], lineAlpha)
        for i = 1, lineCount do
            local angle = (i / lineCount) * math.pi * 2
            local endX = effect.sourceX + math.cos(angle) * lineLength
            local endY = effect.sourceY + math.sin(angle) * lineLength
            love.graphics.line(effect.sourceX, effect.sourceY, endX, endY)
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

-- Update function for meteor effect
function VFX.updateRemote(effect, dt)
    -- Target position tracking now handled in main VFX.update
    
    -- Update particles for the warp/remote effect
    for i, particle in ipairs(effect.particles) do
        -- Activate particles based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Check if we have a motion style to apply
            if particle.motion then
                -- Use the updateParticle function with motion style
                VFX.updateParticle(particle, effect, dt, particleProgress)
            else
                -- Default behavior: move from center outward with easing
                local moveProgress = math.min(particleProgress * 1.5, 1.0) -- Move faster than the total duration
                local easeProgress = math.sin(moveProgress * math.pi / 2) -- Ease out curve
                
                -- Get current target position
                local centerX = effect.targetX
                local centerY = effect.targetY
                
                -- Calculate angle and distance for this particle
                local angle = particle.angle
                local distance = particle.distance
                
                -- Calculate position directly from center using angle and distance
                -- This ensures we're always relative to the current target position
                local moveDistance = distance * easeProgress
                particle.x = centerX + math.cos(angle) * moveDistance
                particle.y = centerY + math.sin(angle) * moveDistance
                
                -- Fade out near the end
                if particleProgress > 0.7 then
                    particle.alpha = (1.0 - particleProgress) / 0.3 -- Fade out in the last 30% of lifetime
                end
                
                -- Scale up then down
                local scaleProgress = 1.0 - math.abs(particleProgress * 2 - 1.0) -- Peak at the middle
                particle.scale = effect.startScale + (effect.endScale - effect.startScale) * scaleProgress
            end
        end
    end
    
    -- Update sprite rotation if enabled
    if effect.rotateSprite and effect.rotationSpeed then
        -- Accumulate rotation over time
        effect.spriteAngle = (effect.spriteAngle or 0) + effect.rotationSpeed * dt
    end
end

-- Update function for cone blast effects
function VFX.updateCone(effect, dt)
    -- Calculate the base direction from source to target
    local dirX = effect.targetX - effect.sourceX
    local dirY = effect.targetY - effect.sourceY
    local baseAngle = math.atan2(dirY, dirX)
    
    -- Update wave timing
    local waveCount = effect.waveCount or 3
    for i = 1, waveCount do
        -- Calculate when this wave should start
        local waveStartTime = (i - 1) * effect.duration * 0.3 / waveCount
        
        -- Check if this wave should be started
        if effect.timer >= waveStartTime and (not effect.waveStarted or not effect.waveStarted[i]) then
            -- Mark this wave as started
            effect.waveStarted = effect.waveStarted or {}
            effect.waveStarted[i] = true
        end
    end
    
    -- Update particles based on their properties
    for _, particle in ipairs(effect.particles) do
        -- Initialize particle if delayed start time has been reached
        if not particle.active and effect.timer >= particle.delay then
            particle.active = true
            particle.startTime = 0
        end
        
        -- Only process active particles
        if particle.active then
            -- Update particle timing
            particle.startTime = (particle.startTime or 0) + dt
            
            -- Handle wave particles specially
            if particle.isWave and particle.waveIndex then
                -- Calculate wave progress
                local waveDelay = (particle.waveIndex - 1) / waveCount * 0.3
                local waveProgress = (effect.progress - waveDelay) / 0.7
                
                if waveProgress > 0 and waveProgress < 1.0 then
                    -- Apply wave persistence to extend wave visibility if property exists
                    local visibleProgress = waveProgress
                    if particle.persistenceFactor then
                        -- Scale progress value to make waves fade more slowly
                        visibleProgress = waveProgress / particle.persistenceFactor
                    end
                    
                    if visibleProgress < 1.0 then
                        -- Calculate wave position along cone
                        local distance = (effect.coneLength or 320) * waveProgress * 0.95  -- Extended wave reach
                        
                        -- Move particle along its angle
                        particle.x = effect.sourceX + math.cos(particle.angle) * distance
                        particle.y = effect.sourceY + math.sin(particle.angle) * distance
                        
                        -- Calculate wave intensity - stronger at the front edge
                        local waveFront = math.max(0, 1 - math.abs(waveProgress - 0.3) * 5) -- Peak around 30% progress
                        local waveCrestSize = effect.waveCrestSize or 2.2
                        
                        -- Apply size increase for wave crest particles
                        if waveFront > 0.1 then
                            -- Make particles larger near the wave front
                            particle.scale = particle.scale * (1 + waveFront * waveCrestSize)
                        end
                        
                        -- Apply glow effect to leading edge if enabled
                        if effect.leadingEdgeGlow and waveFront > 0.1 then
                            -- Flag for special rendering in draw function
                            particle.isLeadingEdge = true
                            particle.glowIntensity = waveFront
                            
                            -- Create trailing glow if enabled
                            if particle.trailGlow and particle.trailGlow > 0 then
                                particle.drawTrail = true
                                particle.trailLength = distance * 0.2 * particle.trailGlow -- 20% of distance back
                                particle.trailWidth = waveFront * 10 * particle.trailGlow -- Width based on wave front
                            end
                        end
                    
                    -- Apply intensity falloff with distance if specified
                    local falloff = 1.0
                    if effect.intensityFalloff then
                        -- Calculate distance from source as a percentage of total cone length
                        local distancePercent = distance / (effect.coneLength or 320)
                        -- Apply non-linear falloff (more dramatic at edges)
                        falloff = 1.0 - (distancePercent * effect.intensityFalloff)
                        falloff = math.max(0.15, falloff) -- Higher minimum intensity
                    end
                    
                    -- Adjust alpha based on wave progress with pulsing effect
                    local pulseEffect = 1.0 + 0.3 * math.sin(waveProgress * math.pi * 8)
                    -- Slower fade for longer persistence
                    local fadeRate = particle.persistenceFactor and 0.8 or 1.0
                    particle.alpha = math.min(1.0, 1.1 * (1 - visibleProgress * fadeRate) * pulseEffect * falloff)
                    
                    -- Add wave-specific motion effects based on spell properties and wave index
                    if particle.waveIndex and particle.waveIndex > 1 then
                        -- Later waves can have additional motion effects
                        local wiggle = math.sin(effect.timer * (8 + particle.waveIndex * 2) + particle.x * 0.02) * 2
                        particle.x = particle.x + wiggle * (particle.waveIndex * 0.5)
                    end
                else
                    -- Wave not visible due to progress
                    particle.alpha = 0
                end
            else
                -- Wave not visible yet or has passed
                particle.alpha = 0
            end
            else
                -- Regular fill particles
                -- Calculate progress for this particle
                local particleProgress = math.min(particle.startTime / (effect.duration * 0.8), 1.0)
                
                -- Move particle from source toward target position - faster for more dramatic movement
                local moveProgress = math.min(particleProgress * 1.7, 1.0) -- Even faster movement for dramatic effect
                
                particle.x = effect.sourceX + (particle.targetX - effect.sourceX) * moveProgress
                particle.y = effect.sourceY + (particle.targetY - effect.sourceY) * moveProgress
                
                -- Add more chaotic turbulence for background particles
                local turbulence = effect.turbulence or 0.4
                -- Scale jitter with distance from center of cone for more chaotic edges
                local dirX = particle.targetX - effect.sourceX
                local dirY = particle.targetY - effect.sourceY
                local angle = math.atan2(dirY, dirX)
                local coneDir = math.atan2(effect.targetY - effect.sourceY, effect.targetX - effect.sourceX)
                local angleDiff = math.abs(angle - coneDir)
                -- More jitter at the edges of the cone
                local edgeFactor = math.min(1.0, angleDiff / (math.rad(effect.coneAngle or 70) / 2))
                local jitterScale = 8 * turbulence * (1 - moveProgress) * (1 + edgeFactor)
                
                particle.x = particle.x + math.cos(particle.startTime * 5) * jitterScale
                particle.y = particle.y + math.sin(particle.startTime * 5) * jitterScale
                
                -- Calculate particle size variance based on template parameter
                local sizeVariance = effect.particleSizeVariance or 0.2
                local sizeMultiplier = 1.0 + (math.random() * 2 - 1) * sizeVariance
                
                -- Apply scale changes with size variance
                particle.scale = (effect.startScale + (effect.endScale - effect.startScale) * particleProgress) * sizeMultiplier
                
                -- Adjust alpha for more dramatic falloff and occasional flicker
                if moveProgress > 0.5 then
                    -- Base falloff
                    local alphaFalloff = (1 - (moveProgress - 0.5) / 0.5)
                    -- Add subtle flicker
                    local flicker = 1.0 + 0.2 * math.sin(particle.startTime * 12 + particle.x * 0.05)
                    particle.alpha = particle.alpha * alphaFalloff * flicker
                end
                
                -- Faster rotation for more energetic appearance
                particle.rotation = particle.rotation + dt * (3 + math.random() * 2)
            end
        end
    end
    
    -- Apply intensity based on range/elevation if not already handled
    if effect.rangeBand == Constants.RangeState.NEAR and effect.nearRangeIntensity and not effect.currentIntensityMultiplier then
        effect.currentIntensityMultiplier = effect.nearRangeIntensity
    end
    
    if effect.elevation == Constants.ElevationState.GROUNDED and effect.matchedElevationIntensity and not effect.currentIntensityMultiplier then
        effect.currentIntensityMultiplier = effect.currentIntensityMultiplier or 1.0
        effect.currentIntensityMultiplier = effect.currentIntensityMultiplier * effect.matchedElevationIntensity
    end
end

function VFX.updateMeteor(effect, dt)
    -- Process all particles
    for i, particle in ipairs(effect.particles) do
        -- Activate particles based on delay
        if not particle.active and effect.timer >= particle.delay then
            particle.active = true
            particle.startTime = effect.timer
        end
        
        if particle.active then
            -- Track particle lifetime
            local particleTime = effect.timer - particle.startTime
            
            -- Handle meteor particles vs. explosion particles differently
            if particle.explosion then
                -- Handle explosion particles (activate after impact)
                if particleTime >= particle.delay then
                    -- Fade in quickly
                    particle.alpha = math.min(1.0, (particleTime - particle.delay) * 10)
                    
                    -- Position based on speed
                    particle.x = particle.x + particle.speedX * dt
                    particle.y = particle.y + particle.speedY * dt
                    
                    -- Add gravity to flatten the explosion
                    particle.speedY = particle.speedY + 400 * dt
                    
                    -- Slow down over time (air resistance)
                    particle.speedX = particle.speedX * 0.95
                    particle.speedY = particle.speedY * 0.95
                    
                    -- Rotate the particle
                    particle.rotation = particle.rotation + dt * 2
                    
                    -- Fade out near end of effect
                    if effect.progress > 0.7 then
                        particle.alpha = math.max(0, 1 - ((effect.progress - 0.7) / 0.3))
                    end
                    
                    -- Scale down slightly
                    particle.scale = particle.scale * 0.98
                end
            else
                -- Handle meteor particles
                if not particle.hasImpacted then
                    -- Still falling - update position
                    particle.x = particle.x + particle.speedX * dt
                    particle.y = particle.y + particle.speedY * dt
                    
                    -- Rotate the meteor
                    particle.rotation = particle.rotation + (particle.rotSpeed or 1) * dt
                    
                    -- Increase speed (acceleration due to gravity)
                    local gravityAccel = 200 * dt
                    particle.speedY = particle.speedY + gravityAccel
                    
                    -- Check for impact with ground
                    if particle.y >= effect.targetY - 10 then
                        particle.hasImpacted = true
                        particle.impactTime = particleTime
                        
                        -- Stop moving
                        particle.speedX = 0
                        particle.speedY = 0
                        
                        -- Set Y to exact ground position
                        particle.y = effect.targetY
                    end
                    
                    -- Create fire trail effect 
                    if particle.fireTrail and effect.timer % 0.05 < dt then
                        -- TODO: In a full implementation, this would create small
                        -- fire particles behind the meteor for a trailing effect
                    end
                else
                    -- After impact, fade out quickly
                    local impactProgress = (particleTime - particle.impactTime) / 0.3
                    particle.alpha = math.max(0, 1 - impactProgress)
                    
                    -- Expand slightly on impact
                    local impactScale = 1 + math.min(0.5, impactProgress * 2)
                    particle.scale = effect.startScale * impactScale
                    
                    -- Fade out
                    if effect.progress > 0.6 then
                        particle.alpha = particle.alpha * 0.9
                    end
                end
            end
        end
    end
end

-- Draw function for cone blast effects
function VFX.drawCone(effect)
    local particleImage = getAssetInternal("sparkle")
    local glowImage = getAssetInternal("fireGlow") -- For enhanced glow effects
    
    -- Get intensity multiplier for range-based effects
    local intensityMult = effect.currentIntensityMultiplier or 1.0
    
    -- Draw background glow for the entire cone area at the beginning
    if effect.progress < 0.5 then
        -- Calculate cone properties
        local coneAngleRad = (effect.coneAngle or 70) * math.pi / 180
        local coneLength = effect.coneLength or 240
        local halfConeLength = coneLength * 0.7 * (1 - effect.progress * 0.8) -- Fades with progress
        
        -- Calculate the base direction from source to target
        local dirX = effect.targetX - effect.sourceX
        local dirY = effect.targetY - effect.sourceY
        local baseAngle = math.atan2(dirY, dirX)
        
        -- Draw a subtle background glow using triangles
        local numSegments = 12
        love.graphics.setColor(effect.color[1] * 0.7, effect.color[2] * 0.7, effect.color[3] * 0.7, 
                             0.2 * (1 - effect.progress) * intensityMult)
        
        for j = 1, numSegments - 1 do
            local angle1 = baseAngle - coneAngleRad/2 + (j-1) * coneAngleRad / (numSegments-1)
            local angle2 = baseAngle - coneAngleRad/2 + j * coneAngleRad / (numSegments-1)
            
            local x1 = effect.sourceX + math.cos(angle1) * halfConeLength
            local y1 = effect.sourceY + math.sin(angle1) * halfConeLength
            local x2 = effect.sourceX + math.cos(angle2) * halfConeLength
            local y2 = effect.sourceY + math.sin(angle2) * halfConeLength
            
            -- Draw triangle from source to arc segment
            love.graphics.polygon("fill", effect.sourceX, effect.sourceY, x1, y1, x2, y2)
        end
    end
    
    -- Draw wave fronts (for wave particles)
    for i = 1, effect.waveCount or 4 do
        -- Only draw if the wave has started
        if effect.waveStarted and effect.waveStarted[i] then
            -- Calculate wave progress based on wave index
            local waveDelay = (i - 1) / (effect.waveCount or 4) * 0.4 -- Spread waves out more
            local waveProgress = (effect.progress - waveDelay) / 0.6
            
            if waveProgress > 0 and waveProgress < 1.0 then
                -- Calculate cone properties
                local coneAngleRad = (effect.coneAngle or 70) * math.pi / 180
                local coneLength = effect.coneLength or 240
                local waveDistance = coneLength * waveProgress * 0.95  -- Extended wave reach
                
                -- Calculate the base direction from source to target
                local dirX = effect.targetX - effect.sourceX
                local dirY = effect.targetY - effect.sourceY
                local baseAngle = math.atan2(dirY, dirX)
                
                -- Calculate wave arc points
                local numPoints = 16  -- More points for smoother arc
                local waveFront = math.max(0, 1 - math.abs(waveProgress - 0.3) * 5) -- Peak around 30% progress
                local waveThickness = (4 + waveFront * 3) * intensityMult -- Thicker at wave front
                
                -- Calculate wave color with leading edge glow
                local r, g, b = effect.color[1], effect.color[2], effect.color[3]
                if waveFront > 0.1 and effect.leadingEdgeGlow then
                    -- Brighter color at wave front
                    r = r * (1 + waveFront * 0.5)
                    g = g * (1 + waveFront * 0.5)
                    b = b * (1 + waveFront * 0.5)
                end
                
                -- Draw wave arc
                love.graphics.setLineWidth(waveThickness)
                love.graphics.setColor(r, g, b, (0.7 + waveFront * 0.3) * (1 - waveProgress * 0.7) * intensityMult)
                
                -- Draw arc segments
                for j = 1, numPoints - 1 do
                    local angle1 = baseAngle - coneAngleRad/2 + (j-1) * coneAngleRad / (numPoints-1)
                    local angle2 = baseAngle - coneAngleRad/2 + j * coneAngleRad / (numPoints-1)
                    
                    local x1 = effect.sourceX + math.cos(angle1) * waveDistance
                    local y1 = effect.sourceY + math.sin(angle1) * waveDistance
                    local x2 = effect.sourceX + math.cos(angle2) * waveDistance
                    local y2 = effect.sourceY + math.sin(angle2) * waveDistance
                    
                    love.graphics.line(x1, y1, x2, y2)
                    
                    -- Add extra glow points at wave crest
                    if waveFront > 0.2 and j % 3 == 1 then
                        local glowSize = waveFront * (effect.waveCrestSize or 1.0) * 15
                        love.graphics.setColor(r, g, b, waveFront * 0.7)
                        love.graphics.circle("fill", (x1 + x2)/2, (y1 + y2)/2, glowSize * intensityMult)
                    end
                end
                
                -- Reset line width
                love.graphics.setLineWidth(1)
            end
        end
    end
    
    -- Draw source effect with enhanced glow
    local sourceGlowSize = 40 * (1 - effect.progress * 0.6) * intensityMult
    if sourceGlowSize > 0 then
        -- Draw outer glow
        love.graphics.setColor(effect.color[1] * 0.6, effect.color[2] * 0.6, effect.color[3] * 0.6, 
                             0.4 * (1 - effect.progress * 0.5) * intensityMult)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, sourceGlowSize * 1.5)
        
        -- Draw inner brighter glow
        love.graphics.setColor(effect.color[1] * 1.2, effect.color[2] * 1.2, effect.color[3] * 1.2, 
                              0.7 * (1 - effect.progress * 0.5) * intensityMult)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, sourceGlowSize * 0.7)
        
        -- Draw bright core (pulsing)
        local pulseEffect = 1.0 + 0.2 * math.sin(effect.timer * 12)
        love.graphics.setColor(1, 1, 1, 0.8 * (1 - effect.progress * 0.7) * pulseEffect)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, sourceGlowSize * 0.3 * pulseEffect)
    end
    
    -- Draw particles (draw regular particles first, then wave particles on top for better layering)
    
    -- First pass: draw regular particles (background fill)
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 and not particle.isWave then
            -- Apply intensity multiplier to particle alpha and scale for range-based effects
            local adjustedAlpha = particle.alpha * (particle.intensityMultiplier or intensityMult)
            local adjustedScale = particle.scale * (particle.intensityMultiplier or intensityMult)
            
            -- Regular particles
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], adjustedAlpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                adjustedScale, adjustedScale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Second pass: draw wave particles (they should appear on top)
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 and particle.isWave then
            -- Apply intensity multiplier to particle alpha and scale for range-based effects
            local adjustedAlpha = particle.alpha * (particle.intensityMultiplier or intensityMult)
            local adjustedScale = particle.scale * (particle.intensityMultiplier or intensityMult)
            
            -- Draw trail if enabled for this particle
            if particle.drawTrail and particle.trailLength and particle.trailWidth then
                -- Calculate trail endpoints
                local trailAngle = math.atan2(effect.sourceY - particle.y, effect.sourceX - particle.x)
                local trailEndX = particle.x + math.cos(trailAngle) * particle.trailLength
                local trailEndY = particle.y + math.sin(trailAngle) * particle.trailLength
                
                -- Draw gradient trail with higher brightness at particle position
                love.graphics.setLineWidth(particle.trailWidth)
                
                -- Use polygon to draw trail with gradient
                local perpX = -math.sin(trailAngle) * (particle.trailWidth * 0.5)
                local perpY = math.cos(trailAngle) * (particle.trailWidth * 0.5)
                
                -- Calculate trail vertices
                local x1 = particle.x + perpX
                local y1 = particle.y + perpY
                local x2 = particle.x - perpX
                local y2 = particle.y - perpY
                local x3 = trailEndX - perpX * 0.5 -- narrow at the end
                local y3 = trailEndY - perpY * 0.5
                local x4 = trailEndX + perpX * 0.5
                local y4 = trailEndY + perpY * 0.5
                
                -- Draw trail with gradient alpha
                love.graphics.setColor(effect.color[1] * 1.5, effect.color[2] * 1.5, effect.color[3] * 1.5, adjustedAlpha * 0.7)
                love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
            end
            
            -- Choose image based on whether it's a leading edge particle
            local imgToDraw = particleImage
            if particle.isLeadingEdge and particle.glowIntensity and particle.glowIntensity > 0.1 then
                imgToDraw = glowImage -- Use glow image for leading edge particles
                -- Draw halo effect for leading wave particles
                love.graphics.setColor(effect.color[1] * 1.7, effect.color[2] * 1.7, effect.color[3] * 1.7, 
                                     adjustedAlpha * 0.8 * particle.glowIntensity)
                love.graphics.circle("fill", particle.x, particle.y, adjustedScale * 15 * particle.glowIntensity)
            end
            
            -- Draw the main particle
            love.graphics.setColor(effect.color[1] * 1.5, effect.color[2] * 1.5, effect.color[3] * 1.5, adjustedAlpha * 1.3)
            love.graphics.draw(
                imgToDraw,
                particle.x, particle.y,
                particle.rotation,
                adjustedScale * 1.7, adjustedScale * 1.7, -- Even bigger wave particles
                imgToDraw:getWidth()/2, imgToDraw:getHeight()/2
            )
            
            -- Add extra bright core for wave particles
            if math.random() < 0.3 then
                love.graphics.setColor(1, 1, 1, adjustedAlpha * 0.8)
                love.graphics.circle("fill", particle.x, particle.y, adjustedScale * 3.5 * math.random())
            end
            
            -- Add burst effect for leading edge particles
            if particle.isLeadingEdge and particle.glowIntensity and particle.glowIntensity > 0.5 and math.random() < 0.4 then
                -- Occasional bursts of energy at leading edge
                local burstSize = adjustedScale * 8 * particle.glowIntensity * math.random()
                love.graphics.setColor(1, 1, 1, adjustedAlpha * 0.9)
                love.graphics.circle("fill", 
                    particle.x + math.random(-3, 3), 
                    particle.y + math.random(-3, 3),
                    burstSize)
            end
        end
    end
    
    -- Draw subtle cone outline at the beginning of the effect
    if effect.progress < 0.3 then
        -- Calculate cone properties
        local coneAngleRad = (effect.coneAngle or 60) * math.pi / 180
        local coneLength = (effect.coneLength or 160) * (1 - effect.progress)
        
        -- Calculate the base direction from source to target
        local dirX = effect.targetX - effect.sourceX
        local dirY = effect.targetY - effect.sourceY
        local baseAngle = math.atan2(dirY, dirX)
        
        -- Calculate cone edges
        local leftAngle = baseAngle - coneAngleRad/2
        local rightAngle = baseAngle + coneAngleRad/2
        
        local leftX = effect.sourceX + math.cos(leftAngle) * coneLength
        local leftY = effect.sourceY + math.sin(leftAngle) * coneLength
        local rightX = effect.sourceX + math.cos(rightAngle) * coneLength
        local rightY = effect.sourceY + math.sin(rightAngle) * coneLength
        
        -- Draw cone outline
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 
                              0.2 * (1 - effect.progress/0.3) * intensityMult)
        love.graphics.line(effect.sourceX, effect.sourceY, leftX, leftY)
        love.graphics.line(effect.sourceX, effect.sourceY, rightX, rightY)
        
        -- Draw arc connecting the edges
        local numPoints = 10
        love.graphics.setLineWidth(1)
        for j = 1, numPoints - 1 do
            local angle1 = leftAngle + (j-1) * (rightAngle - leftAngle) / (numPoints-1)
            local angle2 = leftAngle + j * (rightAngle - leftAngle) / (numPoints-1)
            
            local x1 = effect.sourceX + math.cos(angle1) * coneLength
            local y1 = effect.sourceY + math.sin(angle1) * coneLength
            local x2 = effect.sourceX + math.cos(angle2) * coneLength
            local y2 = effect.sourceY + math.sin(angle2) * coneLength
            
            love.graphics.line(x1, y1, x2, y2)
        end
    end
end

-- Draw function for remote effect
function VFX.drawRemote(effect)
    local particleImage = getAssetInternal("sparkle")
    local glowImage = getAssetInternal("fireGlow")
    local impactImage = getAssetInternal("impactRing")
    
    -- Get warp frames if needed
    local warpFrames = nil
    if effect.useSprites then
        warpFrames = getAssetInternal("warpFrames")
    end
    
    -- Center position is at the current target position
    -- This will automatically reflect any position updates from updateRemote
    local centerX = effect.targetX
    local centerY = effect.targetY
    
    -- Draw base glow at the center
    local glowAlpha = 0.5 * (1 - 0.5 * math.abs(effect.progress * 2 - 1)) -- Peak at the middle
    local glowIntensity = effect.glowIntensity or 0.7
    glowAlpha = glowAlpha * glowIntensity
    
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], glowAlpha)
    local glowScale = 0.5 + effect.progress * 0.5 -- Grow slightly over time
    
    -- Add pulsing if enabled
    if effect.usePulse then
        local pulseAmount = effect.pulseAmount or 0.2
        local pulseRate = effect.pulseRate or 6.0
        glowScale = glowScale * (1 + math.sin(effect.timer * pulseRate) * pulseAmount)
    end
    
    -- Draw the glow
    love.graphics.draw(
        glowImage,
        centerX, centerY,
        0,
        glowScale * 4, glowScale * 4, -- Larger glow
        glowImage:getWidth()/2, glowImage:getHeight()/2
    )
    
    -- Draw expanding circle
    local ringProgress = math.min(effect.progress * 1.2, 1.0)
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.3 * (1 - ringProgress))
    local ringScale = (effect.radius or 60) * 0.02 * ringProgress
    love.graphics.draw(
        impactImage,
        centerX, centerY,
        0,
        ringScale, ringScale,
        impactImage:getWidth()/2, impactImage:getHeight()/2
    )
    
    -- Draw sprite animation if enabled
    if effect.useSprites and warpFrames and #warpFrames > 0 then
        -- Calculate which frame to use based on animation time
        local frameRate = effect.spriteFrameRate or 10
        local totalFrames = #warpFrames
        local frameIndex = math.floor((effect.timer * frameRate) % totalFrames) + 1
        local currentFrame = warpFrames[frameIndex]
        
        if currentFrame then
            -- Calculate scale with pulsing effect if enabled
            local spriteScale = effect.spriteScale or 1.0
            
            -- Apply pulse if enabled
            if effect.usePulse then
                local pulseAmount = effect.pulseAmount or 0.2
                local pulseRate = effect.pulseRate or 6.0
                spriteScale = spriteScale * (1 + math.sin(effect.timer * pulseRate) * pulseAmount)
            end
            
            -- Calculate opacity curve (fade in, stay visible, fade out)
            local alpha = 1.0
            if effect.progress < 0.2 then
                -- Fade in during the first 20%
                alpha = effect.progress / 0.2
            elseif effect.progress > 0.8 then
                -- Fade out during the last 20%
                alpha = (1.0 - effect.progress) / 0.2
            end
            
            -- Set color with tinting if enabled
            if effect.spriteTint then
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
            else
                -- Pure white with alpha
                love.graphics.setColor(1, 1, 1, alpha)
            end
            
            -- Calculate rotation angle if needed
            local rotation = 0
            if effect.rotateSprite then
                rotation = effect.spriteAngle or 0
            end
            
            -- Draw the sprite at the center
            love.graphics.draw(
                currentFrame,
                centerX, centerY,
                rotation,
                spriteScale, spriteScale,
                currentFrame:getWidth()/2, currentFrame:getHeight()/2
            )
        end
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
end

function VFX.drawMeteor(effect)
    love.graphics.setBlendMode("add")
    
    -- Draw all active particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0.01 then
            -- Get the appropriate asset
            local asset = VFX.getAsset(particle.assetId or "fireParticle")
            
            if asset then
                -- Save current color
                local r, g, b, a = love.graphics.getColor()
                
                -- Set particle color based on effect color and alpha
                love.graphics.setColor(
                    effect.color[1], 
                    effect.color[2], 
                    effect.color[3], 
                    effect.color[4] * particle.alpha
                )
                
                -- Draw the particle
                love.graphics.draw(
                    asset,
                    particle.x,
                    particle.y,
                    particle.rotation,
                    particle.scale,
                    particle.scale,
                    asset:getWidth() / 2,
                    asset:getHeight() / 2
                )
                
                -- Draw fiery glow for meteors
                if not particle.explosion and not particle.hasImpacted then
                    local glowAsset = VFX.getAsset("fireGlow")
                    if glowAsset then
                        -- Set a more transparent glow color
                        love.graphics.setColor(
                            effect.color[1], 
                            effect.color[2], 
                            effect.color[3], 
                            effect.color[4] * particle.alpha * 0.7
                        )
                        
                        -- Draw glow slightly larger than the particle
                        local glowScale = particle.scale * 1.8
                        love.graphics.draw(
                            glowAsset,
                            particle.x,
                            particle.y,
                            particle.rotation,
                            glowScale,
                            glowScale,
                            glowAsset:getWidth() / 2,
                            glowAsset:getHeight() / 2
                        )
                    end
                end
                
                -- Restore original color
                love.graphics.setColor(r, g, b, a)
            end
        end
    end
    
    -- Reset blend mode
    love.graphics.setBlendMode("alpha")
end

return VFX