-- Spells.lua
-- Contains data for all spells in the game

-- Import the keyword system and constants
local Constants = require("core.Constants")
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local expr = require("expr")
local ManaHelpers = require("systems.ManaHelpers")

local Spells = {}

-- Schema for spell object:
-- id: Unique identifier for the spell (string)
-- name: Display name of the spell (string)
-- affinity: The element of the spell (string)
-- description: Text description of what the spell does (string)
-- attackType: How the spell is delivered - Constants.AttackType.PROJECTILE, REMOTE, ZONE, UTILITY
--   * PROJECTILE: Physical projectile attacks - can be blocked by barriers and wards
--   * REMOTE:     Magical attacks at a distance - can only be blocked by wards
--   * ZONE:       Area effect attacks - can be blocked by barriers and fields
--   * UTILITY:    Non-offensive spells that affect the caster - cannot be blocked
-- castTime: Duration in seconds to cast the spell (number)
-- cost: Array of token types required (array using Constants.TokenType.FIRE, etc.)
-- keywords: Table of effect keywords and their parameters (table)
--   - Available keywords: damage, burn, stagger, elevate, ground, rangeShift, forcePull, 
--     tokenShift, conjure, dissipate, lock, delay, accelerate, dispel, disjoint, freeze,
--     block, reflect, echo, zoneAnchor, zoneMulti
-- vfx: Visual effect identifier (string, optional)
-- sfx: Sound effect identifier (string, optional)
-- blockableBy: Array of shield types that can block this spell (array, optional)
--
-- Shield Types and Blocking Rules:
-- * barrier: Physical shield that blocks projectiles and zones
-- * ward:    Magical shield that blocks projectiles and remotes
-- * field:   Energy field that blocks remotes and zones

-- Function to validate spell schema - Basic schema validation
local function validateSpell(spell, spellId)
    -- Add a missing ID based on spell name if needed
    if not spell.id and spell.name then
        spell.id = spell.name:lower():gsub(" ", "")
        print("INFO: Added missing ID for spell: " .. spell.name .. " -> " .. spell.id)
    end
    
    -- Check essential properties with better error handling
    if not spell.id then
        print("WARNING: Spell " .. spellId .. " missing required property: id, creating a default")
        spell.id = "spell_" .. spellId
    end
    
    if not spell.name then
        print("WARNING: Spell " .. spellId .. " missing required property: name, creating a default")
        spell.name = "Unnamed Spell " .. spellId
    end

    if not spell.affinity then
        print("WARNING: Spell " .. spellId .. " missing required property: affinity, creating a default")
        spell.affinity = "fire"
    end
    
    if not spell.description then
        print("WARNING: Spell " .. spellId .. " missing required property: description, creating a default")
        spell.description = "No description available for " .. spell.name
    end
    
    if not spell.castTime then
        print("WARNING: Spell " .. spellId .. " missing required property: castTime, setting default")
        spell.castTime = 5.0 -- Default cast time
    end
    
    if type(spell.castTime) ~= "number" then
        print("WARNING: Spell " .. spellId .. " castTime must be a number, fixing")
        spell.castTime = tonumber(spell.castTime) or 5.0
    end
    
    -- Ensure cost is a table, if empty then create empty table
    if not spell.cost then
        print("WARNING: Spell " .. spellId .. " missing required property: cost, creating empty cost")
        spell.cost = {}
    elseif type(spell.cost) ~= "table" then
        print("WARNING: Spell " .. spellId .. " cost must be a table, fixing")
        -- Try to convert to a table if possible
        local originalCost = spell.cost
        spell.cost = {}
        if originalCost then
            print("INFO: Converting non-table cost to table for: " .. spell.name)
            table.insert(spell.cost, tostring(originalCost))
        end
    end
    
    -- Check attackType is valid
    if spell.attackType then
        local validTypes = {
            projectile = true,
            remote = true,
            zone = true,
            utility = true
        }
        
        if not validTypes[spell.attackType] then
            print("WARNING: Spell " .. spellId .. " has invalid attackType: " .. spell.attackType .. ", fixing to utility")
            spell.attackType = "utility" -- Default to utility
        end
    else
        -- Default to utility if not specified
        print("WARNING: Spell " .. spellId .. " missing attackType, setting to utility")
        spell.attackType = "utility"
    end
    
    -- Check keywords are valid (if present)
    if spell.keywords then
        if type(spell.keywords) ~= "table" then
            print("WARNING: Spell " .. spellId .. " keywords must be a table, fixing")
            spell.keywords = {}
        else
            for keyword, _ in pairs(spell.keywords) do
                if not Keywords[keyword] then
                    print("WARNING: Spell " .. spellId .. " has unimplemented keyword: " .. keyword .. ", removing")
                    spell.keywords[keyword] = nil
                end
            end
        end
    else
        -- Create empty keywords table if missing
        spell.keywords = {}
    end
    
    -- Check blockableBy (if present)
    if spell.blockableBy then
        if type(spell.blockableBy) ~= "table" then
            print("WARNING: Spell " .. spellId .. " blockableBy must be a table, fixing")
            spell.blockableBy = {}
        end
    else
        -- Create empty blockableBy table
        spell.blockableBy = {}
    end
    
    return true
