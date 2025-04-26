# Ticket #SST-9: Implement Gravity Pin Trap Spell

## Description
Redefine the Gravity Pin spell (or create a new GravityTrap) in spells.lua to use the newly implemented sustained spell and trap keyword system.

## Tasks

### Update Spell Definition (spells.lua)
- Modify Spells.gravity or create Spells.gravityPin
- Set attackType = Constants.AttackType.UTILITY
- Define the keywords table as follows (adjust cost/castTime as needed):
```lua
keywords = {
    sustain = true,
    trap_trigger = { condition = "on_opponent_elevate" },
    trap_window = { duration = 5.0 },
    trap_effect = {
        -- Re-use existing keywords for the effect
        damage = { amount = 10, type = Constants.DamageType.FORCE, target = "ENEMY" },
        ground = { target = "ENEMY", vfx = "gravity_pin_ground" }
        -- Optional: stagger = { duration = 1.0, target = "ENEMY" }
    }
}
```
- Update vfx to gravity_trap_set (or similar) for the initial placement
- Remove the old damage and ground keywords that were executing immediately

### Testing
- Cast the spell. Verify the slot shows the "Trap" visual and mana/slot remain locked
- Have the opponent use an elevate spell (e.g., Emberlift via debug key '4' or Ashgar's '13' combo) within 5 seconds. Verify the trap triggers: opponent takes damage, is grounded, and the caster's trap slot resets/returns mana
- Cast the spell again. Wait 5 seconds without the opponent elevating. Verify the trap expires: the caster's trap slot resets/returns mana without any effect occurring

## Acceptance Criteria
- Gravity Pin spell is defined using sustain, trap_trigger, trap_window, trap_effect
- Casting it sets the trap correctly (visuals, slot state)
- The trap triggers correctly when the opponent becomes AERIAL within the window
- The trap expires correctly if the window closes without a trigger
- Slot and mana are correctly released in both trigger and expiry scenarios