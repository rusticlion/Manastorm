# Ticket #1 – Implement Sprite/Audio Asset Cache

## Goal
Eliminate duplicate texture loads and audio buffers; centralise behind a lightweight cache so every part of the codebase calls the same memoised accessor.

## Tasks
1. Create core/AssetCache.lua.
2. Add getImage(path) and getSound(path); store results in up‑valued tables.
3. Replace every love.graphics.newImage / love.audio.newSource call with the cache accessor (grep for newImage( and newSource()).
4. Add a flush() helper for dev‑hot‑reload (optional).
5. Unit‑test by loading the same path twice and asserting object identity.

## Deliverables
* AssetCache module.
* Refactor PR touching manapool.lua, vfx.lua, etc.
* Unit‑test spec/asset_cache_spec.lua.

## Design notes
Use weak tables if you want GC to reclaim unused assets during scene unloads.
Expose a simple metrics function (dumpStats()) for debug overlay.

## Pitfalls
Don't cache images created at runtime (e.g., canvases). Ensure synchronous load only during boot, not inside the render loop.

## Senior Feedback
* **Additional Files to Check**: Also review ui.lua and wizard.lua as they may load UI images or character-specific sounds directly. Currently, manapool.lua loads assets/sprites/token-lock.png and token images, vfx.lua loads several particle/glow images, and wizard.lua loads the base wizard sprite.
* **Global State/GC Concerns**: A global or singleton AssetCache can sometimes hold references longer than intended, especially during scene transitions. Test the flush() helper thoroughly if implemented to ensure proper cleanup during hot-reloads.
* **Load Timing**: Ensure all assets needed for the initial scene are loaded synchronously during startup (love.load) and not deferred to first use, which could cause gameplay hitches. Consider an explicit preload() function.
* **Validation**: The pitfall about not caching runtime-created images is relevant – maintain strict separation between file-based assets and dynamic canvases.