end

-- Hilarious Void "conjuring" spell
Spells.conjurenothing = {
    id = "conjurenothing",
    name = "Conjure Nothing",
    affinity = "void",
    description = "Bring nothing into existence",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.FAST,
    cost = {Constants.TokenType.VOID, Constants.TokenType.ANY, Constants.TokenType.ANY},
    keywords = {
        expend = {
            amount = 3
        }
    },
    vfx = "void_conjure",
    sfx = "void_conjure",
}

-- Ashgar's Spells (Fire-focused)
Spells.conjurefire = {
    id = "conjurefire",
    name = "Conjure Fire",
    affinity = "fire",
    description = "Creates a new Fire mana token",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.FAST,  -- Base cast time of 5 seconds
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = Constants.TokenType.FIRE,
            amount = 1
        }
    },
    vfx = "fire_conjure",
    blockableBy = {},  -- Unblockable
    
    -- Custom cast time calculation based on existing fire tokens
    getCastTime = function(caster)
        -- Base cast time
        local baseCastTime = Constants.CastSpeed.FAST
        
        -- Count fire tokens in the mana pool
        local fireCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == Constants.TokenType.FIRE and token.state == Constants.TokenState.FREE then
                    fireCount = fireCount + 1
                end
            end
        else
            print("WARN: ConjureFire getCastTime - caster.manaPool is nil!")
        end
        
        -- Increase cast time by 5 seconds per existing fire token
        local adjustedCastTime = baseCastTime + (fireCount * Constants.CastSpeed.ONE_TIER)
        
        return adjustedCastTime
    end
}

Spells.firebolt = {
    id = "firebolt",
    name = "Firebolt",
    affinity = "fire",
    description = "Quick ranged hit, more damage against AERIAL opponents",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.PROJECTILE,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.gameState.rangeState == Constants.RangeState.FAR then
                    return 15
                end
                return 10
            end,
            type = Constants.DamageType.FIRE
        }
    },
    vfx = "fire_bolt",
    sfx = "fire_whoosh",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
}

Spells.blastwave = {
    id = "blastwave",
    name = "Blast Wave",
    affinity = "fire",
    description = "Blast that deals significant damage up close.",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.ZONE,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE},
    keywords = {
        damage = {
            amount = expr.byRange({
                NEAR = 18,
                FAR = 5,
                default = 5
            }),
            type = Constants.DamageType.FIRE
        }
    },
    vfx = "blastwave",
    sfx = "blastwave",
}

Spells.meteor = {
    id = "meteor",
    name = "Meteor Dive",
    affinity = "sun",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.ZONE,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE, Constants.TokenType.SUN},
    keywords = {
        damage = {
            amount = 20,
            type = Constants.DamageType.FIRE,
            condition = function(caster, target, slot)
                local casterIsAerial = caster and caster.elevation == Constants.ElevationState.AERIAL
                local targetIsGrounded = target and target.elevation == Constants.ElevationState.GROUNDED
                return casterIsAerial and targetIsGrounded
            end
        },
        rangeShift = {
            position = Constants.RangeState.NEAR
        },
        ground = {
            target = Constants.TargetType.SELF 
        }
    },
    vfx = "meteor_dive",
    sfx = "meteor_impact",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.FIELD}
}

Spells.combustMana = {
    id = "combustMana",
    name = "Combust Mana",
    affinity = "fire",
    description = "Disrupts opponent channeling, burning one token to Salt",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.UTILITY,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE},
    keywords = {
        disruptAndShift = {
            targetType = "salt"
        }
    },
    vfx = "combust_lock",
}

Spells.conjuresalt = {
    id = "conjuresalt",
    name = "Conjure Salt",
    affinity = "salt",
    description = "Creates a new Salt mana token",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.FAST,  -- Base cast time
    cost = {},
    keywords = {
        conjure = {
            token = Constants.TokenType.SALT,
            amount = 1
        }
    },
    vfx = "force_conjure", -- Assuming a VFX name
    blockableBy = {},

    getCastTime = function(caster)
        local baseCastTime = Constants.CastSpeed.FAST
        local saltCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == Constants.TokenType.SALT and token.state == Constants.TokenState.FREE then
                    saltCount = saltCount + 1
                end
            end
        end
        return baseCastTime + (saltCount * Constants.CastSpeed.ONE_TIER)
    end
}

