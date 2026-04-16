# M2-4: Remove Compiler Circular-Dependency Fallback

**Goal:** Replace the current “dummy EventRunner” fallback path in `spellCompiler.lua` with explicit module boundaries and fail-fast behavior.

## Tasks

### 1. Review Current Load Order
- Audit how `spellCompiler.lua`, `keywords.lua`, `systems/EventRunner.lua`, and the `spells` module currently require each other.
- Confirm where the circular dependency risk is real versus where the fallback is legacy safety padding.

### 2. Make Dependencies Explicit
- Refactor load order or module responsibilities so `spellCompiler.lua` can obtain the real `EventRunner` without needing a dummy runtime substitute.
- Prefer clear initialization flow over defensive silent fallback.

### 3. Fail Cleanly On Real Misconfiguration
- If the event runner truly cannot be loaded, surface a clear error rather than pretending the spell resolved with zero processed events.
- Preserve headless/tooling use cases that intentionally compile spells without full runtime state.

### 4. Add Or Update Validation
- Add a regression test or tool-level assertion that protects the intended compile/execute path after the refactor.

## Acceptance Criteria

- `spellCompiler.lua` no longer relies on a dummy `EventRunner` to mask load-order problems.
- Legitimate tool workflows still work.
- Actual initialization problems fail loudly and specifically.

## Dependencies

- Best handled after M2-3 so module boundaries are clearer.
