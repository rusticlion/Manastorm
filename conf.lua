-- Configuration
function love.conf(t)
    t.title = "Manastorm - Wizard Duel"  -- The title of the window
    t.version = "11.4"                    -- The LÖVE version this game was made for
    t.window.width = 800
    t.window.height = 600
    
    t.window.vsync = 1                    -- Vertical sync (1 = enabled)
    t.window.msaa = 2                     -- Anti-aliasing (smoothing)
    
    -- For debugging
    t.console = true
    
    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = false
end