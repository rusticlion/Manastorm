Implement Idle Animation Logic
Goal: Update the Wizard's animation state over time.
Tasks:
Modify Wizard:update (wizard.lua):
Add logic to advance the idle animation frame. This should only happen if 
no other primary animation (like casting) is overriding the display.
function Wizard:update(dt)
    -- ... (existing update logic: hitFlashTimer, castFrameTimer, 
positionAnimation, etc.) ...

    -- Update idle animation timer and frame
    -- Only animate idle if not casting or in another special visual state
    if self.castFrameTimer <= 0 then -- Play idle if not in cast animation
        self.idleFrameTimer = self.idleFrameTimer + dt
        if self.idleFrameTimer >= self.idleFrameDuration then
            self.idleFrameTimer = self.idleFrameTimer - 
self.idleFrameDuration -- Subtract to carry over excess time
            self.currentIdleFrame = self.currentIdleFrame + 1
            if self.currentIdleFrame > #self.idleAnimationFrames then
                self.currentIdleFrame = 1 -- Loop animation
            end
        end
    else
        -- If casting, reset idle animation to first frame to look clean 
when cast finishes
        self.currentIdleFrame = 1
        self.idleFrameTimer = 0
    end

    -- ... (rest of Wizard:update logic for status effects, spell slots, 
etc.) ...
end
Use code with caution.
Lua
Acceptance Criteria:
wizard.currentIdleFrame cycles from 1 to 7 (or the number of frames) 
repeatedly.
wizard.idleFrameTimer correctly manages time per frame.
Idle animation is paused/reset if castFrameTimer > 0.
