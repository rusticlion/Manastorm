-- spells/elements/sun.lua
-- Contains sun-element spells

local Constants = require("core.Constants")
local expr = require("expr")

local SunSpells = {}

-- Sunbolt spell
SunSpells.radiantbolt = {
    id = "radiantbolt",
    name = "Radiant Bolt",
    affinity = "sun",
    description = "Bolt of radiation that deals more damage against AERIAL opponents",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = "bolt",
    cost = {Constants.TokenType.SUN, Constants.TokenType.SUN, Constants.TokenType.SUN, Constants.TokenType.SUN},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.elevation == Constants.Elevation.AERIAL then
                    return 25
                end
                return 10
            end,
            type = Constants.DamageType.SUN
        },
    },
    sfx = "fire_whoosh",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
}

-- Meteor spell
SunSpells.meteor = {
    id = "meteor",
    name = "Meteor Dive",
    affinity = "sun",
    description = "Aerial finisher - GROUND self and create a fiery explosion. Only hits GROUNDED enemies.",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.ZONE,
    visualShape = "meteor",
    cost = {Constants.TokenType.SUN, Constants.TokenType.FIRE, Constants.TokenType.SUN, Constants.TokenType.FIRE},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.elevation == Constants.ElevationState.GROUNDED and caster.elevation == Constants.ElevationState.AERIAL then
                    return 30
                end
                return 0
            end,
            type = Constants.DamageType.SUN,
        },
        rangeShift = {
            position = Constants.RangeState.NEAR
        },
        ground = {
            target = Constants.TargetType.SELF 
        }
    },
    sfx = "meteor_impact",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.FIELD}
}

-- Emberlift spell
SunSpells.emberlift = {
    id = "emberlift",
    name = "Emberlift",
    affinity = "sun",
    description = "Launches caster into the air, shifts RANGE, and conjures a Fire token.",
    castTime = Constants.CastSpeed.FAST,
    attackType = "utility",
    visualShape = "surge",
    cost = {"sun"},
    keywords = {
        conjure = {
            token = Constants.TokenType.FIRE,
            amount = 1
        },
        elevate = {
            duration = 5.0,
            target = "SELF",
        },
        rangeShift = {
            position = expr.byRange({
                NEAR = "FAR",
                FAR = "NEAR",
                default = "NEAR"
            }),
        }
    },
    sfx = "whoosh_up",
    blockableBy = {}
}

-- Nova Conjuring (Combine 3 x FIRE into SUN)
SunSpells.novaconjuring = {
    id = "novaconjuring",
    name = "Nova Conjuring",
    affinity = "sun",
    description = "Expends Fire tokens to conjure a Sun token.",
    attackType = Constants.AttackType.UTILITY,
    visualShape = "surge",
    castTime = Constants.CastSpeed.NORMAL,
    cost = {"fire", "fire", "fire"},
    keywords = {
        consume = true,
        conjure = {
            token = {
                Constants.TokenType.SUN,
            },
            amount = 1
        },
    },
    sfx = "conjure_nova",
    blockableBy = {}
}

-- Burn the Soul (Inflict Burn on self to conjure a Sun token)
SunSpells.burnTheSoul = {
    id = "burnTheSoul",
    name = "Burn the Soul",
    affinity = "sun",
    description = "Inflict Burn on self to conjure a Sun token.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.UTILITY,
    visualShape = "surge",
    cost = {},
    keywords = {
        burn = {
            amount = 1,
            duration = 10,
            target = Constants.TargetType.SELF
        },
        conjure = {
            token = Constants.TokenType.SUN,
            amount = 1
        }
    }
}

SunSpells.SpaceRipper = {
    id = "SpaceRipper",
    name = "Space Ripper",
    affinity = "sun",
    description = "Range swap to NEAR. Burn both self and target. Turn SUN to VOID.",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.REMOTE,
    visualShape = "warp",
    cost = {Constants.TokenType.SUN},
    keywords = {
        rangeShift = {
            position = Constants.RangeState.NEAR
        },
        burn = {
            amount = 3,
            duration = 3,
            target = Constants.TargetType.ALL
        },
        consume = true,
        conjure = {
            token = Constants.TokenType.VOID,
            amount = 1
        }
    }
}

