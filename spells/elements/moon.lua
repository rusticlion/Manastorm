-- spells/elements/moon.lua
-- Contains moon-element spells

local Constants = require("core.Constants")
local expr = require("expr")

local MoonSpells = {}

-- Basic Moon Conjuring
MoonSpells.conjuremoonlight = {
    id = "conjuremoonlight",
    name = "Conjure Moonlight",
    affinity = Constants.TokenType.MOON,
    description = "Conjures a Moon mana token. Takes longer to cast the more Moon tokens already present.",
    attackType = "utility",
    visualShape = "affectManaPool",
    castTime = Constants.CastSpeed.FAST,
    cost = {},
    keywords = {
        conjure = {
            token = Constants.TokenType.MOON,
            amount = 1
        },
    },
    blockableBy = {},
    
    getCastTime = function(caster)
        local baseCastTime = Constants.CastSpeed.FAST
        local moonCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == Constants.TokenType.MOON and token.state == "FREE" then
                    moonCount = moonCount + 1
                end
            end
        end
        return baseCastTime + (moonCount * Constants.CastSpeed.ONE_TIER)
    end
}

-- Tidal Force spell
MoonSpells.tidalforce = {
    id = "tidalforce",
    name = "Tidal Force",
    affinity = Constants.TokenType.MOON,
    description = "Chip damage, forces AERIAL enemies out of the air",
    attackType = Constants.AttackType.REMOTE,
    visualShape = "warp",
    castTime = Constants.CastSpeed.FAST,
    cost = {Constants.TokenType.WATER, Constants.TokenType.MOON},
    keywords = {
        damage = {
            amount = 5,
            type = Constants.TokenType.MOON
        },
        ground = {
            conditional = function(caster, target)
                return target and target.elevation == "AERIAL"
            end,
            target = "ENEMY",
        },
    },
    sfx = "tidal_wave",
    blockableBy = {Constants.ShieldType.WARD}
}

-- Lunar Disjunction spell
MoonSpells.lunardisjunction = {
    id = "lunardisjunction",
    name = "Lunar Disjunction",
    affinity = Constants.TokenType.MOON,
    description = "Cleansing moonlight cancels an opponent's spell and dissolves its mana",
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = "zap",
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON},
    keywords = {
        disjoint = {
            slot = function(caster, target, slot) 
                local slotNum = tonumber(slot) or 0
                if slotNum > 0 and slotNum <= 3 then
                    return slotNum
                else
                    return 0  -- 0 means find the first active slot
                end
            end,
            target = "SLOT_ENEMY"
        },
    },
    sfx = "lunardisjunction_sound",
    blockableBy = {Constants.ShieldType.WARD}
}

-- Moon Dance spell
MoonSpells.moondance = {
    id = "moondance",
    name = "Moon Dance",
    affinity = Constants.TokenType.MOON,
    description = "Warp space to switch range, deal chip damage, and Freeze xxx enemy Root slot.",
    attackType = "remote",
    visualShape = "warp",
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
            duration = 3,
            target = "SLOT_ENEMY",
            slot = 1
        }
    }
}

-- Gravity spell
MoonSpells.gravity = {
    id = "gravity",
    name = "Increase Gravity",
    affinity = Constants.TokenType.MOON,
    description = "Grounds AERIAL enemies",
    attackType = Constants.AttackType.REMOTE,
    visualShape = "warp",
    castTime = Constants.CastSpeed.FAST,
    cost = {Constants.TokenType.MOON, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.elevation then
                    return target.elevation == "AERIAL" and 15 or 3
                end
                return 3
            end,
            type = Constants.TokenType.MOON
        },
        ground = {
            conditional = function(caster, target)
                return target and target.elevation == "AERIAL"
            end,
            target = "ENEMY",
        },
        stagger = {
            duration = 2.0
        },
    },
    sfx = "gravity_slam",
    blockableBy = {Constants.ShieldType.WARD}
}

