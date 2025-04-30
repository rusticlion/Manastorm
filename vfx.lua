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
    
    -- Effect definitions keyed by effect name
    VFX.effects = {
        -- Base templates for the rules-driven VFX system
        proj_base = {
            type = "projectile",
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
        
        beam_base = {
            type = "beam",
            duration = 1.2,
            particleCount = 25,
            beamWidth = 30,
            startScale = 0.3,
            endScale = 0.9,
            color = Constants.Color.SMOKE,  -- Default color, will be overridden
            pulseRate = 3,
            sound = nil
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
        
        -- Tidal Force Ground effect - for forcing opponents down from AERIAL to GROUNDED
        tidal_force_ground = {
            type = "impact",
            duration = 0.8,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = Constants.Color.OCEAN,  -- Blue-ish for water/tidal theme
            radius = 80,
            sound = "tidal_wave"
        },
        
        -- Gravity Pin Ground effect - for forcing opponents down from AERIAL to GROUNDED
        gravity_pin_ground = {
            type = "impact",
            duration = 0.8,
            particleCount = 20,
            startScale = 0.6,
            endScale = 1.0,
            color = Constants.Color.MAROON,  -- Purple for gravity theme -> MAROON
            radius = 70,
            sound = "gravity_slam"
        },
        
        -- Gravity Trap Set effect - when placing a gravity trap
        gravity_trap_set = {
            type = "impact",
            duration = 1.2,
            particleCount = 30,
            startScale = 0.4,
            endScale = 1.2,
            color = Constants.Color.MAROON,  -- Purple for gravity theme
            radius = 75,
            sound = "gravity_trap_deploy"  -- Sound will need to be loaded
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
            color = Constants.Color.SKY,  -- Bright blue for freeing mana -> SKY
            radius = 100,
            pulseRate = 4,
            sound = "release"
        },

        -- Firebolt effect - showcasing the improved projectile system
        firebolt = {
            type = "projectile",
            duration = 0.75,               -- Reduced from 1.0 for faster projectile
            particleCount = 40,            -- Good particle count for rich visuals
            startScale = 0.5,
            endScale = 1.0,
            color = Constants.Color.ORANGE, -- {1, 0.5, 0.2, 1}
            trailLength = 12,               -- Trail points for calculation
            impactSize = 1.4,
            sound = "firebolt",
            coreDensity = 0.75,             -- More particles at the leading edge
            trailDensity = 0.5,             -- Fewer trail particles
            turbulence = 0.8,               -- Higher turbulence for fire feeling
            arcHeight = 15,                 -- Much shallower arc (more direct flight)
            particleLifespan = 0.5,         -- Shorter individual particle life
            leadingIntensity = 1.8,         -- Brighter leading edge for fire
            motion = Constants.MotionStyle.RISE  -- Use rising motion for fire
        },
        
        -- Meteor effect
        meteor = {
            type = "impact",
            duration = 1.5,
            particleCount = 40,
            startScale = 2.0,
            endScale = 0.5,
            color = Constants.Color.OCHRE, -- {1, 0.4, 0.1, 1}
            radius = 120,
            sound = "meteor"
        },
        
        -- Mist Veil effect
        mistveil = {
            type = "aura",
            duration = 3.0,
            particleCount = 30,
            startScale = 0.2,
            endScale = 0.8,
            color = Constants.Color.SKY, -- {0.7, 0.7, 1.0, 0.7}
            radius = 80,
            pulseRate = 2,
            sound = "mist",
            criticalAssets = {"sparkle", "runes"} -- Define assets critical for this effect
        },
        
        -- Emberlift effect
        emberlift = {
            type = "vertical",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.1,
            color = Constants.Color.ORANGE, -- {1, 0.6, 0.2, 0.8}
            height = 100,
            sound = "whoosh"
        },
        
        -- Force Blast Up effect (for forcing opponents up to AERIAL)
        force_blast_up = {
            type = "vertical",
            duration = 1.5,
            particleCount = 35,
            startScale = 0.4,
            endScale = 0.2,
            color = Constants.Color.YELLOW,  -- Blue-ish for force -> YELLOW
            height = 120,
            sound = "force_wind"
        },
        
        -- Full Moon Beam effect
        fullmoonbeam = {
            type = "beam",
            duration = 1.8,
            particleCount = 30,
            beamWidth = 40,
            startScale = 0.2,
            endScale = 1.0,
            color = Constants.Color.PINK,
            pulseRate = 3,
            sound = "moonbeam"
        },
        
        -- Tidal Force effect
        tidal_force = {
            type = "projectile",
            duration = 1.2,
            particleCount = 30,
            startScale = 0.4,
            endScale = 0.8,
            color = Constants.Color.OCEAN, -- {0.3, 0.5, 1.0, 0.8} -> Blue-ish for water theme
            trailLength = 15,
            impactSize = 1.6,
            sound = "tidal_wave"
        },
        
        -- Lunar Disjunction effect
        lunardisjunction = {
            type = "projectile",
            duration = 1.0,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.6,
            color = Constants.Color.PINK, -- {0.8, 0.6, 1.0, 0.9} -> Purple-blue for moon/cosmic theme -> PINK
            trailLength = 10,
            impactSize = 1.8,  -- Bigger impact
            sound = "lunar_disrupt"
        },
        
        -- Disjoint effect (for cancelling opponent's spell)
        disjoint_cancel = {
            type = "impact",
            duration = 1.2,
            particleCount = 35,
            startScale = 0.6,
            endScale = 1.0,
            color = Constants.Color.PINK, -- {0.9, 0.5, 1.0, 0.9} -> Brighter purple for disruption -> PINK
            radius = 70,
            sound = "lunar_disrupt"
        },
        
        -- Conjure Fire effect
        conjurefire = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = Constants.Color.ORANGE, -- {1.0, 0.5, 0.2, 0.9}
            height = 140,  -- Height to rise toward mana pool
            spreadRadius = 40, -- Initial spread around the caster
            sound = "conjure"
        },
        
        -- Conjure Moonlight effect
        conjuremoonlight = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = Constants.Color.SKY, -- {0.7, 0.7, 1.0, 0.9}
            height = 140,
            spreadRadius = 40,
            sound = "conjure"
        },
        
        -- Conjure Force effect
        force_conjure = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = Constants.Color.YELLOW, -- {0.3, 0.5, 1.0, 0.9} -> Blue-ish -> YELLOW
            height = 140,
            spreadRadius = 40,
            sound = "conjure"
        },

        -- Conjure Star effect
        star_conjure = {
            type = "conjure",
            duration = 1.5,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.8,
            color = Constants.Color.BONE, -- {0.9, 0.9, 0.2, 0.9} -> Yellow-ish -> BONE
            height = 140,
            spreadRadius = 40,
            sound = "conjure"
        },
        
        -- Volatile Conjuring effect (random mana)
        volatileconjuring = {
            type = "conjure",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.2,
            endScale = 0.6,
            color = Constants.Color.YELLOW,  -- Yellow base color, will be randomized
            height = 140,
            spreadRadius = 55,  -- Wider spread for volatile
            sound = "conjure"
        },
        
        -- Nova Conjuring effect (Fire, Force, Star)
        nova_conjure = {
            type = "conjure",
            duration = 2.0, -- Slightly longer duration
            particleCount = 30, -- More particles
            startScale = 0.4,
            endScale = 1.0,
            color = Constants.Color.ORANGE, -- Mixed color base (orange/gold) -> ORANGE
            height = 140,
            spreadRadius = 60, -- Wider spread
            sound = "conjure_nova" -- Assumed sound effect
        },

        -- Witch Conjuring effect (Moon, Force, Nature)
        witch_conjure = {
            type = "conjure",
            duration = 2.0, -- Slightly longer duration
            particleCount = 30, -- More particles
            startScale = 0.4,
            endScale = 1.0,
            color = Constants.Color.MAROON, -- Mixed color base (purple/indigo) -> MAROON
            height = 140,
            spreadRadius = 60, -- Wider spread
            sound = "conjure_witch" -- Assumed sound effect
        },
        
        -- Shield effect (used for barrier, ward, and field shield activation)
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
        
        -- Gravity Trap Set effect is already defined above,

        -- Additional effects for VFXType constants
        
        -- Movement and positioning effects
        elevation_up = {
            type = "vertical",
            duration = 1.0,
            particleCount = 20,
            startScale = 0.3,
            endScale = 0.1,
            color = Constants.Color.SKY,
            height = 80,
            sound = "whoosh"
        },
        
        elevation_down = {
            type = "impact",
            duration = 0.8,
            particleCount = 20,
            startScale = 0.6,
            endScale = 1.0,
            color = Constants.Color.SMOKE,
            radius = 60,
            sound = "thud"
        },
        
        range_change = {
            type = "impact",
            duration = 0.8,
            particleCount = 15,
            startScale = 0.4,
            endScale = 0.8,
            color = Constants.Color.YELLOW,
            radius = 40,
            sound = nil
        },
        
        force_position = {
            type = "impact",
            duration = 0.8,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = Constants.Color.OCEAN,
            radius = 50,
            sound = "force_wind"
        },
        
        -- Resource effects
        token_lock = {
            type = "aura",
            duration = 0.8,
            particleCount = 15,
            startScale = 0.2,
            endScale = 0.5,
            color = Constants.Color.MAROON,
            radius = 20,
            pulseRate = 4,
            sound = "lock"
        },
        
        token_shift = {
            type = "aura",
            duration = 0.6,
            particleCount = 12,
            startScale = 0.2,
            endScale = 0.4,
            color = Constants.Color.PINK,
            radius = 20,
            pulseRate = 5,
            sound = "shift"
        },
        
        token_consume = {
            type = "impact",
            duration = 0.7,
            particleCount = 18,
            startScale = 0.4,
            endScale = 0.1,
            color = Constants.Color.CRIMSON,
            radius = 25,
            sound = "consume"
        },
        
        -- Defense effects
        reflect = {
            type = "aura",
            duration = 1.2,
            particleCount = 20,
            startScale = 0.4,
            endScale = 0.8,
            color = Constants.Color.YELLOW,
            radius = 50,
            pulseRate = 4,
            sound = "reflect"
        },
        
        -- Spell timing effects
        spell_accelerate = {
            type = "aura",
            duration = 0.8,
            particleCount = 15,
            startScale = 0.2,
            endScale = 0.5,
            color = Constants.Color.LIME,
            radius = 30,
            pulseRate = 5,
            sound = "accelerate"
        },
        
        spell_cancel = {
            type = "impact",
            duration = 0.7,
            particleCount = 20,
            startScale = 0.5,
            endScale = 0.2,
            color = Constants.Color.CRIMSON,
            radius = 40,
            sound = "cancel"
        },
        
        spell_freeze = {
            type = "aura",
            duration = 1.0,
            particleCount = 18,
            startScale = 0.3,
            endScale = 0.6,
            color = Constants.Color.OCEAN,
            radius = 35,
            pulseRate = 3,
            sound = "freeze"
        },
        
        spell_echo = {
            type = "aura",
            duration = 1.0,
            particleCount = 15,
            startScale = 0.3,
            endScale = 0.7,
            color = Constants.Color.BONE,
            radius = 40,
            pulseRate = 4,
            sound = "echo"
        }
    }
    
    -- Initialize sound effects
    VFX.sounds = {
        firebolt = nil, -- Sound files will be loaded when available
        meteor = nil,
        mist = nil,
        whoosh = nil,
        moonbeam = nil,
        conjure = nil,
        shield = nil
    }
    
    -- Preload sound effects when they become available
    -- Example of how to load sounds with AssetCache:
    -- VFX.sounds.firebolt = AssetCache.getSound("assets/sounds/firebolt.wav")
    
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
    
    -- Reset particles array but don't delete it
    effect.particles = {}
    
    return effect
