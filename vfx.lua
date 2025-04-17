-- VFX.lua
-- Visual effects module for spell animations and combat effects

local VFX = {}
VFX.__index = VFX

-- Table to store active effects
VFX.activeEffects = {}

-- Initialize the VFX system
function VFX.init()
    -- Load any necessary assets for effects
    VFX.assets = {
        -- Fire effects
        fireParticle = love.graphics.newImage("assets/sprites/fire-particle.png"),
        fireGlow = love.graphics.newImage("assets/sprites/fire-glow.png"),
        
        -- Force effects
        forceWave = love.graphics.newImage("assets/sprites/force-wave.png"),
        
        -- Moon effects
        moonGlow = love.graphics.newImage("assets/sprites/moon-glow.png"),
        
        -- Generic effects
        sparkle = love.graphics.newImage("assets/sprites/sparkle.png"),
        impactRing = love.graphics.newImage("assets/sprites/impact-ring.png"),
    }
    
    -- Effect definitions keyed by effect name
    VFX.effects = {
        -- General impact effect (used for many spell interactions)
        impact = {
            type = "impact",
            duration = 0.5,  -- Half second by default
            particleCount = 15,
            startScale = 0.8,
            endScale = 0.2,
            color = {1, 1, 1, 0.8},  -- Default white, will be overridden by options
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
            color = {0.4, 0.6, 1.0, 0.9},  -- Blue-ish for water/tidal theme
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
            color = {0.7, 0.3, 0.9, 0.9},  -- Purple for gravity theme
            radius = 70,
            sound = "gravity_slam"
        },
        
        force_blast = {
            type = "impact",
            duration = 1.0,
            particleCount = 30,
            startScale = 0.4,
            endScale = 1.5,
            color = {0.4, 0.7, 1.0, 0.8},  -- Blue-ish for force theme
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
            color = {0.2, 0.6, 0.9, 0.9},  -- Bright blue for freeing mana
            radius = 100,
            pulseRate = 4,
            sound = "release"
        },

        -- Firebolt effect
        firebolt = {
            type = "projectile",
            duration = 1.0,  -- 1 second total duration
            particleCount = 20,
            startScale = 0.5,
            endScale = 1.0,
            color = {1, 0.5, 0.2, 1},
            trailLength = 12,
            impactSize = 1.4,
            sound = "firebolt"
        },
        
        -- Meteor effect
        meteor = {
            type = "impact",
            duration = 1.5,
            particleCount = 40,
            startScale = 2.0,
            endScale = 0.5,
            color = {1, 0.4, 0.1, 1},
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
            color = {0.7, 0.7, 1.0, 0.7},
            radius = 80,
            pulseRate = 2,
            sound = "mist"
        },
        
        -- Emberlift effect
        emberlift = {
            type = "vertical",
            duration = 1.2,
            particleCount = 25,
            startScale = 0.3,
            endScale = 0.1,
            color = {1, 0.6, 0.2, 0.8},
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
            color = {0.3, 0.5, 1.0, 0.8},  -- Blue-ish for force
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
            color = {0.8, 0.8, 1.0, 0.9},
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
            color = {0.3, 0.5, 1.0, 0.8},  -- Blue-ish for water theme
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
            color = {0.8, 0.6, 1.0, 0.9},  -- Purple-blue for moon/cosmic theme
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
            color = {0.9, 0.5, 1.0, 0.9},  -- Brighter purple for disruption
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
            color = {1.0, 0.5, 0.2, 0.9},
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
            color = {0.7, 0.7, 1.0, 0.9},
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
            color = {1.0, 1.0, 0.5, 0.9},  -- Yellow base color, will be randomized
            height = 140,
            spreadRadius = 55,  -- Wider spread for volatile
            sound = "conjure"
        },
        
        -- Shield effect (used for barrier, ward, and field shield activation)
        shield = {
            type = "aura",
            duration = 1.0,
            particleCount = 25,
            startScale = 0.5,
            endScale = 1.2,
            color = {0.8, 0.8, 1.0, 0.8},  -- Default blue-ish, will be overridden by options
            radius = 60,
            pulseRate = 3,
            sound = "shield"
        }
    }
    
    -- Initialize sound effects (placeholders)
    VFX.sounds = {
        firebolt = nil, -- Will load actual sound files when available
        meteor = nil,
        mist = nil,
        whoosh = nil,
        moonbeam = nil,
        conjure = nil,
        shield = nil
    }
    
    return VFX
