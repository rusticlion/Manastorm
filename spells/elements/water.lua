-- spells/elements/water.lua
-- Contains water-element spells

local Constants = require("core.Constants")

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
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
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
    blockableBy = {Constants.ShieldType.BARRIER}
}

return WaterSpells