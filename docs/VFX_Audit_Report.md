# Spells VFX Audit Report

This report shows the current VFX setup for each spell and recommendations for improvement.

| Spell Name | Element | Attack Type | Current VFX | Using VFX Keyword | Generates EFFECT Events | Recommended VFX | Status |
|------------|---------|-------------|-------------|-------------------|------------------------|-----------------|--------|
| Adaptive Surge | fire | projectile | adaptive_surge | No | Yes | adaptive_surge | ✅ Correct |
| Arcane Reversal | fire | remote | arcane_reversal | No | Yes | arcane_reversal | ✅ Correct |
| Battle Shield | fire | utility | battle_shield | No | Yes | battle_shield | ✅ Correct |
| Blast Wave | fire | zone | blastwave | No | Yes | blastwave | ✅ Correct |
| Blazing Ascent | fire | zone | blazing_ascent | No | Yes | blazing_ascent | ✅ Correct |
| Combust Mana | fire | utility | combust_lock | No | Yes | combust_lock | ✅ Correct |
| Conjure Fire | fire | utility | fire_conjure | No | Yes | fire_conjure | ✅ Correct |
| Conjure Moonlight | moon | utility | moon_conjure | No | Yes | moon_conjure | ✅ Correct |
| Conjure Nothing | void | utility | void_conjure | No | Yes | void_conjure | ✅ Correct |
| Conjure Salt | salt | utility | force_conjure | No | Yes | force_conjure | ✅ Correct |
| Conjure Stars | star | utility | star_conjure | No | Yes | star_conjure | ✅ Correct |
| Cosmic Rift | fire | zone | cosmic_rift | No | Yes | cosmic_rift | ✅ Correct |
| Drag From the Sky | moon | zone | None | Yes | Yes | gravity_pin_ground | ✅ Correct |
| Emberlift | sun | utility | ember_lift | No | Yes | ember_lift | ✅ Correct |
| Enhanced Mirror Shield | fire | utility | enhanced_mirror_shield | No | Yes | enhanced_mirror_shield | ✅ Correct |
| Firebolt | fire | projectile | None | Yes | Yes | firebolt | ✅ Correct |
| Force Blast | fire | remote | force_blast | No | Yes | force_blast | ✅ Correct |
| Full Moon Beam | moon | projectile | moon_beam | No | Yes | moon_beam | ✅ Correct |
| Gravity Trap | moon | utility | gravity_trap_set | No | Yes | gravity_trap_set | ✅ Correct |
| Infinite Procession | moon | utility | infinite_procession | No | Yes | infinite_procession | ✅ Correct |
| Lunar Disjunction | moon | projectile | lunardisjunction | No | Yes | lunardisjunction | ✅ Correct |
| Lunar Tides | fire | zone | lunar_tide | No | Yes | lunar_tide | ✅ Correct |
| Meteor Dive | sun | zone | None | Yes | Yes | meteor | ✅ Correct |
| Mirror Shield | fire | utility | mirror_shield | No | Yes | mirror_shield | ✅ Correct |
| Molten Ash | fire | zone | lava_eruption | No | Yes | lava_eruption | ✅ Correct |
| Moon Dance | moon | remote | None | No | No | fullmoonbeam | ❌ Missing VFX |
| Moon Ward | fire | utility | moon_ward | No | Yes | moon_ward | ✅ Correct |
| Nature Field | fire | utility | nature_field | No | Yes | nature_field | ✅ Correct |
| Nova Conjuring | sun | utility | nova_conjure | No | Yes | nova_conjure | ✅ Correct |
| Shield Breaker | fire | projectile | force_blast | No | Yes | force_blast | ✅ Correct |
| Storm Meld | fire | utility | storm_meld | No | Yes | storm_meld | ✅ Correct |
| Sun Block | fire | utility | force_barrier | No | Yes | force_barrier | ✅ Correct |
| Test Shield | fire | utility | force_barrier | No | Yes | force_barrier | ✅ Correct |
| Tidal Force | water | remote | tidal_force | No | Yes | tidal_force | ✅ Correct |
| Total Eclipse | moon | utility | eclipse_burst | No | Yes | eclipse_burst | ✅ Correct |
| Wings of Moonlight | moon | utility | None | Yes | Yes | mistveil | ✅ Correct |
| Witch Conjuring | moon | utility | witch_conjure | No | Yes | witch_conjure | ✅ Correct |

## Summary Statistics

- **Total Spells:** 37
- **Correctly Implemented:** 36 (97.3%)
- **Needs VFX Keyword:** 0 (0.0%)
- **Missing VFX:** 1 (2.7%)

## Implementation Recommendations

1. **Replace top-level VFX properties with VFX keywords:**
   ```lua
   -- Before:
   vfx = "firebolt",

   -- After:
   keywords = {
       -- other keywords...
       vfx = { effect = Constants.VFXType.FIREBOLT, target = Constants.TargetType.ENEMY }
   },
   ```

2. **Add VFX keywords to spells missing visual effects:**
   - Use Constants.VFXType for standard effect names
   - Match the effect type to the spell's element and attack pattern
   - Consider spell's role when selecting the visual effect

3. **Run the automated fix tool:**
   ```bash
   lua tools/fix_vfx_events.lua
   ```

4. **Test with the VFX events test:**
   ```bash
   lua tools/test_vfx_events.lua
   ```
