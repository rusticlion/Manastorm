# AS-6: Demo Architecture Slice And Interview Script

**Goal:** Prepare a small, repeatable demo path that shows the architecture working through real gameplay instead of abstract diagrams only.

## Tasks

### 1. Choose The Demo Slice
- Pick 4-6 spells that demonstrate:
  - mana cost and token acquisition
  - cast timing
  - range or elevation legality
  - shield or block resolution
  - event-driven VFX

### 2. Write The Interview Script
- Create a short document under `docs/` that says:
  - what to run
  - what to show first
  - which files to open
  - what tradeoffs to name
  - what future refactors are intentionally out of scope

### 3. Verify The Slice
- Run the demo path manually.
- Run the core validation commands.
- Capture any known rough edges so they do not become surprises.

## Acceptance Criteria

- The architecture can be demonstrated through one small duel scenario.
- The script links gameplay moments to concrete code paths.
- The demo avoids unfinished content and stale claims.

