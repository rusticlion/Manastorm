Update Drawing Logic
Goal: Draw the current idle animation frame for Ashgar instead of his 
static sprite.
Tasks:
Modify WizardVisuals.drawWizard (systems/WizardVisuals.lua):
Change the sprite drawing logic to use the current idle animation frame 
when appropriate.
function WizardVisuals.drawWizard(wizard)
    -- ... (existing logic for xOffset, yOffset, wizardColor, ground 
indicator) ...

    WizardVisuals.drawSpellSlots(wizard, "back") -- Draw back slots

    -- Draw the wizard sprite
    if wizard.sprite then -- Still check if a base sprite exists (for 
fallbacks/other wizards)
        local flipX = (wizard.name == "Selene") and -1 or 1
        local adjustedScale = wizard.scale * flipX

        local spriteToDraw = nil

        if wizard.castFrameTimer > 0 and wizard.castFrameSprite then
            spriteToDraw = wizard.castFrameSprite
        elseif wizard.idleAnimationFrames and #wizard.idleAnimationFrames 
> 0 then
            spriteToDraw = 
wizard.idleAnimationFrames[wizard.currentIdleFrame]
        else
            -- Fallback to the original static sprite if no animation 
frames are available
            spriteToDraw = wizard.sprite 
        end

        -- Ensure spriteToDraw is not nil before attempting to draw
        if not spriteToDraw then
            print("Error: No sprite to draw for wizard " .. wizard.name)
            -- Optionally draw a placeholder or return
            love.graphics.setColor(1,0,0,1) -- Red error color
            love.graphics.rectangle("fill", wizard.x + xOffset - 20, 
wizard.y + yOffset - 30, 40, 60)
            love.graphics.setColor(1,1,1,1) -- Reset color
        else
            -- Draw shadow first (when not AERIAL)
            if wizard.elevation == Constants.ElevationState.GROUNDED then
                love.graphics.setColor(0, 0, 0, 0.2)
                love.graphics.draw(
                    spriteToDraw,
                    wizard.x + xOffset,
                    wizard.y + 40, -- Shadow on ground
                    0, 
                    adjustedScale * 0.8, 
                    wizard.scale * 0.3, 
                    spriteToDraw:getWidth() / 2,
                    spriteToDraw:getHeight() / 2
                )
            end

            -- Hit flash logic (applies color before drawing main sprite)
            if wizard.hitFlashTimer > 0 then
                local prevBlendMode = love.graphics.getBlendMode()
                love.graphics.setBlendMode("add")
                love.graphics.setColor(wizardColor[1], wizardColor[2], 
wizardColor[3], wizardColor[4]) 
                love.graphics.draw(
                    spriteToDraw,
                    wizard.x + xOffset, wizard.y + yOffset, 0,
                    adjustedScale * 2, wizard.scale * 2,
                    spriteToDraw:getWidth() / 2, spriteToDraw:getHeight() 
/ 2
                )
                love.graphics.setBlendMode(prevBlendMode)
                -- Reset color for normal drawing if hit flash isn't 
covering it
                love.graphics.setColor(1,1,1,1) 
                if wizard.flashBlendMode ~= "add" then -- if hit flash 
isn't additive, draw base normally
                     love.graphics.draw(
                        spriteToDraw,
                        wizard.x + xOffset, wizard.y + yOffset, 0,
                        adjustedScale * 2, wizard.scale * 2,
                        spriteToDraw:getWidth() / 2, 
spriteToDraw:getHeight() / 2
                    )
                end

            else 
                -- Normal drawing (no hit flash)
                love.graphics.setColor(wizardColor[1], wizardColor[2], 
wizardColor[3], wizardColor[4])
                love.graphics.draw(
                    spriteToDraw,
                    wizard.x + xOffset, wizard.y + yOffset, 0,
                    adjustedScale * 2, wizard.scale * 2,
                    spriteToDraw:getWidth() / 2, spriteToDraw:getHeight() 
/ 2
                )
            end
        end
        
        love.graphics.setColor(1, 1, 1, 1) -- Reset color

        -- Draw AERIAL cloud effect (existing logic)
        if wizard.elevation == Constants.ElevationState.AERIAL then
            -- ... (existing cloud drawing logic) ...
        end
    else
        -- ... (existing fallback circle drawing) ...
    end

    WizardVisuals.drawSpellSlots(wizard, "front") -- Draw front slots

    -- ... (existing logic for status effects, spell cast notification) 
...
end
Use code with caution.
Lua
Important: The logic should prioritize castFrameSprite if castFrameTimer > 
0. The idle animation should only play if the cast animation is not 
active.
The existing hit flash (tinting wizardColor) should apply to the current 
animation frame.
Acceptance Criteria:
Ashgar is drawn using his idle animation frames when not casting.
The cast animation (ashgar-cast.png) still takes precedence during 
castFrameTimer.
Hit flash and other visual effects correctly apply to the animated sprite.
Selene (and any other future wizards) continue to display their static 
sprites correctly.
