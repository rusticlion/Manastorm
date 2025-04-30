Ticket AI-3: Basic FSM & Decision Logic
Goal: Implement a rudimentary Finite State Machine (FSM) with simple rules to determine the AI's general intent (e.g., attack, defend).
Tasks:
Define basic AI states as constants within OpponentAI (e.g., local STATE_IDLE = 1, local STATE_ATTACK = 2, local STATE_DEFEND = 3). Add self.currentState = STATE_IDLE in OpponentAI.new.
Implement the OpponentAI:decide(perceptions) function.
Inside decide, implement simple state transition logic based on perceptions:
Example: if perceptions.selfHealth < 40 then self.currentState = STATE_DEFEND
Example: elseif perceptions.oppHealth < 75 then self.currentState = STATE_ATTACK
Example: else self.currentState = STATE_IDLE
Based only on the self.currentState, choose a placeholder action type. Return a simple action description:
If DEFEND: return { type = "DEFEND_ACTION" }
If ATTACK: return { type = "ATTACK_ACTION" }
If IDLE: return { type = "IDLE_ACTION" } (or { type = "WAIT" })
Call self:decide(perceptions) within OpponentAI:update after perceiving. Print the returned action type.
Acceptance Criteria:
The AI transitions between basic states based on simple health thresholds (verified via print statements).
The decide function returns a basic action type corresponding to the current state.
Design Notes: This separates state determination from specific action selection, which comes next. Keep rules extremely simple for now.