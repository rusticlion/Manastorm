# Ticket #SST-1: Foundation - The sustain Keyword & Slot Retention

## Description
Introduce the core concept of a "sustained" spell that keeps its slot active and mana locked after its initial cast time completes. This is the foundation for both Shields and Traps.

## Tasks

### Define Keyword (keywords.lua)
- Create Keywords.sustain
- Behavior: { marksSpellAsSustained = true, category = "TIMING" }
- Execute: `function(params, caster, target, results, events) results.isSustained = true return results end`

### Modify Spell Compiler (spellCompiler.lua)
- Ensure compileSpell processes the sustain keyword
- Ensure executeAll correctly adds results.isSustained = true when the keyword is present

### Modify Casting Logic (wizard.lua -> Wizard:castSpell)
- After the line `effect = spellToUse.executeAll(self, target, {}, spellSlot)`, add a check: `local shouldSustain = effect.isSustained or false`
- Modify the existing logic block that handles non-shield spell completion: Wrap the calls to `TokenManager.returnTokensToPool(slot.tokens)` and `self:resetSpellSlot(spellSlot)` inside an `if not shouldSustain then ... end` block
- Crucially: Ensure that if shouldSustain is true, the tokens in slot.tokens remain in their CHANNELED state (or a similar 'in use' state) and are not returned. Verify that TokenManager.returnTokensToPool isn't called elsewhere implicitly for these sustained spells upon cast completion

## Acceptance Criteria
- A spell defined with `keywords = { sustain = true, ... }` completes its cast timer but the spell slot remains `active = true`
- The mana tokens for the sustained spell remain associated with the slot (in slot.tokens) and in the CHANNELED state, not returning to the mana pool
- The visual progress arc for the sustained spell remains full
- Regular, non-sustained spells complete, return tokens, and reset their slots as normal

## Design Notes
This ticket focuses only on preventing the slot reset for sustained spells. Expiry/triggering comes later. We use CHANNELED for now, assuming it prevents reuse/return.