end

-- Create a new effect instance
function VFX.createEffect(effectName, sourceX, sourceY, targetX, targetY, options)
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
        if effectNameStr:lower():find("ward") or effectNameStr:lower() == "mistveil" then
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
    
    -- Optional overrides
    effect.options = options or {}
    
    -- Initialize particles based on effect type
    VFX.initializeParticles(effect)
    
    -- Play sound effect if available
    if effect.sound and VFX.sounds[effect.sound] then
        -- Will play sound when implemented
    end
    
    -- Add to active effects list
    table.insert(VFX.activeEffects, effect)
    
    return effect
end

-- Initialize particles based on effect type
function VFX.initializeParticles(effect)
    -- Different initialization based on effect type
    if effect.type == "projectile" then
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
            local particle = Pool.acquire("vfx_particle")
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
            local particle = Pool.acquire("vfx_particle")
            
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
    end
end

-- Update all active effects
function VFX.update(dt)
    local i = 1
    while i <= #VFX.activeEffects do
        local effect = VFX.activeEffects[i]
        
        -- Update effect timer
        effect.timer = effect.timer + dt
        effect.progress = math.min(effect.timer / effect.duration, 1.0)
        
        -- Update effect based on type
        if effect.type == "projectile" then
            VFX.updateProjectile(effect, dt)
        elseif effect.type == "impact" then
            VFX.updateImpact(effect, dt)
        elseif effect.type == "aura" then
            VFX.updateAura(effect, dt)
        elseif effect.type == "vertical" then
            VFX.updateVertical(effect, dt)
        elseif effect.type == "beam" then
            VFX.updateBeam(effect, dt)
        elseif effect.type == "conjure" then
            VFX.updateConjure(effect, dt)
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
    local baseProgress = effect.progress
    
    -- Calculate base projectile position
    local posX = effect.sourceX + (effect.targetX - effect.sourceX) * baseProgress
    local posY = effect.sourceY + (effect.targetY - effect.sourceY) * baseProgress
    
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
    local arcProgress = baseProgress * (1 - baseProgress) * 4 -- Quadratic ease in/out curve peaking at 0.5
    local verticalOffset = -arcHeight * rangeBandModifier * arcModifier * arcProgress
    
    -- Apply final position
    posY = posY + verticalOffset + elevationOffset * baseProgress
    
    -- Check for special shield block point
    local blockPoint = effect.options and effect.options.blockPoint
    local isBlocked = blockPoint and baseProgress >= blockPoint
    
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
            if effect.options.shieldType == "ward" then
                shieldColor = {0.3, 0.3, 1.0, 0.7}  -- Blue for wards
            elseif effect.options.shieldType == "field" then
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
            
            VFX.createEffect("shield_hit_base", blockX, blockY, nil, nil, shieldHitOpts)
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
    
    -- Update particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
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
                            
                            -- Fast movement toward block point
                            local moveSpeed = 30 -- Faster movement during block
                            particle.x = particle.x + (targetX - particle.x) * moveSpeed * dt
                            particle.y = particle.y + (targetY - particle.y) * moveSpeed * dt
                        else
                            -- Deflection phase - particles scatter outward from block point
                            -- Calculate deflection angle (away from target, with randomness)
                            local baseAngle = math.atan2(effect.sourceY - effect.targetY, effect.sourceX - effect.targetX)
                            local deflectAngle = baseAngle + (math.random() - 0.5) * math.pi * 0.8
                            
                            -- Calculate outward deflection distance
                            local deflectDistance = 150 * (blockProgress - 0.2) * math.random(0.7, 1.3)
                            local targetX = blockX + math.cos(deflectAngle) * deflectDistance
                            local targetY = blockY + math.sin(deflectAngle) * deflectDistance
                            
                            -- More gradual movement for scatter
                            local moveSpeed = 10
                            particle.x = particle.x + (targetX - particle.x) * moveSpeed * dt
                            particle.y = particle.y + (targetY - particle.y) * moveSpeed * dt
                            
                            -- Fade out as particles scatter
                            particle.alpha = math.max(0, 1.0 - (blockProgress - 0.2)/0.8)
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
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
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
    -- Update beam progress
    effect.beamProgress = math.min(effect.progress * 2, 1.0) -- Beam reaches full extension halfway through
    
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

