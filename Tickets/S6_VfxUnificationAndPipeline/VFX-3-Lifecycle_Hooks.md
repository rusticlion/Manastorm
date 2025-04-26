# Ticket #VFX-3: Standardize VFX Triggering from Lifecycle Hooks

## Goal
Ensure that game systems outside of direct spell casting (like token destruction, shield creation, elevation changes) trigger their associated VFX consistently through the `EventRunner` system, rather than calling the VFX module directly.

## Tasks

1.  **Create EventRunner Helper (`systems/EventRunner.lua`):**
    *   Add a new utility function to `EventRunner` (or a dedicated `GameEventManager` module if preferred):
        ```lua
        -- Function to queue a visual effect event from game systems
        function EventRunner.queueVisual(effectType, x, y, vfxParams)
            if not effectType or not x or not y then
                print("Warning: Invalid parameters for EventRunner.queueVisual")
                return
            end
            
            -- Basic event structure for a visual effect originating from game logic
            local visualEvent = {
                type       = "EFFECT",
                source     = "system", -- Indicate it's from game logic, not a specific spell caster
                target     = "world", -- Or maybe coordinates? Target is less relevant here.
                effectType = effectType,
                -- Store coordinates and params for the handler
                posX       = x, 
                posY       = y,
                vfxParams  = vfxParams or {} 
            }
            
            -- In a more robust system, you'd add this to an event queue.
            -- For now, we can process it immediately for simplicity, but beware of order issues.
            -- Let's assume immediate processing via handleEvent for now.
            print("[EventRunner] Queuing visual: " .. effectType .. " at " .. x .. "," .. y)
            -- We need dummy caster/target for handleEvent signature, can use nil or global game state
            EventRunner.handleEvent(visualEvent, _G.game, nil, nil, {}) 
        end
        ```
    *   Modify the `EFFECT` handler in `EventRunner.EVENT_HANDLERS` to use `event.posX`, `event.posY` if `event.source == "system"`.

2.  **Refactor Token Destruction VFX (`manapool.lua`):**
    *   Locate `TokenMethods:requestDestructionAnimation`.
    *   Find the block that calls `self.gameState.vfx.createEffect("impact", ...)`
    *   **Remove** that direct call.
    *   **Add** a call to the new helper: `local EventRunner = require("systems.EventRunner"); EventRunner.queueVisual(Constants.VFXType.IMPACT, self.x, self.y, { color = Constants.getColorForTokenType(self.type), radius = 30 })` (Pass necessary parameters like color).

3.  **Refactor Shield Creation VFX (`systems/ShieldSystem.lua`):**
    *   Locate the `ShieldSystem.createShield` function.
    *   Find the block that calls `wizard.gameState.vfx.createEffect("shield", ...)`
    *   **Remove** that direct call.
    *   **Add** a call to the new helper: `local EventRunner = require("systems.EventRunner"); EventRunner.queueVisual(Constants.VFXType.SHIELD, wizard.x, wizard.y, { shieldType = slot.defenseType, color = shieldColor })` (Pass shield type, color).

4.  **Refactor Elevation Change VFX (`systems/EventRunner.lua`):**
    *   Locate the `SET_ELEVATION` handler in `EventRunner.EVENT_HANDLERS`.
    *   Find the block that calls `safeCreateVFX(...)` for `elevation_up` or `elevation_down`.
    *   **Remove** that direct call.
    *   **Add** calls to the new helper instead:
        ```lua
        local effectConst = (event.elevation == Constants.ElevationState.AERIAL) and Constants.VFXType.EMBERLIFT or Constants.VFXType.IMPACT -- Or a specific 'LAND' effect
        EventRunner.queueVisual(effectConst, targetWizard.x, targetWizard.y, { duration = 1.0 }) 
        ```
    *   (Consider creating dedicated `Constants.VFXType.LIFT` and `Constants.VFXType.LAND` effects).

## Deliverables
-   Updated `systems/EventRunner.lua` with `queueVisual` helper and updated `EFFECT` handler.
-   Updated `manapool.lua` (`TokenMethods:requestDestructionAnimation`) to use `EventRunner.queueVisual`.
-   Updated `systems/ShieldSystem.lua` (`createShield`) to use `EventRunner.queueVisual`.
-   Updated `systems/EventRunner.lua` (`SET_ELEVATION` handler) to use `EventRunner.queueVisual`.
-   Manual Test: Verify that token destruction, shield creation, and elevation changes still trigger their expected visual effects.

## Design Notes/Pitfalls
-   The immediate processing in `queueVisual` is simple but might cause issues if the order of visual effects relative to state changes matters deeply. A proper event queue might be needed later.
-   Passing parameters like `color` and `shieldType` through `vfxParams` requires the `EFFECT` handler and `safeCreateVFX` to look inside this table when the source is "system".
-   Ensure `Constants.VFXType` includes any new effects needed (like `LAND`).