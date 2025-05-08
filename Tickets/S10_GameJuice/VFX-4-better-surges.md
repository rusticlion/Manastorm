Title: Enhance Surge/Fountain Effects
Goal: Add more detail and stages to surge-type VFX (like Emberlift, 
Conjure).
Description: Incorporate initial flash, rising streaks, and clearer 
particle dissipation.
Tasks:
Modify VFX.updateSurge and VFX.drawSurge (and potentially 
updateConjure/drawConjure).
Initial Flash: In createEffect or initializeParticles for surge/conjure, 
add a small number of very fast, bright particles that fade quickly for an 
initial burst.
Rising Streaks: In drawSurge, add love.graphics.line calls drawing faint 
vertical lines originating from the source and fading with height/time.
Particle Dissipation: Ensure particles clearly shrink and fade towards the 
end of their lifecycle in the update logic.
Acceptance Criteria:
Surge/Conjure effects have a more distinct visual "pop" at the start.
Rising particle streams are visually enhanced.
Particles have a clearer end-of-life visual.
