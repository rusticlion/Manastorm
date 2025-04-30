-- spells/elements/sun.lua
-- Contains sun-element spells

local Constants = require("core.Constants")
local expr = require("expr")

local SunSpells = {}

-- Meteor spell
SunSpells.meteor = {
    id = "meteor",
    name = "Meteor Dive",
    affinity = "sun",
    description = "Aerial finisher, hits GROUNDED enemies",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.ZONE,
    visualShape = "meteor",
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
        },
        vfx = { effect = Constants.VFXType.METEOR, target = Constants.TargetType.ENEMY }
    },
    sfx = "meteor_impact",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.FIELD}
}

-- Emberlift spell
SunSpells.emberlift = {
    id = "emberlift",
    name = "Emberlift",
    affinity = "sun",
    description = "Launches caster into the air, shifts range, and conjures FIRE",
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
    description = "Conjures SUN token from FIRE.",
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