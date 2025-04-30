Ticket AI-2: Perception Implementation
Goal: Enable the AI to gather necessary information about the current game state.
Tasks:
Implement the OpponentAI:perceive() function.
Inside perceive, access necessary data from self.wizard, self.gameState, and the opponent wizard (self.gameState.wizards[1] if AI is P2). Gather:
Own health, elevation, active spell slot details (which are active, progress, isShield).
Opponent health, elevation, active spell slot details.
gameState.rangeState.
Counts of key mana token types in self.wizard.manaPool (using ManaHelpers).
Return the gathered data in a structured table (e.g., perceptions = { selfHealth = ..., oppHealth = ..., range = ..., mana = {fire=..., moon=...} }).
Call self:perceive() within OpponentAI:update and store the result (initially just print it for debugging).
Acceptance Criteria:
perceive() function returns a table containing relevant, up-to-date game state information.
The perception data is logged or verifiable via debugger during gameplay.
Pitfalls: Avoid trying to perceive everything. Start with the most critical information (health, range, elevation, basic mana counts). Avoid deep copying large tables; extract only necessary values or use references carefully.