end

-- Create a new effect instance
function VFX.createEffect(effectName, sourceX, sourceY, targetX, targetY, options)
    -- Get effect template
    local template = VFX.effects[effectName:lower()]
    if not template then
        print("Warning: Effect not found: " .. effectName)
        return nil
    end
    
    -- Create a new effect instance
    local effect = {
        name = effectName,
        type = template.type,
        sourceX = sourceX,
        sourceY = sourceY,
        targetX = targetX or sourceX,
        targetY = targetY or sourceY,
        
        -- Timing
        duration = template.duration,
        timer = 0,
        progress = 0,
        isComplete = false,
        
        -- Visual properties (copied from template)
        particleCount = template.particleCount,
        startScale = template.startScale,
        endScale = template.endScale,
        color = {template.color[1], template.color[2], template.color[3], template.color[4]},
        
        -- Effect specific properties
        particles = {},
        trailPoints = {},
        
        -- Sound
        sound = template.sound,
        
        -- Additional properties based on effect type
        radius = template.radius,
        beamWidth = template.beamWidth,
        height = template.height,
        pulseRate = template.pulseRate,
        trailLength = template.trailLength,
        impactSize = template.impactSize,
        spreadRadius = template.spreadRadius,
        
        -- Optional overrides
        options = options or {}
    }
    
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
        -- For projectiles, create a trail of particles
        for i = 1, effect.particleCount do
            local particle = {
                x = effect.sourceX,
                y = effect.sourceY,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = 0,
                delay = i / effect.particleCount * 0.3, -- Stagger particle start
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "impact" then
        -- For impact effects, create a radial explosion
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(10, effect.radius)
            local speed = math.random(50, 200)
            local particle = {
                x = effect.targetX,
                y = effect.targetY,
                targetX = effect.targetX + math.cos(angle) * distance,
                targetY = effect.targetY + math.sin(angle) * distance,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = angle,
                delay = math.random() * 0.2, -- Slight random delay
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "aura" then
        -- For aura effects, create particles that orbit the character
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local distance = math.random(effect.radius * 0.6, effect.radius)
            local orbitalSpeed = math.random(0.5, 2.0)
            local particle = {
                angle = angle,
                distance = distance,
                orbitalSpeed = orbitalSpeed,
                scale = effect.startScale,
                alpha = 0, -- Start invisible and fade in
                rotation = 0,
                delay = i / effect.particleCount * 0.5,
                active = false
            }
            table.insert(effect.particles, particle)
        end
        
    elseif effect.type == "vertical" then
        -- For vertical effects like emberlift, particles rise upward
        for i = 1, effect.particleCount do
            local offsetX = math.random(-30, 30)
            local startY = math.random(0, 40)
            local speed = math.random(70, 150)
            local particle = {
                x = effect.sourceX + offsetX,
                y = effect.sourceY + startY,
                speed = speed,
                scale = effect.startScale,
                alpha = 1.0,
                rotation = math.random() * math.pi * 2,
                delay = i / effect.particleCount * 0.8,
                active = false
            }
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
            local particle = {
                position = position, -- 0 to 1 along beam
                offset = offset, -- Perpendicular to beam
                scale = effect.startScale * math.random(0.7, 1.3),
                alpha = 0.8,
                rotation = math.random() * math.pi * 2,
                delay = math.random() * 0.3,
                active = false
            }
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
            
            local particle = {
                x = startX,
                y = startY,
                speedX = pathDirX * speed,
                speedY = pathDirY * speed,
                scale = effect.startScale,
                alpha = 0, -- Start transparent and fade in
                rotation = math.random() * math.pi * 2,
                rotSpeed = math.random(-3, 3),
                delay = delay,
                active = false,
                finalPulse = false,
                finalPulseTime = 0
            }
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
            table.remove(VFX.activeEffects, i)
        else
            i = i + 1
        end
    end
end

-- Update function for projectile effects
function VFX.updateProjectile(effect, dt)
    -- Update trail points
    if #effect.trailPoints == 0 then
        -- Initialize trail with source position
        for i = 1, effect.trailLength do
            table.insert(effect.trailPoints, {x = effect.sourceX, y = effect.sourceY})
        end
    end
    
    -- Calculate projectile position based on progress
    local posX = effect.sourceX + (effect.targetX - effect.sourceX) * effect.progress
    local posY = effect.sourceY + (effect.targetY - effect.sourceY) * effect.progress
    
    -- Add curved trajectory based on height
    local midpointProgress = effect.progress - 0.5
    local verticalOffset = -60 * (1 - (midpointProgress * 2)^2)
    posY = posY + verticalOffset
    
    -- Update trail
    table.remove(effect.trailPoints)
    table.insert(effect.trailPoints, 1, {x = posX, y = posY})
    
    -- Update particles
    for i, particle in ipairs(effect.particles) do
        -- Check if particle should be active based on delay
        if effect.timer > particle.delay then
            particle.active = true
        end
        
        if particle.active then
            -- Calculate particle progress
            local particleProgress = math.min((effect.timer - particle.delay) / (effect.duration - particle.delay), 1.0)
            
            -- Distribute particles along the trail
            local trailIndex = math.floor((i / #effect.particles) * #effect.trailPoints) + 1
            if trailIndex > #effect.trailPoints then trailIndex = #effect.trailPoints end
            
            local trailPoint = effect.trailPoints[trailIndex]
            
            -- Add some randomness to particle positions
            local spreadFactor = 8 * (1 - particleProgress)
            particle.x = trailPoint.x + math.random(-spreadFactor, spreadFactor)
            particle.y = trailPoint.y + math.random(-spreadFactor, spreadFactor)
            
            -- Update visual properties
            particle.scale = effect.startScale + (effect.endScale - effect.startScale) * particleProgress
            particle.alpha = math.min(2.0 - particleProgress * 2, 1.0) -- Fade out in last half
            particle.rotation = particle.rotation + dt * 2
        end
    end
    
    -- Create impact effect when reaching the target
    if effect.progress > 0.95 and not effect.impactCreated then
        effect.impactCreated = true
        -- Would create a separate impact effect here in a full implementation
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
            
            -- Move particle outward from center
            local dirX = particle.targetX - effect.targetX
            local dirY = particle.targetY - effect.targetY
            local length = math.sqrt(dirX^2 + dirY^2)
            if length > 0 then
                dirX = dirX / length
                dirY = dirY / length
            end
            
            particle.x = effect.targetX + dirX * length * particleProgress
            particle.y = effect.targetY + dirY * length * particleProgress
            
            -- Update visual properties
            particle.scale = effect.startScale * (1 - particleProgress) + effect.endScale * particleProgress
            particle.alpha = 1.0 - particleProgress^2 -- Quadratic fade out
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
            
            -- Update angle for orbital motion
            particle.angle = particle.angle + dt * particle.orbitalSpeed
            
            -- Calculate position based on orbit
            particle.x = effect.sourceX + math.cos(particle.angle) * particle.distance
            particle.y = effect.sourceY + math.sin(particle.angle) * particle.distance
            
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
    local particleImage = VFX.assets.fireParticle
    local glowImage = VFX.assets.fireGlow
    
    -- Draw trail
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    if #effect.trailPoints >= 3 then
        local points = {}
        for i, point in ipairs(effect.trailPoints) do
            table.insert(points, point.x)
            table.insert(points, point.y)
        end
        love.graphics.setLineWidth(effect.startScale * 10)
        love.graphics.line(points)
        love.graphics.setLineWidth(1)
    end
    
    -- Draw glow at head of projectile
    if #effect.trailPoints > 0 then
        local head = effect.trailPoints[1]
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
        local glowScale = effect.startScale * 3
        love.graphics.draw(
            glowImage,
            head.x, head.y,
            0,
            glowScale, glowScale,
            glowImage:getWidth()/2, glowImage:getHeight()/2
        )
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
            love.graphics.draw(
                particleImage,
                particle.x, particle.y,
                particle.rotation,
                particle.scale, particle.scale,
                particleImage:getWidth()/2, particleImage:getHeight()/2
            )
        end
    end
    
    -- Draw impact flash when projectile reaches target
    if effect.progress > 0.95 then
        local flashIntensity = (1 - (effect.progress - 0.95) * 20) -- Flash quickly fades
        if flashIntensity > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], flashIntensity)
            love.graphics.circle("fill", effect.targetX, effect.targetY, effect.impactSize * 30 * (1 - flashIntensity))
        end
    end
end

-- Draw function for impact effects
function VFX.drawImpact(effect)
    local particleImage = VFX.assets.fireParticle
    local impactImage = VFX.assets.impactRing
    
    -- Draw expanding ring
    local ringProgress = math.min(effect.progress * 1.5, 1.0) -- Ring expands faster than full effect
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - ringProgress) * effect.color[4])
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
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
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
    local particleImage = VFX.assets.sparkle
    
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
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
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
    local particleImage = VFX.assets.fireParticle
    
    -- Draw base effect at source
    local baseProgress = math.min(effect.progress * 3, 1.0) -- Quick initial flash
    if baseProgress < 1.0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], (1.0 - baseProgress) * 0.7)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 40 * baseProgress)
    end
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
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
    local particleImage = VFX.assets.sparkle
    local beamLength = effect.beamLength * effect.beamProgress
    
    -- Draw base beam
    local beamEndX = effect.sourceX + math.cos(effect.beamAngle) * beamLength
    local beamEndY = effect.sourceY + math.sin(effect.beamAngle) * beamLength
    
    -- Calculate beam width with pulse
    local pulseAmount = math.sin(effect.timer * effect.pulseRate) * 0.3
    local beamWidth = effect.beamWidth * (1 + pulseAmount) * (1 - (effect.progress > 0.5 and (effect.progress - 0.5) * 2 or 0))
    
    -- Draw outer beam glow
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.3)
    love.graphics.setLineWidth(beamWidth * 1.5)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw inner beam core
    love.graphics.setColor(effect.color[1] * 1.3, effect.color[2] * 1.3, effect.color[3] * 1.3, effect.color[4] * 0.7)
    love.graphics.setLineWidth(beamWidth * 0.7)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Draw brightest beam center
    love.graphics.setColor(1, 1, 1, effect.color[4] * 0.9)
    love.graphics.setLineWidth(beamWidth * 0.3)
    love.graphics.line(effect.sourceX, effect.sourceY, beamEndX, beamEndY)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Draw particles
    for _, particle in ipairs(effect.particles) do
        if particle.active and particle.alpha > 0 then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * particle.alpha)
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
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.7)
    love.graphics.circle("fill", effect.sourceX, effect.sourceY, 20 * (1 + pulseAmount))
    
    -- Draw impact glow at target if beam is fully extended
    if effect.beamProgress >= 0.99 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.8 * (1 - (effect.progress - 0.5) * 2))
        love.graphics.circle("fill", beamEndX, beamEndY, 25 * (1 + pulseAmount))
    end
