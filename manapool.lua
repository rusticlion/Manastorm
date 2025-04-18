-- ManaPool class
-- Represents the shared pool of mana tokens in the center

-- Import modules at module level so they're available to all methods
local AssetCache = require("core.AssetCache")
local Constants = require("core.Constants")
local Pool = require("core.Pool")

local ManaPool = {}
ManaPool.__index = ManaPool

function ManaPool.new(x, y)
    local self = setmetatable({}, ManaPool)
    
    self.x = x
    self.y = y
    self.tokens = {}  -- List of mana tokens
    
    -- Make elliptical shape even flatter and wider
    self.radiusX = 280  -- Wider horizontal radius
    self.radiusY = 60   -- Flatter vertical radius
    
    -- Define orbital rings (valences) for tokens to follow
    self.valences = {
        {radiusX = 180, radiusY = 25, baseSpeed = 0.35},  -- Inner valence
        {radiusX = 230, radiusY = 40, baseSpeed = 0.25},  -- Middle valence
        {radiusX = 280, radiusY = 55, baseSpeed = 0.18}   -- Outer valence
    }
    
    -- Chance for a token to switch valences
    self.valenceJumpChance = 0.002  -- Per frame chance of switching
    
    -- Load lock overlay image
    self.lockOverlay = AssetCache.getImage("assets/sprites/token-lock.png")
    
    -- Initialize the token pool if not already done
    if not Pool.pools["token"] then
        Pool.create("token", 50, function() 
            return {} -- Simple factory function that creates an empty table
        end, ManaPool.resetToken) -- Use our custom token reset function
    end
    
    return self
end

-- Token reset function for the pool
function ManaPool.resetToken(token)
    -- Clear all references and fields
    token.type = nil
    token.image = nil
    token.x = nil
    token.y = nil
    token.state = nil
    token.lockDuration = nil
    token.valenceIndex = nil
    token.orbitAngle = nil
    token.orbitSpeed = nil
    token.pulsePhase = nil
    token.pulseSpeed = nil
    token.rotAngle = nil
    token.rotSpeed = nil
    token.valenceJumpTimer = nil
    token.inValenceTransition = nil
    token.valenceTransitionTime = nil
    token.valenceTransitionDuration = nil
    token.sourceValenceIndex = nil
    token.targetValenceIndex = nil
    token.sourceRadiusX = nil
    token.sourceRadiusY = nil
    token.targetRadiusX = nil
    token.targetRadiusY = nil
    token.currentRadiusX = nil
    token.currentRadiusY = nil
    token.lockPulse = nil
    token.scale = nil
    token.zOrder = nil
    token.originalSpeed = nil
    token.wizardOwner = nil
    token.spellSlot = nil
    token.dissolving = nil
    token.gameState = nil
    
    -- Clear animation-related fields
    token.returning = nil
    token.animTime = nil
    token.animDuration = nil
    token.startX = nil
    token.startY = nil
    token.targetX = nil
    token.targetY = nil
    token.tokenIndex = nil
    token.inTransition = nil
    token.transitionTime = nil
    token.transitionDuration = nil
    token.originalState = nil
    token.dissolveTime = nil
    token.dissolveMaxTime = nil
    token.dissolveScale = nil
    token.initialX = nil
    token.initialY = nil
    token.exploding = nil
    
    return token
end

-- Clear all tokens from the mana pool
function ManaPool:clear()
    -- Release all tokens back to the pool
    for _, token in ipairs(self.tokens) do
        Pool.release("token", token)
    end
    
    self.tokens = {}
    self.reservedTokens = {}
end

