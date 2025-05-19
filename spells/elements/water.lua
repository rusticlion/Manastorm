-- spells/elements/water.lua
-- Contains water-element spells

local Constants = require("core.Constants")
local ManaHelpers = require("systems.ManaHelpers")

local WaterSpells = {}

-- Water Gun spell
WaterSpells.watergun = {
    id = "watergun",
    name = "Water Gun",
    affinity = "water",
    description = "Quick ranged hit, more damage against NEAR opponents",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = Constants.VisualShape.BOLT,
    cost = {Constants.TokenType.WATER, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.gameState.rangeState == Constants.RangeState.NEAR then
                    return 15
                end
                return 10
            end,
            type = Constants.DamageType.WATER
        }
    },
    sfx = "fire_whoosh",
}

-- Force blast spell (Steam Vent) - water and fire combo
WaterSpells.forceBlast = {
    id = "forceblast",
    name = "Steam Vent",
    affinity = "water",
    description = "Unleashes a blast of steam that launches opponents into the air",
    attackType = "remote",
    castTime = 4.0,
    cost = {"fire", "water"},
    keywords = {
        damage = {
            amount = 8,
            type = "force"
        },
        elevate = {
            duration = 3.0,
            target = "ENEMY",
        },
    },
    sfx = "force_wind",
}

-- Conjure Water spell
WaterSpells.conjurewater = {
    id = "conjurewater",
    name = "Conjure Water",
    affinity = Constants.TokenType.WATER,
    description = "Conjures a Water mana token. Takes longer to cast the more Water tokens already present.",
    attackType = Constants.AttackType.UTILITY,
    visualShape = Constants.VisualShape.CONJURE_BASE,
    castTime = Constants.CastSpeed.FAST,
    cost = {},
    keywords = {
        conjure = {
            token = Constants.TokenType.WATER,
            amount = 1
        }
    },

    getCastTime = function(caster)
        local baseCastTime = Constants.CastSpeed.FAST
        local waterCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == Constants.TokenType.WATER and token.state == Constants.TokenState.FREE then
                    waterCount = waterCount + 1
                end
            end
        end
        return baseCastTime + (waterCount * Constants.CastSpeed.ONE_TIER)
    end
}

-- Maelstrom spell - damage scales with WATER tokens in the pool
WaterSpells.maelstrom = {
    id = "maelstrom",
    name = "Maelstrom",
    affinity = Constants.TokenType.WATER,
    description = "Remote blast that grows stronger with each Water token in the mana pool",
    attackType = Constants.AttackType.REMOTE,
    visualShape = Constants.VisualShape.WAVE,
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.WATER, Constants.TokenType.WATER},
    keywords = {
        damage = {
            amount = function(caster, target)
                local count = ManaHelpers.count(Constants.TokenType.WATER, caster.manaPool)
                return 6 + (count * 2)
            end,
            type = Constants.DamageType.WATER
        }
    },
    sfx = "water_surge",
}

-- Riptide Guard shield - switches range when it blocks
WaterSpells.riptideguard = {
    id = "riptideguard",
    name = "Riptide Guard",
    affinity = Constants.TokenType.WATER,
    description = "Barrier that swaps range with the opponent when it blocks an attack",
    attackType = Constants.AttackType.UTILITY,
    visualShape = Constants.VisualShape.WAVE,
    castTime = Constants.CastSpeed.FAST,
    cost = {Constants.TokenType.WATER, Constants.TokenType.WATER},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.REMOTE},

            onBlock = function(defender, attacker, slotIndex, info)
                local events = {}
                local gameState = defender.gameState
                local newRange = Constants.RangeState.NEAR
                if gameState and gameState.rangeState == Constants.RangeState.NEAR then
                    newRange = Constants.RangeState.FAR
                end
                table.insert(events, {
                    type = "SET_RANGE",
                    source = "caster",
                    target = "both",
                    position = newRange
                })
                return events
            end
        }
    },
    sfx = "tide_rush",
}

-- Brine Chain spell - salt infused lash that slows
WaterSpells.brinechain = {
    id = "brinechain",
    name = "Brine Chain",
    affinity = Constants.TokenType.WATER,
    description = "Salt-laced lash that slows the enemy. Damage scales with Water tokens in the pool",
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = Constants.VisualShape.BOLT,
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.WATER, Constants.TokenType.SALT},
    keywords = {
        damage = {
            amount = function(caster, target)
                local count = ManaHelpers.count(Constants.TokenType.WATER, caster.manaPool)
                return 5 + count
            end,
            type = Constants.DamageType.WATER
        },
        slow = {
            magnitude = 1.0,
            duration = 2.0
        }
    },
    sfx = "water_whip",
}

-- Wave Crash spell - consumes tokens for a powerful strike
WaterSpells.wavecrash = {
    id = "wavecrash",
    name = "Wave Crash",
    affinity = Constants.TokenType.WATER,
    description = "Consumes its channeled tokens to unleash a devastating wave",
    attackType = Constants.AttackType.ZONE,
    visualShape = Constants.VisualShape.WAVE,
    castTime = Constants.CastSpeed.SLOW,
    cost = {Constants.TokenType.WATER, Constants.TokenType.WATER, Constants.TokenType.WATER},
    keywords = {
        damage = {
            amount = function(caster, target)
                local count = ManaHelpers.count(Constants.TokenType.WATER, caster.manaPool)
                return 10 + count * 3
            end,
            type = Constants.DamageType.WATER
        },
        consume = { amount = "all" },
        conjure = {
            token = Constants.TokenType.SALT,
            amount = 1
        }
    },
    sfx = "wave_crash",
}

return WaterSpells
