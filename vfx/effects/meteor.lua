-- meteor.lua
-- Meteor VFX module for handling falling meteor/comet effects

-- Import dependencies
local Constants = require("core.Constants")
local ParticleManager = require("vfx.ParticleManager")

-- Access to the main VFX module (will be required after vfx.lua is loaded)
local VFX

-- Helper functions needed for meteor effects
local function getAssetInternal(assetId)
    -- Lazy-load VFX module to avoid circular dependencies
    if not VFX then
        -- Use a relative path that works with LÖVE's require system
        VFX = require("vfx") -- This will look for vfx.lua in the game's root directory
    end
    
    -- Use the main VFX module's getAsset function
    return VFX.getAsset(assetId)
end

-- Update function for meteor effects - SIMPLIFIED IMPLEMENTATION
local function updateMeteor(effect, dt)
    print("[METEOR] Start of updateMeteor()")

    -- Initialize basic effect properties
    effect.particles = effect.particles or {}
    effect.color = effect.color or {1, 1, 1}
    effect.height = effect.height or 300
    effect.spread = effect.spread or 40

    -- Set delaysDamage flag to true - this tells the spell system to wait for impact
    -- This should be checked in the wizard's castSpell function
    effect.delaysDamage = true
    
    -- Debug output
    print(string.format("[METEOR] Effect: timer=%.2f, progress=%.2f, particles=%d, target=(%d,%d)",
                      effect.timer or 0, effect.progress or 0, #effect.particles, 
                      effect.targetX or 0, effect.targetY or 0))
    
    -- Create particles if none exist
    if #effect.particles == 0 and effect.targetX and effect.targetY then
        print("[METEOR] Creating new meteor particles")

        local particleCount = effect.particleCount or 8

        -- Increase spread to make meteors more visually distinct
        local spreadX = effect.spread * 2.5  -- Much wider X spread
        local spreadY = effect.spread * 0.5  -- Less Y spread for a more uniform height

        for i = 1, particleCount do
            -- Create meteor particle with wide horizontal distribution and less vertical variation
            local offsetX = (math.random() - 0.5) * spreadX
            local offsetY = (math.random() - 0.5) * spreadY
            
            -- Create meteor particle using ParticleManager
            local meteor = ParticleManager.createMeteorParticle(effect, offsetX, offsetY)
            
            -- Initialize position
            meteor.x = meteor.startX
            meteor.y = meteor.startY
            
            table.insert(effect.particles, meteor)
            print(string.format("[METEOR] Created particle #%d at (%.1f, %.1f)", i, meteor.x, meteor.y))
        end
    end
    
    -- Process particles
    local rawProgress = effect.progress or 0
    
    for i, particle in ipairs(effect.particles) do
        if particle.type == "meteor" then
            -- Calculate individual particle progress
            local particleTime = (effect.timer or 0) - (particle.timeCreated or 0)
            local particleProgress = math.min(particleTime / (particle.lifespan or 1.0), 1.0)
            
            -- Use raw effect progress to move
            local moveProgress = rawProgress
            
            -- Simple linear movement from start to end position
            particle.x = particle.startX + (particle.endX - particle.startX) * moveProgress
            particle.y = particle.startY + (particle.endY - particle.startY) * moveProgress
            
            -- Update rotation
            particle.rotation = particle.rotation + particle.rotationSpeed * dt
            
            -- Logging for first particle
            if i == 1 then
                print(string.format("[METEOR] Main particle: progress=%.2f, pos=(%.1f, %.1f)", 
                                 moveProgress, particle.x, particle.y))
            end
            
            -- Randomly create trail particles
            if math.random() < 0.1 and moveProgress > 0.1 and moveProgress < 0.9 then
                local Pool = require("core.Pool")
                -- Create trail particle using ParticleManager
                local trail = ParticleManager.createMeteorTrailParticle(effect, particle)
                table.insert(effect.particles, trail)
            end
        elseif particle.type == "trail" then
            -- Update trail particles
            local trailTime = (effect.timer or 0) - (particle.timeCreated or 0)
            local trailProgress = math.min(trailTime / (particle.lifespan or 0.3), 1.0)
            
            -- Fade out trail
            particle.alpha = (1.0 - trailProgress) * particle.baseAlpha
            
            -- Shrink trail
            particle.scale = particle.baseScale * (1.0 - trailProgress * 0.5)
        elseif particle.type == "impact" then
            -- Update impact particles
            local impactTime = (effect.timer or 0) - (particle.timeCreated or 0)
            local impactProgress = math.min(impactTime / (particle.lifespan or 0.5), 1.0)
            
            -- Radiate outward
            local dist = particle.maxDist * impactProgress
            particle.x = effect.targetX + math.cos(particle.angle) * dist
            particle.y = effect.targetY + math.sin(particle.angle) * dist
            
            -- Fade out
            if impactProgress < 0.2 then
                particle.alpha = impactProgress / 0.2 * particle.baseAlpha
            else
                particle.alpha = (1.0 - (impactProgress - 0.2) / 0.8) * particle.baseAlpha
            end
        end
    end
    
    -- Create impact particles at end of animation
    if effect.progress > 0.8 and effect.progress < 0.9 and not effect.impactCreated then
        print("[METEOR] Creating impact particles")

        -- Create impact effect
        local impactCount = 12
        for i = 1, impactCount do
            local angle = (i-1) * (2 * math.pi / impactCount)
            local Pool = require("core.Pool")
            -- Create impact particle using ParticleManager
            local impact = ParticleManager.createMeteorImpactParticle(effect, angle)
            table.insert(effect.particles, impact)
        end

        -- TRIGGER DAMAGE EVENT AT IMPACT (similar to projectile implementation)
        -- Execute the damage callback if it exists (this is how we delay the actual damage until impact)
        if effect.options and effect.options.onImpact then
            print("[METEOR] Triggering onImpact callback for delayed damage!")

            local success, err = pcall(function()
                effect.options.onImpact(effect)
            end)

            if not success then
                print("[METEOR] Error in onImpact callback: " .. tostring(err))
            end
        end

        -- Trigger screen shake and hit stop on impact
        local shakeDuration = 0.25
        local shakeIntensity = 6

        -- Try to trigger screen shake if available
        if VFX.triggerShake then
            VFX.triggerShake(shakeDuration, shakeIntensity)
            print("[METEOR] Triggered screen shake")
        end

        -- Try to trigger hit stop if available
        if VFX.triggerHitstop then
            VFX.triggerHitstop(0.08)  -- Brief hitstop for impact feel
            print("[METEOR] Triggered hit stop")
        end

        effect.impactCreated = true
    end
    
    -- Clean up expired particles using ParticleManager
    local removedCount = ParticleManager.cleanupEffectParticles(effect.particles, function(particle)
        return particle.type == "trail" and particle.alpha <= 0.05
    end)

    if removedCount > 0 then
        print(string.format("[METEOR] Cleaned up %d expired particles", removedCount))
    end
    
    print(string.format("[METEOR] End of update: %d particles", #effect.particles))
end

-- Draw function for meteor effects
local function drawMeteor(effect)
    -- Set additive blending for the entire effect
    love.graphics.setBlendMode("add")
    
    -- Draw all active particles
    for _, particle in ipairs(effect.particles) do
        -- Skip invalid or invisible particles
        if not particle or particle.alpha <= 0.01 then
            goto next_draw_particle
        end
        
        -- Get the appropriate asset
        local asset = getAssetInternal(particle.assetId or "fireParticle")
        
        if asset then
            -- Get color
            local colorR, colorG, colorB = effect.color[1], effect.color[2], effect.color[3]
            if particle.color then
                colorR, colorG, colorB = particle.color[1], particle.color[2], particle.color[3]
            end
            
            -- Set color and alpha
            love.graphics.setColor(colorR, colorG, colorB, particle.alpha)
            
            -- Draw particle with rotation
            love.graphics.draw(
                asset,
                particle.x, particle.y,
                particle.rotation or 0,
                particle.scale, particle.scale,
                asset:getWidth()/2, asset:getHeight()/2
            )
            
            -- Draw glow for meteor particles
            if particle.type == "meteor" then
                -- Draw glow around meteor with additional color intensity
                love.graphics.setColor(colorR * 1.2, colorG * 1.2, colorB * 1.2, particle.alpha * 0.7)
                local glowAsset = getAssetInternal("fireGlow")
                
                if glowAsset then
                    love.graphics.draw(
                        glowAsset,
                        particle.x, particle.y,
                        0,
                        particle.scale * 2, particle.scale * 2,
                        glowAsset:getWidth()/2, glowAsset:getHeight()/2
                    )
                end
            end
        else
            -- Fallback if asset is missing
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha)
            love.graphics.circle("fill", particle.x, particle.y, (particle.scale or 1) * 20)
        end
        
        ::next_draw_particle::
    end
    
    -- Reset blend mode
    love.graphics.setBlendMode("alpha")
end

-- Return the module
return {
    update = updateMeteor,
    draw = drawMeteor
}