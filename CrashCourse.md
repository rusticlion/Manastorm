Manastorm Crash Course: Welcome to the Ninefold Circle!
Purpose: To quickly bring new contributors up to speed on the overall architecture and key systems of Manastorm.
Target Audience: Developers new to the Manastorm codebase.
1. Introduction: What is Manastorm?
Manastorm is a real-time tactical wizard dueling game. Two spellcasters face off, drawing mana from a shared central pool to queue and cast spells. The core gameplay revolves around:
Shared Resource Economy: Both players draw from the same mana pool.
Casting Tempo: Spells take time to charge, creating windows of opportunity and vulnerability.
Positional Strategy: NEAR/FAR range and GROUNDED/AERIAL elevation states significantly impact spell legality and effects.
Diegetic UI: Game information is primarily conveyed through in-world visual cues rather than traditional HUD elements.
(Refer to ComprehensiveDesignDocument.md for the full vision.)
2. Core Architectural Pillars
The game is built around several key interconnected systems:
Game Loop & State (main.lua):
Manages the main game states (MENU, CHARACTER_SELECT, BATTLE, GAME_OVER, BATTLE_ATTRACT, etc.).
Handles love.load(), love.update(), love.draw(), and input routing via core/Input.lua.
The global game table holds references to major game objects and state (wizards, mana pool, VFX system, etc.).
Wizards (wizard.lua):
The primary actors in the game. Each wizard has health, spell slots, a spellbook, and manages their current state (elevation, status effects).
Spellcasting: Wizards don't cast spells instantly. They:
Key Spells: Players press key combinations (e.g., Q, W, E or Q+W) to select a spell from their spellbook.
Queue Spells: If a slot is available and mana cost can be paid, the spell is queued into an orbiting spell slot. Mana tokens are acquired from the ManaPool and animated towards the wizard.
Channeling: The spell "charges" in the slot, visually represented by a progress arc.
Resolution: Once charged, Wizard:castSpell() is called.
(See docs/wizard.md for more details.)
Mana Pool (manapool.lua):
A shared, central pool of mana tokens.
Tokens have types (Constants.TokenType) and states (Constants.TokenStatus - FREE, CHANNELED, SHIELDING, RETURNING, DISSOLVING, POOLED).
Manages token animations (orbiting in the pool, moving to/from wizards).
Employs object pooling (core/Pool.lua) for token objects to reduce garbage collection.
(See docs/manapool.md and docs/token_lifecycle.md for more details.)
Spell System (The "Triune Spell Engine"):
keywords.lua (Ingredients): Defines atomic game actions (e.g., damage, elevate, conjure). Each keyword has a behavior (metadata) and an execute function.
Crucially, keyword execute functions generate events describing state changes, rather than directly modifying game state.
spells/ directory (Recipes): Spell definitions are organized by element (e.g., spells/elements/fire.lua). Each spell is a table combining keywords with specific parameters (e.g., damage = { amount = 10, type = "fire" }).
spellCompiler.lua (Chef): Takes raw spell definitions and "compiles" them into executable objects. It merges keyword behaviors and binds their execute functions. The compiled spell's executeAll() method is called by Wizard:castSpell().
(See docs/spellcasting.md and docs/keywords.lua [generated] for more details.)
Event System (systems/EventRunner.lua):
The Core of Gameplay Logic Application. After compiledSpell.executeAll() generates a list of events, the EventRunner processes them.
Events have a type, source, target, and event-specific data.
The EventRunner sorts events by PROCESSING_PRIORITY and calls specific handler functions from EventRunner.EVENT_HANDLERS for each event type.
It is these handlers within EventRunner that actually modify the game state (e.g., wizard health, token states, VFX triggers).
(See docs/combat_events.md for the event schema.)
Visual Effects (VFX) System (vfx.lua & systems/VisualResolver.lua):
Rule-Driven: Most VFX are not manually specified per spell. Instead, the VisualResolver inspects metadata within EFFECT events (like affinity, attackType, visualShape, manaCost, tags) to pick a base VFX template and its parameters (color, scale, motion).
vfx.lua contains base effect templates (e.g., proj_base, beam_base) and the logic to update and draw active visual effects. It also uses object pooling for effects and particles.
Specific named effects (like meteor) exist for more unique visuals.
(See docs/Visual_Language.md, docs/AddingVisualTemplates.md, and VFX-RulesBasedRefactor-GamePlan.md.)
AI System (ai/):
OpponentAI.lua: Provides the core FSM (Idle, Attack, Defend, etc.) and Perception-Decision-Action loop.
PersonalityBase.lua: Defines an interface for character-specific AI behavior.
ai/personalities/: Contains specific AI logic for different wizards (e.g., SelenePersonality.lua). Personalities suggest spells and can influence state transitions.
The AI interacts with its wizard object via the same API as a human player would (e.g., wizard:queueSpell()), not by simulating key presses.
Core Utilities (core/):
Constants.lua: Centralized string constants. Crucial for avoiding magic strings.
AssetCache.lua: Prevents duplicate loading of images and sounds.
Pool.lua: Generic object pooling system.
Input.lua: Unified input routing. Uses an action-based scheme defined in
  `Constants.ControlAction`. Keyboard and gamepad bindings are loaded from
  Settings.lua and can be changed at runtime.
