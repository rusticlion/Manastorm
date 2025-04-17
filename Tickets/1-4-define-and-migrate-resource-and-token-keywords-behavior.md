~Define & Migrate Resource/Token Keywords (Behavior Only)

Goal: Define keywords related to mana token manipulation.
Tasks:
Identify token logic (conjure, dissipate, shift, lock).
Define keyword entries in keywords.lua for: conjure, dissipate, 
tokenShift, lock.
Populate the behavior table for each (e.g., behavior = { addsTokens = 1, 
tokenType = "moon" }, behavior = { locksEnemyPool = true }).
Deliverable: keywords.lua includes definitions for resource/token keywords 
with populated behavior tables.~
