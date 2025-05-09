Title: Separate Projectile VFX Logic
Goal: Move updateProjectile and drawProjectile logic into its own file.
Tasks:
Create directory vfx/effects/.
Create file vfx/effects/projectile.lua.
Move the VFX.updateProjectile and VFX.drawProjectile functions from 
vfx.lua into projectile.lua.
Modify projectile.lua to return a table: return { update = 
updateProjectile, draw = drawProjectile }. Ensure any helper functions 
used only by these two are also moved or handled appropriately.
In vfx.lua:
Remove the original VFX.updateProjectile and VFX.drawProjectile functions.
Add local ProjectileEffect = require("vfx.effects.projectile").
Update the dispatcher population: VFX.updaters["projectile"] = 
ProjectileEffect.update, VFX.drawers["projectile"] = 
ProjectileEffect.draw.
Acceptance Criteria:
Projectile-type VFX (including bolt-base, which uses projectile logic) 
update and draw correctly.
The projectile logic resides entirely within vfx/effects/projectile.lua.
vfx.lua is smaller.
