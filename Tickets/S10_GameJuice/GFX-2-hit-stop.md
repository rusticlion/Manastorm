Title: Implement Screen Shake & Hitstop
Goal: Add significant physical weight and impact feedback to powerful hits 
or events.
Description: Implement global screen shake and brief update pause 
triggered by specific game events.
Tasks:
Implement Helpers (main.lua or core/CameraUtils.lua):
Create triggerShake(duration, intensity): Sets global variables 
shakeTimer, shakeIntensity.
Create triggerHitstop(duration): Sets global variable hitstopTimer.
Modify love.update (main.lua):
At the very beginning, check if hitstopTimer > 0 then hitstopTimer = 
hitstopTimer - dt; return end.
Decrement shakeTimer if > 0.
Modify love.draw (main.lua):
Before the main love.graphics.push() for scaling:
Calculate shake offset: local offsetX, offsetY = 0, 0. If shakeTimer > 0, 
calculate offsetX = math.random(-shakeIntensity, shakeIntensity), offsetY 
= math.random(-shakeIntensity, shakeIntensity). Gradually reduce 
shakeIntensity as shakeTimer decreases.
Apply this offset using love.graphics.translate(offsetX, offsetY).
Ensure there's a love.graphics.pop() at the very end of love.draw to undo 
this translation.
Trigger from EventRunner.lua:
In relevant handlers (e.g., DAMAGE for high event.amount, potentially 
BLOCKED_DAMAGE, or based on specific event.tags), call triggerShake(...) 
and triggerHitstop(...).
Acceptance Criteria:
The screen visibly shakes for a short duration upon specific high-impact 
events.
The game briefly pauses (hitstop) upon specific high-impact events.
Effects are configurable (duration, intensity).