-- Eclipse spell
MoonSpells.eclipse = {
    id = "eclipse",
    name = "Total Eclipse",
    affinity = Constants.TokenType.MOON,
    description = "Freeze xxx your Heart slot. Conjure Sun.",
    attackType = "utility", 
    visualShape = "eclipse",
    castTime = Constants.CastSpeed.VERY_FAST,
    cost = {Constants.TokenType.MOON, Constants.TokenType.SUN},
    keywords = {
        freeze = {
            duration = 3,
            slot = 2,
            target = "self"
        },
        conjure = {
            token = Constants.TokenType.SUN,
            amount = 1
        },
    },
    sfx = "eclipse_shatter",
    blockableBy = {}
}

-- Full Moon Beam spell
MoonSpells.fullmoonbeam = {
    id = "fullmoonbeam",
    name = "Full Moon Beam",
    affinity = Constants.TokenType.MOON,
    description = "Channels moonlight into a beam that deals more damage the longer it's delayed.",
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = "beam",
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON, Constants.TokenType.MOON},
    keywords = {
        damage = {
            amount = function(caster, target, slot)
                local baseCastTime = Constants.CastSpeed.FAST
                local accruedModifier = 0
                
                if slot and caster.spellSlots[slot] then
                    local spellSlotData = caster.spellSlots[slot]
                    print(string.format("DEBUG_FMB_SLOT_CHECK: Slot=%d, Active=%s, Progress=%.2f, CastTime=%.1f, Modifier=%.4f, Frozen=%s",
                        slot, tostring(spellSlotData.active), spellSlotData.progress or -1, spellSlotData.castTime or -1, spellSlotData.castTimeModifier or -99, tostring(spellSlotData.frozen)))
                    
                    baseCastTime = spellSlotData.castTime 
                    accruedModifier = spellSlotData.castTimeModifier or 0
                    print(string.format("DEBUG_FMB: Read castTimeModifier=%.4f from spellSlotData", accruedModifier))
                else
                    print(string.format("DEBUG_FMB_WARN: Slot %s or caster.spellSlots[%s] is nil!", tostring(slot), tostring(slot)))
                end
                
                local effectiveCastTime = math.max(0.1, baseCastTime + accruedModifier)
                local damage = math.floor(effectiveCastTime * 2.5)
                
                print(string.format("Full Moon Beam: Base Cast=%.1fs, Modifier=%.1fs, Effective=%.1fs => Damage=%d", 
                    baseCastTime, accruedModifier, effectiveCastTime, damage))
                
                return damage
            end,
            type = Constants.TokenType.MOON
        },
        vfx = { effect = Constants.VFXType.FULLMOONBEAM, target = Constants.TargetType.ENEMY }
    },
    sfx = "beam_charge",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
}

-- Lunar Tides spell
MoonSpells.lunarTides = {
    id = "lunartides",
    name = "Lunar Tides",
    affinity = Constants.TokenType.MOON,
    description = "Manipulates the battle flow based on range and elevation",
    attackType = Constants.AttackType.REMOTE,
    visualShape = "warp",
    castTime = 7.0,
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON, Constants.TokenType.ANY, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = expr.byElevation({
                GROUNDED = 8,
                AERIAL = 12,
                default = 8
            }),
            type = Constants.TokenType.MOON,
            target = "ENEMY"
        },
        rangeShift = {
            position = expr.byRange({
                NEAR = "FAR",
                FAR = "NEAR",
                default = "NEAR"
            }),
            target = "SELF"
        },
    },
    sfx = "tide_rush",
    blockableBy = {Constants.ShieldType.WARD}
}

