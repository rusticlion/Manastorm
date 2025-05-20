-- systems/UnlockSystem.lua
-- Simple character unlock logic

local UnlockSystem = {}

--- Check if a spell unlocks any characters
-- Currently unlocks Silex when a Salt spell is cast
-- @param spell table Executed spell definition
-- @param caster table Wizard casting the spell
function UnlockSystem.checkSpellUnlock(spell, caster)
    if not spell or not caster then return end
    if spell.affinity == "salt" and game and not game.unlockedCharacters.Silex then
        game.unlockedCharacters.Silex = true
        print("[UNLOCK] Silex has been unlocked!")
        if caster.spellCastNotification then
            caster.spellCastNotification.text = "Unlocked Silex!"
            caster.spellCastNotification.timer = 2.0
        else
            caster.spellCastNotification = {
                text = "Unlocked Silex!",
                timer = 2.0,
                x = caster.x,
                y = caster.y + 70,
                color = {1,1,0,1}
            }
        end
    end

    -- Unlock additional spells
    if spell.unlockSpell and game and not game.unlockedSpells[spell.unlockSpell] then
        game.unlockedSpells[spell.unlockSpell] = true
        print("[UNLOCK] Spell unlocked: " .. spell.unlockSpell)
    end
end

return UnlockSystem
