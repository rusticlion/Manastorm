# AS-2: Architecture One-Pager And Spell Lifecycle Trace

**Goal:** Create interview-ready documentation that explains Manastorm's core architecture without requiring the reader to already know the whole codebase.

## Tasks

### 1. Write The One-Pager
- Create a concise document under `docs/` that explains:
  - spell definitions as data
  - keyword compilation
  - event emission
  - EventRunner combat authority
  - VisualResolver/VFX interpretation
  - where wizard, mana, shields, and sustained spells fit

### 2. Trace One Representative Spell
- Pick a readable spell that exercises the core path.
- Link its definition, keyword behavior, compiled execution, event handling, and VFX resolution.

### 3. Document Boundaries And Exceptions
- State which layer owns combat outcomes, slot lifecycle, token lifecycle, visual dispatch, and local wizard state.
- Call out any remaining transitional exceptions honestly.

### 4. Add Interview Notes
- Include a short "how to talk through this" section with the code path to open live.

## Acceptance Criteria

- A contributor can understand the spell pipeline from one document.
- The document references current code paths and does not describe stale behavior.
- The doc can double as a show-and-tell outline.

