-- spells/elements/sun.lua
-- Contains sun-element spells

local Constants = require("core.Constants")
local expr = require("expr")

local SunSpells = {}

-- Sunbolt spell
SunSpells.radiantbolt = {
    id = "radiantbolt",
    name = "Radiant Bolt",
    affinity = Constants.TokenType.SUN,
    description = "Bolt of radiation that deals more damage against AERIAL opponents",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = Constants.VisualShape.BOLT,
    cost = {Constants.TokenType.SUN, Constants.TokenType.SUN, Constants.TokenType.SUN, Constants.TokenType.SUN},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.elevation == Constants.ElevationState.AERIAL then
                    return 25
                end
                return 10
            end,
            type = Constants.DamageType.SUN
        },
    },
    sfx = "fire_whoosh",
}

SunSpells.fusionRay = {
    id = "fusionRay",
    name = "Fusion Ray",
    affinity = Constants.TokenType.SUN,
    description = "A powerful beam of sunlight. Burns the user.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = Constants.VisualShape.BEAM,
    cost = {Constants.TokenType.SUN, Constants.TokenType.SUN, Constants.TokenType.SUN},
    keywords = {
        damage = {
            amount = 18,
            target = Constants.TargetType.ENEMY
        },
        burn = {
            amount = 1,
            duration = 5,
            target = Constants.TargetType.SELF  
        }
    },
    sfx = "fire_whoosh",
}

-- Meteor spell
SunSpells.meteor = {
    id = "meteor",
    name = "Meteor Dive",
    affinity = Constants.TokenType.SUN,
    description = "Aerial finisher - GROUND self and create a fiery explosion. Only hits GROUNDED enemies.",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.ZONE,
    visualShape = Constants.VisualShape.METEOR,
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
    affinity = Constants.TokenType.SUN,
    description = "Launches caster into the air, shifts RANGE, and conjures a Fire token.",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.UTILITY,
    visualShape = Constants.VisualShape.SURGE,
    cost = {Constants.TokenType.SUN},
    keywords = {
        conjure = {
            token = Constants.TokenType.FIRE,
            amount = 1
        },
        elevate = {
            duration = 5.0,
            target = Constants.TargetType.SELF,
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
    affinity = Constants.TokenType.SUN,
    description = "Expends Fire tokens to conjure a Sun token.",
    attackType = Constants.AttackType.UTILITY,
    visualShape = Constants.VisualShape.SURGE,
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE, Constants.TokenType.FIRE},
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

-- Burn the Soul (Inflict Burn on self to conjure a Sun token)
SunSpells.burnTheSoul = {
    id = "burnTheSoul",
    name = "Burn the Soul",
    affinity = Constants.TokenType.SUN,
    description = "Inflict Burn on self to conjure a Sun token.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.UTILITY,
    visualShape = Constants.VisualShape.SURGE,
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
    affinity = Constants.TokenType.SUN,
    description = "Range swap to NEAR. Burn both self and target. Turn SUN to VOID.",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.REMOTE,
    visualShape = Constants.VisualShape.WARP,
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
    affinity = Constants.TokenType.SUN,
    description = "Damage based on user's Burn level.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = Constants.VisualShape.BEAM,
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
    affinity = Constants.TokenType.SUN,
    description = "Expend SUN and VOID for a powerful energy bolt.",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = Constants.VisualShape.BOLT,
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
    affinity = Constants.TokenType.SUN,
    description = "Damage based on user's Burn level. Burn user further. Conjure Fire.",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.ZONE,
    visualShape = Constants.VisualShape.BLAST,
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
    affinity = Constants.TokenType.SUN,
    description = "A protective barrier that blocks projectile and area attacks",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.UTILITY,
    visualShape = Constants.VisualShape.SURGE,
    cost = {Constants.TokenType.SUN, Constants.TokenType.SUN},
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
    affinity = Constants.TokenType.SUN,
    description = "Blinding field that slows both wizards while active.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.UTILITY,
    visualShape = Constants.VisualShape.BLAST,
    cost = {Constants.TokenType.SUN, Constants.TokenType.SUN},
    keywords = {
        vfx = {
            emitEvent = true,
            target = Constants.TargetType.SELF,
            duration = 1.0,
        },
        field_status = {
            statusType = Constants.StatusType.SLOW,
            magnitude = Constants.CastSpeed.ONE_TIER
        }
    },
    sfx = "radiant_field"
}

return SunSpells
