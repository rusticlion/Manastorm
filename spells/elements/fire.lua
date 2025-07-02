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
    description = "Conjures a Fire mana token. Takes longer to cast the more Fire tokens already present.",
    attackType = Constants.AttackType.UTILITY,
    visualShape = "surge",
    castTime = Constants.CastSpeed.FAST,
    cost = {},  -- No mana cost
    keywords = {
        conjure = {
            token = Constants.TokenType.FIRE,
            amount = 1
        },
    },
    
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
    description = "Superheated bolt. Maximum damage at FAR RANGE.",
    castTime = Constants.CastSpeed.FAST,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = "bolt",
    cost = {Constants.TokenType.FIRE, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = function(caster, target)
                if target and target.gameState.rangeState == Constants.RangeState.FAR then
                    return 9
                end
                return 5
            end,
            type = Constants.DamageType.FIRE
        },
    },
    sfx = "fire_whoosh",
}

-- Fireball spell
FireSpells.fireball = {
    id = "fireball",
    name = "Fireball",
    affinity = "fire",
    description = "Fireball that deals damage and burns.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.PROJECTILE,
    visualShape = "orb",
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE, Constants.TokenType.ANY},
    keywords = {
        damage = {
            amount = 10,
            burn = {
                amount = 2,
                duration = 2
            }
        },
    }
}

-- Blastwave spell
FireSpells.blastwave = {
    id = "blastwave",
    name = "Blast Wave",
    affinity = "fire",
    description = "Blast of flame. Maximum damage at NEAR RANGE and matched ELEVATION.",
    castTime = Constants.CastSpeed.SLOW,
    attackType = Constants.AttackType.ZONE,
    visualShape = "blast",
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE},
    keywords = {
        damage = {
            amount = function(caster, target)
                local baseDmg = 2
                if target and target.elevation == caster.elevation then
                    baseDmg = baseDmg + 5
                end
                if target and target.gameState.rangeState == Constants.RangeState.NEAR then
                    baseDmg = baseDmg + 12
                end
                return baseDmg
            end,
            type = Constants.DamageType.FIRE,
        },
    },
    sfx = "blastwave",
}

-- Combust Mana spell
FireSpells.combustMana = {
    id = "combustMana",
    name = "Combust Mana",
    affinity = "fire",
    description = "Disrupts opponent channeling, burning one token to Salt.",
    castTime = Constants.CastSpeed.NORMAL,
    attackType = Constants.AttackType.UTILITY,
    visualShape = "affectManaPool",
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
    description = "Rockets upward in a burst of fire, dealing damage and becoming AERIAL.",
    attackType = Constants.AttackType.ZONE,
    visualShape = "blast",
    castTime = Constants.CastSpeed.SLOW,
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
}

-- Eruption spell
FireSpells.eruption = {
    id = "eruption",
    name = "Molten Ash",
    affinity = "fire",
    description = "Creates a volcanic eruption under the opponent. Only works at NEAR range.",
    attackType = Constants.AttackType.ZONE,
    visualShape = "groundBurst",
    castTime = Constants.CastSpeed.SLOW,
    cost = {"fire", "fire", "salt"},
    unlockSpell = "blazingascent",
    keywords = {
        zoneAnchor = {
            range = function(caster, target)
                return caster.gameState.rangeState
            end,
            elevation = "GROUNDED",
            requireAll = true
        },
        damage = {
            amount = 16,
            type = "fire"
        },
        burn = {
            duration = 4.0,
            tickDamage = 3
        },
    },
    sfx = "volcano_rumble",
    
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
    description = "A Barrier of flames that stops Projectile and Zone attacks, burning NEAR attackers.",
    attackType = Constants.AttackType.UTILITY,
    visualShape = "barrier",
    castTime = Constants.CastSpeed.SLOW,
    cost = {Constants.TokenType.FIRE, Constants.TokenType.FIRE, Constants.TokenType.FIRE},
    keywords = {
        block = {
            type = Constants.ShieldType.BARRIER,
            blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
            
            onBlock = function(defender, attacker, slotIndex, blockInfo)
                print("[SPELL DEBUG] Flamewreath onBlock handler executing!")
                local events = {}
                
                if attacker.elevation == Constants.ElevationState.NEAR then
                    table.insert(events, {
                        type = "APPLY_STATUS",
                        source = "caster",
                        target = "enemy",
                        statusType = Constants.StatusType.BURN,
                        duration = 1.5,
                        tickDamage = 4,
                        targetSlot = "NEAR"
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
}

-- Desperation Fire - cost decreases as caster health drops
FireSpells.desperationFire = {
    id = "desperationfire",
    name = "Burning Desperation",
    affinity = Constants.TokenType.FIRE,
    description = "A fiery attack whose Fire cost decreases as your health lowers.",
    attackType = Constants.AttackType.PROJECTILE,
    castTime = Constants.CastSpeed.NORMAL,
    cost = { Constants.TokenType.FIRE, Constants.TokenType.FIRE, Constants.TokenType.FIRE },
    keywords = {
        damage = { amount = 15, type = Constants.DamageType.FIRE }
    },
    getCost = function(caster, target)
        local fireCost = 3
        if caster and caster.health < 75 then fireCost = 2 end
        if caster and caster.health < 40 then fireCost = 1 end
        if caster and caster.health < 20 then fireCost = 0 end

        local finalCost = {}
        for i = 1, fireCost do
            table.insert(finalCost, Constants.TokenType.FIRE)
        end
        return finalCost
    end,
}

return FireSpells