Spells.emberlift = {
    id = "emberlift",
    name = "Emberlift",
    affinity = "sun",
    description = "Launches caster into the air and increases range",
    castTime = Constants.CastSpeed.FAST,
    attackType = "utility",
    cost = {"sun"},
    keywords = {
        conjure = {
            token = Constants.TokenType.FIRE,
            amount = 1
        },
        elevate = {
            duration = 5.0,
            target = "SELF",
            vfx = "emberlift"
        },
        rangeShift = {
            position = expr.byRange({
                NEAR = "FAR",
                FAR = "NEAR",
                default = "NEAR"
            })
        }
    },
    vfx = "ember_lift",
    sfx = "whoosh_up",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Selene's Spells (Moon-focused)
Spells.conjuremoonlight = {
    id = "conjuremoonlight",
    name = "Conjure Moonlight",
    affinity = Constants.TokenType.MOON,
    description = "Creates a new Moon mana token",
    attackType = "utility",
    castTime = Constants.CastSpeed.FAST,  -- Base cast time of 5 seconds
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = Constants.TokenType.MOON,
            amount = 1
        }
    },
    vfx = "moon_conjure",
    blockableBy = {},  -- Unblockable
    
    -- Custom cast time calculation based on existing moon tokens
    getCastTime = function(caster)
        -- Base cast time
        local baseCastTime = Constants.CastSpeed.FAST
        
        -- Count moon tokens in the mana pool
        local moonCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == Constants.TokenType.MOON and token.state == "FREE" then
                    moonCount = moonCount + 1
                end
            end
        end
        
        -- Increase cast time by 5 seconds per existing moon token
        local adjustedCastTime = baseCastTime + (moonCount * Constants.CastSpeed.ONE_TIER)
        
        return adjustedCastTime
    end
}

Spells.conjurestars = {
    id = "conjurestars",
    name = "Conjure Stars",
    affinity = "star",
    description = "Creates a new Star mana token",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.FAST,  -- Base cast time
    cost = {},
    keywords = {
        conjure = {
            token = Constants.TokenType.STAR,
            amount = 1
        }
    },
    vfx = "star_conjure", -- Assuming a VFX name
    blockableBy = {},

    getCastTime = function(caster)
        local baseCastTime = Constants.CastSpeed.FAST
        local starCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == Constants.TokenType.STAR and token.state == Constants.TokenState.FREE then
                    starCount = starCount + 1
                end
            end
        end
        return baseCastTime + (starCount * Constants.CastSpeed.ONE_TIER)
    end
}

-- Nova Conjuring (Fire, Force, Star)
Spells.novaconjuring = {
    id = "novaconjuring",
    name = "Nova Conjuring",
    affinity = "sun",
    description = "Conjures SUN token from FIRE.",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.NORMAL,  -- Fixed cast time
    cost = {"fire", "fire", "fire"},  -- Needs basic fire to "fuse"
    keywords = {
        consume = true,
        conjure = {
            token = {
                Constants.TokenType.SUN,
            },
            amount = 1 -- Conjures 2 of each listed type
        }
    },
    vfx = "nova_conjure",
    sfx = "conjure_nova",
    blockableBy = {}  -- Unblockable
}

-- Witch Conjuring (Moon, Force, Nature)
Spells.witchconjuring = {
    id = "witchconjuring",
    name = "Witch Conjuring",
    affinity = Constants.TokenType.MOON,
    description = "Conjures WATER, MOON, and LIFE tokens.",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.SLOW,  -- Fixed cast time
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON, Constants.TokenType.MOON},  -- Needs some basic moon
    keywords = {
        conjure = {
            token = { 
                Constants.TokenType.WATER, 
                Constants.TokenType.MOON, 
                Constants.TokenType.LIFE 
            },
            amount = 1 -- Conjures 1 of each listed type
        }
    },
    vfx = "witch_conjure",
    sfx = "conjure_witch",
    blockableBy = {}  -- Unblockable
}

Spells.infiniteprocession = {
    id = "infiniteprocession",
    name = "Infinite Procession",
    affinity = Constants.TokenType.MOON,
    description = "Transmutes MOON tokens into SUN or SUN into MOON.",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.SLOW,
    cost = {},
    keywords = {
        tokenShift = {
            -- If there's more SUN than MOON, flip a random token to MOON (and vice-versa)
            -- Make this target a specific token as appropriate later
            type = expr.more(Constants.TokenType.SUN, Constants.TokenType.MOON),
            amount = 1
        }
    },
    vfx = "infinite_procession",
    sfx = "conjure_infinite",
}
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
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
            
            -- Simplified onBlock implementation
            onBlock = function(defender, attacker, slot, info)
                print("[SPELL DEBUG] Wings of Moonlight onBlock handler executing!")
                
                -- Create a simple event array
                local events = {}
                
                -- Add the elevation event
                table.insert(events, {
                    type = "SET_ELEVATION",
                    source = "caster",
                    target = "self",
                    elevation = Constants.ElevationState.AERIAL,
                    duration = 4.0,
                    vfx = "mist_veil"
                })
                
                print("[SPELL DEBUG] Wings of Moonlight returning " .. #events .. " events")
                return events
            end
        }
    },
    vfx = "mist_veil",
    sfx = "mist_shimmer",
    blockableBy = {},  -- Utility spell, can't be blocked
}

Spells.tidalforce = {
    id = "tidalforce",
    name = "Tidal Force",
    affinity = "water",
    description = "Chip damage, forces AERIAL enemies out of the air",
    attackType = "remote",
    castTime = Constants.CastSpeed.FAST,
    cost = {"water", Constants.TokenType.MOON},
    keywords = {
        damage = {
            amount = 5,
            type = Constants.TokenType.MOON
        },
        ground = {
            -- Only apply grounding if the target is AERIAL
            conditional = function(caster, target)
                return target and target.elevation == "AERIAL"
            end,
            target = "ENEMY", -- Explicitly specify the enemy as the target
            vfx = "tidal_force_ground" -- Specify the visual effect to use
        }
    },
    vfx = "tidal_force",
    sfx = "tidal_wave",
    blockableBy = {"ward", "field"}
}

