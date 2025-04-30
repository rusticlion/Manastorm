Ticket AI-4: Action Execution
Goal: Translate the AI's high-level action decision into specific calls to the Wizard API.
Tasks:
Implement the OpponentAI:act(action) function.
Add if/elseif conditions based on action.type returned from decide.
Crucially: For CAST actions (which will be defined in the next ticket), call self.wizard:queueSpell(action.spell). Do NOT simulate key presses.
Implement handlers for placeholder actions from AI-3 (initially, they might just print a message like "AI wants to attack").
Add basic action types like { type = "WAIT" } (does nothing) and { type = "FREE_ALL" } (calls self.wizard:freeAllSpells()).
Call self:act(action) within OpponentAI:update after deciding.
Acceptance Criteria:
The act function receives the action table from decide.
Appropriate wizard methods are called based on the action type (initially verified with prints, later by observing game behavior).
Pitfalls: Using queueSpell directly is essential. Avoid any logic related to keySpell or castKeyedSpell for the AI.