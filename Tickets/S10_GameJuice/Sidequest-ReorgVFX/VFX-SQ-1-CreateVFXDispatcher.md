Title: Create VFX Effect Dispatcher Infrastructure
Goal: Set up the core structure in vfx.lua to dynamically call update/draw 
functions based on effect type.
Description: Before moving individual effect logic, establish the 
dispatcher mechanism that will call the separated functions.
Tasks:
In vfx.lua, create empty tables: VFX.updaters = {} and VFX.drawers = {}.
Modify the main VFX.update loop:
Inside the loop iterating through VFX.activeEffects:
Replace the large if/elseif effect.type == ... block with a dispatcher 
call:
local updater = VFX.updaters[effect.type]
if updater then
    updater(effect, dt)
else
    -- Fallback or warning for unhandled types
    -- print("Warning: No updater found for VFX type: " .. 
tostring(effect.type))
    -- Optionally call a default update function here
end
Use code with caution.
Lua
Modify the main VFX.draw loop similarly, using VFX.drawers[effect.type].
(Temporary): For now, populate VFX.updaters and VFX.drawers by directly 
assigning the existing functions within vfx.lua itself (e.g., 
VFX.updaters["projectile"] = VFX.updateProjectile). This verifies the 
dispatcher works before moving files.
Acceptance Criteria:
The game runs, and all existing VFX update and draw correctly using the 
new dispatcher mechanism.
VFX.updaters and VFX.drawers tables exist and are populated (initially 
with local functions).
The large if/elseif blocks in the main update and draw loops are replaced 
with lookups and function calls.
