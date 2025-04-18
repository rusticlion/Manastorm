# Manastorm Core Systems

This directory contains core systems and utilities for the Manastorm game.

## AssetCache

A centralized cache for game assets to prevent duplicate loads and enable hot-reloading during development.

- `AssetCache.getImage(path)`: Load an image once, return cached version on subsequent calls
- `AssetCache.getSound(path, [soundType])`: Load a sound once, return cached version on subsequent calls
- `AssetCache.preload(manifest)`: Preload a collection of assets at once
- `AssetCache.flush()`: Clear the cache (for hot-reloading)
- `AssetCache.dumpStats()`: Get cache statistics

## AssetPreloader

A utility for preloading all game assets at startup to prevent in-game hitches.

- `AssetPreloader.preloadAllAssets()`: Preload all game assets
- `AssetPreloader.reloadAllAssets()`: Hot-reload all game assets 
- `AssetPreloader.getStats()`: Get preloader statistics

## Input

A unified input handling system that routes keyboard events to the appropriate handlers.

### Key Routes

The Input system organizes key handlers by category:

- `Input.Routes.system`: System-level controls (scaling, fullscreen, quit)
- `Input.Routes.p1`: Player 1 controls
- `Input.Routes.p2`: Player 2 controls
- `Input.Routes.debug`: Debug controls (only available outside gameOver state)
- `Input.Routes.test`: Test controls (only available outside gameOver state)
- `Input.Routes.ui`: UI controls (available in any state)
- `Input.Routes.gameOver`: Game over state controls

### Reserved Keys

The Input system maintains a list of all reserved keys by category in `Input.reservedKeys`. 
This can be displayed in-game by pressing \` to open the debug overlay, then TAB to show the hotkey list.

### Integration

To integrate the Input system:

1. Add `local Input = require("core.Input")` to your imports
2. Initialize the Input system with `Input.init(gameState)` 
3. Replace your love.keypressed function with:
   ```lua
   function love.keypressed(key, scancode, isrepeat)
       return Input.handleKey(key, scancode, isrepeat)
   end
   ```
4. Replace your love.keyreleased function with:
   ```lua
   function love.keyreleased(key, scancode)
       return Input.handleKeyReleased(key, scancode)
   end
   ```

### Adding New Inputs

To add a new input handler, add a function to the appropriate route table:

```lua
Input.Routes.ui["f1"] = function()
    -- Display help screen
    showHelp()
    return true
end
```

The function should return `true` if it handled the input, or `false` to allow other handlers to process it.

## Constants

A centralized repository of game constants and enums to ensure type safety and prevent string literal mistakes.

## Pool

Object pooling system to reduce garbage collection and frame spikes. Allows for reuse of frequently created and destroyed objects like visual effects particles and mana tokens.

### Pool Features

- **Acquire/Release Pattern**: Simple API for obtaining objects from the pool and returning them when finished
- **Automatic Growth**: Pools grow automatically when demand exceeds supply
- **Configurable Factory & Reset**: Each pool has customizable functions for creating new objects and resetting released objects
- **Multi-Pool Support**: Maintains separate pools for different object types
- **Debugging Tools**: Built-in statistics tracking and visual debug overlay
- **Minimal Overhead**: Designed for high-performance real-time applications

### Usage Examples

Creating a pool:

```lua
Pool.create("token", 50, function() 
    return {} -- Factory function
end, function(obj)
    -- Reset function that clears all fields
    for k, _ in pairs(obj) do
        obj[k] = nil
    end
    return obj
end)
```

Getting an object:

```lua
local object = Pool.acquire("token")
object.type = "fire"
object.x = 100
object.y = 200
-- Other property initialization
```

Returning an object:

```lua
Pool.release("token", object)
```

Viewing statistics:

```lua
Pool.printStats()
```

Debug Overlay (in love.draw):

```lua
Pool.drawDebugOverlay()
```

### Implementation Notes

The Pool system was primarily implemented in three areas:

1. Core Pool Module (`core/Pool.lua`)
2. Mana Token Pooling (`manapool.lua`)
3. VFX Particle Pooling (`vfx.lua`)

Test scripts are available in `tools/test_pools.lua` to verify correct behavior.