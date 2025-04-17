~Integrate Compiled Spells into Simulation

Goal: Modify the game simulation (combat.lua or relevant files) to use the 
compiled spell objects instead of the old spells.lua definitions.
Tasks:
Identify where spells are loaded/accessed for casting (e.g., main.lua on 
load, or combat.lua when casting starts).
Call compileSpell for each spell defined in spells.lua at game 
initialization. Store these compiled spell objects (e.g., in a 
CompiledSpells table).
Update functions like castSpell, applyEffect, etc., to read data from 
compiledSpell.behavior (e.g., if compiledSpell.behavior.dealsDamage then 
...) instead of checking spell names or reading directly from the old 
Spells table structure.
Deliverable: The game runs, spells can be cast, and their behavioral 
effects (damage, state changes, token manipulation) work correctly based 
on the data merged by the spellCompiler. Visuals and sounds might be 
broken or missing at this stage. Thorough testing is crucial here.~
