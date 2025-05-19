-- Keywords Documentation Generator
-- This file helps maintain up-to-date documentation for the keyword system

local Spells = require("spells")

local DocGenerator = {}

-- Function to get the default target type description for a keyword
local function getTargetTypeDescription(keyword)
    local targetType = Spells.keywordSystem.keywordTargets[keyword]
    local descriptions = {
        self = "Affects the caster",
        enemy = "Affects the opponent",
        pool_self = "Affects the caster's mana pool",
        pool_enemy = "Affects the opponent's mana pool",
        slot_self = "Affects the caster's spell slots",
        slot_enemy = "Affects the opponent's spell slots",
        global = "Affects the game state",
        none = "No specific target"
    }
    
    return descriptions[targetType] or "Unknown target type"
end

-- Generate markdown documentation for all available keywords
function DocGenerator.generateMarkdown()
    local output = "# Manastorm Spell Keyword Reference\n\n"
    output = output .. "This document provides a reference for all available keywords in the Manastorm spell system.\n\n"
    
    -- Get keyword info organized by category
    local keywordsByCategory = Spells.keywordSystem.getKeywordHelp("byCategory")
    
    -- Table of contents
    output = output .. "## Contents\n\n"
    for categoryKey, category in pairs(keywordsByCategory) do
        output = output .. "- [" .. category.name .. "](#" .. string.lower(category.name:gsub("%s+", "-")) .. ")\n"
    end
    output = output .. "\n\n"
    
    -- Generate sections for each category
    for categoryKey, category in pairs(keywordsByCategory) do
        output = output .. "## " .. category.name .. "\n\n"
        
        for _, keyword in ipairs(category.keywords) do
            output = output .. "### " .. keyword.name .. "\n\n"
            output = output .. keyword.description .. "\n\n"
            output = output .. "**Default targeting:** " .. getTargetTypeDescription(keyword.name) .. "\n\n"
            output = output .. "**Example usage:**\n\n"
            output = output .. "```lua\n" .. keyword.example .. "\n```\n\n"
            
            -- Add targeting example if appropriate
            if Spells.keywordSystem.keywordTargets[keyword.name] then
                output = output .. "**Custom targeting example:**\n\n"
                output = output .. "```lua\n" .. keyword.name .. " = {\n"
                output = output .. "    -- Parameters as above\n"
                output = output .. "    target = \"" .. Spells.keywordSystem.keywordTargets[keyword.name] .. "\"  -- Default target\n"
                output = output .. "    -- You can override with any of: \"self\", \"enemy\", \"pool_self\", \"pool_enemy\", \"slot_self\", \"slot_enemy\", \"global\", \"none\"\n"
                output = output .. "}\n```\n\n"
            end
        end
    end
    
    -- Add a section with sample spells
    output = output .. "## Sample Spells\n\n"
    output = output .. "These examples show how to combine multiple keywords to create complex spell effects.\n\n"
    
    -- Targeting section
    output = output .. "### About Targeting\n\n"
    output = output .. "Each keyword has a default target (shown in the keyword documentation). You can override this by specifying a `target` parameter in the keyword configuration.\n\n"
    output = output .. "Available target types:\n\n"
    output = output .. "| Target Type | Description |\n"
    output = output .. "|------------|-------------|\n"
    output = output .. "| `self` | Affects the caster |\n"
    output = output .. "| `enemy` | Affects the opponent |\n"
    output = output .. "| `pool_self` | Affects the caster's mana pool |\n"
    output = output .. "| `pool_enemy` | Affects the opponent's mana pool |\n"
    output = output .. "| `slot_self` | Affects the caster's spell slots |\n"
    output = output .. "| `slot_enemy` | Affects the opponent's spell slots |\n"
    output = output .. "| `global` | Affects the game state |\n"
    output = output .. "| `none` | No specific target |\n\n"
    
    -- Multi-target spell example
    output = output .. "### Arcane Reversal (Multi-Target Example)\n\n"
    output = output .. "```lua\nSpells.arcaneReversal = {\n"
    output = output .. "    id = \"arcanereversal\",\n"
    output = output .. "    name = \"Arcane Reversal\",\n"
    output = output .. "    description = \"A complex spell that manipulates mana, movement, and timing simultaneously\",\n"
    output = output .. "    attackType = \"remote\",\n"
    output = output .. "    castTime = 6.0,\n"
    output = output .. "    cost = {\"moon\", \"star\", \"force\", \"force\"},\n"
    output = output .. "    keywords = {\n"
    output = output .. "        -- Apply damage to enemy\n"
    output = output .. "        damage = {\n"
    output = output .. "            amount = function(caster, target)\n"
    output = output .. "                -- More damage if enemy has active shields\n"
    output = output .. "                local shieldCount = 0\n"
    output = output .. "                for _, slot in ipairs(target.spellSlots) do\n"
    output = output .. "                    if slot.active and slot.isShield then\n"
    output = output .. "                        shieldCount = shieldCount + 1\n"
    output = output .. "                    end\n"
    output = output .. "                end\n"
    output = output .. "                return 8 + (shieldCount * 4)  -- 8 base + 4 per shield\n"
    output = output .. "            end,\n"
    output = output .. "            type = \"star\",\n"
    output = output .. "            target = \"ENEMY\"  -- Explicit targeting\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Move self to opposite range\n"
    output = output .. "        rangeShift = {\n"
    output = output .. "            position = function(caster, target)\n"
    output = output .. "                return caster.gameState.rangeState == \"NEAR\" and \"FAR\" or \"NEAR\"\n"
    output = output .. "            end,\n"
    output = output .. "            target = \"SELF\"  -- Different target from damage\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Lock opponent's mana tokens\n"
    output = output .. "        lock = {\n"
    output = output .. "            duration = 4.0,\n"
    output = output .. "            target = \"POOL_ENEMY\"  -- Target opponent's pool\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Add tokens to own pool\n"
    output = output .. "        conjure = {\n"
    output = output .. "            token = \"force\",\n"
    output = output .. "            amount = 1,\n"
    output = output .. "            target = \"POOL_SELF\"  -- Target own pool\n"
    output = output .. "        },\n"
    output = output .. "        \n"
    output = output .. "        -- Accelerate own next spell\n"
    output = output .. "        accelerate = {\n"
    output = output .. "            amount = 2.0,\n"
    output = output .. "            slot = 1,  -- First slot\n"
    output = output .. "            target = \"SLOT_SELF\"  -- Target own slot\n"
    output = output .. "        }\n"
    output = output .. "    },\n"
    output = output .. "    vfx = \"arcane_reversal\",\n"
    output = output .. "}\n```\n\n"
    
    -- Fireball example
    output = output .. "### Fireball\n\n"
    output = output .. "```lua\nSpells.fireball = {\n"
    output = output .. "    id = \"fireball\",\n"
    output = output .. "    name = \"Fireball\",\n"
    output = output .. "    description = \"Launches a ball of fire that deals heavy damage\",\n"
    output = output .. "    attackType = \"projectile\",\n"
    output = output .. "    castTime = 4.0,\n"
    output = output .. "    cost = {\"fire\", \"fire\", \"force\"},\n"
    output = output .. "    keywords = {\n"
    output = output .. "        damage = {\n"
    output = output .. "            amount = function(caster, target)\n"
    output = output .. "                -- More damage at FAR range\n"
    output = output .. "                return caster.gameState.rangeState == \"FAR\" and 18 or 12\n"
    output = output .. "            end,\n"
    output = output .. "            type = \"fire\"\n"
    output = output .. "            -- No target specified, uses default: ENEMY\n"
    output = output .. "        },\n"
    output = output .. "        -- Add AOE effect if cast from AERIAL\n"
    output = output .. "        zoneMulti = function(caster, target)\n"
    output = output .. "            return caster.elevation == \"AERIAL\"\n"
    output = output .. "        end\n"
    output = output .. "    },\n"
    output = output .. "    vfx = \"fireball\",\n"
    output = output .. "    sfx = \"explosion\",\n"
    output = output .. "}\n```\n\n"
    
    return output
end

-- Generate a documentation file
function DocGenerator.writeDocumentation(outputPath)
    outputPath = outputPath or "/Users/russell/Manastorm/docs/KEYWORDS.md"
    
    local markdown = DocGenerator.generateMarkdown()
    
    local file = io.open(outputPath, "w")
    if file then
        file:write(markdown)
        file:close()
        print("Keyword documentation written to: " .. outputPath)
        return true
    else
        print("Error: Could not open file for writing: " .. outputPath)
        return false
    end
end

-- Execute documentation generation if this file is run directly
if not ... then
    DocGenerator.writeDocumentation()
end

return DocGenerator