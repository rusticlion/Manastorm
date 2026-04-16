# M3-3: Complete The Minimum VFX Template Set

**Goal:** Finish the minimum set of distinct, polished VFX templates needed for the vertical slice so each major mechanical class reads immediately.

## Tasks

### 1. Use The Existing Slice Checklist
- Review the unfinished items in `docs/VerticalSliceMustHaves.md`.
- Confirm which templates still need a real polish pass:
  - warp
  - blast
  - meteor
  - fountain or equivalent sustained/field visual

### 2. Close The Resolver-To-Template Gaps
- Review `systems/VisualResolver.lua` and the effect implementations under `vfx/`.
- Ensure each target template has:
  - distinct motion
  - readable silhouette
  - affinity-driven variation
  - strong blocked/hit/resolve readability where applicable

### 3. Validate Against Real Authored Spells
- Check each template against at least one real spell that uses it in the active roster.
- Prefer improving shared templates over adding bespoke one-off effects unless the spell truly needs it.

### 4. Preserve Headless Audit Coverage
- Keep `tools/test_vfx_events.lua` passing while improving the template set.

## Acceptance Criteria

- The core mechanical visual families each have a clear, intentional visual identity.
- Active roster spells no longer rely on rough placeholder-feeling visuals for key templates.
- VFX improvements stay aligned with the rule-driven resolver pipeline.

## Validation

- `lua tools/test_vfx_events.lua`
