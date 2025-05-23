# SCT-5: Documentation & Testing

**Goal:** Document the new dynamic cost feature and ensure robust testing.

## Tasks

### 1. Update docs/spellcasting.md
- Explain the `getCost` function in spell definitions
- Provide an example of its usage

### 2. Update docs/wizard.md
- Mention how `canPayManaCost` and `queueSpell` handle dynamic costs

### 3. Update docs/DevelopmentGuidelines.md
- Add a section on defining spells with dynamic costs

### 4. Unit/Integration Tests (if a testing framework is in place, otherwise manual)
- Test `Wizard:canPayManaCost` with static and dynamic cost spells under various conditions
- Test `Wizard:queueSpell` ensuring correct token acquisition
- Test AI's ability to evaluate and cast dynamically-costed spells
- Test UI display

## Acceptance Criteria
- Relevant documentation is updated
- The feature is tested and works reliably under various game states

## Testing Scenarios
1. **Static Cost Spells** - Ensure existing spells continue to work normally
2. **Dynamic Cost Spells** - Test both example spells under various conditions:
   - Desperation Fire at different health levels
   - Moon Drain with different opponent STAR token counts
3. **AI Behavior** - Verify AI correctly evaluates affordability of dynamic spells
4. **UI Display** - Check that spellbook shows correct dynamic costs
5. **Edge Cases** - Test with nil targets, extreme values, etc.