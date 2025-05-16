Implement SelenePersonality Module
Goal: Create the personality module for Selene, encapsulating her current 
hardcoded spell selection logic.
Tasks:
Create ai/personalities/SelenePersonality.lua:
Implement the functions defined in the Personality Interface (from AI-R1).
Move Selene's spell selection logic from the old OpponentAI:decide() and 
cast<Type>Spell() methods into these new functions.
getDefenseSpell: Prioritize spellbook["2"] (Wrap in Moonlight).
getEscapeSpell: Prioritize spellbook["2"] then spellbook["3"] (Moondance).
getAttackSpell: Implement logic to choose between spellbook["123"] (Full 
Moon Beam), spellbook["13"] (Eclipse), spellbook["3"] (Moondance) based on 
perception (e.g., mana, opponent health).
getCounterSpell: Choose between spellbook["13"] (Eclipse) and 
spellbook["3"] (Moondance).
getConjureSpell: Return spellbook["1"] (Conjure Moonlight).
Update AI Initialization (main.lua):
When creating the AI for game.wizards[2] (Selene), pass an instance of 
SelenePersonality:
local SelenePersonality = require("ai.personalities.SelenePersonality")
game.opponentAI = OpponentAI.new(game.wizards[2], game, SelenePersonality)
Use code with caution.
Lua
Acceptance Criteria:
The AI controlling Selene behaves identically to its pre-refactor state.
Selene AI correctly selects and attempts to cast her specific spells based 
on game situations.
