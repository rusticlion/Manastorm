# Spell Visual Language v1 (Chunky Blocks + Per-Effect CA)

- Pixel style: chunky blocks rendered crisply with nearest-neighbor filtering; integer snapping for draw positions/sizes.
- CA overlays: subtle, local grids bound to each effect’s main point (projectile head, zone center, beam path midpoint) to add motion/texture.

## Mapping
- Affinity → color: uses `Constants.getColorForTokenType`.
- Attack type → base template: via `VisualResolver` (`PROJ_BASE`, `BEAM_BASE`, `BLAST_BASE`, `REMOTE_BASE`, `AURA/ZONE`, `SURGE_BASE`).
- Range/Elevation → motion/arc: FAR raises arcs and trails; AERIAL offsets source/target.
- Magnitude → `blockSize` and density: `blockSize` defaults 3 (NEAR) / 4 (FAR), scales with mana/damage; clamp 2–6.
- Tags → overlays: DAMAGE/DOT/MOVEMENT/SHIELD use existing overlay templates.

## Tuning Knobs (from `VisualResolver.pick`)
- `useBlocky` (bool): enable blocky drawing path.
- `blockSize` (int): 2–6, default derived from range and magnitude.
- `enableCA` (bool): if true, per-effect CA overlay enabled.
- `caProfile`:
  - `cellSize`: defaults to `blockSize` (clamped 2–6)
  - `gridSize`: 24 (small, local grid)
  - `alpha`: 0.16–0.22 (subtle)
  - `stepRate`: 2–3 gens/sec

## Implementation Notes
- New helpers:
  - `vfx/BlockRenderer.lua`: snapped block drawing (single and batched).
  - `vfx/CARenderer.lua`: small CA grid per effect with B3/S23-like rule.
- Resolver: `systems/VisualResolver.lua` now returns `blockSize`, `useBlocky`, `enableCA`, and `caProfile` alongside existing options.
- VFX plumbing: `vfx.lua` stores/resets `blockSize`/`useBlocky`; effects can read `effect.blockSize` and `effect.options`.
- Effects updated: `projectile.lua`, `impact.lua`, `beam.lua`, `cone.lua`, `remote.lua`, `aura.lua` draw blocks and invoke CA overlay when enabled.
- Startup: `main.lua` sets `love.graphics.setDefaultFilter('nearest','nearest')` and `setLineStyle('rough')`.

## Performance
- Blocks use filled rects with integer snapping; prefer batching when possible (`BlockRenderer.drawBlocks`).
- CA grids are tiny (24×24) and step at low frequency; alpha is low to avoid heavy overdraw.
- Consider disabling CA for >N concurrent effects (future toggle) or reducing `gridSize`.

## Visual Guidelines
- Keep CA subtle; use alpha < 0.35. Favor negative space (don’t cover wizard silhouettes or UI text).
- Use higher `blockSize` for impactful spells; lower at NEAR for clarity.
- For beams, place sparse block markers along path; for auras/remote, center CA grid; for projectiles, track head.

## Testing
- Use existing `tools/test_vfx_events.lua` to spawn templates; compare NEAR/FAR, grounded/aerial.
- Visual toggles to consider adding: show CA grid bounds, freeze CA, force blockSize.