Spells.lunardisjunction = {
    id = "lunardisjunction",
    name = "Lunar Disjunction",
    affinity = Constants.TokenType.MOON,
    description = "Counterspell, cancels an opponent's spell and destroys its mana",
    attackType = Constants.AttackType.PROJECTILE,
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.MOON, "any"},
    keywords = {
        disjoint = {
            -- Target the opponent's slot corresponding to the slot this spell was cast from
            slot = function(caster, target, slot) 
                -- Make sure slot is a number
                local slotNum = tonumber(slot) or 0
                -- Validate the slot is in a valid range
                if slotNum > 0 and slotNum <= 3 then
                    return slotNum
                else
                    return 0  -- 0 means find the first active slot
                end
            end,
            target = "SLOT_ENEMY"  -- Explicitly target enemy's spell slot
        }
    },
    vfx = "lunardisjunction",
    sfx = "lunardisjunction_sound",
    blockableBy = {"ward"} -- Disjunction is a projectile
}

Spells.gravityTrap = {
    id = "gravityTrap",
    name = "Gravity Trap",
    affinity = Constants.TokenType.MOON,
    description = "Sets a trap that triggers when an enemy becomes AERIAL, pulling them down and dealing damage",
    attackType = "utility",  -- Changed to utility since it's not a direct attack
    castTime = 5.0,          -- Slightly faster cast time
    cost = {Constants.TokenType.SUN, Constants.TokenType.MOON, Constants.TokenType.MOON, Constants.TokenType.MOON},
    keywords = {
        -- Mark as a sustained spell
        sustain = true,
        
        -- Define trap trigger condition
        trap_trigger = { 
            condition = "on_opponent_elevate" 
        },
        
        -- Define trap window/expiry
        trap_window = { 
            duration = 600.0  -- Trap lasts indefinitely, treat this as default later
        },
        
        -- Define trap effect when triggered
        trap_effect = {
            -- Re-use existing keywords for the effect
            -- stagger or whatever once properly implemented
            damage = { 
                amount = 3, 
                type = Constants.TokenType.MOON,  
                target = "ENEMY" 
            },
            ground = { 
                target = "ENEMY", 
                vfx = "gravity_pin_ground" 
            },
            burn = { 
                duration = 1.0,
                tickDamage = 4,
                tickInterval = 0.5,
                target = "ENEMY"
            }
        }
    },
    vfx = "gravity_trap_set",
    sfx = "gravity_trap_set",
    blockableBy = {}  -- Trap spells can't be blocked since they're utility spells
}

Spells.moondance = {
    id = "moondance",
    name = "Moon Dance",
    affinity = Constants.TokenType.MOON,
    description = "Switch Range. Freeze <6> enemy Root slot.",
    attackType = "remote",
    castTime = Constants.CastSpeed.SLOW,
    cost = {Constants.TokenType.MOON},
    keywords = {
        damage = {
            amount = 5,
            type = Constants.TokenType.MOON
        },
        rangeShift = {
            position = expr.byRange({
                NEAR = "FAR",
                FAR = "NEAR",
                default = "NEAR"
            }),
            target = "SELF" 
        },
        freeze = {
            duration = Constants.CastSpeed.ONE_TIER*2,
            target = "SLOT_ENEMY",
            slot = 1
        }
    }
}

-- Keep the original spell for backward compatibility
Spells.gravity = {
    id = "gravity",
    name = "Drag From the Sky",
    affinity = Constants.TokenType.MOON,
    description = "Grounds AERIAL enemies",
    attackType = Constants.AttackType.ZONE,
    castTime = Constants.CastSpeed.FAST,
    cost = {Constants.TokenType.MOON, Constants.TokenType.WATER},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.elevation then
                    return target.elevation == "AERIAL" and 15 or 0
                end
                return 0 -- Default damage if target is nil
            end,
            type = Constants.TokenType.MOON
        },
        ground = {
            conditional = function(caster, target)
                return target and target.elevation == "AERIAL"
            end,
            target = "ENEMY",
            vfx = "gravity_pin_ground"
        },
        stagger = {
            duration = 2.0  -- Stun for 2 seconds
        }
    },
    vfx = "gravity_pin",
    sfx = "gravity_slam",
    blockableBy = {Constants.S, "field"}
}

Spells.eclipse = {
    id = "eclipse",
    name = "Total Eclipse",
    affinity = Constants.TokenType.MOON,
    description = "Freeze <3> your Crown slot. Conjure Sun", -- Simplified description
    attackType = "utility", 
    castTime = Constants.CastSpeed.FAST,
    cost = {Constants.TokenType.MOON, Constants.TokenType.SUN},
    keywords = {
        freeze = {
            duration = Constants.CastSpeed.ONE_TIER,
            slot = 3,
            target = "both" -- Explicitly target the caster
        },
        conjure = {
            token = Constants.TokenType.SUN,
            amount = 1
        }
    },
    vfx = "eclipse_burst", -- Keep visual/sound for now
    sfx = "eclipse_shatter",
    blockableBy = {} -- Utility spells are not blockable
}

