-- generate_vfx_report.lua
-- Script to generate a detailed report of spell VFX usage

local Spells = require("spells").spells
local Keywords = require("keywords")
local Constants = require("core.Constants")
local SpellCompiler = require("spellCompiler")

-- Function to determine the correct VFX type for a spell based on its properties
local function determineCorrectVfx(spell)
    -- If the spell already uses vfx keyword, assume it's correct
    if spell.keywords and spell.keywords.vfx then
        local effect = spell.keywords.vfx.effect
        -- Handle both string and Constants.VFXType references
        if type(effect) == "string" then
            return effect
        else
            return tostring(effect) -- Convert constant to string
        end
    end
    
    -- If the spell has a top-level vfx property, use that
    if spell.vfx then
        return spell.vfx
    end
    
    -- Check for keywords with built-in VFX
    if spell.keywords then
        -- Check ground keyword
        if spell.keywords.ground then
            local groundVfx = spell.keywords.ground.vfx
            if groundVfx then
                return groundVfx
            else
                return "tidal_force_ground" -- Default for ground
            end
        end
        
        -- Check elevate keyword
        if spell.keywords.elevate then
            local elevateVfx = spell.keywords.elevate.vfx
            if elevateVfx then
                return elevateVfx
            else
                return "emberlift" -- Default for elevate
            end
        end
    end
    
    -- Otherwise, determine based on spell type and element
    local spellElement = spell.affinity
    local attackType = spell.attackType
    
    -- Mapping of element + attack type to suggested VFX
    local elementAttackMap = {
        -- Fire element
        fire = {
            projectile = "firebolt",
            remote = "firebolt",
            zone = "meteor",
            utility = "conjurefire"
        },
        -- Moon element
        moon = {
            projectile = "lunardisjunction",
            remote = "fullmoonbeam",
            zone = "mistveil",
            utility = "conjuremoonlight"
        },
        -- Sun element
        sun = {
            projectile = "firebolt",
            remote = "meteor",
            zone = "blazing_ascent",
            utility = "nova_conjure"
        },
        -- Water element
        water = {
            projectile = "tidal_force",
            remote = "tidal_force",
            zone = "tidal_force_ground",
            utility = "mistveil"
        },
        -- Generic fallbacks
        generic = {
            projectile = "firebolt",
            remote = "impact",
            zone = "impact",
            utility = "impact"
        }
    }
    
    -- Get the element-specific map or fall back to generic
    local elementMap = elementAttackMap[spellElement] or elementAttackMap.generic
    
    -- Get the attack-specific VFX or fall back to impact
    return elementMap[attackType] or "impact"
end

-- Function to get the proper formatting for VFX values
local function formatVfxValue(value)
    if not value then return "N/A" end
    
    -- Check if it's a Constants.VFXType value
    for typeName, typeValue in pairs(Constants.VFXType) do
        if typeValue == value then
            return string.format("Constants.VFXType.%s", typeName)
        end
    end
    
    -- If it's just a string, return it with quotes
    return string.format('"%s"', value)
end

-- Function to check if a spell has events in the test
local function hasEffectEvents(spell)
    -- Skip if no spell
    if not spell then return false end
    
    -- Dummy objects for testing
    local dummyCaster = {
        name = "Test Caster",
        elevation = Constants.ElevationState.GROUNDED,
        gameState = { rangeState = Constants.RangeState.NEAR },
        spellSlots = { {}, {}, {} },
        manaPool = { tokens = {} }
    }
    
    local dummyTarget = {
        name = "Test Target",
        elevation = Constants.ElevationState.GROUNDED,
        gameState = { rangeState = Constants.RangeState.NEAR },
        spellSlots = { {}, {}, {} },
        manaPool = { tokens = {} }
    }
    
    -- Compile the spell
    local compiledSpell = SpellCompiler.compileSpell(spell, Keywords)
    if not compiledSpell then return false end
    
    -- Generate events but don't execute them
    local events = compiledSpell.generateEvents(dummyCaster, dummyTarget, 1)
    
    -- Check for EFFECT events
    for _, event in ipairs(events or {}) do
        if event.type == "EFFECT" then
            return true
        end
    end
    
    return false
end

