-- Keywords Documentation Generator
-- This file helps maintain up-to-date documentation for the keyword system

local Spells = require("spells")

local DocGenerator = {}

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
            output = output .. "**Example usage:**\n\n"
            output = output .. "```lua\n" .. keyword.example .. "\n```\n\n"
        end
    end
    
    -- Add a section with sample spells
    output = output .. "## Sample Spells\n\n"
    output = output .. "These examples show how to combine multiple keywords to create complex spell effects.\n\n"
    
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
    output = output .. "        },\n"
    output = output .. "        -- Add AOE effect if cast from AERIAL\n"
    output = output .. "        zoneMulti = function(caster, target)\n"
    output = output .. "            return caster.elevation == \"AERIAL\"\n"
    output = output .. "        end\n"
    output = output .. "    },\n"
    output = output .. "    vfx = \"fireball\",\n"
    output = output .. "    sfx = \"explosion\",\n"
    output = output .. "    blockableBy = {\"barrier\"}\n"
    output = output .. "}\n```\n\n"
    
    -- Arcane Shield example
    output = output .. "### Arcane Shield\n\n"
    output = output .. "```lua\nSpells.arcaneShield = {\n"
    output = output .. "    id = \"arcaneshield\",\n"
    output = output .. "    name = \"Arcane Shield\",\n"
    output = output .. "    description = \"Creates a powerful shield that also accelerates your next spell\",\n"
    output = output .. "    attackType = \"utility\",\n"
    output = output .. "    castTime = 3.0,\n"
    output = output .. "    cost = {\"force\", \"star\", \"star\"},\n"
    output = output .. "    keywords = {\n"
    output = output .. "        block = {\n"
    output = output .. "            type = \"ward\",\n"
    output = output .. "            blocks = {\"projectile\", \"remote\"},\n"
    output = output .. "            manaLinked = true\n"
    output = output .. "        },\n"
    output = output .. "        accelerate = {\n"
    output = output .. "            slot = 1,  -- Accelerate first spell slot\n"
    output = output .. "            amount = 2.0  -- Reduce cast time by 2 seconds\n"
    output = output .. "        }\n"
    output = output .. "    },\n"
    output = output .. "    vfx = \"arcane_barrier\",\n"
    output = output .. "    blockableBy = {}\n"
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