Spells.fullmoonbeam = {
    id = "fullmoonbeam",
    name = "Full Moon Beam",
    affinity = Constants.TokenType.MOON,
    description = "Channels moonlight into a beam that deals damage equal to its cast time",
    attackType = Constants.AttackType.PROJECTILE,
    castTime = Constants.CastSpeed.FAST,
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON, Constants.TokenType.MOON},  -- 3 moon mana
    keywords = {
        damage = {
            amount = function(caster, target, slot) -- slot is the spellSlot index
                local baseCastTime = Constants.CastSpeed.FAST  -- Default/base cast time
                local accruedModifier = 0
                
                -- If we know which slot this spell was cast from
                if slot and caster.spellSlots[slot] then
                    local spellSlotData = caster.spellSlots[slot]
                    -- LOGGING: Check multiple fields of the slot data
                    print(string.format("DEBUG_FMB_SLOT_CHECK: Slot=%d, Active=%s, Progress=%.2f, CastTime=%.1f, Modifier=%.4f, Frozen=%s",
                        slot, tostring(spellSlotData.active), spellSlotData.progress or -1, spellSlotData.castTime or -1, spellSlotData.castTimeModifier or -99, tostring(spellSlotData.frozen)))
                    
                    baseCastTime = spellSlotData.castTime 
                    accruedModifier = spellSlotData.castTimeModifier or 0
                    -- LOGGING:
                    print(string.format("DEBUG_FMB: Read castTimeModifier=%.4f from spellSlotData", accruedModifier))
                else
                    aprint(string.format("DEBUG_FMB_WARN: Slot %s or caster.spellSlots[%s] is nil!", tostring(slot), tostring(slot)))
                end
                
                -- Calculate effective cast time including modifier
                -- Ensure effective time doesn't go below some minimum (e.g., 0.1s)
                local effectiveCastTime = math.max(0.1, baseCastTime + accruedModifier)
                
                -- Calculate damage based on effective cast time (roughly 3.5 damage per second)
                local damage = math.floor(effectiveCastTime * 2.5)
                
                -- Log the damage calculation with details
                print(string.format("Full Moon Beam: Base Cast=%.1fs, Modifier=%.1fs, Effective=%.1fs => Damage=%d", 
                    baseCastTime, accruedModifier, effectiveCastTime, damage))
                
                return damage
            end,
            type = Constants.TokenType.MOON
        }
    },
    vfx = "moon_beam",
    sfx = "beam_charge",
    blockableBy = {Constants.ShieldType.BARRIER, "ward"}
}

-- Shield spells
Spells.forcebarrier = {
    id = "forcebarrier",
    name = "Sun Block",
    description = "A protective barrier that blocks projectile and area attacks",
    castTime = Constants.CastSpeed.SLOW,
    attackType = "utility",
    cost = {"sun", "sun"},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE}
        }
    },
    vfx = "force_barrier",
    sfx = "shield_up",
    blockableBy = {}  -- Utility spell, can't be blocked
}

Spells.moonward = {
    id = "moonward",
    name = "Moon Ward",
    description = "A mystical ward that blocks projectiles and remotes",
    attackType = "utility",
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON},
    keywords = {
        block = {
            type = "ward",
            blocks = {Constants.AttackType, "remote"}
            -- All shields are mana-linked now (consume tokens when blocking)
        }
    },
    vfx = "moon_ward",
    sfx = "shield_up",
    blockableBy = {}  -- Utility spell, can't be blocked
}

Spells.naturefield = {
    id = "naturefield",
    name = "Nature Field",
    description = "A field of natural energy that blocks remotes and zones",
    attackType = "utility",
    castTime = 4.0,
    cost = {Constants.TokenType.WATER, Constants.TokenType.WATER},
    keywords = {
        block = {
            type = "field",
            blocks = {"remote", Constants.AttackType.ZONE}
            -- All shields are mana-linked now (consume tokens when blocking)
        }
    },
    vfx = "nature_field",
    sfx = "nature_grow",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Advanced reflective shield
Spells.mirrorshield = {
    id = "mirrorshield",
    name = "Mirror Shield",
    description = "A reflective barrier that returns damage to attackers",
    attackType = "utility",
    castTime = 5.0,
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON, "star"},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,  -- Barrier type blocks projectiles and zones
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
            reflect = true      -- Reflects damage back to attacker
            -- All shields are mana-linked now (consume tokens when blocking)
            -- Token count is the source of truth for shield strength
        }
    },
    vfx = "mirror_shield",
    sfx = "crystal_ring",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Enhanced Mirror Shield with direct damage reflection via onBlock
