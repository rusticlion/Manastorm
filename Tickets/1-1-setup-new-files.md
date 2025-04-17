Ticket #1: Setup Keyword & Compiler Files

Goal: Create the basic file structure for the new system.
Tasks:
Create a new file: keywords.lua. Initialize it with an empty Lua table 
Keywords = {}.
Create a new file: spellCompiler.lua. Define an empty function 
compileSpell(spellDef, keywordData) that currently just returns the input 
spellDef. Require this file where needed (e.g., main.lua or combat.lua).
Ensure both files are correctly loaded by the LÖVE project.
Deliverable: The two new Lua files exist and are integrated into the 
project structure without errors.
