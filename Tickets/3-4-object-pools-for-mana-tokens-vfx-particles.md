# Ticket #4 – Object Pools for Mana Tokens & VFX Particles

## Goal
Reduce garbage generation and frame spikes by reusing token and particle tables instead of creating / GC‑ing every frame.

## Tasks
1. Add core/Pool.lua with acquire() / release().
2. Refactor manapool.lua token creation to Pool.acquire("token").
3. Do the same for VFX.createEffect particle tables.
4. Optional: add game.showPoolsStats() debug overlay.

## Deliverables
* Pool module.
* Profiling numbers (before/after) in PR description.

## Pitfalls
Ensure released objects are fully reset; lingering references will cause spooky bugs.

## Senior Feedback
* **Complex Object Reset**: The resetting of released objects is particularly critical for this codebase:
  * Mana Tokens (manapool.lua) have many properties: state, lockDuration, valenceIndex, orbitAngle, orbitSpeed, pulsePhase, rotAngle, valenceJumpTimer, transition states, wizardOwner, spellSlot, etc. The Pool.release function must meticulously reset all of these. Consider adapting logic from the existing finalizeTokenReturn function in manapool.lua.
  * VFX Particles (vfx.lua) have different properties depending on the effect type: x, y, scale, alpha, rotation, delay, active, speed, targetX/Y, angle, distance, orbitalSpeed, position, offset, speedX/Y, finalPulse, etc.
* **Pool Design Question**: Decide whether to use a single Pool module handling different object types, or separate pools. If using a single Pool, ensure the acquire/release logic correctly handles the different structures for each object type.
* **Performance Measurement**: Focus profiling efforts on scenarios with high token/particle turnover (e.g., rapid spellcasting, complex VFX) to demonstrate the most significant improvements.