Spells.enhancedmirrorshield = {
    id = "enhancedmirrorshield",
    name = "Enhanced Mirror Shield",
    description = "A powerful reflective barrier that returns damage to attackers with interest",
    attackType = "utility",
    castTime = 6.0,
    cost = {Constants.TokenType.MOON, Constants.TokenType.STAR, Constants.TokenType.STAR},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
            
            -- Add a custom onBlock handler to implement reflection logic
            onBlock = function(defender, attacker, slotIndex, blockInfo)
                -- Only reflect if we have an attacker
                if not attacker then return {} end
                
                -- Generate damage reflection events
                local events = {}
                
                -- Create a damage reflection event
                table.insert(events, {
                    type = "DAMAGE",
                    source = "caster", -- The defender becomes the source
                    target = "enemy",  -- The attacker becomes the target
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

-- Battle Shield with multiple effects on block
Spells.battleshield = {
    id = "battleshield",
    name = "Battle Shield",
    description = "An aggressive barrier that counterattacks and empowers the caster when blocking",
    attackType = "utility",
    castTime = 7.0,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.SUN, Constants.TokenType.STAR},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
            
            -- Advanced onBlock handler with multiple effects
            onBlock = function(defender, attacker, slotIndex, blockInfo)
                print("[SPELL DEBUG] Battle Shield onBlock handler executing!")
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
                
                print("[SPELL DEBUG] Battle Shield returning " .. #events .. " events")
                return events
            end
        }
    },
    vfx = "battle_shield",
    sfx = "fire_shield",
    blockableBy = {}  -- Utility spell, can't be blocked
}

-- Simple test shield just for debugging
Spells.testshield = {
    id = "testshield",
    name = "Test Shield",
    description = "A simple test shield that prints debug info when it blocks",
    attackType = "utility",
    castTime = 3.0,
    cost = {"fire"},
    keywords = {
        block = {
            type = "barrier",
            blocks = {"projectile"},
            
            -- Super simple onBlock handler
            onBlock = function(defender, attacker, slotIndex, blockInfo)
                print("TEST SHIELD BLOCK TRIGGERED")
                print("Defender: " .. (defender and defender.name or "nil"))
                print("Attacker: " .. (attacker and attacker.name or "nil"))
                print("Slot: " .. tostring(slotIndex))
                
                -- Return a damage event
                return {
                    {
                        type = "DAMAGE",
                        source = "caster",
                        target = "enemy",
                        amount = 5,
                        damageType = "fire"
                    }
                }
            end
        }
    },
    vfx = "force_barrier",
    sfx = "shield_up",
    blockableBy = {}
}

-- Shield-breaking spell
Spells.shieldbreaker = {
    id = "shieldbreaker",
    name = "Shield Breaker",
    description = "A powerful force blast that shatters shields and barriers",
    attackType = Constants.AttackType.PROJECTILE, -- Projectile type (can be blocked by barriers and wards)
    castTime = 6.0,
    cost = {"force", "force", "star"},
    keywords = {
        -- Regular damage component
        damage = {
            amount = function(caster, target)
                -- Base damage
                local baseDamage = 8
                
                -- Check if target exists before checking shields
                local shieldBonus = 0
                if target and target.spellSlots then
                    -- Bonus damage if target has active shields
                    for _, slot in ipairs(target.spellSlots) do
                        if slot.active and slot.isShield then
                            shieldBonus = shieldBonus + 6
                            break -- Only count one shield for bonus
                        end
                    end
                end
                
                return baseDamage + shieldBonus
            end,
            type = "force"
        }
    },
    -- Add special property that indicates this is a shield-breaker spell
    -- This will be used in the shield-blocking logic
    shieldBreaker = 3, -- Deals 3 hits worth of damage to shields
    vfx = "force_blast",
    sfx = "shield_break",
    blockableBy = {Constants.S, "ward"}, -- Can be blocked by barriers and wards
    
    -- Custom handler for when this spell is blocked
    onBlock = function(caster, target, slot, blockInfo)
        print(string.format("[SHIELD BREAKER] %s's Shield Breaker is testing the %s shield's strength!", 
            caster.name, blockInfo.blockType))
        
        -- Return a special response that overrides behavior
        return {
            specialBlockMessage = "Shield Breaker collides with active shield!",
            damageShield = true,  -- Signal that we want to damage the shield
            continueExecution = false  -- Don't continue processing the spell
        }
    end
}

-- Zone spell with range anchoring
Spells.eruption = {
    id = "eruption",
    name = "Molten Ash",
    description = "Creates a volcanic eruption under the opponent. Only works at NEAR range.",
    attackType = Constants.AttackType.ZONE, -- Zone attack - can be blocked by barriers, fields, or dodged
    castTime = Constants.CastSpeed.SLOW,
    cost = {"fire", "fire", "salt"},
    keywords = {
        -- Anchor the spell to NEAR range - it can only work when cast at NEAR range
        zoneAnchor = {
            range = "NEAR", -- Only works at NEAR range
            elevation = "GROUNDED", -- Only hits GROUNDED targets
            requireAll = true -- Must match both conditions
        },
        
        -- Damage component
        damage = {
            amount = 16,
            type = "fire"
        },
        
        -- Secondary effect - ground the target if they're AERIAL
        ground = true,
        
        -- Add damage over time
        burn = {
            duration = 4.0,
            tickDamage = 3
        }
    },
    vfx = "lava_eruption",
    sfx = "volcano_rumble",
    blockableBy = {Constants.S, "field"},
    
    -- Custom handler for when this spell misses
    onMiss = function(caster, target, slot)
        print(string.format("[MISS] %s's Lava Eruption misses because conditions aren't right!", caster.name))
        
        -- Return special response for handling the miss
        return {
            missBackfire = true,
            backfireDamage = 4,
            backfireMessage = "Lava Eruption backfires when cast at wrong range!"
        }
    end,
    
    -- Custom handler for when this spell succeeds
    onSuccess = function(caster, target, slot, results)
        print(string.format("[SUCCESS] %s's Lava Eruption hits %s with full force!", caster.name, target.name))
        
        -- Return additional effects for when the spell hits successfully
        return {
            successMessage = "The ground trembles with volcanic fury!",
            extraEffect = "area_burn",
            burnDuration = 2.0
        }
    end
}

-- Utility spell that changes tokens
Spells.stormMeld = {
    id = "stormmeld",
    name = "Storm Meld",
    description = "An elemental fusion spell that changes tokens to random types",
    attackType = "utility",
    castTime = 3.0,
    cost = {"fire", Constants.TokenType.MOON},
    keywords = {
        tokenShift = {
            type = "random",
            amount = 3
        },
        damage = {
            amount = 5,
            type = "mixed"
        },
        echo = {
            delay = 3.0
        }
    },
    vfx = "storm_meld",
    sfx = "elemental_fusion",
    blockableBy = {}  -- Utility spells can't be blocked
}

-- Offensive spell with multiple effects
Spells.cosmicRift = {
    id = "cosmicrift",
    name = "Cosmic Rift",
    description = "Opens a rift that damages opponents and disrupts spellcasting",
    attackType = Constants.AttackType.ZONE,
    castTime = 5.5,
    cost = {"star", "star", "force"},
    keywords = {
        damage = {
            amount = 12,
            type = "star"
        },
        slow = { -- Changed back from freeze to slow
            magnitude = 2.0, -- Increase cast time by 2.0s
            duration = 10.0, -- Effect persists for 10s waiting for a cast
            slot = nil -- Affects the next spell cast from any slot
        },
        zoneMulti = true  -- Affects both NEAR and FAR
    },
    vfx = "cosmic_rift",
    sfx = "space_tear",
    blockableBy = {Constants.S, "field"}
}

-- Force blast spell that launches opponents into the air
Spells.forceBlast = {
    id = "forceblast",
    name = "Force Blast",
    description = "Unleashes a blast of force that launches opponents into the air",
    attackType = "remote",
    castTime = 4.0,
    cost = {"force", "force"},
    keywords = {
        damage = {
            amount = 8,
            type = "force"
        },
        elevate = {
            duration = 3.0,         -- Lasts for 3 seconds
            target = "ENEMY",       -- Targets the opponent
            vfx = "force_blast_up"  -- Custom VFX for the effect
        }
    },
    vfx = "force_blast",
    sfx = "force_wind",
    blockableBy = {"ward", "field"}
}

-- Movement spell with multiple effects
Spells.blazingAscent = {
    id = "blazingascent",
    name = "Blazing Ascent",
    description = "Rockets upward in a burst of fire, dealing damage and becoming AERIAL",
    attackType = Constants.AttackType.ZONE,
    castTime = 3.0,
    cost = {"fire", "fire", "force"},
    keywords = {
        damage = {
            amount = function(caster, target)
                -- More damage if already AERIAL (harder to cast while falling)
                return caster.elevation == "AERIAL" and 15 or 10
            end,
            type = "fire"
        },
        elevate = {
            duration = 6.0
        },
        dissipate = {
            token = Constants.TokenType.WATER,
            amount = 1
        }
    },
    vfx = "blazing_ascent",
    sfx = "fire_whoosh",
    blockableBy = {Constants.S, "ward"}
}

-- Complex multi-target spell using the new targeting system
Spells.arcaneReversal = {
    id = "arcanereversal",
    name = "Arcane Reversal",
    description = "A complex spell that manipulates mana, movement, and timing simultaneously",
    attackType = "remote",
    castTime = 6.0,
    cost = {Constants.TokenType.MOON, "star", "force", "force"},
    keywords = {
        -- Apply damage to enemy
        damage = {
            amount = function(caster, target)
                -- More damage if enemy has active shields
                local shieldCount = 0
                if target and target.spellSlots then
                    for _, slot in ipairs(target.spellSlots) do
                        if slot.active and slot.isShield then
                            shieldCount = shieldCount + 1
                        end
                    end
                end
                return 8 + (shieldCount * 4)  -- 8 base + 4 per shield
            end,
            type = "star",
            target = "ENEMY"  -- Explicit targeting
        },
        
        -- Move self to opposite range
        rangeShift = {
            position = function(caster, target)
                return caster.gameState.rangeState == "NEAR" and "FAR" or "NEAR"
            end,
            target = "SELF"
        },
        
        -- Lock opponent's mana tokens
        lock = {
            duration = 4.0,
            target = "POOL_ENEMY" 
        },
        
        -- Add tokens to own pool
        conjure = {
            token = function(caster, target)
                -- Create a token of the type that's most common in opponent's pool
                local tokenCounts = {
                    fire = 0,
                    force = 0,
                    moon = 0,
                    nature = 0,
                    star = 0
                }
                
                -- Count opponent's token types in mana pool
                if target.manaPool then
                    for _, token in ipairs(target.manaPool.tokens or {}) do
                        if token.state == "FREE" then
                            tokenCounts[token.type] = (tokenCounts[token.type] or 0) + 1
                        end
                    end
                end
                
                -- Find the most common type
                local maxCount = 0
                local mostCommonType = "force"  -- Default
                
                for tokenType, count in pairs(tokenCounts) do
                    if count > maxCount then
                        maxCount = count
                        mostCommonType = tokenType
                    end
                end
                
                return mostCommonType
            end,
            amount = 1,
            target = "POOL_SELF"
        },
        
        -- Accelerate own next spell
        accelerate = {
            amount = 2.0,
            slot = 1,  -- First slot
            target = "SLOT_SELF"
        }
    },
    vfx = "arcane_reversal",
    sfx = "time_shift",
    blockableBy = {"ward", "field"}
}

-- Complex positional spell
Spells.lunarTides = {
    id = "lunartides",
    name = "Lunar Tides",
    description = "Manipulates the battle flow based on range and elevation",
    attackType = Constants.AttackType.ZONE,
    castTime = 7.0,
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON, "force", "star"},
    keywords = {
        damage = {
            -- Use expr.byElevation to set damage based on elevation
            amount = expr.byElevation({
                GROUNDED = 8,
                AERIAL = 12,
                default = 8
            }),
            type = Constants.TokenType.MOON,
            target = "ENEMY"  -- Explicit targeting
        },
        rangeShift = {
            -- Position changes based on current state using the expr.byRange helper
            position = expr.byRange({
                NEAR = "FAR",
                FAR = "NEAR",
                default = "NEAR"
            }),
            target = "SELF"  -- Affects caster
        },
        lock = {
            -- Lock duration increases if target has multiple active spells
            duration = function(caster, target)
                local activeSlots = 0
                for _, slot in ipairs(target.spellSlots) do
                    if slot.active then
                        activeSlots = activeSlots + 1
                    end
                end
                return 3.0 + (activeSlots * 1.0)  -- Base 3 seconds + 1 per active slot
            end,
            target = "POOL_ENEMY"  -- Affects opponent's mana pool
        }
    },
    vfx = "lunar_tide",
    sfx = "tide_rush",
    blockableBy = {"field"}
}