-- Wings of Moonlight (shield spell)
MoonSpells.wrapinmoonlight = {
    id = "wrapinmoonlight",
    name = "Wings of Moonlight",
    affinity = Constants.TokenType.MOON,
    description = "A runic Ward that stops Projectile and Remote attacks, elevating the caster.",
    attackType = "utility",
    visualShape = "wings",
    castTime = Constants.CastSpeed.FAST,
    cost = {Constants.TokenType.MOON, "any"},
    keywords = {
        block = {
            type = Constants.ShieldType.WARD,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.REMOTE},
            
            onBlock = function(defender, attacker, slot, info)
                print("[SPELL DEBUG] Wings of Moonlight onBlock handler executing!")
                
                local events = {}
                
                table.insert(events, {
                    type = "SET_ELEVATION",
                    source = "caster",
                    target = "self",
                    elevation = Constants.ElevationState.AERIAL,
                    duration = 4.0,
                })
                
                print("[SPELL DEBUG] Wings of Moonlight returning " .. #events .. " events")
                return events
            end
        },
    },
    sfx = "mist_shimmer",
    blockableBy = {},
}

-- Gravity Trap spell
MoonSpells.gravityTrap = {
    id = "gravityTrap",
    name = "Icarus Trap",
    affinity = Constants.TokenType.MOON,
    description = "Gravitational trap that triggers when an enemy becomes AERIAL, grounding and damaging them.",
    attackType = Constants.AttackType.UTILITY,
    visualShape = "warp",
    castTime = Constants.CastSpeed.SLOW,
    cost = {Constants.TokenType.MOON, Constants.TokenType.SUN},
    keywords = {
        sustain = true,
        
        trap_trigger = { 
            condition = "on_opponent_elevate" 
        },
        
        trap_window = { 
            duration = 600.0
        },
        
        trap_effect = {
            damage = { 
                amount = 3, 
                type = Constants.TokenType.MOON,  
                target = "ENEMY" 
            },
            ground = { 
                target = "ENEMY", 
            },
            burn = { 
                duration = 1.5,
                tickDamage = 3,
                tickInterval = 0.5,
                target = "ENEMY"
            },
        },
    },
    sfx = "gravity_trap_set",
    blockableBy = {}
}

-- Infinite Procession spell
-- TODO: Improve token-shift keyword to allow _input token_ to be specified
MoonSpells.infiniteprocession = {
    id = "infiniteprocession",
    name = "Infinite Procession",
    affinity = Constants.TokenType.MOON,
    description = "Transmutes MOON tokens into SUN or SUN into MOON.",
    attackType = Constants.AttackType.UTILITY,
    visualShape = "affectManaPool",
    castTime = Constants.CastSpeed.NORMAL,
    cost = {},
    keywords = {
        tokenShift = {
            type = expr.more(Constants.TokenType.SUN, Constants.TokenType.MOON),
            amount = 1
        },
    },
    sfx = "conjure_infinite",
}

-- Enhanced Mirror Shield (moon-based shield)
MoonSpells.enhancedmirrorshield = {
    id = "enhancedmirrorshield",
    name = "Celestial Mirror",
    affinity = Constants.TokenType.MOON,
    description = "A powerful reflective barrier that returns damage to attackers with interest",
    attackType = Constants.AttackType.UTILITY,
    visualShape = "mirror",
    castTime = Constants.CastSpeed.VERY_SLOW,
    cost = {Constants.TokenType.MOON, Constants.TokenType.MOON, Constants.TokenType.STAR},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
            
            onBlock = function(defender, attacker, slotIndex, blockInfo)
                if not attacker then return {} end
                
                local events = {}
                
                table.insert(events, {
                    type = "DAMAGE",
                    source = "caster",
                    target = "enemy",
                    amount = 10,
                    damageType = "star",
                    reflectedDamage = true
                })
                
                table.insert(events, {
                    type = "EFFECT",
                    source = "caster",
                    target = "enemy",
                    effectType = "reflect",
                    duration = 0.5
                })
                
                return events
            end
        },
    },
    sfx = "crystal_ring",
    blockableBy = {}
}

return MoonSpells