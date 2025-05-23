-- spells/elements/generic.lua
-- Contains generic spells with no elemental affinity

local Constants = require("core.Constants")

local GenericSpells = {}

-- Placeholder spell for empty slots
GenericSpells.none = {
    id = "none",
    name = "<None>",
    affinity = "generic",
    description = "Empty spell slot. Cast to do nothing.",
    attackType = Constants.AttackType.UTILITY,
    visualShape = "none",
    castTime = Constants.CastSpeed.INSTANT,
    cost = {},  -- No mana cost
    keywords = {
        -- No effect - this is a no-op spell
    },
}

return GenericSpells