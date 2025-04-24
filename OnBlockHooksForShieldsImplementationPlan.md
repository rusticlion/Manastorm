~Implementation Plan for Adding On-Block Hooks for Shields

  Step 1: Update Keywords.block to support onBlock callbacks

  This is a small change to the Keywords.block.execute function in
  keywords.lua to pass the onBlock parameter through to the CREATE_SHIELD
  event.

  File: keywords.lua
  Location: Inside the Keywords.block.execute function, around line 725

  -- Modified execute function in Keywords.block
  execute = function(params, caster, target, results, events)
      -- Mark the spell as sustained
      results.isSustained = true
      print("[DEBUG] Block keyword setting results.isSustained = true")

      table.insert(events or {}, {
          type = "CREATE_SHIELD",
          source = "caster",
          target = "self_slot", -- Shields are created in the caster's 
slot
          slotIndex = results.currentSlot, -- Use the slot the spell was 
  cast from
          defenseType = params.type or "barrier",
          blocksAttackTypes = params.blocks or {"projectile"},
          reflect = params.reflect or false,
          onBlock = params.onBlock -- Add support for the onBlock callback
      })
      return results
  end

  Step 2: Update ShieldSystem.createShield to store the onBlock handler

  File: systems/ShieldSystem.lua
  Location: Inside the createShield function around line 32

  -- Update shield parameters in ShieldSystem.createShield
  -- Set shield parameters - simplified to use token count as the only 
  source of truth
  slot.isShield = true
  slot.defenseType = blockParams.type or "barrier"

  -- Store the original spell completion
  slot.active = true
  slot.progress = slot.castTime -- Mark as fully cast

  -- Store the onBlock handler if provided
  slot.onBlock = blockParams.onBlock -- Add this line

  -- Continue with existing code...

  Step 3: Modify ShieldSystem.handleShieldBlock to invoke the onBlock 
  callback

  File: systems/ShieldSystem.lua
  Location: At the end of the handleShieldBlock function before the return
  statement, around line 247

  -- After the shield hit VFX code, add the onBlock hook invocation
  -- Trigger shield hit VFX
  if wizard.gameState and wizard.gameState.vfx then
      -- existing VFX code...
  end

  -- Add support for on-block effects
  if slot.onBlock then
      local EventRunner = require("systems.EventRunner")
      local ok, blockEvents = pcall(slot.onBlock,
                                    wizard,          -- defender (owner of 
  the shield)
                                    incomingSpell and 
incomingSpell.caster,
   -- attacker (may be nil)
                                    slotIndex,
                                    { blockType = slot.defenseType })
      if ok and type(blockEvents) == "table" and #blockEvents > 0 then
          EventRunner.processEvents(blockEvents, wizard, incomingSpell and
  incomingSpell.caster, slotIndex)
      elseif not ok then
          print("[SHIELD ERROR] Error executing onBlock handler: " ..
  tostring(blockEvents))
      end
  end

  -- The checkFizzleOnTokenRemoval method handles the actual shield 
  breaking (slot reset)
  return true

  Step 4: Update the Wings of Moonlight spell to use the onBlock hook

  File: spells.lua
  Location: Spells.wrapinmoonlight definition around line 499

  Spells.wrapinmoonlight = {
      id = "wrapinmoonlight",
      name = "Wings of Moonlight",
      affinity = Constants.TokenType.MOON,
      description = "Ward that elevates the caster each time it blocks.",
      attackType = "utility",
      castTime = Constants.CastSpeed.FAST,
      cost = {Constants.TokenType.MOON, "any"},
      keywords = {
          block = {
              type = Constants.ShieldType.WARD,
              blocks = {Constants.AttackType.PROJECTILE,
  Constants.AttackType.ZONE},

              -- Add onBlock hook to emit a SET_ELEVATION event each time 
  the ward absorbs a hit
              onBlock = function(defender, attacker, slot, info)
                  return {{
                      type = "SET_ELEVATION",
                      source = "caster",  -- defender is the caster for 
  shields
                      target = "self",
                      elevation = Constants.ElevationState.AERIAL,
                      duration = 4.0,
                      vfx = "mist_veil"
                  }}
              end
          }
          -- Remove the original elevate keyword as it's now handled by 
the
   onBlock handler
      },
      vfx = "mist_veil",
      sfx = "mist_shimmer",
      blockableBy = {}  -- Utility spell, can't be blocked
  }

  Step 5: Create a new Mirror Shield spell to showcase the onBlock 
