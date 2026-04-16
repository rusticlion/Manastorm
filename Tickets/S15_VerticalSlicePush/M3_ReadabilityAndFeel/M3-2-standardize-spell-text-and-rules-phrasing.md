# M3-2: Standardize Spell Text And Rules Phrasing

**Goal:** Make spell descriptions consistent, player-facing, and trustworthy as a rules communication layer.

## Tasks

### 1. Audit Current Spell Copy
- Review spell descriptions across `spells/elements/`.
- Flag:
  - placeholder text
  - inconsistent capitalization or terminology
  - unclear references to slots/range/elevation
  - descriptions that omit the actual tactical hook

### 2. Define A Text Style Rule
- Standardize phrasing for:
  - range terms
  - elevation terms
  - slot references
  - status names
  - shield/block terminology

### 3. Rewrite The Current Roster First
- Prioritize the actively playable/demo-targeted spellbooks before polishing every dormant spell.
- Match descriptions to actual runtime behavior, not design intent from older versions.

### 4. Sanity-Check Against Gameplay
- Spot-check rewritten descriptions against live behavior and automated tests.
- Do not ship cleaner prose that lies about the real rule.

## Acceptance Criteria

- Spell descriptions are consistent in tone and terminology.
- No obvious placeholder phrasing remains in the active roster.
- Players can infer the key tactical use of a spell from its description.

## Dependencies

- Should happen before external playtests and before finalizing demo onboarding.
