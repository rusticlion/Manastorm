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
    
    -- Initialize token trails system
    self.tokenTrails = {}
    self.trailLength = 30  -- Max number of positions to store per token
    
    -- Initialize the token pool if not already done
    if not Pool.pools["token"] then
        Pool.create("token", 50, function() 
            return {} -- Simple factory function that creates an empty table
        end, ManaPool.resetToken) -- Use our custom token reset function
    end
    
    return self
end

-- Token methods for state machine
local TokenMethods = {}

-- Set the token's state with validation
function TokenMethods:setState(newStatus)
    local oldStatus = self.status

    -- Validate state transitions
    if self.status == Constants.TokenStatus.POOLED then
        print("[TOKEN LIFECYCLE] WARNING: Cannot transition from POOLED state!")
        return false
    end

    -- Finalize scale if leaving an animation state that modifies scale
    if (oldStatus == Constants.TokenStatus.APPEARING or oldStatus == Constants.TokenStatus.ORBITING) and
       (newStatus == Constants.TokenStatus.CHANNELED or
        newStatus == Constants.TokenStatus.SHIELDING or
        newStatus == Constants.TokenStatus.FREE) then
        if self.targetScale then
            self.scale = self.targetScale
        else
            self.scale = 0.85 + math.random() * 0.3
        end
    end

    -- Update the token's status
    self.status = newStatus
    
    -- For backwards compatibility, keep the legacy state in sync with the new status
    if newStatus == Constants.TokenStatus.FREE or 
       newStatus == Constants.TokenStatus.CHANNELED or 
       newStatus == Constants.TokenStatus.SHIELDING then
        self.state = newStatus
    elseif newStatus == Constants.TokenStatus.RETURNING or
           newStatus == Constants.TokenStatus.APPEARING or
           newStatus == Constants.TokenStatus.ORBITING then
        self.state = self.originalStatus or Constants.TokenState.FREE -- Keep original state during animation
    elseif newStatus == Constants.TokenStatus.DISSOLVING then
        self.state = Constants.TokenState.DESTROYED
    elseif newStatus == Constants.TokenStatus.POOLED then
        self.state = Constants.TokenState.DESTROYED
    end
    
    return true
end

-- Request token return animation
function TokenMethods:requestReturnAnimation()
    -- Validate current state
    if self.status ~= Constants.TokenStatus.CHANNELED and self.status ~= Constants.TokenStatus.SHIELDING then
        print("[TOKEN LIFECYCLE] WARNING: Can only return tokens from CHANNELED or SHIELDING state, not " .. (self.status or "nil"))
        return false
    end
    
    -- Store the original status for later reference
    self.originalStatus = self.status
    
    -- Set animation flags
    self.isAnimating = true
    self.returning = true  -- For backward compatibility
    
    -- Set animation parameters
    self.startX = self.x
    self.startY = self.y
    self.animTime = 0
    self.animDuration = 0.5 -- Half second return animation
    
    -- Store callback to be called when animation completes
    self.animationCallback = function() self:finalizeReturn() end
    
    -- Change state to RETURNING
    self:setState(Constants.TokenStatus.RETURNING)
    
    return true
end

-- Request token destruction animation
function TokenMethods:requestDestructionAnimation()
    -- Validate current state
    if self.status == Constants.TokenStatus.DISSOLVING or self.status == Constants.TokenStatus.POOLED then
        print("[TOKEN LIFECYCLE] Token is already dissolving or pooled")
        return false
    end
    
    -- Set animation flags
    self.isAnimating = true
    self.dissolving = true  -- For backward compatibility
    
    -- Set animation parameters
    self.dissolveTime = 0
    self.dissolveMaxTime = 0.8  -- Dissolution animation duration
    self.dissolveScale = self.scale or 1.0
    self.initialX = self.x
    self.initialY = self.y
    
    -- Store callback to be called when animation completes
    self.animationCallback = function() self:finalizeDestruction() end
    
    -- Change state to DISSOLVING
    self:setState(Constants.TokenStatus.DISSOLVING)
    
    -- Create visual particle effects at the token's position using events
    if not self.exploding and self.gameState then
        self.exploding = true
        
        -- Get token color based on its type
        local colorTable = Constants.getColorForTokenType(self.type)
        
        -- Create an EFFECT event instead of calling VFX directly
        if self.gameState.eventRunner then
            local event = {
                type = "EFFECT",
                source = "token",
                target = Constants.TargetType.SELF, -- Not targeting a wizard
                effectType = Constants.VFXType.IMPACT,
                duration = 0.7,
                vfxParams = {
                    x = self.x,  -- Pass coordinates directly in vfxParams
                    y = self.y,
                    color = colorTable,
                    particleCount = 15,
                    radius = 30,
                    tokenType = self.type
                }
            }
            
            -- Process the event immediately
            self.gameState.eventRunner.processEvents({event}, self, nil)
        else
            print("[TOKEN LIFECYCLE] Warning: No eventRunner in gameState for token VFX")
        end
    end
    
    return true
end

