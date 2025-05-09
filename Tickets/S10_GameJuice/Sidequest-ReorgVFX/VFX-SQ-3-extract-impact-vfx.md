Title: Separate Impact VFX Logic
Goal: Move updateImpact and drawImpact logic into its own file.
Tasks:
Create file vfx/effects/impact.lua.
Move the VFX.updateImpact and VFX.drawImpact functions from vfx.lua into 
impact.lua.
Modify impact.lua to return { update = updateImpact, draw = drawImpact }.
In vfx.lua:
Remove the original functions.
Require the new module: local ImpactEffect = 
require("vfx.effects.impact").
Update dispatchers: VFX.updaters["impact"] = ImpactEffect.update, 
VFX.drawers["impact"] = ImpactEffect.draw. (Handle other types mapping to 
impact like remote_base, shield_hit_base here or adjust their 
definitions).
Acceptance Criteria:
Impact-type VFX update and draw correctly.
vfx.lua is further reduced in size.