SunSpells.StingingEyes = {
    id = "StingingEyes",
    name = "Stinging Eyes",
    affinity = "sun",
    description = "Damage based on user's Burn level.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = "beam",
    cost = {Constants.TokenType.SUN, Constants.TokenType.SUN},
    keywords = {
        damage = {
            amount = function(caster, target)
                local baseDamage = 3
                local selfBurnIntensity = 0
                local bonusPerIntensityPoint = 8 -- How much extra damage per point of self-burn tickDamage

                -- Check if the caster is burning
                if caster.statusEffects and
                   caster.statusEffects.burn and
                   caster.statusEffects.burn.active then
                    selfBurnIntensity = caster.statusEffects.burn.tickDamage or 0
                end

                local totalDamage = baseDamage + (selfBurnIntensity * bonusPerIntensityPoint)

                return totalDamage
            end,
            type = Constants.DamageType.SUN
        },
        burn = {
            amount = function(caster, target)
                -- Check if the caster is burning
                if caster.statusEffects and
                   caster.statusEffects.burn and
                   caster.statusEffects.burn.active then
                    local selfBurnIntensity = caster.statusEffects.burn.tickDamage or 0
                    return selfBurnIntensity
                end
                return 0
            end,
            duration = 1,
            target = Constants.TargetType.ENEMY
        }
    }
}

SunSpells.CoreBolt = {
    id = "CoreBolt",
    name = "Core Bolt",
    affinity = "sun",
    description = "Expend SUN and VOID for a powerful energy bolt.",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = "bolt",
    cost = {Constants.TokenType.SUN, Constants.TokenType.VOID, Constants.TokenType.SUN},
    keywords = {
        damage = {
            amount = 25,
            target = Constants.TargetType.ENEMY
        },
        consume = true,
    },
    sfx = "fire_whoosh",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
}
SunSpells.NuclearFurnace = {
    id = "NuclearFurnace",
    name = "Nuclear Furnace",
    affinity = "sun",
    description = "Damage based on user's Burn level. Burn user further. Conjure Fire.",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.ZONE,
    visualShape = "blast",
    cost = {Constants.TokenType.SUN, Constants.TokenType.SUN},
    keywords = {
        damage = {
            amount = function(caster, target)
                local baseDamage = 10
                local selfBurnIntensity = 0
                local bonusPerIntensityPoint = 10 -- How much extra damage per point of self-burn tickDamage

                -- Check if the caster is burning
                if caster.statusEffects and
                   caster.statusEffects.burn and
                   caster.statusEffects.burn.active then
                    selfBurnIntensity = caster.statusEffects.burn.tickDamage or 0
                end

                local attackStrength = baseDamage + (selfBurnIntensity * bonusPerIntensityPoint)

                if caster.elevation ~= target.elevation then
                    attackStrength = attackStrength * 0.5
                end

                if caster.gameState.rangeState ~= Constants.RangeState.NEAR then
                    attackStrength = attackStrength * 0.5
                end

                return attackStrength
            end,
            type = Constants.DamageType.SUN
        },
        conjure = {
            token = Constants.TokenType.FIRE,
            amount = 1
        },
        burn = {
            amount = 2,
            duration = 7,
            target = Constants.TargetType.SELF
        }
    },
    sfx = "fire_whoosh",
    blockableBy = {Constants.ShieldType.BARRIER}
}

-- Force Barrier spell (Sun-based shield)
SunSpells.forcebarrier = {
    id = "forcebarrier",
    name = "Sun Block",
    affinity = "sun",
    description = "A protective barrier that blocks projectile and area attacks",
    castTime = Constants.CastSpeed.SLOW,
    attackType = "utility",
    visualShape = "surge",
    cost = {"sun", "sun"},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE}
        },
    },
    sfx = "shield_up",
    blockableBy = {}
}

return SunSpells