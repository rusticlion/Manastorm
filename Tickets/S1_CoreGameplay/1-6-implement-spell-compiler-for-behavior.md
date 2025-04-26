~ Implement Spell Compiler (Behavior Merging)

Goal: Make compileSpell function correctly merge behavior data from 
multiple keywords.
Tasks:
Implement the logic inside compileSpell(spellDef, keywordData) in 
spellCompiler.lua.
Loop through spellDef.keywords.
For each keyword, fetch its definition from keywordData.
Merge the behavior table from the keyword into a compiledSpell.behavior 
table. Define a clear merge strategy (e.g., simple table merge, last 
keyword wins for conflicting keys, or additive for things like damage 
bonuses).
The function should return a compiledSpell object containing name, cost, 
cooldown (from spellDef) and the merged behavior table.
Deliverable: compileSpell function correctly processes a sample spellDef 
and merges behavior tables from the specified keywords. Add unit tests if 
possible.~
