# Visual Language Reference

This document defines the visual language for the Manastorm game, mapping game concepts to visual elements to ensure consistency across the game.

## Overview

The visual language is organized by:

1. **Element**: The magical element (Fire, Moon, etc.)
2. **Concept**: The game mechanic (Damage, Heal, Shield, etc.)
3. **Target**: Who/what the effect targets (Self, Enemy, Pool)
4. **VFX Name**: The corresponding `Constants.VFXType` value
5. **Particle Sprite**: The asset used by the VFX system
6. **Core Color**: The base color used for the effect (from `Constants.Color`)

## Visual Language Map

| Element | Concept | Target | VFX Name | Particle Sprite | Core Color | Notes |
|---------|---------|--------|----------|----------------|------------|-------|
| **Fire** | Damage | Enemy | `FIREBOLT` | fireParticle | CRIMSON | Fast, direct projectile |
| Fire | Area Damage | Enemy | `METEOR` | fireParticle | OCHRE | Impact-focused with larger radius |
| Fire | Elevation | Self | `EMBERLIFT` | fireParticle | ORANGE | Vertical rising particles |
| Fire | Conjure | Pool | `CONJUREFIRE` | fireParticle | ORANGE | Particles converge on mana pool |
| **Water** | Damage | Enemy | `TIDAL_FORCE` | sparkle | OCEAN | Flowing, wave-like projectile |
| Water | Ground | Enemy | `TIDAL_FORCE_GROUND` | impactRing | OCEAN | Downward pressing impact |
| Water | Shield | Self | `SHIELD` | impactRing | OCEAN | Barrier-type with liquid appearance |
| **Moon** | Damage | Enemy | `LUNARDISJUNCTION` | sparkle | PINK | Elegant, arcing projectile |
| Moon | Disable | Enemy | `DISJOINT_CANCEL` | impactRing | PINK | Disruptive, sparkling impact |
| Moon | Conjure | Pool | `CONJUREMOONLIGHT` | moonGlow | SKY | Soft, glowing particles to pool |
| Moon | Shield | Self | `SHIELD` | runeAssets | SKY | Ward-type with runic symbols |
| Moon | Field | Area | `MISTVEIL` | sparkle | SKY | Diffuse, fog-like effect |
| **Sun** | Damage | Enemy | `METEOR` | fireParticle | ORANGE | Falling impact from above |
| Sun | Shield | Self | `SHIELD` | impactRing | ORANGE | Barrier-type with bright rings |
| Sun | Conjure | Pool | `NOVA_CONJURE` | sparkle | ORANGE | Bright, star-like particles |
| **Star** | Damage | Enemy | `STAR_CONJURE` | sparkle | YELLOW | Small, bright flashes |
| **Salt** | Control | Enemy | `TOKEN_LOCK` | impactRing | SAND | Crystalline, binding appearance |
| **Force** | Push | Enemy | `FORCE_BLAST` | forceWave | YELLOW | Wave-like, rippling effect |
| Force | Elevate | Enemy | `FORCE_BLAST_UP` | forceWave | YELLOW | Upward-moving force waves |
| Force | Conjure | Pool | `FORCE_CONJURE` | sparkle | YELLOW | Dynamic, energetic particles |
| **Life** | Heal | Self | `FREE_MANA` | sparkle | LIME | Gentle, pulsing aura |
| **Mind** | Control | Enemy | `SPELL_FREEZE` | sparkle | PINK | Twisting, distorting effect |
| **Void** | Consume | Enemy | `TOKEN_CONSUME` | sparkle | BONE | Draining, empty appearance |
| **Generic** | Impact | Any | `IMPACT` | impactRing | SMOKE | Basic impact when no specific VFX |
| Generic | Range Change | Both | `RANGE_CHANGE` | sparkle | SMOKE | Quick positional indicator |
| Generic | Acceleration | Slot | `SPELL_ACCELERATE` | sparkle | LIME | Speed-up animation |
| Generic | Cancel | Slot | `SPELL_CANCEL` | impactRing | CRIMSON | Spell interruption effect |
| Generic | Echo | Slot | `SPELL_ECHO` | sparkle | BONE | Spell replication effect |

## Shield Visual Language

Shields have distinct visual characteristics based on their type:

| Shield Type | Visual Style | Color | Asset | Description |
|-------------|--------------|-------|-------|-------------|
| `barrier` | Solid, physical | ORANGE (Sun) | impactRing | Concentric rings that expand outward, solid appearance |
| `ward` | Magical, runic | SKY (Moon) | runeAssets | Runic symbols that rotate around the wizard, ethereal glow |
| `field` | Energy, force | YELLOW (Force) | forceWave | Wave-like energy that pulses outward, semi-transparent |

## Element Color Reference

For consistency, these are the primary colors associated with each element:

- Fire: CRIMSON/ORANGE
- Water: OCEAN
- Salt: SAND
- Sun: ORANGE (brighter than Fire)
- Moon: SKY/PINK
- Star: YELLOW
- Life: LIME
- Mind: PINK
- Void: BONE
- Force: YELLOW
- Generic: SMOKE

## Implementation Checklist

When implementing visual effects for a new spell:

1. Identify which element the spell belongs to
2. Determine the primary concept (what game mechanic it represents)
3. Choose the appropriate target type
4. Select the matching VFX from the table above
5. Use the color values in the spell's visual implementation
6. Consider combining multiple VFX types for complex spells

## Particle System Usage

The particle system has several main effect types that produce different visual patterns:

- `projectile`: Moves from source to target with trailing particles
- `impact`: Creates a radial burst of particles from a central point
- `aura`: Generates particles orbiting around a central point
- `beam`: Creates a solid beam with particle effects along its length
- `conjure`: Creates particles that rise toward the mana pool