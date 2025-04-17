~Define & Migrate Movement/Positioning Keywords (Behavior Only)

Goal: Define keywords related to player/opponent movement and positioning.
Tasks:
Identify positioning logic (NEAR/FAR, GROUNDED/AERIAL).
Define keyword entries in keywords.lua for: elevate, ground, rangeShift, 
forcePull.
Populate the behavior table for each (e.g., behavior = { setsCasterState = 
"AERIAL" }, behavior = { togglesRange = true }).
Deliverable: keywords.lua includes definitions for movement/positioning 
keywords with populated behavior tables.~