-- Finalize return to pool after animation (first phase)
function TokenMethods:finalizeReturn()
    -- Validate current state
    if self.status ~= Constants.TokenStatus.RETURNING then
        print("[TOKEN LIFECYCLE] WARNING: Can only finalize return from RETURNING state, not " .. (self.status or "nil"))
        return false
    end
    
    -- Reset some animation flags but keep isAnimating true for orbit animation
    self.returning = false  -- For backward compatibility
    
    -- Clear wizard/spell references
    self.wizardOwner = nil
    self.spellSlot = nil
    self.tokenIndex = nil
    
    -- Get the ManaPool instance from the token's game state or another reference
    local manaPool = self.manaPool
    if not manaPool then
        print("[TOKEN LIFECYCLE] ERROR: Cannot find manaPool reference to finalize token return!")
        return false
    end
    
    -- Choose a random valence for the token's destination
    local valenceIndex = math.random(1, #manaPool.valences)
    local valence = manaPool.valences[valenceIndex]
    self.valenceIndex = valenceIndex
    
    -- Calculate a random angle for the token's destination
    -- We'll use a random angle rather than the current angle to ensure
    -- tokens don't all follow the same path
    local angle = math.random() * math.pi * 2
    self.orbitAngle = angle
    
    -- Calculate target position based on valence
    local targetX = manaPool.x + math.cos(angle) * valence.radiusX
    local targetY = manaPool.y + math.sin(angle) * valence.radiusY
    
    -- Add slight position variation to the target
    local variationX = math.random(-2, 2)
    local variationY = math.random(-1, 1)
    
    -- Store current position (center of pool) as start for orbit animation
    self.startOrbitX = self.x
    self.startOrbitY = self.y
    
    -- Store target position for orbit animation
    self.targetOrbitX = targetX + variationX
    self.targetOrbitY = targetY + variationY
    
    -- Set up orbit animation parameters
    self.orbitAnimTime = 0
    self.orbitAnimDuration = 0.8  -- Slightly faster than return animation
    
    -- Set an animation callback for when the orbit animation completes
    self.animationCallback = function() self:finalizeOrbit() end
    
    -- Set transitioning to orbit state
    self:setState(Constants.TokenStatus.ORBITING)
    
    -- Randomize orbit direction and speed
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    self.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    self.originalSpeed = self.orbitSpeed
    
    -- Initialize valence properties
    self.valenceJumpTimer = 2 + math.random() * 8
    self.inValenceTransition = false
    self.valenceTransitionTime = 0
    self.valenceTransitionDuration = 0.8
    self.sourceValenceIndex = valenceIndex
    self.targetValenceIndex = valenceIndex
    self.sourceRadiusX = valence.radiusX
    self.sourceRadiusY = valence.radiusY
    self.targetRadiusX = valence.radiusX
    self.targetRadiusY = valence.radiusY
    self.currentRadiusX = valence.radiusX
    self.currentRadiusY = valence.radiusY
    
    -- Visual variance
    self.scale = 0.85 + math.random() * 0.3
    self.zOrder = math.random()
    
    return true
end

-- Finalize orbit transition (second phase)
function TokenMethods:finalizeOrbit()
    -- Validate current state
    if self.status ~= Constants.TokenStatus.ORBITING then
        print("[TOKEN LIFECYCLE] WARNING: Can only finalize orbit from ORBITING state, not " .. (self.status or "nil"))
        return false
    end
    
    -- Reset animation flags
    self.isAnimating = false
    
    -- Get the ManaPool instance from the token's game state or another reference
    local manaPool = self.manaPool
    if not manaPool then
        print("[TOKEN LIFECYCLE] ERROR: Cannot find manaPool reference to finalize token orbit!")
        return false
    end
    
    -- Update position to make sure it's at the target
    self.x = self.targetOrbitX
    self.y = self.targetOrbitY

    -- Ensure scale is finalized
    if self.targetScale then
        self.scale = self.targetScale
    else
        self.scale = 0.85 + math.random() * 0.3
    end
    
    -- Clean up orbit animation properties
    self.startOrbitX = nil
    self.startOrbitY = nil
    self.targetOrbitX = nil
    self.targetOrbitY = nil
    self.orbitAnimTime = nil
    self.orbitAnimDuration = nil
    
    -- Set state to FREE
    self:setState(Constants.TokenStatus.FREE)
    
    -- Set transition flags for smooth animation of orbital motion
    self.transitionTime = 0
    self.transitionDuration = 0.4  -- Shorter orbital transition (was 1.0)
    self.inTransition = true
    
    return true
end

-- Initialize conjured token appearance animation
function TokenMethods:requestAppearAnimation(fromWizard)
    -- Set up animation parameters
    self.isAnimating = true
    
    -- Store the source position (wizard position)
    self.startX = fromWizard.x
    self.startY = fromWizard.y - 40  -- Start a little above the wizard
    
    -- Initialize animation timing
    self.appearAnimTime = 0
    self.appearAnimDuration = 0.7  -- Slightly longer than return animation
    
    -- Set the target scale
    self.targetScale = 0.85 + math.random() * 0.3
    
    -- Start very small
    self.scale = 0.1
    
    -- Initial position is at the wizard
    self.x = self.startX
    self.y = self.startY
    
    -- Prepare callback for when animation completes
    self.animationCallback = function() self:finalizeAppear() end
    
    -- Set status to APPEARING
    self:setState(Constants.TokenStatus.APPEARING)
    
    return true
end

-- Finalize appear animation and transition to orbiting
function TokenMethods:finalizeAppear()
    -- Validate current state
    if self.status ~= Constants.TokenStatus.APPEARING then
        print("[TOKEN LIFECYCLE] WARNING: Can only finalize appear from APPEARING state, not " .. (self.status or "nil"))
        return false
    end
    
    -- Maintain animation flag
    self.isAnimating = true
    
    -- Get the ManaPool instance from the token's game state
    local manaPool = self.manaPool
    if not manaPool then
        print("[TOKEN LIFECYCLE] ERROR: Cannot find manaPool reference to finalize token appearance!")
        return false
    end
    
    -- Choose a random valence for the token's destination
    local valenceIndex = math.random(1, #manaPool.valences)
    local valence = manaPool.valences[valenceIndex]
    self.valenceIndex = valenceIndex
    
    -- Calculate a random angle for the token's destination
    local angle = math.random() * math.pi * 2
    self.orbitAngle = angle
    
    -- Calculate target position based on valence
    local targetX = manaPool.x + math.cos(angle) * valence.radiusX
    local targetY = manaPool.y + math.sin(angle) * valence.radiusY
    
    -- Add slight position variation to the target
    local variationX = math.random(-2, 2)
    local variationY = math.random(-1, 1)
    
    -- Store current position (center of pool) as start for orbit animation
    self.startOrbitX = self.x
    self.startOrbitY = self.y
    
    -- Store target position for orbit animation
    self.targetOrbitX = targetX + variationX
    self.targetOrbitY = targetY + variationY
    
    -- Set up orbit animation parameters
    self.orbitAnimTime = 0
    self.orbitAnimDuration = 0.8  -- Slightly faster than return animation
    
    -- Set an animation callback for when the orbit animation completes
    self.animationCallback = function() self:finalizeOrbit() end
    
    -- Set transitioning to orbit state
    self:setState(Constants.TokenStatus.ORBITING)
    
    -- Randomize orbit direction and speed
    local direction = math.random(0, 1) * 2 - 1  -- -1 or 1
    self.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    self.originalSpeed = self.orbitSpeed
    
    -- Initialize valence properties
    self.valenceJumpTimer = 2 + math.random() * 8
    self.inValenceTransition = false
    self.valenceTransitionTime = 0
    self.valenceTransitionDuration = 0.8
    self.sourceValenceIndex = valenceIndex
    self.targetValenceIndex = valenceIndex
    self.sourceRadiusX = valence.radiusX
    self.sourceRadiusY = valence.radiusY
    self.targetRadiusX = valence.radiusX
    self.targetRadiusY = valence.radiusY
    self.currentRadiusX = valence.radiusX
    self.currentRadiusY = valence.radiusY

    -- Visual variance set during appearing animation
    self.scale = self.targetScale
    self.zOrder = math.random()
    
    return true
end

-- Finalize token destruction and release to pool
function TokenMethods:finalizeDestruction()
    -- Validate current state
    if self.status ~= Constants.TokenStatus.DISSOLVING then
        print("[TOKEN LIFECYCLE] WARNING: Can only finalize destruction from DISSOLVING state, not " .. (self.status or "nil"))
        return false
    end
    
    -- Reset animation flags
    self.isAnimating = false
    self.dissolving = false  -- For backward compatibility
    
    -- Set new state
    self:setState(Constants.TokenStatus.POOLED)
    
    -- Get the token's index in the mana pool
    local found = false
    local manaPool = self.manaPool
    local index = nil
    
    if not manaPool then
        print("[TOKEN LIFECYCLE] ERROR: Cannot find manaPool reference to finalize token destruction!")
        return false
    end
    
    for i, t in ipairs(manaPool.tokens) do
        if t == self then
            index = i
            found = true
            break
        end
    end
    
    if found and index then
        -- Remove the token from the mana pool's token list
        table.remove(manaPool.tokens, index)
    else
        print("[TOKEN LIFECYCLE] WARNING: Token not found in manaPool.tokens during finalization!")
    end
    
    -- Release the token back to the object pool
    Pool.release("token", self)
    
    return true
end

-- Token reset function for the pool
function ManaPool.resetToken(token)
    -- Remove all methods first
    for name, _ in pairs(TokenMethods) do
        token[name] = nil
    end
    
    -- Clear token trails if they exist
    if token.manaPool and token.manaPool.tokenTrails and token.manaPool.tokenTrails[token] then
        token.manaPool.tokenTrails[token] = nil
    end
    
    -- Clear all references and fields
    token.type = nil
    token.image = nil
    token.x = nil
    token.y = nil
    token.state = nil
    token.status = nil  -- New field for the state machine
    token.isAnimating = nil  -- New field to track animation state
    token.animationCallback = nil  -- New field for animation completion callback
    token.originalStatus = nil  -- To store the state before transitions
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
    token.scale = nil
    token.targetScale = nil
    token.zOrder = nil
    
    -- Clear animation-specific fields
    token.startOrbitX = nil
    token.startOrbitY = nil
    token.targetOrbitX = nil
    token.targetOrbitY = nil
    token.orbitAnimTime = nil
    token.orbitAnimDuration = nil
    token.appearAnimTime = nil
    token.appearAnimDuration = nil
    token.startX = nil
    token.startY = nil
    token.originalSpeed = nil
    token.wizardOwner = nil
    token.spellSlot = nil
    token.dissolving = nil
    token.gameState = nil
    token.manaPool = nil  -- New field to reference the mana pool
    token.id = nil  -- New field for tracking tokens
    
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
    self.tokenTrails = {} -- Clear token trails when clearing the pool
end

-- Standard token addition - creates token directly at its final position
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
    
    -- Create a new token from the pool
    local token = Pool.acquire("token")
    
    -- Add methods from TokenMethods table
    for name, method in pairs(TokenMethods) do
        token[name] = method
    end
    
    -- Initialize basic properties
    token.type = tokenType
    token.image = tokenImage
    token.x = x + variationX
    token.y = y + variationY
    
    -- Initialize state machine properties
    token.status = Constants.TokenStatus.FREE
    token.state = Constants.TokenState.FREE -- For backwards compatibility
    token.isAnimating = false
    token.manaPool = self -- Reference to this mana pool instance
    token.id = #self.tokens + 1
    
    token.valenceIndex = valenceIndex
    token.orbitAngle = angle
    token.orbitSpeed = valence.baseSpeed * (0.8 + math.random() * 0.4) * direction
    
    -- Visual effects
    token.pulsePhase = math.random() * math.pi * 2
    token.pulseSpeed = 2 + math.random() * 3
    token.rotAngle = math.random() * math.pi * 2
    token.rotSpeed = math.random(-2, 2) * 0.5
    
    -- Valence jump timer
    token.valenceJumpTimer = 2 + math.random() * 8
    
    -- Valence transition properties
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
    
    -- Size variation for visual interest
    token.scale = 0.85 + math.random() * 0.3
    
    -- Depth/z-order variation
    token.zOrder = math.random()
    
    token.originalSpeed = token.orbitSpeed
    
    -- If game state is available, store it for VFX access
    if self.gameState then
        token.gameState = self.gameState
    end
    
    -- Add to the pool's token list
    table.insert(self.tokens, token)
    
    return token
end

-- Add token with appearance animation from wizard
function ManaPool:addTokenWithAnimation(tokenType, imagePath, sourceWizard)
    if not sourceWizard then
        -- Fall back to regular addition if no wizard provided
        return self:addToken(tokenType, imagePath)
    end
    
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
    
    -- Create a new token with animation-ready properties
    local token = Pool.acquire("token")
    
    -- Add methods from TokenMethods table
    for name, method in pairs(TokenMethods) do
        token[name] = method
    end
    
    -- Initialize basic properties
    token.type = tokenType
    token.image = tokenImage
    
    -- Position will be set by animation
    token.x = sourceWizard.x
    token.y = sourceWizard.y - 40 -- Start slightly above wizard
    
    -- Initialize state machine properties
    token.status = nil -- Will be set to APPEARING by requestAppearAnimation
    token.state = Constants.TokenState.FREE -- For backwards compatibility
    token.isAnimating = true
    token.manaPool = self  -- Reference to this mana pool instance
    token.id = #self.tokens + 1
    
    -- Visual effects
    token.pulsePhase = math.random() * math.pi * 2
    token.pulseSpeed = 2 + math.random() * 3
    token.rotAngle = math.random() * math.pi * 2
    token.rotSpeed = math.random(-2, 2) * 0.5
    
    -- Scale starts small and grows during animation
    token.scale = 0.1
    
    -- If game state is available, store it for VFX access
    if self.gameState then
        token.gameState = self.gameState
    end
    
    -- Add to the pool's token list
    table.insert(self.tokens, token)
    
    -- Start appearance animation
    token:requestAppearAnimation(sourceWizard)
    
    return token
end

-- Removed token repulsion system, reverting to pure orbital motion

function ManaPool:update(dt)
    -- Update token positions and states
    for i = #self.tokens, 1, -1 do
        local token = self.tokens[i]
        
        -- Skip updating POOLED tokens, they've been reset and their properties are nil
        if token.status == Constants.TokenStatus.POOLED then
            goto continue_token
        end
        
        -- Update token trail position history
        if not self.tokenTrails[token] then
            self.tokenTrails[token] = {}
        end
        
        -- Only add a new trail point if the token has moved significantly
        local lastPosition = self.tokenTrails[token][1]
        local shouldAddTrail = true
        
        if lastPosition then
            -- Calculate distance moved since last trail point
            local dx = token.x - lastPosition.x
            local dy = token.y - lastPosition.y
            local distSquared = dx*dx + dy*dy
            
            -- Only add trail points if moved more than a minimum distance
            shouldAddTrail = distSquared > 4
        end
        
        if shouldAddTrail then
            -- Store new position at the beginning of history array
            table.insert(self.tokenTrails[token], 1, {
                x = token.x, 
                y = token.y, 
                time = love.timer.getTime()
            })
            
            -- Limit trail length
            if #self.tokenTrails[token] > self.trailLength then
                table.remove(self.tokenTrails[token])
            end
        end
        
        -- Update token based on its status in the state machine
        if token.status == Constants.TokenStatus.FREE then
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
            if token.pulsePhase and token.pulseSpeed then
                token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            end
            
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
            if token.rotAngle and token.rotSpeed then
                token.rotAngle = token.rotAngle + token.rotSpeed * dt
                if math.random() < 0.002 then  -- Small chance to reverse rotation
                    token.rotSpeed = -token.rotSpeed
                end
            end
            
        elseif token.status == Constants.TokenStatus.CHANNELED or token.status == Constants.TokenStatus.SHIELDING then
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
                    local isNear = wizard.gameState and wizard.gameState.rangeState == Constants.RangeState.NEAR
                    
                    -- Apply the same NEAR/FAR offset logic as in the wizard's draw function
                    local isLeft = true
                    if wizard.gameState and wizard.gameState.wizards then
                        for _, other in ipairs(wizard.gameState.wizards) do
                            if other ~= wizard then
                                isLeft = wizard.x <= other.x
                                break
                            end
                        end
                    end
                    if isLeft then
                        xOffset = isNear and 60 or 0
                    else
                        xOffset = isNear and -60 or 0
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
            
            -- Update common pulse
            if token.pulsePhase and token.pulseSpeed then
                token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            end
            
        elseif token.status == Constants.TokenStatus.RETURNING then
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
                -- Token has reached the pool - call the animation callback
                if token.animationCallback then
                    token.animationCallback()
                else
                    print("[MANAPOOL] WARNING: No animation callback defined for returning token")
                    -- Fallback for backward compatibility
                    token:setState(Constants.TokenStatus.FREE)
                end
            end
            
            -- Update common pulse
            if token.pulsePhase and token.pulseSpeed then
                token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            end
            
        elseif token.status == Constants.TokenStatus.APPEARING then
            -- Token is being animated into existence from a wizard to the mana pool
            token.appearAnimTime = token.appearAnimTime + dt
            local progress = math.min(1, token.appearAnimTime / token.appearAnimDuration)
            
            -- Ease in-out function for smoother animation
            progress = progress < 0.5 and 4 * progress * progress * progress 
                        or 1 - math.pow(-2 * progress + 2, 3) / 2
            
            -- Calculate current position based on bezier curve for arcing motion
            local x0 = token.startX
            local y0 = token.startY
            local x3 = self.x  -- Center of mana pool
            local y3 = self.y
            
            -- Calculate higher arc height for appearing tokens
            local height = 80 -- Higher arc for appearing tokens
            
            -- Control points for bezier (creating an arc)
            local midX = (x0 + x3) / 2
            local midY = (y0 + y3) / 2 - height  -- Negative for upward arc
            
            -- Quadratic bezier calculation
            local t = progress
            local u = 1 - t
            token.x = u*u*x0 + 2*u*t*midX + t*t*x3
            token.y = u*u*y0 + 2*u*t*midY + t*t*y3
            
            -- Gradual scaling up with progress
            local startScale = 0.1  -- Start very small
            local endScale = token.targetScale or 1.0
            token.scale = startScale + (endScale - startScale) * progress
            
            -- Update token rotation during flight - spin faster while appearing
            token.rotAngle = token.rotAngle + dt * 10
            
            -- Check if animation is complete
            if token.appearAnimTime >= token.appearAnimDuration then
                -- Token has reached the pool center - transition to orbiting
                token.animationCallback()
            end
            
            -- Update common pulse
            if token.pulsePhase and token.pulseSpeed then
                token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            end
            
        elseif token.status == Constants.TokenStatus.ORBITING then
            -- Token is in second phase of return, animating from pool center to orbit position
            token.orbitAnimTime = token.orbitAnimTime + dt
            local progress = math.min(1, token.orbitAnimTime / token.orbitAnimDuration)
            
            -- Ease in-out function for smoother animation
            progress = progress < 0.5 and 4 * progress * progress * progress 
                        or 1 - math.pow(-2 * progress + 2, 3) / 2
            
            -- Calculate current position based on bezier curve for arcing motion
            local x0 = token.startOrbitX
            local y0 = token.startOrbitY
            local x3 = token.targetOrbitX
            local y3 = token.targetOrbitY
            
            -- Control points for bezier (creating an arc)
            -- Make the arc go outward in the direction of the target
            local dx = x3 - x0
            local dy = y3 - y0
            local dist = math.sqrt(dx*dx + dy*dy)
            local nx = dx / dist  -- Normalized direction vector
            local ny = dy / dist
            
            -- Control point perpendicular to the path with a height proportional to distance
            local arcHeight = math.min(dist * 0.4, 35)  -- Cap the arc height
            local midX = (x0 + x3) / 2 + ny * arcHeight  -- Perpendicular offset
            local midY = (y0 + y3) / 2 - nx * arcHeight
            
            -- Quadratic bezier calculation
            local t = progress
            local u = 1 - t
            token.x = u*u*x0 + 2*u*t*midX + t*t*x3
            token.y = u*u*y0 + 2*u*t*midY + t*t*y3
            
            -- Update token rotation during flight - spin faster but not as fast as returning
            token.rotAngle = token.rotAngle + dt * 5
            
            -- Check if animation is complete
            if token.orbitAnimTime >= token.orbitAnimDuration then
                -- Token has reached its orbit position - call the animation callback
                if token.animationCallback then
                    token.animationCallback()
                else
                    print("[MANAPOOL] WARNING: No animation callback defined for orbiting token")
                    -- Fallback
                    token:setState(Constants.TokenStatus.FREE)
                end
            end
            
            -- Update common pulse
            if token.pulsePhase and token.pulseSpeed then
                token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
            end
            
        elseif token.status == Constants.TokenStatus.DISSOLVING then
            -- Update dissolution animation
            token.dissolveTime = token.dissolveTime + dt
            
            -- When dissolution is complete, call the animation callback
            if token.dissolveTime >= token.dissolveMaxTime then
                -- Execute the callback to finalize destruction
                if token.animationCallback then
                    token.animationCallback()
                else
                    print("[MANAPOOL] WARNING: No animation callback defined for dissolving token")
                    -- No fallback needed; token will be removed on the next frame
                end
            end
            
        end
        
        -- Update common properties for all tokens (moved inside the token loop)
        if token.pulsePhase and token.pulseSpeed then
            token.pulsePhase = token.pulsePhase + token.pulseSpeed * dt
        end
        
        ::continue_token::
    end
end

function ManaPool:drawToken(token)
    -- Skip drawing POOLED tokens (should not happen if called correctly, but good safeguard)
    if token.status == Constants.TokenStatus.POOLED then
        return
    end
    
    -- Draw trailing effect behind the token first (similar to main menu tokens)
    if self.tokenTrails[token] and #self.tokenTrails[token] > 2 then
        local colorTable = Constants.getColorForTokenType(token.type)
        local stepSize = (#self.tokenTrails[token] > 20) and 2 or 1
        
        for j = #self.tokenTrails[token], 2, -stepSize do
            local pos = self.tokenTrails[token][j]
            local time = love.timer.getTime()
            local timeDiff = time - pos.time
            
            -- Calculate fade based on position in trail (older = more transparent)
            local trailAlpha = 0.2 * (1 - (j / self.trailLength)^1.5)
            
            -- Trail size based on position (older = smaller)
            local trailScale = 12 * (1 - (j / self.trailLength) * 0.6)
            
            -- Adjust trail appearance based on token state
            if token.status == Constants.TokenStatus.APPEARING then
                -- Enhanced trail for appearing tokens (brightest)
                trailAlpha = trailAlpha * 1.8
                trailScale = trailScale * 1.4
            elseif token.status == Constants.TokenStatus.RETURNING then
                -- Enhanced trail for returning tokens
                trailAlpha = trailAlpha * 1.5
                trailScale = trailScale * 1.2
            elseif token.status == Constants.TokenStatus.ORBITING then
                -- Enhanced trail for orbiting tokens
                trailAlpha = trailAlpha * 1.3
                trailScale = trailScale * 1.1
            elseif token.status ~= Constants.TokenStatus.FREE then
                -- Reduce trails for other token states
                trailAlpha = trailAlpha * 0.7
                trailScale = trailScale * 0.7
            end
            
            -- Draw trail particle
            love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], trailAlpha)
            love.graphics.circle("fill", pos.x, pos.y, trailScale)
        end
    end
    
    -- Draw a larger, more vibrant glow around the token based on its type
    local glowSize = 15 -- Larger glow radius
    local glowIntensity = 0.6  -- Stronger glow intensity
    
    -- Multiple glow layers for more visual interest
    for layer = 1, 2 do
        local layerSize = glowSize * (1.2 - layer * 0.3)
        local layerIntensity = glowIntensity * (layer == 1 and 0.4 or 0.8)
        
        -- Increase glow for tokens in transition (newly returned to pool)
        if token.status == Constants.TokenStatus.FREE and token.inTransition then
            -- Stronger glow that fades over the transition period
            local transitionBoost = 0.6 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
            layerSize = layerSize * (1 + transitionBoost * 0.5)
            layerIntensity = layerIntensity + transitionBoost * 0.5
        end
        
        -- Special visual effects for APPEARING tokens
        if token.status == Constants.TokenStatus.APPEARING then
            -- Intense, bright glow for appearing tokens
            local appearProgress = token.appearAnimTime / token.appearAnimDuration
            layerSize = layerSize * (1.4 + appearProgress * 1.0) -- Extra large glow
            layerIntensity = layerIntensity + appearProgress * 0.6 -- Very bright
        -- Special visual effects for RETURNING tokens
        elseif token.status == Constants.TokenStatus.RETURNING then
            -- Bright, trailing glow for returning tokens
            local returnProgress = token.animTime / token.animDuration
            layerSize = layerSize * (1.2 + returnProgress * 0.8) -- Growing glow
            layerIntensity = layerIntensity + returnProgress * 0.4 -- Brightening
        end
        
        -- Special visual effects for DISSOLVING tokens
        if token.status == Constants.TokenStatus.DISSOLVING then
            -- Fading, expanding glow for dissolving tokens
            local dissolveProgress = token.dissolveTime / token.dissolveMaxTime
            layerSize = layerSize * (1 + dissolveProgress) -- Expanding glow
            layerIntensity = layerIntensity * (1 - dissolveProgress * 0.8) -- Fading
        end
        
        -- Set glow color based on token type with improved contrast and vibrancy
        local colorTable = Constants.getColorForTokenType(token.type)
        love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], layerIntensity)
        
        -- Draw glow with pulsation
        local pulseAmount = 0.7 + 0.3 * math.sin(token.pulsePhase * 0.5)
        
        -- Enhanced pulsation for transitioning tokens
        if token.status == Constants.TokenStatus.FREE and token.inTransition then
            pulseAmount = pulseAmount + 0.3 * math.sin(token.transitionTime * 10)
        end
        
        -- Enhanced pulsation for returning tokens
        if token.status == Constants.TokenStatus.RETURNING then
            pulseAmount = pulseAmount + 0.4 * math.sin(token.animTime * 15)
        end
        
        love.graphics.circle("fill", token.x, token.y, layerSize * pulseAmount * token.scale)
    end
    
    -- Draw a small outer ring for better definition
    if token.status == Constants.TokenStatus.FREE then
        local ringAlpha = 0.4 + 0.2 * math.sin(token.pulsePhase * 0.8)
        
        -- Set ring color based on token type
        local colorTable = Constants.getColorForTokenType(token.type)
        love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], ringAlpha)
        
        love.graphics.circle("line", token.x, token.y, (glowSize + 3) * token.scale)
    end
    
    -- Draw a trailing effect for returning tokens
    if token.status == Constants.TokenStatus.RETURNING then
        local progress = token.animTime / token.animDuration
        local trailAlpha = 0.6 * (1 - progress)
        
        -- Set trail color based on token type
        local colorTable = Constants.getColorForTokenType(token.type)
        love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], trailAlpha)
        
        -- Draw the trail as small circles along the bezier path
        local numTrailPoints = 6
        for i = 0, numTrailPoints do
            local trailProgress = progress - (i / numTrailPoints) * 0.25  -- Trail behind the token
            
            -- Only draw trail points that are within the animation progress
            if trailProgress > 0 and trailProgress < 1 then
                -- Calculate position along the bezier path
                local x0 = token.startX
                local y0 = token.startY
                local x3 = self.x  -- End at center of mana pool
                local y3 = self.y
                
                -- Control points for bezier curve
                local midX = (x0 + x3) / 2
                local midY = (y0 + y3) / 2 - 50  -- Arc height
                
                -- Quadratic bezier calculation
                local t = trailProgress
                local u = 1 - t
                local trailX = u*u*x0 + 2*u*t*midX + t*t*x3
                local trailY = u*u*y0 + 2*u*t*midY + t*t*y3
                
                -- Draw trail point with decreasing size
                local pointSize = (numTrailPoints - i) / numTrailPoints * 8 * token.scale
                love.graphics.circle("fill", trailX, trailY, pointSize)
            end
        end
    end
    
    -- Draw token image based on state
    if token.status == Constants.TokenStatus.FREE then
        -- Free tokens are fully visible
        -- If token is in transition (just returned to pool), add a subtle glow effect
        if token.inTransition then
            local transitionGlow = 0.2 + 0.8 * (1 - token.transitionTime / token.transitionDuration)
            love.graphics.setColor(1, 1, 1 + transitionGlow * 0.5, 1)  -- Slightly blue-white glow during transition
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
    elseif token.status == Constants.TokenStatus.CHANNELED then
        -- Channeled tokens are fully visible
        love.graphics.setColor(1, 1, 1, 1)
    elseif token.status == Constants.TokenStatus.SHIELDING then
        -- Shielding tokens have a slight colored tint based on their type
        local colorTable = Constants.getColorForTokenType(token.type)
        -- Use the color from Constants, but keep alpha = 1 for the tint
        love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], 1)
    elseif token.status == Constants.TokenStatus.RETURNING then
        -- Returning tokens have a bright, energetic glow
        local returnGlow = 0.3 + 0.7 * math.sin(token.animTime * 15)
        love.graphics.setColor(1, 1, 1, 0.8 + returnGlow * 0.2)
    elseif token.status == Constants.TokenStatus.DISSOLVING then
        -- Dissolving tokens fade out
        -- Calculate progress of the dissolve animation
        local progress = token.dissolveTime / token.dissolveMaxTime
        
        -- Fade out by decreasing alpha
        local alpha = (1 - progress) * 0.8
        
        -- Get token color based on its type for the fade effect
        local colorTable = Constants.getColorForTokenType(token.type)
        love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], alpha)
    else
        -- For legacy compatibility - handle any other states (like "DESTROYED")
        -- Check for dissolving flag for backwards compatibility
        if token.dissolving then
            local progress = token.dissolveTime / token.dissolveMaxTime
            local alpha = (1 - progress) * 0.8
            love.graphics.setColor(1, 1, 1, alpha)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
    
    -- Draw the token with dynamic scaling
    if token.status == Constants.TokenStatus.DISSOLVING then
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
    
    -- Draw additional effects for non-POOLED tokens only
    if token.status ~= Constants.TokenStatus.POOLED then
        -- Draw shield effect for shielding tokens
        if token.status == Constants.TokenStatus.SHIELDING then
            -- Get token color based on its mana type
            local colorTable = Constants.getColorForTokenType(token.type)
            local shieldBaseAlpha = 0.3 -- Keep the original base alpha
            
            -- Draw a subtle shield aura with slight pulsation
            local pulseScale = 0.9 + math.sin(love.timer.getTime() * 2) * 0.1
            love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], shieldBaseAlpha)
            love.graphics.circle("fill", token.x, token.y, 15 * pulseScale * token.scale)
            
            -- Draw shield border
            love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], 0.5) -- Keep original border alpha
            love.graphics.circle("line", token.x, token.y, 15 * pulseScale * token.scale)
        end
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
        -- Safe sorting - handle nil zOrder values
        local zOrderA = a.token.zOrder or 0
        local zOrderB = b.token.zOrder or 0
        return zOrderA > zOrderB
    end)
    
    -- Draw tokens in sorted order, skipping those attached to wizards
    for _, tokenData in ipairs(sortedTokens) do
        local token = tokenData.token
        
        -- Only draw tokens that are NOT CHANNELED or SHIELDING
        if token.status ~= Constants.TokenStatus.CHANNELED and 
           token.status ~= Constants.TokenStatus.SHIELDING then
            self:drawToken(token)
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
        if token.type == tokenType and token.status == Constants.TokenStatus.FREE then
            return token, i  -- Return token and its index without changing state
        end
    end
    return nil  -- No token available