function ManaPool:addToken(tokenType, imagePath)
    -- Pick a random valence for the token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    
    -- Calculate a random angle along the valence
    local angle = math.random() * math.pi * 2
    
    -- Calculate position based on elliptical path
    local x = self.x + math.cos(angle) * valence.radiusX
    local y = self.y + math.sin(angle) * valence.radiusY
    
    -- Generate slight positional variation to avoid tokens stacking perfectly
    local variationX = math.random(-5, 5)
    local variationY = math.random(-3, 3)
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Get image from cache, with fallback
    local tokenImage = AssetCache.getImage(imagePath)
    if not tokenImage then
        print("WARNING: Failed to load token image: " .. imagePath .. " - using placeholder")
        -- Create a placeholder image using LÖVE's built-in canvas
        tokenImage = love.graphics.newCanvas(32, 32)
        love.graphics.setCanvas(tokenImage)
        love.graphics.clear(0.8, 0.2, 0.8, 1) -- Bright color to make missing textures obvious
        love.graphics.rectangle("fill", 0, 0, 32, 32)
        love.graphics.setCanvas()
    end
    
    -- Create a new token with valence-based properties
    local token = Pool.acquire("token")
    token.type = tokenType
    token.image = tokenImage
    token.x = x + variationX
    token.y = y + variationY
    token.state = Constants.TokenState.FREE  -- FREE, CHANNELED, SHIELDING, LOCKED, DESTROYED
    token.lockDuration = 0 -- Duration for how long a token remains locked
    
    -- Valence-based orbit properties
    token.valenceIndex = valenceIndex
    token.orbitAngle = angle
    -- Speed varies by token but influenced by valence's base speed
    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    
    -- Visual effects
    token.pulsePhase = math.random() * math.pi * 2
    token.pulseSpeed = 2 + math.random() * 3
    token.rotAngle = math.random() * math.pi * 2
    token.rotSpeed = math.random(-2, 2) * 0.5 -- Varying rotation speeds
    
    -- Valence jump timer (occasional orbit changes)
    token.valenceJumpTimer = 2 + math.random() * 8 -- Random time until possible valence change
    
    -- Valence transition properties (for smooth valence changes)
    token.inValenceTransition = false
    token.valenceTransitionTime = 0
    token.valenceTransitionDuration = 0.8
    token.sourceValenceIndex = valenceIndex
    token.targetValenceIndex = valenceIndex
    token.sourceRadiusX = valence.radiusX
    token.sourceRadiusY = valence.radiusY
    token.targetRadiusX = valence.radiusX
    token.targetRadiusY = valence.radiusY
    token.currentRadiusX = valence.radiusX
    token.currentRadiusY = valence.radiusY
    
    -- Visual effect for locked state
    token.lockPulse = 0 -- For pulsing animation when locked
    
    -- Size variation for visual interest
    token.scale = 0.85 + math.random() * 0.3 -- Slight size variation
    
    -- Depth/z-order variation
    token.zOrder = math.random()  -- Used for layering tokens
    
    token.originalSpeed = token.orbitSpeed
    
    table.insert(self.tokens, token)
end

-- Removed token repulsion system, reverting to pure orbital motion

