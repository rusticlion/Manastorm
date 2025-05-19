-- spells/elements/void.lua
-- Contains void-element spells

local Constants = require("core.Constants")

local VoidSpells = {}

-- Hilarious Void "conjuring" spell
VoidSpells.conjurenothing = {
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
    sfx = "void_conjure",
}

-- TODO: Implement this spell. Might need dynamic costing to be implemented first.
-- Design
VoidSpells.riteofemptiness = {
    id = "riteofemptiness",
    name = "Rite of Emptiness",
    affinity = "void",
    description = "Consumes SALT to create STAR, consumes STAR to create VOID.",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.NORMAL,
    cost = {},
    keywords = {
        --todo
    }
}

-- One-shot kill combo payoff/mega-nuke
VoidSpells.heartripper = {
    id = "heartripper",
    name = "Heart Ripper",
    affinity = "void",
    description = "A terrible curse that strikes down the target with a single instant-kill hit.",
    attackType = Constants.AttackType.REMOTE,
    castTime = Constants.CastSpeed.VERY_SLOW,
    cost = {Constants.TokenType.VOID, Constants.TokenType.STAR, Constants.TokenType.STAR, Constants.TokenType.SALT, Constants.TokenType.SALT, Constants.TokenType.SALT},
    keywords = {
        damage = {
            amount = 100,
            type = Constants.TokenType.VOID
        }
    },
    sfx = "heartripper",
}

return VoidSpells