-- Example test spell showcasing new expression helpers
Spells.adaptive_surge = {
    id = "adaptivesurge",
    name = "Adaptive Surge",
    description = "A spell that adapts its effects based on the current mana pool",
    attackType = Constants.AttackType.PROJECTILE,
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.SUN, Constants.TokenType.MOON},
    keywords = {
        -- Damage scales based on the number of sun tokens
        damage = {
            amount = expr.countScale(Constants.TokenType.SUN, 5, 2), -- 5 base damage + 2 per sun token
            type = expr.more(Constants.TokenType.SUN, Constants.TokenType.MOON) -- Use token that's more abundant
        },
        -- Apply either burn or slow based on which wizard has more tokens
        burn = expr.ifCond(
            function(caster, target) 
                return ManaHelpers.count(Constants.TokenType.SUN, caster.manaPool) > 
                       ManaHelpers.count(Constants.TokenType.MOON, caster.manaPool)
            end,
            { -- Apply burn if caster has more SUN tokens
                duration = 3.0,
                tickDamage = 2
            },
            nil -- Don't apply burn otherwise
        ),
        slow = expr.ifCond(
            function(caster, target) 
                return ManaHelpers.count(Constants.TokenType.MOON, caster.manaPool) >= 
                       ManaHelpers.count(Constants.TokenType.SUN, caster.manaPool)
            end,
            { -- Apply slow if caster has more MOON tokens
                magnitude = 1.0,
                duration = 5.0
            },
            nil -- Don't apply slow otherwise
        )
    },
    vfx = "adaptive_surge",
    sfx = "adaptive_sound",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
}

-- Prepare the return table with all spells and utility functions
local SpellsModule = {
    spells = Spells,
    validateSpell = validateSpell,
    
    -- Public method to compile all spells
    compileAll = function()
        local compiled = {}
        for id, spell in pairs(Spells) do
            validateSpell(spell, id)
            -- References to SpellCompiler and Keywords need to be passed from game object
            -- This function will be called with the correct context from main.lua
            print("Waiting for SpellCompiler to compile: " .. spell.name)
        end
        return compiled
    end,
    
    -- Public method to get a compiled spell by ID
    getCompiledSpell = function(spellId, spellCompiler, keywords)
        if not Spells[spellId] then
            print("ERROR: Spell not found: " .. spellId)
            return nil
        end
        
        -- Make sure we have the required objects
        if not spellCompiler or not keywords then
            print("ERROR: Missing SpellCompiler or Keywords for compiling spell: " .. spellId)
            return nil
        end
        
        return spellCompiler.compileSpell(Spells[spellId], keywords)
    end
}

-- Validate all spells at module load time to catch errors early
for spellId, spell in pairs(Spells) do
    validateSpell(spell, spellId)
end

return SpellsModule