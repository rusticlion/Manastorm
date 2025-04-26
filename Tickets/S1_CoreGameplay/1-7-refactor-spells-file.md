~ Refactor spells.lua

Goal: Convert all spell definitions in spells.lua to use the new 
keyword-only format.
Tasks:
Go through each spell definition in spells.lua.
Remove all hardcoded behavior logic, VFX calls, SFX triggers etc.
Replace them with a keywords = { ... } list, using the keywords defined in 
keywords.lua.
Keep name, cost, cooldown fields.
Deliverable: spells.lua contains only keyword-based definitions. All 
previous spell logic is now represented by keyword lists.~