function ManaPool:update(dt)
    -- Check for destroyed tokens and remove them from the list
    for i = #self.tokens, 1, -1 do
        local token = self.tokens[i]
        if token.state == "DESTROYED" then
            -- Create an explosion/dissolution visual effect if we haven't already
            if not token.dissolving then
                token.dissolving = true
                token.dissolveTime = 0
                token.dissolveMaxTime = 0.8  -- Dissolution animation duration
                token.dissolveScale = token.scale or 1.0
                token.initialX = token.x
                token.initialY = token.y
                
                -- Create visual particle effects at the token's position
                if token.exploding ~= true then  -- Prevent duplicate explosion effects
                    token.exploding = true
                    
                    -- Get token color based on its type
                    local color = {1, 0.6, 0.2, 0.8}  -- Default orange
                    if token.type == "fire" then
                        color = {1, 0.3, 0.1, 0.8}
                    elseif token.type == "force" then
                        color = {1, 0.9, 0.3, 0.8}
                    elseif token.type == "moon" then
                        color = {0.8, 0.6, 1.0, 0.8}  -- Purple for lunar disjunction
                    elseif token.type == "nature" then
                        color = {0.2, 0.9, 0.1, 0.8}
                    elseif token.type == "star" then
                        color = {1, 0.8, 0.2, 0.8}
                    end
                    
                    -- Create destruction visual effect
                    if token.gameState and token.gameState.vfx then
                        -- Use game state VFX system if available
                        token.gameState.vfx.createEffect("impact", token.x, token.y, nil, nil, {
                            duration = 0.7,
                            color = color,
                            particleCount = 15,
                            radius = 30
                        })
                    end
                end
            else
                -- Update dissolution animation
                token.dissolveTime = token.dissolveTime + dt
                
                -- When dissolution is complete, remove the token
                if token.dissolveTime >= token.dissolveMaxTime then
                    -- Return the token to the object pool instead of just removing it
                    local removedToken = table.remove(self.tokens, i)
                    Pool.release("token", removedToken)
                end
            end
        end
    end
    
    -- Update token positions and states
    for _, token in ipairs(self.tokens) do
        -- Update token position based on state
        if token.state == "FREE" then
            -- Handle the transition period for newly returned tokens
            if token.inTransition then
                token.transitionTime = token.transitionTime + dt
                local transProgress = math.min(1, token.transitionTime / token.transitionDuration)
                
                -- Ease transition using a smooth curve
                transProgress = transProgress < 0.5 and 4 * transProgress * transProgress * transProgress 
                            or 1 - math.pow(-2 * transProgress + 2, 3) / 2
                
                -- During transition, gradually start orbital motion
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt * transProgress
                
                -- Check if transition is complete
                if token.transitionTime >= token.transitionDuration then
                    token.inTransition = false
                end
            else
                -- Normal FREE token behavior after transition
                -- Update orbit angle with variable speed
                token.orbitAngle = token.orbitAngle + token.orbitSpeed * dt
                
                -- Update valence jump timer
                token.valenceJumpTimer = token.valenceJumpTimer - dt
                
                -- Chance to change valence when timer expires
                if token.valenceJumpTimer <= 0 then
                    token.valenceJumpTimer = 2 + math.random() * 8  -- Reset timer
                    
                    -- Random chance to jump to a different valence
                    if math.random() < self.valenceJumpChance * 100 then
                        -- Store current valence for interpolation
                        local oldValenceIndex = token.valenceIndex
                        local oldValence = self.valences[oldValenceIndex]
                        local newValenceIndex = oldValenceIndex
                        
                        -- Ensure we pick a different valence if more than one exists
                        if #self.valences > 1 then
                            while newValenceIndex == oldValenceIndex do
                                newValenceIndex = math.random(1, #self.valences)
                            end
                        end
                        
                        -- Start valence transition
                        local newValence = self.valences[newValenceIndex]
                        local direction = token.orbitSpeed > 0 and 1 or -1
                        
                        -- Set up transition parameters
                        token.inValenceTransition = true
                        token.valenceTransitionTime = 0
                        token.valenceTransitionDuration = 0.8  -- Time to transition between valences
                        token.sourceValenceIndex = oldValenceIndex
                        token.targetValenceIndex = newValenceIndex
                        token.sourceRadiusX = oldValence.radiusX
                        token.sourceRadiusY = oldValence.radiusY
                        token.targetRadiusX = newValence.radiusX
                        token.targetRadiusY = newValence.radiusY
                        
                        -- Update speed for new valence but maintain direction
                        token.orbitSpeed = newValence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                        token.originalSpeed = token.orbitSpeed
                    end
                end
                
                -- Handle valence transition if active
                if token.inValenceTransition then
                    token.valenceTransitionTime = token.valenceTransitionTime + dt
                    local progress = math.min(1, token.valenceTransitionTime / token.valenceTransitionDuration)
                    
                    -- Use easing function for smooth transition
                    progress = progress < 0.5 and 4 * progress * progress * progress 
                              or 1 - math.pow(-2 * progress + 2, 3) / 2
                    
                    -- Interpolate between source and target radiuses
                    token.currentRadiusX = token.sourceRadiusX + (token.targetRadiusX - token.sourceRadiusX) * progress
                    token.currentRadiusY = token.sourceRadiusY + (token.targetRadiusY - token.sourceRadiusY) * progress
                    
                    -- Check if transition is complete
                    if token.valenceTransitionTime >= token.valenceTransitionDuration then
                        token.inValenceTransition = false
                        token.valenceIndex = token.targetValenceIndex
                    end
                end
                
                -- Occasionally vary the speed slightly
                if math.random() < 0.01 then
                    local direction = token.orbitSpeed > 0 and 1 or -1
                    local valence = self.valences[token.valenceIndex]
                    local variation = 0.9 + math.random() * 0.2  -- Subtle variation
                    token.orbitSpeed = valence.baseSpeed * variation * direction
                end
            end
            
            -- Common behavior for all FREE tokens
            -- Update pulse phase
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            
            -- Calculate new position based on elliptical orbit - maintain perfect elliptical path
            if token.inValenceTransition then
                -- Use interpolated radii during transition
                token.x = self.x + math.cos(token.orbitAngle) * token.currentRadiusX
                token.y = self.y + math.sin(token.orbitAngle) * token.currentRadiusY
            else
                -- Use valence radii when not transitioning
                local valence = self.valences[token.valenceIndex]
                token.x = self.x + math.cos(token.orbitAngle) * valence.radiusX
                token.y = self.y + math.sin(token.orbitAngle) * valence.radiusY
            end
            
            -- Minimal wobble to maintain clean orbits but add slight visual interest
            local wobbleX = math.sin(token.pulsePhase * 0.7) * 2
            local wobbleY = math.cos(token.pulsePhase * 0.5) * 1
            token.x = token.x + wobbleX
            token.y = token.y + wobbleY
            
            -- Rotate token itself for visual interest, occasionally reversing direction
            token.rotAngle = token.rotAngle + token.rotSpeed * dt
            if math.random() < 0.002 then  -- Small chance to reverse rotation
                token.rotSpeed = -token.rotSpeed
            end
        elseif token.state == "CHANNELED" or token.state == "SHIELDING" then
            -- For channeled or shielding tokens, animate movement to/from their spell slot
            
            if token.animTime < token.animDuration then
                -- Token is still being animated to the spell slot
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                -- Start point
                local x0 = token.startX
                local y0 = token.startY
                
                -- End point (in the spell slot)
                local wizard = token.wizardOwner
                if wizard then
                    -- Calculate position in the 3D elliptical spell slot orbit
                    -- These values must match those in wizard.lua drawSpellSlots
                    local slotYOffsets = {30, 0, -30}  -- legs, midsection, head
                    local horizontalRadii = {80, 70, 60}  -- From bottom to top
                    local verticalRadii = {20, 25, 30}    -- From bottom to top
                    
                    local slotY = wizard.y + slotYOffsets[token.slotIndex]
                    local radiusX = horizontalRadii[token.slotIndex]
                    local radiusY = verticalRadii[token.slotIndex]
                    
                    local tokenCount = #wizard.spellSlots[token.slotIndex].tokens
                    local anglePerToken = math.pi * 2 / tokenCount
                    local tokenAngle = wizard.spellSlots[token.slotIndex].progress / 
                                       wizard.spellSlots[token.slotIndex].castTime * math.pi * 2 +
                                       anglePerToken * (token.tokenIndex - 1)
                    
                    -- Calculate position using elliptical projection
                    -- Apply the NEAR/FAR offset to the target position
                    local xOffset = 0
                    local isNear = wizard.gameState and wizard.gameState.rangeState == "NEAR"
                    
                    -- Apply the same NEAR/FAR offset logic as in the wizard's draw function
                    if wizard.name == "Ashgar" then -- Player 1 (left side)
                        xOffset = isNear and 60 or 0 -- Move right when NEAR
                    else -- Player 2 (right side)
                        xOffset = isNear and -60 or 0 -- Move left when NEAR
                    end
                    
                    local x3 = wizard.x + xOffset + math.cos(tokenAngle) * radiusX
                    local y3 = slotY + math.sin(tokenAngle) * radiusY
                    
                    -- Control points for bezier (creating an arc)
                    local midX = (x0 + x3) / 2
                    local midY = (y0 + y3) / 2 - 80  -- Arc height
                    
                    -- Quadratic bezier calculation
                    local t = progress
                    local u = 1 - t
                    token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                    token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                    
                    -- Update token rotation during flight
                    token.rotAngle = token.rotAngle + dt * 5  -- Spin faster during flight
                    
                    -- Store target position for the drawing function
                    token.targetX = x3
                    token.targetY = y3
                end
            else
                -- Animation complete - token is now in the spell orbit
                -- Token position will be updated by the wizard's drawSpellSlots function
                token.rotAngle = token.rotAngle + dt * 2  -- Continue spinning in orbit
            end
            
            -- Check if token is returning to the pool
            if token.returning then
                -- Token is being animated back to the mana pool
                token.animTime = token.animTime + dt
                local progress = math.min(1, token.animTime / token.animDuration)
                
                -- Ease in-out function for smoother animation
                progress = progress < 0.5 and 4 * progress * progress * progress 
                            or 1 - math.pow(-2 * progress + 2, 3) / 2
                
                -- Calculate current position based on bezier curve for arcing motion
                local x0 = token.startX
                local y0 = token.startY
                local x3 = self.x  -- Center of mana pool
                local y3 = self.y
                
                -- Control points for bezier (creating an arc)
                local midX = (x0 + x3) / 2
                local midY = (y0 + y3) / 2 - 50  -- Arc height
                
                -- Quadratic bezier calculation
                local t = progress
                local u = 1 - t
                token.x = u*u*x0 + 2*u*t*midX + t*t*x3
                token.y = u*u*y0 + 2*u*t*midY + t*t*y3
                
                -- Update token rotation during flight - spin faster
                token.rotAngle = token.rotAngle + dt * 8
                
                -- Check if animation is complete
                if token.animTime >= token.animDuration then
                    -- Token has reached the pool - finalize its return and perform state transition
                    print(string.format("[MANAPOOL] Token return animation completed, finalizing state"))
                    self:finalizeTokenReturn(token)
                end
            end
            
            -- Update common pulse
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
        elseif token.state == "LOCKED" then
            -- For locked tokens, update the lock duration
            if token.lockDuration > 0 then
                token.lockDuration = token.lockDuration - dt
                
                -- Update lock pulse for animation
                token.lockPulse = (token.lockPulse + dt * 3) % (math.pi * 2)
                
                -- When lock duration expires, return to FREE state
                if token.lockDuration <= 0 then
                    token.state = "FREE"
                    print("A " .. token.type .. " token has been unlocked and returned to the mana pool")
                    
                    -- Reset position to center with some random velocity
                    token.x = self.x
                    token.y = self.y
                    -- Pick a random valence for the formerly locked token
                    token.valenceIndex = math.random(1, #self.valences)
                    token.orbitAngle = math.random() * math.pi * 2
                    -- Set direction and speed based on the valence
                    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
                    local valence = self.valences[token.valenceIndex]
                    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
                    token.originalSpeed = token.orbitSpeed
                    -- No repulsion forces needed (system removed)
                end
            end
            
            -- Even locked tokens should move a bit, but more constrained
            token.x = token.x + math.sin(token.lockPulse) * 0.3
            token.y = token.y + math.cos(token.lockPulse) * 0.3
            
            -- Slight rotation
            token.rotAngle = token.rotAngle + token.rotSpeed * dt * 0.2
        end
        
        -- Update common properties for all tokens
        token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
    end
end

function ManaPool:draw()
    -- No longer drawing the pool background or valence rings
    -- The pool is now completely invisible, defined only by the positions of the tokens
    
    -- Sort tokens by z-order for better layering
    local sortedTokens = {}
    for i, token in ipairs(self.tokens) do
        table.insert(sortedTokens, {token = token, index = i})
    end
    
    table.sort(sortedTokens, function(a, b)
        return a.token.zOrder > b.token.zOrder
    end)
    
    -- Draw tokens in sorted order
    for _, tokenData in ipairs(sortedTokens) do
        local token = tokenData.token
        
        -- Draw a larger, more vibrant glow around the token based on its type
        local glowSize = 15 -- Larger glow radius
        local glowIntensity = 0.6  -- Stronger glow intensity
        
        -- Multiple glow layers for more visual interest
        for layer = 1, 2 do
            local layerSize = glowSize * (1.2 - layer * 0.3)
            local layerIntensity = glowIntensity * (layer == 1 and 0.4 or 0.8)
            
            -- Increase glow for tokens in transition (newly returned to pool)
            if token.state == "FREE" and token.inTransition then
                -- Stronger glow that fades over the transition period
                local transitionBoost = 0.6 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
                layerSize = layerSize * (1 + transitionBoost * 0.5)
                layerIntensity = layerIntensity + transitionBoost * 0.5
            end
            
            -- Set glow color based on token type with improved contrast and vibrancy
            if token.type == "fire" then
                love.graphics.setColor(1, 0.3, 0.1, layerIntensity)
            elseif token.type == "force" then
                love.graphics.setColor(1, 0.9, 0.3, layerIntensity)
            elseif token.type == "moon" then
                love.graphics.setColor(0.4, 0.4, 1, layerIntensity)
            elseif token.type == "nature" then
                love.graphics.setColor(0.2, 0.9, 0.1, layerIntensity)
            elseif token.type == "star" then
                love.graphics.setColor(1, 0.8, 0.2, layerIntensity)
            end
            
            -- Draw glow with pulsation
            local pulseAmount = 0.7 + 0.3 * math.sin(token.pulsePhase * 0.5)
            
            -- Enhanced pulsation for transitioning tokens
            if token.state == "FREE" and token.inTransition then
                pulseAmount = pulseAmount + 0.3 * math.sin(token.transitionTime * 10)
            end
            
            love.graphics.circle("fill", token.x, token.y, layerSize * pulseAmount * token.scale)
        end
        
        -- Draw a small outer ring for better definition
        if token.state == "FREE" then
            local ringAlpha = 0.4 + 0.2 * math.sin(token.pulsePhase * 0.8)
            
            -- Set ring color based on token type
            if token.type == "fire" then
                love.graphics.setColor(1, 0.5, 0.2, ringAlpha)
            elseif token.type == "force" then
                love.graphics.setColor(1, 1, 0.4, ringAlpha)
            elseif token.type == "moon" then
                love.graphics.setColor(0.6, 0.6, 1, ringAlpha)
            elseif token.type == "nature" then
                love.graphics.setColor(0.3, 1, 0.2, ringAlpha)
            elseif token.type == "star" then
                love.graphics.setColor(1, 0.9, 0.3, ringAlpha)
            end
            
            love.graphics.circle("line", token.x, token.y, (glowSize + 3) * token.scale)
        end
        
        -- Draw token image based on state
        if token.state == "FREE" then
            -- Free tokens are fully visible
            -- If token is in transition (just returned to pool), add a subtle glow effect
            if token.inTransition then
                local transitionGlow = 0.2 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
                love.graphics.setColor(1, 1, 1 + transitionGlow * 0.5, 1)  -- Slightly blue-white glow during transition
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
        elseif token.state == "CHANNELED" then
            -- Channeled tokens are fully visible
            love.graphics.setColor(1, 1, 1, 1)
        elseif token.state == "SHIELDING" then
            -- Shielding tokens have a slight colored tint based on their type
            if token.type == "force" then
                love.graphics.setColor(1, 1, 0.7, 1)  -- Yellow tint for force (barrier)
            elseif token.type == "moon" or token.type == "star" then
                love.graphics.setColor(0.8, 0.8, 1, 1)  -- Blue tint for moon/star (ward)
            elseif token.type == "nature" then
                love.graphics.setColor(0.8, 1, 0.8, 1)  -- Green tint for nature (field)
            else
                love.graphics.setColor(1, 1, 1, 1)  -- Default
            end
        elseif token.state == "LOCKED" then
            -- Locked tokens have a red tint
            love.graphics.setColor(1, 0.5, 0.5, 0.7)
        elseif token.state == "DESTROYED" then
            -- Dissolving tokens fade out
            if token.dissolving then
                -- Calculate progress of the dissolve animation
                local progress = token.dissolveTime / token.dissolveMaxTime
                
                -- Fade out by decreasing alpha
                local alpha = (1 - progress) * 0.8
                
                -- Get token color based on its type for the fade effect
                if token.type == "fire" then
                    love.graphics.setColor(1, 0.3, 0.1, alpha)
                elseif token.type == "force" then
                    love.graphics.setColor(1, 0.9, 0.3, alpha)
                elseif token.type == "moon" then
                    love.graphics.setColor(0.8, 0.6, 1.0, alpha)  -- Purple for lunar disjunction
                elseif token.type == "nature" then
                    love.graphics.setColor(0.2, 0.9, 0.1, alpha)
                elseif token.type == "star" then
                    love.graphics.setColor(1, 0.8, 0.2, alpha)
                else
                    love.graphics.setColor(1, 1, 1, alpha)
                end
            else
                -- Skip drawing if not dissolving
                goto continue
            end
        end
        
        -- Draw the token with dynamic scaling
        if token.state == "DESTROYED" and token.dissolving then
            -- For dissolving tokens, add special effects
            local progress = token.dissolveTime / token.dissolveMaxTime
            
            -- Expand and fade out
            local scaleFactor = token.dissolveScale * (1 + progress * 0.5)
            local rotationSpeed = token.rotSpeed or 1.0
            
            -- Speed up rotation as it dissolves
            token.rotAngle = token.rotAngle + rotationSpeed * 5 * progress
            
            -- Draw at original position with expanding effect
            love.graphics.draw(
                token.image, 
                token.initialX, 
                token.initialY, 
                token.rotAngle,
                scaleFactor * (1 - progress * 0.7), scaleFactor * (1 - progress * 0.7),
                token.image:getWidth()/2, token.image:getHeight()/2
            )
        else
            -- Normal tokens
            love.graphics.draw(
                token.image, 
                token.x, 
                token.y, 
                token.rotAngle,  -- Use the rotation angle
                token.scale, token.scale,  -- Use token-specific scale
                token.image:getWidth()/2, token.image:getHeight()/2  -- Origin at center
            )
        end
        
        ::continue::
        
        -- Draw shield effect for shielding tokens
        if token.state == "SHIELDING" then
            -- Get token color based on its mana type
            local tokenColor = {1, 1, 1, 0.3}  -- Default white
            
            -- Match color to the token type
            if token.type == "fire" then
                tokenColor = {1.0, 0.3, 0.1, 0.3}  -- Red-orange for fire
            elseif token.type == "force" then
                tokenColor = {1.0, 1.0, 0.3, 0.3}  -- Yellow for force
            elseif token.type == "moon" then
                tokenColor = {0.5, 0.5, 1.0, 0.3}  -- Blue for moon
            elseif token.type == "star" then
                tokenColor = {1.0, 0.8, 0.2, 0.3}  -- Gold for star
            elseif token.type == "nature" then
                tokenColor = {0.3, 0.9, 0.1, 0.3}  -- Green for nature
            end
            
            -- Draw a subtle shield aura with slight pulsation
            local pulseScale = 0.9 + math.sin(love.timer.getTime() * 2) * 0.1
            love.graphics.setColor(tokenColor)
            love.graphics.circle("fill", token.x, token.y, 15 * pulseScale * token.scale)
            
            -- Draw shield border
            love.graphics.setColor(tokenColor[1], tokenColor[2], tokenColor[3], 0.5)
            love.graphics.circle("line", token.x, token.y, 15 * pulseScale * token.scale)
            
            -- Add a small defensive shield symbol inside the circle
            -- Determine symbol shape by defense type if available
            if token.wizardOwner and token.spellSlot then
                local slot = token.wizardOwner.spellSlots[token.spellSlot]
                if slot and slot.defenseType then
                    love.graphics.setColor(1, 1, 1, 0.7)
                    if slot.defenseType == "barrier" then
                        -- Draw a small hexagon (shield shape) for barriers
                        local shieldSize = 6 * token.scale
                        local points = {}
                        for i = 1, 6 do
                            local angle = (i - 1) * math.pi / 3
                            table.insert(points, token.x + math.cos(angle) * shieldSize)
                            table.insert(points, token.y + math.sin(angle) * shieldSize)
                        end
                        love.graphics.polygon("line", points)
                    elseif slot.defenseType == "ward" then
                        -- Draw a small circle (ward shape)
                        love.graphics.circle("line", token.x, token.y, 6 * token.scale)
                    elseif slot.defenseType == "field" then
                        -- Draw a small diamond (field shape)
                        local fieldSize = 7 * token.scale
                        love.graphics.polygon("line", 
                            token.x, token.y - fieldSize,
                            token.x + fieldSize, token.y,
                            token.x, token.y + fieldSize,
                            token.x - fieldSize, token.y
                        )
                    end
                end
            end
        end
        
        -- Draw lock overlay for locked tokens
        if token.state == "LOCKED" then
            -- Draw the lock overlay
            local pulseScale = 0.9 + math.sin(token.lockPulse) * 0.2  -- Pulsing effect
            local overlayScale = 1.2 * pulseScale * token.scale  -- Scale for the lock overlay
            
            -- Pulsing red glow behind the lock
            love.graphics.setColor(1, 0, 0, 0.3 + 0.2 * math.sin(token.lockPulse))
            love.graphics.circle("fill", token.x, token.y, 12 * pulseScale * token.scale)
            
            -- Lock icon
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                self.lockOverlay,
                token.x,
                token.y,
                0,  -- No rotation for lock
                overlayScale, overlayScale,
                self.lockOverlay:getWidth()/2, self.lockOverlay:getHeight()/2
            )
            
            -- Display remaining lock time if more than 1 second
            if token.lockDuration > 1 then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(
                    string.format("%.0f", token.lockDuration),
                    token.x - 5,
                    token.y - 25
                )
            end
        end
    end
    
    -- No border - the pool is now completely invisible
end

-- Helper function to draw an ellipse
function ManaPool:drawEllipse(x, y, radiusX, radiusY, mode)
    local segments = 64
    local vertices = {}
    
    for i = 1, segments do
        local angle = (i - 1) * (2 * math.pi / segments)
        local px = x + math.cos(angle) * radiusX
        local py = y + math.sin(angle) * radiusY
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    -- Close the shape by adding the first point again
    table.insert(vertices, vertices[1])
    table.insert(vertices, vertices[2])
    
    if mode == "fill" then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
end

function ManaPool:findFreeToken(tokenType)
    -- Find a free token of the specified type without changing its state
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            return token, i  -- Return token and its index without changing state
        end
    end
    return nil  -- No token available
end

function ManaPool:getToken(tokenType)
    -- Find a free token of the specified type that's not in transition
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" and
           not token.returning and not token.inTransition then
            -- Mark as being used
            token.state = "CHANNELED"  
            print(string.format("[MANAPOOL] Token %d (%s) reserved for channeling", i, token.type))
            return token, i  -- Return token and its index
        end
    end
    
    -- Second pass - try with less strict requirements if nothing was found
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.state == "FREE" then
            if token.returning then
                print("[MANAPOOL] WARNING: Using token in return animation - visual glitches may occur")
            elseif token.inTransition then
                print("[MANAPOOL] WARNING: Using token in transition state - visual glitches may occur")
            end
            token.state = "CHANNELED"
            print(string.format("[MANAPOOL] Token %d (%s) reserved for channeling (fallback)", i, token.type))
            -- Cancel any return animation
            token.returning = false
            token.inTransition = false
            return token, i
        end
    end
    
    return nil  -- No token available
end

function ManaPool:returnToken(tokenIndex)
    -- Return a token to the pool
    if self.tokens[tokenIndex] then
        local token = self.tokens[tokenIndex]
        
        -- Validate the token state and ownership before return
        if token.returning then
            print("[MANAPOOL] WARNING: Token " .. tokenIndex .. " is already being returned - ignoring duplicate return")
            return
        end
        
        -- Clear any wizard ownership immediately to prevent double-tracking
        token.wizardOwner = nil
        token.spellSlot = nil
        
        -- Ensure token is in a valid state - convert any state to valid transition state
        local originalState = token.state
        if token.state == "SHIELDING" or token.state == "CHANNELED" then
            print("[MANAPOOL] Token " .. tokenIndex .. " transitioning from " .. 
                 (token.state or "nil") .. " to return animation")
            
            -- We don't set state = FREE here yet - we let the animation complete first
            -- This prevents tokens from being reused in the middle of an animation
        elseif token.state ~= "FREE" then
            print("[MANAPOOL] WARNING: Returning token " .. tokenIndex .. " from unexpected state: " .. 
                 (token.state or "nil"))
        end
        
        -- Store current position as start position for return animation
        token.startX = token.x
        token.startY = token.y
        
        -- Pick a random valence for the token to return to
        local valenceIndex = math.random(1, #self.valences)
        
        -- Initialize needed valence transition fields
        local valence = self.valences[valenceIndex]
        token.valenceIndex = valenceIndex
        token.sourceValenceIndex = valenceIndex  -- Will be properly set in finalizeTokenReturn
        token.targetValenceIndex = valenceIndex
        token.sourceRadiusX = valence.radiusX
        token.sourceRadiusY = valence.radiusY
        token.targetRadiusX = valence.radiusX
        token.targetRadiusY = valence.radiusY
        token.currentRadiusX = valence.radiusX
        token.currentRadiusY = valence.radiusY
        
        -- Set up return animation parameters
        token.targetX = self.x  -- Center of mana pool
        token.targetY = self.y
        token.animTime = 0
        token.animDuration = 0.5 -- Half second return animation
        token.returning = true   -- Flag that this token is returning to the pool
        token.originalState = originalState  -- Remember what state it was in before return
        
        -- Set direction and speed based on the valence for when it becomes FREE
        local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
        token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
        token.originalSpeed = token.orbitSpeed
        
        -- Reset timers with some randomness
        token.valenceJumpTimer = 2 + math.random() * 4
        
        -- Initialize transition state for smooth blending
        token.inValenceTransition = false
        token.valenceTransitionTime = 0
        token.valenceTransitionDuration = 0.8
        
        print("[MANAPOOL] Token " .. tokenIndex .. " (" .. token.type .. ") returning animation started")
    else
        print("[MANAPOOL] WARNING: Attempted to return invalid token index: " .. tokenIndex)
    end
end

-- Called by update method when a token finishes its return animation
function ManaPool:finalizeTokenReturn(token)
    -- Clear all references to the spell it was used in
    token.wizardOwner = nil
    token.spellSlot = nil
    token.tokenIndex = nil
    
    -- Record the original state for debugging
    local originalState = token.state
    
    -- ALWAYS set to FREE state when a token returns to the pool
    token.state = "FREE"
    
    -- Log state change with details
    if originalState ~= "FREE" then
        print(string.format("[MANAPOOL] Token state changed: %s -> FREE (was %s before return animation)", 
              originalState or "nil", token.originalState or "unknown"))
    end
    token.originalState = nil -- Clean up
    
    -- Use the final position from the animation as the starting point
    local currentX = token.x
    local currentY = token.y
    
    -- Calculate angle from center
    local dx = currentX - self.x
    local dy = currentY - self.y
    local angle = math.atan2(dy, dx)
    
    -- Assign a random valence for the returned token
    local valenceIndex = math.random(1, #self.valences)
    local valence = self.valences[valenceIndex]
    token.valenceIndex = valenceIndex
    
    -- Calculate position based on current angle but using valence's elliptical dimensions
    token.orbitAngle = angle
    
    -- Calculate initial x,y based on selected valence
    local newX = self.x + math.cos(angle) * valence.radiusX
    local newY = self.y + math.sin(angle) * valence.radiusY
    
    -- Apply minimal variation to maintain clean orbits
    local variationX = math.random(-2, 2)
    local variationY = math.random(-1, 1)
    token.x = newX + variationX
    token.y = newY + variationY
    
    -- Randomize orbit direction (clockwise or counter-clockwise)
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    
    -- Set orbital speed based on the valence
    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    token.originalSpeed = token.orbitSpeed
    
    -- Add transition for smooth blending
    token.transitionTime = 0
    token.transitionDuration = 1.0  -- 1 second to blend into normal motion
    token.inTransition = true  -- Mark token as transitioning to normal motion
    
    -- Add valence jump timer
    token.valenceJumpTimer = 2 + math.random() * 8
    
    -- Initialize valence transition properties
    token.inValenceTransition = false
    token.valenceTransitionTime = 0
    token.valenceTransitionDuration = 0.8
    token.sourceValenceIndex = valenceIndex
    token.targetValenceIndex = valenceIndex
    token.sourceRadiusX = valence.radiusX
    token.sourceRadiusY = valence.radiusY
    token.targetRadiusX = valence.radiusX
    token.targetRadiusY = valence.radiusY
    token.currentRadiusX = valence.radiusX
    token.currentRadiusY = valence.radiusY
    
    -- Size and z-order variation
    token.scale = 0.85 + math.random() * 0.3
    token.zOrder = math.random()
    
    -- Clear animation flags and any spell-related ownership
    token.returning = false
    
    print("[MANAPOOL] Token (" .. token.type .. ") has fully returned to the pool and is FREE")
end

return ManaPool