# M4-3: Improve AI For The Demo Roster Only

**Goal:** Raise AI quality where it matters for the vertical slice without turning this milestone into a general-purpose AI rewrite.

## Tasks

### 1. Narrow The Scope
- Focus only on the four demo characters selected in M4-1.
- Do not broaden AI work to unfinished roster entries in this milestone.

### 2. Improve Character Expression
- Tune personalities so each demo wizard demonstrates its intended combat fantasy.
- Improve spell selection, counter timing, and defensive behavior where current AI feels generic or self-sabotaging.

### 3. Improve Demonstration Value
- Make sure AI supports:
  - solo player practice
  - attract mode
  - internal matchup evaluation

### 4. Add Targeted Validation
- Add narrow tests or scripted checks where AI logic can regress cheaply.
- Otherwise rely on focused playtesting against the demo roster.

## Acceptance Criteria

- AI for the four demo wizards feels intentionally different.
- Solo play against the AI is useful for learning and balancing the roster.
- Attract mode presents the game well enough for passive observation.

## Dependencies

- Requires M4-1 and should follow M4-2 so the AI is tuned against stable loadouts.
