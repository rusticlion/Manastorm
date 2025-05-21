-- characterData.lua
-- Defines color and spellbook data for each playable character

local SpellsModule = require("spells")
local Spells = SpellsModule.spells

local characterData = {}

characterData.Ashgar = {
    color = {255,100,100},
    spellbook = {
        ["1"]  = Spells.conjurefire,
        ["2"]  = Spells.firebolt,
        ["3"]  = Spells.fireball,
        ["12"] = Spells.burnToAsh,
        ["13"] = Spells.blastwave,
        ["23"] = Spells.saltcircle,
        ["123"] = Spells.eruption,
    },
    spells = {
        Spells.conjurefire,
        Spells.firebolt,
        Spells.fireball,
        Spells.burnToAsh,
        Spells.blastwave,
        Spells.saltcircle,
        Spells.eruption,
        Spells.combustMana,
        Spells.blazingAscent,
    }
}

characterData.Selene = {
    color = {100,100,255},
    spellbook = {
        ["1"]  = Spells.conjuremoonlight,
        ["2"]  = Spells.wrapinmoonlight,
        ["3"]  = Spells.moondance,
        ["12"] = Spells.infiniteprocession,
        ["13"] = Spells.eclipse,
        ["23"] = Spells.gravityTrap,
        ["123"] = Spells.fullmoonbeam,
    },
    spells = {
        Spells.conjuremoonlight,
        Spells.wrapinmoonlight,
        Spells.moondance,
        Spells.infiniteprocession,
        Spells.eclipse,
        Spells.gravityTrap,
        Spells.fullmoonbeam,
        Spells.lunardisjunction,
        Spells.lunarTides,
    }
}

characterData.Silex = {
    color = {200,200,200},
    spellbook = {
        ["1"]  = Spells.conjuresalt,
        ["2"]  = Spells.glitterfang,
        ["3"]  = Spells.imprison,
        ["12"] = Spells.saltcircle,
        ["13"] = Spells.stoneshield,
        ["23"] = Spells.shieldbreaker,
        ["123"] = Spells.saltstorm,
    },
    spells = {
        Spells.conjuresalt,
        Spells.glitterfang,
        Spells.imprison,
        Spells.saltcircle,
        Spells.stoneshield,
        Spells.shieldbreaker,
        Spells.saltstorm,
        Spells.jaggedearth,
    }
}

characterData.Borrak = {
    color = {100,180,255},
    spellbook = {
        ["1"]  = Spells.conjurewater,
        ["2"]  = Spells.watergun,
        ["3"]  = Spells.riptideguard,
        ["12"] = Spells.tidalforce,
        ["13"] = Spells.brinechain,
        ["23"] = Spells.maelstrom,
        ["123"] = Spells.wavecrash,
    },
    spells = {
        Spells.conjurewater,
        Spells.watergun,
        Spells.riptideguard,
        Spells.tidalforce,
        Spells.brinechain,
        Spells.maelstrom,
        Spells.wavecrash,
        Spells.forceBlast,
    }
}

characterData.Brightwulf = {
    color = {255,100,100},
    spellbook = {
        ["1"]  = Spells.burnTheSoul,
        ["2"]  = Spells.SpaceRipper,
        ["3"]  = Spells.StingingEyes,
        ["12"] = Spells.emberlift,
        ["13"] = Spells.meteor,
        ["23"] = Spells.fusionRay,
        ["123"] = Spells.CoreBolt,
    },
    spells = {
        Spells.burnTheSoul,
        Spells.SpaceRipper,
        Spells.StingingEyes,
        Spells.emberlift,
        Spells.meteor,
        Spells.fusionRay,
        Spells.CoreBolt,
    }
}

-- Placeholder spellbooks for other characters, defaulting to Ashgar's spells
local defaultSpellbook = characterData.Ashgar.spellbook
local defaultColor = {255,255,255}

local roster = {"Klaus","Ohm","Archive","End"}
for _, name in ipairs(roster) do
    characterData[name] = {
        color = defaultColor,
        spellbook = defaultSpellbook,
    }
end

return characterData
