# AS-5: Remove The Compiler EventRunner Fallback

**Goal:** Replace `spellCompiler.lua`'s dummy EventRunner fallback with explicit dependency boundaries and clear failure behavior.

## Tasks

### 1. Audit Load Order
- Review `spellCompiler.lua`, `keywords.lua`, `systems/EventRunner.lua`, and `spells/init.lua`.
- Identify which dependency cycle is still real and which fallback code is legacy padding.

### 2. Make Runtime Dependencies Explicit
- Ensure compiled spells execute against the real EventRunner in normal runtime paths.
- Preserve headless tooling that compiles spells without a full game loop.

### 3. Fail Clearly
- If EventRunner cannot be loaded in a path that needs it, report a clear error.
- Do not silently process zero events through a dummy stand-in.

### 4. Add Validation
- Add or update a tool-level assertion so the real compile/execute path is protected.

## Acceptance Criteria

- `spellCompiler.lua` no longer masks load-order failures with a dummy EventRunner.
- Legitimate tooling still works.
- Misconfiguration fails loudly and specifically.
- Core validation commands pass.

