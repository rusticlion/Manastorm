~Define & Migrate Core Combat Keywords (Behavior Only)

Goal: Populate keywords.lua with initial keywords based on existing core 
combat mechanics found in spells.lua and combat.lua, focusing only on the 
behavior aspect.
Tasks:
Identify core combat actions currently hardcoded (e.g., dealing damage, 
applying stagger).
Define keyword entries in keywords.lua for: damage, stagger, burn (if 
exists).
Populate the behavior table for each. Example for damage: behavior = { 
dealsDamage = true, baseAmount = 10 } (adjust based on actual 
implementation).
Do not add VFX/SFX/description/flags yet.
Deliverable: keywords.lua contains definitions for damage, stagger, burn 
with populated behavior tables reflecting current game logic.~
