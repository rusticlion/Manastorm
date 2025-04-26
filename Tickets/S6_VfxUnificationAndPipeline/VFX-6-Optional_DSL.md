# Ticket #VFX-6 (Optional): Implement Designer-Friendly VFX Preset DSL

## Goal
Create a simple, text-based Domain Specific Language (DSL) for defining VFX presets, allowing artists or designers to tweak effect parameters without modifying Lua code.

## Tasks

1.  **Define DSL Syntax:**
    *   Design a simple, readable syntax. Example:
        ```pgsql
        effect "firebolt" {
            type = "projectile" -- Corresponds to VFX.updateProjectile/drawProjectile
            duration = 1.0
            color = ORANGE -- Use color names mapped to Constants.Color
            particle {
                asset = "fireParticle" -- Maps to VFX.assetPaths key
                count = 20
                startScale = 0.5
                endScale = 1.0
            }
            trail {
                length = 12
            }
            impact { -- Optional section for impact parameters
                size = 1.4
                sound = "fire_impact" -- Optional sound trigger
            }
            sound = "fire_whoosh" -- Main sound
        }

        effect "impact_generic" {
            type = "impact"
            duration = 0.5
            color = SMOKE
            particle {
                asset = "sparkle"
                count = 15
                startScale = 0.8
                endScale = 0.2
            }
            ring { -- Parameters for the expanding ring
                 asset = "impactRing"
                 radius = 30
            }
        }
        ```

2.  **Create DSL Parser (`core/VFX_Parser.lua`):**
    *   Implement a basic Lua parser for the defined syntax. This could use string patterns (`string.gmatch`), LPEG, or a simpler line-by-line approach depending on complexity.
    *   The parser should take the DSL text file content as input.
    *   It should output a Lua table structure that mirrors the `VFX.effects` registry in `vfx.lua`.

3.  **Load DSL at Startup (`vfx.lua`):**
    *   Modify `VFX.init`.
    *   Read the content of a definition file (e.g., `assets/vfx/presets.vfx`).
    *   Call the parser to convert the text into a Lua table.
    *   Use this parsed table to populate `VFX.effects`, potentially overwriting or merging with any hardcoded defaults.

4.  **Update VFX System to Use Parsed Data:**
    *   Ensure `VFX.createEffect` and the `VFX.update*`/`VFX.draw*` functions correctly read parameters from the parsed `VFX.effects` structure (e.g., `effect.particle.count`, `effect.ring.radius`).

## Deliverables
-   Definition of the VFX DSL syntax (e.g., in `docs/VFX_DSL_Syntax.md`).
-   `core/VFX_Parser.lua` module capable of parsing the DSL.
-   Example `assets/vfx/presets.vfx` file defining at least `firebolt` and `impact` using the DSL.
-   Updated `vfx.lua` to load and use the DSL file at startup.
-   Manual Test: Modify parameters in `presets.vfx` (e.g., change `firebolt` color or particle count), restart the game, and verify the visual changes take effect.

## Design Notes/Pitfalls
-   Parsing can be complex. Start with a very simple syntax and parser. Avoid overly nested structures initially.
-   Error handling in the parser is important to provide feedback on syntax errors in the DSL file.
-   Need a mapping from DSL color names ("ORANGE") to `Constants.Color` tables.
-   This adds a dependency on the parser and the DSL file format.