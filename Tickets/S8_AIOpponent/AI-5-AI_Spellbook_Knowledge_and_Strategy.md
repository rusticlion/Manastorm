Ticket AI-5: Spell Knowledge & Basic Strategy
Goal: Make the AI choose specific spells from its spellbook based on its state and check mana costs.
Tasks:
Refine OpponentAI:decide(perceptions):
Spell Selection: Instead of returning placeholder action types, select an actual spell from self.wizard.spellbook.
If DEFENDING, find a spell with a block keyword (e.g., iterate through self.wizard.spellbook, check if spell.keywords.block exists).
If ATTACKING, find a spell with a damage keyword. Start with the simplest available (e.g., the "1" key spell).
If MANA_GATHERING (add this state if desired), find a conjure spell.
Mana Check: Before returning a { type = "CAST", spell = chosenSpell } action, call self.wizard:canPayManaCost(chosenSpell.cost). If it returns nil (cannot afford), the AI should not choose that spell (it could WAIT or try a cheaper spell/conjure).
Update OpponentAI:act(action) to correctly handle the { type = "CAST", spell = ... } action by calling self.wizard:queueSpell(action.spell).
Acceptance Criteria:
AI attempts to cast spells appropriate to its current state (defensive, offensive).
AI only attempts to cast spells it has the mana for.
AI uses spells defined in its own spellbook.
The AI can be observed successfully casting different spells during gameplay.
Design Notes: Keep spell selection simple initially (e.g., "first available defensive spell"). Can add weights/priorities later. Introduce a simple MANA_GATHERING state if the AI often gets stuck unable to afford anything.