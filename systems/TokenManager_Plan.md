# TokenManager Module Plan

## Overview
The TokenManager module will encapsulate all token-related functionality from the wizard.lua file into a centralized module, providing a cleaner API for token acquisition, management, and return. This module will work closely with the token state machine already implemented in manapool.lua.

## Purpose and Benefits
1. **Centralization of Token Logic**: Move all token-related code from wizard.lua to a dedicated module
2. **Better Code Organization**: Separate token management from wizard spell management
3. **Improved Maintainability**: Make token operations and state transitions more explicit
4. **Delegation Pattern**: Wizard.lua will delegate token operations to the TokenManager
5. **Leverage State Machine**: Build on the existing token state machine in manapool.lua

## Module Structure

### Core Functions

```lua
TokenManager.acquireTokensForSpell(wizard, spellSlot, manaCost)
```
- Takes a wizard, spell slot, and mana cost
- Acquires tokens from the mana pool based on mana cost
- Positions tokens in the spell slot with proper animation parameters
- Returns success/failure and list of acquired tokens

```lua
TokenManager.positionTokensInSpellSlot(wizard, slotIndex, tokens)
```
- Sets up token animation and positioning parameters
- Calculates 3D positioning for tokens in spell slots
- Handles animation state and timing

```lua
TokenManager.returnTokensToPool(tokens)
```
- Takes a list of tokens
- Requests return animation for each token
- Handles any special return effects

```lua
TokenManager.destroyTokens(tokens)
```
- Takes a list of tokens
- Requests destruction animation for each token

```lua
TokenManager.markTokensAsShielding(tokens)
```
- Takes a list of tokens
- Changes their state to SHIELDING
- Useful when shields are created

```lua
TokenManager.checkFizzleCondition(wizard, slotIndex, removedToken)
```
- Checks if a spell should fizzle when a token is removed
- Implements the "Law of Completion" rule

### Utility Functions

```lua
TokenManager.getTokensInSlot(wizard, slotIndex)
```
- Returns a list of all tokens in a specific spell slot

```lua
TokenManager.getTokensByType(tokens, tokenType)
```
- Filters a list of tokens by type

```lua
TokenManager.validateTokenState(token, expectedState)
```
- Validates if a token is in the expected state
- Returns true/false and error message if validation fails

## Wizard.lua Integration Plan

1. **Replace Direct Token Operations**: 
   - Change `canPayManaCost` to call `TokenManager.acquireTokensForSpell`
   - Update token handling in `queueSpell` to use TokenManager
   - Change token return handling in `castSpell` to use TokenManager.returnTokensToPool

2. **Maintain Backward Compatibility**:
   - Keep existing wizard methods as wrappers around TokenManager calls
   - Gradually update wizard code to use TokenManager directly

## Implementation Steps

1. Create the TokenManager.lua file with initial structure
2. Implement core functionality extraction from wizard.lua
3. Test TokenManager functions independently
4. Update wizard.lua to use TokenManager
5. Ensure all token lifecycle follows state machine pattern
6. Add error handling for edge cases

## Considerations

1. **Statefulness**: TokenManager should be stateless, primarily providing utility functions
2. **Error Handling**: Provide helpful error messages for common problems
3. **Logging**: Maintain token lifecycle logging for debugging
4. **Performance**: Minimize any performance impact, especially during animation
5. **Integration**: Consider how this interacts with EventRunner system

## Usage Examples

### Acquiring tokens for a spell:
```lua
local success, tokenData = TokenManager.acquireTokensForSpell(self, slotIndex, spell.manaCost)
if success then
    -- Set up spell with acquired tokens
else
    -- Handle failure to acquire tokens
end
```

### Returning tokens to the pool:
```lua
TokenManager.returnTokensToPool(self.spellSlots[slotIndex].tokens)
```

### Token state management:
```lua
if shield then
    TokenManager.markTokensAsShielding(self.spellSlots[slotIndex].tokens)
end
```

## Token State Machine Integration

The TokenManager will integrate with the token state machine in manapool.lua by:

1. Using the official token methods:
   - token:setState
   - token:requestReturnAnimation
   - token:requestDestructionAnimation

2. Avoiding direct state manipulation:
   - No setting token.state directly
   - No bypassing the token lifecycle

3. Supporting the token state lifecycle:
   ```
   FREE -> CHANNELED -> RETURNING -> FREE
                     -> SHIELDING -> RETURNING -> FREE
                     -> DISSOLVING -> POOLED
   ```

## Dependencies

1. **core/Constants.lua** - For token state constants
2. **systems/EventRunner.lua** - For event-based operations
3. **manapool.lua** - For token acquisition and state machine