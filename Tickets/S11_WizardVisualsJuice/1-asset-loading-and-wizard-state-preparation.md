Asset Loading & Wizard State Preparation
Goal: Load Ashgar's idle animation frames and prepare the Wizard object to 
manage animation state.
Tasks:
Update Asset Manifest (core/assetPreloader.lua):
Add paths for Ashgar's 7 idle frames to the assetManifest.images table.
-- In assetManifest.images
"assets/sprites/ashgar-idle-1.png",
"assets/sprites/ashgar-idle-2.png",
"assets/sprites/ashgar-idle-3.png",
"assets/sprites/ashgar-idle-4.png",
"assets/sprites/ashgar-idle-5.png",
"assets/sprites/ashgar-idle-6.png",
"assets/sprites/ashgar-idle-7.png",
Use code with caution.
Lua
Modify Wizard.new (wizard.lua):
For Ashgar, load and store the idle animation frames.
Add new properties to the Wizard instance for animation control.
function Wizard.new(name, x, y, color, spellbook)
    local self = setmetatable({}, Wizard)
    -- ... (existing properties) ...

    self.idleAnimationFrames = {}
    self.currentIdleFrame = 1
    self.idleFrameTimer = 0
    self.idleFrameDuration = 0.15 -- seconds per frame (adjust for desired 
speed)

    -- Load sprite with fallback
    local spritePathBase = "assets/sprites/" .. string.lower(name)
    
    -- ... (existing sprite loading for self.sprite and 
self.castFrameSprite) ...

    -- Load idle animation frames specifically for Ashgar
    if name == "Ashgar" then
        for i = 1, 7 do
            local framePath = spritePathBase .. "-idle-" .. i .. ".png"
            local frameImg = AssetCache.getImage(framePath)
            if frameImg then
                table.insert(self.idleAnimationFrames, frameImg)
            else
                print("Warning: Could not load Ashgar idle frame: " .. 
framePath)
                -- Optional: Add a fallback, e.g., use self.sprite
                table.insert(self.idleAnimationFrames, self.sprite) 
            end
        end
        -- If no idle frames loaded, use the main sprite as a single-frame 
animation
        if #self.idleAnimationFrames == 0 then
            print("Warning: Ashgar has no idle animation frames loaded, 
using static sprite.")
            table.insert(self.idleAnimationFrames, self.sprite)
        end
    else
        -- For other wizards, populate with their main sprite for now
        table.insert(self.idleAnimationFrames, self.sprite)
    end
    
    -- ... (rest of Wizard.new) ...
    return self
end
Use code with caution.
Lua
Acceptance Criteria:
Ashgar's idle animation frames are preloaded at game start.
The Wizard object for Ashgar contains the idleAnimationFrames table 
populated with image objects.
currentIdleFrame, idleFrameTimer, and idleFrameDuration properties are 
initialized.
