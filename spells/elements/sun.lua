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
}

-- Radiant Field spell applying slow to both wizards
SunSpells.radiantfield = {
    id = "radiantfield",
    name = "Radiant Field",
    affinity = "sun",
    description = "Blinding field that slows both wizards while active.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.UTILITY,
    visualShape = "blast",
    cost = {Constants.TokenType.SUN, Constants.TokenType.SUN},
    keywords = {
        field_status = {
            statusType = Constants.StatusType.SLOW,
            magnitude = Constants.CastSpeed.ONE_TIER
        }
    },
    sfx = "radiant_field"
}

return SunSpells
