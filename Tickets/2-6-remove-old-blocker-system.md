# Ticket PROG-16: Remove Old Blocker System

## Goal
Clean up the codebase by removing the deprecated blocker system that's now replaced by the shield keyword system.

## Tasks

1. Remove wizard.blockers property and related initialization.

2. Remove all logic that manages blocker timers.

3. Remove any drawing code related to the old blocker system.

4. Ensure all references to the old blocker system are removed or migrated to the new shield system.

## Acceptance Criteria
The old blocker system is completely removed from the codebase, and all shield functionality works through the new shield system without errors.