Manastorm AI Opponent - Phase 1: Local Demo Implementation
Version: 1.0
Date: 2025-04-29
1. Context & Goal
Context: Manastorm currently requires two human players. To facilitate local testing, demonstrations, and balancing of core mechanics without needing a second player, a basic AI opponent is required.
Primary Goal: Implement a functional, non-player opponent ("AI") capable of participating in a duel using the existing game mechanics. The AI should provide a minimal level of interaction and challenge, enabling single-player testing and demonstration of the core gameplay loop.
Non-Goals (for this phase): This is not intended to be a highly skilled, human-like, or strategically deep AI. Advanced features like prediction, complex counter-play, learning, or multiple difficulty levels are outside the scope of this initial implementation.
2. Scope
In Scope:
Creating a dedicated AI module (ai/OpponentAI.lua).
Integrating the AI update loop into the main game cycle (main.lua).
Implementing basic perception of critical game state (own/opponent health, range, elevation, basic mana availability).
Implementing a simple Finite State Machine (FSM) with core states (e.g., Idle, Attack, Defend).
Rule-based transitions between AI states based on perceived game state.
Ability for the AI to select spells from its pre-defined spellbook based on its current state.
Ability to check mana costs using the existing Wizard:canPayManaCost function.
Ability to execute actions by directly calling methods on its assigned Wizard object (specifically queueSpell, freeAllSpells).
Basic configuration points (like decision timer interval, health thresholds).
Out of Scope:
Simulating key presses or interacting with the Input module.
Predicting player actions or reacting to player spell casting progress.
Complex strategic planning or resource management beyond basic mana checks.
Learning or adaptive behavior.
Multiple distinct difficulty levels (beyond simple parameter tuning).
AI vs. AI simulations.
3. High-Level Approach: Rule-Based FSM
We will implement a simple Finite State Machine (FSM) combined with rule-based decision-making.
States: The AI will operate in a small number of distinct states (e.g., IDLE, ATTACKING, DEFENDING).
Perception: On a regular interval, the AI will perceive the game state.
Decision: Based on the perceived state and simple rules, the AI will transition between its internal states and select an appropriate action (e.g., "cast defensive spell", "cast offensive spell", "wait").
Action: The AI will execute the chosen action by calling the relevant methods on its Wizard instance.
Rationale: This approach is chosen for its relative simplicity, ease of initial implementation and debugging, clear alignment with the game's existing discrete states (range, elevation), and extensibility for future enhancements. It avoids the complexity of behavior trees or learning systems for this initial phase.
4. Integration Points
Initialization: An OpponentAI instance will be created in main.lua during love.load and associated with one of the Wizard instances (typically game.wizards[2]).
Update Loop: The OpponentAI:update(dt) method will be called from main.lua's love.update function during the BATTLE state.
State Reading: The AI will read data directly from its assigned Wizard object, the opponent Wizard object, and the shared gameState (including manaPool via ManaHelpers).
Action Execution: The AI will directly invoke methods on its Wizard object (queueSpell, freeAllSpells). It will NOT simulate keyboard input.
5. Success Metrics (for Phase 1)
The AI component runs without causing errors or stability issues.
The AI can perceive basic game state changes (health, range, etc.).
The AI transitions between its defined behavioral states based on simple rules.
The AI successfully queues spells from its spellbook when it has sufficient mana.
The AI provides some level of interaction, casting spells periodically and reacting minimally to significant health changes (e.g., attempting to defend when low).
A human player can complete a basic duel against the AI, allowing testing of the core game loop, spell effects, and win/loss conditions.
6. Future Considerations (Post-Phase 1)
More sophisticated decision-making (e.g., Behavior Trees).
Improved perception (tracking specific tokens, opponent cast progress).
Reactive behaviors (e.g., attempting to block projectiles, countering specific spell types).
Strategic mana management and combo spell usage.
Distinct difficulty levels.
7. Related Tickets
AI-1: AI Module Setup & Integration
AI-2: Perception Implementation
AI-3: Basic FSM & Decision Logic
AI-4: Action Execution
AI-5: Spell Knowledge & Basic Strategy