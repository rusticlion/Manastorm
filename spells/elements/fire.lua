-- spells/elements/fire.lua
-- Contains fire-element spells

local Constants = require("core.Constants")
local expr = require("expr")

local FireSpells = {}

-- Basic Fire Conjuring
FireSpells.conjurefire = {
    id = "conjurefire",
    name = "Conjure Fire",
    affinity = "fire",
    description = "Creates a new Fire mana token",
    attackType = Constants.AttackType.UTILITY,
    castTime = Constants.CastSpeed.FAST,
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = Constants.TokenType.FIRE,
            amount = 1
        },
    },
    blockableBy = {},
    
    -- Custom cast time calculation based on existing fire tokens
    getCastTime = function(caster)
        -- Base cast time
        local baseCastTime = Constants.CastSpeed.FAST
        
        -- Count fire tokens in the mana pool
        local fireCount = 0
        if caster.manaPool then
            for _, token in ipairs(caster.manaPool.tokens) do
                if token.type == Constants.TokenType.FIRE and token.state == Constants.TokenState.FREE then
                    fireCount = fireCount + 1
                end
            end
        else
            print("WARN: ConjureFire getCastTime - caster.manaPool is nil!")
        end
        return baseCastTime + (fireCount * Constants.CastSpeed.ONE_TIER)
    end
}

-- Firebolt spell
FireSpells.firebolt = {
    id = "firebolt",
    name = "Firebolt",
    affinity = "fire",
    description = "Quick ranged hit, more damage against FAR opponents",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.PROJECTILE,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.gameState.rangeState == Constants.RangeState.FAR then
                    return 12
                end
                return 7
            end,
            type = Constants.DamageType.FIRE
        },
    },
    sfx = "fire_whoosh",
    blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
}

-- Fireball spell
FireSpells.fireball = {
    id = "fireball",
    name = "Fireball",
    affinity = "fire",
    description = "Fireball",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.PROJECTILE,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = 10,
            burn = {
                amount = 2,
                duration = 2
            }
        },
        blockableBy = {Constants.ShieldType.BARRIER, Constants.ShieldType.WARD}
    }
}

-- Blastwave spell
FireSpells.blastwave = {
    id = "blastwave",
    name = "Blast Wave",
    affinity = "fire",
    description = "Blast that deals significant damage up close.",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.ZONE,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE},
    keywords = {
        damage = {
            amount = expr.byRange({
                NEAR = 18,
                FAR = 5,
                default = 5
            }),
            type = Constants.DamageType.FIRE
        },
    },
    sfx = "blastwave",
}

-- Combust Mana spell
FireSpells.combustMana = {
    id = "combustMana",
    name = "Combust Mana",
    affinity = "fire",
    description = "Disrupts opponent channeling, burning one token to Salt",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.UTILITY,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE},
    keywords = {
        disruptAndShift = {
            targetType = "salt"
        },
    },
}

-- Blazing Ascent spell
FireSpells.blazingAscent = {
    id = "blazingascent",
    name = "Blazing Ascent",
    affinity = "fire",
    description = "Rockets upward in a burst of fire, dealing damage and becoming AERIAL",
    attackType = Constants.AttackType.ZONE,
    castTime = 3.0,
    cost = {"fire", "fire", "star"},
    keywords = {
        damage = {
            amount = function(caster, target)
                -- More damage if already AERIAL (harder to cast while falling)
                return caster.elevation == "AERIAL" and 15 or 10
            end,
            type = "fire"
        },
        elevate = {
            duration = 6.0
        },
        dissipate = {
            token = Constants.TokenType.WATER,
            amount = 1
        },
    },
    sfx = "fire_whoosh",
    blockableBy = {Constants.ShieldType.BARRIER}
}

-- Eruption spell
FireSpells.eruption = {
    id = "eruption",
    name = "Molten Ash",
    affinity = "fire",
    description = "Creates a volcanic eruption under the opponent. Only works at NEAR range.",
    attackType = Constants.AttackType.ZONE,
    castTime = Constants.CastSpeed.SLOW,
    cost = {"fire", "fire", "salt"},
    keywords = {
        zoneAnchor = {
            range = "NEAR",
            elevation = "GROUNDED",
            requireAll = true
        },
        damage = {
            amount = 16,
            type = "fire"
        },
        ground = true,
        burn = {
            duration = 4.0,
            tickDamage = 3
        },
    },
    sfx = "volcano_rumble",
    blockableBy = {Constants.ShieldType.BARRIER},
    
    onMiss = function(caster, target, slot)
        print(string.format("[MISS] %s's Lava Eruption misses because conditions aren't right!", caster.name))
        return {
            missBackfire = true,
            backfireDamage = 4,
            backfireMessage = "Lava Eruption backfires when cast at wrong range!"
        }
    end,
    
    onSuccess = function(caster, target, slot, results)
        print(string.format("[SUCCESS] %s's Lava Eruption hits %s with full force!", caster.name, target.name))
        return {
            successMessage = "The ground trembles with volcanic fury!",
            extraEffect = "area_burn",
            burnDuration = 2.0
        }
    end
}

-- Battle Shield with multiple effects on block (Fire-based shield)
FireSpells.battleshield = {
    id = "battleshield",
    name = "Flamewreath",
    affinity = "fire", 
    description = "An aggressive barrier that counterattacks and empowers the caster when blocking",
    attackType = Constants.AttackType.UTILITY,
    castTime = 7.0,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE, Constants.TokenType.FIRE},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
            
            onBlock = function(defender, attacker, slotIndex, blockInfo)
                print("[SPELL DEBUG] Flamewreath onBlock handler executing!")
                local events = {}
                
                if attacker then
                    table.insert(events, {
                        type = "DAMAGE",
                        source = "caster",
                        target = "enemy",
                        amount = 5,
                        damageType = "fire",
                        counterDamage = true
                    })
                end
                
                table.insert(events, {
                    type = "EFFECT",
                    source = "caster",
                    target = "self",
                    effectType = "battle_shield_counter",
                    duration = 0.8,
                    color = {1.0, 0.7, 0.2, 0.8}
                })
                
                print("[SPELL DEBUG] Battle Shield returning " .. #events .. " events")
                return events
            end
        },
    },
    sfx = "fire_shield",
    blockableBy = {}
}

return FireSpells