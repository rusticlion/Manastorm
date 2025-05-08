Title: Enhance Beam Visuals (Width/Intensity)
Goal: Make beam effects feel more dynamic and powerful.
Description: Vary the beam's width and core intensity over its duration or 
based on parameters.
Tasks:
Modify VFX.updateBeam and VFX.drawBeam in vfx.lua.
In drawBeam, make beamWidth calculation dynamic. Use effect.timer or 
effect.progress with math.sin for pulsing, or potentially read an 
intensity value from effect.options.
Adjust the alpha/color of the inner core line based on the same dynamic 
value to make the intensity fluctuate.
Acceptance Criteria:
Beam effects visually pulse or vary in intensity/width during their 
animation.