callback

  File: spells.lua
  Location: Add a new spell after other shield spells (around line 835)

  -- Enhanced Mirror Shield with direct damage reflection via onBlock
  Spells.enhancedmirrorshield = {
      id = "enhancedmirrorshield",
      name = "Enhanced Mirror Shield",
      description = "A powerful reflective barrier that returns damage to 
  attackers with interest",
      attackType = "utility",
      castTime = 6.0,
      cost = {Constants.TokenType.MOON, Constants.TokenType.STAR,
  Constants.TokenType.STAR},
      keywords = {
          block = {
              type = Constants.ShieldType.BARRIER,
              blocks = {Constants.AttackType.PROJECTILE,
  Constants.AttackType.ZONE},

              -- Add a custom onBlock handler to implement reflection 
logic
              onBlock = function(defender, attacker, slotIndex, blockInfo)
                  -- Only reflect if we have an attacker
                  if not attacker then return {} end

                  -- Generate damage reflection events
                  local events = {}

                  -- Create a damage reflection event
                  table.insert(events, {
                      type = "DAMAGE",
                      source = "caster", -- The defender becomes the 
source
                      target = "enemy",  -- The attacker becomes the 
target
                      amount = 10,       -- Fixed reflection damage
                      damageType = "star",
                      reflectedDamage = true
                  })

                  -- Create a visual effect event
                  table.insert(events, {
                      type = "EFFECT",
                      source = "caster",
                      target = "enemy",
                      effectType = "reflect",
                      duration = 0.5
                  })

                  return events
              end
          }
      },
      vfx = "enhanced_mirror_shield",
      sfx = "crystal_ring",
      blockableBy = {}  -- Utility spell, can't be blocked
  }

  Step 6: Add a new EFFECT event type to EventRunner for visual effects

  File: systems/EventRunner.lua
  Location: Add to the EVENT_HANDLERS table around line 1101

  -- Add a new EFFECT event handler for pure visual effects
  EFFECT = function(event, caster, target, spellSlot, results)
      local targetInfo = EventRunner.resolveTarget(event, caster, target)
      if not targetInfo or not targetInfo.wizard then return false end

      local targetWizard = targetInfo.wizard

      -- Create visual effect if VFX system is available
      if caster.gameState and caster.gameState.vfx then
          local params = {
              duration = event.duration or 0.5,
              source = caster.name,
              target = targetWizard.name,
              effectType = event.effectType
          }

          -- Add any additional parameters from the event
          for k, v in pairs(event) do
              if k ~= "type" and k ~= "source" and k ~= "target" and
                 k ~= "duration" and k ~= "effectType" then
                  params[k] = v
              end
          end

          -- Use our safe VFX creation helper
          safeCreateVFX(
              caster.gameState.vfx,
              "createEffect",
              event.effectType or "generic_effect",
              targetWizard.x,
              targetWizard.y,
              params
          )
      end

      return true
  end

  Step 7: Add the EFFECT event type to the processing priority list

  File: systems/EventRunner.lua
  Location: In the PROCESSING_PRIORITY table around line 38

  -- Constants for event processing order
  local PROCESSING_PRIORITY = {
      -- State setting events (first)
      SET_ELEVATION = 10,
      SET_RANGE = 20,
      FORCE_POSITION = 30,
      ZONE_ANCHOR = 40,

      -- Resource events (second)
      CONJURE_TOKEN = 100,
      DISSIPATE_TOKEN = 110,
      SHIFT_TOKEN = 120,
      LOCK_TOKEN = 130,
      CONSUME_TOKENS = 140,

      -- Spell timeline events (third)
      ACCELERATE_SPELL = 210,
      CANCEL_SPELL = 220,
      FREEZE_SPELL = 230,

      -- Defense events (fourth)
      CREATE_SHIELD = 300,
      REFLECT = 310,

      -- Status effects (fifth)
      APPLY_STATUS = 400,

      -- Damage events (sixth)
      DAMAGE = 500,

      -- Visual effects (before special effects)
      EFFECT = 550,

      -- Special effects (last)
      ECHO = 600,
      ZONE_MULTI = 610
  }

  Step 8: Add a Battle Shield spell that has multiple on-block effects

  File: spells.lua
  Location: Add a new spell after other shield spells

  -- Battle Shield with multiple effects on block
  Spells.battleshield = {
      id = "battleshield",
      name = "Battle Shield",
      description = "An aggressive barrier that counterattacks and 
empowers
   the caster when blocking",
      attackType = "utility",
      castTime = 7.0,
      cost = {Constants.TokenType.FIRE, Constants.TokenType.SUN,
  Constants.TokenType.STAR},
      keywords = {
          block = {
              type = Constants.ShieldType.BARRIER,
              blocks = {Constants.AttackType.PROJECTILE,
  Constants.AttackType.ZONE},

              -- Advanced onBlock handler with multiple effects
              onBlock = function(defender, attacker, slotIndex, blockInfo)
                  local events = {}

                  -- 1. Deal counter damage to the attacker
                  if attacker then
                      table.insert(events, {
                          type = "DAMAGE",
                          source = "caster",
                          target = "enemy",
                          amount = 8,
                          damageType = "fire",
                          counterDamage = true
                      })
                  end

                  -- 2. Accelerate the defender's next spell
                  table.insert(events, {
                      type = "ACCELERATE_SPELL",
                      source = "caster",
                      target = "self_slot",
                      slotIndex = 0, -- Next cast in any slot
                      amount = 2.0
                  })

                  -- 3. Create a token on successful block
                  table.insert(events, {
                      type = "CONJURE_TOKEN",
                      source = "caster",
                      target = "POOL_SELF",
                      tokenType = "fire",
                      amount = 1
                  })

                  -- 4. Visual effect feedback
                  table.insert(events, {
                      type = "EFFECT",
                      source = "caster",
                      target = "self",
                      effectType = "battle_shield_counter",
                      duration = 0.8,
                      color = {1.0, 0.7, 0.2, 0.8}
                  })

                  return events
              end
          }
      },
      vfx = "battle_shield",
      sfx = "fire_shield",
      blockableBy = {}  -- Utility spell, can't be blocked
  }

  Step 9: Create Documentation for the onBlock Feature

  File: Create a new file in the docs folder:
  /Users/russell/Manastorm/docs/shield_hooks.md

  # Shield On-Block Hooks

  This document describes the on-block hook system for shield spells, 
