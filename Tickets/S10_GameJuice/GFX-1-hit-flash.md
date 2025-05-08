Title: Implement Character Hit Flash
Goal: Provide immediate, clear visual feedback when a wizard takes damage.
Description: Currently, damage reduces health but lacks instant visual 
feedback on the character sprite itself. Adding a brief color flash will 
make impacts more readable.
Tasks:
Modify EventRunner.lua: In the DAMAGE handler (and potentially 
APPLY_STATUS for DoTs), after health is reduced, set a temporary flag or 
timer on the targetWizard (e.g., targetWizard.hitFlashTimer = 0.1).
Modify Wizard:update(dt): Decrement hitFlashTimer if it's > 0.
Modify WizardVisuals.drawWizard:
Before drawing the wizard sprite, check if wizard.hitFlashTimer > 0.
If true, use love.graphics.setColor(1, 1, 1, 1) (or maybe a slight red 
tint like 1, 0.8, 0.8) just before drawing the sprite.
Immediately after drawing the sprite, reset the color using 
love.graphics.setColor(1, 1, 1, 1).
Acceptance Criteria:
When a wizard's health is reduced by a direct hit or DoT tick, their 
sprite flashes white/red briefly (e.g., for ~0.1 seconds).
The flash does not interfere with other color changes (like stun).
Technical Notes: Using a simple timer on the wizard object is efficient. 
Ensure color reset happens correctly to avoid persistent tinting.
