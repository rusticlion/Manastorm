-- spells/elements/mind.lua
-- Contains mind-element spells

local Constants = require("core.Constants")

local MindSpells = {}

-- Placeholder for future Mind element spells

-- TODO: add "spell state" tracking to support this (and probably other Mind and Star spells in particular)
MindSpells.thoughtscalp = {
    id = "thoughtscalp",
    name = "Thought Scalp",
    affinity = "mind",
    description = "Picks at opponent's worst fear, dealing slightly more damage every time.",
    attackType = Constants.AttackType.REMOTE,
    visualShape = "slash", -- Constants.VisualShape.SLASH,
    castTime = Constants.CastSpeed.NORMAL,
    cost = {Constants.TokenType.MIND},
    keywords = {
      damage = 10
    }
}

return MindSpells