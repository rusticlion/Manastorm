Abstract Core AI Logic & Create Personality Interface
Goal: Refactor OpponentAI.lua to remove hardcoded spell choices and 
delegate character-specific decisions to a new "Personality" system.
Tasks:
Define Personality Interface (ai/PersonalityBase.lua or similar concept):
Outline the functions a personality module must provide, e.g.:
getAttackSpell(ai, perception, spellbook)
getDefenseSpell(ai, perception, spellbook)
getCounterSpell(ai, perception, spellbook)
getEscapeSpell(ai, perception, spellbook)
getConjureSpell(ai, perception, spellbook)
getPositioningSpell(ai, perception, spellbook) (Optional, for 
STATE.POSITION)
These functions should return a specific spell object from the AI's 
spellbook or nil if no suitable spell is found/affordable.
Modify OpponentAI.new(wizard, gameState, personalityModule):
Add personalityModule as a parameter.
Store self.personality = personalityModule.
Refactor OpponentAI:decide():
Remove all direct spellbook["X"] lookups.
When a state (ATTACK, DEFEND, etc.) determines a spell should be cast, 
call the appropriate function from self.personality, passing self, 
self.perception, and self.wizard.spellbook.
Example: if self.currentState == STATE.ATTACK, then local spellToCast = 
self.personality.getAttackSpell(self, p, self.wizard.spellbook).
The decision to cast should still check 
self.wizard:canPayManaCost(spellToCast.cost) and 
self:hasAvailableSpellSlot().
Refactor OpponentAI:castOffensiveSpell(), castDefensiveSpell(), etc.:
These helper methods in OpponentAI:act() should be simplified or removed.
The decide() function will now return specific spells if one is chosen.
act() will primarily handle decision.type == "CAST_SPELL" with 
decision.spell directly.
If decide() returns a more general action like ATTACK_ACTION (without a 
specific spell because the personality couldn't find one), act() can then 
call a generic self.personality.getBestSpellForIntent(STATE.ATTACK, ...) 
or simply do nothing if no spell is forthcoming.
Acceptance Criteria:
OpponentAI.lua no longer contains hardcoded spell IDs for Selene.
OpponentAI:decide() calls methods on a self.personality object to get 
spell suggestions.
The game still runs with the AI (it will be broken until AI-R2 is 
complete, but shouldn't crash due to missing methods if a dummy 
personality is temporarily used).
Design Notes:
The personality module effectively becomes the AI's "brain" for spell 
selection strategy.
The core OpponentAI FSM and perception logic remains generic.
