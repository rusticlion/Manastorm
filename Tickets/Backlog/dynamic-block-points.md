Ticket ID: VFX-P1 (Visual Polish)
Title: VFX: Implement Dynamic Shield Block Point Calculation
Goal: Enhance visual realism by making blocked projectiles visually stop at the calculated intersection point with the defender's shield orbit, rather than at a fixed percentage along the trajectory.
Problem: Currently, blockPoint is hardcoded to 0.75 in Wizard:castSpell. This causes visual inconsistencies where the projectile might appear to stop too early (FAR range) or too late/behind the target (NEAR range), breaking immersion.
Tasks:
Modify Wizard:castSpell (wizard.lua):
Locate the if blockInfo.blockable then block.
Replace blockInfo.blockPoint = 0.75.
Calculate dynamic blockPoint:
Get caster position (self.x, self.y including currentX/YOffset).
Get defender position (target.x, target.y including currentX/YOffset).
Calculate total distance (casterDist) between them.
Approximate the shield's visual radius based on blockInfo.blockingSlot (using radii from WizardVisuals as a reference, e.g., local shieldRadius = WizardVisuals.slotRadii.h[blockInfo.blockingSlot] or 70).
Calculate the distance from the caster to the impact point: local impactDistance = casterDist - shieldRadius.
Calculate the ratio: local pointRatio = impactDistance / casterDist.
Set blockInfo.blockPoint = math.max(0.05, math.min(0.95, pointRatio)) (clamp to prevent edge cases).
Verify Propagation: Ensure the calculated blockInfo.blockPoint is correctly passed through blockedResults, BLOCKED_DAMAGE event conversion, EFFECT event generation, and finally arrives in the opts table for VFX.createEffect.
Acceptance Criteria:
When a spell is blocked, the blockPoint value passed to VFX.createEffect is calculated dynamically based on caster/defender positions and the blocking slot's radius.
Visually, blocked projectiles stop noticeably closer to the defender when NEAR compared to when FAR.
The visual stop point roughly corresponds to the outer edge of the defender's shield orbit animation for the blocking slot.
System remains stable, no new errors introduced.
Notes:
This is primarily a visual polish ticket.
The shield radius approximation can be refined later, especially if shield visuals become non-elliptical.
Depends on the core blocking logic and event system being stable.
Priority: Low (Post-Demo)