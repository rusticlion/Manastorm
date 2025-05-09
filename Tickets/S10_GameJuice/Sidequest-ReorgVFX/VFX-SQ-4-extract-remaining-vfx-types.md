Title: Separate Remaining VFX Type Logic (Aura, Beam, Cone, Conjure, 
Surge, Vertical, Meteor, etc.)
Goal: Move update/draw logic for all remaining specific effect types into 
their own files.
Tasks:
Repeat the process from VFX-R8/R9 for each distinct effect type currently 
handled in vfx.lua:
Create vfx/effects/[type_name].lua.
Move update[TypeName] and draw[TypeName] functions.
Return { update = ..., draw = ... }.
Remove originals from vfx.lua.
Require the new module in vfx.lua.
Update VFX.updaters and VFX.drawers accordingly.
Acceptance Criteria:
All effect types update and draw correctly from their dedicated modules.
vfx.lua primarily contains core logic (init, createEffect, main 
update/draw loops, pooling, assets) and the dispatcher setup.