-- Draw all active effects
function VFX.draw()
    for _, effect in ipairs(VFX.activeEffects) do
        if effect.type == "projectile" then
            VFX.drawProjectile(effect)
        elseif effect.type == "impact" then
            VFX.drawImpact(effect)
        elseif effect.type == "aura" then
            VFX.drawAura(effect)
        elseif effect.type == "vertical" then
            VFX.drawVertical(effect)
        elseif effect.type == "beam" then
            VFX.drawBeam(effect)
        elseif effect.type == "conjure" then
            VFX.drawConjure(effect)
        end
    end
end

-- Draw function for projectile effects
function VFX.drawProjectile(effect)
    local particleImage = getAssetInternal("fireParticle")
    local glowImage = getAssetInternal("fireGlow")
    local impactImage = getAssetInternal("impactRing")
    
    -- Calculate trail points but don't draw central line anymore
    -- We'll keep the trail points for particle positioning
    
    -- Draw head glow with motion blur effect
    if #effect.trailPoints > 0 then
        local head = effect.trailPoints[1]
        local leadingIntensity = effect.leadingIntensity or 1.5
        
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
            
            love.graphics.setColor(r, g, b, particle.alpha * 0.8)
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

-- Helper function to create the appropriate effect for a spell
function VFX.createSpellEffect(spell, caster, target)
    local Constants = require("core.Constants")
    
    -- Get mana pool position for conjuration spells
    local manaPoolX = caster.manaPool and caster.manaPool.x or 400
    local manaPoolY = caster.manaPool and caster.manaPool.y or 120
    
    -- Determine source and target positions
    local sourceX, sourceY = caster.x, caster.y
    print("[VFX] sourceX: " .. sourceX .. " sourceY: " .. sourceY)
    local targetX, targetY = target.x, target.y
    print("[VFX] targetX: " .. targetX .. " targetY: " .. targetY)
    -- Handle different spell types
    local spellName = spell.name:lower():gsub("%s+", "") -- Convert to lowercase and remove spaces
    
    -- Handle conjuration spells first
    if spellName == "conjurefire" then
        return VFX.createEffect(Constants.VFXType.CONJUREFIRE, sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "conjuremoonlight" then
        return VFX.createEffect(Constants.VFXType.CONJUREMOONLIGHT, sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "conjureforce" then
        return VFX.createEffect(Constants.VFXType.FORCE_CONJURE, sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "conjurestars" then
        return VFX.createEffect(Constants.VFXType.STAR_CONJURE, sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "volatileconjuring" then
        return VFX.createEffect(Constants.VFXType.VOLATILECONJURING, sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "novaconjuring" then
        return VFX.createEffect(Constants.VFXType.NOVA_CONJURE, sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "witchconjuring" then
        return VFX.createEffect(Constants.VFXType.WITCH_CONJURE, sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    
    -- Special handling for other specific spells
    elseif spellName == "firebolt" then
        return VFX.createEffect(Constants.VFXType.FIREBOLT, sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "meteor" then
        return VFX.createEffect(Constants.VFXType.METEOR, targetX, targetY - 100, targetX, targetY)
    elseif spellName == "mistveil" then
        return VFX.createEffect(Constants.VFXType.MISTVEIL, sourceX, sourceY, nil, nil)
    elseif spellName == "emberlift" then
        return VFX.createEffect(Constants.VFXType.EMBERLIFT, sourceX, sourceY, nil, nil)
    elseif spellName == "fullmoonbeam" then
        return VFX.createEffect(Constants.VFXType.FULLMOONBEAM, sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "tidalforce" then
        return VFX.createEffect(Constants.VFXType.TIDAL_FORCE, sourceX, sourceY - 15, targetX, targetY - 15)
    elseif spellName == "lunardisjunction" then
        return VFX.createEffect(Constants.VFXType.LUNARDISJUNCTION, sourceX, sourceY - 15, targetX, targetY - 15)
    elseif spellName == "forceblast" then
        return VFX.createEffect(Constants.VFXType.FORCE_BLAST, sourceX, sourceY - 15, targetX, targetY - 15)
    else
        -- Create a generic effect based on spell type or mana cost
        if spell.spellType == "projectile" then
            return VFX.createEffect(Constants.VFXType.FIREBOLT, sourceX, sourceY, targetX, targetY)
        else
            -- Look at spell cost to determine effect type
            local hasFireMana = false
            local hasMoonMana = false
            
            for _, cost in ipairs(spell.cost or {}) do
                if cost.type == "fire" then hasFireMana = true end
                if cost.type == "moon" then hasMoonMana = true end
            end
            
            if hasFireMana then
                return VFX.createEffect(Constants.VFXType.FIREBOLT, sourceX, sourceY, targetX, targetY)
            elseif hasMoonMana then
                return VFX.createEffect(Constants.VFXType.MISTVEIL, sourceX, sourceY, nil, nil)
            else
                -- Default generic effect if no specific match
                print("Warning: No specific VFX defined for spell: " .. spell.name .. ". Using generic impact.")
                return VFX.createEffect(Constants.VFXType.IMPACT, targetX, targetY, nil, nil) -- Default to a simple impact at target
            end
        end
    end
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

return VFX