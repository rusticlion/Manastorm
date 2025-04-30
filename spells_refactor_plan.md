# Spells.lua Refactoring Plan

## Current Structure Analysis

The current `spells.lua` file (1500+ lines) contains:

1. A validation function (`validateSpell`)
2. Spell definitions for multiple wizards/affinities organized linearly
3. Utility functions for spell compilation
4. Schema documentation (in comments)

## Natural Groupings Identified

### By Wizard Character
- **Ashgar (Fire-focused)**: conjurefire, firebolt, fireball, blastwave, meteor, combustMana
- **Selene (Moon-focused)**: conjuremoonlight, conjurestars, wrapinmoonlight, tidalforce, lunardisjunction, gravityTrap, moondance, gravity, eclipse, fullmoonbeam

### By Element/Affinity
- **Fire**: conjurefire, firebolt, fireball, blastwave, meteor, combustMana, blazingAscent
- **Water**: watergun, tidalforce
- **Moon**: conjuremoonlight, wrapinmoonlight, lunardisjunction, gravity, eclipse, fullmoonbeam, gravityTrap, moondance, lunarTides
- **Salt**: conjuresalt, glitterfang, imprison, saltcircle, stoneshield, jaggedearth, saltstorm
- **Sun/Star**: emberlift, conjurestars, novaconjuring, cosmicRift, adaptive_surge
- **Void**: conjurenothing

### By Functionality
- **Conjuration Spells**: conjurefire, conjuremoonlight, conjuresalt, conjurestars, conjurenothing, novaconjuring, witchconjuring
- **Damage Spells**: firebolt, fireball, watergun, blastwave, meteor, glitterfang, fullmoonbeam
- **Movement/Positioning**: emberlift, blazingAscent, moondance
- **Shield Spells**: saltcircle, stoneshield, forcebarrier, enhancedmirrorshield, battleshield, wrapinmoonlight
- **Trap Spells**: imprison, gravityTrap, jaggedearth
- **Control Spells**: gravity, combustMana, lunardisjunction, cosmicRift

### Shared Utility Functions
- `validateSpell` - Schema validation
- `SpellsModule.compileAll` - Compile all spells
- `SpellsModule.getCompiledSpell` - Get a single compiled spell

## Recommended Refactoring Structure

```
spells/
├── init.lua                 # Main entry point that loads all spell modules
├── schema.lua               # Schema validation & utilities
├── wizards/                 # Character-specific spell collections
│   ├── ashgar.lua           # Ashgar's spell collection
│   └── selene.lua           # Selene's spell collection  
├── types/                   # Element/Affinity-based collections
│   ├── fire.lua             # Fire spells
│   ├── water.lua            # Water spells
│   ├── moon.lua             # Moon spells
│   ├── salt.lua             # Salt spells
│   ├── sun.lua              # Sun/Star spells
│   └── void.lua             # Void spells
└── functions/               # Functional groupings
    ├── conjuration.lua      # Token creation spells
    ├── damage.lua           # Direct damage spells
    ├── movement.lua         # Positioning/elevation spells
    ├── shields.lua          # Shield/defensive spells
    ├── traps.lua            # Delayed/trigger effect spells
    └── control.lua          # Status effect/control spells
```

## Implementation Plan

1. Create the directory structure
2. Extract `validateSpell` and utility functions to `schema.lua`
3. Create the main module in `init.lua` that imports and combines all spells
4. Sort each spell to the appropriate file based on primary function
5. Update imports in main.lua to use the new structure

## Benefits

1. **Maintainability**: Smaller files are easier to understand and modify
2. **Organization**: Spells are grouped logically by function or affinity
3. **Extensibility**: Easier to add new spells to appropriate categories
4. **Collaboration**: Multiple developers can work on different spell types simultaneously
5. **Testing**: Easier to test specific categories of spells

## Migration Timeline

1. Create new structure without modifying original file
2. Incrementally move spells with tests after each move
3. When complete, switch to the new system and remove the original file

## Future Improvements

After this refactoring, consider:
1. Implementing a more robust spell factory pattern
2. Adding more extensive spell validation
3. Creating a DSL (Domain Specific Language) for spell definition
4. Adding inheritance for spell types to reduce duplication