Settings.lua: Handles persistent game settings.
assetPreloader.lua: Manages preloading of assets.
3. Key Interactions & Data Flow
Player Input (core/Input.lua) -> Wizard (wizard.lua):
Keys pressed are routed to wizard:keySpell() to select a spell, then wizard:castKeyedSpell() calls wizard:queueSpell().
Spell Queuing (wizard.lua):
wizard:canPayManaCost() checks ManaPool.
TokenManager.acquireTokensForSpell() moves tokens from ManaPool to wizard.spellSlots[i].tokens (state: CHANNELED).
Spell slot becomes active; casting progress begins.
Spell Resolution (wizard.lua -> spellCompiler.lua -> keywords.lua):
When slot.progress >= slot.castTime, wizard:castSpell() is called.
compiledSpell.executeAll() (from spellCompiler) iterates through the spell's keywords.
Each keyword's execute() function is called, adding descriptive events to a list.
Event Processing (spellCompiler.lua -> systems/EventRunner.lua):
executeAll() passes the generated event list to EventRunner.processEvents().
EventRunner sorts events and calls the appropriate handler for each.
State Mutation & VFX Triggering (systems/EventRunner.lua):
Event handlers modify game state (e.g., targetWizard.health -= event.amount).
For visual changes, handlers often generate an EFFECT event.
The EFFECT event handler calls VisualResolver.pick(event) to determine the baseEffectName and vfxOpts.
Then, VFX.createEffect(baseEffectName, ..., vfxOpts) is called to create the visual.
Visual Rendering (vfx.lua, systems/WizardVisuals.lua):
VFX.update() and VFX.draw() manage active visual effects.
WizardVisuals.drawWizard() handles drawing the wizard sprite, spell slots, and status effects.
4. Current Development Focus
"Game Juice": Enhancing visual and audio feedback to make gameplay feel more impactful and satisfying.
Content Creation: Adding new spells, characters, and potentially AI personalities.
Balancing: Tweaking spell costs, cast times, and effects.
5. Getting Started
Read the Docs: Start with ComprehensiveDesignDocument.md, README.md, then dive into system-specific docs relevant to your task (e.g., spellcasting.md, VFX-RulesBasedRefactor-GamePlan.md).
Trace a Spell: Pick a simple spell (e.g., Firebolt). Trace its definition in spells/elements/fire.lua, its keywords in keywords.lua, how spellCompiler.lua prepares it, how wizard.lua casts it, how EventRunner.lua processes the resulting events, and how vfx.lua (via VisualResolver.lua) displays it.
Look at Tickets: The Tickets/ directory shows recent work and priorities, which can give context to code changes.