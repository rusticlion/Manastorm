Title: Implement Additive Blending for Core VFX Components
Goal: Enhance visual impact and brightness of key effect elements like 
particle cores, impacts, and beams.
Description: Apply additive blending selectively to make bright parts of 
effects bloom realistically when overlapping or against dark backgrounds.
Tasks:
Identify drawing calls in vfx.lua's draw* functions that render the 
brightest/core components (e.g., inner glow layers, impact flashes, beam 
cores, bright core particles).
Wrap these specific love.graphics.draw or love.graphics.circle calls with:
local prevMode = {love.graphics.getBlendMode()}
love.graphics.setBlendMode("add")
-- ... drawing calls for bright elements ...
love.graphics.setBlendMode(prevMode[1], prevMode[2])
Use code with caution.
Lua
Acceptance Criteria:
Core elements of impacts, projectiles, beams, etc., appear noticeably 
brighter and bloom when overlapping.
Overall visual clarity is maintained (don't make everything additive).
