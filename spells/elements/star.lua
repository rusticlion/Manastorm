-- spells/elements/star.lua
-- Contains star-element spells

local Constants = require("core.Constants")
local expr = require("expr")
local ManaHelpers = require("systems.ManaHelpers")

local StarSpells = {}

-- Conjure Stars spell
StarSpells.conjurestars = {
    id = "conjurestars",
    name = "Conjure Stars",
    affinity = "star",
    description = "Creates a new Star mana token",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.FAST,
    cost = {},
    keywords = {
        conjure = {
            token = Constants.TokenType.STAR,
            amount = 1
        },
    },
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

-- Adaptive Surge test spell
StarSpells.adaptive_surge = {
    id = "adaptivesurge",
    name = "Starstuff",
    affinity = "star",
    description = "A spell that adapts its effects based on the current mana pool",
    attackType = Constants.AttackType.PROJECTILE,
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.STAR, Constants.TokenType.SUN, Constants.TokenType.MOON},
    keywords = {
        damage = {
            amount = expr.countScale(Constants.TokenType.SUN, 5, 2),
            type = expr.more(Constants.TokenType.SUN, Constants.TokenType.MOON)
        },
        burn = expr.ifCond(
            function(caster, target) 
                return ManaHelpers.count(Constants.TokenType.SUN, caster.manaPool) > 
                    ManaHelpers.count(Constants.TokenType.MOON, caster.manaPool)
            end,
            {
                duration = 3.0,
                tickDamage = 2
            },
            nil
        ),
        slow = expr.ifCond(
            function(caster, target) 
                return ManaHelpers.count(Constants.TokenType.MOON, caster.manaPool) >= 
                    ManaHelpers.count(Constants.TokenType.SUN, caster.manaPool)
            end,
            {
                magnitude = 1.0,
                duration = 5.0
            },
            nil
        ),
    },
    sfx = "adaptive_sound",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
}

-- Cosmic Rift spell
StarSpells.cosmicRift = {
    id = "cosmicrift",
    name = "Cosmic Rift",
    affinity = "star",
    description = "Opens a rift that damages opponents and disrupts spellcasting",
    attackType = Constants.AttackType.ZONE,
    castTime = 5.5,
    cost = {"star", "star", "star"},
    keywords = {
        damage = {
            amount = 12,
            type = "star"
        },
        slow = {
            magnitude = 2.0,
            duration = 10.0,
            slot = nil
        },
        zoneMulti = true,
    },
    sfx = "space_tear",
    blockableBy = {Constants.ShieldType.BARRIER}
}

return StarSpells