end

function ManaPool:getToken(tokenType)
    -- Find a free token of the specified type that's not in transition
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.status == Constants.TokenStatus.FREE and
           not token.returning and not token.inTransition then
            -- Mark as being used (using setState for state machine)
            token:setState(Constants.TokenStatus.CHANNELED)
            return token, i  -- Return token and its index
        end
    end
    
    -- Second pass - try with less strict requirements if nothing was found
    for i, token in ipairs(self.tokens) do
        if token.type == tokenType and token.status == Constants.TokenStatus.FREE then
            if token.returning then
                print("[MANAPOOL] WARNING: Using token in return animation - visual glitches may occur")
            elseif token.inTransition then
                print("[MANAPOOL] WARNING: Using token in transition state - visual glitches may occur")
            end
            
            -- Use setState method for state machine transition
            token:setState(Constants.TokenStatus.CHANNELED)
            
            -- Cancel any return animation
            token.returning = false
            token.inTransition = false
            return token, i
        end
    end
    
    return nil  -- No token available
end

function ManaPool:returnToken(tokenIndex)
    -- Return a token to the pool using the new state machine
    if self.tokens[tokenIndex] then
        local token = self.tokens[tokenIndex]
        
        -- Use token's method if available, otherwise fallback to legacy behavior
        if token.requestReturnAnimation then
            token:requestReturnAnimation()
        else
            -- Legacy fallback for tokens that don't have the state machine methods
            print("[MANAPOOL] WARNING: Using legacy return method for token " .. tokenIndex .. " - state machine methods not found")
            
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
            if token.state == Constants.TokenState.SHIELDING or token.state == Constants.TokenState.CHANNELED then
            elseif token.state ~= Constants.TokenState.FREE then
                print("[MANAPOOL] WARNING: Returning token " .. tokenIndex .. " from unexpected state: " .. 
                     (token.state or "nil"))
            end
            
            -- Store current position as start position for return animation
            token.startX = token.x
            token.startY = token.y
            
            -- Set up return animation parameters
            token.targetX = self.x  -- Center of mana pool
            token.targetY = self.y
            token.animTime = 0
            token.animDuration = 0.5 -- Half second return animation
            token.returning = true   -- Flag that this token is returning to the pool
            token.originalState = originalState  -- Remember what state it was in before return
        end
    else
        print("[MANAPOOL] WARNING: Attempted to return invalid token index: " .. tokenIndex)
    end
end

-- This method has been replaced by token:finalizeReturn
-- Kept for backward compatibility with code that hasn't been updated yet
function ManaPool:finalizeTokenReturn(token)
    print("[MANAPOOL] WARNING: ManaPool:finalizeTokenReturn is deprecated, use token:finalizeReturn instead")
    
    -- Just call the token's method if available
    if token.finalizeReturn then
        token:finalizeReturn()
    else
        -- Legacy fallback (simplified)
        token.state = Constants.TokenState.FREE
        token.status = Constants.TokenStatus.FREE
        token.returning = false
        token.wizardOwner = nil
        token.spellSlot = nil
        token.tokenIndex = nil
    end
end

return ManaPool