which
   allows custom effects to be triggered when a shield successfully blocks
  an incoming spell.

  ## Overview

  Shields can now define an `onBlock` callback function that is invoked
  whenever the shield successfully blocks an attack. This callback can 
emit
   events that are processed by the EventRunner, allowing for a wide
  variety of dynamic effects.

  ## onBlock Callback Signature

  The `onBlock` callback has the following signature:

  ```lua
  function onBlock(defender, attacker, slotIndex, blockInfo)
      -- Return an array of events to process
      return events
  end

  Parameters

  - defender: The wizard who owns the shield (shield caster)
  - attacker: The wizard who cast the spell being blocked (may be nil)
  - slotIndex: The spell slot index where the shield is active
  - blockInfo: A table with contextual information about the block:
    - blockType: The type of shield (barrier, ward, field)

  Return Value

  The callback should return an array of events to be processed by the
  EventRunner. Each event should follow the standard event structure
  defined in the EventRunner system.

  Examples

  Simple Elevation on Block

  onBlock = function(defender, attacker, slotIndex, blockInfo)
      return {{
          type = "SET_ELEVATION",
          source = "caster",
          target = "self",
          elevation = "AERIAL",
          duration = 4.0
      }}
  end

  Counter Damage

  onBlock = function(defender, attacker, slotIndex, blockInfo)
      if not attacker then return {} end

      return {{
          type = "DAMAGE",
          source = "caster",
          target = "enemy",
          amount = 10,
          damageType = "fire"
      }}
  end

  Multiple Effects

  onBlock = function(defender, attacker, slotIndex, blockInfo)
      local events = {}

      -- Deal counter damage
      table.insert(events, {
          type = "DAMAGE",
          source = "caster",
          target = "enemy",
          amount = 8,
          damageType = "fire"
      })

      -- Accelerate next spell
      table.insert(events, {
          type = "ACCELERATE_SPELL",
          source = "caster",
          target = "self_slot",
          slotIndex = 0,
          amount = 2.0
      })

      return events
  end

  Creating Custom Shield Spells

  To create a shield spell with an on-block hook:

  1. Define a normal spell with the block keyword
  2. Add an onBlock function to the block keyword parameters
  3. Return an array of events from the onBlock function

  The events will be processed through the EventRunner system, maintaining
  compatibility with all existing game systems.

  ## Step 10: Update tests or add test code

  If there's a test framework, create test cases for the new onBlock
  functionality to ensure it works correctly across different scenarios. 
If
   no formal tests exist, add test/example code for the development team 
to
   verify functionality.

  ## Summary

  This implementation plan adds support for on-block hooks to the shield
  system, allowing for more dynamic and reactive shield behaviors. The
  changes are minimal and targeted, focusing on the key areas needed to
  support this feature while maintaining compatibility with existing code.

  The main components are:
  1. Updating the Keywords.block handler to pass through the onBlock
  function
  2. Adding code to ShieldSystem to store and invoke the onBlock callback
  3. Adding example shield spells that use the new functionality
  4. Creating documentation for the feature

  This approach preserves the event-based architecture while adding a
  powerful new capability for spell designers, allowing shields to have
  dynamic effects when they block spells.
~
