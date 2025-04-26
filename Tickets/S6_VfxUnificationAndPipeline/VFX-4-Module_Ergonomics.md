# Ticket #VFX-4: Improve VFX Module Ergonomics

## Goal
Refactor the `vfx.lua` module to improve its internal organization, prepare for asynchronous operations, and optimize asset loading.

## Tasks

1.  **Consolidate Effect Registry (`vfx.lua`):**
    *   The file currently defines `VFX.effects` twice. Remove the duplicate definition and ensure only one canonical registry exists near the top of the file.
    *   Verify all effects used in `Constants.VFXType` are defined in this single registry.

2.  **Implement Basic Async Handling Stub (`vfx.lua`):**
    *   Add a new function `VFX.createEffectAsync(effectName, ...)`
    *   For now, this function can simply call the synchronous `VFX.createEffect(...)` internally.
    *   It should return a placeholder "promise" table: `return { onComplete = function(callback) print("Async VFX callback registered (stub)") end }`.
    *   *Note:* Full async/callback implementation is complex and deferred. This task only sets up the function signature and basic return structure.

3.  **Lazy Asset Loading (`vfx.lua`):**
    *   Modify the `VFX.init` function. Instead of loading all images into `VFX.assets` immediately using `AssetCache.getImage`, store *only the paths*:
        ```lua
        VFX.assetPaths = {
            fireParticle = "assets/sprites/fire-particle.png",
            fireGlow = "assets/sprites/fire-glow.png",
            -- ... etc
            runes = { -- Store paths for runes too
               "assets/sprites/runes/rune1.png",
               -- ...
            }
        }
        -- Remove the direct loading into VFX.assets here
        ```
    *   Create a helper function within `vfx.lua`:
        ```lua
        local function getAsset(assetId)
            local path = VFX.assetPaths[assetId]
            if not path then return nil end -- Handle missing asset paths
            
            -- Check if already loaded (simple cache within VFX module)
            if VFX.assets[assetId] then return VFX.assets[assetId] end 
            
            -- Load on demand using AssetCache
            print("[VFX] Lazily loading asset: " .. assetId)
            VFX.assets[assetId] = require("core.AssetCache").getImage(path) 
            return VFX.assets[assetId]
        end
        ```
    *   Update all `VFX.draw*` functions (e.g., `drawProjectile`, `drawImpact`) to call `local particleImage = getAsset("fireParticle")` etc., instead of directly accessing `VFX.assets.fireParticle`.
    *   Handle rune loading similarly within the `WizardVisuals.drawSpellSlots` function or refactor rune drawing to use `getAsset`.

## Deliverables
-   Updated `vfx.lua` with a single, consolidated `VFX.effects` registry.
-   Updated `vfx.lua` with the stub `VFX.createEffectAsync` function.
-   Updated `vfx.lua` implementing lazy loading for particle/effect assets via `getAsset`.
-   Manual Test: Verify that all visual effects still load and display correctly. Observe console output for "[VFX] Lazily loading asset:" messages during gameplay to confirm lazy loading works. Check game startup time for potential (minor) improvement.

## Design Notes/Pitfalls
-   Lazy loading slightly defers load time from startup to first use, which *could* cause a micro-hitch the very first time an effect is used if not already preloaded by `AssetPreloader`. Ensure `core/assetPreloader.lua` includes paths for common VFX assets.
-   The async stub provides the API for future expansion without needing immediate complex coroutine/callback management.
-   Remember to handle the rune assets' lazy loading as well, which might involve modifying `WizardVisuals.lua` or passing loaded assets from `vfx.lua`.