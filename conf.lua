-- Configuration
function love.conf(t)
    t.title = "Manastorm - Wizard Duel"  -- The title of the window
    t.version = "11.4"                    -- The LÖVE version this game was made for
    
    -- Base design resolution
    t.window.width = 800
    t.window.height = 600
    
    -- Allow high DPI mode on supported displays (macOS, etc)
    t.window.highdpi = true
    
    -- Make window resizable
    t.window.resizable = true
    
    -- Graphics settings
    t.window.vsync = 1                    -- Vertical sync (1 = enabled)
    t.window.msaa = 0                     -- Disable anti-aliasing to keep pixel art crisp
    
    -- For debugging
    t.console = true
    
    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = false
end