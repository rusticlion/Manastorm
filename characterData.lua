-- characterData.lua
-- Defines color and spellbook data for each playable character

local SpellsModule = require("spells")
local Spells = SpellsModule.spells

local characterData = {}

characterData.Ashgar = {
    color = {255,100,100},
    spellbook = {
        ["1"]  = Spells.conjurefire,
        ["2"]  = Spells.novaconjuring,
        ["3"]  = Spells.firebolt,
        ["12"] = Spells.battleshield,
        ["13"] = Spells.blastwave,
        ["23"] = Spells.emberlift,
        ["123"] = Spells.meteor,
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
    }
}

-- Placeholder spellbooks for other characters, defaulting to Ashgar's spells
local defaultSpellbook = characterData.Ashgar.spellbook
local defaultColor = {255,255,255}

local roster = {"Borrak","Brightwulf","Klaus","Ohm","Archive","End"}
for _, name in ipairs(roster) do
    characterData[name] = {
        color = defaultColor,
        spellbook = defaultSpellbook,
    }
end

return characterData
