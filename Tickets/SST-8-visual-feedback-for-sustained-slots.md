# Ticket #SST-8: Visual Feedback for Sustained Slots

## Description
Update the spell slot visuals to clearly distinguish between empty slots, casting slots, active Shield slots, and active Trap slots.

## Tasks

### Modify WizardVisuals.drawSpellSlots (systems/WizardVisuals.lua)
- Inside the loop drawing each slot i:
  - Check slot.active. If not active, draw as empty/invisible (existing logic)
  - If active:
    - Check slot.isShield. If true, draw using Shield visuals (existing logic, maybe refine pulsing/color)
    - Else If check if slot.spell exists and slot.spell.behavior.trap_trigger exists (indicates a Trap). If true, draw using a new Trap visual style (e.g., purple orbit line, a subtle static "trap sigil" icon in the center, full progress arc but maybe dimmer or pulsing differently than shields)
    - Else If check if slot.spell exists and slot.spell.behavior.sustain exists (generic sustained spell, not shield/trap). Draw with another distinct style (e.g., maybe a steady white or grey full arc)
    - Else (it's an active, non-sustained spell currently casting): Draw using the existing casting progress arc visual

## Acceptance Criteria
- Empty slots look distinct
- Slots casting normal spells show a growing progress arc
- Slots holding active Shields have their unique visual style (e.g., yellow/blue/green pulsing full arc)
- Slots holding active Traps have a new, clearly different visual style (e.g., purple static full arc with an icon)

## Pitfalls
Ensure the checks for shield/trap/sustained are robust and don't misclassify slots.