-- This file contains the improvements for shield blocking visuals
-- It should be added to vfx.lua and systems/EventRunner.lua

-- === PATCH FOR VFX.lua ===

-- Find the `updateEffect` function in vfx.lua and add this code to the top:
-- Near beginning of the function, after checking if effect is complete add:
```lua
-- Check if effect is complete
if effect.progress >= 1.0 then
    effect.isComplete = true
    effect.progress = 1.0
    
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
    
    return
end
```

-- In the projectile update section, modify the handler for particles to check for blockPoint:
```lua
-- Inside the update logic for projectile effects
if effect.type == "projectile" then
    -- For projectiles, update particles along trajectory
    -- Activate particles based on their delay
    for _, particle in ipairs(effect.particles) do
        -- Activate particles that are past their delay
        if not particle.active and effect.timer >= particle.delay then
            particle.active = true
            particle.startTime = 0
        end
        
        -- Update active particles
        if particle.active then
            -- Basic projectile motion from source to target
            -- Apply time-based progress
            local particleProgress = (effect.timer - particle.delay) / effect.duration
            if particleProgress > 1.0 then particleProgress = 1.0 end
            
            -- Check if this effect has a blockPoint progress value (for shield blocks)
            local blockPoint = effect.options and effect.options.blockPoint
            local isBlocked = blockPoint and (effect.progress >= blockPoint)
            
            -- Handle normal projectile motion vs. shield block scenario
            if not isBlocked then
                -- Normal movement toward target (either full path or up to block point)
                -- Apply motion style update if we aren't at impact yet
                if effect.progress < 0.98 or not particle.isCore then
                    VFX.updateParticle(particle, effect, dt, particleProgress)
                else
                    -- For core particles at impact, start the impact cluster
                    -- Move quickly to impact point with decay
                    local impactProgress = (particleProgress - 0.9) * 10 -- 0 to 1 in last 10%
                    local distance = effect.impactSize * 20 * (1 - impactProgress)
                    local explosionAngle = math.random() * math.pi * 2
                    
                    particle.x = effect.targetX + math.cos(explosionAngle) * distance * math.random()
                    particle.y = effect.targetY + math.sin(explosionAngle) * distance * math.random()
                    
                    -- Fade out at end
                    particle.alpha = 1 - impactProgress
                end
            else
                -- We're past the block point, display shield block behavior
                -- Calculate how far into the block animation we are
                local blockProgress = (effect.progress - blockPoint) / (1.0 - blockPoint)
                
                if blockProgress < 0.2 then
                    -- Initial impact phase - particles bunch up at block point
                    -- Calculate block point coordinates based on progress
                    local blockX = effect.sourceX + (effect.targetX - effect.sourceX) * blockPoint
                    local blockY = effect.sourceY + (effect.targetY - effect.sourceY) * blockPoint
                    
                    -- Move particles toward block point with some randomness
                    local angle = math.random() * math.pi * 2
                    local scatter = 20 * (1.0 - blockProgress/0.2) -- Reduce scatter as we progress
                    particle.x = blockX + math.cos(angle) * scatter * math.random()
                    particle.y = blockY + math.sin(angle) * scatter * math.random()
                else
                    -- Deflection phase - particles scatter outward from block point
                    local blockX = effect.sourceX + (effect.targetX - effect.sourceX) * blockPoint
                    local blockY = effect.sourceY + (effect.targetY - effect.sourceY) * blockPoint
                    
                    -- Calculate deflection angle (away from target, with randomness)
                    local baseAngle = math.atan2(effect.sourceY - effect.targetY, effect.sourceX - effect.targetX)
                    local deflectAngle = baseAngle + (math.random() - 0.5) * math.pi * 0.8
                    
                    -- Move particles outward from block point
                    local deflectDistance = 60 * (blockProgress - 0.2) * math.random(0.7, 1.3)
                    particle.x = blockX + math.cos(deflectAngle) * deflectDistance
                    particle.y = blockY + math.sin(deflectAngle) * deflectDistance
                    
                    -- Fade out as particles scatter
                    particle.alpha = math.max(0, 1.0 - (blockProgress - 0.2)/0.8)
                end
            end
            
            -- Update scale and alpha based on lifecycle
            local baseScale = effect.startScale + (effect.endScale - effect.startScale) * effect.progress
            
            -- (rest of particle update code)
        end
    end
    
    -- Handle impact or block effects
    local blockPoint = effect.options and effect.options.blockPoint
    
    -- Check for normal impact (near completion and no block point defined)
    if effect.progress > 0.97 and not effect.impactCreated and not blockPoint then
        -- Create impact effect at target location
        effect.impactCreated = true
        
        -- Note: Since we're already in the VFX module, we can directly create a
        -- new effect without going through safeCreateVFX
        if effect.impactSize and effect.impactSize > 0 then
            local impactOpts = {
                duration = 0.3,
                color = effect.color,
                particleCount = math.floor(effect.particleCount * 0.5) -- Half as many particles
            }
            
            VFX.createEffect("impact", effect.targetX, effect.targetY, nil, nil, impactOpts)
        end
    end
    
    -- Check for block effect (we've reached the block point)
    if blockPoint and effect.progress >= blockPoint and not effect.blockEffectCreated then
        -- Create block effect at block point
        effect.blockEffectCreated = true
        
        -- Calculate block point coordinates
        local blockX = effect.sourceX + (effect.targetX - effect.sourceX) * blockPoint
        local blockY = effect.sourceY + (effect.targetY - effect.sourceY) * blockPoint
        
        -- Create shield hit effect
        local shieldHitOpts = {
            duration = 0.5,
            color = effect.options.shieldColor or {1.0, 1.0, 0.3, 0.7}, -- Default yellow
            particleCount = math.floor(effect.particleCount * 0.8),
            shieldType = effect.options.shieldType
        }
        
        VFX.createEffect("shield_hit_base", blockX, blockY, nil, nil, shieldHitOpts)
    end
```

-- === PATCH FOR createEffect FUNCTION ===

-- In the createEffect function, after copying option parameters, add:
```lua
-- Store options for later access (including callbacks)
effect.options = opts
```

-- === USAGE INSTRUCTIONS ===

-- This file documents the changes needed to VFX.lua and EventRunner.lua to implement
-- improved shield block visuals and delayed damage. The changes are designed to be 
-- merged into existing code, not used directly.

-- The key changes are:
-- 1. Adding onComplete callback support to VFX effects
-- 2. Adding blockPoint support to show projectiles traveling to a point before being blocked
-- 3. Showing shield block animations at the block point

-- To use these improvements:
-- 1. Make sure createEffect stores options including callbacks 
-- 2. Update the updateEffect function to execute callbacks on completion
-- 3. Modify the projectile update logic to handle blockPoint
-- 4. Set delayDamage=true in damage events from projectile spells
-- 5. Pass spell information to createBlockVFX in ShieldSystem