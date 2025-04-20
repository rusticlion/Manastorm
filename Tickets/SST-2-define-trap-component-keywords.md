# Ticket #SST-2: Define Trap Component Keywords

## Description
Create the keywords used to define the parameters of a Trap spell (trap_trigger, trap_window, trap_effect). These keywords will only store data in the spell's execution results; they won't implement the trap logic itself yet.

## Tasks

### Define Keywords (keywords.lua)
Create entries for:

#### trap_trigger
- Behavior: { storesTriggerCondition = true, category = "TRAP" }
- Execute: `function(params, caster, target, results, events) results.trapTrigger = params return results end` (Stores data like { condition = "on_opponent_elevate" })

#### trap_window
- Behavior: { storesWindowCondition = true, category = "TRAP" }
- Execute: `function(params, caster, target, results, events) results.trapWindow = params return results end` (Stores data like { duration = 5.0 } or { condition = "until_next_conjure" })

#### trap_effect
- Behavior: { storesEffectPayload = true, category = "TRAP" }
- Execute: `function(params, caster, target, results, events) results.trapEffect = params return results end` (Stores the keyword structure for the effect, e.g., { damage = { amount = 10 } })

### Update Spell Compiler (spellCompiler.lua)
- Ensure compileSpell correctly processes these new keywords
- Verify that executeAll populates results.trapTrigger, results.trapWindow, and results.trapEffect when these keywords are present in a spell definition

## Acceptance Criteria
- The three trap keywords (trap_trigger, trap_window, trap_effect) exist and are processed by the compiler
- When a spell using these keywords is executed via executeAll, the corresponding results.trapTrigger, results.trapWindow, and results.trapEffect fields contain the parameters defined in the spell
- These keywords produce no side effects or events on their own

## Pitfalls
The structure stored in results.trapEffect must be a valid keyword definition that can be processed later by the EventRunner.