# Ticket #VFX-R2: Implement VisualResolver Module

## Goal
Provide a central module that maps enriched gameplay events to VFX template names and parameters, decoupling gameplay logic from visual implementation.

## Tasks
1. **Create File (`systems/VisualResolver.lua`):**
   * Implement a new module file under `systems/` named `VisualResolver.lua`.

2. **Define Mapping Tables:**
   * `BASE_BY_ATTACK` – maps `Constants.AttackType` values to base VFX template names (e.g., `proj_base`, `beam_base`).
   * `COLOR_BY_AFF` – maps `Constants.TokenType` (affinities) to `Constants.Color` tables.
   * `TAG_ADDONS` – maps keyword tags (e.g., `burn`, `conjure`, `shield`) to overlay VFX template names (e.g., `ember_overlay`, `sparkle_overlay`).
   * `AFFINITY_MOTION` – maps `Constants.TokenType` values to `Constants.MotionStyle` (to be defined in next ticket).

3. **Implement `VisualResolver.pick(event)` Function:**
   * First, check `event.effectOverride`; if present, return it directly (`base`, `opts = {}`).
   * Determine base template using `BASE_BY_ATTACK[event.attackType]` (fallback to `impact_base`).
   * Determine color tint using `COLOR_BY_AFF[event.affinity]` (fallback to white).
   * Calculate scale based on `event.manaCost` (`0.8 + 0.15 * (event.manaCost or 1)`).
   * Determine motion style using `AFFINITY_MOTION[event.affinity]` (fallback to `Constants.MotionStyle.RADIAL`).
   * Build `addons` list from `event.tags` via `TAG_ADDONS`.
   * Return two values: `baseTemplateName`, and `opts` table containing `{ color, scale, motion, addons, rangeBand = event.rangeBand, elevation = event.elevation }`.

## Acceptance Criteria
* `systems/VisualResolver.lua` exists with mapping tables and a working `pick` function.
* Function returns appropriate defaults for unknown values.
* Unit tests or debug prints confirm correct mapping when fed sample events.

## Design Notes / Pitfalls
* Keep mappings data-driven for easy tweaking by designers.
* Ensure `Constants` tables are required safely to avoid circular deps.
* The `opts` table should be forward-compatible with additional parameters. 