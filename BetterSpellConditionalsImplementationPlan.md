~Implementation Plan for Better Spell Conditionals

  Step 1: Add a Generic Parameter Resolver

  1. Add the resolve() utility function in keywords.lua at the top level,
  before the Keywords table:

  -- Utility: resolve a param that may be a callable
  local function resolve(value, caster, target, slot, default)
      if type(value) == "function" then
          local ok, result = pcall(value, caster, target, slot)
          return ok and result or default
      end
      return value ~= nil and value or default
  end

  2. Export the utility function for use by other modules:

  Keywords.util = { resolve = resolve }

  Step 2: Update Existing Keywords to Use the Resolver

  1. Patch all keywords that directly use param fields to use the 
resolve()
   function:

    - Start with tokenShift (currently doesn't evaluate callables):

  execute = function(params, caster, target, results, events)
      local tokenType = resolve(params.type, caster, target,
  results.currentSlot, "fire")
      local amount = resolve(params.amount, caster, target,
  results.currentSlot, 1)

      table.insert(events or {}, {
          type = "SHIFT_TOKEN",
          source = "caster",
          target = "pool",
          tokenType = tokenType,
          amount = amount,
          shiftTarget = params.target or "self"
      })
      return results
  end
  2. Apply similar changes to other keywords that access params directly:
    - ground
    - rangeShift
    - forcePull
    - conjure
    - dissipate
    - disruptAndShift
    - slow
    - accelerate
    - dispel
    - disjoint
    - freeze
    - block
    - reflect
    - echo
    - zoneAnchor
    - zoneMulti
    - consume
  3. Replace custom conditional logic with resolver pattern:
    - Replace the conditional handling in damage with the resolver.
    - Replace the conditional handling in ground with the resolver.

  Step 3: Create Helper Expression Utilities

  1. Create a new file manaHelpers.lua in the systems directory:

  -- systems/ManaHelpers.lua
  -- Provides utility functions for working with tokens in the mana pool

  local ManaHelpers = {}

  -- Count tokens of a specific type in the mana pool
  function ManaHelpers.count(tokenType, manaPool)
      local count = 0
      if not manaPool or not manaPool.tokens then return 0 end

      for _, token in ipairs(manaPool.tokens) do
          if token.type == tokenType and token.state == "FREE" then
              count = count + 1
          end
      end

      return count
  end

  -- Get the most abundant token type from options
  function ManaHelpers.most(tokenTypes, manaPool)
      local maxCount = -1
      local maxType = nil

      for _, tokenType in ipairs(tokenTypes) do
          local count = ManaHelpers.count(tokenType, manaPool)
          if count > maxCount then
              maxCount = count
              maxType = tokenType
          end
      end

      return maxType
  end

  -- Get the least abundant token type from options
  function ManaHelpers.least(tokenTypes, manaPool)
      local minCount = math.huge
      local minType = nil

      for _, tokenType in ipairs(tokenTypes) do
          local count = ManaHelpers.count(tokenType, manaPool)
          if count < minCount and count > 0 then
              minCount = count
              minType = tokenType
          end
      end

      return minType
  end

  return ManaHelpers

  2. Create an expr.lua file for expression helpers:

  -- expr.lua
  -- Expression helper functions for spell parameter evaluation

  local Constants = require("core.Constants")
  local ManaHelpers = require("systems.ManaHelpers")

  local expr = {}

  -- Choose whichever token is more abundant in the shared pool
  function expr.more(a, b)
      return function(caster)
          local manaPool = caster and caster.manaPool
          return ManaHelpers.count(a, manaPool) > ManaHelpers.count(b,
  manaPool) and a or b
      end
  end

  -- Choose the scarcer token
  function expr.less(a, b)
      return function(caster)
          local manaPool = caster and caster.manaPool
          return ManaHelpers.count(a, manaPool) < ManaHelpers.count(b,
  manaPool) and a or b
      end
  end

  -- Choose a token type based on a condition
  function expr.ifCond(condition, trueValue, falseValue)
      return function(caster, target, slot)
          if condition(caster, target, slot) then
              return trueValue
          else
              return falseValue
          end
      end
  end

  -- Choose a value based on elevation state
  function expr.byElevation(elevationValues)
      return function(caster, target, slot)
          local entityToCheck = target or caster
          local elevation = entityToCheck and entityToCheck.elevation or
  "GROUNDED"
          return elevationValues[elevation] or elevationValues.default
      end
  end

  -- Choose a value based on range state
  function expr.byRange(rangeValues)
      return function(caster, target, slot)
          local rangeState = caster and caster.gameState and
  caster.gameState.rangeState or "NEAR"
          return rangeValues[rangeState] or rangeValues.default
      end
  end

  return expr

  Step 4: Update the Infinite Procession Spell

  Update the "Infinite Procession" spell in spells.lua to use the new
  expression helpers:

  Spells.infiniteprocession = {
      id = "infiniteprocession",
      name = "Infinite Procession",
      affinity = Constants.TokenType.MOON,
      description = "Transmutes MOON tokens into SUN or SUN into MOON.",
      attackType = Constants.AttackType.UTILITY,
      castTime = Constants.CastSpeed.FAST,
      cost = {},
      keywords = {
          tokenShift = {
              type = expr.more(Constants.TokenType.SUN,
  Constants.TokenType.MOON),
              amount = 1
          }
      },
      vfx = "infinite_procession",
      sfx = "conjure_infinite",
  }

  Step 5: Documentation and Examples

  1. Update the documentation for keywords.lua to include examples of the
  new parameter resolution:

  -- Add to documentation at the top of keywords.lua:
  --
  -- Parameter resolution:
  -- Keyword parameters can now be static values or functions. If a 
  function is provided, 
  -- it will be called with (caster, target, slot) and the result used as 
  the parameter value.
  --
  -- Example static parameter:
  --   damage = { amount = 10 }
  --
  -- Example function parameter:
  --   damage = { 
  --     amount = function(caster, target, slot)
  --       return target.elevation == "AERIAL" and 15 or 10
  --     end
  --   }
  --
  -- Example using expression helpers:
  --   tokenShift = {
  --     type = expr.more(Constants.TokenType.SUN, 
  Constants.TokenType.MOON),
  --     amount = 1
  --   }

  2. Create example spells that showcase the new conditional expressions.

  Step 6: Testing and Integration

  1. Write test spells that use the new parameter resolution:
    - Write a spell that uses expr.more()
    - Write a spell that uses expr.less()
    - Write a spell that uses expr.ifCond()
    - Write a spell that uses expr.byElevation()
    - Write a spell that uses expr.byRange()
  2. Test each spell to ensure that the parameter resolution works
  correctly.
  3. If needed, implement some optimization features mentioned in the
  document:
    - Context struct for cleaner function signatures
    - Compile-time pre-resolution for pure functions
    - Declarative mini-DSL if desired

  Step 7: Code Cleanup

  1. Remove any redundant conditional handling code in keywords that is 
now
   superseded by the resolver.
  2. Update all keywords to use a consistent pattern for parameter
  resolution.
  3. Add explicit type checking and validation in the resolver function 
for
   more robust error handling.

  Step 8: Performance Optimization

  1. Add caching for frequently evaluated expressions to avoid redundant
  calculations.
  2. Implement the optional compile-time pre-resolution of static
  expressions in the SpellCompiler.

  This implementation plan will introduce a more flexible and maintainable
  way to handle conditional parameters in spell definitions, making the
  code more reusable and reducing duplication.~
