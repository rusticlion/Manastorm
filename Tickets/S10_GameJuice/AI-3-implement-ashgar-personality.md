 Implement AshgarPersonality Module
Goal: Create a new personality module for Ashgar, enabling the AI to 
control him.
Tasks:
Analyze Ashgar's Spellbook (wizard.lua):
"1": Conjure Fire (Conjure)
"2": Nova Conjuring (Resource Management/Setup - harder for AI initially, 
maybe focus on "1" for conjure)
"3": Firebolt (Attack)
"12": Battle Shield (Defense)
"13": Blast Wave (Attack - Zone, good vs NEAR)
"23": Emberlift (Positioning/Utility, Conjure Fire)
"123": Meteor (Attack - Aerial Finisher, requires AERIAL setup)
Create ai/personalities/AshgarPersonality.lua:
Implement the Personality Interface functions for Ashgar.
getDefenseSpell: Prioritize spellbook["12"] (Battle Shield).
getEscapeSpell: Could be spellbook["23"] (Emberlift) for repositioning. If 
low health, might also consider freeAllSpells.
getAttackSpell:
If opponent AERIAL: Maybe spellbook["123"] (Meteor) if self is AERIAL.
If opponent NEAR: spellbook["13"] (Blast Wave).
Default/FAR: spellbook["3"] (Firebolt).
Consider spellbook["123"] (Meteor) as a high-mana option if AI is AERIAL 
and opponent is GROUNDED.
getCounterSpell: Ashgar doesn't have direct counters like Selene's 
Eclipse. Could use Blast Wave to disrupt NEAR, or Emberlift to change 
range/elevation. This might be less effective initially.
getConjureSpell: Prioritize spellbook["1"] (Conjure Fire). Nova Conjuring 
is more complex due to its cost.
getPositioningSpell: spellbook["23"] (Emberlift).
Testing:
Temporarily modify main.lua to assign Ashgar's personality to an AI 
controlling Ashgar (e.g., game.wizards[1] if P2 is human, or set up a 
temporary AI vs AI).
Acceptance Criteria:
An AI controlling Ashgar can select and attempt to cast spells from 
Ashgar's spellbook.
The spell choices are somewhat logical for Ashgar's kit (e.g., uses 
shields defensively, firebolt offensively).
The Ashgar AI functions without errors.
