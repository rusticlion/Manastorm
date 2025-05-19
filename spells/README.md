# Spells System

The Manastorm spells system uses an elemental approach to organize all spells by their primary affinity.

## Directory Structure

- `spells/init.lua` - Main entry point that combines all spell collections
- `spells/schema.lua` - Schema validation for spells
- `spells/elements/` - Element-based spell definitions
  - `fire.lua` - Fire element spells
  - `water.lua` - Water element spells
  - `salt.lua` - Salt element spells
  - `sun.lua` - Sun element spells
  - `moon.lua` - Moon element spells
  - `star.lua` - Star element spells
  - `life.lua` - Life element spells (placeholder)
  - `mind.lua` - Mind element spells (placeholder)
  - `void.lua` - Void element spells

## Usage

The spell system maintains backward compatibility with the original interface:

```lua
local SpellsModule = require("spells") -- Now loads from the modular system
```

The module provides the following interfaces:
- `SpellsModule.spells` - Table of all spells
- `SpellsModule.validateSpell(spell, spellId)` - Validate spell schema  
- `SpellsModule.compileAll()` - Compile all spells
- `SpellsModule.getCompiledSpell(spellId, spellCompiler, keywords)` - Get a compiled spell by ID

## Adding New Spells

To add a new spell:

1. Determine which elemental category it belongs to based on its affinity
2. Add the spell definition to the appropriate file in `spells/elements/`
3. The main module will automatically include it

## Spell Schema

Each spell must follow this schema:
- `id`: Unique identifier (string)
- `name`: Display name (string)
- `affinity`: Element of the spell (string)
- `description`: Text description (string)
- `attackType`: Delivery method - projectile, remote, zone, utility
- `castTime`: Duration in seconds (number)
- `cost`: Array of token types required (array)
- `keywords`: Table of effect keywords and parameters (table)

See `schema.lua` for detailed validation logic.