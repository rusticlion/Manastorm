Title: Add Secondary Particles & Glow Layers to Base Templates
Goal: Increase visual richness and depth of core effect templates.
Description: Modify base templates (proj_base, impact_base, etc.) to spawn 
secondary, softer/larger/dimmer particles alongside the primary ones.
Tasks:
Modify VFX.initializeParticles in vfx.lua.
For relevant effect types (e.g., "projectile", "impact", "beam"):
Adjust effect.particleCount logic if necessary (e.g., allocate 70% 
primary, 30% secondary).
In the particle creation loop, sometimes create secondary particles (e.g., 
using fireGlow asset, lower alpha, slower speed, different scale 
progression). Store a flag particle.isSecondary = true.
Modify corresponding draw* functions:
Draw secondary particles first (behind primary).
Use different assets/drawing parameters based on particle.isSecondary.
Acceptance Criteria:
Projectiles, impacts, and other core effects have visible softer glow 
layers or slower background particles complementing the main effect.
Performance remains acceptable.
