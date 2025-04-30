Ticket AI-1: AI Module Setup & Integration
Goal: Create the fundamental structure for the AI system and integrate it into the main game loop.
Tasks:
Create a new directory ai/.
Create ai/OpponentAI.lua.
Define the basic OpponentAI table structure with empty new, update, perceive, decide, and act functions.
In OpponentAI.new(wizard, gameState), store the wizard (AI's wizard object) and gameState references.
In main.lua (love.load), require ai/OpponentAI and create an instance, storing it in game.opponentAI (e.g., game.opponentAI = OpponentAI.new(game.wizards[2], game)).
In main.lua (love.update, within the "BATTLE" state), add a call to game.opponentAI:update(dt) if game.opponentAI exists.
Add a simple print("AI Update Tick") inside OpponentAI:update for initial verification.
Acceptance Criteria:
The game loads and runs without errors.
The "AI Update Tick" message appears periodically in the console during the BATTLE state.
game.opponentAI holds a valid instance of the AI controller.
Design Notes: Keep this purely structural. No decision logic yet.