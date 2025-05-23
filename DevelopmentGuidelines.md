Manastorm Development Guidelines
Purpose: To establish conventions and best practices for coding new features and refactoring existing systems in Manastorm, ensuring consistency and maintainability.
I. General Principles
Modularity:
Keep systems decoupled. Favor communication through well-defined interfaces or events.
New major functionalities should generally reside in their own modules within appropriate directories (e.g., systems/, ai/, core/).
Avoid "god objects"; delegate responsibilities to specialized modules.
Data-Driven Design:
Prefer defining game entities (spells, character stats, AI behaviors) in Lua tables rather than hardcoding logic. This is evident in spells/, keywords.lua, and ai/personalities/.
This makes balancing and content creation easier.
Event-Driven Architecture (for Gameplay Logic):
Primary Rule: Changes to game state (wizard health, token status, positions, status effects) resulting from spell effects must be processed through the EventRunner.
Keywords and spell logic should generate descriptive events, not directly mutate state.
Refer to docs/combat_events.md for the event schema.
Use EventRunner.queueVisual() (or generate an EFFECT event) for triggering VFX from game systems outside direct spell casts (e.g., token destruction animations).
Use Constants (core/Constants.lua):
Strictly avoid magic strings for anything that represents a defined game state, type, or category (e.g., "fire", "AERIAL", "projectile").
Always use Constants.TokenType.FIRE, Constants.ElevationState.AERIAL, Constants.AttackType.PROJECTILE, etc.
Add new constants to core/Constants.lua as needed, following existing naming conventions.
Run tools/check_magic_strings.lua periodically or as a pre-commit hook.
Readability & Clarity:
Write clear, self-documenting code where possible.
Use meaningful variable and function names.
Add comments to explain complex logic or non-obvious decisions.
Performance Considerations:
Object Pooling: For frequently created/destroyed objects (mana tokens, VFX particles, VFX effect containers), use the core/Pool.lua system. Ensure resetFn thoroughly clears all object fields.
Asset Caching: All image and sound loading must go through core/AssetCache.lua to prevent duplicate loads.
Avoid heavy computations in love.update() or love.draw() where possible. Profile if performance issues arise.
II. Specific System Guidelines
Adding New Spells:
Define the spell in the appropriate spells/elements/your_element.lua file.
Adhere to the schema in spells/schema.lua (id, name, affinity, description, attackType, castTime, cost, keywords, visualShape (optional)).
Compose spell effects using existing keywords from keywords.lua. If new mechanics are needed, define new keywords first.
Spell visualShape and affinity will primarily drive visuals via VisualResolver. Only use the vfx keyword with effectOverride for truly unique cinematic effects.
Update characterData.lua if the spell is part of a default spellbook or the character's general spell list for the Compendium.
Add to game.unlockedSpells in main.lua if it's unlockable.
Modifying or Adding Keywords (keywords.lua):
Event Generation: The execute function must add events to the passed-in events table. It should not directly modify caster, target, or gameState.
Parameters: Keyword parameters defined in spells.lua can be static values or functions (resolved by keywords.lua.resolve()).
Dynamic Costs: Spells may include a `getCost(caster, target)` function which returns a token cost table at runtime. Use this for mechanics like health-scaled or target-dependent costs.
Metadata: Keep the behavior table updated with descriptive flags, targetType, and category.
VFX: Keywords generally should not trigger VFX directly. Instead, the events they generate (e.g., DAMAGE, SET_ELEVATION) will be picked up by EventRunner, which then uses VisualResolver for VFX. If a keyword has a unique, inherent visual distinct from its gameplay event (rare), it can generate a specific EFFECT event.
Documentation: Update docs/keywords.lua (or ensure it's auto-generated) if adding or significantly changing a keyword.
Visual Effects (VFX - vfx.lua, systems/VisualResolver.lua):
Rule-Driven First: Strive to have visuals determined by VisualResolver based on event metadata (affinity, attackType, visualShape, manaCost, tags).
Base Templates: Add to or modify base templates in VFX.effects (e.g., proj_base, beam_base) to handle parameters like color, scale, and motion style.
Motion Styles: Utilize Constants.MotionStyle and implement the corresponding logic in VFX.updateParticle.
Constants.VFXType: Add new base template names or unique override effect names to Constants.VFXType.
Asset Handling: Add asset paths to VFX.assetPaths. Critical assets needed immediately should be preloaded in VFX.init(); others will be lazy-loaded via getAssetInternal.
(Refer to docs/AddingVisualTemplates.md and VFX-RulesBasedRefactor-GamePlan.md.)
AI Personalities (ai/personalities/):
Create new personality files that implement the interface defined in ai/PersonalityBase.lua.
Personality modules are responsible for spell selection logic for a specific character.
Keep the core OpponentAI.lua generic; character-specific logic belongs in personality modules.
AI actions should use wizard:queueSpell(), not simulate input.
Input Handling:
  The game uses an action-based input layer. All actions are defined in
  `Constants.ControlAction`. Default bindings for keyboard and gamepad live in
  `core/Settings.lua` and can be rebound at runtime through the Settings menu.
UI (ui.lua, main.lua draw functions):
Strive for diegetic UI where possible (information integrated into the game world).
Keep UI drawing logic separate from game state update logic.
For complex UI elements, consider dedicated update/draw functions within ui.lua.
State Management & Game Logic:
EventRunner is King: Gameplay state changes resulting from spell effects must go through the EventRunner.
Wizard Object: Owns its immediate state (health, slots, current keyed spell, position).
_G.game Table: Holds global game state and references to major systems. Use judiciously.
main.lua: Orchestrates system updates and drawing based on game.currentState.
Asset Handling:
core/AssetCache.lua: All static file-based assets (images, sounds) must be loaded via AssetCache.getImage() or AssetCache.getSound().
core/assetPreloader.lua: Add paths for new assets to assetManifest to ensure they are preloaded at game start, preventing hitches. For VFX assets, also add paths to VFX.assetPaths in vfx.lua for lazy loading fallback/management.
III. Coding Conventions
Naming:
Modules / "Classes": PascalCase (e.g., OpponentAI, VisualResolver).
Functions / Methods: camelCase (e.g., requestReturnAnimation, canPayManaCost).
Local Variables: camelCase.
Constants: ALL_CAPS_SNAKE_CASE (e.g., Constants.TokenType.FIRE).
Private module functions (not intended for export): prefix with _ (e.g., _privateHelperFunction).
Comments:
Use LuaDoc-style comments for public functions/methods in modules (--- Description \n -- @param name type \n -- @return type).
Add inline comments for complex or non-obvious logic.
Use TODO:, FIXME:, NOTE: prefixes for actionable comments.
Error Handling & Logging:
Use pcall() for operations that might fail (e.g., file loading, external calls if any).
Use print("ERROR: ...") or print("WARNING: ...") for logging issues.
Leverage core/Log.lua (Log.debug(...)) for verbose development logs, which can be toggled.
Constants: Reiterate: No magic strings.
Global State:
Minimize direct modification of _G.game from modules other than main.lua. Systems should generally read from _G.game or have necessary parts passed to them.
Functions within modules should operate on self or passed-in parameters.
IV. Testing
Unit Tests (Informal): While a formal unit testing framework isn't in place, consider writing small, isolated test functions within modules or in tools/ to verify specific logic, especially for utility functions or complex algorithms.
V. Documentation
Update Existing Docs: If a change impacts a system described in docs/, update the relevant markdown file.
New Systems: Create new markdown documents in docs/ for significant new systems or architectural patterns.
Code Comments: Keep docblocks and inline comments current.