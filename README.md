# Manastorm

A tactical wizard dueling game built with LÖVE (Love2D).

## Description

Manastorm is a real-time strategic battler where two spellcasters clash in arcane combat by channeling mana from a shared pool to queue spells into orbiting "spell slots." Strategy emerges from a shared resource economy, strict limitations on casting tempo, and deep interactions between positional states and spell types.

## Requirements

- [LÖVE](https://love2d.org/) 11.4 or later

## How to Run

1. Install LÖVE from [love2d.org](https://love2d.org/)
2. Clone this repository
3. Run the game:
   - On Windows: Drag the folder onto love.exe, or run `"C:\Program Files\LOVE\love.exe" path\to\Manastorm`
   - On macOS: Run `open -n -a love.app --args $(pwd)` from the Manastorm directory
   - On Linux: Run `love .` from the Manastorm directory

## Controls

### Player 1 (Ashgar)
- Q, W, E: Queue spells in spell slots 1, 2, and 3

### Player 2 (Selene)
- I, O, P: Queue spells in spell slots 1, 2, and 3

### General
- ESC: Quit the game

## Development Status

This is an early prototype with basic functionality:
- Two opposing wizards with health bars
- Shared mana pool with floating tokens
- Three spell slots per wizard with visual feedback
- Basic state representation (NEAR/FAR, GROUNDED/AERIAL)

## Next Steps

- Connect mana tokens to spell queueing
- Implement actual spell effects
- Add position changes
- Create proper spell descriptions
- Add collision detection
- Add visual effects