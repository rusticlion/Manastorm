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

Manastorm uses an **action-based** input layer. Each action is defined in
`Constants.ControlAction` and can be bound independently for keyboard or
gamepad via the Settings menu. The mappings below reflect the defaults shipped
with the game.

### Default Keyboard Mapping

**Player 1**

- Q / W / E: Spell slots 1–3
- F: Cast (also acts as menu confirm)
- G: Free spells (also acts as menu cancel)
- B: Toggle spellbook
- Arrow Keys: Menu navigation

**Player 2**

- I / O / P: Spell slots 1–3
- J: Cast
- H: Free spells
- M: Toggle spellbook

### Default Gamepad Mapping

Gamepad controls mirror the keyboard actions. Use the D-pad for spell slots and
menu navigation. The **A** button casts or confirms, **Y** frees or cancels, and
**B** toggles the spellbook. When a second gamepad is connected these mappings
apply to Player 2 as well.

### General
- ESC: Quit the game

## Unlocking Characters

Casting any Salt-affinity spell during a match unlocks the wizard **Silex** for
future character selection.

## Debug Logging

Verbose debug output can be toggled at runtime. Require the `core.Log` module and
call `Log.setVerbose(true)` to enable detailed logging. Set it to `false` (the
default) to silence development traces.

## Development Status

This is a late prototype with basic full engine functionality:
- Two opposing wizards with health bars
- Shared mana pool with floating tokens
- Three spell slots per wizard with visual feedback
- Simple spatial state representation (NEAR/FAR, GROUNDED/AERIAL)
- Data-driven VFX engine (actual visuals are still rough)
- Various spell types with unique mechanics: Attack, Utility, Shield, Trap (with various subtypes of each)
- Various spell keywords with rigorously defined mechanics.
- "Triune Spell Engine" custom DSL/data-driven format for defining spells in terms of keywords. Spells are "compiled" at runtime from keyword-based definitions which can be authored using any convenient tool.

## Next Steps

- Polish VFX and add SFX. Use consistent design language driven by TSE spell definitions.
- Add basic main menu, mode select, control customization.
- Add AI opponent (strategy design pattern).
- Add content. Lots of content. Lots and lots and lots of content.
