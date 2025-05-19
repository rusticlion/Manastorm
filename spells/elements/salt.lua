-- spells/elements/salt.lua
-- Contains salt-element spells

local Constants = require("core.Constants")

local SaltSpells = {}

-- Conjure Salt spell
SaltSpells.conjuresalt = {
    id = "conjuresalt",
    name = "Conjure Salt",
    affinity = "salt",
    description = "Creates a new Salt mana token",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.FAST,
    cost = {},
    keywords = {
        conjure = {
            token = Constants.TokenType.SALT,
            amount = 1
        },
    },

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

-- Glitter Fang spell
SaltSpells.glitterfang = {
    id = "glitterfang",
    name = "Glitter Fang",
    affinity = "salt",
    description = "Very fast, unblockable attack. Only hits NEAR/GROUNDED enemies",
    castTime = Constants.CastSpeed.VERY_FAST,
    attackType = Constants.AttackType.UTILITY,
    cost = {Constants.TokenType.SALT, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = 7,
            type = Constants.DamageType.SALT,
            condition = function(caster, target, slot)
                return target and target.gameState.rangeState == Constants.RangeState.NEAR
                    and target.elevation == Constants.ElevationState.GROUNDED
            end
        },
    },
    sfx = "glitter_fang",
}

-- Salt Storm spell
SaltSpells.saltstorm = {
    id = "saltstorm",
    name = "Salt Storm",
    affinity = "salt",
    description = "Slow, hard-hitting, shield-breaking area attack.",
    castTime = Constants.CastSpeed.VERY_SLOW,
    attackType = Constants.AttackType.ZONE,
    cost = {Constants.TokenType.SALT, Constants.TokenType.SALT, Constants.TokenType.SALT},
    keywords = {
        damage = {
            amount = 15,
            type = Constants.DamageType.SALT
        },
        zoneMulti = true,
        shieldBreaker = 2,
    },
    sfx = "salt_storm",
}

-- Imprison spell (Salt trap)
SaltSpells.imprison = {
    id = "imprison",
    name = "Imprison",
    affinity = "salt",
    description = "Trap: Deals damage and prevents enemy movement to FAR",
    attackType = "utility",
    castTime = Constants.CastSpeed.SLOW,
    cost = {Constants.TokenType.SALT, Constants.TokenType.SALT},
    keywords = {
        sustain = true,
        
        trap_trigger = { 
            condition = "on_opponent_far" 
        },
        
        
        trap_effect = {
            damage = { 
                amount = 7, 
                type = Constants.DamageType.SALT,  
                target = "ENEMY" 
            },
            rangeShift = { 
                position = Constants.RangeState.NEAR,
            },
        },
    },
    sfx = "gravity_trap_set",
}

-- Jagged Earth spell (Salt trap)
SaltSpells.jaggedearth = {
    id = "jaggedearth",
    name = "Jagged Earth",
    affinity = "salt",
    description = "Trap: Creates a zone of jagged earth that hurts enemies when they become Grounded.",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.ZONE,
    cost = {Constants.TokenType.SALT, Constants.TokenType.SALT},
    keywords = {
        damage = {
            amount = 7, 
            type = Constants.DamageType.SALT,
            condition = function(caster, target, slot)
                return target and target.elevation == Constants.ElevationState.GROUNDED
            end
        },
        rangeShift = {  
            position = Constants.RangeState.NEAR,
        },
    },
    sfx = "jagged_earth",
}

-- Salt Circle spell (Ward)
SaltSpells.saltcircle = {
    id = "saltcircle",
    name = "Salt Circle",
    affinity = "salt",
    description = "Ward: Creates a circle of Salt around the caster",
    castTime = Constants.CastSpeed.VERY_FAST,
    attackType = Constants.AttackType.ZONE,
    cost = {Constants.TokenType.SALT},
    keywords = {
        block = {
            type = Constants.ShieldType.WARD,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.REMOTE},
        }
    },
    sfx = "salt_circle",
}

-- Stone Shield spell (Barrier)
SaltSpells.stoneshield = {
    id = "stoneshield",
    name = "Stone Shield",
    affinity = "salt",
    description = "Barrier: Creates a shield of stone around the caster",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.UTILITY,
    cost = {Constants.TokenType.SALT, Constants.TokenType.SALT},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
        }
    },
    sfx = "stone_shield",
}

-- Shield-breaking spell
SaltSpells.shieldbreaker = {
    id = "shieldbreaker",
    name = "Salt Spear",
    affinity = "salt",
    description = "A mineral lance that shatters wards and barriers",
    attackType = Constants.AttackType.PROJECTILE,
    castTime = Constants.CastSpeed.SLOW,
    cost = {Constants.TokenType.SALT, Constants.TokenType.SALT, Constants.TokenType.SALT},
    keywords = {
        damage = {
            amount = function(caster, target)
                local baseDamage = 8
                
                local shieldBonus = 0
                if target and target.spellSlots then
                    for _, slot in ipairs(target.spellSlots) do
                        if slot.active and slot.isShield then
                            shieldBonus = shieldBonus + 6
                            break
                        end
                    end
                end
                
                return baseDamage + shieldBonus
            end,
            type = "force"
        },
    },
    shieldBreaker = 3,
    sfx = "shield_break",
    
    onBlock = function(caster, target, slot, blockInfo)
        print(string.format("[SHIELD BREAKER] %s's Shield Breaker is testing the %s shield's strength!", 
            caster.name, blockInfo.blockType))
        
        return {
            specialBlockMessage = "Shield Breaker collides with active shield!",
            damageShield = true,
            continueExecution = false
        }
    end
}

return SaltSpells