end

-- Draw function for conjure effects
function VFX.drawConjure(effect)
    local particleImage = VFX.assets.sparkle
    local glowImage = VFX.assets.fireGlow  -- We'll use this for all conjure types
    
    -- Draw source glow if active
    if effect.sourceGlow and effect.sourceGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.sourceGlow * 0.6)
        love.graphics.circle("fill", effect.sourceX, effect.sourceY, 50 * effect.sourceGlow)
        
        -- Draw expanding rings from source (hint at conjuration happening)
        local ringCount = 3
        for i = 1, ringCount do
            local ringProgress = ((effect.timer * 1.5) % 1.0) + (i-1) / ringCount
            if ringProgress < 1.0 then
                local ringSize = 60 * ringProgress
                local ringAlpha = 0.5 * (1.0 - ringProgress) * effect.sourceGlow
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], ringAlpha)
                love.graphics.circle("line", effect.sourceX, effect.sourceY, ringSize)
            end
        end
    end
    
    -- Draw mana pool glow if active
    if effect.poolGlow and effect.poolGlow > 0 then
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * effect.poolGlow * 0.7)
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
                    effect.color[4] * particle.alpha
                )
                imgToDraw = glowImage
            else
                love.graphics.setColor(
                    effect.color[1], 
                    effect.color[2], 
                    effect.color[3], 
                    effect.color[4] * particle.alpha
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
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.color[4] * 0.2)
        
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
                            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
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
    -- Get mana pool position for conjuration spells
    local manaPoolX = caster.manaPool and caster.manaPool.x or 400
    local manaPoolY = caster.manaPool and caster.manaPool.y or 120
    
    -- Determine source and target positions
    local sourceX, sourceY = caster.x, caster.y
    local targetX, targetY = target.x, target.y
    
    -- Handle different spell types
    local spellName = spell.name:lower():gsub("%s+", "") -- Convert to lowercase and remove spaces
    
    -- Handle conjuration spells first
    if spellName == "conjurefire" then
        return VFX.createEffect("conjurefire", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "conjuremoonlight" then
        return VFX.createEffect("conjuremoonlight", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    elseif spellName == "volatileconjuring" then
        return VFX.createEffect("volatileconjuring", sourceX, sourceY, nil, nil, {
            manaPoolX = manaPoolX,
            manaPoolY = manaPoolY
        })
    
    -- Special handling for other specific spells
    elseif spellName == "firebolt" then
        return VFX.createEffect("firebolt", sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "meteor" then
        return VFX.createEffect("meteor", targetX, targetY - 100, targetX, targetY)
    elseif spellName == "mistveil" then
        return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
    elseif spellName == "emberlift" then
        return VFX.createEffect("emberlift", sourceX, sourceY, nil, nil)
    elseif spellName == "fullmoonbeam" then
        return VFX.createEffect("fullmoonbeam", sourceX, sourceY - 20, targetX, targetY - 20)
    elseif spellName == "tidalforce" then
        return VFX.createEffect("tidal_force", sourceX, sourceY - 15, targetX, targetY - 15)
    elseif spellName == "lunardisjunction" then
        return VFX.createEffect("lunardisjunction", sourceX, sourceY - 15, targetX, targetY - 15)
    elseif spellName == "forceblast" then
        return VFX.createEffect("force_blast", sourceX, sourceY - 15, targetX, targetY - 15)
    else
        -- Create a generic effect based on spell type or mana cost
        if spell.spellType == "projectile" then
            return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
        else
            -- Look at spell cost to determine effect type
            local hasFireMana = false
            local hasMoonMana = false
            
            for _, cost in ipairs(spell.cost or {}) do
                if cost.type == "fire" then hasFireMana = true end
                if cost.type == "moon" then hasMoonMana = true end
            end
            
            if hasFireMana then
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            elseif hasMoonMana then
                return VFX.createEffect("mistveil", sourceX, sourceY, nil, nil)
            else
                -- Default generic effect
                return VFX.createEffect("firebolt", sourceX, sourceY, targetX, targetY)
            end
        end
    end
end

return VFX