-- Main function to generate the report
local function generateReport()
    print("Generating VFX report...")
    
    -- Table headers for markdown
    local report = "# Spells VFX Audit Report\n\n"
    report = report .. "This report shows the current VFX setup for each spell and recommendations for improvement.\n\n"
    report = report .. "| Spell Name | Element | Attack Type | Current VFX | Using VFX Keyword | Generates EFFECT Events | Recommended VFX | Status |\n"
    report = report .. "|------------|---------|-------------|-------------|-------------------|------------------------|-----------------|--------|\n"
    
    -- Process all spells and add to report
    local stats = {
        total = 0,
        correct = 0,
        needsKeyword = 0,
        noVfx = 0
    }
    
    -- Sort spells by name
    local sortedSpells = {}
    for _, spell in pairs(Spells) do
        table.insert(sortedSpells, spell)
    end
    
    table.sort(sortedSpells, function(a, b) return a.name < b.name end)
    
    -- Process sorted spells
    for _, spell in ipairs(sortedSpells) do
        stats.total = stats.total + 1
        
        local currentVfx = spell.vfx or "None"
        local usesVfxKeyword = (spell.keywords and spell.keywords.vfx) and "Yes" or "No"
        local hasEvents = hasEffectEvents(spell) and "Yes" or "No"
        local recommendedVfx = determineCorrectVfx(spell)
        
        -- Determine status
        local status
        if hasEvents == "Yes" then
            status = "✅ Correct"
            stats.correct = stats.correct + 1
        elseif usesVfxKeyword == "No" and currentVfx ~= "None" then
            status = "⚠️ Needs VFX Keyword"
            stats.needsKeyword = stats.needsKeyword + 1
        elseif currentVfx == "None" and spell.attackType ~= "utility" then
            status = "❌ Missing VFX"
            stats.noVfx = stats.noVfx + 1
        else
            status = "⚠️ Review"
            stats.needsKeyword = stats.needsKeyword + 1
        end
        
        -- Add row to report
        report = report .. string.format("| %s | %s | %s | %s | %s | %s | %s | %s |\n",
            spell.name,
            spell.affinity or "N/A",
            spell.attackType or "N/A",
            currentVfx,
            usesVfxKeyword,
            hasEvents,
            recommendedVfx,
            status
        )
    end
    
    -- Add statistics section
    report = report .. "\n## Summary Statistics\n\n"
    report = report .. string.format("- **Total Spells:** %d\n", stats.total)
    report = report .. string.format("- **Correctly Implemented:** %d (%.1f%%)\n", 
        stats.correct, (stats.correct / stats.total) * 100)
    report = report .. string.format("- **Needs VFX Keyword:** %d (%.1f%%)\n", 
        stats.needsKeyword, (stats.needsKeyword / stats.total) * 100)
    report = report .. string.format("- **Missing VFX:** %d (%.1f%%)\n", 
        stats.noVfx, (stats.noVfx / stats.total) * 100)
    
    -- Implementation recommendations
    report = report .. "\n## Implementation Recommendations\n\n"
    report = report .. "1. **Replace top-level VFX properties with VFX keywords:**\n"
    report = report .. "   ```lua\n"
    report = report .. "   -- Before:\n"
    report = report .. "   vfx = \"firebolt\",\n\n"
    report = report .. "   -- After:\n"
    report = report .. "   keywords = {\n"
    report = report .. "       -- other keywords...\n"
    report = report .. "       vfx = { effect = Constants.VFXType.FIREBOLT, target = Constants.TargetType.ENEMY }\n"
    report = report .. "   },\n"
    report = report .. "   ```\n\n"
    
    report = report .. "2. **Add VFX keywords to spells missing visual effects:**\n"
    report = report .. "   - Use Constants.VFXType for standard effect names\n"
    report = report .. "   - Match the effect type to the spell's element and attack pattern\n"
    report = report .. "   - Consider spell's role when selecting the visual effect\n\n"
    
    report = report .. "3. **Run the automated fix tool:**\n"
    report = report .. "   ```bash\n"
    report = report .. "   lua tools/fix_vfx_events.lua\n"
    report = report .. "   ```\n\n"
    
    report = report .. "4. **Test with the VFX events test:**\n"
    report = report .. "   ```bash\n"
    report = report .. "   lua tools/test_vfx_events.lua\n"
    report = report .. "   ```\n"
    
    print("Report generated successfully!")
    return report
end

-- Generate the report
local report = generateReport()

-- Write report to file
local reportPath = "/Users/russell/Manastorm/docs/VFX_Audit_Report.md"
local file = io.open(reportPath, "w")
if file then
    file:write(report)
    file:close()
    print("Report written to: " .. reportPath)
else
    print("Error: Could not write report to file")
end

-- Return success
return true